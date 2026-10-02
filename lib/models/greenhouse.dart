import 'petal.dart';
import 'plant.dart';
import 'quest.dart';

/// 온실에 담긴 꽃 하나. Firestore: users/{uid}/greenhouse/{itemId}
class GreenhouseItem {
  const GreenhouseItem({
    required this.id,
    required this.questId,
    required this.questTitle,
    required this.kind,
    required this.petalId,
    required this.plantedAt,
    required this.harvestedAt,
    required this.growth,
  });

  final String id;
  final String questId;

  /// 수확할 때의 퀘스트 제목 (나중에 제목을 바꿔도 기록은 그대로)
  final String questTitle;
  final PlantKind kind;
  final String petalId;
  final DateTime plantedAt;
  final DateTime harvestedAt;

  /// 수확할 때까지 완료한 횟수
  final int growth;

  PetalColor get petal => PetalPalette.find(kind, petalId);

  Map<String, dynamic> toMap() => {
        'questId': questId,
        'questTitle': questTitle,
        'kind': kind.name,
        'petalId': petalId,
        'plantedAt': plantedAt.toIso8601String(),
        'harvestedAt': harvestedAt.toIso8601String(),
        'growth': growth,
      };

  factory GreenhouseItem.fromMap(String id, Map<String, dynamic> map) => GreenhouseItem(
        id: id,
        questId: map['questId'] as String? ?? '',
        questTitle: map['questTitle'] as String? ?? '',
        kind: PlantKind.values.firstWhere((k) => k.name == map['kind'], orElse: () => PlantKind.tulip),
        petalId: map['petalId'] as String? ?? '',
        plantedAt: DateTime.tryParse(map['plantedAt']?.toString() ?? '') ?? DateTime.now(),
        harvestedAt: DateTime.tryParse(map['harvestedAt']?.toString() ?? '') ?? DateTime.now(),
        growth: (map['growth'] as num?)?.toInt() ?? 0,
      );
}

/// 수확 결과: 온실에 담긴 꽃 + 새 씨앗이 심어진 퀘스트
class HarvestResult {
  const HarvestResult({
    required this.item,
    required this.quest,
    required this.isNewColor,
    this.sameColorCount = 1,
    this.newBadge,
  });

  final GreenhouseItem item;
  final Quest quest;

  /// 도감에 처음 모은 색인지
  final bool isNewColor;

  /// 이번 수확까지 포함해 같은 꽃·같은 색을 몇 송이 모았는지
  final int sameColorCount;

  /// 이번 수확으로 새로 받은 배지 (없으면 null)
  final BadgeTier? newBadge;
}

/// 같은 꽃·같은 색을 여러 송이 모으면 받는 배지
enum BadgeTier {
  bouquet(3, '꽃다발', 0xFFE7B58C, 0xFFB97A4F), // 동
  basket(5, '꽃바구니', 0xFFEEF1F4, 0xFFAEB8C2), // 은
  field(10, '꽃밭', 0xFFFFE38A, 0xFFE8A92B); // 금

  const BadgeTier(this.count, this.label, this.light, this.dark);

  /// 이만큼 모으면 받는다
  final int count;
  final String label;
  final int light;
  final int dark;

  /// [count]송이를 모았을 때의 가장 높은 배지
  static BadgeTier? of(int count) {
    BadgeTier? best;
    for (final t in values) {
      if (count >= t.count) best = t;
    }
    return best;
  }

  /// 다음 배지 (이미 꽃밭이면 null)
  static BadgeTier? next(int count) {
    for (final t in values) {
      if (count < t.count) return t;
    }
    return null;
  }
}

/// 받은 배지 하나: 어떤 꽃·어떤 색을 몇 송이 모았는지
class ColorBadge {
  const ColorBadge({required this.kind, required this.petal, required this.count, required this.tier});
  final PlantKind kind;
  final PetalColor petal;
  final int count;
  final BadgeTier tier;
}

/// 도감: 꽃 종류별로 모은 색
class Collection {
  const Collection(this.items);
  final List<GreenhouseItem> items;

  /// 그 꽃에서 모은 색 ID (팔레트에 있는 색만)
  Set<String> colorsOf(PlantKind kind) {
    final valid = PetalPalette.of(kind).map((c) => c.id).toSet();
    return items.where((i) => i.kind == kind && valid.contains(i.petalId)).map((i) => i.petalId).toSet();
  }

  int get collected => PlantKind.values.fold(0, (sum, k) => sum + colorsOf(k).length);

  /// 같은 꽃·같은 색을 몇 송이 모았는지
  int countOf(PlantKind kind, String petalId) => items.where((i) => i.kind == kind && i.petalId == petalId).length;

  /// 받은 배지 전부 (높은 배지, 많이 모은 순)
  List<ColorBadge> get badges {
    final list = <ColorBadge>[];
    for (final kind in PlantKind.values) {
      for (final petal in PetalPalette.of(kind)) {
        final n = countOf(kind, petal.id);
        final tier = BadgeTier.of(n);
        if (tier != null) list.add(ColorBadge(kind: kind, petal: petal, count: n, tier: tier));
      }
    }
    list.sort((a, b) => b.tier.index != a.tier.index ? b.tier.index - a.tier.index : b.count - a.count);
    return list;
  }
  int get total => PlantKind.values.fold(0, (sum, k) => sum + PetalPalette.of(k).length);
}

class NotReadyToHarvestException implements Exception {
  const NotReadyToHarvestException();
}
