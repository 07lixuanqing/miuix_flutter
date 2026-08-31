# flutter_miuix 扩展组件指南

本文覆盖 `flutter_miuix 1.2.0` 新增的库级扩展。组件实现全部位于
`lib/src/extensions/`，并由以下入口公开导出：

```dart
import 'package:flutter_miuix/flutter_miuix.dart';
```

示例应用只持有演示数据，不包含组件实现。这里的扩展不冒充 Compose MIUIX
官方目录中的同名控件；它们复用本库的 MIUIX 颜色、表面、动画、玻璃、震动和
无障碍基础设施，为 Android、平板和 Windows 应用补足常见产品场景。

## 组件总览

| 场景 | 公共组件 |
| --- | --- |
| 自适应布局 | `MiuixAdaptiveScaffold`、`MiuixAdaptiveContentFrame`、`MiuixNavigationDrawer` |
| 主从分栏 | `MiuixSplitView`、`MiuixResizablePane` |
| 日历日程 | `MiuixDateRangePicker`、`MiuixMonthPicker`、`MiuixYearPicker`、`MiuixWeekCalendar`、`MiuixAgendaView` |
| 集合编辑 | `MiuixReorderableList`、`MiuixDragHandle`、`MiuixTreeView` |
| 选择与标签 | `MiuixSearchableSelect`、`MiuixComboBox`、`MiuixTagInput`、`MiuixChip` |
| 结构化数据 | `MiuixProcessStepper`、`MiuixDataTable` |
| 滚动标题 | `MiuixSliverTopAppBar` |
| 桌面效率 | `MiuixFileDropZone`、`MiuixCommandPalette` |

## 骨架屏与加载占位

`MiuixSkeleton` 和 `MiuixShimmer` 的默认扫光周期读取
`MiuixThemeData.hyperOs4.skeletonMotion`。传入非默认 `duration` 时以组件参数为准。
系统开启“减少动态”或组件被禁用后，渐变稳定停在中间帧，不会保留随机扫光位置。
矩形圆角读取 `skeletonCornerRadius`，显式 `cornerRadius` 仍然优先；需要保持旧版
固定 12dp 几何时使用 `MiuixSkeleton.source` 或 `MiuixShimmer.source`。

## 自适应 Scaffold 与分栏

`MiuixAdaptiveScaffold` 默认按宽度选择导航形式：小于 600dp 使用底部导航，
600–1199dp 使用 NavigationRail，1200dp 起使用固定 NavigationDrawer。应用也可
通过 `navigationMode` 强制一种形式。

宽窗口的 `MiuixNavigationDrawer` 普通入口默认不是贴边实体矩形：它与
NavigationRail 共用 `navigationRailBlur`、`navigationRailTintOpacity`、
`navigationRailCornerRadius` 和 `navigationRailOuterMargin`，形成四周可看到页面
内容的局部悬浮玻璃面。`glass: false` 只关闭模糊，仍保留相同悬浮层级与连续圆角；
`floating: false` 可取消透明外间距。需要完整保留旧版 300dp 宽、零外间距、零圆角
实体面板时使用 `MiuixNavigationDrawer.source`。这些圆角和间距是项目画面校准值，
不是小米公开参数。`MiuixAdaptiveScaffold` 可用 `floatingDrawer` 控制宽窗抽屉是否
悬浮，默认开启。

```dart
MiuixAdaptiveScaffold(
  items: const [
    MiuixNavigationItem(icon: Icon(Icons.home_outlined), label: '首页'),
    MiuixNavigationItem(icon: Icon(Icons.folder_outlined), label: '文件'),
  ],
  selectedIndex: selectedIndex,
  onDestinationSelected: (index) => setState(() => selectedIndex = index),
  glassNavigation: true,
  floatingDrawer: true,
  body: const ProjectPage(),
);
```

最大化桌面窗口时，不应把手机卡片直接拉伸到整块剩余画布。可在自适应 Scaffold 的
`body`、嵌套 Navigator 或具体页面外包一层 `MiuixAdaptiveContentFrame`：可用宽度不超过
1200dp 时完整占宽，超过后把主内容面限制在 1200dp 并居中，同时保持整页高度。1200dp 是
根据本项目 Windows 运行画面校准的内容宽度，不是小米公开设计参数；产品可以通过
`maximumWidth` 覆盖。NaN、无穷或非正值会安全回退到项目默认值。

