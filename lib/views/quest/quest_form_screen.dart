import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../models/category.dart';
import '../../utils/level.dart';
import '../../viewmodels/quest_view_models.dart';
import '../../widgets/common/app_card.dart';

/// 5. 퀘스트 추가 / 수정
class QuestFormScreen extends ConsumerStatefulWidget {
  const QuestFormScreen({super.key, this.questId, this.bookTitle});

  final String? questId;
  final String? bookTitle;

  @override
  ConsumerState<QuestFormScreen> createState() => _QuestFormScreenState();
}

class _QuestFormScreenState extends ConsumerState<QuestFormScreen> {
  late final QuestFormArgs _args = (questId: widget.questId, bookTitle: widget.bookTitle);
  late final _title = TextEditingController(text: ref.read(questFormViewModelProvider(_args)).title);
  late final _desc = TextEditingController(text: ref.read(questFormViewModelProvider(_args)).description);

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ok = await ref.read(questFormViewModelProvider(_args).notifier).save();
    if (!ok || !mounted) return;
    final editing = widget.questId != null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(editing ? '퀘스트를 수정했어요' : '정원에 새 씨앗을 심었어요')),
    );
    // 책에서 왔으면 검색·상세 화면까지 닫고 퀘스트 목록으로 간다.
    if (widget.bookTitle != null) {
      context.go(Routes.quests);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(questFormViewModelProvider(_args));
    final vm = ref.read(questFormViewModelProvider(_args).notifier);
    final editing = widget.questId != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? '퀘스트 수정' : '퀘스트 추가')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 32),
        children: [
          TextField(
            controller: _title,
            onChanged: vm.setTitle,
            textInputAction: TextInputAction.next,
            maxLength: 30,
            decoration: InputDecoration(
              hintText: '퀘스트 제목을 입력하세요',
              prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.textHint),
              errorText: state.error,
              counterText: '',
            ),
          ),
          const SizedBox(height: 18),
          const Text('카테고리 · 고른 카테고리의 꽃이 정원에 심어져요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          ChoiceChipRow<QuestCategory>(
            items: QuestCategory.values,
            selected: state.category,
            labelOf: (c) => '${c.label} · ${c.plant.label}',
            onSelected: vm.setCategory,
          ),
          const SizedBox(height: 18),
          const _XpRuleCard(),
          const SizedBox(height: 14),
          TextField(
            controller: _desc,
            onChanged: vm.setDescription,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(hintText: '간단한 설명을 입력하세요 (선택)'),
          ),
          if (!editing && widget.bookTitle == null) ...[
            const SizedBox(height: 14),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: () => context.push(Routes.books),
              child: Row(
                children: [
                  IconTile(icon: QuestCategory.reading.icon, background: QuestCategory.reading.tileColor, color: QuestCategory.reading.iconColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('책에서 찾기', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text('읽을 책을 골라 독서 퀘스트로 만들어요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.saving ? null : _save,
            child: state.saving
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('저장하기'),
          ),
        ],
      ),
    );
  }
}

/// XP는 고르지 않는다. 규칙만 보여 준다.
class _XpRuleCard extends StatelessWidget {
  const _XpRuleCard();

  @override
  Widget build(BuildContext context) {
    Widget rule(String label, String xp) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const Icon(Icons.eco_rounded, size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
              Text(xp, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('보상 XP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          const Text('많이 하는 것보다 매일 하는 게 더 크게 자라요', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          rule('완료할 때마다', '+$questXp'),
          rule('오늘의 퀘스트를 모두 끝내면', '+$allClearBonusXp'),
          rule('$streakBonusEvery일 연속 실천할 때마다', '+$streakBonusXp'),
        ],
      ),
    );
  }
}
