<?php

namespace App\Http\Controllers;
use Illuminate\Support\Facades\Auth;
use App\Models\VendorUsers;

class PayoutsController extends Controller
{  

   public function __construct()
    {
        $this->middleware('auth');
    }

    public function index()
    {
        $id = Auth::id();
        $exist = VendorUsers::where('user_id', $id)->first();
        if (!$exist) {
            abort(403, 'Compte vendeur introuvable.');
        }
        $id = $exist->uuid;
        return view("vendors_payouts.index")->with('id', $id);
    }

    public function create()
    {
        $id = Auth::id();
        $exist = VendorUsers::where('user_id', $id)->first();
        if (!$exist) {
            abort(403, 'Compte vendeur introuvable.');
        }
        $id = $exist->uuid;
        return view("vendors_payouts.create")->with('id', $id);
    }
}