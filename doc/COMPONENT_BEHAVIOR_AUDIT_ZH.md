# flutter_miuix 全组件行为审计

本文记录行为审计的当前证据、已经确认的缺陷以及仍需验证的范围。名称存在、组件能编译、
Golden 通过或 `verify_scope.ps1` 通过，都不能单独证明行为符合预期。

## 验收证据层级

每个可交互组件最终至少需要以下证据：

1. 默认、禁用、动态更新和异常边界的确定性 Widget 测试。
2. 触摸、鼠标、键盘、返回键、RTL、减少动态效果及无障碍语义中适用的行为测试。
3. 弹层组件额外验证根/嵌套宿主、遮罩范围、锚点、窗口变化和销毁期间的生命周期。
4. Android 真机与 Windows Release 运行证据；测试通过不能代替实际运行。
5. 视觉数值以 `HYPEROS4_OFFICIAL_APP_DESIGN_SPEC_ZH.md` 为默认基线；项目推导值不得
   描述为小米官方公开参数。

## 2026-08-28 首轮结果

静态盘点得到 438 个 `Miuix*` 公共类，其中 100 个类名没有在测试中被直接引用。
这些类中包含颜色、Defaults、图标目录和兼容子类，不能简单判定为未测试；但以下交互入口
需要继续增加直接覆盖：组合下拉偏好、兼容 Spinner 偏好、横向滚动条、独立 HSV/OKLab/
OKLCH 通道滑块、可调整分栏、Overlay/Window 下拉对话框及弹层定位提供器。

全量库测试在本轮修改前为 756/756。全量示例测试同时暴露 31 项失败：其中多数仍断言旧版
MIUIX/source 几何或旧 Golden，而示例默认视觉已经迁移到 HyperOS 4；另有部分检查已被
单一顶部溢出按钮隐藏的旧三按钮示例。它们需要重新建立 HyperOS 4 验收值，不能直接更新
期望值掩盖差异，也不能用这些旧断言证明库控件错误。

本轮已用失败用例复现并修复：

- `MiuixSplitView` / `MiuixResizablePane` 在窗口小于次面板最小宽度时不再形成反向
  `clamp` 范围；主面板安全收缩为零。
- `MiuixDatePicker`、`MiuixCalendar`、`MiuixMonthPicker` 和 `MiuixYearPicker` 统一
  规范化反向日期范围；外部值和动态收紧后的值会投影到最近合法端点。
- `MiuixColorPalette` 在小于一个逻辑像素的合法约束下仍能处理指针输入，不再抛出
  数值范围异常。
- 日期、时间、时长、日期时间、日期范围、多选和命令面板弹窗统一由根导航器完成确认与
  取消；嵌套页面不会再被误弹出并遗留根弹窗。
- `MiuixIconButton` 从禁用动态切换为启用时，先安装回调再公开启用语义，并对空回调
  保持防御；不再在语义树更新期间强制解包空值。

## 下一批高优先级

- 对全部 Overlay/Window 弹层族验证嵌套 Scaffold、嵌套 Navigator、物理返回键、窗口
  尺寸改变、锚点消失和异步关闭竞争。
- 对所有水平拖动控件验证其手势优先级高于页面横向切换，包括颜色通道、范围滑块、
  分段选择、Tab、时间轴、轮播和可调整分栏。
- 对 ScrollBar、下拉长列表、Calendar/Picker、ReorderableList、TreeView 和 DataTable
  验证触摸滚动、鼠标滚轮、拖动条、键盘与控制器动态替换。
- 对异步组件验证页面销毁后的回调安全，包括自动完成、命令面板、文件拖放、刷新、
  搜索选择器、Snackbar 和所有弹窗 Future。
- 将示例的旧 source 几何测试分离为显式 `.source` 兼容测试，并为 HyperOS 4 默认外观
  重新采集真机和 Windows 证据；不得直接把当前渲染图覆盖成“正确答案”。

## 2026-08-28 第二批结果

本批继续以失败行为用例为入口，修复了以下跨组件契约：

- Window 下拉弹层的 `canDismiss` 现在同时约束遮罩点击、按钮返回和预测返回启动；不再出现
  遮罩无法关闭、Android 返回键却能绕过约束的双重行为。
- 旧兼容 `MiuixIconCascadingDropdownMenu` 改为由 State 持有 `LayerLink` 和级联控制器。
  父级因主题、语言或无关状态重建时，已打开菜单不会失去锚点；控制器也会随组件销毁。
- 横向和纵向优先拖动识别器支持按指针落点决定是否参加手势竞技场。ScrollBar 透明触摸带
  只有滑块本体会接管拖动，滑块外的手势继续交给外层 PageView/List；滑块内拖动仍优先于
  外层同轴滚动。
- `MiuixContextMenuController.close` 统一关闭根导航器上的菜单，不再从嵌套 Navigator
  返回页面。控制器允许菜单结束前先销毁，ContextMenuRegion 销毁后也不会发布迟到选择。

新增回归覆盖禁止关闭的 Window 下拉、级联锚点重建、ScrollBar 滑块内外手势、嵌套路由
ContextMenu 关闭以及控制器/触发区域异步销毁。下一批仍需继续处理树异步加载代际、文件选择
异常恢复、数据表缩容后的键盘焦点，以及其余直接测试引用不足的交互组件。

## 2026-08-28 第三批结果

- TreeView 为每次懒加载分配代际令牌，并记录启动加载的节点定义。相同 value 的节点在请求
  完成前被替换时，旧结果、旧错误和旧展开动作都会被丢弃；新节点可以立即重新发起加载。
- FileDropZone 为浏览选择与原生拖放共享操作代际。controller、选择回调或 enabled 所属
  代际改变后，旧异步结果不会写入新 controller；原生拖放异常也通过 finally 恢复 busy，
  同一时刻只允许一个文件操作修改状态。
- DataTable 不再仅用可变行号保存键盘焦点。焦点由 `rowKey` 跟随排序后的同一数据项；聚焦
  行被数据缩容删除时，会迁移到原位置附近仍存在的行，并马上取得新的稳定键。

本批新增 TreeView 旧加载竞争、FileDrop controller 替换、DataTable 排序身份和数据缩容
四个行为测试。后续继续检查异步错误呈现、ReorderableList 跨输入设备、搜索/自动完成弹层
生命周期，以及仍无直接行为测试的兼容组件入口。

## 2026-08-28 第四批结果

- `MiuixReorderableList` 的标准拖动手柄现在同时支持触摸/鼠标拖动、键盘上下方向键和
  无障碍增减动作。键盘移动复用 Flutter 拖动排序的目标索引契约，并完整触发排序开始、
  数据变更、排序结束和分段触觉反馈；首尾边界不会越界，也不会产生伪回调。
- `MiuixAutoCompleteField` 将内部/外部文本控制器与焦点节点改为独立生命周期。只替换
  `focusNode` 不再清空内部输入文本，只替换 controller 也不会丢失内部焦点；调用方持有的
  对象仍不会被组件销毁。

本批新增排序手柄键盘移动、排序边界、生命周期回调，以及自动完成控制器/焦点节点分别热替换
的三个行为测试。后续仍需继续审计异步错误呈现、Search 兼容入口、横向拖动组件的手势竞争，
以及无直接行为覆盖的剩余交互组件；这一批通过不代表全组件审计已经结束。

## 2026-08-28 第五批结果

- `MiuixPinInput` 的文本控制器和焦点节点改为独立挂接/释放。只替换焦点节点时保留内部
  PIN 文本，只替换 controller 时保留内部焦点，且调用方对象始终由调用方释放。
- 兼容 `MiuixSearchBar` 的收起清理绑定到收起前实际显示的 controller。父级在同一帧
  换入新 controller 时，延迟回调不再误清新查询，也不会因为 controller 被移除而强制解包。
- `MiuixSearchableSelect` 为每次弹窗分配操作代际。弹窗打开期间若 controller、选项、
  单/多选约束、过滤器或 enabled 契约改变，旧弹窗返回值会被丢弃，不会污染新的状态所有者。
- 禁用 `MiuixRating` 和 `MiuixDial` 不再安装直接操作手势。它们不会阻塞父级 PageView，
  Dial 也不会在禁用拖动结束时错误发布 `onChangeEnd`；启用 Rating 仍优先消费自身拖动。

本批新增 PIN 两类独立热替换、SearchBar 收起与 controller 同帧替换、SearchableSelect 旧弹窗
结果、Rating 启用/禁用手势归属和 Dial 禁用回调六类回归。下一批继续检查可调整分栏、
Carousel、时间轴及剩余异步控制器的动态替换和边界行为。

## 2026-08-28 第六批结果

- `MiuixSplitView` 只为当前方向安装键盘调整键：横向使用左右键，纵向使用上下键。固定
  分隔线改为纯装饰语义，不再让 TalkBack 停在一个不能操作的禁用滑块；控制器、方向或
  resizable 契约变化时也会结束旧的直接拖动呈现。
- 内部 controller 的 `MiuixCarousel` 会在 `viewportFraction` 动态变化时重建 PageController，
  同时保留合法的当前页。children 缩容或清空会把逻辑页和实际 PageView 一起投影到最近合法页，
  并通过 ChangeNotifier 和 `onPageChanged` 发布一次非触摸状态变化，不产生用户翻页震动。
- Carousel 对零或负自动播放周期采取安全禁用，避免创建零周期 Timer；数据变化后的页面同步
  使用代际和 controller 身份检查，销毁或再次更新后不会执行迟到跳页。
- Timeline 补充了显式零 marker、connector 和横向条目宽度边界验证，当前实现保持有效布局，
  未发现异常或滚动手势劫持；这项通过只覆盖该边界，不代表 Timeline 所有行为已经验完。

本批新增固定/纵向 SplitView 语义与快捷键、Carousel 内部视口变化、缩容、清空、无效自动播放
周期，以及 Timeline 零几何共七类回归。下一批继续检查 ProcessStepper、Pagination、Stepper、
刷新/加载更多和剩余异步状态控件。

## 2026-08-28 第七批结果

- `MiuixProcessStepper` 对受控 `currentStep`、外部 controller 和步骤动态缩容统一执行合法
  投影。删除当前步骤后，controller 会在当前更新代际的下一帧归一化，并只发布一次纠正回调；
  旧帧回调不会覆盖随后换入的 controller 或步骤集合。
- ProcessStepper 只为当前布局方向安装快捷键：横向使用左右键，纵向使用上下键。位于首尾
  边界时不会重复选择、震动或发布伪回调；关闭步骤选择或不存在可用步骤时，不再申请键盘焦点，
  也不吞掉外层页面的方向键。
- `MiuixPullToRefresh` 增加刷新启动阶段锁。手势释放弹簧尚未完成时，父级同步将
  `isRefreshing` 提升为 true，不会再并发启动第二次刷新并取消第一条动画 Future；一次手势
  始终最多调用一次刷新回调。
- PullToRefresh 在受控模式下也接管异步刷新回调的错误报告。调用方可以继续用
  `isRefreshing` 决定视觉状态，但未等待的 Future 错误不会变成无人接管的异步异常。

本批新增 ProcessStepper 受控越界/缩容、方向快捷键/边界、禁用键盘交互，以及 PullToRefresh
受控状态在释放动画期间提升的四类回归。当前公共导出中未发现独立 Pagination 或 LoadMore
组件；后续需先明确是否应新增公共能力，再按 HyperOS 4 基线设计，不能把缺少 API 描述成
已有组件已经通过行为验收。下一批继续审计其余加载、分页、表单和弹层异步状态控件。

## 2026-08-28 第八批结果

- `MiuixMultiSelect` 为每次选择弹窗绑定打开时的 controller、选项集合、数量上限和操作代际。
  弹窗打开期间替换 controller、选项、上限或 enabled 契约后，旧确认结果不会写入新状态所有者，
  也不会通过新一代 `onChanged` 发布。弹窗内部使用打开时的选项快照，避免一次编辑过程混合两代
  选择域。
- `MiuixSwipeAction` 在动作数量或 `actionExtent` 动态变化时，根据当前逻辑 side 重新计算
  完整位移；删除某侧全部动作会安全回到关闭状态。运行期间禁用控件会关闭瞬态操作面板，且
  背后的动作 surface 同时移除点击回调，不再出现“不能滑动但仍能执行动作”的半禁用状态。
