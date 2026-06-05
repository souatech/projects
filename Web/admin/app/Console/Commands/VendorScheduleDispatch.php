<?php

namespace App\Console\Commands;

use Google\Client as GoogleClient;
use GuzzleHttp\Client as HttpClient;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;

class VendorScheduleDispatch extends Command
{
    protected $signature = 'app:vendor-schedule-dispatch';
    protected $description = 'Dispatches accepted vendor delivery orders to available delivery drivers';

    private string $projectId;
    private string $accessToken;
    private HttpClient $http;

    public function handle(): void
    {
        $this->bootstrapFirestore();
        $orders = $this->fsQuery('vendor_orders', [
            ['field' => 'status', 'op' => 'EQUAL', 'value' => ['stringValue' => 'Order Accepted']],
        ]);

        foreach ($orders as $order) {
            $this->dispatchOrder($order);
        }
    }

    public function dispatchVendorOrderById(string $orderId): bool
    {
        \Log::info("[VENDOR_DISPATCH_HTTP_STARTED] orderId=$orderId");
        \Log::info("[DISPATCH_START] service=vendor orderId=$orderId");

        try {
            $this->bootstrapFirestore();
            $order = $this->fsGet('vendor_orders', $orderId);
            if (empty($order)) {
                \Log::warning("[VENDOR_DISPATCH_HTTP_SKIP] orderId=$orderId not found");
                return false;
            }

            $status = (string)($order['status'] ?? '');
            \Log::info("[ORDER_LOADED] service=vendor orderId=$orderId status=$status sectionId=" . ($order['section_id'] ?? $order['sectionId'] ?? ''));
            if (!in_array($status, ['Order Accepted', 'Driver Rejected'], true)) {
                \Log::info("[VENDOR_DISPATCH_HTTP_SKIP] orderId=$orderId status=$status not dispatchable");
                return false;
            }

            return $this->dispatchOrder($order);
        } catch (\Throwable $e) {
            \Log::error("[VENDOR_DISPATCH_HTTP_ERROR] orderId=$orderId message=" . $e->getMessage());
            return false;
        }
    }

    private function bootstrapFirestore(): void
    {
        if (!Storage::disk('local')->has('firebase/credentials.json')) {
            throw new \RuntimeException('credentials.json not found at storage/app/firebase/credentials.json');
        }

        $credJson = json_decode(Storage::disk('local')->get('firebase/credentials.json'), true);
        $this->projectId = $credJson['project_id'] ?? '';
        $this->accessToken = $this->getAccessToken();
        $this->http = new HttpClient(['timeout' => 30, 'http_errors' => false]);
    }

