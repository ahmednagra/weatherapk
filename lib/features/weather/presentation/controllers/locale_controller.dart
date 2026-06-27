import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/di_providers.dart';

/// Holds the active [Locale]. Reads the persisted code synchronously from the
/// already-open Hive box on build, and persists on change.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.read(weatherLocalProvider).getLanguage();
    return Locale(code);
  }

  Future<void> setLanguage(String code) async {
    await ref.read(setLanguageProvider).call(code);
    state = Locale(code);
  }
}

final localeControllerProvider =
    NotifierProvider<LocaleController, Locale>(LocaleController.new);
