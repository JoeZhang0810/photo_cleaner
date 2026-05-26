import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/models/media_item.dart';
import '../../domain/providers/app_providers.dart';
import '../../data/services/photo_service.dart';

class BatchScreen extends ConsumerStatefulWidget {
  const BatchScreen({super.key});

  @override
  ConsumerState<BatchScreen> createState() => _BatchScreenState();
}

class _BatchScreenState extends ConsumerState<BatchScreen> {
  final Set<String> _selectedIds = {};
  bool _isLoading = false;
  
  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    
    final confirmed = await _showDeleteConfirmDialog();
    if (!confirmed) return;
    
    setState(() => _isLoading = true);
    
    final mediaList = ref.read(mediaListProvider);
    final toDelete = mediaList.where((m) => _selectedIds.contains(m.id)).toList();
    
    final count = await ref.read(mediaListProvider.notifier).deleteMultiple(toDelete);
    
    setState(() {
      _selectedIds.clear();
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已删除 $count 个项目'),
          backgroundColor: AppTheme.bgSecondary,
        ),
      );
    }
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
          '确定要删除选中的 ${_selectedIds.length} 个项目吗？此操作无法撤销。',
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
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
  
  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }
  
  void _selectAll() {
    final mediaList = ref.read(mediaListProvider);
    final pending = mediaList.where((m) => m.status == MediaStatus.pending);
    setState(() {
      if (_selectedIds.length == pending.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(pending.map((m) => m.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = ref.watch(mediaListProvider);
    final pendingMedia = mediaList.where((m) => m.status == MediaStatus.pending).toList();
    
    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: AppBar(
        title: Text('批量选择', style: AppTheme.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _selectAll,
            child: Text(
              _selectedIds.length == pendingMedia.length ? '取消全选' : '全选',
              style: AppTheme.labelMedium,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.textPrimary),
            )
          : pendingMedia.isEmpty
              ? _buildEmptyState()
              : _buildGrid(pendingMedia),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgSecondary,
                border: Border(
                  top: BorderSide(color: AppTheme.glassBorder, width: 0.5),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '已选择 ${_selectedIds.length} 项',
                        style: AppTheme.bodyLarge,
                      ),
                    ),
                    GestureDetector(
                      onTap: _deleteSelected,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.danger.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                          border: Border.all(
                            color: AppTheme.danger.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.delete_outline,
                              color: AppTheme.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '删除',
                              style: AppTheme.labelMedium.copyWith(
                                color: AppTheme.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
            '没有待处理的照片',
            style: AppTheme.titleSmall,
          ),
        ],
      ),
    );
  }
  
  Widget _buildGrid(List<MediaItem> media) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        final isSelected = _selectedIds.contains(item.id);
        
        return GestureDetector(
          onTap: () => _toggleSelection(item.id),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 缩略图
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                child: FutureBuilder<Uint8List?>(
                  future: PhotoService().getThumbnail(item.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    }
                    return Container(
                      color: AppTheme.bgTertiary,
                      child: const Icon(
                        Icons.image,
                        color: AppTheme.textTertiary,
                      ),
                    );
                  },
                ),
              ),
              
              // 选中遮罩
              if (isSelected)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.textPrimary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.textPrimary,
                      width: 2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle,
                      color: AppTheme.textPrimary,
                      size: 32,
                    ),
                  ),
                ),
              
              // 视频标识
              if (item.isVideo)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.videocam,
                      color: AppTheme.textPrimary,
                      size: 14,
                    ),
                  ),
                ),
              
              // 选择指示器（未选中时）
              if (!isSelected)
                Positioned(
                  top: 4,
                  left: 4,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.bgPrimary.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.textPrimary.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
