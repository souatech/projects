@extends('layouts.app')

@section('content')

<div class="page-wrapper">

    <div class="card">

        <div class="payment-top-tab mt-3 mb-3">

            <ul class="nav nav-tabs card-header-tabs align-items-end">

                <li class="nav-item">
                    <a class="nav-link stripe_active_label" href="{!! url('settings/payment/stripe') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_stripe')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link cod_active_label" href="{!! url('settings/payment/cod') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_cod_short')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link razorpay_active_label" href="{!! url('settings/payment/razorpay') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_razorpay')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link paypal_active_label" href="{!! url('settings/payment/paypal') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_paypal')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link wallet_active_label" href="{!! url('settings/payment/wallet') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_wallet')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link payfast_active_label" href="{!! url('settings/payment/payfast') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.payfast')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link paystack_active_label" href="{!! url('settings/payment/paystack') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.app_setting_paystack_lable')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link mercadopago_active_label" href="{!! url('settings/payment/mercadopago') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.mercadopago')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link xendit_active_label" href="{!! url('settings/payment/xendit') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.xendit')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link midTrans_active_label" href="{!! url('settings/payment/midtrans') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.midtrans')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link flutterWave_active_label"
                       href="{!! url('settings/payment/flutterwave') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.flutterWave')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                    <a class="nav-link orangePay_active_label"
                       href="{!! url('settings/payment/orangepay') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>
                        {{trans('lang.orangePay')}}
                        <span class="badge ml-2"></span>
                    </a>
                </li>

                <li class="nav-item">
                   <a class="nav-link active paydunya_active_label"
                       href="{!! url('settings/payment/paydunya') !!}">
                        <i class="fa fa-envelope-o mr-2"></i>  PayDunya  <span class="badge ml-2"></span>
                    </a>
                </li>

            </ul>

        </div>

        <div class="card-body">

            <div class="row vendor_payout_create">

                <div class="vendor_payout_create-inner">

                    <fieldset>

                        <legend>PayDunya</legend>

                        <div class="form-check width-100">

                            <input type="checkbox"
                                   class="enable_payment_method"
                                   id="enable_payment_method">

                            <label class="col-3 control-label"
                                   for="enable_payment_method">

                                {{trans('lang.app_setting_enable_payment')}}

                            </label>

                        </div>

                        <div class="form-check width-100">

                            <input type="checkbox"
                                   class="sand_box_mode"
                                   id="sand_box_mode">

                            <label class="col-3 control-label"
                                   for="sand_box_mode">

                                {{trans('lang.app_setting_enable_sandbox_mode')}}

                            </label>

                        </div>

                        <div class="form-group row width-100">

                            <label class="col-3 control-label">
                                Master Key
                            </label>

                            <div class="col-7">

                                <input type="password"
                                       class="form-control masterKey">

                            </div>

                        </div>

                        <div class="form-group row width-100">

                            <label class="col-3 control-label">
                                Public Key
                            </label>

                            <div class="col-7">

                                <input type="password"
                                       class="form-control publicKey">

                            </div>

                        </div>

                        <div class="form-group row width-100">

                            <label class="col-3 control-label">
                                Private Key
                            </label>

                            <div class="col-7">

                                <input type="password"
                                       class="form-control privateKey">

                            </div>

                        </div>

                        <div class="form-group row width-100">

                            <label class="col-3 control-label">
                                Token
                            </label>

                            <div class="col-7">

                                <input type="password"
                                       class="form-control token">

                            </div>

                        </div>

                    </fieldset>

                    <fieldset>

                        <legend>
                            <i class="mr-3 fa fa-cc-stripe"></i>
                            {{trans('lang.withdraw_setting')}}
                        </legend>

                        <div class="form-check width-100">

                            <input type="checkbox"  class="withdraw_enable" id="withdraw_enable">

                            <label class="col-3 control-label" for="withdraw_enable">  Activer PayDunya  </label>

                            <div class="form-text text-muted">

                                Activer PayDunya comme méthode de retrait
                                pour les vendeurs et chauffeurs.

                            </div>

                        </div>

                    </fieldset>

                </div>

            </div>

        </div>

        <div class="form-group col-12 text-center btm-btn"
             style="margin-bottom: inherit;">

            <button type="button"
                    class="btn btn-primary edit-setting-btn">

                <i class="fa fa-save"></i>
                {{trans('lang.save')}}

            </button>

            <a href="{{url('/dashboard')}}"
               class="btn btn-default">

                <i class="fa fa-undo"></i>
                {{trans('lang.cancel')}}

            </a>

        </div>

    </div>

</div>


@endsection



@section('scripts')

<script type="text/javascript">

var database = firebase.firestore();

var ref = database.collection('settings').doc('paydunya_settings');

var stripeData = database.collection('settings').doc('stripeSettings');

var codData = database.collection('settings').doc('CODSettings');

var paypalData = database.collection('settings').doc('paypalSettings');

var walletData = database.collection('settings').doc('walletSettings');

var razorpayData = database.collection('settings').doc('razorpaySettings');

var payFastSettings = database.collection('settings').doc('payFastSettings');

var payStackSettings = database.collection('settings').doc('payStack');

var MercadopagoSettings = database.collection('settings').doc('MercadoPago');

