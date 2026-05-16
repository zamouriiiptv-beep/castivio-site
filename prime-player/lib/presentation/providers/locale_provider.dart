import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/storage_service.dart';
import 'playlist_provider.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, String>((ref) {
  final storage = ref.read(storageServiceProvider);
  return LocaleNotifier(storage);
});

class LocaleNotifier extends StateNotifier<String> {
  final StorageService _storage;
  LocaleNotifier(this._storage) : super(_storage.appLanguage);

  void setLocale(String code) {
    state = code;
    _storage.setAppLanguage(code);
  }
}
