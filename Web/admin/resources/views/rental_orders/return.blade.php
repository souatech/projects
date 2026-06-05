@extends('layouts.app')

@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Retour véhicule Rental</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item"><a href="{{ route('rental_orders.edit', $id) }}">Rental order</a></li>
                <li class="breadcrumb-item active">Retour véhicule</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header"><h4 class="card-header-title">Checklist retour</h4></div>
                    <div class="card-body">
                        <div class="alert alert-info" id="return_access_hint">Chargement...</div>
                        <div class="row">
                            <div class="col-md-6">
                                <p><strong>Date retour prévue :</strong> <span id="return_datetime">-</span></p>
                                <p><strong>Durée location :</strong> <span id="rental_days">-</span></p>
                                <p><strong>Km départ :</strong> <span id="start_km_label">-</span></p>
                                <p><strong>Tolérance retard :</strong> <span id="grace_period_label">30 min</span></p>
                            </div>
                            <div class="col-md-6">
                                <p><strong>Forfait :</strong> <span id="package_name_label">-</span></p>
                                <p><strong>Heures incluses :</strong> <span id="included_hours_label">-</span></p>
                                <p><strong>Km inclus :</strong> <span id="included_km_label">-</span></p>
                                <p><strong>Prix km supplémentaire :</strong> <span id="extra_km_price_label">-</span></p>
                                <p><strong>Prix minute supplémentaire :</strong> <span id="extra_minute_price_label">-</span></p>
                            </div>
                        </div>

                        <hr>

                        <div class="row">
                            <div class="col-md-6 form-group">
                                <label>Date/heure retour réel</label>
                                <input type="datetime-local" class="form-control" id="actual_return_datetime">
                            </div>
                            <div class="col-md-6 form-group">
                                <label>Km retour</label>
                                <input type="number" min="0" class="form-control" id="return_km">
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-6 form-group">
                                <label>Niveau carburant retour</label>
                                <select class="form-control" id="return_fuel_level">
                                    <option value="">Choisir</option>
                                    <option value="empty">Vide</option>
                                    <option value="quarter">1/4</option>
                                    <option value="half">1/2</option>
                                    <option value="three_quarter">3/4</option>
                                    <option value="full">Plein</option>
                                </select>
                            </div>
                        </div>

                        <div class="form-group">
                            <label>Frais carburant éventuels</label>
                            <input type="number" min="0" class="form-control" id="fuel_fee" value="0">
                        </div>
                        <div class="form-group">
                            <label>État véhicule</label>
                            <textarea class="form-control" id="vehicle_condition" rows="3"></textarea>
                        </div>
                        <div class="form-group">
                            <label>Photos état des lieux retour x4</label>
                            <input type="file" class="form-control" id="return_photos" accept="image/*" multiple>
                            <small class="text-muted">Sélectionner au moins 4 photos.</small>
                        </div>
                        <div class="form-group">
                            <label>Photo compteur retour</label>
                            <input type="file" class="form-control" id="return_odometer_photo" accept="image/*">
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input" type="checkbox" id="cash_deposit_returned">
                            <label class="form-check-label" for="cash_deposit_returned">Caution rendue</label>
                        </div>

                        <div class="card bg-light">
                            <div class="card-body">
                                <h5>Récapitulatif final</h5>
                                <p><strong>Km utilisés :</strong> <span id="used_km">0</span></p>
                                <p><strong>Km supp :</strong> <span id="extra_km">0</span></p>
                                <p><strong>Minutes de retard facturées :</strong> <span id="extra_minutes">0</span></p>
                                <p><strong>Frais de location :</strong> <span id="base_price_label">0</span></p>
                                <p><strong>Frais de retard :</strong> <span id="extra_minutes_fee">0</span></p>
                                <p><strong>Frais km supp :</strong> <span id="extra_km_fee">0</span></p>
                                <p><strong>Frais carburant :</strong> <span id="fuel_fee_label">0</span></p>
                                <p><strong>Total final :</strong> <span id="final_amount_due">0</span></p>
                                <p><strong>Déjà payé :</strong> <span id="already_paid_amount">0</span></p>
                                <p><strong>Reste à payer :</strong> <span id="remaining_due_amount">0</span></p>
                            </div>
                        </div>

                        <div class="d-flex flex-wrap mt-4" style="gap:10px;">
                            <button type="button" class="btn btn-primary" id="calculate_return">Calculer</button>
                            <button type="button" class="btn btn-success" id="complete_rental">
                                <i class="fa fa-check"></i> Clôturer location
                            </button>
                            <a href="{{ route('rental_orders.edit', $id) }}" class="btn btn-default">
                                <i class="fa fa-undo"></i> Retour détail
                            </a>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection

