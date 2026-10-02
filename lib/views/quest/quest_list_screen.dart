import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/category.dart';
import '../../models/garden_rules.dart';
import '../../models/quest.dart';
import '../../utils/level.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/quest_view_models.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/quest_plant.dart';
import 'garden_full_dialog.dart';

/// 4. 퀘스트 목록
class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(questFilterProvider);
    final quests = ref.watch(filteredQuestsProvider);
    final all = ref.watch(questsProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('퀘스트', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Pretendard'),
                    ),
                    onPressed: () => openNewQuest(context, ref),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('퀘스트 추가'),
                  ),
                ],
              ),
              if (all != null && all.isNotEmpty) ...[
                const SizedBox(height: 14),
                _GardenCapacityCard(
                  active: all.where((q) => q.active).length,
                  paused: all.where((q) => !q.active).length,
                ),
              ],
              const SizedBox(height: 14),
              ChoiceChipRow<QuestCategory?>(
                items: const [null, ...QuestCategory.values],
                selected: filter,
                labelOf: (c) => c?.label ?? '전체',
                onSelected: (c) => ref.read(questFilterProvider.notifier).state = c,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: quests.when(
                  loading: StateView.loading,
                  error: (e, _) => StateView.error(e, onRetry: () => ref.invalidate(questsProvider)),
                  data: (list) => list.isEmpty
                      ? StateView.empty(onAdd: () => openNewQuest(context, ref))
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (_, i) => QuestCard(quest: list[i]),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestCard extends StatelessWidget {
  const QuestCard({super.key, required this.quest});
  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final c = quest.category;
    return Opacity(
      opacity: quest.active ? 1 : 0.55,
      child: AppCard(
        padding: const EdgeInsets.all(14),
        onTap: () => context.push(Routes.questDetail(quest.id)),
        child: Row(
          children: [
            IconTile(icon: c.icon, background: c.tileColor, color: c.iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(quest.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ),
                      Text('+${quest.xp} XP', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: XpBar(progress: quest.growth / harvestAt, height: 7)),
                      const SizedBox(width: 8),
                      Text(
                        !quest.active
                            ? '쉬는 중'
                            : quest.canHarvest
                                ? '수확할 수 있어요'
                                : '${quest.stage.label} · ${quest.growth}/$harvestAt',
                        style: TextStyle(
                          fontSize: 12,
                          color: quest.canHarvest && quest.active ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: quest.canHarvest ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            QuestPlant.forQuest(quest, size: 40),
          ],
        ),
      ),
    );
  }
}

/// 현재 퀘스트 5 / 8 — 화단 자리가 몇 개 남았는지 보여 준다.
class _GardenCapacityCard extends StatelessWidget {
  const _GardenCapacityCard({required this.active, required this.paused});

  final int active;
  final int paused;

  @override
  Widget build(BuildContext context) {
    final left = maxActiveQuests - active;
    final full = left <= 0;
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('현재 퀘스트', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
              const Spacer(),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: '$active',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: full ? const Color(0xFFE08A1E) : AppColors.primary),
                  ),
                  const TextSpan(
                    text: ' / $maxActiveQuests',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  ),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GardenSlots(filled: active, size: 26),
          const SizedBox(height: 10),
          Text(
            full
                ? '정원이 가득 찼어요 · 수확하거나 쉬게 하면 자리가 생겨요'
                : '화단에 $left자리 더 심을 수 있어요${paused > 0 ? ' · 쉬는 중 $paused개' : ''}',
            style: TextStyle(fontSize: 12, color: full ? const Color(0xFFB06A10) : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
