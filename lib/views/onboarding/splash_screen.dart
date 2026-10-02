import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/providers.dart';
import '../../models/weather.dart';
import '../../widgets/common/tium_logo.dart';

/// 1. 스플래시 — 잠깐 보여 준 뒤, 처음이면 시작 화면으로, 이미 정원이 있으면 홈으로 간다.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      // 이 기기에서 이미 익명 로그인했다면(= 정원이 있다면) 바로 홈으로
      final returning = !useFakeGarden && FirebaseAuth.instance.currentUser != null;
      context.go(returning ? Routes.home : Routes.start);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppImages.garden(WeatherKind.sunny), fit: BoxFit.cover, alignment: const Alignment(0, 0.4)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.34, 0.56, 0.75, 1],
                colors: [Color(0xF7FCF8EE), Color(0xD9FCF8EE), Color(0x00FCF8EE), Color(0x00142814), Color(0x59142814)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 64),
                const TiumLogo(size: 78),
                const SizedBox(height: 14),
                const Text(
                  '퀘스트로 키우는\n나만의 습관 정원',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.primaryDark, height: 1.5),
                ),
                const Spacer(),
                Text(
                  '작은 실천이 싹이 되고,\n꾸준함이 나를 키운다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.6,
                    shadows: [Shadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
