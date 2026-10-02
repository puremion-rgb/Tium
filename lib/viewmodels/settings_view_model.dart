import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../data/services/notification_service.dart';

/// MY 화면의 설정 변경
class SettingsViewModel {
  SettingsViewModel(this._ref);
  final Ref _ref;

  Future<void> setCity(String city) => _ref.read(gardenRepositoryProvider).updateSettings(city: city);

  Future<void> setMorningAlarm(bool on) async {
    await _ref.read(gardenRepositoryProvider).updateSettings(morningAlarm: on);
    await _ref.read(notificationServiceProvider).setDailyQuestSubscription(on);
  }
}

final settingsViewModelProvider = Provider<SettingsViewModel>(SettingsViewModel.new);
