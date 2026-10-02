import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../models/completion.dart';
import '../models/quest.dart';
import '../models/user_profile.dart';
import 'garden_providers.dart';

class HomeState {
  const HomeState({required this.profile, required this.quests});

  final UserProfile profile;

  /// 모든 퀘스트 (쉬는 중 포함)
  final List<Quest> quests;

  /// 오늘 할 퀘스트 = 화단에 심겨 있는 식물 (쉬는 중인 퀘스트는 화단에서 빠진다)
  List<Quest> get todayQuests => quests.where((q) => q.active).toList();
  int get doneCount => todayQuests.where((q) => q.doneToday).length;
  bool get isEmpty => quests.isEmpty;
}

/// 홈(정원) 화면의 ViewModel
class HomeViewModel extends AsyncNotifier<HomeState> {
  @override
  Future<HomeState> build() async {
    final profile = await ref.watch(profileProvider.future);
    final quests = await ref.watch(questsProvider.future);
    return HomeState(profile: profile, quests: quests);
  }

  /// 체크 버튼. 오늘 이미 했으면 [AlreadyCompletedException]을 던진다.
  Future<CompletionResult> complete(String questId) =>
      ref.read(gardenRepositoryProvider).completeQuest(questId);

  Future<void> retry() async {
    ref.invalidate(profileProvider);
    ref.invalidate(questsProvider);
    ref.invalidate(weatherProvider);
  }
}

final homeViewModelProvider = AsyncNotifierProvider<HomeViewModel, HomeState>(HomeViewModel.new);
