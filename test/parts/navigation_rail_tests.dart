part of '../miuix_flutter_test.dart';

// 按职责拆分原导航注册，测试名称、顺序与共享私有夹具保持不变。
void _registerNavigationRailTests() {
  testWidgets('top app bar defaults to gradient glass and circular actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(),
          child: Scaffold(
            appBar: MiuixTopAppBar(
              title: 'Browse',
              large: false,
              actions: [
                MiuixIconButton(
                  key: const ValueKey('selected-top-action'),
                  selected: true,
                  onPressed: () {},
                  icon: const Icon(Icons.search),
                ),
                MiuixIconButton(
                  key: const ValueKey('normal-top-action'),
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar));
    expect(bar.blurStyle, MiuixTopAppBarBlurStyle.gradient);
    expect(bar.actionStyle, MiuixTopAppBarActionStyle.glass);
    expect(
      find.byKey(const ValueKey('top-app-bar-progressive-glass')),
      findsOneWidget,
    );
    expect(find.byType(ShaderMask), findsNothing);
    final actionGroup = find.byKey(const ValueKey('top-app-bar-glass-actions'));
    expect(tester.getSize(actionGroup), const Size(100, 48));
    final actionGlass = find.descendant(
      of: actionGroup,
      matching: find.byType(MiuixGlass),
    );
    expect(actionGlass, findsNWidgets(2));
    for (final glass in tester.widgetList<MiuixGlass>(actionGlass)) {
      expect(glass.shape, isA<CircleBorder>());
      expect(tester.getSize(find.byWidget(glass)), const Size(44, 44));
    }
    final selectedAction = find.byKey(const ValueKey('selected-top-action'));
    final selectedSurface = tester.widget<DecoratedBox>(
      find.descendant(
        of: selectedAction,
        matching: find.byKey(const ValueKey('miuix-icon-button-surface')),
      ),
    );
    final selectedDecoration = selectedSurface.decoration as ShapeDecoration;
    expect(selectedDecoration.shape, isA<CircleBorder>());
    expect(selectedDecoration.color!.a, closeTo(.14, .001));
    final selectedIconTheme = tester.widget<IconTheme>(
      find.descendant(of: selectedAction, matching: find.byType(IconTheme)),
    );
    expect(
      selectedIconTheme.data.color,
      Theme.of(tester.element(selectedAction)).colorScheme.primary,
    );
    expect(
      find.descendant(of: actionGroup, matching: find.byType(BackdropFilter)),
      findsNWidgets(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('source floating action button keeps MIUIX surface metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixFloatingActionButton.source(
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final scheme = Theme.of(
      tester.element(find.byType(MiuixFloatingActionButton)),
    ).colorScheme;
    final shadowBox = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-floating-action-button-surface')),
    );
    final shadowDecoration = shadowBox.decoration as ShapeDecoration;
    final fillBox = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-floating-action-button-fill')),
    );
    final fillDecoration = fillBox.decoration as ShapeDecoration;
    final iconTheme = tester.widget<IconTheme>(
      find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(IconTheme),
      ),
    );

    expect(
      tester.getSize(find.byType(MiuixFloatingActionButton)),
      const Size(60, 60),
    );
    expect(MiuixFloatingActionButtonDefaults.minWidth, 60);
    expect(MiuixFloatingActionButtonDefaults.minHeight, 60);
    expect(MiuixFloatingActionButtonDefaults.shadowElevation, 4);
    expect(fillDecoration.color, scheme.primary);
    expect(fillDecoration.shape, isA<StadiumBorder>());
    expect((fillDecoration.shape as StadiumBorder).side, BorderSide.none);
    expect(shadowDecoration.color, Colors.transparent);
    expect(shadowDecoration.shape, fillDecoration.shape);
    expect(shadowDecoration.shadows, hasLength(1));
    final shadow = shadowDecoration.shadows!.single;
    expect(shadow.color.a, closeTo(.20, .001));
    expect(shadow.blurRadius, 8);
    expect(shadow.offset, const Offset(0, 2));
    expect(iconTheme.data.color, scheme.onSurface);
    expect(iconTheme.data.size, 24);

    // Surface.kt uses LocalIndication without adding sink motion.
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.none);
    expect(pressable.showIndication, isTrue);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiuixFloatingActionButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final indication = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('miuix-press-indication')),
    );
    expect(indication.opacity.value, inExclusiveRange(0, .10));
    await tester.pumpAndSettle();
    expect(indication.opacity.value, closeTo(.10, .001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating action button defaults to one shape-aligned HyperOS glass',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: MiuixFloatingActionButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MiuixFloatingActionButton));
      final scheme = Theme.of(context).colorScheme;
      final tokens = MiuixTheme.of(context).hyperOs4;
      final glassFinder = find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(MiuixGlass),
      );
      expect(glassFinder, findsOneWidget);
      final glass = tester.widget<MiuixGlass>(glassFinder);
      expect(glass.blur, tokens.floatingActionButtonBlur);
      expect(glass.opacity, tokens.floatingActionButtonTintOpacity);
      expect(glass.color, scheme.primary);
      expect(glass.shape, isA<StadiumBorder>());
      expect(glass.showSpecular, isTrue);
      expect(
        find.byKey(const ValueKey('miuix-floating-action-button-fill')),
        findsNothing,
      );

      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
          of: find.byType(MiuixFloatingActionButton),
          matching: find.byType(IconTheme),
        ),
      );
      expect(iconTheme.data.color, scheme.onPrimary);
      final shadow = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      expect((shadow.decoration as ShapeDecoration).shape, glass.shape);
      expect(tester.takeException(), isNull);
    },
  );

  test('floating action capsule follows the final shorter dimension', () {
    const capsule = MiuixCapsuleBorder();
    const square = Rect.fromLTWH(0, 0, 60, 60);
    const extended = Rect.fromLTWH(0, 0, 120, 80);
    final squarePath = capsule.getOuterPath(square);
    final extendedPath = capsule.getOuterPath(extended);
    final squareReference = const MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ).getOuterPath(square);
    final extendedReference = const MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(40)),
    ).getOuterPath(extended);

    // Path objects do not define geometric equality. Sampling the complete
    // physical grid verifies that each capsule uses half of its own short edge.
    for (var y = 0.5; y < square.height; y += 1) {
      for (var x = 0.5; x < square.width; x += 1) {
        final point = Offset(x, y);
        expect(squarePath.contains(point), squareReference.contains(point));
      }
    }
    for (var y = 0.5; y < extended.height; y += 1) {
      for (var x = 0.5; x < extended.width; x += 1) {
        final point = Offset(x, y);
        expect(extendedPath.contains(point), extendedReference.contains(point));
      }
    }
  });

  testWidgets('floating action circle ignores the smooth-rounding switch', (
    tester,
  ) async {
    for (final enableSquircle in <bool>[true, false]) {
      final theme = MiuixThemeData.defaults().copyWith(
        enableSquircle: enableSquircle,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: theme,
            child: Center(
              child: MiuixFloatingActionButton.source(
                onPressed: () {},
                child: const SizedBox(width: 96, height: 64),
              ),
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      final shape = (decorated.decoration as ShapeDecoration).shape;
      // Upstream uses CircleShape directly; the global smooth-corner setting
      // must not silently replace it with MIUIX's G2 squircle capsule.
      expect(shape, isA<StadiumBorder>());
      expect(
        tester.getSize(find.byType(MiuixFloatingActionButton)),
        const Size(96, 64),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating action button preserves content and accepts negative shadow',
    (tester) async {
      const customShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingActionButton.source(
                onPressed: null,
                shape: customShape,
                containerColor: Colors.red,
                contentColor: Colors.cyan,
                // Surface.kt tests only `> 0f`. A negative Dp is therefore a
                // legal no-shadow request, not a constructor error.
                shadowElevation: -4,
                minWidth: 72,
                minHeight: 64,
                child: SizedBox(
                  key: ValueKey('source-fab-content'),
                  width: 96,
                  height: 44,
                ),
              ),
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-fill')),
      );
      final decoration = decorated.decoration as ShapeDecoration;
      final shadowBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      final shadowDecoration = shadowBox.decoration as ShapeDecoration;
      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
          of: find.byType(MiuixFloatingActionButton),
          matching: find.byType(IconTheme),
        ),
      );
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(MiuixFloatingActionButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      // Compose defaultMinSize supplies only minimum constraints, so content is
      // free to make the source surface wider than the default 60dp.
      expect(
        tester.getSize(find.byType(MiuixFloatingActionButton)),
        const Size(96, 64),
      );
      final surfaceRect = tester.getRect(
        find.byType(MiuixFloatingActionButton),
      );
      final contentRect = tester.getRect(
        find.byKey(const ValueKey('source-fab-content')),
      );
      // Source Box(contentAlignment = Center) centers the shorter content in
      // the independently supplied minimum height.
      expect(contentRect.center, surfaceRect.center);
      expect(contentRect.top - surfaceRect.top, 10);
      expect(decoration.color, Colors.red);
      expect(decoration.shape, customShape);
      expect(shadowDecoration.shadows, anyOf(isNull, isEmpty));
      expect(iconTheme.data.color, Colors.cyan);
      expect(semantics.properties.enabled, isFalse);
      expect(
        find.byKey(const ValueKey('miuix-press-indication')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('floating action button centers a small arbitrary child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingActionButton.source(
              onPressed: null,
              child: SizedBox(
                key: ValueKey('small-fab-content'),
                width: 20,
                height: 10,
              ),
            ),
          ),
        ),
      ),
    );

    final surfaceRect = tester.getRect(find.byType(MiuixFloatingActionButton));
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('small-fab-content')),
    );
    expect(surfaceRect.size, const Size.square(60));
    expect(contentRect.size, const Size(20, 10));
    expect(contentRect.center, surfaceRect.center);
    expect(contentRect.topLeft - surfaceRect.topLeft, const Offset(20, 25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaffold places FAB with MIUIX spacing above bottom bar', (
    tester,
  ) async {
    const fabKey = ValueKey('fab');
    const bottomKey = ValueKey('bottom-bar');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: const SizedBox(key: bottomKey, height: 64),
            floatingActionButton: MiuixFloatingActionButton(
              key: fabKey,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final fabRect = tester.getRect(find.byKey(fabKey));
    final bottomRect = tester.getRect(find.byKey(bottomKey));

    expect(800 - fabRect.right, closeTo(12, 1));
    expect(bottomRect.top - fabRect.bottom, closeTo(12, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('glass bottom bar keeps FAB above its measured source height', (
    tester,
  ) async {
    const density = 2.625;
    const fabKey = ValueKey('glass-fab');
    const bottomKey = ValueKey('glass-bottom-bar');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: MiuixNavigationBar(
              key: bottomKey,
              glass: true,
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
            floatingActionButton: MiuixFloatingActionButton(
              key: fabKey,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fabRect = tester.getRect(find.byKey(fabKey));
    final bottomRect = tester.getRect(find.byKey(bottomKey));
    final windowWidth = tester.view.physicalSize.width / density;

    // Scaffold.kt rounds 12dp to 32px before placing the 158px FAB. A glass
    // bar extends the body, so its complete measured height must also be
    // subtracted rather than letting the button paint behind the bar.
    expect(fabRect.width * density, closeTo(158, .01));
    expect(fabRect.height * density, closeTo(158, .01));
    expect((windowWidth - fabRect.right) * density, closeTo(32, .01));
    expect((bottomRect.top - fabRect.bottom) * density, closeTo(32, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaffold keeps snackbar above the measured floating button', (
    tester,
  ) async {
    const fabKey = ValueKey('snackbar-fab');
    const snackbarKey = ValueKey('snackbar-above-fab');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: SizedBox.expand(),
            bottomBar: SizedBox(height: 64),
            floatingActionButton: SizedBox(key: fabKey, width: 60, height: 60),
            snackbarHost: SizedBox(key: snackbarKey, height: 40),
          ),
        ),
      ),
    );
    // Compose subcomposes both placeables in one pass. The Flutter adapter
    // reads their final transformed rectangles immediately after first layout.
    await tester.pump();
    await tester.pump();

    final fabRect = tester.getRect(find.byKey(fabKey));
    final snackbarRect = tester.getRect(find.byKey(snackbarKey));
    expect(snackbarRect.bottom, closeTo(fabRect.top, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar clears only a bottom-docked floating toolbar', (
    tester,
  ) async {
    const density = 2.625;
    const toolbarKey = ValueKey('snackbar-toolbar');
    const snackbarKey = ValueKey('snackbar-above-toolbar');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget configuredScene(MiuixToolbarPosition position) {
      return MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: const SizedBox(height: 64),
            floatingToolbarPosition: position,
            floatingToolbar: const SizedBox(
              key: toolbarKey,
              width: 100,
              height: 140,
            ),
            snackbarHost: const SizedBox(key: snackbarKey, height: 40),
          ),
        ),
      );
    }

    await tester.pumpWidget(configuredScene(MiuixToolbarPosition.bottomCenter));
    await tester.pump();
    await tester.pump();

    var toolbarRect = tester.getRect(find.byKey(toolbarKey));
    var snackbarRect = tester.getRect(find.byKey(snackbarKey));
    // FloatingToolbarSpacing is independently rounded: 4dp at 2.625 density
    // is an 11px gap rather than a fractional 10.5px placement.
    expect((toolbarRect.top - snackbarRect.bottom) * density, closeTo(11, .01));

    await tester.pumpWidget(configuredScene(MiuixToolbarPosition.topCenter));
    await tester.pump();
    await tester.pump();
    toolbarRect = tester.getRect(find.byKey(toolbarKey));
    snackbarRect = tester.getRect(find.byKey(snackbarKey));
    final bottomBarRect = tester.getRect(find.byType(MiuixScaffold));
    expect(toolbarRect.bottom, lessThan(snackbarRect.top));
    // A top/center toolbar is not a bottom obstruction. The snackbar keeps
    // the ordinary 64dp bottom-bar anchor instead of jumping above it.
    expect(
      (bottomBarRect.bottom - snackbarRect.bottom) * density,
      closeTo(168, .01),
    );
    expect(tester.takeException(), isNull);
  });

  test('pull refresh defaults match the upstream public constants', () {
    // Compose Color.Gray is #888888, not Material Colors.grey (#9E9E9E).
    expect(MiuixPullToRefreshDefaults.color, const Color(0xFF888888));
    expect(MiuixPullToRefreshDefaults.circleSize, 20);
    expect(MiuixPullToRefreshDefaults.refreshTextStyle.fontSize, 14);
    expect(
      MiuixPullToRefreshDefaults.refreshTextStyle.fontWeight,
      FontWeight.bold,
    );
    expect(
      MiuixPullToRefreshDefaults.refreshTextStyle.color,
      const Color(0xFF888888),
    );
    expect(MiuixPullToRefreshDefaults.refreshTexts, hasLength(4));
  });

  testWidgets('pull refresh uses HyperOS tokens and source stays fixed', (
    tester,
  ) async {
    Widget fixture({required bool source}) => MaterialApp(
      home: MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            pullRefreshIndicatorSize: 28,
            pullRefreshSettleMotion: Duration(milliseconds: 10),
            pullRefreshCompleteMotion: Duration(milliseconds: 333),
            pullRefreshOrbitMotion: Duration(milliseconds: 777),
          ),
        ),
        child: Scaffold(
          body: source
              ? MiuixPullToRefresh.source(
                  isRefreshing: true,
                  onRefresh: () {},
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 800)],
                  ),
                )
              : MiuixPullToRefresh(
                  isRefreshing: true,
                  onRefresh: () {},
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 800)],
                  ),
                ),
        ),
      ),
    );

    List<AnimationController> orbitControllers() => tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .map((builder) => builder.animation)
        .whereType<AnimationController>()
        .toList(growable: false);

    await tester.pumpWidget(fixture(source: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(28),
    );
    expect(
      orbitControllers().map((controller) => controller.duration),
      contains(const Duration(milliseconds: 777)),
    );

    await tester.pumpWidget(fixture(source: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(20),
    );
    expect(
      orbitControllers().map((controller) => controller.duration),
      contains(const Duration(milliseconds: 800)),
    );
  });

  testWidgets('pull refresh normalizes invalid theme geometry and motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              pullRefreshIndicatorSize: double.nan,
              pullRefreshSettleMotion: Duration(microseconds: -1),
              pullRefreshCompleteMotion: Duration(microseconds: -1),
              pullRefreshOrbitMotion: Duration(microseconds: -1),
            ),
          ),
          child: Scaffold(
            body: MiuixPullToRefresh(
              isRefreshing: true,
              onRefresh: () {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[SizedBox(height: 800)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(MiuixPullToRefreshDefaults.circleSize),
    );
    final orbit = tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .map((builder) => builder.animation)
        .whereType<AnimationController>()
        .first;
    expect(orbit.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pull refresh exposes configurable trigger and full-range progress',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshState = MiuixPullToRefreshState();
      final listKey = GlobalKey();
      final progressValues = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: MiuixPullToRefresh(
                state: refreshState,
                refreshThreshold: .5,
                onPullProgress: progressValues.add,
                onRefresh: () {},
                child: ListView(
                  key: listKey,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [SizedBox(height: 1000)],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(refreshState.refreshThreshold, .5);
      expect(refreshState.refreshThresholdOffset, closeTo(35, .01));
      expect(refreshState.triggerProgressOffset, closeTo(140, .01));
      expect(progressValues, [0]);

      final context = listKey.currentContext!;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 160,
        pixels: 0,
        viewportDimension: 840,
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
      await tester.pump();

      expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
      expect(refreshState.fullDragProgress, closeTo(progressValues.last, .001));
      expect(progressValues.last, greaterThan(.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pull refresh accepts source-style sync callback and short text list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshState = MiuixPullToRefreshState();
      final listKey = GlobalKey();
      late StateSetter updateHost;
      var refreshing = false;
      var callbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Scaffold(
                  body: MiuixPullToRefresh(
                    state: refreshState,
                    isRefreshing: refreshing,
                    // PullToRefresh.kt accepts () -> Unit and reads missing
                    // labels with getOrElse, including a completely empty list.
                    refreshTexts: const [],
                    onRefresh: () {
                      callbackCount++;
                      setState(() => refreshing = true);
                    },
                    child: ListView(
                      key: listKey,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 1000)],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final context = listKey.currentContext!;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 160,
        pixels: 0,
        viewportDimension: 840,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: -90,
        velocity: 0,
      ).dispatch(context);
      ScrollEndNotification(
        metrics: metrics,
        context: context,
      ).dispatch(context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(callbackCount, 1);
      expect(refreshState.refreshState, MiuixRefreshState.refreshing);
      expect(tester.takeException(), isNull);

      updateHost(() => refreshing = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(refreshState.refreshState, MiuixRefreshState.idle);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pull refresh coalesces a hoisted start during release spring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final refreshState = MiuixPullToRefreshState();
    final listKey = GlobalKey();
    bool? isRefreshing;
    var callbackCount = 0;
    late StateSetter rebuildHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Scaffold(
                body: MiuixPullToRefresh(
                  state: refreshState,
                  isRefreshing: isRefreshing,
                  onRefresh: () => callbackCount++,
                  child: ListView(
                    key: listKey,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const <Widget>[SizedBox(height: 1000)],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -220,
      velocity: 0,
    ).dispatch(context);
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);

    rebuildHost(() => isRefreshing = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(callbackCount, 1);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh ignores null scroll deltas safely', (tester) async {
    final dispatchKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              onRefresh: () async {},
              child: Builder(
                key: dispatchKey,
                builder: (_) =>
                    const SizedBox(height: 80, child: Text('Dispatch target')),
              ),
            ),
          ),
        ),
      ),
    );

    final dispatchContext = dispatchKey.currentContext!;
    ScrollUpdateNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 120,
        pixels: 0,
        viewportDimension: 80,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: dispatchContext,
      dragDetails: DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, 12),
      ),
    ).dispatch(dispatchContext);
    await tester.pump();

    expect(find.text('Dispatch target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh uses the source Android pointer slop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    final listKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              state: refreshState,
              onRefresh: () => refreshCompleter.future,
              child: ListView(
                key: listKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 1000)],
              ),
            ),
          ),
        ),
      ),
    );

    // Android Compose removes its native 8dp touch slop from the first event.
    // Flutter's larger 18dp fallback would produce the wrong drag geometry.
    final gesture = await tester.startGesture(const Offset(195, 300));
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    const normalized = (90 - 8) / 840;
    const expected =
        840 *
        (normalized -
            normalized * normalized +
            normalized * normalized * normalized / 3);
    expect(refreshState.dragOffset, closeTo(expected, .01));
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);

    // Subsequent events use the gesture's cumulative displacement and must
    // not be added again by the scroll-notification fallback.
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();
    const secondNormalized = (140 - 8) / 840;
    const secondExpected =
        840 *
        (secondNormalized -
            secondNormalized * secondNormalized +
            secondNormalized * secondNormalized * secondNormalized / 3);
    expect(refreshState.dragOffset, closeTo(secondExpected, .01));
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('miuix-pull-refresh-header')),
    );
    final listRect = tester.getRect(find.byKey(listKey));
    expect(listRect.top, closeTo(headerRect.bottom, .01));

    await gesture.up();
    await tester.pump();
    // Leave the asynchronous refresh callback pending only until teardown.
    refreshCompleter.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh follows the source threshold and five states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listKey = GlobalKey();
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    var callbackStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              state: refreshState,
              refreshTexts: const ['下拉刷新', '松开刷新', '正在刷新…', '刷新成功'],
              onRefresh: () {
                callbackStarted = true;
                return refreshCompleter.future;
              },
              child: ListView(
                key: listKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 1000)],
              ),
            ),
          ),
        ),
      ),
    );

    // The fixed visual offset stays 840 * 1/6 * 1/4 = 35dp. The current
    // configurable default triggers at 25% of the 280dp damped drag range.
    expect(refreshState.refreshThresholdOffset, closeTo(35, .01));
    expect(refreshState.triggerProgressOffset, closeTo(70, .01));
    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    // Twenty raw pixels are damped but remain just above half the threshold,
    // which is precisely where the source begins showing its first label.
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -20,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.pulling);
    expect(find.text('下拉刷新'), findsOneWidget);
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('miuix-pull-refresh-header')),
    );
    final listRect = tester.getRect(find.byKey(listKey));
    // The source header participates in Column measurement and pushes content;
    // it is not a floating spinner painted over the first list item.
    expect(listRect.top, closeTo(headerRect.bottom, .01));

    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -60,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
    expect(find.text('松开刷新'), findsOneWidget);

    // A substantial over-pull makes the release spring observable. During
    // that spring the source deliberately keeps the capsule/release phase.
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -180,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(
      refreshState.dragOffset,
      greaterThan(refreshState.refreshThresholdOffset * 3),
    );

    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(callbackStarted, isFalse);
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
    expect(find.text('松开刷新'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(callbackStarted, isTrue);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(find.text('正在刷新…'), findsOneWidget);

    refreshCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshState.refreshState, MiuixRefreshState.refreshComplete);
    expect(find.text('刷新成功'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 420));
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, closeTo(0, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh preserves direct drag but skips autonomous motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listKey = GlobalKey();
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    var reduceMotion = false;
    var callbackCount = 0;
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
                child: Scaffold(
                  body: MiuixPullToRefresh(
                    state: refreshState,
                    refreshTexts: const [
                      'Pull',
                      'Release',
                      'Refreshing',
                      'Complete',
                    ],
                    onRefresh: () {
                      callbackCount++;
                      return refreshCompleter.future;
                    },
                    child: ListView(
                      key: listKey,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 1000)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -220,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    final overPullOffset = refreshState.dragOffset;
    expect(
      overPullOffset,
      greaterThan(refreshState.refreshThresholdOffset * 3),
    );

    // First prove that an ordinary release really is inside the source spring.
    // Enabling the setting during that spring must finish the same coroutine,
    // not cancel its pending refresh callback or strand ThresholdReached.
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(callbackCount, 0);
    expect(refreshState.dragOffset, lessThan(overPullOffset));
    expect(
      refreshState.dragOffset,
      greaterThan(refreshState.refreshThresholdOffset),
    );

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(callbackCount, 1);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(
      refreshState.dragOffset,
      closeTo(refreshState.refreshThresholdOffset, .01),
    );

    dynamic refreshPainter() => tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
        )
        .painter;
    final frozenRotation = refreshPainter().rotation as double;
    await tester.pump(const Duration(seconds: 3));
    expect(refreshPainter().rotation, frozenRotation);

    // Completion remains visible for one frame, then both the collapse and
    // return spring resolve without animated intermediate geometry.
    refreshCompleter.complete();
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.refreshComplete);
    // The completion can arrive after this frame's build phase. The next frame
    // paints it, and the reduced-motion branch keeps it through that boundary.
    await tester.pump();
    expect(find.text('Complete'), findsOneWidget);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, 0);

    // Reduced motion does not disable direct manipulation. A fresh subthreshold
    // pointer drag still tracks the finger, while its release snaps closed.
    final gesture = await tester.startGesture(const Offset(195, 300));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.pulling);
    expect(refreshState.dragOffset, greaterThan(0));
    await gesture.up();
    await tester.pump();
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, 0);
    expect(callbackCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh can unmount while refresh is pending', (
    tester,
  ) async {
    final refreshCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              height: 120,
              child: MiuixPullToRefresh(
                onRefresh: () => refreshCompleter.future,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 300, child: Text('Pending refresh')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshCompleter.isCompleted, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    refreshCompleter.complete();
    await tester.pump(const Duration(milliseconds: 420));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'custom navigation rail, tabs, and dropdown preference stay safe',
    (tester) async {
      var selectedTab = -1;
      var selectedDropdown = 'one';
      var selectedRail = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      MiuixTabBar(
                        tabs: const ['First', 'Second', 'Third'],
                        onTap: (index) => setState(() => selectedTab = index),
                      ),
                      SizedBox(
                        height: 180,
                        child: MiuixNavigationRail(
                          selectedIndex: 99,
                          extended: true,
                          onDestinationSelected: (index) =>
                              setState(() => selectedRail = index),
                          items: const [
                            MiuixNavigationItem(
                              icon: Icon(Icons.home),
                              label: 'Home',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.settings),
                              label: 'Settings',
                            ),
                          ],
                        ),
                      ),
                      MiuixDropdownPreference<String>(
                        title: 'Choice',
                        value: selectedDropdown,
                        entries: const [
                          MiuixDropdownEntry(value: 'one', label: 'One'),
                          MiuixDropdownEntry(value: 'two', label: 'Two'),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedDropdown = value),
                      ),
                      const MiuixFloatingActionButton(
                        icon: Icon(Icons.add),
                        onPressed: null,
                      ),
                      const MiuixAvatar(initials: 'MI'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(selectedTab, 1);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(selectedRail, 0);

      await tester.tap(find.text('Choice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();
      expect(selectedDropdown, 'two');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation rail defaults to local HyperOS glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '主页',
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
    await tester.pumpAndSettle();

    final rail = find.byType(MiuixNavigationRail);
    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('navigation-rail-glass')),
    );
    final selectedSurface = tester
        .widgetList<AnimatedContainer>(
          find.byKey(const ValueKey('navigation-rail-item-surface')),
        )
        .first;
    final selectedDecoration = selectedSurface.decoration! as ShapeDecoration;
    final selectedShape = selectedDecoration.shape as MiuixSquircleBorder;
    final scheme = Theme.of(tester.element(rail)).colorScheme;

    expect(tester.getSize(rail), const Size(104, 300));
    expect(
      tester.getRect(find.byKey(const ValueKey('navigation-rail-glass'))),
      const Rect.fromLTWH(12, 12, 80, 276),
    );
    expect(glass.blur, 24);
    expect(glass.opacity, .56);
    expect(glass.radius, 32);
    expect(glass.padding, EdgeInsets.zero);
    expect(find.byKey(const ValueKey('navigation-rail-divider')), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(selectedDecoration.color, scheme.primary.withValues(alpha: .08));
    expect(selectedShape.borderRadius, BorderRadius.circular(22));
    expect(selectedSurface.constraints?.minHeight, 54);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail.sourceItems(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-rail-glass')), findsNothing);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      find.byKey(const ValueKey('navigation-rail-divider')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail selected wash preserves foreground contrast', (
    tester,
  ) async {
    double contrast(Color foreground, Color background) {
      final lighter = math.max(
        foreground.computeLuminance(),
        background.computeLuminance(),
      );
      final darker = math.min(
        foreground.computeLuminance(),
        background.computeLuminance(),
      );
      return (lighter + .05) / (darker + .05);
    }

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 220,
                  child: MiuixNavigationRail(
                    defaultWindowInsetsPadding: false,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    items: const [
                      MiuixNavigationItem(
                        icon: Icon(Icons.home_outlined),
                        label: '主页',
                      ),
                      MiuixNavigationItem(
                        icon: Icon(Icons.settings_outlined),
                        label: '设置',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = find.byType(MiuixNavigationRail);
      final scheme = Theme.of(tester.element(rail)).colorScheme;
      final selectedSurface = tester
          .widgetList<AnimatedContainer>(
            find.byKey(const ValueKey('navigation-rail-item-surface')),
          )
          .first;
      final decoration = selectedSurface.decoration! as ShapeDecoration;
      final wash = decoration.color!;
      final paintedBackground = Color.alphaBlend(wash, scheme.surface);
      final label = tester.widget<Text>(find.text('主页'));
      expect(Theme.of(tester.element(find.text('主页'))).brightness, brightness);
      final expectedForeground = brightness == Brightness.dark
          ? scheme.onPrimaryContainer
          : scheme.primary;
      expect(label.style?.color, expectedForeground);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.home_outlined))).color,
        expectedForeground,
      );
      expect(
        contrast(expectedForeground, paintedBackground),
        greaterThanOrEqualTo(3),
        reason: '$brightness selected rail content must remain distinguishable',
      );
    }
  });

  testWidgets('navigation rail snaps selection and expansion when reduced', (
    tester,
  ) async {
    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);
    MiuixNavigationRailState? activeState = state;
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 360,
                  child: MiuixNavigationRail(
                    state: activeState,
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
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 104);
    state.expand();
    await tester.pump();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 264);

    updateHost(() {
      activeState = null;
      selected = 1;
    });
    await tester.pump();
    final surfaces = tester.widgetList<AnimatedContainer>(
      find.byKey(const ValueKey('navigation-rail-item-surface')),
    );
    expect(surfaces, isNotEmpty);
    expect(
      surfaces.every((surface) => surface.duration == Duration.zero),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail uses MIUIX source item metrics', (tester) async {
    Future<void> pumpRail({required bool extended}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                height: 180,
                child: MiuixNavigationRail.sourceItems(
                  selectedIndex: 0,
                  extended: extended,
                  onDestinationSelected: (_) {},
                  items: const [
                    MiuixNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpRail(extended: true);

    final scheme = Theme.of(
      tester.element(find.byType(MiuixNavigationRail)),
    ).colorScheme;
    final semantic = MiuixSemanticColors.of(
      tester.element(find.byType(MiuixNavigationRail)),
    );
    final selectedContainer = tester
        .widgetList<AnimatedContainer>(
          find.ancestor(
            of: find.text('Home'),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .firstWhere((container) => container.decoration is BoxDecoration);
    final selectedDecoration = selectedContainer.decoration! as BoxDecoration;
    final selectedText = tester.widget<Text>(find.text('Home'));
    final selectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.home_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 28);

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 240.75);
    expect(selectedContainer.constraints?.minWidth, 216);
    expect(selectedContainer.constraints?.minHeight, 56);
    expect(
      selectedContainer.padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
    expect(selectedDecoration.color, scheme.surfaceContainerHigh);
    expect(selectedText.style?.fontSize, 16);
    expect(selectedText.style?.fontWeight, FontWeight.w500);
    expect(selectedText.style?.color, semantic['onSurfaceContainer']);
    expect(selectedIconTheme.data.size, 28);
    expect(selectedIconTheme.data.color, semantic['onSurfaceContainer']);

    await pumpRail(extended: false);

    final collapsedContainer = tester
        .widgetList<AnimatedContainer>(
          find.ancestor(
            of: find.text('Home'),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .firstWhere((container) => container.decoration is BoxDecoration);
    final collapsedDecoration = collapsedContainer.decoration! as BoxDecoration;
    final collapsedText = tester.widget<Text>(find.text('Home'));

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('navigation-rail-divider')))
          .width,
      .75,
    );
    expect(collapsedContainer.constraints?.minHeight, 0);
    expect(collapsedContainer.padding, EdgeInsets.zero);
    expect(collapsedDecoration.color, Colors.transparent);
    expect(collapsedText.style?.fontSize, 12);
    expect(collapsedText.style?.fontWeight, FontWeight.w700);
    expect(collapsedText.style?.color, semantic['onSurfaceContainer']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail exposes all four current source modes', (
    tester,
  ) async {
    var mode = MiuixNavigationRailDisplayMode.iconAndText;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: SizedBox(
                  height: 240,
                  child: MiuixNavigationRail(
                    displayMode: mode,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
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
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    updateHost(() => mode = MiuixNavigationRailDisplayMode.iconOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    updateHost(() => mode = MiuixNavigationRailDisplayMode.textOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    updateHost(
      () => mode = MiuixNavigationRailDisplayMode.iconWithSelectedLabel,
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source navigation rail exposes defaults and arbitrary items', (
    tester,
  ) async {
    var selected = 0;
    var mode = MiuixNavigationRailDisplayMode.iconOnly;
    late StateSetter updateHost;

    expect(MiuixNavigationRailDefaults.minWidth, 80);
    expect(MiuixNavigationRailDefaults.verticalPadding, 24);
    expect(MiuixNavigationRailDefaults.headerSpacing, 24);
    expect(MiuixNavigationRailDefaults.iconSize, 28);
    expect(MiuixNavigationRailDefaults.iconTextSpacing, 4);
    expect(MiuixNavigationRailDefaults.itemVerticalPadding, 12);
    expect(MiuixNavigationRailDefaults.labelFontSize, 12);
    expect(MiuixNavigationRailDefaults.textOnlyFontSize, 14);
    expect(MiuixNavigationRailDefaults.textOnlyVerticalPadding, 4);
    expect(MiuixNavigationRailDefaults.selectedPressedAlpha, .5);
    expect(MiuixNavigationRailDefaults.unselectedPressedAlpha, .6);
    expect(MiuixNavigationRailDefaults.unselectedAlpha, .4);
    final spring = debugMiuixNavigationRailSizeSpring();
    expect(spring.stiffness, 400);
    expect(spring.damping, closeTo(40, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 260,
                  child: MiuixNavigationRail.source(
                    defaultWindowInsetsPadding: false,
                    mode: mode,
                    header: const SizedBox(
                      key: ValueKey('source-rail-header'),
                      width: 16,
                      height: 16,
                    ),
                    children: [
                      MiuixNavigationRailItem(
                        key: const ValueKey('source-rail-home'),
                        selected: selected == 0,
                        onClick: () => updateHost(() => selected = 0),
                        icon: const Icon(Icons.home_outlined),
                        label: '主页',
                        badge: const MiuixBadge.source(
                          key: ValueKey('source-rail-badge'),
                          content: Text('8'),
                        ),
                      ),
                      MiuixNavigationRailItem(
                        key: const ValueKey('source-rail-settings'),
                        selected: selected == 1,
                        onClick: () => updateHost(() => selected = 1),
                        icon: const Icon(Icons.settings_outlined),
                        label: '设置',
                      ),
                      const SizedBox(
                        key: ValueKey('source-rail-arbitrary-child'),
                        height: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(find.byKey(const ValueKey('source-rail-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('source-rail-arbitrary-child')),
      findsOneWidget,
    );
    expect(find.text('主页'), findsNothing);
    expect(find.byKey(const ValueKey('source-rail-badge')), findsOneWidget);
    final iconOnlyHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;

    updateHost(
      () => mode = MiuixNavigationRailDisplayMode.iconWithSelectedLabel,
    );
    await tester.pump();
    await tester.pump();
    final springStartHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;
    await tester.pump(const Duration(milliseconds: 16));
    final springFrameHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;
    await tester.pumpAndSettle();
    final settledHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;

    expect(springStartHeight, closeTo(iconOnlyHeight, .01));
    expect(springFrameHeight, greaterThan(springStartHeight));
    expect(springFrameHeight, lessThan(settledHeight));
    expect(find.text('主页'), findsOneWidget);
    expect(find.text('设置'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('source-rail-settings')));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('主页'), findsNothing);
    expect(find.text('设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current classic rail uses medium tint and MIUIX indication', (
    tester,
  ) async {
    final enter = debugMiuixNavigationRailIndicationSpring(entering: true);
    final exit = debugMiuixNavigationRailIndicationSpring(entering: false);
    const enterFrequency = 2 * math.pi / .2;
    const exitFrequency = 2 * math.pi / .35;
    expect(enter.stiffness, closeTo(enterFrequency * enterFrequency, .001));
    expect(enter.damping, closeTo(2 * enterFrequency, .001));
    expect(exit.stiffness, closeTo(exitFrequency * exitFrequency, .001));
    expect(exit.damping, closeTo(2 * .95 * exitFrequency, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 260,
              child: MiuixNavigationRail.source(
                defaultWindowInsetsPadding: false,
                children: [
                  MiuixNavigationRailItem(
                    key: const ValueKey('classic-current-selected'),
                    selected: true,
                    onClick: () {},
                    icon: const Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  MiuixNavigationRailItem(
                    key: const ValueKey('classic-current-unselected'),
                    selected: false,
                    onClick: () {},
                    icon: const Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Current NavigationRail.kt does not dim or bold classic destinations;
    // both labels use the same medium onSurfaceContainer style.
    final home = tester.widget<Text>(find.text('Home'));
    final settings = tester.widget<Text>(find.text('Settings'));
    expect(home.style?.fontWeight, FontWeight.w500);
    expect(settings.style?.fontWeight, FontWeight.w500);
    expect(home.style?.color, settings.style?.color);
    expect(home.style?.color?.a, 1);

    final unselected = find.byKey(const ValueKey('classic-current-unselected'));
    final indications = find.byKey(
      const ValueKey('navigation-rail-source-indication'),
    );
    expect(indications, findsNWidgets(2));
    double indicationAlpha() => tester
        .widgetList<ColoredBox>(indications)
        .map((box) => box.color.a)
        .reduce(math.max);
    expect(indicationAlpha(), 0);
    final gesture = await tester.startGesture(tester.getCenter(unselected));
    // The first frame resolves the tap recognizer and starts the spring; the
    // next frame measures the source indication while that spring is moving.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(indicationAlpha(), greaterThan(0));
    expect(indicationAlpha(), lessThan(.1));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(.1, .001));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(indicationAlpha(), greaterThan(0));
    expect(indicationAlpha(), lessThan(.1));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(0, .001));

    final quickGesture = await tester.startGesture(
      tester.getCenter(unselected),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final quickReleaseAlpha = indicationAlpha();
    expect(quickReleaseAlpha, inExclusiveRange(0, .1));
    await quickGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // MiuixIndication joins the positive press job before starting PressExit;
    // a short tap therefore still reaches toward the authored 10% overlay.
    expect(indicationAlpha(), greaterThan(quickReleaseAlpha));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expandable navigation rail follows current stateful morph', (
    tester,
  ) async {
    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);

    expect(MiuixNavigationRailDefaults.expandedWidth, 240);
    expect(MiuixNavigationRailDefaults.expandedLabelFontSize, 16);
    expect(MiuixNavigationRailDefaults.expandedItemHorizontalMargin, 12);
    expect(MiuixNavigationRailDefaults.expandedItemCornerRadius, 16);
    expect(MiuixNavigationRailDefaults.collapsedIndicatorVerticalPadding, 4);
    expect(
      MiuixNavigationRailDefaults.expandedItemContentHorizontalPadding,
      14,
    );
    expect(MiuixNavigationRailDefaults.expandedItemContentVerticalPadding, 14);
    expect(MiuixNavigationRailDefaults.expandedItemIconTextSpacing, 16);
    final expandSpring = debugMiuixNavigationRailExpandSpring();
    const expectedFrequency = 2 * math.pi / .35;
    expect(
      expandSpring.stiffness,
      closeTo(expectedFrequency * expectedFrequency, .001),
    );
    expect(expandSpring.damping, closeTo(2 * expectedFrequency, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 560,
              child: MiuixNavigationRail.sourceItems(
                state: state,
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: '主页',
                    badge: MiuixBadge.source(
                      key: ValueKey('expandable-rail-badge'),
                      content: Text('8'),
                    ),
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings_outlined),
                    label: '设置',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(state.currentValue, MiuixNavigationRailValue.collapsed);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('navigation-rail-expandable-item-visual')),
      findsNWidgets(2),
    );
    final collapsedHome = tester.widget<Text>(find.text('主页'));
    expect(collapsedHome.style?.fontSize, 12);
    expect(collapsedHome.style?.fontWeight, FontWeight.w500);
    final collapsedIndicator = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-expandable-indicator')).first,
    );
    expect(collapsedIndicator.left, 12);
    expect(collapsedIndicator.width, 56);
    expect(collapsedIndicator.height, 36);
    final collapsedIcon = tester.getRect(find.byIcon(Icons.home_outlined));
    final collapsedBadge = tester.getRect(
      find.byKey(const ValueKey('expandable-rail-badge')),
    );
    // NavigationItemIcon retains the 28dp anchor and lets a content badge
    // overlap it by the source 12dp/14dp offsets. Wrapping the pair in the
    // icon's FittedBox would incorrectly shrink this 16dp badge.
    expect(collapsedIcon.size, const Size.square(28));
    // Flutter's Ahem test font makes one 11sp digit wider than Android Roboto;
    // it may exceed the 16dp minimum, but must remain below the 28dp icon slot.
    expect(collapsedBadge.width, greaterThanOrEqualTo(16));
    expect(collapsedBadge.width, lessThan(28));
    expect(collapsedBadge.height, 16);
    expect(collapsedBadge.left, closeTo(collapsedIcon.left + 16, .001));
    expect(collapsedBadge.top, closeTo(collapsedIcon.top - 2, .001));

    state.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final movingWidth = tester.getSize(find.byType(MiuixNavigationRail)).width;
    expect(movingWidth, greaterThan(80.75));
    expect(movingWidth, lessThan(240.75));
    await tester.pumpAndSettle();

    expect(state.currentValue, MiuixNavigationRailValue.expanded);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 240.75);
    final expandedHome = tester.widget<Text>(find.text('主页'));
    expect(expandedHome.style?.fontSize, 16);
    expect(expandedHome.style?.fontWeight, FontWeight.w500);
    final expandedIndicator = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-expandable-indicator')).first,
    );
    expect(expandedIndicator.left, 12);
    expect(expandedIndicator.width, 216);
    expect(expandedIndicator.height, 56);
    final expandedIcon = tester.getRect(find.byIcon(Icons.home_outlined));
    final expandedBadge = tester.getRect(
      find.byKey(const ValueKey('expandable-rail-badge')),
    );
    expect(expandedIcon.size, const Size.square(28));
    expect(expandedBadge.width, greaterThanOrEqualTo(16));
    expect(expandedBadge.width, lessThan(28));
    expect(expandedBadge.height, 16);
    expect(expandedBadge.left, closeTo(expandedIcon.left + 16, .001));
    expect(expandedBadge.top, closeTo(expandedIcon.top - 2, .001));
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find
                        .byKey(
                          const ValueKey(
                            'navigation-rail-expandable-indicator',
                          ),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration)
          .shape,
      isA<MiuixSquircleBorder>(),
    );

    await tester.tap(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
    );
    await tester.pumpAndSettle();
    expect(state.currentValue, MiuixNavigationRailValue.collapsed);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);

    state.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final widthBeforeReverse = tester
        .getSize(find.byType(MiuixNavigationRail))
        .width;
    state.collapse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    // animateFloatAsState retargets with its current outward velocity, so a
    // rapid reversal continues outward briefly instead of forming a cusp.
    expect(
      tester.getSize(find.byType(MiuixNavigationRail)).width,
      greaterThan(widthBeforeReverse),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'navigation rail applies source header divider and start insets',
    (tester) async {
      tester.view.physicalSize = const Size(300, 400);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 20, left: 10);
      tester.view.viewPadding = const FakeViewPadding(top: 20, left: 10);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      Widget rail({
        bool showDivider = true,
        bool defaultWindowInsetsPadding = true,
      }) => MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail.sourceItems(
                color: Colors.red,
                showDivider: showDivider,
                defaultWindowInsetsPadding: defaultWindowInsetsPadding,
                header: const SizedBox(
                  key: ValueKey('rail-header'),
                  width: 20,
                  height: 20,
                ),
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(rail());
      await tester.pumpAndSettle();

      final railRect = tester.getRect(find.byType(MiuixNavigationRail));
      final columnRect = tester.getRect(
        find.byKey(const ValueKey('navigation-rail-column')),
      );
      final dividerRect = tester.getRect(
        find.byKey(const ValueKey('navigation-rail-divider')),
      );
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('rail-header')),
      );
      final surface = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(MiuixNavigationRail),
              matching: find.byType(ColoredBox),
            ),
          )
          .first;

      expect(railRect, const Rect.fromLTWH(0, 0, 90.75, 300));
      // Current NavigationRail applies status/navigation insets to the
      // scrollable column only. Its background and divider remain full height,
      // while the first header still starts after 20dp + 24dp content padding.
      expect(columnRect, const Rect.fromLTWH(10, 0, 80, 300));
      expect(dividerRect, const Rect.fromLTWH(90, 0, .75, 300));
      expect(headerRect, const Rect.fromLTWH(40, 44, 20, 20));
      expect(surface.color, Colors.red);

      await tester.pumpWidget(
        rail(showDivider: false, defaultWindowInsetsPadding: false),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiuixNavigationRail)),
        const Rect.fromLTWH(0, 0, 80, 300),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('navigation-rail-column'))),
        const Rect.fromLTWH(0, 0, 80, 300),
      );
      expect(tester.getRect(find.byKey(const ValueKey('rail-header'))).top, 24);
      expect(
        find.byKey(const ValueKey('navigation-rail-divider')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation rail follows source pressed and disabled behavior', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 320,
              child: MiuixNavigationRail.sourceItems(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (index) => selected = index,
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Disabled',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color iconColor(int index) {
      final item = find.byKey(ValueKey('navigation-rail-item-$index'));
      return tester
          .widgetList<IconTheme>(
            find.descendant(of: item, matching: find.byType(IconTheme)),
          )
          .firstWhere((theme) => theme.data.size == 28)
          .data
          .color!;
    }

    expect(iconColor(0).a, 1);
    expect(iconColor(1).a, closeTo(.4, .001));
    expect(iconColor(2).a, closeTo(.4, .001));

    final selectedGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('navigation-rail-item-0'))),
    );
    await tester.pump();
    expect(iconColor(0).a, closeTo(.5, .001));
    await selectedGesture.up();
    await tester.pump();
    expect(iconColor(0).a, 1);
    expect(selected, 0);

    final unselectedGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('navigation-rail-item-1'))),
    );
    await tester.pump();
    expect(iconColor(1).a, closeTo(.6, .001));
    await unselectedGesture.up();
    await tester.pump();
    expect(iconColor(1).a, closeTo(.4, .001));
    expect(selected, 1);

    selected = -1;
    await tester.tap(find.byKey(const ValueKey('navigation-rail-item-2')));
    await tester.pump();
    expect(selected, -1);
    expect(iconColor(2).a, closeTo(.4, .001));
    expect(tester.takeException(), isNull);
  });

  test('tab rows allocate widths with the MIUIX source formula', () {
    expect(
      debugMiuixTabWidth(
        tabCount: 3,
        minWidth: 76,
        maxWidth: 98,
        spacing: 9,
        availableWidth: 366,
      ),
      116,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 3,
        minWidth: 76,
        maxWidth: 98,
        spacing: 9,
        availableWidth: 300,
      ),
      94,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 6,
        minWidth: 62,
        maxWidth: 84,
        spacing: 5,
        availableWidth: 290,
      ),
      62,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 6,
        minWidth: 62,
        maxWidth: 84,
        spacing: 5,
        availableWidth: 520,
      ),
      82.5,
    );
  });

  testWidgets('tab row normalizes dynamic geometry before layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              child: MiuixTabBar.contour(
                tabs: <String>['One', 'Two'],
                minWidth: double.nan,
                maxWidth: -10,
                height: -4,
                cornerRadius: double.infinity,
                itemSpacing: double.nan,
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-hyperos4-tab-surface')))
          .height,
      MiuixTabRowDefaults.hyperOs4Padding * 2,
    );
    expect(
      indicator.borderRadius,
      BorderRadius.circular(MiuixTabRowDefaults.hyperOs4CornerRadius),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation remains a read-only controlled preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixFloatingNavigationBar(
            items: <MiuixNavigationItem>[
              MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
              MiuixNavigationItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedIndex: 0,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
