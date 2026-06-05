<?php $__env->startSection('content'); ?>

<div class="page-wrapper">

    <div class="row page-titles">

        <div class="col-md-5 align-self-center">

            <h3 class="text-themecolor"><?php echo e(trans('lang.edit_car_model')); ?></h3>

        </div>



        <div class="col-md-7 align-self-center">

            <ol class="breadcrumb">

                <li class="breadcrumb-item"><a href="<?php echo e(route('dashboard')); ?>"><?php echo e(trans('lang.dashboard')); ?></a></li>

                <li class="breadcrumb-item"><a href="<?php echo route('carModel'); ?>"><?php echo e(trans('lang.car_model')); ?></a>

                </li>

                <li class="breadcrumb-item active"><?php echo e(trans('lang.edit_car_model')); ?></li>

            </ol>

        </div>



        <div class="card-body">

            <div class="error_top"></div>



            <div class="row vendor_payout_create">

                <div class="vendor_payout_create-inner">

                    <fieldset>

                        <legend><?php echo e(trans('lang.car_model')); ?></legend>



                        <div class="form-group row width-50">

                            <label class="col-3 control-label"><?php echo e(trans('lang.car_make')); ?></label>

                            <div class="col-7 select2-container-full">

                                <select name="car_make" class="form-control car_make">

                                    <option value=""><?php echo e(trans('lang.select')); ?></option>

                                </select>

                            </div>

                        </div>

                        <div class="form-group row width-50">

                            <label class="col-3 control-label"><?php echo e(trans('lang.name')); ?></label>

                            <div class="col-7">

                                <input type="text" class="form-control title" id="title">

                            </div>

                        </div>



                        <div class="form-group row width-100">

                            <div class="form-check">

                                <input type="checkbox" class="car_model_active" id="car_model_active">

                                <label class="col-3 control-label"

                                       for="car_model_active"><?php echo e(trans('lang.active')); ?></label>



                            </div>





                        </div>



                    </fieldset>

                </div>

            </div>

        </div>



        <div class="form-group col-12 text-center btm-btn">

            <button type="button" class="btn btn-primary  edit-setting-btn"><i class="fa fa-save"></i> <?php echo e(trans('lang.save')); ?>


            </button>

            <a href="<?php echo url('carModel'); ?>" class="btn btn-default"><i class="fa fa-undo"></i><?php echo e(trans('lang.cancel')); ?></a>

        </div>



    </div>



</div>



<?php $__env->stopSection(); ?>



<?php $__env->startSection('scripts'); ?>



<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet"/>

<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>



<script type="text/javascript">



var database = firebase.firestore();

var ref = database.collection('car_make');

var id = "<?php  echo $id; ?>";

var refCarModel = database.collection('car_model').where('id', '==', id);



ref.get().then(async function (snapshots) {

    snapshots.docs.forEach((listval) => {

        var data = listval.data();



        $('.car_make').append($("<option></option>")

            .attr("value", data.id)

            .text(data.name));

    })

    $('.car_make').select2();

});



$(document).ready(function () {

    refCarModel.get().then(async function (snapshots) {

        snapshots.docs.forEach((listval) => {

            var data = listval.data();



            $('.car_make').val(data.car_make_id).trigger('change');

            $('.title').val(data.name);

            if (data.isActive == true) {

                $(".car_model_active").prop('checked', true);

            }



        })

    })

});



$(".edit-setting-btn").click(function () {



    var title = $("#title").val();

    var car_make_id = $('.car_make').val();

    var car_make_name = $('.car_make option:selected').text();

    var active = $(".car_model_active").is(":checked");



    if (car_make_id == '') {

        $(".error_top").show();

        $(".error_top").html("");

        $(".error_top").append("<p><?php echo e(trans('lang.car_make_error')); ?></p>");

        window.scrollTo(0, 0);



    } else if (title == '') {

        $(".error_top").show();

        $(".error_top").html("");

        $(".error_top").append("<p><?php echo e(trans('lang.name_error')); ?></p>");

        window.scrollTo(0, 0);



    } else {



        jQuery("#data-table_processing").show();

        database.collection('car_model').doc(id).update({

            'id': id,

            'name': title,

            'car_make_id': car_make_id,

            'car_make_name': car_make_name,

            'isActive': active

        }).then(function (result) {

            jQuery("#data-table_processing").hide();

            window.location.href = '<?php echo e(route("carModel")); ?>';

        });

    }



})

</script>

<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /home/u844577645/domains/joxmako.com/public_html/admin/resources/views/carModel/edit.blade.php ENDPATH**/ ?>