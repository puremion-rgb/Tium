import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tium/data/repositories/fake_garden_repository.dart';
import 'package:tium/models/category.dart';
import 'package:tium/models/completion.dart';
import 'package:tium/models/greenhouse.dart';
import 'package:tium/models/petal.dart';
import 'package:tium/models/plant.dart';
import 'package:tium/models/quest.dart';
import 'package:tium/utils/level.dart';

void main() {
  group('처음 데이터로', () {
    late FakeGardenRepository repo;

    setUp(() => repo = FakeGardenRepository(latency: Duration.zero));
    tearDown(() => repo.dispose());

    test('5개 퀘스트, 3개는 오늘 완료', () async {
      final quests = await repo.watchQuests().first;
      expect(quests, hasLength(5));
      expect(quests.where((q) => q.doneToday), hasLength(3));
    });

    test('완료하면 기본 10 XP와 완료 횟수가 함께 오른다', () async {
      final before = await repo.watchProfile().first;
      final result = await repo.completeQuest('q5'); // 자란 정도 15 → 16, 남은 퀘스트가 있어 보너스 없음
      final after = await repo.watchProfile().first;

      expect(result.gainedXp, questXp);
      expect(result.allClearBonus, 0);
      expect(after.totalXp, before.totalXp + questXp);
      expect(result.quest.growth, 16);
      expect(result.quest.completionCount, 4 * harvestAt + 16);
      expect(result.quest.doneToday, isTrue);
    });

    test('같은 날 두 번 완료하면 AlreadyCompletedException', () async {
      await repo.completeQuest('q4');
      expect(() => repo.completeQuest('q4'), throwsA(isA<AlreadyCompletedException>()));
    });

    test('이미 오늘 한 퀘스트는 바로 막힌다', () async {
      expect(() => repo.completeQuest('q1'), throwsA(isA<AlreadyCompletedException>()));
    });

    test('마지막 남은 퀘스트를 끝내면 모두 완료 보너스 +10', () async {
      await repo.completeQuest('q4');
      final last = await repo.completeQuest('q5');
      expect(last.allClearBonus, allClearBonusXp);
      expect(last.gainedXp, questXp + allClearBonusXp);
    });

    test('모두 완료 보너스는 하루 한 번만 (새 퀘스트를 추가해 끝내도 다시 안 줌)', () async {
      await repo.completeQuest('q4');
      final first = await repo.completeQuest('q5');
      expect(first.allClearBonus, allClearBonusXp);

      final extra = await repo.addQuest(const QuestDraft(title: '산책', category: QuestCategory.life));
      final again = await repo.completeQuest(extra.id);
      expect(again.allClearBonus, 0);
    });

    test('처음 데이터의 연속 실천은 13일', () async {
      expect((await repo.watchProfile().first).streak, 13);
    });

    test('430 XP에서 남은 두 개를 끝내면 450 XP 이상 → Lv3 → Lv4', () async {
      final first = await repo.completeQuest('q4'); // 440
      expect(first.leveledUp, isFalse);
      final last = await repo.completeQuest('q5'); // 440 + 10 + 보너스 10 = 460
      expect(last.before.level, 3);
      expect(last.after.level, 4);
      expect(last.leveledUp, isTrue);
    });

    test('첫 완료로 씨앗이 싹이 된다', () async {
      final result = await repo.completeQuest('q4'); // 자란 정도 0 → 1
      expect(result.quest.stage, GrowthStage.sprout);
      expect(result.stageChanged, isTrue);
    });

    test('새 퀘스트는 씨앗으로 심어지고 XP는 고정 10, 꽃잎 색이 정해진다', () async {
      final q = await repo.addQuest(const QuestDraft(title: '산책 20분', category: QuestCategory.life));
      final quests = await repo.watchQuests().first;
      expect(quests.any((x) => x.id == q.id && x.stage == GrowthStage.seed), isTrue);
      expect(q.plant, PlantKind.rose);
      expect(q.xp, questXp);
      expect(PetalPalette.of(PlantKind.rose).map((c) => c.id), contains(q.petalId));
    });

    test('쉬는 퀘스트도 정원에는 남는다', () async {
      await repo.setQuestActive('q2', active: false);
      final quests = await repo.watchQuests().first;
      expect(quests.firstWhere((q) => q.id == 'q2').active, isFalse);
      expect(quests, hasLength(5));
    });

    test('완료하면 스트림으로 바로 알려 준다', () async {
      final emitted = <List<Quest>>[];
      final sub = repo.watchQuests().listen(emitted.add);
      await Future<void>.delayed(Duration.zero);
      await repo.completeQuest('q4');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(emitted.last.firstWhere((q) => q.id == 'q4').doneToday, isTrue);
    });
  });

  group('수확과 온실', () {
    late FakeGardenRepository repo;

    setUp(() => repo = FakeGardenRepository(latency: Duration.zero, random: Random(1)));
    tearDown(() => repo.dispose());

    test('처음 온실에는 꽃 6송이', () async {
      expect(await repo.watchGreenhouse().first, hasLength(6));
    });

    test('다 자란 식물(q2)을 수확하면 온실에 담기고 새 씨앗이 심어진다', () async {
      final before = (await repo.watchQuests().first).firstWhere((q) => q.id == 'q2');
      expect(before.canHarvest, isTrue);

      final result = await repo.harvest('q2');

      expect(result.item.questTitle, '코딩 연습하기');
      expect(result.item.petalId, before.petalId);
      expect(result.item.growth, harvestAt);
      expect(result.quest.growth, 0);
      expect(result.quest.stage, GrowthStage.seed);
      expect(result.quest.harvestCount, before.harvestCount + 1);
      expect(result.quest.completionCount, before.completionCount, reason: '전체 완료 횟수는 줄지 않는다');

      final greenhouse = await repo.watchGreenhouse().first;
      expect(greenhouse, hasLength(7));
      expect(greenhouse.first.id, result.item.id, reason: '최근 수확이 맨 앞');
    });

    test('도감에 없던 색이면 isNewColor, 같은 색은 1송이째라 배지 없음', () async {
      // 처음 온실의 라벤더는 보라뿐, q2는 분홍 라벤더
      final result = await repo.harvest('q2');
      expect(result.isNewColor, isTrue);
      expect(result.sameColorCount, 1);
      expect(result.newBadge, isNull);
    });

    test('같은 색 모음 배지: 빨강 장미 3송이 → 꽃다발', () async {
      final collection = Collection(await repo.watchGreenhouse().first);
      expect(collection.countOf(PlantKind.rose, 'red'), 3);
      final badges = collection.badges;
      expect(badges, hasLength(1));
      expect(badges.first.tier, BadgeTier.bouquet);
      expect(badges.first.petal.id, 'red');
    });

    test('다 자라지 않은 식물은 수확할 수 없다', () async {
      expect(() => repo.harvest('q1'), throwsA(isA<NotReadyToHarvestException>()));
    });

    test('도감 집계', () async {
      final collection = Collection(await repo.watchGreenhouse().first);
      expect(collection.total, 20);
      expect(collection.collected, 4); // 장미 빨강·파랑, 튤립 분홍, 라벤더 보라
      expect(collection.colorsOf(PlantKind.rose), {'red', 'blue'});
    });

    test('21번 완료하면 수확할 수 있게 된다', () async {
      var now = DateTime.utc(2026, 10, 1, 3);
      final fresh = FakeGardenRepository(latency: Duration.zero, seed: false, clock: () => now);
      final q = await fresh.addQuest(const QuestDraft(title: '독서', category: QuestCategory.reading));
      CompletionResult? last;
      for (var i = 0; i < harvestAt; i++) {
        last = await fresh.completeQuest(q.id);
        now = now.add(const Duration(days: 1));
      }
      expect(last!.justBloomed, isTrue);
      expect(last.quest.canHarvest, isTrue);
      fresh.dispose();
    });
  });

  group('배지 단계', () {
    test('3송이 꽃다발 · 5송이 꽃바구니 · 10송이 꽃밭', () {
      expect(BadgeTier.of(2), isNull);
      expect(BadgeTier.of(3), BadgeTier.bouquet);
      expect(BadgeTier.of(4), BadgeTier.bouquet);
      expect(BadgeTier.of(5), BadgeTier.basket);
      expect(BadgeTier.of(10), BadgeTier.field);
      expect(BadgeTier.of(25), BadgeTier.field);
    });

    test('다음 배지', () {
      expect(BadgeTier.next(0), BadgeTier.bouquet);
      expect(BadgeTier.next(3), BadgeTier.basket);
      expect(BadgeTier.next(9), BadgeTier.field);
      expect(BadgeTier.next(10), isNull);
    });
  });

  group('연속 실천 보너스', () {
    test('7일째 첫 완료에 +30, 8일째에는 없음', () async {
      var now = DateTime.utc(2026, 10, 1, 3); // 한국 시간 낮 12시
      final repo = FakeGardenRepository(latency: Duration.zero, seed: false, clock: () => now);
      final quest = await repo.addQuest(const QuestDraft(title: '물 마시기', category: QuestCategory.life));

      final results = <CompletionResult>[];
      for (var day = 0; day < 8; day++) {
        results.add(await repo.completeQuest(quest.id));
        now = now.add(const Duration(days: 1));
      }

      // 퀘스트가 하나뿐이라 매일 '모두 완료' 보너스도 받는다.
      expect(results.map((r) => r.streak), [1, 2, 3, 4, 5, 6, 7, 8]);
      expect(results[5].streakBonus, 0);
      expect(results[6].streakBonus, streakBonusXp);
      expect(results[6].gainedXp, questXp + allClearBonusXp + streakBonusXp);
      expect(results[7].streakBonus, 0);

      final profile = await repo.watchProfile().first;
      expect(profile.totalXp, 8 * (questXp + allClearBonusXp) + streakBonusXp);
      repo.dispose();
    });

    test('하루를 건너뛰면 연속 일수가 다시 1부터', () async {
      var now = DateTime.utc(2026, 10, 1, 3);
      final repo = FakeGardenRepository(latency: Duration.zero, seed: false, clock: () => now);
      final quest = await repo.addQuest(const QuestDraft(title: '독서', category: QuestCategory.reading));

      final first = await repo.completeQuest(quest.id);
      now = now.add(const Duration(days: 2)); // 하루 건너뜀
      final second = await repo.completeQuest(quest.id);

      expect(first.streak, 1);
      expect(second.streak, 1);
      repo.dispose();
    });
  });
}
