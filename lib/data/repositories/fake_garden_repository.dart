import 'dart:async';
import 'dart:math';

import '../../models/category.dart';
import '../../models/completion.dart';
import '../../models/greenhouse.dart';
import '../../models/petal.dart';
import '../../models/quest.dart';
import '../../models/user_profile.dart';
import '../../utils/date_key.dart';
import '../../utils/level.dart';
import 'garden_repository.dart';

/// 메모리에만 저장하는 가짜 저장소. 앱을 다시 켜면 처음 데이터로 돌아간다.
class FakeGardenRepository implements GardenRepository {
  FakeGardenRepository({
    this.latency = const Duration(milliseconds: 350),
    DateTime Function()? clock,
    Random? random,
    bool seed = true,
  })  : _clock = clock ?? DateTime.now,
        _random = random ?? Random() {
    if (seed) _seed();
  }

  final Duration latency;
  final DateTime Function() _clock;
  final Random _random;

  UserProfile _profile = const UserProfile(uid: 'local-user');
  final List<Quest> _quests = [];
  final Map<String, Completion> _completions = {};
  final List<GreenhouseItem> _greenhouse = [];
  final _changes = StreamController<void>.broadcast();
  int _idSeq = 100;

  /// 모두 완료 보너스를 받은 날 (하루 한 번만 주기 위해)
  String? _allClearDay;

  String get _today => dateKey(_clock());

  // ---------- 시연용 처음 데이터 ----------

  void _seed() {
    final now = _clock();
    DateTime ago(int days) => now.subtract(Duration(days: days));

    // Lv.3 새싹 정원사, 다음 레벨까지 20 XP 남은 상태로 시작한다.
    _profile = _profile.copyWith(totalXp: 430, bestStreak: 9);

    Quest q(String id, String title, QuestCategory c, {required int growth, required int harvests, required String petal, required int age}) =>
        Quest(
          id: id,
          title: title,
          category: c,
          growth: growth,
          harvestCount: harvests,
          completionCount: harvests * harvestAt + growth,
          petalId: petal,
          createdAt: ago(age),
          plantedAt: ago(growth + 3),
        );
    _quests.addAll([
      q('q1', '책 20분 읽기', QuestCategory.reading, growth: 9, harvests: 1, petal: 'yellow', age: 60),
      // 다 자라서 바로 수확해 볼 수 있는 식물
      q('q2', '코딩 연습하기', QuestCategory.coding, growth: 21, harvests: 1, petal: 'pink', age: 55),
      q('q3', '물 2L 마시기', QuestCategory.life, growth: 1, harvests: 0, petal: 'white', age: 6),
      q('q4', '영어 단어 20개', QuestCategory.study, growth: 0, harvests: 0, petal: 'orange', age: 1),
      q('q5', '스트레칭 10분', QuestCategory.life, growth: 15, harvests: 4, petal: 'yellow', age: 120),
    ]);

    GreenhouseItem g(String id, String questId, String title, QuestCategory c, String petal, int planted, int harvested) => GreenhouseItem(
          id: id,
          questId: questId,
          questTitle: title,
          kind: c.plant,
          petalId: petal,
          plantedAt: ago(planted),
          harvestedAt: ago(harvested),
          growth: harvestAt,
        );
    _greenhouse.addAll([
      g('g1', 'q5', '스트레칭 10분', QuestCategory.life, 'red', 118, 96),
      g('g2', 'q5', '스트레칭 10분', QuestCategory.life, 'red', 95, 73),
      g('g3', 'q1', '책 20분 읽기', QuestCategory.reading, 'pink', 58, 35),
      g('g4', 'q2', '코딩 연습하기', QuestCategory.coding, 'purple', 54, 31),
      g('g5', 'q5', '스트레칭 10분', QuestCategory.life, 'red', 72, 50), // 빨강 장미 3송이 → 꽃다발 배지
      g('g6', 'q5', '스트레칭 10분', QuestCategory.life, 'blue', 49, 26), // 희귀 색
    ]);

    // 최근 완료 기록 (기록 화면·연속 실천용). q1~q3는 오늘 완료한 상태 → 연속 실천 13일.
    const doneToday = {'q1', 'q2', 'q3'};
    for (final quest in _quests) {
      // 오늘 완료한 퀘스트는 오늘부터, 나머지는 어제부터 하루도 빠짐없이 거슬러 올라간다.
      final recent = min(quest.completionCount, 12);
      final offset = doneToday.contains(quest.id) ? 0 : 1;
      for (var i = 0; i < recent; i++) {
        final day = ago(i + offset);
        final c = Completion(questId: quest.id, questTitle: quest.title, category: quest.category, dateKey: dateKey(day), xp: questXp);
        _completions[c.id] = c;
      }
    }
  }

