# Android 集成说明

## Release 签名

仓库的完整 Release 周期有意生成使用本地 Android Debug 证书的测试分发 APK。
PowerShell 构建脚本会显式启用该回退；直接执行 Gradle 或 Flutter Release 构建则默认
关闭签名回退并立即失败。

生产签名需要设置以下四个进程环境变量，然后运行：

```powershell
$env:MIUIX_RELEASE_KEYSTORE = 'C:\secure\miuix-release.jks'
$env:MIUIX_RELEASE_STORE_PASSWORD = '<store password>'
$env:MIUIX_RELEASE_KEY_ALIAS = '<alias>'
$env:MIUIX_RELEASE_KEY_PASSWORD = '<key password>'
.\tool\build_android_arm64_release.ps1 -ProductionSigning `
  -ExpectedCertificateSha256 '<certificate SHA-256>'
```

脚本不会把这些值写入仓库；配置不完整、keystore 不存在、最终签名仍为 Debug，或证书
摘要与可选固定值不一致时都会失败。

## 真机帧时序门禁

连接已安装示例应用的 ARM64 真机后，可运行：

```powershell
.\tool\verify_android_frame_timing.ps1 -DeviceId '<adb serial>'
```

脚本会重置 `gfxinfo`、启动应用、重复切换底部 Tab，再校验有效帧数、卡顿帧比例和
95 分位帧耗时，并把原始证据保存在 `artifacts/parity/performance_*`。默认拒绝 x86、
非 ARM64 和模拟器；`-AllowArm64EmulatorDiagnostic` 只用于诊断，不代表真机验收。

## 系统返回手势

`flutter_miuix` 的叠加对话框、底部弹层和下拉菜单使用 Flutter
`PopScope`，会先关闭最上层弹层，再允许页面或 Activity 退出。库清单已自动合并
`android:enableOnBackInvokedCallback="true"`，以支持 Android 13 及以上的
返回回调和预测性返回。

如果主应用的 `AndroidManifest.xml` 显式把这个属性设成了 `false`，主应用清单的
优先级会覆盖组件库。请删除该覆盖，或在 `<application>` 上改回：

```xml
<application
    android:enableOnBackInvokedCallback="true"
    ... />
```

否则在较新的 Android 系统上，系统返回可能直接退出 Activity，而 Flutter
弹层收不到关闭事件。

## 工程要求

- `minSdk` 不低于 21
- 建议 `compileSdk` 36
- Java/Kotlin JVM target 17
- Android arm64 构建目标为 `arm64-v8a`

库自带 `FlutterMiuixPlugin`。应用引用包后，Flutter 会自动注册插件，无需在 `MainActivity` 中手写 MethodChannel。开关、选择器、Slider、菜单和确认操作会尽量映射到 Android 对应的 `HapticFeedbackConstants`；旧系统自动降级到最接近的震动角色。

## 系统栏与手势导航

建议在应用启动时启用 edge-to-edge：

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const App());
}
```

应用应保留 `SafeArea`/`MediaQuery` 的系统 inset。`MiuixTopAppBar` 和底部导航默认处理自身系统栏安全距离；使用悬浮底栏时设置 `MiuixScaffold.extendBody: true`，不要再给整个页面增加固定的底部白色占位。

Android 插件会把 `WindowInsets.Type.navigationBars()` 与
`WindowInsets.Type.captionBar()` 分开传给组件。普通底栏把 navigation inset 放在
64dp 内容行之后；悬浮底栏在非零 navigation inset 之上再保留 26dp。caption bar
出现或消失时，两种底栏都按原版以 300ms 线性动画调整位置，不会把输入法高度误当成
导航栏高度。这个通道会自动注册，业务应用无需添加平台代码。

将组件的 `defaultWindowInsetsPadding` 设为 `false` 会关闭原版由该参数控制的
caption inset；普通底栏也会同时移除 navigation inset。悬浮底栏自身的 26dp/36dp
屏幕边缘位置是组件几何的一部分，和原版一样不会被这个参数关闭。

## 构建

为保证测试 APK 可以连续覆盖安装，请从仓库根目录使用统一脚本。脚本会自动生成
单调递增的 `versionCode`、沿用当前工程签名、检查最终包名和签名，并把产物复制到
`releases`。成功构建后还会把最终 APK 的实际 `versionCode` 记录到示例
`pubspec.yaml`，因此后续直接运行普通 Flutter 构建也不会回落到旧版本号：

```powershell
.\tool\build_android_arm64_release.ps1
```

需要直接覆盖安装到已连接的设备、同时保留应用数据时：

```powershell
.\tool\build_android_arm64_release.ps1 -Install
```

Android 只有在包名相同、签名证书相同且新包 `versionCode` 不低于已安装版本时才
允许覆盖。若设备上曾安装过其他证书签名的同包名 APK，任何构建参数都无法跨证书
覆盖，只能卸载旧应用，或重新使用旧应用的签名证书构建。

至少成功运行过一次上述统一脚本后，不需要生成可分发测试包时，也可以直接运行
Flutter 命令：

```powershell
flutter build apk --release --target-platform android-arm64
```

商店发布通常使用 AAB：

```powershell
flutter build appbundle --release --target-platform android-arm64
```

正式应用必须在自己的 Android 工程中配置生产签名。库本身不包含也不应分发应用签名密钥。
