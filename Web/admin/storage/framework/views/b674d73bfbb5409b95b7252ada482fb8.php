<?php $__env->startSection('content'); ?>

<div class="page-wrapper">
    <div class="row page-titles">
        <div class="col-md-5 align-self-center">
            <h3 class="text-themecolor"><?php echo e(trans('lang.admin_plural')); ?></h3>
        </div>
        <div class="col-md-7 align-self-center">
            <ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="<?php echo e(route('dashboard')); ?>"><?php echo e(trans('lang.dashboard')); ?></a></li>
                <li class="breadcrumb-item active"><?php echo e(trans('lang.admin_table')); ?></li>
            </ol>
        </div>
        <div>
        </div>
    </div>
    <div class="container-fluid">
       
       <div class="admin-top-section"> 
        <div class="row">
            <div class="col-12">
                <div class="d-flex top-title-section pb-4 justify-content-between">
                    <div class="d-flex top-title-left align-self-center">
                        <span class="icon mr-3"><img src="<?php echo e(asset('images/admin.png')); ?>"></span>
                        <h3 class="mb-0"><?php echo e(trans('lang.admin_plural')); ?></h3>
                        <span class="counter ml-3 total_count"><?php echo e($users->count()); ?></span>
                    </div>                    
                </div>
            </div>
        </div> 
    
       </div>
       <div class="table-list">
       <div class="row">
           <div class="col-12">
               <div class="card border">
                 <div class="card-header d-flex justify-content-between align-items-center border-0">
                   <div class="card-header-title">
                    <h3 class="text-dark-2 mb-2 h4"><?php echo e(trans('lang.admin_table')); ?></h3>
                    <p class="mb-0 text-dark-2"><?php echo e(trans('lang.admin_table_text')); ?></p>
                   </div>
                   <div class="card-header-right d-flex align-items-center">
                    <div class="card-header-btn mr-3">                     
                        <a class="btn-primary btn rounded-full" href="<?php echo route('admin.users.create'); ?>"><i class="mdi mdi-plus mr-2"></i><?php echo e(trans('lang.create_admin')); ?></a>
                     </div>
                   </div>                
                 </div>
                 <div class="card-body">
                         <div class="table-responsive m-t-10">
                            <table id="adminTable"
                                   class="display nowrap table table-hover table-striped table-bordered table table-striped"
                                   cellspacing="0" width="100%">
                                <thead>
                                <tr>
                                    <?php if (in_array('admin.users.delete', json_decode(@session('user_permissions'),true))) { ?>
                                    <th class="delete-all"><input type="checkbox" id="is_active"><label class="col-3 control-label" for="is_active"><a id="deleteAll"
                                    class="do_not_delete" href="javascript:void(0)"><i class="mdi mdi-delete"></i> <?php echo e(trans('lang.all')); ?></a></label></th>
                                    <?php } ?>
                                    <th><?php echo e(trans('lang.name')); ?></th>
                                    <th><?php echo e(trans('lang.email')); ?></th>
                                    <th><?php echo e(trans('lang.role')); ?></th>
                                    <th><?php echo e(trans('lang.actions')); ?></th>
                                </tr>
                                </thead>  
                                <tbody id="append_list1">
                                    <?php $__currentLoopData = $users; $__env->addLoop($__currentLoopData); foreach($__currentLoopData as $user): $__env->incrementLoopIndices(); $loop = $__env->getLastLoop(); ?>
                                    <tr>
                                        <?php if (in_array('admin.users.delete', json_decode(@session('user_permissions'),true))) { ?>

                                            <td class="delete-all"><input type="checkbox" id="is_open_<?php echo e($user->id); ?>"
                                                    class="is_open" dataid="<?php echo e($user->id); ?>"><label
                                                    class="col-3 control-label" for="is_open_<?php echo e($user->id); ?>"></label>
                                            </td>
                                        <?php } ?>
                                        <td>
                                            <a href="<?php echo e(route('admin.users.edit', ['id' => $user->id])); ?>"><?php echo e($user->name); ?></a>
                                        </td>

                                        <td>
                                            <?php echo e($user->email); ?>

                                        </td>

                                        <td>
                                            <?php echo e($user->roleName); ?>

                                        </td>

                                        <td><span class="action-btn">
                                            <a href="<?php echo e(route('admin.users.edit', ['id' => $user->id])); ?>" data-toggle="tooltip" data-bs-original-title="<?php echo e(trans('lang.edit')); ?>"><i
                                                    class="mdi mdi-lead-pencil"></i></a>
                                            <?php if($user->id != 1): ?>
                                            <?php if(in_array('role.delete', json_decode(@session('user_permissions'),true))): ?>

                                            <a href="<?php echo e(route('admin.users.delete', ['id' => $user->id])); ?>" class="delete-btn" data-toggle="tooltip" data-bs-original-title="<?php echo e(trans('lang.delete')); ?>"><i
                                                    class="mdi mdi-delete"></i></a>
                                            <?php endif; ?>
                                            <?php endif; ?>
                                        </span></td>
                                    </tr>
                                    <?php endforeach; $__env->popLoop(); $loop = $__env->getLastLoop(); ?>
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



<?php $__env->stopSection(); ?>

<?php $__env->startSection('scripts'); ?>

<script type="text/javascript">
    var user_permissions = '<?php echo @session('user_permissions') ?>';

    user_permissions = Object.values(JSON.parse(user_permissions));

    var checkDeletePermission = false;

    if ($.inArray('admin.users.delete', user_permissions) >= 0) {
            checkDeletePermission = true;
    }
   
    const table = $('#adminTable').DataTable({
        order: [],
        columnDefs: [
            { orderable: false, targets: (checkDeletePermission==true) ? [0, 4] : [3] },

        ],
        "language": datatableLang,
        responsive: true
    });
    table.on('search.dt', function() {
        var filteredCount = table.rows({ search: 'applied' }).count();
        $('.total_count').text(filteredCount);  // Update count
    });

    $("#is_active").click(function () {
        $("#adminTable .is_open").prop('checked', $(this).prop('checked'));

    });

    $("#deleteAll").click(function () {
        if ($('#adminTable .is_open:checked').length) {
            if (confirm('<?php echo e(trans('lang.are_you_sure_want_to_delete_selected_data')); ?>')) {
                var arrayUsers = [];
                $('#adminTable .is_open:checked').each(function () {
                    var dataId = $(this).attr('dataId');
                    arrayUsers.push(dataId);

                });

                arrayUsers = JSON.stringify(arrayUsers);
                var url = "<?php echo e(url('admin-users/delete', 'id')); ?>";
                url = url.replace('id', arrayUsers);

                $(this).attr('href', url);
            }
        } else {
            alert('<?php echo e(trans('lang.please_select_any_one_record')); ?>');
        }
    });

</script>


<?php $__env->stopSection(); ?>
<?php echo $__env->make('layouts.app', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?><?php /**PATH /home/u844577645/domains/joxmako.com/public_html/admin/resources/views/admin_users/index.blade.php ENDPATH**/ ?>