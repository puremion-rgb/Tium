import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show ClientException;

import '../../app/theme.dart';
import '../../models/plant.dart';
import '../garden/quest_plant.dart';

/// 17 로딩 · 18 빈 화면 · 19 네트워크 오류 · 20 이미 완료됨 을 한 위젯으로 그린다.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.illustration,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.background = AppColors.accentLight,
    this.showDots = false,
  });

  factory StateView.loading() => const StateView(
        illustration: QuestPlant(kind: PlantKind.tulip, stage: GrowthStage.sprout, size: 92),
        title: '데이터를 불러오고 있어요',
        message: '잠시만 기다려 주세요',
        showDots: true,
      );

  factory StateView.empty({required VoidCallback onAdd}) => StateView(
        illustration: const QuestPlant(kind: PlantKind.rose, stage: GrowthStage.seed, size: 84),
        title: '등록된 퀘스트가 없어요',
        message: '첫 퀘스트를 만들면 정원에 씨앗이 심어져요',
        actionLabel: '퀘스트 추가하기',
        onAction: onAdd,
      );

  /// 오류 종류에 맞춰 문구를 고른다.
  factory StateView.error(Object error, {required VoidCallback onRetry}) {
    debugPrint('[StateView] $error');
    final offline = error is SocketException || (error is ClientException && error.message.contains('SocketException'));
    final slow = error is TimeoutException;
    return StateView(
      illustration: Icon(offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded, size: 54, color: const Color(0xFFC0574E)),
      background: const Color(0xFFFBE9E7),
      title: offline ? '인터넷에 연결되지 않았어요' : slow ? '응답이 너무 늦어요' : '불러오는 중 문제가 생겼어요',
      message: offline ? '연결 상태를 확인한 뒤 다시 시도해 주세요' : '잠시 후 다시 시도해 주세요',
      actionLabel: '다시 시도',
      onAction: onRetry,
    );
  }

  final Widget illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color background;
  final bool showDots;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(color: background, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: illustration,
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            ],
            if (showDots)
              const Padding(padding: EdgeInsets.only(top: 16), child: _Dots()),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              SizedBox(width: 200, child: FilledButton(onPressed: onAction, child: Text(actionLabel!))),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [AppColors.primary, Color(0xFF66A86A), AppColors.accent];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Opacity(
                opacity: ((_c.value * 3 - i) % 3) < 1 ? 1 : 0.3,
                child: Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[i], shape: BoxShape.circle)),
              ),
            ),
        ],
      ),
    );
  }
}

/// 20. 이미 완료한 퀘스트를 다시 눌렀을 때
Future<void> showAlreadyDoneSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('오늘은 이미 완료한 퀘스트예요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('내일 다시 정원을 가꿔 주세요', style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
          ],
        ),
      ),
    ),
  );
}
