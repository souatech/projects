@extends('layouts.app')

@section('content')
    <div class="page-wrapper">
        <div class="row page-titles">
            <div class="col-md-5 align-self-center">
                <div class="d-flex top-title-section pb-4 justify-content-between">
                    <div class="d-flex top-title-left align-self-center">
                        <span class="icon mr-3"><img src="{{ asset('images/payment.png') }}"></span>
                        <h3 class="mb-0">{{trans('lang.vendors_payout_plural')}} <span class="page-title"></span></h3>
                        <span class="counter ml-3 total_count"></span>
                    </div>
                </div>
            </div>
            <div class="col-md-7 align-self-center">
                <ol class="breadcrumb">
                    <li class="breadcrumb-item"><a href="{{ route('dashboard') }}">{{ trans('lang.dashboard') }}</a></li>
                    <li class="breadcrumb-item active">{{ trans('lang.vendors_payout_plural') }}</li>
                </ol>
            </div>
            <div>
            </div>
        </div>
        <div class="container-fluid">
            <div class="table-list">
                <div class="row">
                    <div class="col-12">
                        <?php if ($id != '') { ?>
                        <div class="menu-tab">

                            <ul>

                                <li>

                                    <a href="{{ route('stores.view', $id) }}"><i class="ri-list-indefinite"></i>{{ trans('lang.tab_basic') }}</a>

                                </li>

                                <li>

                                    <a href="{{ route('vendors.items', $id) }}"><i class="ri-shopping-basket-fill"></i>{{ trans('lang.tab_items') }}</a>

                                </li>

                                <li>

                                    <a href="{{ route('vendors.orders', $id) }}"><i class="ri-shopping-bag-line"></i>{{ trans('lang.tab_orders') }}</a>

                                </li>

                                <li>

                                    <a href="{{ route('vendors.reviews', $id) }}"><i class="ri-shield-star-fill"></i>{{ trans('lang.tab_reviews') }}</a>

                                </li>

                                <li>

                                    <a href="{{ route('vendors.coupons', $id) }}"><i class="ri-discount-percent-fill"></i>{{ trans('lang.tab_promos') }}</a>

                                <li class="active">

                                    <a href="{{ route('vendors.payout', $id) }}"><i class="ri-bank-card-line"></i>{{ trans('lang.tab_payouts') }}</a>

                                </li>

                                <li>

                                    <a href="{{ route('payoutRequests.vendor.view', $id) }}"><i class="ri-refund-line"></i>{{ trans('lang.tab_payout_request') }}</a>

                                </li>

                                <li>

                                    <a class="wallet_transaction"><i class="ri-wallet-line"></i>{{ trans('lang.wallet_transaction') }}</a>

                                </li>

                                <li class="dine_in_future" style="display:none;">

                                    <a href="{{route('vendors.booktable',$id)}}"><i class="ri-restaurant-line"></i>{{trans('lang.dine_in_booking_history')}}</a>

                                </li>
                                <?php
                                $subscription = route('subscription.subscriptionPlanHistory', ':id');
                                $subscription = str_replace(':id', 'storeID=' . $id, $subscription);
                                ?>
                                <li>
                                    <a href="{{ $subscription }}"><i class="ri-chat-history-fill"></i>{{ trans('lang.subscription_history') }}</a>
                                </li>
                                <li>
                                    <a href="{{ route('restaurants.advertisements', $id) }}"><i class="mdi mdi-newspaper"></i>{{ trans('lang.advertisement_plural') }}</a>
                                </li>
                                 @php
                                    $sectionType = $_COOKIE['service_type'] ?? ''; 
                                    
                                @endphp
                                <?php if($sectionType == 'ecommerce-service'){ ?>
                               
                                <?php }else{ ?>
                                <li class="">
                                    <a href="{{ route('restaurants.deliveryman', $id) }}"><i class="ri-riding-fill"></i>{{ trans('lang.deliveryman') }}</a>
                                </li>
                                    <?php }?>

                            </ul>

                        </div>
                        <?php } ?>
                        <div class="card border">
                            <div class="card-header d-flex justify-content-between align-items-center border-0">
                                <div class="card-header-title">
                                    <h3 class="text-dark-2 mb-2 h4">{{ trans('lang.vendors_payout_plural') }}</h3>
                                    <p class="mb-0 text-dark-2">{{ trans('lang.vendors_payouts_table_text') }}</p>
                                </div>
                                <div class="card-header-right d-flex align-items-center">
                                    <div class="card-header-btn mr-3">
                                        <?php if ($id != '') { ?>
                                        <a class="btn-primary btn rounded-full" href="{!! route('vendorsPayouts.create') !!}/{{ $id }}"><i class="mdi mdi-plus mr-2"></i>{{ trans('lang.vendors_payout_create') }}</a>
                                        <?php } else { ?>
                                        <a class="btn-primary btn rounded-full" href="{!! route('vendorsPayouts.create') !!}"><i class="mdi mdi-plus mr-2"></i>{{ trans('lang.vendors_payout_create') }}</a>
                                        <?php } ?>
                                    </div>
                                </div>
                            </div>
                            <div class="card-body">
                                <div class="table-responsive m-t-10">
                                    <table id="example24" class="display nowrap table table-hover table-striped table-bordered table table-striped" cellspacing="0" width="100%">
                                        <thead>
                                            <tr>
                                                <th>Restaurant</th>
                                                <th>Méthode</th>
                                                <th>Numéro</th>
                                                <th>Revenus impayés</th>
                                                <th>Commandes</th>
                                                <th>{{ trans('lang.actions') }}</th>
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
        // JOXMAKO — Revenus impayés restaurants
        var database = firebase.firestore();
        var id = '<?php echo $id; ?>';
        var currentCurrency = '';
        database.collection('currencies').where('isActive','==',true).get().then(function(s){
            if(s.docs[0]) currentCurrency = s.docs[0].data().symbol||'';
        });
        function fmt(v){ return currentCurrency+' '+parseFloat(v||0).toFixed(0); }

        $(document).ready(async function(){
            var query = database.collection('vendor_orders').where('status','==','Order Completed');
            if(id!=='') query = query.where('vendorID','==',id);
            var snap = await query.get();

            var groups={};
            snap.docs.forEach(function(doc){
                var d=doc.data();
                if(d.vendor_payout_status!=='unpaid') return;
                if(!d.vendorID||!d.vendor_earning) return;
                if(!groups[d.vendorID]) groups[d.vendorID]={total:0,count:0,vendorId:d.vendorID};
                groups[d.vendorID].total+=parseFloat(d.vendor_earning||0);
                groups[d.vendorID].count++;
            });

            var tbody=$('#append_list1').empty();
            if(!Object.keys(groups).length){
                tbody.append('<tr><td colspan="6" class="text-center">Aucun revenu impayé</td></tr>');
                return;
            }
            for(var vid in groups){
                var g=groups[vid];
                var vSnap=await database.collection('users').where('vendorID','==',vid).get();
                var name=vid,method='-',number='-';
                if(!vSnap.empty){
                    var u=vSnap.docs[0].data();
                    name=(u.firstName||'')+(u.restaurantName||u.lastName||'');
                    method=(u.userBankDetails&&u.userBankDetails.bankName)?u.userBankDetails.bankName:'-';
                    number=(u.userBankDetails&&u.userBankDetails.accountNumber)?u.userBankDetails.accountNumber:'-';
                }
                var payUrl='{{ url("vendorsPayouts/create") }}/'+vid;
                tbody.append(
                    '<tr>'+
                    '<td>'+name+'</td>'+
                    '<td>'+method+'</td>'+
                    '<td>'+number+'</td>'+
                    '<td><strong>'+fmt(g.total)+'</strong></td>'+
                    '<td>'+g.count+'</td>'+
                    '<td><a href="'+payUrl+'" class="btn btn-sm btn-primary">Payer</a></td>'+
                    '</tr>'
                );
            }
            $('.total_count').text(Object.keys(groups).length);
        });
    </script>

@endsection
