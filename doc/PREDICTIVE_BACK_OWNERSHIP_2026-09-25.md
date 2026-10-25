# 嵌套导航与弹窗的返回手势归属（2026-09-25）

Flutter 会把同一次 predictive Back 分发给所有接受手势的 WidgetsBindingObserver。原先页面转场没有加入 MIUIX 的归属仲裁，因此外层弹窗与内层 Navigator 的当前页面可能同时响应，导致弹窗下面的编辑页被返回。

页面转场现与 Dialog、BottomSheet、Popup、NavDisplay 和公开 BackHandler 共用仲裁。候选者必须处于启用的 TickerMode 和可见导航分支；检查自身以及各级 Navigator 所属路由是否 current。一次开始事件只选定一个处理者，避免开始动画改变资格后出现第二个处理者。Dialog 同时遵循 PopScope 的禁止返回约束。

新增 `test/predictive_back_ownership_test.dart`，覆盖普通 MIUIX 弹窗、Material 弹窗、叠加弹窗、路由/Overlay 底部面板、窗口/Overlay 菜单、禁止关闭的弹窗、缓存隐藏 Navigator 共 9 项，验证取消、完成、下一次返回以及底层页面动画不被推进。

测试中的 MiuixTheme 内部显式安装 MiuixNavigationPageTransitionsBuilder，与 LoveStory 的真实集成一致。Flutter 默认转场不参与此 MIUIX 注册表；对本库之外的自定义 WidgetsBindingObserver，不宣称可仲裁其行为。

LoveStory 的“添加一级分类”真实页面回归在修改前确认 predictive Back 错误销毁编辑页，修改后保留编辑页和输入金额。测试通过 flutter/backgesture 平台消息模拟手势，尚未进行 Android 真机侧滑验证。完整 Release 验证与产物以构建脚本生成的发布清单为准。
