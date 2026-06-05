import 'package:driver/lang/app_ar.dart';
import 'package:driver/lang/app_de.dart';
import 'package:driver/lang/app_en.dart';
import 'package:driver/lang/app_fr.dart';
import 'package:driver/lang/app_hi.dart';
import 'package:driver/lang/app_ja.dart';
import 'package:driver/lang/app_pt.dart';
import 'package:driver/lang/app_ru.dart';
import 'package:driver/lang/app_wo.dart';
import 'package:driver/lang/app_zh.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LocalizationService extends Translations {
  // Default locale
  static const locale = Locale('fr');

  static final locales = [
    const Locale('en'),
    const Locale('fr'),
    const Locale('zh'),
    const Locale('ja'),
    const Locale('hi'),
    const Locale('de'),
    const Locale('pt'),
    const Locale('ru'),
    const Locale('ar'),
    const Locale('wo', 'SN'),
  ];

  // Keys and their translations
  // Translations are separated maps in `lang` file
  @override
  Map<String, Map<String, String>> get keys => {
        'en': enUS,
        'fr': trFR,
        'zh': zhCH,
        'ja': jaJP,
        'hi': hiIN,
        'de': deGR,
        'pt': ptPO,
        'ru': ruRU,
        'ar': lnAr,
        'wo': woSN,
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
        return const Locale('fr');
      case 'en':
      case 'en_US':
        return const Locale('en');
      case 'zh':
      case 'zh_CN':
        return const Locale('zh');
      case 'ja':
      case 'ja_JP':
        return const Locale('ja');
      case 'hi':
      case 'hi_IN':
        return const Locale('hi');
      case 'de':
      case 'de_DE':
        return const Locale('de');
      case 'pt':
      case 'pt_PT':
        return const Locale('pt');
      case 'ru':
      case 'ru_RU':
        return const Locale('ru');
      case 'ar':
      case 'ar_AR':
        return const Locale('ar');
      case 'wo':
      case 'wo_SN':
        return const Locale('wo', 'SN');
      default:
        return locale;
    }
  }
}
