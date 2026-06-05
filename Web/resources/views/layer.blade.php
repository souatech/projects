@include('layouts.app')

<div class="jox-web-home" id="home">
    <header class="jox-web-nav">
        <a class="jox-brand" href="{{ url('/') }}" aria-label="JOXMAKO">
            <img id="joxLogo" src="{{ asset('img/logo_web.png') }}" alt="JOXMAKO">
        </a>
        <button class="jox-location-pill" type="button" onclick="document.getElementById('user_locationnew').focus();">
            <i class="feather-map-pin"></i>
            <span class="jox-current-location">Choisir une adresse</span>
            <i class="feather-chevron-down"></i>
        </button>
        <nav class="jox-nav-links" aria-label="Navigation principale">
            <a href="#jox-services">Services</a>
            <a href="#jox-how">Comment ca marche</a>
            <a href="#jox-partner">A propos</a>
            <a href="{{ route('contact_us') }}">Aide</a>
        </nav>
        <div class="jox-auth-actions">
            <span class="jox-lang"><i class="feather-globe"></i> FR</span>
            @guest
                <a class="jox-login" href="{{ route('login') }}">Se connecter</a>
                <a class="jox-signup" href="{{ route('signup') }}">S'inscrire</a>
            @else
                <a class="jox-login" href="{{ route('profile') }}">Mon compte</a>
            @endguest
        </div>
    </header>

    <main>
        <section class="jox-hero">
            <div class="jox-hero-copy">
                <h1>Tout ce dont vous avez besoin, <span>livre a Dakar.</span></h1>
                <p>Repas, courses, colis et trajets dans une seule application.</p>

                <div class="location-box">
                    <div class="location-group">
                        <i class="feather-map-pin"></i>
                        <input id="user_locationnew" type="text" size="50" class="pac-target-input"
                               placeholder="Ou voulez-vous aller ?">
                        <button type="button" class="locate-me" onclick="getCurrentLocation()">
                            <i class="feather-crosshair"></i>
                            Me localiser
                        </button>
                    </div>
                </div>

                <div id="jox-services" class="cat-slider jox-services"></div>
                <button type="button" class="btn-continue jox-hidden-continue">Continuer</button>
            </div>

            <div class="jox-hero-visual">
                <img class="jox-hero-img" src="{{ asset('img/joxmako-hero-bg.png') }}" alt="JOXMAKO">
                <div class="jox-floating-card jox-payment-card">
                    <strong>Paiement securise</strong>
                    <span>Wave, Orange Money et cartes bancaires</span>
                    <i class="feather-chevron-right"></i>
                </div>
                <div class="jox-floating-card jox-delivery-card">
                    <strong>Livraison express</strong>
                    <span>Suivi en temps reel</span>
                    <i class="feather-truck"></i>
                </div>
                <div class="jox-floating-card jox-support-card">
                    <strong>Support 24/7</strong>
                    <span>Nous sommes la pour vous aider</span>
                    <i class="feather-headphones"></i>
                </div>
            </div>
        </section>

        <section class="jox-content-grid">
            <div class="jox-main-column">
                <section class="jox-section jox-restaurants-section" hidden>
                    <div class="jox-section-head">
                        <h2>Restaurants a la une</h2>
                        <a href="{{ route('vendors') }}">Voir tout <i class="feather-chevron-right"></i></a>
                    </div>
                    <div class="jox-restaurant-row" id="joxRestaurants"></div>
                </section>

                <section class="jox-section jox-activities-section" hidden>
                    <div class="jox-section-head">
                        <h2>Dernieres activites</h2>
                        <a href="{{ route('my_order') }}">Voir tout <i class="feather-chevron-right"></i></a>
                    </div>
                    <div class="jox-activity-row" id="joxActivities"></div>
                </section>
            </div>

            <aside class="jox-side-column">
                <section class="jox-promo-section" hidden>
                    <a class="jox-promo-card" id="joxPromoCard" href="{{ route('offers') }}"></a>
                </section>

                <section class="jox-partner-card" id="jox-partner">
                    <div>
                        <h2>Devenez partenaire</h2>
                        <p>Rejoignez des milliers de partenaires et developpez votre activite.</p>
                        <a href="https://store.joxmako.com">S'inscrire maintenant</a>
                    </div>
                    <img src="{{ asset('img/all_vendor.png') }}" alt="">
                </section>
            </aside>
        </section>

        <section class="jox-benefits" id="jox-how">
            <div><i class="feather-user-check"></i><span>Chauffeurs verifies<br>et de confiance</span></div>
            <div><i class="feather-shield"></i><span>Paiement securise<br>a 100%</span></div>
            <div><i class="feather-headphones"></i><span>Service client<br>disponible 24/7</span></div>
            <div><i class="feather-file-text"></i><span>Prix transparents<br>sans frais caches</span></div>
        </section>
    </main>
