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
              quests: state.quests,
              backgroundAlignment: const Alignment(0, 0.2),
              plantScale: 1.15,
              lift: 0.17,
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    LevelCard(profile: state.profile, weather: weather, translucent: true),
                    const Spacer(),
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
                    const SizedBox(height: 12),
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(99)),
                          child: Text(
                            '식물 ${state.quests.length}그루',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primaryDark),
                          ),
                        ),
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
