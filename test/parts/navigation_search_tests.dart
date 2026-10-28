part of '../miuix_flutter_test.dart';

// 按职责拆分原导航注册，测试名称、顺序与共享私有夹具保持不变。
void _registerNavigationSearchTests() {
  testWidgets('tab row defaults resolve the four source color channels', (
    tester,
  ) async {
    late MiuixTabRowColors colors;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              colors = MiuixTabRowDefaults.tabRowColors(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    final semantic = MiuixSemanticColors.of(context);
    expect(MiuixTabRowDefaults.height, 42);
    expect(MiuixTabRowDefaults.contourHeight, 45);
    expect(MiuixTabRowDefaults.cornerRadius, 12);
    expect(MiuixTabRowDefaults.contourCornerRadius, 8);
    expect(MiuixTabRowDefaults.minWidth, 76);
    expect(MiuixTabRowDefaults.contourMinWidth, 62);
    expect(MiuixTabRowDefaults.maxWidth, 98);
    expect(MiuixTabRowDefaults.contourMaxWidth, 84);
    expect(MiuixTabRowDefaults.itemSpacing, 9);
    expect(MiuixTabRowDefaults.contourItemSpacing, 5);
    expect(colors.backgroundColor, semantic['surface']);
    expect(colors.contentColor, semantic['onSurfaceVariantSummary']);
    expect(colors.selectedBackgroundColor, semantic['surfaceContainer']);
    expect(colors.selectedContentColor, semantic['onBackground']);

    const replacement = Color(0xff102030);
    final changed = colors.copyWith(contentColor: replacement);
    expect(changed.contentColor, replacement);
    expect(changed.backgroundColor, colors.backgroundColor);
    expect(changed.selectedBackgroundColor, colors.selectedBackgroundColor);
    expect(changed.selectedContentColor, colors.selectedContentColor);
    expect(changed, colors.copyWith(contentColor: replacement));
    expect(
      changed.hashCode,
      colors.copyWith(contentColor: replacement).hashCode,
    );
  });

  testWidgets('default tab row uses HyperOS glass metrics and reduced motion', (
    tester,
  ) async {
    var selected = 0;
    var reduceMotion = false;
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
                child: Center(
                  child: SizedBox(
                    width: 366,
                    child: MiuixTabRow(
                      tabs: const ['One', 'Two', 'Three'],
                      selectedTabIndex: selected,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(MiuixTabRowDefaults.hyperOs4Height, 44);
    expect(MiuixTabRowDefaults.hyperOs4CornerRadius, 19);
    expect(MiuixTabRowDefaults.hyperOs4Padding, 3);
    final row = find.byType(MiuixTabRow);
    final surface = tester.widget<MiuixSurface>(
      find.descendant(of: row, matching: find.byType(MiuixSurface)).first,
    );
    final first = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final second = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final positioned = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-tab-indicator')),
    );
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(of: row, matching: find.byType(MiuixPressable)),
    );

    // These are project-calibrated HyperOS values, not unpublished Xiaomi dp.
    expect(tester.getSize(row).height, 44);
    expect(first.height, 38);
    expect(first.width, 118);
    expect(second.left - first.right, 3);
    expect(surface.glass, isTrue);
    expect(surface.radius, 22);
    expect(surface.glassBlur, 18);
    expect(surface.glassOpacity, .60);
    expect(positioned.duration, const Duration(milliseconds: 380));
    expect(positioned.curve, Curves.easeOutCubic);
    expect(tester.widget<Text>(find.text('One')).style?.fontSize, 14);
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w600,
    );
    expect(pressables.every((pressable) => pressable.showIndication), isTrue);

    final start = tester.getTopLeft(indicator).dx;
    updateHost(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final intermediate = tester.getTopLeft(indicator).dx;
    expect(intermediate, greaterThan(start));
    expect(intermediate, lessThan(second.left));
    await tester.pump(const Duration(milliseconds: 260));
    expect(tester.getTopLeft(indicator).dx, closeTo(second.left, .01));

    updateHost(() {
      reduceMotion = true;
      selected = 2;
    });
    await tester.pump();
    final third = tester.getRect(find.byKey(const ValueKey('miuix-tab-2')));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab row applies custom source geometry colors and interaction', (
    tester,
  ) async {
    const colors = MiuixTabRowColors(
      backgroundColor: Color(0xff112233),
      contentColor: Color(0xff445566),
      selectedBackgroundColor: Color(0xff778899),
      selectedContentColor: Color(0xffaabbcc),
    );
    final interactionSource = MiuixInteractionSource();
    addTearDown(interactionSource.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 210,
              child: MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                colors: colors,
                minWidth: 60,
                maxWidth: 70,
                height: 50,
                cornerRadius: 10,
                itemSpacing: 4,
                contentAlignment: Alignment.centerLeft,
                interactionSource: interactionSource,
                showIndication: true,
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byType(MiuixTabRow);
    final first = find.byKey(const ValueKey('miuix-tab-0'));
    final second = find.byKey(const ValueKey('miuix-tab-1'));
    final firstRect = tester.getRect(first);
    final secondRect = tester.getRect(second);
    final background = tester.widget<ColoredBox>(
      find.descendant(of: row, matching: find.byType(ColoredBox)).first,
    );
    final indicator = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    final firstText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(of: row, matching: find.byType(MiuixPressable)),
    );

    expect(tester.getSize(row), const Size(210, 50));
    expect(firstRect.width, closeTo(202 / 3, .01));
    expect(secondRect.left - firstRect.right, closeTo(4, .01));
    expect(
      tester.getTopLeft(find.text('One')).dx,
      closeTo(firstRect.left + 12, .01),
    );
    expect(background.color, colors.backgroundColor);
    expect(indicator.color, colors.selectedBackgroundColor);
    expect(indicator.borderRadius, BorderRadius.circular(10));
    expect(firstText.style?.color, colors.selectedContentColor);
    expect(secondText.style?.color, colors.contentColor);
    expect(
      pressables.every(
        (pressable) =>
            pressable.showIndication &&
            identical(pressable.interactionSource, interactionSource),
      ),
      isTrue,
    );

    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump();
    expect(interactionSource.pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(interactionSource.pressed, isFalse);
  });

  testWidgets('tab items expose selected source tab semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixTabRow.source(tabs: ['One', 'Two'], selectedTabIndex: 1),
        ),
      ),
    );

    final first = tester.getSemantics(
      find.byKey(const ValueKey('miuix-tab-semantic-0')),
    );
    final second = tester.getSemantics(
      find.byKey(const ValueKey('miuix-tab-semantic-1')),
    );
    expect(first.role, SemanticsRole.tab);
    expect(first.flagsCollection.isSelected, Tristate.isFalse);
    expect(first.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(first.rect.height, 48);
    expect(second.role, SemanticsRole.tab);
    expect(second.flagsCollection.isSelected, Tristate.isTrue);
    expect(second.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(second.rect.height, 48);
  });

  testWidgets('tab accepts taps in the source 48dp expansion band', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                selectedTabIndex: 0,
                onTabSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      ),
    );

    final second = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(second.height, 42);
    await tester.tapAt(Offset(second.center.dx, second.top - 2));
    await tester.pump();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab row fills wide source layouts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(tabs: ['One', 'Two', 'Three']),
            ),
          ),
        ),
      ),
    );

    final first = find.byKey(const ValueKey('miuix-tab-0'));
    final second = find.byKey(const ValueKey('miuix-tab-1'));
    final firstRect = tester.getRect(first);
    final secondRect = tester.getRect(second);
    final firstText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    final selectedOutline =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-tab-outline-0')),
                )
                .decoration
            as ShapeDecoration;
    final unselectedOutline =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-tab-outline-1')),
                )
                .decoration
            as ShapeDecoration;
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixTabRow),
        matching: find.byType(MiuixPressable),
      ),
    );
    final semantic = MiuixSemanticColors.of(tester.element(first));

    expect(tester.getSize(find.byType(MiuixTabRow)).height, 42);
    expect(firstRect.width, 116);
    expect(secondRect.left - firstRect.right, 9);
    expect(firstText.style?.fontSize, 16);
    expect(firstText.style?.fontWeight, FontWeight.w700);
    expect(firstText.style?.color, semantic['onBackground']);
    expect(secondText.style?.fontWeight, FontWeight.w400);
    expect(secondText.style?.color, semantic['onSurfaceVariantSummary']);
    expect(indicatorSurface.enabled, isTrue);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(12));
    expect(
      (selectedOutline.shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    expect(
      (unselectedOutline.shape as MiuixSquircleBorder).side,
      BorderSide(color: semantic['outline'], width: 1),
    );
    expect(
      pressables.every(
        (pressable) =>
            pressable.feedbackType == MiuixPressFeedbackType.none &&
            !pressable.showIndication,
      ),
      isTrue,
    );
  });

  testWidgets('tab row preserves the source empty-list surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              SizedBox(width: 300, child: MiuixTabRow.source(tabs: [])),
              SizedBox(
                width: 300,
                child: MiuixTabRowWithContour.source(tabs: []),
              ),
            ],
          ),
        ),
      ),
    );

    // calculateTabWidth returns the variant's minimum width for an empty
    // source list. Both composables still build their fixed-height surface
    // and a zero-selection indicator; they do not collapse.
    expect(tester.getSize(find.byType(MiuixTabRow)), const Size(300, 42));
    expect(
      tester.getSize(find.byType(MiuixTabRowWithContour)),
      const Size(300, 45),
    );
    final indicators = find.byKey(
      const ValueKey('miuix-tab-indicator-surface'),
    );
    expect(indicators, findsNWidgets(2));
    expect(tester.getSize(indicators.at(0)).width, 76);
    expect(tester.getSize(indicators.at(1)).width, 62);
    expect(find.byKey(const ValueKey('miuix-tab-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab row snaps an initial nonzero source selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(
                tabs: ['One', 'Two', 'Three'],
                selectedTabIndex: 2,
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final third = tester.getRect(find.byKey(const ValueKey('miuix-tab-2')));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(
      tester.widget<Text>(find.text('Three')).style?.fontWeight,
      FontWeight.w700,
    );

    // Current TabRow derives its indicator offset directly. It must not reuse
    // the contour variant's remembered Animatable or delayed target handoff.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('source-controlled tab row waits for its selected index', (
    tester,
  ) async {
    var selected = 0;
    var callbackIndex = -1;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                selectedTabIndex: selected,
                onTabSelected: (index) => callbackIndex = index,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(callbackIndex, 1);
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('Two')).style?.fontWeight,
      FontWeight.w400,
    );

    updateHost(() => selected = 1);
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w400,
    );
    expect(
      tester.widget<Text>(find.text('Two')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab indicator follows selection without animation', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return MiuixTabRow.source(
                    tabs: const ['One', 'Two', 'Three'],
                    selectedTabIndex: selected,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final start = tester.getTopLeft(indicator).dx;
    final firstTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final secondTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(start, closeTo(firstTab.left, .01));

    updateHost(() => selected = 1);
    await tester.pump();
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contour tab indicator follows the source 200 ms linear motion', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return MiuixTabRowWithContour.source(
                    tabs: const ['One', 'Two', 'Three'],
                    selectedTabIndex: selected,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final firstTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final secondTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(tester.getTopLeft(indicator).dx, closeTo(firstTab.left, .01));

    updateHost(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(indicator).dx,
      closeTo((firstTab.left + secondTab.left) / 2, .01),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contour tab row snaps its initial selection and scroll offset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
                selectedTabIndex: 5,
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byType(MiuixTabRowWithContour);
    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final selected = find.byKey(const ValueKey('miuix-tab-5'));
    await tester.pump();

    // The first source LaunchedEffect uses scrollToItem and the contour
    // Animatable uses snapTo, so neither operation begins an entrance tween.
    expect(tester.getRect(indicator), tester.getRect(selected));
    expect(
      tester.getRect(selected).right,
      lessThanOrEqualTo(tester.getRect(row).right),
    );
    final scrollable = find.descendant(
      of: row,
      matching: find.byType(Scrollable),
    );
    expect(
      tester
          .state<ScrollableState>(scrollable)
          .position
          .isScrollingNotifier
          .value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab rows follow the source smooth-rounding theme switch', (
    tester,
  ) async {
    final theme = MiuixThemeData.defaults().copyWith(enableSquircle: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: theme,
          child: const Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: ['One', 'Two', 'Three'],
              ),
            ),
          ),
        ),
      ),
    );

    final outer = tester.widget<SizedBox>(
      find.byKey(const ValueKey('miuix-contour-tab-surface')),
    );
    final outerSurface = tester.widget<MiuixSquircleBackground>(
      find
          .descendant(
            of: find.byKey(const ValueKey('miuix-contour-tab-surface')),
            matching: find.byType(MiuixSquircleBackground),
          )
          .first,
    );
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );

    // LocalSmoothRounding=false makes both source shapes ordinary rounded
    // rectangles; the geometry and radii remain unchanged.
    expect(outer.height, 45);
    expect(outerSurface.enabled, isFalse);
    expect(outerSurface.borderRadius, BorderRadius.circular(13));
    expect(indicatorSurface.enabled, isFalse);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('contour tab row uses source metrics and centers selection', (
    tester,
  ) async {
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: const ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
                onTap: (index) => selected = index,
              ),
            ),
          ),
        ),
      ),
    );

    final outer = tester.widget<SizedBox>(
      find.byKey(const ValueKey('miuix-contour-tab-surface')),
    );
    final outerSurface = tester.widget<MiuixSquircleBackground>(
      find
          .descendant(
            of: find.byKey(const ValueKey('miuix-contour-tab-surface')),
            matching: find.byType(MiuixSquircleBackground),
          )
          .first,
    );
    final selectedTabFinder = find.byKey(const ValueKey('miuix-tab-0'));
    final secondTabFinder = find.byKey(const ValueKey('miuix-tab-1'));
    final selectedText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(MiuixPressable),
      ),
    );
    final horizontalViewport = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    final selectedRect = tester.getRect(selectedTabFinder);
    final secondRect = tester.getRect(secondTabFinder);
    final semantic = MiuixSemanticColors.of(tester.element(selectedTabFinder));
    final indicator = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-tab-indicator')),
    );
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );

    expect(tester.getSize(find.byType(MiuixTabRowWithContour)).height, 45);
    expect(outer.height, 45);
    expect(outerSurface.color, semantic['surface']);
    expect(outerSurface.enabled, isTrue);
    expect(outerSurface.borderRadius, BorderRadius.circular(13));
    expect(tester.getSize(selectedTabFinder).height, 35);
    expect(tester.getSize(selectedTabFinder).width, 62);
    // Compose LazyRow clips only scroll-axis paint. This prevents the sixth
    // sample label from escaping the right side while the independent target
    // proxy below still exposes the full 48dp vertical interaction band.
    expect(horizontalViewport.clipBehavior, Clip.hardEdge);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-tab-semantic-0')))
          .rect
          .height,
      48,
    );
    expect(tester.getSize(secondTabFinder).height, 35);
    expect(tester.getSize(secondTabFinder).width, 62);
    expect(secondRect.left - selectedRect.right, closeTo(5, 1));
    expect(selectedText.style?.fontSize, 14);
    expect(selectedText.style?.fontWeight, FontWeight.w700);
    expect(selectedText.style?.color, semantic['onBackground']);
    expect(secondText.style?.fontWeight, FontWeight.w400);
    expect(secondText.style?.color, semantic['onSurfaceVariantSummary']);
    expect(indicator.duration, const Duration(milliseconds: 200));
    expect(indicator.curve, Curves.linear);
    expect(indicatorSurface.color, semantic['surfaceContainer']);
    expect(indicatorSurface.enabled, isTrue);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(8));
    expect(
      pressables.every(
        (pressable) =>
            pressable.feedbackType == MiuixPressFeedbackType.none &&
            !pressable.showIndication,
      ),
      isTrue,
    );

    await tester.drag(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Four'));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(Scrollable),
      ),
    );
    expect(selected, 3);
    expect(scrollable.position.pixels, closeTo(87, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom snackbar, chip, and pull refresh stay safe', (
    tester,
  ) async {
    var actionPressed = false;
    var chipDeleted = false;
    var refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    MiuixTextButton(
                      label: 'Show snackbar',
                      onPressed: () {
                        MiuixSnackbar.show(
                          context,
                          'Saved',
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => actionPressed = true,
                          ),
                        );
                      },
                    ),
                    MiuixTextButton(
                      label: 'Show toast',
                      onPressed: () => MiuixToast.show(context, 'Toast text'),
                    ),
                    MiuixChip(
                      label: 'Tagged',
                      icon: const Icon(Icons.label_outline),
                      onDeleted: () => chipDeleted = true,
                    ),
                    SizedBox(
                      height: 120,
                      child: MiuixPullToRefresh(
                        onRefresh: () async => refreshed = true,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 300, child: Text('Refresh child')),
                          ],
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
    );

    await tester.tap(find.text('Show snackbar'));
    // Snackbar.kt uses Compose's critically damped default spring rather than
    // a fixed 180ms tween. Settle that source motion before exercising action
    // hit testing so the control is at its final screen coordinate.
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(actionPressed, isTrue);

    await tester.tap(find.text('Show toast'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('Toast text'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 120));
    expect(chipDeleted, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, 160));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));
    expect(refreshed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom text fields and segmented controls stay safe', (
    tester,
  ) async {
    final controller = TextEditingController();
    var changed = '';
    var submitted = '';
    var selected = <String>{'A'};

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixTextField(
                      controller: controller,
                      label: 'Name',
                      hint: 'Type name',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: const Icon(Icons.check),
                      onChanged: (value) => changed = value,
                      onSubmitted: (value) => submitted = value,
                    ),
                    const MiuixTextField(hint: 'Internal controller'),
                    MiuixSegmentedControl<String>(
                      values: const ['A', 'B', 'C'],
                      selected: selected,
                      labelBuilder: (value) => value,
                      onSelectionChanged: (value) =>
                          setState(() => selected = value),
                    ),
                    const MiuixSegmentedControl<String>(
                      values: [],
                      selected: {},
                      labelBuilder: _identityLabel,
                      onSelectionChanged: _ignoreStringSet,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, 'Miuix');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(changed, 'Miuix');
    expect(submitted, 'Miuix');
    expect(controller.text, 'Miuix');

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(selected, containsAll(['A', 'B']));

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(selected, isNot(contains('A')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized empty text field keeps source one-line height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 320,
              child: MiuixTextField(
                key: ValueKey('localized-source-field'),
                label: '文本框',
              ),
            ),
          ),
        ),
      ),
    );

    // TextFieldDefaults.InsideMargin contributes 16dp above and below. At the
    // test's 3x density, the source 17sp line box encloses 60 physical pixels;
    // together with the two 48px insets that is 156px.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('localized-source-field')))
          .height,
      52,
    );
    final labelDefaults = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('文本框'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    // The rendered style carries the already-enclosed 60px line box back as a
    // ratio so Text and StrutStyle cannot independently round it a second time.
    expect(labelDefaults.style.height, closeTo(20 / 17, 1e-12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preference trailing content contracts on narrow screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 220,
              child: MiuixSettingsGroup(
                children: [
                  const MiuixPreference(
                    title: 'Display mode',
                    summary: 'A compact row with a long selected value.',
                    leading: Icon(Icons.tune),
                    trailing: Text('Very long selected preference value'),
                  ),
                  MiuixDropdownPreference<String>(
                    title: 'Dropdown',
                    value: 'expressive',
                    entries: const [
                      MiuixDropdownEntry(
                        value: 'expressive',
                        label: 'Expressive mode with long copy',
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Display mode'), findsOneWidget);
    expect(find.text('Dropdown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar uses HyperOS 4 glass metrics and clears safely', (
    tester,
  ) async {
    final firstController = TextEditingController();
    final secondController = TextEditingController(text: 'swap');
    final changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixSearchBar(
              controller: firstController,
              hint: 'Search components',
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 48);
    final semanticTarget = find.byKey(
      const ValueKey('miuix-search-semantic-target'),
    );
    expect(tester.getSize(semanticTarget).height, 48);
    final semantics = tester.ensureSemantics();
    final semanticNode = tester.getSemantics(semanticTarget);
    // The HyperOS 4 capsule and accessibility target now share 48dp.
    expect(semanticNode.rect.height, 48);
    semantics.dispose();
    // InputField.kt applies size(44.dp) before 16dp/8dp padding. The padding
    // constrains the vector to 20dp; it must not enlarge the slot to 48dp.
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-leading-slot'))),
      const Size(44, 44),
    );
    final glass = tester.widget<MiuixGlass>(container);
    expect(glass.enabled, isTrue);
    expect(glass.blur, 18);
    expect(glass.opacity, .62);
    final clip = tester.widget<ClipPath>(
      find.descendant(of: container, matching: find.byType(ClipPath)).first,
    );
    final shape = (clip.clipper! as ShapeBorderClipper).shape;
    expect(shape, isA<MiuixSquircleBorder>());
    expect((shape as MiuixSquircleBorder).side, BorderSide.none);
    expect(
      tester
          .widget<EditableText>(
            find.byKey(const ValueKey('miuix-search-bar-input')),
          )
          .style
          .fontSize,
      17,
    );

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'miuix',
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-trailing-slot'))),
      const Size(44, 44),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-bar-clear'))),
      const Size(20, 20),
    );
    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-clear')));
    await tester.pump();

    expect(firstController.text, isEmpty);
    expect(changes, containsAll(['miuix', '']));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(body: MiuixSearchBar(controller: secondController)),
        ),
      ),
    );
    await tester.pump();

    expect(secondController.text, 'swap');
    expect(tester.takeException(), isNull);
  });

  testWidgets('search collapse never clears a replacement controller', (
    tester,
  ) async {
    final firstController = TextEditingController(text: 'old query');
    final secondController = TextEditingController(text: 'new query');
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    var controller = firstController;
    var expanded = true;
    late StateSetter rebuildHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildHost = setState;
                return MiuixSearchBar(
                  controller: controller,
                  expanded: expanded,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    rebuildHost(() {
      controller = secondController;
      expanded = false;
    });
    await tester.pump();
    await tester.pump();

    expect(firstController.text, 'old query');
    expect(secondController.text, 'new query');
    expect(tester.takeException(), isNull);
  });

  testWidgets('search glass follows the smooth capsule switch', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    Future<void> pumpSearch({required bool enableSquircle}) {
      return tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              enableSquircle: enableSquircle,
            ),
            child: Scaffold(body: MiuixSearchBar(controller: controller)),
          ),
        ),
      );
    }

    ShapeBorder currentShape() {
      final surface = find.byKey(const ValueKey('miuix-search-bar-container'));
      final clip = tester.widget<ClipPath>(
        find.descendant(of: surface, matching: find.byType(ClipPath)).first,
      );
      return (clip.clipper! as ShapeBorderClipper).shape;
    }

    await pumpSearch(enableSquircle: true);
    expect(currentShape(), isA<MiuixSquircleBorder>());

    await pumpSearch(enableSquircle: false);
    expect(currentShape(), isA<RoundedRectangleBorder>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar expands source action and result slots', (
    tester,
  ) async {
    final controller = TextEditingController();
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixSearchBar(
                controller: controller,
                expanded: expanded,
                onExpandedChanged: (value) {
                  setState(() => expanded = value);
                },
                outsideEndAction: GestureDetector(
                  key: const ValueKey('source-search-cancel'),
                  onTap: () => setState(() => expanded = false),
                  child: const Text('Cancel'),
                ),
                expandedContent: const Text(
                  'Suggestion',
                  key: ValueKey('source-search-result'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('source-search-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-result')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-input')));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(find.byKey(const ValueKey('source-search-cancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-result')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'query',
    );
    await tester.tap(find.byKey(const ValueKey('source-search-cancel')));
    await tester.pumpAndSettle();
    expect(expanded, isFalse);
    expect(controller.text, isEmpty);
    expect(find.byKey(const ValueKey('source-search-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-result')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar inserted already expanded requests input focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixSearchBar(
              controller: controller,
              expanded: true,
              onExpandedChanged: (_) {},
              outsideEndAction: const Text('取消'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.byKey(const ValueKey('miuix-search-bar-input')),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar stays safe under very narrow constraints', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'narrow');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              width: 44,
              child: MiuixSearchBar(controller: controller),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('miuix-search-bar-container')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar accepts a bounded legacy app-bar height', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              height: 45,
              child: MiuixSearchBar(controller: controller),
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 45);
    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('miuix-search-semantic-target')),
          )
          .rect
          .height,
      48,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search input exposes HyperOS defaults and legacy metrics', (
    tester,
  ) async {
    var query = '';
    var expanded = false;
    var searched = '';
    final interaction = MiuixInteractionSource();
    addTearDown(interaction.dispose);

    expect(MiuixSearchBarDefaults.insideMargin, const Size(12, 0));
    expect(MiuixSearchBarDefaults.inputFieldMinHeight, 48);
    expect(MiuixSearchBarDefaults.legacyInputFieldMinHeight, 45);
    expect(MiuixSearchBarDefaults.inputFieldFontSize, 17);
    expect(MiuixSearchBarDefaults.leadingIconStartPadding, 16);
    expect(MiuixSearchBarDefaults.leadingIconEndPadding, 8);
    expect(MiuixSearchBarDefaults.trailingIconStartPadding, 8);
    expect(MiuixSearchBarDefaults.trailingIconEndPadding, 16);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixSearchBar.source(
                inputField: MiuixInputField(
                  query: query,
                  onQueryChange: (value) => setState(() => query = value),
                  onSearch: (value) => searched = value,
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  label: '搜索',
                  interactionSource: interaction,
                ),
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
                outsideEndAction: const Text(
                  '取消',
                  key: ValueKey('source-search-action'),
                ),
                content: const Text(
                  '建议',
                  key: ValueKey('source-search-content'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 48);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-action')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-content')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-leading-slot'))),
      const Size(44, 20),
    );

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-container')));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(interaction.focused, isTrue);
    expect(find.text('搜索'), findsNothing);
    expect(find.byKey(const ValueKey('source-search-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-content')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'miuix',
    );
    await tester.pumpAndSettle();
    expect(query, 'miuix');
    final trailing = tester.getSize(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
    );
    expect(trailing.width, closeTo(42.199984, .0001));
    expect(trailing.height, closeTo(18.199984, .0001));

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(searched, 'miuix');

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-clear')));
    await tester.pumpAndSettle();
    expect(query, isEmpty);
    expect(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('source search collapse delays fade cleanup and focus release', (
    tester,
  ) async {
    var query = 'query';
    var expanded = true;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixInputField(
                query: query,
                onQueryChange: (value) => setState(() => query = value),
                onSearch: (_) {},
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final editableFinder = find.byKey(const ValueKey('miuix-search-bar-input'));
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );

    expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixInputField(
                query: query,
                onQueryChange: (value) => setState(() => query = value),
                onSearch: (_) {},
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 99));
    expect(query, 'query');
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(query, isEmpty);
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search reduced motion snaps visibility and collapse cleanup', (
    tester,
  ) async {
    var query = 'query';
    var expanded = true;
    late StateSetter updateSearch;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateSearch = setState;
                return MiuixSearchBar.source(
                  inputField: MiuixInputField(
                    query: query,
                    onQueryChange: (value) => setState(() => query = value),
                    onSearch: (_) {},
                    expanded: expanded,
                    onExpandedChange: (value) {
                      setState(() => expanded = value);
                    },
                  ),
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  outsideEndAction: const Text(
                    '立即取消',
                    key: ValueKey('reduced-search-action'),
                  ),
                  content: const Text(
                    '立即结果',
                    key: ValueKey('reduced-search-content'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final editableFinder = find.byKey(const ValueKey('miuix-search-bar-input'));
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );
    expect(find.byKey(const ValueKey('reduced-search-action')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reduced-search-content')),
      findsOneWidget,
    );

    updateSearch(() => expanded = false);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(query, isEmpty);
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      false,
    );
    expect(find.byKey(const ValueKey('reduced-search-action')), findsNothing);
    expect(find.byKey(const ValueKey('reduced-search-content')), findsNothing);
    expect(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
      findsNothing,
    );

    // Re-expansion after an interrupted collapse restores text opacity to its
    // visible endpoint instead of allowing the old fade to keep running.
    updateSearch(() {
      query = 'restored';
      expanded = true;
    });
    await tester.pump();
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(MiuixInputField),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling reduced motion settles active search expansion', (
    tester,
  ) async {
    var expanded = false;
    var reduceMotion = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: MiuixTheme(
              child: Scaffold(
                body: MiuixSearchBar.source(
                  inputField: MiuixInputField(
                    query: '',
                    onQueryChange: (_) {},
                    onSearch: (_) {},
                    expanded: expanded,
                    onExpandedChange: (value) {
                      setState(() => expanded = value);
                    },
                  ),
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  outsideEndAction: const Text(
                    '动态取消',
                    key: ValueKey('moving-search-action'),
                  ),
                  content: const SizedBox(
                    key: ValueKey('moving-search-content'),
                    height: 120,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    updateHost(() => expanded = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    Align actionReveal() => tester
        .widgetList<Align>(
          find.ancestor(
            of: find.byKey(const ValueKey('moving-search-action')),
            matching: find.byType(Align),
          ),
        )
        .firstWhere((align) => align.widthFactor != null);
    Align contentReveal() => tester
        .widgetList<Align>(
          find.ancestor(
            of: find.byKey(const ValueKey('moving-search-content')),
            matching: find.byType(Align),
          ),
        )
        .firstWhere((align) => align.heightFactor != null);
    expect(actionReveal().widthFactor!, inExclusiveRange(0, 1));
    expect(contentReveal().heightFactor!, inExclusiveRange(0, 1));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(actionReveal().widthFactor, 1);
    expect(contentReveal().heightFactor, 1);
    expect(tester.takeException(), isNull);
  });
}