```dart
MiuixAdaptiveScaffold(
  items: destinations,
  selectedIndex: selectedIndex,
  onDestinationSelected: selectDestination,
  body: MiuixAdaptiveContentFrame(
    child: Navigator(
      key: paneNavigatorKey,
      onGenerateRoute: buildPaneRoute,
    ),
  ),
);
```

`MiuixSplitViewController` 由调用方持有时必须释放。分隔条支持触摸拖动、Windows
鼠标光标、方向键调整、无障碍增减动作和边界震动。

拖动分隔条始终逐帧跟手；程序化调整和折叠在普通模式下使用短时尺寸过渡。系统
启用“减少动态效果”时，程序化尺寸也会直接到达最终位置，不保留过渡中的旧面板。

```dart
final split = MiuixSplitViewController(primaryExtent: 320);

MiuixSplitView(
  controller: split,
  minimumPrimaryExtent: 240,
  maximumPrimaryExtent: 480,
  primary: const FolderTree(),
  secondary: const DocumentView(),
);

// State.dispose
split.dispose();
```

## 日期、月份、年份、周历与日程

日期范围可直接嵌入，也可使用静态对话框入口：

```dart
final range = await MiuixDateRangePicker.show(
  context: context,
  initialRange: currentRange,
  minimumDate: DateTime(2025),
  maximumDate: DateTime(2030, 12, 31),
);
```

日历、范围选择器、月份、年份、周历和各类滚轮选择器默认使用 HyperOS 4
局部玻璃表面，具体模糊、透明度、圆角和阶段动画来自
`MiuixThemeData.hyperOs4`。它们不是官网公布的 dp 常量，而是本项目统一的
截图校准值。需要旧版实体面板时使用 `glass: false`；静态 `show` 入口也接受
同名参数。

范围日期不是 42 个互不关联的圆点：起点、中间日期和终点组成连续色带，并在
LTR/RTL 下使用正确的逻辑方向圆角。月历横向翻月会占有自己的横向手势，避免
嵌入 `PageView` 后误切换整个页面。

月份和年份共享 `MiuixMonthPickerController`，切换年份时会保留月份：

```dart
final month = MiuixMonthPickerController();

Column(
  children: [
    MiuixMonthPicker(controller: month),
    MiuixYearPicker(
      controller: month,
      minimumYear: 2020,
      maximumYear: 2035,
    ),
  ],
);
```

周历适合作为日程页头，`MiuixAgendaView` 会按本地日期排序并分组：

```dart
MiuixWeekCalendar(
  controller: weekController,
  onChanged: loadAgenda,
);

MiuixAgendaView(
  items: [
    MiuixAgendaItem(
      date: DateTime.now(),
      title: '设计评审',
      subtitle: '10:00–11:00',
    ),
  ],
);
```

## 重排列表与树

重排列表的数据顺序仍由应用管理。桌面建议显式放置 `MiuixDragHandle`；移动端
同一组件会使用延迟长按拖动。

拖动位置始终直接跟随指针。代理抬升与缩放在普通模式下保留连续反馈；系统开启
“减少动态”时直接显示完整抬升终态，不延迟拖动。代理圆角与树行共同读取
`MiuixThemeData.hyperOs4.collectionRowCornerRadius`，普通 `MiuixReorderableItem`
的静止表面也读取同一 token，因此不会在抬起时突然换形；旧版固定 18dp 行通过
`MiuixReorderableItem.source` 显式保留。完整列表使用
`MiuixReorderableList.source` 时，拖动代理也固定为旧 18dp，避免旧行在拖起后
突然切换到新主题圆角。

```dart
MiuixReorderableList<Task>(
  items: tasks,
  itemKey: (task) => ValueKey(task.id),
  onReorder: reorderTasks,
  itemBuilder: (context, task, index) => MiuixReorderableItem(
    index: index,
    child: Row(
      children: [
        Expanded(child: Text(task.title)),
        MiuixDragHandle(index: index),
      ],
    ),
  ),
);
```

树节点可以同时使用静态 `children` 或异步 `childrenLoader`。异步子项只在首次
展开时读取，失败后展开按钮会变成重试操作。

