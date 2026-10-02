import '../models/plant.dart';

// ---------- XP 규칙 ----------
// 사용자가 XP를 고르지 않는다. 많이 고르는 것보다 매일 하는 쪽이 이득이 되도록 한다.
// 값이 고정이라 Firestore 보안 규칙에서도 검사할 수 있다.

/// 퀘스트 하나를 완료할 때마다
const questXp = 10;

/// 그날 활성 퀘스트를 모두 끝냈을 때 한 번
const allClearBonusXp = 10;

/// 연속 실천 [streakBonusEvery]일마다 한 번
const streakBonusXp = 30;
const streakBonusEvery = 7;

/// 레벨 L에 도달하는 데 필요한 누적 XP. T(L) = 25(L−1)(L+2)
/// Lv1 = 0, Lv2 = 100, Lv3 = 250, Lv4 = 450, Lv5 = 700 ...
int xpForLevel(int level) => 25 * (level - 1) * (level + 2);

class LevelInfo {
  const LevelInfo({required this.level, required this.xpInLevel, required this.xpToNext});

  final int level;

  /// 현재 레벨 안에서 모은 XP
  final int xpInLevel;

  /// 다음 레벨까지 이번 레벨에서 필요한 전체 XP
  final int xpToNext;

  double get progress => xpToNext == 0 ? 0 : xpInLevel / xpToNext;
  String get title => titleForLevel(level);
}

LevelInfo levelInfo(int totalXp) {
  final xp = totalXp < 0 ? 0 : totalXp;
  var level = 1;
  while (xpForLevel(level + 1) <= xp) {
    level++;
  }
  final start = xpForLevel(level);
  final next = xpForLevel(level + 1);
  return LevelInfo(level: level, xpInLevel: xp - start, xpToNext: next - start);
}

String titleForLevel(int level) {
  if (level <= 2) return '씨앗 정원사';
  if (level == 3) return '새싹 정원사';
  if (level <= 5) return '꽃 정원사';
  return '숲 정원사';
}

// ---------- 식물 성장 ----------
// 씨앗을 심은 뒤 완료한 횟수(growth)로 단계를 정한다. 매일 하면 3주 뒤 다 자란다.

/// 이 횟수부터 다 자란 식물이 되고 수확할 수 있다.
const harvestAt = 21;

GrowthStage stageFor(int growth) {
  if (growth <= 0) return GrowthStage.seed;
  if (growth <= 6) return GrowthStage.sprout;
  if (growth < harvestAt) return GrowthStage.young;
  return GrowthStage.adult;
}

/// 다음 단계가 되는 횟수. 다 자랐으면 null.
int? nextStageAt(int growth) {
  if (growth <= 0) return 1;
  if (growth <= 6) return 7;
  if (growth < harvestAt) return harvestAt;
  return null;
}
