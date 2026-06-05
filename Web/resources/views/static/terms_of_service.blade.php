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
</style>

<div class="jox-legal-page">

    {{-- ─────────────── FRANÇAIS ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">FRANÇAIS</span>

        <h1>Conditions Générales d'Utilisation – JOXMAKO</h1>
        <p class="jox-date">Dernière mise à jour : mai 2026</p>

        <p>Les présentes Conditions Générales d'Utilisation (ci-après « CGU ») régissent l'accès et l'utilisation des applications mobiles, du site web et des services proposés par <strong>JOXMAKO</strong>, opéré par <strong>Complexe Souafa</strong> (ci-après « nous », « notre » ou « la Plateforme »).</p>
        <p>En accédant ou en utilisant JOXMAKO, vous reconnaissez avoir lu, compris et accepté sans réserve les présentes CGU. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser nos services.</p>

        <h2>1. Description du Service</h2>
        <p>JOXMAKO est une plateforme de mise en relation entre des clients, des vendeurs/prestataires et des livreurs indépendants opérant dans des zones géographiques définies. La Plateforme facilite :</p>
        <ul>
            <li>La commande et la livraison de produits auprès de commerces partenaires ;</li>
            <li>L'envoi de colis entre particuliers ou entre professionnels et particuliers ;</li>
            <li>La réservation de véhicules avec chauffeur (service taxi/VTC) ;</li>
            <li>La réservation de prestataires de services à la demande.</li>
        </ul>
        <p>JOXMAKO n'est ni vendeur ni expéditeur : nous agissons exclusivement en tant qu'intermédiaire technique entre les parties.</p>

        <h2>2. Éligibilité</h2>
        <p>L'utilisation de JOXMAKO est réservée aux personnes physiques âgées d'au moins 18 ans et ayant la capacité juridique de conclure des contrats. En créant un compte, vous garantissez remplir ces conditions.</p>

        <h2>3. Compte Utilisateur</h2>
        <p>Pour accéder à la plupart des fonctionnalités, vous devez créer un compte en fournissant des informations exactes, complètes et à jour. Vous êtes responsable de la confidentialité de vos identifiants et de toutes les activités effectuées depuis votre compte.</p>
        <p>Nous nous réservons le droit de suspendre ou de supprimer tout compte en cas de violation des présentes CGU, de fraude, ou de mise en danger d'un utilisateur ou d'un livreur.</p>

        <h2>4. Obligations des Utilisateurs</h2>
        <p>En utilisant JOXMAKO, vous vous engagez à :</p>
        <ul>
            <li>Fournir des informations exactes lors de vos commandes et profils ;</li>
            <li>Ne pas utiliser la Plateforme à des fins illégales ou frauduleuses ;</li>
            <li>Ne pas expédier d'articles interdits (voir la liste complète en Section 6 et dans notre <a href="{{ route('prohibited-items') }}" style="color:#FF6839;">Politique des Articles Interdits</a>) ;</li>
            <li>Respecter les livreurs, vendeurs et autres utilisateurs ;</li>
            <li>Ne pas tenter de contourner les mécanismes de paiement de la Plateforme ;</li>
            <li>Ne pas reproduire, copier ou exploiter le contenu de la Plateforme sans autorisation écrite.</li>
        </ul>

        <h2>5. Obligations des Livreurs</h2>
        <p>Les livreurs inscrits sur JOXMAKO sont des prestataires indépendants. Ils s'engagent à :</p>
        <ul>
            <li>Disposer d'une autorisation légale de conduire et d'exercer une activité de livraison ;</li>
            <li>Fournir des documents valides lors de leur inscription (permis de conduire, carte d'identité, etc.) ;</li>
            <li>Respecter les lois et règlements applicables dans leur pays d'exercice ;</li>
            <li>Ne pas transporter de marchandises interdites ;</li>
            <li>Maintenir leur véhicule en état de marche et conformément aux exigences réglementaires locales.</li>
        </ul>
        <p>L'inscription des livreurs est soumise à validation manuelle par l'équipe JOXMAKO. Tout livreur peut être suspendu ou exclu en cas de manquement à ces obligations.</p>

        <h2>6. Articles et Expéditions Interdits</h2>
        <p>Il est strictement interdit d'utiliser la Plateforme pour commander, expédier, transporter ou faciliter la livraison des articles suivants :</p>
        <ul>
            <li>Armes à feu, munitions, explosifs, armes blanches ou tout objet pouvant servir d'arme ;</li>
            <li>Drogues illicites, stupéfiants, précurseurs chimiques contrôlés ;</li>
            <li>Produits contrefaits, articles piratés, marchandises de contrebande ;</li>
            <li>Matières dangereuses, substances chimiques corrosives, produits inflammables non déclarés ;</li>
            <li>Médicaments sur ordonnance sans prescription médicale valide ;</li>
            <li>Animaux vivants, espèces protégées ou produits dérivés d'espèces protégées ;</li>
            <li>Billets de banque, espèces, chèques, instruments financiers négociables ;</li>
            <li>Matériel pornographique impliquant des mineurs ;</li>
            <li>Tout article dont l'importation, l'exportation ou la détention est illégale dans la juridiction concernée ;</li>
            <li>Déchets toxiques ou déchets industriels non déclarés.</li>
        </ul>
        <p>Toute violation de cette interdiction entraîne la suspension immédiate du compte et peut faire l'objet d'un signalement aux autorités compétentes. Consultez notre <a href="{{ route('prohibited-items') }}" style="color:#FF6839;">Politique des Articles Interdits</a> pour plus de détails.</p>

        <h2>7. Paiements et Remboursements</h2>
        <p>Les paiements sont traités via des prestataires tiers sécurisés. JOXMAKO ne stocke pas vos données bancaires complètes. En cas de litige sur une commande, nous vous invitons à contacter notre support. Les remboursements sont traités conformément à la politique applicable au type de service utilisé et dans les délais légaux.</p>

        <h2>8. Limitation de Responsabilité</h2>
        <p>JOXMAKO agit en qualité d'intermédiaire et ne peut être tenu responsable :</p>
        <ul>
            <li>Des retards de livraison liés à des événements de force majeure ;</li>
            <li>De la qualité des produits fournis par les vendeurs partenaires ;</li>
            <li>Des dommages causés à des tiers par un livreur indépendant ;</li>
            <li>De l'inexactitude des informations fournies par les utilisateurs.</li>
        </ul>
        <p>Dans tous les cas, la responsabilité de JOXMAKO est limitée au montant de la commande en cause.</p>

        <h2>9. Propriété Intellectuelle</h2>
        <p>L'ensemble du contenu de la Plateforme (logo, marques, textes, code, design) est la propriété exclusive de Complexe Souafa ou de ses concédants. Toute reproduction ou utilisation non autorisée est interdite.</p>

        <h2>10. Modifications des CGU</h2>
        <p>Nous nous réservons le droit de modifier les présentes CGU à tout moment. Les modifications prennent effet dès leur publication sur la Plateforme. Il vous appartient de consulter régulièrement cette page. L'utilisation continue de JOXMAKO après modification vaut acceptation des nouvelles conditions.</p>

        <h2>11. Contact</h2>
        <p>Pour toute question relative aux présentes CGU, contactez-nous via la page <a href="{{ route('support') }}" style="color:#FF6839;">Support</a>.</p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── ENGLISH ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">ENGLISH</span>

        <h1>Terms of Service – JOXMAKO</h1>
        <p class="jox-date">Last updated: May 2026</p>

        <p>These Terms of Service ("Terms") govern your access to and use of the JOXMAKO mobile applications, website, and services operated by <strong>Complexe Souafa</strong> ("we", "our", or "the Platform").</p>
        <p>By accessing or using JOXMAKO, you confirm that you have read, understood, and agree to be bound by these Terms. If you do not agree, please do not use our services.</p>

        <h2>1. Service Description</h2>
        <p>JOXMAKO is a technology platform connecting customers, merchants/service providers, and independent delivery drivers operating in defined geographic areas. The Platform facilitates:</p>
        <ul>
            <li>Ordering and delivery of products from partner merchants;</li>
            <li>Parcel delivery between individuals or businesses and individuals;</li>
            <li>Ride-hailing and driver-on-demand services;</li>
            <li>On-demand service provider bookings.</li>
        </ul>
        <p>JOXMAKO is neither a seller nor a shipper. We act solely as a technology intermediary between parties.</p>

        <h2>2. Eligibility</h2>
        <p>Use of JOXMAKO is restricted to individuals aged 18 or older who have the legal capacity to enter into binding contracts. By creating an account, you warrant that you meet these requirements.</p>

        <h2>3. User Account</h2>
        <p>To access most features, you must create an account with accurate, complete, and current information. You are responsible for maintaining the confidentiality of your credentials and all activity under your account.</p>
        <p>We reserve the right to suspend or terminate any account that violates these Terms, engages in fraud, or poses a risk to users or drivers.</p>

        <h2>4. User Obligations</h2>
        <p>By using JOXMAKO, you agree to:</p>
        <ul>
            <li>Provide accurate information in your orders and profile;</li>
            <li>Not use the Platform for illegal or fraudulent purposes;</li>
            <li>Not ship prohibited items (see Section 6 and our <a href="{{ route('prohibited-items') }}" style="color:#FF6839;">Prohibited Items Policy</a>);</li>
            <li>Treat drivers, merchants, and other users with respect;</li>
            <li>Not circumvent the Platform's payment mechanisms;</li>
            <li>Not reproduce or exploit Platform content without written permission.</li>
        </ul>

        <h2>5. Driver Obligations</h2>
        <p>Drivers registered on JOXMAKO are independent contractors. They agree to:</p>
        <ul>
            <li>Hold valid legal authorization to drive and perform delivery activities;</li>
            <li>Submit valid documents at registration (driver's license, ID, etc.);</li>
            <li>Comply with all applicable laws and regulations in their operating jurisdiction;</li>
            <li>Refuse to transport prohibited goods;</li>
            <li>Maintain their vehicle in roadworthy condition per local regulatory requirements.</li>
        </ul>
        <p>Driver registration is subject to manual review and approval by the JOXMAKO team. Drivers may be suspended or removed for failure to comply with these obligations.</p>

        <h2>6. Prohibited Items and Shipments</h2>
        <p>It is strictly forbidden to use the Platform to order, ship, transport, or facilitate delivery of any of the following:</p>
        <ul>
            <li>Firearms, ammunition, explosives, bladed weapons, or any item usable as a weapon;</li>
            <li>Illegal drugs, narcotics, or controlled chemical precursors;</li>
            <li>Counterfeit goods, pirated products, or smuggled merchandise;</li>
            <li>Hazardous materials, corrosive substances, or undeclared flammable goods;</li>
            <li>Prescription medications without a valid medical prescription;</li>
            <li>Live animals, protected species, or products derived from protected species;</li>
            <li>Banknotes, cash, cheques, or negotiable financial instruments;</li>
            <li>Child sexual abuse material;</li>
            <li>Any item whose import, export, or possession is illegal in the relevant jurisdiction;</li>
            <li>Toxic waste or undeclared industrial waste.</li>
        </ul>
        <p>Any violation results in immediate account suspension and may be reported to relevant authorities. See our full <a href="{{ route('prohibited-items') }}" style="color:#FF6839;">Prohibited Items Policy</a>.</p>

        <h2>7. Payments and Refunds</h2>
        <p>Payments are processed through secure third-party providers. JOXMAKO does not store complete banking details. Disputes should be directed to our support team. Refunds are processed in accordance with the policy applicable to the service used and within legal timeframes.</p>

        <h2>8. Limitation of Liability</h2>
        <p>JOXMAKO acts as an intermediary and is not liable for:</p>
        <ul>
            <li>Delivery delays caused by force majeure events;</li>
            <li>The quality of products provided by partner merchants;</li>
            <li>Damages caused to third parties by independent drivers;</li>
            <li>Inaccurate information provided by users.</li>
        </ul>
        <p>In all cases, JOXMAKO's liability is limited to the value of the order in dispute.</p>

        <h2>9. Intellectual Property</h2>
        <p>All Platform content (logos, trademarks, text, code, design) is the exclusive property of Complexe Souafa or its licensors. Unauthorized reproduction or use is prohibited.</p>

        <h2>10. Changes to Terms</h2>
        <p>We reserve the right to modify these Terms at any time. Changes take effect upon publication on the Platform. Continued use of JOXMAKO following any modification constitutes acceptance of the updated Terms.</p>

        <h2>11. Contact</h2>
        <p>For questions regarding these Terms, contact us via the <a href="{{ route('support') }}" style="color:#FF6839;">Support</a> page.</p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── العربية ─────────────── --}}
    <div class="jox-lang-block jox-rtl">
        <span class="jox-lang-label">العربية</span>

        <h1>شروط الاستخدام – JOXMAKO</h1>
        <p class="jox-date">آخر تحديث: مايو 2026</p>

        <p>تحكم شروط الاستخدام هذه ("الشروط") وصولك إلى تطبيقات JOXMAKO للهاتف المحمول والموقع الإلكتروني والخدمات التي يديرها <strong>Complexe Souafa</strong>.</p>
        <p>باستخدام JOXMAKO، فإنك تقر بأنك قرأت هذه الشروط وفهمتها ووافقت عليها. إذا كنت لا توافق، يُرجى التوقف عن استخدام خدماتنا.</p>

        <h2>١. وصف الخدمة</h2>
        <p>JOXMAKO منصة تقنية تربط بين العملاء والتجار ومقدمي الخدمات وسائقي التوصيل المستقلين في مناطق جغرافية محددة. تُسهّل المنصة:</p>
        <ul>
            <li>طلب المنتجات وتوصيلها من التجار الشركاء؛</li>
            <li>إرسال الطرود بين الأفراد أو بين الشركات والأفراد؛</li>
            <li>خدمات توصيل الركاب والسيارات بحسب الطلب؛</li>
            <li>حجز مقدمي الخدمات عند الطلب.</li>
        </ul>
        <p>لا يُعدّ JOXMAKO بائعاً أو شاحناً، بل يعمل وسيطاً تقنياً فقط.</p>

        <h2>٢. الأهلية</h2>
        <p>يقتصر استخدام JOXMAKO على الأشخاص الذين تجاوزوا 18 عاماً ويتمتعون بالأهلية القانونية لإبرام العقود الملزمة.</p>

        <h2>٣. التزامات المستخدم</h2>
        <p>بموجب استخدامك لـ JOXMAKO، تلتزم بما يلي:</p>
        <ul>
            <li>تقديم معلومات دقيقة في طلباتك وملفك الشخصي؛</li>
            <li>عدم استخدام المنصة لأغراض غير مشروعة أو احتيالية؛</li>
            <li>عدم شحن العناصر المحظورة (انظر القسم ٤ وسياسة العناصر المحظورة)؛</li>
            <li>معاملة السائقين والتجار والمستخدمين الآخرين باحترام.</li>
        </ul>

        <h2>٤. العناصر والشحنات المحظورة</h2>
        <p>يُحظر استخدام المنصة لطلب أو شحن أو نقل أو تسهيل توصيل أيٍّ مما يلي:</p>
        <ul>
            <li>الأسلحة النارية والذخيرة والمتفجرات وأي أداة يمكن استخدامها سلاحاً؛</li>
            <li>المخدرات غير المشروعة والمواد الخاضعة للرقابة؛</li>
            <li>البضائع المقلدة أو المهربة؛</li>
            <li>المواد الخطرة والمواد الكيميائية الحارقة وأي بضائع قابلة للاشتعال غير مُصرَّح بها؛</li>
            <li>الأدوية الخاضعة للوصفة الطبية دون وصفة سارية المفعول؛</li>
            <li>الحيوانات الحية أو الأنواع المحمية أو منتجاتها؛</li>
            <li>الأوراق النقدية والنقد والشيكات أو أي أدوات مالية قابلة للتداول؛</li>
            <li>أي بند يُعدّ استيراده أو تصديره أو حيازته غير مشروع في الولاية القضائية المعنية.</li>
        </ul>
        <p>يترتب على أي انتهاك تعليق الحساب فوراً وقد يُبلَّغ عنه للسلطات المختصة.</p>

        <h2>٥. تحديد المسؤولية</h2>
        <p>يتصرف JOXMAKO بوصفه وسيطاً ولا يتحمل المسؤولية عن تأخيرات التوصيل بسبب القوة القاهرة، أو جودة منتجات التجار، أو الأضرار التي يسببها السائقون المستقلون لأطراف ثالثة.</p>

        <h2>٦. التواصل</h2>
        <p>لأي استفسار، يُرجى التواصل معنا عبر صفحة <a href="{{ route('support') }}" style="color:#FF6839;">الدعم</a>.</p>
    </div>

</div>

@include('layouts.footer')
