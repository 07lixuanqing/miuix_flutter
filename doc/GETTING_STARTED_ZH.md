# flutter_miuix 接入指南

## 发行文件怎么选

- `flutter_miuix-1.2.0-android.zip`：供 Android 项目接入，根目录附带 Android 平台说明。
- `flutter_miuix-1.2.0-windows.zip`：供 Windows 项目接入，根目录附带 Windows 平台说明。
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
      ref: v1.2.0
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

五档玻璃强度由 `MiuixGlassIntensity` 控制。HyperOS 4 默认下，TopAppBar、
NavigationBar、SearchBar、Dialog、BottomSheet 和锚定菜单会直接启用玻璃；把
`enableGlass` 设置为 `false` 可全局关闭。需要兼容旧实体表面的单个组件可以显式传入
`glass: false`，而不是继续依赖旧默认值。

如果应用需要与原版 `ThemeController` 相同的固定色、Monet 和明暗覆盖逻辑，可以直接把控制器交给 `MiuixTheme`：

```dart
final controller = MiuixThemeController(
  colorSchemeMode: MiuixColorMode.monetSystem,
  // 非空时由 MIUIX 生成 Monet；null 表示使用平台动态配色。
  keyColor: const Color(0xFF3482FF),
  paletteStyle: MiuixThemePaletteStyle.tonalSpot,
  colorSpec: MiuixThemeColorSpec.spec2021,
);

MaterialApp(
  builder: (context, child) => MiuixTheme(
    controller: controller,
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
);
```

`System`、`Light` 和 `Dark` 模式只使用控制器的 `lightColors`/`darkColors`，不会被 `keyColor` 改色。使用空关键色时，可通过 `platformDynamicLightColors` 和 `platformDynamicDarkColors` 传入平台读取结果；未传入时采用原版跨平台紫色回退方案。

## 3. 页面骨架

优先使用 `MiuixScaffold` 承载 MIUIX 顶栏、底栏、Snackbar 和弹层。悬浮底栏需要 `extendBody: true`，这样胶囊以外区域能看到页面内容。

```dart
MiuixScaffold(
  extendBody: true,
  topBar: const MiuixTopAppBar(
    title: '设置',
    large: true,
    glass: true,
    actions: [Icon(Icons.more_vert)],
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

顶栏默认持续采样并模糊后方内容，并通过连续语义色渐变让玻璃向内容边缘自然减弱。
每个 `actions` 项都拥有独立的 48dp 圆形玻璃按钮，多个操作不会合并成椭圆胶囊；
旧式透明图标使用 `actionStyle: MiuixTopAppBarActionStyle.plain`，滚动渐显背景使用
`blurStyle: MiuixTopAppBarBlurStyle.progressive`，均匀背景使用
`blurStyle: MiuixTopAppBarBlurStyle.gaussian`。

默认浮动导航会保留至少 48dp 的交互目标。图标和文字同时显示时采用图标在上、
文字在下的纵向排列；
项目推导默认值把 52dp 目的地热区和选中表面设为同高，使选中表面距 58dp 外层
上下各 3dp，并让它距等分目的地左右边缘各 2dp。内外圆角按该 3dp 间距形成同心
轮廓，不再把选中态缩成图标周围的小底板。这些数值是画面校准值，不是小米公开的
官方 dp 参数。不要通过 `itemExtent` 把每项重新压成正方形；只有业务确实
需要固定尺寸时才分别设置 `itemWidth`、`itemHeight`、
`selectionHeight`，或覆盖主题中的二至五项宽度 token。

底栏默认支持直接左右拖动选中块。拖动位置跟随手指并按逻辑方向兼容 RTL，越过目的地
边界时产生一次段落触觉反馈，松手后按手指最终位置选择最近槽位，再使用临界阻尼弹簧吸附并提交目标页；释放速度不会额外跨越一个 Tab。与 iOS 液态
导航不同，拖动中的滑块会在四边额外内缩 2dp；例如三项底栏由 `84×52dp` 变为
`80×48dp`，五项底栏由 `64×52dp` 变为 `60×48dp`，吸附后恢复完整选中底板。
可用 `dragEnabled: false` 关闭手势，或用 `dragSelectionInset` 覆盖拖动内缩量。

宽窗口可直接使用 `MiuixNavigationRail(items: ...)`。普通构造器绘制局部玻璃
侧栏，窗口边缘、状态栏和侧栏圆角外均保持透明，并支持图标加文字、仅图标、仅文字
及仅选中项显示文字。项目校准的模糊、透明度、32dp 连续圆角、12dp 外边距和
54dp 项目热区由 `MiuixThemeData.hyperOs4` 统一控制；这些不是小米公开的 dp
参数。若迁移页必须维持旧 MIUIX 实体侧栏，数据列表使用
`MiuixNavigationRail.sourceItems`，任意子组件使用 `MiuixNavigationRail.source`。

## 3.1 HyperOS 4 内容表面

搜索、菜单、对话框、底部面板和提示条的模糊、透明度与圆角来自
`MiuixThemeData.hyperOs4`，并由同一五档玻璃强度共同缩放。应用通常不需要重复填写
blur 或 opacity：

```dart
MiuixSearchBar(
  controller: searchController,
  hint: '搜索',
);

