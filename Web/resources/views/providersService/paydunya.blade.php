@include('layouts.app')
@include('layouts.header')

<div class="siddhi-checkout siddhi-checkout-payment">
    <div class="container position-relative">
        <div class="py-5 row">
            <div class="col-md-12 mb-3">
                <div class="siddhi-cart-item mb-3 rounded shadow-sm bg-white overflow-hidden">
                    <div class="siddhi-cart-item-profile bg-white p-3">
                        <div class="card card-default payment-wrap text-center p-4">
                            <p>{{ trans('lang.processing_success') }}</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@include('layouts.footer')
@include('layouts.nav')
