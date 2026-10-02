import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 익명 로그인은 저장소(FirestoreGardenRepository)가 처음 쓰일 때 한다.
  // 인터넷이 없어도 앱은 켜지고, 화면에서 '다시 시도'로 다시 로그인할 수 있다.
  // Day 8: FirebaseMessaging.onMessage 등록 (앱 안 알림 = showDailyQuestDialog)
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: TiumApp()));
}
