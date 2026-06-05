<?php

namespace App\Http\Controllers;

use App\Console\Commands\CabScheduleRide;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CabDispatchController extends Controller
{
    public function dispatchRide(Request $request, string $rideId): JsonResponse
    {
        if (empty($rideId)) {
            return response()->json(['success' => false, 'error' => 'rideId required'], 400);
        }

        try {
            $dispatched = (new CabScheduleRide())->dispatchRideById($rideId);

            return response()->json([
                'success'    => true,
                'dispatched' => $dispatched,
                'rideId'     => $rideId,
            ]);
        } catch (\Throwable $e) {
            \Log::error('[CAB_DISPATCH_HTTP] Controller error rideId=' . $rideId . ': ' . $e->getMessage());
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }
}
