part of '../miuix_flutter_test.dart';

// 按职责拆分原导航注册，测试名称、顺序与共享私有夹具保持不变。
void _registerNavigationSurfaceTests() {
  testWidgets(
    'selected-label navigation animates only source position and alpha',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      Text homeLabel() => tester.widget<Text>(find.text('Home'));
      Text settingsLabel() => tester.widget<Text>(find.text('Settings'));
      Opacity labelOpacity(String label) => tester.widget<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      );
      final navigationBar = find.byType(MiuixNavigationBar);
      double labelTop(String label) =>
          tester.getTopLeft(find.text(label)).dy -
          tester.getTopLeft(navigationBar).dy;

      // Source tint and weight change with selected state immediately; only the
      // selected-label offset and alpha use the 300ms FastOutSlowIn tween. The
      // paragraph follows the animated icon bottom instead of staying pinned
      // to the row bottom.
      expect(homeLabel().style?.fontWeight, FontWeight.w400);
      expect(settingsLabel().style?.fontWeight, FontWeight.w700);
      expect(labelOpacity('Home').opacity, 1);
      expect(labelOpacity('Settings').opacity, 0);
      expect(labelTop('Home'), closeTo(35, .001));
      expect(labelTop('Settings'), closeTo(46, .001));

      await tester.pump(const Duration(milliseconds: 150));
      final midpoint = Curves.fastOutSlowIn.transform(.5);
      expect(labelOpacity('Home').opacity, closeTo(1 - midpoint, .02));
      expect(labelOpacity('Settings').opacity, closeTo(midpoint, .02));
      expect(labelTop('Home'), closeTo(46 - 11 * (1 - midpoint), .02));
      expect(labelTop('Settings'), closeTo(46 - 11 * midpoint, .02));
      await tester.pump(const Duration(milliseconds: 150));
      expect(labelOpacity('Home').opacity, 0);
      expect(labelOpacity('Settings').opacity, 1);
      expect(labelTop('Home'), closeTo(46, .001));
      expect(labelTop('Settings'), closeTo(35, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected-label navigation restarts the full source tween when reversed',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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

      Opacity labelOpacity(String label) => tester.widget<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final firstLeg = Curves.fastOutSlowIn.transform(1 / 3);
      expect(labelOpacity('Home').opacity, closeTo(1 - firstLeg, .02));
      expect(labelOpacity('Settings').opacity, closeTo(firstLeg, .02));

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final reverseMidpoint = Curves.fastOutSlowIn.transform(.5);
      final expectedHome = (1 - firstLeg) + firstLeg * reverseMidpoint;
      final expectedSettings = firstLeg * (1 - reverseMidpoint);

      // Compose's tween restarts its complete 300ms clock from the sampled
      // value whenever animateDpAsState receives another target. Flutter's
      // default AnimationController.animateTo duration is proportional to the
      // remaining distance, which would already finish this reversal at 150ms.
      expect(labelOpacity('Home').opacity, closeTo(expectedHome, .02));
      expect(labelOpacity('Settings').opacity, closeTo(expectedSettings, .02));
      expect(labelOpacity('Home').opacity, lessThan(.99));
      expect(labelOpacity('Settings').opacity, greaterThan(.01));

      await tester.pump(const Duration(milliseconds: 150));
      expect(labelOpacity('Home').opacity, 1);
      expect(labelOpacity('Settings').opacity, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected-label navigation snaps with reduced motion', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    Opacity labelOpacity(String label) => tester.widget<Opacity>(
      find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
    );
    expect(labelOpacity('Home').opacity, 0);
    expect(labelOpacity('Settings').opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation exposes all four display modes', (
    tester,
  ) async {
    var mode = MiuixFloatingNavigationBarDisplayMode.iconAndText;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  displayMode: mode,
                  selectedIndex: 0,
                  onSelected: (_) {},
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
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    final iconAndTextTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.home_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    expect(iconAndTextTheme.data.size, 24);
    expect(
      tester.getSize(
        find
            .byKey(const ValueKey('floating-navigation-vertical-content'))
            .first,
      ),
      predicate<Size>((s) => s.width == 96 && s.height >= 43),
    );
    expect(
      tester
          .getSize(
            find
                .byKey(const ValueKey('floating-navigation-content-spacing'))
                .first,
          )
          .height,
      5,
    );
    final combinedIconRect = tester.getRect(find.byIcon(Icons.home_outlined));
    final combinedLabelRect = tester.getRect(find.text('Home').last);
    expect(
      combinedLabelRect.top,
      greaterThanOrEqualTo(combinedIconRect.bottom),
    );
    expect(combinedLabelRect.center.dx, closeTo(combinedIconRect.center.dx, 1));
    Size itemSize() => tester.getSize(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    Size indicatorSize() => tester.getSize(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    // 宽度保持固定，实际标签可按字号与换行增加高度。
    expect(itemSize().width, 104);
    expect(itemSize().height, greaterThanOrEqualTo(52));
    expect(indicatorSize().width, 100);
    expect(indicatorSize().height, greaterThanOrEqualTo(52));
    expect(
      find.descendant(
        of: find.byType(MiuixFloatingNavigationBar),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );

    updateHost(() => mode = MiuixFloatingNavigationBarDisplayMode.textOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    // 宽度保持固定，实际标签可按字号与换行增加高度。
    expect(itemSize().width, 104);
    expect(itemSize().height, greaterThanOrEqualTo(52));
    expect(indicatorSize().width, 100);
    expect(indicatorSize().height, greaterThanOrEqualTo(52));

    updateHost(() => mode = MiuixFloatingNavigationBarDisplayMode.iconOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    // 宽度保持固定，实际标签可按字号与换行增加高度。
    expect(itemSize().width, 104);
    expect(itemSize().height, greaterThanOrEqualTo(52));
    expect(indicatorSize().width, 100);
    expect(indicatorSize().height, greaterThanOrEqualTo(52));

    updateHost(
      () => mode = MiuixFloatingNavigationBarDisplayMode.iconWithSelectedLabel,
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    // 宽度保持固定，实际标签可按字号与换行增加高度。
    expect(itemSize().width, 104);
    expect(itemSize().height, greaterThanOrEqualTo(52));
    expect(indicatorSize().width, 100);
    expect(indicatorSize().height, greaterThanOrEqualTo(52));
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-like navigation shows only the selected label', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              displayMode:
                  MiuixFloatingNavigationBarDisplayMode.iconWithSelectedLabel,
              onDestinationSelected: (_) {},
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
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.settings), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation bars honor the source item enabled switch', (
    tester,
  ) async {
    var selected = -1;
    const items = [
      MiuixNavigationItem(
        icon: Icon(Icons.block),
        label: 'Disabled',
        enabled: false,
      ),
      MiuixNavigationItem(icon: Icon(Icons.check), label: 'Enabled'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixNavigationBar(
              items: items,
              selectedIndex: 1,
              onDestinationSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    await tester.pump();
    expect(selected, -1);
    await tester.tap(find.text('Enabled'));
    await tester.pump();
    expect(selected, 1);

    selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              items: items,
              selectedIndex: 1,
              displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
              onSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-0')));
    await tester.pump();
    expect(selected, -1);
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-1')));
    await tester.pump();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation bar uses near-full HyperOS 4 selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                MiuixNavigationItem(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets),
                  label: 'Components',
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Settings',
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.image_outlined),
                  label: 'Color',
                ),
                MiuixNavigationItem(icon: Icon(Icons.sort), label: 'Dropdown'),
                MiuixNavigationItem(
                  icon: Icon(Icons.edit_outlined),
                  label: 'Icon',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final scheme = Theme.of(
      tester.element(find.byType(MiuixFloatingNavigationBar)),
    ).colorScheme;
    final selectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.widgets),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    final unselectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.tune_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    final unselectedRect = tester.getRect(find.byIcon(Icons.tune_outlined));
    final selectedRect = tester.getRect(find.byIcon(Icons.widgets));
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    final surface = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('floating-navigation-glass')),
    );

    expect(selectedIconTheme.data.size, 24);
    expect(selectedIconTheme.data.color, isNot(unselectedIconTheme.data.color));
    expect(
      HSLColor.fromColor(selectedIconTheme.data.color!).hue,
      closeTo(HSLColor.fromColor(scheme.primary).hue, 1),
    );
    expect(unselectedIconTheme.data.color, scheme.onSurfaceVariant);
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsOneWidget,
    );
    expect(surface.radius, 29);
    expect(surface.blur, 12);
    expect(surface.opacity, .38);
    expect(
      find.byKey(const ValueKey('floating-navigation-shadow')),
      findsOneWidget,
    );
    expect(MiuixFloatingNavigationBar.sourceShadowRadius, 10);
    expect(MiuixFloatingNavigationBar.sourceShadowOpacity, .2);
    expect(unselectedRect.left - selectedRect.right, closeTo(44, 1));
    // Five touching 68dp equal items and two 6dp capsule insets fit a 360dp
    // phone without allowing an English label to enlarge one destination.
    // The selected 64x52 material leaves only three dp above and below it,
    // while the semantic destination and 58dp glass surface remain separate.
    // 长标签不再压小字体，表面随内容自然增高，仍保持同一横向预算。
    expect(surfaceRect.width, 352);
    expect(surfaceRect.height, greaterThanOrEqualTo(58));
    final indicatorRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    final selectedContentRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-vertical-content')).first,
    );
    expect(indicatorRect.width, 64);
    expect(indicatorRect.height, greaterThanOrEqualTo(52));
    expect(indicatorRect.height, closeTo(surfaceRect.height - 6, .001));
    expect(indicatorRect.top - surfaceRect.top, closeTo(3, .001));
    expect(surfaceRect.bottom - indicatorRect.bottom, closeTo(3, .001));
    final indicatorBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(
          const ValueKey('floating-navigation-selection-indicator'),
        ),
        matching: find.byType(DecoratedBox),
      ),
    );
    final indicatorShape =
        (indicatorBox.decoration as ShapeDecoration).shape
            as MiuixSquircleBorder;
    expect(indicatorShape.side, BorderSide.none);
    // A 3dp inset from a 29dp outer radius keeps both capsule ends concentric.
    expect(
      indicatorShape.borderRadius.resolve(TextDirection.ltr).topLeft.x,
      26,
    );
    expect(indicatorRect.center.dy, closeTo(surfaceRect.center.dy, .001));
    // 全文自然换行后内容可增高，不恢复固定单行裁剪。
    expect(selectedContentRect.height, greaterThanOrEqualTo(43));
    expect(
      selectedContentRect.center.dy,
      closeTo(indicatorRect.center.dy, .001),
    );
    expect(selectedContentRect.top, greaterThan(indicatorRect.top));
    expect(selectedContentRect.bottom, lessThan(indicatorRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation selection surface moves continuously', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: selected,
                  onSelected: (value) => updateHost(() => selected = value),
                  items: const [
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
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final startCenter = tester.getCenter(indicator);
    final indicatorRect = tester.getRect(indicator);
    final firstItemRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    // 横向位置契约保持不变，垂直尺寸由最长真实标签决定。
    expect(firstItemRect.width, 88);
    expect(firstItemRect.height, greaterThanOrEqualTo(52));
    expect(indicatorRect.width, 84);
    expect(indicatorRect.height, greaterThanOrEqualTo(52));
    expect(
      indicatorRect.height,
      lessThanOrEqualTo(
        tester
            .getSize(find.byKey(const ValueKey('floating-navigation-surface')))
            .height,
      ),
    );
    final destinationCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-navigation-item-2')),
    );
    expect(startCenter.dx, lessThan(destinationCenter.dx));

    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final midpoint = tester.getCenter(indicator).dx;
    expect(midpoint, greaterThan(startCenter.dx));
    expect(midpoint, lessThan(destinationCenter.dx));
    await tester.pumpAndSettle();
    expect(tester.getCenter(indicator).dx, closeTo(destinationCenter.dx, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation drag shrinks and commits the selector', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: selected,
                  onSelected: (value) => updateHost(() => selected = value),
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
              );
            },
          ),
        ),
      ),
    );

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final firstItem = find.byKey(const ValueKey('floating-navigation-item-0'));
    final secondItem = find.byKey(const ValueKey('floating-navigation-item-1'));
    // 记录文字排版后的静止尺寸，按压仍只内缩相同的几何量。
    final restingSize = tester.getSize(indicator);
    expect(restingSize.width, 84);
    expect(restingSize.height, greaterThanOrEqualTo(52));

    final gesture = await tester.startGesture(tester.getCenter(firstItem));
    await gesture.moveBy(const Offset(88, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    // Movement briefly stretches the lens; holding still returns to the inset.
    expect(tester.getSize(indicator).width, inInclusiveRange(80, 96));
    expect(
      tester.getSize(indicator).height,
      inInclusiveRange(restingSize.height * .75, restingSize.height - 4),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(indicator),
      Size(restingSize.width - 4, restingSize.height - 4),
    );
    expect(
      tester.getCenter(indicator).dx,
      closeTo(tester.getCenter(secondItem).dx, .01),
    );
    expect(
      selected,
      0,
      reason: 'dragging does not switch the page mid-gesture',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.getSize(indicator), restingSize);
    expect(
      tester.getCenter(indicator).dx,
      closeTo(tester.getCenter(secondItem).dx, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation survives items clearing during a drag', (
    tester,
  ) async {
    var items = const <MiuixNavigationItem>[
      MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
      MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: 2,
                  onSelected: (_) {},
                  items: items,
                ),
              );
            },
          ),
        ),
      ),
    );

    final first = find.byKey(const ValueKey('floating-navigation-item-0'));
    final drag = await tester.startGesture(tester.getCenter(first));
    await drag.moveBy(const Offset(32, 0));
    await tester.pump();
    updateHost(() => items = const <MiuixNavigationItem>[]);
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsNothing,
    );

    updateHost(
      () => items = const <MiuixNavigationItem>[
        MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation drag follows logical direction in RTL', (
    tester,
  ) async {
    var selected = 1;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Center(
                  child: MiuixFloatingNavigationBar(
                    selectedIndex: selected,
                    onSelected: (value) => updateHost(() => selected = value),
                    items: const <MiuixNavigationItem>[
                      MiuixNavigationItem(icon: Icon(Icons.home), label: '主页'),
                      MiuixNavigationItem(
                        icon: Icon(Icons.search),
                        label: '搜索',
                      ),
                      MiuixNavigationItem(
                        icon: Icon(Icons.settings),
                        label: '设置',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final secondItem = find.byKey(const ValueKey('floating-navigation-item-1'));
    final gesture = await tester.startGesture(tester.getCenter(secondItem));
    // Physical movement to the right selects the preceding logical RTL item.
    await gesture.moveBy(const Offset(88, 0));
    await tester.pump(const Duration(milliseconds: 140));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation near-full selector honors RTL and motion', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return Center(
                    child: MiuixFloatingNavigationBar(
                      selectedIndex: selected,
                      onSelected: (value) => updateHost(() => selected = value),
                      items: const <MiuixNavigationItem>[
                        MiuixNavigationItem(
                          icon: Icon(Icons.home),
                          label: '主页',
                        ),
                        MiuixNavigationItem(
                          icon: Icon(Icons.search),
                          label: '搜索',
                        ),
                        MiuixNavigationItem(
                          icon: Icon(Icons.settings),
                          label: '设置',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final dragSizeAnimation = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('floating-navigation-drag-size-animation')),
    );
    expect(dragSizeAnimation.duration, Duration.zero);
    expect(
      tester.getCenter(indicator).dx,
      closeTo(
        tester
            .getCenter(find.byKey(const ValueKey('floating-navigation-item-0')))
            .dx,
        .001,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-2')));
    await tester.pump();
    expect(
      tester.getCenter(indicator).dx,
      closeTo(
        tester
            .getCenter(find.byKey(const ValueKey('floating-navigation-item-2')))
            .dx,
        .001,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation exposes independent geometry overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              itemWidth: 90,
              itemHeight: 50,
              selectionHeight: 38,
              selectionHorizontalInset: 7,
              items: const <MiuixNavigationItem>[
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

    final item = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    final indicator = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    // 显式宽度不变，高度仍不能裁掉实际字号下的完整标签。
    expect(item.width, 90);
    expect(item.height, greaterThanOrEqualTo(50));
    expect(indicator.size, const Size(76, 38));
    expect(indicator.center, item.center);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation badge bounds clamp top and logical end in RTL', (
    tester,
  ) async {
    Future<void> pumpBar(TextDirection direction) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Directionality(
              textDirection: direction,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  key: const ValueKey('bounded-regular-bar'),
                  width: 180,
                  height: 64,
                  child: MiuixNavigationBar(
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    showDivider: false,
                    defaultWindowInsetsPadding: false,
                    items: const [
                      MiuixNavigationItem(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                        badge: SizedBox(
                          key: ValueKey('bounded-regular-badge'),
                          width: 120,
                          height: 48,
                        ),
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
        ),
      );
      await tester.pump();
    }

    await pumpBar(TextDirection.ltr);
    var host = tester.getRect(
      find.byKey(const ValueKey('bounded-regular-bar')),
    );
    var badge = tester.getRect(
      find.byKey(const ValueKey('bounded-regular-badge')),
    );
    expect(badge.top, closeTo(host.top, .001));
    expect(badge.right, closeTo(host.left + host.width / 2, .001));

    await pumpBar(TextDirection.rtl);
    host = tester.getRect(find.byKey(const ValueKey('bounded-regular-bar')));
    badge = tester.getRect(find.byKey(const ValueKey('bounded-regular-badge')));
    // The first logical destination occupies the physical right half in RTL;
    // its logical end is therefore the half-width boundary on the left.
    expect(badge.top, closeTo(host.top, .001));
    expect(badge.left, closeTo(host.left + host.width / 2, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation clamps an oversized source badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              defaultWindowInsetsPadding: false,
              items: const [
                MiuixNavigationItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                  badge: SizedBox(
                    key: ValueKey('bounded-floating-badge'),
                    width: 120,
                    height: 48,
                  ),
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
    );
    await tester.pump();

    final item = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    final badge = tester.getRect(
      find.byKey(const ValueKey('bounded-floating-badge')),
    );
    // Horizontal HyperOS content may keep a large badge slightly inside the
    // item, but it must never escape above or beyond the logical-end edge.
    expect(badge.top, greaterThanOrEqualTo(item.top));
    expect(badge.right, closeTo(item.right, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic and expandable rails clamp oversized source badges', (
    tester,
  ) async {
    Widget rail({MiuixNavigationRailState? state, required String badgeKey}) {
      return MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 400,
              child: MiuixNavigationRail.sourceItems(
                state: state,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                showDivider: false,
                defaultWindowInsetsPadding: false,
                items: [
                  MiuixNavigationItem(
                    icon: const Icon(Icons.home_outlined),
                    label: 'Home',
                    badge: SizedBox(
                      key: ValueKey(badgeKey),
                      width: 120,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(rail(badgeKey: 'bounded-classic-rail-badge'));
    await tester.pump();
    var item = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-item-0')),
    );
    var badge = tester.getRect(
      find.byKey(const ValueKey('bounded-classic-rail-badge')),
    );
    expect(badge.top, closeTo(item.top, .001));
    expect(badge.right, closeTo(item.right, .001));

    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      rail(state: state, badgeKey: 'bounded-expandable-rail-badge'),
    );
    await tester.pump();
    item = tester.getRect(find.byKey(const ValueKey('navigation-rail-item-0')));
    badge = tester.getRect(
      find.byKey(const ValueKey('bounded-expandable-rail-badge')),
    );
    expect(badge.top, closeTo(item.top, .001));
    expect(badge.right, closeTo(item.right, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating navigation evenly divides Chinese and English destinations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
                displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home),
                    label: '主页',
                    layoutLabel: 'Home',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings),
                    label: '设置',
                    layoutLabel: 'Settings',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.image),
                    label: '颜色',
                    layoutLabel: 'Color',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.sort),
                    label: '下拉菜单',
                    layoutLabel: 'Dropdown',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.edit),
                    label: '图标',
                    layoutLabel: 'Icon',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final homeLabel = tester.getRect(find.text('主页'));
      // 不再绘制隐藏的英文计量标签，宽度仍由等分目的地决定。
      expect(find.text('Home'), findsNothing);
      final settingsLabel = tester.getRect(find.text('设置'));
      expect(find.text('Settings'), findsNothing);
      final surface = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );

      expect(homeLabel.width, greaterThan(0));
      expect(settingsLabel.width, greaterThan(0));
      // 真正的中文标签以所属等宽目的地居中，不再引用隐藏英文节点。
      expect(
        homeLabel.center.dx,
        closeTo(
          tester
              .getRect(find.byKey(const ValueKey('floating-navigation-item-0')))
              .center
              .dx,
          .01,
        ),
      );
      expect(
        settingsLabel.center.dx,
        closeTo(
          tester
              .getRect(find.byKey(const ValueKey('floating-navigation-item-1')))
              .center
              .dx,
          .01,
        ),
      );
      final itemRects = [
        for (var index = 0; index < 5; index++)
          tester.getRect(
            find.byKey(ValueKey('floating-navigation-item-$index')),
          ),
      ];
      final equalWidth = itemRects.first.width;
      expect(equalWidth, greaterThanOrEqualTo(68));
      expect(
        itemRects.map((rect) => rect.width),
        everyElement(closeTo(equalWidth, .001)),
      );
      expect(itemRects.map((rect) => rect.height).toSet(), {52.0});
      for (var index = 1; index < itemRects.length; index++) {
        expect(
          itemRects[index].left - itemRects[index - 1].right,
          closeTo(0, .001),
        );
      }
      expect(surface.width, closeTo(equalWidth * 5 + 12, .001));
      expect(surface.height, 58);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
                displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
                items: const [
                  MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                  MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Icons'),
                  MiuixNavigationItem(icon: Icon(Icons.image), label: 'Colors'),
                  MiuixNavigationItem(
                    icon: Icon(Icons.sort),
                    label: 'Dropdown',
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
      );
      final englishItemRects = [
        for (var index = 0; index < 5; index++)
          tester.getRect(
            find.byKey(ValueKey('floating-navigation-item-$index')),
          ),
      ];
      final englishEqualWidth = englishItemRects.first.width;
      expect(englishEqualWidth, greaterThanOrEqualTo(68));
      expect(
        englishItemRects.map((rect) => rect.width),
        everyElement(closeTo(englishEqualWidth, .001)),
      );
      // 更长的英文可以增加共同高度，但所有目的地仍等宽且等高。
      expect(englishItemRects.map((rect) => rect.height).toSet().length, 1);
      expect(englishItemRects.first.height, greaterThanOrEqualTo(52));
      expect(
        tester.getRect(find.text('Dropdown').last).width,
        lessThanOrEqualTo(englishItemRects.first.width),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('floating navigation bar keeps scaffold body visible', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            topBar: const MiuixTopAppBar(title: 'Settings'),
            body: const ColoredBox(
              key: ValueKey('floating-navigation-body'),
              color: Colors.white,
              child: Center(child: Text('Body remains visible')),
            ),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bodySize = tester.getSize(
      find.byKey(const ValueKey('floating-navigation-body')),
    );
    final barRect = tester.getRect(find.byType(MiuixFloatingNavigationBar));
    final iconRect = tester.getRect(find.byIcon(Icons.home));

    expect(find.text('Body remains visible'), findsOneWidget);
    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-body')),
    );
    expect(bodySize.height, greaterThan(750));
    expect(bodyRect.bottom, 844);
    expect(barRect.height, 84);
    expect(barRect.bottom, 844);
    expect(bodyRect.bottom, greaterThan(barRect.top));
    expect(iconRect.center.dy, greaterThan(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation reserves the source upper shadow paint', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const ColoredBox(color: Colors.white),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final shadowAllowance = tester
        .widgetList<Padding>(
          find.descendant(
            of: find.byType(MiuixFloatingNavigationBar),
            matching: find.byType(Padding),
          ),
        )
        .where((padding) => padding.padding == const EdgeInsets.only(top: 10));

    // Floating bars are painted in the full-window overlay rather than the
    // clipping Scaffold slot. The transparent 10dp band gives the zero-offset
    // source halo room above the capsule without changing its keyed height.
    expect(scaffold.bottomNavigationBar, isNull);
    expect(shadowAllowance, hasLength(1));
    expect(
      tester.getSize(find.byKey(const ValueKey('floating-navigation-surface'))),
      const Size(220, 58),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation keeps the Android gesture-bar gap', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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

    final navigation = tester.getRect(find.byType(MiuixFloatingNavigationBar));
    final pill = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(navigation.bottom, 600);
    expect(navigation.bottom - pill.bottom, 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation supports a compact gesture-bar gap', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixFloatingNavigationBar(
              bottomMargin: 4,
              selectedIndex: 0,
              onSelected: (_) {},
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

    final navigation = tester.getRect(find.byType(MiuixFloatingNavigationBar));
    final pill = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(navigation.bottom, 600);
    // The 24dp system gesture region owns the safety clearance. This override
    // adds only 4dp, keeping the capsule close to the gesture handle.
    expect(navigation.bottom - pill.bottom, 28);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation animates caption above the gesture gap', (
    tester,
  ) async {
    final insets = StreamController<MiuixWindowInsets>.broadcast(sync: true);
    MiuixWindowInsetsObserver.debugEvents = insets.stream;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() async {
      MiuixWindowInsetsObserver.debugEvents = null;
      debugDefaultTargetPlatformOverride = null;
      await insets.close();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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
    await tester.pump();

    double capsuleBottomGap() {
      final navigation = tester.getRect(
        find.byType(MiuixFloatingNavigationBar),
      );
      final capsule = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );
      return navigation.bottom - capsule.bottom;
    }

    expect(capsuleBottomGap(), 40);
    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(capsuleBottomGap(), closeTo(55, .001));
    await tester.pump(const Duration(milliseconds: 150));
    expect(capsuleBottomGap(), 70);
    MiuixWindowInsetsObserver.debugEvents = null;
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation caption inset snaps with reduced motion', (
    tester,
  ) async {
    final insets = StreamController<MiuixWindowInsets>.broadcast(sync: true);
    MiuixWindowInsetsObserver.debugEvents = insets.stream;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() async {
      MiuixWindowInsetsObserver.debugEvents = null;
      debugDefaultTargetPlatformOverride = null;
      await insets.close();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
            disableAnimations: true,
          ),
          child: MiuixTheme(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
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
      ),
    );
    await tester.pump();

    double capsuleBottomGap() {
      final navigation = tester.getRect(
        find.byType(MiuixFloatingNavigationBar),
      );
      final capsule = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );
      return navigation.bottom - capsule.bottom;
    }

    expect(capsuleBottomGap(), 40);
    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
    );
    await tester.pump();
    expect(capsuleBottomGap(), 70);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find
                .descendant(
                  of: find.byKey(
                    const ValueKey(
                      'floating-navigation-caption-inset-animation',
                    ),
                  ),
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          )
          .duration,
      Duration.zero,
    );
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid navigation tolerates asynchronous empty items', (
    tester,
  ) async {
    var items = const <MiuixNavigationItem>[
      MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
      MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MiuixIosLiquidGlassNavigationBar(
                items: items,
                selectedIndex: 99,
                onDestinationSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('ios-liquid-panel'));
    final pointer = await tester.startGesture(tester.getCenter(panel));
    await tester.pump();
    updateHost(() => items = const <MiuixNavigationItem>[]);
    await tester.pump();
    expect(panel, findsNothing);
    await pointer.up();
    await tester.pump();

    updateHost(
      () => items = const <MiuixNavigationItem>[
        MiuixNavigationItem(icon: Icon(Icons.home), label: 'Only'),
      ],
    );
    await tester.pumpAndSettle();
    expect(panel, findsOneWidget);
    expect(find.byKey(const ValueKey('ios-liquid-tab-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-like navigation keeps liquid source metrics and taps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    final indicator = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-indicator')),
    );
    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('ios-liquid-surface')),
    );
    expect(panel, const Rect.fromLTWH(24, 744, 342, 64));
    expect(indicator.left, closeTo(28, .01));
    expect(indicator.top, 748);
    expect(indicator.width, closeTo(66.8, .01));
    expect(indicator.height, 56);
    // Upstream draws a 40% surface-container tint into its refracting panel.
    // The global five-level setting modulates that authored opacity.
    expect(
      surface.color.a,
      closeTo(MiuixGlassIntensity.intense.resolveOpacity(.4), .001),
    );
    // Host text themes must not inject underline/overline decoration into the
    // duplicated normal and selector rows. Release screenshots previously
    // exposed those inherited baselines as bright double rules under labels.
    for (final label in tester.widgetList<Text>(find.text('Home'))) {
      expect(label.style?.decoration, TextDecoration.none);
      expect(label.style?.decorationColor, Colors.transparent);
    }
    expect(
      find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-panel-source-specular')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsOneWidget,
    );
    // Selected color now belongs to the stationary destination row. The lens
    // no longer carries a second translated copy that can reveal two clipped
    // labels while travelling between adjacent destinations.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);

    // A click shrinks the current selector on down but does not jump to the
    // touched destination before the gesture has actually been committed.
    final target = find.byKey(const ValueKey('ios-liquid-tab-2'));
    final tap = await tester.startGesture(tester.getCenter(target));
    // Start the spring clock first; the next frame then has a deterministic
    // nonzero elapsed duration instead of being AnimationController's epoch.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(selected, -1);
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28, .01),
    );
    await tap.up();
    await tester.pump();
    expect(selected, 2);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28 + 2 * 66.8, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-like navigation supports a centered split action group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    var actionTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(),
          child: Scaffold(
            extendBody: true,
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.history), label: 'Recent'),
                MiuixNavigationItem(icon: Icon(Icons.folder), label: 'Browse'),
              ],
              trailingAction: MiuixIconButton(
                key: const ValueKey('split-search'),
                onPressed: () => actionTaps++,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-panel'))),
      const Rect.fromLTWH(77, 752, 168, 56),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-trailing-action'))),
      const Rect.fromLTWH(257, 752, 56, 56),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))),
      const Rect.fromLTWH(81, 756, 80, 48),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ios-liquid-trailing-action')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('split-search')));
    await tester.pumpAndSettle();
    expect(actionTaps, 1);
    expect(selected, -1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HyperOS liquid selector keeps a local selected blur layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Set'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    expect(
      find.descendant(
        of: indicator,
        matching: find.byKey(
          const ValueKey('ios-liquid-indicator-single-fill'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-specular')),
      findsNothing,
    );
    // The upstream panel BloomStroke concentrates its secondary light along
    // the capsule's lower edge. HyperOS omits it so the bar cannot acquire a
    // bright horizontal seam over light content.
    expect(
      find.byKey(const ValueKey('ios-liquid-panel-source-specular')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-inner-depth')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsNWidgets(2),
    );
    final singleFill = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
    );
    // Level five may clear the shared panel tint, but the selected destination
    // retains a stable light-mode contrast wash instead of fading to 2.2%.
    expect(singleFill.color.a, closeTo(.08, .001));

    final panelFilter = tester.widget(
      find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
    );
    void expectStableHyperOsGeometry() {
      final panelScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-panel-press-scale')),
      );
      final indicatorScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      final selectedItemScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-selected-item-scale-0')),
      );
      expect(panelScale.transform.storage[0], closeTo(1, 1e-9));
      expect(panelScale.transform.storage[5], closeTo(1, 1e-9));
      expect(indicatorScale.transform.storage[0], closeTo(1, 1e-9));
      expect(indicatorScale.transform.storage[5], closeTo(1, 1e-9));
      expect(selectedItemScale.transform.storage[0], closeTo(1, 1e-9));
      expect(selectedItemScale.transform.storage[5], closeTo(1, 1e-9));
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
            )
            .color,
        singleFill.color,
      );
    }

    expectStableHyperOsGeometry();

    // Pressing and dragging contract the same travelling surface. They must
    // not insert a second edge light or inner-shadow ellipse at interaction
    // time, which was the hardware-only doubled selector appearance.
    final drag = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expectStableHyperOsGeometry();
    expect(
      identical(
        tester.widget(find.byKey(const ValueKey('ios-liquid-backdrop-filter'))),
        panelFilter,
      ),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-specular')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-inner-depth')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsOneWidget,
    );
    await drag.moveBy(const Offset(72, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsNWidgets(2),
    );
    await drag.up();
    await tester.pumpAndSettle();
    expectStableHyperOsGeometry();
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid selector tracks drag directly and snaps once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    // A tap retains a short settle spring and reaches the exact destination.
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
    const tabWidth = 66.8;
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28 + 2 * tabWidth, .01),
    );
    expect(selected, 2);

    // The HyperOS 4 travelling thumb contracts inside the resting tab-wide,
    // 56dp-high lens and retains only bounded velocity deformation.
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final panelShadow = find.byKey(const ValueKey('ios-liquid-panel-shadow'));
    final restingShadowRect = tester.getRect(panelShadow);
    final restingHighlight = tester
        .widgetList<MiuixHighlightOverlay>(
          find.descendant(
            of: indicator,
            matching: find.byType(MiuixHighlightOverlay),
          ),
        )
        .single;
    // Android used to keep a .35-alpha fallback outline at rest. Against the
    // outer capsule edge that rendered as a second concentric ellipse.
    expect(restingHighlight.highlight.alpha, closeTo(0, .001));
    final press = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    var shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    expect(shape.transform.storage[0], inExclusiveRange(.7, 1));
    expect(shape.transform.storage[5], inExclusiveRange(.7, 1));
    await tester.pump(const Duration(milliseconds: 100));
    // Only the glass surface expands. Its drop shadow remains at exactly the
    // resting panel footprint, matching the upstream modifier order.
    expect(tester.getRect(panelShadow), restingShadowRect);
    final panelGlassScale = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-panel-press-scale')),
    );
    expect(panelGlassScale.transform.storage[0], greaterThan(1));
    // Each selected item scales around its own center. Scaling the complete
    // row would shift edge items away from their stationary item underneath.
    final selectedItemScale = find.byKey(
      const ValueKey('ios-liquid-selected-item-scale-2'),
    );
    final selectedForegroundCenter = tester.getCenter(selectedItemScale);
    final stationaryItemCenter = tester.getCenter(
      find.byKey(const ValueKey('ios-liquid-tab-2')),
    );
    expect(selectedForegroundCenter.dx, closeTo(stationaryItemCenter.dx, .001));
    expect(selectedForegroundCenter.dy, closeTo(stationaryItemCenter.dy, .001));
    expect(
      tester.widget<Transform>(selectedItemScale).transform.storage[0],
      greaterThan(1),
    );
    // WidgetTester.getRect reports layout bounds and deliberately excludes a
    // RenderTransform's paint-only scale. Reconstruct the painted vertical
    // bounds from the actual matrix around the centered selection slot.
    shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    final indicatorSlot = tester.getRect(indicator);
    final paintedHeight = indicatorSlot.height * shape.transform.storage[5];
    final paintedTop = indicatorSlot.center.dy - paintedHeight / 2;
    final paintedBottom = indicatorSlot.center.dy + paintedHeight / 2;
    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    expect(paintedHeight, lessThan(56));
    expect(paintedTop, greaterThan(panel.top));
    expect(paintedBottom, lessThan(panel.bottom));
    await press.up();
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(indicator));
    final dragStartLeft = tester.getRect(indicator).left;
    await tester.pump();
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 16));
    // Pointer samples move the selector one-for-one instead of repeatedly
    // retargeting a lagging spring. Only release performs a spring snap.
    final panelTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
    );
    final panelOffset = panelTransform.transform.storage[12];
    expect(
      tester.getRect(indicator).left,
      closeTo(dragStartLeft + 40 + panelOffset, .01),
    );
    expect(panelTransform.transform.storage[12].abs(), inExclusiveRange(0, 4));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
          )
          .transform
          .storage[12],
      // The source panel spring uses a .5px visibility threshold; after the
      // rubber-band transfer that permits only a few thousandths of a dp.
      closeTo(0, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid release stays in the slot under the finger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 4,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    const tabWidth = 66.8;
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final gesture = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    // End 20% inside the second slot, as the physical Xiaomi verification did.
    // Its nearest selector center is still index 1; release velocity must not
    // fling the committed destination one extra slot to index 0.
    await gesture.moveBy(const Offset(-3.2 * tabWidth, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(tester.getRect(indicator).left, closeTo(28 + tabWidth, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid position frames retain both filter subtrees', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panelLens = find.byKey(const ValueKey('ios-liquid-backdrop-filter'));
    final indicatorLens = find.byKey(
      const ValueKey('ios-liquid-indicator-lens-filter'),
    );
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('ios-liquid-indicator'))),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    final panelLensWidget = tester.widget(panelLens);
    final indicatorLensWidget = tester.widget(indicatorLens);

    await drag.moveBy(const Offset(28, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(identical(tester.widget(panelLens), panelLensWidget), isTrue);
    expect(
      identical(tester.widget(indicatorLens), indicatorLensWidget),
      isTrue,
    );

    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android high-DPR liquid lens stays bounded and releases', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    expect(tester.getSize(indicator), const Size(83.5, 56));
    final pointer = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    var shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    // The springs settle around a two-dp-per-edge inset. Both dimensions stay
    // below the resting tab-wide lens on a high-density Android host.
    expect(shape.transform.storage[0], inInclusiveRange(.88, .98));
    expect(shape.transform.storage[5], inInclusiveRange(.88, .98));

    await pointer.up();
    await tester.pumpAndSettle();
    shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    expect(shape.transform.storage[0], closeTo(1, .001));
    expect(shape.transform.storage[5], closeTo(1, .001));
    expect(tester.getSize(indicator), const Size(83.5, 56));
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid selector keeps RTL drag direction and fixed inset', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          // The source ignores iOS MediaQuery navigation padding here and
          // installs its own fixed 20dp optical bottom gap.
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: MiuixTheme(
                child: MiuixIosLiquidGlassNavigationBar.source(
                  selectedIndex: 1,
                  onDestinationSelected: (value) => selected = value,
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'One'),
                    MiuixNavigationItem(icon: Icon(Icons.search), label: 'Two'),
                    MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Three'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    expect(panel.bottom, 824);

    // In RTL a physical rightward drag moves from logical index one to zero.
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final gesture = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    // Cross touch slop first, then deliver an accepted drag segment; a single
    // synthetic jump can be consumed entirely by arena resolution.
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(96, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 0);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOS liquid selector reduced motion snaps but keeps direct drag',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 0;
      var reduceMotion = false;
      late StateSetter updateHost;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: MiuixTheme(
                  child: Scaffold(
                    bottomNavigationBar:
                        MiuixIosLiquidGlassNavigationBar.source(
                          selectedIndex: selected,
                          onDestinationSelected: (value) => selected = value,
                          items: const [
                            MiuixNavigationItem(
                              icon: Icon(Icons.home),
                              label: 'Home',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.search),
                              label: 'Search',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.image),
                              label: 'Color',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.edit),
                              label: 'Text',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.settings),
                              label: 'Settings',
                            ),
                          ],
                        ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
      final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
      await tester.pumpAndSettle();
      expect(tester.getRect(indicator).left, closeTo(161.6, .01));

      updateHost(() => reduceMotion = true);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(indicator).left, closeTo(161.6, .01));
      var shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(1, 1e-9));
      expect(shape.transform.storage[5], closeTo(1, 1e-9));

      final drag = await tester.startGesture(tester.getCenter(indicator));
      await tester.pump();
      shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(52 / 56, 1e-9));
      expect(shape.transform.storage[5], closeTo(52 / 56, 1e-9));
      await drag.moveBy(const Offset(24, 0));
      await tester.pump();
      await drag.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(tester.getRect(indicator).left, greaterThan(210));

      await drag.up();
      await tester.pump();
      expect(selected, 3);
      expect(tester.getRect(indicator).left, closeTo(228.4, .01));
      shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(1, 1e-9));
      expect(shape.transform.storage[5], closeTo(1, 1e-9));
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
            )
            .transform
            .storage[12],
        closeTo(0, 1e-9),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('intense glass top and bottom bars blur extended page content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: MiuixScaffold(
            topBar: const MiuixTopAppBar(
              title: 'Glass',
              glass: true,
              blurStyle: MiuixTopAppBarBlurStyle.gaussian,
            ),
            bottomBar: MiuixNavigationBar(
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
            body: ListView(
              key: const ValueKey('glass-bars-body'),
              padding: EdgeInsets.zero,
              children: const [
                ColoredBox(color: Colors.red, child: SizedBox(height: 300)),
                ColoredBox(color: Colors.blue, child: SizedBox(height: 600)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final topGlass = find.byKey(const ValueKey('top-app-bar-glass'));
    final bottomGlass = find.byKey(const ValueKey('navigation-bar-glass'));
    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(scaffold.extendBody, isTrue);
    expect(
      find.descendant(of: topGlass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bottomGlass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    // Level five scales the shared HyperOS 4 28dp/58% recipe. The resulting
    // tint stays visibly translucent rather than turning into a white slab.
    expect(tester.widget<MiuixGlass>(topGlass).blur, 28);
    expect(tester.widget<MiuixGlass>(topGlass).opacity, .58);
    expect(tester.widget<MiuixGlass>(topGlass).showSpecular, isFalse);
    expect(
      tester.widget<MiuixGlass>(topGlass).optics,
      same(MiuixGlassOptics.navigation),
    );
    expect(tester.widget<MiuixGlass>(bottomGlass).blur, 28);
    expect(tester.widget<MiuixGlass>(bottomGlass).opacity, .58);
    expect(
      tester.widget<MiuixGlass>(bottomGlass).optics,
      same(MiuixGlassOptics.navigation),
    );
    final topSurface = tester.widget<DecoratedBox>(
      find.descendant(of: topGlass, matching: find.byType(DecoratedBox)).first,
    );
    final bottomSurface = tester.widget<DecoratedBox>(
      find
          .descendant(of: bottomGlass, matching: find.byType(DecoratedBox))
          .first,
    );
    expect(
      (topSurface.decoration as ShapeDecoration).color!.a,
      closeTo(.0928, .001),
    );
    expect(
      (bottomSurface.decoration as ShapeDecoration).color!.a,
      closeTo(.0928, .001),
    );
    expect(
      find.byKey(const ValueKey('miuix-glass-specular-highlight')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('glass-bars-body'))).top,
      0,
    );
    expect(tester.takeException(), isNull);
  });
}
