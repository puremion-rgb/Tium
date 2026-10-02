import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../models/completion.dart';
import '../../models/quest.dart';
import '../../viewmodels/home_view_model.dart';
import '../../widgets/common/state_view.dart';

/// 체크 → (완료 화면) → (레벨업 화면) → 홈으로 돌아와 한 줄 안내
Future<void> runCompleteFlow(BuildContext context, WidgetRef ref, Quest quest) async {
  if (quest.doneToday) {
    await showAlreadyDoneSheet(context);
    return;
  }
  try {
    final result = await ref.read(homeViewModelProvider.notifier).complete(quest.id);
    if (!context.mounted) return;
    await context.push(Routes.complete, extra: result);
    if (result.leveledUp && context.mounted) {
      await context.push(Routes.levelUp, extra: result);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${quest.title} 완료! +${result.gainedXp} XP')),
      );
    }
  } on AlreadyCompletedException {
    if (context.mounted) await showAlreadyDoneSheet(context);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('완료 처리를 하지 못했어요. 연결 상태를 확인하고 다시 눌러 주세요')),
      );
    }
  }
}
