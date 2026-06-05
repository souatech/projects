<?php $__env->startSection('content'); ?>

    <div class="page-wrapper">

         

        <div class="row page-titles">

            <div class="col-md-5 align-self-center">

                <h3 class="text-themecolor"><?php echo e(trans('lang.edit_car_make')); ?></h3>

            </div>



            <div class="col-md-7 align-self-center">

                <ol class="breadcrumb">

                    <li class="breadcrumb-item"><a href="<?php echo e(route('dashboard')); ?>"><?php echo e(trans('lang.dashboard')); ?></a></li>

                    <li class="breadcrumb-item"><a

                                href="<?php echo route('carMake'); ?>"><?php echo e(trans('lang.car_make')); ?></a></li>

                    <li class="breadcrumb-item active"><?php echo e(trans('lang.edit_car_make')); ?></li>

                </ol>

            </div>



            <div class="card-body">

                <div class="error_top"></div>



                <div class="row vendor_payout_create">

                    <div class="vendor_payout_create-inner">

                        <fieldset>

                            <legend><?php echo e(trans('lang.car_make')); ?></legend>



                            <div class="form-group row width-100">

                                <label class="col-3 control-label"><?php echo e(trans('lang.name')); ?></label>

                                <div class="col-7">

                                    <input type="text" class="form-control title" id="title">

                                </div>

                            </div>



                            <div class="form-group row width-100">

                                <div class="form-check">

                                    <input type="checkbox" class="car_make_active" id="car_make_active">

                                    <label class="col-3 control-label"

                                           for="car_make_active"><?php echo e(trans('lang.active')); ?></label>



                                </div>





                            </div>



                        </fieldset>

                    </div>

                </div>

            </div>



            <div class="form-group col-12 text-center btm-btn">

                <button type="button" class="btn btn-primary  edit-setting-btn"><i

                            class="fa fa-save"></i> <?php echo e(trans('lang.save')); ?></button>

                <a href="<?php echo url('carMake'); ?>" class="btn btn-default"><i

                            class="fa fa-undo"></i><?php echo e(trans('lang.cancel')); ?></a>

            </div>



        </div>



    </div>



<?php $__env->stopSection(); ?>



<?php $__env->startSection('scripts'); ?>



<script type="text/javascript">



var database = firebase.firestore();

var id = "<?php echo $id; ?>";

var ref = database.collection('car_make').where('id', '==', id);





$(document).ready(function () {

    jQuery("#data-table_processing").show();

    ref.get().then(async function (snapshots) {

        var carMake = snapshots.docs[0].data();



        $('.title').val(carMake.name);

        if (carMake.isActive == true) {

            $(".car_make_active").prop('checked', true);

        }



        jQuery("#data-table_processing").hide();

    });

});

$(".edit-setting-btn").click(function () {



    var title = $("#title").val();

    var active = $(".car_make_active").is(":checked");





    if (title == '') {

        $(".error_top").show();

        $(".error_top").html("");

        $(".error_top").append("<p><?php echo e(trans('lang.name_error')); ?></p>");

        window.scrollTo(0, 0);



    } else {



        jQuery("#data-table_processing").show();

        database.collection('car_make').doc(id).update({

            'id': id,

            'name': title,

            'isActive': active

        }).then(function (result) {

            jQuery("#data-table_processing").hide();

            window.location.href = '<?php echo e(route("carMake")); ?>';

        });

    }



})



</script>



<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /home/u844577645/domains/joxmako.com/public_html/admin/resources/views/carMake/edit.blade.php ENDPATH**/ ?>