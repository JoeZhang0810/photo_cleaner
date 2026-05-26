plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")  // 必须添加这个插件才能编译 Kotlin 代码
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.photo_cleaner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.example.photo_cleaner"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
