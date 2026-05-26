import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/providers/app_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'feedback@photocleaner.app',
      queryParameters: {
        'subject': '相册清理助手 - 用户反馈',
        'body': '请在此输入您的反馈和建议：\n\n',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _resetStats(WidgetRef ref) async {
    await ref.read(statsProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(statsProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('统计', style: AppTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 主要统计数据
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: AppTheme.glassCardStrong,
                child: Column(
                  children: [
                    Text(
                      stats.spaceSavedFormatted,
                      style: AppTheme.displayLarge.copyWith(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '已释放空间',
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 详细统计
              Container(
                padding: const EdgeInsets.all(24),
                decoration: AppTheme.glassCard,
                child: Column(
                  children: [
                    _buildStatItem('已浏览', '${stats.totalViewed}'),
                    const Divider(height: 24, color: AppTheme.glassBorder),
                    _buildStatItem('已保留', '${stats.totalKept}'),
                    const Divider(height: 24, color: AppTheme.glassBorder),
                    _buildStatItem('已删除', '${stats.totalDeleted}'),
                    const Divider(height: 24, color: AppTheme.glassBorder),
                    _buildStatItem('已压缩', '${stats.totalCompressed}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 设置选项
              Text(
                '设置',
                style: AppTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              
              // 重置统计
              GestureDetector(
                onTap: () => _showResetConfirmDialog(context, ref),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '重置统计',
                              style: AppTheme.bodyLarge,
                            ),
                            Text(
                              '清空所有统计数据',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // 用户反馈
              GestureDetector(
                onTap: _sendFeedback,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppTheme.glassCard,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.mail_outline,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '建议与反馈',
                              style: AppTheme.bodyLarge,
                            ),
                            Text(
                              '向开发者发送邮件',
                              style: AppTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.textTertiary,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // 版本信息
              Center(
                child: Text(
                  '相册清理助手 v1.0.0',
                  style: AppTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
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
  
  Future<void> _showResetConfirmDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('确认重置', style: AppTheme.titleSmall),
        content: Text(
          '确定要重置所有统计数据吗？此操作无法撤销。',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: AppTheme.bodyMedium),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              '重置',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _resetStats(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('统计数据已重置'),
            backgroundColor: AppTheme.bgSecondary,
          ),
        );
      }
    }
  }
}
