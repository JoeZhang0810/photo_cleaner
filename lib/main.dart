import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "core/theme/app_theme.dart";
import "presentation/screens/home_screen.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 延迟初始化，确保 Flutter 引擎完全启动
  Future.delayed(const Duration(milliseconds: 100), () {
    runApp(
      const ProviderScope(
        child: PhotoCleanerApp(),
      ),
    );
  });
}

class PhotoCleanerApp extends StatelessWidget {
  const PhotoCleanerApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "相册清理助手",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
