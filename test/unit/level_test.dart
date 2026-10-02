import 'package:flutter_test/flutter_test.dart';
import 'package:tium/models/plant.dart';
import 'package:tium/models/weather.dart';
import 'package:tium/utils/date_key.dart';
import 'package:tium/utils/korean.dart';
import 'package:tium/utils/level.dart';

void main() {
  group('레벨 공식 T(L) = 25(L-1)(L+2)', () {
    test('레벨별 누적 XP', () {
      expect(xpForLevel(1), 0);
      expect(xpForLevel(2), 100);
      expect(xpForLevel(3), 250);
      expect(xpForLevel(4), 450);
      expect(xpForLevel(5), 700);
    });

    test('경계값에서 레벨이 바뀐다', () {
      expect(levelInfo(0).level, 1);
      expect(levelInfo(99).level, 1);
      expect(levelInfo(100).level, 2);
      expect(levelInfo(449).level, 3);
      expect(levelInfo(450).level, 4);
    });

    test('레벨 안 진행도는 현재 레벨 기준', () {
      final info = levelInfo(430); // Lv3: 250~450
      expect(info.xpInLevel, 180);
      expect(info.xpToNext, 200);
      expect(info.progress, closeTo(0.9, 0.0001));
    });

    test('음수 XP는 0으로 본다', () => expect(levelInfo(-10).level, 1));

    test('칭호', () {
      expect(titleForLevel(1), '씨앗 정원사');
      expect(titleForLevel(3), '새싹 정원사');
      expect(titleForLevel(5), '꽃 정원사');
      expect(titleForLevel(6), '숲 정원사');
    });
  });

  group('성장 단계 (21회에 다 자람)', () {
    test('씨앗을 심은 뒤 완료 횟수 → 단계', () {
      expect(stageFor(0), GrowthStage.seed);
      expect(stageFor(1), GrowthStage.sprout);
      expect(stageFor(6), GrowthStage.sprout);
      expect(stageFor(7), GrowthStage.young);
      expect(stageFor(20), GrowthStage.young);
      expect(stageFor(21), GrowthStage.adult);
      expect(stageFor(30), GrowthStage.adult);
    });

    test('다음 단계까지', () {
      expect(nextStageAt(0), 1);
      expect(nextStageAt(3), 7);
      expect(nextStageAt(15), harvestAt);
      expect(nextStageAt(21), isNull);
    });
  });

  group('날짜 키 (한국 시간)', () {
    test('UTC 15시는 한국 기준 다음 날', () {
      expect(dateKey(DateTime.utc(2026, 10, 1, 15, 30)), '20261002');
      expect(dateKey(DateTime.utc(2026, 10, 1, 14, 59)), '20261001');
    });

    test('완료 문서 ID', () => expect(completionId('q1', DateTime.utc(2026, 1, 5, 3)), 'q1_20260105'));
  });

  group('날씨 코드 매핑', () {
    test('WMO 코드 → 정원 날씨', () {
      expect(WeatherKind.fromWmo(0, isDay: true), WeatherKind.sunny);
      expect(WeatherKind.fromWmo(0, isDay: false), WeatherKind.night);
      expect(WeatherKind.fromWmo(3, isDay: true), WeatherKind.cloudy);
      expect(WeatherKind.fromWmo(61, isDay: true), WeatherKind.rain);
      expect(WeatherKind.fromWmo(95, isDay: false), WeatherKind.rain);
      expect(WeatherKind.fromWmo(73, isDay: true), WeatherKind.snow);
    });
  });

  group('조사', () {
    test('으로/로', () {
      expect(withRo('싹'), '싹으로');
      expect(withRo('어린 식물'), '어린 식물로');
      expect(withRo('나무'), '나무로');
    });

    test('이/가', () {
      expect(withIga('해바라기'), '해바라기가');
      expect(withIga('튤립'), '튤립이');
      expect(withIga('꽃 정원사'), '꽃 정원사가');
    });
  });
}
