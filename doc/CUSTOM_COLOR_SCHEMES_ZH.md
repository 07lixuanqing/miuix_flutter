# 显式配色与导航选中态

`MiuixThemeData.useSchemeSemanticColors` 允许固定明暗模式使用调用方的 `ColorScheme`，无需启用 Monet。默认值为 false，原有固定 MIUIX 色表保持兼容。这个字段只选择语义角色来源，不运行或关闭调色算法；原色模式应配合 `light`、`dark` 或 `system` 模式，并提供完整明暗方案。

`copyWith`、主题插值和控制器 `setTheme` 后的明暗切换都保留该字段。语义角色由实际绘制方案映射，不能出现背景已经换色、按钮文字却继续读取默认蓝色方案的情况。

普通 `MiuixNavigationRail` 新增 `selectedContentColor` 和 `selectedBackgroundColor`。调用方应传入配对前景和填充，例如最终方案的 `onPrimary`、`primary`；不传时沿用既有默认。背景覆盖完整选中单元，包括标签，避免白字在胶囊外落到白色画布。

展开式侧栏同样沿用该颜色对。长标签自然换行，测量与实际文字使用同一个系统 TextScaler；短标签的既有默认几何不变。Source 兼容构造器不开放新的覆盖参数，保留其原生色表语义。

`test/custom_theme_roles_test.dart` 覆盖固定模式语义映射、控制器明暗切换、5 种颜色、明暗模式、展开/收回及 200% 字号长中文。框架回归不能代替厂商设备验收，完整 Release 周期另由 `tool/build_release_cycle.ps1` 生成和校验。
