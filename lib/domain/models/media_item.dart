import 'package:photo_manager/photo_manager.dart';

enum MediaType { image, video }

enum MediaStatus { pending, kept, deleted, compressed }

class MediaItem {
  final String id;
  final MediaType type;
  final String? title;
  final DateTime createTime;
  final DateTime modifiedTime;
  final int width;
  final int height;
  final int size;
  final String? path;
  final AssetEntity? assetEntity;
  final double? latitude;
  final double? longitude;
  final String? mimeType;
  final int? duration; // 视频时长（秒）
  
  MediaStatus status;
  String? compressedPath;
  int? compressedSize;
  
  MediaItem({
    required this.id,
    required this.type,
    this.title,
    required this.createTime,
    required this.modifiedTime,
    required this.width,
    required this.height,
    required this.size,
    this.path,
    this.assetEntity,
    this.latitude,
    this.longitude,
    this.mimeType,
    this.duration,
    this.status = MediaStatus.pending,
    this.compressedPath,
    this.compressedSize,
  });
  
  factory MediaItem.fromAssetEntity(AssetEntity entity) {
    return MediaItem(
      id: entity.id,
      type: entity.type == AssetType.image ? MediaType.image : MediaType.video,
      title: entity.title,
      createTime: entity.createDateTime,
      modifiedTime: entity.modifiedDateTime,
      width: entity.width,
      height: entity.height,
      size: 0, // 需要通过 file 获取
      assetEntity: entity,
      latitude: entity.latitude,
      longitude: entity.longitude,
      mimeType: entity.mimeType,
      duration: entity.duration,
    );
  }
  
  bool get isVideo => type == MediaType.video;
  bool get isImage => type == MediaType.image;
  
  String get sizeFormatted {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
  
  String get compressedSizeFormatted {
    if (compressedSize == null) return '';
    if (compressedSize! < 1024) return '$compressedSize B';
    if (compressedSize! < 1024 * 1024) return '${(compressedSize! / 1024).toStringAsFixed(1)} KB';
    return '${(compressedSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String get savedSpaceFormatted {
    if (compressedSize == null || status != MediaStatus.compressed) return '';
    final saved = size - compressedSize!;
    if (saved < 1024) return '$saved B';
    if (saved < 1024 * 1024) return '${(saved / 1024).toStringAsFixed(1)} KB';
    return '${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  String get durationFormatted {
    if (duration == null) return '';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String get resolutionFormatted => '${width}x$height';
  
  MediaItem copyWith({
    MediaStatus? status,
    String? compressedPath,
    int? compressedSize,
    int? size,
    String? path,
  }) {
    return MediaItem(
      id: id,
      type: type,
      title: title,
      createTime: createTime,
      modifiedTime: modifiedTime,
      width: width,
      height: height,
      size: size ?? this.size,
      path: path ?? this.path,
      assetEntity: assetEntity,
      latitude: latitude,
      longitude: longitude,
      mimeType: mimeType,
      duration: duration,
      status: status ?? this.status,
      compressedPath: compressedPath ?? this.compressedPath,
      compressedSize: compressedSize ?? this.compressedSize,
    );
  }
}

// 统计信息
class StatsInfo {
  final int totalViewed;
  final int totalDeleted;
  final int totalCompressed;
  final int totalKept;
  final int spaceSaved;
  final int imageCount;
  final int videoCount;
  
  StatsInfo({
    this.totalViewed = 0,
    this.totalDeleted = 0,
    this.totalCompressed = 0,
    this.totalKept = 0,
    this.spaceSaved = 0,
    this.imageCount = 0,
    this.videoCount = 0,
  });
  
  StatsInfo copyWith({
    int? totalViewed,
    int? totalDeleted,
    int? totalCompressed,
    int? totalKept,
    int? spaceSaved,
    int? imageCount,
    int? videoCount,
  }) {
    return StatsInfo(
      totalViewed: totalViewed ?? this.totalViewed,
      totalDeleted: totalDeleted ?? this.totalDeleted,
      totalCompressed: totalCompressed ?? this.totalCompressed,
      totalKept: totalKept ?? this.totalKept,
      spaceSaved: spaceSaved ?? this.spaceSaved,
      imageCount: imageCount ?? this.imageCount,
      videoCount: videoCount ?? this.videoCount,
    );
  }
  
  String get spaceSavedFormatted {
    if (spaceSaved < 1024) return '$spaceSaved B';
    if (spaceSaved < 1024 * 1024) return '${(spaceSaved / 1024).toStringAsFixed(1)} KB';
    if (spaceSaved < 1024 * 1024 * 1024) return '${(spaceSaved / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(spaceSaved / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
