# 常用组件示例

## flutter_miuix 扩展控件

以下控件是库级公共 API，源码位于 `lib/src/extensions/`。它们用于补齐业务应用
常见的日期、输入、反馈和数据展示能力；当前 Compose MIUIX 官方组件目录没有
同名独立组件时，文档会明确把它们称为 flutter_miuix 扩展，而不是原版移植。

日期和时间组均可内联使用，也可以调用静态 `show` 方法打开 MIUIX 对话框：

```dart
final date = await MiuixDatePicker.show(
  context: context,
  initialDate: DateTime.now(),
);
final time = await MiuixTimePicker.show(
  context: context,
  initialTime: const MiuixTimeValue(hour: 9, minute: 30),
);

MiuixCalendar(
  controller: calendarController,
  selectionMode: MiuixCalendarSelectionMode.range,
  minimumDate: DateTime.now(),
  onChanged: (state) => setState(() => range = state.selectedRange),
);
```

`MiuixDatePicker` 支持月历和三滚轮模式；`MiuixTimePicker` 支持 12/24 小时、
分钟步进和可选秒；`MiuixDateTimePicker` 组合日期与时间阶段；
`MiuixDurationPicker` 可独立显示天、时、分、秒。滚轮直接复用
`MiuixNumberPicker`，所以拖动、回弹和逐项震动与库内原版滚轮一致。
系统启用“减少动态效果”时，手指拖动和跨项震动仍然逐帧生效，但松手后的惯性衰减
与居中弹簧会被跳过，滚轮直接提交离当前位置最近的一项。普通惯性运动进行中再开启
该设置，也会在当前最近项停止并只回调一次，不会继续滚动或重复选择。
这些日期时间扩展现在默认使用 `MiuixThemeData.hyperOs4` 中的日历/选择器玻璃、
圆角和 380ms 连续切换令牌。日期范围会把中间日期连接为连续色带，端点保留
方向正确的胶囊圆角；月历横向切换会优先于外层页面横向切换。迁移旧页面时可在
对应日历或选择器上传入 `glass: false`，显式恢复不透明表面。

`MiuixDateRangePicker` 上方的开始与结束日期端点现在和月历共同读取
`calendarCornerRadius`、`calendarBlur` 与 `calendarTintOpacity`。默认模式下三个
局部轮廓分别采样真实背景，端点之间和月历外侧仍保持透明；`glass: false` 会同时
关闭端点与月历的玻璃，但不会改变当前日期范围、交互或几何。端点激活色继续使用
语义 primary-container，并通过 `pickerStageMotion` 连续过渡。

`MiuixDateTimePicker` 的日期/时间入口使用同一个滑动选择表面，不再由两个宽度
不同的独立按钮模拟状态。系统启用“减少动态效果”后，日历选择与阶段切换会直接
稳定落位。

`MiuixExpandableCard` 与 `MiuixCascadingMenu` 的内容展开和上下方向箭头同样遵守
这一设置。减少动态效果下直接构建展开或折叠终态，而不是把 `AnimatedCrossFade`
的时长简单设为零；这样可以避免 Flutter 在布局过程中重新触发布局的异常。

输入和表单扩展示例：

```dart
MiuixPinInput(
  length: 6,
  onCompleted: verifyCode,
);

MiuixAutoCompleteField<String>(
  label: '城市',
  displayStringForOption: (value) => value,
  optionsBuilder: (editing) => cities.where(
    (city) => city.contains(editing.text),
  ),
  onSelected: selectCity,
);

MiuixFormSection(
  title: '通知方式',
  glass: true,
  children: [
    MiuixMultiSelect<String>(
      options: const [
        MiuixMultiSelectOption(value: 'push', label: '推送'),
        MiuixMultiSelectOption(value: 'mail', label: '邮件'),
      ],
      onChanged: saveChannels,
    ),
  ],
);
```

PIN/OTP、自动完成和多选均有公开控制器，适合表单恢复、外部重置和自动化测试。
`MiuixFormField<T>` 直接参与 Flutter `Form` 的保存与验证流程，并用 MIUIX
语义色显示说明和错误信息。PIN 活动单元格、Tag 输入焦点和校验边框统一读取
`MiuixThemeData.hyperOs4.inputStateMotion`；流程步骤的标记、连接线和内容展开读取
`processStateMotion`。两者都是可由应用主题覆盖的项目校准值，并支持运行中切换
“减少动态效果”后立即落到当前状态。

普通 `MiuixAutoCompleteField` 的字段圆角读取 `textFieldCornerRadius`，结果面读取
`popupCornerRadius`、`popupBlur` 与 `popupTintOpacity`。结果面默认从字段起点锚定、
匹配字段宽度，在窄窗口内自动收窄，并在宽窗口受 `maximumOptionsWidth` 限制；
需要紧凑结果面时设置 `matchFieldWidth: false` 并用 `minimumOptionsWidth` 指定宽度。
`popupGlass`、模糊、透明度、镜面高光及两个圆角都可单独覆盖。迁移旧页面时使用
`MiuixAutoCompleteField.source`，同时恢复 16dp 字段和 18dp 不透明结果面。结果
数量很少时仍按内容定高，超过 `maximumOptionsHeight` 后才在锚定面内滚动。

普通 `MiuixFormSection` 默认启用一个完整分组的内容玻璃；普通
`MiuixDataTable` 默认让表头和数据行共用一个裁剪后的内容玻璃；普通
`MiuixProcessStepper` 只在当前展开步骤上启用局部玻璃，待处理步骤不会堆成一列
重复玻璃卡片。三者仍可显式设置 `glass: false`，只关闭材质而不切回旧几何。
它们的圆角、模糊、透明度以及字段/错误间距由 `hyperOs4` token 统一校准。
迁移旧页面时可使用 `MiuixFormSection.source` 和 `MiuixFormField.source` 保留原来的
固定 18dp 不透明分组与间距；`MiuixDataTable.source` 和
`MiuixProcessStepper.source` 分别保留原来的 20dp 表面和 18dp 步骤面。

分栏的程序化折叠/展开和命令面板的内容高度变化统一使用
`MiuixThemeData.hyperOs4.inlineSurfaceMotion`。拖动分栏仍然逐帧跟手，不会因为
主题时长产生输入延迟；减少动态效果下，分栏与命令面板都直接构建目标布局。

交互和加载状态示例：

