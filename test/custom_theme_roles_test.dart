import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 人工显式方案不调用莫奈生成器，用于隔离固定模式的语义映射。
MiuixThemeData rawTheme(Color color, Color foreground, Brightness brightness) {
  // 固定明暗模式验证旧语义表与显式方案的边界，不借 Monet 模式绕过问题。
  final base = MiuixThemeData.defaults(
    mode: brightness == Brightness.dark
        ? MiuixColorMode.dark
        : MiuixColorMode.light,
  );
  // 只替换调用方提供的角色，旧原生默认仍保持原契约。
  ColorScheme colors(ColorScheme scheme) =>
      scheme.copyWith(primary: color, onPrimary: foreground);
  return base.copyWith(
    seedColor: color,
    // 显式开启后只映射已经提供的方案，不生成新的主色。
    useSchemeSemanticColors: true,
    lightScheme: colors(base.lightScheme),
    // 两套角色均覆盖，防止切暗后露出原生默认蓝色。
    darkScheme: colors(base.darkScheme),
  );
}

// 本组回归的覆盖边界：
// 固定模式本身不要求生成器参与，因此应允许调用方提供完整角色。
// 旧调用没有显式选择时仍使用原来的语义表。
// 新字段是选择语义来源的契约，不是让主题自动检测颜色是否被修改。
// controller.setMode 会重新组装主题，是丢失这个选择的高风险入口。
// copyWith 和 lerp 分别覆盖静态派生与主题动画两条路径。
// 测试通过公开入口进入，不直接改写控制器的私有成员。
// 每个控制器独立释放，不共享前一个案例的方案。
// 侧栏测试使用前景与背景成对输入，不能只修图标颜色。
// 背景颜色精确传入，调用方不需要为了可读性自己再次调色。
// 普通侧栏与可展开侧栏内部绘制不同，必须分别验收。
// 标题文字跟随相同前景，背景应覆盖图标和全文。
// 折叠状态有宽度限制，长中文必须通过增高换行处理。
// 展开状态则允许利用新增宽度，不能沿用折叠时的一行裁剪。
// 标准字号通过其他布局组覆盖，本组集中检查 200% 压力。
// 系统文字缩放通过平台事实进入，不在文本样式里伪造字号。
// 物理窗口和设备像素比分开设置，确保逻辑宽度可复现。
// 360 宽度对应小窗口，1280 宽度对应平板横向布局。
// 图标使用不同形状，读取选中项不会误取未选中的任务图标。
// 第一项长中文与第二项短标签同时存在，保留实际列表结构。
// 没有额外的页面颜色覆盖，观测值来自库自身主题继承。
// primary 和 onPrimary 明暗成对提供，避免混用另一套角色。
// 橙黄覆盖实际用户场景，湖蓝覆盖非暖色输入。
// 灰色覆盖中性原色，黑白覆盖前景反转边界。
// 文字检查读取渲染对象，不能只靠 finder 找到原始 Text。
// didExceedMaxLines 检测显式裁剪，选区边界检测横向越界。
// 段落尺寸必须包含末行，避免卡片高度固定后遮住后半段。
// 选区非空检查可防止空段落让循环无条件通过。
// 浮点布局仅接受一像素误差，不允许隐藏一个汉字的宽度。
// 状态变化后等待动画结束，测量对象仍来自同一个已挂载页面。
// 展开后收回可发现测量缓存沿用宽屏结果的问题。
// 不重新 pump 新侧栏绕过收回时的真实生命周期。
// 不发点击事件，选择保持稳定以隔离颜色和排版。
// 若主题或布局抛错，takeException 断言必须让用例失败。
// 组件卸载先于状态控制器释放，避免释放时误报监听器错误。
// 这里验证 Flutter 绘制契约，不替代厂商桌面或系统设置验收。
// 全部色值与标签均为人工数据，不需要登录或设备权限。
// 测试新增接口没有强制旧调用改参数，兼容性由其他默认案例覆盖。
void main() {
  test(
    'explicit scheme semantics survive controller copy and brightness changes',
    () {
      // 直接 setTheme 后再变更明暗，不能恢复成固定蓝色语义表。
      final theme = rawTheme(
        const Color(0xffffa726),
        Colors.black,
        Brightness.light,
      );
      final controller = MiuixThemeController();
      // 通过公开控制器入口替换，覆盖内部重建时丢失标记的回归。
      controller.setTheme(theme);
      controller.setMode(MiuixColorMode.dark);
      // 控制器重新构建仍须保留调用方已明确选择的语义来源。
      final data = controller.data.materialTheme(Brightness.dark);
      expect(
        data.extension<MiuixSemanticColors>()!['primary'],
        const Color(0xffffa726),
      );
      // 复制不能仅保留 ColorScheme 而遗失语义来源开关。
      expect(theme.copyWith().useSchemeSemanticColors, isTrue);
      // Theme 动画终点不能遗失新字段。
      expect(theme.lerp(theme, 1).useSchemeSemanticColors, isTrue);
      controller.dispose();
    },
  );

  // 极端亮度也要验证配对颜色；所有值是调用方已确定的绘制事实。
  for (final pair in [
    (const Color(0xffffa726), Colors.black),
    (const Color(0xff1aa7a1), Colors.black),
    (const Color(0xff808080), Colors.black),
    // 白色背景需要黑字，不能用深色主色的默认白字。
    (Colors.white, Colors.black),
    // 黑色背景需要白字，标签必须完整落在背景覆盖区。
    (Colors.black, Colors.white),
  ]) {
    for (final brightness in Brightness.values) {
      for (final expanded in [false, true]) {
        testWidgets('explicit rail $pair $brightness expandable=$expanded', (
          tester,
        ) async {
          // 窄屏和宽屏使用同一侧栏约束，200% 字号不得缩小或截断。
          tester.view.physicalSize = expanded
              ? const Size(1280, 900)
              : const Size(360, 800);
          // 固定像素比只隔离尺寸，系统文字缩放依然真实进入布局。
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          // null 测试普通侧栏，非空测试真实展开控制器，不能只替换宽度模拟。
          final state = expanded ? MiuixNavigationRailState() : null;
          addTearDown(() => state?.dispose());
          // 标签长度超过折叠侧栏一行，必须实际产生多行布局。
          const label = '需要完整阅读的中文导航目的地';
          final theme = rawTheme(pair.$1, pair.$2, brightness);
          await tester.pumpWidget(
            MaterialApp(
              // 复用真实库主题，不手工补造组件内部的语义扩展。
              home: MiuixTheme(
                data: theme,
                child: Scaffold(
                  body: Row(
                    children: [
                      MiuixNavigationRail(
                        items: const [
                          MiuixNavigationItem(
                            icon: Icon(Icons.home),
                            label: label,
                          ),
                          MiuixNavigationItem(
                            icon: Icon(Icons.task),
                            label: '任务',
                          ),
                        ],
                        state: state,
                        // 选中第一项后从实际图标上下文读取前景，不只检查构造参数。
                        selectedIndex: 0,
                        selectedContentColor: pair.$2,
                        selectedBackgroundColor: pair.$1,
                        // 点击不切换状态，让每个颜色案例保持相同选中目的地。
                        onDestinationSelected: (_) {},
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // 观察实际图标上下文，不能只比较传入参数。
          expect(
            IconTheme.of(tester.element(find.byIcon(Icons.home))).color,
            pair.$2,
          );
          // 每次检查实际 RenderParagraph 全文布局，而非仅检查原始字符串。
          void readable() {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(label),
            );
            expect(paragraph.didExceedMaxLines, isFalse);
            final boxes = paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: label.length),
            );
            // 空测量结果不能被误当成没有溢出的成功状态。
            expect(boxes, isNotEmpty);
            // 全部文字框必须落在测量区域内，避免多行文字被固定高度遮住。
            for (final box in boxes) {
              expect(box.left, greaterThanOrEqualTo(-1));
              // 允许一个像素的浮点舍入，不能放宽到隐藏整段文字。
              expect(box.right, lessThanOrEqualTo(paragraph.size.width + 1));
              expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 1));
            }
          }

          readable();
          if (state != null) {
            // 展开、收回分别检查，不能只验证一个稳定端点。
            state.expand();
            await tester.pumpAndSettle();
            readable();
            state.collapse();
            await tester.pumpAndSettle();
            readable();
          }
          // 所有布局与绘制错误都应使测试失败。
          expect(tester.takeException(), isNull);
          // 卸载后再由 teardown 释放外部控制器，避免对已释放监听器发通知。
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
