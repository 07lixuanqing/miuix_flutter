import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 人工角色与主色故意不同，用来发现控件偷偷恢复完整主按钮背景。
// 库测试只验证角色传输，应用的取色和对比度算法由 Rust 回归覆盖。
// 测试色全部是公开常量，不读取真实用户主题或壁纸。
// 主色、镜片、文字刻意设成不同值，检测角色是否被接错。
// 库只测试显示契约，应用的取色算法另由 Rust 验证。
// 颜色不相等不代表失败，关键是不同用途采用正确配对。
// 镜片和面板分别检查，避免只降低其中一个透明度。
// 双倍字号使用实际布局，不通过整体缩放截图验收。
// 旧构造没有扩展时仍由完整库回归验证兼容。
// 回调在实际目的地区域触发，不直接调用私有函数。
// 字体大小来自 MediaQuery，而不是临时改小字号。
// 所有状态均来自人工本地控件，不访问服务端。
MiuixAccentLayers fixture() => MiuixAccentLayers(
  navigationPanelOpacity: .46,
  colors: {
    // 无实色底的文字与主按钮前景分开提供。
    // 这样可发现控件直接复用 onPrimary 的错误。
    'accentForeground': const Color(0xff764800),
    // 镜片带 Alpha，不能成为不透明 primary 副本。
    // 真实透色必须保留在最终装饰上。
    'navigationFill': const Color(0x88fff3df),
    // 文字与镜片的 Alpha 独立。
    // 图标与文字消费同一个前景角色。
    'navigationForeground': const Color(0xff503000),
    // 筛选使用普通轻选中层。
    // 它与导航材质采用不同的浓度。
    'selectionFill': const Color(0xffffeed4),
    // 普通选择有独立的配对前景。
    // 同主题不代表所有位置都用白字。
    'selectionForeground': const Color(0xff754600),
    // 说明衬底更轻。
    // 它不承担活动进度或主操作反馈。
    'subtleFill': const Color(0xfffff7e9),
    // 辅助强调同样成对。
    // 这些字段参与完整快照复制检查。
    'subtleForeground': const Color(0xff805000),
    // 边界只承担弱结构标记。
    // 透明值可以暴露错误的不透明转换。
    'outline': const Color(0x38ffa726),
    // 选区是覆盖背景。
    // 测试不改真实用户输入。
    'textSelection': const Color(0x38ffa726),
    // 未选轨道保留完整可操作范围。
    // 它不能和活动主色等重。
    'inactiveTrack': const Color(0xffffe9c8),
    // 禁用背景中性化。
    // 对应前景不能继续沿用按钮白字。
    'disabledFill': const Color(0xffededed),
    // 禁用前景参与复制与动画。
    // 不根据颜色推断业务可操作性。
    'disabledForeground': const Color(0xff999999),
  },
);

