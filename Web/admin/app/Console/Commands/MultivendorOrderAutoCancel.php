<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class MultivendorOrderAutoCancel extends Command
{
    protected $signature   = 'app:multivendor-order-auto-cancel';
    protected $description = 'Auto-cancel timed-out vendor orders (pure PHP — no Node.js)';

    private string     $projectId;
    private string     $accessToken;
    private HttpClient $http;

    public function handle(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            \Log::error('[VENDOR_CANCEL] credentials.json not found');
            return;
        }
        try {
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            \Log::info('[VENDOR_CANCEL] Starting');
            $this->cancelTimedOutPlacedOrders();
            $this->cancelTimedOutAcceptedOrders();
            \Log::info('[VENDOR_CANCEL] Done');
        } catch (\Throwable $e) {
            \Log::error('[VENDOR_CANCEL] Fatal: ' . $e->getMessage());
        }
    }

    // Cancel orders stuck in 'Order Placed' that exceeded orderAutoCancelDuration
    private function cancelTimedOutPlacedOrders(): void
    {
        $settings = $this->fsGet('settings', 'DriverNearBy');
        $durationMinutes = (int)($settings['orderAutoCancelDuration'] ?? 5);

        $orders = $this->fsQuery('vendor_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Placed']],
        ]);

        foreach ($orders as $order) {
            $orderId = $order['id'] ?? '';

            // Skip ecommerce
            $sectionId = $order['vendor']['section_id'] ?? '';
            if ($sectionId) {
                $section = $this->fsGet('sections', $sectionId);
                if (($section['serviceTypeFlag'] ?? '') === 'ecommerce-service') continue;
            }

            $scheduleTime = $this->extractTimestamp($order['scheduleTime'] ?? null);
            $createdAt    = $this->extractTimestamp($order['createdAt']    ?? null);
            $baseTime     = $scheduleTime ?? $createdAt;
            if (!$baseTime) continue;

            $expiresAt = $baseTime + $durationMinutes * 60;
            if (time() <= $expiresAt) continue;

            \Log::info("[VENDOR_CANCEL] Cancelling placed order $orderId (placed >$durationMinutes min ago)");
            $this->fsUpdate('vendor_orders', $orderId, [
                'status' => ['stringValue' => 'Order Cancelled'],
            ]);
            $this->processRefund($order, 'not accepted');
        }
    }

    // Cancel 'Order Accepted' orders whose orderAutoCancelAt has passed
    private function cancelTimedOutAcceptedOrders(): void
    {
        $orders = $this->fsQuery('vendor_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Accepted']],
        ]);

        $now = time();
        foreach ($orders as $order) {
            $orderId      = $order['id'] ?? '';
            $cancelAt     = $this->extractTimestamp($order['orderAutoCancelAt'] ?? null);
            if (!$cancelAt || $now <= $cancelAt) continue;

            $sectionId = $order['vendor']['section_id'] ?? '';
            if ($sectionId) {
                $section = $this->fsGet('sections', $sectionId);
                if (($section['serviceTypeFlag'] ?? '') === 'ecommerce-service') continue;
            }

            \Log::info("[VENDOR_CANCEL] Cancelling accepted order $orderId (orderAutoCancelAt expired)");
            $this->fsUpdate('vendor_orders', $orderId, [
                'status' => ['stringValue' => 'Order Cancelled'],
            ]);
            $this->processRefund($order, 'no driver found');
        }
    }

    private function processRefund(array $order, string $reason): void
    {
        $customerId    = $order['authorID'] ?? '';
        $paymentMethod = strtolower($order['payment_method'] ?? 'cod');
        $orderId       = $order['id'] ?? '';

        if ($customerId && $paymentMethod !== 'cod') {
            $refundAmount = (float)($order['payableAmount'] ?? $order['total'] ?? 0);
            if ($refundAmount > 0) {
                $userDoc = $this->fsGet('users', $customerId);
                $current = (float)($userDoc['wallet_amount'] ?? 0);
                $this->fsUpdate('users', $customerId, [
                    'wallet_amount' => ['doubleValue' => $current + $refundAmount],
                ]);
                $walletId = (string) \Illuminate\Support\Str::uuid();
                $this->fsCreate('wallet', [
                    'id'               => ['stringValue'   => $walletId],
                    'amount'           => ['doubleValue'   => $refundAmount],
                    'date'             => ['timestampValue' => gmdate('Y-m-d\TH:i:s\Z')],
                    'isTopUp'          => ['booleanValue'  => true],
                    'order_id'         => ['stringValue'   => $orderId],
                    'payment_method'   => ['stringValue'   => 'Wallet'],
                    'payment_status'   => ['stringValue'   => 'success'],
                    'user_id'          => ['stringValue'   => $customerId],
                    'transactionUser'  => ['stringValue'   => 'customer'],
                    'note'             => ['stringValue'   => 'Order Cancelled - Full refund'],
                ], $walletId);
                \Log::info("[VENDOR_CANCEL] Refunded {$refundAmount} to customer $customerId for order $orderId");
            }
        }

        // For accepted orders vendor was already credited — reverse it
        if ($reason === 'no driver found') {
            $vendorId = $order['vendor']['author'] ?? '';
            if ($vendorId) {
                $vendorWalletDocs = $this->fsQuery('wallet', [
                    ['field' => 'user_id',  'op' => 'EQUAL', 'value' => ['stringValue'  => $vendorId]],
                    ['field' => 'order_id', 'op' => 'EQUAL', 'value' => ['stringValue'  => $orderId]],
                    ['field' => 'isTopUp',  'op' => 'EQUAL', 'value' => ['booleanValue' => true]],
                ]);
                $vendorCreditTotal = 0;
                foreach ($vendorWalletDocs as $doc) {
                    $vendorCreditTotal += (float)($doc['amount'] ?? 0);
                }
                if ($vendorCreditTotal > 0) {
                    $vendorDoc     = $this->fsGet('users', $vendorId);
                    $vendorCurrent = (float)($vendorDoc['wallet_amount'] ?? 0);
                    $this->fsUpdate('users', $vendorId, [
                        'wallet_amount' => ['doubleValue' => $vendorCurrent - $vendorCreditTotal],
                    ]);
                    $vendorWalletId = (string) \Illuminate\Support\Str::uuid();
                    $this->fsCreate('wallet', [
                        'id'              => ['stringValue'   => $vendorWalletId],
                        'amount'          => ['doubleValue'   => $vendorCreditTotal],
                        'date'            => ['timestampValue' => gmdate('Y-m-d\TH:i:s\Z')],
                        'isTopUp'         => ['booleanValue'  => false],
                        'order_id'        => ['stringValue'   => $orderId],
                        'payment_method'  => ['stringValue'   => 'Wallet'],
                        'payment_status'  => ['stringValue'   => 'success'],
                        'user_id'         => ['stringValue'   => $vendorId],
                        'transactionUser' => ['stringValue'   => 'vendor'],
                        'note'            => ['stringValue'   => 'Order auto-cancelled — amount reversed'],
                    ], $vendorWalletId);
                    \Log::info("[VENDOR_CANCEL] Reversed {$vendorCreditTotal} from vendor {$vendorId} for order {$orderId}");
                }
            }
        }

        $customerFcm = $order['authorDetails']['fcmToken'] ?? '';
        $vendorFcm   = $order['vendor']['fcmToken']        ?? '';
        $shortId     = substr($orderId, -10);
        $body = $reason === 'no driver found'
            ? "Order #{$shortId} cancelled — no driver available."
            : "Order #{$shortId} cancelled — restaurant did not accept.";

        if ($vendorFcm)   $this->sendFcm($vendorFcm,   'Order Cancelled', $body);
        if ($customerFcm) $this->sendFcm($customerFcm, 'Order Cancelled', $body);
    }

    // ════ Firestore helpers (same pattern as CabScheduleRide.php) ═══

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
            \Log::warning("[VENDOR_CANCEL] fsGet $collection/$docId: " . $e->getMessage());
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
            \Log::error("[VENDOR_CANCEL] fsQuery $collection: " . $e->getMessage());
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
                \Log::error("[VENDOR_CANCEL] fsUpdate $collection/$docId status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[VENDOR_CANCEL] fsUpdate $collection/$docId: " . $e->getMessage());
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
                \Log::error("[VENDOR_CANCEL] fsCreate $collection status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error("[VENDOR_CANCEL] fsCreate $collection: " . $e->getMessage());
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

    // Extract Unix timestamp from a Firestore timestamp value (raw or decoded array)
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
            $url  = "https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send";
            $resp = $this->http->post($url, [
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
            ]);
            if ($resp->getStatusCode() !== 200) {
                \Log::error("[VENDOR_CANCEL] FCM error status={$resp->getStatusCode()}");
            }
        } catch (\Throwable $e) {
            \Log::error('[VENDOR_CANCEL] FCM exception: ' . $e->getMessage());
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
