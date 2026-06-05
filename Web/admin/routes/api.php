<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CabDispatchController;
use App\Http\Controllers\ParcelDispatchController;
use App\Http\Controllers\VendorDispatchController;
use App\Http\Controllers\PaymentController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
});

// ─── CAB instant dispatch (called by customer app immediately on ride place) ─
Route::post('cab/dispatch/{rideId}', [CabDispatchController::class, 'dispatchRide']);

// ─── Parcel instant dispatch (called by customer app immediately on parcel place) ─
Route::post('parcel/dispatch/{parcelOrderId}', [ParcelDispatchController::class, 'dispatchParcel']);

// ─── Vendor delivery instant dispatch (called by store app after order acceptance) ─
Route::post('vendor/dispatch/{orderId}', [VendorDispatchController::class, 'dispatchVendorOrder']);

// ─── PayDunya (appelé depuis l'app Flutter via Constant.globalUrl) ──────────
Route::get('payments/paydunya/config', [PaymentController::class, 'getPaydunyaConfig']);
Route::post('payments/paydunya/create', [PaymentController::class, 'createPaydunyaPayment']);
Route::post('payments/paydunya/confirm', [PaymentController::class, 'confirmPaydunyaPayment']);
Route::post('payments/paydunya/callback', [PaymentController::class, 'paydunyaPaymentCallback']);
