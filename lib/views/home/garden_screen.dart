import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../models/weather.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/home_view_model.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/garden_scene.dart';
import '../../widgets/garden/level_card.dart';

/// 9~12. 정원 전체 보기 (맑음 · 비 · 눈 · 밤 + 흐림)
class GardenScreen extends ConsumerWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeViewModelProvider);
    final weather = ref.watch(weatherProvider);
    final preview = ref.watch(weatherPreviewProvider);

    return Scaffold(
      body: home.when(
        skipLoadingOnReload: true,
        loading: StateView.loading,
        error: (e, _) => StateView.error(e, onRetry: ref.read(homeViewModelProvider.notifier).retry),
        data: (state) => Stack(
          fit: StackFit.expand,
          children: [
            GardenScene(
              weather: gardenWeatherOf(weather),
              quests: state.todayQuests,
              backgroundAlignment: const Alignment(0, 0.2),
              plantScale: 1.15,
              soilDepth: 0.2,
              // 아래 버튼 줄(44px + 여백)이 화단 앞판 위에 올라가도록
              panelHeight: 72 + MediaQuery.paddingOf(context).bottom,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                child: Column(
                  children: [
                    LevelCard(profile: state.profile, weather: weather, translucent: true),
                    const SizedBox(height: 10),
                    // 발표·디자인 확인용 날씨 미리보기
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _PreviewChip(label: '실제 날씨', selected: preview == null, onTap: () => ref.read(weatherPreviewProvider.notifier).state = null),
                          for (final k in WeatherKind.values)
                            _PreviewChip(label: k.label, selected: preview == k, onTap: () => ref.read(weatherPreviewProvider.notifier).state = k),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.92),
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onPressed: () => context.pop(),
                          child: const Text('홈으로'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.92),
                            foregroundColor: AppColors.primaryDark,
                            minimumSize: const Size(0, 44),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          onPressed: () => context.push(Routes.greenhouse),
                          icon: const Icon(Icons.local_florist_rounded, size: 18),
                          label: const Text('온실'),
                        ),
                        const Spacer(),
                        _TodayProgress(done: state.doneCount, total: state.todayQuests.length),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.white.withValues(alpha: 0.85),
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.text, fontWeight: FontWeight.w600, fontSize: 12),
        showCheckmark: false,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// 오늘의 진행 — '홈으로'·'온실' 버튼과 같은 흰색 알약 모양.
/// 왼쪽 작은 원이 진행 바 역할을 한다 (예: ◔ 오늘 3/5).
class _TodayProgress extends StatelessWidget {
  const _TodayProgress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final allDone = total > 0 && done >= total;
    return Semantics(
      label: total == 0 ? '오늘 할 퀘스트가 없어요' : '오늘의 퀘스트 $total개 중 $done개 완료',
      excludeSemantics: true,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(99)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allDone)
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary)
            else
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  strokeWidth: 3,
                  backgroundColor: AppColors.track,
                  color: AppColors.primary,
                  strokeCap: StrokeCap.round,
                ),
              ),
            const SizedBox(width: 8),
            Text(
              total == 0 ? '오늘 퀘스트 없음' : (allDone ? '오늘 모두 완료' : '오늘 $done/$total'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
            ),
          ],
        ),
      ),
    );
  }
}
