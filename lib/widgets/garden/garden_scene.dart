import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/app_images.dart';
import '../../models/plant.dart';
import '../../models/quest.dart';
import '../../models/weather.dart';
import 'quest_plant.dart';

/// 정원 = 날씨 배경 + 앞쪽 나무 화단 + 퀘스트마다 식물 하나.
///
/// 식물은 배경 그림 위에 흩어 놓지 않고 화단 흙 위에 줄지어 심는다.
/// (배경의 연못·길 위에 식물이 떠 보이지 않도록)
/// - [soilDepth]: 흙 부분 높이 (가로 폭에 대한 비율)
/// - [panelHeight]: 앞쪽 나무판 높이(px). 전체 화면에서는 이 위에 버튼을 올린다.
class GardenScene extends StatelessWidget {
  const GardenScene({
    super.key,
    required this.weather,
    required this.quests,
    this.backgroundAlignment = const Alignment(0, 0.25),
    this.plantScale = 1,
    this.soilDepth = 0.13,
    this.panelHeight = 26,
  });

  final WeatherKind weather;
  final List<Quest> quests;
  final Alignment backgroundAlignment;
  final double plantScale;
  final double soilDepth;
  final double panelHeight;

  /// 한 줄에 심는 최대 그루 수. 넘치면 두 줄(뒷줄·앞줄)로 나눈다.
  static const _perRow = 4;

  /// 식물 SVG에서 흙더미 중심이 그림 아래에서 얼마나 위에 있는지 (viewBox 1024 중 cy=860)
  static const _plantFootRatio = 0.16;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final bed = _BedGeometry(width: w, soil: w * soilDepth, panel: panelHeight);
      final placed = _layout(quests, bed, w * 0.24 * plantScale);
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImages.garden(weather), fit: BoxFit.cover, alignment: backgroundAlignment, excludeFromSemantics: true),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bed.height,
            child: CustomPaint(painter: _FlowerBedPainter(weather: weather, panel: panelHeight)),
          ),
          for (final p in placed) _plant(p),
          // 앞판은 식물 뿌리(흙더미) 아래쪽을 살짝 가려서 흙에 심긴 것처럼 보이게 한다.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bed.height,
            child: IgnorePointer(child: CustomPaint(painter: _FlowerBedPainter(weather: weather, panel: panelHeight, frontOnly: true))),
          ),
        ],
      );
    });
  }

  /// 뒷줄부터 그리도록 순서를 정해 돌려준다.
  List<_Placed> _layout(List<Quest> qs, _BedGeometry bed, double base) {
    final n = qs.length;
    if (n == 0) return const [];
    final rows = n <= _perRow ? 1 : 2;
    final frontCount = rows == 1 ? n : (n / 2).ceil();
    final backCount = n - frontCount;
    final inner = bed.soilRight - bed.soilLeft;

    _Placed place(Quest q, int j, int count, double soilY, double rowScale, double stagger) {
      final spacing = inner / count;
      final stageScale = switch (q.stage) {
        GrowthStage.seed => 0.8,
        GrowthStage.sprout => 0.85,
        GrowthStage.young => 1.0,
        GrowthStage.adult => 1.2,
      };
      // 한 줄에 많이 심으면 서로 겹치지 않게 조금 작게
      final size = math.min(base * rowScale * stageScale, spacing * 1.25);
      final cx = bed.soilLeft + spacing * (j + 0.5) + stagger * spacing;
      return _Placed(q, cx - size / 2, soilY - size * _plantFootRatio, size);
    }

    final front = [
      for (var j = 0; j < frontCount; j++) place(qs[j], j, frontCount, bed.frontRowY, 1.0, 0),
    ];
    final back = [
      for (var j = 0; j < backCount; j++)
        place(qs[frontCount + j], j, backCount, bed.backRowY, 0.85, backCount == frontCount ? 0.25 : 0),
    ];
    return [...back, ...front];
  }

  Widget _plant(_Placed p) {
    return Positioned(
      left: p.left,
      bottom: p.bottom,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          QuestPlant.forQuest(p.quest, size: p.size),
          // 다 자라서 수확할 수 있는 식물에는 반짝이 표시
          if (p.quest.canHarvest)
            Positioned(
              right: -2,
              top: -2,
              child: Icon(Icons.auto_awesome_rounded, size: p.size * 0.32, color: const Color(0xFFFFD54F)),
            ),
        ],
      ),
    );
  }
}