```dart
MiuixSwipeAction(
  endActions: [
    MiuixSwipeActionItem(
      label: '删除',
      backgroundColor: MiuixSemanticColors.of(context)['error'],
      onPressed: deleteItem,
    ),
  ],
  child: const SizedBox(height: 72, child: Text('消息')),
);

MiuixContextMenuRegion<String>(
  items: const [
    MiuixContextMenuItem(value: 'copy', label: '复制'),
    MiuixContextMenuItem(value: 'delete', label: '删除', destructive: true),
  ],
  onSelected: handleAction,
  child: messageCard,
);

const MiuixSkeleton(width: 180, height: 20);
```

侧滑操作按 `MiuixSwipeActionDefaults.actionExtent` 为每个动作分配相同宽度，
支持 RTL，并在越过提交阈值时震动。上下文菜单同时处理 Android 长按和
Windows 鼠标右键，弹层会避让安全区。骨架屏在系统关闭动画时自动停止闪光。

展示与数值控件包括：

```dart
MiuixRating(
  controller: ratingController,
  allowHalf: true,
  onChanged: saveRating,
);

MiuixDial(
  minimum: 16,
  maximum: 30,
  divisions: 28,
  onChanged: setTemperature,
);

MiuixTimeline(items: orderEvents);
MiuixCarousel(children: promotionalCards, showIndicator: true);
```

`MiuixEmptyStateView` 统一 empty、noResults、offline、error、restricted 五种
空状态；`MiuixListSection` 普通入口提供单层玻璃分组容器，并允许覆盖模糊、
染色、镜面与圆角；旧 18dp 不透明分组使用 `MiuixListSection.source`。它只给
完整分组绘制一个表面，不会给每个子行重复套玻璃。`MiuixTimeline` 支持纵向和
横向，并由主题校准标记、连接线和横向里程碑宽度；旧固定几何通过 `.source`
保留。`MiuixCarouselController` 可由业务代码切页并监听当前页。评分和旋钮都
提供无障碍增减动作、拖动反馈和离散刻度震动。轮播内置页码点与独立
`MiuixPageIndicator` 共用 HyperOS 4 页码指示动效令牌和减少动态效果契约。

独立轮播或引导页可以使用 `MiuixPageIndicator(count: ..., index: ...)`。普通模式
下，宽点切换使用 `MiuixThemeData.hyperOs4.pageIndicatorMotion`，以便应用统一
校准连续动效；系统启用“减少动态效果”或在动画中途启用时，所有圆点会立即落到
当前索引对应的 16dp/6dp 终态，不保留半宽中间帧。

## 滚动反馈

`MiuixVerticalScrollBar`、`MiuixHorizontalScrollBar` 和通用
`MiuixScrollBar` 保持窄而弱化的浮层，不把滚动轨道做成第二条实体导航。现有
3.64dp 默认拇指宽度与这一 HyperOS 4 原则一致，因此默认构造器不额外制造一套
未经官方公布的新尺寸。

滚动条现在响应 `MediaQuery.disableAnimations`：手指滚动、滚轮滚动和直接拖动
拇指仍逐帧跟手；系统开启“减少动态效果”后，悬停宽度、内容尺寸引起的拇指长度
变化，以及可见停留后的淡出会直接到达终态。关闭该设置时，原有 150ms 高亮、
1000ms 可见停留和 500ms 淡出保持不变。`MiuixOverscrollEffect` 没有独立的
自主动画控制器，越界位移继续由滚动物理和输入直接决定。

## 顶栏与普通底部导航

```dart
MiuixScaffold(
  topBar: const MiuixTopAppBar(
    title: '主页',
    glass: true,
    actions: [Icon(Icons.more_vert)],
  ),
  body: pages[index],
  bottomBar: MiuixNavigationBar(
    items: const [
      MiuixNavigationItem(icon: Icon(Icons.home_outlined), label: '主页'),
      MiuixNavigationItem(icon: Icon(Icons.settings_outlined), label: '设置'),
    ],
    selectedIndex: index,
    onDestinationSelected: (value) => setState(() => index = value),
    displayMode: MiuixNavigationBarDisplayMode.iconAndText,
    glass: true,
  ),
);
```

`MiuixTopAppBar` 默认使用持续高斯磨砂背景，右侧一个操作会形成 48dp 圆形玻璃面，
多个操作共用连续胶囊。需要旧的滚动渐显背景时显式传入
`blurStyle: MiuixTopAppBarBlurStyle.progressive`；需要无背景图标时传入
`actionStyle: MiuixTopAppBarActionStyle.plain`。尺寸为项目画面推导值。

长列表页面优先把 `MiuixSliverTopAppBar` 作为 `CustomScrollView` 的第一个 sliver。
普通入口读取 HyperOS 4 的四个展开/折叠高度 token：首屏正文从大标题下方开始，
继续上滑后正文进入固定顶部玻璃后方。需要旧版 94/114/56/62dp 几何时使用
`MiuixSliverTopAppBar.source`。这些新默认高度是项目画面校准值，不是小米公开参数。

导航栏支持 `iconAndText`、`iconOnly`、`textOnly` 和 `iconWithSelectedLabel`。普通
悬浮胶囊使用 `MiuixFloatingNavigationBar`。图标和文字同时显示时默认采用图标在上、
文字在下的纵向结构；`iconOnly` 和 `textOnly` 仍可显式切换。默认单项和选中底板均为
52dp 高，选中底板距 58dp 外层玻璃上下各 3dp，左右端按同一胶囊轮廓同心内缩，
不再使用只有图标或围绕图标收窄的默认构图。2/3/4/5 项会按数量使用
不同的项目校准宽度，中文、英文和三种显示模式仍保持严格等分。这些尺寸是按官网
联系人、文件管理演示画面比例得到的项目校准值，不是小米公开的 dp 规范。
选中块支持整段左右拖动、RTL 逻辑方向、跨项触觉反馈和临界阻尼吸附。拖动时默认在
四边额外内缩 2dp，因此滑块比松手后的选中圆角矩形略小；这项差异是项目交互要求，
并非照搬 iOS 拖动时放大的液态指示器。

需要当前原版示例的 iOS-like 液态
导航时，使用独立的公共组件：

```dart
MiuixIosLiquidGlassNavigationBar(
  items: items, // 2 至 5 项，组件按原版自动等分
  selectedIndex: index,
  onDestinationSelected: (value) => setState(() => index = value),
  showBlur: true,
  trailingAction: MiuixIconButton(
    icon: const Icon(Icons.search),
    onPressed: openSearch,
  ),
);
```

