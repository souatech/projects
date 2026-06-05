<nav id="main-nav">
    <ul class="second-nav">
        <li> <a href="<?php echo e(route('search')); ?>" class="widget-header mr-4 page text-dark">
            <div class="icon d-flex align-items-center">
                <i class="feather-search h6 mr-2 mb-0"></i> <span><?php echo e(trans('lang.search')); ?></span>
            </div>
        </a></li>
        <li><a href="<?php echo e(url('/')); ?>"><i class="fa fa-home mr-2"></i> <?php echo e(trans('lang.home_page')); ?></a></li>
        <?php if(auth()->guard()->check()): ?>
            <li><a href="<?php echo e(route('offers')); ?>" class="widget-header mr-4 page text-dark offer-link">
                <div class="icon d-flex align-items-center">
                    <img alt="#" class="img-fluid mr-2"
                                                                            src="<?php echo e(asset('img/discount.png')); ?>">
                    <span><?php echo e(trans('lang.offers')); ?></span>
                </div>
            </a></li>
            <li> <a href="<?php echo e(route('checkout')); ?>" class="widget-header mr-4 page text-dark">
                <div class="icon d-flex align-items-center">
                    <i class="feather-shopping-cart h6 mr-2 mb-0"></i> <span><?php echo e(trans('lang.cart')); ?></span>
                </div>
            </a></li>
            <?php if(@$_COOKIE['service_type'] == "Parcel Delivery Service"): ?>
                <li><a href="<?php echo e(route('parcel_orders')); ?>"><i class="fa fa-list-ul mr-2"></i> <?php echo e(trans('lang.my_orders')); ?>

                    </a></li>
            <?php elseif(@$_COOKIE['service_type'] == "Rental Service"): ?>
                <li><a href="<?php echo e(route('rental_orders')); ?>"><i class="fa fa-list-ul mr-2"></i> <?php echo e(trans('lang.my_orders')); ?>

                    </a></li>
            <?php elseif(@$_COOKIE['service_type'] == "Cab Service"): ?>
                <li><a href="<?php echo e(route('my_order')); ?>" style="display:none"><i class="fa fa-list-ul mr-2"
                                                                          style="display:none"></i> <?php echo e(trans('lang.my_orders')); ?>

                    </a></li>
            <?php elseif(@$_COOKIE['service_type'] == "On Demand Service"): ?>
                <li><a href="<?php echo e(route('my-bookings')); ?>"><i class="fa fa-list-ul mr-2"></i> <?php echo e(trans('lang.my_booking')); ?></a>
                </li>
            <?php else: ?>
                <li><a href="<?php echo e(route('my_order')); ?>"><i class="fa fa-list-ul mr-2"></i> <?php echo e(trans('lang.my_orders')); ?></a>
                </li>
            <?php endif; ?>
            <?php if(false): ?> 
            <?php if(@$_COOKIE['service_type'] == "Cab Service"): ?>
                <li><a href="<?php echo e(route('transactions')); ?>" style="display:none"><i class="fa fa-list-ol mr-2"
                                                                              style="display:none"></i> <?php echo e(trans('lang.my_transactions')); ?>

                    </a></li>
            <?php else: ?>
                <li><a href="<?php echo e(route('transactions')); ?>"><i
                                class="fa fa-list-ol mr-2"></i> <?php echo e(trans('lang.my_transactions')); ?></a></li>
            <?php endif; ?>
            <?php endif; ?>
            <?php if(@$_COOKIE['service_type'] == "Multivendor Delivery Service" || @$_COOKIE['service_type']=="Ecommerce Service" ): ?>
                <li><a href="<?php echo e(route('favorites')); ?>"><i
                                class="fa fa-heart mr-2"></i> <?php echo e(trans('lang.favorite_stores')); ?></a></li>
                <li><a href="<?php echo e(route('favorites.product')); ?>"><i
                                class="fa fa-heart mr-2"></i> <?php echo e(trans('lang.favorite_products')); ?></a></li>
                <li><a href="<?php echo e(route('vendors')); ?>"><i class="fa fa-th-list mr-2"></i> <?php echo e(trans('lang.all_store')); ?></a></li>
                <li><a href="<?php echo e(route('delivery-address.index')); ?>"><i
                                class="feather-book mr-2"></i> <?php echo e(trans('lang.address_book')); ?></a></li>
            <?php endif; ?>
            <?php if(@$_COOKIE['service_type'] == "On Demand Service"): ?>
                <li><a href="<?php echo e(route('ondemand-services')); ?>"><i
                                class="fa fa-th-list mr-2"></i> <?php echo e(trans('lang.all_services')); ?></a></li>
                <li><a href="<?php echo e(route('favorites.provider')); ?>"><i
                                class="fa fa-heart mr-2"></i> <?php echo e(trans('lang.favorite_providers')); ?></a></li>
                <li><a href="<?php echo e(route('favorites.service')); ?>"><i
                                class="fa fa-heart mr-2"></i> <?php echo e(trans('lang.favorite_services')); ?></a></li>
                <li><a href="<?php echo e(route('delivery-address.index')); ?>"><i
                                class="feather-book mr-2"></i> <?php echo e(trans('lang.address_book')); ?></a></li>
            <?php endif; ?>
            <?php if(false): ?> 
            <li><a href="<?php echo e(route('customize.giftcard')); ?>"><i class="fa fa-gift mr-2"></i> <?php echo e(trans('lang.buy_gift_card')); ?></a>
            </li>
            <li><a href="<?php echo e(route('giftcards')); ?>"><i class="fa fa-gift mr-2"></i> <?php echo e(trans('lang.my_gift_cards')); ?></a></li>
            <?php endif; ?>
            <?php if(@$_COOKIE['dine_in_active'] && @$_COOKIE['dine_in_active'] == 'true'): ?>
                <li class="dine_in_menu"><a href="<?php echo e(route('vendors')); ?>?dinein=1"><i
                                class="fa fa-list-ul mr-2"></i><?php echo e(trans('lang.dine_in_vendor')); ?></a></li>
                <li class="dine_in_menu dineinrestaurant_tab "><a href="<?php echo e(route('my_dinein')); ?>"><i
                                class="fa fa-list-ul mr-2"></i><?php echo e(trans('lang.my_dine_in_requests')); ?></a></li>
            <?php endif; ?>
            <li><a href="<?php echo e(route('profile')); ?>"><i class="fa fa-user mr-2"></i><?php echo e(trans('lang.user_profile')); ?></a></li>
            <li><a href="<?php echo e(route('contact_us')); ?>"><i class="fa fa-phone mr-2"></i><?php echo e(trans('lang.contact_us')); ?></a></li>
            <li><a href="<?php echo e(route('logout')); ?>"
                   onclick="event.preventDefault(); document.getElementById('logout-form').submit();"><i
                            class="fa fa-sign-out mr-2"></i><?php echo e(trans('lang.logout')); ?></a></li>
            <form id="logout-form" action="<?php echo e(route('logout')); ?>" method="POST" class="d-none">
                <?php echo csrf_field(); ?>
            </form>
            <li><p class="referral_code"></p></li>
        <?php else: ?>
            <li><a href="<?php echo e(route('contact_us')); ?>"><i class="fa fa-phone mr-2"></i><?php echo e(trans('lang.contact_us')); ?></a></li>
            <?php if(@$_COOKIE['service_type'] == "Multivendor Delivery Service" ||  @$_COOKIE['service_type']=="Ecommerce Service" ): ?>
                <li><a href="<?php echo e(route('vendors')); ?>"><i class="fa fa-th-list mr-2"></i> <?php echo e(trans('lang.all_store')); ?></a></li>
            <?php endif; ?>
            <?php if(@$_COOKIE['service_type'] == "On Demand Service"): ?>
                <li><a href="<?php echo e(route('ondemand-services')); ?>"><i
                                class="fa fa-th-list mr-2"></i> <?php echo e(trans('lang.all_services')); ?></a></li>
            <?php endif; ?>
            <?php if(@$_COOKIE['dine_in_active'] && @$_COOKIE['dine_in_active'] == 'true'): ?>
                <li class="dine_in_menu"><a href="<?php echo e(route('vendors')); ?>?dinein=1"><i
                                class="fa fa-th-list mr-2"></i><?php echo e(trans('lang.dine_in_vendor')); ?></a></li>
            <?php endif; ?>
            <li><a href="<?php echo e(route('login')); ?>"><i class="fa fa-sign-in mr-2"></i><?php echo e(trans('lang.login')); ?></a></li>
            <li><a href="<?php echo e(route('signup')); ?>"><i class="fa fa-user-plus mr-2"></i><?php echo e(trans('lang.register')); ?></a></li>
        <?php endif; ?>
        <li><p class="web_version"></p></li>
    </ul>
    <ul class="bottom-nav">
        <li class="email">
            <a class="text-danger" href="<?php echo e(url('/')); ?>">
                <p class="h5 m-0"><i class="fa fa-home text-danger"></i></p>
                <?php echo e(trans('lang.home')); ?>

            </a>
        </li>
        <li class="ko-fi">
            <a href="<?php echo e(route('contact_us')); ?>">
                <p class="h5 m-0"><i class="feather-phone"></i></p>
                <?php echo e(trans('lang.help')); ?>

            </a>
        </li>
    </ul>
