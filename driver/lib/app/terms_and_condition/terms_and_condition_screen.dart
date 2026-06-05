import 'package:driver/constant/constant.dart';
import 'package:driver/widget/driver_app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TermsAndConditionScreen extends StatelessWidget {
  final String? type;

  const TermsAndConditionScreen({super.key, this.type});

  @override
  Widget build(BuildContext context) {
    final title = type == "privacy" ? "Privacy Policy" : "Terms and Conditions";
    return DriverAppShell(
      title: title,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Html(
          shrinkWrap: true,
          data: type == "privacy"
              ? Constant.privacyPolicy
              : Constant.termsAndConditions,
        ),
      ),
    );
  }
}
