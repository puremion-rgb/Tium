import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../models/completion.dart';
import '../models/greenhouse.dart';
import '../models/quest.dart';
import '../models/user_profile.dart';
import '../models/weather.dart';

/// 저장소의 스트림을 화면에서 바로 쓸 수 있게 감싼 공통 Provider들.

final profileProvider = StreamProvider<UserProfile>(
  (ref) => ref.watch(gardenRepositoryProvider).watchProfile(),
);

final questsProvider = StreamProvider<List<Quest>>(
  (ref) => ref.watch(gardenRepositoryProvider).watchQuests(),
);

final completionsProvider = StreamProvider<List<Completion>>(
  (ref) => ref.watch(gardenRepositoryProvider).watchCompletions(),
);

final greenhouseProvider = StreamProvider<List<GreenhouseItem>>(
  (ref) => ref.watch(gardenRepositoryProvider).watchGreenhouse(),
);

/// 사용자가 고른 도시의 현재 날씨. 실패해도 홈은 그대로 보여야 하므로 따로 둔다.
final weatherProvider = FutureProvider<Weather>((ref) async {
  final city = await ref.watch(profileProvider.selectAsync((p) => p.city));
  return ref.watch(weatherRepositoryProvider).fetch(city);
});

/// 날씨를 못 불러왔을 때 쓸 정원 배경
WeatherKind gardenWeatherOf(AsyncValue<Weather> weather) => weather.valueOrNull?.kind ?? WeatherKind.sunny;
