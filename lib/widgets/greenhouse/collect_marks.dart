import 'package:flutter/material.dart';

import '../../models/greenhouse.dart';
import '../../models/petal.dart';
import '../../models/plant.dart';
import '../garden/quest_plant.dart';

/// 희귀 색에 쓰는 무지갯빛 (파스텔)
const rareSweep = SweepGradient(colors: [
  Color(0xFFB39DDB),
  Color(0xFF90CAF9),
  Color(0xFFA5D6A7),
  Color(0xFFFFE082),
  Color(0xFFF48FB1),
  Color(0xFFB39DDB),
]);

const rareLinear = LinearGradient(colors: [Color(0xFF9F86E0), Color(0xFFEE8DB8), Color(0xFFF5BE4B)]);

/// '희귀' 리본
class RarePill extends StatelessWidget {
  const RarePill({super.key, this.label = '희귀', this.large = false});
  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 7, vertical: large ? 5 : 2.5),
      decoration: BoxDecoration(
        gradient: rareLinear,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x40EE8DB8), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: large ? 14 : 10, color: Colors.white),
          SizedBox(width: large ? 4 : 2),
          Text(label, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: large ? 13 : 10, height: 1.1)),
        ],
      ),
    );
  }
}

/// 꽃 색 동그라미 (도감 한 칸)
/// - 모은 색: 그 색으로 칠함 / 못 모은 색: '?'
/// - 희귀 색: 무지갯빛 테두리
/// - 같은 색 2송이 이상: 오른쪽 위에 개수, 배지를 받았으면 테두리가 메달 색
class PetalDot extends StatelessWidget {
  const PetalDot({super.key, required this.petal, required this.count, this.size = 26});

  final PetalColor petal;
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final owned = count > 0;
    final tier = BadgeTier.of(count);
    final inner = Container(
      width: size - 5,
      height: size - 5,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: owned ? Color(petal.mainArgb) : const Color(0xFFF1EFE7),
        border: owned ? null : Border.all(color: const Color(0xFFD9D5C7), width: 1.2),
      ),
      child: owned
          ? (petal.rare ? Icon(Icons.auto_awesome_rounded, size: size * 0.42, color: Colors.white) : null)
          : Text('?', style: TextStyle(fontSize: size * 0.42, color: const Color(0xFFB3AE9F), fontWeight: FontWeight.w700)),
    );
    final ring = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: petal.rare
            ? rareSweep
            : tier != null
                ? LinearGradient(colors: [Color(tier.light), Color(tier.dark)], begin: Alignment.topLeft, end: Alignment.bottomRight)
                : null,
        color: petal.rare || tier != null ? null : Colors.transparent,
      ),
      child: inner,
    );
    return Tooltip(
      message: owned ? '${petal.name}${petal.rare ? ' (희귀)' : ''} · $count송이' : (petal.rare ? '아직 못 모은 희귀 색' : '아직 못 모은 색'),
      child: SizedBox(
        width: size + 6,
        height: size + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // 못 모은 희귀 색은 무지갯빛 테두리를 흐리게 보여 '특별한 칸'이라는 걸 알려 준다.
            Opacity(opacity: owned || !petal.rare ? 1 : 0.55, child: ring),
            if (count >= 2)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: tier != null ? Color(tier.dark) : const Color(0xFF5D6B58),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800, height: 1.2)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 같은 색 모음 배지 (동 꽃다발 · 은 꽃바구니 · 금 꽃밭)
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.kind, required this.petal, required this.tier, this.count, this.size = 64});

  final PlantKind kind;
  final PetalColor petal;
  final BadgeTier tier;
  final int? count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final light = Color(tier.light);
    final dark = Color(tier.dark);
    return SizedBox(
      width: size,
      height: size * 1.18,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 리본 꼬리 두 개
          Positioned(
            bottom: 0,
            left: size * 0.26,
            child: Transform.rotate(angle: 0.28, child: _Tail(color: dark, width: size * 0.2, height: size * 0.36)),
          ),
          Positioned(
            bottom: 0,
            right: size * 0.26,
            child: Transform.rotate(angle: -0.28, child: _Tail(color: dark, width: size * 0.2, height: size * 0.36)),
          ),
          // 메달
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(size * 0.08),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [light, dark], begin: Alignment.topLeft, end: Alignment.bottomRight),
              boxShadow: [BoxShadow(color: dark.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFFDF6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9), width: 1.5),
              ),
              alignment: Alignment.center,
              child: QuestPlant(kind: kind, stage: GrowthStage.adult, petal: petal, size: size * 0.7),
            ),
          ),
          if (count != null)
            Positioned(
              right: -4,
              top: size * 0.62,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: dark, borderRadius: BorderRadius.circular(99), border: Border.all(color: Colors.white, width: 1.5)),
                child: Text('×$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tail extends StatelessWidget {
  const _Tail({required this.color, required this.width, required this.height});
  final Color color;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: _TailClipper(),
        child: Container(width: width, height: height, color: color),
      );
}

/// 아래가 V자로 파인 리본 꼬리
class _TailClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(s.width / 2, s.height * 0.78)
    ..lineTo(0, s.height)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
