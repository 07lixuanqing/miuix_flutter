import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps an extension beneath the real package theme and Material delegates.
Future<void> pumpExtension(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MiuixTheme(
      child: MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('MiuixCalendarController', () {
    test('normalizes dates and applies every selection policy', () {
      final controller = MiuixCalendarController(
        visibleMonth: DateTime(2026, 8, 13, 23),
      );

      expect(controller.visibleMonth, DateTime(2026, 8));
      controller.select(
        DateTime(2026, 8, 4, 15),
        MiuixCalendarSelectionMode.single,
      );
      expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 4)});

      controller.select(
        DateTime(2026, 8, 6),
        MiuixCalendarSelectionMode.multiple,
      );
      expect(controller.state.selectedDates, contains(DateTime(2026, 8, 6)));
      controller.select(
        DateTime(2026, 8, 6),
        MiuixCalendarSelectionMode.multiple,
      );
      expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 4)});

      controller.select(
        DateTime(2026, 8, 20),
        MiuixCalendarSelectionMode.range,
      );
      controller.select(
        DateTime(2026, 8, 10),
        MiuixCalendarSelectionMode.range,
      );
      expect(controller.state.selectedRange?.start, DateTime(2026, 8, 10));
      expect(controller.state.selectedRange?.end, DateTime(2026, 8, 20));
    });
  });

  testWidgets('calendar renders six weeks and updates controlled selection', (
    tester,
  ) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 8));
    await pumpExtension(
      tester,
      SizedBox(width: 360, child: MiuixCalendar(controller: controller)),
    );

    expect(find.byType(MiuixCalendar), findsOneWidget);
    final calendarGlass = tester.widget<MiuixGlass>(
      find.descendant(
        of: find.byType(MiuixCalendar),
        matching: find.byType(MiuixGlass),
      ),
    );
    expect(calendarGlass.blur, 20);
    expect(calendarGlass.opacity, .64);
    expect(find.text('13'), findsOneWidget);
    // Extension defaults use the bundled MIUIX optical family instead of
    // mixing Material chevrons into an otherwise MIUIX surface.
    expect(
      find.byIcon(MiuixExtendedIconCatalog.find('ChevronBackward')!.regular),
      findsOneWidget,
    );
    expect(
      find.byIcon(MiuixExtendedIconCatalog.find('ChevronForward')!.regular),
      findsOneWidget,
    );
    // Six rows only when the month needs them; weekday labels, header, and
    // surface padding stay compact under the route's MediaQuery safe-area insets.
    expect(
      tester.getSize(find.byType(MiuixCalendar)).height,
      closeTo(444, 0.01),
    );
    await tester.tap(find.text('13'));
    await tester.pumpAndSettle();
    expect(controller.state.selectedDates, contains(DateTime(2026, 8, 13)));
  });

  testWidgets('calendar omits trailing weeks with no day of the visible month', (
    tester,
  ) async {
    // September 2026 (Mon-first) fits in five weeks; do not paint Oct 5–11.
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 9));
    await pumpExtension(
      tester,
      SizedBox(width: 360, child: MiuixCalendar(controller: controller)),
    );
    final augustHeight = 444.0;
    final fiveWeekHeight = augustHeight - MiuixCalendarDefaults.dayExtent;
    expect(
      tester.getSize(find.byType(MiuixCalendar)).height,
      closeTo(fiveWeekHeight, 0.01),
    );
    expect(find.text('30'), findsOneWidget);
  });

  testWidgets('calendar wraps unchecked first-weekday values consistently', (
    tester,
  ) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 8));

    Future<double> dayOneX(int firstWeekday) async {
      await pumpExtension(
        tester,
        SizedBox(
          width: 360,
          child: MiuixCalendar(
            controller: controller,
            firstWeekday: firstWeekday,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      // The six-week grid may also contain July 1 as an adjacent-month day;
      // August 1 is the later matching cell in chronological build order.
      return tester.getCenter(find.text('1').last).dx;
    }

    // Eight wraps to Monday and zero wraps to Sunday. These unchecked values
    // can arrive from persisted platform preferences and must behave exactly
    // like their canonical DateTime weekday rather than asserting in Debug.
    expect(await dayOneX(8), closeTo(await dayOneX(DateTime.monday), .001));
    expect(await dayOneX(0), closeTo(await dayOneX(DateTime.sunday), .001));
  });

  testWidgets('calendar paints range interiors separately from endpoints', (
    tester,
  ) async {
    const endpoint = Color(0xff123456);
    const interior = Color(0xffabcdef);
    final controller = MiuixCalendarController(
      visibleMonth: DateTime(2026, 8),
      selectedRange: MiuixDateRange(
        DateTime(2026, 8, 10),
        DateTime(2026, 8, 20),
      ),
    );
    await pumpExtension(
      tester,
      SizedBox(
        width: 360,
        child: MiuixCalendar(
          controller: controller,
          selectionMode: MiuixCalendarSelectionMode.range,
          colors: const MiuixCalendarColors(
            background: Colors.white,
            foreground: Colors.black,
            secondaryForeground: Colors.grey,
            selectedBackground: endpoint,
            selectedForeground: Colors.white,
            rangeBackground: interior,
            disabledForeground: Colors.black26,
          ),
        ),
      ),
    );

    // August 10 is a range endpoint, whereas August 13 is strictly inside
    // the range. Both remain selected for accessibility, but their visual
    // hierarchy must use the two independent public color channels.
    BoxDecoration decorationFor(String day) {
      final cell = find
          .ancestor(
            of: find.text(day),
            matching: find.byType(Stack),
          )
          .first;
      final animated = find.descendant(
        of: cell,
        matching: find.byType(AnimatedContainer),
      );
      return tester.widget<AnimatedContainer>(animated).decoration!
          as BoxDecoration;
    }

    expect(decorationFor('10').color, endpoint);
    expect(decorationFor('13').color, interior);
    expect(decorationFor('13').borderRadius, BorderRadius.zero);
    expect(
      decorationFor('10').borderRadius,
      const BorderRadiusDirectional.only(
        topStart: Radius.circular(22),
        bottomStart: Radius.circular(22),
      ),
    );
    expect(
      decorationFor('20').borderRadius,
      const BorderRadiusDirectional.only(
        topEnd: Radius.circular(22),
        bottomEnd: Radius.circular(22),
      ),
    );
  });

  testWidgets('date picker exposes calendar and wheel presentations', (
    tester,
  ) async {
    final controller = MiuixDatePickerController(value: DateTime(2026, 8, 13));
    await pumpExtension(
      tester,
      SizedBox(
        width: 380,
        child: MiuixDatePicker(
          controller: controller,
          mode: MiuixDatePickerMode.wheels,
        ),
      ),
    );

    expect(find.byType(MiuixNumberPicker), findsNWidgets(3));
    expect(
      find.descendant(
        of: find.byType(MiuixDatePicker),
        matching: find.byType(MiuixGlass),
      ),
      findsOneWidget,
    );
    controller.value = DateTime(2027, 2, 14, 19);
    await tester.pump();
    expect(controller.value, DateTime(2027, 2, 14));
  });

  testWidgets('calendar treats reversed date bounds as one inclusive range', (
    tester,
  ) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 8));
    addTearDown(controller.dispose);
    await pumpExtension(
      tester,
      SizedBox(
        width: 380,
        child: MiuixCalendar(
          controller: controller,
          minimumDate: DateTime(2026, 8, 20),
          maximumDate: DateTime(2026, 8, 10),
        ),
      ),
    );

    await tester.tap(find.text('15'));
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 15)});
    expect(tester.takeException(), isNull);
  });

  testWidgets('date picker normalizes reversed and live date limits', (
    tester,
  ) async {
    final controller = MiuixDatePickerController(value: DateTime(2030, 1, 1));
    final limits = ValueNotifier<({DateTime minimum, DateTime maximum})>((
      minimum: DateTime(2027, 12, 31),
      maximum: DateTime(2025, 1, 1),
    ));
    addTearDown(controller.dispose);
    addTearDown(limits.dispose);

    await pumpExtension(
      tester,
      ValueListenableBuilder<({DateTime minimum, DateTime maximum})>(
        valueListenable: limits,
        builder: (context, value, child) => SizedBox(
          width: 380,
          child: MiuixDatePicker(
            controller: controller,
            mode: MiuixDatePickerMode.wheels,
            minimumDate: value.minimum,
            maximumDate: value.maximum,
          ),
        ),
      ),
    );

    // Reversed authored endpoints become one inclusive range, and an external
    // value outside it is immediately projected to the nearest endpoint.
    expect(controller.value, DateTime(2027, 12, 31));
    expect(tester.takeException(), isNull);

    limits.value = (
      minimum: DateTime(2027, 12, 31),
      maximum: DateTime(2026, 6, 1),
    );
    await tester.pump();
    expect(controller.value, DateTime(2027, 12, 31));

    limits.value = (
      minimum: DateTime(2028, 6, 1),
      maximum: DateTime(2029, 6, 1),
    );
    await tester.pump();
    expect(controller.value, DateTime(2028, 6, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('date dialog contains its calendar inside the compact surface', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MiuixTheme(
        child: MaterialApp(
          home: Builder(
            builder: (context) => MiuixButton(
              label: 'open',
              onPressed: () => MiuixDatePicker.show(
                context: context,
                initialDate: DateTime(2026, 8, 16),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-dialog-surface')),
    );
    final calendar = tester.getRect(find.byType(MiuixCalendar));
    expect(
      surface.contains(calendar.topLeft) &&
          surface.contains(calendar.bottomRight),
      isTrue,
      reason: 'calendar $calendar escaped compact dialog surface $surface',
    );
    expect(surface.height, lessThan(620));
  });

  testWidgets(
    'picker dialog actions dismiss the root modal from a nested route',
    (tester) async {
      final nestedNavigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Navigator(
              key: nestedNavigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => const Scaffold(body: Text('nested root')),
              ),
            ),
          ),
        ),
      );
      nestedNavigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Column(
              children: <Widget>[
                const Text('nested picker page'),
                MiuixButton(
                  label: 'open nested picker',
                  onPressed: () => MiuixDatePicker.show(context: context),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open nested picker'));
      await tester.pumpAndSettle();
      expect(find.byType(MiuixDialog), findsOneWidget);

      await tester.tap(find.widgetWithText(MiuixTextButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(MiuixDialog), findsNothing);
      expect(find.text('nested picker page'), findsOneWidget);
      expect(nestedNavigator.currentState!.canPop(), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('time picker renders seconds and a localized period wheel', (
    tester,
  ) async {
    final controller = MiuixTimePickerController(
      value: const MiuixTimeValue(hour: 13, minute: 30, second: 15),
    );
    await pumpExtension(
      tester,
      MiuixTimePicker(
        controller: controller,
        use24HourFormat: false,
        showSeconds: true,
      ),
    );

    expect(find.byType(MiuixNumberPicker), findsNWidgets(4));
    expect(
      find.descendant(
        of: find.byType(MiuixTimePicker),
        matching: find.byType(MiuixGlass),
      ),
      findsOneWidget,
    );
    expect(
      controller.value.toTimeOfDay(),
      const TimeOfDay(hour: 13, minute: 30),
    );
  });

  test('time value normalizes every wall-clock unit in release semantics', () {
    const wrapped = MiuixTimeValue(hour: 25, minute: 61, second: 120);
    const negative = MiuixTimeValue(hour: -1, minute: -2, second: -3);

    expect(wrapped, const MiuixTimeValue(hour: 1, minute: 1));
    expect(negative.hour, 23);
    expect(negative.minute, 58);
    expect(negative.second, 57);
  });

  testWidgets('time and date-time pickers normalize invalid intervals', (
    tester,
  ) async {
    await pumpExtension(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiuixTimePicker(
            use24HourFormat: true,
            minuteInterval: 0,
            secondInterval: 100,
            showSeconds: true,
          ),
          MiuixDateTimePicker(
            initialStage: MiuixDateTimePickerStage.time,
            use24HourFormat: true,
            minuteInterval: -4,
          ),
        ],
      ),
    );

    final pickers = tester.widgetList<MiuixNumberPicker>(
      find.byType(MiuixNumberPicker),
    );
    expect(pickers.map((picker) => picker.step), containsAll(<int>[1, 59]));
    expect(pickers.every((picker) => picker.step > 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duration picker renders only requested unit columns', (
    tester,
  ) async {
    final controller = MiuixDurationPickerController(
      value: const Duration(hours: 2, minutes: 15),
    );
    await pumpExtension(
      tester,
      MiuixDurationPicker(
        controller: controller,
        showDays: false,
        showSeconds: false,
      ),
    );

    expect(find.byType(MiuixNumberPicker), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(MiuixDurationPicker),
        matching: find.byType(MiuixGlass),
      ),
      findsOneWidget,
    );
    expect(controller.value, const Duration(hours: 2, minutes: 15));
    expect(find.text('2h'), findsOneWidget);
    expect(find.text('15min'), findsOneWidget);
  });

  testWidgets('duration picker normalizes invalid ranges and intervals', (
    tester,
  ) async {
    await pumpExtension(
      tester,
      const MiuixDurationPicker(
        maximumDays: -5,
        minuteInterval: 0,
        secondInterval: 100,
        showSeconds: true,
      ),
    );

    final pickers = tester
        .widgetList<MiuixNumberPicker>(find.byType(MiuixNumberPicker))
        .toList(growable: false);
    expect(pickers.first.max, 0);
    expect(pickers.map((picker) => picker.step), containsAll(<int>[1, 59]));
    expect(pickers.every((picker) => picker.step > 0), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duration picker retains a minute wheel when all units hide', (
    tester,
  ) async {
    await pumpExtension(
      tester,
      const MiuixDurationPicker(
        showDays: false,
        showHours: false,
        showMinutes: false,
        showSeconds: false,
      ),
    );

    expect(find.byType(MiuixNumberPicker), findsOneWidget);
    expect(find.text('0min'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('duration dialog uses the locale-aware public title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MiuixTheme(
        child: MaterialApp(
          home: Builder(
            builder: (context) => MiuixButton(
              label: 'open duration',
              onPressed: () =>
                  MiuixDurationPicker.show(context: context, showSeconds: true),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open duration'));
    await tester.pumpAndSettle();
    expect(find.text('Select duration'), findsOneWidget);
    expect(find.text('0d'), findsOneWidget);
    expect(find.text('0h'), findsOneWidget);
    expect(find.text('0min'), findsOneWidget);
    expect(find.text('0s'), findsOneWidget);
  });

  testWidgets('date-time picker switches stages without losing the value', (
    tester,
  ) async {
    final initial = DateTime(2026, 8, 13, 16, 20);
    final controller = MiuixDateTimePickerController(value: initial);
    await pumpExtension(
      tester,
      SizedBox(
        width: 380,
        child: MiuixDateTimePicker(
          controller: controller,
          initialStage: MiuixDateTimePickerStage.time,
          use24HourFormat: true,
        ),
      ),
    );

    expect(find.byType(MiuixTimePicker), findsOneWidget);
    expect(find.byType(MiuixTabBar), findsOneWidget);
    final dateLabel = MaterialLocalizations.of(
      tester.element(find.byType(MiuixDateTimePicker)),
    ).formatMediumDate(initial);
    await tester.tap(find.text(dateLabel));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixDatePicker), findsOneWidget);
    expect(controller.value, initial);
  });

  testWidgets('date-time picker clamps external dates and preserves time', (
    tester,
  ) async {
    final controller = MiuixDateTimePickerController(
      value: DateTime(2020, 1, 2, 16, 20, 31, 400, 500),
    );
    final callbacks = <DateTime>[];
    await pumpExtension(
      tester,
      SizedBox(
        width: 380,
        child: MiuixDateTimePicker(
          controller: controller,
          minimumDate: DateTime(2026, 3, 10),
          maximumDate: DateTime(2026, 3, 20),
          initialStage: MiuixDateTimePickerStage.time,
          use24HourFormat: true,
          showSeconds: true,
          onChanged: callbacks.add,
        ),
      ),
    );

    expect(controller.value, DateTime(2026, 3, 10, 16, 20, 31, 400, 500));
    expect(callbacks, isEmpty);

    controller.value = DateTime(2035, 9, 8, 7, 6, 5, 4, 3);
    await tester.pump();
    expect(controller.value, DateTime(2026, 3, 20, 7, 6, 5, 4, 3));
    expect(callbacks, <DateTime>[DateTime(2026, 3, 20, 7, 6, 5, 4, 3)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar month swipe owns horizontal drag above a pager', (
    tester,
  ) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 8));
    final pages = PageController();
    addTearDown(pages.dispose);
    await pumpExtension(
      tester,
      SizedBox(
        width: 380,
        height: 430,
        child: PageView(
          controller: pages,
          children: <Widget>[
            MiuixCalendar(controller: controller),
            const ColoredBox(color: Colors.red),
          ],
        ),
      ),
    );

    await tester.fling(find.byType(MiuixCalendar), const Offset(-240, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.visibleMonth, DateTime(2026, 9));
    expect(pages.page, closeTo(0, .001));
  });

  testWidgets('calendar clamps controller navigation to its date bounds', (
    tester,
  ) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2020, 1));
    var notifications = 0;
    await pumpExtension(
      tester,
      SizedBox(
        width: 360,
        child: MiuixCalendar(
          controller: controller,
          minimumDate: DateTime(2026, 3, 10),
          maximumDate: DateTime(2026, 5, 20),
          onChanged: (_) => notifications++,
        ),
      ),
    );

    expect(controller.visibleMonth, DateTime(2026, 3));
    var buttons = tester
        .widgetList<MiuixIconButton>(
          find.descendant(
            of: find.byType(MiuixCalendar),
            matching: find.byType(MiuixIconButton),
          ),
        )
        .toList(growable: false);
    expect(buttons.first.onPressed, isNull);
    expect(buttons.last.onPressed, isNotNull);

    // A stale external month is projected back to the nearest valid month and
    // the public callback receives only the final state.
    controller.showMonth(DateTime(2035, 9));
    await tester.pump();
    expect(controller.visibleMonth, DateTime(2026, 5));
    expect(notifications, 1);
    buttons = tester
        .widgetList<MiuixIconButton>(
          find.descendant(
            of: find.byType(MiuixCalendar),
            matching: find.byType(MiuixIconButton),
          ),
        )
        .toList(growable: false);
    expect(buttons.first.onPressed, isNotNull);
    expect(buttons.last.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calendar keyboard moves focus and selects only on activation', (
    tester,
  ) async {
    final controller = MiuixCalendarController(
      visibleMonth: DateTime(2026, 8),
      selectedDates: <DateTime>[DateTime(2026, 8, 10)],
    );
    final semantics = tester.ensureSemantics();
    await pumpExtension(
      tester,
      SizedBox(
        width: 360,
        child: MiuixCalendar(
          controller: controller,
          minimumDate: DateTime(2026, 8, 1),
          maximumDate: DateTime(2026, 9, 20),
          selectableDayPredicate: (date) => date.day != 11,
        ),
      ),
    );

    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(MiuixCalendar)),
    );
    final day17 = localizations.formatFullDate(DateTime(2026, 8, 17));
    await tester.tap(find.text('10'));
    await tester.pump();

    // The adjacent day is disabled, so a direct arrow does not scan past it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 10)});

    // Moving a row changes semantic focus without silently changing selection.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 10)});
    final focusedDay = find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == day17,
    );
    expect(
      tester.getSemantics(focusedDay).flagsCollection.isFocused,
      Tristate.isTrue,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 17)});

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    expect(controller.visibleMonth, DateTime(2026, 9));
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 17)});
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 9, 17)});
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('calendar horizontal keyboard direction mirrors under RTL', (
    tester,
  ) async {
    final controller = MiuixCalendarController(
      visibleMonth: DateTime(2026, 8),
      selectedDates: <DateTime>[DateTime(2026, 8, 10)],
    );
    await pumpExtension(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: SizedBox(
          width: 360,
          child: MiuixCalendar(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.state.selectedDates, <DateTime>{DateTime(2026, 8, 11)});
    expect(tester.takeException(), isNull);
  });

  testWidgets('date-time panels can explicitly disable HyperOS glass', (
    tester,
  ) async {
    await pumpExtension(
      tester,
      ListView(
        shrinkWrap: true,
        children: const <Widget>[
          MiuixCalendar(glass: false),
          MiuixTimePicker(glass: false),
        ],
      ),
    );

    expect(find.byType(MiuixGlass), findsNothing);
  });

  testWidgets('calendar selection honors reduced motion', (tester) async {
    final controller = MiuixCalendarController(visibleMonth: DateTime(2026, 8));
    await pumpExtension(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: SizedBox(
          width: 360,
          child: MiuixCalendar(controller: controller),
        ),
      ),
    );

    await tester.tap(find.text('13'));
    await tester.pump();
    final dayTransitions = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixCalendar),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(dayTransitions, isNotEmpty);
    expect(
      dayTransitions.every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
  });

  testWidgets('month picker detaches a replaced external controller', (
    tester,
  ) async {
    final first = MiuixMonthPickerController(value: DateTime(2026, 8));
    final second = MiuixMonthPickerController(value: DateTime(2027, 2));
    late StateSetter replace;
    var controller = first;

    await pumpExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          replace = setState;
          return SizedBox(
            width: 360,
            child: MiuixMonthPicker(controller: controller),
          );
        },
      ),
    );
    expect(find.text('2026'), findsOneWidget);

    replace(() => controller = second);
    await tester.pump();
    expect(find.text('2027'), findsOneWidget);

    // Mutating the detached controller must neither rebuild nor overwrite the
    // visible year owned by the replacement controller.
    first.value = DateTime(2035, 4);
    await tester.pump();
    expect(find.text('2027'), findsOneWidget);
  });

  testWidgets('week calendar detaches a replaced external controller', (
    tester,
  ) async {
    final first = MiuixWeekCalendarController(
      selectedDate: DateTime(2026, 8, 13),
    );
    final second = MiuixWeekCalendarController(
      selectedDate: DateTime(2026, 8, 20),
    );
    late StateSetter replace;
    var controller = first;

    await pumpExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          replace = setState;
          return SizedBox(
            width: 420,
            child: MiuixWeekCalendar(controller: controller),
          );
        },
      ),
    );
    expect(find.text('10'), findsOneWidget);
    expect(find.text('17'), findsNothing);

    replace(() => controller = second);
    await tester.pump();
    expect(find.text('17'), findsOneWidget);
    expect(find.text('10'), findsNothing);

    first.selectedDate = DateTime(2026, 9, 10);
    await tester.pump();
    expect(find.text('17'), findsOneWidget);
  });
}
