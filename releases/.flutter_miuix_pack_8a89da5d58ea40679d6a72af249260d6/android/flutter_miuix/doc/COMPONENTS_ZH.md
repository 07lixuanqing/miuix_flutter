# 常用组件示例

## 顶栏与普通底部导航

```dart
MiuixScaffold(
  topBar: const MiuixTopAppBar(title: '主页', glass: true),
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

导航栏支持 `iconAndText`、`iconOnly`、`textOnly` 和 `iconWithSelectedLabel`。悬浮导航栏使用独立的 `MiuixFloatingNavigationBar`。

宽屏原版导航轨使用任意内容槽：

```dart
MiuixNavigationRail.source(
  mode: MiuixNavigationRailDisplayMode.iconAndText,
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
    ),
  ],
);
```

原版 `NavigationRailItem` 是受控的可视组件，不是普通导航数据对象；显示模式
由外层导航轨传递。尺寸、间距和按压透明度可以从
`MiuixNavigationRailDefaults` 获取。旧的
`MiuixNavigationRail(items: ...)` 仍作为 Flutter 兼容入口保留。

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
默认值可以从 `MiuixFloatingToolbarDefaults` 获取。`showDivider` 开启后会在
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
  colors: MiuixTabRowDefaults.tabRowColors(context),
  minWidth: MiuixTabRowDefaults.minWidth,
  maxWidth: MiuixTabRowDefaults.maxWidth,
  height: MiuixTabRowDefaults.height,
  cornerRadius: MiuixTabRowDefaults.cornerRadius,
  itemSpacing: MiuixTabRowDefaults.itemSpacing,
  interactionSource: interactionSource,
);
```

带轮廓版本使用 `MiuixTabRowWithContour`，默认采用原版的 45dp 外层高度、
5dp 内边距、8dp 标签圆角和 13dp 外层圆角。`selectedTabIndex` 是完全受控状态：
点击后组件只回调新索引，调用方更新索引后指示器才会移动。默认
`showIndication` 为 `false`，对应原版 `indication = null`；需要 MIUIX
按压指示层时可以显式开启。外部创建的 `MiuixInteractionSource` 需要由调用方释放。

## 卡片与开关

```dart
MiuixCard(
  insideMargin: const EdgeInsets.all(16),
  colors: MiuixCardDefaults.colors(
    context,
    color: MiuixSemanticColors.of(context)['primaryVariant'],
    contentColor: MiuixSemanticColors.of(context)['onPrimaryVariant'],
  ),
  cornerRadius: MiuixCardDefaults.cornerRadius,
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

## 文本框

```dart
final controller = TextEditingController();
final focusNode = FocusNode();
final scrollController = ScrollController();

MiuixTextField.source(
  controller: controller,
  label: '用户名',
  insideMargin: MiuixTextFieldDefaults.insideMargin,
  cornerRadius: MiuixTextFieldDefaults.cornerRadius,
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

`MiuixTextField.source` 使用原版参数语义。`leadingIcon` 和
`trailingIcon` 是不附加尺寸、颜色或 12dp 间距的原版任意内容槽；
需要兼容旧版 Flutter 调用时仍可使用 `prefixIcon`、`suffixIcon`。
文字默认继承最近的 MIUIX Surface 内容色，调用者明确传入的
`textStyle.color` 优先。控制器、焦点节点和滚动控制器均由调用者释放。

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
