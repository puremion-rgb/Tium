import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../models/quest.dart';
import '../../widgets/common/tium_logo.dart';
import '../../widgets/garden/quest_plant.dart';

/// 22. 앱을 켜 둔 상태에서 'daily-quest' 푸시를 받았을 때 띄우는 알림.
/// Day 8: FirebaseMessaging.onMessage.listen 에서 이 함수를 부른다.
Future<void> showDailyQuestDialog(BuildContext context, List<Quest> todayQuests) {
  final left = todayQuests.where((q) => !q.doneToday).toList();
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: const Color(0xFFDDF2D8), borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: const SproutMark(size: 36),
            ),
            const SizedBox(height: 12),
            const Text('오늘의 퀘스트가 도착했어요', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              left.isEmpty ? '오늘 퀘스트를 모두 끝냈어요!' : '아직 남은 퀘스트 ${left.length}개',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            for (final q in left.take(4))
              Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    QuestPlant.forQuest(q, size: 26),
                    const SizedBox(width: 8),
                    Expanded(child: Text(q.title)),
                    Text('+${q.xp}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('바로가기')),
          ],
        ),
      ),
    ),
  );
}
