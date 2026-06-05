<?php
$user = Auth::user();
$role_has_permission = App\Models\Permission::where('role_id', $user->role_id)->pluck('permission')->toArray();
$service_type = @$_COOKIE['service_type'];
?>

<div class="navbar-header position-relative">
    <a class="navbar-brand" href="<?php echo URL::to('/'); ?>">
        <b>
            <img src="<?php echo e(asset('/images/logo_web.png')); ?>" onerror="this.onerror=null; this.src='<?php echo e(asset('/images/logo_web.png')); ?>';" alt="homepage" class="dark-logo" width="100%" id="logo_web">
            <img src="<?php echo e(asset('images/logo-light-icon.png')); ?>" onerror="this.onerror=null; this.src='<?php echo e(asset('images/logo-light-icon.png')); ?>';" alt="homepage" class="light-logo">
        </b>
    </a>
    <div class="sidebar-toggle">  
        <span class="nav-item mb-toggle">
            <a class="nav-link nav-toggler hidden-md-up text-muted waves-effect waves-dark" href="javascript:void(0)"><i class="mdi mdi-menu"></i></a>
        </span>
        <span class="nav-item">
            <a class="nav-link sidebartoggler hidden-sm-down text-muted waves-effect waves-dark" href="javascript:void(0)">
                <svg xmlns="http://www.w3.org/2000/svg" width="19" height="19" viewBox="0 0 19 19" fill="none">
                    <path fill-rule="evenodd" clip-rule="evenodd"
                        d="M0.791687 9.49999C0.791687 4.69051 4.69054 0.791656 9.50002 0.791656C14.3095 0.791656 18.2084 4.69051 18.2084 9.49999C18.2084 14.3095 14.3095 18.2083 9.50002 18.2083C4.69054 18.2083 0.791687 14.3095 0.791687 9.49999ZM9.50002 2.37499C5.56499 2.37499 2.37502 5.56496 2.37502 9.49999C2.37502 13.435 5.56499 16.625 9.50002 16.625C13.4351 16.625 16.625 13.435 16.625 9.49999C16.625 5.56496 13.4351 2.37499 9.50002 2.37499ZM9.85861 5.57561C10.1678 5.88478 10.1678 6.38603 9.85861 6.6952L7.64757 8.90624H12.8613C13.2985 8.90624 13.653 9.26068 13.653 9.69791C13.653 10.1351 13.2985 10.4896 12.8613 10.4896H7.64757L9.85861 12.7006C10.1678 13.0098 10.1678 13.511 9.85861 13.8202C9.54945 14.1294 9.04819 14.1294 8.73903 13.8202L5.17653 10.2577C4.86736 9.94853 4.86736 9.44728 5.17653 9.13811L8.73903 5.57561C9.04819 5.26645 9.54945 5.26645 9.85861 5.57561Z"
                        fill="white"></path>
                </svg>
            </a>
        </span>
    </div>