- `MiuixCommandPalette` 的高亮归一化改为绑定实际构建时的 controller，并在回调执行时重新
  读取当前过滤结果。命令缩容会投影到最近合法行，空结果统一归零；换入的新 controller 不会
  被旧帧使用旧列表长度纠正。

本批重新盘点 155 个公开 Stateful/Stateless 组件类，发现 19 个类名未被测试文件直接引用。
其中大部分是 HSV/OKHSV/OKLab/OKLCH 单通道 slider、弹层内容或图标薄封装，类名未直接出现
不能等同于底层手势完全无覆盖；后续仍要为每个公开通道补充直接的 LTR/RTL、禁用、非有限输入、
48dp 触摸区和外层 PageView 手势归属证据。当前结果只完成上述三类状态缺陷，不代表 19 项或
全部公共控件已经验收完毕。

## 2026-08-28 第九批结果

- 为 HSV、OKHSV、OKLab、OKLCH 的 16 个公开单通道滑块建立直接行为矩阵，覆盖 LTR/RTL
  物理端点映射、各自公开数值域、非有限主值与辅助值、48dp 最小触摸目标，以及嵌套在
  `PageView` 中时启用和禁用两种手势归属。启用通道接管横向拖动，禁用通道不再阻止外层翻页。
- `MiuixListPopupContent` 会在进入透明度、缩放和变换原点计算前归一化非有限输入。NaN 回落到
  收起端，正负无穷映射到相应端点；变换原点经过公共安全函数处理，避免无效矩阵进入渲染树，
  同时保留有限的弹簧过冲值。
- `MiuixSquircleClip` 会把公开传入的 NaN、无穷和负半径归一化为有限非负值。无效显式半径回落
  到安全主题半径，负值钳制为零，不再把无效圆角传播给裁剪器。
- 补充了命令面板 Ctrl/Meta+K 快捷键，以及组合下拉、图标下拉和下拉箭头薄封装的禁用契约。

第八批的“155 个公开组件类”是基于源码类名的保守扫描，并不等于 Dart barrel 的实际导出图；
例如 `MiuixExtensionChevron` 是库内辅助类而不是公开 API。本批直接类名缺口缩小后，继续把源码
类名扫描只作为发现线索，不再作为“公共组件已覆盖/未覆盖”的单独结论。当前仍需继续审计异步
弹层所有权、键盘焦点、动态列表缩容及真机视觉/触觉行为，本批通过不代表全部控件已验收。

## 2026-08-28 第十批结果

- `MiuixSegmentedControl` 的公开 `height` 和 `cornerRadius` 在进入布局、裁剪与边框绘制前统一
  归一化。NaN 和无穷回落到有限非负的 HyperOS 4 主题值，负数钳制为零，零仍可作为调用方
  明确要求的紧凑几何值。
- 新增无效几何回归，分别验证 NaN/无穷不会造成布局或绘制异常，以及负值不会生成负高度或
  负圆角。本批只处理分段控件的公开几何边界；其余复合控件仍需按同样方式逐项检查。

## 2026-08-28 第十一批结果

- `MiuixEmptyState` 现在会在创建 `BoxConstraints`、Padding 和 IconTheme 前归一化公开几何。
  NaN 与负无穷不再进入布局；显式正无穷仍保留“不限制最大宽度”的合法语义，负尺寸归零。
- `MiuixPageIndicator` 的点尺寸、选中宽度和间距改用同一有限非负边界。选中宽度始终不小于
  普通点尺寸，异常 index 继续投影到最近合法页，不再产生无限宽隐式动画。
- `MiuixAvatar` 对非有限直径回落到 48dp，负直径归零；缩写文字字号与归一化后的实际直径
  共用一个值，避免布局尺寸与文字尺寸分离。
- `MiuixSkeleton` 对宽高、圆角和负动画时长建立防御边界。显式 null 继续表示对应轴不约束，
  无效显式尺寸归零，负时长按零时长处理，主题圆角本身也会再次验证。
- `MiuixScrollBar` 的绘制宽度、最小滑块长度、物理边距、圆角和拖动触摸带统一由同一组安全
  几何派生。无效配置不再让视觉滑块、命中区域和拖动换算各自使用不同数值。

本批用失败回归实际复现了 EmptyState 的 NaN `BoxConstraints` 异常，并为上述五个公共组件
补充非有限/负数边界测试。下一批继续检查 TreeView 缩进、DataTable 尺寸、PullToRefresh 阈值、
时间日期间隔和其余公开几何；当前结果仍不是全组件行为完成证明。

## 2026-08-28 第十二批结果

- `MiuixTreeView` 的行缩进与圆角在构造 EdgeInsets 和 Surface 前归一化。非有限缩进回落到
  24dp，负缩进归零；无效主题圆角也不会继续传播到行绘制。
- `MiuixDataTable` 的表高、最小宽度、表头高、行高和列宽统一经过有限正数边界。内容宽度、
  键盘滚动偏移、ListView `itemExtent`、行容器和缩容高度全部使用同一组解析值，避免视觉行与
  键盘焦点滚动采用不同几何。
- `MiuixPullToRefresh` 会验证主题提供的指示器尺寸及完成/旋转时长。负旋转时长归零后不会再
  调用不允许零周期的 `AnimationController.repeat()`，而是保持确定的静态相位。
- `MiuixTimePicker`、`MiuixDurationPicker` 和 DateTimePicker 的时间阶段统一把分钟/秒间隔
  投影到 1…59。Duration 的负最大天数归零，避免 Release 模式下出现 `% 0`、非法步长或反向
  NumberPicker 范围；这些边界不再只依赖 Debug assert。

本批新增 TreeView、DataTable、PullToRefresh、TimePicker、DateTimePicker 和 DurationPicker
六类直接回归。下一批继续检查 Calendar 的首周规则与主题几何、NumberPicker 超大范围、进度
动画主题时长、导航集合动态增删以及剩余弹层窗口变化；当前仍未获得 Android 真机运行证据。

## 2026-08-28 第十三批结果

- `MiuixCalendar` 不再用只在 Debug 生效的构造断言限制 `firstWeekday`。任意整数都会按七天
  周期投影到周一至周日，星期标题和月首偏移共用同一归一化值，因此持久化设置越界时 Debug、
  Profile 和 Release 的排列保持一致。
- `MiuixNumberPicker` 不再把 `min...max` 的所有合法数字预生成到列表。范围现在由下界、上界、
  步长和数量四个整数表示，可见行按索引 O(1) 计算；十亿级跨度仍只构建当前中心附近的少量
  行，并保留范围反转、非法步长、最近值下侧平局和环绕行为。
- 线性、圆形和轨道式进度指示器会把负主题动画时长归零。零周期不再进入
  `AnimationController.repeat()`，而是停在可识别的静态加载相位；主题运行时从零时长切换回
  正时长时也会重新同步动画状态。
- `MiuixFloatingNavigationBar` 在拖动期间遇到项目缩容时会把连续位置和触觉索引投影到新域；
  项目清空会完整取消瞬态拖动。`MiuixIosLiquidGlassNavigationBar` 同样支持异步空列表帧，清除
  所有按压、弹簧和指针状态，项目恢复后从合法选中项重新建立等宽布局。

本批新增 Calendar 越界星期、NumberPicker 十亿级稀疏域、进度负数/零时长，以及两种悬浮导航
在指针按下期间清空并恢复项目共五类回归。静态分析和完整 819 项测试均通过；Android 真机
配对端口虽可建立 TCP，但 TLS 配对服务已关闭，故本批仍不能把模拟器或静态 APK 检查描述为
真机视觉、触觉与系统手势验证。下一批继续审计弹层窗口变化、焦点恢复及其余异步集合组件。

## 2026-08-28 第十四批结果

- `MiuixTooltip` 在显示期间会按应用实际产生的帧重新采样锚点。列表滚动、窗口尺寸变化或布局
  重排后，提示内容会继续指向控件的新位置；锚点从渲染树移除时会主动关闭，而不是停留在旧的
  屏幕坐标。采样不会自行请求新帧，因此静止页面没有常驻 ticker 或无意义重绘。
- 下拉菜单的 Overlay 与 Window 两条路径都获得实时锚点提供器。普通菜单、偏好设置菜单及带
  自定义偏移的菜单在滚动期间共用当前全局坐标，并由宿主转换到各自 Overlay 坐标系；窗口路径
  同时使用自适应 follower，避免系统尺寸变化后沿用打开瞬间的修正量。仅使用 `LayerLink` 的
  旧式图标级联菜单也统一补上原先遗漏的 8dp 下拉间距；DPR 3 golden 因此按预期下移 24px，
  与普通 Window/Overlay 下拉路径保持一致。
- 打开的 `MiuixDropdownMenuButton` 会在条目、分组、最小宽度、多选模式或内容构建器更新后刷新
  当前弹层。选择回调在执行时读取当前 widget 所有者，父级重建后不会把新条目交给旧回调。
- `MiuixListPopup` 与分组级联列表统一归一化公开 `minWidth`：非有限值回落到 200dp，有限值投影
  到 0…288dp。Release 模式不再依赖 assert 阻止负宽度或无穷约束进入布局。
- 新增窗口弹层关闭后的焦点回归，确认点击外部关闭后触发控件所在焦点域重新获得键盘焦点；同时
  覆盖 Overlay/Window 两种菜单在程序化滚动中的位置变化。

本批定向 5 项回归通过。这里的“实时”指跟随应用产生的布局/绘制帧，并非启动空闲轮询；当前仍需
继续审计其余异步弹层、组合框键盘导航、路由返回动画和 Android 真机触觉/系统栏协同。单元测试
不能替代真机上的像素、模糊材质和振动波形验收。

## 2026-08-28 第十五批结果

- `MiuixSearchableSelect` 与 `MiuixComboBox` 的搜索输入现在直接拥有键盘候选导航：打开后搜索框
  自动获得输入焦点，上下键逐项移动，Page Up/Down 跨五项移动，Enter/小键盘 Enter 选择，Esc
  关闭。禁用项会被跳过；过滤结果缩容后以稳定 value 保留当前高亮，原项消失时投影到首个可用项。
- 键盘高亮与已选状态共用连续行背景但保持不同强度，并补充 `selected`/`focused` 语义。长列表只在
  高亮项越出视口时滚动；减少动态效果时直接跳转，其余情况使用当前 HyperOS 4 选择面板时长。
- SearchableSelect 的非正 `maximumSelection` 不再只依赖 Debug assert；Release 中回落到一项，
  避免所有未选行无提示失效。窗口关闭后仍由 Navigator 恢复触发区域焦点，陈旧对话框结果屏障不变。
- `MiuixAutoCompleteField` 会在建立结果面板约束前归一化非有限、负数和反向的公开宽高。无效高度
  回落到 280dp，宽度回落到 220/420dp 且最大值不小于最小值，窄窗口仍由 RawAutocomplete 锚点
  约束，不再把 NaN、无穷或负宽度送入 `BoxConstraints`。
- `MiuixPinInput` 的非正长度回落到默认六位，空/多字符遮罩只取首个字素或回落圆点。文本控制器
  仅改变光标、选区或 composing region 时不再重复发布 `onChanged`/`onCompleted` 和确认触觉；
  真正文本变化且达到有效长度时才完成。
- `MiuixTagInput` 的非正标签数量与字符上限回落到一，空分隔符会被过滤，重复分隔符会去重，避免
  Release 模式出现恒拒绝或无效正则边界。

本批新增五项直接回归，并复核既有路由返回证据：反向导航把控制器倒计时转换为新的弹簧经过时间，
返回首个 16ms 帧已有可见位移，不会先停在二级页面再突然返回；RTL 同样按逻辑方向镜像。该结论
证明库级路由实现与测试场景，不等同于每个下游应用都已换用 `MiuixPageRoute`。下一批继续审计文件
输入、命令面板、可重排/树形集合及剩余异步错误状态。

## 2026-08-28 第十六批结果

- `MiuixFileDropZone` 的浏览与原生拖放结果现在绑定完整操作契约。控制器、选择器、接收/拒绝
  回调、类型限制、数量/字节限制、目录策略、追加模式、原生拖放开关或启用状态变化后，旧异步
  结果不会再套用新配置写入。禁用状态下内部选择按钮也同步呈禁用视觉，不再只是点击后静默返回。
