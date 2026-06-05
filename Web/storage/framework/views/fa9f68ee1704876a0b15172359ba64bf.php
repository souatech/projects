<?php echo $__env->make('layouts.app', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
<div class="home" id="home"></div>
<script type="text/javascript">
    var is_layer = 1;
</script>
<?php echo $__env->make('layouts.footer', \Illuminate\Support\Arr::except(get_defined_vars(), ['__data', '__path']))->render(); ?>
<script type="text/javascript">
    jQuery("#overlay").show();
    var placeholderImageRef = database.collection('settings').doc('placeHolderImage');
    var placeholderImageSrc = '';
    placeholderImageRef.get().then(async function (placeholderImageSnapshots) {
        var placeHolderImageData = placeholderImageSnapshots.data();
        placeholderImageSrc = placeHolderImageData.image;
    })
    var globalSettingsRef = database.collection('settings').doc('globalSettings');
    var homepageTemplateRef = database.collection('settings').doc('homepageTemplate');
    var localHeroSrc        = "<?php echo e(asset('img/joxmako_hero_img.png')); ?>";
    var localHeroFallback   = "<?php echo e(asset('img/hero_banner.png')); ?>";
    var localAllVendorSrc      = "<?php echo e(asset('img/all_vendor.png')); ?>";
    var localAllVendorFallback = "<?php echo e(asset('img/hero_banner.png')); ?>";

    homepageTemplateRef.get().then(async function (homepageTemplateSnapshots) {
        var homepageTemplateData = homepageTemplateSnapshots.data();

        // Remplace les images Firebase par les assets locaux avant injection DOM
        var pageTemplate = homepageTemplateData.homepageTemplate
            .replace(/https?:\/\/[^"']*\/hero_img\.png/g,   localHeroSrc)
            .replace(/https?:\/\/[^"']*\/all_vendor\.png/g, localAllVendorSrc);
        $('#home').html(pageTemplate);

        // Attributs propres sur l'image hero
        $('#home .st-home-banner-right img').addClass('img-fluid').attr({
            alt: 'JOXMAKO',
            onerror: 'this.onerror=null;this.src="' + localHeroFallback + '"'
        });

        // Attributs propres sur l'image all_vendor
        $('#home img[src="' + localAllVendorSrc + '"]').addClass('img-fluid').attr({
            alt: 'JOXMAKO',
            onerror: 'this.onerror=null;this.src="' + localAllVendorFallback + '"'
        });
        await globalSettingsRef.get().then(async function (globalSettingsSnapshots) {
            var globalSettingsData = globalSettingsSnapshots.data();
            var src_new = globalSettingsData.appLogo;
            $('#logo_web').html('<img alt="#" class="logo_web img-fluid" src="' + src_new + '">');
            $('.location-group .locate-me').attr("onclick", "getCurrentLocation()");
        });
        getSections();
        jQuery("#overlay").hide();
    });
    $(document).ready(function () {
        $(document).on("click", ".cat-slider .cat-item", function (e) {
            $(this).addClass('section-selected').siblings().removeClass('section-selected');
        });
        $(document).on("click", ".btn-continue", function (e) {
            var element = $('.cat-slider .cat-item.section-selected');
            var section_id = element.attr('data-id');
            if ($('#user_locationnew').val() == '') {
                alert('Please select your address');
                return false;
            }
            if (!section_id) {
                alert('Please select your section');
                return false;
            }
            var section_name = element.attr('data-name');
            var section_color = element.attr('data-color');
            var dine_in_active = element.attr('data-dine_in');
            var service_type = element.attr('service_type');
            if (dine_in_active != 'true') {
                dine_in_active = 'false';
            }
            setCookie('section_id', section_id, 365);
            setCookie('section_name', section_name, 365);
            setCookie('section_color', section_color, 365);
            setCookie('dine_in_active', dine_in_active.toString(), 365);
            setCookie('service_type', service_type, 365);
            window.location.href = "<?php echo url('/'); ?>";
        });
    });

    async function getSections() {
        database.collection('sections').where('isActive', '==', true).orderBy('order').get().then(async function (sectionsSnapshot) {
            sections = document.getElementById('sections');
            sections.innerHTML = '';
            sectionshtml = buildHTMLSections(sectionsSnapshot);
            sections.innerHTML = sectionshtml;
            slickcatCarousel();
        })
    }

    function buildHTMLSections(sectionsSnapshot) {
        var html = '';
        var alldata = [];
        sectionsSnapshot.docs.forEach((listval) => {
            var datas = listval.data();
            datas.id = listval.id;
            alldata.push(datas);
        });
        alldata.forEach((listval) => {
            var val = listval;
            var category_id = val.id;
            var trending_route = "<?php echo e(route('category_detail',':id')); ?>";
            trending_route = trending_route.replace(':id', category_id);
            if (val.sectionImage) {
                photo = val.sectionImage;
            } else {
                photo = placeholderImageSrc;
            }
                html = html + '<div class="cat-item px-2 py-1" data-color="' + val.color + '" service_type="' + val.serviceType + '" data-name="' + val.name + '" data-dine_in="' + val.dine_in_active + '" data-id="' + val.id + '"><a class="bg-white d-block p-2 text-center shadow-sm cat-link" href="javascript:void(0)"><img alt="#" src="' + photo + '" onerror="this.onerror=null;this.src=\'' + placeholderImageSrc + '\'" class="img-fluid mb-2"><p class="m-0 small">' + val.name + '</p></a></div>';
        });
        return html;
    }

    function slickcatCarousel() {
        $('.cat-slider').slick({
            slidesToShow: 4,
            arrows: true,
            responsive: [{
                breakpoint: 1199,
                settings: {
                    arrows: true,
                    centerMode: true,
                    centerPadding: '40px',
                    slidesToShow: 4
                }
            }, {
                breakpoint: 992,
                settings: {
                    arrows: true,
                    centerMode: true,
                    centerPadding: '40px',
                    slidesToShow: 3
                }
            }, {
                breakpoint: 768,
                settings: {
                    arrows: true,
                    centerMode: true,
                    centerPadding: '40px',
                    slidesToShow: 2
                }
            },
                {
                    breakpoint: 560,
                    settings: {
                        arrows: false,
                        centerMode: true,
                        centerPadding: '20px',
                        slidesToShow: 2
                    }
                }
            ]
        });
    }

   
</script><?php /**PATH /home/u844577645/domains/joxmako.com/public_html/resources/views/layer.blade.php ENDPATH**/ ?>