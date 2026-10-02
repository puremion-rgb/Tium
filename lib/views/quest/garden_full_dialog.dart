import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/garden_rules.dart';
import '../../viewmodels/garden_providers.dart';

/// 지금 화단에 심겨 있는(쉬는 중이 아닌) 퀘스트 수
int activeQuestCount(WidgetRef ref) => (ref.read(questsProvider).valueOrNull ?? const []).where((q) => q.active).length;

bool isGardenFull(WidgetRef ref) => activeQuestCount(ref) >= maxActiveQuests;

/// '퀘스트 추가'를 누르면 이걸 부른다. 화단이 가득 찼으면 안내 창을, 아니면 추가 화면을 연다.
Future<void> openNewQuest(BuildContext context, WidgetRef ref, {String? bookTitle}) async {
  if (isGardenFull(ref)) {
    await showGardenFullDialog(context);
    return;
  }
  await context.push(Routes.questNew, extra: bookTitle);
}

/// 정원이 가득 찼어요! — 화단 자리 8칸이 모두 찬 그림과 함께 정리 방법을 알려 준다.
Future<void> showGardenFullDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const GardenSlots(filled: maxActiveQuests, size: 26),
            const SizedBox(height: 18),
            const Text(
              '정원이 가득 찼어요! 🌱',
              style: TextStyle(fontFamily: 'Jua', fontSize: 22, color: AppColors.primaryDark),
            ),
            const SizedBox(height: 10),
            const Text(
              '퀘스트는 $maxActiveQuests개까지 키울 수 있어요.\n'
              '수확하거나 쉬게 하면 자리가 생겨요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.6, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go(Routes.quests);
              },
              child: const Text('퀘스트 정리하러 가기'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('닫기', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    ),
  );
}

/// 화단 자리 8칸. 심긴 자리는 초록 새싹, 빈자리는 점선 흙자리.
class GardenSlots extends StatelessWidget {
  const GardenSlots({super.key, required this.filled, this.size = 22});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '화단 $maxActiveQuests자리 중 $filled자리 사용 중',
      excludeSemantics: true,
      child: Wrap(
        spacing: size * 0.28,
        children: [
          for (var i = 0; i < maxActiveQuests; i++)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < filled ? const Color(0xFFE3F1DA) : const Color(0xFFF1E7D6),
                border: Border.all(
                  color: i < filled ? AppColors.primary.withValues(alpha: 0.55) : const Color(0xFFD9C7A8),
                  width: 1.4,
                ),
              ),
              child: i < filled
                  ? Icon(Icons.spa_rounded, size: size * 0.62, color: AppColors.primary)
                  : Center(
                      child: Container(
                        width: size * 0.22,
                        height: size * 0.22,
                        decoration: const BoxDecoration(color: Color(0xFFCDB592), shape: BoxShape.circle),
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}