树行的选中背景与前景使用 `MiuixThemeData.hyperOs4.collectionRowMotion` 连续
过渡，圆角读取 `collectionRowCornerRadius`。系统在过渡中开启“减少动态”时，
当前选中行立即落到最终颜色；键盘、点击、异步加载及相应触觉保持不变。
旧版 15dp 选择行通过 `MiuixTreeView.source` 保留；普通树只给当前状态行使用
轻量语义色，不会把所有节点变成玻璃卡片。

`MiuixListSection` 普通入口把整个分组作为一个 HyperOS 4 内容玻璃面，圆角读取
`settingsGroupCornerRadius`，模糊和染色读取内容表面 token，也可逐项覆盖。标题、
脚注仍位于分组轮廓外，分隔线只出现在内部行之间；`.source` 保留旧 18dp
不透明分组。

分支展开和折叠使用独立的 `treeExpansionMotion`，子行通过高度与透明度连续进入或
退出，逻辑可见列表仍是键盘导航和语义状态的唯一依据。运行中开启“减少动态”会
丢弃半高插入/移除帧并显示当前控制器终态。

```dart
MiuixTreeView<String>(
  nodes: [
    MiuixTreeNode(
      value: 'root',
      label: '项目',
      childrenLoader: repository.loadChildren,
    ),
  ],
  onSelected: openNode,
);
```

## 搜索选择、ComboBox、标签与 Chip

`MiuixSearchableSelect` 支持单选、多选、选择上限、禁用选项和自定义过滤；
`MiuixComboBox` 是单选外观入口。

```dart
MiuixSearchableSelect<String>(
  label: '参与成员',
  multiple: true,
  maximumSelection: 5,
  options: const [
    MiuixSearchableSelectOption(value: 'design', label: '设计'),
    MiuixSearchableSelectOption(value: 'develop', label: '开发'),
  ],
  onChanged: updateMembers,
);
```

`MiuixTagInput` 会拦截回车和中英文逗号/分号，提供去重、长度、数量、校验、
退格删除和拒绝回调。`MiuixChipVariant` 提供 `assist`、`filter`、`choice`、
`input`、`suggestion` 五种语义，不要仅凭颜色模拟不同交互类型。普通
`MiuixTagInput` 默认使用一个完整的 HyperOS 4 输入玻璃面，圆角、模糊和透明度
跟随主题；内部标签不会再次嵌套背景模糊。旧版 18dp 不透明输入面通过
`MiuixTagInput.source` 显式保留。普通
`MiuixChip` 默认采用 HyperOS 4 低高度玻璃胶囊，选中时语义色连续过渡；需要
旧版不透明外观时显式使用 `MiuixChip.source`。模糊和染色强度由主题 token 与
应用的五档玻璃设置共同决定。

系统启用“减少动态效果”时，`MiuixTagInput` 的聚焦和校验描边会直接到达最终
状态，不再播放隐式过渡；标签提交、拒绝回调、触觉反馈和键盘输入能力保持不变。

## 表单与 PIN 输入

`MiuixFormField` 的错误信息在普通模式下使用短时尺寸过渡。在“减少动态效果”
模式下，错误区会直接切换最终结构，旧错误内容不会继续占位、保留语义或拦截
输入。普通 `MiuixFormSection` 的连续圆角读取 `settingsGroupCornerRadius`，默认内边距、
字段元数据间距、错误间距、分隔高度和无分隔字段间距读取 `hyperOs4` 表单 token；
`glass: true` 时只在完整分组轮廓内使用内容玻璃的模糊与染色值。需要旧版固定
18dp、不透明、16×12dp 内边距时使用 `MiuixFormSection.source`，字段旧间距使用
`MiuixFormField.source`。这些尺寸是项目校准值，不是小米公开参数。

`MiuixPinInput` 的聚焦、已填和错误描边也会直接到达终态，但输入、焦点、
自动前进和触觉反馈仍然可用。默认单元格圆角跟随 `textFieldCornerRadius`；旧版
14dp 单元格使用 `MiuixPinInput.source`，OTP 别名可用 `MiuixOtpInput.source`。
外部传入的控制器与焦点节点仍由应用负责释放。

## 流程步骤器与数据表

