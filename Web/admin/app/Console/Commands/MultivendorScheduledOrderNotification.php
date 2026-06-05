<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class MultivendorScheduledOrderNotification extends Command
{
    protected $signature   = 'app:multivendor-scheduled-order-notification';
    protected $description = 'Notify vendor of upcoming scheduled orders (pure PHP — no Node.js)';

    private string     $projectId;
    private string     $accessToken;
    private HttpClient $http;

    public function handle(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            \Log::error('[SCHED_NOTIFY] credentials.json not found');
            return;
        }
        try {
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            \Log::info('[SCHED_NOTIFY] Starting');

            $settings = $this->fsGet('settings', 'scheduleOrderNotification');
            if (empty($settings)) {
                \Log::info('[SCHED_NOTIFY] No scheduleOrderNotification settings found');
                return;
            }

            $timeUnit   = $settings['timeUnit']   ?? 'minute';
            $notifyTime = (int)($settings['notifyTime'] ?? 0);
            if (!$notifyTime) {
                \Log::info('[SCHED_NOTIFY] notifyTime is 0 — nothing to do');
                return;
            }

            $notifyBeforeSeconds = match ($timeUnit) {
                'hour'  => $notifyTime * 3600,
                'day'   => $notifyTime * 86400,
                default => $notifyTime * 60,
            };

            $orders = $this->fsQuery('vendor_orders', [
                ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Placed']],
            ]);

            $now    = time();
            $buffer = 60; // ±60s window (matches JS bufferMs)

            foreach ($orders as $order) {
                $scheduleTs = $this->extractTimestamp($order['scheduleTime'] ?? null);
                if (!$scheduleTs) continue;

                $notificationSent = $order['notificationSent'] ?? false;
                if ($notificationSent) continue;

                $diffSeconds = $scheduleTs - $now;
                if ($diffSeconds <= 0) continue; // already past

                if (abs($diffSeconds - $notifyBeforeSeconds) > $buffer) continue;

                $orderId = $order['id'] ?? '';
                \Log::info("[SCHED_NOTIFY] Sending notification for order $orderId (schedule in {$diffSeconds}s)");

                $this->fsUpdate('vendor_orders', $orderId, [
                    'notificationSent' => ['booleanValue' => true],
                ]);

                $vendorUserId = $order['vendor']['author'] ?? '';
                if ($vendorUserId) {
                    $vendorDoc = $this->fsGet('users', $vendorUserId);
                    $fcmToken  = $vendorDoc['fcmToken'] ?? '';
                    if ($fcmToken) {
                        $scheduleDate = date('D M d Y', $scheduleTs);
                        $scheduleTime = date('h:i:s A', $scheduleTs);
                        $this->sendFcm(
                            $fcmToken,
                            'Scheduled Order Reminder',
                            "You have a scheduled order for {$scheduleDate} at {$scheduleTime}."
                        );
                    }
                }
            }

            \Log::info('[SCHED_NOTIFY] Done');
        } catch (\Throwable $e) {
            \Log::error('[SCHED_NOTIFY] Fatal: ' . $e->getMessage());
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
            \Log::warning("[SCHED_NOTIFY] fsGet $collection/$docId: " . $e->getMessage());
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
            \Log::error("[SCHED_NOTIFY] fsQuery $collection: " . $e->getMessage());
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
                \Log::error("[SCHED_NOTIFY] fsUpdate $collection/$docId status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[SCHED_NOTIFY] fsUpdate $collection/$docId: " . $e->getMessage());
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
                \Log::error("[SCHED_NOTIFY] FCM error status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error('[SCHED_NOTIFY] FCM exception: ' . $e->getMessage());
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
