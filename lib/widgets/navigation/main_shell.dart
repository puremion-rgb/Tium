import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

/// 하단 탭: 홈 · 퀘스트 · 기록 · MY
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, '홈'),
    (Icons.fact_check_outlined, Icons.fact_check_rounded, '퀘스트'),
    (Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, '기록'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'MY'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(child: _TabButton(tab: _tabs[i], selected: shell.currentIndex == i, onTap: () => _go(i))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.tab, required this.selected, required this.onTap});

  final (IconData, IconData, String) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : const Color(0xFF9AA096);
    return Semantics(
      selected: selected,
      button: true,
      label: '${tab.$3} 탭',
      child: InkResponse(
        onTap: onTap,
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? tab.$2 : tab.$1, color: color, size: 24),
              const SizedBox(height: 3),
              Text(tab.$3, style: TextStyle(fontSize: 11, color: color, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
