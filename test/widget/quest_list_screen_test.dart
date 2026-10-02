import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tium/app/theme.dart';
import 'package:tium/data/providers.dart';
import 'package:tium/data/repositories/fake_garden_repository.dart';
import 'package:tium/views/quest/quest_list_screen.dart';

void main() {
  Widget app() => ProviderScope(
        overrides: [
          gardenRepositoryProvider.overrideWithValue(FakeGardenRepository(latency: Duration.zero)),
        ],
        child: MaterialApp(theme: AppTheme.light(), home: const QuestListScreen()),
      );

  testWidgets('퀘스트 목록이 보이고 카테고리로 거를 수 있다', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('책 20분 읽기'), findsOneWidget);
    expect(find.text('코딩 연습하기'), findsOneWidget);
    expect(find.byType(QuestCard), findsNWidgets(5));

    await tester.tap(find.text('생활'));
    await tester.pumpAndSettle();

    expect(find.byType(QuestCard), findsNWidgets(2));
    expect(find.text('물 2L 마시기'), findsOneWidget);
    expect(find.text('코딩 연습하기'), findsNothing);
  });
}
