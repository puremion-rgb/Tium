# 틔움 (Tium)

퀘스트로 키우는 나만의 습관 정원. 작은 실천이 싹이 되고, 꾸준함이 나를 키운다.

## 처음 실행하기

이 폴더에는 `lib/`, `assets/`, `test/`만 있고 안드로이드·iOS 폴더는 아직 없어요. 처음 한 번만 아래 순서로 만들어 주세요.

```bash
cd tium_app
flutter create . --project-name tium --org com.tium --platforms=android,ios   # lib/ 파일은 덮어쓰지 않아요
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

- `flutter create`가 `test/widget_test.dart`를 새로 만들면 지워 주세요. 기본 카운터 앱용 테스트라 실패해요.
- 이미지를 바꾼 뒤에는 앱을 완전히 껐다가 다시 실행하세요. 핫 리로드로는 반영이 안 될 때가 많아요.

## 책 검색 키 넣기 (카카오)

한글 책 검색은 카카오 책 검색 API를 써요. 키는 코드에 쓰지 않고 `env.json` 파일로 넣어요.

1. `env.example.json`을 복사해서 `env.json`으로 이름을 바꾸고 카카오 REST API 키를 넣어요. (`env.json`은 .gitignore에 있어서 GitHub에 올라가지 않아요)
2. 실행할 때 파일을 지정해요.
   ```bash
   flutter run --dart-define-from-file=env.json
   flutter build apk --release --dart-define-from-file=env.json
   ```

키가 없어도 앱은 돌아가요. 그때는 영어 검색만 Open Library로 찾아요.

## 지금 상태 (Day 3~5: 가짜 데이터로 UI 완성)

| 기능 | 상태 |
|---|---|
| 24개 화면 | 완성 (가짜 데이터로 동작) |
| 퀘스트 저장 | `FakeGardenRepository` (앱을 끄면 처음 데이터로 돌아감) |
| 도서 검색 | 한글: 카카오 책 검색 (키 필요) · 영어: Open Library |
| 날씨 | Open-Meteo 실제 API (정원 전체 보기에서 날씨 미리보기 가능) |
| 푸시 알림 | `FakeNotificationService` (Day 8에 FCM으로 교체) |

스위치는 `lib/data/providers.dart`에 모여 있어요. 인터넷 없이 시연할 때는 `useFakeBooks`, `useFakeWeather`를 `true`로 바꾸세요.

## 구조 (MVVM)

```
View (views/)  →  ViewModel (viewmodels/, Riverpod)  →  Repository (data/repositories/)  →  API · Firestore
```

```
lib/
├── app/          theme(색·글꼴), router(화면 경로), app_images(이미지 경로 한곳에)
├── models/       Quest, UserProfile, Completion, Book, Weather, 카테고리·식물
├── data/
│   ├── repositories/  GardenRepository(인터페이스) + Fake 구현, 도서·날씨 API
│   ├── services/      알림 (Day 8 FCM)
│   └── providers.dart 가짜/실제 구현 스위치
├── viewmodels/   화면별 상태와 동작
├── views/        onboarding · home · quest · book · records · my · feedback
├── widgets/      공통 카드·버튼·상태 화면, 정원(GardenScene)·식물·레벨 카드, 하단 탭
└── utils/        레벨 공식, 한국 시간 날짜 키, 조사
```

## 화면 ↔ 파일

| 번호 | 화면 | 파일 |
|---|---|---|
| 1 | 스플래시 | views/onboarding/splash_screen.dart |
| 2 | 시작 | views/onboarding/start_screen.dart |
| 3 | 홈 (정원) | views/home/home_screen.dart |
| 4 | 퀘스트 목록 | views/quest/quest_list_screen.dart |
| 5 | 퀘스트 추가·수정 | views/quest/quest_form_screen.dart |
| 6 · 7 | 도서 검색 · 상세 | views/book/ |
| 8 | 퀘스트 완료 | views/feedback/quest_complete_screen.dart |
| 9~12 | 정원 전체 보기 (날씨별) | views/home/garden_screen.dart |
| 13 | 기록 | views/records/records_screen.dart |
| 14 · 15 | MY · 도시 선택 | views/my/ |
| 16 | 알림 권한 안내 | views/onboarding/push_permission_screen.dart |
| 17~20 | 로딩 · 빈 화면 · 오류 · 이미 완료 | widgets/common/state_view.dart |
| 21 | 잠금 화면 알림 | FCM 시스템 알림 (Day 8) |
| 22 | 앱 안 알림 | views/home/daily_quest_dialog.dart |
| 23 | 퀘스트 상세 | views/quest/quest_detail_screen.dart |
| 24 | 레벨업 | views/feedback/level_up_screen.dart |

## 규칙

- XP: 완료마다 +10 (고정) · 오늘 퀘스트 모두 완료 +10 · 7일 연속마다 +30 — `lib/utils/level.dart` 상수
- 레벨: 누적 XP T(L) = 25(L−1)(L+2) → Lv2 100, Lv3 250, Lv4 450, Lv5 700
- 칭호: Lv1–2 씨앗 정원사 · Lv3 새싹 정원사 · Lv4–5 꽃 정원사 · Lv6+ 숲 정원사
- 식물 성장: 완료 0회 씨앗 · 1–2회 싹 · 3–6회 어린 식물 · 7회+ 다 자란 식물
- 카테고리: 공부 = 해바라기 · 코딩 = 라벤더 · 독서 = 튤립 · 생활 = 장미
- 하루 한 번: 완료 문서 ID `{questId}_{yyyyMMdd}` (한국 시간)

## 다음 단계

- **Day 6** Firebase 연결: `flutterfire configure` → `FirestoreGardenRepository` 작성(`GardenRepository` 구현, 완료는 `runTransaction`) → `providers.dart`의 `useFakeGarden = false`
- **Day 7** APK 빌드 확인: `flutter build apk --release`
- **Day 8** FCM: `NotificationService`를 FirebaseMessaging으로 구현, 토픽 `daily-quest`
- **Day 11–12** 테스트 보강 (Firestore 저장소는 fake_cloud_firestore로)
