import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../utils/date_key.dart';
import 'garden_providers.dart';

class MonthRecord {
  const MonthRecord({
    required this.month,
    required this.doneDays,
    required this.completionRate,
    required this.byCategory,
    required this.totalCompletions,
  });

  /// 그 달의 1일
  final DateTime month;

  /// 하나 이상 완료한 날짜(일)
  final Set<int> doneDays;

  /// 지난 날 중 하나 이상 완료한 날의 비율 (0~1)
  final double completionRate;
  final Map<QuestCategory, int> byCategory;
  final int totalCompletions;
}

/// 기록 화면에서 보고 있는 달
class RecordsMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = nowKst();
    return DateTime(now.year, now.month);
  }

  void previous() => state = DateTime(state.year, state.month - 1);
  void next() {
    final now = nowKst();
    final candidate = DateTime(state.year, state.month + 1);
    if (!candidate.isAfter(DateTime(now.year, now.month))) state = candidate;
  }
}

final recordsMonthProvider = NotifierProvider<RecordsMonth, DateTime>(RecordsMonth.new);

final monthRecordProvider = Provider<AsyncValue<MonthRecord>>((ref) {
  final month = ref.watch(recordsMonthProvider);
  return ref.watch(completionsProvider).whenData((all) {
    final prefix = '${month.year}${month.month.toString().padLeft(2, '0')}';
    final inMonth = all.where((c) => c.dateKey.startsWith(prefix)).toList();
    final days = inMonth.map((c) => int.parse(c.dateKey.substring(6))).toSet();
    final byCat = {for (final c in QuestCategory.values) c: 0};
    for (final c in inMonth) {
      byCat[c.category] = byCat[c.category]! + 1;
    }
    final now = nowKst();
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final isCurrent = month.year == now.year && month.month == now.month;
    final elapsed = isCurrent ? now.day : lastDay;
    return MonthRecord(
      month: month,
      doneDays: days,
      completionRate: elapsed == 0 ? 0 : days.length / elapsed,
      byCategory: byCat,
      totalCompletions: inMonth.length,
    );
  });
});
