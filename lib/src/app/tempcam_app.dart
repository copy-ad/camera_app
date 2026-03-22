import 'package:flutter/material.dart';
import 'package:tempcam/src/app/tempcam_root.dart';
import 'package:tempcam/src/shared/theme/app_theme.dart';

class TempCamApp extends StatelessWidget {
  const TempCamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const TempCamRoot(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
