import 'package:customer/lang/app_ar.dart';
import 'package:customer/lang/app_en.dart';
import 'package:customer/lang/app_wo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../lang/app_fr.dart';

class LocalizationService extends Translations {
  // Default locale
  static const locale = Locale('fr', 'FR');

  static final locales = [
    const Locale('fr', 'FR'),
    const Locale('en', 'US'),
    const Locale('ar', 'AR'),
    const Locale('wo', 'SN'),
  ];

  // Keys and their translations
  // Translations are separated maps in `lang` file
  @override
  Map<String, Map<String, String>> get keys => {
    'fr_FR': frFR,
    'en_US': enUS,
    'ar_AR': arAR,
    'wo_SN': woSN,
  };

  // Gets locale from language, and updates the locale
  void changeLocale(String lang) {
    Get.updateLocale(localeFromSlug(lang));
  }

  static Locale localeFromSlug(String? slug) {
    final normalized = (slug ?? '').trim().replaceAll('-', '_');
    switch (normalized) {
      case 'fr':
      case 'fr_FR':
        return const Locale('fr', 'FR');
      case 'en':
      case 'en_US':
        return const Locale('en', 'US');
      case 'ar':
      case 'ar_AR':
        return const Locale('ar', 'AR');
      case 'wo':
      case 'wo_SN':
        return const Locale('wo', 'SN');
      default:
        return locale;
    }
  }
}
