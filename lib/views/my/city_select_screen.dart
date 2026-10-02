import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/repositories/weather_repository.dart';
import '../../viewmodels/garden_providers.dart';
import '../../viewmodels/settings_view_model.dart';
import '../../widgets/common/app_card.dart';

/// 15. 도시 선택
class CitySelectScreen extends ConsumerStatefulWidget {
  const CitySelectScreen({super.key});

  @override
  ConsumerState<CitySelectScreen> createState() => _CitySelectScreenState();
}

class _CitySelectScreenState extends ConsumerState<CitySelectScreen> {
  String? _picked;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(profileProvider).valueOrNull?.city ?? '서울';
    final selected = _picked ?? current;
    final cities = cityCoordinates.keys.where((c) => c.contains(_filter)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('도시 선택')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (v) => setState(() => _filter = v.trim()),
              decoration: const InputDecoration(hintText: '도시 검색하기', prefixIcon: Icon(Icons.search_rounded, color: AppColors.textHint)),
            ),
            const SizedBox(height: 8),
            const Text('정원 날씨를 이 도시 기준으로 보여 줘요', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(6),
                child: ListView(
                  children: [
                    for (final c in cities)
                      ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: c == selected ? AppColors.accentLight : null,
                        title: Text(c, style: TextStyle(fontWeight: c == selected ? FontWeight.w700 : FontWeight.w400)),
                        trailing: c == selected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                        selected: c == selected,
                        onTap: () => setState(() => _picked = c),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                await ref.read(settingsViewModelProvider).setCity(selected);
                if (context.mounted) context.pop();
              },
              child: const Text('확인'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
