import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class TiumApp extends StatelessWidget {
  const TiumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '틔움',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: appRouter,
    );
  }
}