// 长标题与短标题同时出现，覆盖共同高度而非逐项独立膨胀。
// 最大字重用于测量，避免选中动画触发突然换行。
// 系统字号必须作用于真实字形，不能只扩大点击区域。
// 不允许固定单行后把原文藏在语义标签中。
// 不允许整体缩小标签来适配既定宽度。
// 文字底边必须落在所属目的地内部。
// 底栏颜色改变不能移动命中位置。
// 所需高度由内容决定，不能靠增加测试屏幕高度通过。
// 插值端点应保留调用方的精确颜色对象。
// 输入 Map 的后续变化不得影响已经绘制的扩展。
// 未提供新扩展的默认控件仍由全库兼容测试覆盖。
// 本文件的颜色常量仅为测试资料，不是厂商设计参数。
void main() {
  test(
    'accent layers are immutable and copy and interpolate complete pairs',
    () {
      // 修改调用方 Map 不能在没有主题更新的情况下改变屏幕颜色。
      // 先复制输入再修改原 Map。
      // 检查构造器是否隔离可变引用。
      final colors = {...fixture().colors};
      final first = MiuixAccentLayers(
        colors: colors,
        navigationPanelOpacity: .46,
      );
      colors['navigationFill'] = Colors.red;
      expect(first.navigationFill, fixture().navigationFill);
      // copyWith 保留所有未覆盖角色，不能丢掉与新底色配对的前景。
      // 只覆盖指定绘制槽位。
      // 其他成对角色必须保留。
      final last = first.copyWith(
        colors: {'navigationFill': Colors.blue},
        navigationPanelOpacity: .6,
      );
      expect(first.navigationPanelOpacity, .46);
      expect(last.selectionForeground, first.selectionForeground);
      // 插值端点必须完整还原，不只比较一项颜色。
      expect(first.lerp(last, 0).colors, first.colors);
      expect(first.lerp(last, 1).colors, last.colors);
      expect(first.lerp(last, .5).navigationPanelOpacity, closeTo(.53, .0001));
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'shared accent layers reach controls and live navigation $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 850);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        // 每种字号独立创建主题。
        // 不能复用前一尺寸的膨胀布局。
        final layers = fixture();
        final selected = <int>[];
        // 读取正式后代上下文。
        // 不能在主题注入前查询默认颜色。
        late BuildContext context;
        // 主色保留橙色，选中镜片则必须是另一种透明浅衬底。
        // 使用正式主题宿主。
        // 不以假工厂代替通用组件。
        final data = MiuixThemeData.defaults(mode: MiuixColorMode.light);
        // 扩展注入实际 Material Theme。
        // 各控件消费相同快照。
        final theme = data
            .materialTheme(Brightness.light)
            .copyWith(extensions: [layers]);
        // 完整建树后读取绘制。
        // 检查工厂与控件真实接线。
        await tester.pumpWidget(
          MiuixTheme(
            data: data,
            child: MaterialApp(
              theme: theme,
              builder: (c, child) => MediaQuery(
                data: MediaQuery.of(
                  c,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Builder(
                builder: (c) {
                  context = c;
                  return Scaffold(
                    body: Center(
                      child: MiuixFloatingNavigationBar(
                        items: const [
                          MiuixNavigationItem(
                            icon: Icon(Icons.home),
                            label: '首页与每日运动健康',
                          ),
                          MiuixNavigationItem(
                            icon: Icon(Icons.task),
                            label: '任务',
                          ),
                          MiuixNavigationItem(
                            icon: Icon(Icons.person),
                            label: '我的',
                          ),
                        ],
                        selectedIndex: 0,
                        onDestinationSelected: selected.add,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 工厂是实际控件共同使用的入口，不能只给导航加应用侧颜色参数。
        expect(
          MiuixChipDefaults.colors(context).selectedBackground,
          layers.selectionFill,
        );
        expect(
          MiuixSegmentedControlDefaults.colors(context).selectedForeground,
          layers.selectionForeground,
        );
        expect(
          MiuixTabRowDefaults.tabRowColors(context).selectedBackgroundColor,
          layers.selectionFill,
        );
        // 可用按钮仍为强色，禁用按钮才改为中性层。
        expect(
          MiuixButtonDefaults.buttonColorsPrimary(context).disabledColor,
          layers.disabledFill,
        );
        // 精确定位面板材质。
        // 不把外层透明布局当作玻璃。
        final glass = tester.widget<MiuixGlass>(
          find.byKey(const ValueKey('floating-navigation-glass')),
        );
        expect(glass.opacity, layers.navigationPanelOpacity);
        // 从实际镜片装饰读取颜色，避免只检查 Widget 参数而漏掉绘制路径。
        final lens = find.byKey(
          const ValueKey('floating-navigation-selection-indicator'),
        );
        // 读取实际镜片装饰。
        // 只比较 Widget 参数不足以证明绘制已修改。
        final decorated = tester.widget<DecoratedBox>(
          find.descendant(of: lens, matching: find.byType(DecoratedBox)),
        );
        expect(
          (decorated.decoration as ShapeDecoration).color,
          layers.navigationFill,
        );
        // 文字保持不透明，与透明镜片的 Alpha 分离。
        // 文字和底色分开核对。
        // 避免底色变浅却残留白字。
        final item = find.byKey(const ValueKey('floating-navigation-item-0'));
        // 实际长中文参与布局，不用短标签避开两倍字号的换行问题。
        // 渲染对象必须允许全文，而不是仅在语义树里保留原文。
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: item, matching: find.byType(RichText)).first,
        );
        expect(paragraph.maxLines, isNull);
        expect(paragraph.didExceedMaxLines, isFalse);
        // 字形底边必须在点击区内，不能有最后一行越过镜片的情况。
        final textRect = tester.getRect(
          find.descendant(of: item, matching: find.byType(Text)).last,
        );
        expect(
          textRect.bottom,
          lessThanOrEqualTo(tester.getRect(item).bottom + .1),
        );
        final label = tester
            .widgetList<Text>(
              find.descendant(of: item, matching: find.byType(Text)),
            )
            .last;
        expect(label.style!.color, layers.navigationForeground);
        // 改色不改变点击回调；两倍字号下所有目的地仍可触达。
        // 命中真实目的地区域。
        // 颜色更新不能改变回调编号。
        await tester.tap(
          find.byKey(const ValueKey('floating-navigation-item-2')),
        );
        await tester.pumpAndSettle();
        expect(selected, [2]);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
