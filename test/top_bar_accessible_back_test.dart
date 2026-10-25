import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 本组验证真实标题栏布局，避免只检查 PreferredSize 的计算结果。
// 放大的是整台测试设备的文字设置，不是单独修改某个 Text 字号。
// 窄屏使用 320dp，平板使用 840dp，均以逻辑像素断言。
// 长标题包含实际健康设置场景，不能用四字标题替代长文本验收。
// 返回图标保留正式触摸大小，不通过缩小按钮给标题腾位置。
// 标题测量与绘制使用同一个字体角色，测试字体无需依赖主机安装。
// 定位展开文字时同时检查字号，排除被保留的紧凑标题。
// 文字盒子不能进入返回按钮的点击区域。
// 后续页面正文也不能被增长后的标题区遮住。
// 标题允许自然换行，不设固定行数或省略号。
// 测试仍以正常滚动容器承载正文，符合实际页面布局。
// 不要求固定截图像素，允许真实字体行高与系统缩放产生合理高度。
// 本组不改变紧凑标题栏或系统状态栏的既有尺寸。
// 关闭手势与文字放大互不影响，这里仅验证返回按钮可见可点。
// 最终实际中文字体截图由应用级设置页面测试输出。
void main() {
  // 每个组合单独挂载，确保宽度变化不沿用上一个布局的测量结果。
  // 文字区域取真实元素矩形，不用组件声明的 nominal height 代替。
  // 点击回调次数用于检查返回按钮未被大标题遮挡。
  // 长标题在大字号下应换行，并增加标题栏实际预留高度。
  // 覆盖默认 expandedHeight 不随字号增长时的按钮重叠回归。
  for (final width in [320.0, 840.0]) {
    for (final title in ['本机偏好', '运动健康关联任务同步与核对设置']) {
      testWidgets('large title leaves Back accessible $width $title', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        var backs = 0;
        // 读无上下文尺寸不能重置已测量的字体缩放行程，或形成无限布局通知。
        final behavior = MiuixTopAppBarScrollBehavior();
        addTearDown(behavior.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(width, 1000),
                textScaler: const TextScaler.linear(2),
              ),
              child: MiuixTheme(
                child: MiuixScaffold(
                  topBar: MiuixTopAppBar(
                    title: title,
                    large: true,
                    scrollBehavior: behavior,
                    leading: MiuixIconButton(
                      key: const ValueKey('back'),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: '返回',
                      onPressed: () => backs++,
                    ),
                  ),
                  body: ListView(children: const [Text('页面正文')]),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 使用实际 Text 元素位置，发现只改预留高度而没有移动绘制的问题。
        final expanded = find.byWidgetPredicate(
          (w) => w is Text && w.data == title && w.style?.fontSize == 32,
        );
        final text = tester.widget<Text>(expanded);
        expect(text.maxLines, isNull);
        expect(text.overflow, isNot(TextOverflow.ellipsis));
        // 两个矩形不能相交；不能用视觉上暂时透明来规避触摸冲突。
        expect(
          tester.getTopLeft(expanded).dy,
          greaterThanOrEqualTo(
            tester.getBottomLeft(find.byKey(const ValueKey('back'))).dy,
          ),
        );
        expect(
          tester.getTopLeft(find.text('页面正文')).dy,
          greaterThanOrEqualTo(tester.getBottomLeft(expanded).dy),
        );
        // 点击同一个返回按钮，验证自适应高度没有丢失事件或移动锚点。
        await tester.tap(find.byKey(const ValueKey('back')));
        expect(backs, 1);
        expect(tester.takeException(), isNull);
        final limit = behavior.state.heightOffsetLimit;
        // 始终读取同一个 behavior，不能通过新建控制器掩盖尺寸查询的副作用。
        // 正文会在 build 中读取无上下文尺寸，不能因此恢复为默认 38dp 行程。
        // 如果反复通知，pumpAndSettle 会超时，暴露布局循环。
        // 读取之后仍保持同一高度限制，滚动状态不会被重置。
        tester
            .widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar))
            .preferredSize;
        await tester.pumpAndSettle();
        expect(behavior.state.heightOffsetLimit, limit);
      });
    }
  }
}