    private function dispatchOrder(array $order): bool
    {
        $orderId = (string)($order['id'] ?? $order['__docId'] ?? '');
        $sectionId = (string)($order['section_id'] ?? $order['sectionId'] ?? '');
        $rejected = (array)($order['rejectedByDrivers'] ?? []);

        \Log::info("[DISPATCH_START] service=vendor orderId=$orderId status=" . ($order['status'] ?? '') . " sectionId=$sectionId");

        if ($orderId === '') {
            \Log::warning('[VENDOR_DISPATCH_SKIP] missing order id');
            return false;
        }

        $allDriverDocs = $this->fsQuery('users', [
            ['field' => 'role', 'op' => 'EQUAL', 'value' => ['stringValue' => 'driver']],
        ]);

        $candidates = [];
        foreach ($allDriverDocs as $driver) {
            $driverId = (string)($driver['id'] ?? $driver['__docId'] ?? '');
            if ($driverId === '') continue;

            $active = ($driver['active'] ?? true) === true;
            $isActive = ($driver['isActive'] ?? false) === true;
            $role = (string)($driver['driverRole'] ?? '');
            $serviceTypes = (array)($driver['serviceTypes'] ?? []);
            $legacyType = (string)($driver['serviceType'] ?? '');

            $deliveryLike = $role === 'delivery'
                || in_array('delivery-service', $serviceTypes, true)
                || in_array('multivendor-delivery-service', $serviceTypes, true)
                || in_array('parcel-service', $serviceTypes, true)
                || in_array('parcel_delivery', $serviceTypes, true)
                || in_array($legacyType, ['delivery-service', 'multivendor-delivery-service', 'parcel-service', 'parcel_delivery'], true);

            if (!$active || !$isActive || !$deliveryLike) {
                \Log::info("[DISPATCH_DRIVER_SKIP] driverId=$driverId active=$active isActive=$isActive role=$role deliveryLike=$deliveryLike");
                continue;
            }

            $sectionIds = (array)($driver['sectionIds'] ?? []);
            if (empty($sectionIds) && !empty($driver['sectionId'])) {
                $sectionIds = [(string)$driver['sectionId']];
            }
            if ($sectionId !== '' && !empty($sectionIds) && !in_array($sectionId, $sectionIds, true)) {
                \Log::info("[DISPATCH_DRIVER_SKIP_SECTION] driverId=$driverId sections=" . implode(',', $sectionIds) . " orderSection=$sectionId");
                continue;
            }

            if (in_array($driverId, $rejected, true)) {
                \Log::info("[DISPATCH_DRIVER_SKIP_REJECTED] driverId=$driverId orderId=$orderId");
                continue;
            }

            $requests = (array)($driver['orderRequestData'] ?? []);
            if (in_array($orderId, $requests, true)) {
                \Log::info("[DISPATCH_DRIVER_SKIP_ALREADY_REQUESTED] driverId=$driverId orderId=$orderId");
                continue;
            }
            if (!empty($driver['ordercabRequestData']) || !empty($driver['orderParcelRequestData'])) {
                \Log::info("[DISPATCH_DRIVER_SKIP_BUSY_OTHER_FLOW] driverId=$driverId orderId=$orderId");
                continue;
            }

            $distance = $this->distanceToPickup($driver, $order);
            $candidates[] = ['driver' => $driver, 'distance' => $distance];
            \Log::info("[DISPATCH_DRIVER_CANDIDATE] driverId=$driverId distance=" . ($distance === null ? 'unknown' : round($distance, 2)) . " sectionMatch=1");
        }

        usort($candidates, function ($a, $b) {
            if ($a['distance'] === null && $b['distance'] === null) return 0;
            if ($a['distance'] === null) return 1;
            if ($b['distance'] === null) return -1;
            return $a['distance'] <=> $b['distance'];
        });

        \Log::info("[DISPATCH_FIND_DRIVERS] role=delivery count=" . count($candidates) . " orderId=$orderId");
        if (empty($candidates)) {
            \Log::info("[DRIVER_FOUND] service=vendor orderId=$orderId driverId=none");
            return false;
        }

        $selected = $candidates[0]['driver'];
        $driverId = (string)($selected['id'] ?? $selected['__docId'] ?? '');
        \Log::info("[DRIVER_FOUND] service=vendor orderId=$orderId driverId=$driverId");
        $requests = (array)($selected['orderRequestData'] ?? []);
        $requests[] = $orderId;
        $requests = array_values(array_unique(array_filter($requests)));

        $now = gmdate('Y-m-d\TH:i:s\Z');
        $this->fsUpdate('vendor_orders', $orderId, [
            'status' => ['stringValue' => 'Driver Pending'],
            'driverID' => ['stringValue' => $driverId],
            'driverAssignedAt' => ['timestampValue' => $now],
        ]);

        \Log::info("[FIRESTORE_WRITE] service=vendor collection=users doc=$driverId field=orderRequestData orderId=$orderId");
        $writeOk = $this->fsUpdateWithCheck('users', $driverId, [
            'orderRequestData' => $this->toFsArray($requests),
        ]);

        \Log::info("[DISPATCH_WRITE_DRIVER_REQUEST] driverId=$driverId field=orderRequestData orderId=$orderId ok=" . ($writeOk ? '1' : '0'));

        $token = (string)($selected['fcmToken'] ?? '');
        if ($token !== '') {
            $this->sendFcm($token, 'Nouvelle livraison', 'Une nouvelle commande est disponible.', $orderId, $driverId);
        }

        \Log::info("[VENDOR_DISPATCH_DONE] orderId=$orderId driverId=$driverId");
        \Log::info("[DISPATCH_SUCCESS] service=vendor orderId=$orderId driverId=$driverId firestoreWrite=" . ($writeOk ? '1' : '0'));
        return $writeOk;
    }