MiuixButton(
  label: '打开面板',
  onPressed: () => MiuixBottomSheet.show<void>(
    context: context,
    child: const Text('内容高度由子组件决定'),
  ),
);
```

这些表面只在自身连续圆角内采样背景，外侧宿主仍为透明。Dialog 和 BottomSheet
不会因为开启玻璃而改成全屏高度；下拉菜单仍根据触发控件、可用窗口和内容高度定位。
标准弹层统一使用 `MiuixGlassOptics.transient`：Dialog、BottomSheet、Snackbar、
Tooltip、下拉/级联/右键菜单、Autocomplete 与 CommandPalette 会共享同一五档光学
进程。自定义弹层可通过 `MiuixSurface(glass: true, glassOptics:
MiuixGlassOptics.transient, ...)` 获得相同材质；如果外层弹层已经拥有玻璃，内部内容
应保持透明，避免嵌套两个 `BackdropFilter`。
若迁移中的页面必须暂时保持旧实体外观，可在对应的 `MiuixSearchBar`、
`MiuixInputField`、`MiuixDialog.show`、`MiuixOverlayDialog.show`、
`MiuixWindowDialog.show`、`MiuixBottomSheet.show`、`MiuixOverlayBottomSheet.show`
或 `MiuixWindowBottomSheet.show` 调用中明确传入 `glass: false`。

普通 `MiuixButton`、`MiuixTextButton`、`MiuixIconButton` 和
`MiuixTextField` 也已经以 HyperOS 4 的项目校准尺寸为默认值。需要逐项复刻
MIUIX 1.0.9 时，使用对应的 `.source` 构造函数；提示条可使用
`MiuixSnackbar.source` 获得旧版 16dp、不透明表面。

进度组件的普通构造同样读取 `hyperOs4`：线性轨道高度、圆形尺寸与描边、轨道式
加载器尺寸与圆点，以及四类自主循环时钟均可统一校准。小米官网没有公开这些 dp
和毫秒值，因此默认值属于项目校准点。明确需要复刻 MIUIX 1.0.9 的 6/30/20dp
几何及 1250/1000/1600/800ms 时钟时，使用
`MiuixProgressIndicator.source`、`MiuixLinearProgressIndicator.source`、
`MiuixCircularProgressIndicator.source` 或
`MiuixInfiniteProgressIndicator.source`。显式尺寸参数仍然优先于主题。
`MiuixPullToRefresh` 的反馈环尺寸、释放回位周期、成功收束和旋转周期也读取同一
token 集；手指拖动仍逐帧直跟，只有松手后的自主运动读取时钟。需要完全保留旧版
20dp、400/200/800ms 行为时使用 `MiuixPullToRefresh.source`。

若要使用当前原版示例的 iOS-like 液态导航，将上面的 `bottomBar` 替换为
`MiuixIosLiquidGlassNavigationBar`，参数仍为 `items`、`selectedIndex` 和
`onDestinationSelected`，玻璃开关使用 `showBlur`。它支持 2 至 5 个等宽目标；
`extendBody: true` 仍然是透明四角显示页面内容的必要条件。
传入 `trailingAction` 可得到主导航胶囊加独立圆形操作的拆分布局。独立操作不改变
`selectedIndex`；当前默认 56dp 面板和圆形操作、48dp 静止镜片、12dp 间隔以及
每项目的地优先 80dp 是参考画面推导值，不是小米公开令牌。需要来源示例的
64dp 面板和 56dp 镜片时使用 `MiuixIosLiquidGlassNavigationBar.source`。
该兼容组件也读取 `MediaQuery.disableAnimations`：开启后，按压和拖动状态仍然
直接响应指针，但选择器不再通过弹簧追赶触点，松手、取消和外部索引更新立即落位。
普通模式下静止选择器占一个完整等宽 Tab，拖动时四边内缩约 2dp；指针阶段直接
跟手，松手后才执行一次吸附弹簧。点击在松手确认后开始目标位移，真实选择变化会
发出一次 `segmentTick` 语义触觉。
承载页面时不要对远距离 Tab 直接调用 `PageController.animateToPage`，否则会把中间
页面全部扫过。示例采用 80ms 淡出、直接 `jumpToPage`、180ms 淡入；内容区自身的
左右手势仍交给 `PageView`，两类交互不会争用同一段滚动动画。

## 3.2 页面进出动画

应用应同时安装 `MiuixNavigationPageTransitionsBuilder` 并使用
`MiuixPageRoute`，以保证主题动画和路由的 500ms 项目校准周期一致：

```dart
MaterialApp(
  theme: ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: MiuixNavigationPageTransitionsBuilder(),
        TargetPlatform.windows: MiuixNavigationPageTransitionsBuilder(),
      },
    ),
  ),
);