`MiuixProcessStepper` 和被动 `MiuixTimeline` 的边界不同：前者有当前步骤、
展开内容、前后移动和键盘导航，后者只显示事件历史。
时间线的标记直径、连接线厚度和横向项目宽度分别读取 `timelineMarkerExtent`、
`timelineConnectorWidth` 和 `timelineHorizontalItemWidth`，状态颜色、图标及标题权重
仍统一读取 `processStateMotion`。需要旧版固定 24/3/184dp 几何时使用
`MiuixTimeline.source`；被动时间线不会为了追求玻璃效果凭空增加卡片层。

```dart
MiuixProcessStepper(
  controller: processController,
  onContinue: saveAndContinue,
  onCancel: processController.previous,
  steps: const [
    MiuixProcessStep(title: '基本信息', content: BasicForm()),
    MiuixProcessStep(title: '确认', content: ReviewPanel()),
  ],
);
```

数据表使用泛型应用数据和稳定 `rowKey`，不会要求业务对象继承库类型。固定表头
下方独立纵向滚动，列宽超出时整表横向滚动。

```dart
MiuixDataTable<User>(
  items: users,
  rowKey: (user) => user.id,
  selectable: true,
  columns: [
    MiuixDataColumn(
      id: 'name',
      label: '姓名',
      comparator: (a, b) => a.name.compareTo(b.name),
      cellBuilder: (context, user) => Text(user.name),
    ),
  ],
);
```

键盘上下移动会同步保持当前行可见。启用“减少动态效果”时，键盘定位直接跳到目标
滚动位置，行的选中、焦点和鼠标悬停表面也直接切换终态；排序、选择和触觉反馈
保持不变。普通模式分别读取 `MiuixThemeData.hyperOs4.collectionScrollMotion`
和 `collectionRowMotion`；如果在键盘定位动画中途开启减少动态效果，滚动会立即
结束在最新焦点行，而不是继续播放旧动画。
普通 `MiuixDataTable` 的外层圆角读取 `cardCornerRadius`；启用 `glass` 时读取
`contentSurfaceBlur` 和 `contentSurfaceTintOpacity`，表头使用独立的
`dataTableHeaderTintOpacity` 叠色，因此不会用不透明矩形盖住背后的模糊内容。
显式 `cornerRadius` 仍然优先。需要旧版固定 20dp、不透明表格时使用
`MiuixDataTable.source`。所有这些材质数值都是项目画面校准点。

`MiuixProcessStepper` 会响应 `MediaQuery.disableAnimations`。开启“减少动态
效果”时，当前步骤的正文结构直接替换，标记和连接线颜色立即到达目标值；关闭时
继续使用原有展开尺寸与颜色过渡。键盘选择、点击及对应的语义震动不受影响。
普通构造的步骤圆角读取 `inlineSurfaceCornerRadius`；开启 `glass` 后只有当前步骤
在连续轮廓内读取 inline 模糊和染色。横向模式现在与纵向模式一样显示正文和动作区，
连接线、正文及动作展开共同读取 `processStateMotion`。需要旧版固定 18dp、不透明
步骤面时使用 `MiuixProcessStepper.source`。这些材质与尺寸均为项目推导值。

## 轮播与滑动操作

`MiuixCarousel` 保留手指横向拖动的直接跟随。系统开启“减少动态效果”时，拖动
松手和控制器翻页直接落到目标页，运行中的程序化翻页立即收敛，页面指示器不再
插值，同时暂停自动播放；关闭该设置后，后续操作恢复原有时序，但不会重播已经
跳过的翻页。默认程序化翻页读取 `MiuixThemeData.hyperOs4.carouselPageMotion`，
显式传入的非默认 `duration` 仍然优先；内置页码点读取独立的
`MiuixThemeData.hyperOs4.pageIndicatorMotion`。圆点直径、选中胶囊宽度和单项两侧
间距分别读取 `pageIndicatorDotSize`、`pageIndicatorActiveWidth` 和
`pageIndicatorSpacing`，轮播与指示器之间的垂直距离读取 `carouselIndicatorGap`；
这些数值是项目截图校准点，不是小米公开参数。`indicatorDotSize`、
`indicatorActiveWidth`、`indicatorSpacing`、`indicatorGap` 可逐项覆盖。
`MiuixCarousel.source` 固定保留轮播旧版 6/18/3/10dp 几何，独立的
`MiuixPageIndicator.source` 则保留 6/16/2.5dp 几何。

