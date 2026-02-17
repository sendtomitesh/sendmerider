import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// JSON-based localization system that loads translations from
/// `assets/i18n/{locale}.json` files.
class AppLocalizations {
  final Locale locale;
  late final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale);

  /// Convenience accessor from any widget tree context.
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// Supported locales for the rider app.
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
    Locale('hi'),
    Locale('fr'),
  ];

  /// Loads the JSON translation file for [locale] and populates
  /// the internal lookup map.
  Future<bool> load() async {
    final String jsonString = await rootBundle.loadString(
      'assets/i18n/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap =
        json.decode(jsonString) as Map<String, dynamic>;
    _localizedStrings = jsonMap.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    return true;
  }

  /// Returns the translated string for [key], or `null` if not found.
  String? translate(String key) => _localizedStrings[key];
}

/// Delegate that tells Flutter how to create and load [AppLocalizations].
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .map((l) => l.languageCode)
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
