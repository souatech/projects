<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;

class PayDunyaService
{
    public function createInvoice($data)
    {
        // DISABLED: Dead code — not called anywhere in the application.
        // The active PayDunya flow uses PaymentController (keys from .env only).
        // Hardcoded sandbox keys have been removed.
        throw new \RuntimeException('PayDunyaService::createInvoice is disabled. Use PaymentController instead.');
    }
}