该组件包含等宽拖拽选项、越界回弹、按压形变、重力高光与折射 shader，
不是普通悬浮栏的换色样式。外层 `MiuixScaffold` 必须设置 `extendBody: true`，
页面内容才能出现在胶囊及其透明四角后方。
HyperOS 4 默认面板高 56dp，静止选中镜片使用一个完整 Tab 的宽度和 48dp 高度，
拖动时四边内缩约 2dp。需要来源示例的 64dp 面板和 56dp 镜片时使用
`MiuixIosLiquidGlassNavigationBar.source`。
面板阴影不参与按压放大，玻璃表面单独缩放；选中内容按每个 Tab 自身中心缩放，
不会与下层普通内容错位。Android 静止态不再补画选中镜片高光边，内阴影直接贴合
镜片外轮廓，因此首尾项不会出现两个彼此分离的同心椭圆。
传入 `trailingAction` 后，主胶囊与默认 56dp 独立圆形操作组成居中的拆分底栏；两者间隔
12dp，每个目的地优先宽 80dp，窄窗口再等分收缩。独立操作不参与选中索引和拖拽。
这些数值按参考截图推导，不是小米公开的官方参数。
拖动阶段位置逐帧直跟，松手以最终触点最近槽位提交目标（释放速度不再投射到相邻项）；点击在松手确认后执行一次目标弹簧，真实选择变化只发出一次
`segmentTick` 触觉；这些交互差异是项目真机校准值，不宣称为小米公开参数。
系统开启“减少动态效果”时，触点对应的按压和高光状态立即显示，拖动位置直接
跟手；松手吸附、取消、程序化选择、缩放恢复和面板橡皮筋归位均直接到达终态。
设置在弹簧运行中改变时会清除旧速度，不会由已取消的通道再次覆盖当前选择。

普通 `MiuixNavigationRail(items: ...)` 现在是 HyperOS 4 宽屏默认：只有距窗口
边缘留白后的连续圆角轨道采样背景，轨道外保持透明；选中目标使用局部语义色表面，
并优先显示 `selectedIcon`。模糊、透明度、外边距、项目高度和动效都集中在
`MiuixThemeData.hyperOs4`。点击新的目的地会触发 `segmentTick` 语义触觉；系统
启用“减少动态效果”时，选中、显示模式和展开宽度均直接到达目标状态。

需要复刻当前原版宽屏导航轨时，由状态对象控制展开和收起。状态通常保存在页面的
`State` 中，并在 `dispose` 时释放：

```dart
final railState = MiuixNavigationRailState();

MiuixNavigationRail.source(
  state: railState,
  expandContentDescription: '展开导航栏',
  collapseContentDescription: '折叠导航栏',
  children: [
    MiuixNavigationRailItem(
      selected: index == 0,
      onClick: () => setState(() => index = 0),
      icon: const Icon(Icons.home_outlined),
      label: '主页',
    ),
    MiuixNavigationRailItem(
      selected: index == 1,
      onClick: () => setState(() => index = 1),
      icon: const Icon(Icons.settings_outlined),
      label: '设置',
      badge: const MiuixBadge.source(content: Text('8')),
    ),
  ],
);

// 也可以由窗口断点或应用操作驱动。
railState.expand();
railState.collapse();
railState.toggle();
```

传入 `state` 后会显示原版内置 Sidebar 按钮，并用同一条临界阻尼弹簧在
80dp 与 240dp 间改变宽度；图标、文字、字号和选中胶囊会连续变形。未传入
`state` 时仍是原版的经典紧凑轨，此时可以用
`MiuixNavigationRailDisplayMode` 选择兼容显示模式。原版
`NavigationRailItem` 是受控的可视组件；尺寸和间距可以从
`MiuixNavigationRailDefaults` 获取。`badge` 是独立的原版徽标插槽，会按
`BadgedBox` 的偏移覆盖在 28dp 图标上，不会跟随图标容器缩放。
原版任意子组件入口使用 `MiuixNavigationRail.source(children: ...)`；原版数据列表
入口使用 `MiuixNavigationRail.sourceItems(items: ...)`。这样旧的 80dp/240dp
实体背景、分隔线、几何和弹簧不会继续成为新页面的默认视觉。

## 页面导航动画

`MiuixNavigationPageTransitionsBuilder` 是组件库公开的 HyperOS 页面切换构建器，
`MiuixPageRoute` 提供与其一致的正向和反向周期。返回动画不会直接把倒计时中的
`animation.value` 填进正向弹簧曲线，而是按退出已用时间重新启动响应，从而消除
二级页面返回时的起步停顿。两个页面通道、暗色遮罩、连续圆角和输入阻断选项均由
同一个方向感知进度驱动；LTR 与 RTL 会分别从逻辑末端进入并向逻辑末端退出。

如需在自定义路由中复用同一计算，可调用
`MiuixNavigationTransitionMotion.resolve(animation)`；确定性测试可使用
`resolveValue(value: ..., status: ...)`。500ms 周期、四分之一底页偏移和 32dp
移动页圆角是当前项目根据官方应用画面与运行行为得到的校准值，不是小米公开的
官方动效参数。

## 徽标

```dart
MiuixBadgedBox.source(
  badge: const MiuixBadge.source(content: Text('99+')),
  child: const Icon(Icons.settings_outlined, size: 28),
)
```

`MiuixBadge.source()` 是 6dp 圆点；传入 `content` 后最小尺寸为 16dp，
文字较长时会按原版 `CircleShape` 扩展成胶囊，而不是把文字画到圆形背景外。
`MiuixBadgedBox.source` 使用原版的 6dp 空徽标偏移或 12dp/14dp 内容徽标
偏移，并在 Android 分数密度下逐项换算为物理像素。自定义页面若需要复刻
Compose `FlowRow(horizontalArrangement = SpaceEvenly)`，还应按每一行的整数
像素余数分配锚点，不能直接假设 Flutter `WrapAlignment.spaceEvenly` 的小数
位置会得到相同结果。

## 正文与富文本

普通 `MiuixText` 和 `MiuixText.rich` 默认使用 HyperOS 4 内容正文角色，读取当前
主题的 `bodyMedium`；项目当前根据小米官方应用画面比例校准为 16sp，这不是小米
公开的官方字号参数。需要逐像素保留 MIUIX 1.0.9 Main 角色时，分别使用
`MiuixText.source` 和 `MiuixText.sourceRich`，其默认字号仍为 17sp。

```dart
const MiuixText('HyperOS 4 正文');

MiuixText.rich(
  TextSpan(
    text: '正文与',
    children: [TextSpan(text: '强调内容', style: TextStyle(fontWeight: FontWeight.w600))],
  ),
);

const MiuixText.source('MIUIX 1.0.9 来源复刻正文');
```

