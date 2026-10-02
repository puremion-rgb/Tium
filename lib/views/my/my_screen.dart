import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';

/// 14. MY
class MyScreen extends ConsumerWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final questCount = ref.watch(questsProvider).valueOrNull?.length ?? 0;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: profile.when(
          loading: StateView.loading,
          error: (e, _) => StateView.error(e, onRetry: () => ref.invalidate(profileProvider)),
          data: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Text('MY', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              AppCard(
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: Color(0xFFF3E6CF),
                      backgroundImage: AssetImage(AppImages.avatar),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nickname, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Lv.${p.level.level} ${p.level.title} · 누적 ${p.totalXp} XP', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          XpBar(progress: p.level.progress, height: 7),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Column(
                  children: [
                    _MenuTile(
                      icon: Icons.eco_outlined,
                      title: '내 정원',
                      trailing: Text('식물 $questCount그루', style: const TextStyle(color: AppColors.textSecondary)),
                      onTap: () => context.push(Routes.garden),
                    ),
                    _MenuTile(
                      icon: Icons.local_florist_outlined,
                      title: '나의 온실',
                      trailing: Text('꽃 ${ref.watch(greenhouseProvider).valueOrNull?.length ?? 0}송이', style: const TextStyle(color: AppColors.textSecondary)),
                      onTap: () => context.push(Routes.greenhouse),
                    ),
                    _MenuTile(icon: Icons.pie_chart_outline_rounded, title: '퀘스트 통계', onTap: () => context.go(Routes.records)),
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_none_rounded, color: Color(0xFF5D6B58)),
                      title: const Text('아침 알림', style: TextStyle(fontSize: 15)),
                      subtitle: const Text('매일 오전 9시', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      value: p.morningAlarm,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => ref.read(settingsViewModelProvider).setMorningAlarm(v),
                    ),
                    _MenuTile(
                      icon: Icons.place_outlined,
                      title: '도시 설정',
                      trailing: Text(p.city, style: const TextStyle(color: AppColors.textSecondary)),
                      onTap: () => context.push(Routes.city),
                    ),
                    _MenuTile(
                      icon: Icons.settings_outlined,
                      title: '계정 관리',
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('지금은 이 기기에만 저장되는 익명 계정이에요')),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Image.asset(AppImages.characterReading, width: 280, excludeFromSemantics: true)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, this.trailing, this.onTap});

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5D6B58)),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) trailing!,
          const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
        ],
      ),
      onTap: onTap,
    );
  }
}
