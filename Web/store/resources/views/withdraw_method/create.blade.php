@extends('layouts.app')
@section('content')
<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center"></div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                <li class="breadcrumb-item"><a href="{{ route('withdraw-method') }}">Méthode de paiement</a></li>
                <li class="breadcrumb-item active">Configurer</li>
            </ol>
        </div>
    </div>
    <div class="container-fluid">
        <div id="data-table_processing" class="dataTables_processing panel panel-default" style="display:none;">
            {{ trans('lang.processing') }}
        </div>
        <div class="row">
            <div class="col-lg-6">
                <div class="card border">
                    <div class="card-header">
                        <h4 class="mb-0">Méthode de paiement</h4>
                    </div>
                    <div class="card-body">
                        <div id="error_top" class="alert alert-danger" style="display:none"></div>
                        <div id="success_top" class="alert alert-success" style="display:none"></div>

                        <div class="form-group row">
                            <label class="col-4 control-label">Méthode</label>
                            <div class="col-7">
                                <div class="custom-control custom-radio mb-2">
                                    <input type="radio" id="method_wave" name="payout_method" class="custom-control-input" value="wave" checked>
                                    <label class="custom-control-label" for="method_wave">Wave</label>
                                </div>
                                <div class="custom-control custom-radio">
                                    <input type="radio" id="method_om" name="payout_method" class="custom-control-input" value="orange_money">
                                    <label class="custom-control-label" for="method_om">Orange Money</label>
                                </div>
                            </div>
                        </div>

                        <div class="form-group row">
                            <label class="col-4 control-label">Numéro</label>
                            <div class="col-7">
                                <input type="text" id="payout_phone" class="form-control" placeholder="+221XXXXXXXX">
                            </div>
                        </div>

                        <div class="form-group row">
                            <label class="col-4 control-label">Titulaire</label>
                            <div class="col-7">
                                <input type="text" id="payout_holder" class="form-control" placeholder="Nom du titulaire">
                            </div>
                        </div>

                        <div class="alert alert-info">
                            <i class="mdi mdi-information mr-1"></i>
                            Une fois enregistrée, cette méthode est verrouillée. Pour la modifier, contactez le support JOXMAKO.
                        </div>

                        <div class="form-group row">
                            <div class="col-10 offset-4">
                                <button id="save_method_btn" class="btn btn-primary">
                                    <i class="fa fa-save"></i> Enregistrer
                                </button>
                                <a href="{{ route('withdraw-method') }}" class="btn btn-default ml-2">Annuler</a>
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
    var database     = firebase.firestore();
    var vendorUserId = "<?php echo $id; ?>";
    var authRole     = "{{ $authRole }}";
    var empVendorId  = "{{ $empVendorId }}";
    var targetUserId = vendorUserId;

    document.addEventListener('DOMContentLoaded', async function() {
        jQuery('#data-table_processing').show();

        if (authRole !== 'vendor' && empVendorId) {
            try {
                var vSnap = await database.collection('vendors').doc(empVendorId).get();
                if (vSnap.exists) targetUserId = vSnap.data().author || vendorUserId;
            } catch(e) {}
        }

        // Redirect if already locked
        try {
            var userDoc = await database.collection('users').doc(targetUserId).get();
            var bd = userDoc.exists ? (userDoc.data().userBankDetails || null) : null;
            if (bd && bd.payout_locked) {
                window.location.href = '{{ route("withdraw-method") }}';
                return;
            }
        } catch(e) {}

        jQuery('#data-table_processing').hide();

        $('#save_method_btn').on('click', async function() {
            $('#error_top').hide();
            var method = $('input[name="payout_method"]:checked').val();
            var phone  = $('#payout_phone').val().trim();
            var holder = $('#payout_holder').val().trim();

            if (!phone) {
                $('#error_top').show().text('Veuillez entrer votre numéro de paiement.');
                return;
            }
            if (!holder) {
                $('#error_top').show().text('Veuillez entrer le nom du titulaire.');
                return;
            }

            $(this).prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Enregistrement…');
            jQuery('#data-table_processing').show();

            try {
                await database.collection('users').doc(targetUserId).update({
                    'userBankDetails': {
                        'bankName':      method,
                        'accountNumber': phone,
                        'holderName':    holder,
                        'payout_locked': true,
                    }
                });

                jQuery('#data-table_processing').hide();
                $('#success_top').show().text('Méthode de paiement enregistrée et verrouillée.');
                setTimeout(function() {
                    window.location.href = '{{ route("withdraw-method") }}';
                }, 1500);

            } catch(e) {
                jQuery('#data-table_processing').hide();
                $('#error_top').show().text('Erreur : ' + e.message);
                $('#save_method_btn').prop('disabled', false).html('<i class="fa fa-save"></i> Enregistrer');
            }
        });
    });
</script>
@endsection