显式 `style`、`fontSize` 和颜色仍会覆盖默认角色；自动字号、`minLines`、
`maxLines`、富文本链接、`WidgetSpan`、布局回调及语义行为不因视觉入口分层而改变。

## 按钮与文字按钮

普通 `MiuixButton` 可使用 `child` 传入原版任意 Row 内容；仅需文字时使用
`MiuixTextButton`。当前原版允许通过 `textStyle` 覆盖文字样式：

```dart
MiuixTextButton(
  label: '需要在窄区域自然换行的操作',
  onPressed: submit,
  textStyle: const TextStyle(
    fontSize: 15,
    height: 1.35,
    fontWeight: FontWeight.w600,
  ),
);
```

未传 `textStyle` 时使用原版按钮文字角色；自定义样式没有颜色时继续继承
按钮当前的启用或禁用文字色，显式设置的 `textStyle.color` 优先。原版没有为
TextButton 强制 `maxLines = 1`，所以有限宽度下会自然换行；无界父布局仍保持
文字的自然宽度。普通构造器默认使用 HyperOS 4 项目校准的 48dp 最小高度和
24dp 连续圆角；Android 触控与无障碍目标仍不少于 48dp。需要 MIUIX 1.0.9
的 40dp/16dp 几何时，显式使用 `MiuixButton.source` 或
`MiuixTextButton.source`。`MiuixIconButton` 默认绘制为 44dp、22dp 圆角，
旧版 40dp 几何对应 `MiuixIconButton.source`。

所有经 `MiuixPressable` 实现的卡片、按钮、FAB 和工具栏操作，以及专用
`MiuixIconButton`，都会读取系统 `MediaQuery.disableAnimations`。开启“减少动态
效果”后，按压缩放、倾斜和叠加指示层直接落到清晰的目标状态，不再运行弹簧或
延迟淡出；触控、键盘、鼠标状态和已有语义震动仍然保留。设置在动画进行中发生
变化时，当前控件也会立即停止旧动量，不需要重建整个应用。

页面级反馈同样遵守该设置：普通底部导航的选中文字布局会立即落位，大标题顶栏
直接完成折叠端点与紧凑标题显隐，Tooltip 直接显示并在下一帧安全移除 Overlay，
不会为了跳过视觉动画而遗留不可见的全屏命中层。悬浮导航、分段选择器、Chip、
日历和日期时间选择器也继续使用各自已有的零时长分支。

基础选择控件也遵守同一边界。`MiuixSwitch` 会立即停止拇指位置、按压缩放以及
轨道/拇指颜色弹簧；拖动时仍直接跟随手指。`MiuixCheckbox` 和 `MiuixRadio`
会立即完成勾选路径、混合态形变和颜色端点。切换系统设置时，正在运行的动画会在
当前控件上直接结束；触控区域、语义状态、横向手势优先级和开关震动保持不变。

不定进度反馈也会实时读取该设置。线形扫动条、圆形扫动环和轨道点在普通模式下
保持原有循环节奏；开启“减少动态效果”后立即停在清晰的静态加载帧，之后不会
偷偷重启循环。静态帧仍向辅助技术暴露 `loadingSpinner` 角色，并不伪装成已经
完成的确定型进度；关闭该设置后才恢复循环。带数值的线形和圆形进度继续直接表达
传入百分比，不受不定进度动画策略影响。

`MiuixPullToRefresh` 对“减少动态效果”采用完整状态机策略，而不是只把刷新图标
停住：手指拖动仍实时跟随，越过阈值的震动和刷新回调保持不变；松手后的回弹、
进入刷新位置的弹簧以及完成后的收缩会直接到达目标。刷新中的图标固定在稳定角度，
但“刷新成功”状态仍至少完整绘制一帧，避免辅助功能设置导致结果反馈完全不可见。
如果系统在回弹或完成动画途中切换该设置，当前异步流程会继续完成，不会卡在
“松开刷新”或“刷新成功”状态。

## 浮动工具栏

```dart
MiuixFloatingToolbar(
  color: MiuixSemanticColors.of(context)['primary'],
  cornerRadius: 20,
  child: Padding(
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        MiuixIconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        MiuixIconButton(icon: const Icon(Icons.delete), onPressed: () {}),
      ],
    ),
  ),
);
```

原版 `FloatingToolbar` 接收一个任意 `child`，不会自动排列或着色内部操作。
普通构造器现在默认使用 HyperOS 4 局部玻璃胶囊，模糊、透明度和圆角来自
`MiuixThemeData.hyperOs4`；材质只裁剪在工具栏轮廓内，外侧不会补成矩形。
需要旧 MIUIX 不透明表面时使用 `MiuixFloatingToolbar.source`。旧版默认值
仍可从 `MiuixFloatingToolbarDefaults` 获取。`showDivider` 开启后会在
内容外增加原版 0.75dp 分隔层，因此会改变整体测量尺寸；它不是画在内部的普通
`BoxBorder`。旧版 `children`、`orientation`、`spacing` 和
`contentPadding` 仍作为 Flutter 便捷接口保留。

## 标签行

```dart
var selectedIndex = 0;
final interactionSource = MiuixInteractionSource();

MiuixTabRow(
  tabs: const ['标签 1', '标签 2', '标签 3'],
  selectedTabIndex: selectedIndex,
  onTabSelected: (index) => setState(() => selectedIndex = index),
  interactionSource: interactionSource,
);
```

普通 `MiuixTabRow` 和 `MiuixTabRowWithContour` 现在默认使用 HyperOS 4 的局部
玻璃选项胶囊。默认项目校准值为 44dp 外层高度、3dp 内边距、38dp 可见标签高度、
19dp 标签连续圆角和 22dp 外层连续圆角；这些数值来自同尺寸官方画面比例校准，
不是小米公开的 dp 规范。玻璃模糊、染色和 380ms 连续选中位移共用主题中的紧凑
选项组 token，并随系统“减少动态效果”直接落到目标位置。默认按压指示层开启，
切换到不同标签时使用 `segmentTick` 语义震动。

`selectedTabIndex` 仍是完全受控状态：点击后组件只回调新索引，调用方更新索引后
指示器才会移动。旧版像素对照必须显式使用 `MiuixTabRow.source` 或
`MiuixTabRowWithContour.source`；它们分别保留 MIUIX 1.0.9 的 42dp 普通实体条，
以及 45dp 外层高度、5dp 内边距、8dp 标签圆角、13dp 外层圆角和 200ms 线性
位移。旧版 `.source` 默认 `showIndication: false` 且不新增震动。外部创建的
`MiuixInteractionSource` 仍由调用方释放。

## 卡片与开关