  // ---------- 조회 ----------

  List<Quest> _questSnapshot() => [
        for (final q in _quests) q.copyWith(doneToday: _completions.containsKey(completionId(q.id, _clock()))),
      ];

  /// 하나 이상 완료한 날이 며칠 연속인지. 오늘 아직 안 했으면 어제부터 센다.
  int _currentStreak() {
    final days = _completions.values.map((c) => c.dateKey).toSet();
    var streak = 0;
    var cursor = _clock();
    if (!days.contains(dateKey(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    while (days.contains(dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  UserProfile _profileSnapshot() {
    final streak = _currentStreak();
    final best = streak > _profile.bestStreak ? streak : _profile.bestStreak;
    return _profile.copyWith(streak: streak, bestStreak: best);
  }

  Stream<T> _watch<T>(T Function() snapshot) async* {
    await Future<void>.delayed(latency);
    yield snapshot();
    yield* _changes.stream.map((_) => snapshot());
  }

  @override
  Stream<UserProfile> watchProfile() => _watch(_profileSnapshot);

  @override
  Stream<List<Quest>> watchQuests() => _watch(_questSnapshot);

  @override
  Stream<List<Completion>> watchCompletions() => _watch(() => _completions.values.toList());

  @override
  Stream<List<GreenhouseItem>> watchGreenhouse() =>
      _watch(() => [..._greenhouse]..sort((a, b) => b.harvestedAt.compareTo(a.harvestedAt)));

  // ---------- 변경 ----------

  void _emit() => _changes.add(null);

  int _indexOf(String questId) {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index < 0) throw StateError('퀘스트를 찾을 수 없어요: $questId');
    return index;
  }

  @override
  Future<CompletionResult> completeQuest(String questId) async {
    await Future<void>.delayed(latency);
    final index = _indexOf(questId);
    final quest = _quests[index];
    final id = completionId(questId, _clock());
    if (_completions.containsKey(id)) throw const AlreadyCompletedException();

    // Firestore에서는 이 블록이 runTransaction 안에 들어간다.
    final today = _today;
    final firstToday = !_completions.values.any((c) => c.dateKey == today);
    final before = levelInfo(_profile.totalXp);

    // 보너스 1: 이번 완료로 오늘의 활성 퀘스트를 '처음' 모두 끝냈다면 (하루 한 번)
    final activeIds = _quests.where((q) => q.active).map((q) => q.id).toSet();
    bool doneNow(String id) => _completions.containsKey(completionId(id, _clock()));
    final wasAllDone = activeIds.every(doneNow);
    final allDone = !wasAllDone && _allClearDay != today && quest.active && activeIds.every((id) => id == questId || doneNow(id));
    final allClear = allDone ? allClearBonusXp : 0;
    if (allDone) _allClearDay = today;

    final updated = quest.copyWith(completionCount: quest.completionCount + 1, growth: quest.growth + 1);
    _quests[index] = updated;

    // 보너스 2: 오늘 첫 완료로 연속 일수가 7의 배수가 됐다면 (오늘 완료를 넣은 뒤 센다)
    _completions[id] = Completion(questId: questId, questTitle: quest.title, category: quest.category, dateKey: today, xp: questXp + allClear);
    final streak = _currentStreak();
    final streakBonus = firstToday && streak > 0 && streak % streakBonusEvery == 0 ? streakBonusXp : 0;
    // 완료 문서에는 이번에 받은 XP 전부를 기록한다.
    _completions[id] = Completion(
      questId: questId,
      questTitle: quest.title,
      category: quest.category,
      dateKey: today,
      xp: questXp + allClear + streakBonus,
    );

    final result = CompletionResult(
      quest: updated.copyWith(doneToday: true),
      before: before,
      after: levelInfo(_profile.totalXp + questXp + allClear + streakBonus),
      allClearBonus: allClear,
      streakBonus: streakBonus,
      streak: streak,
    );
    _profile = _profile.copyWith(totalXp: _profile.totalXp + result.gainedXp);
    _emit();
    return result;
  }

  @override
  Future<HarvestResult> harvest(String questId) async {
    await Future<void>.delayed(latency);
    final index = _indexOf(questId);
    final quest = _quests[index];
    if (!quest.canHarvest) throw const NotReadyToHarvestException();

    // Firestore에서는 greenhouse 문서 생성 + 퀘스트 growth 초기화를 한 트랜잭션으로 한다.
    final petal = quest.petal;
    final isNewColor = !_greenhouse.any((g) => g.kind == quest.plant && g.petalId == petal.id);
    final now = _clock();
    final item = GreenhouseItem(
      id: 'g${_idSeq++}',
      questId: quest.id,
      questTitle: quest.title,
      kind: quest.plant,
      petalId: petal.id,
      plantedAt: quest.plantedAt,
      harvestedAt: now,
      growth: quest.growth,
    );
    _greenhouse.add(item);
    final sameColor = _greenhouse.where((g) => g.kind == item.kind && g.petalId == item.petalId).length;
    final tierNow = BadgeTier.of(sameColor);
    final newBadge = tierNow != null && tierNow.count == sameColor ? tierNow : null;
    final replanted = quest.copyWith(
      growth: 0,
      harvestCount: quest.harvestCount + 1,
      petalId: PetalPalette.pick(quest.plant, _random).id,
      plantedAt: now,
    );
    _quests[index] = replanted;
    _emit();
    return HarvestResult(
      item: item,
      quest: replanted,
      isNewColor: isNewColor,
      sameColorCount: sameColor,
      newBadge: newBadge,
    );
  }

  @override
  Future<Quest> addQuest(QuestDraft draft) async {
    await Future<void>.delayed(latency);
    final quest = Quest(
      id: 'q${_idSeq++}',
      title: draft.title,
      category: draft.category,
      description: draft.description,
      bookTitle: draft.bookTitle,
      petalId: PetalPalette.pick(draft.category.plant, _random).id,
      createdAt: _clock(),
    );
    _quests.add(quest);
    _emit();
    return quest;
  }

  @override
  Future<void> updateQuest(Quest quest) async {
    await Future<void>.delayed(latency);
    final index = _quests.indexWhere((q) => q.id == quest.id);
    if (index >= 0) {
      final old = _quests[index];
      // 카테고리를 바꾸면 식물 종류가 바뀌므로 그 꽃의 색을 새로 뽑는다.
      final petalId = old.category == quest.category ? quest.petalId : PetalPalette.pick(quest.plant, _random).id;
      _quests[index] = quest.copyWith(doneToday: false, petalId: petalId);
    }
    _emit();
  }

  @override
  Future<void> setQuestActive(String questId, {required bool active}) async {
    final index = _quests.indexWhere((q) => q.id == questId);
    if (index >= 0) _quests[index] = _quests[index].copyWith(active: active);
    _emit();
  }

  @override
  Future<void> updateSettings({String? city, bool? morningAlarm}) async {
    _profile = _profile.copyWith(city: city, morningAlarm: morningAlarm);
    _emit();
  }

  void dispose() => _changes.close();
}
