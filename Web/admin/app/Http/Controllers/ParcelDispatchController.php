<?php

namespace App\Http\Controllers;

use App\Console\Commands\ParcelScheduleDispatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ParcelDispatchController extends Controller
{
    public function dispatchParcel(Request $request, string $parcelOrderId): JsonResponse
    {
        if (empty($parcelOrderId)) {
            return response()->json(['success' => false, 'error' => 'parcelOrderId required'], 400);
        }

        try {
            $dispatched = (new ParcelScheduleDispatch())->dispatchParcelById($parcelOrderId);

            return response()->json([
                'success'       => true,
                'dispatched'    => $dispatched,
                'parcelOrderId' => $parcelOrderId,
            ]);
        } catch (\Throwable $e) {
            \Log::error('[PARCEL_DISPATCH_HTTP] Controller error parcelOrderId=' . $parcelOrderId . ': ' . $e->getMessage());
            return response()->json(['success' => false, 'error' => $e->getMessage()], 500);
        }
    }
}
