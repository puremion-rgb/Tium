import 'dart:math';

import 'plant.dart';

/// 꽃잎 색. 씨앗을 심을 때 랜덤으로 정해지고, 어린 식물(봉오리)부터 보인다.
class PetalColor {
  const PetalColor({
    required this.id,
    required this.name,
    required this.main,
    required this.dark,
    required this.light,
    this.rare = false,
  });

  /// 저장용 ID (예: 'pink')
  final String id;

  /// 화면에 보여 줄 이름 (예: '분홍')
  final String name;
  final String main;
  final String dark;
  final String light;

  /// 희귀 색. 나올 확률이 낮다.
  final bool rare;

  int get mainArgb => int.parse('FF${main.substring(1)}', radix: 16);
}

/// 식물 그림(SVG) 원본에 들어 있는 꽃잎 색. 이 색을 골라 바꿔 칠한다.
class _BaseColors {
  const _BaseColors({required this.main, required this.dark, this.light});
  final String main;
  final String dark;
  final String? light;
}

class PetalPalette {
  PetalPalette._();

  /// 흔한 색 4개는 22%씩, 희귀 색 1개는 12%
  static const _commonWeight = 22;
  static const _rareWeight = 12;

  static const Map<PlantKind, List<PetalColor>> colors = {
    PlantKind.tulip: [
      PetalColor(id: 'pink', name: '분홍', main: '#F48B94', dark: '#D9576A', light: '#F9B6BC'),
      PetalColor(id: 'yellow', name: '노랑', main: '#FFD54F', dark: '#E0A92A', light: '#FFE58A'),
      PetalColor(id: 'white', name: '하양', main: '#FAF6EE', dark: '#C9C1B0', light: '#FFFFFF'),
      PetalColor(id: 'purple', name: '보라', main: '#B48BE0', dark: '#7E57C2', light: '#D5BDF2'),
      PetalColor(id: 'night', name: '밤의 여왕', main: '#5B3A6B', dark: '#2E1A38', light: '#7E5A90', rare: true),
    ],
    PlantKind.rose: [
      PetalColor(id: 'pink', name: '분홍', main: '#F07A86', dark: '#C9505F', light: '#FF9B9F'),
      PetalColor(id: 'red', name: '빨강', main: '#E53945', dark: '#A4161A', light: '#F26B73'),
      PetalColor(id: 'yellow', name: '노랑', main: '#FFD166', dark: '#D9A21F', light: '#FFE29A'),
      PetalColor(id: 'white', name: '하양', main: '#FDF8F2', dark: '#D3C7B8', light: '#FFFFFF'),
      PetalColor(id: 'blue', name: '파랑', main: '#6C8EF5', dark: '#3D5BC4', light: '#9DB4FA', rare: true),
    ],
    PlantKind.sunflower: [
      PetalColor(id: 'yellow', name: '노랑', main: '#F6BE3E', dark: '#DB9A20', light: '#F9D272'),
      PetalColor(id: 'orange', name: '주황', main: '#F59E3B', dark: '#C9721A', light: '#F8BE7A'),
      PetalColor(id: 'lemon', name: '레몬', main: '#F4E66B', dark: '#C9B83A', light: '#F9F0A5'),
      PetalColor(id: 'velvet', name: '벨벳 레드', main: '#B5452F', dark: '#7E2A1B', light: '#D06A52'),
      PetalColor(id: 'white', name: '하양', main: '#F3EEE0', dark: '#C8BFA6', light: '#FFFDF5', rare: true),
    ],
    PlantKind.lavender: [
      PetalColor(id: 'purple', name: '보라', main: '#9B7BE0', dark: '#6E52B8', light: '#B49AF0'),
      PetalColor(id: 'lilac', name: '연보라', main: '#C3A7F2', dark: '#8F6CD6', light: '#DAC8F8'),
      PetalColor(id: 'pink', name: '분홍', main: '#E79AC7', dark: '#B86495', light: '#F2BFDD'),
      PetalColor(id: 'white', name: '하양', main: '#F1EEF7', dark: '#BDB5CC', light: '#FFFFFF'),
      PetalColor(id: 'blue', name: '파랑', main: '#7FA3EA', dark: '#4A6FC0', light: '#A9C2F2', rare: true),
    ],
  };

  /// 원본 SVG의 꽃잎 색 (어린 식물 / 다 자란 식물)
  static const Map<PlantKind, Map<GrowthStage, _BaseColors>> _base = {
    PlantKind.tulip: {
      GrowthStage.young: _BaseColors(main: '#E56B6F', dark: '#B64C50'),
      GrowthStage.adult: _BaseColors(main: '#F48B94', dark: '#D9576A'),
    },
    PlantKind.rose: {
      GrowthStage.young: _BaseColors(main: '#EF6B72', dark: '#C74B55', light: '#FF9B9F'),
      GrowthStage.adult: _BaseColors(main: '#F07A86', dark: '#C9505F'),
    },
    PlantKind.sunflower: {
      GrowthStage.young: _BaseColors(main: '#F5B83D', dark: '#D9961F'),
      GrowthStage.adult: _BaseColors(main: '#F6BE3E', dark: '#DB9A20'),
    },
    PlantKind.lavender: {
      GrowthStage.young: _BaseColors(main: '#9C6ADE', dark: '#7047A8', light: '#B78AE8'),
      GrowthStage.adult: _BaseColors(main: '#9B7BE0', dark: '#6E52B8', light: '#B49AF0'),
    },
  };

  static List<PetalColor> of(PlantKind kind) => colors[kind]!;

  /// 저장된 ID로 색을 찾는다. 없으면 기본(첫 번째) 색.
  static PetalColor find(PlantKind kind, String? id) =>
      of(kind).firstWhere((c) => c.id == id, orElse: () => of(kind).first);

  /// 가중치 랜덤으로 색을 하나 고른다.
  static PetalColor pick(PlantKind kind, Random random) {
    final list = of(kind);
    final total = list.fold<int>(0, (sum, c) => sum + (c.rare ? _rareWeight : _commonWeight));
    var roll = random.nextInt(total);
    for (final c in list) {
      roll -= c.rare ? _rareWeight : _commonWeight;
      if (roll < 0) return c;
    }
    return list.first;
  }

  /// SVG 문자열의 꽃잎 색을 [petal]로 바꿔 칠한다. 씨앗·싹은 꽃잎이 없어 그대로 둔다.
  static String recolor(String svg, PlantKind kind, GrowthStage stage, PetalColor petal) {
    final base = _base[kind]?[stage];
    if (base == null) return svg;
    final light = base.light;
    final map = <String, String>{
      base.main.toUpperCase(): petal.main,
      base.dark.toUpperCase(): petal.dark,
      if (light != null) light.toUpperCase(): petal.light,
    };
    // 한 번에 바꿔야 이미 바꾼 색이 다시 바뀌는 일이 없다.
    final pattern = RegExp(map.keys.map(RegExp.escape).join('|'), caseSensitive: false);
    return svg.replaceAllMapped(pattern, (m) => map[m[0]!.toUpperCase()]!);
  }
}