class _Placed {
  const _Placed(this.quest, this.left, this.bottom, this.size);
  final Quest quest;
  final double left;
  final double bottom; // 장면 아래에서부터 px
  final double size;
}

/// 화단 위치 계산 (모두 장면 아래에서부터 px).
class _BedGeometry {
  _BedGeometry({required this.width, required this.soil, required this.panel});
  final double width;
  final double soil; // 흙 높이
  final double panel; // 앞판 높이

  double get height => soil + panel;
  double get soilLeft => width * 0.06;
  double get soilRight => width * 0.94;

  /// 앞줄 식물이 서는 흙 높이(앞판 윗면 바로 뒤) / 뒷줄 식물이 서는 흙 높이
  double get frontRowY => panel + soil * 0.12;
  double get backRowY => panel + soil * 0.62;
}

/// 나무 테두리 화단. 화면 폭 전체에 걸친, 살짝 원근감 있는 사다리꼴.
/// 두 번 나눠 그린다: [frontOnly]가 false면 그림자·흙·뒷판(식물 뒤), true면 앞판·풀(식물 앞, 뿌리를 가림).
class _FlowerBedPainter extends CustomPainter {
  _FlowerBedPainter({required this.weather, required this.panel, this.frontOnly = false});

  final WeatherKind weather;
  final double panel; // 앞판 높이(px)
  final bool frontOnly;

  // 날씨에 따라 화단 밝기를 배경에 맞춘다.
  double get _light => switch (weather) {
        WeatherKind.sunny => 1.0,
        WeatherKind.cloudy => 0.9,
        WeatherKind.rain => 0.8,
        WeatherKind.snow => 0.95,
        WeatherKind.night => 0.55,
      };

  Color _c(int argb) {
    final c = Color(argb);
    final k = _light;
    Color mix(Color a) => weather == WeatherKind.night ? Color.lerp(a, const Color(0xFF1E2A4A), 0.25)! : a;
    return mix(Color.fromARGB(
      (c.a * 255).round(),
      (c.r * 255 * k).round().clamp(0, 255),
      (c.g * 255 * k).round().clamp(0, 255),
      (c.b * 255 * k).round().clamp(0, 255),
    ));
  }

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final inset = w * 0.03; // 뒤쪽이 살짝 좁아 보이게
    final frontTop = h - panel;
    final backPlankH = math.max(5.0, frontTop * 0.16);
    const backTop = 0.0;

