# flutter_miuix 当前界面实现与控件使用指南

本文说明当前 `flutter_miuix` 组件库是怎样组织和绘制界面的，重点解释顶部标题区域、底部 Tab 区域，以及业务页面应该如何选用其他控件。

本文描述的是当前仓库 `lib/` 中已经实现的行为。示例程序只负责展示和回归验证，不拥有组件逻辑。默认视觉以 HyperOS 4 为基线；项目根据官方应用画面与运行行为校准的尺寸、模糊和动效参数，不应表述为小米公开的官方设计令牌。

## 1. 公共入口与代码结构

业务应用统一导入：

```dart
import 'package:flutter_miuix/flutter_miuix.dart';
```

旧入口 `package:flutter_miuix/miuix_flutter.dart` 只为兼容保留。公共入口按职责导出以下模块：

| 目录 | 职责 | 典型公共 API |
| --- | --- | --- |
| `lib/src/theme/` | 色彩、排版、间距、圆角、动效、HyperOS 4 校准令牌 | `MiuixTheme`、`MiuixThemeData`、`MiuixHyperOs4Tokens` |
| `lib/src/widgets/parts/` | MIUIX 基础控件、导航、弹层和反馈 | `MiuixTopAppBar`、`MiuixScaffold`、`MiuixButton`、`MiuixDialog` |
| `lib/src/effects/` | 玻璃、渐进模糊、超椭圆、按压反馈 | `MiuixGlass`、`MiuixPressable`、`MiuixSquircleBorder` |
| `lib/src/extensions/` | 面向业务应用补齐的跨平台扩展 | 日历、表单、数据表、树、命令面板、自适应布局 |
| `lib/src/platform/` | 窄平台桥接 | 震动、窗口 Insets、设备倾斜、辅助功能 |
| `lib/src/icons/` | MIUIX 图标字体 | `MiuixIcons`、扩展图标 |

## 2. 应用级主题与页面骨架

`MiuixTheme` 应放在 `MaterialApp.builder`，使页面、Navigator 路由和 Overlay 弹层共享同一套主题：

```dart
final miuixTheme = MiuixThemeData.defaults(
  mode: MiuixColorMode.system,
  seedColor: const Color(0xFF3482FF),
).copyWith(
  enableGlass: true,
  glassIntensity: MiuixGlassIntensity.standard,
  enableSquircle: true,
);

MaterialApp(
  builder: (context, child) => MiuixTheme(
    data: miuixTheme,
    child: child ?? const SizedBox.shrink(),
  ),
  home: const HomePage(),
);
```

页面优先使用 `MiuixScaffold`。它不是给 Flutter `Scaffold` 换颜色，而是重新组织了页面、顶栏、浮动控件、底栏、Snackbar 和 PopupHost 的层级：

```text
PopupHost / 对话框 / 菜单
Snackbar
普通或悬浮底部导航
FAB / FloatingToolbar
顶部标题区域
页面正文
```

普通矩形底栏会占用布局高度；悬浮底栏在整窗 Stack 中绘制，胶囊四角保持透明，页面内容可以延伸到其后方。直接传入 `MiuixFloatingNavigationBar` 时会自动识别为悬浮栏；只有外面套了动画或可见性组件时，才需要补充 `bottomBarIsFloating: true`。

## 3. 顶部标题区域是怎么写的

### 3.1 可用组件

- `MiuixTopAppBar`：普通页面顶栏，可显示展开大标题或固定小标题。
- `MiuixSmallTopAppBar`：固定小标题的便捷入口。
- `MiuixSliverTopAppBar`：长列表使用的真正 Sliver 顶栏，参与滚动几何。
- `MiuixTopAppBarScrollBehavior`：让普通 `MiuixScaffold` 中的大标题随正文滚动折叠。

### 3.2 当前绘制层级

当前默认 `blurStyle` 是 `MiuixTopAppBarBlurStyle.gradient`。顶栏从后到前分成三部分：

1. 一组直接裁剪并与页面合成的 `BackdropFilter`，持续采样并模糊顶栏后方内容。
2. 一个从顶部到内容边缘逐渐减弱的语义色渐变，形成渐变玻璃观感。
3. 独立的标题、返回按钮、操作按钮和可选 `bottomContent` 前景层。

