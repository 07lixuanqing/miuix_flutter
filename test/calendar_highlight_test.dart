import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets('highlight contains lunar and keeps badges outside', (
    tester,
  ) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final other = DateTime(now.year, now.month, now.day == 15 ? 16 : 15);
    final controller = MiuixCalendarController(
      visibleMonth: today,
      selectedDates: [other],
    );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MiuixTheme(
        child: MaterialApp(
          home: Scaffold(
            body: MiuixCalendar(
              controller: controller,
              dayExtent: 90,
              dayHighlightMargin: const EdgeInsets.fromLTRB(3, 24, 3, 8),
              dayMargin: const EdgeInsets.all(3),
              dayBackgroundBuilder:
                  (
                    date, {
                    required selected,
                    required enabled,
                    required inMonth,
                    required isToday,
                  }) => date == other ? Colors.amber.shade100 : null,
              dayAdornmentBuilder: (_, date, selected, enabled) => Stack(
                children: [
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Text('班', key: ValueKey('badge-${date.day}')),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 6,
                    child: Text('农历', key: ValueKey('lunar-${date.day}')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (final date in [today, other]) {
      final highlight = find.byKey(
        ValueKey('calendar-highlight-${date.year}-${date.month}-${date.day}'),
      );
      final rect = tester.getRect(highlight);
      expect(rect.size, const Size(50, 58));
      expect(
        tester.getRect(find.byKey(ValueKey('badge-${date.day}')).first).bottom,
        lessThan(rect.top),
      );
      expect(
        tester.getRect(find.byKey(ValueKey('lunar-${date.day}')).first).top,
        greaterThan(rect.top),
      );
      expect(
        tester.getRect(find.byKey(ValueKey('lunar-${date.day}')).first).bottom,
        lessThan(rect.bottom),
      );
      final decoration =
          tester.widget<AnimatedContainer>(highlight).decoration!
              as BoxDecoration;
      expect(decoration.border == null, date == today);
    }
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is AnimatedContainer &&
            (w.decoration as BoxDecoration?)?.color == Colors.amber.shade100,
      ),
      findsOneWidget,
    );
    // Range endpoints keep the existing connected range geometry.
    controller.select(other, MiuixCalendarSelectionMode.range);
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey(
          'calendar-highlight-${other.year}-${other.month}-${other.day}',
        ),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  for (final margin in <EdgeInsets?>[
    null,
    const EdgeInsets.all(-1),
    const EdgeInsets.only(left: -1),
    const EdgeInsets.all(double.nan),
    const EdgeInsets.all(double.infinity),
  ]) {
    testWidgets('invalid highlight margin $margin preserves default paint', (
      tester,
    ) async {
      final today = DateTime.now();
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Scaffold(body: MiuixCalendar(dayHighlightMargin: margin)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          ValueKey(
            'calendar-highlight-${today.year}-${today.month}-${today.day}',
          ),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
