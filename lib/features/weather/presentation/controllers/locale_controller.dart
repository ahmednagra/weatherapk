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

/// Holds the active crop id (drives [FarmDecisions] thresholds). Reads the
/// persisted id synchronously on build and persists on change.
class CropController extends Notifier<String> {
  @override
  String build() => ref.read(weatherLocalProvider).getCrop();

  Future<void> setCrop(String id) async {
    await ref.read(weatherLocalProvider).saveCrop(id);
    state = id;
  }
}

final cropControllerProvider =
    NotifierProvider<CropController, String>(CropController.new);
