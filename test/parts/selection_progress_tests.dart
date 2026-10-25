part of '../miuix_flutter_test.dart';

void _ignoreNullableInt(int? _) {}

void _registerSelectionProgressTests() {
  // 先注册拆出的输入和选择控件，再注册原有滑块与进度测试。
  _registerTextFieldTests();
  _registerSelectionControlTests();
  testWidgets('custom sliders update from pointer input safely', (
    tester,
  ) async {
    var sliderValue = 0.0;
    var rangeValues = const RangeValues(0.2, 0.8);
    var verticalValue = 0.0;
    var disabledCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(
                  value: sliderValue,
                  divisions: 4,
                  onChanged: (value) => sliderValue = value,
                ),
                MiuixRangeSlider(
                  values: rangeValues,
                  divisions: 4,
                  onChanged: (value) => rangeValues = value,
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: verticalValue,
                    onChanged: (value) => verticalValue = value,
                  ),
                ),
                MiuixSlider(
                  value: 0.5,
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
                MiuixRangeSlider(
                  values: const RangeValues(0.2, 0.8),
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
                MiuixVerticalSlider(
                  value: 0.5,
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(MiuixSlider).first));
    await tester.tapAt(tester.getCenter(find.byType(MiuixRangeSlider).first));
    await tester.tapAt(
      tester.getCenter(find.byType(MiuixVerticalSlider).first),
    );
    await tester.pump();

    // Slider.kt installs draggable but no tap modifier. A stationary track
    // tap therefore leaves every source slider unchanged.
    expect(sliderValue, 0);
    expect(rangeValues, const RangeValues(.2, .8));
    expect(verticalValue, 0);
    expect(disabledCalls, 0);

    await tester.drag(find.byType(MiuixSlider).first, const Offset(120, 0));
    await tester.drag(
      find.byType(MiuixRangeSlider).first,
      const Offset(-80, 0),
    );
    await tester.drag(
      find.byType(MiuixVerticalSlider).first,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    expect(sliderValue, greaterThan(0));
    expect(rangeValues.start <= rangeValues.end, isTrue);
    expect(verticalValue, greaterThan(0));
    expect(disabledCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal sliders round their own source height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(value: .3, onChanged: null),
                MiuixRangeSlider(values: RangeValues(.2, .8), onChanged: null),
                MiuixRangeSlider(
                  values: RangeValues(.2, .8),
                  height: 20,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final singleHeight =
        tester.getSize(find.byType(MiuixSlider)).height * 2.625;
    final rangeHeights = [
      tester.getSize(find.byType(MiuixRangeSlider).at(0)).height * 2.625,
      tester.getSize(find.byType(MiuixRangeSlider).at(1)).height * 2.625,
    ];
    expect(singleHeight, closeTo(74, .001));
    expect(rangeHeights.first, closeTo(74, .001));
    expect(rangeHeights.last, closeTo(53, .001));
  });

  testWidgets(
    'sliders preserve source layout, 48dp target, enabled contract, and semantics',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semanticsHandle = tester.ensureSemantics();
      const scalarKey = ValueKey('source-scalar-slider');
      const disabledKey = ValueKey('source-disabled-slider');
      const rangeKey = ValueKey('source-range-slider');
      const verticalKey = ValueKey('source-vertical-slider');
      var scalarValue = .3;
      var verticalValue = .3;
      var disabledPointerCalls = 0;
      var rangePointerCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixSlider(
                        key: scalarKey,
                        value: scalarValue,
                        onChanged: (next) => scalarValue = next,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixSlider(
                        key: disabledKey,
                        value: .7,
                        enabled: false,
                        onChanged: (_) => disabledPointerCalls++,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixRangeSlider(
                        key: rangeKey,
                        values: const RangeValues(.3, .7),
                        enabled: false,
                        onChanged: (_) => rangePointerCalls++,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: MiuixVerticalSlider(
                        key: verticalKey,
                        value: verticalValue,
                        width: 25,
                        height: 160,
                        onChanged: (next) => verticalValue = next,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Finder outer(Finder control, String key) =>
          find.descendant(of: control, matching: find.byKey(ValueKey(key)));
      Finder target(Finder control) => find.descendant(
        of: control,
        matching: find.byKey(const ValueKey('miuix-slider-touch-target')),
      );
      final scalar = find.byKey(scalarKey);
      final disabled = find.byKey(disabledKey);
      final range = find.byKey(rangeKey);
      final vertical = find.byKey(verticalKey);

      for (final control in [scalar, disabled, range]) {
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(74, .001),
        );
        expect(
          tester.getRect(target(control)).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      expect(tester.getSize(vertical).width * sourceDensity, closeTo(66, .001));
      expect(
        tester.getRect(target(vertical)).width * sourceDensity,
        closeTo(126, .001),
      );
      expect(
        tester.getSize(vertical).height * sourceDensity,
        closeTo(420, .001),
      );

      final scalarSemantics = tester
          .getSemantics(outer(scalar, 'miuix-slider-semantics'))
          .getSemanticsData();
      final disabledSemantics = tester
          .getSemantics(outer(disabled, 'miuix-slider-semantics'))
          .getSemanticsData();
      final rangeSemantics = tester
          .getSemantics(outer(range, 'miuix-range-slider-semantics'))
          .getSemanticsData();
      final verticalSemantics = tester
          .getSemantics(outer(vertical, 'miuix-vertical-slider-semantics'))
          .getSemanticsData();
      for (final data in [
        scalarSemantics,
        disabledSemantics,
        verticalSemantics,
      ]) {
        // Increase/decrease actions map to android.widget.SeekBar without
        // Flutter's isSlider flag, whose engine bridge would inject a false
        // ACTION_CLICK absent from the Compose source.
        expect(data.flagsCollection.isSlider, isFalse);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.flagsCollection.isFocused, Tristate.none);
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        expect(data.hasAction(SemanticsAction.decrease), isTrue);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.value, isEmpty);
      }
      expect(rangeSemantics.flagsCollection.isSlider, isFalse);
      expect(rangeSemantics.flagsCollection.isEnabled, Tristate.isTrue);
      expect(rangeSemantics.actions, 0);
      expect(rangeSemantics.value, isEmpty);

      // The expanded transparent band owns horizontal/vertical drags, while a
      // stationary tap still follows the source no-op behavior.
      final scalarTarget = tester.getRect(target(scalar));
      await tester.tapAt(scalarTarget.center + const Offset(0, 20));
      expect(scalarValue, .3);
      await tester.dragFrom(
        scalarTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      expect(scalarValue, greaterThan(.3));

      final disabledTarget = tester.getRect(target(disabled));
      await tester.dragFrom(
        disabledTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      final rangeTarget = tester.getRect(target(range));
      await tester.dragFrom(
        rangeTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      expect(disabledPointerCalls, 0);
      expect(rangePointerCalls, 0);

      final verticalTarget = tester.getRect(target(vertical));
      await tester.dragFrom(
        verticalTarget.center + const Offset(20, 0),
        const Offset(0, -70),
      );
      expect(verticalValue, greaterThan(.3));
      semanticsHandle.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vertical slider owns drag ahead of a parent scrollable', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 120),
              Center(
                child: MiuixVerticalSlider(
                  value: .3,
                  width: 25,
                  height: 160,
                  onChanged: (value) => changed = value,
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );

    final slider = find.byType(MiuixVerticalSlider);
    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.bottom - 25),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!, greaterThan(.3));
    expect(scrollController.offset, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  test('sliders expose the exact source motion constants', () {
    final dragging = debugMiuixSliderProgressSpring(dragging: true);
    final resting = debugMiuixSliderProgressSpring(dragging: false);
    final thumb = debugMiuixSliderThumbScaleSpring();
    final overlay = debugMiuixSliderTrackOverlayMotion();

    expect(dragging.mass, 1);
    expect(dragging.stiffness, 1755);
    expect(dragging.damping, closeTo(2 * math.sqrt(1755) * .9, .0001));
    expect(resting.mass, 1);
    expect(resting.stiffness, 322);
    expect(resting.damping, closeTo(2 * math.sqrt(322) * .96, .0001));
    expect(thumb.mass, 1);
    expect(thumb.stiffness, 987);
    expect(thumb.damping, closeTo(2 * math.sqrt(987) * .6, .0001));
    expect(debugMiuixSliderActiveThumbScale(), 1.127);
    expect(overlay.alpha, .044);
    expect(overlay.duration, const Duration(milliseconds: 150));
  });

  testWidgets('all slider variants settle active motion when reduced', (
    tester,
  ) async {
    var reduceMotion = false;
    var horizontalValue = .1;
    var verticalValue = .2;
    var rangeValues = const RangeValues(.2, .4);
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      key: const ValueKey('reduced-horizontal-slider'),
                      width: 300,
                      child: MiuixSlider(
                        value: horizontalValue,
                        onChanged: (value) =>
                            updateHost(() => horizontalValue = value),
                      ),
                    ),
                    SizedBox(
                      key: const ValueKey('reduced-vertical-slider'),
                      width: 48,
                      height: 220,
                      child: MiuixVerticalSlider(
                        value: verticalValue,
                        onChanged: (value) =>
                            updateHost(() => verticalValue = value),
                      ),
                    ),
                    SizedBox(
                      key: const ValueKey('reduced-range-slider'),
                      width: 300,
                      child: MiuixRangeSlider(
                        values: rangeValues,
                        onChanged: (value) =>
                            updateHost(() => rangeValues = value),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    CustomPaint sliderPaint(Finder root) => tester
        .widgetList<CustomPaint>(
          find.descendant(of: root, matching: find.byType(CustomPaint)),
        )
        .firstWhere((paint) {
          try {
            debugMiuixSliderPaintSnapshot(paint.painter);
            return true;
          } on ArgumentError {
            return false;
          }
        });
    final horizontal = find.byKey(const ValueKey('reduced-horizontal-slider'));
    final vertical = find.byKey(const ValueKey('reduced-vertical-slider'));
    final range = find.byKey(const ValueKey('reduced-range-slider'));

    updateHost(() {
      horizontalValue = .9;
      verticalValue = .8;
      rangeValues = const RangeValues(.1, .9);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      debugMiuixSliderPaintSnapshot(
        sliderPaint(horizontal).painter,
      ).endFraction,
      isNot(closeTo(.9, .0001)),
    );

    updateHost(() => reduceMotion = true);
    await tester.pump();
    final horizontalSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    final verticalSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(vertical).painter,
    );
    final rangeSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(range).painter,
    );
    expect(horizontalSettled.endFraction, closeTo(.9, .0001));
    expect(verticalSettled.endFraction, closeTo(.2, .0001));
    expect(rangeSettled.startFraction, closeTo(.1, .0001));
    expect(rangeSettled.endFraction, closeTo(.9, .0001));

    final rect = tester.getRect(horizontal);
    final gesture = await tester.startGesture(
      Offset(rect.left + 70, rect.center.dy),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    final dragging = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    expect(dragging.thumbScale, closeTo(1.127, .0001));
    expect(dragging.backgroundOverlayAlpha, closeTo(.044, .0001));

    await gesture.up();
    await tester.pump();
    final released = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    expect(released.thumbScale, 1);
    expect(released.backgroundOverlayAlpha, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders follow source RTL and reverse-direction mapping', (
    tester,
  ) async {
    Future<double> dragHorizontal({
      required TextDirection direction,
      required bool reverse,
    }) async {
      double? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 228,
                  child: MiuixSlider(
                    value: .5,
                    reverseDirection: reverse,
                    onChanged: (value) => changed = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MiuixSlider));
      final gesture = await tester.startGesture(
        Offset(rect.left + 40, rect.center.dy),
      );
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      return changed!;
    }

    final ltr = await dragHorizontal(
      direction: TextDirection.ltr,
      reverse: false,
    );
    final reversed = await dragHorizontal(
      direction: TextDirection.ltr,
      reverse: true,
    );
    final rtl = await dragHorizontal(
      direction: TextDirection.rtl,
      reverse: false,
    );
    final rtlReversed = await dragHorizontal(
      direction: TextDirection.rtl,
      reverse: true,
    );

    expect(ltr, lessThan(.5));
    expect(reversed, closeTo(1 - ltr, .000001));
    expect(rtl, closeTo(reversed, .000001));
    expect(rtlReversed, closeTo(ltr, .000001));

    Future<double> dragVertical({required bool reverse}) async {
      double? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.topLeft,
              child: MiuixVerticalSlider(
                value: .5,
                width: 28,
                height: 228,
                reverseDirection: reverse,
                onChanged: (value) => changed = value,
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MiuixVerticalSlider));
      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top + 40),
      );
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      return changed!;
    }

    final bottomToTop = await dragVertical(reverse: false);
    final topToBottom = await dragVertical(reverse: true);
    expect(bottomToTop, greaterThan(.5));
    expect(topToBottom, closeTo(1 - bottomToTop, .000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('range slider hands ownership across equal thumbs', (
    tester,
  ) async {
    RangeValues? latest;
    var finished = 0;

    Future<Rect> pumpRange({
      required Key key,
      TextDirection direction = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 228,
                  child: MiuixRangeSlider(
                    key: key,
                    values: const RangeValues(.25, .75),
                    onChanged: (value) => latest = value,
                    onChangeFinished: () => finished++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getRect(find.byType(MiuixRangeSlider));
    }

    var rect = await pumpRange(key: const ValueKey('forward-handoff'));
    var gesture = await tester.startGesture(
      Offset(rect.left + 64, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 164, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.75, .75));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(latest!.start, .75);
    expect(latest!.end, greaterThan(.75));
    await gesture.up();
    await tester.pump();

    latest = null;
    rect = await pumpRange(key: const ValueKey('backward-handoff'));
    gesture = await tester.startGesture(
      Offset(rect.left + 164, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 64, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.25, .25));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(latest!.start, lessThan(.25));
    expect(latest!.end, .25);
    await gesture.up();
    await tester.pump();

    latest = null;
    rect = await pumpRange(
      key: const ValueKey('rtl-forward-handoff'),
      direction: TextDirection.rtl,
    );
    gesture = await tester.startGesture(
      Offset(rect.left + 164, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 64, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.75, .75));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(latest!.start, .75);
    expect(latest!.end, greaterThan(.75));
    await gesture.up();
    await tester.pump();

    expect(finished, 3);
    expect(tester.takeException(), isNull);
  });

  test('slider minimum keeps the active track visually empty', () {
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: false,
        endFraction: 0,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: true,
        endFraction: 1,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: false,
        endFraction: 0.25,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: true,
        vertical: false,
        endFraction: 0,
      ),
      isTrue,
    );
  });

  test('slider painting uses the source semantic color roles', () {
    const semantic = MiuixSemanticColors.light();
    final enabled = debugMiuixSliderResolvedColors(semantic);
    final disabled = debugMiuixSliderResolvedColors(semantic, enabled: false);

    expect(enabled['background'], const Color(0x0F000000));
    expect(enabled['foreground'], const Color(0xFF3482FF));
    expect(enabled['thumb'], const Color(0xFFFFFFFF));
    expect(enabled['keyPoint'], const Color(0x4DA3B3CD));
    expect(enabled['keyPointForeground'], const Color(0xFF6EB5FF));
    expect(disabled['background'], const Color(0xFFF0F0F0));
    expect(disabled['foreground'], const Color(0xFFB8CFF5));
    expect(disabled['thumb'], const Color(0xFFF3F8FF));
  });

  testWidgets('slider colors and defaults expose all source channels', (
    tester,
  ) async {
    late MiuixSliderColors defaults;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixSliderDefaults.sliderColors(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(MiuixSliderDefaults.minHeight, 28);
    expect(MiuixSliderDefaults.keyPointRadius, 3.855);
    expect(
      MiuixSliderDefaults.defaultHapticEffect,
      MiuixSliderHapticEffect.edge,
    );
    expect(defaults.foregroundColor, const Color(0xFF3482FF));
    expect(defaults.disabledForegroundColor, const Color(0xFFB8CFF5));
    expect(defaults.backgroundColor, const Color(0x0F000000));
    expect(defaults.disabledBackgroundColor, const Color(0xFFF0F0F0));
    expect(defaults.thumbColor, const Color(0xFFFFFFFF));
    expect(defaults.disabledThumbColor, const Color(0xFFF3F8FF));
    expect(defaults.keyPointColor, const Color(0x4DA3B3CD));
    expect(defaults.keyPointForegroundColor, const Color(0xFF6EB5FF));
    expect(defaults.copyWith(), defaults);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all slider variants forward a custom source palette', (
    tester,
  ) async {
    const colors = MiuixSliderColors(
      foregroundColor: Color(0xFF000001),
      disabledForegroundColor: Color(0xFF000002),
      backgroundColor: Color(0xFF000003),
      disabledBackgroundColor: Color(0xFF000004),
      thumbColor: Color(0xFF000005),
      disabledThumbColor: Color(0xFF000006),
      keyPointColor: Color(0xFF000007),
      keyPointForegroundColor: Color(0xFF000008),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 240,
            child: Column(
              children: [
                MiuixSlider(
                  value: .4,
                  onChanged: null,
                  colors: colors,
                  showKeyPoints: true,
                  divisions: 4,
                ),
                MiuixRangeSlider(
                  values: RangeValues(.2, .7),
                  onChanged: null,
                  colors: colors,
                ),
                SizedBox(
                  height: 160,
                  child: MiuixVerticalSlider(
                    value: .6,
                    onChanged: null,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    dynamic painterFor(Finder owner) => tester
        .widget<CustomPaint>(
          find.descendant(of: owner, matching: find.byType(CustomPaint)),
        )
        .painter;
    for (final owner in <Finder>[
      find.byType(MiuixSlider),
      find.byType(MiuixRangeSlider),
      find.byType(MiuixVerticalSlider),
    ]) {
      final Map<String, Color> painted =
          painterFor(owner).debugResolvedColors as Map<String, Color>;
      expect(painted['foreground'], colors.foregroundColor);
      expect(painted['background'], colors.backgroundColor);
      expect(painted['thumb'], colors.thumbColor);
      expect(painted['keyPoint'], colors.keyPointColor);
      expect(painted['keyPointForeground'], colors.keyPointForegroundColor);
    }
    expect(tester.takeException(), isNull);
  });

  test('slider source adapters translate interior steps exactly once', () {
    void scalar(double _) {}
    void range(RangeValues _) {}
    final horizontal = MiuixSlider.source(
      value: .3,
      onValueChange: scalar,
      steps: 4,
      keyPoints: const [0, .5, 1],
    );
    final ranged = MiuixRangeSlider.source(
      value: const RangeValues(.2, .8),
      onValueChange: range,
      steps: 4,
    );
    final vertical = MiuixVerticalSlider.source(
      value: .6,
      onValueChange: scalar,
      steps: 4,
      effect: true,
    );

    // Compose `steps` counts only interior values; Flutter compatibility
    // `divisions` counts intervals, so four interior points become five.
    expect(horizontal.divisions, 5);
    expect(ranged.divisions, 5);
    expect(vertical.divisions, 5);
    expect(horizontal.keyPoints, const [0, .5, 1]);
    expect(vertical.effect, isTrue);
    expect(
      MiuixSlider.source(value: .5, onValueChange: scalar).divisions,
      isNull,
    );
  });

  test('infinite progress keeps the source gray default', () {
    expect(
      MiuixInfiniteProgressIndicator.defaultColor,
      const Color(0xFF888888),
    );
  });

  test('slider tick selection follows MIUIX active fill direction', () {
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: false,
        fraction: 0.25,
        startFraction: 0,
        endFraction: 0.5,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: false,
        fraction: 0.75,
        startFraction: 0,
        endFraction: 0.5,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: true,
        fraction: 0.75,
        startFraction: 1,
        endFraction: 0.5,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: true,
        fraction: 0.25,
        startFraction: 1,
        endFraction: 0.5,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: true,
        vertical: false,
        fraction: 0.5,
        startFraction: 0.25,
        endFraction: 0.75,
      ),
      isTrue,
    );
  });

  test('slider key points stay independent from snapping divisions', () {
    expect(debugMiuixSliderKeyPointFractions(divisions: 4), isEmpty);
    expect(
      debugMiuixSliderKeyPointFractions(divisions: 4, showKeyPoints: true),
      orderedEquals(const [0, .25, .5, .75, 1]),
    );
    expect(
      debugMiuixSliderKeyPointFractions(
        min: 0,
        max: 100,
        showKeyPoints: true,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      orderedEquals(const [0, .25, .5, .75, 1]),
    );
    expect(
      debugMiuixSliderKeyPointFractions(
        showKeyPoints: true,
        keyPoints: const [0, .25],
        vertical: true,
      ),
      orderedEquals(const [.75, 1]),
    );
  });

  test('slider uses full source cross-axis geometry', () {
    final horizontal = debugMiuixSliderGeometry(crossAxisExtent: 28);
    expect(horizontal.trackThickness, 28);
    expect(horizontal.trackRadius, 14);
    expect(horizontal.thumbRadius, closeTo(10.08, .000001));
    expect(horizontal.keyPointRadius, closeTo(28 / 7.5, .000001));

    final vertical = debugMiuixSliderGeometry(crossAxisExtent: 25);
    expect(vertical.trackThickness, 25);
    expect(vertical.trackRadius, 12.5);
    expect(vertical.thumbRadius, 9);
    expect(vertical.keyPointRadius, closeTo(25 / 7.5, .000001));
  });

  test('slider applies source step precedence and strict key-point magnet', () {
    // Custom points magnetize only while the pointer is strictly inside the
    // 2% threshold; equality remains a continuous value in Slider.kt.
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .259,
        min: 0,
        max: 100,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      25,
    );
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .27,
        min: 0,
        max: 100,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      closeTo(27, .000001),
    );
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .501,
        min: 0,
        max: 200,
        divisions: 200,
        keyPoints: const [0, 50, 100, 150, 200],
      ),
      100,
    );
  });

  testWidgets('slider gesture uses the source custom-point magnet', (
    tester,
  ) async {
    var value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 228,
              child: MiuixSlider(
                value: value,
                min: 0,
                max: 100,
                keyPoints: const [0, 25, 50, 75, 100],
                onChanged: (next) => value = next,
              ),
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(MiuixSlider));
    // A 228 x 28 slider has 200 dp between the two 14 dp thumb centers.
    final thumbCenter = rect.topLeft + const Offset(14, 14);
    final firstDrag = await tester.startGesture(thumbCenter);
    await firstDrag.moveTo(rect.topLeft + const Offset(14 + 200 * .259, 14));
    await firstDrag.up();
    expect(value, 25);
    final secondDrag = await tester.startGesture(thumbCenter);
    await secondDrag.moveTo(rect.topLeft + const Offset(14 + 200 * .27, 14));
    await secondDrag.up();
    expect(value, closeTo(27, .000001));
  });

  testWidgets('sliders clamp non-finite and inverted inputs without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(value: double.nan, onChanged: null),
                MiuixSlider(value: double.infinity, onChanged: null),
                MiuixRangeSlider(
                  values: RangeValues(double.nan, double.infinity),
                  onChanged: null,
                ),
                MiuixRangeSlider(values: RangeValues(.9, .1), onChanged: null),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: double.negativeInfinity,
                    onChanged: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsNWidgets(2));
    expect(find.byType(MiuixRangeSlider), findsNWidgets(2));
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders tolerate inverted bounds, zero span, and edge drags', (
    tester,
  ) async {
    var horizontal = .5;
    var vertical = .5;
    var range = const RangeValues(.25, .75);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: horizontal,
                    min: 10,
                    max: -10,
                    onChanged: (value) => horizontal = value,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: range,
                    min: 1,
                    max: 1,
                    onChanged: (value) => range = value,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: vertical,
                    min: 2,
                    max: -2,
                    onChanged: (value) => vertical = value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final sliderRect = tester.getRect(find.byType(MiuixSlider));
    final rangeRect = tester.getRect(find.byType(MiuixRangeSlider));
    final verticalRect = tester.getRect(find.byType(MiuixVerticalSlider));

    await tester.dragFrom(
      sliderRect.centerRight - const Offset(2, 0),
      const Offset(-400, 0),
    );
    await tester.tapAt(rangeRect.centerLeft - const Offset(40, 0));
    await tester.dragFrom(
      verticalRect.bottomCenter - const Offset(0, 2),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(horizontal.isFinite, isTrue);
    expect(vertical.isFinite, isTrue);
    expect(range.start.isFinite, isTrue);
    expect(range.end.isFinite, isTrue);
    expect(range.start <= range.end, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders sanitize unstable dimensions and scale inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: .5,
                    divisions: 0,
                    height: double.nan,
                    trackScale: double.nan,
                    thumbScale: double.infinity,
                    onChanged: null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: RangeValues(.2, .8),
                    divisions: -4,
                    onChanged: null,
                  ),
                ),
                MiuixVerticalSlider(
                  value: .5,
                  divisions: -1,
                  height: double.infinity,
                  width: double.nan,
                  trackScale: double.negativeInfinity,
                  thumbScale: double.nan,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsOneWidget);
    expect(find.byType(MiuixRangeSlider), findsOneWidget);
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabled sliders remain interactive under tiny safe scales', (
    tester,
  ) async {
    var sliderValue = .5;
    var verticalValue = .5;
    var rangeValues = const RangeValues(.3, .7);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: sliderValue,
                    trackScale: .25,
                    thumbScale: .25,
                    onChanged: (value) => sliderValue = value,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: rangeValues,
                    onChanged: (value) => rangeValues = value,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: verticalValue,
                    trackScale: .25,
                    thumbScale: .25,
                    onChanged: (value) => verticalValue = value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(MiuixSlider), const Offset(120, 0));
    await tester.drag(find.byType(MiuixRangeSlider), const Offset(-90, 0));
    await tester.drag(find.byType(MiuixVerticalSlider), const Offset(0, -90));
    await tester.pumpAndSettle();

    expect(sliderValue.isFinite, isTrue);
    expect(verticalValue.isFinite, isTrue);
    expect(rangeValues.start.isFinite, isTrue);
    expect(rangeValues.end.isFinite, isTrue);
    expect(rangeValues.start <= rangeValues.end, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders collapse safely under tiny layout constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 8,
                  child: MiuixSlider(value: .5, onChanged: null),
                ),
                SizedBox(
                  width: 8,
                  child: MiuixRangeSlider(
                    values: RangeValues(.2, .8),
                    onChanged: null,
                  ),
                ),
                SizedBox(
                  width: 10,
                  height: 20,
                  child: MiuixVerticalSlider(value: .5, onChanged: null),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsOneWidget);
    expect(find.byType(MiuixRangeSlider), findsOneWidget);
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom progress indicators normalize unstable values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(value: double.nan),
                MiuixLinearProgressIndicator(value: double.infinity),
                MiuixLinearProgressIndicator(value: -1),
                MiuixLinearProgressIndicator(value: 2),
                MiuixCircularProgressIndicator(value: double.nan),
                MiuixCircularProgressIndicator(value: double.infinity),
                MiuixCircularProgressIndicator(value: -1),
                MiuixCircularProgressIndicator(value: 2),
                MiuixProgressIndicator(),
                MiuixProgressIndicator(circular: true),
                MiuixInfiniteProgressIndicator(),
                MiuixInfiniteProgressIndicator(circular: true),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(MiuixLinearProgressIndicator), findsNWidgets(4));
    expect(find.byType(MiuixCircularProgressIndicator), findsNWidgets(4));
    expect(find.byType(MiuixInfiniteProgressIndicator), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('progress defaults and colors expose the complete source contract', () {
    expect(
      MiuixProgressIndicatorDefaults.defaultLinearProgressIndicatorHeight,
      6,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultCircularProgressIndicatorStrokeWidth,
      4,
    );
    expect(
      MiuixProgressIndicatorDefaults.defaultCircularProgressIndicatorSize,
      30,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultInfiniteProgressIndicatorStrokeWidth,
      2,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultInfiniteProgressIndicatorOrbitingDotSize,
      2,
    );
    expect(
      MiuixProgressIndicatorDefaults.defaultInfiniteProgressIndicatorSize,
      20,
    );

    const first = MiuixProgressIndicatorColors(
      foregroundColor: Color(0xFF123456),
      disabledForegroundColor: Color(0xFF654321),
      backgroundColor: Color(0xFFABCDEF),
    );
    const equal = MiuixProgressIndicatorColors(
      foregroundColor: Color(0xFF123456),
      disabledForegroundColor: Color(0xFF654321),
      backgroundColor: Color(0xFFABCDEF),
    );
    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(
      first.copyWith(backgroundColor: const Color(0xFF010203)),
      const MiuixProgressIndicatorColors(
        foregroundColor: Color(0xFF123456),
        disabledForegroundColor: Color(0xFF654321),
        backgroundColor: Color(0xFF010203),
      ),
    );
  });

  testWidgets('progress source constructors retain MIUIX metrics and motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator.source(progress: 0.25),
                MiuixCircularProgressIndicator.source(progress: 0.5),
                MiuixProgressIndicator.source(circular: true),
                MiuixInfiniteProgressIndicator.source(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
          .height,
      6,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-circular-progress')).first,
      ),
      const Size.square(30),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
      const Size.square(20),
    );
    expect(debugMiuixCircularIndeterminateSweepDegrees(0), 30);
    expect(debugMiuixCircularIndeterminateSweepDegrees(.5), 120);
    expect(debugMiuixCircularIndeterminateSweepDegrees(1), 30);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-linear-progress')))
          .getSemanticsData()
          .role,
      SemanticsRole.progressBar,
    );
    final finiteRange = tester
        .getSemantics(
          find.byKey(const ValueKey('miuix-circular-progress')).first,
        )
        .getSemanticsData();
    expect(finiteRange.role, SemanticsRole.progressBar);
    expect(finiteRange.value, '50%');
    expect(finiteRange.minValue, '0');
    expect(finiteRange.maxValue, '1');
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('miuix-circular-progress')).last,
          )
          .getSemanticsData()
          .role,
      SemanticsRole.loadingSpinner,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress geometry and clocks follow HyperOS tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              progressLinearHeight: 9,
              progressCircularSize: 38,
              progressCircularStrokeWidth: 5,
              progressInfiniteSize: 26,
              progressInfiniteStrokeWidth: 3,
              progressOrbitingDotSize: 4,
              progressLinearMotion: Duration(milliseconds: 2000),
              progressCircularRotationMotion: Duration(milliseconds: 800),
              progressCircularSweepMotion: Duration(milliseconds: 1600),
              progressOrbitMotion: Duration(milliseconds: 400),
            ),
          ),
          child: const Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(),
                MiuixCircularProgressIndicator(),
                MiuixInfiniteProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
          .height,
      9,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-circular-progress'))),
      const Size.square(38),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
      const Size.square(26),
    );

    dynamic linearPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-linear-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic circularPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-circular-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic orbitPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-infinite-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    await tester.pump(const Duration(milliseconds: 200));
    expect(linearPainter().animation, closeTo(.1, .001));
    expect(circularPainter().rotation, closeTo(.25, .001));
    expect(circularPainter().sweepProgress, closeTo(.125, .001));
    expect(orbitPainter().animation, closeTo(.5, .001));
  });

  testWidgets('progress indicators safely freeze non-positive theme clocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              progressLinearMotion: Duration(milliseconds: -1),
              progressCircularRotationMotion: Duration.zero,
              progressCircularSweepMotion: Duration(milliseconds: -2),
              progressOrbitMotion: Duration.zero,
            ),
          ),
          child: const Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(),
                MiuixCircularProgressIndicator(),
                MiuixInfiniteProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );

    dynamic painterFor(Key key) => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    await tester.pump(const Duration(seconds: 3));
    expect(painterFor(const ValueKey('miuix-linear-progress')).animation, .5);
    expect(painterFor(const ValueKey('miuix-circular-progress')).rotation, 0);
    expect(
      painterFor(const ValueKey('miuix-circular-progress')).sweepProgress,
      .5,
    );
    expect(painterFor(const ValueKey('miuix-infinite-progress')).animation, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('indeterminate progress freezes when animations are disabled', (
    tester,
  ) async {
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
                child: const Column(
                  children: [
                    MiuixLinearProgressIndicator(),
                    MiuixCircularProgressIndicator(),
                    MiuixInfiniteProgressIndicator(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    dynamic linearPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-linear-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic circularPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-circular-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic orbitPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-infinite-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    // Prove the ordinary mode is genuinely in flight before changing the
    // inherited accessibility setting. This catches implementations that only
    // read MediaQuery during init and leave already-running tickers alive.
    await tester.pump(const Duration(milliseconds: 137));
    expect(linearPainter().animation, isNot(.5));
    expect(circularPainter().rotation, isNot(0));
    expect(orbitPainter().animation, isNot(0));

    updateFixture(() => reduceMotion = true);
    await tester.pump();
    expect(linearPainter().animation, .5);
    expect(circularPainter().rotation, 0);
    expect(circularPainter().sweepProgress, .5);
    expect(orbitPainter().animation, 0);

    // A long pump must not restart any autonomous cycle. Loading semantics are
    // intentionally retained because motion preference does not change state.
    await tester.pump(const Duration(seconds: 3));
    expect(linearPainter().animation, .5);
    expect(circularPainter().rotation, 0);
    expect(circularPainter().sweepProgress, .5);
    expect(orbitPainter().animation, 0);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-infinite-progress')))
          .getSemanticsData()
          .role,
      SemanticsRole.loadingSpinner,
    );

    updateFixture(() => reduceMotion = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 137));
    expect(linearPainter().animation, isNot(.5));
    expect(circularPainter().rotation, isNot(0));
    expect(orbitPainter().animation, isNot(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress color factory resolves theme channels and overrides', (
    tester,
  ) async {
    late MiuixProgressIndicatorColors resolved;
    late Color expectedBackground;
    late Color expectedDisabled;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              expectedBackground = Theme.of(
                context,
              ).colorScheme.secondaryContainer;
              expectedDisabled = MiuixSemanticColors.of(
                context,
              )['disabledPrimarySlider'];
              resolved = MiuixProgressIndicatorDefaults.progressIndicatorColors(
                context,
                foregroundColor: const Color(0xFF102030),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolved.foregroundColor, const Color(0xFF102030));
    expect(resolved.disabledForegroundColor, expectedDisabled);
    expect(resolved.backgroundColor, expectedBackground);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress indicators expose source sizing colors and physical rounding',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const colors = MiuixProgressIndicatorColors(
        foregroundColor: Color(0xFF123456),
        disabledForegroundColor: Color(0xFF654321),
        backgroundColor: Color(0xFFABCDEF),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Column(
                children: [
                  MiuixLinearProgressIndicator(
                    value: .25,
                    colors: colors,
                    height: 7,
                  ),
                  MiuixCircularProgressIndicator(
                    value: .5,
                    colors: colors,
                    size: 31,
                    strokeWidth: 5,
                  ),
                  MiuixInfiniteProgressIndicator(
                    color: Color(0xFF2468AC),
                    size: 21,
                    strokeWidth: 3,
                    orbitingDotSize: 2.5,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Compose rounds the modifier's measured dp size to a physical pixel,
      // while the Canvas stroke and dot values remain floating-point dp.
      expect(
        tester
            .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
            .height,
        18 / 2.625,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('miuix-circular-progress'))),
        const Size.square(81 / 2.625),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
        const Size.square(55 / 2.625),
      );
      expect(colors.foreground(), const Color(0xFF123456));
      expect(colors.foreground(enabled: false), const Color(0xFF654321));
      final semantics = tester
          .getSemantics(find.byKey(const ValueKey('miuix-linear-progress')))
          .getSemanticsData();
      expect(semantics.value, '25%');
      expect(semantics.minValue, '0');
      expect(semantics.maxValue, '1');
      expect(semantics.role, SemanticsRole.progressBar);
      expect(tester.takeException(), isNull);
    },
  );
}
