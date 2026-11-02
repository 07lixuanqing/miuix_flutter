import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('窄窗口二倍字号完整月份、日期字形和横向阅读', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = MiuixCalendarController(
      visibleMonth: DateTime(2026, 10),
      selectedDates: [DateTime(2026, 10, 27)],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MiuixTheme(
        child: MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 280,
                  child: MiuixCalendar(
                    controller: controller,
                    dayExtent: 48,
                    glass: false,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    // 检查实际字形边界，不能仅以没有 RenderFlex 异常认定没有重叠。
    final number = find.text('27').first;
    final paragraph = tester.renderObject<RenderParagraph>(number);
    final boxes = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 2),
    );
    expect(
      boxes.single.right - boxes.single.left,
      lessThanOrEqualTo(tester.getSize(number).width + .1),
    );
    expect(paragraph.didExceedMaxLines, false);
    // 月份标题不再受 52dp 固定行框裁切，星期行在标题之后。
    final context = tester.element(find.byType(MiuixCalendar));
    final label = MaterialLocalizations.of(
      context,
    ).formatMonthYear(DateTime(2026, 10));
    final heading = find.text(label);
    expect(
      tester.getRect(heading).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('M').first).top),
    );
    final monthBefore = controller.visibleMonth;
    final scroll = find.byKey(const ValueKey('calendar-readable-grid'));
    expect(scroll, findsOneWidget);
    await tester.drag(scroll, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(controller.visibleMonth, monthBefore);
    // 横向阅读后仍能选择最后一列，手势不会同时切到另一个月份。
    await tester.tap(find.text('18').first);
    await tester.pumpAndSettle();
    expect(controller.state.selectedDates.single, DateTime(2026, 10, 18));
    expect(tester.takeException(), isNull);
  });
}
