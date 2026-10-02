import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/quest.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/home_view_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/garden_scene.dart';
import '../../widgets/garden/level_card.dart';
import 'complete_flow.dart';
import 'daily_quest_dialog.dart';

/// 3. 홈 (정원)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeViewModelProvider);
    final weather = ref.watch(weatherProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: home.when(
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          loading: StateView.loading,
          error: (e, _) => StateView.error(e, onRetry: ref.read(homeViewModelProvider.notifier).retry),
          data: (state) => RefreshIndicator(
            onRefresh: () async {
              try {
                await ref.refresh(weatherProvider.future);
              } catch (_) {
                // 날씨를 못 불러와도 배지에 표시되므로 여기서는 넘긴다.
              }
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                _Header(streak: state.profile.streak, onBell: () => showDailyQuestDialog(context, state.todayQuests)),
                const SizedBox(height: 14),
                LevelCard(profile: state.profile, weather: weather),
                const SizedBox(height: 14),
                Semantics(
                  button: true,
                  label: '정원 크게 보기',
                  child: GestureDetector(
                    onTap: () => context.push(Routes.garden),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: 210,
                        child: GardenScene(weather: gardenWeatherOf(weather), quests: state.quests, plantScale: 0.85),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (state.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: StateView.empty(onAdd: () => context.push(Routes.questNew)),
                  )
                else
                  _TodayCard(state: state),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.streak, required this.onBell});

  final int streak;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF3E6CF),
            border: Border.all(color: Colors.white, width: 2),
            image: const DecorationImage(image: AssetImage(AppImages.avatar), fit: BoxFit.cover, alignment: Alignment(0, -0.6)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('안녕하세요!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text('오늘도 정원을 가꿔 볼까요?', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Semantics(
          label: '연속 실천 $streak일',
          child: Row(children: [
            const Icon(Icons.local_fire_department_rounded, color: AppColors.streak, size: 22),
            Text('$streak', style: const TextStyle(color: AppColors.streak, fontWeight: FontWeight.w700)),
          ]),
        ),
        IconButton(onPressed: onBell, tooltip: '알림', icon: const Icon(Icons.notifications_none_rounded)),
      ],
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.state});
  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quests = state.todayQuests;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text('오늘의 퀘스트', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
              Text('${state.doneCount}/${quests.length} 완료', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          for (final q in quests) QuestCheckRow(quest: q, onTap: () => runCompleteFlow(context, ref, q)),
        ],
      ),
    );
  }
}

class QuestCheckRow extends StatelessWidget {
  const QuestCheckRow({super.key, required this.quest, required this.onTap});

  final Quest quest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = quest.doneToday;
    return Semantics(
      checked: done,
      label: '${quest.title}, 보상 ${quest.xp} XP',
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.line))),
          child: ExcludeSemantics(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? AppColors.primary : Colors.white,
                    border: Border.all(color: done ? AppColors.primary : const Color(0xFFCBD3BF), width: 2),
                  ),
                  child: done ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(quest.title, style: TextStyle(fontSize: 15, color: done ? const Color(0xFF8C9387) : AppColors.text)),
                ),
                Text('+${quest.xp} XP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
