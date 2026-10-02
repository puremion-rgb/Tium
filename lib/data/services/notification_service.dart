import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 푸시 알림. Day 8에 FCM 구현(FirebaseMessaging의 topic 'daily-quest' 구독)으로 바꾼다.
abstract interface class NotificationService {
  /// 알림 권한 요청. 허용하면 true
  Future<bool> requestPermission();

  /// 아침 알림 켜기/끄기 = 'daily-quest' 토픽 구독/해제
  Future<void> setDailyQuestSubscription(bool on);
}

class FakeNotificationService implements NotificationService {
  bool subscribed = false;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> setDailyQuestSubscription(bool on) async {
    subscribed = on;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => FakeNotificationService());
