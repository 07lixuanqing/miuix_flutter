# flutter_miuix 接入指南

## 发行文件怎么选

- `flutter_miuix-1.0.9-android.zip`：供 Android 项目接入，根目录附带 Android 平台说明。
- `flutter_miuix-1.0.9-windows.zip`：供 Windows 项目接入，根目录附带 Windows 平台说明。
- 两个压缩包内都是名为 `flutter_miuix` 的 Flutter 源码包；Dart 组件、字体和着色器相同，区别是根目录的 `PLATFORM.md`。
- Android 原生震动桥接目录会保留在两个包中。Windows 构建时 Flutter 会自动忽略它，因此同一份解压目录也可以同时供 Android 和 Windows 应用依赖。
- `flutter_miuix_example-*.apk` 和 Windows 示例压缩包只用于安装验证，不是库依赖。应用应解压上面的库包并通过 `path` 或 Git 引用，不能把 APK、EXE 或 DLL 写进 `pubspec.yaml`。

## 1. 解压与依赖

将发行包解压到应用仓库中，例如：

```text
my_app/
  packages/
    flutter_miuix/
      pubspec.yaml
      lib/
      assets/
      shaders/
      android/
  pubspec.yaml
```

应用的 `pubspec.yaml`：

```yaml
dependencies:
  flutter_miuix:
    path: packages/flutter_miuix
```

团队也可以将解压目录提交到独立 Git 仓库，然后使用 Git 依赖：

```yaml
dependencies:
  flutter_miuix:
    git:
      url: https://your-server/flutter_miuix.git
      ref: v1.0.9
```

运行 `flutter pub get` 后，从下面的入口导入：

```dart
import 'package:flutter_miuix/flutter_miuix.dart';
```

## 2. 安装主题

`MiuixTheme` 应放在 `MaterialApp.builder` 中，这样普通页面、Navigator 路由和弹层都能获得相同主题：

```dart
final theme = MiuixThemeData.defaults(
  mode: MiuixColorMode.system,
  seedColor: const Color(0xFF3482FF),
).copyWith(
  enableGlass: true,
  glassIntensity: MiuixGlassIntensity.standard,
  enableSquircle: true,
);

MaterialApp(
  builder: (context, child) => MiuixTheme(
    data: theme,
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
);
```

五档玻璃强度由 `MiuixGlassIntensity` 控制。关闭全局玻璃时，将 `enableGlass` 设置为 `false`；单个 TopAppBar、NavigationBar 或弹层仍需把自身的 `glass` 参数打开，才会绘制玻璃表面。

## 3. 页面骨架

优先使用 `MiuixScaffold` 承载 MIUIX 顶栏、底栏、Snackbar 和弹层。悬浮底栏需要 `extendBody: true`，这样胶囊以外区域能看到页面内容。

```dart
MiuixScaffold(
  extendBody: true,
  topBar: const MiuixTopAppBar(
    title: '设置',
    large: true,
    glass: true,
  ),
  body: ListView(children: const [/* 页面内容 */]),
  bottomBar: MiuixFloatingNavigationBar(
    items: items,
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    glass: true,
  ),
);
```

## 4. 使用原版基础行与箭头偏好

需要与 Compose MIUIX 的参数和槽位逐项对应时，使用源式构造函数。`MiuixBasicComponent.sourceText` 对应标题/摘要重载，`MiuixBasicComponent.source` 对应任意中心内容重载；它们不会自动添加 Flutter 兼容版的独立 Card：

```dart
MiuixBasicComponent.source(
  startAction: const Icon(Icons.person_outline),
  endActions: const Text('尾部'),
  bottomAction: MiuixSlider(value: .5, onChanged: (_) {}),
  onClick: () {},
  content: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('自定义标题'),
      Text('自定义摘要'),
    ],
  ),
);
```

箭头偏好也提供与原版同名的槽位和状态参数：

```dart
MiuixArrowPreference.source(
  title: '关于手机',
  summary: '查看设备信息',
  startAction: const Icon(Icons.phone_android),
  endActions: const Text('当前设备'),
  onClick: () {},
);
```

需要定制状态颜色时，使用 `MiuixBasicComponentColors`、`MiuixBasicComponentDefaults`、`MiuixArrowPreferenceEndActionColors` 和 `MiuixArrowPreferenceDefaults`。箭头前固定保留原版 `endActions` 行的 8dp 尾距，即使没有传入尾部内容也不会扩大中间文字区域。

开关、复选和单选偏好也提供原版参数命名的源式入口：

```dart
MiuixSwitchPreference.source(
  checked: enabled,
  onCheckedChange: (value) => setState(() => enabled = value),
  title: '启用功能',
  summary: '点击整行或开关都可切换',
);

MiuixCheckboxPreference.source(
  title: '复选项',
  checked: checked,
  onCheckedChange: (value) => setState(() => checked = value),
  checkboxLocation: MiuixCheckboxLocation.start,
);

MiuixRadioButtonPreference.source(
  title: '单选项',
  selected: selected,
  onClick: () => setState(() => selected = true),
  radioButtonLocation: MiuixRadioButtonLocation.start,
);
```

