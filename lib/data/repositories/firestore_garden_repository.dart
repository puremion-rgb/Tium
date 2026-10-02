import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/category.dart';
import '../../models/completion.dart';
import '../../models/greenhouse.dart';
import '../../models/petal.dart';
import '../../models/quest.dart';
import '../../models/user_profile.dart';
import '../../utils/date_key.dart';
import '../../utils/level.dart';
import 'garden_repository.dart';

/// Firestore에 저장하는 실제 저장소.
///
/// users/{uid}                       프로필 (totalXp, city, streak, lastDoneDay, allClearDay ...)
/// users/{uid}/quests/{questId}      퀘스트
/// users/{uid}/completions/{questId_yyyyMMdd}  하루 한 번 완료 기록 (문서 ID로 중복 방지)
/// users/{uid}/greenhouse/{itemId}   수확한 꽃
class FirestoreGardenRepository implements GardenRepository {
  FirestoreGardenRepository({
    required FirebaseFirestore db,
    required FirebaseAuth auth,
    this.seedDemoOnFirstRun = false,
    Random? random,
  })  : _db = db,
        _auth = auth,
        _random = random ?? Random();

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final Random _random;

  /// 처음 로그인한 사용자에게 시연용 데이터를 넣을지
  final bool seedDemoOnFirstRun;

  Future<String>? _ready;

  // ---------- 준비: 익명 로그인 + 사용자 문서 ----------

  /// 로그인돼 있지 않으면 익명 로그인하고, 사용자 문서가 없으면 만든다.
  /// 실패하면 다음 호출 때 다시 시도한다 (화면의 '다시 시도' 버튼).
  Future<String> _uid() {
    return _ready ??= () async {
      try {
        final user = _auth.currentUser ?? (await _auth.signInAnonymously()).user!;
        final userRef = _users.doc(user.uid);
        final snap = await userRef.get();
        if (!snap.exists) {
          if (seedDemoOnFirstRun) {
            await _seedDemo(user.uid);
          } else {
            await userRef.set({...UserProfile(uid: user.uid).toMap(), 'createdAt': FieldValue.serverTimestamp()});
          }
        }
        return user.uid;
      } catch (e) {
        _ready = null;
        rethrow;
      }
    }();
  }

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  DocumentReference<Map<String, dynamic>> _userRef(String uid) => _users.doc(uid);
  CollectionReference<Map<String, dynamic>> _quests(String uid) => _userRef(uid).collection('quests');
  CollectionReference<Map<String, dynamic>> _completions(String uid) => _userRef(uid).collection('completions');
  CollectionReference<Map<String, dynamic>> _greenhouse(String uid) => _userRef(uid).collection('greenhouse');

  String get _today => dateKey();
  String get _yesterday => dateKey(DateTime.now().subtract(const Duration(days: 1)));

  /// 연속 기록은 마지막으로 한 날이 오늘이나 어제일 때만 이어진다.
  UserProfile _profileFrom(String uid, Map<String, dynamic> data) {
    final p = UserProfile.fromMap(uid, data);
    final last = data['lastDoneDay'] as String?;
    final alive = last == _today || last == _yesterday;
    return alive ? p : p.copyWith(streak: 0);
  }

  Stream<T> _afterLogin<T>(Stream<T> Function(String uid) build) async* {
    final uid = await _uid();
    yield* build(uid);
  }

  // ---------- 조회 ----------

  @override
  Stream<UserProfile> watchProfile() => _afterLogin(
        (uid) => _userRef(uid).snapshots().where((s) => s.exists).map((s) => _profileFrom(uid, s.data()!)),
      );

  @override
  Stream<List<Quest>> watchQuests() => _afterLogin((uid) {
        final quests = _quests(uid).orderBy('createdAt').snapshots();
        final doneToday = _completions(uid)
            .where('dateKey', isEqualTo: _today)
            .snapshots()
            .map((s) => s.docs.map((d) => d.data()['questId'] as String).toSet());
        return _combine(quests, doneToday, (q, done) => [
              for (final d in q.docs) Quest.fromMap(d.id, d.data(), doneToday: done.contains(d.id)),
            ]);
      });