- 文件数量、字节限制和最小高度不再依赖 Debug assert。非正数量回落到一，负字节上限归零，
  非有限或非正高度回落到 176dp；空扩展名、单独句点和空 MIME 模式不会意外匹配文件名。
- `MiuixCommandPalette` 会把初始、过滤后和动态目录中的高亮投影到可用命令。上下键跳过禁用项，
  Home/End 到达首尾可用项，Enter 与小键盘 Enter 共用调用屏障；同一帧的重复按键不会重复执行。
  长列表的键盘高亮会自动进入视口，减少动态效果时直接跳转，普通模式沿集合行时长滚动。
- 命令面板的非有限/非正最大高度统一回落到默认上限，禁用行不再绘制为选中端点；重复命令 id
  也通过行坐标区分动画身份，避免构建期间产生重复 key。
- `MiuixTreeView` 会记录已经完成加载的 loader 身份。相同节点 value 更换 loader、改为 eager
  children 或从树中移除时，旧缓存与旧错误会一并失效；更换控制器也会撤销尚未完成请求对新控制器
  的扩展写入。键盘上下移动跳过禁用节点，禁用节点的展开按钮不可用，键盘折叠与指针折叠共用
  expansion callback 和触觉路径。
- `MiuixDragHandle` 会拒绝负索引及超出所属列表的索引。运行时禁用会撤销焦点、键盘移动、语义
  可用态和拖动监听器，避免控件视觉禁用后仍保留抓取光标或焦点背景。

本批针对上述异步所有权、禁用状态、键盘导航、视口跟随和缓存替换补充直接回归。后续仍需继续
检查数据表编辑、分页/虚拟列表、上传进度错误恢复、日期范围跨时区以及其余复合控件的动态数据行为；
真机模糊、系统栏和触觉验收仍必须在有效 arm64 无线调试连接建立后执行。

## 2026-08-28 第十七批结果

- `MiuixDataTable` 在 `multiSelect=false` 时不再提供可操作的表头全选框，只保留与行选择框对齐的
  空白列；单选模式不能再通过表头一次写入全部 key。选择回调改为不可变时点快照，后续控制器变化
  不会篡改应用已经保存的旧回调参数。点击行复选框也会更新稳定焦点 key，键盘导航从该行继续。
- 数据表上下键改为仅在目标行离开视口时滚动，而不是每移动一行都把它强制顶到顶部。向下离开时
  对齐行底部，向上离开时对齐行顶部；减少动态效果或非正滚动时长直接跳到合法目标。双击与键盘
  激活统一走确认触觉，表头全选/清除统一走对应开关触觉。
- 日历范围状态新增显式 `rangeSelectionPending`。相同的一天现在可以区分“只选了起点、等待终点”
  与“已经确认的一天范围”；完成的一天范围在翻月后不会退回等待状态，下一次日期点击会开始新的
  范围。仅改变可见月份不再重复触发 DateRangePicker 的 `onChanged`。
- DateRangePicker 对话框的确定和取消共用一次性关闭屏障，同一帧重复触发不会连续 pop 到调用页面。
  `setRange` 会一次性同步范围和阶段，避免通过连续两次 select 推断相同日期的不可区分状态。
- `MiuixWeekCalendar` 不再依赖 Debug assert 限制首周日，任意整数按七天周期投影；周起点、逐日
  生成和跨周移动使用本地日历构造而非固定 24 小时 Duration，避免夏令时边界偏移。点击后可用
  左右键按文字方向逐日移动、上下键跨周移动，禁用日期不会被键盘选中。
- `MiuixCarousel` 会在创建 PageController 前归一化初始页和 viewportFraction，非有限、非正或
  大于一的比例回落到 0.88，非法高度回落到 220dp。初始页超出动态集合后在首帧同步到合法页；
  选中指示器宽度不小于圆点直径，非正主题动效不会进入隐式动画控制器。

本批新增数据表单选快照、按需滚动/零时长、一天范围阶段、周日历键盘与越界首周、范围对话框
重复关闭及轮播非法几何回归。项目当前没有独立的上传队列、分页器或虚拟列表公共组件，因此本批
没有把不存在的 API 描述为已修复；后续继续检查按钮、图标、文本、拨盘、评分、滑动操作和自适应
布局等仍含公开断言或缺少动态状态证据的组件。

## 2026-08-28 第十八批结果

- `MiuixButton` 和 `MiuixTextButton` 不再依赖仅在 Debug 生效的构造断言保护尺寸。非有限最小
  宽高与圆角回落到组件默认值，负值钳制为零；既没有 label 也没有 child 时生成可用的空内容，
  两者同时存在时任意 child 明确优先，配套 icon 不会泄漏进自定义内容。
- `MiuixIcon` 的字体、位图和自绘三条路径共用安全显式尺寸。NaN、无穷和负值回落到 24dp；
  自绘图标的非法固有宽高也会回落。兼容参数发生冲突时保持已有 Release 行为：`tint` 优先于
  `color`，`contentDescription` 优先于 `semanticLabel`，Debug 与 Release 不再表现不同。
- `MiuixText` 的显式字号、行高、最小/最大行数和自动字号策略全部在测量与真实 Text 构建前
  归一化。最小行数至少为一，最大行数不会小于最小行数；非法字号或行高回到主题排版，非法
  自动字号上下限和步长回到公开默认策略，避免除零、NaN TextStyle 或非法 maxLines。
- `MiuixDial` 会把倒置的有限范围排序、相同或非有限端点回落到 0…100、非正 divisions 解释为
  连续模式。布局尺寸和轨道宽度保持有限，轨道不会超过半径；手势、触觉分段、语义增减、动画
  数值和绘制共用同一组解析参数。无效直接 value 会回退到 controller，而不是传播 NaN。
- `MiuixRating` 对非正项数、非法项尺寸和负/非有限间距回落到公开默认值。命中宽度、RTL 换算、
  Row 排列、图标绘制、语义范围和回调钳制共用解析结果；无效直接 value 同样回退 controller，
  控制器构造时的非有限初值则归零。

本批新增五项非法运行时输入回归，专门覆盖构造断言在 Release 被移除后的真实路径。静态分析和
定向测试已通过；完整测试、注释比例、导出范围与本轮 Release 仍需在后续门禁中验证。滑动操作、
自适应布局、图标按钮以及剩余公开断言仍在后续审查范围内，本批不代表全组件验收完成。

## 2026-08-28 第十九批结果

- `MiuixIconButton` 不再把 icon/child 互斥和有限非负几何只交给 Debug assert。自定义 child 明确
  优先于 icon，两者均空时保留一个空内容槽；NaN/无穷最小宽高与圆角回落到 HyperOS 4 默认值，
  负值钳制为零。可见面、连续圆角和非布局扩张的 48dp 触摸区继续保持原契约。
- `MiuixSwipeAction` 的动作宽度现在先解析为同一个有限正值，再用于打开端点、拖动钳制、阈值
  触觉、动作 Pane 宽度及动态几何重定向。非有限或非正值回落到 76dp；无图标且无标签的动作
  仍可作为调用方自定义的空白可点击色块，不再因 Debug 构造断言与 Release 行为分叉。
- `MiuixAdaptiveLayoutDefaults` 新增公开断点归一化：两个不同的有限正数即使倒置也会排序；相等、
  非正或非有限组合回到 600/1200 项目默认值。NaN 与负无穷窗口宽度解析为 compact，正无穷解析
  为 expanded，静态分类函数和真实脚手架共用这一路径。
- `MiuixAdaptiveScaffold` 改为持有模式通知状态。`onResolvedModeChanged` 只在 bottom、rail、drawer
  实际改变时发布一次；普通父级重建和同一帧多次布局会合并，不再每一帧重复触发业务副作用。
  回调执行前重新读取当前 widget，销毁后的延迟帧不会继续通知。

本批新增图标按钮非法槽位/几何、滑动操作非法动作宽度、自适应断点边界和模式通知去重四组直接
回归。后续仍需继续检查 FAB、Breadcrumb、SliverTopAppBar、ProcessStepper、TabRow 及弹层模型中
剩余的公开断言和运行时动态状态，本批仍不代表全部控件已经完成行为与真机验收。

## 2026-08-28 第二十批结果

- `MiuixFloatingActionButton` 现在支持 label-only、完全空内容和 child/icon/label 冲突的确定性降级。
  任意 child 优先，label-only 不再强制解引用 icon；非有限最小宽高回到 60dp，有限负值归零，
  NaN/无穷阴影直接关闭投影。阴影、玻璃、裁剪、指示和点击继续共用一个 ShapeBorder。
- `MiuixBreadcrumbBar` 的 `itemMaxWidth` 在进入 `BoxConstraints` 前归一化。当前样式的非有限值回到
  200dp，source 样式回到 160dp，有限负值归零；高亮居中继续测量归一化后真实 Segment 宽度。
- `MiuixSliverTopAppBar` 的展开/收起标题高度、底部内容高度和展开顶距统一建立运行时边界。非法
  标题高度回到主题值，展开高度不小于收起高度，非法底部几何归零；`snap=true` 但未 floating
  时不再依赖 Debug assert，而是确定地不创建 snapConfiguration。
- `MiuixProcessStepperController` 的负初值立即归零，受控负 index 显示首项，过大 index 显示末项；
  动态缩容后的持久控制器校正机制保持不变。Debug 和 Release 不再因构造断言出现不同入口行为。

本批新增 FAB 内容/几何、Breadcrumb 非有限宽度、Sliver 非法高度与 snap 组合、ProcessStepper
负控制值四组直接回归。后续继续检查 TabRow、Surface、Tooltip/Feedback、Popup 模型和日期时间
值对象中仍存在的公开断言；本批也不替代 arm64 真机视觉、系统栏和触觉波形验收。

## 2026-08-28 第二十一批结果

- `MiuixTimeValue` 的时、分、秒改为构造时按各自周期归一化，越界正负值在 Debug 与 Release 中
  均得到同一合法 24 小时值，不再由仅 Debug 生效的断言决定行为。`copyWith` 与控制器因此也共用
  相同值对象边界。
- `MiuixDurationPicker` 在天、时、分、秒四列同时关闭时保留一个分钟列，避免动态设置产生没有
  任何内容的玻璃空壳。既有最大天数和分钟/秒步长归一化继续生效。
- `MiuixSurface` 的兼容圆角在普通填充、玻璃、静态 G2、交互 Shape 和阴影路径前统一解析：有限
  负值与非有限值均归零，不再把非法半径交给 `BorderRadius` 或玻璃裁剪器。
- `MiuixFloatingToolbar` 对动态圆角、项间距和阴影开关执行运行时归一化。非法圆角回到 HyperOS 4
  工具栏 token，负/非有限间距归零，非有限阴影关闭；Row/Column 的实际占位与绘制使用同一结果。
- `MiuixDialog` 的非正/非有限最大宽度回到公开默认宽度，负或非有限圆角回到 HyperOS 4 对话框
  token。Window 与 Overlay 适配器仍把参数交给同一个库级 Dialog，因此两条路径不会发生分叉。

本批新增五组直接回归，覆盖日期时间值、空列选择器以及 Surface、工具栏、Dialog 的非法动态输入。
后续仍需检查 TabRow、TopAppBar、Divider、颜色输入兼容参数、NavigationBar 回调模型以及 Popup
触发器/源模型中的剩余公开断言；当前无线调试端点跨虚拟路由不可达，本批不宣称 arm64 真机材质、
系统栏或触觉验收完成。

## 2026-08-28 第二十二批结果

- `MiuixTabBar` 的普通、source、contour 与 contourSource 四套入口不再依赖 Debug 构造断言。
  最小/最大宽度、总高度、圆角和项间距在物理像素舍入前按各自样式默认值归一化；最大宽度不会
  小于最小宽度，带表面内边距的样式不会形成负内容高度，指标、点击项与滚动测量共用同一结果。
- `MiuixTopAppBar` 对展开/收起高度、折叠比例、标题和动作边距、底部内容高度及展开间距建立完整
  的运行时边界。NaN、无穷与非法负值不会进入 PreferredSize、SafeArea 内布局或玻璃标题层；
  Scaffold 预留高度与实际构建高度继续一致。
- 横向和纵向 Divider 会把非有限缩进归零；纵向组件同时收到 `thickness` 与兼容 `width` 时明确由
  source 命名的 `thickness` 优先，并把两个公开字段同步为最终值，Debug 与 Release 不再分叉。
