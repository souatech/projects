@extends('layouts.app')
@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <div class="d-flex top-title-section justify-content-between">
                <div class="d-flex top-title-left align-self-center">
                    <span class="icon mr-3"><img src="{{ asset('images/payment.png') }}"></span>
                    <h3 class="mb-0 page-title">{{trans('lang.driver_disburesement')}}</h3>
                    <span class="counter ml-3 total_count"></span>
                </div>
            </div>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{trans('lang.dashboard')}}</a></li>
                <li class="breadcrumb-item active">{{trans('lang.driver_disburesement')}}</li>
            </ol>
        </div>
    </div>
    <div class="container-fluid">
        <div class="table-list">
            <div class="row">
                <div class="col-12">

                    @if($id != '')
                    <div class="menu-tab vendorMenuTab">
                        <ul>
                            <li><a href="{{route('drivers.view',$id)}}"><i class="ri-list-indefinite"></i>{{trans('lang.tab_basic')}}</a></li>
                            <li class="vehicle_tab" style="display:none"><a href="{{route('drivers.vehicle',$id)}}"><i class="ri-car-line"></i>{{trans('lang.vehicle')}}</a></li>
                            <li class="service_type_orders"></li>
                            <li><a href="{{route('driver.payouts',$id)}}"><i class="ri-bank-card-line"></i>{{trans('lang.tab_payouts')}}</a></li>
                            <li><a href="{{route('payoutRequests.drivers.view',$id)}}"><i class="ri-refund-line"></i>{{trans('lang.tab_payout_request')}}</a></li>
                            <li><a href="{{route('users.walletstransaction',$id)}}"><i class="ri-wallet-line"></i>{{trans('lang.wallet_transaction')}}</a></li>
                        </ul>
                    </div>
                    @endif

                    <div class="card border">
                        <div class="card-header d-flex justify-content-between align-items-center border-0">
                            <div class="card-header-title">
                                <h3 class="text-dark-2 mb-2 h4">Paiements chauffeurs</h3>
                                <p class="mb-0 text-dark-2">Historique des paiements Wave / Orange Money effectués par l'admin</p>
                            </div>
                            <div class="card-header-btn mr-3">
                                <a class="btn-primary btn rounded-full" href="{!! route('driversPayouts.create') !!}"><i class="mdi mdi-plus mr-2"></i>{{trans('lang.drivers_payout_create')}}</a>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive m-t-10">
                                <table id="example24" class="display nowrap table table-hover table-striped table-bordered" cellspacing="0" width="100%">
                                    <thead>
                                        <tr>
                                            @if($id == '')
                                            <th>Chauffeur</th>
                                            @endif
                                            <th>Date</th>
                                            <th>Méthode</th>
                                            <th>Numéro</th>
                                            <th>Montant payé</th>
                                            <th>Statut</th>
                                            <th>Référence</th>
                                            <th>Services</th>
                                            <th>Commandes</th>
                                            <th>Note</th>
                                        </tr>
                                    </thead>
                                    <tbody id="append_list1">
                                    </tbody>
                                </table>
                            </div>
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
    var database  = firebase.firestore();
    var driverId  = '<?php echo $id; ?>';
    var currentCurrency = '';
    var decimal_degits  = 0;

    database.collection('currencies').where('isActive', '==', true).get().then(function(s) {
        if (s.docs[0]) {
            currentCurrency = s.docs[0].data().symbol || '';
            decimal_degits  = s.docs[0].data().decimal_degits || 0;
        }
    });

    function fmt(v) {
        return currentCurrency + ' ' + parseFloat(v || 0).toFixed(decimal_degits);
    }

    function fmtMethod(m) {
        if (!m) return '-';
        if (m === 'wave'         || m === 'Wave')         return '<span class="badge badge-info">Wave</span>';
        if (m === 'orange_money' || m === 'Orange Money') return '<span class="badge badge-warning" style="background:#f76b1c;color:#fff">Orange Money</span>';
        return m;
    }

    function fmtStatus(s) {
        if (s === 'paid')     return '<span class="badge badge-success">Payé</span>';
        if (s === 'pending')  return '<span class="badge badge-warning">En attente</span>';
        if (s === 'rejected') return '<span class="badge badge-danger">Rejeté</span>';
        return '<span class="badge badge-secondary">' + (s || '-') + '</span>';
    }

    function fmtDate(ts) {
        if (!ts) return '-';
        try {
            var d = ts.toDate();
            return d.toLocaleDateString('fr-FR') + ' ' + d.toLocaleTimeString('fr-FR', {hour:'2-digit', minute:'2-digit'});
        } catch(e) { return '-'; }
    }

    function fmtServices(svcs) {
        if (!svcs || !svcs.length) return '<span class="text-muted small">-</span>';
        var map = { food: ['Livraison','badge-info'], cab: ['CAB','badge-warning'], parcel: ['Colis','badge-secondary'], unknown: ['?','badge-light border'] };
        return svcs.map(function(s) {
            var e = map[s] || [s,'badge-light border'];
            return '<span class="badge badge-pill ' + e[1] + ' mr-1">' + e[0] + '</span>';
        }).join('');
    }

    $(document).ready(async function() {
        jQuery('#data-table_processing').show();

        // ── Lire payout_ledger (modèle JOXMAKO) ──────────────────────────
        var query = database.collection('payout_ledger')
            .where('paid_to_type', '==', 'driver');

        if (driverId !== '') {
            query = query.where('paid_to_id', '==', driverId);
        }

        var snap = await query.get().catch(function(e) {
            console.error('payout_ledger error:', e);
            return { docs: [] };
        });

        jQuery('#data-table_processing').hide();

        var tbody = $('#append_list1').empty();

        if (snap.docs.length === 0) {
            var colspan = driverId !== '' ? 9 : 10;
            tbody.append('<tr><td colspan="' + colspan + '" class="text-center text-muted py-3">Aucun paiement enregistré</td></tr>');
            $('.total_count').text(0);
            return;
        }

        // Trier par date décroissante (paid_at)
        var docs = snap.docs.slice().sort(function(a, b) {
            var ta = a.data().paid_at ? a.data().paid_at.toMillis() : 0;
            var tb = b.data().paid_at ? b.data().paid_at.toMillis() : 0;
            return tb - ta;
        });

        for (var i = 0; i < docs.length; i++) {
            var doc = docs[i];
            var l = doc.data();

            var driverCell = '';
            if (driverId === '') {
                var driverName = l.paid_to_name || l.paid_to_id || '-';
                var driverUrl  = '{{ url("driversPayouts") }}/' + (l.paid_to_id || '');
                driverCell = '<td><a href="' + driverUrl + '">' + driverName + '</a></td>';
            }

            var orderCount = (l.covered_order_ids && l.covered_order_ids.length) ? l.covered_order_ids.length : 0;
            var orderBadge = orderCount > 0
                ? '<span class="badge badge-light border">' + orderCount + ' cmd</span>'
                : '-';

            tbody.append(
                '<tr>' +
                driverCell +
                '<td>' + fmtDate(l.paid_at || l.createdAt) + '</td>' +
                '<td>' + fmtMethod(l.payout_method) + '</td>' +
                '<td>' + (l.payout_number || '-') + '</td>' +
                '<td><strong>' + fmt(l.amount_paid) + '</strong></td>' +
                '<td>' + fmtStatus(l.status) + '</td>' +
                '<td>' + (l.reference || '-') + '</td>' +
                '<td>' + fmtServices(l.covered_services) + '</td>' +
                '<td>' + orderBadge + '</td>' +
                '<td>' + (l.note || '-') + '</td>' +
                '</tr>'
            );
        }

        $('.total_count').text(docs.length);

        // ── Fallback legacy : driver_payouts (ancien système) ───────────────
        // Afficher séparément si présents, pour ne pas perdre l'historique
        var legacyQuery = database.collection('driver_payouts');
        if (driverId !== '') legacyQuery = legacyQuery.where('driverID', '==', driverId);

        var legacySnap = await legacyQuery.get().catch(function() { return { docs: [] }; });

        if (legacySnap.docs.length > 0) {
            tbody.append(
                '<tr><td colspan="' + (driverId !== '' ? 9 : 10) + '" class="bg-light text-muted small py-1 text-center">' +
                '— Anciens paiements (système précédent) —' +
                '</td></tr>'
            );
            legacySnap.docs.forEach(function(doc) {
                var l = doc.data();
                var driverCell = '';
                if (driverId === '') {
                    driverCell = '<td>' + (l.driverID || '-') + '</td>';
                }
                var dateStr = '-';
                try { if (l.paidDate) dateStr = l.paidDate.toDate().toLocaleDateString('fr-FR'); } catch(e) {}
                var wm = l.withdrawMethod || '';
                var wmLabel = (wm === 'bank') ? 'Bank' : (wm || '-');
                var statusBadge = l.paymentStatus === 'Success'
                    ? '<span class="badge badge-success">Payé</span>'
                    : l.paymentStatus === 'Reject'
                    ? '<span class="badge badge-danger">Rejeté</span>'
                    : '<span class="badge badge-warning">' + (l.paymentStatus || '-') + '</span>';
                tbody.append(
                    '<tr class="text-muted">' +
                    driverCell +
                    '<td>' + dateStr + '</td>' +
                    '<td>' + wmLabel + '</td>' +
                    '<td>-</td>' +
                    '<td>' + (l.amount || '-') + '</td>' +
                    '<td>' + statusBadge + '</td>' +
                    '<td>-</td>' +
                    '<td>-</td>' +
                    '<td>' + (l.adminNote || l.note || '-') + '</td>' +
                    '</tr>'
                );
            });
        }
    });
</script>
@endsection
