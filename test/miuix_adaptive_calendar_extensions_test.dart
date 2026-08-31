import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps a package component at an explicit logical window size.
Future<void> pumpExtensionAtSize(
  WidgetTester tester, {
  required Size size,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MiuixTheme(child: MaterialApp(home: child)));
  await tester.pump();
}

const navigationItems = <MiuixNavigationItem>[
  MiuixNavigationItem(icon: Icon(Icons.home_outlined), label: 'Home'),
  MiuixNavigationItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
];

void main() {
  test('adaptive defaults resolve all three navigation presentations', () {
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(599),
      MiuixAdaptiveNavigationMode.bottom,
    );
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(600),
      MiuixAdaptiveNavigationMode.rail,
    );
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(1200),
      MiuixAdaptiveNavigationMode.drawer,
    );
  });

  test('adaptive defaults normalize malformed runtime breakpoints', () {
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(
        800,
        medium: 1200,
        expanded: 600,
      ),
      MiuixAdaptiveNavigationMode.rail,
    );
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(
        600,
        medium: double.nan,
        expanded: -1,
      ),
      MiuixAdaptiveNavigationMode.rail,
    );
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(double.nan),
      MiuixAdaptiveNavigationMode.bottom,
    );
    expect(
      MiuixAdaptiveLayoutDefaults.navigationModeFor(double.infinity),
      MiuixAdaptiveNavigationMode.drawer,
    );
  });

  testWidgets('adaptive content frame caps and centers expanded planes', (
    tester,
  ) async {
    const planeKey = ValueKey('adaptive-content-plane');
    await pumpExtensionAtSize(
      tester,
      size: const Size(1600, 700),
      child: const Scaffold(
        body: MiuixAdaptiveContentFrame(
          child: ColoredBox(key: planeKey, color: Colors.blue),
        ),
      ),
    );

    final plane = tester.getRect(find.byKey(planeKey));
    expect(plane, const Rect.fromLTWH(200, 0, 1200, 700));
  });

  testWidgets('adaptive content frame fills compact and repairs invalid max', (
    tester,
  ) async {
    const planeKey = ValueKey('adaptive-content-plane');
    Widget frame(double maximumWidth) => Scaffold(
      body: MiuixAdaptiveContentFrame(
        maximumWidth: maximumWidth,
        child: const ColoredBox(key: planeKey, color: Colors.blue),
      ),
    );

    await pumpExtensionAtSize(
      tester,
      size: const Size(800, 600),
      child: frame(1200),
    );
    expect(
      tester.getRect(find.byKey(planeKey)),
      const Rect.fromLTWH(0, 0, 800, 600),
    );

    await pumpExtensionAtSize(
      tester,
      size: const Size(1600, 600),
      child: frame(double.nan),
    );
    expect(
      tester.getRect(find.byKey(planeKey)),
      const Rect.fromLTWH(200, 0, 1200, 600),
    );
  });

  testWidgets('adaptive mode callback publishes actual transitions once', (
    tester,
  ) async {
    final reported = <MiuixAdaptiveNavigationMode>[];
    late StateSetter rebuild;
    var revision = 0;
    await pumpExtensionAtSize(
      tester,
      size: const Size(800, 700),
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MiuixAdaptiveScaffold(
            body: Text('Body $revision'),
            items: navigationItems,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            onResolvedModeChanged: reported.add,
          );
        },
      ),
    );
    await tester.pump();
    expect(reported, <MiuixAdaptiveNavigationMode>[
      MiuixAdaptiveNavigationMode.rail,
    ]);

    // An unrelated parent rebuild retains the resolved mode and must not
    // masquerade as another size-class transition.
    rebuild(() => revision++);
    await tester.pump();
    await tester.pump();
    expect(reported, <MiuixAdaptiveNavigationMode>[
      MiuixAdaptiveNavigationMode.rail,
    ]);

    tester.view.physicalSize = const Size(500, 700);
    await tester.pump();
    await tester.pump();
    expect(reported, <MiuixAdaptiveNavigationMode>[
      MiuixAdaptiveNavigationMode.rail,
      MiuixAdaptiveNavigationMode.bottom,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('adaptive scaffold switches bottom, rail, and fixed drawer', (
    tester,
  ) async {
    Widget shell() => MiuixAdaptiveScaffold(
      body: const Text('Body'),
      items: navigationItems,
      selectedIndex: 0,
      onDestinationSelected: (_) {},
    );

    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 700),
      child: shell(),
    );
    expect(find.byType(MiuixFloatingNavigationBar), findsOneWidget);

    await pumpExtensionAtSize(
      tester,
      size: const Size(800, 700),
      child: shell(),
    );
    expect(find.byType(MiuixNavigationRail), findsOneWidget);

    await pumpExtensionAtSize(
      tester,
      size: const Size(1280, 700),
      child: shell(),
    );
    expect(find.byType(MiuixNavigationDrawer), findsOneWidget);
    final drawerGlass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-navigation-drawer-panel')),
    );
    expect(drawerGlass.blur, 24);
    expect(drawerGlass.opacity, .56);
    expect(drawerGlass.radius, 32);
    final outer = tester.getRect(
      find.byKey(const ValueKey('miuix-navigation-drawer-outer')),
    );
    final panel = tester.getRect(
      find.byKey(const ValueKey('miuix-navigation-drawer-panel')),
    );
    expect(panel.left - outer.left, 12);
    expect(outer.right - panel.right, 12);
    expect(panel.top - outer.top, 12);
    expect(outer.bottom - panel.bottom, 12);
  });

  testWidgets(
    'navigation drawer default, solid override, and source separate',
    (tester) async {
      Widget drawer({required int presentation}) => switch (presentation) {
        0 => MiuixNavigationDrawer(
          items: navigationItems,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        1 => MiuixNavigationDrawer(
          glass: false,
          items: navigationItems,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        _ => MiuixNavigationDrawer.source(
          items: navigationItems,
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      };

      await pumpExtensionAtSize(
        tester,
        size: const Size(500, 700),
        child: Scaffold(body: drawer(presentation: 0)),
      );
      var panelFinder = find.byKey(
        const ValueKey('miuix-navigation-drawer-panel'),
      );
      expect(tester.widget<MiuixGlass>(panelFinder).radius, 32);
      expect(tester.getSize(panelFinder), const Size(300, 676));
      expect(
        tester.getSize(
          find.byKey(const ValueKey('miuix-navigation-drawer-outer')),
        ),
        const Size(324, 700),
      );

      await pumpExtensionAtSize(
        tester,
        size: const Size(500, 700),
        child: Scaffold(body: drawer(presentation: 1)),
      );
      panelFinder = find.byKey(const ValueKey('miuix-navigation-drawer-panel'));
      final solid = tester.widget<MiuixSurface>(panelFinder);
      expect(solid.glass, isFalse);
      expect(solid.radius, 32);
      expect(tester.getSize(panelFinder), const Size(300, 676));

      await pumpExtensionAtSize(
        tester,
        size: const Size(500, 700),
        child: Scaffold(body: drawer(presentation: 2)),
      );
      panelFinder = find.byKey(const ValueKey('miuix-navigation-drawer-panel'));
      final source = tester.widget<MiuixSurface>(panelFinder);
      expect(source.glass, isFalse);
      expect(source.radius, 0);
      expect(tester.getSize(panelFinder), const Size(300, 700));
      expect(
        tester.getSize(
          find.byKey(const ValueKey('miuix-navigation-drawer-outer')),
        ),
        const Size(300, 700),
      );
    },
  );

  testWidgets('navigation drawer exposes selection and disabled semantics', (
    tester,
  ) async {
    var selected = -1;
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 700),
      child: Scaffold(
        body: MiuixNavigationDrawer(
          items: const <MiuixNavigationItem>[
            MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
            MiuixNavigationItem(
              icon: Icon(Icons.block),
              label: 'Disabled',
              enabled: false,
            ),
          ],
          selectedIndex: 0,
          onDestinationSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.text('Home'));
    await tester.pump();
    expect(selected, 0);
    await tester.tap(find.text('Disabled'));
    expect(selected, 0);
  });

  testWidgets('navigation drawer selection uses rail motion and material', (
    tester,
  ) async {
    final selected = ValueNotifier<int>(0);
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(selected.dispose);
    addTearDown(reduceMotion.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 700),
      child: ValueListenableBuilder<bool>(
        valueListenable: reduceMotion,
        builder: (context, reduced, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                navigationRailBlur: 31,
                navigationRailTintOpacity: .42,
                navigationRailCornerRadius: 29,
                navigationRailOuterMargin: 17,
                navigationRailItemCornerRadius: 25,
                navigationRailMotion: Duration(milliseconds: 777),
              ),
            ),
            child: ValueListenableBuilder<int>(
              valueListenable: selected,
              builder: (context, selectedIndex, child) => Scaffold(
                body: MiuixNavigationDrawer(
                  glass: true,
                  items: const <MiuixNavigationItem>[
                    MiuixNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Animated home',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Animated settings',
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value) => selected.value = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final drawerGlass = tester.widget<MiuixGlass>(find.byType(MiuixGlass));
    expect(drawerGlass.blur, 31);
    expect(drawerGlass.opacity, .42);
    expect(drawerGlass.radius, 29);
    final outer = tester.getRect(
      find.byKey(const ValueKey('miuix-navigation-drawer-outer')),
    );
    final panel = tester.getRect(
      find.byKey(const ValueKey('miuix-navigation-drawer-panel')),
    );
    expect(panel.left - outer.left, 17);
    expect(outer.right - panel.right, 17);
    Finder settingsMotion() => find.ancestor(
      of: find.text('Animated settings'),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    MiuixSurface settingsSurface() => tester.widget<MiuixSurface>(
      find.byKey(
        const ValueKey<Object>(('miuix-navigation-drawer-surface', 1)),
      ),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(settingsMotion()).duration,
      const Duration(milliseconds: 777),
    );
    expect(settingsSurface().radius, 25);
    expect(settingsSurface().color, Colors.transparent);
    await tester.tap(find.text('Animated settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = settingsSurface().color!;
    expect(intermediate, isNot(Colors.transparent));

    reduceMotion.value = true;
    await tester.pump();
    expect(
      tester.widget<TweenAnimationBuilder<double>>(settingsMotion()).duration,
      Duration.zero,
    );
    expect(settingsSurface().color, isNot(intermediate));
    expect(selected.value, 1);
  });

  testWidgets('split view controller and drag update a constrained pane', (
    tester,
  ) async {
    final controller = MiuixSplitViewController(primaryExtent: 300);
    await pumpExtensionAtSize(
      tester,
      size: const Size(900, 600),
      child: MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            inlineSurfaceMotion: Duration(milliseconds: 777),
          ),
        ),
        child: Scaffold(
          body: MiuixSplitView(
            controller: controller,
            minimumPrimaryExtent: 220,
            minimumSecondaryExtent: 300,
            primary: const ColoredBox(color: Colors.red),
            secondary: const ColoredBox(color: Colors.blue),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<AnimatedContainer>(
            find.descendant(
              of: find.byType(MiuixSplitView),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .duration,
      const Duration(milliseconds: 777),
    );
    final divider = find.bySemanticsLabel('调整分栏大小');
    expect(divider, findsOneWidget);
    await tester.drag(divider, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(controller.primaryExtent, closeTo(380, .01));

    controller.collapse();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixSplitView)).width, 900);
  });

  testWidgets('split divider owns a narrow isolated slider semantic node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpExtensionAtSize(
      tester,
      size: const Size(900, 600),
      child: const Scaffold(
        body: Column(
          children: <Widget>[
            Text('Before split'),
            SizedBox(
              height: 300,
              child: MiuixSplitView(
                initialPrimaryExtent: 300,
                minimumPrimaryExtent: 220,
                minimumSecondaryExtent: 300,
                primary: Text('Primary content'),
                secondary: Text('Secondary content'),
              ),
            ),
            Text('After split'),
          ],
        ),
      ),
    );

    final divider = find.bySemanticsLabel('调整分栏大小');
    expect(divider, findsOneWidget);
    final node = tester.getSemantics(divider);
    expect(node.label, '调整分栏大小');
    expect(node.rect.width, MiuixSplitViewDefaults.dividerHitExtent);
    expect(node.rect.height, 300);
    expect(node.label, isNot(contains('Before split')));
    expect(node.label, isNot(contains('Primary content')));
    expect(node.label, isNot(contains('After split')));
    semantics.dispose();
  });

  testWidgets(
    'fixed split divider removes adjustment semantics and shortcuts',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpExtensionAtSize(
        tester,
        size: const Size(900, 600),
        child: const Scaffold(
          body: MiuixSplitView(
            resizable: false,
            primary: Text('Fixed primary'),
            secondary: Text('Fixed secondary'),
          ),
        ),
      );

      expect(find.bySemanticsLabel('调整分栏大小'), findsNothing);
      final shortcuts = tester.widget<Shortcuts>(
        find.descendant(
          of: find.byType(MiuixSplitView),
          matching: find.byType(Shortcuts),
        ),
      );
      expect(
        shortcuts.shortcuts.keys,
        containsAll(<ShortcutActivator>[
          const SingleActivator(LogicalKeyboardKey.arrowLeft),
          const SingleActivator(LogicalKeyboardKey.arrowRight),
        ]),
      );
      expect(
        shortcuts.shortcuts.keys,
        isNot(contains(const SingleActivator(LogicalKeyboardKey.arrowUp))),
      );
      semantics.dispose();
    },
  );

  testWidgets('vertical split exposes only vertical divider shortcuts', (
    tester,
  ) async {
    await pumpExtensionAtSize(
      tester,
      size: const Size(600, 900),
      child: const Scaffold(
        body: MiuixSplitView(
          direction: MiuixSplitViewDirection.vertical,
          primary: Text('Top'),
          secondary: Text('Bottom'),
        ),
      ),
    );

    final shortcuts = tester.widget<Shortcuts>(
      find.descendant(
        of: find.bySemanticsLabel('调整分栏大小'),
        matching: find.byType(Shortcuts),
      ),
    );
    expect(
      shortcuts.shortcuts.keys,
      containsAll(<ShortcutActivator>[
        const SingleActivator(LogicalKeyboardKey.arrowUp),
        const SingleActivator(LogicalKeyboardKey.arrowDown),
      ]),
    );
    expect(
      shortcuts.shortcuts.keys,
      isNot(contains(const SingleActivator(LogicalKeyboardKey.arrowLeft))),
    );
  });

  testWidgets('split divider follows a live pointer without animation lag', (
    tester,
  ) async {
    final controller = MiuixSplitViewController(primaryExtent: 300);
    await pumpExtensionAtSize(
      tester,
      size: const Size(900, 600),
      child: Scaffold(
        body: MiuixSplitView(
          controller: controller,
          minimumPrimaryExtent: 220,
          minimumSecondaryExtent: 300,
          primary: const SizedBox(key: ValueKey<String>('primary-content')),
          secondary: const SizedBox.shrink(),
        ),
      ),
    );

    final divider = find.bySemanticsLabel('调整分栏大小');
    final gesture = await tester.startGesture(tester.getCenter(divider));
    await gesture.moveBy(const Offset(80, 0));
    await tester.pump();

    expect(controller.primaryExtent, closeTo(380, .01));
    expect(
      tester.getSize(find.byKey(const ValueKey('primary-content'))).width,
      closeTo(380, .01),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('split view reduced motion snaps programmatic geometry', (
    tester,
  ) async {
    final controller = MiuixSplitViewController(primaryExtent: 300);
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(900, 600),
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(
          body: MiuixSplitView(
            controller: controller,
            minimumPrimaryExtent: 220,
            minimumSecondaryExtent: 300,
            primary: const SizedBox(key: ValueKey<String>('reduced-primary')),
            secondary: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    AnimatedContainer primarySurface() => tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixSplitView),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(primarySurface().duration, Duration.zero);

    controller.primaryExtent = 380;
    await tester.pump();
    expect(primarySurface().duration, Duration.zero);
    expect(
      tester
          .getSize(find.byKey(const ValueKey<String>('reduced-primary')))
          .width,
      380,
    );

    controller.collapse();
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('reduced-primary')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('split view survives a host below the secondary minimum', (
    tester,
  ) async {
    await pumpExtensionAtSize(
      tester,
      size: const Size(100, 180),
      child: const Scaffold(
        body: MiuixResizablePane(
          initialPrimaryExtent: 80,
          minimumPrimaryExtent: 60,
          minimumSecondaryExtent: 160,
          primary: ColoredBox(
            key: ValueKey<String>('tiny-primary'),
            color: Colors.red,
          ),
          secondary: ColoredBox(color: Colors.blue),
        ),
      ),
    );

    expect(find.byType(MiuixResizablePane), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('tiny-primary')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date range picker publishes normalized inclusive endpoints', (
    tester,
  ) async {
    final controller = MiuixDateRangePickerController(
      visibleMonth: DateTime(2026, 8),
    );
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 800),
      child: MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            calendarCornerRadius: 29,
            calendarBlur: 33,
            calendarTintOpacity: .41,
          ),
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: MiuixDateRangePicker(controller: controller),
            ),
          ),
        ),
      ),
    );

    for (final key in const <ValueKey<String>>[
      ValueKey<String>('miuix-date-range-start-endpoint'),
      ValueKey<String>('miuix-date-range-end-endpoint'),
    ]) {
      final endpoint = tester.widget<MiuixSurface>(find.byKey(key));
      expect(endpoint.glass, isTrue);
      expect(endpoint.radius, 29);
      expect(endpoint.glassBlur, 33);
      expect(endpoint.glassOpacity, .41);
    }

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    expect(controller.start, DateTime(2026, 8, 20));
    expect(controller.end, isNull);

    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(controller.value?.start, DateTime(2026, 8, 10));
    expect(controller.value?.end, DateTime(2026, 8, 20));

    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 800),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 420,
            child: MiuixDateRangePicker(controller: controller, glass: false),
          ),
        ),
      ),
    );
    expect(
      tester
          .widget<MiuixSurface>(
            find.byKey(
              const ValueKey<String>('miuix-date-range-start-endpoint'),
            ),
          )
          .glass,
      isFalse,
    );
  });

  test('one-day range keeps completed phase across calendar navigation', () {
    final controller = MiuixDateRangePickerController(
      value: MiuixDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 10)),
    );
    var changes = 0;
    controller.addListener(() => changes++);
    addTearDown(controller.dispose);

    expect(controller.selectingEnd, isFalse);
    expect(controller.end, DateTime(2026, 8, 10));
    controller.calendarController.showMonth(DateTime(2026, 9));
    expect(changes, 0);
    expect(controller.end, DateTime(2026, 8, 10));

    controller.calendarController.select(
      DateTime(2026, 9, 3),
      MiuixCalendarSelectionMode.range,
    );
    expect(controller.start, DateTime(2026, 9, 3));
    expect(controller.end, isNull);
    expect(controller.selectingEnd, isTrue);
    controller.calendarController.select(
      DateTime(2026, 9, 5),
      MiuixCalendarSelectionMode.range,
    );
    expect(
      controller.value,
      MiuixDateRange(DateTime(2026, 9, 3), DateTime(2026, 9, 5)),
    );
    expect(controller.selectingEnd, isFalse);
    expect(changes, 2);
  });

  testWidgets(
    'date range picker clamps initial and external controller ranges',
    (tester) async {
      final controller = MiuixDateRangePickerController(
        value: MiuixDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 20)),
      );
      final published = <MiuixDateRange?>[];
      addTearDown(controller.dispose);

      await pumpExtensionAtSize(
        tester,
        size: const Size(500, 800),
        child: Scaffold(
          body: MiuixDateRangePicker(
            controller: controller,
            minimumDate: DateTime(2026, 8, 5, 23),
            maximumDate: DateTime(2026, 8, 10, 1),
            onChanged: published.add,
            glass: false,
          ),
        ),
      );

      expect(
        controller.value,
        MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 10)),
      );
      expect(controller.selectingEnd, isFalse);
      expect(published, isEmpty);

      controller.value = MiuixDateRange(
        DateTime(2026, 7, 1),
        DateTime(2026, 7, 2),
      );
      await tester.pump();

      expect(
        controller.value,
        MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 5)),
      );
      expect(controller.selectingEnd, isFalse);
      expect(published, <MiuixDateRange?>[
        MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 5)),
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('date range picker preserves a pending endpoint when clamped', (
    tester,
  ) async {
    final controller = MiuixDateRangePickerController(
      visibleMonth: DateTime(2026, 8),
    );
    final published = <MiuixDateRange?>[];
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 800),
      child: Scaffold(
        body: MiuixDateRangePicker(
          controller: controller,
          minimumDate: DateTime(2026, 8, 5),
          maximumDate: DateTime(2026, 8, 10),
          onChanged: published.add,
          glass: false,
        ),
      ),
    );

    controller.calendarController.setRange(
      MiuixDateRange(DateTime(2026, 8, 1), DateTime(2026, 8, 1)),
      selectingEnd: true,
    );
    await tester.pump();

    expect(controller.start, DateTime(2026, 8, 5));
    expect(controller.end, isNull);
    expect(controller.selectingEnd, isTrue);
    expect(published, <MiuixDateRange?>[
      MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 5)),
    ]);

    controller.calendarController.select(
      DateTime(2026, 8, 8),
      MiuixCalendarSelectionMode.range,
    );
    await tester.pump();
    expect(
      controller.value,
      MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 8)),
    );
    expect(controller.selectingEnd, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('date range picker applies live reversed bounds once', (
    tester,
  ) async {
    final controller = MiuixDateRangePickerController(
      value: MiuixDateRange(DateTime(2026, 8, 5), DateTime(2026, 8, 18)),
    );
    final published = <MiuixDateRange?>[];
    late StateSetter rebuild;
    var minimum = DateTime(2026, 8, 1);
    var maximum = DateTime(2026, 8, 20);
    addTearDown(controller.dispose);

    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 800),
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return Scaffold(
            body: MiuixDateRangePicker(
              controller: controller,
              minimumDate: minimum,
              maximumDate: maximum,
              onChanged: published.add,
              glass: false,
            ),
          );
        },
      ),
    );

    rebuild(() {
      minimum = DateTime(2026, 8, 12);
      maximum = DateTime(2026, 8, 10);
    });
    await tester.pump();

    expect(
      controller.value,
      MiuixDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 12)),
    );
    expect(published, <MiuixDateRange?>[
      MiuixDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 12)),
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('month and year pickers share a public controller', (
    tester,
  ) async {
    final controller = MiuixMonthPickerController(value: DateTime(2026, 8));
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 900),
      child: Scaffold(
        body: Column(
          children: <Widget>[
            SizedBox(
              width: 420,
              child: MiuixMonthPicker(
                controller: controller,
                monthLabelBuilder: (_, month) => '$month月',
              ),
            ),
            MiuixYearPicker(
              controller: controller,
              minimumYear: 2025,
              maximumYear: 2027,
              height: 100,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('9月'));
    await tester.pump();
    expect(controller.value, DateTime(2026, 9));
    await tester.tap(find.text('2027'));
    await tester.pump();
    expect(controller.value, DateTime(2027, 9));
  });

  testWidgets('month and year pickers normalize reversed authored bounds', (
    tester,
  ) async {
    final controller = MiuixMonthPickerController(value: DateTime(2030, 1));
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 900),
      child: Scaffold(
        body: Column(
          children: <Widget>[
            SizedBox(
              width: 420,
              child: MiuixMonthPicker(
                controller: controller,
                minimumMonth: DateTime(2027, 12),
                maximumMonth: DateTime(2026, 3),
              ),
            ),
            MiuixYearPicker(
              controller: controller,
              minimumYear: 2028,
              maximumYear: 2026,
              height: 120,
            ),
          ],
        ),
      ),
    );

    expect(controller.value, DateTime(2027, 12));
    Finder year(String value) => find.descendant(
      of: find.byType(MiuixYearPicker),
      matching: find.text(value),
    );
    expect(year('2026'), findsOneWidget);
    expect(year('2027'), findsOneWidget);
    expect(year('2028'), findsOneWidget);
    await tester.tap(year('2026'));
    await tester.pump();
    expect(controller.value, DateTime(2026, 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('month picker clamps external values and separates key focus', (
    tester,
  ) async {
    final controller = MiuixMonthPickerController(value: DateTime(2026, 6));
    final published = <DateTime>[];
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 700),
      child: Scaffold(
        body: SizedBox(
          width: 420,
          child: MiuixMonthPicker(
            controller: controller,
            minimumMonth: DateTime(2026, 3),
            maximumMonth: DateTime(2026, 9),
            monthLabelBuilder: (_, month) => '$month月',
            onChanged: published.add,
            glass: false,
          ),
        ),
      ),
    );

    controller.value = DateTime(2035, 2);
    await tester.pump();
    expect(controller.value, DateTime(2026, 9));
    expect(published, <DateTime>[DateTime(2026, 9)]);

    await tester.tap(find.text('6月'));
    await tester.pump();
    expect(controller.value, DateTime(2026, 6));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(controller.value, DateTime(2026, 6));
    final focusedSeptember = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '9月',
      ),
    );
    expect(focusedSeptember.properties.focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.value, DateTime(2026, 9));
    expect(published.last, DateTime(2026, 9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('year picker clamps, reveals, and keyboard-selects its value', (
    tester,
  ) async {
    final controller = MiuixMonthPickerController(value: DateTime(2028, 7));
    final published = <DateTime>[];
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(420, 500),
      child: Scaffold(
        body: MiuixYearPicker(
          controller: controller,
          minimumYear: 2000,
          maximumYear: 2030,
          height: 70,
          onChanged: published.add,
          glass: false,
        ),
      ),
    );

    // Initial scroll positioning keeps the selected late-range year visible.
    expect(find.text('2028'), findsOneWidget);
    final pickerRect = tester.getRect(find.byType(MiuixYearPicker));
    expect(pickerRect.contains(tester.getCenter(find.text('2028'))), isTrue);

    controller.value = DateTime(2040, 7);
    await tester.pumpAndSettle();
    expect(controller.value, DateTime(2030, 7));
    expect(published, isEmpty);
    expect(find.text('2030'), findsOneWidget);

    await tester.tap(find.text('2030'));
    await tester.pump();
    published.clear();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.value, DateTime(2030, 7));
    final focused2029 = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '2029',
      ),
    );
    expect(focused2029.properties.focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(controller.value, DateTime(2029, 7));
    expect(published, <DateTime>[DateTime(2029, 7)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('year picker follows controller, bounds, and viewport changes', (
    tester,
  ) async {
    final first = MiuixMonthPickerController(value: DateTime(2028, 4));
    final second = MiuixMonthPickerController(value: DateTime(2035, 9));
    late StateSetter rebuild;
    var controller = first;
    var minimumYear = 2020;
    var maximumYear = 2030;
    var shrinkWrap = false;
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    await pumpExtensionAtSize(
      tester,
      size: const Size(420, 500),
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return Scaffold(
            body: MiuixYearPicker(
              controller: controller,
              minimumYear: minimumYear,
              maximumYear: maximumYear,
              height: 70,
              shrinkWrap: shrinkWrap,
              glass: false,
            ),
          );
        },
      ),
    );
    expect(find.text('2028'), findsOneWidget);

    rebuild(() => controller = second);
    await tester.pumpAndSettle();
    expect(second.value, DateTime(2030, 9));
    expect(find.text('2030'), findsOneWidget);

    first.value = DateTime(2021, 1);
    await tester.pump();
    expect(second.value, DateTime(2030, 9));

    rebuild(() {
      minimumYear = 2025;
      maximumYear = 2027;
      shrinkWrap = true;
    });
    await tester.pumpAndSettle();
    expect(second.value, DateTime(2027, 9));
    expect(find.text('2027'), findsOneWidget);

    rebuild(() => shrinkWrap = false);
    await tester.pumpAndSettle();
    final pickerRect = tester.getRect(find.byType(MiuixYearPicker));
    expect(pickerRect.contains(tester.getCenter(find.text('2027'))), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shrink-wrapped year picker delegates vertical drag to parent', (
    tester,
  ) async {
    final controller = MiuixMonthPickerController(value: DateTime(2026, 8));
    final parent = ScrollController();
    addTearDown(parent.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(420, 700),
      child: Scaffold(
        body: ListView(
          controller: parent,
          children: <Widget>[
            const SizedBox(height: 400),
            MiuixYearPicker(
              controller: controller,
              minimumYear: 2020,
              maximumYear: 2032,
              shrinkWrap: true,
            ),
            const SizedBox(height: 600),
          ],
        ),
      ),
    );

    final yearGrid = tester.widget<GridView>(find.byType(GridView));
    expect(yearGrid.shrinkWrap, isTrue);
    expect(yearGrid.physics, isA<NeverScrollableScrollPhysics>());
    await tester.drag(find.text('2026'), const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(parent.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('week calendar and agenda render interactive schedule data', (
    tester,
  ) async {
    final controller = MiuixWeekCalendarController(
      selectedDate: DateTime(2026, 8, 10),
    );
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 800),
      child: Scaffold(
        body: Column(
          children: <Widget>[
            MiuixWeekCalendar(controller: controller),
            MiuixAgendaView(
              items: <MiuixAgendaItem>[
                MiuixAgendaItem(
                  date: DateTime(2026, 8, 10, 9),
                  title: 'Meeting',
                  subtitle: 'Room A',
                ),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Meeting'), findsOneWidget);
    expect(find.text('Room A'), findsOneWidget);
    final agendaList = tester.widget<ListView>(find.byType(ListView));
    expect(agendaList.padding, EdgeInsets.zero);
    expect(agendaList.primary, isFalse);
    await tester.tap(find.text('11'));
    await tester.pump();
    expect(controller.selectedDate, DateTime(2026, 8, 11));
  });

  testWidgets('week calendar normalizes weekday and owns locale arrow keys', (
    tester,
  ) async {
    final controller = MiuixWeekCalendarController(
      selectedDate: DateTime(2026, 8, 10),
    );
    addTearDown(controller.dispose);
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 500),
      child: Scaffold(
        body: MiuixWeekCalendar(
          controller: controller,
          firstWeekday: 99,
          selectableDayPredicate: (date) => date.day != 11,
        ),
      ),
    );

    expect(controller.weekStart(99), DateTime(2026, 8, 10));
    await tester.tap(find.text('10'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(controller.selectedDate, DateTime(2026, 8, 10));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.selectedDate, DateTime(2026, 8, 17));
    expect(tester.takeException(), isNull);
  });

  testWidgets('range dialog returns a controller value on confirm', (
    tester,
  ) async {
    MiuixDateRange? result;
    await pumpExtensionAtSize(
      tester,
      size: const Size(500, 900),
      child: Builder(
        builder: (context) => MiuixButton(
          label: 'Open',
          onPressed: () {
            unawaited(
              MiuixDateRangePicker.show(
                context: context,
                initialRange: MiuixDateRange(
                  DateTime(2026, 8, 10),
                  DateTime(2026, 8, 12),
                ),
              ).then((value) => result = value),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final okLabel = MaterialLocalizations.of(
      tester.element(find.byType(MiuixDialog)),
    ).okButtonLabel;
    final confirm = tester.widget<MiuixButton>(
      find.widgetWithText(MiuixButton, okLabel),
    );
    confirm.onPressed!();
    confirm.onPressed!();
    await tester.pumpAndSettle();
    expect(result?.start, DateTime(2026, 8, 10));
    expect(result?.end, DateTime(2026, 8, 12));
  });
}