  /// 기록 화면용: 최근 120일
  @override
  Stream<List<Completion>> watchCompletions() => _afterLogin((uid) {
        final from = dateKey(DateTime.now().subtract(const Duration(days: 120)));
        return _completions(uid)
            .where('dateKey', isGreaterThanOrEqualTo: from)
            .snapshots()
            .map((s) => s.docs.map((d) => Completion.fromMap(d.data())).toList());
      });

  @override
  Stream<List<GreenhouseItem>> watchGreenhouse() => _afterLogin(
        (uid) => _greenhouse(uid)
            .orderBy('harvestedAt', descending: true)
            .snapshots()
            .map((s) => s.docs.map((d) => GreenhouseItem.fromMap(d.id, d.data())).toList()),
      );

  // ---------- 완료 (트랜잭션) ----------

  @override
  Future<CompletionResult> completeQuest(String questId) async {
    final uid = await _uid();
    final today = _today;
    final yesterday = _yesterday;
    final compRef = _completions(uid).doc('${questId}_$today');

    // 빠른 확인: 이미 했으면 트랜잭션까지 가지 않는다. (트랜잭션 안에서 한 번 더 확인)
    if ((await compRef.get()).exists) throw const AlreadyCompletedException();

    // 트랜잭션 안에서는 쿼리를 못 하므로, 활성 퀘스트 목록은 먼저 읽는다.
    final activeIds = (await _quests(uid).where('active', isEqualTo: true).get()).docs.map((d) => d.id).toList();

    return _db.runTransaction<CompletionResult>((tx) async {
      // 1) 읽기 (쓰기 전에 전부)
      final compSnap = await tx.get(compRef);
      if (compSnap.exists) throw const AlreadyCompletedException();

      final questSnap = await tx.get(_quests(uid).doc(questId));
      if (!questSnap.exists) throw StateError('퀘스트를 찾을 수 없어요');
      final quest = Quest.fromMap(questSnap.id, questSnap.data()!);

      final userSnap = await tx.get(_userRef(uid));
      final userData = userSnap.data() ?? const <String, dynamic>{};
      final user = UserProfile.fromMap(uid, userData);
      final lastDoneDay = userData['lastDoneDay'] as String?;
      final allClearDay = userData['allClearDay'] as String?;

      var othersDone = true;
      for (final id in activeIds) {
        if (id == questId) continue;
        final s = await tx.get(_completions(uid).doc('${id}_$today'));
        if (!s.exists) {
          othersDone = false;
          break;
        }
      }

      // 2) 계산
      final firstToday = lastDoneDay != today;
      final streak = firstToday ? (lastDoneDay == yesterday ? user.streak + 1 : 1) : user.streak;
      final allDone = quest.active && allClearDay != today && othersDone && activeIds.contains(questId);
      final allClear = allDone ? allClearBonusXp : 0;
      final streakBonus = firstToday && streak % streakBonusEvery == 0 ? streakBonusXp : 0;
      final gained = questXp + allClear + streakBonus;
      final updated = quest.copyWith(completionCount: quest.completionCount + 1, growth: quest.growth + 1);

      // 3) 쓰기
      tx.set(compRef, {
        ...Completion(questId: questId, questTitle: quest.title, category: quest.category, dateKey: today, xp: gained).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(_quests(uid).doc(questId), {'completionCount': updated.completionCount, 'growth': updated.growth});
      tx.set(
        _userRef(uid),
        {
          'totalXp': user.totalXp + gained,
          'streak': streak,
          'bestStreak': max(user.bestStreak, streak),
          'lastDoneDay': today,
          if (allDone) 'allClearDay': today,
        },
        SetOptions(merge: true),
      );

      return CompletionResult(
        quest: updated.copyWith(doneToday: true),
        before: levelInfo(user.totalXp),
        after: levelInfo(user.totalXp + gained),
        allClearBonus: allClear,
        streakBonus: streakBonus,
        streak: streak,
      );
    });
  }

  // ---------- 수확 (트랜잭션) ----------

  @override
  Future<HarvestResult> harvest(String questId) async {
    final uid = await _uid();
    final questRef = _quests(uid).doc(questId);

    // 같은 색을 몇 송이 모았는지는 미리 센다 (트랜잭션 안에서는 쿼리 불가).
    final pre = await questRef.get();
    if (!pre.exists) throw StateError('퀘스트를 찾을 수 없어요');
    final preQuest = Quest.fromMap(pre.id, pre.data()!);
    if (!preQuest.canHarvest) throw const NotReadyToHarvestException();
    final sameBefore = (await _greenhouse(uid)
            .where('kind', isEqualTo: preQuest.plant.name)
            .where('petalId', isEqualTo: preQuest.petal.id)
            .get())
        .docs
        .length;

    final itemRef = _greenhouse(uid).doc();
    return _db.runTransaction<HarvestResult>((tx) async {
      final snap = await tx.get(questRef);
      final quest = Quest.fromMap(snap.id, snap.data()!);
      if (!quest.canHarvest) throw const NotReadyToHarvestException();

      final now = DateTime.now();
      final item = GreenhouseItem(
        id: itemRef.id,
        questId: quest.id,
        questTitle: quest.title,
        kind: quest.plant,
        petalId: quest.petal.id,
        plantedAt: quest.plantedAt,
        harvestedAt: now,
        growth: quest.growth,
      );
      final replanted = quest.copyWith(
        growth: 0,
        harvestCount: quest.harvestCount + 1,
        petalId: PetalPalette.pick(quest.plant, _random).id,
        plantedAt: now,
      );
      tx.set(itemRef, item.toMap());
      tx.update(questRef, {
        'growth': 0,
        'harvestCount': replanted.harvestCount,
        'petalId': replanted.petalId,
        'plantedAt': now.toIso8601String(),
      });

      final same = sameBefore + 1;
      final tier = BadgeTier.of(same);
      return HarvestResult(
        item: item,
        quest: replanted,
        isNewColor: sameBefore == 0,
        sameColorCount: same,
        newBadge: tier != null && tier.count == same ? tier : null,
      );
    });
  }

  // ---------- 퀘스트 · 설정 ----------

  @override
  Future<Quest> addQuest(QuestDraft draft) async {
    final uid = await _uid();
    final ref = _quests(uid).doc();
    final quest = Quest(
      id: ref.id,
      title: draft.title,
      category: draft.category,
      description: draft.description,
      bookTitle: draft.bookTitle,
      petalId: PetalPalette.pick(draft.category.plant, _random).id,
      createdAt: DateTime.now(),
    );
    await ref.set(quest.toMap());
    return quest;
  }

  @override
  Future<void> updateQuest(Quest quest) async {
    final uid = await _uid();
    final ref = _quests(uid).doc(quest.id);
    final old = await ref.get();
    final oldCategory = QuestCategory.fromName(old.data()?['category'] as String? ?? quest.category.name);
    // 카테고리를 바꾸면 식물 종류가 바뀌므로 그 꽃의 색을 새로 뽑는다.
    final petalId = oldCategory == quest.category ? quest.petalId : PetalPalette.pick(quest.plant, _random).id;
    await ref.update({
      'title': quest.title,
      'category': quest.category.name,
      'description': quest.description,
      'petalId': petalId,
    });
  }

  @override
  Future<void> setQuestActive(String questId, {required bool active}) async {
    final uid = await _uid();
    await _quests(uid).doc(questId).update({'active': active});
  }

  @override
  Future<void> updateSettings({String? city, bool? morningAlarm}) async {
    final uid = await _uid();
    await _userRef(uid).set({
      if (city != null) 'city': city,
      if (morningAlarm != null) 'morningAlarm': morningAlarm,
    }, SetOptions(merge: true));
  }

  // ---------- 시연용 데이터 ----------

  /// 처음 실행할 때 정원이 비어 보이지 않도록 넣는 예시 데이터 (가짜 저장소와 같은 내용)
  Future<void> _seedDemo(String uid) async {
    final now = DateTime.now();
    DateTime ago(int d) => now.subtract(Duration(days: d));
    final batch = _db.batch();

    batch.set(_userRef(uid), {
      ...UserProfile(uid: uid, totalXp: 430, streak: 13, bestStreak: 13).toMap(),
      'lastDoneDay': dateKey(now),
      'createdAt': FieldValue.serverTimestamp(),
    });

    Quest q(String id, String title, QuestCategory c, int growth, int harvests, String petal) => Quest(
          id: id,
          title: title,
          category: c,
          growth: growth,
          harvestCount: harvests,
          completionCount: harvests * harvestAt + growth,
          petalId: petal,
          createdAt: ago(60 - id.codeUnitAt(1)),
          plantedAt: ago(growth + 3),
        );
    final quests = [
      q('q1', '책 20분 읽기', QuestCategory.reading, 9, 1, 'yellow'),
      q('q2', '코딩 연습하기', QuestCategory.coding, 21, 1, 'pink'),
      q('q3', '물 2L 마시기', QuestCategory.life, 1, 0, 'white'),
      q('q4', '영어 단어 20개', QuestCategory.study, 0, 0, 'orange'),
      q('q5', '스트레칭 10분', QuestCategory.life, 15, 4, 'yellow'),
    ];
    for (final quest in quests) {
      batch.set(_quests(uid).doc(quest.id), quest.toMap());
    }

    void g(String questId, String title, QuestCategory c, String petal, int planted, int harvested) {
      final ref = _greenhouse(uid).doc();
      batch.set(
        ref,
        GreenhouseItem(
          id: ref.id,
          questId: questId,
          questTitle: title,
          kind: c.plant,
          petalId: petal,
          plantedAt: ago(planted),
          harvestedAt: ago(harvested),
          growth: harvestAt,
        ).toMap(),
      );
    }

    g('q5', '스트레칭 10분', QuestCategory.life, 'red', 118, 96);
    g('q5', '스트레칭 10분', QuestCategory.life, 'red', 95, 73);
    g('q1', '책 20분 읽기', QuestCategory.reading, 'pink', 58, 35);
    g('q2', '코딩 연습하기', QuestCategory.coding, 'purple', 54, 31);
    g('q5', '스트레칭 10분', QuestCategory.life, 'red', 72, 50);
    g('q5', '스트레칭 10분', QuestCategory.life, 'blue', 49, 26);

    // 최근 완료 기록: q1~q3는 오늘까지, q5는 어제까지 12일 연속
    const doneToday = {'q1', 'q2', 'q3'};
    for (final quest in quests) {
      final recent = min(quest.completionCount, 12);
      final offset = doneToday.contains(quest.id) ? 0 : 1;
      for (var i = 0; i < recent; i++) {
        final c = Completion(questId: quest.id, questTitle: quest.title, category: quest.category, dateKey: dateKey(ago(i + offset)), xp: questXp);
        batch.set(_completions(uid).doc(c.id), c.toMap());
      }
    }
    await batch.commit();
  }
}

/// 두 스트림의 최신 값을 합친다 (둘 다 한 번 이상 값을 낸 뒤부터).
Stream<R> _combine<A, B, R>(Stream<A> a, Stream<B> b, R Function(A, B) combine) {
  late StreamController<R> controller;
  StreamSubscription<A>? subA;
  StreamSubscription<B>? subB;
  A? lastA;
  B? lastB;
  var hasA = false;
  var hasB = false;

  void emit() {
    if (hasA && hasB) controller.add(combine(lastA as A, lastB as B));
  }

  controller = StreamController<R>(
    onListen: () {
      subA = a.listen((v) {
        lastA = v;
        hasA = true;
        emit();
      }, onError: controller.addError);
      subB = b.listen((v) {
        lastB = v;
        hasB = true;
        emit();
      }, onError: controller.addError);
    },
    onCancel: () async {
      await subA?.cancel();
      await subB?.cancel();
    },
  );
  return controller.stream;
}
