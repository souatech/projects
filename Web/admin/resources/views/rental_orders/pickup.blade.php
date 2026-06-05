@extends('layouts.app')

@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Remise véhicule Rental</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item"><a href="{{ route('rental_orders.edit', $id) }}">Rental order</a></li>
                <li class="breadcrumb-item active">Remise véhicule</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row">
            <div class="col-md-8">
                <div class="card">
                    <div class="card-header"><h4 class="card-header-title">Checklist départ</h4></div>
                    <div class="card-body">
                        <div class="alert alert-info" id="pickup_access_hint">Chargement...</div>
                        <div class="row">
                            <div class="col-md-6">
                                <p><strong>Client :</strong> <span id="customer_name">-</span></p>
                                <p><strong>Véhicule :</strong> <span id="vehicle_name">-</span></p>
                                <p><strong>Pickup :</strong> <span id="pickup_datetime">-</span></p>
                                <p><strong>Retour prévu :</strong> <span id="return_datetime">-</span></p>
                            </div>
                            <div class="col-md-6">
                                <p><strong>Acompte :</strong> <span id="deposit_status">-</span></p>
                                <p><strong>Solde :</strong> <span id="remaining_amount">-</span></p>
                                <p><strong>Caution :</strong> <span id="cash_deposit">-</span></p>
                            </div>
                        </div>

                        <hr>

                        <div class="form-check mb-2">
                            <input class="form-check-input pickup-required" type="checkbox" id="original_docs_verified">
                            <label class="form-check-label" for="original_docs_verified">Documents originaux vérifiés</label>
                        </div>
                        <div class="form-check mb-2">
                            <input class="form-check-input pickup-required" type="checkbox" id="cash_deposit_received">
                            <label class="form-check-label" for="cash_deposit_received">Caution espèces reçue</label>
                        </div>
                        <div class="form-check mb-3">
                            <input class="form-check-input pickup-required" type="checkbox" id="customer_signature">
                            <label class="form-check-label" for="customer_signature">Signature client reçue</label>
                        </div>

                        <div class="row">
                            <div class="col-md-6 form-group">
                                <label>Km départ</label>
                                <input type="number" min="0" class="form-control pickup-required-field" id="start_km">
                            </div>
                            <div class="col-md-6 form-group">
                                <label>Niveau carburant départ</label>
                                <select class="form-control pickup-required-field" id="start_fuel_level">
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
                            <label>Photos état des lieux départ x4</label>
                            <input type="file" class="form-control pickup-required-field" id="start_photos" accept="image/*" multiple>
                            <small class="text-muted">Sélectionner au moins 4 photos.</small>
                        </div>
                        <div class="form-group">
                            <label>Photo compteur départ</label>
                            <input type="file" class="form-control pickup-required-field" id="start_odometer_photo" accept="image/*">
                        </div>

                        <div class="d-flex flex-wrap mt-4" style="gap:10px;">
                            <button type="button" class="btn btn-success" id="send_remaining_whatsapp">
                                <i class="fa fa-whatsapp"></i> Envoyer demande solde WhatsApp
                            </button>
                            <button type="button" class="btn btn-primary" id="confirm_remaining_payment">
                                <i class="fa fa-check"></i> Confirmer solde reçu
                            </button>
                            <button type="button" class="btn btn-warning" id="release_vehicle">
                                <i class="fa fa-car"></i> Remettre le véhicule
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
            $('#pickup_access_hint').removeClass('alert-info').addClass('alert-danger').text('Réservation introuvable.');
            $('#release_vehicle, #confirm_remaining_payment, #send_remaining_whatsapp').prop('disabled', true);
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

    function money(value) {
        var amount = parseFloat(value || 0);
        if (currentCurrency) {
            return currencyAtRight ? amount.toFixed(decimal_degits) + currentCurrency : currentCurrency + amount.toFixed(decimal_degits);
        }
        return amount.toFixed(0);
    }

    function renderOrder() {
        $('#customer_name').text(((order.author || {}).firstName || '') + ' ' + ((order.author || {}).lastName || ''));
        $('#vehicle_name').text((order.rentalVehicleType || {}).name || '-');
        $('#pickup_datetime').text(formatDateTime(order.pickupDateTime || order.bookingDateTime));
        $('#return_datetime').text(formatDateTime(order.returnDateTime));
        $('#deposit_status').text(order.paymentStatusDeposit || order.paymentDepositStatus || 'PENDING');
        $('#remaining_amount').text(money(order.remainingAmount || 0));
        $('#cash_deposit').text(money(order.cashDepositAmount || 0));
        if (order.paymentStatusRemaining === 'PAID' || order.remainingPaymentStatus === 'PAID') {
            $('#confirm_remaining_payment').prop('disabled', true);
        }
        if (order.status !== 'CONFIRMED') {
            $('#pickup_access_hint').removeClass('alert-info').addClass('alert-warning').text('La remise est disponible uniquement si le statut est CONFIRMED.');
            $('#release_vehicle').prop('disabled', true);
        } else {
            $('#pickup_access_hint').removeClass('alert-info').addClass('alert-success').text('Réservation confirmée. Complétez la checklist avant remise.');
        }
    }

    function validatePickup() {
        if (!$('#original_docs_verified').is(':checked')) return 'Documents originaux non vérifiés.';
        if (!$('#cash_deposit_received').is(':checked')) return 'Caution espèces non cochée.';
        if (!$('#customer_signature').is(':checked')) return 'Signature client manquante.';
        if (!$('#start_km').val()) return 'Km départ obligatoire.';
        if (!$('#start_fuel_level').val()) return 'Niveau carburant départ obligatoire.';
        if ($('#start_photos')[0].files.length < 4) return 'Ajoutez au moins 4 photos départ.';
        if ($('#start_odometer_photo')[0].files.length < 1) return 'Photo compteur départ obligatoire.';
        if ((order.paymentStatusRemaining || order.remainingPaymentStatus) !== 'PAID') return 'Confirmez le solde avant remise.';
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

    function openWhatsapp(type) {
        var firstName = order?.author?.firstName || '';
        var amount = parseFloat(order.remainingAmount || 0);
        var message = "Bonjour " + firstName + " 👋\n\n" +
            "Votre réservation JOXMAKO est prête.\n\n" +
            "Merci de régler le solde de " + money(amount) + "\n" +
            "sur notre compte marchand :\n\n" +
            "Wave : \nOrange Money : \n\n" +
            "Référence : " + (order.id || id) + "\n\n" +
            "Une fois le virement effectué,\nenvoyez-nous la capture d'écran.";
        window.open('https://wa.me/?text=' + encodeURIComponent(message), '_blank');
    }

    async function notifyCustomer(title, body) {
        var token = order?.author?.fcmToken || '';
        if (!token || typeof sendNotification !== 'function') return false;
        return await sendNotification(token, title, body, {orderId: id, serviceType: 'rental-service', type: 'rental_order'});
    }

    $('#send_remaining_whatsapp').click(function() {
        if (order) openWhatsapp('remaining');
    });

    $('#confirm_remaining_payment').click(async function() {
        if (!order || !confirm('Confirmer que le solde a bien été reçu ?')) return;
        await database.collection('rental_orders').doc(id).update({
            paymentStatusRemaining: 'PAID',
            remainingPaymentStatus: 'PAID',
            remainingConfirmedAt: firebase.firestore.FieldValue.serverTimestamp()
        });
        order.paymentStatusRemaining = 'PAID';
        order.remainingPaymentStatus = 'PAID';
        await notifyCustomer('Solde reçu ✅', 'Le solde de votre location a été confirmé.');
        renderOrder();
    });

    $('#release_vehicle').click(async function() {
        var error = validatePickup();
        if (error) {
            alert(error);
            return;
        }
        if (!confirm('Remettre le véhicule et passer la location en cours ?')) return;
        $('#release_vehicle').prop('disabled', true).text('Enregistrement...');
        var startPhotos = await uploadFiles('start_photos', 'startPhotos');
        var odometerPhotos = await uploadFiles('start_odometer_photo', 'startOdometer');
        await database.collection('rental_orders').doc(id).update({
            status: 'IN_PROGRESS',
            startKm: parseFloat($('#start_km').val()),
            startKitoMetersReading: $('#start_km').val().toString(),
            startFuelLevel: $('#start_fuel_level').val(),
            startPhotos: startPhotos,
            startOdometerPhoto: odometerPhotos[0],
            originalDocumentsVerified: true,
            cashDepositReceived: true,
            customerSignature: true,
            vehicleReleasedAt: firebase.firestore.FieldValue.serverTimestamp(),
            startTime: firebase.firestore.FieldValue.serverTimestamp()
        });
        window.location.href = "{{ route('rental_orders.edit', $id) }}";
    });
</script>
@endsection
