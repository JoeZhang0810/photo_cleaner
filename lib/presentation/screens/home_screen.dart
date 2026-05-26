import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/providers/app_providers.dart';
import 'browse_screen.dart';
import 'stats_screen.dart';
import 'batch_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // 初始化时加载媒体
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mediaListProvider.notifier).loadMedia();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsProvider);
    
    final screens = [
      const _HomeTab(),
      const BrowseScreen(),
      const BatchScreen(),
      const StatsScreen(),
    ];
    
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSecondary,
          border: Border(
            top: BorderSide(
              color: AppTheme.glassBorder,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, '首页', 0),
                _buildNavItem(Icons.photo_library_outlined, '浏览', 1),
                _buildNavItem(Icons.grid_view_outlined, '批量', 2),
                _buildNavItem(Icons.bar_chart_outlined, '统计', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected ? AppTheme.glassButton : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.textPrimary : AppTheme.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.textPrimary : AppTheme.textTertiary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 首页标签内容
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    final pendingCount = ref.watch(mediaListProvider.notifier).pendingCount;
    
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 标题
            Text(
              '相册清理助手',
              style: AppTheme.displayMedium.copyWith(
                fontSize: 32,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '滑动浏览，快速整理你的相册',
              style: AppTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            
            // 统计卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassCard,
              child: Column(
                children: [
                  _buildStatRow('已浏览', '${stats.totalViewed}'),
                  const SizedBox(height: 16),
                  _buildStatRow('已删除', '${stats.totalDeleted}'),
                  const SizedBox(height: 16),
                  _buildStatRow('已压缩', '${stats.totalCompressed}'),
                  const SizedBox(height: 16),
                  const Divider(color: AppTheme.glassBorder),
                  const SizedBox(height: 16),
                  _buildStatRow('已释放空间', stats.spaceSavedFormatted),
                ],
              ),
            ),
            
            const Spacer(),
            
            // 开始按钮
            if (pendingCount > 0)
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const BrowseScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: AppTheme.glassCardStrong,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '开始清理',
                          style: AppTheme.labelLarge.copyWith(
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.glassBgHover,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$pendingCount',
                            style: AppTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: AppTheme.glassCard,
                  child: Text(
                    '暂无待处理照片',
                    style: AppTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            
            const SizedBox(height: 24),
            
            // 批量模式入口
            SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BatchScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: AppTheme.glassButton,
                  child: Text(
                    '批量选择模式',
                    style: AppTheme.labelMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.bodyLarge,
        ),
        Text(
          value,
          style: AppTheme.labelLarge,
        ),
      ],
    );
  }
}
