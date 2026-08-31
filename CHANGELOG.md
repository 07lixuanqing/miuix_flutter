# Changelog

## 1.2.0

- 修复默认 HyperOS 液态底部 Tab 选中时模糊观感与尺寸发生变化：点击和切换期间不再
  放大整块玻璃采样面、缩小选中胶囊或放大选中内容，选中层透明度也保持稳定；保留
  胶囊跨 Tab 位移、颜色反馈和局部交互光。显式 `.source` 样式继续保留来源按压形变。
  回归锁定按下、拖动和释放前后仅有一个 BackdropFilter，且面板、胶囊、内容尺寸与
  选中层色调均不改变。
- 弱化顶部标题与页面内容之间过重的分界：普通与渐进模糊顶栏不再绘制用于浮动导航
  胶囊的完整矩形光学描边，保留原有模糊、色调、滚动揭示和内容下穿效果；底部 Tab、
  顶栏浮动操作组等独立玻璃控件仍保留边缘质感。新增普通/渐进顶栏无外轮廓回归。
- 修复真实 `Navigator` / `MiuixPageRoute` 子页面的 Android 预测返回：公共页面转场新增
  Navigator 级共享 drag、cancel、commit 状态，拖动阶段直接消费系统线性进度，不再把
  手势位置重复套入 500ms 弹簧；cancel 与 commit 均从释放姿态连续续走，并抵消 Flutter
  `reverse(from: upperBound)` 对 route controller 的重置。示例默认 MIUIX 路由复用同一
  分段算法，右边缘方向保持镜像，AOSP 卡片分支不变。回归锁定 40%/50% 手势等量位移、
  cancel 保持释放帧以及 commit 的控制器重置帧无回跳。
- 修复 `MiuixNavDisplay` 子页面返回时的逐帧重建卡顿：路由注册和页面内容树现在只在
  back stack 或父组件配置变化时刷新，弹簧、预测返回和指针返回的动画 tick 只更新
  位移、缩放、透明度与遮罩外壳。保留同 content key 的状态和父级主动刷新语义，并新增
  回归验证返回位移连续变化期间页面 builder 次数保持不变。预测返回 commit 现在于系统
  事件内直接把当前进度和释放速度交给 commit 弹簧，不再先冻结一帧、等待 post-frame 后
  才启动，也不会在下一帧重复创建第二个 settle；回归锁定第一个有效时间增量帧立即续走。
- 修复底部 Tab 选中后出现额外外轮廓：普通 `MiuixNavigationBar` 的可选选中胶囊移除
  0.75dp 描边，`MiuixFloatingNavigationBar` 的移动选中胶囊移除 0.65dp 高光边；两者继续
  保留选中底色、连续位移动效、按压缩放和图标/标签状态。新增切换前后无边框回归，并更新
  FloatingNavigationBar 六态 Golden，像素变化只落在原选中胶囊轮廓。
- 补齐 `miuix-core` 平台公共面：新增 `MiuixPlatform` 与实际 Flutter 主机解析，区分
  Android、iOS、macOS、桌面、JavaScript 和 WebAssembly；新增不可变平台对话框策略与
  明确的平台默认效果移除兼容钩子。Flutter MIUIX 弹层在同一 FlutterView 内自行绘制
  Back、宽度、inset、透明 scrim 和动画，因此兼容钩子是有文档的无操作，而不是重复创建
  Android Dialog window。系统底角继续复用插件的 API 31 RoundedCorner/资源 fallback。
  Shader 能力查询明确区分不可用的运行时 AGSL/SkSL 字符串编译、可用时的预编译
  FragmentProgram 和稳定 ImageFilter effect graph，不再把描述符冒充编译器。
- 补齐 `miuix-nav` 的公共预测返回协议：新增有限进度事件、可提升的
  `MiuixPredictiveBackHandler` 与多窗口组合标记，并让 NavDisplay、Dialog、BottomSheet、
  ListPopup 共用唯一所有者注册表。后挂载且实际可启动的表面独占一次系统手势；禁用或不可关闭
  的顶层表面会回落给下层，不再出现一次返回同时关闭多层。同步公开 Squircle 1.1 扩展默认值和
  主题能力查询，并把既有渐进模糊、倾斜、高光、颜色模型、下拉、导航栏、范围滑块、
  overscroll、下拉刷新与滚动条能力纳入真实来源映射，范围由 245 扩展至 267 项。
