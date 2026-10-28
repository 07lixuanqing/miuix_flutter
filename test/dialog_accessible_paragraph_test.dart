import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  // 使用长标题同时覆盖换行与系统字号；没有溢出异常不足以证明字形未被裁切。
  for (final scale in [1.0, 2.0]) {
    for (final width in [320.0, 900.0]) {
      testWidgets('dialog paragraphs remain inside placeables $width $scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        const title = '跳转到指定日期并保留完整输入';
        const summary = '请选择有效的年份月份与日期，输入错误后可以继续修改。';
        await tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              data: MiuixThemeData.defaults(),
              child: const MiuixDialog(
                title: title,
                summary: summary,
                glass: false,
                content: Text('内容'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final placeable = tester.getRect(
          find.byKey(const ValueKey('miuix-dialog-title-placeable')),
        );
        final paragraphFinder = find.descendant(
          of: find.text(title),
          matching: find.byType(RichText),
        );
        final paragraph = tester.renderObject<RenderParagraph>(paragraphFinder);
        // RenderParagraph 自身可能在父框中溢出；必须同时比较实际布局边界。
        final actual = tester.getRect(paragraphFinder);
        expect(actual.top, greaterThanOrEqualTo(placeable.top - .01));
        expect(actual.bottom, lessThanOrEqualTo(placeable.bottom + .01));
        expect(placeable.height, greaterThanOrEqualTo(21 * scale));
        expect(paragraph.maxLines, isNull);
        expect(paragraph.overflow, isNot(TextOverflow.ellipsis));
        final surface = tester.getRect(
          find.byKey(const ValueKey('miuix-dialog-surface')),
        );
        final summaryBounds = tester.getRect(find.text(summary));
        expect(summaryBounds.top, greaterThanOrEqualTo(actual.bottom));
        expect(summaryBounds.bottom, lessThan(surface.bottom));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
