import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_images.dart';
import '../../app/theme.dart';
import '../../models/completion.dart';
import '../../models/weather.dart';
import '../../utils/level.dart';
import '../../utils/korean.dart';

/// 24. 레벨업
class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key, required this.result});
  final CompletionResult result;

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final before = widget.result.before.level;
    final after = widget.result.after.level;
    final newTitle = titleForLevel(after);
    final titleChanged = newTitle != titleForLevel(before);
    final rise = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 아래쪽에 그려진 캐릭터가 보이지 않도록 위쪽만 쓴다.
          Image.asset(AppImages.garden(WeatherKind.sunny), fit: BoxFit.cover, alignment: const Alignment(0, -0.55)),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, 0.3, 0.52],
                colors: [Color(0xF5FCF8EE), Color(0xBFFCF8EE), Color(0x00FCF8EE)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 28),
                const Text('레벨업!', style: TextStyle(fontFamily: displayFont, fontSize: 46, color: AppColors.error)),
                Text('Lv.$before → Lv.$after', style: const TextStyle(fontFamily: displayFont, fontSize: 34, color: AppColors.primaryDark)),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 280,
                        height: 280,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [Color(0xD9FFF0AA), Color(0x00FFF0AA)], stops: [0, 0.7]),
                        ),
                      ),
                      AnimatedBuilder(
                        animation: rise,
                        builder: (_, child) => Transform.translate(offset: Offset(0, 40 * (1 - rise.value)), child: child),
                        child: Image.asset(AppImages.characterFront, height: 320, semanticLabel: '레벨업한 정원사'),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 26),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(color: const Color(0xF0FFFDF5), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    titleChanged ? '${withIga(newTitle)} 되었어요!' : '정원이 한층 풍성해졌어요!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark, fontSize: 15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(26, 14, 26, 28),
                  child: FilledButton(onPressed: () => context.pop(), child: const Text('확인')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
