@extends('layouts.app')

@section('content')
<?php if ($id == 'create') { $id = ''; } ?>
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Paiement restaurant</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ url('/dashboard') }}">Dashboard</a></li>
                <li class="breadcrumb-item"><a href="{{ url('/vendorsPayouts') }}">Gains restaurants</a></li>
                <li class="breadcrumb-item active">Marquer comme payé</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div class="row">
            <div class="col-lg-8">
                <div class="card border">
                    <div class="card-header"><h4 class="mb-0">Enregistrer un paiement restaurant</h4></div>
                    <div class="card-body">

                        {{-- Vendor select (si pas de vendorID dans l'URL) --}}
                        <div id="vendor_select_block" style="{{ $id != '' ? 'display:none' : '' }}">
                            <div class="form-group row">
                                <label class="col-3 control-label">Restaurant</label>
                                <div class="col-7">
                                    <select id="vendor_select" class="form-control">
                                        <option value="">— Sélectionner un restaurant —</option>
                                    </select>
                                </div>
                            </div>
                        </div>

                        {{-- Vendor info card --}}
                        <div id="vendor_info" style="display:none" class="alert alert-info mb-3">
                            <strong id="vendor_name"></strong><br>
                            <span id="vendor_method"></span> : <span id="vendor_number"></span>
                        </div>

                        {{-- Commandes impayées --}}
                        <div id="orders_block" style="display:none">
                            <h5>Commandes à payer</h5>
                            <table class="table table-sm table-bordered">
                                <thead><tr><th>Commande</th><th>Date</th><th>Revenu restaurant</th></tr></thead>
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
                                    <a href="{{ url('/vendorsPayouts') }}" class="btn btn-default ml-2">Annuler</a>
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
    var vendorID  = "{{ $id }}";
    var unpaidOrders = [];
    var totalAmount  = 0;
    var currentCurrency = '';

    database.collection('currencies').where('isActive', '==', true).get().then(function(s) {
        if (s.docs[0]) currentCurrency = s.docs[0].data().symbol || '';
    });

    function fmt(v) { return currentCurrency + ' ' + parseFloat(v || 0).toFixed(0); }

    function colToService(col, svcHint) {
        if (col === 'vendor_orders') return 'food';
        if (col === 'rides')         return 'cab';
        if (col === 'parcel_orders') return 'parcel';
        var h = (svcHint || '').toLowerCase();
        if (['cab-service','cab','rides'].indexOf(h) !== -1)                            return 'cab';
        if (['delivery-service','food','multivendor','vendor_orders'].indexOf(h) !== -1) return 'food';
        if (['parcel_delivery','parcel','parcel_orders'].indexOf(h) !== -1)              return 'parcel';
        return null;
    }

    // ── Charger les commandes impayées pour un restaurant ─────────────────
    async function loadVendorData(vid) {
        // Infos restaurant (via users.vendorID)
        var userSnap = await database.collection('users').where('vendorID', '==', vid).get();
        var name   = vid;
        var method = '';
        var number = '';
        if (!userSnap.empty) {
            var u = userSnap.docs[0].data();
            name   = u.restaurantName || (u.firstName || '') + ' ' + (u.lastName || '');
            method = (u.userBankDetails && u.userBankDetails.bankName)      ? u.userBankDetails.bankName      : '';
            number = (u.userBankDetails && u.userBankDetails.accountNumber) ? u.userBankDetails.accountNumber : '';
        }

        $('#vendor_name').text(name);
        $('#vendor_method').text(method || '-');
        $('#vendor_number').text(number || '-');
        $('#vendor_info').show();
        if (method) $('#payout_method').val(method.toLowerCase().replace(' ', '_'));
        if (number) $('#payout_number').val(number);

        // Commandes impayées (filtre client-side)
        var ordersSnap = await database.collection('vendor_orders')
            .where('vendorID', '==', vid)
            .where('status', '==', 'Order Completed')
            .get();

        unpaidOrders = [];
        totalAmount  = 0;
        var tbody = $('#orders_tbody').empty();

        ordersSnap.docs.forEach(function(doc) {
            var d = doc.data();
            // Inclure les orders non payés : vendor_payout_status absent, null, undefined, ou 'unpaid'
            if (d.vendor_payout_status === 'paid') return;
            if (!d.vendor_earning) return;
            unpaidOrders.push({ id: doc.id, col: 'vendor_orders', svcHint: d.service_type || d.type || '', earning: parseFloat(d.vendor_earning || 0) });
            totalAmount += parseFloat(d.vendor_earning || 0);
            var date = d.createdAt ? d.createdAt.toDate().toLocaleDateString('fr-FR') : '-';
            tbody.append('<tr><td>' + doc.id.slice(-8) + '</td><td>' + date + '</td><td>' + fmt(d.vendor_earning) + '</td></tr>');
        });

        $('#total_display').text(fmt(totalAmount));
        $('#orders_block').show();
        $('#payout_form').show();
    }

    // ── Init ──────────────────────────────────────────────────────────────
    $(document).ready(async function() {
        if (vendorID !== '') {
            await loadVendorData(vendorID);
        } else {
            // Charger la liste des restaurants avec gains impayés
            var ordersSnap = await database.collection('vendor_orders')
                .where('status', '==', 'Order Completed').get();
            var vendorIds = new Set();
            ordersSnap.docs.forEach(function(doc) {
                var d = doc.data();
                if (d.vendor_payout_status === 'unpaid' && d.vendorID && d.vendor_earning) vendorIds.add(d.vendorID);
            });
            var sel = $('#vendor_select');
            for (var vid of vendorIds) {
                var snap = await database.collection('users').where('vendorID', '==', vid).get();
                if (!snap.empty) {
                    var u = snap.docs[0].data();
                    var label = u.restaurantName || (u.firstName || '') + ' ' + (u.lastName || '');
                    sel.append('<option value="' + vid + '">' + label + '</option>');
                }
            }
            sel.on('change', async function() {
                var vid = $(this).val();
                if (vid) await loadVendorData(vid);
                else { $('#vendor_info,#orders_block,#payout_form').hide(); }
            });
        }

        // ── Soumettre le paiement ────────────────────────────────────────
        $('#submit_payout').on('click', async function() {
            if (!unpaidOrders.length) { alert('Aucune commande impayée.'); return; }
            var vid = vendorID || $('#vendor_select').val();
            if (!vid) { alert('Sélectionner un restaurant.'); return; }

            var method    = $('#payout_method').val();
            var number    = $('#payout_number').val().trim();
            var reference = $('#payout_reference').val().trim();
            var note      = $('#payout_note').val().trim();

            if (!number) { alert('Entrer le numéro payé.'); return; }

            $(this).prop('disabled', true).text('Enregistrement…');

            try {
                // 1. Créer le payout_ledger doc
                var payoutId    = database.collection('tmp').doc().id;
                var vendorName  = $('#vendor_name').text();
                var orderIds    = unpaidOrders.map(function(o) { return o.id; });
                var now         = firebase.firestore.FieldValue.serverTimestamp();

                await database.collection('payout_ledger').doc(payoutId).set({
                    id:               payoutId,
                    paid_to_id:       vid,
                    paid_to_type:     'vendor',
                    paid_to_name:     vendorName,
                    payout_method:    method,
                    payout_number:    number,
                    amount_paid:      totalAmount,
                    currency:         'XOF',
                    covered_order_ids: orderIds,
                    covered_services: (function() {
                        var sset = {};
                        unpaidOrders.forEach(function(o) {
                            var s = colToService(o.col, o.svcHint);
                            if (s) { sset[s] = true; }
                            else { console.warn('[PAYOUT_SERVICE_TYPE_UNKNOWN] order=' + o.id + ' col=' + o.col); }
                        });
                        var svcs = Object.keys(sset);
                        if (!svcs.length) { console.warn('[PAYOUT_SERVICE_TYPE_UNKNOWN] payout vendor — aucun service'); svcs = ['unknown']; }
                        return svcs;
                    })(),
                    paid_at:          now,
                    paid_by_admin_id:  '{{ auth()->id() }}',
                    status:           'paid',
                    reference:        reference,
                    note:             note,
                    createdAt:        now,
                });

                // 2. Mettre à jour toutes les commandes couvertes
                var batch = database.batch();
                unpaidOrders.forEach(function(o) {
                    batch.update(database.collection('vendor_orders').doc(o.id), {
                        vendor_payout_status: 'paid',
                        vendor_payout_id:     payoutId,
                    });
                });
                await batch.commit();

                // 3. Marquer la demande payout_requests comme payée (si elle existe)
                var pendingReqs = await database.collection('payout_requests')
                    .where('beneficiary_id', '==', vid)
                    .where('beneficiary_type', '==', 'vendor')
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

                // 4. Déduire du wallet restaurant (wallet_amount / walletAmount)
                var userSnap = await database.collection('users').where('vendorID', '==', vid).get();
                if (!userSnap.empty) {
                    var uDoc = userSnap.docs[0];
                    var currentWallet = parseFloat(uDoc.data().wallet_amount || uDoc.data().walletAmount || 0);
                    var newWallet = Math.max(0, currentWallet - totalAmount);
                    await uDoc.ref.update({ wallet_amount: newWallet, walletAmount: newWallet });
                }

                $('#payout_result').html('<div class="alert alert-success">✅ Paiement enregistré — ' + fmt(totalAmount) + ' payés à ' + vendorName + '</div>');
                $('#submit_payout').text('Payé ✓');
                setTimeout(function() { window.location.href = '{{ url("/vendorsPayouts") }}'; }, 2000);

            } catch(e) {
                console.error(e);
                $('#payout_result').html('<div class="alert alert-danger">Erreur : ' + e.message + '</div>');
                $('#submit_payout').prop('disabled', false).text('Marquer comme payé');
            }
        });
    });
</script>
@endsection