`MiuixSwipeAction` 同样区分直接操作和自主动画：手指拖动、阈值判断及震动保持
逐帧生效，松手归位、打开、关闭和取消操作直接到达相应侧。运行中开启减少动态
效果会结束当前缓动，旧的异步完成回调不会覆盖新的拖动结果。普通模式的自主归位
读取 `MiuixThemeData.hyperOs4.swipeActionMotion`，圆角读取
`collectionRowCornerRadius` 并跟随超椭圆设置。旧版固定 18dp 圆角矩形通过
`MiuixSwipeAction.source` 保留。组件嵌套在横向 `PageView` 中时，行内横滑会优先
取得手势并保留触摸阈值前累计的位移，不会一边露出操作一边切换页面。

`MiuixContextMenu` 普通入口现在默认使用 HyperOS 4 局部柔光玻璃，并读取共享的
`popupBlur`、`popupTintOpacity` 与 `popupCornerRadius`。菜单不再固定为 220dp：实际
宽度先按图标和文字测量，再限制在 `contextMenuMinWidth` 与
`contextMenuMaxWidth` 之间；动作高度、内边距、图标间距、窗口边距和柔和阴影分别
读取对应的 `contextMenu*` token。超过可用窗口高度时仅菜单内容滚动，少量动作仍
保持内容高度；最终定位使用实际渲染尺寸，因此靠近右侧或底部触发时不会按估算
尺寸错位。这些尺寸是项目画面校准点，不是小米公开参数。

长按/右键打开触觉与动作确认触觉保持实时。菜单自主淡入和缩放读取
`MiuixThemeData.hyperOs4.contextMenuMotion`；系统开启“减少动态”时，新打开的
菜单直接显示终态。需要旧版固定 220dp 宽、48dp 行高、18dp 圆角和不透明材质时，
直接组件使用 `MiuixContextMenu.source`，路由使用 `MiuixContextMenu.showSource`，
区域触发器可设置 `sourceStyle: true`。

## Sliver TopAppBar

`MiuixSliverTopAppBar` 必须放入 `CustomScrollView.slivers`。它直接使用 sliver
收缩量驱动 MIUIX 大标题、紧凑标题、底部内容和渐进玻璃，不需要在构建期通知
普通滚动控制器。浮动吸附读取
`MiuixThemeData.hyperOs4.sliverAppBarSnapMotion`；系统开启“减少动态”时吸附直接
到达端点，用户滚动造成的折叠比例仍然逐帧跟随手势。

普通入口的标题、带副标题标题、折叠标题和带副标题折叠高度分别读取
`sliverAppBarExpandedHeight`、`sliverAppBarExpandedSubtitleHeight`、
`sliverAppBarCollapsedHeight` 与 `sliverAppBarCollapsedSubtitleHeight`。默认
104/126/56/62dp 是项目画面校准值，并非小米公开参数。首帧列表从大标题区域下方
开始；标题折叠后，继续上滑会让列表进入固定顶部玻璃后方，而不会新增一块不透明
占位矩形。旧版像素迁移使用 `MiuixSliverTopAppBar.source`，保留
94/114/56/62dp 源几何。

```dart
CustomScrollView(
  slivers: [
    const MiuixSliverTopAppBar(
      title: '项目',
      glass: true,
      pinned: true,
      floating: true,
      snap: true,
    ),
    SliverList.builder(itemBuilder: buildRow),
  ],
);
```

`snap: true` 要求 `floating: true`，构造函数会在调试期检查这一约束。

## 文件拖放

`MiuixFileDropZone` 在 Windows 使用原生文件拖放。Android 选择文件涉及应用的
权限、SAF 和产品策略，因此组件不强制绑定某个选择器；宿主通过
`onBrowseRequested` 返回统一的 `MiuixDroppedFile`。

普通入口默认使用 HyperOS 4 inline 柔光玻璃，并读取 `inlineSurfaceBlur`、
`inlineSurfaceTintOpacity` 与 `inlineSurfaceCornerRadius`；`cornerRadius`、
`glassBlur`、`glassOpacity` 和 `showGlassSpecular` 可独立覆盖。拖入时的背景、
边框颜色和 1→2dp 宽度在同一 `MiuixSurface` 轮廓上过渡，玻璃裁剪、实体回退、
边框与点击反馈不会再使用两套不同圆角。需要旧版固定 22dp 普通圆角、不透明面板时
使用 `MiuixFileDropZone.source`。这些尺寸是项目校准值，并非小米公开参数。

