import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/media_item.dart';

class PhotoService {
  static final PhotoService _instance = PhotoService._internal();
  factory PhotoService() => _instance;
  PhotoService._internal();
  
  List<MediaItem> _allMedia = [];
  List<MediaItem> get allMedia => List.unmodifiable(_allMedia);
  
  StatsInfo _stats = StatsInfo();
  StatsInfo get stats => _stats;
  
  // 请求权限
  Future<bool> requestPermission() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    return state.isAuth || state == PermissionState.limited;
  }
  
  // 检查权限
  Future<bool> checkPermission() async {
    final PermissionState state = await PhotoManager.getPermissionState(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.common,
          mediaLocation: true,
        ),
      ),
    );
    return state.isAuth || state == PermissionState.limited;
  }
  
  // 加载所有媒体
  Future<List<MediaItem>> loadAllMedia() async {
    try {
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        final granted = await requestPermission();
        if (!granted) return [];
      }
      
      // 获取所有相册
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.common,
        filterOption: FilterOptionGroup(
          orders: [
            const OrderOption(
              type: OrderOptionType.createDate,
              asc: false,
            ),
          ],
        ),
      );
      
      _allMedia = [];
      
      for (final album in albums) {
        final List<AssetEntity> assets = await album.getAssetListRange(
          start: 0,
          end: await album.assetCountAsync,
        );
        
        for (final asset in assets) {
          final mediaItem = MediaItem.fromAssetEntity(asset);
          // 获取文件大小
          final file = await asset.file;
          if (file != null) {
            final stat = await file.stat();
            _allMedia.add(mediaItem.copyWith(
              size: stat.size,
              path: file.path,
            ));
          }
        }
      }
      
      // 按时间排序
      _allMedia.sort((a, b) => b.createTime.compareTo(a.createTime));
      
      await _loadStats();
      return _allMedia;
    } catch (e) {
      debugPrint('加载媒体失败: $e');
      return [];
    }
  }
  
  // 获取单个媒体文件
  Future<File?> getFile(String id) async {
    final asset = await AssetEntity.fromId(id);
    return await asset?.file;
  }
  
  // 获取缩略图
  Future<Uint8List?> getThumbnail(String id, {int width = 300, int height = 300}) async {
    final asset = await AssetEntity.fromId(id);
    return await asset?.thumbnailDataWithSize(
      ThumbnailSize(width, height),
      quality: 80,
    );
  }
  
  // 删除媒体
  Future<bool> deleteMedia(MediaItem item) async {
    try {
      final List<String> result = await PhotoManager.editor.deleteWithIds([item.id]);
      if (result.isNotEmpty) {
        item.status = MediaStatus.deleted;
        _allMedia.removeWhere((m) => m.id == item.id);
        await _updateStats(
          deleted: 1,
          spaceSaved: item.isVideo && item.compressedSize != null
              ? item.compressedSize!
              : item.size,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('删除媒体失败: $e');
      return false;
    }
  }
  
  // 批量删除
  Future<int> deleteMultiple(List<MediaItem> items) async {
    int successCount = 0;
    int savedSpace = 0;
    
    for (final item in items) {
      try {
        final List<String> result = await PhotoManager.editor.deleteWithIds([item.id]);
        if (result.isNotEmpty) {
          item.status = MediaStatus.deleted;
          savedSpace += item.isVideo && item.compressedSize != null
              ? item.compressedSize!
              : item.size;
          successCount++;
        }
      } catch (e) {
        debugPrint('删除媒体失败: $e');
      }
    }
    
    _allMedia.removeWhere((m) => items.any((i) => i.id == m.id));
    await _updateStats(deleted: successCount, spaceSaved: savedSpace);
    return successCount;
  }
  
  // 保留媒体（仅更新状态）
  Future<void> keepMedia(MediaItem item) async {
    item.status = MediaStatus.kept;
    await _updateStats(kept: 1);
  }
  
  // 更新压缩后的信息
  Future<void> updateCompressedInfo(
    MediaItem item,
    String compressedPath,
    int compressedSize,
  ) async {
    item.compressedPath = compressedPath;
    item.compressedSize = compressedSize;
    item.status = MediaStatus.compressed;
    
    await _updateStats(
      compressed: 1,
      spaceSaved: item.size - compressedSize,
    );
  }
  
  // 获取随机未处理的媒体
  MediaItem? getRandomPendingMedia() {
    final pending = _allMedia.where((m) => m.status == MediaStatus.pending).toList();
    if (pending.isEmpty) return null;
    pending.shuffle();
    return pending.first;
  }
  
  // 获取待处理数量
  int get pendingCount => _allMedia.where((m) => m.status == MediaStatus.pending).length;
  
  // 加载统计
  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    _stats = StatsInfo(
      totalViewed: prefs.getInt('totalViewed') ?? 0,
      totalDeleted: prefs.getInt('totalDeleted') ?? 0,
      totalCompressed: prefs.getInt('totalCompressed') ?? 0,
      totalKept: prefs.getInt('totalKept') ?? 0,
      spaceSaved: prefs.getInt('spaceSaved') ?? 0,
    );
  }
  
  // 更新统计
  Future<void> _updateStats({
    int viewed = 0,
    int deleted = 0,
    int compressed = 0,
    int kept = 0,
    int spaceSaved = 0,
  }) async {
    _stats = _stats.copyWith(
      totalViewed: _stats.totalViewed + viewed,
      totalDeleted: _stats.totalDeleted + deleted,
      totalCompressed: _stats.totalCompressed + compressed,
      totalKept: _stats.totalKept + kept,
      spaceSaved: _stats.spaceSaved + spaceSaved,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalViewed', _stats.totalViewed);
    await prefs.setInt('totalDeleted', _stats.totalDeleted);
    await prefs.setInt('totalCompressed', _stats.totalCompressed);
    await prefs.setInt('totalKept', _stats.totalKept);
    await prefs.setInt('spaceSaved', _stats.spaceSaved);
  }
  
  // 重置统计
  Future<void> resetStats() async {
    _stats = StatsInfo();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('totalViewed');
    await prefs.remove('totalDeleted');
    await prefs.remove('totalCompressed');
    await prefs.remove('totalKept');
    await prefs.remove('spaceSaved');
  }
  
  // 清除缓存
  Future<void> clearCache() async {
    await PhotoManager.clearFileCache();
  }
}
