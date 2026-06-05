<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class ParcelScheduleDispatch extends Command
{
    protected $signature   = 'app:parcel-schedule-dispatch';
    protected $description = 'Dispatches parcel orders to available drivers (pure PHP — no Node.js)';

    private string     $projectId;
    private string     $accessToken;
    private HttpClient $http;

    // ════════════════════════════════════════════
    // ENTRY POINT
    // ════════════════════════════════════════════

    public function handle(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            $this->abort('credentials.json not found at storage/app/firebase/credentials.json');
            return;
        }

        try {
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            \Log::info('[PARCEL_DISPATCH] Starting parcel schedule dispatch');

            $this->expireTimedOutPendingOrders();
            $this->dispatchPendingOrders();

            \Log::info('[PARCEL_DISPATCH] Finished');
            $this->consoleInfo('[PARCEL_DISPATCH] Done.');

        } catch (\Throwable $e) {
            \Log::error('[PARCEL_DISPATCH] Fatal: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            $this->consoleError('[PARCEL_DISPATCH] Fatal: ' . $e->getMessage());
        }
    }

    // ════════════════════════════════════════════
    // STEP 1 — Expire drivers that didn't accept in time
    // ════════════════════════════════════════════

    private function expireTimedOutPendingOrders(): void
    {
        $settings       = $this->fsGet('settings', 'DriverNearBy');
        $acceptDuration = (int)($settings['driverOrderAcceptRejectDuration'] ?? 0);
        if ($acceptDuration <= 0) return;

        $orders = $this->fsQuery('parcel_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Driver Pending']],
        ]);

        foreach ($orders as $order) {
            $assignedAt = $order['driverAssignedAt'] ?? null;
            if (!$assignedAt) continue;

            $tsString     = is_array($assignedAt) ? ($assignedAt['timestampValue'] ?? '') : (string)$assignedAt;
            $assignedTime = strtotime($tsString);
            if (!$assignedTime || (time() - $assignedTime) < $acceptDuration) continue;

            $orderId  = $order['id'] ?? '';
            $driverId = $order['driverId'] ?? '';
            $rejected = $order['rejectedByDrivers'] ?? [];

            \Log::info("[PARCEL_DISPATCH] Order #$orderId timed out — driver $driverId did not accept in {$acceptDuration}s");

            if ($driverId) {
                $this->fsUpdate('users', $driverId, [
                    'orderParcelRequestData' => ['nullValue' => null],
                ]);
            }

            if ($driverId && !in_array($driverId, $rejected, true)) {
                $rejected[] = $driverId;
            }

            $this->fsUpdate('parcel_orders', $orderId, [
                'status'            => ['stringValue' => 'Order Accepted'],
                'driverId'          => ['nullValue' => null],
                'driverAssignedAt'  => ['nullValue' => null],
                'rejectedByDrivers' => $this->toFsArray($rejected),
            ]);
        }
    }

    // ════════════════════════════════════════════
    // STEP 2 — Dispatch new / re-dispatch rejected orders
    // ════════════════════════════════════════════

    private function dispatchPendingOrders(): void
    {
        $settings       = $this->fsGet('settings', 'DriverNearBy');
        $acceptDuration = (int)  ($settings['driverOrderAcceptRejectDuration'] ?? 0);
        $radiusMiles    = (float)($settings['driverRadios']                    ?? 50);

        $orders = $this->fsQuery('parcel_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Placed']],
        ]);

        // Also pick up re-dispatchable orders
        $ordersAccepted = $this->fsQuery('parcel_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Accepted']],
        ]);

        $dispatchable = array_merge($orders, $ordersAccepted);

        if (empty($dispatchable)) {
            \Log::info('[PARCEL_DISPATCH] No pending parcel orders found.');
            $this->consoleInfo('[PARCEL_DISPATCH] No pending orders.');
            return;
        }

        \Log::info(sprintf(
            '[PARCEL_DISPATCH] %d order(s) to process. radius=%.0f mi acceptTimeout=%d s',
            count($dispatchable), $radiusMiles, $acceptDuration
        ));

        foreach ($dispatchable as $order) {
            $oId = $order['id'] ?? '?';
            \Log::info("[PARCEL_ORDER_FETCHED] id=$oId status={$order['status']} sectionId={$order['sectionId']}");

            $missing = [];
            if (empty($order['sectionId']))    $missing[] = 'sectionId';
            if (empty($order['senderLatLong'])) $missing[] = 'senderLatLong';
            if (empty($order['status']))        $missing[] = 'status';
            if (!empty($missing)) {
                \Log::warning("[PARCEL_ORDER_MISSING_FIELD] id=$oId missing=" . implode(',', $missing) . " — skipping");
                continue;
            }

            $this->dispatchOrder($order, $acceptDuration, $radiusMiles);
        }
    }

    private function dispatchOrder(array $order, int $acceptDuration, float $radiusMiles): void
    {
        $orderId   = $order['id']       ?? '';
        $sectionId = $order['sectionId'] ?? '';
        $rejected  = $order['rejectedByDrivers'] ?? [];

        \Log::info("[PARCEL_DISPATCH_STARTED_FOR_ORDER] #$orderId status={$order['status']} sectionId=$sectionId");

        $allDriverDocs = $this->fsQuery('users', [
            ['field' => 'role', 'op' => 'EQUAL', 'value' => ['stringValue' => 'driver']],
        ]);

        \Log::info(sprintf('[PARCEL_DRIVER_ONLINE] %d role=driver doc(s) fetched for order #%s', count($allDriverDocs), $orderId));
        \Log::info('[DRIVER_MATCH_START] service=parcel orderId=' . $orderId);

        $seen    = [];
        $drivers = [];
        foreach ($allDriverDocs as $doc) {
            $uid = $doc['id'] ?? $doc['__docId'] ?? '';
            if (empty($uid) || isset($seen[$uid])) continue;
            $seen[$uid] = true;

            $driverRole = (string)($doc['driverRole']   ?? '');
            $types      = (array) ($doc['serviceTypes'] ?? []);
            $typeLegacy = (string)($doc['serviceType']  ?? '');
            $isActive   = ($doc['isActive'] ?? false) === true;

            \Log::info(sprintf(
                '[DRIVER_CANDIDATE] id=%s role=%s isActive=%s serviceTypes=%s sectionIds=%s',
                $uid, $driverRole, $isActive ? 'true' : 'false',
                implode('|', $types),
                implode('|', (array)($doc['sectionIds'] ?? []))
            ));

            if (!$isActive) {
                \Log::info("[DRIVER_REJECT] id=$uid reason=isActive_false");
                continue;
            }

            $hasParcel = $driverRole === 'delivery'
                      || in_array('parcel-service', $types, true)
                      || in_array('parcel_delivery', $types, true)
                      || $typeLegacy === 'parcel-service'
                      || $typeLegacy === 'parcel_delivery';
            if (!$hasParcel) {
                \Log::info("[DRIVER_REJECT] id=$uid reason=no_parcel_service driverRole=$driverRole serviceTypes=" . implode('|', $types));
                continue;
            }

            $drivers[] = $doc;
        }

        \Log::info(sprintf('[PARCEL_DRIVER_ELIGIBLE] %d parcel driver(s) (isActive+service filtered) for order #%s', count($drivers), $orderId));

        foreach ($drivers as $driver) {
            $driverId = $driver['id'] ?? $driver['__docId'] ?? '';
            if (empty($driverId)) continue;

            \Log::info("[PARCEL_DRIVER_EVALUATING] driver=$driverId order=#$orderId");

            // ── Section check ──────────────────────────────────────────────
            $sectionIds = $driver['sectionIds'] ?? [];
            if (empty($sectionIds) && !empty($driver['sectionId'])) {
                $sectionIds = [$driver['sectionId']];
            }
            if (!empty($sectionIds) && !in_array($sectionId, $sectionIds, true)) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_SECTION] driver=$driverId sections=[" . implode(',', $sectionIds) . "] order_section=$sectionId");
                \Log::info("[DRIVER_REJECT] id=$driverId reason=section_mismatch");
                continue;
            }

            // ── Rejected list check ────────────────────────────────────────
            if (in_array($driverId, $rejected, true)) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_REJECTED] driver=$driverId previously rejected order #$orderId");
                continue;
            }

            // ── Availability check ─────────────────────────────────────────
            if (empty($driver['location'])) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_NO_LOCATION] driver=$driverId");
                continue;
            }
            if (!empty($driver['orderParcelRequestData'])) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_BUSY] driver=$driverId — already has orderParcelRequestData");
                continue;
            }
            if (!empty($driver['ordercabRequestData'])) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_BUSY] driver=$driverId — already has ordercabRequestData (on a cab ride)");
                continue;
            }
            if (!empty($driver['inProgressOrderID'])) {
                \Log::info("[PARCEL_DRIVER_SKIPPED_BUSY] driver=$driverId — inProgressOrderID set");
                continue;
            }

            // ── Distance check — uses senderLatLong (pickup) ───────────────
            $src = $order['senderLatLong'] ?? [];
            if (isset($src['geoPointValue'])) {
                $oLat = (float)($src['geoPointValue']['latitude']  ?? 0);
                $oLng = (float)($src['geoPointValue']['longitude'] ?? 0);
            } else {
                $oLat = (float)($src['latitude']  ?? 0);
                $oLng = (float)($src['longitude'] ?? 0);
            }

            $dist = $this->haversineDistanceMiles(
                (float)($driver['location']['latitude']  ?? 0),
                (float)($driver['location']['longitude'] ?? 0),
                $oLat,
                $oLng
            );
            if ($dist >= $radiusMiles) {
                \Log::info(sprintf('[PARCEL_DRIVER_SKIPPED_TOO_FAR] driver=%s dist=%.2f mi radius=%.2f mi', $driverId, $dist, $radiusMiles));
                continue;
            }

            // ── Driver found — assign ──────────────────────────────────────
            \Log::info(sprintf('[PARCEL_DRIVER_SELECTED] driver=%s order=#%s dist=%.2f mi', $driverId, $orderId, $dist));
            \Log::info("[DRIVER_ACCEPT] id=$driverId");
            \Log::info("[DRIVER_FOUND] service=parcel orderId=$orderId driverId=$driverId");

            // Send FCM notification
            $fcmToken = $driver['fcmToken'] ?? '';
            if ($fcmToken) {
                $mins = intdiv($acceptDuration, 60);
                $secs = str_pad($acceptDuration % 60, 2, '0', STR_PAD_LEFT);
                $this->sendFcm($fcmToken, 'Nouvelle demande colis', "Acceptez sous {$mins}:{$secs} min", $orderId, $driverId);
            } else {
                \Log::info("[PARCEL_DRIVER_SELECTED] driver=$driverId has no fcmToken — dispatch via Firestore only");
            }

            // Update parcel order status
            $now = gmdate('Y-m-d\TH:i:s\Z');
            $this->fsUpdate('parcel_orders', $orderId, [
                'status'           => ['stringValue' => 'Driver Pending'],
                'driverId'         => ['stringValue' => $driverId],
                'driverAssignedAt' => ['timestampValue' => $now],
            ]);

            // Build minimal payload and write to driver's user doc
            $parcelPayload = $this->buildParcelRequestData($order);
            $encodedFields = [];
            $badKeys       = [];
            static $dangerKeys = ['arrayValue', 'mapValue'];
            foreach ($parcelPayload as $k => $v) {
                if (is_array($v) && count($v) === 1 && in_array(array_key_first($v), $dangerKeys, true)) {
                    $badKeys[] = $k;
                    continue;
                }
                $encodedFields[$k] = $this->phpToFsValue($v);
            }
            if (!empty($badKeys)) {
                \Log::error("[PARCEL_REQUEST_DATA_BUILT] SKIPPED raw Firestore fields — keys=" . implode(',', $badKeys) . " order=#$orderId");
            }

            $fieldList = implode(',', array_keys($encodedFields));
            \Log::info("[PARCEL_REQUEST_DATA_BUILT] order=#$orderId driver=$driverId fields=$fieldList");
            \Log::info("[FIRESTORE_WRITE] service=parcel collection=users doc=$driverId field=orderParcelRequestData orderId=$orderId");

            $writeOk = $this->fsUpdateWithCheck('users', $driverId, [
                'orderParcelRequestData' => ['mapValue' => ['fields' => $encodedFields]],
            ]);

            if ($writeOk) {
                \Log::info("[PARCEL_REQUEST_DATA_WRITTEN] OK users/$driverId order=#$orderId");
            } else {
                \Log::error("[PARCEL_REQUEST_DATA_WRITTEN] FAILED users/$driverId order=#$orderId");
            }

            \Log::info("[PARCEL_DISPATCH_DONE] Order #$orderId → driver #$driverId");
            \Log::info("[DISPATCH_SUCCESS] service=parcel orderId=$orderId driverId=$driverId firestoreWrite=" . ($writeOk ? '1' : '0'));
            $this->consoleInfo("[PARCEL_DISPATCH] Order #$orderId → driver #$driverId");
            return; // one driver per order per cron tick
        }

        \Log::info(sprintf(
            '[PARCEL_DISPATCH] NO available driver for order #%s — all %d driver(s) skipped',
            $orderId, count($drivers)
        ));
        \Log::info("[DRIVER_FOUND] service=parcel orderId=$orderId driverId=none");
        $this->consoleInfo("[PARCEL_DISPATCH] No driver for #$orderId");
    }

    // ════════════════════════════════════════════
    // HTTP DISPATCH — called immediately when a parcel order is placed
    // ════════════════════════════════════════════

    public function dispatchParcelById(string $parcelOrderId): bool
    {
        \Log::info("[PARCEL_DISPATCH_HTTP_STARTED] parcelOrderId=$parcelOrderId");
        \Log::info("[DISPATCH_START] service=parcel orderId=$parcelOrderId");
        try {
            if (!Storage::disk('local')->has('firebase/credentials.json')) {
                \Log::error('[PARCEL_DISPATCH_HTTP] credentials.json not found');
                return false;
            }
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            try {
                $this->setOutput(new \Symfony\Component\Console\Output\NullOutput());
            } catch (\Throwable $_) {}

            $settings       = $this->fsGet('settings', 'DriverNearBy');
            $acceptDuration = (int)  ($settings['driverOrderAcceptRejectDuration'] ?? 0);
            $radiusMiles    = (float)($settings['driverRadios']                    ?? 50);

            $order = $this->fsGet('parcel_orders', $parcelOrderId);
            if (empty($order)) {
                \Log::info("[PARCEL_DISPATCH_HTTP_NO_ORDER] parcelOrderId=$parcelOrderId — not found");
                return false;
            }

            $status = $order['status'] ?? '';
            \Log::info("[ORDER_LOADED] service=parcel orderId=$parcelOrderId status=$status sectionId=" . ($order['sectionId'] ?? ''));
            if (!in_array($status, ['Order Placed', 'Order Accepted', 'Driver Rejected'], true)) {
                \Log::info("[PARCEL_DISPATCH_HTTP_SKIP] parcelOrderId=$parcelOrderId — status=$status not dispatchable");
                return false;
            }

            if (empty($order['sectionId'])) {
                \Log::warning("[PARCEL_DISPATCH_HTTP_SKIP] parcelOrderId=$parcelOrderId — sectionId missing, cannot find eligible drivers");
                return false;
            }

            $this->dispatchOrder($order, $acceptDuration, $radiusMiles);
            \Log::info("[PARCEL_DISPATCH_HTTP_DONE] parcelOrderId=$parcelOrderId");
            return true;

        } catch (\Throwable $e) {
            \Log::error('[PARCEL_DISPATCH_HTTP] parcelOrderId=' . $parcelOrderId . ': ' . $e->getMessage());
            return false;
        }
    }

    // ════════════════════════════════════════════
    // PARCEL REQUEST DATA BUILDER
    // ════════════════════════════════════════════

    // Builds the minimal flat payload for orderParcelRequestData.
    // Only PHP scalars + two {latitude, longitude} assoc arrays — never raw Firestore typed wrappers.
    private function buildParcelRequestData(array $order): array
    {
        $src = $order['senderLatLong']   ?? [];
        $dst = $order['receiverLatLong'] ?? [];

        if (isset($src['geoPointValue'])) {
            $srcLat = (float)($src['geoPointValue']['latitude']  ?? 0);
            $srcLng = (float)($src['geoPointValue']['longitude'] ?? 0);
        } else {
            $srcLat = (float)($src['latitude']  ?? 0);
            $srcLng = (float)($src['longitude'] ?? 0);
        }

        if (isset($dst['geoPointValue'])) {
            $dstLat = (float)($dst['geoPointValue']['latitude']  ?? 0);
            $dstLng = (float)($dst['geoPointValue']['longitude'] ?? 0);
        } else {
            $dstLat = (float)($dst['latitude']  ?? 0);
            $dstLng = (float)($dst['longitude'] ?? 0);
        }

        $sender   = $order['sender']   ?? [];
        $receiver = $order['receiver'] ?? [];

        return [
            'id'              => (string)($order['id']             ?? ''),
            'status'          => (string)($order['status']         ?? 'Order Placed'),
            'sectionId'       => (string)($order['sectionId']      ?? ''),
            'authorID'        => (string)($order['authorID']       ?? ''),
            'subTotal'        => (float) ($order['subTotal']        ?? 0),
            'paymentMethod'   => (string)($order['payment_method'] ?? $order['paymentMethod'] ?? ''),
            'senderAddress'   => (string)($sender['address']       ?? ''),
            'senderName'      => (string)($sender['name']          ?? ''),
            'senderPhone'     => (string)($sender['phone']         ?? ''),
            'receiverAddress' => (string)($receiver['address']     ?? ''),
            'receiverName'    => (string)($receiver['name']        ?? ''),
            'receiverPhone'   => (string)($receiver['phone']       ?? ''),
            'senderLatLong'   => ['latitude' => $srcLat, 'longitude' => $srcLng],
            'receiverLatLong' => ['latitude' => $dstLat, 'longitude' => $dstLng],
        ];
    }

    // ════════════════════════════════════════════
    // FCM
    // ════════════════════════════════════════════

    private function sendFcm(string $token, string $title, string $body, string $orderId, ?string $driverId = null): void
    {
        try {
            \Log::info("[FCM_SEND] service=parcel orderId=$orderId driverId=" . ($driverId ?? '') . " token=" . substr($token, 0, 20) . '...');
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
                        'data'         => ['type' => 'parcel_order_request', 'orderId' => $orderId],
                    ],
                ],
            ]);
            $statusCode = $resp->getStatusCode();
            $respBody   = (string)$resp->getBody();
            \Log::info("[PARCEL_FCM_SENT] status=$statusCode order=$orderId body=$respBody");
            if ($statusCode !== 200) {
                \Log::error("[PARCEL_FCM_ERROR] status=$statusCode body=$respBody");
                $this->handleInvalidFcmToken($respBody, $driverId, 'PARCEL_FCM');
            }
        } catch (\Throwable $e) {
            \Log::error('[PARCEL_FCM_EXCEPTION] ' . $e->getMessage());
        }
    }

    // ════════════════════════════════════════════
    // FIRESTORE REST HELPERS (identical to CabScheduleRide)
    // ════════════════════════════════════════════

    private function fsBaseUrl(): string
    {
        return "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";
    }

    private function fsGet(string $collection, string $docId): array
    {
        try {
            $url  = "{$this->fsBaseUrl()}/{$collection}/{$docId}";
            $resp = $this->http->get($url, [
                'headers' => ['Authorization' => 'Bearer ' . $this->accessToken],
            ]);
            if ($resp->getStatusCode() !== 200) return [];
            $body    = json_decode((string)$resp->getBody(), true);
            $decoded = $this->decodeDoc($body);
            $decoded['__rawFields'] = $body['fields'] ?? [];
            return $decoded;
        } catch (\Throwable $e) {
            \Log::warning("[PARCEL_DISPATCH] fsGet $collection/$docId: " . $e->getMessage());
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

            $url  = "{$this->fsBaseUrl()}:runQuery";
            $resp = $this->http->post($url, [
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

            $statusCode = $resp->getStatusCode();
            $rawBody    = (string)$resp->getBody();

            if ($statusCode !== 200) {
                \Log::error("[PARCEL_DISPATCH] fsQuery $collection HTTP $statusCode — body=$rawBody");
                return [];
            }

            $rows    = json_decode($rawBody, true) ?? [];
            $results = [];
            foreach ($rows as $row) {
                if (!empty($row['document'])) {
                    $decoded = $this->decodeDoc($row['document']);
                    $decoded['__rawFields'] = $row['document']['fields'] ?? [];
                    $docName = $row['document']['name'] ?? '';
                    $decoded['__docId'] = $docName ? basename($docName) : '';
                    $results[] = $decoded;
                }
            }
            return $results;
        } catch (\Throwable $e) {
            \Log::error("[PARCEL_DISPATCH] fsQuery $collection: " . $e->getMessage());
            return [];
        }
    }

    private function fsUpdate(string $collection, string $docId, array $typedFields): void
    {
        $this->fsUpdateWithCheck($collection, $docId, $typedFields);
    }

    private function fsUpdateWithCheck(string $collection, string $docId, array $typedFields): bool
    {
        if (empty($docId)) {
            \Log::warning("[PARCEL_DISPATCH] fsUpdate $collection: empty docId — skipped");
            return false;
        }
        try {
            $maskParams = implode('&', array_map(
                fn($k) => 'updateMask.fieldPaths=' . urlencode($k),
                array_keys($typedFields)
            ));
            $url  = "{$this->fsBaseUrl()}/{$collection}/{$docId}?{$maskParams}";
            $resp = $this->http->patch($url, [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->accessToken,
                    'Content-Type'  => 'application/json',
                ],
                'json' => ['fields' => $typedFields],
            ]);
            $code = $resp->getStatusCode();
            if ($code !== 200) {
                \Log::error("[PARCEL_DISPATCH] fsUpdate $collection/$docId HTTP $code — body=" . $resp->getBody());
                return false;
            }
            return true;
        } catch (\Throwable $e) {
            \Log::error("[PARCEL_DISPATCH] fsUpdate $collection/$docId: " . $e->getMessage());
            return false;
        }
    }

    // ════════════════════════════════════════════
    // FIRESTORE TYPE CODEC (identical to CabScheduleRide)
    // ════════════════════════════════════════════

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
            $values = $v['arrayValue']['values'] ?? [];
            return array_map(fn($item) => $this->decodeFsValue($item), $values);
        }
        if (array_key_exists('mapValue', $v)) {
            return $this->decodeDoc(['fields' => $v['mapValue']['fields'] ?? []]);
        }
        return null;
    }

    private function phpToFsValue(mixed $value): array
    {
        if (is_null($value))   return ['nullValue' => null];
        if (is_bool($value))   return ['booleanValue' => $value];
        if (is_int($value))    return ['integerValue' => (string)$value];
        if (is_float($value))  return ['doubleValue'  => $value];
        if (is_string($value)) return ['stringValue'  => $value];

        if (is_array($value)) {
            static $typeKeys = [
                'stringValue', 'integerValue', 'doubleValue', 'booleanValue',
                'nullValue', 'timestampValue', 'arrayValue', 'mapValue',
                'geoPointValue', 'referenceValue', 'bytesValue',
            ];
            if (count($value) === 1) {
                $k = array_key_first($value);
                if (in_array($k, $typeKeys, true)) return $value;
            }

            if (array_keys($value) === range(0, count($value) - 1)) {
                return ['arrayValue' => [
                    'values' => array_map(fn($v) => $this->phpToFsValue($v), $value),
                ]];
            }

            $fields = [];
            foreach ($value as $k => $v) {
                $fields[(string)$k] = $this->phpToFsValue($v);
            }
            return ['mapValue' => ['fields' => $fields ?: (object)[]]];
        }

        return ['nullValue' => null];
    }

    private function toFsArray(array $items): array
    {
        return ['arrayValue' => [
            'values' => array_map(fn($v) => $this->phpToFsValue($v), $items),
        ]];
    }

    // ════════════════════════════════════════════
    // OAUTH2
    // ════════════════════════════════════════════

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

    // ════════════════════════════════════════════
    // GEOMETRY (identical to CabScheduleRide)
    // ════════════════════════════════════════════

    private function haversineDistanceMiles(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        if ($lat1 === $lat2 && $lon1 === $lon2) return 0.0;
        $radLat1 = deg2rad($lat1);
        $radLat2 = deg2rad($lat2);
        $theta   = $lon1 - $lon2;
        $dist    = sin($radLat1) * sin($radLat2)
                 + cos($radLat1) * cos($radLat2) * cos(deg2rad($theta));
        $dist    = min(1.0, max(-1.0, $dist));
        return acos($dist) * (180 / M_PI) * 60 * 1.1515;
    }

    // ════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════

    private function abort(string $msg): void
    {
        \Log::error('[PARCEL_DISPATCH] ' . $msg);
        $this->consoleError('[PARCEL_DISPATCH] ' . $msg);
    }

    private function consoleInfo(string $message): void
    {
        try {
            if ($this->output) {
                parent::info($message);
            }
        } catch (\Throwable $e) {
            \Log::info($message);
        }
    }

    private function consoleError(string $message): void
    {
        try {
            if ($this->output) {
                parent::error($message);
            }
        } catch (\Throwable $e) {
            \Log::error($message);
        }
    }

    private function handleInvalidFcmToken(string $responseBody, ?string $driverId, string $logPrefix): void
    {
        if (!$driverId) {
            return;
        }

        $decoded = json_decode($responseBody, true);
        $bodyContainsUnregistered = str_contains($responseBody, 'UNREGISTERED');
        $errorCode = $decoded['error']['details'][0]['errorCode'] ?? $decoded['error']['status'] ?? null;

        if ($bodyContainsUnregistered || $errorCode === 'UNREGISTERED') {
            \Log::warning("[FCM_INVALID_TOKEN] service=parcel driverId=$driverId reason=UNREGISTERED; clearing token and keeping dispatch request");
            $this->fsUpdate('users', $driverId, [
                'fcmToken' => ['nullValue' => null],
            ]);
        }
    }
}