- 补齐当前 `miuix-nav` 的公共分层显示面：新增 `MiuixNavDisplay`、精确运行时类型
  `MiuixNavEntryBuilder`、连续相对深度、稳定 content key、Push/Pop/批量/替换分类、离场层
  保留、深层 State 保活、默认/Modal/None 与方向分派转场。指针返回支持四个物理方向、
  位置/速度阈值、运行中无跳变接管、commit/cancel 弹簧与减弱动效；Android 预测返回复用
  同一驱动。系统圆角读取下沉到库插件，示例嵌套导航改为直接使用公共显示组件。14 项真实
  来源映射把范围由 231 扩展到 245；设备视觉与帧节奏仍只接受任务自有 arm64 目标证据。
- 新增 `miuix-nav` 第一阶段公共核心：`MiuixNavKey`、可直接修改且可观察的
  `MiuixNavBackStack`、保根的 `MiuixNavController`、`MiuixNavDisplayEffects`、
  `MiuixNavRole`、SettleSpec 与 `MiuixNavMotion`。应用可显式编码/解码完整导航栈；
  弹簧非法组合在 Release 中也会抛错，不再只靠 assert。页面转场 Builder 与
  `MiuixPageRoute` 可共同消费 programmatic 配方，进入页、被覆盖页、遮罩和视差共享
  同一曲线。九项真实来源映射把当前范围由 222 扩展至 231；本阶段尚不声称已实现
  `NavEntry`、`NavDisplay`、连续手势深度或协调器。
- 补齐 BottomSheet 当前公开契约：新增 `MiuixBottomSheetDefaults`，并将背景色、
  窗口遮罩、顶角、640dp 最大宽度、外边距、内边距、IME inset 开关和拖拽条颜色
  贯通 `MiuixBottomSheet`、`MiuixOverlayBottomSheet`、`MiuixWindowBottomSheet` 与
  共享 Surface。自定义背景同时覆盖弹性 overscroll 底色；关闭遮罩仍保留可点击的透明
  模态平面；自定义拖拽条继续使用来源静止 20%/按下 35% alpha。`DialogDefaults` 与
  `BottomSheetDefaults` 两项真实映射把当前范围由 220 扩展至 222。
- 补齐按钮颜色数据模型与 Defaults 公开面：`MiuixButtonColors`、
  `MiuixTextButtonColors` 现具有 Kotlin `data class` 对等的值比较、哈希与逐通道
  `copyWith`；新增来源同名 `buttonColorsPrimary` / `textButtonColorsPrimary`
  工厂。按钮、图标按钮、FAB、分隔线、进度和小标题既有 Defaults/Colors 已按
  当前源码逐项纳入范围门禁；同批新增导航栏、浮动导航栏和顶部栏 Defaults，并让实际
  尺寸、按压透明度与无效输入 fallback 统一读取这些公共值，映射由 204 项扩展至 217 项；
  `NavigationItem` 也映射到已有的可禁用、可带 badge 的公共数据模型。映射只证明公开契约存在，
  组件行为仍由定向测试和完整回归单独验证。
- 修正顶栏滚动范围中的同名误映射：上游 `MiuixScrollBehavior` 现在映射到实际处理
  大标题折叠、fling 与 snap 的 `MiuixTopAppBarScrollBehavior`，不再指向通用页面
  overscroll 物理。新增可提升的 `MiuixTopAppBarState`，公开 height/content offset、
  collapsed/overlapped fraction，并与滚动控制器双向同步；当前映射总数由 217 增至 220。
- 补齐当前模糊与边缘高光公开模型：新增 `MiuixBlendColorEntry`、完整标准/扩展
  `MiuixBlurBlendMode`、`MiuixHighlightStyle`、`MiuixLightSource` 与
  `MiuixBloomStroke`；`MiuixBlurColors` 现直接持有亮度、对比度和饱和度，scope
  会按来源顺序传播。BloomStroke 支持单峰/双峰 shader、两盏独立光源及可配置
  合成模式，传感器倾斜会保留 style 和双峰设置；旧的扁平 Highlight 与
  `MiuixBlurBlendEntry` 名称继续兼容。六个来源 preset 的方向光不再错误继承 5% 平面
  描边 alpha，上缘镜面层恢复由独立光源 alpha 与 intensity 控制。
- 补齐当前来源公开的 `MiuixSurfaceDefaults`、`MiuixSurface.source` 与
  `MiuixTextFieldColors`：来源 Surface 明确使用矩形轮廓、零阴影和无玻璃默认值，普通入口仍保留
  HyperOS 4 连续圆角路由；TextField 的背景、标签、焦点描边三通道可作为
  不可变 palette 传递且仍允许逐通道兼容参数覆盖。范围映射同时把上游六态
  `ColorSchemeMode` 改为真实的 `MiuixColorMode`，不再用旧 `preset/custom/dynamic`
  元数据制造名称已覆盖的假象。
