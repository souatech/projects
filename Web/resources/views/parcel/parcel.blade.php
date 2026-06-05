@include('layouts.app')
@include('layouts.header')
@php
    $countries = file_get_contents(public_path('countriesdata.json'));
    $countries = json_decode($countries);
    $countries = (array)$countries;
    $newcountries = array();
    $newcountriesjs = array();
    foreach ($countries as $keycountry => $valuecountry) {
        $newcountries[$valuecountry->phoneCode] = $valuecountry;
        $newcountriesjs[$valuecountry->phoneCode] = $valuecountry->code;
    }
@endphp
<div class="siddhi-home-page">
    <div class="bg-primary px-3 d-none mobile-filter pb-3">
        <div class="row align-items-center">
            <div class="input-group rounded shadow-sm overflow-hidden col-md-9 col-sm-9">
                <div class="input-group-prepend">
                    <button class="border-0 btn btn-outline-secondary text-dark bg-white btn-block"><i
                                class="feather-search"></i></button>
                </div>
                <input type="text" class="shadow-none border-0 form-control" placeholder="Search for vendors or dishes">
            </div>
            <div class="text-white col-md-3 col-sm-3">
                <div class="title d-flex align-items-center">
                    <a class="text-white font-weight-bold ml-auto" data-toggle="modal" data-target="#exampleModal"
                       href="#">{{trans('lang.filter')}}</a>
                </div>
            </div>
        </div>
    </div>
    <div class="parcel_delivery_content mt-5 mb-5">
        <section id="tabs">
            <div class="container">
                <div class="parcel_delivery">
                    <div class="error_top"></div>
                    <input type="hidden" class="form-control" value="" id="parcelType" name="parcelType">
                    <nav>
                        <div class="nav nav-tabs nav-fill" id="nav-tab" role="tablist">
                            <a class="nav-item nav-link active" id="nav-home-tab" data-toggle="tab"
                               href="#as-soon-as-possible" role="tab" aria-controls="as-soon-as-possible"
                               aria-selected="true"><img
                                        src="{{asset('img/asap_unselected.png')}}">{{trans('lang.as_soon_as_possible')}}
                            </a>
                            <a class="nav-item nav-link" id="nav-profile-tab" data-toggle="tab" href="#schedule"
                               role="tab" aria-controls="schedule" aria-selected="false"><img
                                        src="{{asset('img/schedule_unselected.png')}}"> {{trans('lang.schedule')}}</a>
                        </div>
                    </nav> 
                    <div class="tab-content" id="nav-tabContent">
                        <div class="tab-pane fade show active" id="as-soon-as-possible" role="tabpanel"
                             aria-labelledby="nav-home-tab">
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>1</span>{{trans('lang.sender_info')}}</h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <div class="input-group">
                                            <input type="text" class="form-control senderAddress" value=""
                                                   id="senderAddress"
                                                   name="address" required="" placeholder=" ">
                                            <div class="input-group-append">
                                                <button type="button" class="btn btn-outline-secondary gps-btn" title="{{ trans('lang.use_my_location') }}">
                                                    <i class="feather-navigation"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <span for="exampleFormControlInput1"></span>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control senderName" value="" name="name"
                                               required="" placeholder=" ">
                                        <span for="exampleFormControlInput2">{{trans('lang.sender_name')}}</span>
                                    </div>

                                    <div class="inputField col-md-6 phone-box">
                                        <div class="col-xs-12">
                                            <select class="form-control country_selector" name="senderPhoneCountry" id="senderPhoneCountry">
                                                <?php foreach ($newcountries as $keycy => $valuecy) { ?>
                                                    <option code="<?php echo $valuecy->code; ?>" value="<?php echo $keycy; ?>">+<?php echo $valuecy->phoneCode; ?> <?php echo $valuecy->countryName; ?></option>
                                                <?php } ?>
                                            </select>
                                            <input type="text" class="form-control senderPhone" required="" placeholder=" ">
                                            <span for="exampleFormControlInput3">{{trans('lang.phone_number')}}</span>
                                        </div>
                                    </div>
                                    
                                    <div class="inputField col-md-6">
                                        <label for="exampleFormControlTextarea1"></label>
                                        <br><br>
                                        <select class="form-control senderParcelWeight"
                                                style="border-top:none;border-left:none;border-right:none;">
                                            <option value="">{{trans('lang.select')}} {{trans('lang.parcel_weight')}}</option>
                                        </select>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control senderNote" 
                                               placeholder=" ">
                                        <span for="exampleFormControlTextarea1">{{trans('lang.note')}}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>2</span> {{trans('lang.receiver_info')}}</h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control receiverAddress" value=""
                                               id="receiver_address" name="address" required="" placeholder=" ">
                                        <span for="exampleFormControlInput1">{{trans('lang.receiver_address')}}</span>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="email" class="form-control receiverName" value="" name="name"
                                               required="" placeholder=" ">
                                        <span for="exampleFormControlInput2">{{trans('lang.sender_name')}}</span>
                                    </div>
                                    <div class="inputField col-md-6 phone-box">
                                        <div class="col-xs-12">
                                            <select class="form-control country_selector" name="receiverPhoneCountry" id="receiverPhoneCountry">
                                                <?php foreach ($newcountries as $keycy => $valuecy) { ?>
                                                    <option code="<?php echo $valuecy->code; ?>" value="<?php echo $keycy; ?>">+<?php echo $valuecy->phoneCode; ?> <?php echo $valuecy->countryName; ?></option>
                                                <?php } ?>
                                            </select>
                                            <input type="text" class="form-control receiverPhone" required="" placeholder="">
                                            <span for="exampleFormControlInput3">{{trans('lang.phone_number')}}</span>
                                        </div>
                                    </div>
                                     <div class="inputField col-md-6">
                                        <input type="text" class="form-control receiverNote" 
                                               placeholder=" ">
                                        <span for="exampleFormControlTextarea1">{{trans('lang.note')}}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>3</span> {{trans('lang.upload_parcel_image')}}</h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <div class="parcelImageUploadDiv">
                                            <input type="file" onChange="handleFileSelect(event)" class="col-7">
                                            <div class="uploding_image_photos"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group row width-50">
                                    <div class="appendParcelImages">
                                    </div>
                                </div>
                            </div>
                            <div class="tab-btn">
                                <button type="button"
                                        class="btn btn-primary parcel_btn">{{trans('lang.continue')}}</button>
                            </div>
                        </div>
                        <div class="tab-pane fade" id="schedule" role="tabpanel" aria-labelledby="nav-profile-tab">
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>1</span>{{trans('lang.sender_info')}}</h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <div class="input-group">
                                            <input type="text"
                                                   class="form-control senderAddress sender_address pac-target-input"
                                                   value=""
                                                   id="sender_address_schedule"
                                                   name="address" required="" placeholder=" ">
                                            <div class="input-group-append">
                                                <button type="button" class="btn btn-outline-secondary gps-btn" title="{{ trans('lang.use_my_location') }}">
                                                    <i class="feather-navigation"></i>
                                                </button>
                                            </div>
                                        </div>
                                        <span for="exampleFormControlInput1"></span>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="email" class="form-control senderName" value="" name="name"
                                               required="" placeholder=" ">
                                        <span for="exampleFormControlInput2">{{trans('lang.sender_name')}}</span>
                                    </div>
                                    <div class="inputField col-md-6 phone-box">
                                        <div class="col-xs-12">
                                            <select class="form-control country_selector" name="senderPhoneCountry" id="senderPhoneCountry">
                                                <?php foreach ($newcountries as $keycy => $valuecy) { ?>
                                                    <option code="<?php echo $valuecy->code; ?>" value="<?php echo $keycy; ?>">+<?php echo $valuecy->phoneCode; ?> <?php echo $valuecy->countryName; ?></option>
                                                <?php } ?>
                                            </select>
                                            <input type="text" class="form-control senderPhone" required="" placeholder=" ">
                                            <span for="exampleFormControlInput3">{{trans('lang.phone_number')}}</span>
                                        </div>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <label for="exampleFormControlTextarea1"></label>
                                        <br><br>
                                        <select class="form-control senderParcelWeight"
                                                style="border-top:none;border-left:none;border-right:none;">
                                            <option value="">{{trans('lang.select')}} {{trans('lang.parcel_weight')}}</option>
                                        </select>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="datetime-local" class="form-control senderArrive" required=""
                                               placeholder="Select date & time">
                                        <span for="exampleFormControlTextarea1">{{trans('lang.when_pickup_address')}}</span>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control senderNote" 
                                               placeholder=" ">
                                        <span for="exampleFormControlTextarea1">{{trans('lang.note')}}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>2</span> {{trans('lang.receiver_info')}} </h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control receiverAddress" value=""
                                               id="receiver_address_schedule" name="address" required=""
                                               placeholder="">
                                        <span for="exampleFormControlInput1">{{trans('lang.receiver_address')}}</span>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="email" class="form-control receiverName" value="" name="name"
                                               required="" placeholder=" ">
                                        <span for="exampleFormControlInput2">{{trans('lang.sender_name')}}</span>
                                    </div>
                                    <div class="inputField col-md-6 phone-box">
                                        <div class="col-xs-12">
                                            <select class="form-control country_selector" name="receiverPhoneCountry" id="receiverPhoneCountry">
                                                <?php foreach ($newcountries as $keycy => $valuecy) { ?>
                                                    <option code="<?php echo $valuecy->code; ?>" value="<?php echo $keycy; ?>">+<?php echo $valuecy->phoneCode; ?> <?php echo $valuecy->countryName; ?></option>
                                                <?php } ?>
                                            </select>
                                            <input type="text" class="form-control receiverPhone" required="" placeholder=" ">
                                            <span for="exampleFormControlInput3">{{trans('lang.phone_number')}}</span>
                                        </div>
                                    </div>
                                    <div class="inputField col-md-6">
                                        <input type="text" class="form-control receiverNote" 
                                               placeholder=" ">
                                        <span for="exampleFormControlTextarea1">{{trans('lang.note')}}</span>
                                    </div>
                                </div>
                            </div>
                            <div class="tab-inner">
                                <div class="tab-title sende-title">
                                    <h3><span>3</span> {{trans('lang.upload_parcel_image')}}</h3>
                                </div>
                                <div class="row">
                                    <div class="inputField col-md-6">
                                        <div class="parcelImageUploadDiv">
                                            <input type="file" onChange="handleFileSelect(event)" class="col-7">
                                            <div class="uploding_image_photos"></div>
                                        </div>
                                    </div>
                                </div>
                                <div class="form-group row width-50">
                                    <div class="appendParcelImages">
                                    </div>
                                </div>
                            </div>
                            <div class="tab-btn">
                                <button type="button" class="btn btn-primary parcel_btn">Continue</button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>
