<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     *
     * @return void
     */
    public function register()
    {
        $fb = config('services.firebase_web');
        setcookie('XSRF-TOKEN-AK', bin2hex($fb['api_key']             ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-AD', bin2hex($fb['auth_domain']         ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-DU', bin2hex($fb['database_url']        ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-PI', bin2hex($fb['project_id']          ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-SB', bin2hex($fb['storage_bucket']      ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-MS', bin2hex($fb['messaging_sender_id'] ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-AI', bin2hex($fb['app_id']              ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-MI', bin2hex($fb['measurement_id']      ?? ''), time() + 3600, "/");
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
    }
}