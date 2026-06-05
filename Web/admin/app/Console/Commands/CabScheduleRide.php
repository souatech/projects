<?php

namespace App\Console\Commands;

use GuzzleHttp\Client as HttpClient;
use GuzzleHttp\Exception\RequestException;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use Google\Client as GoogleClient;

class CabScheduleRide extends Command
{
    protected $signature   = 'app:cab-schedule-ride';
    protected $description = 'Dispatches cab orders to available drivers (pure PHP — no Node.js)';

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

            \Log::info('[CAB_DISPATCH] Starting cab schedule ride');

            $this->expireTimedOutPendingOrders();
            $this->dispatchPendingOrders();

            \Log::info('[CAB_DISPATCH] Finished');
            $this->consoleInfo('[CAB_DISPATCH] Done.');

        } catch (\Throwable $e) {
            \Log::error('[CAB_DISPATCH] Fatal: ' . $e->getMessage() . "\n" . $e->getTraceAsString());
            $this->consoleError('[CAB_DISPATCH] Fatal: ' . $e->getMessage());
        }
    }

    // ════════════════════════════════════════════
    // STEP 1 — Expire drivers that didn't accept in time
    // ════════════════════════════════════════════

    private function expireTimedOutPendingOrders(): void
    {
        $settings        = $this->fsGet('settings', 'DriverNearBy');
        $acceptDuration  = (int)($settings['driverOrderAcceptRejectDuration'] ?? 0);
        if ($acceptDuration <= 0) return;

        $rides = $this->fsQuery('rides', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Driver Pending']],
        ]);

        foreach ($rides as $order) {
            $assignedAt = $order['driverAssignedAt'] ?? null;
            if (!$assignedAt) continue;

            // driverAssignedAt was stored as a Firestore timestamp; we keep it as ['timestampValue'=>'...']
            $tsString = is_array($assignedAt) ? ($assignedAt['timestampValue'] ?? '') : (string)$assignedAt;
            $assignedTime = strtotime($tsString);
            if (!$assignedTime || (time() - $assignedTime) < $acceptDuration) continue;

            $orderId  = $order['id'] ?? '';
            $driverId = $order['driverId'] ?? '';
            $rejected = $order['rejectedByDrivers'] ?? [];

            \Log::info("[CAB_DISPATCH] Order #$orderId timed out — driver $driverId did not accept in {$acceptDuration}s");

            if ($driverId) {
                $this->fsUpdate('users', $driverId, [
                    'ordercabRequestData' => ['nullValue' => null],
                ]);
            }

            if ($driverId && !in_array($driverId, $rejected, true)) {
                $rejected[] = $driverId;
            }

            $this->fsUpdate('rides', $orderId, [
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
        $minWallet      = (float)($settings['minimumDepositToRideAccept']      ?? 0);
        $acceptDuration = (int)  ($settings['driverOrderAcceptRejectDuration'] ?? 0);
        $radiusMiles    = (float)($settings['driverRadios']                    ?? 50);

        if ($minWallet > 0) {
            \Log::warning("[CAB_DISPATCH] minimumDepositToRideAccept=$minWallet — drivers with wallet=0 will be SKIPPED. Set to 0 in Firestore settings/DriverNearBy for COD-first systems.");
        }

        // All rides where scheduleDateTime <= now
        $rides = $this->fsQuery('rides', [
            [
                'field' => 'scheduleDateTime',
                'op'    => 'LESS_THAN_OR_EQUAL',
                'value' => ['timestampValue' => gmdate('Y-m-d\TH:i:s\Z')],
            ],
        ]);

        $dispatchable = array_filter(
            $rides,
            fn($r) => in_array($r['status'] ?? '', ['Order Placed', 'Order Accepted', 'Driver Rejected'], true)
        );

        if (empty($dispatchable)) {
            \Log::info('[DISPATCH_STARTED] No pending rides found.');
            $this->consoleInfo('[DISPATCH_STARTED] No pending rides.');
            return;
        }

        \Log::info(sprintf(
            '[DISPATCH_STARTED] %d ride(s) to process. radius=%.0f mi acceptTimeout=%d s',
            count($dispatchable), $radiusMiles, $acceptDuration
        ));

        foreach ($dispatchable as $order) {
            $oId  = $order['id'] ?? '?';
            $oSrc = ($order['sourceLocation']['latitude'] ?? '?') . ',' . ($order['sourceLocation']['longitude'] ?? '?');
            $oDst = ($order['destinationLocation']['latitude'] ?? '?') . ',' . ($order['destinationLocation']['longitude'] ?? '?');
            \Log::info("[CAB_RIDE_FETCHED] id=$oId status={$order['status']} sectionId={$order['sectionId']} vehicleId={$order['vehicleId']} rideType={$order['rideType']} src=$oSrc dst=$oDst");
            $missing = [];
            if (empty($order['sectionId'])) $missing[] = 'sectionId';
            if (empty($order['sourceLocation'])) $missing[] = 'sourceLocation';
            if (empty($order['status'])) $missing[] = 'status';
            if (!empty($missing)) {
                \Log::warning("[CAB_RIDE_MISSING_FIELD] id=$oId missing=" . implode(',', $missing));
            } else {
                \Log::info("[CAB_RIDE_FIELD_CHECK] id=$oId all required fields present");
            }
            \Log::info("[CAB_DISPATCH_STARTED_FOR_RIDE] id=$oId");
            $this->dispatchOrder($order, $minWallet, $acceptDuration, $radiusMiles);
        }
    }

    private function dispatchOrder(array $order, float $minWallet, int $acceptDuration, float $radiusMiles): void
    {
        $orderId  = $order['id']       ?? '';
        $sectionId = $order['sectionId'] ?? '';
        $vehicleId = $order['vehicleId'] ?? '';
        $rideType  = $order['rideType']  ?? '';
        $rejected  = $order['rejectedByDrivers'] ?? [];

        \Log::info("[ORDER_CREATED] #$orderId status={$order['status']} sectionId=$sectionId vehicleId=$vehicleId rideType=$rideType");

        // Single-field query only — no composite index required.
        // isActive + serviceTypes filters are applied client-side below.
        $allDriverDocs = $this->fsQuery('users', [
            ['field' => 'role', 'op' => 'EQUAL', 'value' => ['stringValue' => 'driver']],
        ]);

        \Log::info(sprintf('[DRIVER_ONLINE] %d role=driver doc(s) fetched for order #%s — will filter isActive + service client-side', count($allDriverDocs), $orderId));
        \Log::info('[DRIVER_MATCH_START] service=cab orderId=' . $orderId);

        $seen    = [];
        $drivers = [];
        foreach ($allDriverDocs as $doc) {
            $uid = $doc['id'] ?? $doc['__docId'] ?? '';
            if (empty($uid) || isset($seen[$uid])) continue;
            $seen[$uid] = true;

            $driverRole    = (string)($doc['driverRole']   ?? '');
            $types         = (array) ($doc['serviceTypes'] ?? []);
            $typeLegacy    = (string)($doc['serviceType']  ?? '');
            $isActiveRaw   = $doc['isActive'] ?? false;
            // Accept both bool true and int 1 — Firestore may store either depending on client
            $isActive      = $isActiveRaw === true || $isActiveRaw === 1;

            $inProgressRaw = $doc['inProgressOrderID'] ?? null;
            $inProgressStr = is_array($inProgressRaw) ? implode(',', $inProgressRaw) : (string)($inProgressRaw ?? '');
            $rawType       = is_bool($isActiveRaw)
                ? ($isActiveRaw ? 'bool:true' : 'bool:false')
                : (gettype($isActiveRaw) . ':' . var_export($isActiveRaw, true));

            \Log::info(sprintf(
                '[DRIVER_CANDIDATE] id=%s role=%s isActiveRaw=%s isActive=%s serviceTypes=%s sectionIds=%s inProgressOrderID=%s hasLocation=%s',
                $uid, $driverRole,
                $rawType,
                $isActive ? 'true' : 'false',
                implode('|', $types),
                implode('|', (array)($doc['sectionIds'] ?? [])),
                $inProgressStr ?: 'empty',
                empty($doc['location']) ? 'no' : 'yes'
            ));

            if (!$isActive) {
                \Log::info("[DRIVER_REJECT] id=$uid reason=isActive_false rawType=$rawType");
                continue;
            }

            // cab_rental is Rental-only in V1 — CAB dispatch matches driverRole=cab only
            $hasCab = $driverRole === 'cab'
                   || in_array('cab-service', $types, true)
                   || in_array('Cab Service', $types, true)
                   || $typeLegacy === 'cab-service';
            if (!$hasCab) {
                \Log::info("[DRIVER_REJECT] id=$uid reason=no_cab_service driverRole=$driverRole serviceTypes=" . implode('|', $types));
                continue;
            }

            $drivers[] = $doc;
        }

        \Log::info(sprintf('[DRIVER_ONLINE] %d eligible cab driver(s) (isActive+service filtered) for order #%s', count($drivers), $orderId));

        foreach ($drivers as $driver) {
            $driverId = $driver['id'] ?? $driver['__docId'] ?? '';
            if (empty($driverId)) {
                \Log::warning("[CAB_DRIVER_EVALUATING] driver has no id field and no __docId — skipping (doc name resolution failed)");
                continue;
            }
            \Log::info("[CAB_DRIVER_EVALUATING] driver=$driverId order=#$orderId");

            // ── Section check ──────────────────────────────────────────────
            $sectionIds = $driver['sectionIds'] ?? [];
            if (empty($sectionIds) && !empty($driver['sectionId'])) {
                $sectionIds = [$driver['sectionId']];
            }
            if (!empty($sectionIds) && !in_array($sectionId, $sectionIds, true)) {
                \Log::info("[DRIVER_SKIPPED_SECTION] driver=$driverId sections=[" . implode(',', $sectionIds) . "] order_section=$sectionId");
                \Log::info("[DRIVER_REJECT] id=$driverId reason=section_mismatch");
                continue;
            }

            // ── Vehicle check (Option A — soft launch) ─────────────────────
            // If the driver has no vehicleDetails for this section, let them through.
            // If vehicleDetails exist AND the order specifies a vehicleId, they must match.
            $vehicleDetails = $driver['vehicleDetails'] ?? [];
            $sectionVehicle = $vehicleDetails[$sectionId] ?? null;
            if ($sectionVehicle === null) {
                \Log::info("[DRIVER_NO_VEHICLE_FOR_SECTION] driver=$driverId section=$sectionId — soft-launch: allowing through");
            } elseif (!empty($vehicleId) && ($sectionVehicle['vehicleId'] ?? '') !== $vehicleId) {
                \Log::info("[DRIVER_SKIPPED_NO_VEHICLE_FOR_SECTION] driver=$driverId order_vehicle=$vehicleId driver_vehicle=" . ($sectionVehicle['vehicleId'] ?? 'none'));
                continue;
            }

            // ── Ride type check ────────────────────────────────────────────
            // Soft launch: if no rideType info available, accept any ride type.
            $driverRideType = $sectionVehicle !== null ? ($sectionVehicle['rideType'] ?? ($driver['rideType'] ?? '')) : ($driver['rideType'] ?? '');
            if (!empty($driverRideType) && $driverRideType !== 'both' && !empty($rideType) && $driverRideType !== $rideType) {
                \Log::info("[DRIVER_SKIPPED_RIDETYPE] driver=$driverId driver_type=$driverRideType order_type=$rideType");
                continue;
            }

            // ── Rejected list check ────────────────────────────────────────
            if (in_array($driverId, $rejected, true)) {
                \Log::info("[DRIVER_SKIPPED_REJECTED] driver=$driverId previously rejected order #$orderId");
                continue;
            }

            // ── Wallet check ───────────────────────────────────────────────
            // Dual-read: Flutter SDK peut écrire walletAmount (camelCase) ou wallet_amount (snake_case)
            $wallet = (float)($driver['wallet_amount'] ?? $driver['walletAmount'] ?? 0);
            if (!empty($driver['ownerId'])) {
                $owner       = $this->fsGet('users', $driver['ownerId']);
                $ownerWallet = (float)($owner['wallet_amount'] ?? $owner['walletAmount'] ?? 0);
                $wallet      = max($wallet, $ownerWallet);
            }
            if ($wallet < $minWallet) {
                \Log::info("[DRIVER_SKIPPED_WALLET_MINIMUM] driver=$driverId wallet=$wallet min=$minWallet");
                continue;
            }

            // ── Availability check ─────────────────────────────────────────
            if (empty($driver['location'])) {
                \Log::info("[DRIVER_SKIPPED_NO_LOCATION] driver=$driverId — location field empty");
                continue;
            }
            if (!empty($driver['ordercabRequestData'])) {
                \Log::info("[DRIVER_SKIPPED_BUSY] driver=$driverId — already has ordercabRequestData");
                continue;
            }
            if (!empty($driver['inProgressOrderID'])) {
                \Log::info("[DRIVER_SKIPPED_BUSY] driver=$driverId — inProgressOrderID set");
                continue;
            }
            if (!empty($driver['orderRequestData'])) {
                \Log::info("[DRIVER_SKIPPED_BUSY] driver=$driverId — has pending orderRequestData");
                continue;
            }

            // ── Zone check (advisory — distance is authoritative for MVP) ──────
            if (!empty($driver['zoneId'])) {
                $zone = $this->fsGet('zone', $driver['zoneId']);
                if ($zone) {
                    $area  = $zone['area'] ?? [];
                    $vertx = array_column($area, 'longitude');
                    $verty = array_column($area, 'latitude');
                    $dLat  = (float)($driver['location']['latitude']          ?? 0);
                    $dLng  = (float)($driver['location']['longitude']         ?? 0);
                    $oLat  = (float)($order['sourceLocation']['latitude']     ?? 0);
                    $oLng  = (float)($order['sourceLocation']['longitude']    ?? 0);
                    if (!$this->isInPolygon($vertx, $verty, $dLng, $dLat) ||
                        !$this->isInPolygon($vertx, $verty, $oLng, $oLat)) {
                        \Log::warning("[CAB_DRIVER_SKIPPED_ZONE] driver=$driverId zone={$driver['zoneId']} polygon mismatch — soft-launch: continuing to distance check");
                        // MVP: zone polygon is advisory. Remove once zones are correctly configured.
                    }
                }
            }

            // ── Distance check ─────────────────────────────────────────────
            $dist = $this->haversineDistanceMiles(
                (float)($driver['location']['latitude']       ?? 0),
                (float)($driver['location']['longitude']      ?? 0),
                (float)($order['sourceLocation']['latitude']  ?? 0),
                (float)($order['sourceLocation']['longitude'] ?? 0)
            );
            if ($dist >= $radiusMiles) {
                \Log::info(sprintf('[DRIVER_SKIPPED_TOO_FAR] driver=%s dist=%.2f mi radius=%.2f mi', $driverId, $dist, $radiusMiles));
                continue;
            }

            // ── Driver found — assign ──────────────────────────────────────
            \Log::info(sprintf('[CAB_DRIVER_SELECTED] driver=%s order=#%s dist=%.2f mi vehicle=%s rideType=%s', $driverId, $orderId, $dist, $sectionVehicle['vehicleId'] ?? 'any', $driverRideType ?: 'any'));
            \Log::info("[DRIVER_ACCEPT] id=$driverId");
            \Log::info("[DRIVER_FOUND] service=cab orderId=$orderId driverId=$driverId");

            // Send FCM
            $fcmToken = $driver['fcmToken'] ?? '';
            if ($fcmToken) {
                \Log::info('[FCM_TOKEN_FOUND] driver=' . $driverId . ' token=' . substr($fcmToken, 0, 20) . '...');
                $mins = intdiv($acceptDuration, 60);
                $secs = str_pad($acceptDuration % 60, 2, '0', STR_PAD_LEFT);
                $this->sendFcm(
                    $fcmToken,
                    'New ride request received',
                    "Please accept in {$mins}:{$secs} mins",
                    $orderId,
                    $driverId
                );
            } else {
                \Log::info("[FCM_TOKEN_FOUND] MISSING — driver $driverId has no fcmToken — dispatch via Firestore only");
            }

            // Update Firestore
            $now = gmdate('Y-m-d\TH:i:s\Z');

            $this->fsUpdate('rides', $orderId, [
                'status'           => ['stringValue' => 'Driver Pending'],
                'driverId'         => ['stringValue' => $driverId],
                'driverAssignedAt' => ['timestampValue' => $now],
            ]);

            // Build a minimal clean payload and encode exactly once via phpToFsValue.
            // Guard: skip any field whose decoded value is already a Firestore-typed wrapper
            // (arrayValue / mapValue) — that means decodeDoc left it raw and a second pass
            // would produce double-encoded JSON that Firestore REST rejects with HTTP 400.
            $cabPayload    = $this->buildCabRequestData($order);
            $encodedFields = [];
            $badKeys       = [];
            static $dangerKeys = ['arrayValue', 'mapValue'];
            foreach ($cabPayload as $k => $v) {
                if (is_array($v) && count($v) === 1 && in_array(array_key_first($v), $dangerKeys, true)) {
                    $badKeys[] = $k;
                    continue;
                }
                $encodedFields[$k] = $this->phpToFsValue($v);
            }
            if (!empty($badKeys)) {
                \Log::error("[CAB_REQUEST_DATA_WRITTEN] SKIPPED raw Firestore fields in payload — keys=" . implode(',', $badKeys) . " order=#$orderId (fix buildCabRequestData)");
            }

            $fieldList = implode(',', array_keys($encodedFields));
            \Log::info("[CAB_REQUEST_DATA_BUILT] order=#$orderId driver=$driverId fields=$fieldList");
            \Log::info("[FIRESTORE_WRITE] service=cab collection=users doc=$driverId field=ordercabRequestData orderId=$orderId");

            $writeOk = $this->fsUpdateWithCheck('users', $driverId, [
                'ordercabRequestData' => ['mapValue' => ['fields' => $encodedFields]],
            ]);

            if ($writeOk) {
                \Log::info("[CAB_REQUEST_DATA_WRITTEN] OK users/$driverId order=#$orderId fields=$fieldList");
            } else {
                \Log::error("[CAB_REQUEST_DATA_WRITTEN] FAILED users/$driverId order=#$orderId");
            }
            \Log::info("[CAB_DISPATCH_DONE] Order #$orderId → driver #$driverId (Firestore updated)");
            \Log::info("[DISPATCH_SUCCESS] service=cab orderId=$orderId driverId=$driverId firestoreWrite=" . ($writeOk ? '1' : '0'));
            $this->consoleInfo("[DISPATCH_STARTED] Order #$orderId → driver #$driverId");
            return; // one driver per order per cron tick
        }

        \Log::info(sprintf(
            '[DRIVER_FOUND] NO available driver for order #%s — all %d driver(s) skipped',
            $orderId, count($drivers)
        ));
        \Log::info("[DRIVER_FOUND] service=cab orderId=$orderId driverId=none");
        $this->consoleInfo("[DRIVER_FOUND] No driver for #$orderId");
    }

    // ════════════════════════════════════════════
    // FCM
    // ════════════════════════════════════════════

    private function sendFcm(string $token, string $title, string $body, string $orderId, ?string $driverId = null): void
    {
        try {
            \Log::info("[FCM_SEND] service=cab orderId=$orderId driverId=" . ($driverId ?? '') . " token=" . substr($token, 0, 20) . '...');
            \Log::info("[FCM_PAYLOAD_BUILT] order=$orderId token=" . substr($token, 0, 20) . '...');

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
                        'data'         => ['type' => 'cab_ride_request', 'orderId' => $orderId],
                    ],
                ],
            ]);

            $statusCode = $resp->getStatusCode();
            $respBody   = (string)$resp->getBody();
            \Log::info("[FCM_SENT] status=$statusCode body=$respBody");

            if ($statusCode !== 200) {
                \Log::error("[FCM_RESPONSE] ERROR status=$statusCode body=$respBody");
                $this->handleInvalidFcmToken($respBody, $driverId, 'CAB_FCM');
            }
        } catch (\Throwable $e) {
            \Log::error('[FCM_RESPONSE] EXCEPTION: ' . $e->getMessage());
        }
    }

    // ════════════════════════════════════════════
    // FIRESTORE REST HELPERS
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
            \Log::warning("[CAB_DISPATCH] fsGet $collection/$docId: " . $e->getMessage());
            return [];
        }
    }

    // ════════════════════════════════════════════
    // HTTP DISPATCH — called immediately when a ride is placed
    // ════════════════════════════════════════════

    public function dispatchRideById(string $rideId): bool
    {
        \Log::info("[CAB_DISPATCH_HTTP_STARTED] rideId=$rideId");
        \Log::info("[DISPATCH_START] service=cab orderId=$rideId");
        try {
            if (!Storage::disk('local')->has('firebase/credentials.json')) {
                \Log::error('[CAB_DISPATCH_HTTP] credentials.json not found');
                return false;
            }
            $credJson          = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
            $this->projectId   = $credJson['project_id'] ?? '';
            $this->accessToken = $this->getAccessToken();
            $this->http        = new HttpClient(['timeout' => 30, 'http_errors' => false]);

            // Silence console output — called from HTTP context, not Artisan
            try {
                $this->setOutput(new \Symfony\Component\Console\Output\NullOutput());
            } catch (\Throwable $_) {}

            $settings       = $this->fsGet('settings', 'DriverNearBy');
            $minWallet      = (float)($settings['minimumDepositToRideAccept']      ?? 0);
            $acceptDuration = (int)  ($settings['driverOrderAcceptRejectDuration'] ?? 0);
            $radiusMiles    = (float)($settings['driverRadios']                    ?? 50);

            $order = $this->fsGet('rides', $rideId);
            if (empty($order)) {
                \Log::info("[CAB_DISPATCH_HTTP_NO_DRIVER] rideId=$rideId — ride not found");
                return false;
            }

            $status = $order['status'] ?? '';
            \Log::info("[ORDER_LOADED] service=cab orderId=$rideId status=$status sectionId=" . ($order['sectionId'] ?? ''));
            if (!in_array($status, ['Order Placed', 'Order Accepted', 'Driver Rejected'], true)) {
                \Log::info("[CAB_DISPATCH_HTTP_NO_DRIVER] rideId=$rideId — status=$status not dispatchable");
                return false;
            }

            $this->dispatchOrder($order, $minWallet, $acceptDuration, $radiusMiles);
            \Log::info("[CAB_DISPATCH_HTTP_DONE] rideId=$rideId");
            return true;

        } catch (\Throwable $e) {
            \Log::error('[CAB_DISPATCH_HTTP] rideId=' . $rideId . ': ' . $e->getMessage());
            return false;
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
                \Log::error("[CAB_DISPATCH] fsQuery $collection HTTP $statusCode — body=$rawBody — likely missing Firestore composite index or auth error");
                return [];
            }

            $rows    = json_decode($rawBody, true) ?? [];
            $results = [];
            foreach ($rows as $row) {
                if (!empty($row['document'])) {
                    $decoded = $this->decodeDoc($row['document']);
                    // Stash raw Firestore-typed fields so dispatchOrder can write them back
                    // without a lossy decode → re-encode roundtrip.
                    $decoded['__rawFields'] = $row['document']['fields'] ?? [];
                    // Fallback doc ID from document name path (used if 'id' field is absent).
                    $docName = $row['document']['name'] ?? '';
                    $decoded['__docId'] = $docName ? basename($docName) : '';
                    $results[] = $decoded;
                }
            }
            return $results;
        } catch (\Throwable $e) {
            \Log::error("[CAB_DISPATCH] fsQuery $collection: " . $e->getMessage());
            return [];
        }
    }

    // ════════════════════════════════════════════
    // CAB REQUEST DATA BUILDER
    // ════════════════════════════════════════════

    // Builds the minimal flat payload for ordercabRequestData.
    // ONLY plain PHP scalars + two {latitude, longitude} maps — never raw Firestore-typed fields.
    // phpToFsValue() encodes the result exactly once; a second pass would produce double-encoded
    // arrayValue / mapValue wrappers which Firestore REST rejects with HTTP 400.
    private function buildCabRequestData(array $order): array
    {
        // sourceLocation / destinationLocation may come back as a decoded assoc array
        // ['latitude' => float, 'longitude' => float] or, if stored as a Firestore geoPointValue,
        // as ['geoPointValue' => ['latitude' => float, 'longitude' => float]].
        // In both cases we extract plain floats — never pass the raw typed wrapper downstream.
        $src = $order['sourceLocation'] ?? [];
        $dst = $order['destinationLocation'] ?? [];

        $srcLat = (float)($src['latitude']  ?? $src['geoPointValue']['latitude']  ?? 0);
        $srcLng = (float)($src['longitude'] ?? $src['geoPointValue']['longitude'] ?? 0);
        $dstLat = (float)($dst['latitude']  ?? $dst['geoPointValue']['latitude']  ?? 0);
        $dstLng = (float)($dst['longitude'] ?? $dst['geoPointValue']['longitude'] ?? 0);

        // authorID is always a plain string scalar after decodeDoc.
        $authorId   = (string)($order['authorID'] ?? $order['author']['id'] ?? '');
        $authorName = '';
        if (!empty($order['author']['restaurantName'])) {
            $authorName = (string)$order['author']['restaurantName'];
        } elseif (!empty($order['author']['firstName'])) {
            $authorName = trim(
                (string)($order['author']['firstName'] ?? '') . ' ' .
                (string)($order['author']['lastName']  ?? '')
            );
        }

        // Every value here is a PHP scalar or a two-key assoc array of floats.
        // NO author object, NO arrays, NO Firestore typed wrappers.
        return [
            'id'                  => (string)($order['id']                      ?? ''),
            'rideId'              => (string)($order['id']                      ?? ''),
            'status'              => (string)($order['status']                  ?? 'Order Placed'),
            'sectionId'           => (string)($order['sectionId']               ?? ''),
            'vehicleId'           => (string)($order['vehicleId']               ?? ''),
            'rideType'            => (string)($order['rideType']                ?? 'ride'),
            'sourceName'          => (string)($order['sourceLocationName']      ?? ''),
            'destinationName'     => (string)($order['destinationLocationName'] ?? ''),
            'sourceLocation'      => ['latitude' => $srcLat, 'longitude' => $srcLng],
            'destinationLocation' => ['latitude' => $dstLat, 'longitude' => $dstLng],
            'customerId'          => $authorId,
            'customerName'        => $authorName,
            'price'               => (float)($order['subTotal']                 ?? 0),
        ];
    }

    private function fsUpdate(string $collection, string $docId, array $typedFields): void
    {
        $this->fsUpdateWithCheck($collection, $docId, $typedFields);
    }

    private function fsUpdateWithCheck(string $collection, string $docId, array $typedFields): bool
    {
        if (empty($docId)) {
            \Log::warning("[CAB_DISPATCH] fsUpdate $collection: empty docId — skipped");
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
                $sentJson = json_encode(['fields' => $typedFields]);
                \Log::error("[CAB_DISPATCH] fsUpdate $collection/$docId HTTP $code — body=" . $resp->getBody());
                \Log::error("[CAB_DISPATCH] fsUpdate $collection/$docId sent_len=" . strlen($sentJson) . " sent=" . substr($sentJson, 0, 3000));
                return false;
            }
            return true;
        } catch (\Throwable $e) {
            \Log::error("[CAB_DISPATCH] fsUpdate $collection/$docId: " . $e->getMessage());
            return false;
        }
    }

    // ════════════════════════════════════════════
    // FIRESTORE TYPE CODEC
    // ════════════════════════════════════════════

    // Decode a Firestore REST document {name, fields} → plain PHP array
    private function decodeDoc(array $doc): array
    {
        $result = [];
        foreach ($doc['fields'] ?? [] as $key => $typedVal) {
            $result[$key] = $this->decodeFsValue($typedVal);
        }
        return $result;
    }

    // Recursively unwrap a Firestore typed value to a plain PHP value.
    // Timestamps are returned as their original typed wrapper so phpToFsValue can
    // round-trip them correctly when writing ordercabRequestData back.
    private function decodeFsValue(array $v): mixed
    {
        if (array_key_exists('stringValue',    $v)) return $v['stringValue'];
        if (array_key_exists('integerValue',   $v)) return (int)$v['integerValue'];
        if (array_key_exists('doubleValue',    $v)) return (float)$v['doubleValue'];
        if (array_key_exists('booleanValue',   $v)) return (bool)$v['booleanValue'];
        if (array_key_exists('nullValue',      $v)) return null;
        if (array_key_exists('timestampValue', $v)) return $v; // keep typed wrapper for round-trip
        if (array_key_exists('geoPointValue',  $v)) return $v; // keep typed wrapper
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

    // Convert a plain PHP value → Firestore typed value for REST writes.
    private function phpToFsValue(mixed $value): array
    {
        if (is_null($value))   return ['nullValue' => null];
        if (is_bool($value))   return ['booleanValue' => $value];
        if (is_int($value))    return ['integerValue' => (string)$value];
        if (is_float($value))  return ['doubleValue'  => $value];
        if (is_string($value)) return ['stringValue'  => $value];

        if (is_array($value)) {
            // Already a Firestore typed wrapper — pass through
            static $typeKeys = [
                'stringValue', 'integerValue', 'doubleValue', 'booleanValue',
                'nullValue', 'timestampValue', 'arrayValue', 'mapValue',
                'geoPointValue', 'referenceValue', 'bytesValue',
            ];
            if (count($value) === 1) {
                $k = array_key_first($value);
                if (in_array($k, $typeKeys, true)) return $value;
            }

            // Indexed array → arrayValue
            if (array_keys($value) === range(0, count($value) - 1)) {
                return ['arrayValue' => [
                    'values' => array_map(fn($v) => $this->phpToFsValue($v), $value),
                ]];
            }

            // Associative array → mapValue
            // Cast to object when empty: json_encode([]) = "[]" but Firestore requires "{}".
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
    // GEOMETRY
    // ════════════════════════════════════════════

    // Haversine formula — returns distance in miles (same formula as cabScheduleRide.js)
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

    // Ray-casting point-in-polygon (same algorithm as cabScheduleRide.js)
    private function isInPolygon(array $vertx, array $verty, float $testx, float $testy): bool
    {
        $c = false;
        $n = count($vertx);
        $j = $n - 1;
        for ($i = 0; $i < $n; $i++) {
            if (($verty[$i] > $testy) !== ($verty[$j] > $testy) &&
                $testx < (($vertx[$j] - $vertx[$i]) * ($testy - $verty[$i])
                         / ($verty[$j] - $verty[$i]) + $vertx[$i])) {
                $c = !$c;
            }
            $j = $i;
        }
        return $c;
    }

    // ════════════════════════════════════════════
    // HELPERS
    // ════════════════════════════════════════════

    private function abort(string $msg): void
    {
        \Log::error('[CAB_DISPATCH] ' . $msg);
        $this->consoleError('[CAB_DISPATCH] ' . $msg);
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
            \Log::warning("[FCM_INVALID_TOKEN] service=cab driverId=$driverId reason=UNREGISTERED; clearing token and keeping dispatch request");
            $this->fsUpdate('users', $driverId, [
                'fcmToken' => ['nullValue' => null],
            ]);
        }
    }
}
