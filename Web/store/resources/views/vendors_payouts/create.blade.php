@extends('layouts.app')

@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor">Nouvelle demande de paiement</h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item"><a href="{{ route('payments') }}">Mes demandes</a></li>
                <li class="breadcrumb-item active">Nouvelle demande</li>
            </ol>
        </div>
    </div>

    <div class="container-fluid">
        <div id="data-table_processing" class="dataTables_processing panel panel-default" style="display:none;">
            {{ trans('lang.processing') }}
        </div>

        <div class="row">
            <div class="col-lg-7">

                {{-- Résumé revenus --}}
                <div class="card border mb-3" id="earnings_card" style="display:none">
                    <div class="card-body py-3">
                        <div class="row text-center">
                            <div class="col-6">
                                <div class="text-muted small">Revenus disponibles</div>
                                <div class="h4 text-danger mb-0" id="earn_unpaid">—</div>
                            </div>
                            <div class="col-6">
                                <div class="text-muted small">Revenus payés</div>
                                <div class="h4 text-success mb-0" id="earn_paid">—</div>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="card border">
                    <div class="card-header">
                        <h4 class="mb-0">Demande de paiement</h4>
                    </div>
                    <div class="card-body">
                        <div id="error_top" class="alert alert-danger" style="display:none"></div>
                        <div id="success_top" class="alert alert-success" style="display:none"></div>

                        {{-- Méthode active (lecture seule) --}}
                        <div class="form-group row" id="method_row" style="display:none">
                            <label class="col-3 control-label text-muted small pt-2">Méthode active</label>
                            <div class="col-7">
                                <div id="method_display" class="pt-1"></div>
                            </div>
                        </div>

                        {{-- Montant --}}
                        <div class="form-group row">
                            <label class="col-3 control-label">Montant demandé</label>
                            <div class="col-7">
                                <input type="number" id="payout_amount" class="form-control" min="0" step="any" placeholder="Ex: 5000">
                                <small class="form-text text-muted" id="payout_amount_hint"></small>
                            </div>
                        </div>

                        {{-- Note --}}
                        <div class="form-group row">
                            <label class="col-3 control-label">Note (optionnel)</label>
                            <div class="col-7">
                                <textarea id="payout_note" class="form-control" rows="2" placeholder="Ajoutez une note…"></textarea>
                            </div>
                        </div>

                        <div class="form-group row">
                            <div class="col-10 offset-3">
                                <button id="submit_request" type="button" class="btn btn-primary btn-lg" disabled>
                                    <i class="fa fa-paper-plane"></i> Envoyer la demande
                                </button>
                                <a href="{{ route('payments') }}" class="btn btn-default ml-2">Annuler</a>
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
    var database      = firebase.firestore();
    var userAuthId    = '<?php echo $id; ?>';
    var vendorId      = '';
    var vendorName    = '';
    var unpaidAmount  = 0;
    var savedMethod   = '';
    var savedNumber   = '';
    var savedHolder   = '';
    var currentCurrency = '';
    var decimal_degits  = 0;
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

    function fmtMethodBadge(m) {
        if (m === 'orange_money' || m === 'Orange Money')
            return '<span class="badge badge-warning" style="background:#f76b1c;color:#fff;font-size:0.95em;padding:5px 12px">Orange Money</span>';
        return '<span class="badge badge-info" style="font-size:0.95em;padding:5px 12px">Wave</span>';
    }

    function maskNumber(n) {
        if (!n || n.length < 5) return n || '—';
        return n.slice(0, 3) + '••••' + n.slice(-2);
    }

    $(document).ready(function() {

        // ── Handler enregistré IMMÉDIATEMENT (avant tout chargement async) ──
        $('#submit_request').on('click', async function() {
            $('#error_top').hide();

            if (!vendorId || !savedMethod || !savedNumber) {
                $('#error_top').show().text('Les données de paiement ne sont pas encore chargées. Attendez quelques secondes.');
                return;
            }

            var note   = $('#payout_note').val().trim();
            var amount = parseFloat($('#payout_amount').val());

            if (isNaN(amount) || amount <= 0) {
                $('#error_top').show().text('Veuillez entrer un montant valide.');
                return;
            }
            if (unpaidAmount <= 0) {
                $('#error_top').show().text('Aucun revenu disponible à demander.');
                return;
            }
            if (amount > unpaidAmount) {
                $('#error_top').show().text('Le montant demandé ne peut pas dépasser vos revenus disponibles (' + fmt(unpaidAmount) + ').');
                return;
            }

            $('#submit_request').prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Envoi…');
            jQuery('#data-table_processing').show();

            try {
                var reqId = database.collection('tmp').doc().id;
                var now   = firebase.firestore.FieldValue.serverTimestamp();

                await database.collection('payout_requests').doc(reqId).set({
                    id:                 reqId,
                    beneficiary_id:     vendorId,
                    beneficiary_type:   'vendor',
                    beneficiary_name:   vendorName,
                    amount_requested:   amount,
                    available_balance:  unpaidAmount,
                    payout_method:      savedMethod,
                    payout_number:      savedNumber,
                    payout_holder_name: savedHolder,
                    status:             'pending',
                    requested_at:       now,
                    source:             'web_store',
                    note:               note,
                });

                jQuery('#data-table_processing').hide();
                $('#success_top').show().text('Demande de paiement prise en compte.');
                $('#submit_request').html('<i class="fa fa-check"></i> Envoyée');

                setTimeout(function() {
                    window.location.href = '{{ route("payments") }}';
                }, 2000);

            } catch(e) {
                jQuery('#data-table_processing').hide();
                $('#error_top').show().text('Erreur lors de l\'envoi : ' + e.message);
                $('#submit_request').prop('disabled', false).html('<i class="fa fa-paper-plane"></i> Envoyer la demande');
            }
        });

        // ── Chargement des données (async séparé, n'affecte pas le handler) ──
        loadPayoutPageData();
    });

    async function loadPayoutPageData() {
        jQuery('#data-table_processing').show();

        try {
            // 1. Résoudre le vendorID
            var vendorSnap = await database.collection('vendors').where('author', '==', userAuthId).get();
            if (vendorSnap.empty) {
                $('#error_top').show().text('Impossible de trouver votre restaurant. Contactez le support.');
                jQuery('#data-table_processing').hide();
                return;
            }
            var vendorData = vendorSnap.docs[0].data();
            vendorId   = vendorData.id;
            vendorName = vendorData.title || '';

            // 2. Charger la méthode de retrait configurée
            var userSnap = await database.collection('users').doc(userAuthId).get();
            var bd = (userSnap.exists && userSnap.data().userBankDetails) ? userSnap.data().userBankDetails : null;

            if (!bd || !bd.bankName || !bd.accountNumber) {
                var userSnap2 = await database.collection('users').where('vendorID', '==', vendorId).get();
                if (!userSnap2.empty) {
                    var u2 = userSnap2.docs[0].data();
                    bd = (u2.userBankDetails && u2.userBankDetails.bankName) ? u2.userBankDetails : null;
                }
            }

            if (!bd || !bd.bankName || !bd.accountNumber) {
                $('#error_top').show().html(
                    'Veuillez <a href="' + withdrawMethodCreateUrl + '">configurer votre méthode de paiement</a> avant de soumettre une demande.'
                );
                jQuery('#data-table_processing').hide();
                return;
            }

            savedMethod = bd.bankName;
            savedNumber = bd.accountNumber;
            savedHolder = bd.holderName || '';

            $('#method_display').html(
                fmtMethodBadge(savedMethod) +
                ' <span class="ml-2 text-muted">' + maskNumber(savedNumber) + '</span>' +
                (savedHolder ? ' <span class="text-muted small ml-1">(' + savedHolder + ')</span>' : '')
            );
            $('#method_row').show();

            // 3. Revenus disponibles
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

            unpaidAmount = unpaid;
            $('#earn_unpaid').text(fmt(unpaid));
            $('#earn_paid').text(fmt(paid));
            $('#earnings_card').show();

            $('#payout_amount').val(unpaid > 0 ? unpaid.toFixed(2) : '');
            $('#payout_amount_hint').text('Disponible : ' + fmt(unpaid));

            // Activer le bouton maintenant que tout est chargé
            $('#submit_request').prop('disabled', false);

        } catch(e) {
            $('#error_top').show().text('Erreur de chargement : ' + e.message);
        }

        jQuery('#data-table_processing').hide();
    }
</script>
@endsection
