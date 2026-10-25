part of '../miuix_flutter_test.dart';

// 开关、复选框和单选框共同验证选择控件约定。
void _registerSelectionControlTests() {
  testWidgets('custom selection controls toggle without Material wrappers', (
    tester,
  ) async {
    var switchValue = false;
    var checkboxValue = false;
    var radioValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
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
                    const MiuixSwitch(
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixCheckbox(
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixRadio<int>(
                      value: 2,
                      groupValue: 1,
                      enabled: false,
                      onChanged: null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixSwitch).first);
    await tester.tap(find.byType(MiuixCheckbox).first);
    await tester.tap(find.byType(MiuixRadio<int>).first);
    await tester.pumpAndSettle();

    expect(switchValue, isTrue);
    expect(checkboxValue, isTrue);
    expect(radioValue, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selection controls expand enabled targets without changing layout',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const enabledCheckboxKey = ValueKey('enabled-checkbox-target');
      const disabledCheckboxKey = ValueKey('disabled-checkbox-target');
      const disabledCallbackCheckboxKey = ValueKey(
        'disabled-callback-checkbox-target',
      );
      const enabledRadioKey = ValueKey('enabled-radio-target');
      const disabledRadioKey = ValueKey('disabled-radio-target');
      const disabledCallbackRadioKey = ValueKey(
        'disabled-callback-radio-target',
      );
      var checkboxValue = false;
      var radioValue = 0;
      var disabledCheckboxCalls = 0;
      var disabledRadioCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: enabledCheckboxKey,
                              value: checkboxValue,
                              onChanged: (value) => setState(
                                () => checkboxValue = value ?? false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: disabledCheckboxKey,
                              value: false,
                              enabled: false,
                              onChanged: null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: disabledCallbackCheckboxKey,
                              value: true,
                              enabled: false,
                              onChanged: (_) => disabledCheckboxCalls++,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: enabledRadioKey,
                              value: 1,
                              groupValue: radioValue,
                              onChanged: (value) =>
                                  setState(() => radioValue = value ?? 0),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: disabledRadioKey,
                              value: 2,
                              groupValue: 0,
                              enabled: false,
                              onChanged: null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: disabledCallbackRadioKey,
                              value: 3,
                              groupValue: 3,
                              enabled: false,
                              onChanged: (_) => disabledRadioCalls++,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      Finder semanticTarget(Finder control, ValueKey<String> key) =>
          find.descendant(of: control, matching: find.byKey(key));
      final enabledCheckbox = find.byKey(enabledCheckboxKey);
      final disabledCheckbox = find.byKey(disabledCheckboxKey);
      final disabledCallbackCheckbox = find.byKey(disabledCallbackCheckboxKey);
      final enabledRadio = find.byKey(enabledRadioKey);
      final disabledRadio = find.byKey(disabledRadioKey);
      final disabledCallbackRadio = find.byKey(disabledCallbackRadioKey);
      final enabledCheckboxSemantics = semanticTarget(
        enabledCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final disabledCheckboxSemantics = semanticTarget(
        disabledCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final disabledCallbackCheckboxSemantics = semanticTarget(
        disabledCallbackCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final enabledRadioSemantics = semanticTarget(
        enabledRadio,
        const ValueKey('miuix-radio-semantics'),
      );
      final disabledRadioSemantics = semanticTarget(
        disabledRadio,
        const ValueKey('miuix-radio-semantics'),
      );
      final disabledCallbackRadioSemantics = semanticTarget(
        disabledCallbackRadio,
        const ValueKey('miuix-radio-semantics'),
      );

      // Compose measures every control at 26dp, then expands only interactive
      // pointer and accessibility bounds to the platform 48dp minimum.
      for (final control in [
        enabledCheckbox,
        disabledCheckbox,
        disabledCallbackCheckbox,
        enabledRadio,
        disabledRadio,
        disabledCallbackRadio,
      ]) {
        expect(
          tester.getSize(control).width * sourceDensity,
          closeTo(68, .001),
        );
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(68, .001),
        );
      }
      for (final target in [
        enabledCheckboxSemantics,
        disabledCallbackCheckboxSemantics,
        enabledRadioSemantics,
        disabledCallbackRadioSemantics,
      ]) {
        expect(
          tester.getRect(target).width * sourceDensity,
          closeTo(126, .001),
        );
        expect(
          tester.getRect(target).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      for (final target in [
        disabledCheckboxSemantics,
        disabledRadioSemantics,
      ]) {
        expect(tester.getRect(target).width * sourceDensity, closeTo(68, .001));
        expect(
          tester.getRect(target).height * sourceDensity,
          closeTo(68, .001),
        );
      }

      // Twenty logical pixels is outside the 13dp visual radius but inside the
      // expanded 24dp hit radius, so these taps prove the target is functional.
      await tester.tapAt(
        tester.getRect(enabledCheckboxSemantics).center + const Offset(20, 0),
      );
      await tester.tapAt(
        tester.getRect(enabledRadioSemantics).center + const Offset(20, 0),
      );
      await tester.tapAt(
        tester.getRect(disabledCallbackCheckboxSemantics).center,
      );
      await tester.tapAt(tester.getRect(disabledCallbackRadioSemantics).center);
      await tester.pumpAndSettle();
      expect(checkboxValue, isTrue);
      expect(radioValue, 1);
      expect(disabledCheckboxCalls, 0);
      expect(disabledRadioCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('switch exposes the exact MIUIX motion springs', () {
    final offset = debugMiuixSwitchThumbOffsetSpring();
    final scale = debugMiuixSwitchThumbScaleSpring();
    final track = debugMiuixSwitchTrackColorSpring();
    final thumbColor = debugMiuixSwitchThumbColorSpring();

    expect(offset.stiffness, 987);
    expect(offset.damping, closeTo(2 * math.sqrt(987) * .7, .0001));
    expect(scale.stiffness, 987);
    expect(scale.damping, closeTo(2 * math.sqrt(987) * .6, .0001));
    expect(track.stiffness, 438.6);
    expect(track.damping, closeTo(2 * math.sqrt(438.6) * .99, .0001));
    expect(thumbColor.stiffness, 1500);
    expect(thumbColor.damping, closeTo(2 * math.sqrt(1500), .0001));
  });

  test('switch colors preserve all eight source data channels', () {
    const colors = MiuixSwitchColors(
      checkedThumbColor: Color(0xFF000001),
      uncheckedThumbColor: Color(0xFF000002),
      disabledCheckedThumbColor: Color(0xFF000003),
      disabledUncheckedThumbColor: Color(0xFF000004),
      checkedTrackColor: Color(0xFF000005),
      uncheckedTrackColor: Color(0xFF000006),
      disabledCheckedTrackColor: Color(0xFF000007),
      disabledUncheckedTrackColor: Color(0xFF000008),
    );
    expect(colors.thumb(checked: true, enabled: true), const Color(0xFF000001));
    expect(
      colors.thumb(checked: false, enabled: true),
      const Color(0xFF000002),
    );
    expect(
      colors.thumb(checked: true, enabled: false),
      const Color(0xFF000003),
    );
    expect(
      colors.thumb(checked: false, enabled: false),
      const Color(0xFF000004),
    );
    expect(colors.track(checked: true, enabled: true), const Color(0xFF000005));
    expect(
      colors.track(checked: false, enabled: true),
      const Color(0xFF000006),
    );
    expect(
      colors.track(checked: true, enabled: false),
      const Color(0xFF000007),
    );
    expect(
      colors.track(checked: false, enabled: false),
      const Color(0xFF000008),
    );
    expect(colors.copyWith(), colors);
    expect(MiuixSwitchDefaults.width, 49);
    expect(MiuixSwitchDefaults.height, 28);
    expect(MiuixSwitchDefaults.thumbSize, 20);
    expect(MiuixSwitchDefaults.dragDistance, 21);
  });

  testWidgets('switch source adapter and custom colors drive real painting', (
    tester,
  ) async {
    late MiuixSwitchColors defaults;
    var value = false;
    const custom = MiuixSwitchColors(
      checkedThumbColor: Color(0xFF102030),
      uncheckedThumbColor: Color(0xFF203040),
      disabledCheckedThumbColor: Color(0xFF304050),
      disabledUncheckedThumbColor: Color(0xFF405060),
      checkedTrackColor: Color(0xFF506070),
      uncheckedTrackColor: Color(0xFF607080),
      disabledCheckedTrackColor: Color(0xFF708090),
      disabledUncheckedTrackColor: Color(0xFF8090A0),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixSwitchDefaults.switchColors(context);
              return StatefulBuilder(
                builder: (context, setState) => MiuixSwitch.source(
                  checked: value,
                  onCheckedChange: (next) => setState(() => value = next),
                  colors: custom,
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(
      defaults.checkedTrackColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledUncheckedThumbColor,
      const MiuixSemanticColors.light()['disabledOnSecondary'],
    );
    BoxDecoration trackDecoration() =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-track')),
                )
                .decoration
            as BoxDecoration;
    BoxDecoration thumbDecoration() =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-thumb')),
                )
                .decoration
            as BoxDecoration;
    expect(
      trackDecoration().color?.toARGB32(),
      custom.uncheckedTrackColor.toARGB32(),
    );
    expect(
      thumbDecoration().color?.toARGB32(),
      custom.uncheckedThumbColor.toARGB32(),
    );
    await tester.tap(find.byType(MiuixSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(
      trackDecoration().color?.toARGB32(),
      custom.checkedTrackColor.toARGB32(),
    );
    expect(
      thumbDecoration().color?.toARGB32(),
      custom.checkedThumbColor.toARGB32(),
    );
    expect(tester.takeException(), isNull);
  });

  test('checkbox colors preserve all eight source data channels', () {
    const colors = MiuixCheckboxColors(
      checkedForegroundColor: Color(0xFF000001),
      uncheckedForegroundColor: Color(0xFF000002),
      disabledCheckedForegroundColor: Color(0xFF000003),
      disabledUncheckedForegroundColor: Color(0xFF000004),
      checkedBackgroundColor: Color(0xFF000005),
      uncheckedBackgroundColor: Color(0xFF000006),
      disabledCheckedBackgroundColor: Color(0xFF000007),
      disabledUncheckedBackgroundColor: Color(0xFF000008),
    );
    expect(
      colors.foreground(checked: true, enabled: true),
      const Color(0xFF000001),
    );
    expect(
      colors.foreground(checked: false, enabled: true),
      const Color(0xFF000002),
    );
    expect(
      colors.foreground(checked: true, enabled: false),
      const Color(0xFF000003),
    );
    expect(
      colors.foreground(checked: false, enabled: false),
      const Color(0xFF000004),
    );
    expect(
      colors.background(checked: true, enabled: true),
      const Color(0xFF000005),
    );
    expect(
      colors.background(checked: false, enabled: true),
      const Color(0xFF000006),
    );
    expect(
      colors.background(checked: true, enabled: false),
      const Color(0xFF000007),
    );
    expect(
      colors.background(checked: false, enabled: false),
      const Color(0xFF000008),
    );
    expect(colors.copyWith(), colors);
    expect(
      colors.copyWith(checkedBackgroundColor: const Color(0xFF123456)),
      const MiuixCheckboxColors(
        checkedForegroundColor: Color(0xFF000001),
        uncheckedForegroundColor: Color(0xFF000002),
        disabledCheckedForegroundColor: Color(0xFF000003),
        disabledUncheckedForegroundColor: Color(0xFF000004),
        checkedBackgroundColor: Color(0xFF123456),
        uncheckedBackgroundColor: Color(0xFF000006),
        disabledCheckedBackgroundColor: Color(0xFF000007),
        disabledUncheckedBackgroundColor: Color(0xFF000008),
      ),
    );
    expect(MiuixCheckboxDefaults.size, 26);
    expect(MiuixCheckboxDefaults.touchTargetSize, 48);
  });

  testWidgets('checkbox source defaults and tristate adapter drive painting', (
    tester,
  ) async {
    late MiuixCheckboxColors defaults;
    var clicks = 0;
    const custom = MiuixCheckboxColors(
      checkedForegroundColor: Color(0xFF102030),
      uncheckedForegroundColor: Color(0xFF203040),
      disabledCheckedForegroundColor: Color(0xFF304050),
      disabledUncheckedForegroundColor: Color(0xFF405060),
      checkedBackgroundColor: Color(0xFF506070),
      uncheckedBackgroundColor: Color(0xFF607080),
      disabledCheckedBackgroundColor: Color(0xFF708090),
      disabledUncheckedBackgroundColor: Color(0xFF8090A0),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixCheckboxDefaults.checkboxColors(context);
              return MiuixCheckbox.tristate(
                state: null,
                onClick: () => clicks++,
                colors: custom,
              );
            },
          ),
        ),
      ),
    );

    expect(
      defaults.checkedBackgroundColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledUncheckedBackgroundColor,
      const MiuixSemanticColors.light()['disabledSecondary'],
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-checkbox-canvas')),
                )
                .painter
            as dynamic;
    expect(painter.background, custom.checkedBackgroundColor);
    expect(painter.foreground, custom.checkedForegroundColor);
    expect(painter.crossCenterGravitation, 1);
    await tester.tap(find.byType(MiuixCheckbox));
    expect(clicks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only checkbox retains source press feedback only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(child: MiuixCheckbox(value: false, onChanged: null)),
        ),
      ),
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackOnly, isTrue);
    final semantics = tester
        .getSemantics(find.byKey(const ValueKey('miuix-checkbox-semantics')))
        .getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);

    final detector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byType(GestureDetector),
      ),
    );
    detector.onTapDown!(TapDownDetails(localPosition: const Offset(13, 13)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final sink = tester.widget<Transform>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byKey(const ValueKey('miuix-sink-transform')),
      ),
    );
    expect(sink.transform.entry(0, 0), closeTo(.85, .002));
    detector.onTapCancel!();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('radio colors preserve source data and defaults dimensions', () {
    const colors = MiuixRadioButtonColors(
      selectedColor: Color(0xFF112233),
      disabledSelectedColor: Color(0xFF445566),
    );
    expect(colors.color(enabled: true), const Color(0xFF112233));
    expect(colors.color(enabled: false), const Color(0xFF445566));
    expect(colors.copyWith(), colors);
    expect(
      colors.copyWith(selectedColor: const Color(0xFF778899)),
      const MiuixRadioButtonColors(
        selectedColor: Color(0xFF778899),
        disabledSelectedColor: Color(0xFF445566),
      ),
    );
    expect(MiuixRadioButtonDefaults.size, 26);
    expect(MiuixRadioButtonDefaults.touchTargetSize, 48);
  });

  testWidgets('radio source adapter colors and read-only feedback are exact', (
    tester,
  ) async {
    late MiuixRadioButtonColors defaults;
    var clicks = 0;
    const custom = MiuixRadioButtonColors(
      selectedColor: Color(0xFF123456),
      disabledSelectedColor: Color(0xFF654321),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixRadioButtonDefaults.radioButtonColors(context);
              return Column(
                children: [
                  MiuixRadioButton.source(
                    selected: true,
                    onClick: () => clicks++,
                    colors: custom,
                  ),
                  MiuixRadioButton.source(
                    selected: true,
                    onClick: null,
                    colors: custom,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(
      defaults.selectedColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledSelectedColor,
      const MiuixSemanticColors.light()['disabledPrimary'],
    );
    final firstPainter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-radio-canvas')).first,
                )
                .painter
            as dynamic;
    expect(firstPainter.color, custom.selectedColor);
    await tester.tap(find.byType(MiuixRadioButton<bool>).first);
    expect(clicks, 1);

    final readOnly = find.byType(MiuixRadioButton<bool>).last;
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(of: readOnly, matching: find.byType(MiuixPressable)),
    );
    expect(pressable.feedbackOnly, isTrue);
    final semantics = tester
        .getSemantics(
          find.descendant(
            of: readOnly,
            matching: find.byKey(const ValueKey('miuix-radio-semantics')),
          ),
        )
        .getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);
    expect(tester.takeException(), isNull);
  });

  test('checkbox preserves every MIUIX transition channel and keyframe', () {
    // Off -> On: visibility finishes at 10 ms, start trim at 200 ms, while
    // the first end-trim leg is linear and deliberately peaks at .85.
    final enteringMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 5,
    );
    expect(
      enteringMidpoint.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      enteringMidpoint.trimStart,
      closeTo(.1 + .086 * Curves.fastOutSlowIn.transform(.025), .000001),
    );
    expect(enteringMidpoint.trimEnd, closeTo(.1 + .75 * .025, .000001));

    final firstKeyframe = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 200,
    );
    expect(firstKeyframe.checkAlpha, 1);
    expect(firstKeyframe.trimStart, .186);
    expect(firstKeyframe.trimEnd, .85);

    final secondKeyframeMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 250,
    );
    expect(
      secondKeyframeMidpoint.trimEnd,
      closeTo(.85 + (.803 - .85) * Curves.fastOutSlowIn.transform(.5), .000001),
    );

    // On -> Mixed changes only path gravitation. updateTransition leaves the
    // already-resolved visibility and trim channels untouched.
    final mixedMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 1,
      fromTrimStart: .186,
      fromTrimEnd: .803,
      fromCrossCenterGravitation: 0,
      targetChecked: false,
      targetIndeterminate: true,
      elapsedMilliseconds: 100,
    );
    expect(mixedMidpoint.checkAlpha, 1);
    expect(mixedMidpoint.trimStart, .186);
    expect(mixedMidpoint.trimEnd, .803);
    expect(
      mixedMidpoint.crossCenterGravitation,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
  });

  test('radio keeps source alpha and trim durations independent', () {
    final entering = debugMiuixRadioTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimEnd: 0,
      targetSelected: true,
      elapsedMilliseconds: 5,
    );
    expect(
      entering.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      entering.trimEnd,
      closeTo(Curves.fastOutSlowIn.transform(5 / 300), .000001),
    );

    final exiting = debugMiuixRadioTransitionFrame(
      fromCheckAlpha: 1,
      fromTrimEnd: 1,
      targetSelected: false,
      elapsedMilliseconds: 75,
    );
    expect(
      exiting.checkAlpha,
      closeTo(1 - Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      exiting.trimEnd,
      closeTo(1 - Curves.fastOutSlowIn.transform(.25), .000001),
    );
  });

  testWidgets('selection painters follow source timelines and disabled roles', (
    tester,
  ) async {
    var checked = false;
    var selected = false;
    late StateSetter updateFixture;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateFixture = setState;
              return Column(
                children: [
                  MiuixCheckbox(value: checked, onChanged: (_) {}),
                  MiuixRadio<int>(
                    value: 1,
                    groupValue: selected ? 1 : 0,
                    onChanged: (_) {},
                  ),
                  const MiuixCheckbox(
                    value: true,
                    enabled: false,
                    onChanged: null,
                  ),
                  const MiuixRadio<int>(
                    value: 1,
                    groupValue: 1,
                    enabled: false,
                    onChanged: null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Disabled controls use the fixed-light palette's dedicated roles. This
    // prevents a future generic Opacity wrapper from silently returning.
    final disabledCheckbox =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-checkbox-canvas')).last,
                )
                .painter
            as dynamic;
    final disabledRadio =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-radio-canvas')).last,
                )
                .painter
            as dynamic;
    expect(disabledCheckbox.background, const Color(0xFFC2D9FF));
    expect(disabledCheckbox.foreground, const Color(0xFFF3F8FF));
    expect(disabledRadio.color, const Color(0xFFC2D9FF));

    updateFixture(() {
      checked = true;
      selected = true;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));

    dynamic checkboxPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')).first,
        )
        .painter;
    dynamic radioPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-radio-canvas')).first,
        )
        .painter;
    expect(
      checkboxPainter.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      radioPainter.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );

    await tester.pump(const Duration(milliseconds: 195));
    checkboxPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')).first,
        )
        .painter;
    radioPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-radio-canvas')).first,
        )
        .painter;
    expect(checkboxPainter.trimEnd, closeTo(.85, .000001));
    expect(
      radioPainter.trimEnd,
      closeTo(Curves.fastOutSlowIn.transform(2 / 3), .000001),
    );
  });

  testWidgets('selection controls snap active motion when animations disable', (
    tester,
  ) async {
    var selected = false;
    var reduceMotion = false;
    late StateSetter updateFixture;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateFixture = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Column(
                  children: [
                    MiuixSwitch(value: selected, onChanged: (_) {}),
                    MiuixCheckbox(value: selected, onChanged: (_) {}),
                    MiuixRadio<int>(
                      value: 1,
                      groupValue: selected ? 1 : 0,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    double thumbLeft() => tester
        .widget<Positioned>(
          find.ancestor(of: thumb, matching: find.byType(Positioned)).first,
        )
        .left!;
    dynamic checkboxPainter() => tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')),
        )
        .painter;
    dynamic radioPainter() => tester
        .widget<CustomPaint>(find.byKey(const ValueKey('miuix-radio-canvas')))
        .painter;

    updateFixture(() => selected = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(
      thumbLeft(),
      inExclusiveRange(
        MiuixSwitchDefaults.uncheckedThumbOffset,
        MiuixSwitchDefaults.checkedThumbOffset,
      ),
    );
    expect(checkboxPainter().trimEnd, inExclusiveRange(.1, .803));
    expect(radioPainter().trimEnd, inExclusiveRange(0, 1));

    updateFixture(() => reduceMotion = true);
    await tester.pump();
    expect(thumbLeft(), MiuixSwitchDefaults.checkedThumbOffset);
    final switchContext = tester.element(find.byType(MiuixSwitch));
    final switchColors = MiuixSwitchDefaults.switchColors(switchContext);
    final trackDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-track')),
                )
                .decoration
            as BoxDecoration;
    final thumbDecoration =
        tester.widget<DecoratedBox>(thumb).decoration as BoxDecoration;
    expect(trackDecoration.color, switchColors.checkedTrackColor);
    expect(thumbDecoration.color, switchColors.checkedThumbColor);
    expect(checkboxPainter().checkAlpha, 1);
    expect(checkboxPainter().trimEnd, .803);
    expect(radioPainter().checkAlpha, 1);
    expect(radioPainter().trimEnd, 1);

    updateFixture(() => selected = false);
    await tester.pump();
    expect(thumbLeft(), MiuixSwitchDefaults.uncheckedThumbOffset);
    expect(checkboxPainter().checkAlpha, 0);
    expect(checkboxPainter().trimStart, .1);
    expect(checkboxPainter().trimEnd, .1);
    expect(radioPainter().checkAlpha, 0);
    expect(radioPainter().trimEnd, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch matches MIUIX size and drag threshold', (tester) async {
    var switchValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixSwitch(
                      value: switchValue,
                      onChanged: (value) => setState(() => switchValue = value),
                    ),
                    const MiuixSwitch(
                      value: false,
                      enabled: false,
                      onChanged: null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final track = find.byKey(const ValueKey('miuix-switch-track')).first;
    final thumb = find.byKey(const ValueKey('miuix-switch-thumb')).first;
    expect(tester.getSize(track), const Size(49, 28));
    expect(tester.getSize(thumb), const Size.square(20));
    // Switch.kt places the 20dp thumb at 4dp when off and 25dp when on. The
    // asymmetric values are deliberate and must not be visually centered by
    // adding a self-designed border or shadow.
    expect(tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx, 4);
    final trackDecoration =
        tester.widget<DecoratedBox>(track).decoration as BoxDecoration;
    final thumbDecoration =
        tester.widget<DecoratedBox>(thumb).decoration as BoxDecoration;
    expect(trackDecoration.color, const Color(0xFFE6E6E6));
    expect(thumbDecoration.color, Colors.white);

    // Disabled switches use dedicated MIUIX roles rather than applying a
    // generic opacity to the enabled colors. These exact values come from the
    // original fixed light palette and guard both semantic-role lookup and the
    // component's state resolution.
    final disabledTrack = find.byKey(const ValueKey('miuix-switch-track')).last;
    final disabledThumb = find.byKey(const ValueKey('miuix-switch-thumb')).last;
    final disabledTrackDecoration =
        tester.widget<DecoratedBox>(disabledTrack).decoration as BoxDecoration;
    final disabledThumbDecoration =
        tester.widget<DecoratedBox>(disabledThumb).decoration as BoxDecoration;
    expect(disabledTrackDecoration.color, const Color(0xFFF0F0F0));
    expect(disabledThumbDecoration.color, const Color(0xFFFCFCFC));

    await tester.drag(thumb, const Offset(44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isTrue);
    expect(
      tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx,
      closeTo(25, .001),
    );

    await tester.drag(thumb, const Offset(-44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isFalse);

    await tester.drag(disabledThumb, const Offset(44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch drag starts only on the source thumb hit area', (
    tester,
  ) async {
    var value = false;
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
    final trackRect = tester.getRect(track);

    // Switch.kt installs draggable on the 20dp thumb, not the 49dp track.
    // Starting at the track's far edge therefore cannot move or commit it.
    await tester.dragFrom(
      Offset(trackRect.right - 2, trackRect.center.dy),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(
      tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx,
      closeTo(MiuixSwitchDefaults.uncheckedThumbOffset, .001),
    );

    // The same horizontal motion beginning on the authored thumb does commit.
    await tester.dragFrom(tester.getCenter(thumb), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch reverses immediately after dragging past an endpoint', (
    tester,
  ) async {
    var value = false;
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

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    double authoredThumbLeft() => tester
        .widget<Positioned>(
          find.ancestor(of: thumb, matching: find.byType(Positioned)).first,
        )
        .left!;
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    // 多帧拖动超过整个轨道，验证端点外的指针位移不会积压。
    // 指针仍保持按下，接下来的反向运动必须立即改变滑块位置。
    for (var frame = 0; frame < 10; frame += 1) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      authoredThumbLeft(),
      closeTo(MiuixSwitchDefaults.checkedThumbOffset, .1),
    );

    // 反向 10dp 应立即向左移动 10dp，不再把指针位移减半。
    // 原始实现会一直停在端点，这正是本次需要覆盖的回归。
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      authoredThumbLeft(),
      closeTo(MiuixSwitchDefaults.checkedThumbOffset - 10, .1),
    );
    // 同一手势继续向左，必须能回到原始关闭端点。
    // 回到原处后松手，不应把开关改为开启。
    await gesture.moveBy(const Offset(-42, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      authoredThumbLeft(),
      closeTo(MiuixSwitchDefaults.uncheckedThumbOffset, .1),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch thumb claims horizontal drag inside an ancestor pager', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var value = false;
    var selectedPage = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: controller,
              onPageChanged: (page) => selectedPage = page,
              children: [
                StatefulBuilder(
                  builder: (context, setState) => Center(
                    child: MiuixSwitch(
                      value: value,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  ),
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    await tester.drag(thumb, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(selectedPage, 0);
    expect(controller.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switch expands callback targets to 48dp without changing its track',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const enabledKey = ValueKey('switch-enabled-target');
      const disabledCallbackKey = ValueKey('switch-disabled-callback-target');
      const callbacklessKey = ValueKey('switch-callbackless-target');
      var value = false;
      var disabledCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: enabledKey,
                            value: value,
                            onChanged: (next) => setState(() => value = next),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: disabledCallbackKey,
                            value: true,
                            enabled: false,
                            onChanged: (_) => disabledCalls++,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: callbacklessKey,
                            value: false,
                            enabled: false,
                            onChanged: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Finder target(Finder control) => find.descendant(
        of: control,
        matching: find.byKey(const ValueKey('miuix-switch-semantics')),
      );
      final enabled = find.byKey(enabledKey);
      final disabledCallback = find.byKey(disabledCallbackKey);
      final callbackless = find.byKey(callbacklessKey);
      for (final control in [enabled, disabledCallback, callbackless]) {
        expect(
          tester.getSize(control).width * sourceDensity,
          closeTo(129, .001),
        );
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(74, .001),
        );
      }
      for (final control in [enabled, disabledCallback]) {
        expect(
          tester.getRect(target(control)).width * sourceDensity,
          closeTo(129, .001),
        );
        expect(
          tester.getRect(target(control)).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      expect(
        tester.getRect(target(callbackless)).height * sourceDensity,
        closeTo(74, .001),
      );

      // Twenty logical pixels is below the source 24dp target radius but
      // outside the 14dp visible half-height.
      await tester.tapAt(
        tester.getRect(target(enabled)).center + const Offset(0, 20),
      );
      await tester.tapAt(tester.getRect(target(disabledCallback)).center);
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(disabledCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('checkbox uses MIUIX source checkmark metrics', (tester) async {
    var value = true;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MiuixCheckbox(
                  value: value,
                  onChanged: (next) => setState(() => value = next ?? false),
                ),
              );
            },
          ),
        ),
      ),
    );

    final canvas = find.byKey(const ValueKey('miuix-checkbox-canvas'));
    expect(tester.getSize(canvas), const Size.square(26));

    final metrics = debugMiuixCheckboxMetrics(const Size.square(26));
    expect(metrics.start.dx, closeTo(5.65, 0.01));
    expect(metrics.start.dy, closeTo(10.63, 0.01));
    expect(metrics.middle.dx, closeTo(11.64, 0.01));
    expect(metrics.middle.dy, closeTo(16.84, 0.01));
    expect(metrics.end.dx, closeTo(20.23, 0.01));
    expect(metrics.end.dy, closeTo(5.77, 0.01));
    expect(metrics.strokeWidth, closeTo(2.34, 0.01));

    await tester.tap(find.byType(MiuixCheckbox));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox exposes the MIUIX indeterminate state', (tester) async {
    bool? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixCheckbox(
              value: false,
              indeterminate: true,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    // A mixed-state click progresses to checked, matching the three-state
    // cycle used by the original Checkbox section.
    expect(
      tester.widget<MiuixCheckbox>(find.byType(MiuixCheckbox)).indeterminate,
      isTrue,
    );
    await tester.tap(find.byType(MiuixCheckbox));
    expect(changed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio uses MIUIX source checkmark metrics', (tester) async {
    var value = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MiuixRadio<int>(
                  value: 1,
                  groupValue: value,
                  onChanged: (next) => setState(() => value = next ?? 0),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixRadio<int>));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('miuix-radio-canvas'));
    expect(tester.getSize(canvas), const Size.square(26));

    final metrics = debugMiuixRadioMetrics(const Size.square(26));
    expect(metrics.start.dx, closeTo(5.06, 0.01));
    expect(metrics.start.dy, closeTo(13.46, 0.01));
    expect(metrics.middle.dx, closeTo(10.72, 0.01));
    expect(metrics.middle.dy, closeTo(18.94, 0.01));
    expect(metrics.end.dx, closeTo(20.43, 0.01));
    expect(metrics.end.dy, closeTo(7.43, 0.01));
    expect(metrics.strokeWidth, closeTo(3.25, 0.01));
    expect(value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio preference defaults to source start placement', (
    tester,
  ) async {
    // The upstream RadioButtonPreference API defaults to Start. Keeping both
    // variants in one fixture also guards the opt-in End layout independently.
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixRadioButtonPreference<int>(
                  title: 'Start radio',
                  value: 1,
                  groupValue: 1,
                  onChanged: _ignoreNullableInt,
                ),
                MiuixRadioButtonPreference<int>(
                  title: 'End radio',
                  value: 2,
                  groupValue: 2,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onChanged: _ignoreNullableInt,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final radios = find.byType(MiuixRadio<int>);
    final startText = tester.getRect(find.text('Start radio'));
    final endText = tester.getRect(find.text('End radio'));
    final startRadio = tester.getRect(radios.at(0));
    final endRadio = tester.getRect(radios.at(1));

    expect(startRadio.right, lessThan(startText.left));
    expect(endRadio.left, greaterThan(endText.right));
  });
}