```dart
MiuixFileDropZone(
  controller: dropController,
  acceptedExtensions: const ['png', 'jpg'],
  acceptedMimeTypes: const ['image/*'],
  maximumFiles: 8,
  maximumBytes: 10 * 1024 * 1024,
  onBrowseRequested: () async {
    final picked = await appFilePicker();
    return picked.map(toMiuixDroppedFile).toList();
  },
  onFilesAccepted: uploadFiles,
  onFilesRejected: showRejections,
  onError: (operation, error, stackTrace) {
    showFileOperationError(operation, error);
  },
);
```

拖放进入和离开仍会立即更新边框、底色及提示文案。启用“减少动态效果”时，表面
装饰不再插值，但原生拖放命中、文件校验、接受/拒绝回调和阈值触觉反馈保持可用。
选择器或原生拖放尚未完成时，另一条输入路径会暂时禁用，避免旧拖入事件留下悬空
高亮或与当前结果竞争。平台操作失败通过 `onError` 返回操作类型、原始错误和堆栈；
宿主可据此显示 Snackbar、重试入口或记录日志。未提供回调时错误交给 `FlutterError`
统一报告，组件仍会先释放忙碌状态。

如果应用要读取内容，构造 `MiuixDroppedFile` 时提供惰性的 `readBytes`。不要在
选择阶段立即把大文件全部载入内存。目录默认拒绝，只有业务真的支持递归目录时
才设置 `allowDirectories: true`。

## 命令面板

普通 `MiuixCommandPalette` 在直接嵌入页面或桌面浮层时，自带一层 HyperOS 4
弹层玻璃；模糊、染色和连续圆角分别读取 `popupBlur`、`popupTintOpacity` 与
`popupCornerRadius`，也可以通过构造参数逐项覆盖。它只在完整面板边界采样一次
背景，命令行、选中行和快捷键标签不会再次创建背景模糊。

`MiuixCommandPalette.show` 由 `MiuixDialog` 独占这一层玻璃，内部命令面板使用
透明壳，因此整条弹窗路径仍然只有一个 backdrop filter。旧页面如果已经自己提供
不透明卡片或弹窗，使用 `MiuixCommandPalette.source`；需要直接打开旧式不透明
弹窗时使用 `MiuixCommandPalette.showSource`。

静态 `show` 会在对话框关闭后执行命令，避免命令内部导航与弹层退场竞争：

```dart
await MiuixCommandPalette.show(
  context: context,
  commands: [
    MiuixCommand(
      id: 'open',
      title: '打开文件',
      shortcut: const SingleActivator(
        LogicalKeyboardKey.keyO,
        control: true,
      ),
      onInvoke: openFile,
    ),
  ],
);
```

需要全局 Ctrl/Cmd+K 时，把页面树包在 `MiuixCommandPaletteShortcut` 中。命令
支持标题、说明、分类、关键词、图标、快捷键显示和禁用状态。

命令过滤仍会立即更新结果。在“减少动态效果”模式下，面板高度直接采用过滤后
结果的最终尺寸，不保留一个零时长的 `AnimatedSize`；焦点、方向键和快捷键行为
不受影响。普通模式继续使用短时高度过渡。

## 已优化的复合控件

- `MiuixActionSheet`：标题、说明、取消项、禁用/选中/破坏性动作、玻璃和震动。
  默认沿用 HyperOS 4 BottomSheet 的单层局部玻璃；只有明确兼容旧界面时才传入
  `glass: false`。
- `MiuixSegmentedControl`：单选/多选、禁止空选、禁用项、均分宽度、方向键和玻璃。
  普通构造器默认采用 HyperOS 4 玻璃胶囊；单选且 `expanded: true` 时，选中态
  使用同一块表面在等宽项目之间连续滑动。系统开启“减少动态效果”后立即落位。
  旧版 42dp 不透明样式需显式使用 `MiuixSegmentedControl.source`。
- `MiuixInlineAlert` / `MiuixBanner`：标题、动作、关闭、live region 和玻璃。
  普通构造器默认使用带语义染色的 HyperOS 4 局部玻璃；`.source` 保留旧式不透明
  表面。开启玻璃时不会再丢失信息、警告、错误或成功状态的颜色层级。
