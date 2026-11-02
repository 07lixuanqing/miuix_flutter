part of '../miuix_flutter_test.dart';

// 保留原测试注册顺序和公共夹具；按弹层职责拆分超长文件。
void _registerOverlayFeedbackPickerTests() {
  testWidgets('rich tooltip renders custom content in its overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixRichTooltipBox(
                message: 'Rich title',
                content: Text('Rich detail content'),
                child: Text('Rich target'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rich detail content'), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Rich target')),
    );
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Rich title'), findsOneWidget);
    expect(find.text('Rich detail content'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Rich detail content'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Rich detail content'), findsNothing);
  });

  testWidgets('scroll behavior suppresses Flutter default overscroll effects', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ScrollConfiguration(
            behavior: const MiuixScrollBehavior(),
            child: Scaffold(
              body: SizedBox(
                height: 80,
                child: ListView(
                  children: const [
                    SizedBox(height: 240, child: Text('Scrollable content')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('MIUIX spring physics uses the source cubic damping curve', () {
    const physics = MiuixSpringScrollPhysics();
    expect(physics.frictionFactor(0), 1);
    expect(physics.frictionFactor(.5), .25);
    expect(physics.frictionFactor(1), 0);

    var pixels = 0.0;
    for (var index = 0; index < 1000; index++) {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: pixels,
        viewportDimension: 1000,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      pixels += physics.applyPhysicsToUserOffset(metrics, -1);
    }
    // x - x² + x³/3 reaches exactly one third of the viewport at x=1.
    expect(-pixels, closeTo(1000 / 3, 2));
  });

  test('MIUIX spring physics uses the source window range and inverse', () {
    const physics = MiuixSpringScrollPhysics(windowSize: Size(500, 1000));
    for (final touch in <double>[1, 50, 250, 500, 1000]) {
      final damped = physics.dampingDistance(touch, 1000);
      expect(physics.touchDistance(damped, 1000), closeTo(touch, .0001));
    }

    var pixels = 0.0;
    for (var index = 0; index < 1000; index++) {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: pixels,
        viewportDimension: 100,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      pixels += physics.applyPhysicsToUserOffset(metrics, -1);
    }
    // A popup still damps against the 1000px window, not its 100px viewport.
    expect(-pixels, closeTo(1000 / 3, 2));
  });

  test('MIUIX spring simulation copies the source Euler frame step', () {
    const physics = MiuixSpringScrollPhysics();
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: -100,
      viewportDimension: 500,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    final simulation = physics.createBallisticSimulation(metrics, 0)!;
    const dt = .016;
    const omega = 2 * math.pi / .4;
    const expectedVelocity = omega * omega * 100 * dt;
    const expectedPosition = -100 + expectedVelocity * dt;
    expect(simulation.dx(dt), closeTo(expectedVelocity, 1e-9));
    expect(simulation.x(dt), closeTo(expectedPosition, 1e-9));
    expect(simulation.isDone(dt), isFalse);
  });

  testWidgets('overscroll behavior uses window range and honors its toggle', (
    tester,
  ) async {
    late ScrollPhysics enabled;
    late ScrollPhysics disabled;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            enabled = const MiuixScrollBehavior().getScrollPhysics(context);
            disabled = const MiuixScrollBehavior(
              showOverscrollIndicator: false,
            ).getScrollPhysics(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(enabled, isA<MiuixSpringScrollPhysics>());
    expect(
      (enabled as MiuixSpringScrollPhysics).windowSize,
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    expect(disabled, isA<ClampingScrollPhysics>());
  });

  test('overscroll factory preserves singleton value semantics and state', () {
    const first = MiuixOverscrollFactory();
    const second = MiuixOverscrollFactory();
    // Non-const calls prove the Kotlin singleton's strict identity semantics.
    // ignore: prefer_const_constructors
    final runtimeFirst = MiuixOverscrollFactory();
    // ignore: prefer_const_constructors
    final runtimeSecond = MiuixOverscrollFactory();
    final state = MiuixOverScrollState();
    addTearDown(state.dispose);
    expect(first, second);
    expect(runtimeFirst == runtimeSecond, isFalse);
    expect(first.hashCode, 1);
    final effect = first.createOverscrollEffect(
      state: state,
      child: const Text('Effect child'),
    );
    expect(effect.state, same(state));
    expect(effect.child, isA<Text>());
  });

  testWidgets('overscroll effect reports the source one-pixel active state', (
    tester,
  ) async {
    final state = MiuixOverScrollState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixOverscrollEffect(
          state: state,
          showScrollbars: false,
          child: SizedBox(
            height: 80,
            child: ListView(
              children: const [
                SizedBox(height: 240, child: Text('Scrollable content')),
              ],
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(state.isOverScrollActive, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.isOverScrollActive, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker uses the source flat stack and reports selection', (
    tester,
  ) async {
    var value = 5;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => MiuixNumberPicker(
                value: value,
                min: 0,
                max: 10,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(
      find.descendant(of: wheel, matching: find.byType(Stack)),
      findsOneWidget,
    );
    expect(tester.getSize(wheel).height, 225);
    final selectedText = tester.widget<Text>(find.text('5'));
    final semantic = MiuixSemanticColors.of(tester.element(wheel));
    expect(semantic['onSurface'], const Color(0xFF000000));
    expect(selectedText.style?.fontSize, 32);
    expect(selectedText.style?.fontWeight, FontWeight.w600);
    expect(selectedText.style?.color, semantic['onSurface']);

    // One row from center: normalized distance is 1 / (2 + 0.5). The source
    // formula produces 48% opacity and 92% scale, without wheel magnification.
    final adjacentVisual = debugMiuixNumberPickerItemVisual(
      distanceFromCenter: 1,
      visibleItemCount: 5,
      selectedColor: semantic['onSurface'],
      unselectedColor: semantic['onSurfaceSecondary'],
    );
    expect(adjacentVisual.opacity, closeTo(.48, .0001));
    expect(adjacentVisual.scale, closeTo(.92, .0001));
    expect(
      adjacentVisual.color,
      Color.lerp(semantic['onSurface'], semantic['onSurfaceSecondary'], .4),
    );

    await tester.drag(wheel, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(value, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker renders a huge sparse domain in constant space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixNumberPicker(
              value: 999999999,
              min: -1000000000,
              max: 1000000000,
              step: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    // The requested value is between two legal entries and resolves to the
    // nearer lower entry. Only the visible preparation rows are constructed;
    // the two-billion-wide domain is never materialized as a list.
    expect(find.text('999999999'), findsNothing);
    expect(find.text('999999998'), findsOneWidget);
    expect(
      tester.getSemantics(wheel).label,
      '999999998, -1000000000 - 1000000000',
    );
    expect(
      find.descendant(of: wheel, matching: find.byType(Text)).evaluate().length,
      lessThanOrEqualTo(9),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'number picker reduced motion commits without autonomous settle',
    (tester) async {
      var value = 5;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MiuixTheme(
              child: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => MiuixNumberPicker(
                    value: value,
                    min: 0,
                    max: 10,
                    onChanged: (next) => setState(() {
                      value = next;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
      await tester.timedDrag(
        wheel,
        const Offset(0, -52),
        const Duration(seconds: 2),
      );
      // One bounded frame is sufficient: reduced motion skips both the
      // exponential decay and the critically damped row-centering spring.
      await tester.pump();
      expect(value, 6);
      expect(changes, 1);
      expect(tester.getSemantics(wheel).label, '6, 0 - 10');
      await tester.pump(const Duration(seconds: 1));
      expect(changes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('number picker settles a running fling when motion is reduced', (
    tester,
  ) async {
    var value = 5;
    var changes = 0;
    final reduceMotion = ValueNotifier(false);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => MiuixNumberPicker(
                    value: value,
                    min: 0,
                    max: 10,
                    onChanged: (next) => setState(() {
                      value = next;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    await tester.fling(wheel, const Offset(0, -80), 1000);
    await tester.pump(const Duration(milliseconds: 16));
    expect(changes, 0);

    reduceMotion.value = true;
    await tester.pump();
    await tester.pump();
    expect(value, greaterThan(5));
    expect(changes, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  test('number picker uses Kotlin tie rounding in both directions', () {
    expect(debugMiuixNumberPickerRoundToInt(.49), 0);
    expect(debugMiuixNumberPickerRoundToInt(.5), 1);
    expect(debugMiuixNumberPickerRoundToInt(1.5), 2);
    expect(debugMiuixNumberPickerRoundToInt(-.49), 0);
    expect(debugMiuixNumberPickerRoundToInt(-.5), 0);
    expect(debugMiuixNumberPickerRoundToInt(-1.5), -1);
  });

  testWidgets('number picker colors defaults and source adapter are exact', (
    tester,
  ) async {
    const custom = MiuixNumberPickerColors(
      selectedTextColor: Color(0xFF000001),
      unselectedTextColor: Color(0xFF000002),
      disabledSelectedTextColor: Color(0xFF000003),
      disabledUnselectedTextColor: Color(0xFF000004),
    );
    late MiuixNumberPickerColors defaults;
    late MiuixNumberPickerColors overridden;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixNumberPickerDefaults.colors(context);
              overridden = MiuixNumberPickerDefaults.colors(
                context,
                selectedTextColor: custom.selectedTextColor,
                unselectedTextColor: custom.unselectedTextColor,
                disabledSelectedTextColor: custom.disabledSelectedTextColor,
                disabledUnselectedTextColor: custom.disabledUnselectedTextColor,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(MiuixNumberPickerDefaults.itemHeight, 45);
    expect(defaults.selectedTextColor, const Color(0xFF000000));
    expect(defaults.unselectedTextColor, const Color(0xCC000000));
    expect(defaults.disabledSelectedTextColor, const Color(0xFFFCFCFC));
    expect(defaults.disabledUnselectedTextColor, const Color(0xFFFCFCFC));
    expect(overridden, custom);
    expect(custom.copyWith(), custom);
    expect(custom.selected(true), custom.selectedTextColor);
    expect(custom.selected(false), custom.disabledSelectedTextColor);
    expect(custom.unselected(true), custom.unselectedTextColor);
    expect(custom.unselected(false), custom.disabledUnselectedTextColor);

    final source = MiuixNumberPicker.source(
      value: 7,
      onValueChange: (_) {},
      range: (first: 3, last: 9),
      visibleItemCount: 7,
      wrapAround: true,
      colors: custom,
    );
    expect(source.value, 7);
    expect(source.min, 3);
    expect(source.max, 9);
    expect(source.visibleItemCount, 7);
    expect(source.wrapAround, isTrue);
    expect(source.colors, custom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker forwards colors and source slot paint order', (
    tester,
  ) async {
    const custom = MiuixNumberPickerColors(
      selectedTextColor: Color(0xFF102030),
      unselectedTextColor: Color(0xFF203040),
      disabledSelectedTextColor: Color(0xFF304050),
      disabledUnselectedTextColor: Color(0xFF405060),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            children: [
              Expanded(
                child: MiuixNumberPicker(
                  value: 2,
                  min: 0,
                  max: 5,
                  colors: custom,
                  label: (value) => 'E$value',
                  textStyle: const TextStyle(fontFamily: 'sans-serif'),
                  onChanged: (_) {},
                ),
              ),
              Expanded(
                child: MiuixNumberPicker(
                  value: 2,
                  min: 0,
                  max: 5,
                  enabled: false,
                  colors: custom,
                  label: (value) => 'D$value',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('E2')).style?.color,
      const Color(0xFF102030),
    );
    expect(
      tester.widget<Text>(find.text('E5')).style?.color,
      const Color(0xFF203040),
    );
    expect(
      tester.widget<Text>(find.text('D2')).style?.color,
      const Color(0xFF304050),
    );
    expect(
      tester.widget<Text>(find.text('D5')).style?.color,
      const Color(0xFF405060),
    );
    // A caller style with no size stays unspecified; NumberPicker.kt only
    // fills a missing SemiBold weight instead of replacing the whole style.
    expect(tester.widget<Text>(find.text('E2')).style?.fontSize, isNull);
    expect(
      tester.widget<Text>(find.text('E2')).style?.fontWeight,
      FontWeight.w600,
    );

    final enabledWheel = find
        .byKey(const ValueKey('miuix-number-picker-wheel'))
        .first;
    final opacityKeys = tester
        .widgetList<Opacity>(
          find.descendant(of: enabledWheel, matching: find.byType(Opacity)),
        )
        .map((opacity) => opacity.key)
        .whereType<ValueKey<String>>()
        .map((key) => key.value)
        .toList();
    expect(opacityKeys, const [
      'miuix-number-picker-item-0',
      'miuix-number-picker-item-1',
      'miuix-number-picker-item-2',
      'miuix-number-picker-item-3',
      'miuix-number-picker-item-4',
      'miuix-number-picker-item-5',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker supports disabled and wrap-around states', (
    tester,
  ) async {
    var value = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixNumberPicker(
              value: value,
              min: 0,
              max: 2,
              enabled: false,
              wrapAround: true,
              visibleItemCount: 4,
              label: (item) => 'v$item',
              onChanged: (next) => value = next,
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    expect(tester.getSize(wheel).height, 225);
    expect(find.text('v2'), findsWidgets);

    await tester.drag(wheel, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(value, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wrap-around number picker centers its controlled initial value',
    (tester) async {
      var hour = 16;
      var minute = 30;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  Expanded(
                    child: MiuixNumberPicker(
                      value: hour,
                      min: 0,
                      max: 23,
                      wrapAround: true,
                      onChanged: (next) => setState(() => hour = next),
                    ),
                  ),
                  Expanded(
                    child: MiuixNumberPicker(
                      value: minute,
                      min: 0,
                      max: 59,
                      wrapAround: true,
                      onChanged: (next) => setState(() => minute = next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A looping wheel must not let its synthetic scroll origin replace the
      // externally controlled value during the first Android/layout frame.
      expect(hour, 16);
      expect(minute, 30);
      final wheels = find.byKey(const ValueKey('miuix-number-picker-wheel'));
      expect(wheels, findsNWidgets(2));
      expect(tester.getSemantics(wheels.at(0)).label, '16, 0 - 23');
      expect(tester.getSemantics(wheels.at(0)).value, isEmpty);
      expect(tester.getSemantics(wheels.at(1)).label, '30, 0 - 59');
      expect(tester.getSemantics(wheels.at(1)).value, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('number picker semantics use the displayed source label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixNumberPicker(
            value: 2,
            min: 0,
            max: 6,
            label: (value) => 'v$value',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    final semantics = tester.getSemantics(wheel);
    expect(semantics.label, 'v2, 0 - 6');
    expect(semantics.value, isEmpty);
  });

  testWidgets('snackbar host manages stacked lifecycle and action results', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            snackbarHost: MiuixSnackbarHost(state: state),
          ),
        ),
      ),
    );

    final oldest = state.showSnackbar(
      'Oldest message',
      duration: MiuixSnackbarDuration.indefinite,
    );
    final newest = state.showSnackbar(
      'Newest message',
      actionLabel: 'Undo',
      withDismissAction: true,
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Oldest message'), findsOneWidget);
    expect(find.text('Newest message'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(await newest, MiuixSnackbarResult.actionPerformed);

    final oldestData = await state.oldestSnackbarData();
    await oldestData!.dismiss();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(await oldest, MiuixSnackbarResult.dismissed);
    expect(find.text('Oldest message'), findsNothing);
    expect(find.text('Newest message'), findsNothing);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('snackbar reduced motion snaps entry and exit to endpoints', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    final reduceMotion = ValueNotifier(false);
    addTearDown(state.dispose);
    addTearDown(reduceMotion.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 200,
                  child: MiuixSnackbarHost(
                    state: state,
                    contentBuilder: (context, data) => SizedBox(
                      key: const ValueKey('reduced-motion-snackbar'),
                      height: 48,
                      child: Text(data.visuals.message),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final result = state.showSnackbar(
      'Reduced motion',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final content = find.byKey(const ValueKey('reduced-motion-snackbar'));
    Align entryAlign() => tester
        .widgetList<Align>(
          find.ancestor(of: content, matching: find.byType(Align)),
        )
        .singleWhere((align) => align.heightFactor != null);
    expect(entryAlign().heightFactor, inExclusiveRange(0, 1));

    // Turning the platform setting on during the spring must expose the fully
    // entered terminal frame immediately instead of replaying from the current
    // sampled value.
    reduceMotion.value = true;
    await tester.pump();
    expect(entryAlign().heightFactor, 1);

    await (await state.newestSnackbarData())!.dismiss();
    expect(await result, MiuixSnackbarResult.dismissed);
    await tester.pump();
    await tester.pump();
    expect(content, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar reduced motion preserves direct drag then snaps', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: MiuixSnackbarHost(state: state),
              ),
            ),
          ),
        ),
      ),
    );
    final result = state.showSnackbar(
      'Direct drag',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump();
    final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));
    final initialLeft = tester.getTopLeft(surface).dx;
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, closeTo(initialLeft + 100, .001));

    // Hold long enough that release velocity cannot cross the velocity anchor.
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, closeTo(initialLeft, .001));
    expect(find.text('Direct drag'), findsOneWidget);

    await (await state.newestSnackbarData())!.dismiss();
    await tester.pump();
    await tester.pump();
    expect(await result, MiuixSnackbarResult.dismissed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root snackbar overlay honors reduced motion endpoints', (
    tester,
  ) async {
    late BuildContext overlayContext;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Builder(
              builder: (context) {
                overlayContext = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    final controller = MiuixSnackbar.show(
      overlayContext,
      'Reduced overlay',
      duration: MiuixSnackbarDuration.indefinite,
      withDismissAction: true,
    );
    await tester.pump();
    await tester.pump();
    final message = find.text('Reduced overlay');
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: message, matching: find.byType(Opacity)).first,
    );
    final translation = tester.widget<FractionalTranslation>(
      find
          .ancestor(of: message, matching: find.byType(FractionalTranslation))
          .first,
    );
    expect(opacity.opacity, 1);
    expect(translation.translation, Offset.zero);

    await tester.tap(
      find.byKey(const ValueKey('miuix-snackbar-dismiss-action')),
    );
    await tester.pump();
    await tester.pump();
    await controller.closed;
    expect(message, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar paints newest above an older shrinking entry', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 240,
              height: 220,
              child: MiuixSnackbarHost(
                state: state,
                contentBuilder: (context, data) => Listener(
                  key: ValueKey('paint-${data.visuals.message}'),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(width: 200, height: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final oldest = state.showSnackbar(
      'oldest',
      duration: MiuixSnackbarDuration.indefinite,
    );
    state.showSnackbar('newest', duration: MiuixSnackbarDuration.indefinite);
    await tester.pumpAndSettle();

    // The source gives the newest list entry the greatest zIndex. Dismissing
    // an older entry is the frame where this matters: that entry fades and
    // shrinks from the top with clip=false, so its full child temporarily
    // overlaps the newer surface below it.
    await (await state.oldestSnackbarData())!.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final oldFinder = find.byKey(const ValueKey('paint-oldest'));
    final newFinder = find.byKey(const ValueKey('paint-newest'));
    expect(oldFinder, findsOneWidget);
    expect(newFinder, findsOneWidget);
    final oldRect = tester.getRect(oldFinder);
    final newRect = tester.getRect(newFinder);
    final overlap = oldRect.intersect(newRect);
    expect(overlap.width, greaterThan(0));
    expect(overlap.height, greaterThan(0));

    // RenderFlex hit-tests in reverse paint order. At a shared point only the
    // newest Listener may win, proving the older unclipped child is behind it
    // just like the explicit Compose zIndex ordering.
    final hit = tester.hitTestOnBinding(overlap.center);
    final newestRender = tester.renderObject(newFinder);
    final oldestRender = tester.renderObject(oldFinder);
    expect(hit.path.any((entry) => entry.target == newestRender), isTrue);
    expect(hit.path.any((entry) => entry.target == oldestRender), isFalse);

    await tester.pumpAndSettle();
    expect(await oldest, MiuixSnackbarResult.dismissed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar timer uses Android recommended accessibility timeout', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('flutter_miuix/accessibility');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 80;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            snackbarHost: MiuixSnackbarHost(state: state),
          ),
        ),
      ),
    );
    final result = state.showSnackbar(
      'Accessible timeout',
      actionLabel: 'Undo',
    );
    await tester.pump();
    // The second frame lets the native recommendation future complete and
    // starts its replacement timer, matching SnackbarHost's LaunchedEffect.
    await tester.pump();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'recommendedTimeoutMillis');
    expect(calls.single.arguments, <String, Object>{
      'originalTimeoutMillis': 4000,
      'hasAction': true,
    });
    await tester.pump(const Duration(milliseconds: 79));
    expect(find.text('Accessible timeout'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(await result, MiuixSnackbarResult.dismissed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Accessible timeout'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar defaults to HyperOS glass geometry and styling', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: MiuixSnackbarHost(state: state),
              ),
            ),
          ),
        ),
      ),
    );

    state.showSnackbar(
      'Source message',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pumpAndSettle();

    final surfaceFinder = find.byKey(const ValueKey('miuix-snackbar-surface'));
    final surfaceRect = tester.getRect(surfaceFinder);
    // Snackbar.kt: 12dp outer horizontal padding leaves 376dp of a 400dp host.
    // The current source Row has a 48dp minimum after its 12dp content inset.
    expect(surfaceRect.width, 376);
    expect(surfaceRect.height, 48);

    final surface = tester.widget<DecoratedBox>(surfaceFinder);
    final decoration = surface.decoration as ShapeDecoration;
    final context = tester.element(surfaceFinder);
    final semantic = MiuixSemanticColors.of(context);
    final background = tester.widget<MiuixGlass>(
      find.descendant(of: surfaceFinder, matching: find.byType(MiuixGlass)),
    );
    expect(background.color, semantic['onSecondaryVariant']);
    expect(background.blur, 24);
    expect(background.opacity, .72);
    expect(background.optics, same(MiuixGlassOptics.transient));
    // Snackbar.kt applies dropShadow to RoundedCornerShape before the nested
    // squircleBackground paints the actual fill.
    expect(decoration.shape, isA<RoundedRectangleBorder>());
    final shape = decoration.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(24));
    final shadows = decoration.shadows!;
    expect(shadows, hasLength(1));
    expect(shadows.single.blurRadius, 10);
    expect(shadows.single.spreadRadius, 0);
    expect(shadows.single.offset, Offset.zero);
    expect(shadows.single.color, Colors.black.withValues(alpha: .1));

    await (await state.newestSnackbarData())!.dismiss();
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Source message',
      actionLabel: '撤销',
      withDismissAction: true,
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pumpAndSettle();
    // The current source action pill has a 26dp minimum and zero vertical
    // action inset. The snackbar's 12dp vertical inset makes the row 50dp.
    expect(tester.getRect(surfaceFinder).height, 50);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-snackbar-action')))
          .height,
      26,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-snackbar-dismiss-action')),
      ),
      const Size.square(20),
    );

    // The current host enables two-way anchored swipe dismissal by default.
    await tester.drag(surfaceFinder, const Offset(360, 0));
    await tester.pumpAndSettle();
    expect(find.text('Source message'), findsNothing);
  });

  test('snackbar value models retain source data-class equality', () {
    const colors = MiuixSnackbarColors(
      containerColor: Color(0xFF102030),
      contentColor: Color(0xFF405060),
      actionContentColor: Color(0xFF708090),
      dismissActionContentColor: Color(0xFFA0B0C0),
      actionContainerColor: Color(0xFFD0E0F0),
    );
    expect(
      MiuixSnackbarDuration.custom(const Duration(milliseconds: 1250)),
      MiuixSnackbarDuration.custom(const Duration(milliseconds: 1250)),
    );
    expect(
      const MiuixSnackbarVisuals(
        message: 'Saved',
        actionLabel: 'Undo',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.long,
      ),
      const MiuixSnackbarVisuals(
        message: 'Saved',
        actionLabel: 'Undo',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.long,
      ),
    );
    expect(
      colors,
      const MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF405060),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      ),
    );
    expect(
      colors.copyWith(contentColor: const Color(0xFF112233)),
      const MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF112233),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      ),
    );
    expect(
      () => MiuixSnackbarDuration.custom(Duration.zero),
      throwsArgumentError,
    );
  });

  testWidgets(
    'snackbar anchored swipe uses both source directions and opt-out',
    (tester) async {
      final state = MiuixSnackbarHostState();
      final swipeEnabled = ValueNotifier(true);
      addTearDown(state.dispose);
      addTearDown(swipeEnabled.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                height: 240,
                child: ValueListenableBuilder<bool>(
                  valueListenable: swipeEnabled,
                  builder: (context, enabled, _) => MiuixSnackbarHost(
                    state: state,
                    canSwipeToDismiss: enabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final first = state.showSnackbar(
        'Anchored swipe',
        duration: MiuixSnackbarDuration.indefinite,
      );
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));

      // A slow drag below half the 400dp entry width settles back to zero.
      await tester.timedDrag(
        surface,
        const Offset(150, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('Anchored swipe'), findsOneWidget);

      // Crossing the source 50-percent anchor dismisses toward either side.
      await tester.timedDrag(
        surface,
        const Offset(-240, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(await first, MiuixSnackbarResult.dismissed);
      expect(find.text('Anchored swipe'), findsNothing);

      swipeEnabled.value = false;
      await tester.pump();
      final second = state.showSnackbar(
        'Swipe disabled',
        duration: MiuixSnackbarDuration.indefinite,
      );
      await tester.pumpAndSettle();
      await tester.drag(surface, const Offset(360, 0));
      await tester.pumpAndSettle();
      expect(find.text('Swipe disabled'), findsOneWidget);
      await (await state.newestSnackbarData())!.dismiss();
      await tester.pumpAndSettle();
      expect(await second, MiuixSnackbarResult.dismissed);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('snackbar horizontal drag owns the gesture above a pager', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    final pager = PageController();
    var selectedPage = 0;
    addTearDown(state.dispose);
    addTearDown(pager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 400,
              height: 260,
              child: MiuixSnackbarHost(
                state: state,
                child: PageView(
                  controller: pager,
                  onPageChanged: (value) => selectedPage = value,
                  children: const [
                    ColoredBox(color: Colors.white, child: Text('Page zero')),
                    ColoredBox(color: Colors.blue, child: Text('Page one')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final result = state.showSnackbar(
      'Pager-safe swipe',
      duration: MiuixSnackbarDuration.indefinite,
    );
    MiuixSnackbarResult? completion;
    unawaited(result.then((value) => completion = value));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));

    // The 240dp drag crosses the snackbar's 50% anchor and would also be
    // enough to select Page one if the ancestor PageView won the gesture.
    final initialLeft = tester.getTopLeft(surface).dx;
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, lessThan(initialLeft - 50));
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectedPage, 0);
    expect(pager.page, 0);
    expect(find.text('Pager-safe swipe'), findsNothing);
    expect(completion, MiuixSnackbarResult.dismissed);
    expect(find.text('Page zero'), findsOneWidget);
    expect(find.text('Page one'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'snackbar source widget exposes colors radius and inside margin',
    (tester) async {
      final state = MiuixSnackbarHostState();
      addTearDown(state.dispose);
      state.showSnackbar(
        'Source contract',
        actionLabel: '执行',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.indefinite,
      );
      final data = await state.newestSnackbarData();
      const colors = MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF405060),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                child: MiuixSnackbar(
                  data: data!,
                  cornerRadius: 20,
                  colors: colors,
                  insideMargin: const EdgeInsets.fromLTRB(20, 10, 24, 12),
                  glass: false,
                ),
              ),
            ),
          ),
        ),
      );

      final surfaceFinder = find.byKey(
        const ValueKey('miuix-snackbar-surface'),
      );
      final surface = tester.widget<DecoratedBox>(surfaceFinder);
      final decoration = surface.decoration as ShapeDecoration;
      final defaults = MiuixSnackbarDefaults.snackbarColors(
        tester.element(surfaceFinder),
        containerColor: const Color(0xFF010203),
      );
      expect(defaults.containerColor, const Color(0xFF010203));
      expect(
        defaults.contentColor,
        MiuixSemanticColors.of(
          tester.element(surfaceFinder),
        )['secondaryVariant'],
      );
      expect(
        defaults.actionContentColor,
        MiuixSemanticColors.of(tester.element(surfaceFinder))['onPrimary'],
      );
      expect(
        defaults.dismissActionContentColor,
        MiuixSemanticColors.of(
          tester.element(surfaceFinder),
        )['onSurfaceContainerVariant'],
      );
      expect(
        defaults.actionContainerColor,
        MiuixSemanticColors.of(tester.element(surfaceFinder))['primary'],
      );
      final background = tester.widget<MiuixSquircleBackground>(
        find.descendant(
          of: surfaceFinder,
          matching: find.byType(MiuixSquircleBackground),
        ),
      );
      expect(background.color, colors.containerColor);
      expect(
        (decoration.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(20),
      );
      expect(
        tester.widget<Text>(find.text('Source contract')).style?.color,
        colors.contentColor,
      );
      expect(
        tester.widget<Text>(find.text('执行')).style?.color,
        colors.actionContentColor,
      );
      expect(tester.getSize(surfaceFinder).height, 48);
      final dismissFinder = find.byKey(
        const ValueKey('miuix-snackbar-dismiss-action'),
      );
      final dismissSemantics = tester.getSemantics(dismissFinder);
      expect(
        dismissSemantics,
        matchesSemantics(
          label: 'Dismiss',
          isImage: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      // Modifier.size(20.dp).clickable() retains a 20dp glyph but Android's
      // Compose touch-bounds expansion publishes a separate 48dp target.
      expect(dismissSemantics.rect.size, const Size.square(48));
      expect(
        tester.getSize(find.byIcon(MiuixIcons.basic.close)),
        const Size.square(20),
      );
    },
  );

  testWidgets('empty snackbar action label does not create an action button', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    state.showSnackbar(
      'Empty action',
      actionLabel: '',
      duration: MiuixSnackbarDuration.indefinite,
    );
    final data = await state.newestSnackbarData();

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SizedBox(width: 400, child: MiuixSnackbar(data: data!)),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('miuix-snackbar-action')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-snackbar-surface')))
          .height,
      48,
    );
  });

  testWidgets('extended scaffold keeps snackbar above animated bottom bar', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            snackbarHost: MiuixSnackbarHost(
              state: state,
              contentBuilder: (context, data) => SizedBox(
                key: const ValueKey('measured-snackbar-surface'),
                height: 48,
                child: Text(data.visuals.message),
              ),
            ),
            bottomBar: const AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey('measured-bottom-navigation'),
                height: 96,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Navigation-safe feedback',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final snackbar = tester.getRect(
      find.byKey(const ValueKey('measured-snackbar-surface')),
    );
    final bottomBar = tester.getRect(
      find.byKey(const ValueKey('measured-bottom-navigation')),
    );
    expect(
      find.byKey(const ValueKey('miuix-scaffold-snackbar-layer')),
      findsOneWidget,
    );
    // The host adds its own 12dp visual gap. The essential contract is that
    // even the complete custom surface ends before navigation begins.
    expect(snackbar.bottom, lessThan(bottomBar.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar stays above the floating tab and gesture region', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final state = MiuixSnackbarHostState();
    var selectedDestination = -1;
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            snackbarHost: MiuixSnackbarHost(
              state: state,
              contentBuilder: (context, data) => SizedBox(
                key: const ValueKey('floating-safe-snackbar'),
                height: 48,
                child: Text(data.visuals.message),
              ),
            ),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (index) => selectedDestination = index,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Floating-safe feedback',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    final snackbar = tester.getRect(
      find.byKey(const ValueKey('floating-safe-snackbar')),
    );
    final pill = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    expect(
      find.byKey(const ValueKey('miuix-scaffold-snackbar-layer')),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
    expect(snackbar.bottom, lessThan(pill.top));
    // The elevated host occupies only the message region. Its transparent
    // surroundings must never become a full-screen pointer barrier.
    await tester.tap(find.byIcon(Icons.settings));
    expect(selectedDestination, 1);
    expect(tester.takeException(), isNull);
  });
}
