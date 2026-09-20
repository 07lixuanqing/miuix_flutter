# 对照 ChuxinNeko/flutter_miuix 的优化建议

对比日期：2026-09-08。本轮只克隆参考仓库、检查源码和形成建议，没有替换组件实现。

## 1. 结论与优先级

**值得借鉴的是职责划分、状态约束和接入体验。当前项目的 HyperOS 4 底栏、材质分级、扩展控件和发布验证应继续保留。** 参考项目没有直接解决我们上一轮发现的液态底栏一致性、顶部模糊下缘衔接和背景内容自适应问题，不能整体换成它就认为完成优化。

建议按以下顺序推进：

| 优先级 | 我们应该优化什么 | 参考项目带来的启发 | 最终效果 |
| --- | --- | --- | --- |
| P1 | 统一底栏默认入口、主题参数和材质档位 | 导航类、默认参数、颜色角色集中在同一模块，调用边界更清楚 | 示例、文档和业务应用使用同一默认底栏，修改主题就能统一生效 |
| P1 | 统一标题与滚动状态，补短页面和中途打断场景 | 对方明确区分长页面、短页面、回弹和释放吸附，并有专门测试 | 标题不追赶手指、不停在错误中间态，返回顶部能恢复 |
| P1 | 让模糊模块有明确的背景来源与合成职责 | 对方把捕获、颜色控制、裁剪、高光分开，背景来源显式传入 | 能解释每个表面采样谁、叠几层、如何回退，避免反复修复同一种花屏 |
| P2 | 收拢弹簧参数与重复计算 | 独立 `miuix_motion.dart`、`miuix_spring_utils.dart` | 导航、弹层、按压共享参数语义，同时保留不同动作的合理差别 |
| P2 | 完善字重策略及测量一致性 | 显式 `fontWeightAdjustment`、字重调整函数和测试 | 粗体、大字体、长标题与自动缩放协同，不只改变最终画字结果 |
| P2 | 提供更容易查用的组件目录和跨包迁移说明 | 分类示例、参数表、默认值、成套用法资料 | 接入者容易找到正确组件，不混用两个同名包的 API |
| P2 | 让测试按用户操作和失效场景更容易检索 | 中文输入合成、键盘遮挡、刷新中断等独立回归文件 | 定位失败更快，避免“全量通过”掩盖未覆盖场景 |

这些建议是在当前 [界面问题审查](CURRENT_UI_ISSUES_AND_OPTIMIZATION_ZH.md) 基础上补充的工程对照。视觉目标仍以 [本项目 HyperOS 4 基线](HYPEROS4_OFFICIAL_APP_DESIGN_SPEC_ZH.md) 为准，所有 dp、sigma、字重及动效数值都要区分项目校准值和来源兼容值。

## 2. 已保留的参考仓库与对比边界

| 项目 | 当前项目 | 参考项目 |
| --- | --- | --- |
| 仓库 | `07lixuanqing/miuix_flutter` | `ChuxinNeko/flutter_miuix` |
| 本地位置 | `C:\Code\miuix_flutter` | `C:\Code\references\flutter_miuix_ChuxinNeko` |
| 对比提交 | `d7a601ef32164b5051f96073d5a4a4a74a5b0fb1` | `964c180e3b4687820986a53ff2d8b7bc9cf7a395` |
| 包版本 | 1.2.1 | 1.1.1 |
| Dart 约束 | `>=3.10.0 <4.0.0` | `^3.12.2` |
| 主入口 | `package:flutter_miuix/flutter_miuix.dart` | `package:flutter_miuix/miuix.dart` |
| 分发定位 | 当前禁止 pub 发布，提供项目规定的双平台 Release 和库 ZIP | pub 包元数据、仓库与问题入口、组件用法文档 |

参考仓库是完整克隆，非浅克隆，工作区保持干净，没有安装其配套 Skill、执行其安装器或修改 SDK 要求。后续可以直接在该目录查询历史、对比组件。另有本地索引：`C:\Code\references\flutter_miuix_ChuxinNeko_REFERENCE.md`。

