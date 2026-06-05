@include('layouts.app')
@include('layouts.header')

<style>
.jox-legal-page { max-width: 860px; margin: 0 auto; padding: 40px 20px 80px; }
.jox-lang-block { margin-bottom: 48px; }
.jox-lang-label {
    display: inline-block;
    font-size: 11px;
    font-weight: 700;
    letter-spacing: 1.5px;
    text-transform: uppercase;
    color: #fff;
    background: #FF6839;
    border-radius: 4px;
    padding: 4px 12px;
    margin-bottom: 18px;
}
.jox-legal-page h1 { font-size: 28px; font-weight: 700; margin-bottom: 8px; color: #1a1a1a; }
.jox-legal-page .jox-date { font-size: 13px; color: #888; margin-bottom: 32px; }
.jox-legal-page h2 { font-size: 20px; font-weight: 700; margin-top: 36px; margin-bottom: 6px; color: #1a1a1a; }
.jox-legal-page h3 { font-size: 16px; font-weight: 600; margin-top: 20px; margin-bottom: 6px; color: #333; }
.jox-legal-page p, .jox-legal-page li { font-size: 15px; line-height: 1.75; color: #444; }
.jox-legal-page ul { padding-left: 20px; margin-bottom: 12px; }
.jox-divider { border: none; border-top: 2px solid #f0f0f0; margin: 48px 0; }
.jox-rtl { direction: rtl; text-align: right; }
.jox-rtl ul { padding-left: 0; padding-right: 20px; }
.jox-prohibited-notice {
    background: #fff5f2;
    border-left: 4px solid #FF6839;
    padding: 16px 20px;
    border-radius: 4px;
    margin-bottom: 28px;
}
</style>

<div class="jox-legal-page">

    {{-- ─────────────── FRANÇAIS ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">FRANÇAIS</span>

        <h1>Politique des Articles Interdits – JOXMAKO</h1>
        <p class="jox-date">Dernière mise à jour : mai 2026</p>

        <div class="jox-prohibited-notice">
            <strong>Important :</strong> L'utilisation de la Plateforme JOXMAKO pour commander, expédier, transporter ou faciliter la livraison de l'un des articles listés ci-dessous est strictement interdite et entraîne la suspension immédiate du compte, ainsi qu'un éventuel signalement aux autorités compétentes.
        </div>

        <h2>1. Armes et Explosifs</h2>
        <ul>
            <li>Armes à feu, revolvers, pistolets, fusils, carabines ;</li>
            <li>Munitions, cartouches, balles ;</li>
            <li>Explosifs, détonateurs, grenades, artifices de guerre ;</li>
            <li>Armes blanches (couteaux de combat, dagues, poignards) ;</li>
            <li>Armes de défense interdites (tasers, matraques électriques non homologuées) ;</li>
            <li>Pièces ou composants d'armes à feu.</li>
        </ul>

        <h2>2. Drogues et Stupéfiants</h2>
        <ul>
            <li>Drogues illicites (cannabis, cocaïne, héroïne, ecstasy, etc.) ;</li>
            <li>Précurseurs chimiques contrôlés ;</li>
            <li>Médicaments psychotropes détournés de leur usage médical ;</li>
            <li>Nouvelles substances psychoactives (NPS) non autorisées.</li>
        </ul>

        <h2>3. Médicaments et Produits de Santé</h2>
        <ul>
            <li>Médicaments nécessitant une ordonnance médicale sans prescription valide ;</li>
            <li>Médicaments dont la vente ou la distribution est réglementée et non autorisée ;</li>
            <li>Produits pharmaceutiques contrefaits.</li>
        </ul>

        <h2>4. Articles Contrefaits et de Contrebande</h2>
        <ul>
            <li>Produits contrefaits portant des marques déposées sans autorisation ;</li>
            <li>Logiciels ou médias piratés ;</li>
            <li>Marchandises de contrebande ou soumises à embargo ;</li>
            <li>Billets de spectacles ou titres de transport falsifiés.</li>
        </ul>

        <h2>5. Matières Dangereuses</h2>
        <ul>
            <li>Substances chimiques corrosives, acides concentrés ;</li>
            <li>Produits radioactifs ou contaminants biologiques ;</li>
            <li>Liquides inflammables non déclarés (carburant, solvants) ;</li>
            <li>Gaz sous pression non conformes à la réglementation de transport ;</li>
            <li>Déchets toxiques ou déchets industriels dangereux.</li>
        </ul>

        <h2>6. Animaux et Espèces Protégées</h2>
        <ul>
            <li>Animaux vivants de toute espèce, sans exception ;</li>
            <li>Espèces animales ou végétales protégées par la Convention CITES ;</li>
            <li>Produits dérivés d'espèces protégées (ivoire, écailles de tortue, fourrures interdites, etc.).</li>
        </ul>

        <h2>7. Valeurs Financières et Monétaires</h2>
        <ul>
            <li>Espèces (billets de banque, pièces de monnaie) ;</li>
            <li>Chèques, chèques de voyage, mandats ;</li>
            <li>Instruments financiers négociables (obligations au porteur, bons au porteur) ;</li>
            <li>Cartes bancaires, cartes prépayées, cartes-cadeaux à forte valeur sans emballage d'origine scellé.</li>
        </ul>

        <h2>8. Contenus Illégaux</h2>
        <ul>
            <li>Matériel d'abus sexuel sur mineurs (MASE) ;</li>
            <li>Tout contenu dont la possession, la diffusion ou le commerce est illégal dans la juridiction concernée.</li>
        </ul>

        <h2>9. Articles Soumis à Restrictions à l'Import/Export</h2>
        <ul>
            <li>Tout article soumis à des restrictions douanières, licences d'importation ou d'exportation spécifiques, et pour lequel la documentation requise n'a pas été fournie ;</li>
            <li>Produits culturels protégés (antiquités, œuvres d'art nécessitant une autorisation d'export) ;</li>
            <li>Produits sous embargo international.</li>
        </ul>

        <h2>10. Signalement</h2>
        <p>Si vous constatez qu'un article interdit est en cours de transport via la Plateforme, veuillez le signaler immédiatement via notre page <a href="{{ route('support') }}" style="color:#FF6839;">Support</a>. JOXMAKO collabore avec les autorités compétentes pour toute infraction signalée.</p>

        <p>Cette politique s'applique à toutes les fonctionnalités de JOXMAKO : livraison de commandes, envoi de colis, transport de personnes et services à la demande. Elle est susceptible d'être mise à jour pour refléter les évolutions légales et réglementaires.</p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── ENGLISH ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">ENGLISH</span>

        <h1>Prohibited Items Policy – JOXMAKO</h1>
        <p class="jox-date">Last updated: May 2026</p>

        <div class="jox-prohibited-notice">
            <strong>Important:</strong> Using the JOXMAKO Platform to order, ship, transport, or facilitate the delivery of any item listed below is strictly prohibited and will result in immediate account suspension and potential reporting to relevant authorities.
        </div>

        <h2>1. Weapons and Explosives</h2>
        <ul>
            <li>Firearms (revolvers, pistols, rifles, carbines);</li>
            <li>Ammunition, cartridges, bullets;</li>
            <li>Explosives, detonators, grenades, military ordnance;</li>
            <li>Bladed weapons (combat knives, daggers);</li>
            <li>Prohibited self-defense weapons (non-approved tasers, electric batons);</li>
            <li>Firearm parts or components.</li>
        </ul>

        <h2>2. Drugs and Narcotics</h2>
        <ul>
            <li>Illegal drugs (cannabis, cocaine, heroin, MDMA, etc.);</li>
            <li>Controlled chemical precursors;</li>
            <li>Psychotropic medications diverted from medical use;</li>
            <li>Unauthorized new psychoactive substances (NPS).</li>
        </ul>

        <h2>3. Medications and Health Products</h2>
        <ul>
            <li>Prescription-only medications without a valid prescription;</li>
            <li>Regulated medications without proper authorization for distribution;</li>
            <li>Counterfeit pharmaceutical products.</li>
        </ul>

        <h2>4. Counterfeit and Smuggled Goods</h2>
        <ul>
            <li>Counterfeit products bearing registered trademarks without authorization;</li>
            <li>Pirated software or media;</li>
            <li>Contraband or embargoed merchandise;</li>
            <li>Forged event tickets or transport documents.</li>
        </ul>

        <h2>5. Hazardous Materials</h2>
        <ul>
            <li>Corrosive chemical substances, concentrated acids;</li>
            <li>Radioactive or biological contaminants;</li>
            <li>Undeclared flammable liquids (fuel, solvents);</li>
            <li>Pressurized gases not compliant with transport regulations;</li>
            <li>Toxic waste or hazardous industrial waste.</li>
        </ul>

        <h2>6. Animals and Protected Species</h2>
        <ul>
            <li>Live animals of any species, without exception;</li>
            <li>Animal or plant species protected under the CITES Convention;</li>
            <li>Products derived from protected species (ivory, tortoiseshell, prohibited furs, etc.).</li>
        </ul>

        <h2>7. Financial and Monetary Values</h2>
        <ul>
            <li>Cash (banknotes, coins);</li>
            <li>Cheques, traveler's cheques, money orders;</li>
            <li>Negotiable financial instruments (bearer bonds, bearer notes);</li>
            <li>Bank cards, prepaid cards, or high-value gift cards without original sealed packaging.</li>
        </ul>

        <h2>8. Illegal Content</h2>
        <ul>
            <li>Child sexual abuse material (CSAM);</li>
            <li>Any content whose possession, distribution, or sale is illegal in the relevant jurisdiction.</li>
        </ul>

        <h2>9. Import/Export-Restricted Items</h2>
        <ul>
            <li>Any item subject to customs restrictions, import or export licenses, for which required documentation has not been provided;</li>
            <li>Protected cultural property (antiques, artworks requiring export authorization);</li>
            <li>Products under international embargo.</li>
        </ul>

        <h2>10. Reporting</h2>
        <p>If you become aware that a prohibited item is being transported via the Platform, please report it immediately through our <a href="{{ route('support') }}" style="color:#FF6839;">Support</a> page. JOXMAKO cooperates with relevant authorities on all reported violations.</p>

        <p>This policy applies to all JOXMAKO features: order delivery, parcel sending, ride-hailing, and on-demand services. It may be updated to reflect changes in laws and regulations.</p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── العربية ─────────────── --}}
    <div class="jox-lang-block jox-rtl">
        <span class="jox-lang-label">العربية</span>

        <h1>سياسة العناصر المحظورة – JOXMAKO</h1>
        <p class="jox-date">آخر تحديث: مايو 2026</p>

        <div class="jox-prohibited-notice" style="border-left:none;border-right:4px solid #FF6839;">
            <strong>تنبيه:</strong> يُحظر تماماً استخدام منصة JOXMAKO لطلب أو شحن أو نقل أو تسهيل توصيل أي من العناصر المدرجة أدناه، وسيُؤدي ذلك إلى تعليق الحساب فوراً، وقد يُبلَّغ عن المخالفة للسلطات المختصة.
        </div>

        <h2>١. الأسلحة والمتفجرات</h2>
        <ul>
            <li>الأسلحة النارية (مسدسات، بنادق، كرابين)؛</li>
            <li>الذخيرة والرصاص؛</li>
            <li>المتفجرات والقنابل والمواد الحربية؛</li>
            <li>الأسلحة البيضاء (سكاكين القتال، الخناجر)؛</li>
            <li>أجزاء أو مكونات الأسلحة النارية.</li>
        </ul>

        <h2>٢. المخدرات والمؤثرات العقلية</h2>
        <ul>
            <li>المخدرات غير المشروعة (الحشيش، الكوكايين، الهيروين، الإكستازي، إلخ)؛</li>
            <li>السلائف الكيميائية الخاضعة للرقابة؛</li>
            <li>الأدوية النفسية المحولة عن استخدامها الطبي.</li>
        </ul>

        <h2>٣. المواد الخطرة</h2>
        <ul>
            <li>المواد الكيميائية المسببة للتآكل والأحماض المركزة؛</li>
            <li>المواد المشعة أو الملوثات البيولوجية؛</li>
            <li>السوائل القابلة للاشتعال غير المُصرَّح بها؛</li>
            <li>النفايات السامة أو النفايات الصناعية الخطرة.</li>
        </ul>

        <h2>٤. الحيوانات والأنواع المحمية</h2>
        <ul>
            <li>الحيوانات الحية من أي نوع دون استثناء؛</li>
            <li>الأنواع الحيوانية والنباتية المحمية بموجب اتفاقية سايتس (CITES)؛</li>
            <li>المنتجات المشتقة من الأنواع المحمية (العاج، درع السلاحف، الفراء المحظور، إلخ).</li>
        </ul>

        <h2>٥. القيم المالية والنقدية</h2>
        <ul>
            <li>النقد (الأوراق النقدية والعملات المعدنية)؛</li>
            <li>الشيكات وحوالات الأموال؛</li>
            <li>الأدوات المالية القابلة للتداول؛</li>
            <li>أي بند يُعدّ استيراده أو تصديره أو حيازته غير مشروع في الولاية القضائية المعنية.</li>
        </ul>

        <h2>٦. الإبلاغ عن المخالفات</h2>
        <p>إذا لاحظت أن عنصراً محظوراً يجري نقله عبر المنصة، يُرجى الإبلاغ عنه فوراً من خلال صفحة <a href="{{ route('support') }}" style="color:#FF6839;">الدعم</a>. تتعاون JOXMAKO مع السلطات المختصة بشأن جميع المخالفات المُبلَّغ عنها.</p>
    </div>

</div>

@include('layouts.footer')
