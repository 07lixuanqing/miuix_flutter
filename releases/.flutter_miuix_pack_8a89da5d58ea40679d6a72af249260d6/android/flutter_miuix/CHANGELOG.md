# Changelog

## 1.0.9

- 将公开包名确定为 `flutter_miuix`，新增标准入口 `flutter_miuix.dart`。
- 保留旧的 `miuix_flutter.dart` 文件入口作为迁移兼容层。
- 增加 Android 自动注册插件，提供 MIUIX 震动角色的原生映射。
- 支持 Android 和 Windows 的字体、图标、着色器及玻璃效果打包。
- 修复颜色选择器、二维调色板、模糊控制和外层分页之间的手势冲突。
- 修正颜色输入框的单行 HEX 前缀、RGBA 数值格式与原版示例不一致的问题。
- 隔离嵌套标签分页与主页滚动状态，避免首次滚动后错误恢复到最后一个标签。
- 补充 Android、Windows、主题和常用组件中文接入文档。