两边当前可见 Git 历史分别为 8 和 27 个提交，本轮比较所有已获取提交 ID 没有交集。这说明**当前可见 Git 历史没有共同提交**，不据此判断代码最初来源或否认共同的 Compose MIUIX 参考。

上游项目地址：[ChuxinNeko/flutter_miuix](https://github.com/ChuxinNeko/flutter_miuix)。本报告引用的代码链接固定在上述提交，避免后续仓库更新后无法复核。本地参考仓库保留其 origin，未向当前项目添加新 remote 或依赖。

## 3. 底部 Tab：借鉴模块边界，保留自己的 HyperOS 4 能力

### 3.1 对方实际实现了什么

参考项目的导航颜色和默认值集中在 `miuix_navigation_bar.dart`：普通导航与悬浮导航共用颜色角色，各自有明确的默认参数类。

但它的 `MiuixFloatingNavigationBar` 核心是 `DecoratedBox(ShapeDecoration(...))` 加内容 Row，内部采用实体颜色和阴影；导航项主要提供图标、徽标和按压/选中透明度。该组件本身没有我们当前液态底栏的背景滤镜、移动镜片、镜片横拖或独立圆形操作。见 [参考导航实现](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/components/miuix_navigation_bar.dart)。

因此，不建议把它的悬浮底栏直接移植来替换当前底栏，也不能把它的 52dp 最小高度、图标间距和旧式透明度当成我们的新视觉目标。

### 3.2 我们真正需要优化的地方

当前存在两条公共悬浮实现：

- `MiuixFloatingNavigationBar`：默认 token 为 58dp 面板、52dp 选中层。
- `MiuixIosLiquidGlassNavigationBar`：示例实际使用，默认 56dp 面板、48dp 镜片，显式 `.source` 保留 64/56dp。

现有接入指南把前者推荐为默认；液态实现注释又把前者描述为兼容方案。这样一来，使用文档的应用和示例得到的并不是同一套底栏。液态实现还把尺寸、图标、文字和部分材质常量留在私有字段中，修改 `MiuixHyperOs4Tokens` 不一定能作用到它。

**建议：以当前项目要求的 56/48dp 路线统一新默认，建立一套共同的导航几何与材质配置。** 普通业务代码只需要选择目的地、显示模式、当前索引和可选主操作。旧 API 保留适配入口，`.source` 继续承担来源兼容，不默认扩大迁移范围。

先保持以下现有能力：完整胶囊取样、圆角外透明、等分图文、取消回位、减少动态效果、RTL、禁用项、释放位置决定目标、Android 稳定滤镜回退。再补液态 Tab 的焦点可见性、同一底栏中主面板与圆形操作的档位协调。

验收：相同主题配置在示例和最小业务接入页得到相同几何；切五档时主胶囊与独立操作感知一致；键盘焦点可见且不冒充选中状态；切换到旧构造不会改变其已有合约。

## 4. 顶部标题：更值得学的是状态约束，不是模糊外观

### 4.1 参考项目的可取之处

对方的 `MiuixExitUntilCollapsedScrollBehavior` 对可滚动长页面采用明确关系：折叠量从滚动位置推导，再限制在允许区间；释放吸附通过动画改变列表位置，使折叠量继续跟随列表。短页面则走独立逻辑，区分用户拖动和被动回弹，避免回弹时标题被重新拉开。

它为这些行为提供了独立测试：

- `top_app_bar_release_snap_test.dart`：松手到最近端点，吸附后状态与滚动位置保持一致。
- `top_app_bar_scroll_gate_test.dart`：滚动、回弹及标题状态约束。
- `top_app_bar_collapse_probe_test.dart`：标题折叠探针。

见 [参考标题实现](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/components/miuix_top_app_bar.dart) 和 [释放吸附测试](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/test/top_app_bar_release_snap_test.dart)。

### 4.2 不能直接复制的部分

我们的普通顶栏采用嵌套滚动消耗模型：先消耗一部分手势折叠标题，再滚正文，并在需要时对 ScrollPosition 做校正；Sliver 入口还承担实际滚动几何。该模型不能简单套上“标题偏移恒等于负列表位置”的断言，否则会破坏先折叠标题的原有行为。

要借鉴的是**清楚定义状态由谁拥有，以及所有中断路径必须回到一致状态**：

| 场景 | 我们应明确的约束 |
| --- | --- |
| 用户直接拖动 | 同一手势距离只能由标题或正文消费一次，不能重复消费或无故丢失 |
| 列表位置恢复 / jump | 标题与恢复后的页面保持协调，不携带上一页的折叠量 |
| 慢拖后松手 | 按当前设计进入稳定端点，没有悬空的小标题半透明状态 |
| 快速反向拖动 | 中断旧动画并从当前位置继续，不从旧起点重播 |
| 短列表和上下回弹 | 明确何时允许展开，不能把非用户回弹误判为新的展开意图 |
| 销毁或减少动态效果开启 | 清理动画与回调，安全进入目标状态 |

本项目已有吸附、Spline 衰减、取消和减少动态效果处理，不能将这些全部算成缺失。建议保留行为，在默认 HyperOS 路线中协调大小标题的位置、透明度和材质范围，再补与真实列表组合的场景测试。

### 4.3 模糊效果仍要独立优化

参考顶栏 `blurred` 默认关闭；开启后使用一个直接 `BackdropFilter` 和均匀着色。它也没有提供沿高度连续减弱的模糊，不是我们顶部下缘断层的现成解法。

我们的目标保持：持续磨砂核心区、独立清晰标题和圆形操作、向正文平滑衰减的边缘区域。当前渐变模式只让色调 alpha 渐变，sigma 在整区仍一致，边界问题仍需本项目自行校准。不要为了采用参考实现而退回默认不透明 AppBar 或重新合并右侧操作按钮。

## 5. 玻璃材质：借鉴显式背景来源，不直接换成快照管线

### 5.1 两种渲染方式的区别

| 项目 | 参考 TextureBlur | 本项目默认 MiuixGlass / Android 液态底栏 |
| --- | --- | --- |
| 背景来源 | 显式 MiuixLayerBackdrop 对象中的 ui.Image 和坐标 | 当前表面后方已绘制的页面内容 |
| 更新方式 | 捕获节点 paint 后安排帧后回调，通过 OffsetLayer.toImageSync 更新快照 | BackdropFilter 在合成中采样 |
| 颜色与模糊 | 从快照裁取邻域、绘制模糊图像，再做颜色控制 | 由引擎滤镜和局部色调绘制组成，低层效果还有专门 shader |
| 适合借鉴 | 背景归属清楚，捕获与显示分离，采样区域和显示裁剪分开 | 已有稳定直接采样分支，应保留 |
| 需要验证 | 快照新旧时序、纹理生命周期、坐标/DPR 与重绘成本 | 多层采样、saveLayer、着色叠加和不同 GPU 后端 |

参考源码：[背景捕获](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/blur/miuix_layer_backdrop.dart)、[背景对象](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/blur/miuix_backdrop.dart)、[纹理模糊](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/blur/miuix_texture_blur.dart)。

快照方式不是假模糊，也不意味着必然更慢。但对动态滚动，帧后更新意味着使用者需要验证其采样新鲜度；捕获实际发生在该节点重绘后，不能仅凭注释就断言每个显示帧都一定重新捕获。仅祖先变换、滚动位置变化、DPR 变化等也需要检查坐标是否同步。

`toImageSync` 返回前会启动栅格化，但图像返回时栅格化可能尚未结束，不应把函数名字理解成“全部 GPU 工作已同步完成”。其图像尺寸由 bounds 与 pixelRatio 决定，见 [Flutter 官方说明](https://api.flutter.dev/flutter/rendering/OffsetLayer/toImageSync.html)。一张 1080×2400 的原始 RGBA 图像约 9.9MiB，这是尺寸估算，不是参考项目实测显存占用。

本轮没有运行两套方案的性能对照，不宣称哪一种更省电或更流畅。

### 5.2 最值得落地的工程调整

建议将本项目材质分成四个明确职责：

1. **配方解析**：角色、主题、五档、可读性要求、平台能力共同生成配置。
2. **背景取样**：默认走已验证的直接滤镜；只有确有需求时才引入可选显式背景源。
3. **轮廓与合成**：一个几何定义驱动裁剪、着色、边缘和阴影。
4. **交互绘制**：触点光与拖动光尽量局部重绘，避免带动整个滤镜树重建。

当前 `MiuixGlassOptics.navigation` / `.transient` 已提供角色基础，但 `MiuixGlass`、液态底栏及普通内容仍有不同参数路线。先统一配方，再评估是否需要新增背景抽象。不要为了“学习架构”立即更换全部底层渲染。

采样范围与输出裁剪分开这一思想值得借鉴；参考实现用约 3σ 邻域给模糊提供背景，再裁进自身轮廓。不过我们有明确的 Android 边缘纹理错位历史，不能直接把其外扩距离移植进当前 runtime lens 的采样坐标。

### 5.3 保留本项目已有的优势与保护

- Android 液态底栏明确避开未验证的 runtime lens，保留直接真实背景模糊。
- 低层纹理效果有多个扩展混合模式 shader；参考 `MiuixTextureBlur` 的扩展 blend mode 在当前绘制分支中会跳过。不能以同名 API 推断效果等价。
- 本项目已有渐进模糊实现和多种角色 token，可以评估复用，但仍须解决顶栏实际集成与后端验证。
- 本项目有 transient 材质入口，参考项目的普通卡片与悬浮底栏并不默认使用这套玻璃层级。

参考工程中的能力探测函数直接返回 true，这种写法不能替换我们已经存在的 shader 可用性检查和 Android 特定保护。API 存在不等于所有后端均支持所需的滤镜组合。

### 5.4 其他控件应该更克制

参考 Card 主要由语义表面色、内容色和形状组成，这提醒我们：高密度内容首先需要清楚的结构，不需要每行都增加光学层。保留 HyperOS 4 默认能力，同时按角色使用：

- 设置组、表格、树：一组内容共用一个容器，行状态用填色和分隔表达。
- 搜索与输入：光标、正文、占位和焦点对比优先，不靠增大模糊表达聚焦。
- 菜单、Dialog、BottomSheet：外层面板拥有玻璃，内部尽量避免重复取样。
- Slider、Checkbox、Switch：先保证状态、热区和动效，通常不需要每个内部部件都做背景模糊。

具体五档对照、顶部边缘目标与设备矩阵见前一份审查文档，避免维护第二套互相漂移的数值表。

## 6. 动效与模块结构：已有能力要收拢，不必重写

### 6.1 可以直接学习的组织方式

参考项目每个组件通常有独立 import 文件，主题、颜色、基础交互、模糊分别放置。它把 `folmeSpring(damping, response)` 与通用曲线放在 `miuix_motion.dart`，SpringEngine 和阻尼位移工具放在 `miuix_spring_utils.dart`。

本项目核心组件的 `miuix_widgets.dart` 当前聚合 **60 个 part 文件**。这些文件共用一个 Dart library 的私有空间，拆成很多文件不等于职责已独立。`miuix_effects.dart` 共 3735 行，包含材质、shader、形状、按压等多项职责；主题文件 1604 行，普通顶栏 1450 行，液态底栏 1542 行。行数包含注释，不能据此单独判定质量，但能指向维护边界需要审查的位置。

两边 lib 下 Dart 文件数为 233 / 78；这些数字包含生成图标、设计说明和不同扩展范围，**不能当成代码精简度或性能排名**。

### 6.2 建议拆分路线

先沿当前逻辑边界抽出独立 motion、glass recipe、glass surface 和 shader capability 模块，再逐步减少 `part` 间对私有成员的隐式依赖。保留 `flutter_miuix.dart` 公共聚合入口和兼容入口，不要求使用者更换 import。

动效只统一参数语义、合法值处理、减少动态效果、取消和重定向机制；不要把所有动作强制改成同一条弹簧。点击、拖动、释放吸附和来源兼容各有不同目标。

参考的 `folmeSpring` 公式可作对照，但当前项目已经使用 SpringDescription / SpringSimulation 和来源对应参数。下一步是减少重复公式与常量散落，而不是从“没有物理动画”开始补。

参考：[动效模块](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/theme/miuix_motion.dart)、[弹簧工具](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/foundation/miuix_spring_utils.dart)。

验收：拆分前后的关键时刻位置、取消回位、受控目标变更和减少动态效果保持一致；初次抽模块只调整职责，不顺便改视觉数值。之后再单独开展校准。

## 7. 文字与无障碍：需要统一策略，不能误报完全缺失

参考项目提供 `fontWeightAdjustment`、`adjustFontWeight` 和 `withMiuixWeight`，默认可把系统 boldText 映射为 +100，并允许显式覆盖。它还有单独的 `font_weight_adjustment_test.dart`。这种显式策略有助于解释标题、正文、按钮与输入之间的字重关系。

但本轮检查本机 Flutter SDK 后确认，**Text 和 EditableText 自身都读取 MediaQuery.boldText 并合并粗体样式**。本项目使用它们，所以不能写成“当前库不响应系统粗体”。参考项目的 +100 配方也不等于从 Android 系统读取到了完整的数值型 fontWeightAdjustment；其默认输入是 Flutter 的布尔 boldText。

我们更应该补的是：

- 明确是否需要可选的相对字重偏移，而不是全部由框架变成统一粗体。
- 自定义 TextPainter 测量、自动字号选择、标题避让和最后的 Text/EditableText 使用一致的最终样式。
- 对普通 Text、富文本、输入、长标题、字体放大和系统粗体组合做回归。
- 若实现自定义偏移，避免与 Flutter 自带粗体处理重复或相互覆盖。

当前 `MiuixText` 先用自己的 `_resolveStyle` 和 TextPainter 测量，再生成 Text/ Text.rich，本轮没有看到其测量前显式合并 boldText；这属于**测量与绘制可能不一致的风险**，需用实际字体和宽度复现后才能升级为确定 bug。报告的实测尺寸部分又读取了 live RenderBox，因此不能简单断言所有 layout result 字段都错。

参考：[字重解析](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/lib/src/theme/miuix/theme/miuix_text_styles.dart)、[字重测试](https://github.com/ChuxinNeko/flutter_miuix/blob/964c180e3b4687820986a53ff2d8b7bc9cf7a395/test/font_weight_adjustment_test.dart)、[Flutter boldText 定义](https://api.flutter.dev/flutter/widgets/MediaQueryData/boldText.html)。

## 8. 测试与接入文档：按场景组织，更容易找到真正的差距

### 8.1 对方值得借鉴的回归形式

| 对方测试 | 用户遇到的场景 | 对我们项目的用途 |
| --- | --- | --- |
| miuix_input_field_ime_test | 拼音合成时父页面每次输入都重建 | 验证 composing、selection 和文本保持，不能只测英文 enterText |
| overlay_dialog_ime_test | 键盘升起后 Dialog 中操作按钮被遮挡 | 把“能看到、能点击确认”作为验收，而不仅检查底部 padding |
| pull_to_refresh_interrupt_test | 刷新回弹未结束再次下拉 | 检查锁、动画和异步回调的中断路径 |
| floating_toolbar_tap_test | 工具栏真实点按 | 检查表面包装是否吞掉事件 |
| top_app_bar_release_snap_test | 标题半折叠时释放 | 检查实际列表位置与标题状态的组合关系 |

当前库已经有大量手势、键盘、弹层、减少动态效果和状态恢复测试；`MiuixInputField` 也已有持久 controller，并在受控 query 与当前文本相同时跳过覆盖，不能把参考项目修过的“重复拼音”直接认定为我们的现存 bug。

建议建立“场景 → 测试 → 运行证据”的索引，将常用回归从大测试聚合中按职责整理。当前 test 目录有 38 个 `*test.dart` 入口，还有被入口注册的 parts；参考有 12 个入口。入口数量不等于断言数量或覆盖率。

### 8.2 文档和示例的改进

参考项目提供分类 showcase 和按类别拆分的参数表，列出类型、默认值和使用例子。这种结构更适合业务接入。我们的文档已有丰富的行为审查和扩展说明，下一步可以把它们串成更直接的路径：

1. “我要做什么”索引：底部主导航、页内分类、搜索、表单、菜单、列表等。
2. 每个组件一页：效果/状态、最小示例、参数、受控状态、无障碍、兼容入口和运行边界。
3. 默认 HyperOS 4 与 `.source` 分开展示，参数表由真实代码核对，避免两套默认值。
4. 示例提供可复制的主题、导航外壳、表单与弹层组合，避免只有长列表展示。
5. 若后续制作本项目自己的接入 Skill，只引用本项目 API；本轮没有安装参考项目的同名 Skill。

### 8.3 两个同名包尤其需要防混用

| 功能 | 参考项目写法 | 本项目写法 |
| --- | --- | --- |
| 导入 | `flutter_miuix/miuix.dart` | `flutter_miuix/flutter_miuix.dart` |
| Scaffold 正文 | `content: (padding) => ...` | 常规 `body: ...` 与本项目的布局规则 |
| Button | 当前源码要求 `child`、`onPressed` | 常规 `label`、`onPressed`，并有其他内容槽 |
| 顶栏模糊 | `blurred: true` | `glass`、`blurStyle` 与主题材质 |
| 悬浮导航 | `children`、独立 Item 的 selected/onPressed | `items`、`selectedIndex`、`onDestinationSelected` 等 |
| ThemeController | 参考是有状态 Widget 入口 | 本项目是 ChangeNotifier 控制器 |

这里列出常规入口差别，不承诺包含所有兼容适配。两个包 package name 相同，不能在同一个应用中通过普通双依赖方式任意混用。文档应同时标明仓库和导入路径，不要仅写“安装 flutter_miuix”。

不要直接复制对方的安装说明覆盖当前本地库依赖，也不要把其 Skill 当成我们 API 的自动补全资料。

本轮还确认参考 README 的快速开始示例使用 `MiuixButton(title: ..., onClick: ...)`，而同一提交的实际构造要求 `child` 和 `onPressed`。这说明对方文档同样存在与源码不同步的问题：可以学习分类和参数表的组织方式，但示例必须以当前构造核对，最好加入可编译的文档示例检查。不能因其文档看起来完整就原样采用。

## 9. 验证结果与限制

### 已确认

- 参考仓库完整克隆成功，HEAD、origin 和工作区状态已核对；当前可见历史中没有共同提交。
- 对照了 README、pubspec、公共入口、导航、顶栏、Scaffold、TextureBlur、背景捕获、材质颜色、高光相关接口、动效、文字策略、输入逻辑、测试和分类文档。
- 上一轮完整周期日志确认：库静态分析通过、库 954 项测试通过、示例静态分析通过、示例 112 项测试通过，Release `1.2.1+30592000` 完成。这是上一周期证据，不是本轮尚未结束的发布结果。

### 初次对比时的 SDK 阻塞（已在后续升级中解除）

本轮在参考目录分别运行 Flutter analyze 和 Flutter test；两者退出码均为 1，发生在依赖解析阶段：本机 Dart **3.12.1**，对方要求 **^3.12.2**。因此没有完成参考库分析，也没有执行其测试用例；这不是测试断言失败，更不能据此评价组件质量。

日志保存在本项目工作区：

- [参考分析尝试](../artifacts/chuxinneko_20260908_analyze.log)
- [参考测试尝试](../artifacts/chuxinneko_20260908_tests.log)

初次对比没有放宽其 SDK 条件，也没有升级共用 Flutter。随后用户明确要求升级 Dart，已将 `C:\Code\_tools\flutter` 从 Flutter 3.44.1 / Dart 3.12.1 升级至 stable Flutter **3.47.2 / Dart 3.13.2**，框架提交 `d3b14c876900e553bc736ca19295fc09e3853e8e`，配套引擎 `a804b261645ef8c13eb3d5c44a5c2fb0340c5539`。参考项目原有 `^3.12.2` 条件现在已满足，重新执行的静态分析通过。没有构建或运行其 Android/Windows 示例，仍需按原提交、场景和设备进行真实画面对照。

后续升级验证已确认：参考项目静态分析无问题，**36 项测试全部通过**，两个命令退出码均为 0。验证使用原始源码与 SDK 约束，自动解析产生的锁文件和分析配置差异另存至工作区证据后恢复，参考克隆保持原提交干净状态。后续升级验证证据：

- [SDK 升级日志](../artifacts/dart_upgrade_20260908_completed.log)
- [环境检查](../artifacts/dart_upgrade_20260908_doctor.log)
- [参考项目重新分析](../artifacts/dart_upgrade_20260908_reference_analyze.log)
- [参考项目重新测试](../artifacts/dart_upgrade_20260908_reference_tests.log)
- [参考分析与测试退出码](../artifacts/dart_upgrade_20260908_reference_result.json)
- [新 SDK 完整 Release 周期](../artifacts/dart_upgrade_20260908_release_cycle.log)与[生成式发布清单](../releases/README.md)。

Flutter 官方升级流程同时更新配套 Dart，未单独替换 Dart 文件或放宽参考项目约束。Google 下载较慢时，本次进程临时采用 [Flutter 文档列出的 CFUG 镜像](https://docs.flutter.dev/community/china)，不永久修改系统镜像设置；下载归档校验值与 Google Storage 元数据一致，见[校验记录](../artifacts/dart_upgrade_20260908_archive_verification.json)。环境检查的 Android 与 Visual Studio 工具链通过；PATH 未配置和 Chrome 未找到为独立环境提示，不等同于 Android/Windows 构建失败。没有可用的本任务 Android 运行目标，不把 SDK、测试或构建成功等同于视觉验收。

因此，本报告中的架构与配方差异来自源码确认；对性能、触感及未复现的粗体测量问题只给出风险和验证建议，不给出跑分或视觉优劣结论。

### 本轮交付流程

本报告和关联文档定稿后按工作区要求执行完整 `tool/build_release_cycle.ps1`。本轮实际结果以 [发布日志](../artifacts/chuxinneko_comparison_20260908_release_cycle.log)、[生成式发布清单](../releases/README.md) 和交付消息为准。文档在构建前定稿，不预填成功结果。

Android 交付限 arm64-v8a Release、包名 `com.xinxin.miuix_flutter`，本地 Android Debug 证书仅供测试分发。Windows 为 x64 Release，并执行隐藏启动响应性检查。没有本轮 Android 设备运行或参考项目运行证明，不将 Windows 进程存活检查等同于视觉和性能验收。

## 10. 后续执行建议

**第一批：底栏默认入口、配方和接入说明统一。** 范围明确、直接影响所有业务应用；同步修复焦点呈现和独立操作语义，并维护现有兼容入口。

**第二批：顶栏状态与边缘材质。** 先按现有滚动模型确定状态约束，再处理慢拖/反向/短列表/页面恢复，最后验证渐进模糊在真实 Android 后端的取样与过渡。

**第三批：材质和动效模块提取。** 保持数值与行为进行结构调整，建立统一能力判断和局部绘制通道；后续校准另开明确变更，便于定位回归来源。

**第四批：字体策略、场景索引与参考运行对照。** 使用实际字体核查粗体测量；补查测试空白；用已满足条件的 SDK 运行参考示例，绑定 SDK 版本、提交、设备、场景、主题和截图。每批完成修改后仍按要求生成完整 Release 周期。

不建议本轮开始整体替换架构、增加新依赖或迁移到对方公开包。当前最有价值的方向是让已有能力更统一、更好接入，并让每个视觉结论都有可复核的运行证据。