- `MiuixFloatingNavigationBar` 允许没有选择回调的受控只读预览。此时仍按当前 `selectedIndex`
  稳定绘制，点击不会解引用空回调或擅自改变选择；两种回调都存在时继续优先当前命名的
  `onDestinationSelected`。

本批新增四组直接回归，并复核现有 Tab、TopAppBar、NavigationBar 和 Divider 行为用例。剩余审查
继续聚焦颜色输入参数冲突、Popup host/trigger/source 模型、Preference 菜单和主题数据中仍存在的
公开断言或动态所有权边界；本批同样不替代 arm64 真机材质、系统栏与触觉验收。

## 2026-08-28 第二十三批结果

- `MiuixTextField` 的 source leading/trailing 槽位与旧 prefix/suffix 同时出现时，整套 source 槽位
  明确优先；不会在 Debug 拒绝而 Release 静默混用两套几何。非有限 prefix 间距回到 12dp。
- `MiuixCard` 同时收到 `insideMargin` 与兼容 `padding` 时由当前 source 命名优先，有限负圆角归零，
  普通、玻璃、按压和 callback-free hold 分支继续共用同一解析结果。
- `MiuixVisibilityTransition` 会把负时长归零、非法透明端点投影到 0…1、非法缩放归零，并逐轴清理
  非有限偏移。内容与 dim 动画控制器统一读取安全时长，动态 Popup 不再只靠 Debug assert 防护。
- Dropdown trigger 同时提供 child/builder 时 builder 优先；两者均空时保留不可展开的空锚点。
  Icon dropdown 和级联菜单允许异步数据暂时为空，触发器保持禁用而不是构造失败。
- `MiuixDropdownImpl` 与 `MiuixSpinnerItemImpl` 对负索引、负总数建立稳定首项降级；首尾内边距、
  点击回调和选择索引共用归一化结果，不再出现视觉首项却回调负索引的分叉。

本批新增三组组合回归，覆盖 TextField/Card 冲突、Hosted Popup 非法动画，以及空触发器和负索引行。
后续继续检查 Preference 工厂索引、主题数据、Popup 列表参数与剩余内部查找断言；真机边界不变。

## 2026-08-29 第二十四批结果

- `MiuixThemeController` 同时收到当前 `colorSchemeMode`/`keyColor` 与弃用的 `mode`/`seedColor`
  时改为确定性的当前命名优先；当前模式仍为默认 `system` 时，旧 `mode` 才作为迁移回退。行为不再
  依赖 Debug assert，Release 构建与测试构建保持一致。
- `MiuixTheme` 同时收到直接 `data` 与可变 `controller` 时，由承担实时状态的 controller 统一拥有
  子树主题；这覆盖应用迁移期的短暂重复配置，也避免 direct data 与控制器监听重建互相竞争。
- Overlay/Window 两种 `MiuixDropdownPreference.source` 与 `MiuixSpinnerPreference.source` 会把
  持久化的过期索引投影到当前选项范围：负值落到首项，过大值落到末项，空列表保持禁用空态。
  展示值、弹层选中态和回调索引因此共用同一合法初值。

本批新增主题别名冲突、主题所有权和四个 Preference 工厂越界索引的直接回归。后续仍需继续检查
内部图标/语义颜色查找、Popup 列表模型以及运行态视觉与触觉差异；当前结果不代表全组件真机验收。

## 2026-08-29 第二十五批结果

- `MiuixSemanticColors` 对未知角色不再只在 Debug assert、却在 Release 静默返回透明色。所有构建
  模式现在都会抛出带原始角色名的 `ArgumentError`，避免拼写错误伪装成控件内容或背景消失。
- 扩展控件的语义图标表和 `MiuixIcons.extended` 公共别名改用显式 `StateError` 保护生成目录完整性。
  如果图标源与别名发生版本错配，Release 不再偷偷替换为目录首个无关图标或退化为空指针异常。
- Dropdown trigger 会先清理非有限 `popupAnchorInsets`，并通过 Flutter 的比例收缩语义处理超过触发器
  尺寸的边距，避免生成反向 Rect。`popupAnchorOffset`、直接 Anchor Rect 及实时 provider 返回值也在
  Window/Overlay 两种路由和公共 PopupHost 入口统一清理，NaN/无穷不再进入像素舍入与布局代理。

本批新增未知语义角色及非法弹层锚点的直接回归，并确认库源码中已没有仅 Debug 生效的 assert。
后续继续检查日期/时间输入、滚动与手势竞争、无障碍和真机材质/触觉等运行态行为边界。

## 2026-08-29 第二十六批结果

- `MiuixCalendar` 的最小/最大日期现在同时约束日期单元和可见月份。首次挂载、替换 controller、外部
  `showMonth`、按钮点击及横向滑动都投影到同一合法月份范围；到达首月或末月后对应导航按钮禁用，
  不再允许进入整页均不可选的范围外月份。外部非法月份只向 `onChanged` 发布一次最终合法状态。
- `MiuixDateTimePicker` 会在创建日期/时间子 controller 之前校正外部初值，动态范围更新和后续外部
  写入也使用相同的日期范围。反向最小/最大值仍按项目范围控件规则交换，钳制日期时保留原时间。
- 日期子控件和时间子控件的合成写回现在保留毫秒、微秒。DatePicker 只修改年月日，TimePicker 只
  修改时分秒，不再把调用方未编辑的亚秒精度静默清零。
- 复核横向手势覆盖后，Calendar、Rating、颜色/普通/控制 Slider、Switch、SwipeAction、底部导航和
  Snackbar 均已有启用态占有父级 PageView、禁用态按契约让出手势的直接回归，本批未重复改写手势层。

本批新增 Calendar 范围导航和 DateTime 外部值/亚秒保留两组回归，日期时间测试 24/24 通过。
后续继续审计日期范围选择器的边界所有权、键盘/读屏操作及真机材质和触觉反馈。

## 2026-08-29 第二十七批结果

- `MiuixDateRangePicker` 的最小/最大日期现在不仅限制可点击日期，也约束内部初值、调用方 controller
  初值、后续外部写入、直接 calendarController 写入和动态边界更新。反向边界按日期范围控件既有
  契约排序，完全越界的范围收敛到最近端点，部分重叠范围只裁剪越界一端；挂载校正不伪造回调，
  运行期校正只向 `onChanged` 发布一次最终合法范围。
- `MiuixDateRangePickerController.setRange` 新增显式的选择阶段参数。动态边界把“已选择起点、等待
  终点”的日期钳制后仍保持等待状态，不会误变成已完成的一天范围；日历高亮、可见月份和控制器
  端点在同一通知周期同步。
- `MiuixCalendar` 新增真实硬件键盘路径。整个月历只占一个 Tab 焦点，左右键按文字方向逐日移动、
  上下键跨一周、Page Up/Down 按月移动，Enter/Space 才确认选择；焦点移动不再暗中改写选择值。
  键盘移动和翻月共用日期边界及 `selectableDayPredicate`，无合法日期的月份不会接受键盘焦点。
- 当前键盘日期通过子节点语义的 focused 状态暴露，读屏仍读取完整本地化日期；触摸选中会成为后续
  键盘锚点。RTL 左右移动、禁用日期停留、跨月焦点与确认分别有直接回归。

本批日期时间定向测试共 52 项全部通过。下一批继续检查 Month/Year Picker、复合输入、菜单与弹层的
键盘焦点恢复、读屏动作和动态数据缩容；arm64 真机的模糊、系统栏、触觉波形仍等待有效无线调试
连接后验证，不能由 Widget 测试替代。

## 2026-08-29 第二十八批结果

- `MiuixMonthPicker` 对后续外部 Controller 写入也执行与挂载、动态边界相同的月份钳制，嵌套校正
  通知被合并，`onChanged` 只收到一次最终合法月份。触摸月份会建立键盘锚点；三列网格支持左右
  逐月、上下跨三个月、Page Up/Down 跨年移动，Enter/Space 才提交选择，RTL 水平方向同步镜像。
- 月份键盘焦点与选中状态分离，方向移动不会提前改写业务值；局部年份没有可用月份时不接受焦点，
  所有移动继续服从最小/最大月份。年份导航按钮与键盘翻年使用同一边界并补齐轻量触觉反馈。
- `MiuixYearPicker` 从无状态显示器改为保持公共构造 API 的受控状态组件。初值、后续外部值、Controller
  替换和动态年份缩容都会投影到排序后的合法范围并保留月份；显示范围限制在项目统一的 1…9999，
  极端持久化整数不再生成无界 `itemCount`。
- 固定高度年份网格会在首次显示和外部选中变化后把目标年份平滑滚入视口，减少动态效果时直接定位；
  `shrinkWrap` 与固定视口互换后重新建立可见性。网格支持左右逐年、上下跨一行、Page Up/Down 跨
  四行以及 Enter/Space 确认，焦点和选中分别进入语义树，程序化写入不伪造用户选择回调。

本批新增 Month/Year 外部越界、键盘焦点、初始滚动、Controller 替换、动态范围和滚动所有权切换
回归，日期复合定向测试现为 28 项全部通过。下一批继续检查复合输入、搜索选择、标签输入与菜单
弹层在键盘焦点恢复、动态数据删除和读屏动作方面的行为；真机材料与触觉边界仍保持未验证状态。

## 2026-08-29 第二十九批结果

- `MiuixSearchableSelect` 与 `MiuixComboBox` 会把内部初值、外部 Controller 后续写入和动态选项变化
  投影到当前可用 value 集合。选项删除后不再出现界面显示“未选择”、Controller 却保存失效值的
  分叉；禁用但仍存在的选项可以保留已有选择，重复 value 只保留一个逻辑值。
- SearchableSelect 从多选切换到单选、或动态缩小 `maximumSelection` 时，按当前选项顺序确定性保留
  合法值；零和负上限统一按一项处理。挂载及程序化校正不伪造 `onChanged`，外部 Controller 监听者
  仍能观察最终修正，旧选项集合打开的异步对话框继续由 generation 屏障拒绝。
- `MiuixMultiSelect` 使用同一动态集合规则处理初值、外部写入、Controller 替换、选项删除和最大数
  缩容。非正最大数不再让所有未选行永久禁用；选中行在达到上限时仍可取消。
- MultiSelect 空选项会清除失效选择，并同时禁用指针和键盘触发；非空触发器新增 Enter、Space 和
  Alt+ArrowDown 打开方式，只占一个稳定 Tab 焦点。空态语义值改为真实 placeholder，不再发布
  空字符串或看似仍可展开的按钮状态。

本批新增 SearchableSelect 动态选项/选择形状，以及 MultiSelect 动态集合、空态与键盘触发回归。
下一批继续检查 MultiSelect 弹层内部的键盘行导航、checkbox 触觉一致性，以及 TagInput 在 IME
组合文本、粘贴多个分隔符和错误恢复方面的行为；真机运行边界仍保持未验证。

## 2026-08-29 第三十批结果

- 修复示例根页面误把窄屏 `MiuixTopAppBar` 强制设为紧凑模式的接入回归。手机布局重新使用组件库
  已有的大标题滚动行为：列表位于起点时显示左对齐 32sp 标题，上滑消费标题列后切换为居中 20sp
  标题，列表回到起点后再次恢复大标题；宽屏导航轨布局继续使用紧凑标题。
- 新增可见效果回归，不只检查 `collapseFraction` 数值：测试直接验证 32sp/20sp 标题、紧凑标题
  透明度以及“上滑收起、下滑回顶展开”的双向过程。既有玻璃/不透明顶栏高度、内容初始位于标题
  下方并可滚到标题后方的四项几何回归也继续通过。

本次问题的组件能力并未从 `lib/` 删除，故没有复制一套示例私有动画；修复的是示例对公共
`MiuixTopAppBarScrollBehavior` 的错误模式选择。组件库自身的大标题滚动、吸附和还原测试仍作为
底层行为门禁，示例新增测试负责防止集成层再次把该能力关闭。

## 2026-08-29 第三十一批结果

- 公共 `MiuixNavigationPageTransitionsBuilder` 按当前 `miuix-nav` 的 `MiuixDefault` 深度模型补齐
  被覆盖页面从 1 到 0.9 的独立透明度通道。返回时该通道与四分之一宽视差使用同一个反向深度，
  不再等到页面接近终点才突然恢复为完全不透明。
