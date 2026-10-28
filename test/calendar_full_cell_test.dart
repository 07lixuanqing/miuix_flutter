import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'full day selection preserves geometry and today text reduce=$reduceMotion',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final other = DateTime(now.year, now.month, now.day == 1 ? 15 : 1);
        final controller = MiuixCalendarController(
          visibleMonth: today,
          selectedDates: [today],
        );
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          MiuixTheme(
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(800, 1000),
                  disableAnimations: reduceMotion,
                ),
                child: Scaffold(
                  body: MiuixCalendar(
                    controller: controller,
                    fullCellSelection: true,
                    dayExtent: 80,
                    dayMargin: const EdgeInsets.all(3),
                    // Full-cell mode ignores an old inset emphasis, including on today.
                    dayHighlightMargin: const EdgeInsets.all(20),
                    dayAdornmentBuilder: (_, date, selected, enabled) =>
                        SizedBox.expand(key: ValueKey('plane-$date')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Finder frame(DateTime d) => find.byKey(
          ValueKey('calendar-highlight-${d.year}-${d.month}-${d.day}'),
        );
        BoxDecoration target(DateTime d) =>
            tester.widget<AnimatedContainer>(frame(d)).decoration
                as BoxDecoration;
        BoxDecoration rendered(DateTime d) =>
            tester
                    .widget<Container>(
                      find
                          .descendant(
                            of: frame(d),
                            matching: find.byType(Container),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration;
        final todayRect = tester.getRect(frame(today));
        expect(
          todayRect,
          tester.getRect(find.byKey(ValueKey('plane-$today'))).deflate(3),
        );
        expect(todayRect.width, greaterThan(80));
        expect(target(today).color!.a, closeTo(.10, .01));
        expect((target(today).border as Border).top.color.a, 1);
        // 月初网格可能含上月同日，数字文本的第一个匹配不一定属于今天。
        // 按组件真实的完整日期语义定位日期单元，保留原颜色和几何断言。
        final todayLabel = MaterialLocalizations.of(
          tester.element(frame(today)),
        ).formatFullDate(today);
        final number = find.descendant(
          of: find.byWidgetPredicate(
            (w) =>
                w is Semantics &&
                w.properties.button == true &&
                w.properties.label == todayLabel,
          ),
          matching: find.text('${today.day}'),
        );
        // 不能靠 first 隐藏定位歧义，今天的单元只能给出一个日期数字。
        expect(number, findsOneWidget);
        final numberRect = tester.getRect(number);
        final numberStyle = tester.widget<Text>(number).style!;
        expect(tester.widget<Text>(number).maxLines, 1);
        expect(tester.widget<Text>(number).softWrap, isFalse);
        expect(numberStyle.color, (target(today).border as Border).top.color);
        expect(numberStyle.fontWeight, FontWeight.w700);
        final otherRect = tester.getRect(frame(other));
        // Blank padding is part of the hit target; press only changes paint.
        final gesture = await tester.startGesture(
          otherRect.topLeft + const Offset(2, 2),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(target(other).color!.a, closeTo(.18, .01));
        expect(tester.getRect(frame(other)), otherRect);
        await gesture.up();
        await tester.pump();
        expect(controller.state.selectedDates, {other});
        expect((target(today).border as Border).top.color.a, 0);
        if (!reduceMotion) {
          await tester.pump(const Duration(milliseconds: 90));
          expect(
            (rendered(today).border as Border).top.color.a,
            inExclusiveRange(0, 1),
          );
        }
        await tester.pumpAndSettle();
        expect(tester.getRect(number), numberRect);
        expect(tester.widget<Text>(number).style!.color, numberStyle.color);
        expect((rendered(today).border as Border).top.color.a, 0);
        expect(
          tester.widget<AnimatedContainer>(frame(today)).duration,
          reduceMotion ? Duration.zero : const Duration(milliseconds: 180),
        );
        // Existing connected range geometry and semantics are not replaced.
        controller.select(other, MiuixCalendarSelectionMode.range);
        controller.select(
          DateTime(other.year, other.month, other.day + 2),
          MiuixCalendarSelectionMode.range,
        );
        await tester.pumpAndSettle();
        expect(frame(other), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