普通 `MiuixFloatingActionButton` 默认是 HyperOS 4 局部玻璃主操作面：只在
圆形或扩展胶囊自身轮廓内采样后方内容，触点光、折射高光、填充和阴影共用同一个
`ShapeBorder`，圆角外不会出现矩形底板。模糊与染色分别读取
`MiuixThemeData.hyperOs4.floatingActionButtonBlur` 和
`floatingActionButtonTintOpacity`，并响应应用五档玻璃强度。官网没有公布这两项
数值，当前默认值是项目画面校准点。

需要 MIUIX 1.0.9 的实体主色按钮时，显式使用
`MiuixFloatingActionButton.source`。它继续保留 60 × 60dp 最小尺寸、4dp 阴影、
`onSurface` 默认内容色和原版 `CircleShape` 百分比轮廓。两个构造器的 `child`
都是任意内容插槽；内容超过最小尺寸时表面自然扩大，不会被裁进固定图标框。

```dart
MiuixCard(
  insideMargin: const EdgeInsets.all(16),
  colors: MiuixCardDefaults.colors(
    context,
    color: MiuixSemanticColors.of(context)['primaryVariant'],
    contentColor: MiuixSemanticColors.of(context)['onPrimaryVariant'],
  ),
  feedbackType: MiuixPressFeedbackType.sink,
  showIndication: true,
  onTap: () {},
  child: Row(
    children: [
      const Expanded(child: Text('启用功能')),
      MiuixSwitch(
        value: enabled,
        onChanged: (value) => setState(() => enabled = value),
      ),
    ],
  ),
);
```

`MiuixCardColors` 分别控制背景色和卡片内继承的文字/图标色；两项可以通过
`MiuixCardDefaults.colors` 独立覆盖。`insideMargin` 对应原版 Card 的内部
边距，旧版 `padding` 参数仍保留兼容，但不要同时传入两者。

普通 `MiuixCard` 默认使用 HyperOS 4 局部背景玻璃，模糊、染色和连续圆角从
`MiuixThemeData.hyperOs4` 读取，并受应用五档玻璃强度控制。调用方颜色会作为
玻璃语义染色保留，不会因开启玻璃而被忽略。需要原版 MIUIX 的 16dp 不透明
卡片时使用 `MiuixCard.source`；也可以对普通构造器显式设置 `glass: false`。
`showGlassSpecular` 可在保留模糊和染色时单独关闭轻量镜面高光。

应用级的 `MiuixAccountHeader`、`MiuixDeviceCard`、`MiuixAppListTile`、
`MiuixNotificationCard`、`MiuixPermissionCard` 和 `MiuixUpdateCard` 现在统一
公开 `glass`、`glassBlur`、`glassOpacity`、`showGlassSpecular` 与
`cornerRadius`。普通入口读取同一内容玻璃和卡片圆角 token，状态色只用于图标、
按钮和进度等关键信息；每个组件的 `.source` 构造器保留旧版 16dp 不透明卡片。

设置页的多个普通选项应放在一个 `MiuixSettingsGroup` 中。普通入口只为完整分组
绘制一次 HyperOS 4 内容玻璃，子项不会重复套玻璃；模糊、染色、镜面、语义颜色、
描边和连续圆角均可覆盖，并继续响应应用五档玻璃强度。官网没有公开这组材质数值，
当前默认值来自项目画面校准和共享 `hyperOs4` token。

```dart
MiuixSettingsGroup(
  title: '账号服务',
  showDividers: true,
  children: const [
    MiuixPreference(title: '云备份', summary: '每天夜间同步'),
    MiuixPreference(title: '附近设备'),
  ],
);
```

需要保留原来的不透明低层级分组时使用 `MiuixSettingsGroup.source`。两种入口都不会
改变子项的点击、键盘焦点、手势和无障碍语义；圆角切角之外不会增加矩形填充或阴影。

普通 `MiuixPreference` 使用项目校准的 16sp/500 标题、13sp 摘要和 60dp
单行最小高度，起始图标按 22dp 光学尺寸统一；这些数值来自官方应用画面比例和
本项目运行截图校准，不是小米公开参数。需要 MIUIX 1.0.9 的 17/14sp、56dp
最小高度和 24dp 图标时使用 `MiuixPreference.source`。

`MiuixBasicComponent`、`MiuixArrowPreference`、`MiuixSwitchPreference`、
`MiuixCheckboxPreference`、`MiuixRadioButtonPreference` 以及来源模式的下拉和
Spinner 会把各自 `.source` 入口贯通到同一来源行，不会只改变外层控件而继续使用
普通排版。标题/摘要 `TextStyle`、颜色、文本缩放、点击语义和控件触觉优先级保持兼容。

原版只有在 `onTap` 或 `onLongPress` 至少一项不为空时才安装点击层。
单独设置 `showIndication` 或 `feedbackType` 不会让卡片变成空按钮，也不会产生
按压、悬停、键盘焦点或无障碍点击动作。无回调时，`holdDownState` 仍可配合
Sink/Tilt 显示由外部状态驱动的保持动画，但真实指针不会触发它。初始值为
`true` 时也会从普通状态经原版弹簧进入保持状态，不会在第一帧跳到终值。

需要在子对话框退出前保持卡片按下状态时，使用原版参数名构造函数：

```dart
MiuixCard.source(
  content: const Text('长按以显示对话框'),
  pressFeedbackType: MiuixPressFeedbackType.sink,
  showIndication: true,
  holdDownState: dialogVisible,
  onLongPress: showDialog,
);
```

`holdDownState` 应在对话框的 `onDismissFinished` 中恢复为 `false`，这样退出
动画期间不会提前回弹。Android 上长按接受后会自动调用原版对应的
`HapticFeedbackConstants.LONG_PRESS`，开发者不需要再重复触发震动。

## 文本框

```dart
final controller = TextEditingController();
final focusNode = FocusNode();
final scrollController = ScrollController();

MiuixTextField.source(
  controller: controller,
  label: '用户名',
  insideMargin: MiuixTextFieldDefaults.insideMargin,
  cornerRadius: MiuixTextFieldDefaults.legacyCornerRadius,
  colors: MiuixTextFieldDefaults.colors(context),
  keyboardOptions: TextInputAction.done,
  interactionSource: focusNode,
  scrollState: scrollController,
  inputTransformation: [
    LengthLimitingTextInputFormatter(32),
  ],
  onValueChange: (value) {},
  onKeyboardAction: (_) => focusNode.unfocus(),
);
```

