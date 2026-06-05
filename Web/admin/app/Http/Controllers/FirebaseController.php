<?php

namespace App\Http\Controllers;


class FirebaseController extends Controller
{

    public function __construct()
    {
        $this->middleware('auth');
    }

    public function config()
    {
        $fb = config('services.firebase_web');
        $data = array(
            'apiKey'           => base64_encode($fb['api_key']             ?? ''),
            'authDomain'       => base64_encode($fb['auth_domain']         ?? ''),
            'databaseURL'      => base64_encode($fb['database_url']        ?? ''),
            'projectId'        => base64_encode($fb['project_id']          ?? ''),
            'storageBucket'    => base64_encode($fb['storage_bucket']      ?? ''),
            'messagingSenderId'=> base64_encode($fb['messaging_sender_id'] ?? ''),
            'appId'            => base64_encode($fb['app_id']              ?? ''),
            'measurementId'    => base64_encode($fb['measurement_id']      ?? ''),
        );

        return response()->json($data);
    }

}
