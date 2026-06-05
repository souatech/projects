@extends('layouts.app')
@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <div class="d-flex top-title-section justify-content-between">
                <div class="d-flex top-title-left align-self-center">
                    <span class="icon mr-3"><img src="{{ asset('images/driver.png') }}"></span>
                    <h3 class="mb-0 page-title">{{trans('lang.driver_plural')}}</h3>
                </div>
            </div>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{trans('lang.dashboard')}}</a></li>
                <li class="breadcrumb-item"><a href="{!! route('drivers') !!}">{{trans('lang.driver_plural')}}</a></li>
                <li class="breadcrumb-item active">{{trans('lang.driver_details')}}</li>
            </ol>
        </div>
    </div>
    <div class="container-fluid">
        <div class="admin-top-section"> 
            <div class="row">
                <div class="col-12">
                    <div class="d-flex top-title-section justify-content-between">
                        <div class="d-flex top-title-left align-self-center">
                        </div>
                        <div class="d-flex top-title-right align-self-center">
                            <div class="card-header-right"> 
                                    <a href="javascript:void(0)" data-toggle="modal" data-target="#addWalletModal"class="btn-primary btn rounded-full add-wallate"><i class="mdi mdi-plus mr-2"></i>Ajuster les gains</a>
                            </div>
                        </div>
                    </div>
                </div>
            </div> 
        </div>
        <div class="resttab-sec mb-4">  
            <div class="menu-tab">
                <ul>
                    <li class="active">
                        <a href="{{route('drivers.view',$id)}}" class="basic"><i class="ri-list-indefinite"></i> {{trans('lang.tab_basic')}}</a>
                    </li>
                    <li class="vehicle_tab" style="display:none">
                        <a href="{{route('drivers.vehicle',$id)}}" class="vehicle"><i class="ri-car-line"></i> {{trans('lang.vehicle')}}</a>
                    </li>
                    <li class="service_type_orders">
                    </li>
                    <li>
                        <a href="{{route('driver.payouts',$id)}}" class="payout"><i class="ri-bank-card-line"></i> {{trans('lang.tab_payouts')}}</a>
                    </li>
                    <li>
                        <a href="{{route('payoutRequests.drivers.view',$id)}}" class="vendor_payout"><i class="ri-refund-line"></i> {{trans('lang.tab_payout_request')}}</a>
                    </li>
                    <li>
                            <a href="{{route('users.walletstransaction',$id)}}"
                                class="wallet_transaction"><i class="ri-wallet-line"></i> {{trans('lang.wallet_transaction')}}</a>
                    </li>
                </ul>
            </div>  
            <div class="row">
                <div class="col-md-3">
                    <div class="card card-box-with-icon bg--1">
                        <div class="card-body d-flex justify-content-between align-items-center">
                        <div class="card-box-with-content">
                            <h4 class="text-dark-2 mb-1 h4 total_orders" id="total_orders">00</h4>
                            <p class="mb-0 small text-dark-2">{{trans('lang.dashboard_total_orders')}}</p>
                        </div>
                            <span class="box-icon ab"><img src="{{ asset('images/total_rides.png') }}"></span>
                        </div>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="card card-box-with-icon bg--3">
                        <div class="card-body d-flex justify-content-between align-items-center">
                        <div class="card-box-with-content">
                            <h4 class="text-dark-2 mb-1 h4 wallet_balance" id="wallet_balance">$0.00</h4>
                            <p class="mb-0 small text-dark-2">Solde des gains</p>
                        </div>
                            <span class="box-icon ab"><img src="{{ asset('images/total_payment.png') }}"></span>
                        </div>
                    </div>
                </div>
            </div>

            {{-- ── CAISSE CHAUFFEUR (modèle JOXMAKO) ── --}}
            <div class="card border mt-3">
                <div class="card-header border-bottom pb-2 d-flex justify-content-between align-items-center">
                    <h5 class="mb-0">Caisse chauffeur</h5>
                    <div id="cash_remit_action" style="display:none">
                        <button class="btn btn-warning btn-sm" data-toggle="modal" data-target="#cashRemittanceModal">
                            <i class="mdi mdi-cash-check mr-1"></i>Marquer espèces remises
                            <span class="ml-1" id="cash_remit_amount_label"></span>
                        </button>
                    </div>
                </div>
                <div class="card-body pb-2">
                    <div class="row text-center">
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Gains impayés</div>
                            <div class="h5 text-danger mb-0" id="jox_unpaid">—</div>
                        </div>
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Gains payés</div>
                            <div class="h5 text-success mb-0" id="jox_paid">—</div>
                        </div>
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Total collecté</div>
                            <div class="h5 mb-0" id="jox_cash_collected">—</div>
                        </div>
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Espèces à verser</div>
                            <div class="h5 text-warning mb-0" id="jox_cash_pending">—</div>
                        </div>
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Commandes</div>
                            <div class="h5 mb-0" id="jox_orders">—</div>
                        </div>
                        <div class="col-6 col-md-2 mb-3">
                            <div class="text-muted small">Méthode payout</div>
                            <div class="small font-weight-bold mb-0" id="jox_payout_method">—</div>
                        </div>
                    </div>
                    <div id="jox_cash_history" class="mt-2" style="display:none">
                        <small class="text-muted">Historique remises : </small>
                        <span id="jox_cash_history_list" class="small"></span>
                    </div>
                </div>
            </div>

        </div>
        <div class="restaurant_info-section">
          <div class="row">
            <div class="col-md-6">
                <div class="card border h-100">
                    <div class="card-header d-flex justify-content-between align-items-center border-bottom pb-3">
                        <div class="card-header-title">
                            <h3 class="text-dark-2 mb-0 h4">{{trans('lang.driver_details')}}
                                <i class="mdi mdi-verified verified-icon verified-icon-heading ml-2" 
       data-toggle="tooltip" data-bs-original-title="Verified" 
       style="display:none;color: green;"></i>
                            </h3>
                        </div>
                    </div>
            <div class="card-body">
                        <div class="restaurant_info_left">
                            <div class="d-flex mb-1">
                                <div class="sis-img profile_image" id="profile_image">
                                </div>
                                <div class="sis-content pl-4">
                                    <ul class="p-0 info-list mb-0">                                    
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.first_name')}}</label>
                                            <span class="driver_name" id="driver_name"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.email')}}</label>
                                            <span class="email"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.user_phone')}}</label>
                                            <span class="phone"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2 mr-1">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">Solde des gains</label>
                                            <span class="wallet_balance"> </span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2 mr-1">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.service_type')}}</label>
                                            <span class="service_type"> </span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2 mr-1">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.zone_name')}}</label>
                                            <span class="zone_name"> </span>
                                        </li>
                                    </ul>
                                </div>  
                            </div>                            
                        </div>
                </div>
            </div>
            </div>
           <div class="col-md-6">
                <div class="card border h-100">
                    <div class="card-header d-flex justify-content-between align-items-center border-bottom pb-3">
                        <div class="card-header-title">
                            <h3 class="text-dark-2 mb-0 h4">{{trans('lang.bankdetails')}}</h3>
                        </div>
                    </div>
                    <div class="card-body">
                        <div id="noBankData" class="text-muted font-weight-bold py-3" style="display:none;">
                            {{trans("lang.bank_details_not_found")}}
                        </div>
                        <div class="restaurant_info_left" id="bankDetailsBox" style="display:none;">
                            <div class="d-flex mb-1">                              
                                <div class="sis-content">
                                    <ul class="p-0 info-list mb-0">
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.bank_name')}}</label>
                                            <span class="bank_name" id="bank_name"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.branch_name')}}</label>
                                            <span class="branch_name" id="branch_name"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.holer_name')}}</label>
                                            <span class="holer_name" id="holer_name"></span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2 mr-1">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.account_number')}}</label>
                                            <span class="account_number" id="account_number"> </span>
                                        </li>
                                        <li class="d-flex align-items-center mb-2 mr-1">
                                            <label class="mb-0 font-wi font-semibold text-dark-2">{{trans('lang.other_information')}}</label>
                                            <span class="other_information" id="other_information"> </span>
                                        </li>
                                    </ul>
                                </div>  
                            </div>                            
                        </div>
                    </div>
                </div>
            </div>
          </div>  
        </div>
        <!-- Bank detail -->
        <div class="restaurant_info-section">
        </div>
        <div class="form-group col-12 text-center btm-btn">
            <a href="{!! route('drivers') !!}" class="btn btn-default"><i class="fa fa-undo"></i>{{trans('lang.cancel')}}</a>
        </div>
    </div>    
