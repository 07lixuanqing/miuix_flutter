# flutter_miuix

`flutter_miuix` 是面向 Flutter 应用的 MIUIX 组件库，当前重点支持 Android 和 Windows。组件、主题、图标、玻璃模糊、弹层和导航均使用 Flutter 实现；Android 包额外自带原生震动桥接。

## 环境要求

- Flutter 3.22 或更高版本
- Dart 3.4 或更高版本
- Android：minSdk 21、compileSdk 36、JDK 17
- Windows：Visual Studio 的“使用 C++ 的桌面开发”工作负载

## 添加依赖

解压发行包后，在应用的 `pubspec.yaml` 中添加：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_miuix:
    path: ../flutter_miuix
```

然后执行：

```powershell
flutter pub get
```

代码统一从公开入口导入：

```dart
import 'package:flutter_miuix/flutter_miuix.dart';
```

## 最小示例

```dart
import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final miuixTheme = MiuixThemeData.defaults(
      seedColor: const Color(0xFF3482FF),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MiuixTheme(
        data: miuixTheme,
        child: child ?? const SizedBox.shrink(),
      ),
      home: MiuixScaffold(
        topBar: const MiuixTopAppBar(title: 'flutter_miuix'),
        body: Center(
          child: MiuixButton(
            label: '开始使用',
            filled: true,
            onPressed: () {},
          ),
        ),
      ),
    );
  }
}
```

## 功能范围

- 颜色、排版、间距、圆角、动画和五档玻璃强度主题令牌
- TopAppBar、普通/悬浮 NavigationBar、NavigationRail、TabRow
- Button、Card、Switch、Checkbox、Radio、Slider、RangeSlider
- ColorPicker、ColorPalette、SearchBar、TextField、NumberPicker
- 设置项、Snackbar、Tooltip、Badge、PullToRefresh
- Dialog、BottomSheet、Dropdown、级联菜单和锚点弹层
- MIUIX 图标字体、超椭圆和液态玻璃效果
- Android 原生 MIUIX 震动角色；Windows 自动使用 Flutter 安全回退

## 平台说明

- [完整接入指南](doc/GETTING_STARTED_ZH.md)
- [Android 集成说明](doc/ANDROID.md)
- [Windows 集成说明](doc/WINDOWS.md)
- [常用组件示例](doc/COMPONENTS_ZH.md)

Flutter 组件库不会以独立 `.aar` 或 `.dll` 的方式包含 Dart 界面代码。正确的分发物是本源码包：消费应用构建时，Flutter 会把组件代码、字体和着色器编译进 Android APK/AAB 或 Windows EXE。Android 目录中的原生插件会自动参与 Android 构建。

## 验证

```powershell
flutter analyze lib test
flutter test
cd example
flutter build apk --release --target-platform android-arm64
flutter build windows --release
```

旧文件入口 `package:flutter_miuix/miuix_flutter.dart` 暂时保留兼容；新项目应使用 `package:flutter_miuix/flutter_miuix.dart`。