- 50% 调暗层从上一页的平移子树移到固定全窗口兄弟层。它现在只随深度改变透明度，不会跟随
  上一页向前缘移动，因此返回过程中不会在屏幕边缘露出一条未调暗区域，也不会造成上一页晚一拍
  恢复的错觉。示例的动态设置路由同步使用相同层级。
- `MiuixPageRoute` 默认关闭 Flutter 路由快照；示例 MIUIX 路由也采用相同设置。原版 NavDisplay
  在整个转场期间保持 entry 的实时图层，关闭快照可避免 Fragment Shader、BackdropFilter、Ticker
  等动态内容在退出时冻结为旧画面后突然切回实时页面。调用方仍可显式覆盖公共路由参数。
- 回归测试现在检查首个 16ms 返回帧，而非仅在 `pumpAndSettle` 后检查最终页面：子页面必须已经
  向尾缘移动，上一页必须从前缘四分之一宽位置同步返回，0.9…1 透明度与 0…0.5 调暗度必须同时
  处于中间值，并验证调暗层不是平移场景的后代。

本批以本地当前版 `miuix-nav` 的 `NavTransitions.MiuixDefault`、`NavDisplayEffects` 和固定 500ms
`NavProgrammaticEasing` 为依据；10% 页面衰减和 50% 调暗是两个独立通道。项目推导的窗口圆角值
仍不是小米公开设计 token，后续真机验收继续以运行帧和系统圆角通道为准。

## 2026-08-29 第三十二批结果

- 默认 HyperOS 4 悬浮底栏的移动选中区域收敛为单一材质层：静止、按下和拖拽全过程都只绘制
  一个带模糊采样的选中填充，不再在按下时额外叠加旧液态示例的高光轮廓、黑色内阴影和深度
  折射轮廓，消除真机上可见的“椭圆套椭圆”。
- 按压缩小、速度形变、跟手位移和松手吸附仍作用于同一个选中层；目标项内容继续位于材质之上，
  不复制第二套图标或文字。显式 `MiuixIosLiquidGlassNavigationBar.source` 仍保留 Compose 示例的
  旧光学层，供迁移和上游对照使用，不再污染项目默认视觉。
- 新增结构回归，分别在静止、按压和真实横向拖拽帧验证默认模式始终只有一个选中填充，并确认
  source 高光与内深度层不会在交互过程中被条件插入。

这些光学取舍属于根据 HyperOS 4 真机反馈形成的项目校准值，不表述为小米公开的官方参数。

## 2026-08-29 第三十三批结果

- 修复默认 HyperOS 4 底栏在选中目标后局部玻璃突然变浑浊的问题。此前整条底栏先执行一次背景
  模糊，选中区域又执行第二个四-dp `BackdropFilter`；即使已移除重复轮廓，选中槽仍会对已经模糊
  的结果再次采样，产生二次模糊和局部发灰。
- 默认模式现在由完整底栏唯一负责玻璃采样，移动选中区域只叠加一个随强度变化的半透明强调色。
  按下缩放、拖拽形变与松手吸附仍作用于这个单层区域，未选中与选中位置后方保持同一玻璃清晰度。
- 选中强调色不再被第五档的 0.22 表面透明系数继续压低到约 2.2%。默认模式使用项目校准的稳定
  对比洗色（亮色玻璃 8%、暗色玻璃 14%），强度档位继续控制整条底栏的模糊和背景可见度，不能
  把当前目标状态一并变得不可辨认。
- 显式 `source` 构造仍保留独立选中透镜，维持旧 Compose 液态示例的迁移对照。新增结构回归锁定
  默认模式只有一个 `BackdropFilter`，并在静止、按压和拖拽帧确认不会动态插入第二次玻璃采样。

## 2026-08-30 第三十四批结果

- 新增统一的 `MiuixGlassOptics.transient` 临时弹层光学角色。默认对话框、BottomSheet、Snackbar、
  Tooltip、列表/级联/下拉菜单、ContextMenu、Autocomplete 菜单和 CommandPalette 现在使用同一组
  五档模糊、染色以及明暗边缘进程，不再由各组件退回普通内容卡片的玻璃配方。
- 公共 `MiuixSurface` 新增 `glassOptics` 转发入口，第三方应用的自定义弹出菜单也可以复用同一材质，
  无需复制项目推导参数。现有 `glass: false` 继续作为显式兼容和性能降级选项；全局关闭玻璃时，
  所有弹层仍统一退化为自身裁剪形状内的实体表面。
- 旧内联 `MiuixDialogLayout` 与独立 `MiuixListPopupContent` 以前仍绘制实体背景，本批补齐真实背景
  采样；路由内部已经由 `MiuixListPopup` 拥有玻璃的路径继续设置 `paintSurface: false`，避免同一菜单
  叠加两个 BackdropFilter。
- 弹层玻璃严格裁剪在自身连续圆角/超椭圆路径内，阴影位于形状外部而不是矩形底板；页面路由、
  二级页面及窗口背景不被玻璃包装。光学倍率来自项目运行画面校准，不称为小米公开设计 token。

## 2026-08-30 第三十五批结果

- 示例验收明确拆分默认 HyperOS 4 与显式 `.source` 兼容路径。根导航、搜索栏、卡片、按钮、弹层、
  设置行及页面金图不再拿旧 Compose 几何否定新的默认设计；需要逐像素对照上游的独立用例继续显式
  使用 source 构造。由此修复 30 项陈旧失败，示例完整套件 111/111 通过。
- 同时修复两项真实接入问题：默认 56dp 液态底栏不再沿用 source 64dp 内容预留而产生 8dp 空带；
  反馈卡片示例补上真实点击动作，使 `showIndication` 不再因无交互语义而被组件正确抑制。
- `MiuixTagInput` 不再在 IME 组合范围尚未提交时解析逗号等分隔符；组合文本不变但 composing 状态
  收束的提交也会被识别。批量粘贴时合法片段继续提交，校验失败的完整片段与末尾草稿保留在编辑框，
  避免输入法候选和错误数据无声丢失。
- `MiuixMultiSelect` 弹层新增单一键盘焦点与可见高亮：上下键跳过禁用行及达到上限后不可新增的行，
  Enter/Space 切换当前行，长列表自动滚入视口。行点击与 Checkbox 现在使用同一切换和触觉路径；
  取消弹层后焦点恢复到触发器已有直接回归。
- 完整 Release 脚本在分配新 Android `versionCode`、覆盖稳定产物之前，强制执行库 `analyze lib test`、
  库完整测试、示例完整 analyze 与测试。静态或行为门禁失败不会再生成版本号更高的半成品。

本批输入组件定向回归 63/63 通过。视觉金图已经逐张检查当前输出；arm64 真机的系统模糊、触觉波形
及系统栏联动仍必须在任务明确拥有的设备恢复后验证，不能用 Widget 测试或 Release 构建替代。

## 2026-08-30 第三十六批结果

- Windows x64 Release 首次补充页面级运行检查，不再只以隐藏启动进程“有响应”作为视觉证据。窄窗
  首页、最大化首页、设置页和颜色模式下拉弹层均通过真实窗口截图检查；弹层的锚点、裁剪、暗层与
  临时玻璃层级正常。
- 最大化画面暴露出宽屏主体仍把手机/平板卡片拉伸到约 1430dp 的真实视觉缺陷。该行为与 HyperOS 4
  项目规范“宽窗口不能简单等比放大，应调整内容宽度”冲突，过去的 1200dp 导航轨断点测试没有覆盖
  断点之后内容继续增长的情况。
- `lib/` 新增公共 `MiuixAdaptiveContentFrame`。主内容在可用宽度不超过 1200dp 时完整占宽，超过后
  限制为项目校准的 1200dp 并居中，同时保持完整页面高度；调用方可覆盖最大宽度，非有限和非正值
  会回退到安全默认值。该数值不表述为小米公开参数。
- 示例宽屏嵌套 Navigator 已接入这一公共能力，导航轨继续贴近窗口逻辑起点，页面转场、顶栏和列表
  在居中的内容平面内运行。1600dp 公共组件、800dp 窄平面、非法参数及 1708x1019 最大化示例几何
  均新增直接回归。
- 最大化深色画面同时暴露出导航轨选中态的蓝底过重、蓝色图标和文字辨识度不足。默认选中底从旧的
  72% `primaryContainer` 改为项目校准的 8% `primary` 洗色；浅色前景保留主题强调色，深色前景改用
  `onPrimaryContainer`。明暗主题均新增实际合成背景的对比度回归，图标和文字至少达到 3:1；显式
  `.source` 继续保持上游兼容视觉。

重建后的 Windows x64 Release 已再次最大化检查首页和设置页：1200dp 内容面左右留白对称，导航轨
选中层级、标题、卡片和开关排列清晰，窄窗路径仍完整占宽。Android 系统模糊、系统栏与触觉仍须在
任务明确拥有的 arm64 设备上补验；本批其余完整分析、测试和发布结果以 Release 周期记录为准。

## 2026-08-30 第三十七批结果

- 修复 `MiuixFileDropZone` 在文件选择器等待期间仍接收原生拖入的问题。以前旧 `DropTarget` 回调
  可在 busy 后重新点亮边框，而完成事件又会被并发屏障丢弃，导致高亮停留；现在 busy 与 enabled
  共用唯一原生接收条件，旧回调也会再次验证当前操作所有权。
- 选择器和原生拖放失败新增公共 `onError` 回调，携带 `MiuixFileDropOperation`、原始错误与堆栈。
  当前错误在释放 busy 后交给宿主处理；控制器、配置或错误回调已经替换时，旧失败不会污染新宿主。
  未提供回调时继续通过 `FlutterError` 报告，不再产生无人接管的异步 rethrow。
- 实际验证了 `desktop_drop 0.8.2` 的升级边界：该版本在本机 Flutter 3.44.1 模板仍设置
  `android.builtInKotlin=false` 时，会在 AGP 9 配置阶段因缺少 `kotlin` 扩展直接失败。项目因此显式
  约束在 `>=0.7.1 <0.8.0`，避免依赖解析静默进入不可构建状态；待 Flutter 工具链正式启用 Built-in
  Kotlin 后再解除上限。这里以实际 Android 构建为准，不以包变更说明代替兼容验证。

本批文件拖放 8 项行为回归与 4 张明暗/source 材质金图通过。Android arm64 与 Windows x64 的
最终构建、完整测试及发布结果仍由本轮 Release 周期统一记录。

## 2026-08-30 第三十八批结果

- 修复普通与分组下拉偏好在菜单已经打开后无法跟随父组件重建的问题。弹层路由原本位于偏好组件
  Element 子树之外，条目、分组、选中值、颜色和高度约束会停留在打开瞬间；现在由宿主 State 在父帧
  完成后发布修订，弹层只重建内容平面，不关闭菜单，也不重播入场动画。
- 行选择不再持有打开瞬间的 `onChanged` / `onSelected`。真正提交前会用当前条目或当前分组重新校验
  值仍存在、条目仍启用且所属分组仍启用，然后调用当前回调；同一帧被删除或禁用的旧行不会写入新
  owner。确认式对话框虽然不原地替换已经显示的条目，但提交路径同样经过这道当前状态校验。
- 兼容下拉、source Dropdown、source Spinner 与分组 source 行共用这套宿主所有权；Overlay 和 Window
  继续由原路由负责锚点、关闭策略和焦点恢复。新增普通、分组两项打开中重建回归，明确验证旧文本
  消失、新文本出现，并且新选项只进入新回调。

本批 dropdown 定向回归 26/26 通过，`analyze lib test` 无静态问题。完整套件、范围门禁、Android
arm64 与 Windows x64 构建仍由本轮 Release 周期统一记录。

## 2026-08-30 第三十九批结果

- 修复 `MiuixContextMenuRegion` 在菜单打开后替换 actions/controller/启用态时，旧菜单返回值会写入
  新回调 owner 的问题。上下文菜单继续采用一次打开一次快照的短暂交互语义，但返回结果必须匹配
  当前打开代次，且当前 actions 中仍存在同值启用项，否则只完成旧路由关闭而不发布选择。
