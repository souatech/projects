@extends('layouts.app')
@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center"></div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item active">Méthode de paiement</li>
            </ol>
        </div>
    </div>
    <div class="container-fluid">
        <div id="data-table_processing" class="dataTables_processing panel panel-default" style="display:none;">
            {{ trans('lang.processing') }}
        </div>
        <div class="row">
            <div class="col-lg-6">

                {{-- État verrouillé --}}
                <div class="card border" id="payout_locked_card" style="display:none">
                    <div class="card-header">
                        <h4 class="mb-0">Méthode de paiement active</h4>
                    </div>
                    <div class="card-body text-center py-4">
                        <div id="locked_method_badge" class="mb-3"></div>
                        <div class="h5 mb-1" id="locked_phone">—</div>
                        <div class="text-muted mb-4" id="locked_holder"></div>
                        <div class="alert alert-warning d-inline-flex align-items-center px-4 py-2 mb-0">
                            <i class="mdi mdi-lock mr-2" style="font-size:1.1em"></i>
                            <span>Protégé — Pour modifier votre méthode de paiement, contactez le support JOXMAKO.</span>
                        </div>
                    </div>
                </div>

                {{-- Pas encore configuré --}}
                <div class="card border" id="payout_unlocked_card" style="display:none">
                    <div class="card-header">
                        <h4 class="mb-0">Méthode de paiement</h4>
                    </div>
                    <div class="card-body">
                        <p class="text-muted mb-4">
                            Aucune méthode configurée. Configurez votre méthode Wave ou Orange Money pour recevoir vos paiements.
                        </p>
                        <a href="{{ route('withdraw-method.create') }}" class="btn btn-primary">
                            <i class="mdi mdi-plus mr-1"></i> Configurer ma méthode
                        </a>
                    </div>
                </div>

            </div>
        </div>
    </div>
</div>
@endsection
@section('scripts')
<script type="text/javascript">
    var database     = firebase.firestore();
    var vendorUserId = "<?php echo $id; ?>";
    var authRole     = "{{ $authRole }}";
    var empVendorId  = "{{ $empVendorId }}";

    function fmtMethod(m) {
        if (!m) return '';
        if (m === 'wave' || m === 'Wave')
            return '<span class="badge badge-info" style="font-size:1.1em;padding:8px 18px">Wave</span>';
        if (m === 'orange_money' || m === 'Orange Money')
            return '<span class="badge badge-warning" style="background:#f76b1c;color:#fff;font-size:1.1em;padding:8px 18px">Orange Money</span>';
        return '<span class="badge badge-secondary">' + m + '</span>';
    }

    // +221786084343 → +2217xxxxx343
    function maskPayoutNumber(num) {
        if (!num) return '—';
        var s = String(num).replace(/\s/g, '');
        if (s.length < 9) return s;
        return s.slice(0, 5) + 'xxxxx' + s.slice(-3);
    }

    document.addEventListener('DOMContentLoaded', async function() {
        jQuery('#data-table_processing').show();

        var targetUserId = vendorUserId;
        if (authRole !== 'vendor' && empVendorId) {
            try {
                var vSnap = await database.collection('vendors').doc(empVendorId).get();
                if (vSnap.exists) targetUserId = vSnap.data().author || vendorUserId;
            } catch(e) {}
        }

        try {
            var userDoc = await database.collection('users').doc(targetUserId).get();
            var bd = userDoc.exists ? (userDoc.data().userBankDetails || null) : null;

            if (bd && bd.bankName && bd.accountNumber && bd.payout_locked) {
                $('#locked_method_badge').html(fmtMethod(bd.bankName));
                $('#locked_phone').text(maskPayoutNumber(bd.accountNumber));
                if (bd.holderName) $('#locked_holder').text(bd.holderName);
                $('#payout_locked_card').show();
            } else {
                $('#payout_unlocked_card').show();
            }
        } catch(e) {
            console.error('payout method load error:', e);
            $('#payout_unlocked_card').show();
        }

        jQuery('#data-table_processing').hide();
    });
</script>
@endsection
