import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/completion.dart';
import '../../utils/korean.dart';
import '../../utils/level.dart';
import '../../widgets/garden/quest_plant.dart';

/// 8. 퀘스트 완료 애니메이션
class QuestCompleteScreen extends StatefulWidget {
  const QuestCompleteScreen({super.key, required this.result});
  final CompletionResult result;

  @override
  State<QuestCompleteScreen> createState() => _QuestCompleteScreenState();
}

class _QuestCompleteScreenState extends State<QuestCompleteScreen> with TickerProviderStateMixin {
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  late final _grow = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);

  @override
  void dispose() {
    _grow.dispose();
    _pop.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.result.quest;
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3B1F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, 0.05),
                radius: 0.9,
                colors: [Color(0xFFC9E58C), Color(0xFF6FA04A), Color(0xFF2F5A2C), Color(0xFF1E3B1F)],
                stops: [0, 0.22, 0.52, 1],
              ),
            ),
          ),
          if (!reduceMotion)
            AnimatedBuilder(
              animation: _drift,
              builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_drift.value)),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                children: [
                  const Spacer(),
                  const Text('퀘스트 완료!', style: TextStyle(fontFamily: displayFont, fontSize: 40, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(q.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white)),
                  Text('+${widget.result.gainedXp} XP', style: const TextStyle(fontFamily: displayFont, fontSize: 30, color: Color(0xFFFFE38A))),
                  if (widget.result.allClearBonus > 0) _BonusChip(label: '오늘의 퀘스트 모두 완료 +${widget.result.allClearBonus}'),
                  if (widget.result.streakBonus > 0) _BonusChip(label: '${widget.result.streak}일 연속 실천 +${widget.result.streakBonus}'),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Container(
                    width: 200,
                    height: 200,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [Color(0xE6FFF4BE), Color(0x00FFE68C)], stops: [0, 0.7]),
                    ),
                    child: ScaleTransition(
                      scale: reduceMotion ? const AlwaysStoppedAnimation(1) : _grow,
                      child: QuestPlant.forQuest(q, size: 140),
                    ),
                  ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.result.justBloomed || q.growth > harvestAt
                        ? '${q.petal.rare ? '희귀한 ' : ''}${q.petal.name} ${withIga(q.plant.label)} 피었어요!\n퀘스트 상세에서 수확할 수 있어요'
                        : widget.result.stageChanged
                            ? '${withIga(q.plant.label)} ${q.stage.label} 단계가 되었어요!'
                            : '${q.plant.label} · ${q.stage.label} · ${q.growth}/$harvestAt',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.92)),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    onPressed: () => context.pop(),
                    child: const Text('확인하기'),
                  ),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BonusChip extends StatelessWidget {
  const _BonusChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(color: const Color(0x33FFE38A), borderRadius: BorderRadius.circular(99)),
        child: Text(label, style: const TextStyle(color: Color(0xFFFFE38A), fontWeight: FontWeight.w700, fontSize: 13)),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);
  final double t;

  static const _colors = [AppColors.pointYellow, AppColors.accent, AppColors.pointPeach, Color(0xFFE8F5C8)];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 26; i++) {
      final x = ((i * 47) % 100) / 100 * size.width;
      final y = ((((i * 31 + 7) % 96) / 96 + t * (0.3 + (i % 3) * 0.1)) % 1.0) * size.height;
      final paint = Paint()..color = _colors[i % 4].withValues(alpha: 0.85);
      canvas.save();
      canvas.translate(x + math.sin((t * 2 + i) * math.pi) * 8, y);
      canvas.rotate(i * 0.65 + t * 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: i % 3 == 0 ? 10 : 6, height: 4), const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => old.t != t;
}