- 修复 `MiuixIconCascadingDropdownMenu.items` 旧兼容路径的同类问题。旧二级菜单选择现在先用打开时
  的 presentation 与 popup host 关闭真实旧路由，再以当前 items 重新验证启用子项并调用当前回调；
  被替换的旧子项不会写入新 owner，也不会因被拒绝而把无响应菜单滞留在界面。
- 普通无关父重建仍不会中断旧二级菜单，稳定 `LayerLink` 与原锚点回归继续通过；只有 actions、控制器、
  启用态或路由归属变化才使旧结果失效。新增上下文区域和旧二级菜单两项 rebuild-race 回归。

这两类菜单均保持既有玻璃材质、几何、入退场动画与焦点路径，本批只收紧异步结果所有权，不引入
视觉跳变。完整套件、范围门禁和新的 Release 周期结果以本轮发布记录为准。

## 2026-08-30 第四十批结果

- 普通确认式 Spinner、source Spinner 和分组确认对话框不再永久显示打开瞬间的旧条目。宿主偏好
  已有的修订信号现在同时驱动对话框内容平面，条目、分组、选中态、颜色和按钮文案会在原路由内
  更新；`miuix-dialog-surface` Element 保持同一实例，因此不会关闭、重新打开或重播入场动画。
- 普通确认式 Spinner 的未提交草稿在刷新后仍存在且启用时继续保留；草稿被删除或禁用时，先回退
  到当前受控值，再回退到首个启用项。没有有效项时确认按钮不可用，旧值不会通过新 owner 提交。
  source Spinner 和分组对话框仍保持各自原有的立即提交/关闭策略，但提交前继续通过当前宿主校验。
- presentation、根/局部弹层宿主、路由边距和 surface builder 属于本次打开的稳定路由决策，动态内容
  刷新不会在 Overlay 与 Window 之间迁移；这些配置变化从下一次打开生效，避免对话框可见期间跳层。
- 重新核查直接引用清单中的 `MiuixExtensionChevron`：它由 `src` 内多个扩展控件导入，但没有从
  `miuix_extensions.dart` 或包根 barrel 导出，因此不是缺失测试的公共组件。它只做即时物理方向字形
  映射，没有自主动画；实际消费者的数据表、树、MultiSelect 和 SearchableSelect 已有行为和视觉回归。

新增普通草稿保留、失效草稿回退、source items 刷新、分组刷新和路由实例稳定性回归。完整分析、
测试、范围门禁以及 Android arm64/Windows x64 Release 结果由本轮发布周期统一记录。

## 2026-08-30 第四十一批结果

- Windows x64 实际窗口在窄窗到最大化的状态迁移中暴露出搜索栏前景被裁剪的真实响应式缺陷：
  1200dp 宽度上限内的列表子项仍使用整个 1708dp 窗口的 `MediaQuery` 宽度，居中后将搜索图标、
  占位文字和取消动作推出了局部内容平面；背景仍覆盖裁剪区，因而旧的结构检查没有发现。
- 示例搜索栏现通过子项自身的 `LayoutBuilder` 恢复列表局部视口宽度，只溢出它本应抵消的
  12dp 页面内边距，不再依赖全局窗口尺寸。窄窗下的上游搜索几何保持不变，宽屏则与居中内容面
  共享同一宽度所有者。
- 最大化回归从 390x844 紧凑壳启动，保持同一首页路由后迁移到 1708x1019，直接校验导航轨、
  1200dp 内容面以及搜索占位文字的实际矩形；占位文字必须保持在内容面左右边界之内。

这项修复来自 Windows Release 实际截图而非静态 API 对照。完整示例测试、重建后的最大化截图复验与
新 Release 周期结果以本轮发布记录为准。

## 2026-08-30 第四十二批结果

- 完成度重审发现 `MiuixOverlayDropdownPopup`、`MiuixWindowDropdownPopup`、
  `MiuixOverlayDropdownDialog` 和 `MiuixWindowDropdownDialog` 虽在 195 项映射中有同名类，
  但只是接受 `entries/onSelected` 的内联 `ListPopup` 空壳；Dialog 名称也没有对应真实对话框
  宿主、标题和关闭按钮。这是名称覆盖不能代替行为实现的直接反例。
- 四个适配器新增 source 对应的 `show` API。Popup 支持单项/分组数据、当前颜色、最大高度、
  逻辑末端对齐、Overlay 根宿主选择和完整关闭生命周期；Dialog 使用来源对话框颜色、
  56dp 全宽行、24dp 纵向内边距、50dp 关闭按钮，并真正分流到 OverlayDialog 或 WindowDialog。
- 关闭策略跟随当前来源：一个可见分组默认选择后关闭，多组默认保持打开，
  调用方可显式覆盖。source 行每次接受有效点击都发布 Confirm 触觉，即使是重新点击已选值；
  旧普通 `MiuixListPopup` 仍保留只在选择状态跨越时发布 segment tick 的兼容行为。
- 新增四个宿主直接回归：Overlay Popup 多组持久、Window Popup 单组自动关闭、
  Window Dialog 手动关闭和 Overlay Dialog 多组持久；另一项触觉回归锁定已选 source 行的 Confirm 角色。

定向 dropdown 28 项、dialog 17 项、公共 wrapper 8 项及静态分析已通过。完整套件、范围门禁、
Android arm64 和 Windows x64 产物将由本轮 Release 周期统一验证。

## 2026-08-30 第四十三批结果

- 继续按“直接公共引用”重审来源适配层，发现 `MiuixFloatingNavigationBarItem` 虽然继承了
  `MiuixNavigationItem`，构造器却没有转发上游 `FloatingNavigationBarItem` 明确公开的
  `enabled` 与 `badge`。调用方一旦选用该来源类型，就无法声明禁用目的地或图标角标。
- 适配器现完整转发 `icon`、`selectedIcon`、`label`、`layoutLabel`、`enabled` 与 `badge`；
  不另造渲染路径，而是复用浮动导航栏已经验证的禁用点击/语义、按压状态清理和角标边界实现。
  新增直接公共 API 回归，避免共享模型以后扩展时适配构造器再次静默丢参。
- 同轮核查确认 `DrawScope`、`RowScope` 是 Compose 框架接收器而非独立 MIUIX 控件；
  `TooltipScope` 的锚点、方向和 caret 职责已由 Flutter tooltip 内部持有，不能仅凭这些迁移标记
  没有独立示例就判为界面缺失。`MiuixBackdropEffectScope` 与上游可编排效果链仍有 API 形态差异，
  其底层 blur、渐进 blur、noise、颜色控制和 blend 已有实现，但任意 shader/effect 链需另批设计，
  本批不把名称映射误报为完整等价。

公共 wrapper 9 项回归通过。完整分析、测试、范围门禁以及新的 Android arm64/Windows x64
Release 结果由本轮发布周期统一记录；Android 真机运行边界保持单独报告。

## 2026-08-30 第四十四批结果

- `MiuixBackdropEffectScope` 不再只是继承 `MiuixLayerBackdrop` 的同名空壳。它保留原构造
  兼容，同时新增不可变链式 `blur`、`noiseDither`、`colorControls`、`blendColors`、
  `effect` 和 `textureBlurEffect`；标准 preset 对半径执行来源 0..150dp 边界，非正 noise
  与来源一样不覆盖已存在的效果状态。
- `MiuixBackdrop` 新增可选 `blurY` 和顺序 `effects`。省略 `blurY` 时保持旧等向行为；
  各向异性半径继续使用来源 0.45 sigma 换算。自定义 `ImageFilter` 按加入顺序消费完成的
  texture recipe，并支持预编译 FragmentShader 滤镜，弥补过去无法表达任意后处理链的问题。
- 同一 scope 补齐 `progressiveBlur` 与 `progressiveTextureBlurEffect`，返回仍可继续追加
  noise、颜色、blend 与任意 effect 的不可变渐进 scope。运行时横/纵 shader 以及
  13%/40%/100% 三层增量方差 fallback 现在都分别使用 X/Y 半径；省略 Y 时保持旧等向输出。
- 渲染层把自定义 effect 放在独立背景平面上：blur、颜色控制与 blend 先完成，自定义效果随后执行，
  noise、高光、正文和图标仍位于其上。shader 可用时使用组合 shader，shader 不可用时继续走矩阵与
  blend fallback，但不会再因重建 fallback 背景而丢失自定义 effect，也不会二次采样窗口。
- Blur 示例的纹理预览已改为真实调用公共 scope preset，保持原有 280dp 预览、实时 slider、blend
  preset、传感器高光和渐进模糊结构。直接回归覆盖双轴 10/20dp、两级自定义滤镜顺序、fallback
  存活、正文不进入滤镜子树、noise 层与 150dp 上限。

本批定向 scope wrapper 11 项、既有 backdrop 5 项与示例 Blur 行为回归通过。完整分析、测试、
范围门禁以及新的 Android arm64/Windows x64 Release 结果由本轮发布周期统一记录。

## 2026-08-30 第四十五批结果

- 重新从当前上游公开声明反查范围脚本，发现 `ColorSchemeMode` 虽然显示已覆盖，实际映射到的是
  旧 Flutter `preset/custom/dynamic` 元数据；真正实现上游 System、Light、Dark、MonetSystem、
  MonetLight、MonetDark 六分支的是 `MiuixColorMode`。范围映射已改为后者，旧类型明确归为兼容扩展，
  不再拿错误的同名类型充当来源契约证据。
- 同一声明反查发现 `SurfaceDefaults` 和 `TextFieldColors` 完全没有公共对应。现已新增
  `MiuixSurfaceDefaults` 与 `MiuixSurface.source`，明确消费来源矩形 shape、0dp 阴影和无玻璃表面；
  普通入口继续遵循 HyperOS 4 全局连续圆角开关，避免来源兼容默认值倒灌为新组件默认视觉。
- 新增不可变 `MiuixTextFieldColors` 及 `MiuixTextFieldDefaults.colors`。背景、标签、焦点描边三通道
  使用来源语义色并支持独立覆盖；TextField 普通与 source 入口都可接收完整 palette，旧逐通道参数
  仍按通道优先。直接回归验证 palette 的值语义、复制、背景覆盖、焦点 2dp 描边与标签继承。

这批将当前来源映射从 195 扩展到 197 项，并新增两个必需公共名称；完整套件、范围门禁和新 Release
仍由本轮发布周期统一验证。其余当前上游公开声明仍需继续逐项区分框架接收器、兼容别名与真实缺口。

## 2026-08-30 第四十六批结果

- 当前上游 `BlurDefaults.kt` 与 `highlight/HighlightStyle.kt` 的公开声明此前只有
  `BlurColors`、`Highlight` 和 `LightPosition` 的扁平近似；`BlendColorEntry`、
  `BlurBlendMode`、`HighlightStyle`、`LightSource`、`BloomStroke` 和 BlurDefaults 工厂
  没有完整公共对应。范围门禁现为这些真实实现逐项建映射，不再只靠外围类型名表示覆盖。
- 新增不可变 `MiuixBlendColorEntry`、`MiuixLightSource`、`MiuixHighlightStyle` 与
  `MiuixBloomStroke`。BlurColors 直接拥有来源的亮度、对比度、饱和度，blend scope 和
  普通/渐进 texture preset 会一起传播；旧 `MiuixBlurBlendEntry` 保留类型别名兼容。
- BloomStroke 的六组明暗尺寸 preset、两盏光源、颜色、强度、内侧 halo 与 BlendMode
  进入实际 painter。`dualPeak` 选择独立 shader，严格使用上游 `dot(N.xy,L.xy)^2`
  形成相反双峰；style 在运行中切换时会释放旧 shader 并选择正确程序。非 Bloom 自定义
  style 保留颜色和合成模式的平面 fallback，避免假称 Flutter 可动态编译任意 AGSL。
- 扩展 BlurBlendMode 覆盖标准 Skia 0..28 与 MIUIX 100..121、200..203 原始编号。
  已有 shader 精确分支继续走加速路径；尚未直接编入 shader 的标准 Porter-Duff/HSL
  分支转交 Flutter 原生 BlendMode，避免过去新增名称后静默按 SrcOver 绘制。
- 旧扁平 `MiuixHighlight(color/blur/position...)` 继续投影到 BloomStroke，API 与自定义
  参数语义不变；六个来源 preset 则修正了旧 painter 把 5% 平面 stroke alpha 再乘到主光上的
  错误。主/次光现在使用各自 Color alpha 与 intensity，上缘恢复来源可见但克制的镜面边。
  传感器倾斜同时更新 canonical light source 与兼容字段，并保留双峰及合成模式；新增模型值、
  原始编号、scope 控制传播、shader 路由和倾斜不可变性回归。

