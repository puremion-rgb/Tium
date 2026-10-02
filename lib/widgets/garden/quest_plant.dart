import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/app_images.dart';
import '../../models/petal.dart';
import '../../models/plant.dart';
import '../../models/quest.dart';

/// 식물 그림. [petal]을 주면 어린 식물·다 자란 식물의 꽃잎을 그 색으로 칠한다.
class QuestPlant extends StatelessWidget {
  const QuestPlant({super.key, required this.kind, required this.stage, this.petal, this.size = 48, this.semanticLabel});

  /// 퀘스트의 지금 식물 (종류·단계·꽃잎 색)
  factory QuestPlant.forQuest(Quest quest, {Key? key, double size = 48}) => QuestPlant(
        key: key,
        kind: quest.plant,
        stage: quest.stage,
        petal: quest.petal,
        size: size,
        // 씨앗·싹일 때는 꽃잎 색을 말하지 않는다 (꽃이 필 때까지 비밀)
        semanticLabel: quest.stage == GrowthStage.young || quest.stage == GrowthStage.adult
            ? '${quest.title}: ${quest.petal.name} ${quest.plant.label} ${quest.stage.label}'
            : '${quest.title}: ${quest.plant.label} ${quest.stage.label}',
      );

  final PlantKind kind;
  final GrowthStage stage;
  final PetalColor? petal;
  final double size;
  final String? semanticLabel;

  bool get _hasPetals => stage == GrowthStage.young || stage == GrowthStage.adult;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? '${kind.label} ${stage.label}';
    final p = petal;
    if (p == null || !_hasPetals) {
      return SvgPicture.asset(AppImages.plant(kind, stage), width: size, height: size, semanticsLabel: label);
    }
    final key = _PlantSvgCache.keyOf(kind, stage, p);
    final ready = _PlantSvgCache.done[key];
    if (ready != null) return _svg(ready, label);
    return FutureBuilder<String>(
      future: _PlantSvgCache.load(DefaultAssetBundle.of(context), kind, stage, p),
      // 색을 바꾼 그림이 준비되기 전(또는 실패했을 때)에는 원래 그림을 보여 준다.
      builder: (_, snap) => snap.hasData
          ? _svg(snap.data!, label)
          : SvgPicture.asset(AppImages.plant(kind, stage), width: size, height: size, semanticsLabel: label),
    );
  }

  Widget _svg(String svg, String label) => SvgPicture.string(svg, width: size, height: size, semanticsLabel: label);
}

/// 색을 바꾼 SVG 문자열을 한 번만 만들고 다시 쓴다.
class _PlantSvgCache {
  static final done = <String, String>{};
  static final _pending = <String, Future<String>>{};

  static String keyOf(PlantKind kind, GrowthStage stage, PetalColor petal) => '${kind.name}_${stage.name}_${petal.id}';

  static Future<String> load(AssetBundle bundle, PlantKind kind, GrowthStage stage, PetalColor petal) {
    final key = keyOf(kind, stage, petal);
    return _pending.putIfAbsent(key, () async {
      try {
        final raw = await bundle.loadString(AppImages.plant(kind, stage));
        final colored = PetalPalette.recolor(raw, kind, stage, petal);
        done[key] = colored;
        return colored;
      } catch (_) {
        _pending.remove(key); // 다음에 다시 시도할 수 있게
        rethrow;
      }
    });
  }
}
