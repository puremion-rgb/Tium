import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/book.dart';
import '../models/completion.dart';
import '../models/greenhouse.dart';
import '../views/book/book_detail_screen.dart';
import '../views/book/book_search_screen.dart';
import '../views/feedback/level_up_screen.dart';
import '../views/feedback/quest_complete_screen.dart';
import '../views/greenhouse/greenhouse_screen.dart';
import '../views/greenhouse/harvest_screen.dart';
import '../views/home/garden_screen.dart';
import '../views/home/home_screen.dart';
import '../views/my/city_select_screen.dart';
import '../views/my/my_screen.dart';
import '../views/onboarding/push_permission_screen.dart';
import '../views/onboarding/splash_screen.dart';
import '../views/onboarding/start_screen.dart';
import '../views/quest/quest_detail_screen.dart';
import '../views/quest/quest_form_screen.dart';
import '../views/quest/quest_list_screen.dart';
import '../views/records/records_screen.dart';
import '../widgets/navigation/main_shell.dart';

/// 화면 경로. 문자열을 여기저기 쓰지 않도록 모아 둔다.
class Routes {
  Routes._();
  static const splash = '/';
  static const start = '/start';
  static const permission = '/permission';
  static const home = '/home';
  static const quests = '/quests';
  static const records = '/records';
  static const my = '/my';
  static const garden = '/garden';
  static const questNew = '/quest/new';
  static String questDetail(String id) => '/quest/$id';
  static String questEdit(String id) => '/quest/$id/edit';
  static const books = '/books';
  static const bookDetail = '/books/detail';
  static const complete = '/complete';
  static const levelUp = '/level-up';
  static const city = '/city';
  static const greenhouse = '/greenhouse';
  static const harvest = '/harvest';
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: Routes.splash,
  routes: [
    GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
    GoRoute(path: Routes.start, builder: (_, __) => const StartScreen()),
    GoRoute(path: Routes.permission, builder: (_, __) => const PushPermissionScreen()),
    StatefulShellRoute.indexedStack(
      builder: (_, __, shell) => MainShell(shell: shell),
      branches: [
        StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, __) => const HomeScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: Routes.quests, builder: (_, __) => const QuestListScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: Routes.records, builder: (_, __) => const RecordsScreen())]),
        StatefulShellBranch(routes: [GoRoute(path: Routes.my, builder: (_, __) => const MyScreen())]),
      ],
    ),
    // 아래는 하단 탭 없이 전체 화면으로 열린다.
    GoRoute(path: Routes.garden, builder: (_, __) => const GardenScreen()),
    GoRoute(
      path: Routes.questNew,
      builder: (_, state) => QuestFormScreen(bookTitle: state.extra as String?),
    ),
    GoRoute(
      path: '/quest/:id',
      builder: (_, state) => QuestDetailScreen(questId: state.pathParameters['id']!),
      routes: [
        GoRoute(path: 'edit', builder: (_, state) => QuestFormScreen(questId: state.pathParameters['id'])),
      ],
    ),
    GoRoute(path: Routes.books, builder: (_, __) => const BookSearchScreen()),
    GoRoute(path: Routes.bookDetail, builder: (_, state) => BookDetailScreen(book: state.extra! as Book)),
    GoRoute(
      path: Routes.complete,
      pageBuilder: (_, state) => _fade(state, QuestCompleteScreen(result: state.extra! as CompletionResult)),
    ),
    GoRoute(
      path: Routes.levelUp,
      pageBuilder: (_, state) => _fade(state, LevelUpScreen(result: state.extra! as CompletionResult)),
    ),
    GoRoute(path: Routes.city, builder: (_, __) => const CitySelectScreen()),
    GoRoute(path: Routes.greenhouse, builder: (_, __) => const GreenhouseScreen()),
    GoRoute(
      path: Routes.harvest,
      pageBuilder: (_, state) => _fade(state, HarvestScreen(result: state.extra! as HarvestResult)),
    ),
  ],
);

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    );