普通 `MiuixTextField` 默认使用 20dp 的 HyperOS 4 项目校准圆角；
`MiuixTextField.source` 默认使用 16dp 旧版圆角和原版参数语义。`leadingIcon` 和
`trailingIcon` 是不附加尺寸、颜色或 12dp 间距的原版任意内容槽；
需要兼容旧版 Flutter 调用时仍可使用 `prefixIcon`、`suffixIcon`。
`MiuixTextFieldColors` 对应来源的背景、标签与焦点描边三通道；可通过
`MiuixTextFieldDefaults.colors(context, ...)` 只覆盖所需语义色。旧的
`backgroundColor`、`labelColor`、`borderColor` 参数继续保留，并在同时提供时按通道优先，
不会因修改一个通道而意外重置另外两个。
文字默认继承最近的 MIUIX Surface 内容色，调用者明确传入的
`textStyle.color` 优先。控制器、焦点节点和滚动控制器均由调用者释放。

文本框会响应 `MediaQuery.disableAnimations`。系统开启“减少动态效果”时，焦点
边框与浮动标签直接到达新的宽度、字号和位置；输入、选择、光标、格式化和焦点
语义保持不变。运行中的焦点或标签弹簧也会收敛到当前逻辑终点。

## Slider 与 RangeSlider

`MiuixSlider`、`MiuixVerticalSlider` 和 `MiuixRangeSlider` 使用同一套值域、
关键点吸附、方向映射和语义触觉策略。手指或鼠标拖动始终直接更新业务值，横向
Slider 会优先取得横向手势，不应触发外层页面切换。

`MiuixSliderPreference` 与 `MiuixRangeSliderPreference` 的普通构造现在接入
HyperOS 4 设置行层级，使用项目校准的 16sp 标题、13sp 摘要和 60dp 单行标题区
最小高度；放进普通 `MiuixSettingsGroup` 时与其他设置项共用同一个玻璃分组面。
需要直接移植 MIUIX 1.0.9 调用时使用 `.source`，它保留 17/14sp、56dp 来源层级
以及 `steps` 等来源参数。两条路径只切换外围行样式，不改变 Slider 的轨道、拇指、
关键点吸附、横向手势优先级、触觉反馈和完成回调。

三种 Slider 都响应 `MediaQuery.disableAnimations`。开启后，外部值更新直接落到
目标进度，悬停/拖动拇指缩放和轨道遮罩也直接切换终态；运行中的进度或反馈弹簧
会被停止，不能随后用旧速度覆盖新值。拖动、关键点吸附、完成回调和触觉反馈仍
保持可用。普通模式继续使用原版校准的进度、拇指与遮罩时序。

## 颜色选择器与调色板

完整颜色选择器支持原版的 HSV、OKHSV、OKLab 和 OKLCH 四种空间：

```dart
MiuixColorPicker.source(
  color: selectedColor,
  onColorChanged: (color) => setState(() => selectedColor = color),
  colorSpace: MiuixColorSpace.okLab,
  showPreview: false,
  hapticEffect: MiuixSliderHapticEffect.edge,
);
```

`hapticEffect` 与普通 MIUIX Slider 共用三档策略：`none` 不震动，
`edge` 仅在两端震动，`step` 还会在每个不同的中间拖动值产生刻度反馈。
四条颜色通道都继承同一个设置，并会优先取得横向拖动手势，不会触发外层页面切换。

原版调色板使用：

```dart
MiuixColorPalette.source(
  color: selectedColor,
  onColorChanged: (color) => setState(() => selectedColor = color),
  rows: 7,
  hueColumns: 12,
  includeGrayColumn: true,
  showPreview: true,
  cornerRadius: 16,
  indicatorRadius: 10,
);
```

调色板在回调后会立即显示刚选中的颜色，无需等待父组件下一帧回写。
独立通道控件也提供 `.source` 构造函数；其中 HSV Hue 的输入是
`0..360` 度而回调为 `0..1`，OKLab A/B 的原版范围是
`-0.3..0.3`，OKLCH 的 C/H 源参数分别是 `0..1` 的归一化值。
透明度背景可以单独使用 `MiuixCheckerboard`，默认是原版 3dp、
`#CCCCCC/#AAAAAA` 棋盘格。

## 纹理模糊、前景模糊与渐进模糊

当前来源的颜色和高光模型已经直接公开。`MiuixBlurColors` 除有序
`blendColors` 外还持有 `brightness`、`contrast` 与 `saturation`；可用
`MiuixBlurDefaults.blurColors` 创建。单个颜色层使用 `MiuixBlendColorEntry`，
省略模式时为 `srcOver`。标准 Skia 0..28 与 MIUIX 100..121、200..203 模式均有
明确枚举；运行时 shader 尚未直接覆盖的标准 Porter-Duff/HSL 分支会自动交给
Flutter 原生 `BlendMode`，不会错误退化成 SrcOver。

高光使用 `MiuixHighlight(width, alpha, style)`；内置 `MiuixBloomStroke` 支持两盏
`MiuixLightSource`、内侧 halo、合成模式和 `dualPeak`。双峰模式使用独立预编译
shader，一盏灯在相反方向形成两个镜面峰，适合液态玻璃扫光；普通模式保持来源的
单峰方向门控。旧 `color/blur/position` 参数仍会无损投影成 BloomStroke：

```dart
const MiuixHighlight(
  width: 1,
  style: MiuixBloomStroke(
    dualPeak: true,
    primaryLight: MiuixLightSource(
      position: MiuixLightPosition(dx: .25, dy: .45, z: -.4),
      intensity: .7,
    ),
    secondaryLight: MiuixLightSource(
      position: MiuixLightPosition(dx: .75, dy: .9, z: -.3),
      intensity: 0,
    ),
  ),
)
```

`MiuixBackdrop.blur` 与原版一样使用 dp/逻辑像素，不是物理像素；组件内部按
原版 `0.45` 系数转换为高斯 sigma。显式纹理模糊拥有自己的 `enabled` 状态，
不会被应用级 `enableGlass` 开关误关掉：

```dart
MiuixLayerBackdrop(
  radius: 24,
  padding: const EdgeInsets.all(16),
  backdrop: const MiuixBackdrop(
    blur: 100,
    noise: MiuixBlurDefaults.noiseCoefficient,
    colors: MiuixBlurColors(
      tint: Colors.transparent,
      opacity: 0,
      blendColors: [
        MiuixBlurBlendEntry(
          Color(0x803F3F3F),
          MiuixBlurBlendMode.overlay,
        ),
      ],
    ),
  ),
  child: const Text('纹理模糊'),
)
```

