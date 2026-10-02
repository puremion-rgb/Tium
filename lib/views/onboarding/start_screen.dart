import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../widgets/common/tium_logo.dart';

/// 2. 시작 화면
class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              const TiumLogo(size: 60),
              const SizedBox(height: 12),
              const Text(
                '퀘스트로 키우는\n나만의 습관 정원',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryDark, height: 1.5),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    AppImages.startIllustration,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    alignment: const Alignment(0, -0.2),
                    semanticLabel: '물뿌리개로 새싹에 물을 주는 정원사와 강아지',
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: () => context.go(Routes.permission), child: const Text('시작하기')),
              const SizedBox(height: 10),
              const Text('가입 없이 바로 시작해요. 정원은 이 기기에 연결돼요.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
