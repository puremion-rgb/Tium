import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/garden_rules.dart';
import '../../models/greenhouse.dart';
import '../../models/petal.dart';
import '../../models/plant.dart';
import '../../models/quest.dart';
import '../../utils/korean.dart';
import '../../utils/level.dart';
import '../../viewmodels/quest_view_models.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/garden/quest_plant.dart';
import 'garden_full_dialog.dart';

/// 23. 퀘스트 상세 — 성장 단계 보기, 다 자라면 수확
class QuestDetailScreen extends ConsumerWidget {
  const QuestDetailScreen({super.key, required this.questId});
  final String questId;

  Future<void> _harvest(BuildContext context, WidgetRef ref, Quest quest) async {
    try {
      final result = await ref.read(questActionsProvider).harvest(quest.id);
      if (context.mounted) await context.push(Routes.harvest, extra: result);
    } on NotReadyToHarvestException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('아직 다 자라지 않았어요')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('수확하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quest = ref.watch(questByIdProvider(questId));
    return Scaffold(
      appBar: AppBar(title: const Text('퀘스트 상세')),
      body: quest == null
          ? const Center(child: Text('퀘스트를 찾을 수 없어요'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
              children: [
                _InfoCard(quest: quest),
                const SizedBox(height: 14),
                _GrowthCard(quest: quest),
                const SizedBox(height: 22),
                if (quest.canHarvest) ...[
                  FilledButton.icon(
                    onPressed: () => _harvest(context, ref, quest),
                    icon: const Icon(Icons.local_florist_rounded),
                    label: Text('${quest.petal.name} ${quest.plant.label} 수확하기'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: () => context.push(Routes.questEdit(quest.id)), child: const Text('수정하기')),
                ] else
                  FilledButton(onPressed: () => context.push(Routes.questEdit(quest.id)), child: const Text('수정하기')),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () async {
                    // 다시 시작하려면 화단에 빈자리가 있어야 한다.
                    if (!quest.active && isGardenFull(ref)) {
                      await showGardenFullDialog(context);
                      return;
                    }
                    try {
                      await ref.read(questActionsProvider).setActive(quest.id, active: !quest.active);
                    } on GardenFullException {
                      if (context.mounted) await showGardenFullDialog(context);
                      return;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(quest.active ? '퀘스트를 쉬어요. 식물은 화단에서 잠시 빠지고, 자란 정도는 그대로예요' : '퀘스트를 다시 시작해요. 식물이 화단으로 돌아왔어요'),
                      ));
                    }
                  },
                  child: Text(
                    quest.active ? '퀘스트 쉬기 (화단에서 잠시 빠져요)' : '퀘스트 다시 시작하기',
                    style: const TextStyle(color: Color(0xFF8C9387), decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.quest});
  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final c = quest.category;
    Widget row(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(children: [
            Text(k, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            Text(v, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
          ]),
        );
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconTile(icon: c.icon, background: c.tileColor, color: c.iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quest.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    Text('${c.label} · ${c.plant.label}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          if (quest.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(alignment: Alignment.centerLeft, child: Text(quest.description, style: const TextStyle(height: 1.5))),
            ),
          const Padding(padding: EdgeInsets.only(top: 12), child: Divider(height: 1, color: AppColors.line)),
          row('보상 XP', '+${quest.xp}', color: AppColors.primary),
          row('전체 완료 횟수', '${quest.completionCount}회'),
          row('꽃 색', _petalText(quest)),
          if (quest.harvestCount > 0) row('온실에 담은 꽃', '${quest.harvestCount}송이'),
          if (quest.bookTitle != null) row('책', quest.bookTitle!),
        ],
      ),
    );
  }
}

String _petalText(Quest q) => switch (q.stage) {
      GrowthStage.seed || GrowthStage.sprout => '꽃이 피면 알 수 있어요',
      GrowthStage.young => '${q.petal.name} (봉오리)${q.petal.rare ? ' · 희귀' : ''}',
      GrowthStage.adult => '${q.petal.name}${q.petal.rare ? ' · 희귀' : ''}',
    };

class _GrowthCard extends StatelessWidget {
  const _GrowthCard({required this.quest});
  final Quest quest;

  @override
  Widget build(BuildContext context) {
    final current = quest.stage.index;
    final next = nextStageAt(quest.growth);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('성장 단계', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              Text('${quest.growth} / $harvestAt', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Positioned(
                left: 36,
                right: 36,
                top: 33,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: current / 3,
                    minHeight: 6,
                    backgroundColor: AppColors.track,
                    color: const Color(0xFF7CC36A),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final s in GrowthStage.values)
                    Expanded(
                      child: _StageDot(
                        kind: quest.plant,
                        stage: s,
                        state: s.index.compareTo(current),
                        // 아직 안 온 단계는 색을 숨긴다 (꽃이 필 때까지 비밀)
                        petal: s.index <= current ? quest.petal : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              next == null
                  ? '다 자랐어요! 수확해서 온실에 담아 보세요'
                  : '${next - quest.growth}번 더 하면 ${withRo(GrowthStage.values[current + 1].label)} 자라요',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.kind, required this.stage, required this.state, this.petal});

  final PlantKind kind;
  final GrowthStage stage;
  final PetalColor? petal;

  /// -1 지난 단계, 0 현재, 1 아직
  final int state;

  @override
  Widget build(BuildContext context) {
    final isCurrent = state == 0;
    return Column(
      children: [
        Opacity(
          opacity: state > 0 ? 0.45 : 1,
          child: Container(
            width: 70,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCurrent ? const Color(0xFFE3F2D2) : const Color(0xFFF6F4EC),
              border: isCurrent ? Border.all(color: AppColors.accent, width: 3) : null,
            ),
            child: state > 0
                // 아직 안 온 단계는 회색으로 (색은 꽃이 필 때 공개)
                ? ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: QuestPlant(kind: kind, stage: stage, size: 54))
                : QuestPlant(kind: kind, stage: stage, petal: petal, size: 54),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
            color: isCurrent ? AppColors.primaryDark : const Color(0xFF8C9387),
          ),
        ),
        Text(stage.rule, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

const _greyscale = <double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];
