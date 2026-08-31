part of '../miuix_flutter_test.dart';

void _registerHapticTests() {
  group('source haptics', () {
    const channel = MethodChannel('flutter_miuix/haptics');
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return true;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    String lastType() =>
        (calls.last.arguments as Map<Object?, Object?>)['type']! as String;

    testWidgets('combined-clickable card emits the source long-press role', (
      tester,
    ) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixCard.source(
                content: const SizedBox(width: 180, height: 72),
                onLongPress: () => longPressed = true,
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(MiuixCard));
      await tester.pump();
      expect(longPressed, isTrue);
      expect(calls, hasLength(1));
      expect(lastType(), 'longPress');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('switch checkbox and radio emit source toggle roles', (
      tester,
    ) async {
      var switchValue = false;
      var checkboxValue = false;
      var radioValue = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  MiuixSwitch(
                    value: switchValue,
                    onChanged: (value) => setState(() => switchValue = value),
                  ),
                  MiuixCheckbox(
                    value: checkboxValue,
                    onChanged: (value) =>
                        setState(() => checkboxValue = value ?? false),
                  ),
                  MiuixRadio<int>(
                    value: 1,
                    groupValue: radioValue,
                    onChanged: (value) =>
                        setState(() => radioValue = value ?? 0),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MiuixSwitch));
      await tester.pump();
      expect(lastType(), 'toggleOn');
      await tester.tap(find.byType(MiuixCheckbox));
      await tester.pump();
      expect(lastType(), 'toggleOn');
      await tester.tap(find.byType(MiuixRadio<int>));
      await tester.pump();
      expect(lastType(), 'toggleOn');
      expect(calls, hasLength(3));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('indeterminate checkbox emits the source segment role', (
      tester,
    ) async {
      var clicks = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixCheckbox.tristate(
                state: null,
                onClick: () => clicks += 1,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(MiuixCheckbox));
      await tester.pump();
      expect(clicks, 1);
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('popup selection vibrates only across a state boundary', (
      tester,
    ) async {
      var selections = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixListPopup<String>(
                entries: const [MiuixDropdownEntry(value: 'one', label: 'One')],
                onSelected: (_) => selections += 1,
              ),
            ),
          ),
        ),
      );

      final surface = tester.widget<MiuixSurface>(
        find.descendant(
          of: find.byType(MiuixListPopup<String>),
          matching: find.byType(MiuixSurface),
        ),
      );
      expect(surface.glass, isTrue);
      expect(surface.radius, 20);
      expect(surface.glassBlur, 24);
      expect(surface.glassOpacity, .66);

      await tester.tap(find.text('One'));
      await tester.pump();
      expect(selections, 1);
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');

      await tester.tap(find.text('One'));
      await tester.pump();
      expect(selections, 2);
      expect(calls, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('HyperOS navigation rail ticks only on destination changes', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                height: 280,
                child: MiuixNavigationRail(
                  defaultWindowInsetsPadding: false,
                  selectedIndex: selected,
                  onDestinationSelected: (index) =>
                      setState(() => selected = index),
                  items: const [
                    MiuixNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(calls, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('floating navigation drag ticks once per crossed tab', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: MiuixFloatingNavigationBar(
                  defaultWindowInsetsPadding: false,
                  selectedIndex: selected,
                  onDestinationSelected: (index) =>
                      setState(() => selected = index),
                  items: const <MiuixNavigationItem>[
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final first = find.byKey(const ValueKey('floating-navigation-item-0'));
      final gesture = await tester.startGesture(tester.getCenter(first));
      await gesture.moveBy(const Offset(88, 0));
      await tester.pump();
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');

      // Motion inside the same destination must not repeat the haptic.
      await gesture.moveBy(const Offset(12, 0));
      await tester.pump();
      expect(calls, hasLength(1));
      await gesture.moveBy(const Offset(76, 0));
      await tester.pump();
      expect(calls, hasLength(2));
      expect(lastType(), 'segmentTick');

      await gesture.up();
      await tester.pumpAndSettle();
      expect(selected, 2);
      expect(calls, hasLength(2));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('liquid navigation ticks once when a gesture commits', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: MiuixIosLiquidGlassNavigationBar(
                  defaultWindowInsetsPadding: false,
                  selectedIndex: selected,
                  onDestinationSelected: (index) =>
                      setState(() => selected = index),
                  items: const <MiuixNavigationItem>[
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-0')));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
      await tester.pump();
      expect(selected, 2);
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');
      await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
      await tester.pump();
      expect(calls, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('HyperOS tab row ticks while source tab row stays exact', (
      tester,
    ) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  MiuixTabRow(
                    tabs: const ['One', 'Two'],
                    selectedTabIndex: selected,
                    onTabSelected: (index) => setState(() => selected = index),
                  ),
                  MiuixTabRow.source(
                    tabs: const ['Legacy one', 'Legacy two'],
                    selectedTabIndex: selected,
                    onTabSelected: (index) => setState(() => selected = index),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('One'));
      await tester.pump();
      expect(calls, isEmpty);
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(calls, hasLength(1));
      expect(lastType(), 'segmentTick');
      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(calls, hasLength(1));
      await tester.tap(find.text('Legacy one'));
      await tester.pump();
      expect(calls, hasLength(1));
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('inline feedback dismiss actions emit the toggle-off role', (
      tester,
    ) async {
      var dismissals = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Column(
              children: <Widget>[
                MiuixInlineAlert(
                  message: 'Alert',
                  onDismissed: () => dismissals += 1,
                ),
                MiuixBanner(
                  title: 'Banner',
                  message: 'Message',
                  onDismissed: () => dismissals += 1,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pump();
      expect(dismissals, 2);
      expect(calls, hasLength(2));
      expect(
        calls
            .map(
              (call) =>
                  (call.arguments as Map<Object?, Object?>)['type'] as String,
            )
            .toList(),
        const <String>['toggleOff', 'toggleOff'],
      );
      expect(lastType(), 'toggleOff');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'preference rows stay silent while embedded controls own haptics',
      (tester) async {
        var switchValue = false;
        var checkboxValue = false;
        var radioValue = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              child: StatefulBuilder(
                builder: (context, setState) => Column(
                  children: [
                    MiuixSwitchPreference(
                      title: 'Switch preference',
                      value: switchValue,
                      onChanged: (value) => setState(() => switchValue = value),
                    ),
                    MiuixCheckboxPreference(
                      title: 'Checkbox preference',
                      value: checkboxValue,
                      onChanged: (value) =>
                          setState(() => checkboxValue = value),
                    ),
                    MiuixRadioButtonPreference<int>(
                      title: 'Radio preference',
                      value: 1,
                      groupValue: radioValue,
                      onChanged: (value) =>
                          setState(() => radioValue = value ?? 0),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        // The source BasicComponent row path only invokes the state callback.
        // Haptics live inside Switch/Checkbox/RadioButton and therefore must
        // remain absent when the label area activates the preference.
        await tester.tap(find.text('Switch preference'));
        await tester.pump();
        expect(switchValue, isTrue);
        expect(calls, isEmpty);
        await tester.tap(find.byType(MiuixSwitch));
        await tester.pump();
        expect(switchValue, isFalse);
        expect(lastType(), 'toggleOff');

        calls.clear();
        await tester.tap(find.text('Checkbox preference'));
        await tester.pump();
        expect(checkboxValue, isTrue);
        expect(calls, isEmpty);
        await tester.tap(find.byType(MiuixCheckbox));
        await tester.pump();
        expect(checkboxValue, isFalse);
        expect(lastType(), 'toggleOff');

        calls.clear();
        await tester.tap(find.text('Radio preference'));
        await tester.pump();
        expect(radioValue, 1);
        expect(calls, isEmpty);
        await tester.tap(find.byType(MiuixRadio<int>));
        await tester.pump();
        expect(radioValue, 1);
        expect(lastType(), 'toggleOff');
        expect(calls, hasLength(1));
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('source spinner popup and dialog use current haptic roles', (
      tester,
    ) async {
      var popupIndex = 0;
      var dialogIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => MiuixTheme(
              child: Scaffold(
                body: Column(
                  children: [
                    MiuixWindowSpinnerPreference.source(
                      title: '震动弹出选择器',
                      items: const [
                        MiuixSpinnerEntry(title: '弹出项一'),
                        MiuixSpinnerEntry(title: '弹出项二'),
                      ],
                      selectedIndex: popupIndex,
                      onSelectedIndexChange: (index) {
                        setState(() => popupIndex = index);
                      },
                    ),
                    MiuixWindowSpinnerPreference.source(
                      title: '震动对话框选择器',
                      items: const [
                        MiuixSpinnerEntry(title: '对话框项一'),
                        MiuixSpinnerEntry(title: '对话框项二'),
                      ],
                      selectedIndex: dialogIndex,
                      dialogButtonString: '取消',
                      onSelectedIndexChange: (index) {
                        setState(() => dialogIndex = index);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('震动弹出选择器'));
      await tester.pumpAndSettle();
      expect(lastType(), 'contextClick');
      await tester.tap(find.text('弹出项二'));
      await tester.pumpAndSettle();
      expect(popupIndex, 1);
      expect(
        calls.map((call) => call.method),
        everyElement('performHapticFeedback'),
      );
      expect(lastType(), 'confirm');

      calls.clear();
      await tester.tap(find.text('震动对话框选择器'));
      await tester.pumpAndSettle();
      expect(calls, hasLength(1));
      expect(lastType(), 'contextClick');
      await tester.tap(find.text('对话框项二'));
      await tester.pumpAndSettle();
      expect(dialogIndex, 1);
      expect(calls, hasLength(2));
      expect(lastType(), 'confirm');
      expect(tester.takeException(), isNull);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('switch drag vibrates at both source endpoints', (
      tester,
    ) async {
      var value = false;
      String callType(MethodCall call) =>
          (call.arguments as Map<Object?, Object?>)['type']! as String;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: MiuixSwitch(
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              ),
            ),
          ),
        ),
      );

      final track = find.byKey(const ValueKey('miuix-switch-track'));
      final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
      await tester.dragFrom(
        tester.getCenter(thumb),
        const Offset(80, 0),
        view: tester.view,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx,
        greaterThan(20),
      );
      expect(calls.map(callType), ['toggleOn']);

      // A committed drag in the reverse direction uses the opposite role.
      await tester.dragFrom(
        tester.getCenter(thumb),
        const Offset(-80, 0),
        view: tester.view,
      );
      await tester.pumpAndSettle();
      expect(calls.map(callType), ['toggleOn', 'toggleOff']);
      expect(value, isFalse);
      debugDefaultTargetPlatformOverride = null;
    });

    test('switch drag can return to its original endpoint in one gesture', () {
      expect(
        debugMiuixSwitchDragFeedbackValues(
          checked: false,
          offsets: const [5, 21, 15, 10, 5, 0],
          stoppedOffset: 0,
        ),
        const [true, false],
      );
      expect(
        debugMiuixSwitchDragFeedbackValues(
          checked: true,
          offsets: const [-5, -21, -15, -10, -5, 0],
          stoppedOffset: 0,
        ),
        const [false, true],
      );

      // Switch.kt uses 10/11dp for haptic roles while committing the value at
      // 10.5dp, intentionally leaving this fractional release gap silent.
      expect(
        debugMiuixSwitchDragFeedbackValues(
          checked: false,
          offsets: const [10.5],
          stoppedOffset: 10.5,
        ),
        isEmpty,
      );
    });

    testWidgets('slider emits step ticks and a distinct edge threshold', (
      tester,
    ) async {
      var value = 0.0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: SizedBox(
                  width: 240,
                  child: MiuixSlider(
                    value: value,
                    divisions: 4,
                    hapticEffect: MiuixSliderHapticEffect.step,
                    onChanged: (next) => setState(() => value = next),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final rect = tester.getRect(find.byType(MiuixSlider));
      final available = rect.width - 28;
      final firstThumb = Offset(rect.left + 14, rect.center.dy);
      await tester.timedDragFrom(
        firstThumb,
        Offset(available * .5, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(lastType(), 'textHandleMove');
      await tester.timedDragFrom(
        Offset(firstThumb.dx + available * .5, firstThumb.dy),
        Offset(available * .5, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(lastType(), 'gestureThresholdActivate');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('color channels emit the source edge-threshold role', (
      tester,
    ) async {
      Color color = Colors.red;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Center(
                child: SizedBox(
                  width: 280,
                  child: MiuixColorPicker(
                    color: color,
                    onChanged: (next) => setState(() => color = next),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final channel = find.byKey(
        const ValueKey('miuix-color-picker-hue-slider'),
      );
      final rect = tester.getRect(channel);
      await tester.timedDragFrom(
        rect.center,
        Offset(rect.width, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(lastType(), 'gestureThresholdActivate');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('color channels honor source none and step haptic modes', (
      tester,
    ) async {
      Future<void> pumpChannel(MiuixSliderHapticEffect effect) {
        return tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              child: Center(
                child: SizedBox(
                  width: 280,
                  child: MiuixHsvHueSlider(
                    value: 180,
                    hapticEffect: effect,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
      }

      await pumpChannel(MiuixSliderHapticEffect.none);
      var channel = find.byKey(const ValueKey('miuix-color-channel-slider'));
      var rect = tester.getRect(channel);
      await tester.timedDragFrom(
        rect.center,
        Offset(rect.width, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(calls, isEmpty);

      await pumpChannel(MiuixSliderHapticEffect.step);
      calls.clear();
      channel = find.byKey(const ValueKey('miuix-color-channel-slider'));
      rect = tester.getRect(channel);
      await tester.timedDragFrom(
        rect.center,
        const Offset(24, 0),
        const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(calls, isNotEmpty);
      expect(lastType(), 'textHandleMove');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets(
      'number picker emits a source text-handle tick while dragging',
      (tester) async {
        var value = 2;
        await tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              child: StatefulBuilder(
                builder: (context, setState) => Center(
                  child: MiuixNumberPicker(
                    value: value,
                    min: 0,
                    max: 6,
                    onChanged: (next) => setState(() => value = next),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.drag(
          find.byKey(const ValueKey('miuix-number-picker-wheel')),
          const Offset(0, -80),
        );
        await tester.pumpAndSettle();
        expect(calls, isNotEmpty);
        expect(
          calls.map((call) => call.arguments),
          contains(containsPair('type', 'textHandleMove')),
        );
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets(
      'number picker reset stays silent when its owner ignores the value',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              child: Center(
                child: MiuixNumberPicker(
                  value: 2,
                  min: 0,
                  max: 6,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        );

        await tester.timedDrag(
          find.byKey(const ValueKey('miuix-number-picker-wheel')),
          const Offset(0, -46),
          const Duration(seconds: 1),
        );
        await tester.pumpAndSettle();
        final tickCalls = calls.where(
          (call) =>
              (call.arguments as Map<Object?, Object?>)['type'] ==
              'textHandleMove',
        );
        // NumberPicker.kt clears isUserScrolling before snapTo(0), so the
        // transient reset cannot produce a reverse boundary tick.
        expect(tickCalls, hasLength(1));
        debugDefaultTargetPlatformOverride = null;
      },
    );

    testWidgets('pull-to-refresh emits the source threshold role', (
      tester,
    ) async {
      final listKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixPullToRefresh(
              onRefresh: () async {},
              child: ListView(
                key: listKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 1000)],
              ),
            ),
          ),
        ),
      );
      final context = listKey.currentContext!;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 200,
        pixels: 0,
        viewportDimension: 600,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: -180,
        velocity: 0,
      ).dispatch(context);
      await tester.pump();

      expect(lastType(), 'gestureThresholdActivate');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('dropdown preferences emit context-open and confirm roles', (
      tester,
    ) async {
      var value = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => MiuixDropdownPreference<int>(
                title: 'Dropdown',
                value: value,
                entries: const [
                  MiuixDropdownEntry(value: 1, label: 'One'),
                  MiuixDropdownEntry(value: 2, label: 'Two'),
                ],
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dropdown'));
      await tester.pumpAndSettle();
      expect(calls.first.arguments, containsPair('type', 'contextClick'));
      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();
      expect(lastType(), 'confirm');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('source dropdown rows confirm even when reselecting a value', (
      tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixListPopup<int>(
              entries: const [
                MiuixDropdownEntry(
                  value: 1,
                  label: 'Selected source row',
                  selected: true,
                ),
              ],
              sourceRows: true,
              onSelected: selected.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Selected source row'));
      await tester.pump();
      expect(selected, [1]);
      expect(lastType(), 'confirm');
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('scroll boundary haptic preserves source fling thresholds', (
      tester,
    ) async {
      const targetKey = ValueKey('haptic-notification-target');
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixScrollEndHaptic(
            hapticType: MiuixHapticType.confirm,
            child: SizedBox(key: targetKey, height: 200),
          ),
        ),
      );
      final context = tester.element(find.byKey(targetKey));
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        pixels: 100,
        viewportDimension: 200,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );

      // Source onPostFling requires more than one pixel of unconsumed motion.
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: .5,
        velocity: 100,
      ).dispatch(context);
      await tester.pump();
      expect(calls, isEmpty);

      // Its consumed-velocity filter is abs(value) < 25, so the exact 25px/s
      // boundary is accepted while a slower fling and an ordinary drag are
      // silent.
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 24.9,
      ).dispatch(context);
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 0,
      ).dispatch(context);
      await tester.pump();
      expect(calls, isEmpty);
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 25,
      ).dispatch(context);
      await tester.pump();
      expect(lastType(), 'confirm');

      // Repeated flings at the same boundary remain silent. Input in the same
      // direction and the exact one-pixel reverse threshold do not rearm it.
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 100,
      ).dispatch(context);
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: 2,
      ).dispatch(context);
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: -1,
      ).dispatch(context);
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 100,
      ).dispatch(context);
      await tester.pump();
      expect(calls, hasLength(1));

      // Moving away from the bottom by strictly more than one pixel mirrors
      // onPreScroll and allows one new feedback event.
      ScrollUpdateNotification(
        metrics: metrics,
        context: context,
        scrollDelta: -1.1,
      ).dispatch(context);
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 2,
        velocity: 100,
      ).dispatch(context);
      await tester.pump();
      expect(calls, hasLength(2));
      expect(lastType(), 'confirm');
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