var orangePay = database.collection('settings').doc('orange_money_settings');

var xenditSettings = database.collection('settings').doc('xendit_settings');

var midTrans = database.collection('settings').doc('midtrans_settings');

var flutterWaveSettings = database.collection('settings').doc('flutterWave');

$(document).ready(function () {

    jQuery("#data-table_processing").show();

    ref.get().then(async function (snapshots) {

        var paydunya = snapshots.data();

        if (paydunya) {

            // PAYDUNYA

            if (paydunya.enabled || paydunya.isEnable) {

                $(".enable_payment_method").prop('checked', true);

                jQuery(".paydunya_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

            if (paydunya.sandbox || paydunya.isSandbox) {

                $(".sand_box_mode").prop('checked', true);
            }

            if (paydunya.withdrawEnabled || paydunya.isWithdrawEnabled) {
                $(".withdraw_enable").prop('checked', true);
            }

            $(".masterKey").val(paydunya.masterKey || "");

            $(".privateKey").val(paydunya.privateKey || "");

            $(".publicKey").val(paydunya.publicKey || "");

            $(".token").val(paydunya.token || "");
        }

        // COD

        codData.get().then(async function (codSnapshots) {

            var cod = codSnapshots.data();

            if (cod && cod.isEnabled) {

                jQuery(".cod_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // STRIPE

        stripeData.get().then(async function(stripeSnapshots) {

            var stripe = stripeSnapshots.data();

            if (stripe && stripe.isEnabled) {

                jQuery(".stripe_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // PAYPAL

        paypalData.get().then(async function (paypalSnapshots) {

            var paypal = paypalSnapshots.data();

            if (paypal && paypal.isEnabled) {

                jQuery(".paypal_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // RAZORPAY

        razorpayData.get().then(async function (razorpaySnapshots) {

            var razorpay = razorpaySnapshots.data();

            if (razorpay && razorpay.isEnabled) {

                jQuery(".razorpay_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // WALLET

        walletData.get().then(async function (walletSnapshots) {

            var wallet = walletSnapshots.data();

            if (wallet && wallet.isEnabled) {

                jQuery(".wallet_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // PAYFAST

        payFastSettings.get().then(async function (payFastSnapshots) {

            var payFast = payFastSnapshots.data();

            if (payFast && payFast.isEnable) {

                jQuery(".payfast_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // PAYSTACK

        payStackSettings.get().then(async function (payStackSnapshots) {

            var payStack = payStackSnapshots.data();

            if (payStack && payStack.isEnable) {

                jQuery(".paystack_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // MERCADOPAGO

        MercadopagoSettings.get().then(async function (mercadopagoSnapshots) {

            var mercadopago = mercadopagoSnapshots.data();

            if (mercadopago && mercadopago.isEnabled) {

                jQuery(".mercadopago_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // ORANGE MONEY

        orangePay.get().then(async function(orangePaySnapshots) {

            var orangePayData = orangePaySnapshots.data();

            if (orangePayData && orangePayData.enable) {

                jQuery(".orangePay_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // XENDIT

        xenditSettings.get().then(async function(xenditSnapshots) {

            var xendit = xenditSnapshots.data();

            if (xendit && xendit.enable) {

                jQuery(".xendit_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // MIDTRANS

        midTrans.get().then(async function(midTransSnapshots) {

            var midtrans = midTransSnapshots.data();

            if (midtrans && midtrans.enable) {

                jQuery(".midTrans_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        // FLUTTERWAVE

        flutterWaveSettings.get().then(async function(flutterWaveSnapshots) {

            var flutterWave = flutterWaveSnapshots.data();

            if (flutterWave && flutterWave.isEnable) {

                jQuery(".flutterWave_active_label span")
                    .addClass('badge-success')
                    .text('Active');
            }

        });

        jQuery("#data-table_processing").hide();

    }).catch(function (error) {

        console.log(error);

        jQuery("#data-table_processing").hide();

    });




    $(".edit-setting-btn").click(function () {

        var masterKey = $(".masterKey").val();

        var publicKey = $(".publicKey").val();

        var privateKey = $(".privateKey").val();

        var token = $(".token").val();

        var isEnable = $(".enable_payment_method").is(":checked");

        var isSandbox = $(".sand_box_mode").is(":checked");

        var isWithdrawEnabled = $(".withdraw_enable").is(":checked");



        database.collection('settings')
            .doc("paydunya_settings")
            .set({

                // NOUVEAU FORMAT VERROUILLÉ
                'enabled': isEnable,
                'sandbox': isSandbox,
                'withdrawEnabled': isWithdrawEnabled,

                // COMPATIBILITÉ TEMPORAIRE
                'isEnable': isEnable,
                'isSandbox': isSandbox,
                'isWithdrawEnabled': isWithdrawEnabled,

                // KEYS
                'masterKey': masterKey,
                'publicKey': publicKey,
                'privateKey': privateKey,
                'token': token,

                // OPTIONNEL
                'image': ''

            }, { merge: true })

            .then(function () {

                window.location.href =
                    '{{ url("settings/payment/paydunya")}}';

            })

            .catch(function (error) {

                console.log(error);

            });

    });

});

</script>
@endsection