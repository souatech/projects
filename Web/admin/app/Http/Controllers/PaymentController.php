<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    // ─── Helpers ─────────────────────────────────────────────────────────────

    private function paydunyaHeaders(): array
    {
        return [
            'PAYDUNYA-MASTER-KEY'  => env('PAYDUNYA_MASTER_KEY', ''),
            'PAYDUNYA-PRIVATE-KEY' => env('PAYDUNYA_PRIVATE_KEY', ''),
            'PAYDUNYA-TOKEN'       => env('PAYDUNYA_TOKEN', ''),
            'PAYDUNYA-PUBLIC-KEY'  => env('PAYDUNYA_PUBLIC_KEY', ''),
            'Content-Type'         => 'application/json',
        ];
    }

    private function paydunyaBase(): string
    {
        return env('PAYDUNYA_MODE', 'sandbox') === 'live'
            ? 'https://app.paydunya.com/api/v1'
            : 'https://app.paydunya.com/sandbox-api/v1';
    }

    // ─── Config ───────────────────────────────────────────────────────────────

    /** Returns enable status + mode — no secret keys exposed to the client. */
    public function getPaydunyaConfig()
    {
        return response()->json([
            'isEnabled' => env('PAYDUNYA_ENABLED', 'false') === 'true',
            'mode'      => env('PAYDUNYA_MODE', 'sandbox'),
        ]);
    }

    // ─── Create invoice ───────────────────────────────────────────────────────

    /** Creates a PayDunya checkout invoice. Keys read from .env only. */
    public function createPaydunyaPayment(Request $request)
    {
        $request->validate([
            'amount'         => 'required|numeric|min:1',
            'order_id'       => 'required|string|max:255',
            'customer_name'  => 'required|string|max:255',
            'customer_email' => 'required|email',
        ]);

        if (env('PAYDUNYA_ENABLED', 'false') !== 'true') {
            Log::warning('[PayDunya] createPayment called but PAYDUNYA_ENABLED is not true');
            return response()->json(['error' => 'PayDunya is disabled'], 503);
        }

        $baseUrl = env('APP_URL', 'https://joxmako.com');
        $amount  = (float) $request->amount;
        $orderId = $request->order_id;

        // Persist intent for server-side amount validation on callback
        DB::table('paydunya_payment_intents')->insert([
            'order_id'   => $orderId,
            'amount'     => $amount,
            'token'      => null,
            'status'     => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $payload = [
            'invoice' => [
                'total_amount' => $amount,
                'description'  => 'Commande JOXMAKO #' . $orderId,
            ],
            'store' => [
                'name'        => env('PAYDUNYA_STORE_NAME', env('APP_NAME', 'JOXMAKO')),
                'website_url' => $baseUrl,
            ],
            'custom_data' => [
                'order_id'       => $orderId,
                'customer_name'  => $request->customer_name,
                'customer_email' => $request->customer_email,
            ],
            'actions' => [
                'callback_url' => $baseUrl . '/api/payments/paydunya/callback',
                'return_url'   => $baseUrl . '/payments/paydunya/return',
                'cancel_url'   => $baseUrl . '/payments/paydunya/cancel',
            ],
        ];

        Log::info('[PayDunya] createPayment', ['order_id' => $orderId, 'amount' => $amount]);

        $response = Http::withHeaders($this->paydunyaHeaders())
            ->post($this->paydunyaBase() . '/checkout-invoice/create', $payload);

        $data = $response->json();

        if ($response->successful() && isset($data['response_code']) && $data['response_code'] === '00') {
            // Persist the PayDunya token for validation
            DB::table('paydunya_payment_intents')
                ->where('order_id', $orderId)
                ->update(['token' => $data['token'], 'updated_at' => now()]);

            return response()->json([
                'token'       => $data['token'],
                'payment_url' => $data['hosted_payment_url'],
            ]);
        }

        // Rollback the intent row on failure
        DB::table('paydunya_payment_intents')->where('order_id', $orderId)->delete();

        Log::error('[PayDunya] createPayment failed', ['body' => $data]);
        return response()->json([
            'error'   => $data['response_text'] ?? 'PayDunya invoice creation failed',
            'details' => $data,
        ], 502);
    }

    // ─── Confirm invoice ──────────────────────────────────────────────────────

    /** Verifies invoice status with PayDunya. Keys read from .env only. */
    public function confirmPaydunyaPayment(Request $request)
    {
        $request->validate(['token' => 'required|string']);
        $token = $request->input('token');

        Log::info('[PayDunya] confirmPayment', ['token' => $token]);

        $response = Http::withHeaders($this->paydunyaHeaders())
            ->get($this->paydunyaBase() . '/checkout-invoice/confirm/' . $token);

        $data = $response->json();

        Log::info('[PayDunya] confirmPayment response', [
            'status' => $data['status'] ?? null,
            'token'  => $token,
        ]);

        return response()->json([
            'status' => $data['status'] ?? 'pending',
        ]);
    }

    // ─── IPN callback ─────────────────────────────────────────────────────────

    /**
     * PayDunya IPN webhook.
     * Validates that the paid amount matches the invoiced amount,
     * then updates the Firestore order status via Firebase REST API.
     */
    public function paydunyaPaymentCallback(Request $request)
    {
        $data = $request->all();
        Log::info('[PayDunya] IPN received', $data);

        $token      = $data['data']['invoice']['token']        ?? null;
        $paidAmount = (float) ($data['data']['invoice']['total_amount'] ?? 0);
        $status     = $data['data']['status']                  ?? 'unknown';
        $orderId    = $data['data']['custom_data']['order_id'] ?? null;

        if (!$token || !$orderId) {
            Log::warning('[PayDunya] IPN missing token or order_id');
            return response()->json(['success' => false, 'reason' => 'missing_fields'], 400);
        }

        // Validate amount against stored intent
        $intent = DB::table('paydunya_payment_intents')
            ->where('token', $token)
            ->where('order_id', $orderId)
            ->first();

        if (!$intent) {
            Log::error('[PayDunya] IPN no matching intent', ['token' => $token, 'order_id' => $orderId]);
            return response()->json(['success' => false, 'reason' => 'intent_not_found'], 422);
        }

        $expectedAmount = (float) $intent->amount;

        if (abs($paidAmount - $expectedAmount) > 0.01) {
            Log::error('[PayDunya] IPN AMOUNT MISMATCH', [
                'expected' => $expectedAmount,
                'received' => $paidAmount,
                'order_id' => $orderId,
            ]);
            DB::table('paydunya_payment_intents')
                ->where('token', $token)
                ->update(['status' => 'fraud', 'updated_at' => now()]);
            return response()->json(['success' => false, 'reason' => 'amount_mismatch'], 422);
        }

        if ($status === 'completed') {
            DB::table('paydunya_payment_intents')
                ->where('token', $token)
                ->update(['status' => 'completed', 'updated_at' => now()]);

            // Update Firestore order via Firebase REST API
            $this->confirmOrderInFirestore($orderId);
        } elseif (in_array($status, ['cancelled', 'failed'])) {
            DB::table('paydunya_payment_intents')
                ->where('token', $token)
                ->update(['status' => $status, 'updated_at' => now()]);
        }

        return response()->json(['success' => true]);
    }

    /**
     * Updates the Firestore order to "Order Placed" + paymentStatus=true
     * using the Firebase REST API with the service account API key.
     */
    private function confirmOrderInFirestore(string $orderId): void
    {
        $projectId = config('services.firebase_web.project_id', '');
        $apiKey    = config('services.firebase_web.api_key', '');

        if (!$projectId || !$apiKey) {
            Log::warning('[PayDunya] Firebase credentials missing — cannot update Firestore');
            return;
        }

        // Try both provider_orders and vendor_orders collections
        $collections = ['provider_orders', 'vendor_orders'];

        foreach ($collections as $collection) {
            $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collection}/{$orderId}?key={$apiKey}";

            $patchUrl = $url . '&updateMask.fieldPaths=status&updateMask.fieldPaths=paymentStatus';

            $body = [
                'fields' => [
                    'status'        => ['stringValue' => 'Order Placed'],
                    'paymentStatus' => ['booleanValue' => true],
                ],
            ];

            $response = Http::patch($patchUrl, $body);

            if ($response->successful()) {
                Log::info("[PayDunya] Firestore order {$orderId} confirmed in {$collection}");
                return;
            }
        }

        Log::warning("[PayDunya] Could not confirm order {$orderId} in Firestore");
    }

    // ─── Redirects (WebView detection) ────────────────────────────────────────

    /** PayDunya return redirect — Flutter WebView detects this URL. */
    public function paydunyaReturn(Request $request)
    {
        Log::info('[PayDunya] return URL hit');
        return response(
            '<html><body><script>window.close();</script><p>Paiement réussi. Vous pouvez fermer cette fenêtre.</p></body></html>',
            200
        )->header('Content-Type', 'text/html');
    }

    /** PayDunya cancel redirect — Flutter WebView detects this URL. */
    public function paydunyaCancel(Request $request)
    {
        Log::info('[PayDunya] cancel URL hit');
        return response(
            '<html><body><script>window.close();</script><p>Paiement annulé.</p></body></html>',
            200
        )->header('Content-Type', 'text/html');
    }
}