    private function distanceToPickup(array $driver, array $order): ?float
    {
        $dLoc   = $driver['location'] ?? [];
        $vendor = $order['vendor']    ?? [];

        $dLat = (float)($dLoc['latitude']  ?? 0);
        $dLng = (float)($dLoc['longitude'] ?? 0);

        // vendor.latitude/longitude direct (VendorModel standard)
        // ou imbriqué sous vendor.location (geoPoint décodé)
        $oLat = (float)($vendor['latitude']  ?? $vendor['location']['latitude']  ?? 0);
        $oLng = (float)($vendor['longitude'] ?? $vendor['location']['longitude'] ?? 0);

        $orderId  = (string)($order['id']   ?? $order['__docId'] ?? '');
        $driverId = (string)($driver['id']  ?? $driver['__docId'] ?? '');

        if ($oLat == 0.0 || $oLng == 0.0) {
            \Log::warning("[VENDOR_NO_COORDS] orderId=$orderId — vendor.latitude/longitude absent, distance filter ignoré");
            return null;
        }
        if ($dLat == 0.0 || $dLng == 0.0) {
            \Log::info("[DISPATCH_DRIVER_NO_LOCATION] driverId=$driverId — driver.location absent");
            return null;
        }

        return $this->haversineDistanceMiles($dLat, $dLng, $oLat, $oLng);
    }

    private function sendFcm(string $token, string $title, string $body, string $orderId, ?string $driverId = null): void
    {
        try {
            \Log::info("[FCM_SEND] service=vendor orderId=$orderId driverId=" . ($driverId ?? '') . " token=" . substr($token, 0, 20) . '...');
            $resp = $this->http->post("https://fcm.googleapis.com/v1/projects/{$this->projectId}/messages:send", [
                'headers' => [
                    'Authorization' => 'Bearer ' . $this->accessToken,
                    'Content-Type' => 'application/json',
                ],
                'json' => [
                    'message' => [
                        'token' => $token,
                        'notification' => ['title' => $title, 'body' => $body],
                        'data' => ['type' => 'new_delivery_order', 'orderId' => $orderId],
                    ],
                ],
            ]);
            $statusCode = $resp->getStatusCode();
            $respBody = (string)$resp->getBody();
            \Log::info("[DISPATCH_FCM_SENT] status=$statusCode orderId=$orderId body=$respBody");
            if ($statusCode !== 200) {
                \Log::error("[VENDOR_DISPATCH_FCM_ERROR] status=$statusCode body=$respBody");
                $this->handleInvalidFcmToken($respBody, $driverId);
            }
        } catch (\Throwable $e) {
            \Log::error('[VENDOR_DISPATCH_FCM_ERROR] ' . $e->getMessage());
        }
    }

    private function handleInvalidFcmToken(string $responseBody, ?string $driverId): void
    {
        if (!$driverId) {
            return;
        }

        $decoded = json_decode($responseBody, true);
        $bodyContainsUnregistered = str_contains($responseBody, 'UNREGISTERED');
        $errorCode = $decoded['error']['details'][0]['errorCode'] ?? $decoded['error']['status'] ?? null;

        if ($bodyContainsUnregistered || $errorCode === 'UNREGISTERED') {
            \Log::warning("[FCM_INVALID_TOKEN] service=vendor driverId=$driverId reason=UNREGISTERED; clearing token and keeping dispatch request");
            $this->fsUpdate('users', $driverId, [
                'fcmToken' => ['nullValue' => null],
            ]);
        }
    }

    private function fsBaseUrl(): string
    {
        return "https://firestore.googleapis.com/v1/projects/{$this->projectId}/databases/(default)/documents";
    }

    private function fsGet(string $collection, string $docId): array
    {
        $resp = $this->http->get("{$this->fsBaseUrl()}/{$collection}/{$docId}", [
            'headers' => ['Authorization' => 'Bearer ' . $this->accessToken],
        ]);
        if ($resp->getStatusCode() !== 200) return [];
        $body = json_decode((string)$resp->getBody(), true);
        $decoded = $this->decodeDoc($body);
        $decoded['__docId'] = $docId;
        return $decoded;
    }

