# flutter_miuix workspace rules

## HyperOS 4 design baseline

- 后续新增、重做和视觉修复默认以 `doc/HYPEROS4_OFFICIAL_APP_DESIGN_SPEC_ZH.md` 为设计与验收基线，不再以当前示例外观或旧版 MIUIX 视觉作为目标。
- 现有公共 API 尽量保持兼容，但默认视觉应逐步迁移到 HyperOS 4；旧样式仅在确有迁移需求时通过明确的 legacy 选项保留，不能继续作为新组件默认值。
- HyperOS 4 能力必须实现在 `lib/` 组件库中，示例程序只承担展示和回归验证，不得只修改示例造成“已经支持”的假象。
- 小米官网未公开的 dp、字号、动效曲线和材质数值不得凭空称为官方参数；必须用官方画面比例、真机行为和运行截图校准，并标为项目推导值。
- 官网明确说明、官网画面观察和网络传闻必须分开处理。未经官方确认的控制中心布局、全量 2.5D 图标等说法不能成为默认规范。

## Release discipline

- 每轮完成代码、资源、构建配置或开发文档修改后，在交付本轮结果前必须生成一个新的完整 Release 周期。
- Release 脚本自身写回的 `versionCode`、哈希、检查点和生成式发布清单属于同一周期的输出，不触发递归的第二次 Release；其后的人工源码或文档修改才开始下一周期。
- 完整 Release 周期必须使用 `tool/build_release_cycle.ps1`，同时生成 Android `arm64-v8a` Release APK、Windows x64 Release ZIP，以及 Android/Windows 两份可复用 `flutter_miuix` 库包；禁止用 Debug 或 Profile 产物代替。
- Android 与 Windows 必须共用 Android APK 验证后的单调递增 `versionCode` 作为本轮构建号。稳定文件名始终覆盖为最新产物，带构建号的文件作为可追溯检查点。
- 每个平台和产物族只保留最近 3 个带构建号的 Release 检查点。不带构建号的稳定文件只是最新版别名，不计入这 3 个历史检查点；旧版稳定别名只保留最新一份。
- 只有 Android、Windows、库包、签名/架构检查和 SHA-256 全部成功后，才允许运行 `tool/prune_release_checkpoints.ps1` 删除旧包。任一步失败都必须保留现有 Release，不得把半成品称为发布包。
- 删除包时必须同时删除它的校验侧车文件，并确认目标是 `releases` 的直接子文件。不得递归删除目录，不得清理 `artifacts/parity` 中的验证证据。
- 每轮交付必须报告最新 Android/Windows/库包的绝对路径、构建号、SHA-256、签名边界和本轮实际验证结果。

## Build targets

- Android 仅构建 Release `arm64-v8a`，包名保持 `com.xinxin.miuix_flutter`；当前本地 Android Debug 证书只可用于测试分发，不能描述为生产签名。
- Windows 仅构建 Release x64，并在封装前对生成的 EXE 做一次隐藏启动响应性检查，随后主动关闭该进程。
- Android 运行验证只操作本任务明确拥有的设备或模拟器；没有合适目标时仍需完成静态 ABI、包名、版本号和签名检查，并如实说明运行验证边界。