- `MiuixExpandableCard`：受控/非受控展开、说明、尾部内容、语义和震动。普通
  构造器使用连续圆角玻璃和统一展开时序，并遵守“减少动态效果”；
  `MiuixExpandableCard.source` 保留原不透明矩形兼容样式。
- `MiuixLoadingDialog`：详情、确定进度、取消回调和玻璃。默认直接复用
  `MiuixDialog` 自己的单层玻璃，避免嵌套两次模糊；旧式不透明弹层显式传入
  `glass: false`。
- `MiuixToast`：操作、短/长/无限/自定义时长、关闭按钮和返回控制器。
- `MiuixControlCenterTile`：普通构造器默认使用 HyperOS 4 内容玻璃，模糊、染色和
  圆角跟随主题及五档玻璃设置，启用状态颜色使用统一输入动效；需要迁移旧页面时可
  使用 `MiuixControlCenterTile.source` 保留原 20dp 不透明表面。
- `MiuixControlSliderTile`：亮度、音量等紧凑 Slider 卡片默认使用同一内容玻璃
  token，普通构造器的圆角跟随主题；`MiuixControlSliderTile.source` 保留旧版
  18dp 不透明表面。内部 Slider 会优先取得横向拖动，嵌套在 `PageView` 时不会把
  调值手势误判为页面切换。
- `MiuixStepperRow`：pending/current/completed/error 状态、点击和尾部内容。标记
  颜色、图形淡入缩放与当前标题字重共享 `processStateMotion`，按压轮廓使用集合行
  圆角；系统启用“减少动态效果”时直接显示最终状态。
- `MiuixEmptyStateView`：类型化图标、主次操作、紧凑模式、live region 和玻璃。
  基础 `MiuixEmptyState` 同样使用统一的最大阅读宽度、图标和间距 token，并默认
  发布 live-region；需要迁移前无宽度限制的 20/52dp 布局时使用
  `MiuixEmptyState.source`。
- `MiuixMultiSelect`、`MiuixSearchableSelect` 与 `MiuixComboBox`：普通构造器的
  触发字段默认使用 HyperOS 4 内容玻璃，模糊、染色和连续圆角分别跟随
  `contentSurfaceBlur`、`contentSurfaceTintOpacity` 与
  `textFieldCornerRadius`，也可逐项覆盖。多选值使用紧凑输入 Chip，避免在父级
  玻璃内再次模糊；选择对话框保持按内容定高并复用统一弹层材质。迁移旧页面时可
  使用对应的 `.source` 构造器保留 16/18dp 不透明触发字段。
- `MiuixAutoCompleteField`：结果面默认使用 HyperOS 4 弹层玻璃并从编辑字段起点
  锚定，宽度随字段但在窄屏内收、在桌面受上限约束；字段与弹层圆角、模糊、染色
  和镜面高光均可覆盖。少量结果保持内容定高，超限后才滚动；`.source` 保留
  16dp 字段与 18dp 不透明结果面。
- 应用级卡片：`MiuixAccountHeader`、`MiuixDeviceCard`、`MiuixAppListTile`、
  `MiuixNotificationCard`、`MiuixPermissionCard` 和 `MiuixUpdateCard` 的普通
  入口统一使用内容玻璃，支持模糊、染色、镜面和圆角覆盖；对应 `.source` 保留
  16dp 不透明卡片，业务状态色不会扩散为整块高饱和背景。

## 控制器与平台注意事项

- 调用方创建的控制器、`FocusNode`、`TextEditingController` 和
  `ScrollController` 必须由调用方释放；组件内部创建的状态会自动释放。
- Android 精确震动由本包原生插件映射；Windows 和其他平台使用安全回退。
- 玻璃效果受 `MiuixThemeData.enableGlass` 和五档玻璃强度共同控制。组件的
  `glass: true` 表示允许玻璃，不会绕过应用级性能开关。
- 文件拖放依赖 `desktop_drop`，作为 `flutter_miuix` 的传递依赖自动解析；
  消费应用不需要再次声明，除非直接使用该包的类型。当前 Flutter 3.44 工具链显式
  约束在 `desktop_drop 0.7.x`；0.8.x 需要宿主真正启用 AGP 9 Built-in Kotlin，
  不能只根据 AGP 主版本升级。
- 以上控件都是 Flutter 源码组件，发布时会编译进 APK/AAB 或 Windows EXE，
  不以独立 AAR 或 DLL 交付界面代码。
