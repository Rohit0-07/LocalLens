import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_providers.dart';

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

class AppLocaleController extends Notifier<Locale> {
  static const _storageKey = 'app_locale';

  static const supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('mr'),
    Locale('ta'),
    Locale('te'),
  ];

  static const languageNames = {
    'en': 'English',
    'hi': 'Hindi (हिंदी)',
    'mr': 'Marathi (मराठी)',
    'ta': 'Tamil (தமிழ்)',
    'te': 'Telugu (తెలుగు)',
  };

  @override
  Locale build() {
    final store = ref.watch(localStoreProvider);
    final saved = store.getString(_storageKey);
    if (saved != null) {
      for (final locale in supportedLocales) {
        if (locale.languageCode == saved) {
          return locale;
        }
      }
    }
    return const Locale('en');
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await ref.read(localStoreProvider).setString(_storageKey, locale.languageCode);
  }
}
