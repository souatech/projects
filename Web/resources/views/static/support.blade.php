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
.jox-legal-page h2 { font-size: 17px; font-weight: 600; margin-top: 28px; margin-bottom: 8px; color: #1a1a1a; }
.jox-legal-page p, .jox-legal-page li { font-size: 15px; line-height: 1.75; color: #444; }
.jox-legal-page ul { padding-left: 20px; margin-bottom: 12px; }
.jox-divider { border: none; border-top: 2px solid #f0f0f0; margin: 48px 0; }
.jox-rtl { direction: rtl; text-align: right; }
.jox-contact-card {
    background: #fff8f5;
    border: 1px solid #ffd5c5;
    border-radius: 10px;
    padding: 20px 24px;
    margin-top: 24px;
}
.jox-contact-card a { color: #FF6839; font-weight: 600; }
</style>

<div class="jox-legal-page">

    {{-- ─────────────── FRANÇAIS ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">FRANÇAIS</span>

        <h1>Assistance & Support</h1>
        <p class="jox-date">Joxmako — Service client</p>

        <h2>Comment pouvons-nous vous aider ?</h2>
        <p>
            Notre équipe d'assistance est disponible pour répondre à toutes vos questions concernant l'utilisation de l'application Joxmako : commandes, livraisons, paiements, compte ou tout autre problème technique.
        </p>

        <h2>Contacter le support</h2>
        <div class="jox-contact-card">
            <p><strong>E-mail :</strong> <a href="mailto:support@joxmako.com">support@joxmako.com</a></p>
            <p><strong>Heures d'ouverture :</strong> Lundi – Samedi, 08h00 – 20h00 (WAT)</p>
        </div>

        <h2>Questions fréquentes</h2>

        <h2>Ma commande est en retard, que faire ?</h2>
        <p>
            Suivez votre commande en temps réel depuis l'application. Si le délai dépasse l'estimation, contactez le livreur directement via la messagerie intégrée ou écrivez à notre support.
        </p>

        <h2>Comment annuler une commande ?</h2>
        <p>
            Vous pouvez annuler votre commande depuis la section "Mes commandes" tant qu'elle n'a pas encore été acceptée par le marchand.
        </p>

        <h2>Je n'ai pas reçu mon remboursement</h2>
        <p>
            Les remboursements sont traités sous 3 à 7 jours ouvrables selon votre mode de paiement. Si le délai est dépassé, contactez-nous avec votre numéro de commande.
        </p>

        <h2>Comment supprimer mon compte ?</h2>
        <p>
            Rendez-vous dans Paramètres → Mon compte → Supprimer le compte. Cette action est irréversible et supprime toutes vos données conformément à notre politique de confidentialité.
        </p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── ENGLISH ─────────────── --}}
    <div class="jox-lang-block">
        <span class="jox-lang-label">ENGLISH</span>

        <h1>Help & Support</h1>
        <p class="jox-date">Joxmako — Customer Support</p>

        <h2>How Can We Help You?</h2>
        <p>
            Our support team is available to answer all your questions about using the Joxmako app: orders, deliveries, payments, your account, or any technical issues.
        </p>

        <h2>Contact Support</h2>
        <div class="jox-contact-card">
            <p><strong>Email:</strong> <a href="mailto:support@joxmako.com">support@joxmako.com</a></p>
            <p><strong>Hours:</strong> Monday – Saturday, 8:00 AM – 8:00 PM (WAT)</p>
        </div>

        <h2>Frequently Asked Questions</h2>

        <h2>My order is late — what should I do?</h2>
        <p>
            Track your order in real time from the app. If the delay exceeds the estimated time, contact your delivery driver directly via the in-app chat, or write to our support team.
        </p>

        <h2>How do I cancel an order?</h2>
        <p>
            You can cancel your order from the "My Orders" section as long as it has not yet been accepted by the merchant.
        </p>

        <h2>I haven't received my refund</h2>
        <p>
            Refunds are processed within 3 to 7 business days depending on your payment method. If the deadline has passed, contact us with your order number.
        </p>

        <h2>How do I delete my account?</h2>
        <p>
            Go to Settings → My Account → Delete Account. This action is irreversible and will delete all your data in accordance with our privacy policy.
        </p>
    </div>

    <hr class="jox-divider">

    {{-- ─────────────── العربية ─────────────── --}}
    <div class="jox-lang-block jox-rtl">
        <span class="jox-lang-label">العربية</span>

        <h1>المساعدة والدعم</h1>
        <p class="jox-date">Joxmako — خدمة العملاء</p>

        <h2>كيف يمكننا مساعدتكم؟</h2>
        <p>
            فريق الدعم لدينا متاح للإجابة على جميع أسئلتكم المتعلقة باستخدام تطبيق Joxmako: الطلبات، التوصيل، المدفوعات، الحساب، أو أي مشكلة تقنية أخرى.
        </p>

        <h2>التواصل مع الدعم</h2>
        <div class="jox-contact-card">
            <p><strong>البريد الإلكتروني:</strong> <a href="mailto:support@joxmako.com">support@joxmako.com</a></p>
            <p><strong>ساعات العمل:</strong> الاثنين – السبت، من 08:00 إلى 20:00 (توقيت غرب أفريقيا)</p>
        </div>

        <h2>الأسئلة الشائعة</h2>

        <h2>طلبي متأخر، ماذا أفعل؟</h2>
        <p>
            تتبَّع طلبكم في الوقت الفعلي من خلال التطبيق. إذا تجاوز التأخير الوقت المقدَّر، تواصلوا مع عامل التوصيل مباشرةً عبر الدردشة المدمجة، أو تواصلوا مع فريق الدعم.
        </p>

        <h2>كيف أُلغي طلبًا؟</h2>
        <p>
            يمكنكم إلغاء الطلب من قسم "طلباتي" طالما لم يقبله التاجر بعد.
        </p>

        <h2>لم أستلم استرداد المبلغ</h2>
        <p>
            تُعالَج المبالغ المستردة خلال 3 إلى 7 أيام عمل حسب طريقة الدفع. إذا انقضت المدة، تواصلوا معنا مع ذكر رقم الطلب.
        </p>

        <h2>كيف أحذف حسابي؟</h2>
        <p>
            انتقلوا إلى الإعدادات ← حسابي ← حذف الحساب. هذا الإجراء لا رجعة فيه وسيؤدي إلى حذف جميع بياناتكم وفقًا لسياسة الخصوصية.
        </p>
    </div>

</div>

@include('layouts.footer')
