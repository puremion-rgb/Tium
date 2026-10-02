import '../../models/completion.dart';
import '../../models/greenhouse.dart';
import '../../models/quest.dart';
import '../../models/user_profile.dart';

/// 사용자 · 퀘스트 · 완료 기록을 다루는 저장소.
/// 지금은 [FakeGardenRepository]를 쓰고, Day 6에 Firestore 구현으로 바꾼다.
/// 화면과 ViewModel은 이 인터페이스만 알기 때문에 구현을 바꿔도 고칠 곳이 없다.
abstract interface class GardenRepository {
  Stream<UserProfile> watchProfile();

  /// 활성/쉬는 중 퀘스트 전부. doneToday가 채워져 있다.
  Stream<List<Quest>> watchQuests();

  /// 완료 기록 전부 (기록 화면용)
  Stream<List<Completion>> watchCompletions();

  /// 오늘 완료 처리. completions 문서 생성 + totalXp, completionCount 증가를 한 번에(트랜잭션) 한다.
  /// 오늘 이미 완료했다면 [AlreadyCompletedException]을 던진다.
  Future<CompletionResult> completeQuest(String questId);

  /// 온실에 담긴 꽃 (최근 수확 순)
  Stream<List<GreenhouseItem>> watchGreenhouse();

  /// 다 자란 식물을 수확해 온실에 담고, 같은 자리에 새 씨앗(새 랜덤 색)을 심는다.
  /// 아직 다 자라지 않았으면 [NotReadyToHarvestException]을 던진다.
  Future<HarvestResult> harvest(String questId);

  Future<Quest> addQuest(QuestDraft draft);
  Future<void> updateQuest(Quest quest);
  Future<void> setQuestActive(String questId, {required bool active});
  Future<void> updateSettings({String? city, bool? morningAlarm});
}
