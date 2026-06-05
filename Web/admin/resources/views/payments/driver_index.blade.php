@extends('layouts.app')

@section('content')
    <div class="page-wrapper">
        <div class="row page-titles">
            <div class="col-md-5 align-self-center">
                <h3 class="text-themecolor">{{ trans('lang.driver') }} {{ trans('lang.payment_plural') }}</h3>
            </div>
            <div class="col-md-7 align-self-center">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                    <li class="breadcrumb-item active">{{ trans('lang.driver') }} {{ trans('lang.payment_plural') }}</li>
                </ol>
            </div>
        </div>
        <div class="container-fluid">
            <div class="table-list">
                <div class="row">
                    <div class="col-12">
                        <div class="card border">
                            <div class="card-header d-flex justify-content-between align-items-center border-0">
                                <div class="card-header-title">
                                    <h3 class="text-dark-2 mb-2 h4">Gains chauffeurs <span class="counter ml-2 total_count"></span></h3>
                                    <p class="mb-0 text-dark-2">Gains impayés / payés / espèces à remettre par chauffeur</p>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive m-t-10">
                                    <table id="example24" class="display nowrap table table-hover table-striped table-bordered" cellspacing="0" width="100%">
                                        <thead>
                                            <tr>
                                                <th>{{ trans('lang.driver') }}</th>
                                                <th>Gains impayés</th>
                                                <th>Gains payés</th>
                                                <th>Espèces à remettre</th>
                                                <th>Commandes</th>
                                                <th>Actions</th>
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
        var database = firebase.firestore();
        var currentCurrency = '';
        var decimal_degits = 0;

        database.collection('currencies').where('isActive', '==', true).get().then(function(s) {
            if (s.docs[0]) {
                currentCurrency = s.docs[0].data().symbol || '';
                decimal_degits  = s.docs[0].data().decimal_degits || 0;
            }
        });

        function fmt(v) {
            return currentCurrency + ' ' + parseFloat(v || 0).toFixed(decimal_degits);
        }

        $(document).ready(async function() {
            jQuery('#data-table_processing').show();

            var snap = await database.collection('vendor_orders')
                .where('status', '==', 'Order Completed')
                .get();

            // Group by driverID
            var groups = {};
            snap.docs.forEach(function(doc) {
                var d = doc.data();
                if (!d.driverID) return;
                if (!groups[d.driverID]) {
                    groups[d.driverID] = { unpaid: 0, paid: 0, cash: 0, count: 0 };
                }
                var earning = parseFloat(d.driver_earning || 0);
                if (d.driver_payout_status === 'unpaid') groups[d.driverID].unpaid += earning;
                if (d.driver_payout_status === 'paid')   groups[d.driverID].paid   += earning;
                var method = String(d.collected_payment_method || d.payment_method || '').toLowerCase();
                var isCash = method === 'cash' || method === 'cod' || method === 'cash_on_delivery';
                if (isCash && d.cash_remittance_status === 'pending') groups[d.driverID].cash += parseFloat(d.cash_to_remit || 0);
                groups[d.driverID].count++;
            });

            var tbody = $('#append_list1').empty();
            jQuery('#data-table_processing').hide();

            if (Object.keys(groups).length === 0) {
                tbody.append('<tr><td colspan="6" class="text-center">Aucune commande terminée</td></tr>');
                return;
            }

            for (var driverId in groups) {
                var g = groups[driverId];
                var userSnap = await database.collection('users').where('id', '==', driverId).get();
                if (userSnap.empty) continue;
                var u = userSnap.docs[0].data();
                var name = (u.firstName || '') + ' ' + (u.lastName || '');
                var driverUrl = '{{ url("drivers") }}/' + driverId;
                var payoutUrl = '{{ url("driversPayouts") }}/' + driverId;

                var cashCell = g.cash > 0
                    ? '<span class="text-warning font-weight-bold">' + fmt(g.cash) + '</span>'
                    : '<span class="text-muted">-</span>';

                tbody.append(
                    '<tr>' +
                    '<td><a href="' + driverUrl + '">' + name + '</a></td>' +
                    '<td class="text-danger font-weight-bold">' + fmt(g.unpaid) + '</td>' +
                    '<td class="text-success">' + fmt(g.paid) + '</td>' +
                    '<td>' + cashCell + '</td>' +
                    '<td>' + g.count + '</td>' +
                    '<td><a href="' + payoutUrl + '" class="btn btn-sm btn-outline-primary">Détail</a>' +
                         (g.unpaid > 0 ? ' <a href="{{ url("driversPayouts/create") }}/' + driverId + '" class="btn btn-sm btn-primary ml-1">Payer</a>' : '') +
                    '</td>' +
                    '</tr>'
                );
            }
            $('.total_count').text(Object.keys(groups).length);
        });
    </script>
@endsection