Navigator.of(context).push<void>(
  MiuixPageRoute<void>(builder: (_) => const DetailPage()),
);
```

退出时组件会把倒计时控制器转换为“已经退出了多久”，再从弹簧响应的起点计算位移；
因此按下返回键后的第一帧就会产生可见运动，不会先停在二级页面、随后突然返回。
进场、退场、底页偏移和遮罩都使用同一方向感知进度，并自动适配 RTL。这里的
500ms、四分之一底页偏移和连续圆角属于项目画面与行为校准值，不是小米公开参数。

## 4. 使用原版基础行与箭头偏好

需要与 Compose MIUIX 的参数和槽位逐项对应时，使用源式构造函数。`MiuixBasicComponent.sourceText` 对应标题/摘要重载，`MiuixBasicComponent.source` 对应任意中心内容重载；它们不会自动添加 Flutter 兼容版的独立 Card：

```dart
MiuixBasicComponent.source(
  startAction: const Icon(Icons.person_outline),
  endActions: const Text('尾部'),
  bottomAction: MiuixSlider(value: .5, onChanged: (_) {}),
  onClick: () {},
  onClickLabel: '打开详细信息',
  role: MiuixAccessibilityRole.button,
  content: const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('自定义标题'),
      Text('自定义摘要'),
    ],
  ),
);
```

`onClickLabel` 对应原版 `clickable` 的无障碍操作说明。`role` 使用
`MiuixAccessibilityRole`，完整覆盖原版的 `button`、`checkbox`、
`switchControl`、`radioButton`、`tab`、`image` 和 `dropdownList` 七种角色；
开关、复选、单选和下拉偏好会自动附加对应角色及当前状态。

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

复选框和单选按钮的原版默认位置都是行首。行首控件保留自身 5dp 尾距以及基础行对已占用首槽再添加的 8dp 间距；尾部动作即使为空也会保留原版 8dp 尾距。`titleColor`、`summaryColor`、控件颜色、`startAction`/`endActions`、`bottomAction`、`insideMargin`、`holdDownState` 和 `enabled` 均可独立传入。

单选偏好默认会像原版一样，在选中时把标题和摘要切换为主题主色。需要定制四组状态时，可通过 `MiuixRadioButtonPreferenceDefaults.radioButtonPreferenceColors(context, ...)` 创建 `MiuixRadioButtonPreferenceColors`，再传给 `colors`；其中普通标题、选中标题、普通摘要和选中摘要各自仍包含启用/禁用两个颜色通道。

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

原版选择器偏好使用带可选图标、标题和摘要的 `SpinnerEntry`。弹出模式使用 `SpinnerDefaults.spinnerColors()`，对话框模式使用独立的 `dialogSpinnerColors()`：

```dart
const spinnerItems = [
  MiuixSpinnerEntry(
    icon: Icon(Icons.palette_outlined),
    title: '红色主题',
    summary: '活力鲜明',
  ),
  MiuixSpinnerEntry(
    icon: Icon(Icons.water_drop_outlined),
    title: '蓝色主题',
    summary: '沉稳清爽',
  ),
];

MiuixOverlaySpinnerPreference.source(
  items: spinnerItems,
  selectedIndex: selectedIndex,
  title: '主题选择',
  maxHeight: 280,
  renderInRootScaffold: true,
  onSelectedIndexChange: (index) {
    setState(() => selectedIndex = index);
  },
);

MiuixWindowSpinnerPreference.source(
  items: spinnerItems,
  selectedIndex: selectedIndex,
  title: '对话框选择器',
  dialogButtonString: '取消',
  onSelectedIndexChange: (index) {
    setState(() => selectedIndex = index);
  },
);
```

提供 `dialogButtonString` 时会切换到原版对话框模式。点选对话框条目会立即触发 `onSelectedIndexChange`、执行确认震动并关闭；底部按钮只负责关闭，不是第二次确认。弹出模式打开时使用上下文点击震动，选择时使用确认震动。`spinnerColors`、`titleColor`、`summaryColor`、`startAction`、`bottomAction`、`insideMargin`、`maxHeight`、`showValue` 与原版参数逐一对应；`dialogSurfaceBuilder` 是 Flutter 对原版 `popupModifier` 的包装入口。空列表仍显示 10×16dp 箭头，但整行不可点击。

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
