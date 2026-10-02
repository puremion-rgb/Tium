import '../utils/level.dart';
import 'category.dart';
import 'petal.dart';
import 'plant.dart';

/// Firestore: users/{uid}/quests/{questId}
class Quest {
  const Quest({
    required this.id,
    required this.title,
    required this.category,
    this.description = '',
    this.completionCount = 0,
    this.growth = 0,
    this.petalId,
    this.harvestCount = 0,
    this.active = true,
    this.doneToday = false,
    this.bookTitle,
    required this.createdAt,
    DateTime? plantedAt,
  }) : plantedAt = plantedAt ?? createdAt;

  final String id;
  final String title;
  final QuestCategory category;
  final String description;

  /// 지금까지 완료한 전체 횟수 (수확해도 줄지 않는다)
  final int completionCount;

  /// 지금 심어진 식물이 자란 정도 = 씨앗을 심은 뒤 완료한 횟수. 수확하면 0으로 돌아간다.
  final int growth;

  /// 지금 식물의 꽃잎 색 ID. 씨앗을 심을 때 랜덤으로 정한다.
  final String? petalId;

  /// 지금까지 수확한 횟수
  final int harvestCount;

  /// false면 '쉬는 중'. 오늘의 퀘스트에서 빠지지만 식물은 정원에 남는다.
  final bool active;

  /// 오늘 완료했는지. 저장하지 않고 completions 컬렉션에서 계산한다.
  final bool doneToday;

  /// 책에서 만든 독서 퀘스트일 때 책 제목
  final String? bookTitle;
  final DateTime createdAt;

  /// 지금 식물(씨앗)을 심은 날. 수확하면 그날로 바뀐다.
  final DateTime plantedAt;

  GrowthStage get stage => stageFor(growth);
  PlantKind get plant => category.plant;
  PetalColor get petal => PetalPalette.find(plant, petalId);
  bool get canHarvest => growth >= harvestAt;

  /// 완료할 때 받는 기본 XP (모든 퀘스트가 같다)
  int get xp => questXp;

  Quest copyWith({
    String? title,
    QuestCategory? category,
    String? description,
    int? completionCount,
    int? growth,
    String? petalId,
    int? harvestCount,
    bool? active,
    bool? doneToday,
    DateTime? plantedAt,
  }) =>
      Quest(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        description: description ?? this.description,
        completionCount: completionCount ?? this.completionCount,
        growth: growth ?? this.growth,
        petalId: petalId ?? this.petalId,
        harvestCount: harvestCount ?? this.harvestCount,
        active: active ?? this.active,
        doneToday: doneToday ?? this.doneToday,
        bookTitle: bookTitle,
        createdAt: createdAt,
        plantedAt: plantedAt ?? this.plantedAt,
      );

  Map<String, dynamic> toMap() => {
        'title': title,
        'category': category.name,
        'description': description,
        'completionCount': completionCount,
        'growth': growth,
        'petalId': petalId,
        'harvestCount': harvestCount,
        'active': active,
        'bookTitle': bookTitle,
        'createdAt': createdAt.toIso8601String(),
        'plantedAt': plantedAt.toIso8601String(),
      };

  factory Quest.fromMap(String id, Map<String, dynamic> map, {bool doneToday = false}) => Quest(
        id: id,
        title: map['title'] as String? ?? '',
        category: QuestCategory.fromName(map['category'] as String? ?? 'life'),
        description: map['description'] as String? ?? '',
        completionCount: (map['completionCount'] as num?)?.toInt() ?? 0,
        growth: (map['growth'] as num?)?.toInt() ?? 0,
        petalId: map['petalId'] as String?,
        harvestCount: (map['harvestCount'] as num?)?.toInt() ?? 0,
        active: map['active'] as bool? ?? true,
        bookTitle: map['bookTitle'] as String?,
        createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
        plantedAt: DateTime.tryParse(map['plantedAt']?.toString() ?? ''),
        doneToday: doneToday,
      );
}

/// 새 퀘스트를 만들 때 화면에서 넘기는 값
class QuestDraft {
  const QuestDraft({
    required this.title,
    required this.category,
    this.description = '',
    this.bookTitle,
  });

  final String title;
  final QuestCategory category;
  final String description;
  final String? bookTitle;
}
