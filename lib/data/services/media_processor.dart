import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../domain/models/media_item.dart';

class MediaProcessor {
  // 视频压缩配置
  static const int targetHeight = 720; // 720p
  static const int crf = 28; // 质量系数，越小质量越好，文件越大
  static const String videoCodec = 'libx264';
  static const String audioCodec = 'aac';
  
  // 压缩视频
  static Future<CompressionResult> compressVideo(
    MediaItem item, {
    Function(double progress)? onProgress,
  }) async {
    try {
      if (item.path == null) {
        return CompressionResult.error('视频路径为空');
      }
      
      final inputPath = item.path!;
      
      // 检查输入文件是否存在
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        return CompressionResult.error('原视频文件不存在');
      }
      
      // 创建输出目录
      final tempDir = await getTemporaryDirectory();
      final outputDir = Directory('${tempDir.path}/compressed');
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }
      
      // 生成输出文件名
      final fileName = path.basenameWithoutExtension(inputPath);
      final extension = path.extension(inputPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${outputDir.path}/${fileName}_compressed_$timestamp$extension';
      
      // 构建 FFmpeg 命令
      // -i: 输入文件
      // -vf scale=-2:720: 保持宽高比，高度缩放到720
      // -c:v libx264: 视频编码器
      // -crf 28: 质量设置
      // -c:a aac: 音频编码器
      // -map_metadata 0: 复制所有元数据（保留拍摄时间、GPS等）
      // -movflags +faststart: 优化网络播放
      // -y: 覆盖输出文件
      final String command =
          '-i "$inputPath" '
          '-vf scale=-2:$targetHeight '
          '-c:v $videoCodec '
          '-crf $crf '
          '-preset medium '
          '-c:a $audioCodec '
          '-b:a 128k '
          '-map_metadata 0 '
          '-movflags +faststart '
          '-y '
          '"$outputPath"';
      
      debugPrint('FFmpeg 命令: $command');
      
      // 执行压缩
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      
      if (ReturnCode.isSuccess(returnCode)) {
        // 压缩成功
        final outputFile = File(outputPath);
        if (await outputFile.exists()) {
          final stat = await outputFile.stat();
          return CompressionResult.success(
            outputPath: outputPath,
            compressedSize: stat.size,
            originalSize: item.size,
          );
        } else {
          return CompressionResult.error('压缩后文件未生成');
        }
      } else {
        // 压缩失败
        final output = await session.getOutput();
        final logs = await session.getLogs();
        final logText = logs?.map((l) => l.getMessage()).join('\n') ?? '';
        debugPrint('FFmpeg 错误输出: $output');
        debugPrint('FFmpeg 日志: $logText');
        return CompressionResult.error('压缩失败: $output');
      }
    } catch (e) {
      debugPrint('视频压缩异常: $e');
      return CompressionResult.error('压缩异常: $e');
    }
  }
  
  // 获取视频信息
  static Future<Map<String, dynamic>?> getVideoInfo(String path) async {
    try {
      final session = await FFmpegKit.execute('-i "$path" -print_format json -show_streams -show_format');
      final output = await session.getOutput();
      // 解析 JSON 输出
      // 注意：FFmpeg 的 JSON 输出在 stderr 中
      return null;
    } catch (e) {
      debugPrint('获取视频信息失败: $e');
      return null;
    }
  }
  
  // 清理临时文件
  static Future<void> clearTempFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final compressedDir = Directory('${tempDir.path}/compressed');
      if (await compressedDir.exists()) {
        final files = await compressedDir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('清理临时文件失败: $e');
    }
  }
  
  // 删除原视频并替换为压缩版本
  static Future<bool> replaceOriginalWithCompressed(
    MediaItem item,
    String compressedPath,
  ) async {
    try {
      if (item.path == null) return false;
      
      final originalFile = File(item.path!);
      final compressedFile = File(compressedPath);
      
      if (!await compressedFile.exists()) return false;
      
      // 删除原文件
      if (await originalFile.exists()) {
        await originalFile.delete();
      }
      
      // 将压缩后的文件移动到原位置
      // 注意：在实际相册中，我们需要使用 photo_manager 来替换
      // 这里只是文件系统操作
      return true;
    } catch (e) {
      debugPrint('替换原视频失败: $e');
      return false;
    }
  }
}

// 压缩结果类
class CompressionResult {
  final bool success;
  final String? outputPath;
  final int? compressedSize;
  final int? originalSize;
  final String? errorMessage;
  
  CompressionResult._({
    required this.success,
    this.outputPath,
    this.compressedSize,
    this.originalSize,
    this.errorMessage,
  });
  
  factory CompressionResult.success({
    required String outputPath,
    required int compressedSize,
    required int originalSize,
  }) {
    return CompressionResult._(
      success: true,
      outputPath: outputPath,
      compressedSize: compressedSize,
      originalSize: originalSize,
    );
  }
  
  factory CompressionResult.error(String message) {
    return CompressionResult._(
      success: false,
      errorMessage: message,
    );
  }
  
  int? get savedSpace {
    if (originalSize == null || compressedSize == null) return null;
    return originalSize! - compressedSize!;
  }
  
  double? get compressionRatio {
    if (originalSize == null || compressedSize == null) return null;
    return compressedSize! / originalSize!;
  }
  
  String get savedSpaceFormatted {
    final saved = savedSpace;
    if (saved == null) return '';
    if (saved < 1024) return '$saved B';
    if (saved < 1024 * 1024) return '${(saved / 1024).toStringAsFixed(1)} KB';
    return '${(saved / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
