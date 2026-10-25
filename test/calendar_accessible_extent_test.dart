import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets(
    'larger calendar rows reserve the same height for lunar content',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = MiuixCalendarController(
        visibleMonth: DateTime(2026, 9),
      );
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
                child: MiuixCalendar(
                  controller: controller,
                  dayExtent: 108.8,
                  dayCornerRadius: 8,
                  dayMargin: const EdgeInsets.all(3),
                  dayAdornmentBuilder: (_, date, selected, enabled) => SizedBox(
                    key: ValueKey('plane-${date.month}-${date.day}'),
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 12,
                          left: 0,
                          right: 0,
                          child: Text(
                            '农历',
                            key: ValueKey('lunar-${date.month}-${date.day}'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('plane-9-15'))).height,
        closeTo(108.8, .01),
      );
      final number = tester.getRect(find.text('15').first);
      final lunar = tester.getRect(find.byKey(const ValueKey('lunar-9-15')));
      expect(number.bottom, lessThan(lunar.top));
      await tester.tap(find.text('15').first);
      await tester.pumpAndSettle();
      expect(controller.state.selectedDates.single, DateTime(2026, 9, 15));
      expect(tester.takeException(), isNull);
    },
  );
}