</div>
<div class="navbar-collapse sidebar-nav">
    <ul class="navbar-nav mr-auto mt-md-0 header-user-menu sidebarnav p-l-20">
        <?php if(in_array('users', $role_has_permission)): ?>
        <li class="nav-item text-light">
           <a class="nav-link" href="<?php echo route('users'); ?>" aria-expanded="false">
                <i class="mdi mdi-account-multiple"></i>
                <span class="hide-menu"><?php echo e(trans('lang.user_customer')); ?></span>
            </a>
        </li>
        <?php endif; ?>
        <?php if(in_array('zone', $role_has_permission)): ?>
        <li class="nav-item text-light">
            <a class="nav-link" href="<?php echo route('zone'); ?>" aria-expanded="false">
                <i class="mdi mdi-map-marker-circle"></i>
                <span class="hide-menu"><?php echo e(trans('lang.zone')); ?></span>
            </a>
        </li>
        <?php endif; ?>
        <?php if(in_array('section-service', $role_has_permission)): ?>
        <li class="nav-item text-light">
           <a class="nav-link" href="<?php echo route('section'); ?>" aria-expanded="false">
                <i class="mdi mdi-clipboard-text"></i>
                <span class="hide-menu"><?php echo e(trans('lang.section_plural')); ?></span>
            </a>
        </li>
        <?php endif; ?>
        <?php if(
        in_array('app-banners-setting', $role_has_permission) ||
        in_array('global-setting', $role_has_permission) ||
        in_array('currency', $role_has_permission) ||
        in_array('payment-method', $role_has_permission) ||
        in_array('business-model', $role_has_permission) ||
        in_array('radius', $role_has_permission) ||
        in_array('scheduleOrderNotification', $role_has_permission) ||
        in_array('tax', $role_has_permission) ||
        in_array('delivery-charge', $role_has_permission) ||
        in_array('document-verification', $role_has_permission) ||
        in_array('language', $role_has_permission) ||
        in_array('special-offer', $role_has_permission) ||
        in_array('terms', $role_has_permission) ||
        in_array('privacy', $role_has_permission) ||
        in_array('home-page', $role_has_permission) ||
        in_array('footer', $role_has_permission) || in_array('settings-maintenance', $role_has_permission)
        ): ?>
        <li id="activeSection" class="text-light nav-item dropdown">
                <a class="nav-link dropdown-toggle waves-effect waves-dark" href="#" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                    <i class="mdi mdi-settings"></i>
                    <span class="hide-menu"><?php echo e(trans('lang.app_setting')); ?></span>
                </a>
              <div class="dropdown-menu dropdown-setting scale-down sidebar-nav">  
                <ul class="sidebarnav">
                    <?php if(in_array('global-setting', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.globals'); ?>"><i class="mdi mdi-web"></i> <?php echo e(trans('lang.app_setting_globals')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('currency', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('currencies'); ?>"><i class="mdi mdi-currency-usd"></i> <?php echo e(trans('lang.currency_plural')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('business-model', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('businessModel'); ?>"><i class="mdi mdi-domain"></i> <?php echo e(trans('lang.business_model_settings')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('tax', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('tax'); ?>"><i class="mdi mdi-database"></i> <?php echo e(trans('lang.tax_setting')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('payment-method', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('payment.stripe'); ?>"><i class="mdi mdi-credit-card"></i> <?php echo e(trans('lang.app_setting_payment')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('radius', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.radiusConfiguration'); ?>"><i class="mdi mdi-map-marker-radius"></i> <?php echo e(trans('lang.radios_configuration')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('app-banners-setting', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.banners'); ?>"><i class="mdi mdi-page-layout-body"></i> <?php echo e(trans('lang.app_setting_banners')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('scheduleOrderNotification', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.scheduleOrderNotification'); ?>"><i class="mdi mdi-bell-outline"></i> <?php echo e(trans('lang.schedule_order_notification_title')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('delivery-charge', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.deliveryCharge'); ?>"><i class="mdi mdi-truck-delivery"></i> <?php echo e(trans('lang.delivery_charge')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('openai-settings', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.openai-settings'); ?>"><i class="mdi mdi-robot"></i> <?php echo e(trans('lang.openai_settings')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('document-verification', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.documentVerification'); ?>"><i class="mdi mdi-file-document"></i> <?php echo e(trans('lang.document_verification')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('language', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.languages'); ?>"><i class="mdi mdi-translate"></i> <?php echo e(trans('lang.languages')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('special-offer', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.specialoffer'); ?>"><i class="mdi mdi-percent"></i> <?php echo e(trans('lang.special_offer')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('settings-maintenance', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('settings.app.maintenance'); ?>"><i class="mdi mdi-settings"></i> <?php echo e(trans('lang.maintenance_mode_settings')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('terms', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('termsAndConditions'); ?>"><i class="mdi mdi-file"></i> <?php echo e(trans('lang.terms_and_conditions')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('privacy', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('privacyPolicy'); ?>"><i class="mdi mdi-file-check"></i> <?php echo e(trans('lang.privacy_policy')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('home-page', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('homepageTemplate'); ?>"><i class="mdi mdi-page-layout-body"></i> <?php echo e(trans('lang.homepageTemplate')); ?></a></li>
                    <?php endif; ?>
                    <?php if(in_array('footer', $role_has_permission)): ?>
                    <li><a class="nav-link"href="<?php echo route('footerTemplate'); ?>"><i class="mdi mdi-page-layout-footer"></i> <?php echo e(trans('lang.footer_template')); ?></a></li>
                    <?php endif; ?>
                </ul>
            </div>
        </li>
        <?php endif; ?>

        <?php if(
        in_array('banners', $role_has_permission) ||
        in_array('cms', $role_has_permission) ||
        in_array('on-board', $role_has_permission) ||
        in_array('email-template', $role_has_permission)
        ): ?>
        <li id="activeSection" class="text-light nav-item dropdown">
            <a class="nav-link dropdown-toggle waves-effect waves-dark" href="#" data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                <i class="mdi mdi-palette"></i>
                <span class="hide-menu"><?php echo e(trans('lang.content_management')); ?></span>
            </a>
            <div class="dropdown-menu dropdown-setting scale-down sidebar-nav">  
                <ul class="sidebarnav">
                    <?php if($service_type != "rental-service"): ?>
                    <?php if(in_array('banners', $role_has_permission)): ?>
                    <li><a class="waves-effect waves-dark nav-link" href="<?php echo route('banners'); ?>" aria-expanded="false">
                            <i class="mdi mdi-monitor-multiple "></i>
                            <span class="hide-menu"><?php echo e(trans('lang.menu_items')); ?></span>
                        </a>
                    </li>
                    <?php endif; ?>
                    <?php endif; ?>

                    <?php if(in_array('cms', $role_has_permission)): ?>
                    <li><a class="waves-effect waves-dark nav-link" href="<?php echo route('cms'); ?>" aria-expanded="false">
                            <i class="mdi mdi-book-open-page-variant"></i>
                            <span class="hide-menu"><?php echo e(trans('lang.cms_plural')); ?></span>
                        </a>
                    </li>
                    <?php endif; ?>

                    <?php if(in_array('on-board', $role_has_permission)): ?>
                    <li><a class="waves-effect waves-dark nav-link onboard_menu" href="<?php echo route('on-board'); ?>" aria-expanded="false">
                            <i class="mdi mdi-cellphone"></i>
                            <span class="hide-menu"><?php echo e(trans('lang.on_board_plural')); ?></span>
                        </a>
                    </li>
                    <?php endif; ?>

                    <?php if(in_array('email-template', $role_has_permission)): ?>
                    <li><a class="waves-effect waves-dark nav-link" href="<?php echo route('email-templates.index'); ?>" aria-expanded="false">
                            <i class="mdi mdi-email"></i>
                            <span class="hide-menu"><?php echo e(trans('lang.email_templates')); ?></span>
                        </a>
                    </li>
                    <?php endif; ?>
                </ul>
            </div>
        </li>
        <?php endif; ?>
    </ul>

    <div style="visibility: hidden;" class="language-list icon d-flex align-items-center text-light ml-2" id="language_dropdown_box">
        <div class="language-select">
            <i class="fa fa-globe"></i>
        </div>
        <div class="language-options">
            <select class="form-control changeLang text-dark" id="language_dropdown">
            </select>
        </div>
    </div>
    
    <ul class="navbar-nav my-lg-0">
        <li class="nav-item dropdown">
            <a class="nav-link dropdown-toggle text-muted waves-effect waves-dark" href="" data-toggle="dropdown"
                aria-haspopup="true" aria-expanded="false"><img src="<?php echo e(asset('/images/users/user-new.png')); ?>"
                    alt="user" onerror="this.onerror=null; this.src='<?php echo e(asset('/images/users/user-new.png')); ?>';"
                    class="profile-pic"></a>
            <div class="dropdown-menu dropdown-menu-right scale-up">
                <ul class="dropdown-user">
                    <li>
                        <div class="dw-user-box">
                            <div class="u-img"><img src="<?php echo e(asset('/images/users/user-2.png')); ?>"
                                    onerror="this.onerror=null; this.src='<?php echo e(asset('/images/users/user-2.png')); ?>';"
                                    alt="user" style="max-width: 45px;"></div>
                            <div class="u-text">
                                <h4><?php echo e(Auth::user()->name); ?></h4>
                                <p class="text-muted"><?php echo e(session('user_role')); ?></p>
                            </div>
                        </div>
                    </li>
                    <li role="separator" class="divider"></li>
                    <li><a href="<?php echo e(route('users.profile')); ?>"><i class="ti-user"></i>
                            <?php echo trans('lang.user_profile'); ?></a></li>
                    <li role="separator" class="divider"></li>
                    <li><a href="<?php echo e(route('logout')); ?>"
                            onclick="event.preventDefault(); document.getElementById('logout-form').submit();"><i
                                class="fa fa-power-off"></i> <?php echo e(__('Logout')); ?></a></li>
                    <form id="logout-form" action="<?php echo e(route('logout')); ?>" method="POST" class="d-none">
                        <?php echo csrf_field(); ?>
                    </form>
                </ul>
            </div>
        </li>
    </ul>
    <div class="navbar-nav my-lg-0 multi-service-nav">
        <div class="nav-item dropdown" id="activeSection">
            <a class="nav-link dropdown-toggle waves-effect waves-dark" href="#" id="activeSectionLink"
                data-toggle="dropdown" aria-haspopup="true" aria-expanded="false">
                <img src="<?php echo e(asset('/images/logo-light-icon.png')); ?>" id="activeSectionLogo" style="height:40px; margin-right:5px;">
                <span id="activeSectionName"> <?php echo e(trans('lang.select_section')); ?></span>
            </a>
            <div class="dropdown-menu dropdown-service scale-up">
                <div class="dropdown-service_inner">
                    <div class="dropdown-service-top mb-4">
                        <h2><?php echo e(trans('lang.modules_section')); ?></h2>
                        <p><?php echo e(trans('lang.select_module_monitor')); ?></p>
                    </div>
                    <div id="sections_header"></div>
                </div>
            </div>
        </div>
    </div>
</div>
<?php /**PATH /home/u844577645/domains/joxmako.com/public_html/admin/resources/views/layouts/header.blade.php ENDPATH**/ ?>