</div>
<div class="modal fade" id="addWalletModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered location_modal">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title locationModalTitle">{{trans('lang.add_wallet_amount')}}</h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
                <form class="">
                    <div class="form-row">
                        <div class="form-group row">
                            <div class="form-group row width-100">
                                <label class="col-12 control-label">{{trans('lang.amount')}}</label>
                                <div class="col-12">
                                    <input type="number" name="amount" class="form-control" id="amount">
                                    <div id="wallet_error" style="color:red"></div>
                                </div>
                            </div>
                            <div class="form-group row width-100">
                                <label class="col-12 control-label">{{trans('lang.note')}}</label>
                                <div class="col-12">
                                    <input type="text" name="note" class="form-control" id="note">
                                </div>
                            </div>
                            <div class="form-group row width-100">
                                <div id="user_account_not_found_error" class="align-items-center" style="color:red">
                                </div>
                            </div>
                        </div>
                    </div>
                </form>
                <div class="modal-footer">
                    <button type="button" class="btn btn-primary save-form-btn" id="add-wallet-btn">{{trans('submit')}}</a>
                    </button>
                    <button type="button" class="btn btn-primary" data-dismiss="modal"
                            aria-label="Close">{{trans('close')}}</a>
                    </button>
                </div>
            </div>
        </div>
    </div>
