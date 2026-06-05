<?php

namespace App\Http\Controllers;

use App\Console\Commands\VendorScheduleDispatch;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorDispatchController extends Controller
{
    public function dispatchVendorOrder(Request $request, string $orderId): JsonResponse
    {
        \Log::info("[VENDOR_DISPATCH_API] dispatch requested orderId=$orderId");

        $ok = (new VendorScheduleDispatch())->dispatchVendorOrderById($orderId);

        return response()->json([
            'success' => $ok,
            'orderId' => $orderId,
        ], $ok ? 200 : 422);
    }
}
