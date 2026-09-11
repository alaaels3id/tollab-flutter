import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/settings_repository.dart';
import '../models/settings_model.dart';
import '../../../core/notifications/notification_service.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

class SettingsNotifier extends StateNotifier<AsyncValue<AppSettings>> {
  final SettingsRepository _repository;

  SettingsNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _repository.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    await _repository.updateSettings(settings);
    state = AsyncValue.data(settings);
  }

  Future<NotificationEvaluationResult> testNotifications() async {
    return await NotificationService.instance.evaluateNotifications();
  }

  Future<void> sendTestNotification() async {
    await NotificationService.instance.sendTestNotification();
  }

  Future<String> exportBackup() async {
    return await _repository.exportDatabaseBackup();
  }

  Future<bool> restoreBackup(String path) async {
    final success = await _repository.restoreDatabase(path);
    if (success) {
      await loadSettings();
    }
    return success;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<AppSettings>>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsNotifier(repo);
});
