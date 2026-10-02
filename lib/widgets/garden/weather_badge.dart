import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/weather.dart';

class WeatherBadge extends StatelessWidget {
  const WeatherBadge({super.key, required this.weather, required this.city});

  final AsyncValue<Weather> weather;
  final String city;

  @override
  Widget build(BuildContext context) {
    return weather.when(
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(width: 56, height: 52, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)))),
      error: (_, __) => const Tooltip(message: '날씨를 불러오지 못했어요', child: Icon(Icons.cloud_off_outlined, color: AppColors.textHint)),
      data: (w) => Semantics(
        label: '$city ${w.kind.label} ${w.temperatureText}',
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              WeatherIcon(kind: w.kind),
              Text('$city · ${w.kind.label}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(w.temperatureText, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, height: 1.1)),
            ],
          ),
        ),
      ),
    );
  }
}

class WeatherIcon extends StatelessWidget {
  const WeatherIcon({super.key, required this.kind, this.size = 26});
  final WeatherKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      WeatherKind.sunny => (Icons.wb_sunny_rounded, const Color(0xFFFFC93C)),
      WeatherKind.cloudy => (Icons.cloud_rounded, const Color(0xFFB8C4CC)),
      WeatherKind.rain => (Icons.umbrella_rounded, const Color(0xFF5AA0D8)),
      WeatherKind.snow => (Icons.ac_unit_rounded, const Color(0xFF7FB6E0)),
      WeatherKind.night => (Icons.nightlight_round, const Color(0xFFF2C14E)),
    };
    return Icon(icon, color: color, size: size);
  }
}
