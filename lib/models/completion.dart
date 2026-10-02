import '../utils/level.dart';
import 'category.dart';
import 'quest.dart';

/// Firestore: users/{uid}/completions/{questId_yyyyMMdd}
class Completion {
  const Completion({
    required this.questId,
    required this.questTitle,
    required this.category,
    required this.dateKey,
    required this.xp,
  });

  final String questId;
  final String questTitle;
  final QuestCategory category;
  final String dateKey;
  final int xp;

  String get id => '${questId}_$dateKey';

  Map<String, dynamic> toMap() => {
        'questId': questId,
        'questTitle': questTitle,
        'category': category.name,
        'dateKey': dateKey,
        'xp': xp,
      };

  factory Completion.fromMap(Map<String, dynamic> map) => Completion(
        questId: map['questId'] as String,
        questTitle: map['questTitle'] as String? ?? '',
        category: QuestCategory.fromName(map['category'] as String? ?? 'life'),
        dateKey: map['dateKey'] as String,
        xp: (map['xp'] as num?)?.toInt() ?? 0,
      );
}

/// 퀘스트 완료 버튼을 눌렀을 때의 결과. 완료 화면 → 레벨업 화면으로 넘긴다.
class CompletionResult {
  const CompletionResult({
    required this.quest,
    required this.before,
    required this.after,
    this.allClearBonus = 0,
    this.streakBonus = 0,
    this.streak = 0,
  });

  /// 완료 횟수가 반영된 퀘스트
  final Quest quest;
  final LevelInfo before;
  final LevelInfo after;

  /// 오늘 퀘스트를 모두 끝내서 받은 보너스 (0 또는 [allClearBonusXp])
  final int allClearBonus;

  /// 연속 실천 보너스 (0 또는 [streakBonusXp])
  final int streakBonus;

  /// 이번 완료까지 포함한 연속 실천 일수
  final int streak;

  int get baseXp => questXp;
  int get gainedXp => baseXp + allClearBonus + streakBonus;
  bool get leveledUp => after.level > before.level;
  bool get stageChanged => stageFor(quest.growth - 1) != quest.stage;

  /// 이번 완료로 막 다 자라서 수확할 수 있게 됐는지
  bool get justBloomed => quest.growth == harvestAt;
}

class AlreadyCompletedException implements Exception {
  const AlreadyCompletedException();
}
