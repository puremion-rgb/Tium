import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/greenhouse.dart';
import '../../models/petal.dart';
import '../../models/plant.dart';
import '../../utils/level.dart';
import '../../viewmodels/garden_providers.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/quest_plant.dart';
import '../../widgets/greenhouse/collect_marks.dart';

/// 온실에서 보고 있는 꽃 종류. null = 전체
final _kindFilterProvider = StateProvider.autoDispose<PlantKind?>((ref) => null);

const _glass = Color(0xFFF1F6EA);
const _wood = Color(0xFFC79A6B);

/// 나의 온실 — 색 도감 + 배지 + 수확한 꽃 진열장
class GreenhouseScreen extends ConsumerWidget {
  const GreenhouseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(greenhouseProvider);
    final filter = ref.watch(_kindFilterProvider);

    return Scaffold(
      backgroundColor: _glass,
      appBar: AppBar(title: const Text('나의 온실'), backgroundColor: _glass),
      body: items.when(
        loading: StateView.loading,
        error: (e, _) => StateView.error(e, onRetry: () => ref.invalidate(greenhouseProvider)),
        data: (list) {
          if (list.isEmpty) {
            return const StateView(
              illustration: QuestPlant(kind: PlantKind.tulip, stage: GrowthStage.seed, size: 84),
              title: '아직 수확한 꽃이 없어요',
              message: '퀘스트를 $harvestAt번 완료하면 꽃이 피고,\n수확해서 여기에 모을 수 있어요',
            );
          }
          final collection = Collection(list);
          final shown = filter == null ? list : list.where((i) => i.kind == filter).toList();
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                sliver: SliverList.list(children: [
                  _DexCard(collection: collection),
                  const SizedBox(height: 12),
                  _BadgeCard(collection: collection),
                  const SizedBox(height: 16),
                  ChoiceChipRow<PlantKind?>(
                    items: const [null, ...PlantKind.values],
                    selected: filter,
                    labelOf: (k) => k == null ? '전체 ${list.length}' : '${k.label} ${list.where((i) => i.kind == k).length}',
                    onSelected: (k) => ref.read(_kindFilterProvider.notifier).state = k,
                  ),
                  const SizedBox(height: 14),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: shown.length,
                  itemBuilder: (_, i) => _ShelfCell(item: shown[i], collection: collection),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------- 색 도감 ----------------

class _DexCard extends StatelessWidget {
  const _DexCard({required this.collection});
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _Stat(label: '모은 꽃', value: '${collection.items.length}송이')),
              Expanded(child: _Stat(label: '색 도감', value: '${collection.collected} / ${collection.total}', color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 10),
          XpBar(progress: collection.collected / collection.total, height: 8),
          const SizedBox(height: 14),
          for (final kind in PlantKind.values) _DexRow(kind: kind, collection: collection),
          const SizedBox(height: 4),
          const Row(
            children: [
              RarePill(),
              SizedBox(width: 6),
              Expanded(child: Text('희귀 색은 12% 확률로 피어요', style: TextStyle(fontSize: 11, color: AppColors.textSecondary))),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        ],
      );
}

class _DexRow extends StatelessWidget {
  const _DexRow({required this.kind, required this.collection});
  final PlantKind kind;
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final colors = PetalPalette.of(kind);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          QuestPlant(kind: kind, stage: GrowthStage.adult, size: 26),
          const SizedBox(width: 6),
          SizedBox(width: 52, child: Text(kind.label, style: const TextStyle(fontSize: 13))),
          for (final c in colors) ...[
            PetalDot(petal: c, count: collection.countOf(kind, c.id), size: 24),
            const SizedBox(width: 2),
          ],
          const Spacer(),
          Text('${collection.colorsOf(kind).length}/${colors.length}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

// ---------------- 배지 ----------------

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.collection});
  final Collection collection;

  @override
  Widget build(BuildContext context) {
    final badges = collection.badges;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('같은 색 모음 배지', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              Text('${badges.length}개', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '같은 꽃·같은 색을 ${BadgeTier.values.map((t) => '${t.count}송이 ${t.label}').join(' · ')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          if (badges.isEmpty)
            const _BadgeHint()
          else
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                for (final b in badges)
                  SizedBox(
                    width: 84,
                    child: Column(
                      children: [
                        BadgeMedal(kind: b.kind, petal: b.petal, tier: b.tier, count: b.count, size: 62),
                        const SizedBox(height: 6),
                        Text('${b.petal.name} ${b.kind.label}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(b.tier.label, style: TextStyle(fontSize: 11, color: Color(b.tier.dark), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BadgeHint extends StatelessWidget {
  const _BadgeHint();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final t in BadgeTier.values) ...[
          Opacity(
            opacity: 0.35,
            child: BadgeMedal(kind: PlantKind.tulip, petal: PetalPalette.of(PlantKind.tulip).first, tier: t, size: 40),
          ),
          const SizedBox(width: 8),
        ],
        const Expanded(child: Text('아직 받은 배지가 없어요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      ],
    );
  }
}

// ---------------- 진열장 ----------------

/// 선반 한 칸: 꽃 + 나무 선반 + 이름표
class _ShelfCell extends StatelessWidget {
  const _ShelfCell({required this.item, required this.collection});
  final GreenhouseItem item;
  final Collection collection;

  String _d(DateTime d) => '${d.month}.${d.day}';

  @override
  Widget build(BuildContext context) {
    final petal = item.petal;
    return Semantics(
      button: true,
      label: '${petal.name} ${item.kind.label}${petal.rare ? ', 희귀' : ''}, ${item.questTitle}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: ExcludeSemantics(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  clipBehavior: Clip.none,
                  children: [
                    if (petal.rare)
                      // 희귀 꽃 뒤에 은은한 빛
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: const Alignment(0, -0.1),
                              radius: 0.7,
                              colors: [Color(petal.mainArgb).withValues(alpha: 0.32), Color(petal.mainArgb).withValues(alpha: 0)],
                            ),
                          ),
                        ),
                      ),
                    QuestPlant(kind: item.kind, stage: GrowthStage.adult, petal: petal, size: 96),
                    if (petal.rare) const Positioned(top: 2, left: 0, child: RarePill()),
                  ],
                ),
              ),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: _wood,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 3)],
                ),
              ),
              const SizedBox(height: 8),
              Text('${petal.name} ${item.kind.label}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.questTitle, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${_d(item.plantedAt)} ~ ${_d(item.harvestedAt)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final petal = item.petal;
    final days = item.harvestedAt.difference(item.plantedAt).inDays + 1;
    final same = collection.countOf(item.kind, item.petalId);
    final tier = BadgeTier.of(same);
    final next = BadgeTier.next(same);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QuestPlant(kind: item.kind, stage: GrowthStage.adult, petal: petal, size: 140),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${petal.name} ${item.kind.label}', style: Theme.of(context).textTheme.titleLarge),
                  if (petal.rare) ...[const SizedBox(width: 8), const RarePill(large: true)],
                ],
              ),
              const SizedBox(height: 4),
              Text(item.questTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${item.plantedAt.year}.${_d(item.plantedAt)} ~ ${_d(item.harvestedAt)} · $days일 동안 ${item.growth}번',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    if (tier != null) ...[
                      BadgeMedal(kind: item.kind, petal: petal, tier: tier, size: 40),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: Text(
                        [
                          '같은 색을 $same송이 모았어요',
                          if (next != null) '${next.label} 배지까지 ${next.count - same}송이',
                        ].join('\n'),
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: () => Navigator.pop(context), child: const Text('닫기')),
            ],
          ),
        ),
      ),
    );
  }
}
