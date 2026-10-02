import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tium/models/petal.dart';
import 'package:tium/models/plant.dart';

void main() {
  test('꽃마다 색 5개, 그중 희귀 색 1개', () {
    for (final kind in PlantKind.values) {
      final colors = PetalPalette.of(kind);
      expect(colors, hasLength(5));
      expect(colors.where((c) => c.rare), hasLength(1));
      expect(colors.map((c) => c.id).toSet(), hasLength(5), reason: '${kind.name} 색 ID가 겹친다');
    }
  });

  test('랜덤으로 뽑으면 희귀 색은 드물게 나온다 (약 12%)', () {
    final random = Random(42);
    var rare = 0;
    const n = 5000;
    for (var i = 0; i < n; i++) {
      if (PetalPalette.pick(PlantKind.tulip, random).rare) rare++;
    }
    expect(rare / n, inInclusiveRange(0.09, 0.15));
  });

  test('없는 ID는 기본 색으로', () {
    expect(PetalPalette.find(PlantKind.rose, 'nope').id, 'pink');
    expect(PetalPalette.find(PlantKind.rose, null).id, 'pink');
  });

  test('꽃잎 색만 바꿔 칠하고 잎·흙 색은 그대로', () {
    const svg = '<path fill="#F48B94" stroke="#D9576A"/><path fill="url(#leaf)" stroke="#34763A"/>';
    final yellow = PetalPalette.find(PlantKind.tulip, 'yellow');
    final out = PetalPalette.recolor(svg, PlantKind.tulip, GrowthStage.adult, yellow);
    expect(out, contains('fill="${yellow.main}"'));
    expect(out, contains('stroke="${yellow.dark}"'));
    expect(out, contains('#34763A'));
    expect(out, isNot(contains('#F48B94')));
  });

  test('바꾼 색이 다시 바뀌지 않는다 (한 번에 치환)', () {
    // 라벤더 기본: main #9B7BE0, light #B49AF0. purple은 원래 색이라 결과가 같아야 한다.
    const svg = '<a fill="#9B7BE0"/><b fill="#B49AF0"/><c stroke="#6E52B8"/>';
    final purple = PetalPalette.find(PlantKind.lavender, 'purple');
    expect(PetalPalette.recolor(svg, PlantKind.lavender, GrowthStage.adult, purple), svg);
  });

  test('씨앗과 싹은 그대로 둔다', () {
    const svg = '<path fill="#F48B94"/>';
    final white = PetalPalette.find(PlantKind.tulip, 'white');
    expect(PetalPalette.recolor(svg, PlantKind.tulip, GrowthStage.sprout, white), svg);
  });
}
