# Flutter 页面共享转场

`MiuixSharedViewSource` 用于卡片到详情、图片到查看器等有明确来源的跳转。它在同一个 Flutter Navigator 内展开目标页面，返回时重新读取来源位置；来源已移除或离开窗口时使用淡出。

在 Navigator 的 `observers`（MaterialApp 为 `navigatorObservers`）中持有一个稳定的 `MiuixSharedViewObserver`，并使用 `MiuixNavigationPageTransitionsBuilder` 作为页面过渡主题。用来源控件的 `builder` 取得 `open`，在原点击回调中调用 `open(() => Navigator.of(context).push(...))`。普通 MaterialPageRoute 与 MiuixPageRoute 都由同一个过渡主题处理；弹窗、根页和 fullscreenDialog 不接管。

`open` 返回的 Future 只表示导航已派发。需要等到详情关闭才能处理结果时，在回调中保存 Navigator.push 返回的 Future，再单独等待它。异步数据准备应先完成，再调用 open，不能把旧来源留给网络请求之后的另一次导航。

视频与平台纹理设置 `captureImage: false`，只使用几何过渡。外部放大按钮可通过 `GlobalKey<MiuixSharedViewSourceState>` 调用图片来源的 `open`，不要把不相关标题和按钮一起作为来源。

图片按来源面积限制在约一百万像素，保存在内存，路由退出后释放。来源边界不替换原子树，列表滚动和编辑控制器继续由原页面管理。系统减少动态效果时不建立共享展开，保留普通导航。

## 与 Android SharedView Kit 的边界

本组件实现 Flutter 页面内的共享过渡，不包含金标联盟 SDK，也不宣称设备具备系统 Kit 能力。官方 SharedView Kit 使用 View 或 Bitmap 与 ActivityOptions，在支持的 ROM 上连接不同 Activity。单 Activity 内的 Flutter 路由没有这样的 Activity 边界。

需要跨 Activity 接入时，先按官方 API 查询运行时能力，不能只按手机品牌判断。Flutter 导航、系统认证、隐私锁、文件选择与权限窗口不应为动画而拆分或替换。官方示例与接口说明见 https://gitee.com/itgsa_sharedviewkit/SharedViewDemo 。

## 验证

`test/shared_view_transition_test.dart` 覆盖展开、来源原位、左右手势、反复取消、提交、来源失效和无关导航；`test/navigation_physical_back_test.dart` 继续覆盖普通横向路由的方向。手机和平板都检查正常及 200% 字号。测试平台消息不等同于厂商 ROM 真机验收。