复选框和单选按钮的原版默认位置都是行首。行首控件保留自身 8dp 尾距以及基础行对已占用首槽再添加的 8dp 间距；尾部动作即使为空也会保留原版 8dp 尾距。`titleColor`、`summaryColor`、控件颜色、`startAction`/`endActions`、`bottomAction`、`insideMargin`、`holdDownState` 和 `enabled` 均可独立传入。

原版下拉偏好使用“字符串列表 + 选中索引”，可直接使用源式入口：

```dart
MiuixOverlayDropdownPreference.source(
  items: const ['标准', '紧凑', '宽松'],
  selectedIndex: selectedIndex,
  title: '显示模式',
  maxHeight: 240,
  showValue: true,
  renderInRootScaffold: true,
  onSelectedIndexChange: (index) {
    setState(() => selectedIndex = index);
  },
);

MiuixWindowDropdownPreference.source(
  items: const ['选项一', '选项二'],
  selectedIndex: selectedIndex,
  title: '窗口下拉偏好',
  onSelectedIndexChange: (index) {
    setState(() => selectedIndex = index);
  },
);
```

`titleColor`、`summaryColor`、`dropdownColors`、`startAction`、`bottomAction`、`insideMargin`、`maxHeight` 和 `showValue` 均与原版参数对应。空列表会把整行切换为禁用颜色但仍保留 10×16dp 箭头，不会显示额外的 “No actions” 占位文案。叠加模式在嵌套 `MiuixScaffold` 中使用 `renderInRootScaffold: false` 时会自动完成原版的宿主坐标补偿。

## 5. 使用原版宿主弹层

需要复刻原版 `MiuixPopupUtils.kt` 的宿主注册语义时，请在 `MiuixScaffold` 内使用 `.source` 构造函数，并由 `ValueNotifier<bool>` 控制显示状态：

```dart
final popupVisible = ValueNotifier<bool>(false);

MiuixPopupLayout.source(
  visible: popupVisible,
  enableWindowDim: true,
  enableBackHandler: true,
  renderInRootScaffold: true,
  onDismissFinished: () {
    // 退出动画完成且宿主条目物理移除后调用。
  },
  child: const Center(child: YourPopupContent()),
);
```

`MiuixDialogLayout.source` 的用法相同，并额外支持 `enableAutoLargeScreen` 和动态 `dimAlpha`。通用 Dialog 宿主本身不处理返回键或点击外部关闭；这些行为应由 `MiuixDialogContentLayout` 等具体对话框内容负责，与原版分层一致。页面销毁时应 `dispose()` 自己创建的 `ValueNotifier`。

原版允许分别覆盖内容与遮罩的进入、退出动画。Flutter 对应使用 `MiuixVisibilityTransition`，四个通道相互独立：

```dart
MiuixPopupLayout.source(
  visible: popupVisible,
  enterTransition: const MiuixVisibilityTransition.scale(
    duration: Duration(milliseconds: 260),
    hiddenScale: 0.8,
    fade: true,
  ),
  exitTransition: const MiuixVisibilityTransition.fade(
    duration: Duration(milliseconds: 150),
  ),
  dimEnterTransition: const MiuixVisibilityTransition.fade(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeOut,
  ),
  dimExitTransition: const MiuixVisibilityTransition.fade(
    duration: Duration(milliseconds: 150),
  ),
  child: const YourPopupContent(),
);
```

普通构造函数可以同时组合 `hiddenOpacity`、`hiddenScale` 和 `hiddenOffset`；需要其他变换时可使用 `MiuixVisibilityTransition.custom`，其 builder 会收到从隐藏状态 `0` 到显示状态 `1` 的 `Animation<double>`。

未带 `.source` 的旧构造函数保留为兼容用的行内 Surface，不具备原版 PopupHost 注册、退出队列和根/嵌套宿主路由语义。

如果需要显式提供原版 Scaffold 宿主槽，可直接写：

```dart
MiuixScaffold(
  popupHost: const MiuixPopupHost(),
  body: const YourPage(),
);
```

无参 `MiuixPopupHost()` 只渲染当前 `MiuixScaffold` 已有的弹层状态，不会创建第二层宿主。只有确实需要在普通子树中创建独立嵌套宿主时，才使用 `MiuixPopupHost.scope(child: ...)`；这是为旧版 Flutter 接口保留的扩展，不是原版默认用法。

## 6. 字体、图标和着色器

图标字体与 MIUIX 混合着色器已经在库的 `pubspec.yaml` 中声明。不要把 `assets/fonts` 或 `shaders` 手动复制到应用，也不要修改生成图标的 `fontPackage`。只要通过正常 Flutter 依赖接入，Android 和 Windows 构建都会自动打包这些资源。

## 7. 版本升级

替换 `flutter_miuix` 目录后依次执行：

```powershell
flutter clean
flutter pub get
flutter analyze
flutter test
```

若使用 Git 依赖，请更新 `ref`，再执行 `flutter pub upgrade flutter_miuix`。旧入口文件会继续工作，但应逐步迁移到 `flutter_miuix.dart`。
