/// 한국 시간(UTC+9) 기준 날짜 키. 기기 시간대와 상관없이 같은 날을 같은 키로 만든다.
DateTime nowKst([DateTime? now]) => (now ?? DateTime.now()).toUtc().add(const Duration(hours: 9));

String dateKey([DateTime? now]) {
  final d = nowKst(now);
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}$m$day';
}

/// completions 문서 ID: {questId}_{yyyyMMdd}
String completionId(String questId, [DateTime? now]) => '${questId}_${dateKey(now)}';