    private function fsQuery(string $collection, array $filters): array
    {
        $wheres = array_map(fn($f) => [
            'fieldFilter' => [
                'field' => ['fieldPath' => $f['field']],
                'op' => $f['op'],
                'value' => $f['value'],
            ],
        ], $filters);
        $whereClause = count($wheres) === 1 ? $wheres[0] : ['compositeFilter' => ['op' => 'AND', 'filters' => $wheres]];
        $resp = $this->http->post("{$this->fsBaseUrl()}:runQuery", [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->accessToken,
                'Content-Type' => 'application/json',
            ],
            'json' => ['structuredQuery' => ['from' => [['collectionId' => $collection]], 'where' => $whereClause]],
        ]);
        if ($resp->getStatusCode() !== 200) {
            \Log::error("[VENDOR_DISPATCH] fsQuery $collection HTTP {$resp->getStatusCode()} body=" . $resp->getBody());
            return [];
        }
        $rows = json_decode((string)$resp->getBody(), true) ?? [];
        $results = [];
        foreach ($rows as $row) {
            if (!empty($row['document'])) {
                $decoded = $this->decodeDoc($row['document']);
                $decoded['__docId'] = basename($row['document']['name'] ?? '');
                $results[] = $decoded;
            }
        }
        return $results;
    }

    private function fsUpdate(string $collection, string $docId, array $typedFields): void
    {
        $this->fsUpdateWithCheck($collection, $docId, $typedFields);
    }

    private function fsUpdateWithCheck(string $collection, string $docId, array $typedFields): bool
    {
        if ($docId === '') return false;
        $maskParams = implode('&', array_map(fn($k) => 'updateMask.fieldPaths=' . urlencode($k), array_keys($typedFields)));
        $resp = $this->http->patch("{$this->fsBaseUrl()}/{$collection}/{$docId}?{$maskParams}", [
            'headers' => [
                'Authorization' => 'Bearer ' . $this->accessToken,
                'Content-Type' => 'application/json',
            ],
            'json' => ['fields' => $typedFields],
        ]);
        if ($resp->getStatusCode() !== 200) {
            \Log::error("[VENDOR_DISPATCH] fsUpdate $collection/$docId HTTP {$resp->getStatusCode()} body=" . $resp->getBody());
            return false;
        }
        return true;
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
        if (array_key_exists('stringValue', $v)) return $v['stringValue'];
        if (array_key_exists('integerValue', $v)) return (int)$v['integerValue'];
        if (array_key_exists('doubleValue', $v)) return (float)$v['doubleValue'];
        if (array_key_exists('booleanValue', $v)) return (bool)$v['booleanValue'];
        if (array_key_exists('nullValue', $v)) return null;
        if (array_key_exists('timestampValue', $v)) return $v;
        if (array_key_exists('geoPointValue', $v)) return $v['geoPointValue'];
        if (array_key_exists('arrayValue', $v)) {
            return array_map(fn($item) => $this->decodeFsValue($item), $v['arrayValue']['values'] ?? []);
        }
        if (array_key_exists('mapValue', $v)) return $this->decodeDoc(['fields' => $v['mapValue']['fields'] ?? []]);
        return null;
    }

    private function phpToFsValue(mixed $value): array
    {
        if (is_null($value)) return ['nullValue' => null];
        if (is_bool($value)) return ['booleanValue' => $value];
        if (is_int($value)) return ['integerValue' => (string)$value];
        if (is_float($value)) return ['doubleValue' => $value];
        if (is_string($value)) return ['stringValue' => $value];
        if (is_array($value)) {
            if (array_keys($value) === range(0, count($value) - 1)) {
                return ['arrayValue' => ['values' => array_map(fn($v) => $this->phpToFsValue($v), $value)]];
            }
            $fields = [];
            foreach ($value as $k => $v) $fields[(string)$k] = $this->phpToFsValue($v);
            return ['mapValue' => ['fields' => $fields ?: (object)[]]];
        }
        return ['nullValue' => null];
    }

    private function toFsArray(array $items): array
    {
        return ['arrayValue' => ['values' => array_map(fn($v) => $this->phpToFsValue($v), $items)]];
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

    private function haversineDistanceMiles(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        if ($lat1 === $lat2 && $lon1 === $lon2) return 0.0;
        $theta = $lon1 - $lon2;
        $dist = sin(deg2rad($lat1)) * sin(deg2rad($lat2)) + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * cos(deg2rad($theta));
        $dist = min(1.0, max(-1.0, $dist));
        return acos($dist) * (180 / M_PI) * 60 * 1.1515;
    }
}
