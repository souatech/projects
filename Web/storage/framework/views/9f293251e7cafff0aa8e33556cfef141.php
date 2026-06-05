<?php echo $__env->make('auth.default', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
<?php
$countries = file_get_contents(public_path('countriesdata.json'));
$countries = json_decode($countries);
$countries = (array)$countries;
$newcountries = array();
$newcountriesjs = array();
foreach ($countries as $keycountry => $valuecountry) {
    $newcountries[$valuecountry->phoneCode] = $valuecountry;
    $newcountriesjs[$valuecountry->phoneCode] = $valuecountry->code;
}
?>
<?php if (isset($_COOKIE['section_color'])){ ?>
<style type="text/css">
    .btn-primary {
        background: <?php echo $_COOKIE['section_color']; ?>;
        border-color: <?php echo $_COOKIE['section_color']; ?>;
    }

    .btn-primary:hover, .btn-primary:not(:disabled):not(.disabled).active, .btn-primary:not(:disabled):not(.disabled):active, .btn-primary:focus {
        background: <?php echo $_COOKIE['section_color']; ?>;
        border-color: <?php echo $_COOKIE['section_color']; ?>;
    }
    .error {
        color: red;
        font-size: 14px;
        margin-top: 5px;
    }

</style>
<?php } ?>
<link href="<?php echo e(asset('vendor/select2/dist/css/select2.min.css')); ?>" rel="stylesheet">
<link href="<?php echo e(asset('/css/font-awesome.min.css')); ?>" rel="stylesheet">
<div class="login-page vh-100">
    <div class="d-flex align-items-center justify-content-center vh-100">
        <div class="col-md-6">
            <div class="col-10 mx-auto card p-3">
                <h3 class="text-dark my-0 mb-3"><?php echo e(trans('lang.login')); ?></h3>
                <p class="text-50"><?php echo e(trans('lang.sign_in_to_continue')); ?></p>
                <form class="mt-3 mb-4" action="#" onsubmit="return loginClick()" id="login-box">
                    <div class="form-group">
                        <label for="email" class="text-dark"><?php echo e(trans('lang.user_email')); ?></label>
                        <input type="email" placeholder="<?php echo e(trans('lang.user_email_help_2')); ?>" class="form-control"
                               id="email" aria-describedby="emailHelp" name="email">
                        <div id="emil_required"></div>
                        <div class="error email_error"></div>
                        <?php $__errorArgs = ['email'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                            <span class="invalid-feedback" role="alert">
                                <strong><?php echo e($message); ?></strong>
                            </span>
                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                    </div>
                    <div class="form-group">
                        <label for="password" class="text-dark"><?php echo e(trans('lang.password')); ?></label>
                        <input type="password" placeholder="<?php echo e(trans('lang.user_password_help_2')); ?>" class="form-control"
                               id="password" name="password">
                        <div class="error" id="password_required"></div>
                        <div class="error password_error"></div>
                        <?php $__errorArgs = ['password'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                            <span class="invalid-feedback" role="alert">
                                <strong><?php echo e($message); ?></strong>
                            </span>
                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                    </div>
                    <div class="forgot-password">
                        <p><a href="<?php echo e(url('forgot-password')); ?>" class="standard-link"
                              target="_blank"><?php echo e(trans('lang.forgot_password')); ?>?</a></p>
                    </div>
                    <div class="error" id="password_required_new"></div>
                    <button type="submit" class="btn btn-primary btn-lg btn-block" onclick="loginClick()" id="login_btn"><?php echo e(trans('lang.log_in')); ?></button>
                    <a href="<?php echo e(route('signup')); ?>" class="btn btn-primary btn-lg btn-block"><?php echo e(trans('lang.sign_up')); ?></a>
                    <button type="button" onclick="googleAuth()" class="btn btn-dark btn-lg btn-block text-uppercase waves-effect waves-light btn btn-primary">
                        <i class="fa fa-google"> </i> <?php echo e(trans('lang.continue_with_google')); ?>

                    </button>
                    <div class="or-line mb-3 mt-3"><span><?php echo e(trans('lang.or')); ?></span></div>
                    <button type="button" onclick="loginWithPhoneClick()" id="loginphon_btn"
                            class="btn btn-dark btn-lg btn-block text-uppercase waves-effect waves-light btn btn-primary">
                        <i class="fa fa-phone mr-2"> </i> <?php echo e(trans('lang.login')); ?> <?php echo e(trans('lang.with_phone')); ?></button>
                </form>
                <form class="form-horizontal form-material" name="loginwithphon" id="login-with-phone-box" action="#"
                      style="display:none;">
                    <?php echo csrf_field(); ?>
                    <div class="box-title m-b-20"><?php echo e(trans('lang.login')); ?></div>
                    <div class="form-group " id="phone-box">
                        <div class="col-xs-12 country_size phone-box position-relative">
                            <select name="country" id="country_selector">
                                <?php foreach ($newcountries as $keycy => $valuecy) { ?>
                                    <?php $selected = ""; ?>
                                <option <?php echo $selected; ?> code="<?php echo $valuecy->code; ?>"
                                        value="<?php echo $keycy; ?>">
                                    +<?php echo $valuecy->phoneCode; ?><?php echo $valuecy->countryName; ?></option>
                                <?php } ?>
                            </select>
                            <input class="form-control" placeholder="<?php echo e(trans('lang.user_phone')); ?>" id="phone"
                                   type="phone" class="form-control" name="phone" value="<?php echo e(old('phone')); ?>" required
                                   autocomplete="phone" autofocus></div>
                        <?php $__errorArgs = ['phone'];
$__bag = $errors->getBag($__errorArgs[1] ?? 'default');
if ($__bag->has($__errorArgs[0])) :
if (isset($message)) { $__messageOriginal = $message; }
$message = $__bag->first($__errorArgs[0]); ?>
                        <span class="invalid-feedback" role="alert">
                          <strong><?php echo e($message); ?></strong>
                      </span>
                        <?php unset($message);
if (isset($__messageOriginal)) { $message = $__messageOriginal; }
endif;
unset($__errorArgs, $__bag); ?>
                    </div>
                    <div class="form-group " id="otp-box" style="display:none;">
                        <input class="form-control" placeholder="<?php echo e(trans('lang.otp')); ?>" id="verificationcode"
                               type="text" class="form-control" name="otp" value="<?php echo e(old('otp')); ?>" required
                               autocomplete="otp" autofocus>
                    </div>
                    <div id="recaptcha-container" style="display:none;"></div>
                    <div class="error" id="password_required_new1"></div>
                    <div class="form-group text-center m-t-20">
                        <div class="col-xs-12">
                            <button type="button" style="display:none;" onclick="applicationVerifier()" id="verify_btn"
                                    class="btn btn-dark btn-lg btn-block text-uppercase waves-effect waves-light btn btn-primary"><?php echo e(trans('lang.otp_verify')); ?></button>
                            <button type="button" style="display:none;" onclick="sendOTP()" id="sendotp_btn"
                                    class="btn btn-dark btn-lg btn-block text-uppercase waves-effect waves-light btn btn-primary"><?php echo e(trans('lang.otp_send')); ?></button>
                            <button type="button" onclick="loginBackClick()"
                                    class="btn btn-dark btn-lg btn-block text-uppercase waves-effect waves-light btn btn-primary"><?php echo e(trans('lang.login')); ?> <?php echo e(trans('lang.with_email')); ?></button>
                        </div>
                    </div>
                </form>
            </div>
        </div>
    </div>
</div>
</div>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script src="<?php echo e(asset('vendor/select2/dist/js/select2.min.js')); ?>"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-firestore-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-storage-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.23.0/firebase-database-compat.js"></script>
<script src="<?php echo e(asset('js/crypto-js.js')); ?>"></script>
<script src="<?php echo e(asset('js/jquery.cookie.js')); ?>"></script>
<script src="<?php echo e(asset('js/jquery.validate.js')); ?>"></script>
<script type="text/javascript">
    var database = firebase.firestore();

    function loginClick() {
          var email = $("#email").val();
        var password = $("#password").val();
        $("#email_required").css('display', 'none');
        $("#password_required").html("");
        if (email == '') {
            $("#email_required").css('display','block');
            jQuery("#email_required").html("<?php echo e(trans('lang.please_enter_email_id')); ?>").css("color", "red");
            return false;    
        }
        else if (password == '') {
            $("#email_required").css('display','none');
            jQuery("#password_required").html("<?php echo e(trans('lang.please_enter_valid_password')); ?>").css("color", "red");
            return false;
        }
                $("#email_required").css('display', 'none');

        firebase.auth().signInWithEmailAndPassword(email, password).then(function (result) {
            var userEmail = result.user.email;
            database.collection("users").where("email", "==", userEmail).get().then(async function (snapshots) {
                var userData = snapshots.docs[0].data();
                if (userData.role == "customer" && userData.active == true) {
                    var userToken = result.user.getIdToken();
                    var uid = result.user.uid;
                    var user = userData.id;
                    var firstName = userData.firstName;
                    var lastName = userData.lastName;
                    var imageURL = userData.profilePictureURL;
                    var url = "<?php echo e(route('setToken')); ?>";
                    $.ajax({
                        type: 'POST',
                        url: url,
                        data: {
                            id: uid,
                            userId: user,
                            email: email,
                            password: password,
                            firstName: firstName,
                            lastName: lastName,
                            profilePicture: imageURL
                        },
                        headers: {
                            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                        },
                        success: function (data) {
                            if (data.access) {
                                window.location = "<?php echo e(url('/')); ?>";
                            }
                        }
                    });
                } else {
                    $("#password_required_new").html("<p><?php echo e(trans('lang.your_account_has_been_disabled_please_contact_to_admin')); ?></p>");
                }
            })
        })
        .catch(function (error) {
                //$(".password_error").html('<p class="error">' + error.message + '</p>').show();
                //  $("#password_required").html(error.message);
                $("#password_required").html("<?php echo e(trans('lang.the_entered_password_is_invalid_please_check_and_try_again')); ?>").css("color", "red");
        });
        return false;
    }

    function loginWithPhoneClick() {
        jQuery("#login-box").hide();
        jQuery("#login-with-phone-box").show();
        jQuery("#phone-box").show();
        jQuery("#recaptcha-container").show();
        jQuery("#sendotp_btn").show();
        window.recaptchaVerifier = new firebase.auth.RecaptchaVerifier('recaptcha-container', {
            'size': 'invisible',
            'callback': (response) => {
            }
        });
    }

    function loginBackClick() {
        jQuery("#login-box").show();
        jQuery("#login-with-phone-box").hide();
        jQuery("#sendotp_btn").hide();
    }

    function sendOTP() {
        jQuery("#password_required_new1").html("");
        if (jQuery("#phone").val() && jQuery("#country_selector").val()) {
            var phoneNumber = '+' + jQuery("#country_selector").val() + '' + jQuery("#phone").val();
            database.collection("users").where("phoneNumber", "==", jQuery("#phone").val()).where("role", "==", 'customer').get().then(async function (snapshots) {
                if (snapshots.docs.length) {
                    var userData = snapshots.docs[0].data();
                    if (userData.active == true) {
                        firebase.auth().signInWithPhoneNumber(phoneNumber, window.recaptchaVerifier)
                            .then(function (confirmationResult) {
                                window.confirmationResult = confirmationResult;
                                if (confirmationResult.verificationId) {
                                    jQuery("#phone-box").hide();
                                    jQuery("#recaptcha-container").hide();
                                    jQuery("#otp-box").show();
                                    jQuery("#verify_btn").show();
                                }
                            });
                    } else {
                        $("#password_required_new1").html("<?php echo e(trans('lang.your_account_has_been_disabled_please_contact_to_admin')); ?>");
                    }
                } else {
                    jQuery("#password_required_new1").html("<?php echo e(trans('lang.user_not_found')); ?>");
                }
            });
        }
    }

    function applicationVerifier() {
        window.confirmationResult.confirm(document.getElementById("verificationcode").value)
            .then(function (result) {
                database.collection("users").where('phoneNumber', '==', jQuery("#phone").val()).where("role", "==", 'customer').get().then(async function (snapshots_login) {
                    userData = snapshots_login.docs[0].data();
                    if (userData) {
                        if (userData.role == "customer") {
                            var uid = result.user.uid;
                            var user = result.user.uid;
                            var firstName = userData.firstName;
                            var lastName = userData.lastName;
                            var imageURL = userData.profilePictureURL;
                            var url = "<?php echo e(route('setToken')); ?>";
                            $.ajax({
                                type: 'POST',
                                url: url,
                                data: {
                                    id: uid,
                                    userId: user,
                                    email: userData.phoneNumber,
                                    password: '',
                                    firstName: firstName,
                                    lastName: lastName,
                                    profilePicture: imageURL
                                },
                                headers: {
                                    'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                                },
                                success: function (data) {
                                    if (data.access) {
                                        window.location = "<?php echo e(url('/')); ?>";
                                    }
                                }
                            });
                        } else {
                            jQuery("#password_required_new").html("<?php echo e(trans('lang.user_not_found')); ?>");
                        }
                    }
                })
            }).catch(function (error) {
            jQuery("#password_required_new1").html(error.message);
        });
    }

    var newcountriesjs = '<?php echo json_encode($newcountriesjs); ?>';
    var newcountriesjs = JSON.parse(newcountriesjs);

    function formatState(state) {
        if (!state.id) {
            return state.text;
        }
        var baseUrl = "<?php echo URL::to('/'); ?>/flags/120/";
        var $state = $(
            '<span><img src="' + baseUrl + '/' + newcountriesjs[state.element.value].toLowerCase() + '.png" class="img-flag" /> ' + state.text + '</span>'
        );
        return $state;
    }

    function formatState2(state) {
        if (!state.id) {
            return state.text;
        }
        var baseUrl = "<?php echo URL::to('/'); ?>/flags/120/"
        var $state = $(
            '<span><img class="img-flag" /> <span></span></span>'
        );
        $state.find("span").text(state.text);
        $state.find("img").attr("src", baseUrl + "/" + newcountriesjs[state.element.value].toLowerCase() + ".png");
        return $state;
    }

    jQuery(document).ready(function () {

        jQuery("#country_selector").select2({
            templateResult: formatState,
            templateSelection: formatState2,
            placeholder: "Select Country",
            allowClear: true
        });
        
        // --- ADD THIS BLOCK TO SET DEFAULT COUNTRY CODE ---
        var globalSettingsRef = database.collection('settings').doc('globalSettings');
        globalSettingsRef.get().then(async function (snapshot) {
            var globalSettings = snapshot.data();
            if (globalSettings && globalSettings.defaultCountryCode) {
                var defaultPhoneCode = globalSettings.defaultCountryCode.replace('+', '').trim();

                // Find the option with matching phoneCode
                var $option = $("#country_selector option").filter(function() {
                    return $(this).val() === defaultPhoneCode;
                });

                if ($option.length > 0) {
                    $("#country_selector").val(defaultPhoneCode).trigger('change');
                } else {
                    console.warn("Default country code not found in list:", defaultPhoneCode);
                }
            }
        }).catch(function (error) {
            console.error("Error fetching global settings: ", error);
        });
        // --- END OF DEFAULT COUNTRY LOGIC ---
    });
    function googleAuth() {
        var provider=new firebase.auth.GoogleAuthProvider();
        firebase.auth().signInWithPopup(provider)
            .then(function(result) {
                var user=result.user;
                saveUserData(user);
            }).catch(function(error) {
                console.error("Google Sign-In Error:",error.message);

            });
    }

    function saveUserData(user) {
        jQuery('#data-table_processing').show();
        database.collection("users").doc(user.uid).get().then(async function(snapshots_login) {
            var userData=snapshots_login.data();
            if(userData) {
                if(userData.role=="customer"&&userData.active) {
                    var uid = userData.id;
                    var firstName = userData.firstName || '';
                    var lastName = userData.lastName || '';
                    var email = userData.email || '';
                    var imageURL = '';
                    $.ajax({
                        type: 'POST',
                        url: "<?php echo e(route('setToken')); ?>",
                        data: {
                            id: uid,
                            userId: uid,
                            email: email,
                            password: '',
                            firstName: firstName,
                            lastName: lastName,
                            profilePicture: imageURL,
                            provider: "google",
                        },
                        headers: {
                            'X-CSRF-TOKEN': $('meta[name="csrf-token"]').attr('content')
                        },
                        success: function(data) {
                            if(data.access) {
                                jQuery('#data-table_processing').hide();
                                window.location = "<?php echo e(url('/')); ?>";
                            } else {
                                jQuery('#data-table_processing').hide();
                                $(".email_error").hide();
                                $(".password_error").show();
                                $(".password_error").html("");
                                window.scrollTo(0,0);
                                $(".password_error").append( "<p><?php echo e(trans('lang.set_token_error')); ?></p>");
                            }
                        },
                        error: function() {
                            jQuery('#data-table_processing').hide();
                            $(".email_error").hide();
                            $(".password_error").show();
                            $(".password_error").html("");
                            window.scrollTo(0,0);
                            $(".password_error").append(
                                "<p><?php echo e(trans('lang.set_token_error')); ?></p>");
                        }
                    });
                } else {
                    jQuery('#data-table_processing').hide();
                    $(".email_error").hide();
                    $(".password_error").show();
                    $(".password_error").html("");
                    window.scrollTo(0,0);
                    $(".password_error").append("<p class='error'>User is not active or not found</p>");
                }

            } else {
                var loginType='google';
                var phoneNumber=user.phoneNumber||'';
                var firstName=user.displayName? user.displayName.split(' ')[0]:'';
                var lastName=user.displayName? user.displayName.split(' ')[1]:'';
                var uuid=user.uid;
                var email=user.email||'';
                var photoURL=user.photoURL||'';
                var createdAtman=firebase.firestore.Timestamp.fromDate(new Date());
                var redirectUrl=
                    `<?php echo e(url('signup')); ?>?uuid=${encodeURIComponent(uuid)}&loginType=${encodeURIComponent(loginType)}&phoneNumber=${encodeURIComponent(phoneNumber)}&firstName=${encodeURIComponent(firstName)}&lastName=${encodeURIComponent(lastName)}&email=${encodeURIComponent(email)}&photoURL=${encodeURIComponent(photoURL)}&createdAt=${createdAtman.toDate()}`;
                jQuery('#data-table_processing').hide();
                window.location.href=redirectUrl;
            }

        }).catch(function(error) {
            console.log(error);
            jQuery('#data-table_processing').hide();
            $(".email_error").hide();
            $(".password_error").show();
            $(".password_error").html("");
            window.scrollTo(0,0);
            $(".password_error").append("<p>"+error.message+"</p>");

        });
    }

</script>
<?php /**PATH /home/u844577645/domains/joxmako.com/public_html/resources/views/auth/loginuser.blade.php ENDPATH**/ ?>