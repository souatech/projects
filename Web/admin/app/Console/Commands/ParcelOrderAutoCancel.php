<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class ParcelOrderAutoCancel extends Command
{
    protected $signature   = 'app:parcel-order-auto-cancel';
    protected $description = 'Auto-cancel parcel orders unaccepted after 24 hours (pure PHP — no Node.js)';

    private string     $projectId;
    private string     $accessToken;
    private HttpClient $http;

    public function handle(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            \Log::error('[PARCEL_CANCEL] credentials.json not found');
            return;
        }
        try {
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            \Log::info('[PARCEL_CANCEL] Starting');

            $orders = $this->fsQuery('parcel_orders', [
                ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Placed']],
            ]);

            $cutoff = time() - 24 * 3600;

            foreach ($orders as $order) {
                $orderId   = $order['id'] ?? '';
                $createdAt = $this->extractTimestamp($order['createdAt'] ?? null);
                if (!$createdAt || $createdAt > $cutoff) continue;

                \Log::info("[PARCEL_CANCEL] Cancelling order $orderId (placed >24h ago)");
                $this->fsUpdate('parcel_orders', $orderId, [
                    'status' => ['stringValue' => 'Order Cancelled'],
                ]);
                $this->processRefund($order);
            }

            \Log::info('[PARCEL_CANCEL] Done');
        } catch (\Throwable $e) {
            \Log::error('[PARCEL_CANCEL] Fatal: ' . $e->getMessage());
        }
    }

    private function processRefund(array $order): void
    {
        $customerId    = $order['authorID'] ?? '';
        $paymentMethod = strtolower($order['payment_method'] ?? 'cod');
        $orderId       = $order['id'] ?? '';

        if ($customerId && $paymentMethod !== 'cod') {
            $refundAmount = (float)($order['totalPrice'] ?? $order['total'] ?? 0);
            if ($refundAmount > 0) {
                $userDoc = $this->fsGet('users', $customerId);
                $current = (float)($userDoc['wallet_amount'] ?? 0);
                $this->fsUpdate('users', $customerId, [
                    'wallet_amount' => ['doubleValue' => $current + $refundAmount],
                ]);
                $walletId = (string) \Illuminate\Support\Str::uuid();
                $this->fsCreate('wallet', [
                    'id'              => ['stringValue'    => $walletId],
                    'amount'          => ['doubleValue'    => $refundAmount],
                    'date'            => ['timestampValue' => gmdate('Y-m-d\TH:i:s\Z')],
                    'isTopUp'         => ['booleanValue'   => true],
                    'order_id'        => ['stringValue'    => $orderId],
                    'payment_method'  => ['stringValue'    => 'Wallet'],
                    'payment_status'  => ['stringValue'    => 'success'],
                    'user_id'         => ['stringValue'    => $customerId],
                    'transactionUser' => ['stringValue'    => 'customer'],
                    'note'            => ['stringValue'    => 'Order amount refund'],
                ], $walletId);
                \Log::info("[PARCEL_CANCEL] Refunded {$refundAmount} to customer $customerId");
            }
        }

        $customerFcm = $order['author']['fcmToken'] ?? '';
        $shortId     = substr($orderId, -10);
        if ($customerFcm) {
            $this->sendFcm($customerFcm, 'Order Cancelled', "Order #{$shortId} cancelled — no driver available.");
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
            \Log::warning("[PARCEL_CANCEL] fsGet $collection/$docId: " . $e->getMessage());
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
            \Log::error("[PARCEL_CANCEL] fsQuery $collection: " . $e->getMessage());
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
                \Log::error("[PARCEL_CANCEL] fsUpdate $collection/$docId status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[PARCEL_CANCEL] fsUpdate $collection/$docId: " . $e->getMessage());
        }
    }

    private function fsCreate(string $collection, array $typedFields, ?string $docId = null): void
    {
        try {
            if ($docId !== null) {
                $url  = "{$this->fsBaseUrl()}/{$collection}/{$docId}";
                $resp = $this->http->patch($url, [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $this->accessToken,
                        'Content-Type'  => 'application/json',
                    ],
                    'json' => ['fields' => $typedFields],
                ]);
            } else {
                $url  = "{$this->fsBaseUrl()}/{$collection}";
                $resp = $this->http->post($url, [
                    'headers' => [
                        'Authorization' => 'Bearer ' . $this->accessToken,
                        'Content-Type'  => 'application/json',
                    ],
                    'json' => ['fields' => $typedFields],
                ]);
            }
            if ($resp->getStatusCode() !== 200) {
                \Log::error("[PARCEL_CANCEL] fsCreate $collection status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[PARCEL_CANCEL] fsCreate $collection: " . $e->getMessage());
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
                \Log::error("[PARCEL_CANCEL] FCM error status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error('[PARCEL_CANCEL] FCM exception: ' . $e->getMessage());
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
