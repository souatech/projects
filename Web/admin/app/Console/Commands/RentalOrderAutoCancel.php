<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class RentalOrderAutoCancel extends Command
{
    protected $signature   = 'app:rental-order-auto-cancel';
    protected $description = 'Auto-cancel rental orders unpaid after 2 hours (pure PHP — no Node.js)';

    private string     $projectId;
    private string     $accessToken;
    private HttpClient $http;

    public function handle(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            \Log::error('[RENTAL_CANCEL] credentials.json not found');
            return;
        }
        try {
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            \Log::info('[RENTAL_CANCEL] Starting');

            $orders = $this->fsQuery('rental_orders', [
                ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'EN_ATTENTE_PAIEMENT']],
            ]);

            $cutoff = time() - 2 * 3600;

            foreach ($orders as $order) {
                $orderId   = $order['id'] ?? '';
                $createdAt = $this->extractTimestamp($order['createdAt'] ?? null);
                $depositStatus = strtoupper((string)($order['paymentStatusDeposit'] ?? $order['paymentDepositStatus'] ?? 'PENDING'));
                if (!$createdAt || $createdAt > $cutoff) continue;
                if ($depositStatus === 'PAID') continue;

                \Log::info("[RENTAL_CANCEL] Cancelling order $orderId (deposit unpaid >2h)");
                $this->fsUpdate('rental_orders', $orderId, [
                    'status' => ['stringValue' => 'CANCELLED'],
                    'cancelledReason' => ['stringValue' => 'Acompte non confirmé sous 2h'],
                ]);

                $customerId  = $order['authorID'] ?? '';
                $shortId     = substr($orderId, -10);
                if ($customerId) {
                    $userDoc = $this->fsGet('users', $customerId);
                    $fcm     = $userDoc['fcmToken'] ?? '';
                    if ($fcm) {
                        $this->sendFcm(
                            $fcm,
                            'Réservation annulée',
                            "Votre réservation Rental #{$shortId} a été annulée : acompte non confirmé sous 2h."
                        );
                    }
                }
            }

            \Log::info('[RENTAL_CANCEL] Done');
        } catch (\Throwable $e) {
            \Log::error('[RENTAL_CANCEL] Fatal: ' . $e->getMessage());
        }
    }

    // ════ Firestore helpers ════════════════════════════════════════════

    private function fsBaseUrl(): string
    {
        return "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";
    }

    private function fsGet(string $collection, string $docId): array
    {
        try {
            $resp = $this->http->get("{$this->fsBaseUrl()}/{$collection}/{$docId}", [
                'headers' => ['Authorization' => 'Bearer ' . $this->accessToken],
            ]);
            if ($resp->getStatusCode() !== 200) return [];
            return $this->decodeDoc(json_decode((string)$resp->getBody(), true));
        } catch (\Throwable $e) {
            \Log::warning("[RENTAL_CANCEL] fsGet $collection/$docId: " . $e->getMessage());
            return [];
        }
    }

    private function fsQuery(string $collection, array $filters): array
    {
        try {
            $wheres = array_map(fn($f) => [
                'fieldFilter' => [
                    'field' => ['fieldPath' => $f['field']],
                    'op'    => $f['op'],
                    'value' => $f['value'],
                ],
            ], $filters);

            $whereClause = count($wheres) === 1
                ? $wheres[0]
                : ['compositeFilter' => ['op' => 'AND', 'filters' => $wheres]];

            $resp = $this->http->post("{$this->fsBaseUrl()}:runQuery", [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->accessToken,
                    'Content-Type'  => 'application/json',
                ],
                'json' => [
                    'structuredQuery' => [
                        'from'  => [['collectionId' => $collection]],
                        'where' => $whereClause,
                    ],
                ],
            ]);

            $results = [];
            foreach (json_decode((string)$resp->getBody(), true) ?? [] as $row) {
                if (!empty($row['document'])) {
                    $doc       = $this->decodeDoc($row['document']);
                    $nameParts = explode('/', $row['document']['name'] ?? '');
                    $doc['id'] = end($nameParts);
                    $results[] = $doc;
                }
            }
            return $results;
        } catch (\Throwable $e) {
            \Log::error("[RENTAL_CANCEL] fsQuery $collection: " . $e->getMessage());
            return [];
        }
    }

    private function fsUpdate(string $collection, string $docId, array $typedFields): void
    {
        if (empty($docId)) return;
        try {
            $mask = implode('&', array_map(
                fn($k) => 'updateMask.fieldPaths=' . urlencode($k),
                array_keys($typedFields)
            ));
            $resp = $this->http->patch("{$this->fsBaseUrl()}/{$collection}/{$docId}?{$mask}", [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->accessToken,
                    'Content-Type'  => 'application/json',
                ],
                'json' => ['fields' => $typedFields],
            ]);
            if ($resp->getStatusCode() !== 200) {
                \Log::error("[RENTAL_CANCEL] fsUpdate $collection/$docId status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[RENTAL_CANCEL] fsUpdate $collection/$docId: " . $e->getMessage());
        }
    }

    private function decodeDoc(array $doc): array
    {
        $result = [];
        foreach ($doc['fields'] ?? [] as $key => $typedVal) {
            $result[$key] = $this->decodeFsValue($typedVal);
        }
        return $result;
    }

    private function decodeFsValue(array $v): mixed
    {
        if (array_key_exists('stringValue',    $v)) return $v['stringValue'];
        if (array_key_exists('integerValue',   $v)) return (int)$v['integerValue'];
        if (array_key_exists('doubleValue',    $v)) return (float)$v['doubleValue'];
        if (array_key_exists('booleanValue',   $v)) return (bool)$v['booleanValue'];
        if (array_key_exists('nullValue',      $v)) return null;
        if (array_key_exists('timestampValue', $v)) return $v;
        if (array_key_exists('geoPointValue',  $v)) return $v;
        if (array_key_exists('referenceValue', $v)) return $v['referenceValue'];
        if (array_key_exists('arrayValue', $v)) {
            return array_map(fn($i) => $this->decodeFsValue($i), $v['arrayValue']['values'] ?? []);
        }
        if (array_key_exists('mapValue', $v)) {
            return $this->decodeDoc(['fields' => $v['mapValue']['fields'] ?? []]);
        }
        return null;
    }

    private function extractTimestamp(mixed $val): ?int
    {
        if (!$val) return null;
        if (is_int($val) || is_float($val)) return (int)$val;
        if (is_array($val) && isset($val['timestampValue'])) {
            $t = strtotime($val['timestampValue']);
            return $t ?: null;
        }
        return null;
    }

    private function sendFcm(string $token, string $title, string $body): void
    {
        try {
            $resp = $this->http->post(
                "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send",
                [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $this->accessToken,
                        'Content-Type'  => 'application/json',
                    ],
                    'json' => [
                        'message' => [
                            'token'        => $token,
                            'notification' => ['title' => $title, 'body' => $body],
                        ],
                    ],
                ]
            );
            if ($resp->getStatusCode() !== 200) {
                \Log::error("[RENTAL_CANCEL] FCM error status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error('[RENTAL_CANCEL] FCM exception: ' . $e->getMessage());
        }
    }

    private function getAccessToken(): string
    {
        $client = new GoogleClient();
        $client->setAuthConfig(storage_path('app/firebase/credentials.json'));
        $client->addScope('https://www.googleapis.com/auth/cloud-platform');
        $client->refreshTokenWithAssertion();
        $token = $client->getAccessToken();
        if (empty($token['access_token'])) {
            throw new \RuntimeException('Failed to obtain Google access token');
        }
        return $token['access_token'];
    }
}
