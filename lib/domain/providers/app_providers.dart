import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/media_item.dart';
import '../../data/services/photo_service.dart';

// PhotoService 单例 Provider
final photoServiceProvider = Provider<PhotoService>((ref) {
  return PhotoService();
});

// 媒体列表 Provider
final mediaListProvider = StateNotifierProvider<MediaListNotifier, List<MediaItem>>((ref) {
  final photoService = ref.watch(photoServiceProvider);
  return MediaListNotifier(photoService);
});

// 统计信息 Provider
final statsProvider = StateNotifierProvider<StatsNotifier, StatsInfo>((ref) {
  final photoService = ref.watch(photoServiceProvider);
  return StatsNotifier(photoService);
});

// 当前浏览的媒体 Provider
final currentMediaProvider = StateProvider<MediaItem?>((ref) => null);

// 加载状态 Provider
final loadingProvider = StateProvider<bool>((ref) => false);

// 错误信息 Provider
final errorProvider = StateProvider<String?>((ref) => null);

// 批量选择模式 Provider
final batchModeProvider = StateProvider<bool>((ref) => false);

// 选中的媒体 Provider
final selectedMediaProvider = StateProvider<Set<String>>((ref) => {});

// 媒体列表 Notifier
class MediaListNotifier extends StateNotifier<List<MediaItem>> {
  final PhotoService _photoService;
  
  MediaListNotifier(this._photoService) : super([]);
  
  Future<void> loadMedia() async {
    final media = await _photoService.loadAllMedia();
    state = media;
  }
  
  Future<void> refresh() async {
    await loadMedia();
  }
  
  MediaItem? getRandomPending() {
    return _photoService.getRandomPendingMedia();
  }
  
  Future<bool> deleteMedia(MediaItem item) async {
    final success = await _photoService.deleteMedia(item);
    if (success) {
      state = state.where((m) => m.id != item.id).toList();
    }
    return success;
  }
  
  Future<int> deleteMultiple(List<MediaItem> items) async {
    final count = await _photoService.deleteMultiple(items);
    state = state.where((m) => !items.any((i) => i.id == m.id)).toList();
    return count;
  }
  
  Future<void> keepMedia(MediaItem item) async {
    await _photoService.keepMedia(item);
    state = [...state];
  }
  
  Future<void> updateCompressedInfo(
    MediaItem item,
    String compressedPath,
    int compressedSize,
  ) async {
    await _photoService.updateCompressedInfo(item, compressedPath, compressedSize);
    state = [...state];
  }
  
  int get pendingCount {
    return state.where((m) => m.status == MediaStatus.pending).length;
  }
  
  List<MediaItem> get pendingMedia {
    return state.where((m) => m.status == MediaStatus.pending).toList();
  }
}

// 统计 Notifier
class StatsNotifier extends StateNotifier<StatsInfo> {
  final PhotoService _photoService;
  
  StatsNotifier(this._photoService) : super(StatsInfo());
  
  void refresh() {
    state = _photoService.stats;
  }
  
  Future<void> reset() async {
    await _photoService.resetStats();
    state = StatsInfo();
  }
}
