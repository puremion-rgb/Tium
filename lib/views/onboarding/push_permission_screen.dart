import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/services/notification_service.dart';
import '../../viewmodels/settings_view_model.dart';

/// 16. 알림 권한 안내 (FCM 과제 요구 사항)
class PushPermissionScreen extends ConsumerWidget {
  const PushPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> allow() async {
      final granted = await ref.read(notificationServiceProvider).requestPermission();
      await ref.read(settingsViewModelProvider).setMorningAlarm(granted);
      if (context.mounted) context.go(Routes.home);
    }

    Future<void> later() async {
      await ref.read(settingsViewModelProvider).setMorningAlarm(false);
      if (context.mounted) context.go(Routes.home);
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Flexible(flex: 6, child: Image.asset(AppImages.characterReading, width: 280, excludeFromSemantics: true)),
              const SizedBox(height: 20),
              Text('아침마다 퀘스트를\n알려 드릴까요?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              const Text(
                '매일 오전 9시에 오늘의 퀘스트 알림을 보내요.\nMY에서 언제든 끌 수 있어요.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const Spacer(),
              FilledButton(onPressed: allow, child: const Text('알림 받기')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: later, child: const Text('나중에')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
