import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/category.dart';
import '../../models/quest.dart';
import '../../utils/level.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/quest_view_models.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/quest_plant.dart';

/// 4. 퀘스트 목록
class QuestListScreen extends ConsumerWidget {
  const QuestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(questFilterProvider);
    final quests = ref.watch(filteredQuestsProvider);

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
                    onPressed: () => context.push(Routes.questNew),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('퀘스트 추가'),
                  ),
                ],
              ),
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
                      ? StateView.empty(onAdd: () => context.push(Routes.questNew))
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
