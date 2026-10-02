/// 카테고리마다 정해진 식물. enum 이름이 그대로 이미지 파일 이름이 된다.
enum PlantKind {
  sunflower('해바라기'),
  lavender('라벤더'),
  tulip('튤립'),
  rose('장미');

  const PlantKind(this.label);
  final String label;
}

/// 완료 횟수에 따른 성장 단계.
enum GrowthStage {
  seed('씨앗', '0회'),
  sprout('싹', '1–6회'),
  young('어린 식물', '7–20회'),
  adult('다 자란 식물', '21회+');

  const GrowthStage(this.label, this.rule);
  final String label;
  final String rule;
}
