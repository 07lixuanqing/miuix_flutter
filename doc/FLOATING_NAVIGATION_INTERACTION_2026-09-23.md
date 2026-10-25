# Floating navigation interaction / 悬浮导航交互

Updated 2026-10-03 / 更新于 2026-10-03

- Separate panel opacity, selected fill, and foreground colors through optional public properties. Existing callers keep their defaults.
- 通过可选公开参数独立控制面板透明度、选中填色和前景色；既有调用保留默认值。
- Default callers share a surface-colored panel and a lightly tinted translucent lens. Selected text preserves the theme hue while adjusting lightness for contrast against black/white backdrop bounds; resting text uses the surface-variant foreground. Application styles need not add opaque selection layers or glyph shadows.
- 默认共用表面色面板与轻染色透明镜片，选中文字保留主题色相、通过明度调整覆盖黑白背景边界；未选中使用表面次级前景色。应用主题无需另加厚选中底或字形衬影。
- Lens position and text emphasis share continuous progress. A nonselected pickup bridges the old lens to the finger over 90 ms, once per gesture; later pointer samples track directly. Release commits the nearest actual slot and settles with one damped spring; velocity never changes the destination. Cancellation restores the committed selection.
- 镜片位置和文字强调共享连续进度；从未选中项起拖时用一次 90ms 衔接接住手指，后续触点直接跟随。松手提交实际最近槽位，再执行一次阻尼弹簧吸附，速度不改变目标；取消恢复原选中项。
- Remove speed-driven stretch and progress-driven icon scaling. Selected artwork follows the same lens progress as tint, displaying one outline at a time without a separate transition. Press contraction, settling and artwork changes respect reduced motion.
- 去掉速度驱动拉伸和进度驱动图标缩放。选中图形与颜色跟随同一镜片进度，每帧只显示一套轮廓，不额外叠加切换动画；按压收缩、吸附和图标切换遵守减少动态效果设置。
- LoveStory retains mounted destination pages and fades old content out for 70 ms, switches the title and visible destination together, then reveals the destination over 150 ms. Rapid taps resolve to the latest request without traversing intermediate pages.
- LoveStory 保留页面实例，标题与正文用同一进度 70ms 淡出、150ms 淡入最终目标。连续点击以最新请求为准，不依次展示中间页面。
- Shadow excludes the capsule interior; blur and tint are independently configurable to avoid a gray panel.
- 阴影排除胶囊内部，模糊和染色独立配置，避免面板发灰。

The LoveStory validation fixture reuses its production wrapper and this library. Widget checks cover drag preview, cancellation, fast release, RTL/reduced motion and contrasting theme seeds. Widget-rendered screenshots cover light/dark and busy backgrounds. These are not evidence of physical-device frame-rate performance.

LoveStory 验证场景复用生产封装和组件库。控件测试覆盖拖动预览、取消、快速松手、RTL/减少动态效果及不同主题色；控件渲染截图覆盖明暗模式和复杂背景；这些截图不能证明真机帧率。

Release-gate repairs: calendar cells now adapt to finite height with a 44 dp minimum and scrolling fallback; compact date picker uses 48 dp and the range picker retains 44 dp. Range endpoints retain solid selection and interior text respects rangeForeground. These repair existing tests without replacing date-range reference images.

发布检查修复：日历单元适应有限高度，最低 44 dp，不足时滚动；紧凑日期选择器使用 48 dp，日期范围维持 44 dp。范围端点保留实色选中，内部文字遵守 rangeForeground。修复既有测试且不替换日期范围参考图片。

All motion/material numbers above are project tuning, not official Xiaomi specifications. Run tool/build_release_cycle.ps1 for full analysis/tests and Android/Windows/library packaging evidence.

上述动效和材质数值为项目调校值，并非小米官方参数。完整分析、测试及 Android/Windows/库包证据由 tool/build_release_cycle.ps1 生成。

2026-10-13：拖动选中背景增加有上限的速度形变，中心仍逐帧跟随触点，不改变命中区。停住或松手后形变自然衰减；吸附弹簧调整为轻微回弹，点击连续切换仍从当前视觉位置接续。边缘形变对称受限，镜片不会越界或被挤离触点。减少动态效果和 selectionDuration=Duration.zero 时不执行形变或吸附动画。参数为项目调校值，不是官方公开规范。