</div>
<div class="modal fade" id="cashRemittanceModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Confirmer la remise des espèces</h5>
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
            </div>
            <div class="modal-body">
                <p>Le chauffeur a remis <strong id="cash_confirm_amount"></strong> en espèces ?</p>
                <div class="form-group">
                    <label>Note (optionnel)</label>
                    <input type="text" id="cash_remit_note" class="form-control" placeholder="Ex: remis au bureau">
                </div>
                <div id="cash_remit_result" class="mt-2"></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-warning" id="confirm_cash_remit_btn">
                    <i class="mdi mdi-check mr-1"></i>Confirmer la remise
                </button>
                <button type="button" class="btn btn-default" data-dismiss="modal">Annuler</button>
            </div>
        </div>
    </div>
</div>

<div class="modal fade"id="imagePreviewModal" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered location_modal modal-sm">
        <div class="modal-content">
            <div class="modal-header">
<h4 class="modal-title text-dark font-medium" id="modalImageTitle"></h4>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body">
               <img id="previewImage" src="" alt="Image Preview" style="max-width: 100%; height: auto;">
            </div>
        </div>
    </div>
</div>
@endsection
@section('scripts')

    <script type="text/javascript">

        var id = "{{$id}}";  
        var serviceType = getCookie('service_type');    
        
        var database = firebase.firestore();
        var ref = database.collection('users').where("id", "==", id);
        var photo = "";
        var vendorOwnerId = "";
        var vendorOwnerOnline = false;
        var type = '';
        
        var placeholderImage = '';
        var placeholder = database.collection('settings').doc('placeHolderImage');
        placeholder.get().then(async function (snapshotsimage) {
            var placeholderImageData = snapshotsimage.data();
            placeholderImage = placeholderImageData.image;
        });
        
        var currency = database.collection('settings');
        var currentCurrency = '';
        var currencyAtRight = false;
        var decimal_degits = 0;
        var refCurrency = database.collection('currencies').where('isActive', '==', true);
        refCurrency.get().then(async function (snapshots) {
            var currencyData = snapshots.docs[0].data();
            currentCurrency = currencyData.symbol;
            currencyAtRight = currencyData.symbolAtRight;
            if (currencyData.decimal_degits) {
                decimal_degits = currencyData.decimal_degits;
            }
            $(".currentCurrency").text(currencyData.symbol);
        });

        var email_templates = database.collection('email_templates').where('type', '==', 'wallet_topup');
        var emailTemplatesData = null;

        const serviceLabels = {
            "cab-service": "Cab Service",
            "parcel_delivery": "Parcel Delivery Service",
            "rental-service": "Rental Service",
            "delivery-service": "Multivendor Delivery Service",
            "ecommerce-service": "Ecommerce Service",
            "ondemand-service": "On Demand Service"
        };

        $(document).ready(async function () {
            jQuery("#data-table_processing").show();
            if(serviceType !== 'delivery-service' && serviceType !== 'parcel_delivery'){
                $('.vehicle_tab').show();
            }else{
                $('.vehicle_tab').hide();
            }
            await email_templates.get().then(async function (snapshots) {
                emailTemplatesData = snapshots.docs[0].data();
            });

            ref.get().then(async function (snapshots) {
                if(snapshots.docs.length>0){
                
                    var dirver = snapshots.docs[0].data();

                    if (dirver.isDocumentVerify === true) {
                        $('.verified-icon-heading').show();
                    } else {
                        $('.verified-icon-heading').hide();
                    }

                    type = dirver.serviceType;
                    
                    $(".driver_name").text(dirver.firstName);
                    $(".email").text(shortEmail(dirver.email));
                    
                    if(dirver.phoneNumber.includes('+')){
                        $(".phone").text('+' + EditPhoneNumber(dirver.phoneNumber.slice(1)));
                    }else{
                        $(".phone").text(EditPhoneNumber(dirver.phoneNumber));
                    }

                    var wallet_route = "{{route('users.walletstransaction','id')}}";
                    $(".wallet_transaction").attr("href", wallet_route.replace('id', 'driverID='+dirver.id));

                    let serviceTypes = dirver.serviceTypes || (dirver.serviceType ? [dirver.serviceType] : []);
                    let serviceTypeText = serviceTypes.map(type => serviceLabels[type] || type).join(", ");
                    $(".service_type").text(serviceTypeText);
                    
                    if (serviceTypes) {

                        if (serviceTypes.includes("cab-service") && serviceType == "cab-service") {
                            var url = "{{route('drivers.rides','driverId')}}";
                            url = url.replace('driverId', dirver.id);
                            $('.service_type_orders').html('<a href="' + url + '"><i class="ri-shopping-bag-line"></i> {{trans('lang.order_plural')}}</a>');
                        }else if (serviceTypes.includes("rental-service") && serviceType == "rental-service") {
                            var url = "{{route('rental_orders.driver','id')}}";
                            url = url.replace("id", dirver.id);
                            $('.service_type_orders').html('<a href="' + url + '"><i class="ri-shopping-bag-line"></i> {{trans('lang.order_plural')}}</a>');
                        } else if ((serviceTypes.includes("delivery-service") && serviceType == "delivery-service") || (serviceTypes.includes("ecommerce-service") && serviceType == "ecommerce-service")) {
                            var url = "{{route('orders','id')}}";
                            url = url.replace("id", 'driverId=' + dirver.id);
                            $('.service_type_orders').html('<a href="' + url + '"><i class="ri-shopping-bag-line"></i> {{trans('lang.order_plural')}}</a>');
                        } else if (serviceTypes.includes("parcel_delivery")  && serviceType == "parcel_delivery") {
                            var url = "{{route('parcel_orders.driver','id')}}";
                            url = url.replace("id", dirver.id);
                            $('.service_type_orders').html('<a href="' + url + '"><i class="ri-shopping-bag-line"></i> {{trans('lang.order_plural')}}</a>');
                        }

                        let totalOrders = 0;
                        if (serviceTypes.includes("cab-service") && serviceType == "cab-service") {
                            const ordersSnapshot = await database.collection('rides').where('driverId', '==', dirver.id).get();
                            totalOrders += ordersSnapshot.docs.length;
                        }
                        if (serviceTypes.includes("rental-service") && serviceType == "rental-service") {
                            const ordersSnapshot = await database.collection('rental_orders').where('driverId', '==', dirver.id).get();
                            totalOrders += ordersSnapshot.docs.length;
                        } 
                        if ((serviceTypes.includes("delivery-service") && serviceType == "delivery-service") || (serviceTypes.includes("ecommerce-service") && serviceType == "ecommerce-service")) {
                            const ordersSnapshot = await database.collection('vendor_orders').where('driverID', '==', dirver.id).get();
                            totalOrders += ordersSnapshot.docs.length;
                        } 
                        if (serviceTypes.includes("parcel_delivery")  && serviceType == "parcel_delivery") {
                            const ordersSnapshot = await database.collection('parcel_orders').where('driverId', '==', dirver.id).get();
                            totalOrders += ordersSnapshot.docs.length;
                        }

                        $('.total_orders').html(totalOrders);
                    }

                    if (dirver.zoneId) {
                        database.collection('zone').doc(dirver.zoneId).get().then((zoneSnap) => {
                            if (zoneSnap.exists) {
                                const zoneName = zoneSnap.data().name || '';
                                $(".zone_name").text(zoneName);
                            } else {
                                $(".zone_name").text('-');
                            }
                        });
                    }else {
                        $(".zone_name").text('-');
                    }

                    var wallet_balance = 0;
                    if (dirver.hasOwnProperty('wallet_amount') && dirver.wallet_amount != null && !isNaN(dirver.wallet_amount)) {
                        wallet_balance = dirver.wallet_amount;
                    }
                    if (currencyAtRight) {
                        wallet_balance = parseFloat(wallet_balance).toFixed(decimal_degits) + "" + currentCurrency;
                    } else {
                        wallet_balance = currentCurrency + "" + parseFloat(wallet_balance).toFixed(decimal_degits);
                    }
                    
                    $('.wallet_balance').html(wallet_balance);
                    
                    var image = "";
                    if (dirver.profilePictureURL) {
                        if(dirver.profilePictureURL){
                            photo=dirver.profilePictureURL;
                        }else{
                            photo=placeholderImage;
                        }
                        image = '<img width="200px" id="" height="auto" src="' + photo + '" class="clickable-image profile-image" onerror="this.onerror=null;this.src=\'' + placeholderImage + '\'">';
                    } else {
                        image = '<img width="200px" id="" height="auto" src="' + placeholderImage + '" class="clickable-image profile-image">';
                    }
                    $(".profile_image").html(image);
                    
                
                    $('.clickable-image').on('click', function () {
                        var imageSrc = $(this).attr('src');
                        var $parentBox = $(this).closest('.driver-detail-box');
                        var headingText;
                        if ($(this).hasClass('profile-image')) {
                            headingText = 'Profile Image';
                        } else if ($(this).hasClass('vehicle-profile-image')) {
                            headingText = $parentBox.find('h4').text() || 'Vehicle Profile Image';
                        } else if ($(this).hasClass('driver-proof-image')) {
                            headingText = $parentBox.find('h4').text() || 'Driver Proof Image';
                        } else if ($(this).hasClass('vehicle-proof-image')) {
                            headingText = $parentBox.find('h4').text() || 'Vehicle Proof Image';
                        } else {
                            headingText = 'Image Preview';
                        }
                        $('#previewImage').attr('src', imageSrc);
                        $('#modalImageTitle').text(headingText);
                        $('#imagePreviewModal').modal('show');
                    });

                    $('.close, [data-dismiss="modal"]').on('click', function () {
                        $('#imagePreviewModal').modal('hide');
                    });
                
                    if (dirver.hasOwnProperty('userBankDetails') && dirver.userBankDetails != null) {
                        
                        $(".bank_name").text(dirver.userBankDetails.bankName);
                        
                        if (dirver.userBankDetails.hasOwnProperty('branchName')) {
                            $(".branch_name").text(dirver.userBankDetails.branchName);
                        }
                        if (dirver.userBankDetails.hasOwnProperty('holderName')) {
                            $(".holer_name").text(dirver.userBankDetails.holderName);
                        }
                        if (dirver.userBankDetails.hasOwnProperty('accountNumber')) {
                            $(".account_number").text(dirver.userBankDetails.accountNumber);
                        }
                        if (dirver.userBankDetails.hasOwnProperty('otherDetails')) {
                            $(".other_information").text(dirver.userBankDetails.otherDetails);
                        }
                        if (
                            !dirver.userBankDetails.bankName &&
                            !dirver.userBankDetails.branchName &&
                            !dirver.userBankDetails.holder_naholderNameme &&
                            !dirver.userBankDetails.accountNumber &&
                            !dirver.userBankDetails.otherDetails
                        ) {
                            $("#bankDetailsBox").hide();
                            $("#noBankData").show();
                        } else {
                            $("#bankDetailsBox").show();
                            $("#noBankData").hide();
                        }
                    } else {
                        $("#bankDetailsBox").hide();
                        $("#noBankData").show();
                    }

                } else{
                    $('.driver_detail_div').html('<h5 class="font-weight-bold align text-danger text-center">{{trans('lang.driver_unknown_deleted')}}</h5>')
                }
                
                jQuery("#data-table_processing").hide();
            })
        });
        // });
        $("#add-wallet-btn").click(function () {
            var date = firebase.firestore.FieldValue.serverTimestamp();
            var amount = $('#amount').val();
            if (amount == '' || amount <= 0) {
                $('#wallet_error').text('{{trans("lang.add_wallet_amount_error")}}');
                return false;
            }
            var note = $('#note').val();
            database.collection('users').where('id', '==', id).get().then(async function (snapshot) {
                if (snapshot.docs.length > 0) {
                    var data = snapshot.docs[0].data();
                    var walletAmount = 0;
                    if (data.hasOwnProperty('wallet_amount') && !isNaN(data.wallet_amount) && data.wallet_amount != null) {
                        walletAmount = data.wallet_amount;
                    }
                    var user_id = data.id;
                    var newWalletAmount = parseFloat(walletAmount) + parseFloat(amount);
                    database.collection('users').doc(id).update({
                        'wallet_amount': newWalletAmount
                    }).then(function (result) {
                        var tempId = database.collection("tmp").doc().id;
                        database.collection('wallet').doc(tempId).set({
                            'amount': parseFloat(amount),
                            'date': date,
                            'isTopUp': true,
                            'id': tempId,
                            'order_id': '',
                            'payment_method': 'Wallet',
                            'payment_status': 'success',
                            'user_id': user_id,
                            'note': note,
                            'transactionUser': "driver",
                        }).then(async function (result) {
                            if (currencyAtRight) {
                                amount = parseInt(amount).toFixed(decimal_degits) + "" + currentCurrency;
                                newWalletAmount = newWalletAmount.toFixed(decimal_degits) + "" + currentCurrency;
                            } else {
                                amount = currentCurrency + "" + parseInt(amount).toFixed(decimal_degits);
                                newWalletAmount = currentCurrency + "" + newWalletAmount.toFixed(decimal_degits);
                            }
                            var formattedDate = new Date();
                            var month = formattedDate.getMonth() + 1;
                            var day = formattedDate.getDate();
                            var year = formattedDate.getFullYear();
                            month = month < 10 ? '0' + month : month;
                            day = day < 10 ? '0' + day : day;
                            formattedDate = day + '-' + month + '-' + year;
                            var message = emailTemplatesData.message;
                            message = message.replace(/{username}/g, data.firstName + ' ' + data.lastName);
                            message = message.replace(/{date}/g, formattedDate);
                            message = message.replace(/{amount}/g, amount);
                            message = message.replace(/{paymentmethod}/g, 'Wallet');
                            message = message.replace(/{transactionid}/g, tempId);
                            message = message.replace(/{newwalletbalance}/g, newWalletAmount);
                            emailTemplatesData.message = message;
                            var url = "{{url('send-email')}}";
                            if(data.email != '' && data.email != null){
                            var sendEmailStatus = await sendEmail(url, emailTemplatesData.subject, emailTemplatesData.message, [data.email]);
                            if (sendEmailStatus) {
                                window.location.reload();
                            }
                        }else{
                            window.location.reload();
                        }
                        })
                    })
                } else {
                    $('#user_account_not_found_error').text('{{trans("lang.user_detail_not_found")}}');
                }
            });
        });

        // ── JOXMAKO Caisse chauffeur ──────────────────────────────────────
        var _jox_pendingOrderIds = [];
        var _jox_cashPending     = 0;
        var _jox_driverName      = '';

        function joxFmt(v) {
            var n = parseFloat(v || 0);
            return currencyAtRight
                ? n.toFixed(decimal_degits) + currentCurrency
                : currentCurrency + n.toFixed(decimal_degits);
        }

        function joxPaymentLabel(m) {
            return formatPaymentMethod(m);
        }

        async function initJoxmakoSection() {
            // User + payout method
            var userSnap = await database.collection('users').where('id', '==', id).get();
            if (!userSnap.empty) {
                var u = userSnap.docs[0].data();
                _jox_driverName = (u.firstName || '') + ' ' + (u.lastName || '');
                var payMethod = (u.userBankDetails && u.userBankDetails.bankName) ? u.userBankDetails.bankName : '';
                var payNumber = (u.userBankDetails && u.userBankDetails.accountNumber) ? u.userBankDetails.accountNumber : '';
                if (payMethod || payNumber) {
                    $('#jox_payout_method').text((payMethod || '-') + (payNumber ? ' · ' + payNumber : ''));
                }
            }

            // Commandes terminées
            var snap = await database.collection('vendor_orders')
                .where('driverID', '==', id)
                .where('status', '==', 'Order Completed')
                .get();

            var unpaid = 0, paid = 0, totalCollected = 0, cashPending = 0;
            _jox_pendingOrderIds = [];

            snap.docs.forEach(function(doc) {
                var d = doc.data();
                var earning = parseFloat(d.driver_earning || 0);

                if (d.driver_payout_status === 'unpaid') unpaid += earning;
                else if (d.driver_payout_status === 'paid') paid += earning;

                // Total collecté brut
                var method = String(d.collected_payment_method || d.payment_method || '').toLowerCase();
                var isCashPayment = method === 'cash' || method === 'cod' || method === 'cash_on_delivery';
                totalCollected += parseFloat(
                    d.total_collected ||
                    d.totalCollected ||
                    d.cash_collected_amount ||
                    d.total_amount ||
                    d.totalAmount ||
                    d.total_price ||
                    d.totalPrice ||
                    0
                );

                // Espèces à verser
                var isPending = isCashPayment && d.cash_remittance_status === 'pending';
                var isLegacy  = isCashPayment && !d.cash_remittance_status;
                if (isPending || isLegacy) {
                    cashPending += parseFloat(d.cash_to_remit || 0);
                    _jox_pendingOrderIds.push(doc.id);
                }
            });

            _jox_cashPending = cashPending;

            $('#jox_unpaid').text(joxFmt(unpaid));
            $('#jox_paid').text(joxFmt(paid));
            $('#jox_cash_collected').text(joxFmt(totalCollected));
            $('#jox_cash_pending').text(cashPending > 0 ? joxFmt(cashPending) : '0');
            $('#jox_orders').text(snap.docs.length);

            if (cashPending > 0) {
                $('#cash_confirm_amount').text(joxFmt(cashPending));
                $('#cash_remit_amount_label').text('(' + joxFmt(cashPending) + ')');
                $('#cash_remit_action').show();
            }

            // Historique remises
            var ledgerSnap = await database.collection('cash_remittance_ledger')
                .where('driver_id', '==', id)
                .get();
            if (!ledgerSnap.empty) {
                var items = [];
                ledgerSnap.docs.forEach(function(doc) {
                    var l = doc.data();
                    var d = l.received_at ? l.received_at.toDate().toLocaleDateString('fr-FR') : '-';
                    items.push(d + ' : ' + joxFmt(l.amount_remitted));
                });
                $('#jox_cash_history_list').text(items.join(' | '));
                $('#jox_cash_history').show();
            }
        }

        // Confirmer remise espèces
        $('#confirm_cash_remit_btn').on('click', async function() {
            if (!_jox_pendingOrderIds.length) {
                $('#cash_remit_result').html('<div class="alert alert-warning">Aucune commande en attente.</div>');
                return;
            }
            $(this).prop('disabled', true).text('Enregistrement…');
            var note = $('#cash_remit_note').val().trim();
            var now  = firebase.firestore.FieldValue.serverTimestamp();
            var ledgerId = database.collection('tmp').doc().id;
            var adminId  = '{{ auth()->id() }}';

            try {
                // 1. Créer cash_remittance_ledger
                await database.collection('cash_remittance_ledger').doc(ledgerId).set({
                    id:                  ledgerId,
                    driver_id:           id,
                    driver_name:         _jox_driverName,
                    amount_remitted:     _jox_cashPending,
                    covered_order_ids:   _jox_pendingOrderIds,
                    status:              'remitted',
                    received_by_admin_id: adminId,
                    received_at:         now,
                    note:                note || null,
                    createdAt:           now,
                });

                // 2. Mettre à jour les commandes
                var batch = database.batch();
                _jox_pendingOrderIds.forEach(function(oid) {
                    batch.update(database.collection('vendor_orders').doc(oid), {
                        cash_remittance_status:     'remitted',
                        cash_remitted_at:           now,
                        cash_received_by_admin_id:  adminId,
                        cash_remittance_id:         ledgerId,
                    });
                });
                await batch.commit();

                $('#cash_remit_result').html('<div class="alert alert-success">✅ ' + joxFmt(_jox_cashPending) + ' marqués comme remis.</div>');
                $('#confirm_cash_remit_btn').text('Remis ✓');
                $('#cash_remit_action').hide();
                $('#jox_cash_pending').text('0');
                setTimeout(function() { $('#cashRemittanceModal').modal('hide'); window.location.reload(); }, 2000);

            } catch(e) {
                console.error(e);
                $('#cash_remit_result').html('<div class="alert alert-danger">Erreur : ' + e.message + '</div>');
                $('#confirm_cash_remit_btn').prop('disabled', false).text('Confirmer la remise');
            }
        });

        // Lancer JOXMAKO section après le chargement initial
        $(document).ready(function() { initJoxmakoSection(); });

    </script>
@endsection
