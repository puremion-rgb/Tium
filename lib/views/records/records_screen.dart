import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/category.dart';
import '../../models/plant.dart';
import '../../utils/date_key.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/records_view_model.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/state_view.dart';
import '../../widgets/garden/quest_plant.dart';

/// 13. 기록 — 달력 + 완료율 + 연속 실천 + 카테고리별로 자란 식물
class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final record = ref.watch(monthRecordProvider);
    final profile = ref.watch(profileProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: record.when(
          loading: StateView.loading,
          error: (e, _) => StateView.error(e, onRetry: () => ref.invalidate(completionsProvider)),
          data: (r) => ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Text('기록', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 14),
              _CalendarCard(record: r),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              value: r.completionRate,
                              strokeWidth: 6,
                              backgroundColor: AppColors.track,
                              color: const Color(0xFF43A047),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('이번 달 실천율', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              Text('${(r.completionRate * 100).round()}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('연속 실천', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('${profile?.streak ?? 0}일', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.streak)),
                          Text('최고 기록 ${profile?.bestStreak ?? 0}일', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _CategoryCard(record: r),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarCard extends ConsumerWidget {
  const _CalendarCard({required this.record});
  final MonthRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = record.month;
    final first = DateTime(m.year, m.month, 1);
    final days = DateTime(m.year, m.month + 1, 0).day;
    final lead = first.weekday % 7; // 일요일 시작
    final today = nowKst();
    final isThisMonth = today.year == m.year && today.month == m.month;
    final notifier = ref.read(recordsMonthProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(onPressed: notifier.previous, tooltip: '이전 달', icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: Text('${m.year}년 ${m.month}월', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              IconButton(
                onPressed: isThisMonth ? null : notifier.next,
                tooltip: '다음 달',
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.15,
            children: [
              for (final (i, d) in const ['일', '월', '화', '수', '목', '금', '토'].indexed)
                Center(
                  child: Text(d, style: TextStyle(fontSize: 12, color: i == 0 ? const Color(0xFFD9534F) : AppColors.textSecondary)),
                ),
              for (var i = 0; i < lead; i++) const SizedBox.shrink(),
              for (var d = 1; d <= days; d++)
                _DayCell(day: d, done: record.doneDays.contains(d), today: isThisMonth && today.day == d),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.done, required this.today});

  final int day;
  final bool done;
  final bool today;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$day일${done ? ', 실천함' : ''}${today ? ', 오늘' : ''}',
      child: ExcludeSemantics(
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? AppColors.primary : null,
              border: today ? Border.all(color: AppColors.primary, width: 2) : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(fontSize: 13, color: done ? Colors.white : AppColors.text, fontWeight: done ? FontWeight.w700 : FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.record});
  final MonthRecord record;

  @override
  Widget build(BuildContext context) {
    final max = record.byCategory.values.fold<int>(1, (a, b) => b > a ? b : a);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 자란 식물 · ${record.totalCompletions}번 물 줬어요', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          for (final c in QuestCategory.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  QuestPlant(kind: c.plant, stage: GrowthStage.adult, size: 28),
                  const SizedBox(width: 8),
                  SizedBox(width: 92, child: Text('${c.label} · ${c.plant.label}', style: const TextStyle(fontSize: 13))),
                  Expanded(child: XpBar(progress: record.byCategory[c]! / max, height: 8)),
                  SizedBox(
                    width: 28,
                    child: Text('${record.byCategory[c]}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