</div>

<script type="text/javascript">
    var is_layer = 1;
</script>
@include('layouts.footer')

<style>
    .jox-web-home {
        background: #f8f9fb;
        color: #07080d;
        font-family: Poppins, sans-serif;
        min-height: 100vh;
        overflow-x: hidden;
    }

    .jox-web-home a {
        text-decoration: none;
    }

    .jox-web-nav {
        align-items: center;
        display: grid;
        gap: 28px;
        grid-template-columns: auto auto 1fr auto;
        margin: 0 auto;
        max-width: 1680px;
        padding: 24px 48px 12px;
        position: relative;
        z-index: 5;
    }

    .jox-brand img {
        height: 64px;
        object-fit: contain;
        width: 118px;
    }

    .jox-location-pill {
        align-items: center;
        background: #ffffff;
        border: 1px solid rgba(15, 23, 42, .08);
        border-radius: 18px;
        box-shadow: 0 14px 34px rgba(15, 23, 42, .07);
        color: #07080d;
        display: inline-flex;
        font-weight: 700;
        gap: 10px;
        min-height: 48px;
        padding: 0 18px;
    }

    .jox-location-pill i:first-child {
        color: #ff4b0b;
    }

    .jox-nav-links {
        align-items: center;
        display: flex;
        gap: 52px;
        justify-content: center;
    }

    .jox-nav-links a {
        color: #07080d;
        font-weight: 700;
    }

    .jox-auth-actions {
        align-items: center;
        display: flex;
        gap: 16px;
    }

    .jox-lang {
        align-items: center;
        color: #07080d;
        display: inline-flex;
        font-weight: 700;
        gap: 8px;
        margin-right: 16px;
    }

    .jox-login,
    .jox-signup {
        border-radius: 14px;
        font-weight: 800;
        min-width: 144px;
        padding: 15px 22px;
        text-align: center;
    }

    .jox-login {
        border: 1.5px solid #111827;
        color: #07080d;
    }

    .jox-signup {
        background: #ff4b0b;
        color: #ffffff;
        box-shadow: 0 16px 34px rgba(255, 75, 11, .18);
    }

    .jox-hero {
        display: grid;
        gap: 38px;
        grid-template-columns: minmax(460px, 42%) minmax(0, 1fr);
        margin: 0 auto;
        max-width: 1680px;
        padding: 44px 48px 22px;
    }

    .jox-hero-copy {
        padding-top: 52px;
    }

    .jox-hero-copy h1 {
        color: #07080d;
        font-size: clamp(44px, 4.5vw, 72px);
        font-weight: 900;
        letter-spacing: 0;
        line-height: 1.12;
        margin: 0 0 28px;
    }

    .jox-hero-copy h1 span {
        color: #ff4b0b;
    }

    .jox-hero-copy p {
        color: #4b5563;
        font-size: 22px;
        line-height: 1.75;
        margin: 0 0 34px;
        max-width: 520px;
    }

    .location-box .location-group {
        align-items: center;
        background: #ffffff;
        border: 1.8px solid #ff4b0b;
        border-radius: 18px;
        box-shadow: 0 18px 42px rgba(255, 75, 11, .08);
        display: grid;
        gap: 12px;
        grid-template-columns: auto 1fr auto;
        min-height: 74px;
        overflow: hidden;
        padding: 0 12px 0 24px;
    }

    .location-box .location-group > i {
        color: #1f2937;
        font-size: 23px;
    }

    .location-box .location-group input {
        border: 0 !important;
        box-shadow: none !important;
        color: #111827;
        font-size: 17px;
        font-weight: 500;
        height: 70px;
        outline: 0;
        width: 100%;
    }

    .location-box .location-group .locate-me {
        align-items: center;
        background: #ffffff;
        border: 0;
        border-left: 1px solid rgba(15, 23, 42, .08);
        color: #07080d;
        display: inline-flex;
        font-weight: 800;
        gap: 10px;
        height: 52px;
        justify-content: center;
        min-width: 160px;
    }

    .jox-services {
        display: grid;
        gap: 18px;
        grid-template-columns: repeat(5, minmax(0, 1fr));
        margin-top: 30px;
    }

    .jox-services .cat-item {
        cursor: pointer;
        padding: 0 !important;
    }

    .jox-services .cat-item a.cat-link {
        align-items: center;
        background: #ffffff;
        border: 1px solid rgba(15, 23, 42, .08);
        border-radius: 16px !important;
        box-shadow: 0 16px 34px rgba(15, 23, 42, .07) !important;
        color: #07080d;
        display: flex !important;
        flex-direction: column;
        height: 128px;
        justify-content: center;
        padding: 16px 12px !important;
        transition: transform .18s ease, border-color .18s ease;
    }

    .jox-services .cat-item a.cat-link:hover,
    .jox-services .cat-item.section-selected a.cat-link {
        border-color: rgba(255, 75, 11, .36);
        transform: translateY(-2px);
    }

    .jox-services .cat-item img {
        height: 42px;
        margin-bottom: 12px !important;
        object-fit: contain;
        width: 48px;
    }

    .jox-services .cat-item p {
        color: #07080d;
        font-size: 14px;
        font-weight: 800;
        line-height: 1.2;
        margin: 0;
        text-align: center;
    }

    .jox-hidden-continue {
        height: 1px;
        opacity: 0;
        pointer-events: none;
        position: absolute;
        width: 1px;
    }

    .jox-hero-visual {
        border-radius: 340px 0 0 340px;
        min-height: 560px;
        overflow: hidden;
        position: relative;
        box-shadow: 0 32px 90px rgba(15, 23, 42, .14);
    }

    .jox-hero-img {
        display: block;
        height: 100%;
        min-height: 560px;
        object-fit: cover;
        object-position: center;
        width: 100%;
    }

    .jox-floating-card {
        background: rgba(255, 255, 255, .94);
        border: 1px solid rgba(15, 23, 42, .08);
        border-radius: 18px;
        box-shadow: 0 18px 50px rgba(15, 23, 42, .16);
        padding: 24px;
        position: absolute;
        width: 300px;
    }

    .jox-floating-card strong,
    .jox-floating-card span {
        display: block;
    }

    .jox-floating-card strong {
        font-size: 17px;
        margin-bottom: 8px;
    }

    .jox-floating-card span {
        color: #4b5563;
        font-size: 15px;
        line-height: 1.45;
    }

    .jox-floating-card i {
        color: #ff4b0b;
        font-size: 26px;
        position: absolute;
        right: 22px;
        top: 50%;
        transform: translateY(-50%);
    }

    .jox-payment-card {
        right: 30px;
        top: 78px;
    }

    .jox-delivery-card {
        background: rgba(7, 8, 13, .94);
        color: #ffffff;
        right: 30px;
        top: 245px;
    }

    .jox-delivery-card span {
        color: rgba(255, 255, 255, .84);
    }

    .jox-support-card {
        bottom: 70px;
        right: 30px;
    }

    .jox-content-grid {
        display: grid;
        gap: 32px;
        grid-template-columns: minmax(0, 1fr) 420px;
        margin: 0 auto;
        max-width: 1680px;
        padding: 0 48px 26px;
    }

    .jox-main-column,
    .jox-side-column {
        display: grid;
        gap: 32px;
    }

    .jox-section {
        background: rgba(255, 255, 255, .84);
        border: 1px solid rgba(15, 23, 42, .07);
        border-radius: 22px;
        box-shadow: 0 18px 45px rgba(15, 23, 42, .06);
        padding: 22px;
    }

    .jox-section-head {
        align-items: center;
        display: flex;
        justify-content: space-between;
        margin-bottom: 18px;
    }

    .jox-section-head h2 {
        color: #07080d;
        font-size: 22px;
        font-weight: 900;
        letter-spacing: 0;
        margin: 0;
    }

    .jox-section-head a {
        align-items: center;
        color: #ff4b0b;
        display: inline-flex;
        font-weight: 800;
        gap: 8px;
    }

    .jox-restaurant-row {
        display: grid;
        gap: 20px;
        grid-template-columns: repeat(4, minmax(0, 1fr));
    }

    .jox-restaurant-card {
        background: #ffffff;
        border: 1px solid rgba(15, 23, 42, .08);
        border-radius: 14px;
        box-shadow: 0 12px 28px rgba(15, 23, 42, .06);
        color: #07080d;
        display: block;
        overflow: hidden;
    }

    .jox-restaurant-card img {
        display: block;
        height: 116px;
        object-fit: cover;
        object-position: center;
        width: 100%;
    }

    .jox-restaurant-body {
        padding: 14px 16px 16px;
    }

    .jox-restaurant-body strong {
        color: #07080d;
        display: block;
        font-size: 15px;
        margin-bottom: 7px;
    }

    .jox-restaurant-meta {
        color: #6b7280;
        display: flex;
        font-size: 13px;
        justify-content: space-between;
        gap: 10px;
    }

    .jox-restaurant-meta span:last-child {
        color: #ff9900;
        font-weight: 800;
        white-space: nowrap;
    }

    .jox-promo-card {
        background: linear-gradient(135deg, #ff4b0b, #db3400);
        background-position: center;
        background-size: cover;
        border-radius: 22px;
        box-shadow: 0 22px 54px rgba(255, 75, 11, .18);
        color: #ffffff;
        display: block;
        min-height: 230px;
        overflow: hidden;
        padding: 34px;
        position: relative;
    }

    .jox-promo-card:before {
        background: linear-gradient(90deg, rgba(0, 0, 0, .45), rgba(0, 0, 0, .04));
        content: "";
        inset: 0;
        position: absolute;
    }

    .jox-promo-card span,
    .jox-promo-card strong,
    .jox-promo-card em {
        display: block;
        position: relative;
        z-index: 1;
    }

    .jox-promo-card span {
        font-size: 18px;
        font-weight: 800;
        max-width: 280px;
    }

    .jox-promo-card strong {
        font-size: 54px;
        font-weight: 900;
        line-height: 1;
        margin: 12px 0;
    }

    .jox-promo-card em {
        background: #ffffff;
        border-radius: 13px;
        color: #db3400;
        font-style: normal;
        font-weight: 900;
        margin-top: 22px;
        padding: 13px 18px;
        width: max-content;
    }

    .jox-partner-card {
        align-items: center;
        background: #090909;
        border-radius: 22px;
        box-shadow: 0 22px 54px rgba(15, 23, 42, .16);
        color: #ffffff;
        display: grid;
        gap: 14px;
        grid-template-columns: 1fr 150px;
        min-height: 190px;
        overflow: hidden;
        padding: 28px;
    }

    .jox-partner-card h2 {
        color: #ffffff;
        font-size: 20px;
        font-weight: 900;
        margin: 0 0 10px;
    }

    .jox-partner-card p {
        color: rgba(255, 255, 255, .82);
        font-size: 14px;
        line-height: 1.55;
        margin: 0 0 20px;
    }

    .jox-partner-card a {
        background: #ff4b0b;
        border-radius: 12px;
        color: #ffffff;
        display: inline-flex;
        font-weight: 900;
        padding: 13px 18px;
    }

    .jox-partner-card img {
        height: 150px;
        object-fit: cover;
        width: 150px;
    }

    .jox-activity-row {
        display: grid;
        gap: 18px;
        grid-template-columns: repeat(4, minmax(0, 1fr));
    }

    .jox-activity-card {
        background: #ffffff;
        border: 1px solid rgba(15, 23, 42, .07);
        border-radius: 16px;
        box-shadow: 0 12px 28px rgba(15, 23, 42, .06);
        color: #07080d;
        display: block;
        min-height: 118px;
        padding: 18px;
    }

    .jox-activity-card strong,
    .jox-activity-card span,
    .jox-activity-card em {
        display: block;
    }

    .jox-activity-card strong {
        font-size: 15px;
        margin-bottom: 6px;
    }

    .jox-activity-card span {
        color: #6b7280;
        font-size: 13px;
        margin-bottom: 12px;
    }

    .jox-activity-card em {
        color: #07080d;
        font-style: normal;
        font-weight: 900;
    }

    .jox-benefits {
        background: #ffffff;
        border: 1px solid rgba(15, 23, 42, .07);
        border-radius: 18px;
        box-shadow: 0 18px 45px rgba(15, 23, 42, .06);
        display: grid;
        gap: 18px;
        grid-template-columns: repeat(4, minmax(0, 1fr));
        margin: 0 auto 44px;
        max-width: 1680px;
        padding: 18px 48px;
        width: calc(100% - 96px);
    }

    .jox-benefits div {
        align-items: center;
        display: flex;
        gap: 16px;
    }

    .jox-benefits i {
        color: #ff4b0b;
        font-size: 32px;
    }

    .jox-benefits span {
        color: #07080d;
        font-size: 15px;
        font-weight: 800;
        line-height: 1.25;
    }

    @media (max-width: 1199px) {
        .jox-web-nav {
            grid-template-columns: auto 1fr auto;
            padding: 20px;
        }

        .jox-nav-links {
            display: none;
        }

        .jox-hero,
        .jox-content-grid {
            grid-template-columns: 1fr;
            padding-left: 20px;
            padding-right: 20px;
        }

        .jox-hero-copy {
            padding-top: 20px;
        }

        .jox-hero-visual {
            border-radius: 32px;
        }

        .jox-restaurant-row,
        .jox-activity-row {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .jox-benefits {
            grid-template-columns: repeat(2, minmax(0, 1fr));
            width: calc(100% - 40px);
        }
    }

    @media (max-width: 767px) {
        .jox-web-nav {
            gap: 14px;
            grid-template-columns: 1fr auto;
        }

        .jox-location-pill {
            grid-column: 1 / -1;
            justify-content: center;
            order: 3;
        }

        .jox-auth-actions {
            gap: 8px;
        }

        .jox-lang {
            display: none;
        }

        .jox-login,
        .jox-signup {
            min-width: 0;
            padding: 11px 12px;
        }

        .jox-hero-copy h1 {
            font-size: 38px;
        }

        .location-box .location-group {
            grid-template-columns: auto 1fr;
            padding-right: 18px;
        }

        .location-box .location-group .locate-me {
            border-left: 0;
            border-top: 1px solid rgba(15, 23, 42, .08);
            grid-column: 1 / -1;
            width: 100%;
        }

        .jox-services {
            grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .jox-hero-visual,
        .jox-hero-img {
            min-height: 360px;
        }

        .jox-floating-card {
            display: none;
        }

        .jox-restaurant-row,
        .jox-activity-row,
        .jox-benefits {
            grid-template-columns: 1fr;
        }

        .jox-benefits {
            padding: 20px;
        }

        .jox-partner-card {
            grid-template-columns: 1fr;
        }
    }
</style>

<script type="text/javascript">
    jQuery("#overlay").show();

    var placeholderImageSrc = "{{ asset('img/hero_banner.png') }}";
    var localHeroFallback = "{{ asset('img/joxmako-hero-bg.png') }}";
    var localServiceFallback = "{{ asset('img/hero_banner.png') }}";
    var globalSettingsRef = database.collection('settings').doc('globalSettings');

    globalSettingsRef.get().then(function (globalSettingsSnapshots) {
        var globalSettingsData = globalSettingsSnapshots.data();
        if (globalSettingsData && globalSettingsData.appLogo) {
            $('#joxLogo').attr('src', globalSettingsData.appLogo);
        }
    });

    database.collection('settings').doc('placeHolderImage').get().then(function (placeholderImageSnapshots) {
        var data = placeholderImageSnapshots.data();
        if (data && data.image) {
            placeholderImageSrc = data.image;
        }
    });

    $(document).ready(async function () {
        $('.location-group .locate-me').attr("onclick", "getCurrentLocation()");
        syncLocationLabel();
        await Promise.all([
            getSections(),
            hydrateHeroBanner(),
            hydrateRestaurantsAndPromos(),
            hydrateRecentActivities()
        ]);
        jQuery("#overlay").hide();
    });

    function syncLocationLabel() {
        var address = getCookie('address_name') || $('#user_locationnew').val() || '';
        if (address) {
            $('#user_locationnew').val(address);
            $('.jox-current-location').text(shortAddress(address));
        }
    }

    async function hydrateHeroBanner() {
        try {
            var banners = await database.collection('banner_items')
                .where("is_publish", "==", true)
                .orderBy('set_order', 'asc')
                .get();
            var selectedBanner = null;
            banners.docs.some((doc) => {
                var data = doc.data();
                var image = data.web_banner || data.photo || data.image;
                if (!image) {
                    return false;
                }
                if (!data.sectionId || data.position == 'top') {
                    selectedBanner = data;
                    return true;
                }
                return false;
            });
            if (!selectedBanner) {
                return;
            }
            $('.jox-hero-img').attr('src', selectedBanner.web_banner || selectedBanner.photo || selectedBanner.image);
        } catch (error) {}
    }

    async function hydrateRestaurantsAndPromos() {
        try {
            var foodSection = await getFoodSection();
            if (!foodSection) {
                return;
            }
            var restaurants = await getFeaturedRestaurants(foodSection.id);
            if (restaurants.length) {
                $('#joxRestaurants').html(buildRestaurantsHTML(restaurants));
                $('.jox-restaurants-section').removeAttr('hidden');
            }
            var coupon = await getActiveCoupon(foodSection.id);
            if (coupon) {
                $('#joxPromoCard').html(buildPromoHTML(coupon));
                var image = coupon.image || coupon.photo || coupon.web_image || coupon.banner || '';
                if (image) {
                    $('#joxPromoCard').css('background-image', 'linear-gradient(90deg, rgba(0,0,0,.58), rgba(0,0,0,.1)), url(' + escapeCssUrl(image) + ')');
                }
                $('.jox-promo-section').removeAttr('hidden');
            }
        } catch (error) {}
    }

    async function hydrateRecentActivities() {
        if (typeof user_uuid === 'undefined' || !user_uuid) {
            return;
        }
        try {
            var orders = await database.collection('vendor_orders')
                .where("author.id", "==", user_uuid)
                .orderBy('createdAt', 'desc')
                .limit(4)
                .get();
            if (!orders.docs.length) {
                return;
            }
            var html = '';
            orders.docs.forEach((doc) => {
                var order = doc.data();
                order.id = order.id || doc.id;
                html += buildActivityCard(order);
            });
            $('#joxActivities').html(html);
            $('.jox-activities-section').removeAttr('hidden');
        } catch (error) {}
    }

    async function getSections() {
        var sectionsSnapshot = await database.collection('sections')
            .where('isActive', '==', true)
            .orderBy('order')
            .get();
        $('#jox-services').html(buildHTMLSections(sectionsSnapshot));
    }

    function buildHTMLSections(sectionsSnapshot) {
        var html = '';
        sectionsSnapshot.docs.forEach((listval) => {
            var val = listval.data();
            val.id = listval.id;
            var photo = val.sectionImage || val.image || val.photo || placeholderImageSrc || localServiceFallback;
            html += '<div class="cat-item" data-color="' + escapeAttr(val.color || '#ff4b0b') + '" service_type="' + escapeAttr(val.serviceType || '') + '" data-name="' + escapeAttr(val.name || '') + '" data-dine_in="' + escapeAttr(val.dine_in_active || false) + '" data-id="' + escapeAttr(val.id) + '">';
            html += '<a class="cat-link" href="javascript:void(0)">';
            html += '<img alt="' + escapeAttr(val.name || '') + '" src="' + escapeAttr(photo) + '" onerror="this.onerror=null;this.src=\'' + localServiceFallback + '\'">';
            html += '<p>' + escapeHtml(val.name || '') + '</p>';
            html += '</a></div>';
        });
        return html;
    }

    async function getFoodSection() {
        var sections = await database.collection('sections')
            .where('isActive', '==', true)
            .orderBy('order')
            .get();
        var foodSection = null;
        sections.docs.some((doc) => {
            var data = doc.data();
            data.id = doc.id;
            if (data.serviceType == 'Multivendor Delivery Service') {
                foodSection = data;
                return true;
            }
            return false;
        });
        return foodSection;
    }

    async function getFeaturedRestaurants(sectionId) {
        var query = database.collection('vendors').where('section_id', '==', sectionId);
        if (typeof user_zone_id !== 'undefined' && user_zone_id) {
            query = query.where('zoneId', '==', user_zone_id);
        }
        var snapshot = await query.limit(40).get();
        var vendors = [];
        snapshot.docs.forEach((doc) => {
            var data = doc.data();
            data.id = doc.id;
            if (isVendorVisible(data)) {
                vendors.push(data);
            }
        });
        var sponsored = vendors.filter((vendor) => isSponsoredVendor(vendor));
        var list = sponsored.length ? sponsored : vendors;
        return list.sort(sortVendors).slice(0, 4);
    }

    async function getActiveCoupon(sectionId) {
        var now = new Date();
        var coupons = await database.collection('coupons')
            .where('isEnabled', '==', true)
            .where('isPublic', '==', true)
            .where("section_id", "==", sectionId)
            .orderBy("expiresAt")
            .startAt(now)
            .limit(1)
            .get();
        if (!coupons.docs.length) {
            return null;
        }
        var coupon = coupons.docs[0].data();
        coupon.id = coupons.docs[0].id;
        return coupon;
    }

    function buildRestaurantsHTML(restaurants) {
        var html = '';
        restaurants.forEach((vendor) => {
            var route = "{{ route('vendor', ':id') }}".replace(':id', vendor.id);
            var photo = vendor.photo || vendor.coverPhoto || placeholderImageSrc || localServiceFallback;
            var rating = getVendorRating(vendor);
            var meta = Array.isArray(vendor.categoryTitle) ? vendor.categoryTitle.join(', ') : (vendor.categoryTitle || vendor.location || '');
            html += '<a class="jox-restaurant-card" href="' + route + '" onclick="return openWithLocationCheck(\'' + escapeJs(route) + '\')">';
            html += '<img src="' + escapeAttr(photo) + '" alt="' + escapeAttr(vendor.title || '') + '" onerror="this.onerror=null;this.src=\'' + localServiceFallback + '\'">';
            html += '<div class="jox-restaurant-body"><strong>' + escapeHtml(vendor.title || '') + '</strong>';
            html += '<span class="jox-restaurant-meta"><span>' + escapeHtml(meta || '') + '</span><span>★ ' + escapeHtml(rating) + '</span></span></div>';
            html += '</a>';
        });
        return html;
    }

    function buildPromoHTML(coupon) {
        var label = getCouponLabel(coupon);
        var code = coupon.code || coupon.couponCode || '';
        var text = coupon.description || coupon.title || coupon.name || code || '';
        return '<span>' + escapeHtml(text) + '</span><strong>' + escapeHtml(label) + '</strong>' + (code ? '<em>' + escapeHtml(code) + '</em>' : '');
    }

    function buildActivityCard(order) {
        var orderRoute = "{{ route('orderDetails', ':id') }}".replace(':id', 'id=' + order.id);
        var vendorTitle = order.vendor && order.vendor.title ? order.vendor.title : 'Commande';
        var amount = order.amount || order.total || order.total_pay || order.total_pay_amount || '';
        var status = order.status || '';
        var html = '<a class="jox-activity-card" href="' + orderRoute + '">';
        html += '<strong>' + escapeHtml(vendorTitle) + '</strong>';
        html += '<span>' + escapeHtml(formatActivityDate(order.createdAt)) + (status ? ' · ' + escapeHtml(status) : '') + '</span>';
        html += '<em>' + escapeHtml(formatMoney(amount)) + '</em>';
        html += '</a>';
        return html;
    }

    function openWithLocationCheck(url) {
        if (!hasResolvedHomeLocation()) {
            alert('Please select your address');
            $('#user_locationnew').focus();
            return false;
        }
        window.location.href = url;
        return false;
    }

    function hasResolvedHomeLocation() {
        return Boolean((typeof getCookie == 'function' && getCookie('address_name')) || $('#user_locationnew').val());
    }

    $(document).on("click", ".cat-slider .cat-item", function () {
        $(this).addClass('section-selected').siblings().removeClass('section-selected');
        $('.btn-continue').trigger('click');
    });

    $(document).on("click", ".btn-continue", function () {
        var element = $('.cat-slider .cat-item.section-selected');
        var section_id = element.attr('data-id');
        if ($('#user_locationnew').val() == '') {
            alert('Please select your address');
            $('#user_locationnew').focus();
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

    $('#user_locationnew').on('change keyup', function () {
        syncLocationLabel();
    });

    function isVendorVisible(vendor) {
        if (vendor.hasOwnProperty('isActive')) {
            return vendor.isActive == true;
        }
        if (vendor.hasOwnProperty('publish')) {
            return vendor.publish == true;
        }
        return true;
    }

    function isSponsoredVendor(vendor) {
        return vendor.isSponsored == true ||
            vendor.sponsored == true ||
            vendor.is_sponsor == true ||
            vendor.isSponsor == true ||
            vendor.isFeatured == true ||
            vendor.featured == true ||
            vendor.promoted == true ||
            vendor.specialDiscountEnable == true;
    }

    function sortVendors(a, b) {
        var ratingDiff = Number(b.reviewsSum || 0) - Number(a.reviewsSum || 0);
        if (ratingDiff != 0) {
            return ratingDiff;
        }
        return getDateValue(b.createdAt) - getDateValue(a.createdAt);
    }

    function getDateValue(value) {
        if (!value) {
            return 0;
        }
        if (typeof value.toDate == 'function') {
            return value.toDate().getTime();
        }
        return new Date(value).getTime() || 0;
    }

    function getVendorRating(vendor) {
        if (vendor.reviewsSum && vendor.reviewsCount) {
            return (Math.round((vendor.reviewsSum / vendor.reviewsCount) * 10) / 10).toString();
        }
        return vendor.rating || '-';
    }

    function getCouponLabel(coupon) {
        if (coupon.discountType == 'Percent' || coupon.discountType == 'percentage') {
            return '-' + (coupon.discount || coupon.discountAmount || coupon.amount || '') + '%';
        }
        return coupon.discount || coupon.discountAmount || coupon.amount || coupon.code || '';
    }

    function shortAddress(value) {
        return String(value || '').split(',').slice(0, 2).join(', ').trim() || 'Choisir une adresse';
    }

    function formatActivityDate(value) {
        var date = value && typeof value.toDate == 'function' ? value.toDate() : new Date(value);
        if (!date || isNaN(date.getTime())) {
            return '';
        }
        return date.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric' });
    }

    function formatMoney(value) {
        if (value === '' || value === null || value === undefined) {
            return '';
        }
        var numeric = Number(value);
        if (isNaN(numeric)) {
            return value;
        }
        if (typeof currentCurrency !== 'undefined') {
            return numeric.toLocaleString('fr-FR') + ' ' + currentCurrency;
        }
        return numeric.toLocaleString('fr-FR');
    }

    function escapeHtml(value) {
        return String(value || '').replace(/[&<>"']/g, function(match) {
            return ({
                '&': '&amp;',
                '<': '&lt;',
                '>': '&gt;',
                '"': '&quot;',
                "'": '&#039;'
            })[match];
        });
    }

    function escapeAttr(value) {
        return escapeHtml(value).replace(/`/g, '&#096;');
    }

    function escapeJs(value) {
        return String(value || '').replace(/\\/g, '\\\\').replace(/'/g, "\\'");
    }

    function escapeCssUrl(value) {
        return String(value || '').replace(/[\\'")]/g, '');
    }
</script>
