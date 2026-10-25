# 统一预测性返回

把 `MiuixBackGestureScope(enabled: value, child: ...)` 放在根 Navigator 外。
页面过渡、嵌套导航、对话框、底部浮层和菜单会在手势开始时读取该设置。
关闭只停用连续预览，普通返回仍使用现有导航逻辑。Android 返回桌面的动画由系统管理。
认证遮罩可设置 `blocked: true`，同时阻止页面与浮层的普通返回和手势提交。
这项保护与用户关闭动画不同，必须在路由内部注册 PopScope；根部观察者不能替代它。

普通页面使用 `MiuixNavigationPageTransitionsBuilder`；有返回值的页面可使用
`MiuixResultPageRoute<T>` 配合 `MiuixPageResult<T>`，避免通过 `canPop: false`
拦截系统返回后再补一次 pop。取消手势不读取或提交结果。

已有页内位置栈可使用 `MiuixBackHistory`，传入从来源到当前位置的稳定标识列表，
并在 `onBack` 中执行原有退栈。它只在位置变化时保留上一帧的内存图像，
不会创建另一份历史页面，不会写截图文件；单帧最多一百万像素，退出位置后释放。
没有完成首次绘制时不能提供预览，普通返回仍然工作。
子 Navigator 有可返回路由或页面正在保存时，应通过 `canPreview` 拒绝父层预览。
`handlesBack` 表示页内是否接管普通返回，根位置应设为 false。

系统授权窗口、输入法和宿主 Activity 不受该 Flutter 设置控制。
大标题可随字号和换行增加高度；透明标题栏后方的自定义正文可通过
`MiuixTopAppBar.preferredSizeFor(context)` 获取实际预留高度。
退出保护仍用 `PopScope` 提前声明，不能为了播放动画而绕过保存、认证或强制更新限制。