需要像原版 `BackdropEffectScope` 一样按顺序组合效果时，可使用不可变的
`MiuixBackdropEffectScope`。每个链式方法返回新配置；自定义滤镜只作用于完成
blur、颜色控制和 blend 后的背景平面，正文与图标保持清晰：

```dart
MiuixBackdropEffectScope(
  radius: 24,
  padding: const EdgeInsets.all(16),
  child: const Text('顺序效果链'),
)
    .textureBlurEffect(
      blurRadiusX: 32,
      blurRadiusY: 20,
      noiseCoefficient: MiuixBlurDefaults.noiseCoefficient,
      colors: const MiuixBlurColors(tint: Colors.transparent, opacity: 0),
    )
    .effect(ImageFilter.dilate(radiusX: 1, radiusY: 1))
```

`MiuixBackdrop.blurY` 为空时沿用 `blur`，因此旧调用仍是等向模糊。Flutter 不支持
像 Compose/Android 那样在运行时直接编译任意 AGSL 字符串；自定义 shader 必须先作为
Flutter fragment program 随包编译，再以 `ImageFilter.shader` 传给 `effect`。普通
`ImageFilter.blur`、`dilate`、`erode`、`matrix` 等可直接加入效果链。

同一入口也提供 `progressiveBlur` 与 `progressiveTextureBlurEffect`，返回可继续追加
`noiseDither`、`colorControls`、`blendColors` 和 `effect` 的
`MiuixProgressiveBackdropEffectScope`。渐进运行时 shader 和 13%/40%/100% fallback
都会分别换算 X/Y 半径；省略 `blurRadiusY` 时仍与原版一样沿用 X：

```dart
MiuixBackdropEffectScope(
  radius: 24,
  child: const Text('渐进效果链'),
)
    .progressiveTextureBlurEffect(
      blurRadiusX: 30,
      blurRadiusY: 12,
      gradient: MiuixProgressiveBlur.right,
      colors: const MiuixBlurColors(tint: Colors.transparent, opacity: 0),
    )
    .effect(ImageFilter.dilate(radiusX: 1, radiusY: 1))
```

渐进模糊使用原版的方向、起止比例和曲线参数。Android/Windows 支持运行时
图像滤镜时，会执行横向、纵向两遍逐像素可变半径高斯；不支持的渲染后端会
自动使用原版 13%/40%/100% 三档渐进回退：

```dart
MiuixProgressiveLayerBackdrop(
  gradient: MiuixProgressiveBlur.top.copyWith(
    startFraction: 0,
    endFraction: 1,
    curve: 1,
  ),
  backdrop: const MiuixBackdrop(
    blur: 20,
    colors: MiuixBlurColors(tint: Colors.transparent, opacity: 0),
  ),
  child: const Center(child: Text('渐进模糊')),
)
```

需要让文字本身显示后景模糊时使用 `MiuixForegroundBlurText`。它按原版
`DstIn` 语义把字形 alpha 当作遮罩；`fallbackGradient` 只在平台不支持
shader image filter 时生效，不会覆盖 Android/Windows 的真实后景采样。
标准混合、亮/暗 Logo Blend、非 Lab 算术模式和单独 Lab 模式会自动选择
轻量着色器；只有第三方把 Lab 与其他扩展模式任意混排时才使用完整兼容路径，
调用方无需按平台分支。

## 搜索栏

```dart
var query = '';
var expanded = false;

MiuixSearchBar.source(
  inputField: MiuixInputField(
    query: query,
    onQueryChange: (value) => setState(() => query = value),
    onSearch: (_) => setState(() => expanded = false),
    expanded: expanded,
    onExpandedChange: (value) => setState(() => expanded = value),
    label: '搜索',
  ),
  expanded: expanded,
  onExpandedChange: (value) => setState(() => expanded = value),
  outsideEndAction: Padding(
    padding: const EdgeInsetsDirectional.only(end: 12),
    child: GestureDetector(
      onTap: () => setState(() {
        query = '';
        expanded = false;
      }),
      child: const Text('取消'),
    ),
  ),
  content: const Column(
    children: [
      MiuixBasicComponent(title: '建议 0'),
      MiuixBasicComponent(title: '建议 1'),
    ],
  ),
);
```

原版 `SearchBar` 是容器，`InputField` 是独立的搜索输入框；因此源码式调用
使用 `MiuixSearchBar.source` 与 `MiuixInputField` 两层结构。搜索框的公开
默认值位于 `MiuixSearchBarDefaults`。普通 `MiuixTextField` 不具有搜索栏的
胶囊、焦点联动、Search 键和折叠后延迟清理行为，不能用来替代
`MiuixInputField`。旧的 `MiuixSearchBar(controller: ...)` 仍保留兼容。
兼容入口在普通空间中保持 HyperOS 4 项目校准的 48dp 胶囊；若来源顶栏明确只提供
45dp 有界高度，胶囊会服从该视觉槽位，同时继续暴露 48dp 无障碍语义目标。这样在
二级页面退出、上一级页面重新显现的第一帧不会产生 3px Flex 溢出或额外布局抖动。

搜索栏同样遵循系统“减少动态效果”：外部取消操作、结果区和清理按钮不再执行
展开、滑入或淡出；折叠时直接清理查询并释放焦点。普通模式继续保留原版 100ms
折叠等待、文字淡出和结果区弹簧。折叠过程中重新展开会取消旧动画并把文字恢复到
完全可见，避免搜索内容仍在却透明不可见。

## 工具提示

普通 `MiuixTooltip`、`MiuixTooltipBox` 和任意内容的 `MiuixRichTooltip`
默认使用单层 HyperOS 4 背景玻璃。模糊、透明度和 20dp 连续圆角来自
`MiuixThemeData.hyperOs4` 的 popup token，阴影与玻璃使用同一 G2 轮廓，
不会在圆角外留下矩形暗边：

```dart
MiuixTooltip(
  message: '编辑',
  child: MiuixIconButton(
    icon: const Icon(Icons.edit_outlined),
    onPressed: () {},
  ),
);
```

旧版像素对照必须显式使用 `MiuixTooltip.source` 或
`MiuixTooltipBox.source`；它们保留实体填充、12dp 圆角以及旧版分离的圆角
阴影。`MiuixRichTooltip.source`/`MiuixRichTooltipBox.source` 同样保留原版
字符串 API 和 16dp 实体表面。官网没有公布这些玻璃数值，当前 token 属于项目
画面校准值。

## 提示条

页面级提示条应由 `MiuixScaffold` 承载，使队列、进入/退出动画以及底部导航
避让都与原版一致：

