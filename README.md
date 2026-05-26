# 相册清理助手 (Photo Cleaner)

一款帮助用户快速整理相册的 Flutter 应用。

## 功能特性

- 📸 随机浏览相册中的图片和视频
- 👆 滑动手势操作（向左保留，向右跳过，向上删除）
- 🗑️ 批量选择删除
- 📊 统计已浏览、已删除、已释放空间
- 📧 用户反馈邮件功能
- 🎨 纯灰度玻璃拟态 UI 设计（iOS 26 Liquid Glass 风格）

## 技术栈

- Flutter 3.x
- Riverpod 状态管理
- photo_manager 相册访问
- video_player 视频播放
- url_launcher 邮件功能

## 开始使用

### 环境要求

- Flutter SDK 3.0+
- Android SDK (用于 Android 构建)
- Xcode (用于 iOS 构建)

### 安装依赖

```bash
flutter pub get
```

### 运行应用

```bash
flutter run
```

### 构建 APK

```bash
flutter build apk --release
```

### 构建 Web

```bash
flutter build web
```

## GitHub Actions 自动构建

本项目已配置 GitHub Actions 自动构建：

1. 推送代码到 `main` 分支会自动触发构建
2. 构建完成后，APK 会在 Releases 页面发布
3. 也可以在 Actions 页面手动触发构建

## 项目结构

```
lib/
├── core/theme/           # 主题配置
├── data/services/        # 数据服务
├── domain/models/        # 数据模型
├── domain/providers/     # 状态管理
├── presentation/screens/ # UI 页面
└── main.dart            # 入口文件
```

## 许可证

MIT License
