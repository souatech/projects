@extends('layouts.app')

@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Mes demandes de paiement</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item active">Mes demandes de paiement</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div id="data-table_processing" class="dataTables_processing panel panel-default" style="display:none;">
            {{ trans('lang.processing') }}
        </div>

        {{-- Méthode de paiement active --}}
        <div id="method_banner" class="alert mb-3" style="display:none"></div>

        <div class="table-list">
            <div class="row">
                <div class="col-12">
                    <div class="card border">
                        <div class="card-header d-flex justify-content-between align-items-center border-0">
                            <div class="card-header-title">
                                <h3 class="text-dark-2 mb-2 h4">Mes demandes de paiement</h3>
                                <p class="mb-0 text-dark-2">Historique de vos demandes Wave / Orange Money</p>
                            </div>
                            <div class="card-header-btn mr-3">
                                <a class="btn-primary btn rounded-full" href="{{ route('payments.create') }}">
                                    <i class="mdi mdi-plus mr-2"></i>Nouvelle demande
                                </a>
                            </div>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive m-t-10">
                                <table class="display nowrap table table-hover table-striped table-bordered" cellspacing="0" width="100%">
                                    <thead>
                                        <tr>
                                            <th>Date</th>
                                            <th>Montant demandé</th>
                                            <th>Méthode</th>
                                            <th>Numéro</th>
                                            <th>Statut</th>
                                            <th>Note</th>
                                        </tr>
                                    </thead>
                                    <tbody id="payout_list">
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    {{-- Résumé gains --}}
                    <div class="card border mt-3">
                        <div class="card-header border-0">
                            <h4 class="mb-0 text-dark-2">Résumé de mes revenus</h4>
                        </div>
                        <div class="card-body">
                            <div class="row text-center">
                                <div class="col-6 col-md-4">
                                    <div class="text-muted small mb-1">Revenus impayés</div>
                                    <div class="h4 text-danger mb-0" id="summary_unpaid">—</div>
                                </div>
                                <div class="col-6 col-md-4">
                                    <div class="text-muted small mb-1">Revenus payés</div>
                                    <div class="h4 text-success mb-0" id="summary_paid">—</div>
                                </div>
                                <div class="col-12 col-md-4 mt-3 mt-md-0">
                                    <div class="text-muted small mb-1">Total revenus</div>
                                    <div class="h4 mb-0" id="summary_total">—</div>
                                </div>
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
    var database    = firebase.firestore();
    var userAuthId  = '<?php echo $id; ?>';
    var currentCurrency = '';
    var decimal_degits  = 0;
    var withdrawMethodUrl       = "{{ route('withdraw-method') }}";
    var withdrawMethodCreateUrl = "{{ route('withdraw-method.create') }}";

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
        if (m === 'wave' || m === 'Wave') return '<span class="badge badge-info">Wave</span>';
        if (m === 'orange_money' || m === 'Orange Money') return '<span class="badge badge-warning" style="background:#f76b1c;color:#fff">Orange Money</span>';
        return '<span class="badge badge-secondary">' + m + '</span>';
    }

    // +221786084343 → +2217xxxxx343
    function maskPayoutNumber(num) {
        if (!num) return '—';
        var s = String(num).replace(/\s/g, '');
        if (s.length < 9) return s;
        return s.slice(0, 5) + 'xxxxx' + s.slice(-3);
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

    async function getVendorId() {
        var snap = await database.collection('vendors').where('author', '==', userAuthId).get();
        if (!snap.empty) return snap.docs[0].data().id;
        return null;
    }

    $(document).ready(async function() {
        jQuery('#data-table_processing').show();

        var vendorId = await getVendorId();
        if (!vendorId) {
            jQuery('#data-table_processing').hide();
            $('#payout_list').append('<tr><td colspan="6" class="text-center text-muted">Impossible de trouver votre restaurant.</td></tr>');
            return;
        }

        // ── Méthode de paiement active ────────────────────────────────────
        (async function() {
            try {
                var uDoc = await database.collection('users').doc(userAuthId).get();
                var bd = uDoc.exists ? (uDoc.data().userBankDetails || null) : null;
                if (!bd || !bd.bankName || !bd.accountNumber) {
                    // Fallback : chercher via vendorID
                    var uSnap2 = await database.collection('users').where('vendorID', '==', vendorId).get();
                    if (!uSnap2.empty) bd = uSnap2.docs[0].data().userBankDetails || null;
                }
                var banner = $('#method_banner');
                if (bd && bd.bankName && bd.accountNumber) {
                    var methodLabel = (bd.bankName === 'orange_money' || bd.bankName === 'Orange Money')
                        ? '<span class="badge badge-warning mr-2" style="background:#f76b1c;color:#fff">Orange Money</span>'
                        : '<span class="badge badge-info mr-2">Wave</span>';
                    var lockIcon = bd.payout_locked ? '<i class="mdi mdi-lock ml-2 text-warning" title="Verrouillé"></i>' : '';
                    banner.removeClass('alert-warning').addClass('alert-light border')
                        .html('<strong>Méthode de paiement :</strong> ' + methodLabel +
                              '<span class="text-monospace">' + maskPayoutNumber(bd.accountNumber) + '</span>' +
                              (bd.holderName ? ' — ' + bd.holderName : '') + lockIcon +
                              ' <a href="' + withdrawMethodUrl + '" class="ml-3 small">Voir</a>')
                        .show();
                } else {
                    banner.removeClass('alert-light').addClass('alert-warning')
                        .html('<i class="mdi mdi-alert-circle mr-2"></i>Aucune méthode de paiement configurée. ' +
                              '<a href="' + withdrawMethodCreateUrl + '">Configurer maintenant</a>')
                        .show();
                }
            } catch(e) { /* silent */ }
        })();

        // ── Demandes de paiement ──────────────────────────────────────────
        var reqSnap = await database.collection('payout_requests')
            .where('beneficiary_id', '==', vendorId)
            .where('beneficiary_type', '==', 'vendor')
            .get()
            .catch(function(e) { console.error(e); return { docs: [] }; });

        jQuery('#data-table_processing').hide();

        var tbody = $('#payout_list').empty();

        if (reqSnap.docs.length === 0) {
            tbody.append('<tr><td colspan="6" class="text-center text-muted py-3">Aucune demande de paiement</td></tr>');
        } else {
            var docs = reqSnap.docs.slice().sort(function(a, b) {
                var ta = a.data().requested_at ? a.data().requested_at.toMillis() : 0;
                var tb = b.data().requested_at ? b.data().requested_at.toMillis() : 0;
                return tb - ta;
            });
            docs.forEach(function(doc) {
                var r = doc.data();
                tbody.append(
                    '<tr>' +
                    '<td>' + fmtDate(r.requested_at || r.createdAt) + '</td>' +
                    '<td><strong>' + fmt(r.amount_requested) + '</strong></td>' +
                    '<td>' + fmtMethod(r.payout_method || r.preferred_method) + '</td>' +
                    '<td>' + maskPayoutNumber(r.payout_number || r.phone_number || '') + '</td>' +
                    '<td>' + fmtStatus(r.status) + '</td>' +
                    '<td>' + (r.note || '-') + '</td>' +
                    '</tr>'
                );
            });
        }

        // ── Résumé revenus ────────────────────────────────────────────────
        var ordersSnap = await database.collection('vendor_orders')
            .where('vendorID', '==', vendorId)
            .where('status', '==', 'Order Completed')
            .get()
            .catch(function() { return { docs: [] }; });

        var unpaid = 0, paid = 0;
        ordersSnap.docs.forEach(function(doc) {
            var d = doc.data();
            var earning = parseFloat(d.vendor_earning || 0);
            if (d.vendor_payout_status === 'paid') {
                paid += earning;
            } else if (earning > 0) {
                unpaid += earning;
            }
        });

        $('#summary_unpaid').text(fmt(unpaid));
        $('#summary_paid').text(fmt(paid));
        $('#summary_total').text(fmt(unpaid + paid));
    });
</script>
@endsection