标题和按钮不放进透明度渐变中，因此文字、图标不会随玻璃渐变一起变淡。标题背景使用直接裁剪的 Gaussian BackdropFilter，前 68% 保持完整强度，末端 32% 用最多 16 个互不重叠的窄带减弱模糊。滤镜外不包 `ShaderMask`，避免其隔离图层让部分渲染后端只剩染色、实际背景仍清晰。窄带数量按区域高度与像素密度限制；实际模糊和末端渐隐由像素回归验证，不能仅检查滤镜组件是否存在。

三种背景模式分别是：

| 模式 | 行为 | 适用场景 |
| --- | --- | --- |
| `gradient` | 默认；从首帧开始持续显示渐变玻璃 | 新页面、HyperOS 4 默认页面 |
| `gaussian` | 整个顶栏使用均匀玻璃 | 明确需要均匀模糊的页面 |
| `progressive` | 根据正文上滑距离逐渐显现 | 兼容旧示例或特定滚动设计 |

关闭单个顶栏玻璃使用 `glass: false`；全局关闭使用 `MiuixThemeData.enableGlass: false`。

### 3.3 标题折叠与排版

大标题状态使用 32sp 项目校准样式，靠内容区域底部排列；折叠后的小标题使用 20sp/500。紧凑标题在折叠进度超过三分之一后开始显现，并使用独立的淡入和向上位移动效。系统开启“减少动态效果”时直接落到目标状态。

标题不是简单放在左右等宽的 `Row` 里。布局先测量真实的返回区域和操作按钮区域，再让标题以窗口中心为优先位置；发生碰撞时只向有冲突的一侧避让。因此一个返回按钮和多个右侧按钮不会错误地把标题强行偏到另一边，RTL 下也会按逻辑方向镜像。

页面只使用主标题；状态、说明与统计放在正文。旧 `subtitle` 参数为兼容已有调用保留，新页面不再使用，也不再预留副标题高度。

默认尺寸要点：

- 普通小标题区域为 52dp；带副标题时约为 62dp。
- Sliver 默认展开高度为 104dp，带副标题时为 126dp；折叠高度为 56/62dp。
- 标题水平内边距默认为 26dp，返回区起始内边距和操作区末端内边距默认为 16dp。
- 系统状态栏顶部 Insets 始终由顶栏内部消费；`defaultWindowInsetsPadding` 只控制额外的左右窗口 Insets。

这些值是项目校准值。需要旧 MIUIX 1.0.9 的 Sliver 高度时使用 `MiuixSliverTopAppBar.source`。

### 3.4 标题按钮与展开状态

默认 `actionStyle` 为 `MiuixTopAppBarActionStyle.glass`。大标题展开时，左右按钮均透明、无独立圆形底色或边缘，直接共用标题区域的渐变模糊。紧凑标题显现后才绘制独立的圆形玻璃面，返回按钮也遵循此规则。

右侧每个 action 的可见圆形为 44×44dp，交互槽为 48×48dp，相邻可见圆形间距为 8dp；两个操作槽合计宽度 100dp。展开与折叠采用同一布局，只切换背景材质，保证位置、触摸范围、焦点、回调与 Popup 锚点不跳变。

如果页面已有自己的按钮容器，可显式使用 `MiuixTopAppBarActionStyle.plain`。该兼容模式保留旧式 40dp 图标中心节奏和 48dp 交互目标，但不绘制圆形玻璃背景。

顶部操作必须使用 `MiuixIconButton` 或等价的图标菜单锚点，配备准确 tooltip/无障碍名称；不要使用文字按钮。保存中的进度图标应保持原尺寸。点击、长按提示、Popup 锚点、焦点、语义和按压反馈仍由按钮自己负责：

```dart
MiuixScaffold(
  topBar: MiuixTopAppBar(
    title: '设置',
    largeTitle: '设置',
    large: true,
    leading: MiuixIconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: '返回',
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    actions: [
      MiuixIconButton(
        icon: const Icon(Icons.search),
        tooltip: '搜索',
        onPressed: openSearch,
      ),
      MiuixIconButton(
        icon: const Icon(Icons.more_vert),
        tooltip: '更多',
        onPressed: openMenu,
      ),
    ],
  ),
  body: const SettingsContent(),
);
```

长列表使用 Sliver，不要把一个普通顶栏叠在 `CustomScrollView` 上模拟折叠：

