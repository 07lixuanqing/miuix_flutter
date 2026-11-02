import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 验证真实组件输出的镜片，而非在测试中重新实现默认配方。
// 两种画布都覆盖；文字不应随半透明镜片降低Alpha。
// 本测试只验证绘制角色，不替代已有的往返拖动与返回手势测试。
// 公共组件与应用宿主可以分别提供配色，默认路径也必须可辨。
// 配色固定为人工样本，不读取壁纸、账号或设备上的主题偏好。
// 视觉基线覆盖完整构图；这里另外约束选中与未选中的状态差异。
void main() {
  // 每种模式重新建立完整组件树，避免上一模式的Theme被复用。
  // 明暗模式使用相同种子，测试差异只能来自画布与正式组件。
  for (final dark in [false, true]) {
    testWidgets('floating selection remains distinct on neutral card: $dark', (
      tester,
    ) async {
      // 使用浅橙种子，复现近白选中镜片难以辨认的情况。
      // 不安装宿主颜色扩展，确保检查的是公共组件的默认路径。
      final scheme = ColorScheme.fromSeed(
        // 最终primary保持原橙色，不让莫奈派生后的深色掩盖浅种子问题。
        // 其余语义槽位仍由标准方案提供，避免人为拼出异常画布。
        seedColor: const Color(0xffffa726),
        brightness: dark ? Brightness.dark : Brightness.light,
      ).copyWith(primary: const Color(0xffffa726));
      Future<void> mount({Color? override}) async {
        // 显式覆盖与默认路径共用同一组件树，避免比较不同绘制控件。
        // 每次等待动画稳定，过渡帧不作为最终颜色。
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorScheme: scheme),
            home: MiuixTheme(
              // 不传颜色扩展，组件必须沿没有宿主角色的兼容路径绘制。
              // 默认主题保留实际圆角和玻璃效果，不把组件替换成测试色块。
              data: MiuixThemeData.defaults(),
              child: Scaffold(
                body: MiuixFloatingNavigationBar(
                  selectedBackgroundColor: override,
                  selectedIndex: 0,
                  // 保持可操作状态；空的回调不会令选项进入禁用样式。
                  // 这里只读取稳定绘制，点击提交和拖动由专门回归负责。
                  onSelected: (_) {},
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: '首页'),
                    MiuixNavigationItem(icon: Icon(Icons.task), label: '任务'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      Color lensColor() {
        // 读取最终ShapeDecoration，包含宿主优先级和组件实际透明度。
        // 从公开的选中镜片节点向下找，不能误取外壳的玻璃背景。
        // 不直接依赖组件私有状态，因此可发现实际绑定漏传的情况。
        final lens = find.byKey(
          const ValueKey('floating-navigation-selection-indicator'),
        );
        final box = tester.widget<DecoratedBox>(
          find.descendant(of: lens, matching: find.byType(DecoratedBox)).first,
        );
        return (box.decoration as ShapeDecoration).color!;
      }

      // 第一次挂载验证默认配方；第二次挂载才验证显式覆盖。
      // 两种契约分开断言，不能通过强制所有调用使用同一种颜色来修复。
      await mount();
      final lens = lensColor();
      // 状态背景至少明显区别于中性卡片；这不是正文的可读性阈值。
      // 合成后再测量可发现RGB增强但Alpha仍过低的退化。
      final visible = Color.alphaBlend(lens, scheme.surface);
      final a = visible.computeLuminance(),
          b = scheme.surface.computeLuminance();
      // 明暗两种方向都允许，但状态差异必须达到同一最低要求。
      // 阈值是本项目的辨识约束，不宣称为正文的无障碍标准。
      expect(
        (a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05)),
        greaterThanOrEqualTo(1.20),
      );
      expect(lens.a, lessThan(1));
      // 完整保留半透明属性，不能用不透明色块换取对比度通过。
      // 使用者显式指定的镜片不得被默认增强配方二次调色。
      const explicit = Color(0x99cc8800);
      await mount(override: explicit);
      expect(lensColor(), explicit);
      // 框架异常单独收集，颜色正确不能掩盖布局或绘制失败。
      expect(tester.takeException(), isNull);
    });
  }
}