本批把当前来源映射由 197 扩展到 204 项。完整分析、测试、注释门禁以及新的 Android
arm64/Windows x64 Release 仍由本轮发布周期统一验证；没有任务自有 arm64 目标，因此
本批不会把静态 ABI/签名检查或 x86_64 设备冒充成 arm64 运行与视觉证据。

## 2026-08-30 第四十七批结果

- 复核 `Button.kt`、`IconButton.kt`、`FloatingActionButton.kt`、`Divider.kt`、
  `ProgressIndicator.kt` 与 `SmallTitle.kt` 后确认：这些控件的主体布局、来源构造、
  状态切换和关键尺寸已有直接实现，但对应 Colors/Defaults 多数没有进入当前源码范围映射，
  因而被审计误列为名称缺口。现为九个真实公开类型逐项建立映射，范围先由 204 扩展到 213 项。
- `MiuixButtonColors` 和 `MiuixTextButtonColors` 原先只保存四个 final 字段，缺少上游
  Kotlin `data class` 的值语义。现已补齐逐字段相等、稳定哈希和逐通道 `copyWith`，主题或
  配置状态持有者可以可靠比较 palette，而不会改变按钮的布局、命中区或动效。
- `MiuixButtonDefaults` 新增来源同名 `buttonColorsPrimary` 与
  `textButtonColorsPrimary`，完整保留四个独立覆写通道；旧的 `primary` 布尔参数继续兼容。
  普通入口仍使用 HyperOS 4 默认几何，`.source` 仍保留审计过的 MIUIX 1.0.9 几何，避免把
  来源兼容尺寸重新变成新组件默认视觉。
- 同批继续复核导航组，新增 `MiuixNavigationBarDefaults`、
  `MiuixFloatingNavigationBarDefaults` 和 `MiuixTopAppBarDefaults`。普通导航目的地的
  64dp 高度、26dp 图标、12sp 标签、上下 8dp 间距及三种按压/未选透明度，浮动导航的
  36/1/12/12/28/10dp 来源常量，以及顶部栏 26/16/16/52/50/4/8dp 常量均有公共所有者，
  实际布局、着色与无效值 fallback 改为读取同一 Defaults，避免文档常量与控件漂移。
- `NavigationItem` 映射到已有 `MiuixNavigationItem`；后者保留来源 label/icon 核心字段，
  并作为 Flutter 兼容扩展增加 selectedIcon、badge、layoutLabel 和 enabled。映射总数由
  213 继续扩展到 217，扩展字段不反向伪装成上游声明。
- 进一步发现旧范围脚本把上游顶栏工厂 `MiuixScrollBehavior` 映射到了同名的通用页面
  overscroll 类，虽然名称存在，但状态、嵌套滚动和折叠职责完全不相干。现已改为真实的
  `MiuixTopAppBarScrollBehavior`，并新增 `MiuixTopAppBarState`；heightOffsetLimit、
  heightOffset、contentOffset、collapsedFraction 与 overlappedFraction 可独立提升和观察，
  外部状态修改与内部滚动/吸附双向同步。`TopAppBarState`、`rememberTopAppBarState`、
  `ScrollBehavior` 三项真实映射把总数由 217 扩展到 220。

本批新增值语义与来源工厂定向回归；映射门禁仅证明公开类型存在，不代替运行行为或像素验证。
完整分析、测试、范围门禁和新 Release 由本轮发布周期统一验证。

## 2026-08-30 第四十八批结果

- 当前 `BottomSheetContentLayout.kt` 的拖拽、嵌套滚动、预测返回与 Folme 可见性状态机已有
  对应实现，但 Flutter 三个公开入口只暴露标题、动作和 controller，遗漏 backgroundColor、
  enableWindowDim、cornerRadius、sheetMaxWidth、outsideMargin、insideMargin、
  defaultWindowInsetsPadding 与 dragHandleColor，导致上游可配置表面只能被硬编码。
- 新增 `MiuixBottomSheetDefaults`，公开 28dp 顶角、640dp 最大宽度、零外边距、水平
  24dp 内边距以及背景/拖拽条语义色工厂。八个参数现统一贯通 Overlay、Window 和底层
  Surface；无效半径与宽度有 Release 安全 fallback，方向性外边距在布局时解析。
- 自定义背景会同时用于弹层和向上弹性拉伸的补色区域；`enableWindowDim=false` 只清除
  遮罩颜色，不移除模态命中层；dragHandleColor 保留来源静止 20%、按下 35% 的 alpha
  替换语义。普通入口继续默认 HyperOS 4 局部玻璃，`glass:false` 保留 opaque 来源路径。
- 11 项既有 BottomSheet 回归连同新增公开参数回归全部通过，覆盖预测返回、禁止关闭、
  Overlay/Window 可见性、生命周期、内容高度、动态 controller、拖拽条、阈值和嵌套滚动。
  `DialogDefaults` 与 `BottomSheetDefaults` 映射把范围由 220 扩展到 222；映射仍不替代视觉证据。

完整套件、Golden、双平台构建、库包、签名/架构与 SHA-256 由本批 Release 周期统一验证。

## 2026-08-30 第四十九批结果

- 开始按当前 `miuix-nav` 权威源码补导航基础层，新增应用自有 `MiuixNavKey`、可直接修改并
  通过 ChangeNotifier 观察的 `MiuixNavBackStack`，以及只以该栈为状态源的
  `MiuixNavController`。push、replace、pop 与 popUntil 均有直接回归，pop/popUntil 不会
  删除已有根目的地；批量替换与缩短栈只发布一次通知，非空 key 栈禁止通过 length 凭空扩容。
- 栈恢复采用显式 application encoder/decoder：输出是不随原栈继续变化的不可修改快照，恢复
  得到新的可观察栈。它覆盖 Flutter 环境中的持久化边界，但没有把 Dart 缺少 Kotlin 编译期
  多态序列化的事实伪装成自动 `rememberNavBackStack` 等价。
- 补齐 `MiuixNavCornerClipMode`、`MiuixNavDisplayEffects` 与 `MiuixNavRole`。Leading/All
  的连续相对深度开区间、整数深度输入放行、NaN/Infinity 防御、nullable backdrop 和不可变
  值语义均已测试；映射证明模型存在，尚不能替代未来 NavDisplay 的实际分层绘制。
- 补齐 Spring/Tween `MiuixNavSettleSpec` 与 `MiuixNavMotion`。默认 commit/cancel 为临界阻尼、
  stiffness 146、开启过冲钳制，programmatic 为 500ms 项目校准曲线；欠阻尼同时要求
  clampOvershoot=false，且阻尼/刚度必须有限并大于零，这些约束使用显式 ArgumentError，
  Release 构建不会因 assert 移除而失效。
- 现有页面转场 Builder 与 `MiuixPageRoute` 可接收同一 programmatic 配方：Builder 统一驱动
  主/次动画，避免进入页、被覆盖页、遮罩与视差曲线失步；Route 提供匹配的 Navigator 时长。
  Spring 型 programmatic 配方在连续 NavDisplay 实现前仍回退到既有 500ms 曲线，未声称已完成
  交互 settle、swipe-edge 竞技、NavEntry、NavDisplay 或 reconciler。
- 新增六组模型/路由回归并保持既有导航回归通过。九项真实映射把范围从 222 扩展到 231；
  完整分析、测试、Golden、双平台构建、库包与哈希将在本轮 Release 周期统一验证。当前没有
  任务自有 arm64 运行目标，x86_64 模拟器不会被用作 arm64 真机视觉或动效证据。

## 2026-08-30 第五十批结果

- 对照当前 `miuix-nav` 的 `NavDisplay.kt`、`NavPresentation.kt`、`NavDriver.kt`、
  `NavTransitionScope.kt`、`NavTransition.kt`、`NavDirectionalTransition.kt` 与
  `NavTransitions.kt`，实现公共 `MiuixNavDisplay` 和精确运行时类型注册的
  `MiuixNavEntryBuilder`。每个目的地使用应用提供的稳定 content key；重复 key 与空栈会
  明确报错，不再用视觉索引冒充身份。
- 一个无界 AnimationController 现在是唯一连续 `animatedTop` 驱动。进入、被覆盖、离场、
  Modal、遮罩、圆角和输入阻断均读取同一相对深度；离场目的地保留至深度窗口外，当前栈中
  更深的页面 Offstage 保活并关闭 ticker，因此滚动、文本等 Flutter State 不因深度裁剪丢失。
- 直接栈变更会分类为 Push、Pop、MultiPush、MultiPop、Replace 或 ReplaceAll。完整步进使用
  programmatic 配方，部分/被打断步进使用弹簧；commit 采用来源速度下限，cancel 与钳制型
  spring 不越过稳定端点。减弱动效直接落在稳定构图，异常 NaN/Infinity 不进入 Transform、
  Opacity、Clip 或遮罩 alpha。
- 指针返回支持左到右、右到左、上到下和下到上四种物理方向，并采用来源的速度优先与 0.5
  位置阈值；运行中的 programmatic 动画可从当前画面无跳变接管。Android predictive back 的
  start/update/cancel/commit、传统按钮 Back 和嵌套 Back 共用同一栈所有权；交互子控件在
  Flutter arena 中保留优先权。
- 默认转场保留进入页整宽位移、被覆盖页四分之一视差和 0.9 alpha，Modal 采用纵向进入与
  opaqueDepth 2，None 保持恒等。边界所有权、全屏 sibling 遮罩、RTL、像素吸附与自定义方向
  分派均有定向回归；示例“嵌套导航测试”已移除手写双层动画，直接展示公共 NavDisplay。
- Android 物理屏幕底角读取由示例私有动态色通道下沉到 `flutter_miuix/platform` 插件：API 31+
  优先 RoundedCorner，缺失时读取 framework dimen，桌面、无插件与异常安全返回零。14 项真实
  公开声明映射把范围从 231 扩展到 245，必需名称门禁同步加入具体子类型与工厂。

本批 widget 测试证明确定性的层级、状态、手势与返回行为，不替代真机视觉和帧节奏。当前没有
任务自有 arm64 运行目标，因此本轮仍只报告 Android 静态 ABI、包名、版本号和测试签名边界；
x86_64 模拟器不作为 arm64 流畅度或视觉一致性证据。

## 2026-08-30 第五十一批结果

- 对照当前 `miuix-nav` 的 `PredictiveBackHandler.kt`、`NavBackEvent.kt` 与
  `WindowNavigationEventBridge`，新增公共 `MiuixNavBackEvent`、
  `MiuixPredictiveBackHandler` 和 `MiuixWindowNavigationEventBridge`。事件保留有限
  `[0, .999]` 进度、物理边缘、触点 Y 与单调帧时间；cancel/commit 每个手势只交付一个终态，
  按钮 Back 走离散 commit，不伪造连续帧。
- Flutter 的 `WidgetsBinding` 允许多个 observer 同时接受一次预测返回，原实现中的
  NavDisplay 与其上方 Dialog、BottomSheet 或 ListPopup 因而可能一起推进。现在所有 MIUIX
  返回表面共享唯一所有者注册表：按组合顺序选择最后一个实际可启动者，禁用、非当前 Route、
  栈深不足或禁止关闭的表面不会挡住后面的合格所有者。
- `MiuixWindowNavigationEventBridge` 是明确的组合边界，不额外安装 observer。Compose Android
  需要在两个 dispatcher 间转发，而 FlutterView 已经把系统消息统一交给 WidgetsBinding；
  再建一层桥会重复交付，因此这里记录平台职责差异，而不制造空的第二事件源。
- 公开 `MiuixSquircleDefaults` 的 1.1 扩展和 1 至 2 合法范围，并让 CPU 路径与 shader 路径
  读取同一常量；`miuixIsSquircleEnabled` 从当前主题返回能力状态。渐进模糊、设备倾斜、
  高光 indication、HSV/OkLab 色彩模型、下拉、浮动导航、范围滑块、overscroll、下拉刷新与
  滚动条等已实现能力也逐项建立来源映射，当前范围从 245 扩展至 267。
