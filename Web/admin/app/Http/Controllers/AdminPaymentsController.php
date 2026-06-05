<?php
namespace App\Http\Controllers;


use Illuminate\Http\Request;

class AdminPaymentsController extends Controller
{  

   public function __construct()
    {
        $this->middleware('auth');
    }
    
	public function index()
    {
       return view("payments.index");
    }

    public function driverIndex()
 	{
    	return view("payments.driver_index");
 	}
    public function providerIndex()
    {
        return view("payments.provider_index");
    }
   
}
