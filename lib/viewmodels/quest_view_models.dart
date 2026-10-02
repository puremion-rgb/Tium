import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../models/category.dart';
import '../models/garden_rules.dart';
import '../models/greenhouse.dart';
import '../models/quest.dart';
import 'garden_providers.dart';

// ---------------- 퀘스트 목록 ----------------

/// null = 전체
final questFilterProvider = StateProvider<QuestCategory?>((ref) => null);

final filteredQuestsProvider = Provider<AsyncValue<List<Quest>>>((ref) {
  final filter = ref.watch(questFilterProvider);
  return ref.watch(questsProvider).whenData(
        (list) => filter == null ? list : list.where((q) => q.category == filter).toList(),
      );
});

final questByIdProvider = Provider.family<Quest?, String>((ref, id) {
  final list = ref.watch(questsProvider).valueOrNull ?? const <Quest>[];
  for (final q in list) {
    if (q.id == id) return q;
  }
  return null;
});

class QuestActions {
  QuestActions(this._ref);
  final Ref _ref;

  Future<void> setActive(String id, {required bool active}) =>
      _ref.read(gardenRepositoryProvider).setQuestActive(id, active: active);

  /// 다 자란 식물을 수확해 온실에 담는다.
  Future<HarvestResult> harvest(String id) => _ref.read(gardenRepositoryProvider).harvest(id);
}

final questActionsProvider = Provider<QuestActions>(QuestActions.new);

// ---------------- 퀘스트 추가 / 수정 ----------------

typedef QuestFormArgs = ({String? questId, String? bookTitle});

class QuestFormState {
  const QuestFormState({
    this.title = '',
    this.category = QuestCategory.study,
    this.description = '',
    this.bookTitle,
    this.saving = false,
    this.error,
  });

  final String title;
  final QuestCategory category;
  final String description;
  final String? bookTitle;
  final bool saving;
  final String? error;

  bool get canSave => title.trim().isNotEmpty && !saving;

  QuestFormState copyWith({
    String? title,
    QuestCategory? category,
    String? description,
    bool? saving,
    String? error,
    bool clearError = false,
  }) =>
      QuestFormState(
        title: title ?? this.title,
        category: category ?? this.category,
        description: description ?? this.description,
        bookTitle: bookTitle,
        saving: saving ?? this.saving,
        error: clearError ? null : (error ?? this.error),
      );
}

class QuestFormViewModel extends AutoDisposeFamilyNotifier<QuestFormState, QuestFormArgs> {
  Quest? _editing;

  @override
  QuestFormState build(QuestFormArgs arg) {
    final id = arg.questId;
    if (id != null) {
      _editing = ref.read(questByIdProvider(id));
      final q = _editing;
      if (q != null) {
        return QuestFormState(title: q.title, category: q.category, description: q.description, bookTitle: q.bookTitle);
      }
    }
    final book = arg.bookTitle;
    if (book != null) {
      return QuestFormState(title: '『$book』 20쪽 읽기', category: QuestCategory.reading, bookTitle: book);
    }
    return const QuestFormState();
  }

  bool get isEditing => _editing != null;

  void setTitle(String v) => state = state.copyWith(title: v, clearError: true);
  void setCategory(QuestCategory v) => state = state.copyWith(category: v);
  void setDescription(String v) => state = state.copyWith(description: v);

  /// 저장에 성공하면 true
  Future<bool> save() async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(error: '퀘스트 제목을 입력해 주세요');
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    final repo = ref.read(gardenRepositoryProvider);
    try {
      final editing = _editing;
      if (editing != null) {
        await repo.updateQuest(editing.copyWith(
          title: state.title.trim(),
          category: state.category,
          description: state.description.trim(),
        ));
      } else {
        await repo.addQuest(QuestDraft(
          title: state.title.trim(),
          category: state.category,
          description: state.description.trim(),
          bookTitle: state.bookTitle,
        ));
      }
      return true;
    } on GardenFullException {
      state = state.copyWith(saving: false, error: '정원이 가득 찼어요! 수확하거나 쉬는 퀘스트로 바꾼 뒤 추가해 주세요');
      return false;
    } catch (_) {
      state = state.copyWith(saving: false, error: '저장하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요');
      return false;
    }
  }
}

final questFormViewModelProvider =
    NotifierProvider.autoDispose.family<QuestFormViewModel, QuestFormState, QuestFormArgs>(QuestFormViewModel.new);