</div>
@include('layouts.footer')

<script src="{{ asset('js/geofirestore.js') }}"></script>
<script src="https://cdn.firebase.com/libs/geofire/5.0.1/geofire.min.js"></script>
<script type="text/javascript" src="{{asset('vendor/slick/slick.min.js')}}"></script>

<script type="text/javascript">

    var section_id = "<?php echo @$_COOKIE['section_id'] ?>";
    var parcelType = '';
    var parcelServiceType = '';

    var parcelcatref = database.collection('parcel_categories').where('id', '==', '<?php echo $id; ?>');
    parcelcatref.get().then(async function (snapshots) {
        var categoryData = snapshots.docs[0].data();
        parcelType = categoryData.title;
        $('#parcelType').val(parcelType);

        var rawType = categoryData.type || categoryData.serviceType || '';
        var titleLower = parcelType.toLowerCase();
        if (rawType === 'parcel_delivery' || titleLower.includes('express')) {
            parcelServiceType = 'parcel_delivery';
            $('.senderParcelWeight').closest('.inputField').hide();
            applyExpressWeight();
        } else if (rawType === 'colis_gp' || titleLower.includes('colis') || titleLower.includes('gp')) {
            parcelServiceType = 'colis_gp';
            // Hide receiver address input, inject fixed Paris destination
            $('.receiverAddress').closest('.inputField').hide().after(
                '<div class="inputField col-md-6 gp-destination-display">' +
                '<div class="p-3 border rounded bg-light">' +
                '<p class="mb-1 font-weight-bold">📍 {{ trans("lang.destination") }}</p>' +
                '<p class="mb-1 font-weight-bold">Paris 75018, France 🇫🇷</p>' +
                '<small class="text-muted">{{ trans("lang.parcel_gp_fixed_destination") }}</small>' +
                '</div></div>'
            );
            // Info message under weight dropdown
            $('.senderParcelWeight').after(
                '<small class="text-muted d-block mt-1">' +
                "{!! trans('lang.parcel_gp_price_estimate') !!}" +
                '</small>'
            );
        }
    });

    function applyExpressWeight() {
        if (parcelServiceType !== 'parcel_delivery') return;
        var $opt = $('.senderParcelWeight option').filter(function() {
            return $(this).text().toLowerCase().includes('express');
        });
        if ($opt.length) {
            $('.senderParcelWeight').val($opt.first().val());
        }
    }

    var parcelWeightRef = database.collection('parcel_weight');
    var parcelImages = [];
    var parcelImagesCount = 0;
    
    var currencyData = '';
    var currentCurrency = '';
    var currencyAtRight = false;
    var decimal_degits = 0;

    var refCurrency = database.collection('currencies').where('isActive', '==', true);
    refCurrency.get().then(async function (snapshots) {
        currencyData = snapshots.docs[0].data();
        currentCurrency = currencyData.symbol;
        currencyAtRight = currencyData.symbolAtRight;
        if (currencyData.decimal_degits) {
            decimal_degits = currencyData.decimal_degits;
        }
    });
    
    parcelWeightRef.get().then(async function (parcelWeightSnapshots) {
        parcelWeightSnapshots.docs.forEach((listval) => {
            var data = listval.data();
            $('.senderParcelWeight').append($("<option></option>")
                .attr("value", data.id)
                .text(data.title)
                .attr("delivery_charge", data.delivery_charge));
        });
        applyExpressWeight();
    });
    
    var taxScope = 'order';
    let userCountry = getCookie('userCountryName');
    const scopes = ['order', 'platform'];
    const taxesByScope = {};
    database.collection('tax').where('country', '==', userCountry).where('enable', '==', true).where('scope', 'in', scopes).where('sectionId', '==', section_id).get().then(snapshot => {
        snapshot.forEach(doc => {
            const tax = doc.data();
            (taxesByScope[tax.scope] ??= []).push(tax);
        });
    });
    
    var platformCharge = '0';
    let platformFeeSettings = JSON.parse(localStorage.getItem('platformFeeSettings'));
    if (platformFeeSettings && platformFeeSettings.enable) {
        platformCharge = platformFeeSettings.fee;
    }
    
    var address_name = getCookie('address_name');
    let sender_address_lng = getCookie('address_lng');
    let sender_address_lat = getCookie('address_lat');
    let receiver_address_lng = "";
    let receiver_address_lat = "";
    
    if (address_name != undefined) {
        $('.active').find('.senderAddress').val(address_name);
    }
    
    let activeTabId = $('.active').attr('href');
    $(document).on('click', '.nav-item', function () {
        activeTabId = $(this).attr('href');
        $(activeTabId).find('.senderAddress').val(address_name);
    });

    async function getSenderAddress(callback) {

        var senderAddress = $(activeTabId).find('.senderAddress').val();
        if(mapType == 'google'){
            
            var geocoder = new google.maps.Geocoder();
            geocoder.geocode({'address': senderAddress}, function (results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    sender_address_lat = results[0].geometry.location.lat();
                    sender_address_lng = results[0].geometry.location.lng();
                    callback(true);
                }
            });
        }else{       
        
            var nominatimUrl = 'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&q=' + encodeURIComponent(senderAddress);

           fetch(nominatimUrl)
            .then(response => response.json())
            .then(data => {
                if (data && data.length > 0) {
                // pick best match with address type
                let best = data.find(item => 
                    item.type === 'house' || item.type === 'road' || item.type === 'neighbourhood'
                ) || data[0];
                
                sender_address_lat = parseFloat(best.lat);
                sender_address_lng = parseFloat(best.lon);
                callback(true);
                }
            })
            .catch(error => {
                console.error("Geocoding failed:", error);
            });
        }
    }

    async function getReceiverAddress(callback) {
        if (parcelServiceType === 'colis_gp') {
            receiver_address_lat = 48.8876;
            receiver_address_lng = 2.3469;
            callback(true);
            return;
        }
        var receiverAddress = $(activeTabId).find('.receiverAddress').val();
        if(mapType == 'google'){
            var geocoder = new google.maps.Geocoder();
            geocoder.geocode({'address': receiverAddress}, function (results, status) {
                if (status == google.maps.GeocoderStatus.OK) {
                    receiver_address_lat = results[0].geometry.location.lat();
                    receiver_address_lng = results[0].geometry.location.lng();
                    callback(true);
                }
            });
        }else{
        var nominatimUrl = 'https://nominatim.openstreetmap.org/search?format=json&addressdetails=1&limit=5&q=' + encodeURIComponent(receiverAddress);
           fetch(nominatimUrl)
            .then(response => response.json())
            .then(data => {
                if (data && data.length > 0) {
                // pick best match with address type
                let best = data.find(item => 
                    item.type === 'house' || item.type === 'road' || item.type === 'neighbourhood'
                ) || data[0];
                
                receiver_address_lat = parseFloat(best.lat);
                receiver_address_lng = parseFloat(best.lon);
                callback(true);
                }
            })
            .catch(error => {
                console.error("Geocoding failed:", error);
            });
        }
    }

    $(document).on('click', '.parcel_btn', async function () {

        var senderAddress = $(activeTabId).find('.senderAddress').val();
        var senderName = $(activeTabId).find('.senderName').val();
        var senderPhoneCountry = $(activeTabId).find('#senderPhoneCountry').val();
        var senderPhone = $(activeTabId).find('.senderPhone').val();
        var senderParcelWeight = $(activeTabId).find('.senderParcelWeight option:selected').val();
        var senderParcelWeightName = $(activeTabId).find('.senderParcelWeight option:selected').text();
        var delivery_charge = $(activeTabId).find('.senderParcelWeight option:selected').attr('delivery_charge');
        if (parcelServiceType === 'colis_gp') {
            delivery_charge = parseFloat(delivery_charge || 0) + 2000;
        }
        var senderNote = $(activeTabId).find('.senderNote').val();
        var receiverNote = $(activeTabId).find('.receiverNote').val();
        let senderPickupDateTime = "";
        let receiverPickupDateTime = "";
        var receiverAddress = $(activeTabId).find('.receiverAddress').val();
        if (parcelServiceType === 'colis_gp') {
            receiverAddress = 'Paris 75018, France';
        }
        var receiverName = $(activeTabId).find('.receiverName').val();
        var receiverPhoneCountry = $(activeTabId).find('#receiverPhoneCountry').val();
        var receiverPhone = $(activeTabId).find('.receiverPhone').val();
        var parcelType = $("#parcelType").val();
        var parcelCategoryId = '<?php echo $id; ?>';
        var isSchedule = false;
      
        getSenderAddress(async function (response) {
            getReceiverAddress(async function (response) {

                let sender_zone_id = await getUserZoneId(sender_address_lat, sender_address_lng);
                if (!sender_zone_id) {
                    $(".error_top").show().html("<p>{{ trans('lang.sender_zone_error') }}</p>");
                    window.scrollTo(0, 0);
                    return false;
                }
                let receiver_zone_id = await getUserZoneId(receiver_address_lat, receiver_address_lng);

                if (!receiver_zone_id) {
                    if (parcelServiceType !== 'colis_gp') {
                        $(".error_top").show().html("<p>{{ trans('lang.receiver_zone_error') }}</p>");
                        window.scrollTo(0, 0);
                        return false;
                    }
                    receiver_zone_id = sender_zone_id;
                }

                if (activeTabId == "#schedule") {
                    isSchedule = true;
                    senderPickupDateTime = new Date($(activeTabId).find('.senderArrive').val());
                }

                if (senderAddress.trim() === receiverAddress.trim()) {
                    $(".error_top").show().html("<p>{{ trans('lang.parcel_same_address_error') }}</p>");
                    window.scrollTo(0, 0);
                    return false;
                }

                if (senderAddress == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.sender_address_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (senderName == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.sender_name_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (senderPhone == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.sender_phone_error')}}</p>");
                    window.scrollTo(0, 0);
                }else if (!/^\d+$/.test(senderPhone)) {
                    $(".error_top").show().html("<p>{{trans('lang.phone_contains_numbers_only')}}</p>");
                    window.scrollTo(0, 0);
                }else if (parcelServiceType !== 'parcel_delivery' && senderParcelWeight == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.sender_parcel_weight_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (activeTabId == "#schedule" && senderPickupDateTime == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.when_pickup_address_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (receiverAddress == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.receiver_address_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (receiverName == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.receiver_name_error')}}</p>");
                    window.scrollTo(0, 0);
                } else if (receiverPhone == "") {
                    $(".error_top").show();
                    $(".error_top").html("");
                    $(".error_top").append("<p>{{trans('lang.receiver_phone_error')}}</p>");
                    window.scrollTo(0, 0);
                }else if (!/^\d+$/.test(receiverPhone)) {
                    $(".error_top").show().html("<p>{{trans('lang.phone_contains_numbers_only')}}</p>");
                    window.scrollTo(0, 0);
                } else {

                    const payload = {
                            _token: '<?php echo csrf_token(); ?>',
                            section_id,
                            parcelCategoryId,
                            parcelType,
                            isSchedule,
                            senderAddress,
                            senderName,
                            senderPhone: '(+'+senderPhoneCountry+') '+senderPhone,
                            senderParcelWeight,
                            senderParcelWeightName,
                            senderNote,
                            receiverNote,
                            senderPickupDateTime,
                            receiverPickupDateTime,
                            receiverAddress,
                            receiverName,
                            receiverPhone: '(+'+receiverPhoneCountry+') '+receiverPhone,
                            sender_address_lng,
                            sender_address_lat,
                            receiver_address_lng,
                            receiver_address_lat,
                            delivery_charge,
                            parcel_service_type: parcelServiceType,
                            discount: 0,
                            parcelImages: JSON.stringify(parcelImages),
                            decimal_degits: decimal_degits,
                            senderZoneId: sender_zone_id,
                            receiverZoneId: receiver_zone_id,
                            mapType: mapType,
                            taxScope,
                            taxesByScope,
                            platformCharge,
                            currencyData,
                    };

                    $.ajax({
                        type: 'POST',
                        url: "<?php echo route('parcel_cart'); ?>",
                        contentType: 'application/json',
                        dataType: 'json',
                        data: JSON.stringify(payload),
                        success: function (data) {
                            var url = "{{ route('parcel_checkout')}}";
                            window.location.href = url;
                        }
                    });
                }
            });
        });
    });
    var storageRef = firebase.storage().ref('images');

    function handleFileSelect(evt) {
        var f = evt.target.files[0];
        var reader = new FileReader();
        reader.onload = (function (theFile) {
            return function (e) {
                var filePayload = e.target.result;
                var hash = CryptoJS.SHA256(Math.random() + CryptoJS.SHA256(filePayload));
                var val = f.name;
                var ext = val.split('.')[1];
                var docName = val.split('fakepath')[1];
                var filename = (f.name).replace(/C:\\fakepath\\/i, '')
                var timestamp = Number(new Date());
                var filename = filename.split('.')[0] + "_" + timestamp + '.' + ext;
                var uploadTask = storageRef.child(filename).put(theFile);
                uploadTask.on('state_changed', function (snapshot) {
                    var progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
                    console.log('Upload is ' + progress + '% done');
                    $(activeTabId).find(".uploding_image_photos").text("Image is uploading...");
                }, function (error) {
                }, function () {
                    uploadTask.snapshot.ref.getDownloadURL().then(function (downloadURL) {
                        $(activeTabId).find(".uploding_image_photos").text("Upload is completed");
                        if (downloadURL) {
                            parcelImagesCount++;
                            photos_html = '<div id="parcelPhotos"><span class="image-item" id="photo_' + parcelImagesCount + '"><span class="remove-btn" data-id="' + parcelImagesCount + '" data-img="' + downloadURL + '"><i class="fa fa-remove"></i></span><img width="100px" id="" height="auto" src="' + downloadURL + '"></span></div>';
                            $(activeTabId).find(".appendParcelImages").append(photos_html);
                            parcelImages.push(downloadURL);
                        }
                    });
                });
            };
        })(f);
        reader.readAsDataURL(f);
    }

    $(document).on("click", ".remove-btn", function () {
        var id = $(this).attr('data-id');
        var photo_remove = $(this).attr('data-img');
        $("#photo_" + id).remove();
        index = parcelImages.indexOf(photo_remove);
        if (index > -1) {
            parcelImages.splice(index, 1);
        }
    });

    var newcountriesjs = '<?php echo json_encode($newcountriesjs); ?>';
    var newcountriesjs = JSON.parse(newcountriesjs);
    
    function formatState(state) {
        if (!state.id) {
            return state.text;
        }
        var baseUrl = "<?php echo URL::to('/'); ?>/flags/120/";
        var $state = $(
            '<span><img src="' + baseUrl + '/' + newcountriesjs[state.element.value].toLowerCase() + '.png" class="img-flag" /> ' + state.text + '</span>'
        );
        return $state;
    }

    function formatState2(state) {
        if (!state.id) {
            return state.text;
        }
        var baseUrl = "<?php echo URL::to('/'); ?>/flags/120/"
        var $state = $(
            '<span><img class="img-flag" /> <span></span></span>'
        );
        $state.find("span").text(state.text);
        $state.find("img").attr("src", baseUrl + "/" + newcountriesjs[state.element.value].toLowerCase() + ".png");
        return $state;
    }

    jQuery(".country_selector").select2({
        templateResult: formatState,
        templateSelection: formatState2,
        placeholder: "Select Country",
        allowClear: true
    });
    // --- ADD THIS BLOCK TO SET DEFAULT COUNTRY CODE ---
    var globalSettingsRef = database.collection('settings').doc('globalSettings');
    
    globalSettingsRef.get().then(async function (snapshot) {
        var globalSettings = snapshot.data();
       
        if (globalSettings && globalSettings.defaultCountryCode) {
            var defaultPhoneCode = globalSettings.defaultCountryCode.replace('+', '').trim();

            // Find the option with matching phoneCode
            var $option = $(".country_selector option").filter(function() {
                return $(this).val() === defaultPhoneCode;
            });

            if ($option.length > 0) {
                $(".country_selector").val(defaultPhoneCode).trigger('change');
            } else {
                console.warn("Default country code not found in list:", defaultPhoneCode);
            }
        }
    }).catch(function (error) {
        console.error("Error fetching global settings: ", error);
    });
    // --- END OF DEFAULT COUNTRY LOGIC ---

    $(document).ready(function(){
        let now = new Date();
        now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
        let minDateTime = now.toISOString().slice(0,16);
        $(".senderArrive").attr("min", minDateTime);
    });

    // Auto-fill sender fields from logged-in user's Firestore profile
    var userId = "<?php echo $userId ?? ''; ?>";
    if (userId) {
        database.collection('users').where('id', '==', userId).get().then(function(snapshots) {
            if (!snapshots.empty) {
                var user = snapshots.docs[0].data();
                var name = user.firstName || user.name || '';
                if (name) { $('.senderName').val(name); }
                var rawPhone = user.phoneNumber || '';
                if (rawPhone) {
                    var match = rawPhone.match(/^\+(\d{1,4})(\d+)$/);
                    if (match) {
                        var code = match[1];
                        var phoneLocal = match[2];
                        var $opt = $(".country_selector option[value='" + code + "']");
                        if ($opt.length) {
                            $(".country_selector").val(code).trigger('change');
                        }
                        $('.senderPhone').val(phoneLocal);
                    } else {
                        $('.senderPhone').val(rawPhone);
                    }
                }
            }
        });
    }

    // GPS geolocation for sender address
    $(document).on('click', '.gps-btn', function() {
        var $btn = $(this);
        $btn.prop('disabled', true);
        if (!navigator.geolocation) {
            Swal.fire({text: "{{ trans('lang.geolocation_is_not_supported_by_this_browser') }}", icon: 'warning'});
            $btn.prop('disabled', false);
            return;
        }
        navigator.geolocation.getCurrentPosition(function(position) {
            sender_address_lat = position.coords.latitude;
            sender_address_lng = position.coords.longitude;
            if (typeof mapType !== 'undefined' && mapType === 'google') {
                var geocoder = new google.maps.Geocoder();
                geocoder.geocode({location: {lat: sender_address_lat, lng: sender_address_lng}}, function(results, status) {
                    if (status === 'OK' && results[0]) {
                        $('.senderAddress').val(results[0].formatted_address);
                    }
                    $btn.prop('disabled', false);
                });
            } else {
                fetch('https://nominatim.openstreetmap.org/reverse?format=json&lat=' + sender_address_lat + '&lon=' + sender_address_lng)
                    .then(function(r) { return r.json(); })
                    .then(function(data) {
                        $('.senderAddress').val(data.display_name || (sender_address_lat + ', ' + sender_address_lng));
                        $btn.prop('disabled', false);
                    })
                    .catch(function() {
                        $('.senderAddress').val(sender_address_lat + ', ' + sender_address_lng);
                        $btn.prop('disabled', false);
                    });
            }
        }, function(error) {
            $btn.prop('disabled', false);
            var msg = "{{ trans('lang.an_unknown_error_occurred') }}";
            if (error.code === 1) { msg = "{{ trans('lang.user_denied_the_request_for_geolocation') }}"; }
            else if (error.code === 2) { msg = "{{ trans('lang.location_information_is_unavailable') }}"; }
            else if (error.code === 3) { msg = "{{ trans('lang.the_request_to_get_user_location_timed_out') }}"; }
            Swal.fire({text: msg, icon: 'warning'});
        }, {timeout: 10000});
    });

</script>

@include('layouts.nav')