    if (!frontOnly) {
      // 화단 그림자
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(-8, -4, w + 8, h + 6), const Radius.circular(18)),
        Paint()
          ..color = Colors.black.withValues(alpha: weather == WeatherKind.night ? 0.35 : 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // 흙 (사다리꼴)
      final soil = Path()
        ..moveTo(inset, backTop + backPlankH * 0.5)
        ..lineTo(w - inset, backTop + backPlankH * 0.5)
        ..lineTo(w, frontTop + 4)
        ..lineTo(0, frontTop + 4)
        ..close();
      canvas.drawPath(
        soil,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_c(0xFF8C5A36), _c(0xFFA86E44)],
          ).createShader(Rect.fromLTWH(0, 0, w, frontTop)),
      );
      // 흙 알갱이 (고정 시드라 매번 같은 모양)
      final rnd = math.Random(7);
      final dot = Paint()..color = _c(0xFF74482A);
      final dotLight = Paint()..color = _c(0xFFC08A5C);
      for (var i = 0; i < (w / 6).round(); i++) {
        final y = backTop + backPlankH + rnd.nextDouble() * (frontTop - backTop - backPlankH);
        final x = rnd.nextDouble() * w;
        canvas.drawCircle(Offset(x, y), 0.8 + rnd.nextDouble() * 1.4, i.isEven ? dot : dotLight);
      }

      // 뒷판 (얇고 어둡게)
      _plank(canvas, Rect.fromLTRB(inset, backTop, w - inset, backTop + backPlankH), dark: true);
      if (weather == WeatherKind.snow) _snowCap(canvas, inset, w - inset, backTop, backPlankH * 0.6);
      return; // 앞판은 식물 위에 덮는 두 번째 그림에서 그린다.
    }

    // 앞판 (판자 여러 줄. 높이 약 26px마다 한 장)
    final count = math.max(1, (panel / 26).round());
    final plankH = panel / count;
    for (var i = 0; i < count; i++) {
      final top = frontTop + plankH * i;
      _plank(canvas, Rect.fromLTRB(0, top, w, i == count - 1 ? h + 6 : top + plankH), dark: false, lower: i.isOdd);
    }
    // 기둥
    for (final x in [w * 0.015, w * 0.5 - w * 0.012, w * 0.985 - w * 0.024]) {
      final post = RRect.fromRectAndRadius(Rect.fromLTWH(x, frontTop - 5, w * 0.024, panel + 11), const Radius.circular(3));
      canvas.drawRRect(post, Paint()..color = _c(0xFF9C6236));
      canvas.drawRRect(
        post,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = _c(0xFF5E3A1E),
      );
    }
    // 앞판 위 풀잎
    final grass = Paint()..color = _c(0xFF6BAA4A);
    final grassDark = Paint()..color = _c(0xFF4C8A35);
    final rnd = math.Random(3);
    for (var x = 6.0; x < w; x += 10 + rnd.nextDouble() * 18) {
      final gh = 4 + rnd.nextDouble() * 6;
      final tuft = Path()
        ..moveTo(x - 4, frontTop + 1)
        ..quadraticBezierTo(x - 3, frontTop - gh * 0.6, x - 1, frontTop - gh)
        ..quadraticBezierTo(x, frontTop - gh * 0.4, x + 1.5, frontTop - gh * 0.8)
        ..quadraticBezierTo(x + 3, frontTop - gh * 0.3, x + 4, frontTop + 1)
        ..close();
      canvas.drawPath(tuft, rnd.nextBool() ? grass : grassDark);
    }
    if (weather == WeatherKind.snow) _snowCap(canvas, 0, w, frontTop, math.min(plankH, 26) * 0.45);
  }

  void _plank(Canvas canvas, Rect r, {required bool dark, bool lower = false}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    final top = dark ? 0xFF8A5530 : (lower ? 0xFFB97A45 : 0xFFD09358);
    final bottom = dark ? 0xFF6E4223 : (lower ? 0xFF9C6236 : 0xFFB57A44);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_c(top), _c(bottom)],
        ).createShader(r),
    );
    // 나뭇결
    final grain = Paint()
      ..color = _c(0xFF7A4A26).withValues(alpha: 0.45)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(r.top.round());
    for (var i = 0; i < 3; i++) {
      final y = r.top + r.height * (0.3 + i * 0.22);
      final x0 = r.left + rnd.nextDouble() * r.width * 0.4;
      final x1 = x0 + r.width * (0.15 + rnd.nextDouble() * 0.25);
      canvas.drawLine(Offset(x0, y), Offset(x1, y), grain);
    }
    canvas.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = _c(0xFF5E3A1E),
    );
  }

  void _snowCap(Canvas canvas, double l, double r, double top, double thick) {
    final p = Path()..moveTo(l, top + thick * 0.4);
    final rnd = math.Random(11);
    for (var x = l; x <= r; x += 14) {
      p.quadraticBezierTo(x + 7, top - thick * (0.3 + rnd.nextDouble() * 0.4), x + 14, top + thick * 0.2);
    }
    p
      ..lineTo(r, top + thick)
      ..lineTo(l, top + thick)
      ..close();
    canvas.drawPath(p, Paint()..color = Colors.white.withValues(alpha: 0.95));
  }

  @override
  bool shouldRepaint(_FlowerBedPainter old) => old.weather != weather || old.panel != panel || old.frontOnly != frontOnly;
}
