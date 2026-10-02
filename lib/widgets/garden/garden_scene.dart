import 'package:flutter/material.dart';

import '../../app/app_images.dart';
import '../../models/plant.dart';
import '../../models/quest.dart';
import '../../models/weather.dart';
import 'quest_plant.dart';

/// 정원 = 날씨 배경 + 퀘스트마다 식물 하나.
/// [lift]는 식물을 아래에서 얼마나 띄울지(0~1). 전체 화면에서는 배경 아래쪽 캐릭터를 피해 위로 올린다.
class GardenScene extends StatelessWidget {
  const GardenScene({
    super.key,
    required this.weather,
    required this.quests,
    this.backgroundAlignment = const Alignment(0, 0.25),
    this.plantScale = 1,
    this.lift = 0.04,
  });

  final WeatherKind weather;
  final List<Quest> quests;
  final Alignment backgroundAlignment;
  final double plantScale;
  final double lift;

  /// (가로 위치 0~1, 아래에서 띄우는 정도 0~1, 크기 배율) — 앞줄과 뒷줄이 번갈아 놓이게 한다.
  static const _slots = [
    (0.22, 0.09, 1.0),
    (0.46, 0.03, 1.15),
    (0.68, 0.10, 1.0),
    (0.86, 0.03, 0.9),
    (0.33, 0.00, 0.95),
    (0.10, 0.02, 0.85),
    (0.58, 0.15, 0.85),
    (0.78, 0.17, 0.8),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final base = c.maxWidth * 0.16 * plantScale;
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImages.garden(weather), fit: BoxFit.cover, alignment: backgroundAlignment, excludeFromSemantics: true),
          for (var i = 0; i < quests.length; i++) _plant(quests[i], i, c, base),
        ],
      );
    });
  }

  Widget _plant(Quest q, int i, BoxConstraints c, double base) {
    final (x, b, k) = _slots[i % _slots.length];
    // 슬롯이 모자라면 조금씩 옮겨 겹침을 줄인다.
    final round = i ~/ _slots.length;
    final stageScale = switch (q.stage) {
      GrowthStage.seed => 0.8,
      GrowthStage.sprout => 0.85,
      GrowthStage.young => 1.0,
      GrowthStage.adult => 1.2,
    };
    final size = base * k * stageScale;
    final left = ((x + round * 0.07) % 1.0) * c.maxWidth - size / 2;
    return Positioned(
      left: left,
      bottom: (b + lift + round * 0.05) * c.maxHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          QuestPlant.forQuest(q, size: size),
          // 다 자라서 수확할 수 있는 식물에는 반짝이 표시
          if (q.canHarvest)
            Positioned(
              right: -2,
              top: -2,
              child: Icon(Icons.auto_awesome_rounded, size: size * 0.32, color: const Color(0xFFFFD54F)),
            ),
        ],
      ),
    );
  }
}