@section('scripts')
<script type="text/javascript">
    var id = "{{ $id }}";
    var database = firebase.firestore();
    var storage = firebase.storage();
    var order = null;
    var currentCurrency = '';
    var currencyAtRight = false;
    var decimal_degits = 0;

    database.collection('currencies').where('isActive', '==', true).get().then(function(snapshots) {
        if (!snapshots.empty) {
            var currencyData = snapshots.docs[0].data();
            currentCurrency = currencyData.symbol;
            currencyAtRight = currencyData.symbolAtRight;
            decimal_degits = currencyData.decimal_degits || 0;
        }
    });

    $(document).ready(async function() {
        var doc = await database.collection('rental_orders').doc(id).get();
        if (!doc.exists) {
            $('#return_access_hint').removeClass('alert-info').addClass('alert-danger').text('Réservation introuvable.');
            $('#complete_rental, #calculate_return').prop('disabled', true);
            return;
        }
        order = doc.data();
        renderOrder();
    });

    function formatDateTime(timestamp) {
        if (!timestamp || !timestamp.toDate) return '-';
        var date = timestamp.toDate();
        var dd = String(date.getDate()).padStart(2, '0');
        var mm = String(date.getMonth() + 1).padStart(2, '0');
        return date.getFullYear() + '-' + mm + '-' + dd + ' ' + date.toLocaleTimeString('fr-FR', {hour: '2-digit', minute: '2-digit'});
    }

    function toDateTimeLocalValue(date) {
        var pad = function(value) {
            return String(value).padStart(2, '0');
        };
        return date.getFullYear() + '-' + pad(date.getMonth() + 1) + '-' + pad(date.getDate()) + 'T' + pad(date.getHours()) + ':' + pad(date.getMinutes());
    }

    function timestampToDate(timestamp) {
        if (!timestamp) return null;
        if (timestamp.toDate) return timestamp.toDate();
        var parsed = new Date(timestamp);
        return isNaN(parsed.getTime()) ? null : parsed;
    }

    function money(value) {
        var amount = parseFloat(value || 0);
        if (currentCurrency) {
            return currencyAtRight ? amount.toFixed(decimal_degits) + currentCurrency : currentCurrency + amount.toFixed(decimal_degits);
        }
        return amount.toFixed(0);
    }

    function rentalDays() {
        var pickup = order.pickupDateTime || order.bookingDateTime;
        var ret = order.returnDateTime;
        if (!pickup || !ret || !pickup.toDate || !ret.toDate) return 1;
        var diff = ret.toDate().getTime() - pickup.toDate().getTime();
        return Math.max(1, Math.ceil(diff / (1000 * 60 * 60 * 24)));
    }

    function packageSnapshot() {
        var packageModel = order?.rentalPackageModel || {};
        var reservedDays = parseInt(order?.reservedDays || rentalDays() || 1);
        var basePrice = parseFloat(order?.basePrice ?? packageModel.baseFare ?? packageModel.price ?? 0);
        var bookingTotal = parseFloat(order?.bookingTotal ?? order?.subTotal ?? order?.totalPrice ?? (basePrice * reservedDays) ?? 0);
        return {
            name: order?.packageName || packageModel.name || '-',
            basePrice: basePrice,
            bookingTotal: bookingTotal,
            reservedDays: Math.max(1, reservedDays || 1),
            includedHours: parseFloat(order?.includedHours ?? packageModel.includedHours ?? 0),
            includedDistance: parseFloat(order?.includedDistance ?? packageModel.includedDistance ?? 0),
            extraKmPrice: parseFloat(order?.extraKmPrice ?? packageModel.extraKmFare ?? packageModel.extraKmPrice ?? 0),
            extraMinutePrice: parseFloat(order?.extraMinutePrice ?? packageModel.extraMinuteFare ?? packageModel.extraMinutePrice ?? 0),
            gracePeriodMinutes: parseInt(order?.gracePeriodMinutes ?? 30)
        };
    }

    function lateMinutes(pack) {
        var expectedReturn = timestampToDate(order.expectedReturnDateTime || order.returnDateTime);
        var actualValue = $('#actual_return_datetime').val();
        var actualReturn = actualValue ? new Date(actualValue) : new Date();
        if (!expectedReturn || isNaN(actualReturn.getTime())) return 0;
        var rawLateMinutes = Math.ceil((actualReturn.getTime() - expectedReturn.getTime()) / (1000 * 60));
        return Math.max(0, rawLateMinutes - pack.gracePeriodMinutes);
    }

    function renderOrder() {
        var startKm = parseFloat(order.startKm || order.startKitoMetersReading || 0);
        var pack = packageSnapshot();
        $('#return_datetime').text(formatDateTime(order.expectedReturnDateTime || order.returnDateTime));
        $('#rental_days').text(pack.reservedDays + ' jour(s)');
        $('#start_km_label').text(startKm + ' km');
        $('#package_name_label').text(pack.name);
        $('#included_hours_label').text(pack.includedHours + ' h');
        $('#included_km_label').text(pack.includedDistance === -1 ? 'Kilométrage illimité' : (pack.includedDistance * pack.reservedDays) + ' km');
        $('#extra_km_price_label').text(pack.includedDistance === -1 ? '-' : money(pack.extraKmPrice) + ' / km');
        $('#extra_minute_price_label').text(money(pack.extraMinutePrice) + ' / min');
        $('#grace_period_label').text(pack.gracePeriodMinutes + ' min');
        var savedActualReturn = timestampToDate(order.actualReturnDateTime);
        $('#actual_return_datetime').val(toDateTimeLocalValue(savedActualReturn || new Date()));
        if (order.status !== 'IN_PROGRESS') {
            $('#return_access_hint').removeClass('alert-info').addClass('alert-warning').text('Le retour est disponible uniquement si le statut est IN_PROGRESS.');
            $('#complete_rental, #calculate_return').prop('disabled', true);
        } else {
            $('#return_access_hint').removeClass('alert-info').addClass('alert-success').text('Location en cours. Complétez le retour pour clôturer.');
        }
        calculateReturn();
    }

    function calculateReturn() {
        var pack = packageSnapshot();
        var startKm = parseFloat(order?.startKm || order?.startKitoMetersReading || 0);
        var returnKm = parseFloat($('#return_km').val() || 0);
        var includedKm = pack.includedDistance === -1 ? -1 : pack.includedDistance * pack.reservedDays;
        var usedKm = Math.max(0, returnKm - startKm);
        var extraKm = pack.includedDistance === -1 ? 0 : Math.max(0, usedKm - includedKm);
        var extraKmFee = extraKm * pack.extraKmPrice;
        var extraMinutes = lateMinutes(pack);
        var extraMinutesFee = extraMinutes * pack.extraMinutePrice;
        var fuelFee = parseFloat($('#fuel_fee').val() || 0);
        var finalAmountDue = pack.bookingTotal + extraMinutesFee + extraKmFee + fuelFee;
        var alreadyPaidAmount = parseFloat(order?.depositAmount || 0) + parseFloat(order?.remainingAmount || 0);
        var remainingDueAmount = Math.max(0, finalAmountDue - alreadyPaidAmount);
        $('#used_km').text(usedKm + ' km');
        $('#extra_km').text(extraKm + ' km');
        $('#extra_minutes').text(extraMinutes + ' min');
        $('#base_price_label').text(money(pack.bookingTotal));
        $('#extra_minutes_fee').text(money(extraMinutesFee));
        $('#extra_km_fee').text(money(extraKmFee));
        $('#fuel_fee_label').text(money(fuelFee));
        $('#final_amount_due').text(money(finalAmountDue));
        $('#already_paid_amount').text(money(alreadyPaidAmount));
        $('#remaining_due_amount').text(money(remainingDueAmount));
        return {startKm, returnKm, includedKm, usedKm, extraKm, extraKmFee, extraMinutes, extraMinutesFee, fuelFee, finalAmountDue, alreadyPaidAmount, remainingDueAmount};
    }

    function validateReturn() {
        if (!$('#actual_return_datetime').val()) return 'Date/heure retour réel obligatoire.';
        if (!$('#return_km').val()) return 'Km retour obligatoire.';
        if (!$('#return_fuel_level').val()) return 'Niveau carburant retour obligatoire.';
        if ($('#return_photos')[0].files.length < 4) return 'Ajoutez au moins 4 photos retour.';
        if ($('#return_odometer_photo')[0].files.length < 1) return 'Photo compteur retour obligatoire.';
        if (!$('#vehicle_condition').val()) return 'État véhicule obligatoire.';
        return '';
    }

    async function uploadFiles(inputId, folder) {
        var files = $('#' + inputId)[0].files;
        var urls = [];
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            var ref = storage.ref('rentalOrders/' + id + '/' + folder + '/' + Date.now() + '_' + i + '_' + file.name);
            await ref.put(file);
            urls.push(await ref.getDownloadURL());
        }
        return urls;
    }

    async function notifyCustomer(title, body) {
        var token = order?.author?.fcmToken || '';
        if (!token || typeof sendNotification !== 'function') return false;
        return await sendNotification(token, title, body, {orderId: id, serviceType: 'rental-service', type: 'rental_order'});
    }

    $('#calculate_return, #actual_return_datetime, #return_km, #fuel_fee').on('click keyup change', function() {
        calculateReturn();
    });

    $('#complete_rental').click(async function() {
        var error = validateReturn();
        if (error) {
            alert(error);
            return;
        }
        if (!confirm('Clôturer définitivement cette location ?')) return;
        $('#complete_rental').prop('disabled', true).text('Clôture...');
        var totals = calculateReturn();
        var returnPhotos = await uploadFiles('return_photos', 'returnPhotos');
        var odometerPhotos = await uploadFiles('return_odometer_photo', 'returnOdometer');
        await database.collection('rental_orders').doc(id).update({
            status: 'COMPLETED',
            returnKm: totals.returnKm,
            endKitoMetersReading: totals.returnKm.toString(),
            returnFuelLevel: $('#return_fuel_level').val(),
            returnPhotos: returnPhotos,
            returnOdometerPhoto: odometerPhotos[0],
            vehicleCondition: $('#vehicle_condition').val(),
            fuelFee: totals.fuelFee,
            usedKm: totals.usedKm,
            includedKm: totals.includedKm,
            extraKm: totals.extraKm,
            extraKmFee: totals.extraKmFee,
            extraMinutes: totals.extraMinutes,
            lateMinutes: totals.extraMinutes,
            extraMinutesFee: totals.extraMinutesFee,
            finalAmountDue: totals.finalAmountDue,
            alreadyPaidAmount: totals.alreadyPaidAmount,
            remainingDueAmount: totals.remainingDueAmount,
            actualReturnDateTime: firebase.firestore.Timestamp.fromDate(new Date($('#actual_return_datetime').val())),
            gracePeriodMinutes: packageSnapshot().gracePeriodMinutes,
            cashDepositReturned: $('#cash_deposit_returned').is(':checked'),
            completedAt: firebase.firestore.FieldValue.serverTimestamp(),
            endTime: firebase.firestore.FieldValue.serverTimestamp()
        });
        await notifyCustomer('Location terminée ✅', "Merci d’avoir utilisé JOXMAKO Rental.");
        window.location.href = "{{ route('rental_orders.edit', $id) }}";
    });
</script>
@endsection
