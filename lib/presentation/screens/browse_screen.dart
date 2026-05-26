import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/media_item.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/services/photo_service.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  MediaItem? _currentMedia;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  bool _isCompressing = false;
  double _compressionProgress = 0;
  
  @override
  void initState() {
    super.initState();
    _loadNextMedia();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _loadNextMedia() async {
    setState(() => _isLoading = true);
    
    // 释放上一个视频资源
    await _videoController?.dispose();
    _videoController = null;
    
    final next = ref.read(mediaListProvider.notifier).getRandomPending();
    
    if (next != null) {
      setState(() {
        _currentMedia = next;
        _isLoading = false;
      });
      
      // 如果是视频，初始化播放器
      if (next.isVideo && next.path != null) {
        _initializeVideo(next.path!);
      }
    } else {
      setState(() {
        _currentMedia = null;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _initializeVideo(String path) async {
    try {
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (mounted) {
        setState(() {});
        _videoController!.play();
      }
    } catch (e) {
      debugPrint('视频初始化失败: $e');
    }
  }
  
  Future<void> _keepMedia() async {
    if (_currentMedia == null) return;
    await ref.read(mediaListProvider.notifier).keepMedia(_currentMedia!);
    await _loadNextMedia();
  }
  
  Future<void> _deleteMedia() async {
    if (_currentMedia == null) return;
    
    final confirmed = await _showDeleteConfirmDialog();
    if (!confirmed) return;
    
    await ref.read(mediaListProvider.notifier).deleteMedia(_currentMedia!);
    await _loadNextMedia();
  }
  
  Future<void> _compressAndDelete() async {
    // 视频压缩功能需要 ffmpeg，当前版本暂不支持
    // 直接删除原视频
    if (_currentMedia == null || !_currentMedia!.isVideo) return;
    
    final confirmed = await _showDeleteConfirmDialog();
    if (!confirmed) return;
    
    await ref.read(mediaListProvider.notifier).deleteMedia(_currentMedia!);
    await _loadNextMedia();
  }
  
  Future<bool> _showDeleteConfirmDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('确认删除', style: AppTheme.titleSmall),
        content: Text(
          '确定要删除这个文件吗？此操作无法撤销。',
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
              '删除',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.danger,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  void _showCompressionSuccess(dynamic result) {
    // 视频压缩功能已移除
  }
  
  void _showCompressionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
        title: Text('压缩失败', style: AppTheme.titleSmall),
        content: Text(message, style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('确定', style: AppTheme.labelMedium),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('浏览', style: AppTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.textPrimary,
              ),
            )
          : _currentMedia == null
              ? _buildEmptyState()
              : _buildMediaViewer(),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: AppTheme.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            '所有照片已处理完毕',
            style: AppTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '太棒了！你的相册已整理完成',
            style: AppTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMediaViewer() {
    return Column(
      children: [
        // 媒体显示区域
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // 向右滑动 - 保留
                _keepMedia();
              } else if (details.primaryVelocity! < 0) {
                // 向左滑动 - 下一个
                _loadNextMedia();
              }
            },
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // 向下滑动 - 保留
                _keepMedia();
              } else if (details.primaryVelocity! < 0) {
                // 向上滑动 - 删除
                _deleteMedia();
              }
            },
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: AppTheme.glassCard,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                child: _currentMedia!.isVideo
                    ? _buildVideoPlayer()
                    : _buildImageViewer(),
              ),
            ),
          ),
        ),
        
        // 媒体信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                _currentMedia!.isVideo ? '视频' : '图片',
                style: AppTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '${_currentMedia!.sizeFormatted} · ${_currentMedia!.resolutionFormatted}',
                style: AppTheme.bodySmall,
              ),
              if (_currentMedia!.isVideo && _currentMedia!.duration != null)
                Text(
                  '时长: ${_currentMedia!.durationFormatted}',
                  style: AppTheme.bodySmall,
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 操作按钮
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 删除按钮
              _buildActionButton(
                icon: Icons.delete_outline,
                label: '删除',
                onTap: _deleteMedia,
                color: AppTheme.danger,
              ),
              
              // 保留按钮
              _buildActionButton(
                icon: Icons.check,
                label: '保留',
                onTap: _keepMedia,
              ),
              
              // 视频压缩按钮（仅视频显示）
              if (_currentMedia!.isVideo)
                _isCompressing
                    ? Container(
                        width: 72,
                        height: 72,
                        decoration: AppTheme.glassCard,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.textPrimary,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : _buildActionButton(
                        icon: Icons.compress,
                        label: '压缩',
                        onTap: _compressAndDelete,
                      )
              else
                _buildActionButton(
                  icon: Icons.skip_next,
                  label: '下一个',
                  onTap: _loadNextMedia,
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 手势提示
        Text(
          '← 保留 · 删除 ↑ · 下一个 →',
          style: AppTheme.bodySmall,
        ),
        const SizedBox(height: 32),
      ],
    );
  }
  
  Widget _buildImageViewer() {
    return FutureBuilder<Uint8List?>(
      future: PhotoService().getThumbnail(_currentMedia!.id, width: 800, height: 800),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.textPrimary),
          );
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
          );
        }
        
        return const Center(
          child: Icon(Icons.broken_image, color: AppTheme.textTertiary, size: 64),
        );
      },
    );
  }
  
  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.textPrimary),
      );
    }
    
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayer(_videoController!),
        // 播放/暂停按钮
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.glassBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.glassBorder),
              ),
              child: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: AppTheme.textPrimary,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: AppTheme.glassButton,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color ?? AppTheme.textPrimary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.bodySmall.copyWith(
                color: color ?? AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