```dart
final snackbarState = MiuixSnackbarHostState();

MiuixScaffold(
  body: const SizedBox.expand(),
  snackbarHost: MiuixSnackbarHost(state: snackbarState),
);

await snackbarState.showSnackbar(
  '文件已保存',
  actionLabel: '撤销',
  withDismissAction: true,
  duration: MiuixSnackbarDuration.long,
);
```

需要自行组合提示条表面时，可以把从 HostState 取得的
`MiuixSnackbarData` 交给公开组件。普通构造器默认使用 HyperOS 4 玻璃材质、
24dp 圆角，并允许覆盖外观参数：

```dart
MiuixSnackbar(
  data: data,
  cornerRadius: 12,
  colors: MiuixSnackbarDefaults.snackbarColors(context),
  insideMargin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  glass: true,
);
```

`MiuixSnackbarColors` 分别控制容器、消息、操作按钮和关闭按钮颜色。
若维护旧版像素对照，使用 `MiuixSnackbar.source(data: data)` 或显式传入
`glass: false`；`.source` 同时恢复 16dp 旧版圆角。
空字符串 `actionLabel` 不生成操作按钮；关闭按钮保留原版的 `Dismiss`
辅助功能说明和点击动作。`MiuixSnackbarHost.canSwipeToDismiss` 默认开启，与当前
原版 SnackbarHost 的双向锚点拖拽一致；设为 `false` 可以关闭。

Snackbar 同样响应 `MediaQuery.disableAnimations`。开启“减少动态效果”时，进入、
退出、堆叠收缩以及拖拽松手后的归位或关闭直接到达终态；手指仍按实际位移逐帧拖动，
计时关闭和 Android 辅助功能建议停留时间也保持有效。运行中的过渡在设置切换后会
立即收敛，不会留下透明但仍可命中的提示层。

## 面包屑路径

普通 `MiuixBreadcrumbBar` 使用一条低矮的 HyperOS 4 inline 玻璃面承载完整路径。
未选路径段保持透明，当前路径段使用语义强调色，避免每一级都成为互相竞争的独立
卡片。玻璃模糊、染色和连续圆角读取 `inlineSurfaceBlur`、
`inlineSurfaceTintOpacity` 与 `inlineSurfaceCornerRadius`，也可以逐项覆盖；
`glass: false` 保持同一空间几何但改用实色表面。

```dart
MiuixBreadcrumbBar(
  items: const [
    MiuixBreadcrumbItem(path: 'storage', text: '内部存储'),
    MiuixBreadcrumbItem(path: 'pictures', text: '图片'),
  ],
  highlightIndex: 1,
  onItemClick: openPath,
);
```

旧版像素对照使用 `MiuixBreadcrumbBar.source`。它保留每段独立填充，以及原来的
32dp 段高、10dp 横向内边距和 160dp 最大宽度；这些是旧 MIUIX 来源参数。
普通入口的 36dp 段高、12dp 横向内边距和 200dp 上限是项目画面校准值，不是
小米公开的 HyperOS 4 数值。

## 分组小标题

普通 `MiuixSmallTitle` 使用 HyperOS 4 内容优先层级：默认采用较紧凑的横向留白、
15sp/600 字重和 `onSurfaceSecondary` 语义色，使标题负责组织内容，而不是成为
比组内主标题更重的视觉焦点。`textColor`、`insideMargin` 和 `textStyle` 都可以
覆盖；其中 `textColor` 的优先级高于 `textStyle.color`。

需要维护旧版设置页像素时使用 `MiuixSmallTitle.source`。它保留 28×8dp 内边距、
14sp/700 字重、原来的物理像素行高取整和自然多行增长。普通入口的 20×10dp
内边距、15sp 字号与字重是项目画面校准值，不是小米公开参数。

## 对话框、底部弹层与减少动态效果

`MiuixDialog`、`MiuixOverlayDialog`、`MiuixWindowDialog`、
`MiuixBottomSheet`、`MiuixOverlayBottomSheet` 和
`MiuixWindowBottomSheet` 默认使用局部 HyperOS 4 玻璃表面，玻璃只裁剪在弹层
轮廓内。它们现在统一响应 `MediaQuery.disableAnimations`。

系统开启“减少动态效果”后，进入、退出和背景遮罩直接到达终态；运行中的宿主弹层
也会立即收敛。底部弹层仍保留手指拖动和预测返回的直接位移，松手后的回位、确认
关闭和预测返回取消不再播放自主弹簧。普通模式下原版 Dialog 与 BottomSheet 的
弹簧、缩放、位移以及独立遮罩时序保持不变。

下拉菜单和面包屑也遵循相同边界：系统开启“减少动态效果”时，级联菜单的第二层
直接展开或移除，运行中的展开弹簧立即收敛；禁用状态的触发器透明度直接切换；
面包屑高亮变化直接跳到自动居中位置。预测返回、手指拖动、滚轮和触摸滚动仍是
输入直接驱动，不会被禁用。普通模式继续使用原有级联形变与高亮居中弹簧。

当需要直接展示当前 MIUIX 的分组下拉内容，使用四个 source 命名适配器的
`show` 方法：`MiuixOverlayDropdownPopup`、`MiuixWindowDropdownPopup`、
`MiuixOverlayDropdownDialog` 和 `MiuixWindowDropdownDialog`。Popup 使用键点跟随的
source 行；Dialog 使用标题、全宽选择行和独立关闭按钮。单个非空分组默认
选择后关闭，多分组默认保持打开；可通过 `collapseOnSelection` 明确改写。

```dart
MiuixOverlayDropdownDialog.show<String>(
  context: context,
  title: '选择配置',
  dialogButtonString: '完成',
  groups: groups,
  onSelected: applyValue,
);
```

Overlay 变体属于最近或根 `MiuixPopupHost`，Window 变体属于根 Navigator 路由。
它们的入场、退场、遮罩和减少动态行为均复用已校准的宿主实现。不带
`show` 的构造器仍作为旧 Flutter 内联列表兼容入口，不应用来表示 source Dialog 路由。

## 主题内取值

```dart
final miuix = MiuixTheme.of(context);
final colors = MiuixSemanticColors.of(context);

Container(
  color: colors['surface'],
  padding: EdgeInsets.all(miuix.spacing.md),
  child: const Text('MIUIX 内容'),
);
```

## 图标

```dart
final settings = MiuixExtendedIconCatalog.find('Settings');
Icon(settings?.regular ?? Icons.settings_outlined);
```

扩展图标提供 Light、Normal、Regular、Medium、Demibold 五种字重。应用只需通过包入口导入，无需单独声明字体。