</nav>
<div class="modal fade" id="exampleModal" tabindex="-1" role="dialog" aria-labelledby="exampleModalLabel"
     aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title"><?php echo e(trans('lang.filter')); ?></h5>
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span>
                </button>
            </div>
            <div class="modal-body p-0">
                <div class="siddhi-filter">
                    <div class="filter">
                        <div class="p-3 bg-light border-bottom">
                            <h6 class="m-0"><?php echo e(trans('lang.SORT_BY')); ?> </h6>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-radio">
                            <input type="radio" id="customRadio1f" name="location" class="custom-control-input" checked>
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="customRadio1f"><?php echo e(trans('lang.top_rated')); ?></label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-radio">
                            <input type="radio" id="customRadio2f" name="location" class="custom-control-input">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="customRadio2f"><?php echo e(trans('lang.nearest_me')); ?> </label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-radio">
                            <input type="radio" id="customRadio3f" name="location" class="custom-control-input">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="customRadio3f"> <?php echo e(trans('lang.cost_high_to_low')); ?> </label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-radio">
                            <input type="radio" id="customRadio4f" name="location" class="custom-control-input">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="customRadio4f"><?php echo e(trans('lang.cost_low_to_high')); ?> </label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-radio">
                            <input type="radio" id="customRadio5f" name="location" class="custom-control-input">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="customRadio5f"> <?php echo e(trans('lang.most_popular')); ?> </label>
                        </div>
                        <div class="p-3 bg-light border-bottom">
                            <h6 class="m-0"><?php echo e(trans('lang.FILTER')); ?> </h6>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-checkbox">
                            <input type="checkbox" class="custom-control-input" id="defaultCheck1" checked>
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="defaultCheck1"><?php echo e(trans('lang.open_now')); ?> </label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-checkbox">
                            <input type="checkbox" class="custom-control-input" id="defaultCheck2">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="defaultCheck2"><?php echo e(trans('lang.credit_cards')); ?> </label>
                        </div>
                        <div class="custom-control border-bottom px-0  custom-checkbox">
                            <input type="checkbox" class="custom-control-input" id="defaultCheck3">
                            <label class="custom-control-label py-3 w-100 px-3"
                                   for="defaultCheck3"><?php echo e(trans('lang.alcohol_served')); ?> </label>
                        </div>
                        <div class="p-3 bg-light border-bottom">
                            <h6 class="m-0"><?php echo e(trans('lang.ADDITIONAL_FILTERS')); ?> </h6>
                        </div>
                        <div class="px-3 pt-3">
                            <input type="range" class="custom-range" min="0" max="100" name="minmax">
                            <div class="form-row">
                                <div class="form-group col-6">
                                    <label><?php echo e(trans('lang.min')); ?> </label>
                                    <input class="form-control" placeholder="$0" type="number">
                                </div>
                                <div class="form-group text-right col-6">
                                    <label><?php echo e(trans('lang.max')); ?> </label>
                                    <input class="form-control" placeholder="$1,0000" type="number">
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer p-0 border-0">
                <div class="col-6 m-0 p-0">
                    <button type="button" class="btn border-top btn-lg btn-block"
                            data-dismiss="modal"><?php echo e(trans('lang.close')); ?></button>
                </div>
                <div class="col-6 m-0 p-0">
                    <button type="button" class="btn btn-primary btn-lg btn-block"><?php echo e(trans('lang.apply')); ?></button>
                </div>
            </div>
        </div>
    </div>
</div>
<script type="text/javascript">
    var database = firebase.firestore();
    var version = database.collection('settings').doc("Version");
    version.get().then(async function (snapshots) {
        var version_data = snapshots.data();
        if (version_data == undefined) {
            database.collection('settings').doc('Version').set({});
        }
        try {
            $('.web_version').html("V:" + version_data.web_version);
        } catch (error) {
        }
    });
</script><?php /**PATH /home/u844577645/domains/joxmako.com/public_html/resources/views/layouts/nav.blade.php ENDPATH**/ ?>