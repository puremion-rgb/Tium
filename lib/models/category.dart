import 'package:flutter/material.dart';

import 'plant.dart';

/// 퀘스트 카테고리. Firestore에는 name(study, coding ...)으로 저장한다.
enum QuestCategory {
  study('공부', PlantKind.sunflower, Icons.edit_outlined, Color(0xFFFFE9C7), Color(0xFFC77A1E)),
  coding('코딩', PlantKind.lavender, Icons.code_rounded, Color(0xFFE1ECFB), Color(0xFF3E6FB5)),
  reading('독서', PlantKind.tulip, Icons.menu_book_outlined, Color(0xFFFFF2B8), Color(0xFFB98A00)),
  life('생활', PlantKind.rose, Icons.water_drop_outlined, Color(0xFFDDF2D8), Color(0xFF3F8C3A));

  const QuestCategory(this.label, this.plant, this.icon, this.tileColor, this.iconColor);

  final String label;
  final PlantKind plant;
  final IconData icon;
  final Color tileColor;
  final Color iconColor;

  static QuestCategory fromName(String name) =>
      QuestCategory.values.firstWhere((c) => c.name == name, orElse: () => QuestCategory.life);
}
