import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

String _formatDialPercent(double value) => '${value.round()}%';

Future<void> pumpExtensionSurface(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MiuixTheme(
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 420, child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('skeleton and shimmer render with reduced-motion support', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Row(
          children: <Widget>[
            MiuixSkeleton(width: 100, height: 20),
            MiuixShimmer(width: 32, height: 32, shape: BoxShape.circle),
          ],
        ),
      ),
    );

    expect(find.byType(MiuixSkeleton), findsOneWidget);
    expect(find.byType(MiuixShimmer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('skeleton normalizes invalid geometry and duration', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const MiuixSkeleton(
        width: double.nan,
        height: double.negativeInfinity,
        cornerRadius: double.infinity,
        duration: Duration(microseconds: -1),
      ),
    );

    final skeleton = find.byType(MiuixSkeleton);
    final container = tester.widget<Container>(
      find.descendant(of: skeleton, matching: find.byType(Container)),
    );
    expect(container.constraints!.maxWidth, 0);
    expect(container.constraints!.maxHeight, 0);
    final animation = tester.widget<AnimatedBuilder>(
      find.descendant(of: skeleton, matching: find.byType(AnimatedBuilder)),
    );
    expect(
      (animation.animation as AnimationController).duration,
      Duration.zero,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'skeleton tokenizes traversal and freezes a stable reduced frame',
    (tester) async {
      final reduceMotion = ValueNotifier<bool>(false);
      addTearDown(reduceMotion.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, reduced, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
              child: MiuixTheme(
                data: MiuixThemeData.defaults().copyWith(
                  hyperOs4: const MiuixHyperOs4Tokens(
                    skeletonMotion: Duration(milliseconds: 2777),
                  ),
                ),
                child: const MiuixSkeleton(width: 120, height: 24),
              ),
            ),
          ),
        ),
      );

      AnimationController controller() =>
          tester
                  .widget<AnimatedBuilder>(
                    find.descendant(
                      of: find.byType(MiuixSkeleton),
                      matching: find.byType(AnimatedBuilder),
                    ),
                  )
                  .animation
              as AnimationController;

      expect(controller().duration, const Duration(milliseconds: 2777));
      expect(controller().isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 321));
      expect(controller().value, inExclusiveRange(0, .5));

      reduceMotion.value = true;
      await tester.pump();
      expect(controller().isAnimating, isFalse);
      expect(controller().value, .5);
    },
  );

  testWidgets('skeleton shape follows HyperOS tokens and source stays fixed', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(skeletonCornerRadius: 23),
        ),
        child: const Row(
          children: <Widget>[
            MiuixSkeleton(
              key: ValueKey('token-skeleton'),
              width: 80,
              height: 24,
            ),
            MiuixShimmer.source(
              key: ValueKey('source-shimmer'),
              width: 80,
              height: 24,
            ),
          ],
        ),
      ),
    );

    BorderRadius radiusOf(Key key) {
      final container = tester.widget<Container>(
        find.descendant(of: find.byKey(key), matching: find.byType(Container)),
      );
      return (container.decoration! as BoxDecoration).borderRadius!
          as BorderRadius;
    }

    expect(radiusOf(const ValueKey('token-skeleton')).topLeft.x, 23);
    expect(
      radiusOf(const ValueKey('source-shimmer')).topLeft.x,
      MiuixSkeletonDefaults.cornerRadius,
    );
  });

  testWidgets('empty-state view and list section expose public composition', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiuixEmptyStateView(
            title: 'No results',
            type: MiuixEmptyStateType.noResults,
          ),
          MiuixListSection(
            title: 'Section',
            children: <Widget>[SizedBox(height: 44), SizedBox(height: 44)],
          ),
        ],
      ),
    );

    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Section'), findsOneWidget);
    expect(find.byType(Divider), findsOneWidget);
  });

  testWidgets('list section uses grouped shape and content glass tokens', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            settingsGroupCornerRadius: 25,
            contentSurfaceBlur: 34,
            contentSurfaceTintOpacity: .43,
          ),
        ),
        child: const MiuixListSection(children: <Widget>[SizedBox(height: 44)]),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-list-section-surface')),
    );
    expect(surface.radius, 25);
    expect(surface.glass, isTrue);
    expect(surface.glassBlur, 34);
    expect(surface.glassOpacity, .43);
    expect(surface.showGlassSpecular, isTrue);
  });

  testWidgets('list section separates solid overrides and source groups', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const MiuixListSection(
        glass: false,
        glassBlur: 37,
        glassOpacity: .31,
        showGlassSpecular: false,
        cornerRadius: 29,
        children: <Widget>[SizedBox(height: 44)],
      ),
    );
    var surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-list-section-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.glassBlur, 37);
    expect(surface.glassOpacity, .31);
    expect(surface.showGlassSpecular, isFalse);
    expect(surface.radius, 29);

    await pumpExtensionSurface(
      tester,
      const MiuixListSection.source(children: <Widget>[SizedBox(height: 44)]),
    );
    surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-list-section-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.showGlassSpecular, isFalse);
    expect(surface.radius, MiuixListSectionDefaults.cornerRadius);
  });

  testWidgets('empty-state glass uses inline material tokens and tint', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            emptyStateMaximumWidth: 377,
            emptyStatePadding: 29,
            emptyStateIconSize: 71,
            emptyStateTitleSpacing: 17,
            emptyStateMessageSpacing: 9,
            emptyStateActionSpacing: 21,
            inlineSurfaceBlur: 33,
            inlineSurfaceTintOpacity: .41,
            inlineSurfaceCornerRadius: 26,
          ),
        ),
        child: const MiuixEmptyStateView(
          title: 'No files',
          message: 'Try another folder',
          primaryAction: SizedBox(width: 80, height: 32),
          glass: true,
          glassColor: Color(0xFF556677),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-empty-state-glass')),
    );
    expect(surface.glass, isTrue);
    expect(surface.glassBlur, 33);
    expect(surface.glassOpacity, .41);
    expect(surface.radius, 26);
    expect(surface.color, const Color(0xFF556677));
    final constraints = tester
        .widgetList<ConstrainedBox>(
          find.descendant(
            of: find.byType(MiuixEmptyStateView),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .firstWhere((box) => box.constraints.maxWidth == 377);
    final iconTheme = tester
        .widgetList<IconTheme>(
          find.descendant(
            of: find.byType(MiuixEmptyStateView),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 71);
    expect(constraints.constraints.maxWidth, 377);
    expect(iconTheme.data.size, 71);
  });

  testWidgets('context menu returns a typed action', (tester) async {
    String? result;
    await pumpExtensionSurface(
      tester,
      Builder(
        builder: (context) => MiuixButton(
          label: 'Open',
          onPressed: () async {
            result = await MiuixContextMenu.show<String>(
              context: context,
              position: const Offset(40, 40),
              items: const <MiuixContextMenuItem<String>>[
                MiuixContextMenuItem(value: 'copy', label: 'Copy'),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Copy'), findsOneWidget);
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(result, 'copy');
  });

  testWidgets('context menu uses its motion token and reduced endpoint', (
    tester,
  ) async {
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(reduceMotion.dispose);

    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: reduceMotion,
        builder: (context, reduced, child) => MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData().copyWith(disableAnimations: reduced),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  contextMenuMotion: Duration(milliseconds: 777),
                ),
              ),
              child: Builder(
                builder: (context) => Scaffold(
                  body: MiuixButton(
                    label: 'Open timed menu',
                    onPressed: () => MiuixContextMenu.show<String>(
                      context: context,
                      position: const Offset(40, 40),
                      items: const <MiuixContextMenuItem<String>>[
                        MiuixContextMenuItem(
                          value: 'copy',
                          label: 'Timed copy',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    double menuOpacity() {
      final fade = tester.widget<FadeTransition>(
        find.ancestor(
          of: find.text('Timed copy'),
          matching: find.byType(FadeTransition),
        ),
      );
      return fade.opacity.value;
    }

    await tester.tap(find.text('Open timed menu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(menuOpacity(), inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      menuOpacity(),
      lessThan(1),
      reason: 'the custom 777ms token must outlive the former 260ms clock',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Timed copy'));
    await tester.pumpAndSettle();

    reduceMotion.value = true;
    await tester.pump();
    await tester.tap(find.text('Open timed menu'));
    await tester.pump();
    expect(menuOpacity(), 1);
  });

  testWidgets(
    'context menu uses popup glass and content-fitting token geometry',
    (tester) async {
      const shortItems = <MiuixContextMenuItem<String>>[
        MiuixContextMenuItem(value: 'copy', label: 'Copy'),
        MiuixContextMenuItem(
          value: 'delete',
          label: 'Delete',
          separatorBefore: true,
        ),
      ];
      const longItems = <MiuixContextMenuItem<String>>[
        MiuixContextMenuItem(
          value: 'long',
          label: 'A context action whose authored label exceeds the width cap',
        ),
      ];

      Future<void> pumpItems(List<MiuixContextMenuItem<String>> items) {
        return tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  popupBlur: 31,
                  popupTintOpacity: .44,
                  popupCornerRadius: 26,
                  contextMenuMinWidth: 211,
                  contextMenuMaxWidth: 277,
                  contextMenuItemHeight: 53,
                  contextMenuHorizontalPadding: 17,
                  contextMenuIconSpacing: 13,
                  contextMenuVerticalPadding: 7,
                  contextMenuShadowElevation: 9,
                ),
              ),
              child: Center(
                child: MiuixContextMenu<String>(
                  items: items,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        );
      }

      await pumpItems(shortItems);
      final shortSurface = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-context-menu-surface')),
      );
      expect(shortSurface.glass, isTrue);
      expect(shortSurface.glassBlur, 31);
      expect(shortSurface.glassOpacity, .44);
      expect(shortSurface.glassOptics, same(MiuixGlassOptics.transient));
      expect(shortSurface.radius, 26);
      expect(shortSurface.shadowElevation, 9);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('miuix-context-menu-surface')))
            .width,
        211,
      );
      expect(tester.getRect(find.text('Copy')).height, lessThanOrEqualTo(53));
      final divider = tester.getRect(find.byType(Divider));
      final panel = tester.getRect(
        find.byKey(const ValueKey('miuix-context-menu-surface')),
      );
      expect(divider.left - panel.left, 17);
      expect(panel.right - divider.right, 17);

      await pumpItems(longItems);
      expect(
        tester
            .getSize(find.byKey(const ValueKey('miuix-context-menu-surface')))
            .width,
        277,
      );
    },
  );

  testWidgets('source context menu retains fixed opaque legacy geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixContextMenu<String>.source(
              items: const <MiuixContextMenuItem<String>>[
                MiuixContextMenuItem(value: 'copy', label: 'Copy'),
                MiuixContextMenuItem(
                  value: 'delete',
                  label: 'Delete',
                  separatorBefore: true,
                ),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-context-menu-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.radius, 18);
    expect(surface.shadowElevation, 14);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-context-menu-surface')))
          .width,
      220,
    );
    final divider = tester.getRect(find.byType(Divider));
    final panel = tester.getRect(
      find.byKey(const ValueKey('miuix-context-menu-surface')),
    );
    expect(divider.left, panel.left);
    expect(divider.right, panel.right);
  });

  testWidgets('source context region and controller open the legacy route', (
    tester,
  ) async {
    final controller = MiuixContextMenuController();
    addTearDown(controller.dispose);
    await pumpExtensionSurface(
      tester,
      MiuixContextMenuRegion<String>(
        controller: controller,
        sourceStyle: true,
        items: const <MiuixContextMenuItem<String>>[
          MiuixContextMenuItem(value: 'copy', label: 'Legacy copy'),
        ],
        child: const SizedBox(
          width: 180,
          height: 72,
          child: Center(child: Text('Hold legacy region')),
        ),
      ),
    );

    await tester.longPress(find.text('Hold legacy region'));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-context-menu-surface')),
    );
    expect(surface.glass, isFalse);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-context-menu-surface')))
          .width,
      220,
    );

    await tester.tap(find.text('Legacy copy'));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
  });

  testWidgets('context controller closes the root menu from a nested route', (
    tester,
  ) async {
    final controller = MiuixContextMenuController();
    addTearDown(controller.dispose);
    late BuildContext nestedPageContext;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (context) => Center(
                child: MiuixButton(
                  label: 'Enter nested page',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) {
                        nestedPageContext = context;
                        return Scaffold(
                          body: Center(
                            child: MiuixButton(
                              label: 'Open nested context menu',
                              onPressed: () => unawaited(
                                controller.show<String>(
                                  context: context,
                                  position: const Offset(120, 180),
                                  items: const [
                                    MiuixContextMenuItem(
                                      value: 'nested',
                                      label: 'Nested action',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Enter nested page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open nested context menu'));
    await tester.pumpAndSettle();
    expect(find.text('Nested action'), findsOneWidget);

    controller.close(nestedPageContext);
    await tester.pumpAndSettle();

    expect(find.text('Nested action'), findsNothing);
    expect(find.text('Open nested context menu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('context controller may be disposed before its menu completes', (
    tester,
  ) async {
    final controller = MiuixContextMenuController();
    await pumpExtensionSurface(
      tester,
      Builder(
        builder: (context) => MiuixButton(
          label: 'Open dispose',
          onPressed: () => unawaited(
            controller.show<String>(
              context: context,
              position: const Offset(80, 120),
              items: const [
                MiuixContextMenuItem(
                  value: 'dispose',
                  label: 'Done after dispose',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open dispose'));
    await tester.pumpAndSettle();
    controller.dispose();
    await tester.tap(find.text('Done after dispose'));
    await tester.pumpAndSettle();

    expect(find.text('Done after dispose'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposed context region does not publish a late selection', (
    tester,
  ) async {
    late StateSetter rebuildHost;
    var showRegion = true;
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Scaffold(
                body: showRegion
                    ? MiuixContextMenuRegion<String>(
                        items: const [
                          MiuixContextMenuItem(
                            value: 'late',
                            label: 'Late region action',
                          ),
                        ],
                        onSelected: (_) => selected = true,
                        child: const SizedBox(
                          width: 180,
                          height: 72,
                          child: Center(child: Text('Disposable region')),
                        ),
                      )
                    : const Center(child: Text('Region removed')),
              );
            },
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Disposable region'));
    await tester.pumpAndSettle();
    rebuildHost(() => showRegion = false);
    await tester.pump();
    await tester.tap(find.text('Late region action'));
    await tester.pumpAndSettle();

    expect(selected, isFalse);
    expect(find.text('Region removed'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rebuilt context region rejects a stale menu selection', (
    tester,
  ) async {
    late StateSetter rebuildHost;
    var items = const <MiuixContextMenuItem<String>>[
      MiuixContextMenuItem(value: 'old', label: 'Stale region action'),
    ];
    var selected = '';
    ValueChanged<String> handler = (value) => selected = 'old:$value';
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Scaffold(
                body: MiuixContextMenuRegion<String>(
                  items: items,
                  onSelected: handler,
                  child: const SizedBox(
                    width: 180,
                    height: 72,
                    child: Center(child: Text('Rebuilt region')),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.longPress(find.text('Rebuilt region'));
    await tester.pumpAndSettle();

    rebuildHost(() {
      items = const [
        MiuixContextMenuItem(value: 'new', label: 'Current region action'),
      ];
      handler = (value) => selected = 'new:$value';
    });
    await tester.pump();
    await tester.tap(find.text('Stale region action'));
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'context menu uses final child size and scrolls inside the window',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 240);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Builder(
              builder: (context) => Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: MiuixButton(
                    label: 'Open',
                    onPressed: () => MiuixContextMenu.show<int>(
                      context: context,
                      position: const Offset(316, 236),
                      items: List<MiuixContextMenuItem<int>>.generate(
                        10,
                        (index) => MiuixContextMenuItem<int>(
                          value: index,
                          label: 'Action $index',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final panel = tester.getRect(
        find.byKey(const ValueKey('miuix-context-menu-surface')),
      );
      expect(panel.left, greaterThanOrEqualTo(12));
      expect(panel.top, greaterThanOrEqualTo(12));
      expect(panel.right, lessThanOrEqualTo(308));
      expect(panel.bottom, lessThanOrEqualTo(228));
      expect(panel.height, 216);
      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byKey(const ValueKey('miuix-context-menu-scroll')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(scrollable.position.maxScrollExtent, greaterThan(0));
    },
  );

  testWidgets('swipe action controller reveals equal-width actions', (
    tester,
  ) async {
    final controller = MiuixSwipeActionController();
    await pumpExtensionSurface(
      tester,
      MiuixSwipeAction(
        controller: controller,
        startActions: <MiuixSwipeActionItem>[
          MiuixSwipeActionItem(
            label: 'Pin',
            backgroundColor: Colors.blue,
            onPressed: () {},
          ),
          MiuixSwipeActionItem(
            label: 'Read',
            backgroundColor: Colors.green,
            onPressed: () {},
          ),
        ],
        child: const SizedBox(
          height: 72,
          child: Center(child: Text('Message')),
        ),
      ),
    );

    controller.openStart();
    await tester.pumpAndSettle();
    expect(controller.side, MiuixSwipeActionSide.start);
    expect(
      tester
          .getSize(
            find
                .ancestor(of: find.text('Pin'), matching: find.byType(SizedBox))
                .first,
          )
          .width,
      MiuixSwipeActionDefaults.actionExtent,
    );
  });

  testWidgets(
    'swipe action retargets changed geometry and closes when disabled',
    (tester) async {
      final controller = MiuixSwipeActionController();
      var enabled = true;
      var actionCount = 2;
      var actionExtent = 76.0;
      var presses = 0;
      late StateSetter rebuild;
      addTearDown(controller.dispose);
      await pumpExtensionSurface(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MiuixSwipeAction(
              controller: controller,
              enabled: enabled,
              actionExtent: actionExtent,
              startActions: List<MiuixSwipeActionItem>.generate(
                actionCount,
                (index) => MiuixSwipeActionItem(
                  label: 'Action $index',
                  backgroundColor: Colors.blue,
                  onPressed: () => presses++,
                ),
              ),
              child: const SizedBox(
                height: 72,
                child: Center(child: Text('Dynamic message')),
              ),
            );
          },
        ),
      );

      double foregroundX() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('miuix-swipe-action-foreground')),
          )
          .transform
          .storage[12];

      controller.openStart();
      await tester.pumpAndSettle();
      expect(foregroundX(), closeTo(152, 1e-9));

      rebuild(() {
        actionCount = 1;
        actionExtent = 90;
      });
      await tester.pumpAndSettle();
      expect(controller.side, MiuixSwipeActionSide.start);
      expect(foregroundX(), closeTo(90, 1e-9));

      rebuild(() => enabled = false);
      await tester.pumpAndSettle();
      expect(controller.side, MiuixSwipeActionSide.closed);
      expect(foregroundX(), closeTo(0, 1e-9));
      final disabledAction = tester.widget<MiuixSurface>(
        find
            .ancestor(
              of: find.text('Action 0'),
              matching: find.byType(MiuixSurface),
            )
            .first,
      );
      expect(disabledAction.enabled, isFalse);
      expect(disabledAction.onTap, isNull);
      expect(presses, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('swipe action uses collection geometry and squircle shape', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 24),
        ),
        child: const MiuixSwipeAction(
          child: SizedBox(height: 64, child: Text('Theme swipe')),
        ),
      ),
    );

    final clip = tester.widget<ClipPath>(
      find.byKey(const ValueKey('miuix-swipe-action-clip')),
    );
    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-swipe-action-foreground-surface')),
    );
    expect(
      (clip.clipper! as ShapeBorderClipper).shape,
      isA<MiuixSquircleBorder>(),
    );
    expect(surface.shape, isA<MiuixSquircleBorder>());
    expect(surface.radius, 24);
  });

  testWidgets('swipe action source keeps the former rounded 18dp path', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 24),
        ),
        child: const MiuixSwipeAction.source(
          child: SizedBox(height: 64, child: Text('Source swipe')),
        ),
      ),
    );

    final clip = tester.widget<ClipPath>(
      find.byKey(const ValueKey('miuix-swipe-action-clip')),
    );
    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-swipe-action-foreground-surface')),
    );
    expect(
      (clip.clipper! as ShapeBorderClipper).shape,
      isA<RoundedRectangleBorder>(),
    );
    expect(surface.radius, MiuixSwipeActionDefaults.cornerRadius);
  });

  testWidgets('swipe action normalizes malformed Release action extent', (
    tester,
  ) async {
    final controller = MiuixSwipeActionController();
    addTearDown(controller.dispose);
    await pumpExtensionSurface(
      tester,
      MiuixSwipeAction(
        controller: controller,
        actionExtent: double.nan,
        startActions: <MiuixSwipeActionItem>[
          MiuixSwipeActionItem(backgroundColor: Colors.blue, onPressed: () {}),
        ],
        child: const SizedBox(height: 72, child: Text('Safe swipe')),
      ),
    );

    controller.openStart();
    await tester.pumpAndSettle();
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-swipe-action-foreground')),
    );
    expect(
      transform.transform.storage[12],
      MiuixSwipeActionDefaults.actionExtent,
    );
    expect(controller.side, MiuixSwipeActionSide.start);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe action owns horizontal drag above a page view', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    await pumpExtensionSurface(
      tester,
      PageView(
        controller: pageController,
        children: <Widget>[
          Center(
            child: MiuixSwipeAction(
              endActions: <MiuixSwipeActionItem>[
                MiuixSwipeActionItem(
                  label: 'Archive',
                  backgroundColor: Colors.blue,
                  onPressed: () {},
                ),
              ],
              child: const SizedBox(
                height: 72,
                child: Center(child: Text('Swipe message')),
              ),
            ),
          ),
          const Center(child: Text('Next page')),
        ],
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Swipe message')),
    );
    // Physical streams cross touch slop through several move samples. Using
    // the same path here proves the nested recognizers' arena ownership rather
    // than relying on a synthetic one-event teleport.
    for (var index = 0; index < 6; index++) {
      await gesture.moveBy(const Offset(-10, 0));
      await tester.pump();
    }
    final foreground = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-swipe-action-foreground')),
    );
    expect(foreground.transform.storage[12], closeTo(-60, 1e-9));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pageController.page, closeTo(0, .001));
  });

  testWidgets(
    'swipe action reduced motion snaps settle but keeps direct drag',
    (tester) async {
      final controller = MiuixSwipeActionController();
      final reduceMotion = ValueNotifier<bool>(false);
      final settled = <MiuixSwipeActionSide>[];
      addTearDown(controller.dispose);
      addTearDown(reduceMotion.dispose);
      await pumpExtensionSurface(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, reduced, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  swipeActionMotion: Duration(milliseconds: 777),
                ),
              ),
              child: MiuixSwipeAction(
                controller: controller,
                onSideChanged: settled.add,
                startActions: <MiuixSwipeActionItem>[
                  MiuixSwipeActionItem(
                    label: 'Archive',
                    backgroundColor: Colors.blue,
                    onPressed: () {},
                  ),
                ],
                child: const SizedBox(
                  height: 72,
                  child: Center(child: Text('Reduced message')),
                ),
              ),
            ),
          ),
        ),
      );

      double foregroundX() => tester
          .widget<Transform>(
            find.byKey(const ValueKey('miuix-swipe-action-foreground')),
          )
          .transform
          .storage[12];

      controller.openStart();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(foregroundX(), inExclusiveRange(0, 76));
      await tester.pump(const Duration(milliseconds: 250));
      expect(
        foregroundX(),
        inExclusiveRange(0, 76),
        reason: 'the custom 777ms token must outlive the former 320ms clock',
      );

      reduceMotion.value = true;
      await tester.pump();
      await tester.pump();
      expect(foregroundX(), closeTo(76, 1e-9));
      expect(settled, <MiuixSwipeActionSide>[MiuixSwipeActionSide.start]);

      controller.close();
      await tester.pump();
      expect(foregroundX(), closeTo(0, 1e-9));
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Reduced message')),
      );
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      expect(foregroundX(), closeTo(30, 1e-9));
      await gesture.up();
      await tester.pump();
      expect(foregroundX(), closeTo(0, 1e-9));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rating accepts drag input and publishes a half step', (
    tester,
  ) async {
    final controller = MiuixRatingController();
    await pumpExtensionSurface(
      tester,
      MiuixRating(controller: controller, allowHalf: true),
    );

    final gesture = find.descendant(
      of: find.byType(MiuixRating),
      matching: find.byType(GestureDetector),
    );
    final box = tester.getRect(gesture);
    await tester.tapAt(Offset(box.left + box.width * .5, box.center.dy));
    await tester.pump();
    expect(controller.value, 2.5);
  });

  testWidgets('rating owns enabled drag and yields disabled drag to a pager', (
    tester,
  ) async {
    Future<PageController> pumpRating({required bool enabled}) async {
      final pageController = PageController();
      await pumpExtensionSurface(
        tester,
        PageView(
          controller: pageController,
          children: <Widget>[
            Center(child: MiuixRating(enabled: enabled, initialValue: 4)),
            const Center(child: Text('Rating next page')),
          ],
        ),
      );
      return pageController;
    }

    final enabledPager = await pumpRating(enabled: true);
    Finder ratingTarget() => find.descendant(
      of: find.byType(MiuixRating),
      matching: find.byType(GestureDetector),
    );
    await tester.drag(ratingTarget(), const Offset(-180, 0));
    await tester.pumpAndSettle();
    expect(enabledPager.page, closeTo(0, .001));
    enabledPager.dispose();

    final disabledPager = await pumpRating(enabled: false);
    addTearDown(disabledPager.dispose);
    await tester.drag(ratingTarget(), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(disabledPager.page, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('rating fill uses selection motion and reduced endpoint', (
    tester,
  ) async {
    final controller = MiuixRatingController();
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(controller.dispose);
    addTearDown(reduceMotion.dispose);
    await pumpExtensionSurface(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: reduceMotion,
        builder: (context, reduced, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                selectionControlMotion: Duration(milliseconds: 777),
              ),
            ),
            child: MiuixRating(controller: controller, allowHalf: true),
          ),
        ),
      ),
    );

    final motions = find.descendant(
      of: find.byType(MiuixRating),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(motions, findsNWidgets(MiuixRatingDefaults.itemCount));
    expect(
      tester
          .widgetList<TweenAnimationBuilder<double>>(motions)
          .every(
            (animation) =>
                animation.duration == const Duration(milliseconds: 777),
          ),
      isTrue,
    );

    Rect firstFillClip() {
      final clip = tester.widget<ClipRect>(
        find
            .descendant(
              of: find.byType(MiuixRating),
              matching: find.byType(ClipRect),
            )
            .first,
      );
      return clip.clipper!.getClip(
        const Size.square(MiuixRatingDefaults.itemSize),
      );
    }

    controller.value = 2.5;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      firstFillClip().width,
      inExclusiveRange(0, MiuixRatingDefaults.itemSize),
    );

    // Runtime reduced motion replaces the animated fill with the controller's
    // already published logical endpoint; it does not wait out the old clock.
    reduceMotion.value = true;
    await tester.pump();
    expect(firstFillClip().width, MiuixRatingDefaults.itemSize);
    expect(
      tester
          .widgetList<TweenAnimationBuilder<double>>(motions)
          .every((animation) => animation.duration == Duration.zero),
      isTrue,
    );
  });

  testWidgets('dial animates a discrete controlled value', (tester) async {
    final controller = MiuixDialController(value: 50);
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            selectionControlMotion: Duration(milliseconds: 777),
          ),
        ),
        child: MiuixDial(controller: controller, divisions: 10),
      ),
    );

    expect(find.text('50'), findsOneWidget);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.descendant(
              of: find.byType(MiuixDial),
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          )
          .duration,
      const Duration(milliseconds: 777),
    );
    controller.value = 80;
    await tester.pump();
    expect(find.text('50'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    final intermediateLabel = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(MiuixDial),
            matching: find.byType(Text),
          ),
        )
        .single
        .data!;
    expect(double.parse(intermediateLabel), inExclusiveRange(50, 80));
    await tester.pumpAndSettle();
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('disabled dial yields horizontal drag without settled callback', (
    tester,
  ) async {
    final pageController = PageController();
    var settledCount = 0;
    addTearDown(pageController.dispose);
    await pumpExtensionSurface(
      tester,
      PageView(
        controller: pageController,
        children: <Widget>[
          Center(
            child: MiuixDial(
              enabled: false,
              onChangeEnd: (_) => settledCount++,
            ),
          ),
          const Center(child: Text('Dial next page')),
        ],
      ),
    );

    await tester.drag(find.byType(MiuixDial), const Offset(-240, 0));
    await tester.pumpAndSettle();

    expect(pageController.page, closeTo(1, .001));
    expect(settledCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dial reduced motion snaps a programmatic value change', (
    tester,
  ) async {
    final controller = MiuixDialController(value: 20);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                selectionControlMotion: Duration(milliseconds: 777),
              ),
            ),
            child: Scaffold(body: MiuixDial(controller: controller)),
          ),
        ),
      ),
    );
    await tester.pump();
    controller.value = 90;
    await tester.pump();
    expect(find.text('90'), findsOneWidget);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.descendant(
              of: find.byType(MiuixDial),
              matching: find.byType(TweenAnimationBuilder<double>),
            ),
          )
          .duration,
      Duration.zero,
    );
  });

  testWidgets('dial exposes one formatted slider value without label echo', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpExtensionSurface(
      tester,
      const MiuixDial(
        value: 55,
        divisions: 20,
        semanticLabel: '音量',
        semanticValueFormatter: _formatDialPercent,
      ),
    );

    final node = tester.getSemantics(find.byType(MiuixDial));
    expect(node.label, '音量');
    expect(node.value, '55%');
    expect(node.childrenCountInTraversalOrder, 0);
    semantics.dispose();
  });

  testWidgets('rating normalizes malformed Release geometry and value', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = MiuixRatingController(value: 3);
    addTearDown(controller.dispose);
    await pumpExtensionSurface(
      tester,
      MiuixRating(
        controller: controller,
        value: double.nan,
        itemCount: -2,
        itemSize: double.infinity,
        spacing: -4,
      ),
    );

    final target = find.descendant(
      of: find.byType(MiuixRating),
      matching: find.byType(GestureDetector),
    );
    expect(
      tester.getSize(target),
      const Size(
        MiuixRatingDefaults.itemCount * MiuixRatingDefaults.itemSize +
            (MiuixRatingDefaults.itemCount - 1) * MiuixRatingDefaults.spacing,
        MiuixRatingDefaults.itemSize,
      ),
    );
    expect(tester.getSemantics(find.byType(MiuixRating)).value, '3.0');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('dial sorts malformed bounds and falls back to safe geometry', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final controller = MiuixDialController(value: 25);
    addTearDown(controller.dispose);
    await pumpExtensionSurface(
      tester,
      Align(
        child: MiuixDial(
          controller: controller,
          value: double.nan,
          minimum: 100,
          maximum: 0,
          divisions: 0,
          size: double.nan,
          trackWidth: double.infinity,
        ),
      ),
    );

    expect(
      tester.getSize(
        find.descendant(
          of: find.byType(MiuixDial),
          matching: find.byType(CustomPaint),
        ),
      ),
      const Size.square(MiuixDialDefaults.size),
    );
    final node = tester.getSemantics(find.byType(MiuixDial));
    expect(node.value, '25.0');
    expect(node.increasedValue, '30.0');
    expect(node.decreasedValue, '20.0');
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('timeline supports vertical milestones', (tester) async {
    await pumpExtensionSurface(
      tester,
      const MiuixTimeline(
        items: <MiuixTimelineItem>[
          MiuixTimelineItem(
            title: 'Ordered',
            state: MiuixTimelineItemState.completed,
          ),
          MiuixTimelineItem(
            title: 'Shipped',
            state: MiuixTimelineItemState.current,
          ),
        ],
      ),
    );

    expect(find.text('Ordered'), findsOneWidget);
    expect(find.text('Shipped'), findsOneWidget);
    final timelineList = tester.widget<ListView>(find.byType(ListView));
    expect(timelineList.padding, EdgeInsets.zero);
    expect(timelineList.primary, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline geometry follows HyperOS tokens in horizontal mode', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            timelineMarkerExtent: 30,
            timelineConnectorWidth: 5,
            timelineHorizontalItemWidth: 212,
          ),
        ),
        child: const MiuixTimeline(
          orientation: MiuixTimelineOrientation.horizontal,
          items: <MiuixTimelineItem>[
            MiuixTimelineItem(
              title: 'Started',
              state: MiuixTimelineItemState.completed,
            ),
            MiuixTimelineItem(
              title: 'Running',
              state: MiuixTimelineItemState.current,
            ),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<Object>(('miuix-timeline-marker', 0))),
      ),
      const Size.square(30),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<Object>(('miuix-timeline-item', 0))),
          )
          .width,
      212,
    );
    expect(
      tester
          .getSize(
            find.byKey(
              const ValueKey<Object>(('miuix-timeline-connector-after', 0)),
            ),
          )
          .height,
      5,
    );
  });

  testWidgets('timeline source retains former fixed geometry', (tester) async {
    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            timelineMarkerExtent: 32,
            timelineConnectorWidth: 6,
            timelineHorizontalItemWidth: 220,
          ),
        ),
        child: const MiuixTimeline.source(
          orientation: MiuixTimelineOrientation.horizontal,
          items: <MiuixTimelineItem>[
            MiuixTimelineItem(title: 'One'),
            MiuixTimelineItem(title: 'Two'),
          ],
        ),
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<Object>(('miuix-timeline-marker', 0))),
      ),
      const Size.square(MiuixTimelineDefaults.markerExtent),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<Object>(('miuix-timeline-item', 0))),
          )
          .width,
      MiuixTimelineDefaults.horizontalItemWidth,
    );
  });

  testWidgets('timeline accepts zero explicit geometry without overflow', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const MiuixTimeline(
        orientation: MiuixTimelineOrientation.horizontal,
        markerExtent: 0,
        connectorWidth: 0,
        horizontalItemWidth: 0,
        items: <MiuixTimelineItem>[
          MiuixTimelineItem(title: 'Collapsed geometry'),
        ],
      ),
    );

    expect(
      tester.getSize(
        find.byKey(const ValueKey<Object>(('miuix-timeline-marker', 0))),
      ),
      Size.zero,
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<Object>(('miuix-timeline-item', 0))),
          )
          .width,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('timeline state shares process motion and reduced endpoint', (
    tester,
  ) async {
    final state = ValueNotifier<MiuixTimelineItemState>(
      MiuixTimelineItemState.upcoming,
    );
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(state.dispose);
    addTearDown(reduceMotion.dispose);
    const colors = MiuixTimelineColors(
      active: Colors.orange,
      completed: Colors.blue,
      upcoming: Colors.grey,
      error: Colors.red,
      foreground: Colors.black,
      secondaryForeground: Colors.black54,
    );
    await pumpExtensionSurface(
      tester,
      ValueListenableBuilder<bool>(
        valueListenable: reduceMotion,
        builder: (context, reduced, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                processStateMotion: Duration(milliseconds: 777),
              ),
            ),
            child: ValueListenableBuilder<MiuixTimelineItemState>(
              valueListenable: state,
              builder: (context, itemState, child) => MiuixTimeline(
                colors: colors,
                items: <MiuixTimelineItem>[
                  MiuixTimelineItem(title: 'Transfer', state: itemState),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final marker = find.byKey(
      const ValueKey<Object>(('miuix-timeline-marker', 0)),
    );
    Color markerColor() =>
        (tester.widget<Container>(marker).decoration! as BoxDecoration).color!;
    Finder stateMotion() => find.ancestor(
      of: marker,
      matching: find.byType(TweenAnimationBuilder<Color?>),
    );
    expect(markerColor(), Colors.grey);
    expect(
      tester.widget<TweenAnimationBuilder<Color?>>(stateMotion()).duration,
      const Duration(milliseconds: 777),
    );
    state.value = MiuixTimelineItemState.completed;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = markerColor();
    expect(intermediate, isNot(Colors.grey));
    expect(intermediate, isNot(Colors.blue));

    // A policy change replaces marker, connector, icon, and title transitions
    // together, exposing the model's current completed state immediately.
    reduceMotion.value = true;
    await tester.pump();
    expect(markerColor(), Colors.blue);
    expect(
      tester.widget<TweenAnimationBuilder<Color?>>(stateMotion()).duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.descendant(
              of: marker,
              matching: find.byType(AnimatedSwitcher),
            ),
          )
          .duration,
      Duration.zero,
    );
  });

  testWidgets('carousel updates its public controller after a swipe', (
    tester,
  ) async {
    final controller = MiuixCarouselController(viewportFraction: 1);
    await pumpExtensionSurface(
      tester,
      MiuixCarousel(
        controller: controller,
        height: 120,
        children: const <Widget>[
          ColoredBox(color: Colors.red, child: Text('One')),
          ColoredBox(color: Colors.blue, child: Text('Two')),
        ],
      ),
    );

    await tester.drag(find.byType(PageView), const Offset(-360, 0));
    await tester.pumpAndSettle();
    expect(controller.index, 1);
    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('looping carousel controller wraps across both edges', (
    tester,
  ) async {
    final controller = MiuixCarouselController(viewportFraction: 1);
    await pumpExtensionSurface(
      tester,
      MiuixCarousel(
        controller: controller,
        height: 120,
        loop: true,
        children: const <Widget>[
          ColoredBox(color: Colors.red, child: Text('One')),
          ColoredBox(color: Colors.blue, child: Text('Two')),
        ],
      ),
    );

    // A public controller must honor the widget's loop contract. This covers
    // programmatic navigation used by autoplay, keyboard, and desktop buttons.
    unawaited(controller.previous(duration: const Duration(milliseconds: 1)));
    await tester.pumpAndSettle();
    expect(controller.index, 1);

    unawaited(controller.next(duration: const Duration(milliseconds: 1)));
    await tester.pumpAndSettle();
    expect(controller.index, 0);
  });

  testWidgets('carousel applies a changed internal viewport fraction', (
    tester,
  ) async {
    var viewportFraction = .8;
    late StateSetter rebuildHost;
    await pumpExtensionSurface(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixCarousel(
            height: 120,
            viewportFraction: viewportFraction,
            children: const <Widget>[
              ColoredBox(color: Colors.red),
              ColoredBox(color: Colors.blue),
            ],
          );
        },
      ),
    );
    expect(
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .viewportFraction,
      .8,
    );

    rebuildHost(() => viewportFraction = .5);
    await tester.pump();

    expect(
      tester
          .widget<PageView>(find.byType(PageView))
          .controller!
          .viewportFraction,
      .5,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('carousel normalizes invalid controller and visual geometry', (
    tester,
  ) async {
    final controller = MiuixCarouselController(
      initialPage: -4,
      viewportFraction: double.nan,
    );
    addTearDown(controller.dispose);
    expect(controller.index, 0);
    expect(
      controller.pageController.viewportFraction,
      MiuixCarouselDefaults.viewportFraction,
    );

    await pumpExtensionSurface(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            pageIndicatorMotion: Duration(microseconds: -1),
          ),
        ),
        child: const MiuixCarousel(
          initialPage: 99,
          viewportFraction: double.infinity,
          height: double.nan,
          indicatorDotSize: 8,
          indicatorActiveWidth: 2,
          indicatorSpacing: 0,
          children: <Widget>[
            ColoredBox(color: Colors.red),
            ColoredBox(color: Colors.blue),
          ],
        ),
      ),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(
      pageView.controller!.viewportFraction,
      MiuixCarouselDefaults.viewportFraction,
    );
    expect(tester.getSize(find.byType(PageView)).height, 220);
    final indicatorFinder = find.descendant(
      of: find.byType(MiuixCarousel),
      matching: find.byType(AnimatedContainer),
    );
    final indicators = tester
        .widgetList<AnimatedContainer>(indicatorFinder)
        .toList();
    expect(
      List<double>.generate(
        indicators.length,
        (index) => tester.getSize(indicatorFinder.at(index)).width,
      ),
      everyElement(8),
    );
    expect(indicators.every((item) => item.duration == Duration.zero), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carousel returns from a removed page after data shrink', (
    tester,
  ) async {
    final controller = MiuixCarouselController(
      initialPage: 2,
      viewportFraction: 1,
    );
    addTearDown(controller.dispose);
    var pageCount = 3;
    var controllerNotifications = 0;
    final publishedPages = <int>[];
    controller.addListener(() => controllerNotifications++);
    late StateSetter rebuildHost;
    await pumpExtensionSurface(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          const pages = <Widget>[
            ColoredBox(color: Colors.red, child: Text('First page')),
            ColoredBox(color: Colors.blue, child: Text('Second page')),
            ColoredBox(color: Colors.green, child: Text('Third page')),
          ];
          return MiuixCarousel(
            controller: controller,
            height: 120,
            onPageChanged: publishedPages.add,
            children: pages.take(pageCount).toList(growable: false),
          );
        },
      ),
    );
    expect(controller.index, 2);
    controllerNotifications = 0;
    publishedPages.clear();

    rebuildHost(() => pageCount = 1);
    await tester.pump();
    await tester.pump();

    expect(controller.index, 0);
    expect(controller.pageController.page, closeTo(0, .001));
    expect(controllerNotifications, 1);
    expect(publishedPages, <int>[0]);
    expect(find.text('First page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty carousel resets and publishes its controller index', (
    tester,
  ) async {
    final controller = MiuixCarouselController(
      initialPage: 1,
      viewportFraction: 1,
    );
    final publishedPages = <int>[];
    var showPages = true;
    late StateSetter rebuildHost;
    addTearDown(controller.dispose);
    await pumpExtensionSurface(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixCarousel(
            controller: controller,
            height: 120,
            onPageChanged: publishedPages.add,
            children: showPages
                ? const <Widget>[
                    ColoredBox(color: Colors.red),
                    ColoredBox(color: Colors.blue),
                  ]
                : const <Widget>[],
          );
        },
      ),
    );
    publishedPages.clear();

    rebuildHost(() => showPages = false);
    await tester.pump();
    await tester.pump();

    expect(controller.index, 0);
    expect(publishedPages, <int>[0]);
    expect(find.byType(PageView), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carousel disables a non-positive autoplay interval', (
    tester,
  ) async {
    await pumpExtensionSurface(
      tester,
      const MiuixCarousel(
        autoPlay: true,
        autoPlayInterval: Duration.zero,
        children: <Widget>[
          ColoredBox(color: Colors.red, child: Text('Still first')),
          ColoredBox(color: Colors.blue, child: Text('Never auto page')),
        ],
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Still first'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('carousel indicator uses theme, override, and source geometry', (
    tester,
  ) async {
    const pages = <Widget>[
      ColoredBox(color: Colors.red),
      ColoredBox(color: Colors.blue),
      ColoredBox(color: Colors.green),
    ];

    Future<void> pump(Widget carousel) async {
      await pumpExtensionSurface(
        tester,
        MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              pageIndicatorDotSize: 7,
              pageIndicatorActiveWidth: 21,
              pageIndicatorSpacing: 4,
              carouselIndicatorGap: 13,
            ),
          ),
          child: carousel,
        ),
      );
      await tester.pumpAndSettle();
    }

    List<AnimatedContainer> indicators() => tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byType(MiuixCarousel),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .toList();
    List<Size> indicatorSizes() => List<Size>.generate(
      indicators().length,
      (index) => tester.getSize(
        find
            .descendant(
              of: find.byType(MiuixCarousel),
              matching: find.byType(AnimatedContainer),
            )
            .at(index),
      ),
      growable: false,
    );
    double gap() => tester
        .getSize(find.byKey(const ValueKey('miuix-carousel-indicator-gap')))
        .height;

    await pump(const MiuixCarousel(height: 80, children: pages));
    expect(indicatorSizes(), const <Size>[
      Size(29, 7),
      Size(15, 7),
      Size(15, 7),
    ]);
    expect(
      indicators().every(
        (item) => item.margin == const EdgeInsets.symmetric(horizontal: 4),
      ),
      isTrue,
    );
    expect(gap(), 13);

    await pump(
      const MiuixCarousel(
        height: 80,
        indicatorDotSize: 8,
        indicatorActiveWidth: 22,
        indicatorSpacing: 5,
        indicatorGap: 14,
        children: pages,
      ),
    );
    expect(indicatorSizes(), const <Size>[
      Size(32, 8),
      Size(18, 8),
      Size(18, 8),
    ]);
    expect(gap(), 14);

    await pump(const MiuixCarousel.source(height: 80, children: pages));
    expect(indicatorSizes(), const <Size>[
      Size(24, 6),
      Size(12, 6),
      Size(12, 6),
    ]);
    expect(
      indicators().every(
        (item) => item.margin == const EdgeInsets.symmetric(horizontal: 3),
      ),
      isTrue,
    );
    expect(gap(), 10);
  });

  testWidgets('carousel reduced motion snaps pages and pauses autoplay', (
    tester,
  ) async {
    final controller = MiuixCarouselController(viewportFraction: 1);
    addTearDown(controller.dispose);
    var reduceMotion = false;
    var autoPlay = false;
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
                data: MiuixThemeData.defaults().copyWith(
                  hyperOs4: const MiuixHyperOs4Tokens(
                    carouselPageMotion: Duration(milliseconds: 777),
                    pageIndicatorMotion: Duration(milliseconds: 444),
                    pageIndicatorDotSize: 7,
                    pageIndicatorActiveWidth: 19,
                    pageIndicatorSpacing: 4,
                    carouselIndicatorGap: 12,
                  ),
                ),
                child: Scaffold(
                  body: MiuixCarousel(
                    controller: controller,
                    height: 120,
                    autoPlay: autoPlay,
                    autoPlayInterval: const Duration(milliseconds: 50),
                    children: const <Widget>[
                      ColoredBox(color: Colors.red, child: Text('One')),
                      ColoredBox(color: Colors.blue, child: Text('Two')),
                      ColoredBox(color: Colors.green, child: Text('Three')),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    Finder indicatorFinder() => find.descendant(
      of: find.byType(MiuixCarousel),
      matching: find.byType(AnimatedContainer),
    );
    expect(
      tester
          .widgetList<AnimatedContainer>(indicatorFinder())
          .every(
            (indicator) =>
                indicator.duration == const Duration(milliseconds: 444),
          ),
      isTrue,
    );
    final initialIndicators = tester.widgetList<AnimatedContainer>(
      indicatorFinder(),
    );
    expect(initialIndicators, hasLength(3));
    expect(
      List<Size>.generate(
        indicatorFinder().evaluate().length,
        (index) => tester.getSize(indicatorFinder().at(index)),
        growable: false,
      ),
      const <Size>[Size(27, 7), Size(15, 7), Size(15, 7)],
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-carousel-indicator-gap')))
          .height,
      12,
    );

    unawaited(controller.animateTo(2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(controller.pageController.page, inExclusiveRange(0, 2));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      controller.pageController.page,
      inExclusiveRange(0, 2),
      reason: 'the 777ms theme token must outlive the former 420ms clock',
    );

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(controller.pageController.page, closeTo(2, 1e-9));
    final settledIndicators = tester.widgetList<AnimatedContainer>(
      indicatorFinder(),
    );
    expect(settledIndicators, hasLength(3));
    expect(
      settledIndicators.every(
        (indicator) => indicator.duration == Duration.zero,
      ),
      isTrue,
    );
    expect(
      List<double>.generate(
        indicatorFinder().evaluate().length,
        (index) => tester.getSize(indicatorFinder().at(index)).width,
        growable: false,
      ),
      const <double>[15, 15, 27],
    );

    unawaited(controller.previous());
    await tester.pump();
    expect(controller.pageController.page, closeTo(1, 1e-9));

    final drag = await tester.startGesture(
      tester.getCenter(find.byType(PageView)),
    );
    await drag.moveBy(const Offset(-160, 0));
    await tester.pump();
    expect(controller.pageController.page, inExclusiveRange(1, 2));
    await drag.up();
    await tester.pump();
    await tester.pump();
    expect(controller.pageController.page, closeTo(1, 1e-9));

    updateHost(() => autoPlay = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.pageController.page, closeTo(1, 1e-9));
    expect(controller.index, 1);
    expect(tester.takeException(), isNull);
  });
}
