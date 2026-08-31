# Windows 集成说明

## 工程要求

安装 Visual Studio，并勾选“使用 C++ 的桌面开发”以及 Windows SDK。然后执行：

```powershell
flutter config --enable-windows-desktop
flutter doctor -v
```

Windows 使用与 Android 相同的 Dart 组件、字体和着色器。Android 原生插件目录会被 Flutter 自动忽略，不需要删除。Windows 设备通常没有手机式线性马达，因此震动 API 使用 Flutter 的安全回退，不影响交互。

## 窗口尺寸

页面应通过 `LayoutBuilder` 或 `MediaQuery.sizeOf(context)` 响应窗口变化。窄窗口可以使用底部 NavigationBar，宽窗口建议切换到 `MiuixNavigationRail`。弹层和下拉菜单会根据可用窗口区域自动约束。

## 构建与分发

```powershell
flutter build windows --release
```

分发时需要复制整个目录，而不是只复制 EXE：

```text
build/windows/x64/runner/Release/
```

该目录中的 `flutter_windows.dll`、`data` 和插件 DLL 都是应用运行所需文件。