- 将 `MiuixBackdropEffectScope` 从 `MiuixLayerBackdrop` 的同名空别名补成
  可编排的不可变效果入口：支持各向异性 blur、noise、颜色控制、blend、
  标准/渐进纹理模糊 preset 及顺序自定义 `ImageFilter`；渐进运行时 shader 与
  13/40/100% fallback 均支持独立 X/Y 半径。自定义效果只处理背景平面，不会污染
  文字和图标，并在 shader 不可用的 blend fallback 中保持相同顺序。
- 补齐 `MiuixFloatingNavigationBarItem` 适配器遗漏的 `enabled` 与 `badge`
  参数，使公开来源类型能够表达禁用目的地与图标角标，并直接复用浮动导航栏
  已有的禁用交互、语义和角标边界实现。
- 补齐公开 `MiuixOverlayDropdownPopup` / `MiuixWindowDropdownPopup` 与
  `MiuixOverlayDropdownDialog` / `MiuixWindowDropdownDialog` 的当前来源宿主 API：
  支持独立分组、source 行、当前颜色、高度限制、单组/多组默认关闭策略、
  对话框标题与独立关闭按钮，并区分 Scaffold Overlay 和根 Navigator Window 生命周期；
  旧内联构造保留兼容，source 行的每次有效选择统一发布 Confirm 触觉。
- 新增公共 `MiuixNavigationPageTransitionsBuilder`、`MiuixPageRoute` 与
  `MiuixNavigationTransitionMotion`：返回时按已经退出的时间重新启动弹簧响应，
  修复二级页面先停顿、随后才返回的错觉；进出场、底页和遮罩进度保持同步并适配
  LTR/RTL，示例路由也改用同一库级方向感知计算；同时修复上一级页面恢复时，
  45dp 来源顶栏宿主中的兼容搜索框出现 3px Flex 溢出的问题。
- 将 `MiuixDateRangePicker` 的开始/结束端点从硬编码 16dp 不透明卡片迁移为
  HyperOS 4 局部日历玻璃，端点与月历共同读取圆角、模糊和透明度 token；
  `glass: false` 同时提供三个表面的实体回退，端点颜色过渡、范围选择和触觉不变。
- 修正结构化组件的 HyperOS 4 默认材质路由：普通 `MiuixFormSection`、
  `MiuixDataTable` 和 `MiuixProcessStepper` 现在无需手动传入 `glass: true` 即读取
  分组、内容卡片和 inline 玻璃 token；显式 `glass: false` 及 `.source` 继续保留
  实体表面，其中 ProcessStepper 只为当前展开步骤采样，避免重复玻璃卡片。
- 将 `MiuixSliderPreference` 与 `MiuixRangeSliderPreference` 的普通入口接入
  HyperOS 4 设置行层级，继承 16/13sp 和 60dp 标题区；`.source` 显式保留
  17/14sp 与 56dp 来源层级，轨道、拇指、横向手势、磁吸、触觉和完成回调不变。
- 将 `MiuixPreference` 普通入口迁移为 HyperOS 4 设置行层级：项目校准的
  16sp 标题、13sp 摘要、60dp 单行最小高度和 22dp 起始图标；`.source` 保留
  17/14sp、56dp 与 24dp 来源几何，并贯通 BasicComponent、箭头、开关、复选、
  单选、下拉/Spinner 及应用列表卡片的显式来源构造链。
- 将 `MiuixSettingsGroup` 普通入口迁移为单层 HyperOS 4 设置分组玻璃，完整
  分组共用一个裁剪面，模糊、染色、镜面、颜色、描边和圆角均可覆盖；新增
  `.source` 保留原来的不透明低层级容器，标题、分隔线、子项交互和语义不变。
- 将 `MiuixText` 与 `MiuixText.rich` 的普通入口迁移到 HyperOS 4 正文角色，
  默认读取主题 `bodyMedium`（当前项目校准为 16sp）；新增 `.source` 与
  `.sourceRich` 显式保留 MIUIX 1.0.9 的 17sp Main 角色，自动缩放、富文本链接、
  行数约束、布局回调和无障碍语义保持同一套实现。
- 将 `MiuixSmallTitle` 的普通入口迁移到 HyperOS 4 内容层级：默认使用项目校准的
  20×10dp 内边距、15sp/600 字重和次要正文语义色，并支持完整 `TextStyle`
  覆盖；新增 `.source` 保留旧 28×8dp、14sp/700 的来源像素路径。
- 将 `MiuixBreadcrumbBar` 普通入口迁移为单层 HyperOS 4 inline 玻璃路径面：
  普通路径段透明、当前段使用语义高亮，尺寸、模糊、染色和连续圆角读取共享
  token；新增 `.source` 原样保留旧 32dp 高、10dp 内边距、160dp 上限的独立胶囊。
