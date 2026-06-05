@extends('layouts.app')

@section('content')

<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <div class="d-flex top-title-section justify-content-between">
                <div class="d-flex top-title-left align-self-center">
                    <span class="icon mr-3"><img src="{{ asset('images/payment.png') }}"></span>
                    <h3 class="mb-0 page-title">{{trans('lang.drivers_payout_plural')}}</h3>
                    <span class="counter ml-3 total_count"></span>
                </div>
            </div>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{trans('lang.dashboard')}}</a></li>
                <li class="breadcrumb-item active">{{trans('lang.drivers_payout_plural')}}</li>
            </ol>
        </div>
    </div>
    <div class="container-fluid">
       <div class="table-list">
       <div class="row">
           <div class="col-12">
                <?php if ($id != '') { ?>
                    <div class="menu-tab vendorMenuTab">
                        <ul>
                            <li>
                                <a href="{{route('drivers.view',$id)}}"><i class="ri-list-indefinite"></i>{{trans('lang.tab_basic')}}</a>
                            </li>
                            <li class="vehicle_tab" style="display:none">
                                <a href="{{route('drivers.vehicle',$id)}}"><i class="ri-car-line"></i>{{trans('lang.vehicle')}}</a>
                            </li>
                            <li class="service_type_orders"></li>
                            <li class="active">
                                <a href="{{route('driver.payouts',$id)}}"><i class="ri-bank-card-line"></i>{{trans('lang.tab_payouts')}}</a>
                            </li>
                            <li>
                                <a href="{{route('payoutRequests.drivers.view',$id)}}" class="vendor_payout"><i class="ri-refund-line"></i>{{trans('lang.tab_payout_request')}}</a>
                            </li>
                            <li>
                                <a href="{{route('users.walletstransaction',$id)}}" class="wallet_transaction"><i class="ri-wallet-line"></i>{{trans('lang.wallet_transaction')}}</a>
                            </li>
                        </ul>
                    </div>

                    {{-- ── 4 Cartes résumé chauffeur ── --}}
                    <div class="row mb-3" id="summary_cards" style="display:none">
                        <div class="col-6 col-md-3">
                            <div class="card border text-center p-3">
                                <div class="text-muted small mb-1">Gains impayés</div>
                                <div class="h4 text-danger mb-0" id="card_unpaid">—</div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card border text-center p-3">
                                <div class="text-muted small mb-1">Gains payés</div>
                                <div class="h4 text-success mb-0" id="card_paid">—</div>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card border text-center p-3">
                                <div class="text-muted small mb-1">Espèces à remettre</div>
                                <div class="h4 text-warning mb-0" id="card_cash">—</div>
                                <button id="btn-all-cash-remis" class="btn btn-sm btn-success mt-2" style="display:none">
                                    Marquer remis
                                </button>
                            </div>
                        </div>
                        <div class="col-6 col-md-3">
                            <div class="card border text-center p-3">
                                <div class="text-muted small mb-1">Commandes terminées</div>
                                <div class="h4 mb-0" id="card_orders">—</div>
                            </div>
                        </div>
                    </div>
                <?php } ?>

               <div class="card border">
                 <div class="card-header d-flex justify-content-between align-items-center border-0">
                   <div class="card-header-title">
                    <h3 class="text-dark-2 mb-2 h4">
                        <?php if ($id != '') { ?>Commandes à payer<?php } else { ?>{{trans('lang.drivers_payout_plural')}}<?php } ?>
                    </h3>
                    <p class="mb-0 text-dark-2">{{trans('lang.driver_payouts_table_text')}}</p>
                   </div>
                   <div class="card-header-right d-flex align-items-center">
                    <div class="card-header-btn mr-3">
                        <?php if ($id != '') { ?>
                            <a class="btn-primary btn rounded-full" href="{{ url('driversPayouts/create/'.$id) }}"><i class="mdi mdi-plus mr-2"></i>{{trans('lang.drivers_payout_create')}}</a>
                        <?php } else { ?>
                            <a class="btn-primary btn rounded-full" href="{!! route('driversPayouts.create') !!}"><i class="mdi mdi-plus mr-2"></i>{{trans('lang.drivers_payout_create')}}</a>
                        <?php } ?>
                     </div>
                   </div>
                 </div>
                 <div class="card-body">
                     <div class="table-responsive m-t-10">
                         <?php if ($id != '') { ?>
                         {{-- Vue détail chauffeur : commandes impayées --}}
                         <table id="example24" class="display nowrap table table-hover table-striped table-bordered" cellspacing="0" width="100%">
                             <thead>
                                 <tr>
                                     <th>Commande</th>
                                     <th>Date</th>
                                     <th>Gain livraison</th>
                                     <th>Paiement client</th>
                                     <th>Espèces à remettre</th>
                                     <th>Statut payout</th>
                                 </tr>
                             </thead>
                             <tbody id="append_list1"></tbody>
                         </table>
                         <?php } else { ?>
                         {{-- Vue globale : résumé par chauffeur --}}
                         <table id="example24" class="display nowrap table table-hover table-striped table-bordered" cellspacing="0" width="100%">
                             <thead>
                                 <tr>
                                     <th>{{ trans('lang.driver') }}</th>
                                     <th>Méthode</th>
                                     <th>Numéro</th>
                                     <th>Gains impayés</th>
                                     <th>Commandes</th>
                                     <th>{{ trans('lang.actions') }}</th>
                                 </tr>
                             </thead>
                             <tbody id="append_list1"></tbody>
                         </table>
                         <?php } ?>
                     </div>
                 </div>
               </div>

               {{-- Historique paiements admin pour ce chauffeur --}}
               <?php if ($id != '') { ?>
               <div class="card border mt-4" id="ledger_card" style="display:none">
                   <div class="card-header border-0">
                       <h4 class="mb-0">Historique paiements admin</h4>
                   </div>
                   <div class="card-body">
                       <div class="table-responsive">
                           <table class="table table-sm table-bordered">
                               <thead>
                                   <tr>
                                       <th>Date</th>
                                       <th>Montant</th>
                                       <th>Méthode</th>
                                       <th>Numéro</th>
                                       <th>Référence</th>
                                       <th>Services</th>
                                       <th>Commandes</th>
                                   </tr>
                               </thead>
                               <tbody id="ledger_tbody"></tbody>
                           </table>
                       </div>
                   </div>
               </div>
               <?php } ?>

            </div>
        </div>
        </div>
    </div>
