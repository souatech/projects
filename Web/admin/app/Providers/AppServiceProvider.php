<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Config;
use App\Helpers\FirestoreHelper;

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
        setcookie('XSRF-TOKEN-AK', bin2hex($fb['api_key']              ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-AD', bin2hex($fb['auth_domain']          ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-DU', bin2hex($fb['database_url']         ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-PI', bin2hex($fb['project_id']           ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-SB', bin2hex($fb['storage_bucket']       ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-MS', bin2hex($fb['messaging_sender_id']  ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-AI', bin2hex($fb['app_id']               ?? ''), time() + 3600, "/");
        setcookie('XSRF-TOKEN-MI', bin2hex($fb['measurement_id']       ?? ''), time() + 3600, "/");

        $countries_data = [];
        $get_countries_json = file_get_contents(public_path('countriesdata.json'));
        if($get_countries_json != ''){
            $countries_data = json_decode($get_countries_json);
        }
        view()->composer('*', function($view) use($countries_data) {
            $view->with('countries_data', $countries_data);
        });
    }

    /**
     * Bootstrap any application services.
     *
     * @return void
     */
    public function boot()
    {
        $openai_settings = FirestoreHelper::getDocument('settings/openai_settings');
        if (!empty($openai_settings)) {
            if (!empty($openai_settings['api_key'])) {
                Config::set('openai.api_key', $openai_settings['api_key']);
            }
            if (!empty($openai_settings['organization'])) {
                Config::set('openai.organization', $openai_settings['organization']);
            }
        }

        view()->composer('*', function ($view) use ($openai_settings) {
            $view->with('openai_settings', $openai_settings);
        });
    }
}