- 将嵌入式 `MiuixCommandPalette` 迁移为 HyperOS 4 弹层玻璃，模糊、染色、
  镜面及圆角读取共享 popup token 并可逐项覆盖；`show` 由外层对话框独占玻璃，
  避免重复模糊，`.source` 与 `showSource` 保留原来的宿主自绘及不透明弹窗路径。
- 将 `MiuixListSection` 普通入口迁移为单层 HyperOS 4 分组玻璃，并支持材质、
  镜面及圆角覆盖；新增 `MiuixTreeView.source` 与
  `MiuixReorderableList.source`，分别保留旧 15dp 树选择行和 18dp 拖动代理，
  避免把每一行错误升级为独立玻璃卡片。
- 统一 `MiuixAccountHeader`、`MiuixDeviceCard`、`MiuixAppListTile`、
  `MiuixNotificationCard`、`MiuixPermissionCard` 与 `MiuixUpdateCard` 的
  HyperOS 4 内容玻璃 API，支持模糊、染色、镜面高光和圆角覆盖；对应 `.source`
  保留旧版 16dp 不透明卡片，并为基础 `MiuixCard` 补齐镜面开关。
- 将 `MiuixSliverTopAppBar` 的普通入口迁移到 HyperOS 4 大标题空间 token：展开、
  副标题展开、折叠和副标题折叠高度均可由主题校准，首屏内容位于大标题下方，
  上滑后进入渐进玻璃后方；`.source` 保留旧版 94/114/56/62dp 几何。
- 扩展 `MiuixAutoCompleteField` 的 HyperOS 4 锚定结果面：字段圆角与弹层材质
  跟随主题并支持逐项覆盖，默认宽度匹配字段且在窄屏内收、在桌面受上限约束；
  `.source` 同时恢复 16dp 字段与 18dp 不透明结果面。
- 将 `MiuixMultiSelect`、`MiuixSearchableSelect` 与 `MiuixComboBox` 的触发字段
  迁移为 HyperOS 4 内容玻璃，支持模糊、染色、镜面高光和圆角覆盖；多选值改为
  紧凑输入 Chip，避免嵌套玻璃重复模糊，`.source` 保留旧式不透明字段。
- 将 `MiuixFileDropZone` 普通入口迁移为 HyperOS 4 inline 柔光玻璃，并使背景、
  玻璃裁剪、1→2dp 拖入边框、连续圆角和交互反馈共享同一 Surface 轮廓；支持
  材质与圆角逐项覆盖、减少动态即时收敛，`.source` 保留旧版 22dp 不透明目标。
- 将 `MiuixNavigationDrawer` 和 AdaptiveScaffold 宽窗抽屉从贴边零圆角矩形
  迁移为局部悬浮玻璃：默认复用 NavigationRail 的模糊、染色、32dp 连续圆角及
  12dp 内容可见外间距，关闭玻璃后仍保持同一空间层级；`.source` 保留旧版
  300dp 贴边实体面板，`floatingDrawer` 提供显式宽窗布局控制。
- 将 `MiuixContextMenu` 从固定 220×48dp 的不透明旧面板迁移为 HyperOS 4
  内容自适应柔光玻璃：宽度、行高、内边距、图标间距、窗口边距和阴影均可由
  token 或调用参数覆盖，定位使用最终子项尺寸，超高内容在安全窗口内滚动；
  `.source`、`showSource` 与 `sourceStyle` 明确保留旧版几何和材质。
- 修正 `MiuixCarousel` 文档与实现不一致：内置页码点现在真正读取共享的
  `pageIndicatorDotSize`、`pageIndicatorActiveWidth`、`pageIndicatorSpacing`
  及新增的 `carouselIndicatorGap`，支持逐项覆盖，并由 `.source` 保留旧版
  6/18/3/10dp 几何。
- 将基础 `MiuixEmptyState` 与扩展 `MiuixEmptyStateView` 统一到 HyperOS 4
  最大阅读宽度、图标和间距 token；基础版新增 live-region、几何覆盖项及
  `.source` 旧布局入口，并补齐 Banner 关闭动作的 `toggleOff` 触觉反馈。
- 将 HyperOS 4 悬浮底部导航的图标加文字模式改为低矮横排结构，图标与标签
  完整收进接近整项宽度的选中底板；两到五项继续严格等分，长中英文仅在本项
  内缩放，并同步修正横排图标的徽标边界、RTL 与项目推导 token 文档。