```dart
CustomScrollView(
  slivers: [
    MiuixSliverTopAppBar(
      title: '文件',
      largeTitle: '文件',
      pinned: true,
      actions: [
        MiuixIconButton(
          icon: const Icon(Icons.search),
          onPressed: openSearch,
        ),
      ],
    ),
    SliverList.builder(
      itemCount: files.length,
      itemBuilder: (context, index) => FileRow(file: files[index]),
    ),
  ],
);
```

## 4. 底部 Tab 区域是怎么写的

“底部 Tab”在当前库中有三种导航组件，另有一种页内标签组件。应先按用途选择，不能只按外观替换。

| 组件 | 布局 | 用途 |
| --- | --- | --- |
| `MiuixNavigationBar` | 全宽矩形底栏 | 传统底部主导航 |
| `MiuixFloatingNavigationBar` | 局部悬浮玻璃胶囊 | 当前 HyperOS 4 默认主导航 |
| `MiuixIosLiquidGlassNavigationBar` | 液态主胶囊，可带独立圆形操作 | 需要 iOS-like 液态交互的页面 |
| `MiuixTabBar` | 页内横向选项组 | 同一页面内切换分类，不承担应用主导航 |

### 4.1 悬浮底部导航的实现

`MiuixFloatingNavigationBar` 的全宽宿主保持透明，只有局部连续圆角轮廓拥有玻璃、裁剪、高光和阴影。Android 手势安全区也保持透明，不会被错误地涂成矩形底板。

当前默认几何：

- 外层玻璃胶囊高 58dp，圆角 29dp，左右内边距 6dp。
- 每个目的地交互区高 52dp，2/3/4/5 项分别使用 104/88/74/68dp 的项目校准宽度。
- 选中表面高 52dp，距所属目的地区域左右各 2dp，距外层上下各 3dp。
- 图标与文字采用纵向排列；显示模式可切换为图标加文字、仅图标或仅文字。
- 选中表面和外层玻璃是两个明确的轮廓层，但没有横向分割线，也没有上下两个矩形背景层。
- Android 手势安全区与额外视觉间距分开计算；应用可用 `bottomMargin` 缩短胶囊与小白条之间的距离，而不压缩 52dp 交互区。

之前容易出现“上半透明、下半模糊”或中间白线的根因，是把安全区、选中表面、光学边缘或外层宿主当作多个矩形玻璃层叠加。当前实现只让局部胶囊拥有背景取样，并让选中表面在同一胶囊内部移动；外部安全区与四角不绘制第二块玻璃。

### 4.2 选择与拖动

`selectedIndex` 是受控状态。点击或拖动后，组件通过 `onDestinationSelected`（兼容名为 `onSelected`）提交目标索引，业务层更新 `selectedIndex`。

选择块支持直接横向拖动、RTL 逻辑方向和跨项触觉反馈。拖动期间四边额外内缩 2dp，松手后按最终位置选择最近的可用目的地，再通过临界阻尼弹簧吸附。释放速度只影响吸附过程，不会额外投射到下一个 Tab。系统减少动态效果开启时直接落位。

### 4.3 推荐用法

```dart
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var index = 0;

  static const items = [
    MiuixNavigationItem(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: '主页',
    ),
    MiuixNavigationItem(
      icon: Icon(Icons.folder_outlined),
      selectedIcon: Icon(Icons.folder),
      label: '文件',
    ),
    MiuixNavigationItem(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings),
      label: '设置',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MiuixScaffold(
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: const [HomePage(), FilesPage(), SettingsPage()],
      ),
      bottomBar: MiuixFloatingNavigationBar(
        items: items,
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
      ),
    );
  }
}
```

使用 `IndexedStack` 可以保留各 Tab 的状态。若内容必须使用 `PageView`，远距离点击切换不建议直接 `animateToPage`，否则会快速扫过所有中间页面；可以先淡出，`jumpToPage` 后再淡入。页面内左右滑动仍可交给 `PageView`。

如果底栏外面包了 `AnimatedSwitcher`：

```dart
MiuixScaffold(
  extendBody: true,
  bottomBarIsFloating: true,
  bottomBarShadowPaintExtent: MiuixFloatingNavigationBar.sourceShadowRadius,
  bottomBar: AnimatedSwitcher(
    duration: const Duration(milliseconds: 180),
    child: MiuixFloatingNavigationBar(
      key: ValueKey(index),
      items: items,
      selectedIndex: index,
      onDestinationSelected: selectPage,
    ),
  ),
  body: pages[index],
);
```

