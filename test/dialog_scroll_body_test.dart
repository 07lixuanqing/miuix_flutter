import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  // 手机和平板分别测试，不能只在宽屏上验证共用弹窗。
  for (final width in [320.0, 1024.0]) {
    for (final scale in [1.0, 2.0]) {
      // 每种组合独立挂载，初始位置不继承上一项的滚动偏移。
      testWidgets('long dialog body keeps actions reachable $width $scale', (
        tester,
      ) async {
        // 固定像素比例，几何边界可直接与窗口尺寸比较。
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        // 大字走实际 TextScaler 输入，不放大结果图片。
        // 用实际文字缩放和键盘边距参与布局，不缩放已经绘制的图片。
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        // 恢复全部平台数据，避免影响后续组件测试。
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        // 超长原文固定保留，不通过缩短摘要换取按钮可见。
        final title = '长中文摘要需要完整阅读并能继续修改输入。' * 30;
        var cancelled = false;
        // 只从真实回调观察操作是否发生，不以外观推断可点击。
        await tester.pumpWidget(
          MaterialApp(
            // 键盘只提供系统边距，由实际弹窗消费这份约束。
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                // 底部 260 像素不能被正文或按钮占用。
                context,
              ).copyWith(viewInsets: const EdgeInsets.only(bottom: 260)),
              // 使用完整主题和外层弹窗，保留产品中的有限高度。
              child: MiuixTheme(data: MiuixThemeData.defaults(), child: child!),
            ),
            home: MiuixDialog(
              // 关闭背景取样，使排版不依赖背后场景的画面。
              glass: false,
              content: Flexible(
                // 与应用相同的内容槽，不用无界 Column 冒充弹窗。
                child: MiuixDialogScrollBody(
                  // 底栏参与实际布局，正文先让出它所需的空间。
                  footer: MiuixButton(
                    key: const ValueKey('cancel'),
                    // 稳定键不受摘要中的相同文字影响。
                    label: '取消',
                    // 回调不关闭路由，点击后还能读取同一棵渲染树的异常。
                    onPressed: () => cancelled = true,
                  ),
                  // 首尾属于同一滚动区，定位末尾不应改变固定操作。
                  children: [Text(title), const Text('最后一行错误原因')],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        // 读取实际段落，而非仅检查静态 Text 的属性。
        // 不允许通过省略号或限制行数消除溢出。
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text(title),
            // RichText 对应真正完成文字测量的对象。
            matching: find.byType(RichText),
          ),
        );
        expect(paragraph.maxLines, isNull);
        // 所有原文都完成排版，视口外的部分允许滚动阅读。
        expect(paragraph.didExceedMaxLines, isFalse);
        // 操作独立于正文，长摘要不能使按钮落到键盘后面。
        final button = find.byKey(const ValueKey('cancel'));
        // 记录滚动前位置，后面要求同一操作不随正文移动。
        final before = tester.getRect(button);
        // 900 减去键盘 260 后，可用下界是 640。
        expect(before.bottom, lessThanOrEqualTo(640));
        // 末尾须能实际进入阅读区，不能只是存在于组件树。
        await tester.ensureVisible(find.text('最后一行错误原因'));
        await tester.pumpAndSettle();
        // 比较同一渲染树的布局结果，不重新打开窗口消除滚动状态。
        // 滚到真正的末尾后，按钮仍留在相同位置。
        expect(tester.getRect(button), before);
        // 末尾文字不能画到固定底栏后面。
        expect(tester.getRect(find.text('最后一行错误原因')).overlaps(before), isFalse);
        await tester.tap(button);
        // 命中检测也需成功，屏幕内的几何位置不是可操作性的充分条件。
        expect(cancelled, isTrue);
        // 任何 RenderFlex 溢出或框架错误都应使本项失败。
        expect(tester.takeException(), isNull);
        // 测试绑定随后销毁整棵树，不复用前一项的滚动位置。
        // 此处只证明组件布局，不代替 Android 实际输入法或手势验收。
      });
    }
  }
}