- 新增自适应 Scaffold、NavigationDrawer、SplitView/ResizablePane，覆盖
  手机底栏、平板侧栏、桌面固定抽屉和可键盘调整的主从分栏。
- 新增 DateRangePicker、MonthPicker、YearPicker、WeekCalendar 和
  AgendaView，补齐范围、月年、周视图与分组日程场景。
- 新增 ReorderableList、TreeView、SearchableSelect/ComboBox、TagInput，
  并将 Chip 扩展为 assist/filter/choice/input/suggestion 五类。
- 新增 ProcessStepper、DataTable、SliverTopAppBar、FileDropZone 和
  CommandPalette；Windows 文件拖放使用原生目标，Android 可注入宿主选择器。
- ActionSheet、SegmentedControl、Banner、InlineAlert、LoadingDialog、
  Toast、ExpandableCard、StepperRow 与 EmptyStateView 补齐禁用/选中状态、
  键鼠、无障碍、震动和可选玻璃表面。
- 所有实现均位于库源码并从标准入口公开导出；示例拆为日历、集合和布局三组，
  文档增加扩展组件的选择边界、控制器所有权与跨平台接入说明。
- `MiuixIosLiquidGlassNavigationBar` 对齐当前原版示例的 64dp/24dp 几何、
  等宽目标、阻尼拖拽与越界回弹、按压形变、重力高光、24dp 液态折射、
  40dp 隐藏采样边界和 Android/iOS 底部 inset；导航标签不再继承异常装饰线。
- Tooltip 的外层投影恢复原版 `RoundedCornerShape` 路径，内部内容继续使用
  baked-SDF 超椭圆背景；两条轮廓不再被错误合并，普通与富提示的尺寸和定位不变。
- Snackbar 同步恢复原版“普通圆角投影 + 超椭圆内容填充”的双路径结构，
  避免开启超椭圆后投影四角被错误向内收缩；20dp 关闭图标保持原布局，
  Android 语义与触控区域则扩展到原版的 48dp。
- `MiuixTextButton` 补齐当前原版公开的 `textStyle` 参数，并恢复有限宽度下
  的自然多行排版；自定义样式颜色优先，未指定颜色时继续继承按钮状态色。
- 修正 Card 在没有点击或长按回调时错误制造空按钮的问题；仅设置按压反馈、
  指示层或外部保持状态不再产生指针、悬停、键盘焦点和无障碍点击动作，
  但外部 `holdDownState` 仍可按原版驱动 Sink/Tilt 保持动画；初始保持状态
  也从 1.0 经原版弹簧进入 0.94，不再在首帧直接跳到终值。
- 按当前官方 `FloatingActionButton.kt` 修正默认轮廓与阴影输入：默认
  `CircleShape` 现在始终映射为百分比圆角 `StadiumBorder`，不再被全局超椭圆
  开关替换为 G2 胶囊；负 `shadowElevation` 与零一样合法关闭阴影。
- 修正 `MiuixFloatingActionButton.child` 小于 60dp 最小表面时落在左上角的
  问题；任意内容现在与原版 `Box(contentAlignment = Center)` 一样始终居中，
  大于最小尺寸的内容仍可自然扩展按钮。
- 悬浮导航栏撤除原版不存在的选中胶囊、液态指示器和主题主色选中态，恢复
  `onSurfaceContainer` 及原版 `.5/.6` 按压透明度；图文、纯文字扩展模式继续
  按内容固有宽度测量后等分，不再由虚构的 48/56dp 单项下限把胶囊撑宽。
- 修正 `MiuixIconButton` 在未指定 `contentColor` 时强行覆盖父级图标/文字颜色、
  内容描述被拆成第二个语义节点及普通按钮暴露未选中状态的问题；同时修正
  `MiuixSurface` 仅设置 `holdDown` 就错误创建空交互层的问题。
- `MiuixFloatingToolbar.shadowElevation` 恢复原版仅以正值开启固定投影的规则；
  零值和负值现在都合法关闭投影，不再由 Flutter 额外断言拒绝。
- `MiuixBadgedBox.source` 恢复原版只放松徽标最小高度、保留父级最小宽度的
  测量规则；可展开侧栏与示例 FlowRow 则在组件外按原版先松约束测量，避免
  数字徽标被 28dp 图标槽错误拉宽，同时保留直接紧宽调用的原版行为；普通、
  悬浮底栏及经典、可展开侧栏也补齐 `badgeBounds()` 的顶部和逻辑末端夹取，
  RTL 时正确反向，且不再用裁剪误删原版允许的起点/底部溢出。