### 4.4 页内标签行

`MiuixTabBar` 是页内分类选择器。它默认是 44dp 高的局部玻璃选项组，选中项在同一裁剪轮廓内移动。受控写法如下：

```dart
MiuixTabBar(
  tabs: const ['全部', '图片', '文档'],
  selectedTabIndex: categoryIndex,
  onTabSelected: (value) => setState(() => categoryIndex = value),
);
```

旧 MIUIX 1.0.9 外观使用 `MiuixTabBar.source`；兼容旧轮廓 API 使用 `MiuixTabBar.contourSource`。不要用 `MiuixTabBar` 替代应用的底部主导航，也不要把 `MiuixFloatingNavigationBar` 放在页面正文中模拟分段按钮。

## 5. 其他控件怎么用

### 5.1 基础内容与容器

| 需求 | 首选控件 | 使用要点 |
| --- | --- | --- |
| 普通正文或富文本 | `MiuixText` / `MiuixText.rich` | 默认读取当前主题正文角色 |
| 分组小标题 | `MiuixSmallTitle` | 用于组织设置组，不替代页面顶栏 |
| 内容卡片 | `MiuixCard` | 默认局部玻璃；一组列表只套一层卡片 |
| 自定义设置行 | `MiuixBasicComponent` | 提供 leading、正文、trailing、bottomAction 槽位 |
| 分隔 | `MiuixHorizontalDivider` / `MiuixVerticalDivider` | 只在信息结构确实需要时使用，顶栏默认不画明显底线 |
| 徽标 | `MiuixBadge` / `MiuixBadgedBox` | badge 不参与主图标布局尺寸 |

```dart
MiuixCard(
  child: Column(
    children: [
      MiuixBasicComponent(
        title: '账户',
        summary: '管理个人资料与同步',
        leading: const Icon(Icons.person_outline),
        trailing: const Icon(Icons.chevron_right),
        onTap: openAccount,
        standalone: false,
      ),
      const MiuixHorizontalDivider(),
      MiuixBasicComponent(
        title: '隐私',
        leading: const Icon(Icons.lock_outline),
        onTap: openPrivacy,
        standalone: false,
      ),
    ],
  ),
);
```

### 5.2 按钮与操作

- `MiuixButton`：普通或填充按钮；`filled: true` 使用主色语义。
- `MiuixTextButton`：轻量文字操作。
- `MiuixIconButton`：工具栏、顶栏和紧凑图标操作。
- `MiuixFloatingActionButton`：页面级主操作，由 `MiuixScaffold.floatingActionButton` 定位。
- `MiuixFloatingToolbar`：一组浮动操作，由 Scaffold 负责避让底栏与 Snackbar。

```dart
Wrap(
  spacing: 12,
  children: [
    MiuixButton(label: '保存', filled: true, onPressed: save),
    MiuixTextButton(label: '取消', onPressed: cancel),
    MiuixIconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: '删除',
      onPressed: remove,
    ),
  ],
);
```

回调为 `null` 或 `enabled: false` 时控件禁用。按钮需要业务方负责异步防重入；例如保存期间将 `enabled` 设为 false。

`MiuixTextButton` 同时带图标和长标签时，文字会在扣除图标与内边距后的宽度内自然换行，短标签保持自然宽度。设置页可用文字按钮安排次要操作，明确提交动作使用主按钮；不要通过截断文字适配窄屏或大字号。

### 5.3 设置项与选择控件

| 需求 | 控件 |
| --- | --- |
| 普通设置行 | `MiuixPreference` |
| 进入子页面 | `MiuixArrowPreference` |
| 开关、复选、单选 | `MiuixSwitchPreference`、`MiuixCheckboxPreference`、`MiuixRadioButtonPreference` |
| 单值/范围调节 | `MiuixSliderPreference`、`MiuixRangeSliderPreference` |
| 下拉或 Spinner | `MiuixOverlayDropdownPreference`、`MiuixWindowDropdownPreference`、对应 Spinner 组件 |
| 统一设置分组 | `MiuixSettingsGroup` |

所有选择组件都推荐由业务状态控制，不要在行组件外再套一个抢手势的 `GestureDetector`：

