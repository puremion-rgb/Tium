import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// 새싹 마크 + '틔움' 글자
class TiumLogo extends StatelessWidget {
  const TiumLogo({super.key, this.size = 64, this.color = AppColors.primaryDark});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SproutMark(size: size * 0.9, stemColor: AppColors.primary),
        Text('틔움', style: TextStyle(fontFamily: displayFont, fontSize: size, height: 1.05, color: color)),
      ],
    );
  }
}

class SproutMark extends StatelessWidget {
  const SproutMark({super.key, this.size = 48, this.stemColor = AppColors.primary, this.leftLeaf, this.rightLeaf});

  final double size;
  final Color stemColor;
  final Color? leftLeaf;
  final Color? rightLeaf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 46 / 54,
      child: CustomPaint(
        painter: _SproutPainter(
          stem: stemColor,
          left: leftLeaf ?? const Color(0xFF5FA845),
          right: rightLeaf ?? stemColor,
        ),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({required this.stem, required this.left, required this.right});
  final Color stem;
  final Color left;
  final Color right;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 54, size.height / 46);
    canvas.drawLine(
      const Offset(27, 46),
      const Offset(27, 22),
      Paint()
        ..color = stem
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    final leftLeaf = Path()
      ..moveTo(26, 26)
      ..cubicTo(14, 26, 4, 20, 3, 6)
      ..cubicTo(16, 6, 25, 12, 26, 26)
      ..close();
    final rightLeaf = Path()
      ..moveTo(28, 22)
      ..cubicTo(30, 9, 40, 2, 52, 2)
      ..cubicTo(51, 15, 41, 22, 28, 22)
      ..close();
    canvas.drawPath(leftLeaf, Paint()..color = left);
    canvas.drawPath(rightLeaf, Paint()..color = right);
  }

  @override
  bool shouldRepaint(covariant _SproutPainter old) => old.stem != stem || old.left != left || old.right != right;
}