- 定向回归覆盖有限进度、左右边缘、cancel/commit、按钮 Back、嵌套 handler、浮层覆盖
  NavDisplay，以及不可用顶层向下回落。映射门禁只证明公开能力存在；设备视觉、触感和帧节奏
  仍必须由任务自有 arm64 目标验证。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-08-30 第五十二批结果

- 对照当前 `miuix-core/utils/Utils.kt` 的 `Platform`、`platform()`、`getRoundedCorner()`、
  `platformDialogProperties()` 与 `RemovePlatformDialogDefaultEffects()`，新增公共
  `MiuixPlatform`、`miuixPlatform` 和不可变 `MiuixPlatformDialogProperties`。Flutter 的
  `kIsWeb`/`kIsWasm` 与 TargetPlatform 可区分 Android、iOS、macOS、桌面、JS 和 WasmJS，
  Fuchsia 在上游无独立分支，归入 Desktop 兼容路径。
- Android 来源对话框关闭平台 Back、平台默认宽度和 decorFitsSystemWindows；Skiko 还关闭
  platform inset、scrim 与 platform transition。Flutter MIUIX 的 OverlayRoute 在现有
  FlutterView 内拥有这些职责，因此公共策略统一表达关闭平台默认值；
  `removeMiuixPlatformDialogDefaultEffects()` 是明确的安全无操作，不会再安装第二个 dim 或动画源。
- `getRoundedCorner()` 与 Android-only `getCornerRadiusBottom()` 复用既有
  `loadMiuixNavSystemCornerRadius()`：API 31+ 优先 bottom-left RoundedCorner，缺失时读取系统
  dimen，桌面、缺插件和异常返回零。
- Flutter 不公开从任意 AGSL/SkSL 字符串创建 shader 的运行时编译器，
  `miuixIsRuntimeShaderSupported()` 因而如实返回 false；包内预编译 FragmentProgram 由独立
  `miuixIsBundledFragmentShaderSupported()` 查询。Blur、颜色矩阵、合成与 backdrop 的
  ImageFilter effect graph 可用，`miuixIsRenderEffectSupported()` 返回 true。这样不会把既有
  `MiuixRuntimeShader` 迁移描述符伪装成真正编译结果。
- 八项来源声明加入范围门禁，映射由 267 增至 275。
- 定向回归验证平台分支、对话框策略值语义及无操作钩子。该静态回归不替代 Android 真机
  圆角、Dialog window 或系统手势验证。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-08-30 第五十三批结果

- 修复底部 Tab 的选中胶囊轮廓重复。普通 `MiuixNavigationBar` 在传入
  `selectedIndicatorColor` 时原先同时绘制 5.5% 底色和 0.75dp/8% alpha 外边框；现在只保留
  底色。`MiuixFloatingNavigationBar` 的连续移动胶囊原先额外绘制 0.65dp 白色高光边；现在
  Squircle 与 rounded-rectangle fallback 均使用 `BorderSide.none`。
- 修改只影响选中胶囊，不移除导航外壳自身的可选 `showDivider`，也不改变选中项尺寸、圆角、
  图标/文字着色、拖拽位置、按压缩小和选择弹簧。普通底栏切换选中项前后均保持一个无描边
  指示器；浮动底栏的形状回归明确断言 side 为 none。
- FloatingNavigationBar 六态 Golden 的差异为 0.09% 至 0.10%，隔离差异集中在原选中胶囊
  外沿；更新后的 light、dark、pressed、disabled、expanded 与 animationMidpoint 基线已再次
  独立验证通过。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-08-31 第五十四批结果

- 以 `Kyant0/AndroidLiquidGlass` 的提交
  `65ab177e90e5c1d8c62e70cf7755841982da65f6` 为光学参考，复核 `LiquidBottomTabs.kt`、
  `Lens.kt`、颜色控制和圆角折射 shader。底栏手势、弹簧、选择状态、尺寸及现有 HyperOS
  单选中层保持不变，没有引入 Kotlin、原生 View 或平台 UI。
- 完整底栏材质由原来的 4dp 模糊升级为参考链的 1.5 倍 vibrancy、8dp 模糊和 24/24dp
  圆角折射。vibrancy 使用参考项目相同的 Rec. 709 系数 `.213/.715/.072`；因为颜色矩阵是
  线性变换，Flutter 在一次镜片 runtime shader 的采样出口执行同值运算，避免新增第二个
  BackdropFilter。
- 默认 HyperOS 模式仍不绘制常驻 BloomStroke，避免重新出现底栏白线；移动选中区域仍只叠加
  稳定强调色，不独立模糊。显式 `.source` 保留现有高光、深度与按压色散兼容路径。
- 新增 shader ABI/材质链回归，确认 8dp、1.5 倍饱和度、物理像素统一域和 Impeller 路径；
  四张受影响 Golden 已逐张检查，像素差异集中在底栏的背景清晰度和胶囊边缘，没有布局位移。
  另增亮/暗两张高饱和彩色背景专用基线，直接锁定折射、颜色恢复、无白线和 56dp 稳定高度。

上述数值来自第三方 Apache-2.0 项目的公开实现，不称为小米官方 HyperOS 参数；Android 真机
运行效果仍必须在任务自有 arm64 设备上验证，不能用 Windows/Widget Golden 代替。

## 2026-08-31 第五十五批排查结果

- 第一阶段排查 HyperOS 液态底栏在窗口底边呈现“上半透明、下半模糊”的水平分层。主胶囊只有
  56dp 高，却把 BackdropFilter 的采样平面向四周额外扩展 40dp；本批先消除这个确定存在的范围
  错配，但后续 Android 实机反馈仍有分层，证明外扩裁切不是唯一根因。
- 主镜片的负向折射位移始终朝胶囊内部采样，不需要外部 40dp 邻域。本批将默认 HyperOS 主面板
  改为零扩展、单一完整 56dp 采样平面；现有 8dp 模糊、1.5 倍 vibrancy、24/24dp 折射，以及
  手势、弹簧、选中层和显式 `.source` 兼容路径均保持不变。
- 亮暗专用 Golden 新增结构断言：主胶囊 Rect 必须与其唯一 BackdropFilter Rect 完全相同。
  该断言会直接阻止未来再次引入上下越界、窗口裁切或半幅滤镜；示例中的四张受影响 Golden
  也已重新生成并检查；这些桌面测试只能证明布局和 fallback，不能证明 Android runtime shader。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-08-31 第五十六批结果

- 重新隔离背景变量后确认：纵向完全不变的条纹背景在普通 Flutter blur 路径上下连续；此前亮暗
  Golden 在截图时 runtime shader 尚未异步加载，实际覆盖的是 fallback，不能为 Android 的
  `ImageFilter.shader` 采样正确性提供证据。
- Git 历史显示项目曾根据 Android 真机的 padded-texture 坐标错位和异常采样证据，明确禁用
  Android runtime lens；`1f7c5d2` 又基于“Impeller 已统一输入原点”的假设重新启用，但该假设
  没有 arm64 真机证据，且与本轮连续实机分层反馈冲突。
- Android 现在不再加载或绑定 `miuix_liquid_lens.frag`。完整胶囊改用 Flutter 引擎稳定的单一
  `ImageFilter.blur`，并在该模糊结果上用 `ColorFiltered` 和同一 Rec. 709 矩阵恢复 1.5 倍
  vibrancy，最后再绘制 40% 语义表面色。该路径无外扩采样、无上下纹理坐标换算，也没有第二个
  BackdropFilter；桌面受支持后端仍可保留折射 shader。
- 底栏尺寸、点击/拖拽、选中位置、弹簧、按压高光及 `.source` 交互全部保持不变。新增强制
  `TargetPlatform.android` 的专用 Golden，并在独立 PNG 解码测试中逐像素比较三个未选中槽、
  三组上下镜像行；纵向不变背景的 RGB/A 差值必须不超过 3，否则直接失败。
- 新建本任务专用 API 35 x86_64 模拟器，以 OpenGLES Impeller 安装调试包，分别截取首页与设置
  Tab 选中后的实际 Android 画面。两张画面中完整胶囊均使用连续灰色玻璃面，背景文字在上下
  区域统一模糊；日志无 Flutter Error、Fatal 或 ANR。该证据验证 Android 布局和稳定滤镜分支，
  但不替代 arm64 真机 GPU 验证。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-08-31 第五十七批结果

- 后续 arm64 真机反馈显示第五十六批虽然移除了上下分区，但整个底栏又失去可见模糊。重新检查
  RenderObject 合成顺序后确认，问题是把 `ColorFiltered` 包在 `BackdropFilter` 外侧：它会先建立
  一个透明离屏层，部分 Android Impeller 设备随后无法从真实页面背板取样；Widget 测试后端仍能
  合成该结构，因此此前 Golden 与像素断言没有暴露问题。
- Android 与 shader 不可用的稳定分支改成 Flutter 推荐的直接合成顺序：`BackdropFilter` 直接
  读取已经绘制的页面，40% 语义表面色作为它的 child 随后绘制。该路径不再使用外层
  `ColorFiltered`、runtime lens、扩展采样或第二个 BackdropFilter，因而同时保留完整 56dp 的可见
  模糊和上下统一性；桌面端支持的 lens shader 仍保留 1.5 倍 vibrancy 与折射。
- Android 专用回归现在同时检查直接 BackdropFilter、`srcOver`、表面色层级、精确胶囊 Rect 和
  高频条纹边缘对比；胶囊外条纹保持锐利，胶囊内每个采样行都必须明显软化，且上下模糊强度差
  小于 0.1。
- 在本任务 API 35 x86_64 OpenGLES Impeller 模拟器重新安装调试包，首页与设置页均能看到背景
  文字进入底栏后边缘软化，完整胶囊保持连续玻璃着色；日志无 Flutter Error、Fatal 或 ANR。
  该运行证据验证 Android 稳定合成分支，但最终 arm64 GPU 表现仍以用户真机安装新版 APK 为准。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。

## 2026-09-01 第五十八批结果

- 顶部标题区域新增默认 `MiuixTopAppBarBlurStyle.gradient`。该路径只使用一个直接读取
  页面背板的 `BackdropFilter`，其 child 绘制三段语义色纵向渐变；标题、返回按钮和操作按钮
  位于独立前景层。滤镜外不再使用 `ShaderMask`、整层 `Opacity` 或横向切片，避免 Android
  Impeller 丢失真实背景取样、标题区域完全透明或出现条带分界。
- `gaussian` 继续提供显式均匀玻璃，`progressive` 继续提供随正文滚动渐显的兼容路径；新增枚举
  值追加在现有值之后，避免改变旧值顺序。普通 `MiuixTopAppBar` 与
  `MiuixSliverTopAppBar` 使用渐变玻璃作为新默认，`.source` Sliver 保留滚动渐显行为。
- 小标题状态的玻璃操作区不再把多个 action 合成一个横向椭圆。每个 action 现在拥有独立的
  48×48dp `MiuixGlass` 和 `CircleBorder`，相邻圆形间距 8dp；标题碰撞测量同步使用实际圆形组
  宽度。显式 `plain` 模式继续保留原来的 40dp 图标中心节奏与 48dp 交互目标。
- Android 平台专用材质回归断言顶栏不存在 `ShaderMask`、只有一个直接背景滤镜，并用高频彩条
  Golden 验证标题区域每一行均发生软化、下边缘仍保留模糊且渐变连续。双 action 几何回归锁定
  104×48dp 组宽、两个独立圆形玻璃和 8dp 间距；相关普通、Scaffold、Sliver 与示例 Golden
  已更新并逐项复核。
- 在本任务 API 35 x86_64 模拟器安装 Android x64 Debug APK，以 OpenGLES Impeller 打开示例首页；
  运行截图可见顶部持续渐变玻璃和圆形操作按钮，日志没有 Flutter Error 或 Fatal。该证据验证
  Android 稳定合成路径，不替代 arm64 真机 GPU 与触感验证。
- 新增 `doc/CURRENT_UI_IMPLEMENTATION_AND_USAGE_ZH.md`，按当前 `lib/` 实现说明主题、Scaffold
  层级、顶部标题、四类 Tab/导航、常用基础控件、设置与输入、弹层反馈、扩展控件、页面返回和
  `.source` 兼容边界；同步修正旧接入文档中“默认均匀模糊、多个操作共用胶囊”的过时描述。

完整分析、全量测试、双平台 Release、库包、签名/架构与 SHA-256 由本批发布周期统一验证。