开关拖动期间按手指位移直接跟随，只有松手和点击使用位置弹簧。到端点后不再累计多余位移，反向立即响应，系统取消不切换。横拖开始后，回到起点附近的小幅纵向偏移不会中断拖动。松手超过中点才请求切换；往返后回到原端点不改变状态。需要系统验证的设置仍由调用方验证成功后更新 `value`。

```dart
MiuixSettingsGroup(
  title: '通知',
  children: [
    MiuixSwitchPreference(
      title: '允许通知',
      summary: '接收重要状态提醒',
      value: notificationsEnabled,
      onChanged: (value) {
        setState(() => notificationsEnabled = value);
      },
    ),
    MiuixSliderPreference(
      title: '提醒音量',
      value: volume,
      onChanged: (value) => setState(() => volume = value),
    ),
  ],
);
```

### 5.4 输入与搜索

- 普通文本输入使用 `MiuixTextField`。
- 搜索入口使用 `MiuixSearchBar`，需要更接近底层输入结构时使用 `MiuixInputField`。
- PIN/OTP 使用 `MiuixPinInput` / `MiuixOtpInput`。
- 自动完成使用 `MiuixAutoCompleteField<T>`。
- 可搜索单选使用 `MiuixSearchableSelect<T>` 或 `MiuixComboBox<T>`。
- 标签和多选使用 `MiuixTagInput`、`MiuixMultiSelect<T>`。
- 参与 Flutter `Form` 保存和校验时使用 `MiuixFormField<T>` 与 `MiuixFormSection`。

`TextEditingController`、FocusNode 和库内公开控制器如果由页面创建，必须在 `dispose` 中释放。

### 5.5 弹层、菜单与反馈

| 场景 | 推荐 API |
| --- | --- |
| 确认或少量选择 | `MiuixDialog.show` |
| 底部操作/较长内容 | `MiuixBottomSheet.show` |
| 触发器下拉菜单 | `MiuixOverlayDropdownMenu` |
| 跨窗口或桌面层 | `MiuixWindowDropdownMenu` / `MiuixWindowDialog` |
| 二级菜单 | `MiuixCascadingMenu` |
| Android 长按/Windows 右键 | `MiuixContextMenuRegion` |
| 短提示 | `MiuixTooltip` / `MiuixRichTooltip` |
| 页面级消息 | `MiuixSnackbarHost` 与 `MiuixSnackbarController` |
| 极短系统式反馈 | `MiuixToast` |

标准 Dialog、BottomSheet、Snackbar、Tooltip、菜单、Autocomplete 和 CommandPalette 共享 transient 玻璃光学。外层弹层已经拥有玻璃时，内部内容应保持透明，不要再套第二个 `BackdropFilter`。

```dart
final confirmed = await MiuixDialog.show<bool>(
  context: context,
  title: '删除项目？',
  content: const Text('此操作无法撤销。'),
  actions: [
    MiuixTextButton(
      label: '取消',
      onPressed: () => Navigator.of(context).pop(false),
    ),
    MiuixButton(
      label: '删除',
      filled: true,
      onPressed: () => Navigator.of(context).pop(true),
    ),
  ],
);
```

### 5.6 进度、刷新与滚动

- 确定进度：`MiuixLinearProgressIndicator`、`MiuixCircularProgressIndicator`。
- 不确定进度：`MiuixInfiniteProgressIndicator`。
- 下拉刷新：`MiuixPullToRefresh` 与 `MiuixPullToRefreshState`。
- 滚动条：`MiuixVerticalScrollBar`、`MiuixHorizontalScrollBar`、`MiuixScrollBar`。
- MIUIX 回弹：`MiuixSpringScrollPhysics`、`MiuixOverscrollEffect`。
- 加载占位：`MiuixSkeleton` / `MiuixShimmer`。

手指直接操作保持逐帧跟手；惯性、回位、淡入淡出等自主动画才响应 `MediaQuery.disableAnimations`。

### 5.7 日期、数据与高级扩展

| 类别 | 组件 |
| --- | --- |
| 日期时间 | `MiuixCalendar`、`MiuixDatePicker`、`MiuixTimePicker`、`MiuixDateTimePicker`、`MiuixDurationPicker`、日期范围/周历/日程 |
| 数据集合 | `MiuixDataTable`、`MiuixTreeView`、`MiuixReorderableList` |
| 结构展示 | `MiuixTimeline`、`MiuixCarousel`、`MiuixProcessStepper` |
| 数值输入 | `MiuixRating`、`MiuixDial`、`MiuixNumberPicker` |
| 交互 | `MiuixSwipeAction`、`MiuixCommandPalette`、`MiuixFileDropZone` |
| 空状态 | `MiuixEmptyStateView` |
| 自适应布局 | `MiuixAdaptiveScaffold`、`MiuixNavigationDrawer`、`MiuixSplitView`、`MiuixResizablePane` |

