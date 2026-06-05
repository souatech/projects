<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     *
     * @var array<int, string>
     */
    protected $except = [
        // Only the PayDunya IPN webhook needs CSRF exemption (server-to-server, no browser session).
        // All other payment endpoints keep CSRF protection.
        'payments/paydunya/callback',
    ];
}
