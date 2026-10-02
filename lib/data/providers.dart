import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather.dart';
import 'repositories/book_repository.dart';
import 'repositories/fake_garden_repository.dart';
import 'repositories/firestore_garden_repository.dart';
import 'repositories/garden_repository.dart';
import 'repositories/weather_repository.dart';

/// 스위치들.
/// - useFakeGarden: true면 메모리(가짜) 저장소, false면 Firestore에 실제로 저장
/// - seedDemoOnFirstRun: Firestore를 쓸 때, 처음 로그인한 사용자에게 시연용 정원을 넣어 줄지
const useFakeGarden = false;
const seedDemoOnFirstRun = true;
const useFakeBooks = false; // 한글 책 검색은 카카오 키가 필요하다 (README 참고).
const useFakeWeather = false; // Open-Meteo도 키가 없다.

final gardenRepositoryProvider = Provider<GardenRepository>((ref) {
  if (useFakeGarden) {
    final repo = FakeGardenRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  return FirestoreGardenRepository(
    db: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
    seedDemoOnFirstRun: seedDemoOnFirstRun,
  );
});

final bookRepositoryProvider = Provider<BookRepository>(
  (ref) => useFakeBooks ? const FakeBookRepository() : ApiBookRepository(),
);

/// 발표·디자인 확인용 날씨 미리보기. null이면 실제 날씨를 쓴다.
final weatherPreviewProvider = StateProvider<WeatherKind?>((ref) => null);

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final preview = ref.watch(weatherPreviewProvider);
  if (preview != null) return FakeWeatherRepository(kind: preview);
  return useFakeWeather ? const FakeWeatherRepository() : OpenMeteoWeatherRepository();
});
