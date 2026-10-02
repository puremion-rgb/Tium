import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/user_profile.dart';
import '../../models/weather.dart';
import '../common/app_card.dart';
import 'weather_badge.dart';

/// Lv.3 새싹 정원사 + 경험치 바 + 날씨
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.profile, required this.weather, this.translucent = false});

  final UserProfile profile;
  final AsyncValue<Weather> weather;
  final bool translucent;

  @override
  Widget build(BuildContext context) {
    final lv = profile.level;
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                LevelBadge(level: lv.level),
                const SizedBox(width: 10),
                Text(lv.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: XpBar(progress: lv.progress)),
                const SizedBox(width: 8),
                Text(
                  '${lv.xpInLevel} / ${lv.xpToNext}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFeatures: [FontFeature.tabularFigures()]),
                ),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 12),
        WeatherBadge(weather: weather, city: profile.city),
      ],
    );
    if (translucent) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(AppRadius.card)),
        child: content,
      );
    }
    return AppCard(padding: const EdgeInsets.fromLTRB(16, 14, 16, 14), child: content);
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});
  final int level;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
        child: Text('Lv.$level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      );
}