这些控件位于 `lib/src/extensions/`，是 `flutter_miuix` 的公共跨平台扩展。它们不冒充 Compose MIUIX 官方同名组件，但同样读取主题、玻璃强度、减少动态效果和语义色。

## 6. 页面导航与预测性返回

应用应在 `MaterialApp` 中安装 `MiuixNavigationPageTransitionsBuilder`，并使用 `MiuixPageRoute` 创建需要一致返回动效的页面：

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

路由进入、系统返回、手势返回、底页偏移、遮罩和页面圆角由同一个方向感知进度驱动。不要同时给页面再套一层独立的 `SlideTransition`，否则两套位移会叠加，返回时容易产生停顿或跳帧感。

转场期间保留裁剪与遮罩的节点层级，只更新裁剪状态和透明度。进入、返回和取消手势不会因为切换转场外层结构而重建页面；主题和窗口变化仍正常更新页面。

## 7. 默认 HyperOS 4 与 `.source` 的选择

普通构造函数是当前 HyperOS 4 默认视觉；`.source`、`sourceText`、`contourSource` 等入口用于明确复刻 MIUIX 1.0.9 或旧示例行为。

推荐规则：

1. 新页面先使用普通构造函数。
2. 只有像素对照或迁移旧页面时才使用 `.source`。
3. 不要为了关闭玻璃而整体切回 `.source`；优先设置 `glass: false`。
4. 不要在业务页硬编码全局 blur、radius 和 motion；优先通过 `MiuixThemeData.hyperOs4` 集中覆盖。
5. 一个视觉轮廓只应拥有一个背景滤镜。父级已经是玻璃卡片或弹层时，子级通常保持透明。

## 8. 常见问题与检查清单

- 顶栏没有模糊：确认页面确实有内容滚动到顶栏后方、`glass` 和全局 `enableGlass` 均为 true，并优先使用默认 `gradient`。
- 顶栏出现明显底线：不要额外添加 Divider；页面顶栏默认关闭矩形光学描边，边界应由内容与渐变自然过渡。
- 小标题操作按钮变成椭圆：不要在多个 action 外再包共享 Capsule；紧凑模式默认 action 已各自拥有 44dp 圆形玻璃与 48dp 交互槽。大标题展开时不应再额外包圆形材质。
- 底栏上下分层或中间白线：确认使用的是直接 `MiuixFloatingNavigationBar`，宿主没有额外矩形背景、BackdropFilter 或 SafeArea 填充。
- 底栏四角不透明：设置 `extendBody: true`，并避免在 `bottomBar` 外层加有颜色的 `Container`。
- Tab 切换后状态丢失：主导航使用 `IndexedStack`，或为各页提供稳定 Key 和独立状态容器。
- 点击 Tab 后 UI 不动：`selectedIndex` / `selectedTabIndex` 是受控值，回调里必须更新业务状态。
- 返回动画卡顿：不要混用默认 `MaterialPageRoute`、自定义 SlideTransition 和 MIUIX 路由；统一使用 `MiuixPageRoute`。
- 玻璃太重或太轻：先调整全局 `MiuixGlassIntensity`，只有单个特殊表面才覆盖 blur/opacity。
- 控件禁用后仍能点击：同时检查业务外层是否又套了自己的 GestureDetector。
- 控制器泄漏：页面创建的 `TextEditingController`、`TabController`、ScrollController 和 Miuix 控制器均应释放。

## 9. 相关文档与示例

- `doc/GETTING_STARTED_ZH.md`：安装、主题和接入流程。
- `doc/COMPONENTS_ZH.md`：基础组件的详细参数与示例。
- `doc/EXTENSIONS_ZH.md`：扩展控件的详细用法。
- `doc/HYPEROS4_OFFICIAL_APP_DESIGN_SPEC_ZH.md`：默认视觉与验收基线。
- `example/lib/reference_page_scaffold.dart`：示例页面骨架、顶栏和底栏组装。
- `example/lib/reference_home_page.dart`：组件目录与首页使用方式。