- 跟进当前官方 Scaffold 修复：Snackbar 现在优先避让实际测量后的悬浮按钮，
  并在工具栏位于底部三种位置时避让其变换后的真实顶部，再保留独立舍入的
  4dp 间距；顶部和中部工具栏不会错误地把底部提示条推高。
- `MiuixSmallTopAppBar` 补齐当前官方 `scrollBehavior` 参数；同一个滚动状态从
  大标题切到小标题时会钉住高度但保留内容偏移，切回大标题时按偏移符号恢复
  完全展开或完全折叠，不再显示错误的紧凑标题或篡改列表位置。
- 级联列表弹窗改用“组位置 + 项位置”保持展开状态、行锚点和箭头状态；调用方
  在弹窗打开期间重建不可变条目对象时，二级菜单会原位刷新标签、摘要、子项和
  选中态，不再继续渲染旧对象或意外关闭。若调用方直接删除已展开父项，位置
  状态会在当前构建中失效，而 Overlay 移除、动画归零和控制器通知统一延后到
  帧末执行，避免构建期重入并确保 Back 不再误消费已经不存在的二级深度。
- 跟进当前原版液态玻璃导航交互：完整 64dp 面板现在统一接管按下、点击和横拖，
  从任意未选中项按下都会先驱动液态指示器，松开后才提交目标；取消则回到已提交
  项。每项仍独立提供语义点击以及 Enter、数字键盘 Enter、空格键激活。

## 1.1.0

- 新增 18 组库级扩展控件：Calendar、DatePicker、TimePicker、
  DateTimePicker、DurationPicker、PIN/OTP、AutoComplete、MultiSelect、
  FormField/FormSection、SwipeAction、ContextMenu、Skeleton/Shimmer、
  EmptyStateView、ListSection、Rating、Dial、Timeline 和 Carousel。
- 所有扩展实现位于 `lib/src/extensions/` 并由标准包入口公开导出；示例程序
  只新增独立展示页，不再承载组件实现。
- 日期与时间选择器复用 MIUIX 平面 NumberPicker 的手势、回弹与震动；输入、
  选择、侧滑、菜单、评分、旋钮和轮播均提供应用可持有的公开控制器或值模型。
- 新增 Android 长按与 Windows 右键共用的定位式上下文菜单、RTL 等宽侧滑动作、
  无障碍增减动作、系统减少动画支持，以及五档玻璃体系可用的列表分组。
- 将原版 baked-SDF 静态超椭圆补到非裁剪背景路径，并接入悬浮导航、Snackbar、
  Tooltip、TextField、TabRow、颜色控件和 FloatingToolbar。
- 补充扩展控件中文接入文档、公共 API/Widget 回归和四类设计契约；结构校验继续
  强制源码注释比例不低于 50%。

## 1.0.9

- Port the current `miuix-squircle` baked-SDF static surface pipeline instead
  of approximating every fill and clip with a cubic path. Card, Button,
  IconButton, Dialog, and radius-based `MiuixSurface` now share the upstream
  512 x 512 alpha table, 1.1 extension, pi/4 capsule blend, physical-pixel
  antialias width, Android API 33 gate, and rounded-rectangle fallback. The
  localized example preloads the shader before frame one.

- Restore the current example's AOSP CrossActivity predictive-back fling
  bounce. Flutter now derives the same last-two-frame progress velocity used by
  upstream `NavDisplay.kt`, freezes it at commit, and applies the source
  stiffness-200/damping-0.75 closed-form scale overlay to both scenes.