</div>

@endsection

@section('scripts')

<script type="text/javascript">
    var database = firebase.firestore();
    var id = "{{$id}}";
    var adminId = "{{ auth()->id() ?? '' }}";
    var currentCurrency = '';
    var decimal_degits = 0;

    database.collection('currencies').where('isActive', '==', true).get().then(function(s) {
        if (s.docs[0]) {
            currentCurrency = s.docs[0].data().symbol || '';
            decimal_degits  = s.docs[0].data().decimal_degits || 0;
        }
    });

    function fmtAmount(v) {
        return currentCurrency + ' ' + parseFloat(v || 0).toFixed(decimal_degits);
    }

    function fmtPaymentMethod(m) {
        if (!m) return '-';
        if (m === 'cash' || m === 'cod' || m === 'Cash') return 'Espèces';
        if (m === 'wave' || m === 'Wave') return 'Wave';
        if (m === 'orange_money' || m === 'Orange Money') return 'Orange Money';
        return m;
    }

    function fmtDate(ts) {
        if (!ts) return '-';
        try { return ts.toDate().toLocaleDateString('fr-FR'); } catch(e) { return '-'; }
    }

    function fmtServices(svcs) {
        if (!svcs || !svcs.length) return '<span class="text-muted small">-</span>';
        var map = { food: ['Livraison','badge-info'], cab: ['CAB','badge-warning'], parcel: ['Colis','badge-secondary'], unknown: ['?','badge-light border'] };
        return svcs.map(function(s) {
            var e = map[s] || [s,'badge-light border'];
            return '<span class="badge badge-pill ' + e[1] + ' mr-1">' + e[0] + '</span>';
        }).join('');
    }

    $(document).ready(async function () {

        if (id !== '') {
            // ── Vue détail chauffeur ────────────────────────────────────────
            var unpaidTotal = 0, paidTotal = 0, cashTotal = 0, orderCount = 0;
            var tbody = $('#append_list1').empty();

            function addOrderRow(d, docId, svcLabel, svcClass, collection) {
                var earning = parseFloat(d.driver_earning || 0);
                var cashRem = parseFloat(d.cash_to_remit || 0);
                var gpAmt   = parseFloat(d.gp_amount_collected_by_driver || 0);
                var gpSt    = d.gp_payment_status || '';
                if (d.driver_payout_status === 'unpaid') unpaidTotal += earning;
                if (d.driver_payout_status === 'paid')   paidTotal   += earning;
                if (d.cash_remittance_status === 'pending') cashTotal += cashRem;
                orderCount++;
                if (d.driver_payout_status !== 'unpaid') return;

                // Badge GP (Colis GP uniquement)
                var gpBadge = '';
                if (gpAmt > 0) {
                    var gpStBadge = gpSt === 'pending'  ? '<span class="badge badge-pill badge-warning gp-status-badge ml-1">GP non remis</span>'
                                  : gpSt === 'remitted' ? '<span class="badge badge-pill badge-success ml-1">GP remis</span>'
                                  : '';
                    var driverFeeDisp = d.collectionFee ? fmtAmount(d.collectionFee) : '—';
                    var gpAmtDisp     = fmtAmount(gpAmt);
                    var commDrv       = d.driver_admin_comm_amount != null ? fmtAmount(d.driver_admin_comm_amount) : '—';
                    var commGp        = d.gp_admin_comm_amount     != null ? fmtAmount(d.gp_admin_comm_amount)     : fmtAmount(gpAmt - parseFloat(d.gp_earning || 0));
                    var gainDrv       = fmtAmount(d.driver_earning || 0);
                    var gainGp        = fmtAmount(d.gp_earning || 0);
                    gpBadge = '<br>' +
                        '<small class="text-muted d-block mt-1">' +
                        '<strong>Frais livreur :</strong> ' + driverFeeDisp + ' &nbsp;|&nbsp; ' +
                        '<strong>Montant GP :</strong> ' + gpAmtDisp + ' ' + gpStBadge +
                        '</small>' +
                        '<small class="text-muted d-block">' +
                        'Comm. livreur : ' + commDrv + ' &nbsp;·&nbsp; Gain net : ' + gainDrv +
                        '</small>' +
                        '<small class="text-muted d-block">' +
                        'Comm. GP : ' + commGp + ' &nbsp;·&nbsp; Gain GP net : ' + gainGp +
                        '</small>';
                }

                // Bouton "Remis" pour les ordres avec cash en attente
                var remisBtn = '';
                if (d.cash_remittance_status === 'pending') {
                    remisBtn = ' <button class="btn btn-xs btn-outline-success btn-mark-remis" ' +
                               'data-id="' + docId + '" data-col="' + collection + '" ' +
                               'data-hasgp="' + (gpAmt > 0 ? '1' : '0') + '" ' +
                               'data-cash="' + cashRem + '">' +
                               'Remis</button>';
                }

                tbody.append(
                    '<tr>' +
                    '<td>' + docId.slice(-8) + ' <span class="badge badge-pill ' + svcClass + '">' + svcLabel + '</span>' + gpBadge + '</td>' +
                    '<td>' + fmtDate(d.createdAt) + '</td>' +
                    '<td><strong>' + fmtAmount(earning) + '</strong></td>' +
                    '<td>' + fmtPaymentMethod(d.collected_payment_method || d.payment_method) + '</td>' +
                    '<td>' + (cashRem > 0 ? fmtAmount(cashRem) : '-') + '</td>' +
                    '<td><span class="badge badge-warning">Impayé</span>' + remisBtn + '</td>' +
                    '</tr>'
                );
            }

            // Food delivery (driverID majuscule)
            var deliverySnap = await database.collection('vendor_orders')
                .where('driverID', '==', id)
                .where('status', '==', 'Order Completed').get();
            deliverySnap.docs.forEach(function(doc) { addOrderRow(doc.data(), doc.id, 'Livraison', 'badge-info', 'vendor_orders'); });

            // CAB (driverId minuscule)
            var cabSnap = await database.collection('rides')
                .where('driverId', '==', id)
                .where('status', '==', 'Order Completed').get();
            cabSnap.docs.forEach(function(doc) { addOrderRow(doc.data(), doc.id, 'CAB', 'badge-warning', 'rides'); });

            // Parcel (driverId minuscule)
            var parcelSnap = await database.collection('parcel_orders')
                .where('driverId', '==', id)
                .where('status', '==', 'Order Completed').get();
            parcelSnap.docs.forEach(function(doc) { addOrderRow(doc.data(), doc.id, 'Colis', 'badge-secondary', 'parcel_orders'); });

            if (tbody.children().length === 0) {
                tbody.append('<tr><td colspan="6" class="text-center text-success">Toutes les commandes ont été payées</td></tr>');
            }

            // Afficher le bouton "Marquer tout remis" si cash > 0
            $('#card_cash').text(fmtAmount(cashTotal));
            if (cashTotal > 0) $('#btn-all-cash-remis').show();

            // ── Handler "Marquer remis" (par commande) ───────────────────────
            $('#append_list1').on('click', '.btn-mark-remis', async function() {
                var btn   = $(this);
                var docId = btn.data('id');
                var col   = btn.data('col');
                var hasGp = (btn.data('hasgp') + '') === '1';
                var cash  = parseFloat(btn.data('cash') || 0);
                btn.prop('disabled', true).text('…');
                try {
                    var upd = {
                        cash_remittance_status: 'remitted',
                        cash_remitted_at: firebase.firestore.FieldValue.serverTimestamp(),
                        cash_received_by_admin_id: adminId
                    };
                    if (hasGp) upd.gp_payment_status = 'remitted';
                    await database.collection(col).doc(docId).update(upd);
                    btn.closest('td').html('<span class="badge badge-success">Cash remis</span>');
                    // Mise à jour GP badge si applicable
                    if (hasGp) {
                        btn.closest('tr').find('.gp-status-badge')
                            .removeClass('badge-warning').addClass('badge-success').text('GP remis');
                    }
                    cashTotal = Math.max(0, cashTotal - cash);
                    $('#card_cash').text(fmtAmount(cashTotal));
                    if (cashTotal <= 0) $('#btn-all-cash-remis').hide();
                } catch(e) {
                    console.error('[MARK_REMIS_ERROR]', e);
                    btn.prop('disabled', false).text('Remis');
                    alert('Erreur: ' + e.message);
                }
            });

            // ── Handler "Marquer TOUT le cash remis" ─────────────────────────
            $('#btn-all-cash-remis').on('click', async function() {
                if (!confirm('Confirmer la réception de tout le cash en attente pour ce chauffeur ?')) return;
                var btn = $(this);
                btn.prop('disabled', true).text('…');
                try {
                    var remisUpd = {
                        cash_remittance_status: 'remitted',
                        cash_remitted_at: firebase.firestore.FieldValue.serverTimestamp(),
                        cash_received_by_admin_id: adminId
                    };
                    var [fPend, cPend, pPend] = await Promise.all([
                        database.collection('vendor_orders')
                            .where('driverID', '==', id)
                            .where('cash_remittance_status', '==', 'pending').get(),
                        database.collection('rides')
                            .where('driverId', '==', id)
                            .where('cash_remittance_status', '==', 'pending').get(),
                        database.collection('parcel_orders')
                            .where('driverId', '==', id)
                            .where('cash_remittance_status', '==', 'pending').get()
                    ]);
                    var updates = [];
                    fPend.docs.forEach(function(doc) {
                        updates.push(database.collection('vendor_orders').doc(doc.id).update(remisUpd));
                    });
                    cPend.docs.forEach(function(doc) {
                        updates.push(database.collection('rides').doc(doc.id).update(remisUpd));
                    });
                    pPend.docs.forEach(function(doc) {
                        var d = doc.data();
                        var upd = Object.assign({}, remisUpd);
                        if (parseFloat(d.gp_amount_collected_by_driver || 0) > 0) {
                            upd.gp_payment_status = 'remitted';
                        }
                        updates.push(database.collection('parcel_orders').doc(doc.id).update(upd));
                    });
                    await Promise.all(updates);
                    // Recalcul : plus aucun cash en attente
                    cashTotal = 0;
                    $('#card_cash').text(fmtAmount(cashTotal));
                    btn.hide();
                    // MAJ affichage lignes du tableau
                    $('.btn-mark-remis').each(function() {
                        $(this).closest('td').html('<span class="badge badge-success">Cash remis</span>');
                    });
                    $('.gp-status-badge').removeClass('badge-warning').addClass('badge-success').text('GP remis');
                } catch(e) {
                    console.error('[ALL_CASH_REMIS_ERROR]', e);
                    btn.prop('disabled', false).text('Marquer remis');
                    alert('Erreur: ' + e.message);
                }
            });

            // Populate summary cards
            $('#card_unpaid').text(fmtAmount(unpaidTotal));
            $('#card_paid').text(fmtAmount(paidTotal));
            $('#card_orders').text(orderCount);
            $('#summary_cards').show();
            $('.total_count').text(orderCount);

            // ── Historique payout_ledger ────────────────────────────────────
            var ledgerSnap = await database.collection('payout_ledger')
                .where('paid_to_id', '==', id)
                .where('paid_to_type', '==', 'driver')
                .get();

            if (!ledgerSnap.empty) {
                var lBody = $('#ledger_tbody').empty();
                ledgerSnap.docs.forEach(function(doc) {
                    var l = doc.data();
                    lBody.append(
                        '<tr>' +
                        '<td>' + fmtDate(l.paid_at) + '</td>' +
                        '<td><strong>' + fmtAmount(l.amount_paid) + '</strong></td>' +
                        '<td>' + fmtPaymentMethod(l.payout_method) + '</td>' +
                        '<td>' + (l.payout_number || '-') + '</td>' +
                        '<td>' + (l.reference || '-') + '</td>' +
                        '<td>' + fmtServices(l.covered_services) + '</td>' +
                        '<td>' + (l.covered_order_ids ? l.covered_order_ids.length + ' commandes' : '-') + '</td>' +
                        '</tr>'
                    );
                });
                $('#ledger_card').show();
            }

        } else {
            // ── Vue globale : résumé par chauffeur ──────────────────────────
            var [deliverySnap, cabSnap, parcelSnap] = await Promise.all([
                database.collection('vendor_orders').where('status', '==', 'Order Completed').get(),
                database.collection('rides').where('status', '==', 'Order Completed').get(),
                database.collection('parcel_orders').where('status', '==', 'Order Completed').get()
            ]);

            var groups = {};

            function addToGroup(dId, d) {
                if (d.driver_payout_status !== 'unpaid') return;
                if (!dId || !d.driver_earning) return;
                if (!groups[dId]) groups[dId] = { total: 0, count: 0 };
                groups[dId].total += parseFloat(d.driver_earning || 0);
                groups[dId].count++;
            }

            deliverySnap.docs.forEach(function(doc) { addToGroup(doc.data().driverID, doc.data()); });
            cabSnap.docs.forEach(function(doc)      { addToGroup(doc.data().driverId,  doc.data()); });
            parcelSnap.docs.forEach(function(doc)   { addToGroup(doc.data().driverId,  doc.data()); });

            var tbody = $('#append_list1').empty();

            if (Object.keys(groups).length === 0) {
                tbody.append('<tr><td colspan="6" class="text-center">Aucun gain impayé</td></tr>');
                return;
            }

            for (var driverId in groups) {
                var g = groups[driverId];
                var userSnap = await database.collection('users').where('id', '==', driverId).get();
                if (userSnap.empty) continue;
                var u = userSnap.docs[0].data();
                var name   = (u.firstName || '') + ' ' + (u.lastName || '');
                var method = (u.userBankDetails && u.userBankDetails.bankName) ? u.userBankDetails.bankName : '-';
                var number = (u.userBankDetails && u.userBankDetails.accountNumber) ? u.userBankDetails.accountNumber : '-';
                var payUrl = '{{ url("driversPayouts/create") }}/' + driverId;
                tbody.append(
                    '<tr>' +
                    '<td><a href="{{ url("driversPayouts") }}/' + driverId + '">' + name + '</a></td>' +
                    '<td>' + fmtPaymentMethod(method) + '</td>' +
                    '<td>' + number + '</td>' +
                    '<td><strong>' + fmtAmount(g.total) + '</strong></td>' +
                    '<td>' + g.count + '</td>' +
                    '<td><a href="' + payUrl + '" class="btn btn-sm btn-primary">Payer</a></td>' +
                    '</tr>'
                );
            }
            $('.total_count').text(Object.keys(groups).length);
        }
    });
</script>

@endsection
