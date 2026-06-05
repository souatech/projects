@extends('layouts.app')

@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Paiement chauffeur</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ url('/dashboard') }}">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="{{ url('/driversPayouts') }}">Gains chauffeurs</a></li>
                <li class="breadcrumb-item active">Marquer comme payé</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-8">
                <div class="card border">
                    <div class="card-header"><h4 class="mb-0">Enregistrer un paiement chauffeur</h4></div>
                    <div class="card-body">

                        {{-- Driver list (si pas de driverID dans l'URL) --}}
                        <?php if ($id == '') { ?>
                        <div id="driver_list_block" class="mb-3">
                            <p class="font-weight-bold mb-2">Sélectionner un chauffeur :</p>
                            <div id="driver_list_container">
                                <div class="text-muted"><i class="mdi mdi-loading mdi-spin mr-1"></i>Chargement…</div>
                            </div>
                        </div>
                        <?php } ?>

                        {{-- Driver info card --}}
                        <div id="driver_info" style="display:none" class="alert alert-info mb-3">
                            <strong id="driver_name"></strong><br>
                            <span id="driver_method"></span> : <span id="driver_number"></span>
                        </div>

                        {{-- Commandes impayées --}}
                        <div id="orders_block" style="display:none">
                            <h5>Commandes à payer</h5>
                            <table class="table table-sm table-bordered">
                                <thead><tr><th>Commande</th><th>Date</th><th>Gain livraison</th></tr></thead>
                                <tbody id="orders_tbody"></tbody>
                                <tfoot>
                                    <tr>
                                        <td colspan="2"><strong>Total à payer</strong></td>
                                        <td><strong id="total_display">0</strong></td>
                                    </tr>
                                </tfoot>
                            </table>
                        </div>

                        {{-- Formulaire paiement --}}
                        <div id="payout_form" style="display:none">
                            <hr>
                            <div class="form-group row">
                                <label class="col-3 control-label">Méthode</label>
                                <div class="col-7">
                                    <select id="payout_method" class="form-control">
                                        <option value="wave">Wave</option>
                                        <option value="orange_money">Orange Money</option>
                                    </select>
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-3 control-label">Numéro payé</label>
                                <div class="col-7">
                                    <input type="text" id="payout_number" class="form-control" placeholder="Ex: 77xxxxxxx">
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-3 control-label">Référence Wave/OM</label>
                                <div class="col-7">
                                    <input type="text" id="payout_reference" class="form-control" placeholder="Optionnel">
                                </div>
                            </div>
                            <div class="form-group row">
                                <label class="col-3 control-label">Note</label>
                                <div class="col-7">
                                    <textarea id="payout_note" class="form-control" rows="2"></textarea>
                                </div>
                            </div>

                            <div class="form-group row">
                                <div class="col-10 offset-3">
                                    <button id="submit_payout" class="btn btn-primary btn-lg">
                                        <i class="fa fa-check"></i> Marquer comme payé
                                    </button>
                                    <a href="{{ url('/driversPayouts') }}" class="btn btn-default ml-2">Annuler</a>
                                </div>
                            </div>
                            <div id="payout_result" class="mt-3"></div>
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
    var database = firebase.firestore();
    var driverID  = "{{ $id }}";
    var selectedDriverUID = '';   // mis à jour au clic sur une carte chauffeur
    var unpaidOrders = [];
    var totalAmount  = 0;
    var currentCurrency = '';

    database.collection('currencies').where('isActive', '==', true).get().then(function(s) {
        if (s.docs[0]) currentCurrency = s.docs[0].data().symbol || '';
    });

    function fmt(v) { return currentCurrency + ' ' + parseFloat(v || 0).toFixed(0); }

    // Mappe collection + champs doc → label service canonique
    function colToService(col, svcHint) {
        if (col === 'vendor_orders') return 'food';
        if (col === 'rides')         return 'cab';
        if (col === 'parcel_orders') return 'parcel';
        // Fallback sur les champs du doc
        var h = (svcHint || '').toLowerCase();
        if (['cab-service','cab','rides'].indexOf(h) !== -1)                       return 'cab';
        if (['delivery-service','food','multivendor','vendor_orders'].indexOf(h) !== -1) return 'food';
        if (['parcel_delivery','parcel','parcel_orders'].indexOf(h) !== -1)        return 'parcel';
        return null;
    }

    // ── Charger les commandes impayées pour un chauffeur ──────────────────
    async function loadDriverData(uid) {
        // Infos chauffeur
        var userSnap = await database.collection('users').where('id', '==', uid).get();
        if (userSnap.empty) { alert('Chauffeur introuvable'); return; }
        var u = userSnap.docs[0].data();
        var name   = (u.firstName || '') + ' ' + (u.lastName || '');
        var method = (u.userBankDetails && u.userBankDetails.bankName) ? u.userBankDetails.bankName : '';
        var number = (u.userBankDetails && u.userBankDetails.accountNumber) ? u.userBankDetails.accountNumber : '';

        $('#driver_name').text(name);
        $('#driver_method').text(method);
        $('#driver_number').text(number);
        $('#driver_info').show();
        if (method) $('#payout_method').val(method.toLowerCase().replace(' ', '_'));
        if (number) $('#payout_number').val(number);

        unpaidOrders = [];
        totalAmount  = 0;
        var tbody = $('#orders_tbody').empty();

        // Delivery (vendor_orders)
        var deliverySnap = await database.collection('vendor_orders')
            .where('driverID', '==', uid)
            .where('status', '==', 'Order Completed')
            .get();
        deliverySnap.docs.forEach(function(doc) {
            var d = doc.data();
            if (d.driver_payout_status !== 'unpaid') return;
            if (!d.driver_earning) return;
            unpaidOrders.push({ id: doc.id, col: 'vendor_orders', svcHint: d.service_type || d.type || '', earning: parseFloat(d.driver_earning || 0) });
            totalAmount += parseFloat(d.driver_earning || 0);
            var date = d.createdAt ? d.createdAt.toDate().toLocaleDateString('fr-FR') : '-';
            tbody.append('<tr><td>' + doc.id.slice(-8) + ' <span class="badge badge-info badge-pill">Livraison</span></td><td>' + date + '</td><td>' + fmt(d.driver_earning) + '</td></tr>');
        });

        // CAB (rides)
        var cabSnap = await database.collection('rides')
            .where('driverId', '==', uid)
            .where('status', '==', 'Order Completed')
            .get();
        cabSnap.docs.forEach(function(doc) {
            var d = doc.data();
            if (d.driver_payout_status !== 'unpaid') return;
            if (!d.driver_earning) return;
            unpaidOrders.push({ id: doc.id, col: 'rides', svcHint: d.service_type || d.rideType || '', earning: parseFloat(d.driver_earning || 0) });
            totalAmount += parseFloat(d.driver_earning || 0);
            var date = d.createdAt ? d.createdAt.toDate().toLocaleDateString('fr-FR') : '-';
            tbody.append('<tr><td>' + doc.id.slice(-8) + ' <span class="badge badge-warning badge-pill">CAB</span></td><td>' + date + '</td><td>' + fmt(d.driver_earning) + '</td></tr>');
        });

        // Parcel (parcel_orders)
        var parcelSnap = await database.collection('parcel_orders')
            .where('driverId', '==', uid)
            .where('status', '==', 'Order Completed')
            .get();
        parcelSnap.docs.forEach(function(doc) {
            var d = doc.data();
            if (d.driver_payout_status !== 'unpaid') return;
            if (!d.driver_earning) return;
            unpaidOrders.push({ id: doc.id, col: 'parcel_orders', svcHint: d.service_type || '', earning: parseFloat(d.driver_earning || 0) });
            totalAmount += parseFloat(d.driver_earning || 0);
            var date = d.createdAt ? d.createdAt.toDate().toLocaleDateString('fr-FR') : '-';
            tbody.append('<tr><td>' + doc.id.slice(-8) + ' <span class="badge badge-secondary badge-pill">Colis</span></td><td>' + date + '</td><td>' + fmt(d.driver_earning) + '</td></tr>');
        });

        $('#total_display').text(fmt(totalAmount));
        $('#orders_block').show();
        $('#payout_form').show();
    }

    // ── Init ──────────────────────────────────────────────────────────────
    $(document).ready(async function() {
        if (driverID !== '') {
            await loadDriverData(driverID);
        } else {
            var driverStats = {}; // uid → { unpaid, orderCount }

            // Delivery (vendor_orders)
            var deliveryAll = await database.collection('vendor_orders')
                .where('status', '==', 'Order Completed').get();
            deliveryAll.docs.forEach(function(doc) {
                var d = doc.data();
                if (!d.driverID) return;
                if (d.driver_payout_status === 'paid') return;
                if (!d.driver_earning) return;
                if (!driverStats[d.driverID]) driverStats[d.driverID] = { unpaid: 0, orderCount: 0 };
                driverStats[d.driverID].unpaid += parseFloat(d.driver_earning || 0);
                driverStats[d.driverID].orderCount++;
            });

            // CAB (rides)
            var cabAll = await database.collection('rides')
                .where('status', '==', 'Order Completed').get();
            cabAll.docs.forEach(function(doc) {
                var d = doc.data();
                if (!d.driverId) return;
                if (d.driver_payout_status === 'paid') return;
                if (!d.driver_earning) return;
                if (!driverStats[d.driverId]) driverStats[d.driverId] = { unpaid: 0, orderCount: 0 };
                driverStats[d.driverId].unpaid += parseFloat(d.driver_earning || 0);
                driverStats[d.driverId].orderCount++;
            });

            // Parcel (parcel_orders)
            var parcelAll = await database.collection('parcel_orders')
                .where('status', '==', 'Order Completed').get();
            parcelAll.docs.forEach(function(doc) {
                var d = doc.data();
                if (!d.driverId) return;
                if (d.driver_payout_status === 'paid') return;
                if (!d.driver_earning) return;
                if (!driverStats[d.driverId]) driverStats[d.driverId] = { unpaid: 0, orderCount: 0 };
                driverStats[d.driverId].unpaid += parseFloat(d.driver_earning || 0);
                driverStats[d.driverId].orderCount++;
            });

            // Filtrer : seulement ceux qui ont des gains impayés
            var eligibleIds = Object.keys(driverStats).filter(function(uid) {
                return driverStats[uid].unpaid > 0;
            });

            var $container = $('#driver_list_container').empty();

            if (eligibleIds.length === 0) {
                $container.html('<div class="alert alert-success mb-0">Aucun chauffeur avec des gains impayés.</div>');
                return;
            }

            // Construire les cartes chauffeur
            for (var i = 0; i < eligibleIds.length; i++) {
                var uid = eligibleIds[i];
                var snap = await database.collection('users').where('id', '==', uid).get();
                if (snap.empty) continue;
                var u = snap.docs[0].data();

                var name   = ((u.firstName || '') + ' ' + (u.lastName || '')).trim() || uid;
                var phone  = u.phoneNumber || '';
                var method = (u.userBankDetails && u.userBankDetails.bankName) ? u.userBankDetails.bankName : '';
                var number = (u.userBankDetails && u.userBankDetails.accountNumber) ? u.userBankDetails.accountNumber : '';
                var stats  = driverStats[uid];
                var gainLbl= '<span class="badge badge-danger">' + fmt(stats.unpaid) + ' impayés</span>';
                var orderLbl = stats.orderCount > 0 ? '<small class="text-muted ml-1">(' + stats.orderCount + ' cmd)</small>' : '';
                var methodLbl = method ? method + (number ? ' : ' + number : '') : (number || '<em class="text-muted">méthode non renseignée</em>');

                var card = $('<div>', {
                    class: 'card border mb-2 driver-card',
                    'data-uid': uid,
                    css: { cursor: 'pointer' }
                }).html(
                    '<div class="card-body py-2 px-3 d-flex justify-content-between align-items-center">' +
                    '<div>' +
                    '<strong>' + name + '</strong>' +
                    (phone ? '<span class="text-muted ml-2 small">' + phone + '</span>' : '') +
                    '<br><small class="text-muted">' + methodLbl + '</small>' +
                    '</div>' +
                    '<div class="text-right">' + gainLbl + orderLbl + '</div>' +
                    '</div>'
                );
                $container.append(card);
            }

            // Sélection d'une carte chauffeur
            $container.on('click', '.driver-card', async function() {
                $container.find('.driver-card').removeClass('border-primary').css('background', '');
                $(this).addClass('border-primary').css('background', '#f0f8ff');
                selectedDriverUID = $(this).data('uid');
                await loadDriverData(selectedDriverUID);
            });
        }

        // ── Soumettre le paiement ────────────────────────────────────────
        $('#submit_payout').on('click', async function() {
            if (!unpaidOrders.length) { alert('Aucune commande impayée.'); return; }
            var uid    = driverID || selectedDriverUID;
            if (!uid)  { alert('Sélectionner un chauffeur.'); return; }

            var method    = $('#payout_method').val();
            var number    = $('#payout_number').val().trim();
            var reference = $('#payout_reference').val().trim();
            var note      = $('#payout_note').val().trim();

            if (!number) { alert('Entrer le numéro payé.'); return; }

            $(this).prop('disabled', true).text('Enregistrement…');

            try {
                // 1. Créer le payout_ledger doc
                var payoutId   = database.collection('tmp').doc().id;
                var driverName = $('#driver_name').text();
                var orderIds   = unpaidOrders.map(function(o) { return o.id; });
                var now        = firebase.firestore.FieldValue.serverTimestamp();

                var serviceSet = {};
                unpaidOrders.forEach(function(o) {
                    var svc = colToService(o.col, o.svcHint);
                    if (svc) {
                        serviceSet[svc] = true;
                    } else {
                        console.warn('[PAYOUT_SERVICE_TYPE_UNKNOWN] order=' + o.id + ' col=' + o.col + ' svcHint=' + o.svcHint);
                    }
                });
                var coveredServices = Object.keys(serviceSet);
                if (coveredServices.length === 0) {
                    coveredServices = ['unknown'];
                    console.warn('[PAYOUT_SERVICE_TYPE_UNKNOWN] payout=' + payoutId + ' aucun service détecté');
                }

                await database.collection('payout_ledger').doc(payoutId).set({
                    id:               payoutId,
                    paid_to_id:       uid,
                    paid_to_type:     'driver',
                    paid_to_name:     driverName,
                    payout_method:    method,
                    payout_number:    number,
                    amount_paid:      totalAmount,
                    currency:         'XOF',
                    covered_order_ids: orderIds,
                    covered_services: coveredServices,
                    paid_at:          now,
                    paid_by_admin_id:  '{{ auth()->id() }}',
                    status:           'paid',
                    reference:        reference,
                    note:             note,
                    createdAt:        now,
                });

                // 2. Mettre à jour toutes les commandes couvertes (bonne collection par ordre)
                var batch = database.batch();
                unpaidOrders.forEach(function(o) {
                    batch.update(database.collection(o.col).doc(o.id), {
                        driver_payout_status: 'paid',
                        driver_payout_id:     payoutId,
                    });
                });
                await batch.commit();

                // 3. Marquer la demande payout_requests comme payée (si elle existe)
                var pendingReqs = await database.collection('payout_requests')
                    .where('beneficiary_id', '==', uid)
                    .where('beneficiary_type', '==', 'driver')
                    .where('status', '==', 'pending')
                    .get().catch(function() { return { docs: [] }; });
                if (!pendingReqs.empty) {
                    var reqBatch = database.batch();
                    pendingReqs.docs.forEach(function(rd) {
                        reqBatch.update(rd.ref, {
                            status: 'paid',
                            paid_at: now,
                            paid_by_admin_id: '{{ auth()->id() }}',
                            payout_ledger_id: payoutId,
                        });
                    });
                    await reqBatch.commit();
                }

                $('#payout_result').html('<div class="alert alert-success">✅ Paiement enregistré — ' + fmt(totalAmount) + ' payés à ' + driverName + '</div>');
                $('#submit_payout').text('Payé ✓');
                setTimeout(function() { window.location.href = '{{ url("/driversPayouts") }}'; }, 2000);

            } catch(e) {
                console.error(e);
                $('#payout_result').html('<div class="alert alert-danger">Erreur : ' + e.message + '</div>');
                $('#submit_payout').prop('disabled', false).text('Marquer comme payé');
            }
        });
    });
</script>
@endsection