- 将公开包名确定为 `flutter_miuix`，新增标准入口 `flutter_miuix.dart`。
- 保留旧的 `miuix_flutter.dart` 文件入口作为迁移兼容层。
- 增加 Android 自动注册插件，提供 MIUIX 震动角色的原生映射。
- 支持 Android 和 Windows 的字体、图标、着色器及玻璃效果打包。
- 修复颜色选择器、二维调色板、模糊控制和外层分页之间的手势冲突。
- 修正颜色输入框的单行 HEX 前缀、RGBA 数值格式与原版示例不一致的问题。
- 修复顶部级联菜单被错误固定为 288dp、二级菜单替换第一层的问题；恢复原版按内容测宽、第一层 95% 缩放遮罩、从触发行裁剪展开的独立二级层、标题行 12/20dp 到 20dp 的内边距变形、18% 黑色 24dp 模糊阴影、`0.99/0.45s` 与 `0.95/0.20s` Folme 弹簧，以及逐层 Back 行为。
- 汉化后的顶部多选菜单继续保留原版英文内容撑出的 546px 固有宽度，避免回落到 200dp/525px 下限并使左边缘右移；排序和多选在不自动关闭时均保留原版实时勾选行为。
- 修复“过度滚动与加载更多”在同一次惯性滚动中连续追加多页的问题；现在一次真实 fling 只追加 20 项，忽略布局后重建的 ballistic 滚动通知，第二次用户 fling 才会继续加载下一页。
- 修正“嵌套导航”汉化说明文本比原版短 2 个物理像素、12dp 底边距保留半像素导致后续卡片上移的问题；保留文字原始顶部对齐，在底部补齐 2px，并按 Compose 规则独立舍入底边距。
- 修正浮动工具栏错误跟随全局玻璃开关、三个动作错误弹出提示、显示与隐藏瞬间跳变的问题；示例恢复原版不透明主题主色、空操作，以及仅透明度变化的中低刚度 `fadeIn`/`fadeOut` 弹簧，淡出期间保持完整尺寸并支持从当前透明度与速度反向。组件投影改为当前原版固定的 10dp 模糊、10% 黑色、零偏移，填充不再错误裁剪任意子内容，并更新对应视觉基线。
- 修正浮动操作按钮点击后只显示“GitHub”提示条的问题；现在与原版 `LocalUriHandler` 一样打开项目的确切外部链接，且 About、License 和该按钮在平台没有处理程序时都不再插入原版不存在的失败提示。
- 修正 FPS 监视器错误使用 300/200ms `AnimatedSwitcher`、改变高度并只显示单个约一秒计数 `FPS` 的问题；现在完整复现原版全屏可拖动半透明药丸、初始 `--`、5 秒滚动帧耗时窗口、每 0.5 秒发布的 `AVG`/最慢 1% `LOW`、30 秒自适应参考帧率、超过 500ms 空闲间隔过滤、红黄绿健康色及默认颜色弹簧，同时保留中低刚度的纯透明度显隐弹簧。
- 将底部导航栏从单层 300ms `AnimatedSwitcher` 改为原版的双层 `AnimatedVisibility`：全局显示/隐藏使用底边锚定的淡入与高度弹簧；切换到悬浮栏时悬浮栏立即加入、普通栏从顶部淡出收缩；切回时悬浮栏立即移除、普通栏从顶部淡入展开。透明度改为对完成的图层做 RGBA 调制，避免 Impeller 将继承透明度错误传入玻璃模糊内容；实现已拆到独立文件，避免继续膨胀主入口。
- 修正图标页搜索弹层瞬间切换、最终位置上移 32px、汉化“取消”后搜索框过宽，以及取消语义错误合并到整页的问题；现在按原版以 300ms LinearOutSlowIn 从顶部栏搜索框移动到系统栏下方，以 200ms FastOutSlowIn 淡入背景，并保留英文 `Cancel` 的 52.5dp 固有槽宽与独立本地语义边界。
- 修正主页搜索栏被 12dp 页面边距再次收窄、展开后胶囊多占 48px、建议项整体右移 32px，以及中文“取消”使尾部动作槽缩短的问题；搜索行现在按原版占满视口，只在加权输入框内部保留 12dp 边距，并为汉化文本保留英文 `Cancel` 的 52.5dp 固有槽宽。
- 修复 Window Dialog 汉化摘要从原版两行错误缩成一行、导致紧凑面板整体下移 49px 的回归；中文摘要现在保留两行节奏，面板恢复原版物理像素边界 y=1841..2305。
- 补充当前原版 `SpinnerSection` 的完整同机审计：十行示例顺序、179/213px 偏好行、525×666px 富内容弹层、分组分隔线、紧凑对话框，以及分组选择保持展开和对话框选择立即关闭的行为均由 Release 运行证据与回归测试共同覆盖。
- 修复多条 Snackbar 动画重叠时旧项反而绘制在最新项上方的问题；队列改为按旧到新布局，使 Flutter 的 Flex 绘制顺序复现原版逐项递减 `zIndex`，旧项无裁切收缩时不会再闪过新项表面。并恢复原版 14sp body2 在 420dpi 下逐行 43px 的舍入，汉化后的两行“操作 + 关闭”表面由错误的 148px 修正为原版 150px。
- 修复主页单选按钮示例把原版四张独立卡片错误合并成一张大卡片的问题；恢复三个选项和禁用项各自的圆角表面、12dp 间距及禁用摘要。组件库同时补齐 `RadioButtonPreferenceColors`/`Defaults` 的四组文字调色板，使选中标题和摘要使用原版主题主色，并将单选、复选偏好开头控件的内部间距从错误的 8dp 恢复为原版 5dp。
- 修正数字选择器示例在 420dpi 下把原版 15px 冒号测成 14px、两个滚轮都分配为 469px 的问题；示例现在按 Compose 的整数 placeable 规则分配为 468px / 15px / 469px，消除分钟滚轮前的 1px 间隙。
- 修复进度指示器示例把整个区段置于每帧 `AnimatedBuilder` 中、导致 Android 无障碍子树约每 50ms 持续失效并使后续 TextField 无法稳定导出 UI 树的问题；现在仅重绘两个往返动画图形，并为其保留稳定的有界进度语义。当前同机复核同时确认四个 TextField 的 1016×136px 边界、32px 间距、浮动标签、输入保留和真实 IME Done 失焦行为均与原版一致。
- 修正线形进度示例在 420dpi 下把原版一次舍入的 15dp 左右边距拆成已舍入 12dp 与再次舍入 3dp、导致七条轨道从原版 `[39..1041]` 内缩成 `[40..1040]` 的问题；现在以 39px 总边距减去页面已放置的 32px，逐侧保留准确的 7px 余量。
- 修复 `VerticalSlider` 与父级纵向列表使用相同 Flutter 触摸阈值、导致真实 Android 手势滚动页面而不能拖动滑块的问题；新增与横向控件对称的方向优先识别器，明确纵向时滑块先接管、明确横向时主动让给页面。Release 实测普通垂直滑块从 30% 变为 78%，五个滑块矩形及页面滚动位置保持不变。
- 修正颜色页短中文角色名把原版两行英文标签压成一行的问题；逐项遍历原版 52 个语义色角色，并为其中 25 个原版两行角色保留对应的双行中文节奏，色卡高度、行距和颜色值保持不变。
- 将“关于”页隐藏表单更新为当前原版的效果版本、动态背景和全屏背景三项配置。
- 修正中文 BottomSheet 标题比原版行盒高 25px、导致表面整体上移的问题。
- 修复 Overlay/Window BottomSheet 仍使用旧的 150/180ms 三次曲线、Window 遮罩随整屏一起滑动且 Android 预测返回不跟手的问题；现在面板和固定遮罩共同使用原版 `0.9/0.38s` Folme 弹簧，允许关闭时按手势进度下移并淡出，禁止关闭时仅位移 10%、遮罩不变，取消以 150ms 回弹，提交按原版 `0.85/0.4s` 弹簧完成。补齐两个 host 的生命周期、取消、提交及动态 `allowDismiss` 回归，并完成同机 Release 对照。
- 修复 BottomSheet 普通拖拽错误由整个表面接管、首段 MOVE 被 Flutter 默认 18dp 识别器整段吞掉、禁止嵌套滚动时手柄也失效，以及回弹/关闭仍使用 150ms 三次曲线的问题；手柄现在独立使用原版 24dp 触区、45→55dp 与 1→1.15 按压形变，按 Android/Compose 8dp 起拖阈值转发首段余量，上拉和禁止关闭下拉均采用 0.1 阻尼，150dp/800dp/s 判定与 `.85/.4s` 弹簧完全分离。内容滚动只在起点转发未消费距离，反向滑动先复位弹层；越过自身高度后两个 host 立即完成回调，不再补播不可见的 680ms 退场。
- 修复 Overlay/Window ListPopup 与 CascadingListPopup 缺少原版预测返回的问题；普通弹窗现在按手势进度同时缩回生成角、裁切、淡出并降低遮罩，取消使用 `0.82/362.5` 原版弹簧复位。级联菜单在手势开始时冻结当前深度，第二层只反向驱动主层缩放、遮罩、箭头和二级裁切，第一次提交只收回第二层，第二次才关闭弹窗；Window 按键返回和二级选项关闭也统一遵守逐层规则，并修复取消后紧接下一次手势时旧异步回调清空新所有权，以及宿主卸载时合并监听器重新连接已释放进度的生命周期竞态。
- 将“关于”页身份标题的前景纹理模糊半径从旧的 200dp 修正为当前原版 `AboutPage.kt` 的 150dp，并补充精确组件回归与 Android Release 运行验证。
- 修正大标题栏仍把 `defaultWindowInsetsPadding=false` 误解为连顶部系统栏一起移除、列表内容使用固定展开内边距，以及滚动通知只回退实际收缩量的问题。现在顶部系统栏始终保留，Scaffold 内容内边距跟随标题实测高度变化，并复现原版预滚动的完整增量消费语义：只要一帧改变了 `heightOffset`，该帧全部交给标题，列表从下一帧才开始移动；向下滚动仍先回到列表起点再展开标题。补齐显式状态、PageStorage、程序跳转、动态内容内边距及同机 Release 回归。
- 隔离嵌套标签分页与主页滚动状态，避免首次滚动后错误恢复到最后一个标签。
- 补充 Android、Windows、主题和常用组件中文接入文档。
