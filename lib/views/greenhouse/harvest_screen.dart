import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/greenhouse.dart';
import '../../models/plant.dart';
import '../../widgets/garden/quest_plant.dart';
import '../../widgets/greenhouse/collect_marks.dart';

/// 수확 완료: 온실에 담긴 꽃을 보여 주고 새 씨앗이 심어졌다고 알린다.
class HarvestScreen extends StatefulWidget {
  const HarvestScreen({super.key, required this.result});
  final HarvestResult result;

  @override
  State<HarvestScreen> createState() => _HarvestScreenState();
}

class _HarvestScreenState extends State<HarvestScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
  late final _pop = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

  @override
  void dispose() {
    _pop.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.result.item;
    final petal = item.petal;
    final days = item.harvestedAt.difference(item.plantedAt).inDays + 1;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text('수확했어요!', style: TextStyle(fontFamily: displayFont, fontSize: 40, color: AppColors.primaryDark)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  if (petal.rare) const RarePill(label: '희귀한 색', large: true),
                  if (widget.result.isNewColor) const _Tag(label: '도감에 새로 등록', color: AppColors.primary),
                  if (widget.result.sameColorCount >= 2 && widget.result.newBadge == null)
                    _Tag(label: '같은 색 ${widget.result.sameColorCount}송이째', color: const Color(0xFF5D6B58)),
                ],
              ),
              if (widget.result.newBadge case final badge?) ...[
                const SizedBox(height: 14),
                _NewBadge(item: item, tier: badge, count: widget.result.sameColorCount),
              ],
              Expanded(
                // 화면이 작거나 배지 안내가 붙어도 넘치지 않게 줄여서 맞춘다.
                child: FittedBox(
                  child: Container(
                    width: 260,
                    height: 260,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(petal.mainArgb).withValues(alpha: 0.35), Color(petal.mainArgb).withValues(alpha: 0)],
                      ),
                    ),
                    child: ScaleTransition(
                      scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _pop,
                      child: QuestPlant(kind: item.kind, stage: GrowthStage.adult, petal: petal, size: 200),
                    ),
                  ),
                ),
              ),
              Text('${petal.name} ${item.kind.label}', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '‘${item.questTitle}’ 퀘스트를 $days일 동안 ${item.growth}번 해서 피운 꽃이에요.\n온실에 담고, 같은 자리에 새 씨앗을 심었어요.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 6),
              const Text('이번 씨앗은 어떤 색으로 필지 몰라요', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.pushReplacement(Routes.greenhouse), child: const Text('온실 보러 가기')),
              const SizedBox(height: 10),
              OutlinedButton(onPressed: () => context.pop(), child: const Text('확인')),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 이번 수확으로 받은 배지
class _NewBadge extends StatelessWidget {
  const _NewBadge({required this.item, required this.tier, required this.count});
  final GreenhouseItem item;
  final BadgeTier tier;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 18, 10),
      decoration: BoxDecoration(
        color: Color(tier.light).withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(tier.dark).withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BadgeMedal(kind: item.kind, petal: item.petal, tier: tier, size: 48),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tier.label} 배지를 받았어요!', style: TextStyle(fontWeight: FontWeight.w800, color: Color(tier.dark))),
              Text('${item.petal.name} ${item.kind.label} $count송이', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}
