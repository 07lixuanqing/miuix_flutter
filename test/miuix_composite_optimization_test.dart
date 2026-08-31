import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps composite components with the package theme and a root overlay.
Future<void> pumpComposite(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(700, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MiuixTheme(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('segmented control supports guarded single selection and keys', (
    tester,
  ) async {
    var selected = <int>{1};
    await pumpComposite(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MiuixSegmentedControl<int>(
          values: const <int>[1, 2, 3],
          selected: selected,
          labelBuilder: (value) => 'Option $value',
          multipleSelection: false,
          allowEmptySelection: false,
          expanded: true,
          isValueEnabled: (value) => value != 2,
          onSelectionChanged: (value) => setState(() => selected = value),
        ),
      ),
    );

    await tester.tap(find.text('Option 2'));
    expect(selected, <int>{1});
    await tester.tap(find.text('Option 3'));
    await tester.pumpAndSettle();
    expect(selected, <int>{3});
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(selected, <int>{
      1,
    }, reason: 'disabled neighboring option is skipped');
  });

  testWidgets('segmented control defaults to token glass and shared motion', (
    tester,
  ) async {
    var selected = <int>{1};
    await pumpComposite(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MiuixSegmentedControl<int>(
          values: const <int>[1, 2, 3],
          selected: selected,
          labelBuilder: (value) => 'Choice $value',
          multipleSelection: false,
          allowEmptySelection: false,
          expanded: true,
          onSelectionChanged: (value) => setState(() => selected = value),
        ),
      ),
    );

    final glass = tester.widget<MiuixGlass>(
      find.descendant(
        of: find.byType(MiuixSegmentedControl<int>),
        matching: find.byType(MiuixGlass),
      ),
    );
    expect(glass.blur, 18);
    expect(glass.opacity, .60);
    expect(glass.radius, 22);
    expect(tester.getSize(find.byType(MiuixSegmentedControl<int>)).height, 44);

    final before = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-segmented-selection')),
    );
    expect(before.start, 0);
    expect(before.duration, const Duration(milliseconds: 380));
    await tester.tap(find.text('Choice 3'));
    await tester.pump();
    final after = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-segmented-selection')),
    );
    expect(after.start, greaterThan(0));
    expect(selected, <int>{3});
  });

  testWidgets('segmented source style and reduced motion stay explicit', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Column(
          children: <Widget>[
            MiuixSegmentedControl<int>(
              values: const <int>[1, 2],
              selected: const <int>{1},
              labelBuilder: (value) => '$value',
              multipleSelection: false,
              expanded: true,
              onSelectionChanged: (_) {},
            ),
            MiuixSegmentedControl<int>.source(
              values: const <int>[1, 2],
              selected: const <int>{1},
              labelBuilder: (value) => '$value',
              onSelectionChanged: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MiuixGlass), findsOneWidget);
    final indicator = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-segmented-selection')),
    );
    expect(indicator.duration, Duration.zero);
    final source = find.byType(MiuixSegmentedControl<int>).last;
    expect(tester.getSize(source).height, 42);
  });

  testWidgets('segmented control normalizes invalid public geometry', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      Column(
        children: <Widget>[
          MiuixSegmentedControl<int>(
            values: const <int>[1, 2],
            selected: const <int>{1},
            labelBuilder: (value) => '$value',
            height: double.nan,
            cornerRadius: double.infinity,
            onSelectionChanged: (_) {},
          ),
          MiuixSegmentedControl<int>(
            values: const <int>[1, 2],
            selected: const <int>{1},
            labelBuilder: (value) => '$value',
            height: -10,
            cornerRadius: -10,
            onSelectionChanged: (_) {},
          ),
        ],
      ),
    );

    final controls = find.byType(MiuixSegmentedControl<int>);
    expect(tester.getSize(controls.first).height, 44);
    expect(tester.getSize(controls.last).height, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('action sheet exposes selected and disabled actions', (
    tester,
  ) async {
    var selectedAction = '';
    await pumpComposite(
      tester,
      Builder(
        builder: (context) => MiuixButton(
          label: 'Open sheet',
          onPressed: () => MiuixActionSheet.show(
            context: context,
            title: 'Actions',
            message: 'Choose one action',
            cancelLabel: 'Cancel',
            actions: <MiuixActionSheetItem>[
              MiuixActionSheetItem(
                label: 'Unavailable',
                enabled: false,
                onTap: () => selectedAction = 'disabled',
              ),
              MiuixActionSheetItem(
                label: 'Use this',
                selected: true,
                onTap: () => selectedAction = 'enabled',
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixGlass), findsOneWidget);
    expect(
      tester
          .widget<MiuixGlass>(
            find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
          )
          .enabled,
      isTrue,
    );
    expect(find.text('Choose one action'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    await tester.tap(find.text('Unavailable'));
    expect(selectedAction, isEmpty);
    await tester.tap(find.text('Use this'));
    await tester.pumpAndSettle();
    expect(selectedAction, 'enabled');
  });

  testWidgets('expandable card supports controlled state and haptic callback', (
    tester,
  ) async {
    var expanded = false;
    await pumpComposite(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MiuixExpandableCard(
          title: 'Advanced',
          subtitle: 'More settings',
          expanded: expanded,
          glass: true,
          onExpandedChanged: (value) => setState(() => expanded = value),
          children: const <Widget>[Text('Details')],
        ),
      ),
    );

    expect(
      tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState,
      CrossFadeState.showSecond,
    );
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('miuix-vertical-disclosure-arrow')),
          )
          .turns,
      .25,
    );
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
    await tester.tap(find.text('Advanced'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(expanded, isTrue);
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('miuix-vertical-disclosure-arrow')),
          )
          .turns,
      -.25,
    );
    expect(
      tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState,
      CrossFadeState.showFirst,
    );
  });

  testWidgets('inline application surfaces default to HyperOS token glass', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      const Column(
        children: <Widget>[
          MiuixChip(label: 'Filter'),
          MiuixInlineAlert(message: 'Connected'),
          MiuixBanner(title: 'Update', message: 'Ready to install'),
          MiuixExpandableCard(
            title: 'Advanced',
            children: <Widget>[Text('Details')],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final glasses = tester.widgetList<MiuixGlass>(find.byType(MiuixGlass));
    expect(glasses, hasLength(4));
    final chipMotion = tester.widget<TweenAnimationBuilder<Color?>>(
      find.descendant(
        of: find.byType(MiuixChip),
        matching: find.byType(TweenAnimationBuilder<Color?>),
      ),
    );
    expect(chipMotion.duration, const Duration(milliseconds: 280));
    expect(glasses.first.blur, 18);
    expect(glasses.first.opacity, .56);
    expect(glasses.first.radius, 999);
    for (final glass in glasses.skip(1)) {
      expect(glass.blur, 20);
      expect(glass.opacity, .62);
      expect(glass.radius, 20);
      expect(
        glass.color!.a,
        greaterThan(0),
        reason: 'semantic tint must reach the backdrop material',
      );
    }
  });

  testWidgets('source inline surfaces stay opaque and motion can be disabled', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Column(
          children: <Widget>[
            MiuixChip.source(label: 'Filter'),
            MiuixInlineAlert.source(message: 'Connected'),
            MiuixBanner.source(title: 'Update', message: 'Ready'),
            MiuixExpandableCard(
              title: 'Advanced',
              children: <Widget>[Text('Details')],
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MiuixGlass), findsOneWidget);
    final chipMotion = tester.widget<TweenAnimationBuilder<Color?>>(
      find.descendant(
        of: find.byType(MiuixChip),
        matching: find.byType(TweenAnimationBuilder<Color?>),
      ),
    );
    expect(chipMotion.duration, Duration.zero);
    expect(
      tester.widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade)).duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<AnimatedRotation>(
            find.byKey(const ValueKey('miuix-vertical-disclosure-arrow')),
          )
          .duration,
      Duration.zero,
    );
  });

  testWidgets('empty state uses HyperOS tokens and keeps a source geometry', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      const MiuixEmptyState(
        title: 'Nothing here',
        message: 'Create an item to continue.',
        action: SizedBox(width: 80, height: 32),
      ),
    );

    ConstrainedBox content() => tester.widget<ConstrainedBox>(
      find.byKey(const ValueKey('miuix-empty-state-content')),
    );
    IconTheme iconTheme() => tester.widget<IconTheme>(
      find.byKey(const ValueKey('miuix-empty-state-icon-theme')),
    );
    double gap(String key) => tester.getSize(find.byKey(ValueKey(key))).height;
    expect(content().constraints.maxWidth, 360);
    expect(iconTheme().data.size, 64);
    expect(gap('miuix-empty-state-title-spacing'), 14);
    expect(gap('miuix-empty-state-message-spacing'), 6);
    expect(gap('miuix-empty-state-action-spacing'), 18);
    final semantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(MiuixEmptyState),
        matching: find.byType(Semantics),
      ),
    );
    expect(semantics.any((node) => node.properties.liveRegion == true), isTrue);

    await pumpComposite(
      tester,
      const MiuixEmptyState.source(
        title: 'Nothing here',
        message: 'Legacy composition',
        action: SizedBox(width: 80, height: 32),
      ),
    );
    expect(content().constraints.maxWidth, double.infinity);
    expect(iconTheme().data.size, 52);
    expect(tester.widget<Icon>(find.byIcon(Icons.inbox)).size, 56);
    expect(gap('miuix-empty-state-title-spacing'), 10);
    expect(gap('miuix-empty-state-message-spacing'), 6);
    expect(gap('miuix-empty-state-action-spacing'), 10);
    final sourceSemantics = tester.widgetList<Semantics>(
      find.descendant(
        of: find.byType(MiuixEmptyState),
        matching: find.byType(Semantics),
      ),
    );
    expect(
      sourceSemantics.any((node) => node.properties.liveRegion == true),
      isFalse,
    );
  });

  testWidgets('empty state and page indicator reject invalid geometry', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiuixEmptyState(
            title: 'Safe empty state',
            maximumWidth: double.nan,
            padding: double.negativeInfinity,
            iconSize: -12,
          ),
          MiuixPageIndicator(
            count: 3,
            index: 99,
            dotSize: double.nan,
            activeWidth: double.infinity,
            spacing: -4,
          ),
          MiuixAvatar(initials: 'MI', size: double.nan),
          MiuixAvatar(initials: 'MI', size: -8),
        ],
      ),
    );

    final content = tester.widget<ConstrainedBox>(
      find.byKey(const ValueKey('miuix-empty-state-content')),
    );
    final iconTheme = tester.widget<IconTheme>(
      find.byKey(const ValueKey('miuix-empty-state-icon-theme')),
    );
    expect(content.constraints.maxWidth, 360);
    expect(iconTheme.data.size, 0);
    final avatars = find.byType(MiuixAvatar);
    expect(tester.getSize(avatars.first), const Size.square(48));
    expect(tester.getSize(avatars.last), Size.zero);
    final dots = find.descendant(
      of: find.byType(MiuixPageIndicator),
      matching: find.byType(AnimatedContainer),
    );
    for (var index = 0; index < dots.evaluate().length; index++) {
      final size = tester.getSize(dots.at(index));
      expect(size.width.isFinite, isTrue);
      expect(size.height.isFinite, isTrue);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy cascading menu keeps physical MIUIX disclosure arrows', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      Directionality(
        textDirection: TextDirection.rtl,
        child: MiuixCascadingMenu<String>(
          items: const <MiuixCascadingMenuItem<String>>[
            MiuixCascadingMenuItem<String>(
              label: 'Display',
              children: <MiuixDropdownEntry<String>>[
                MiuixDropdownEntry<String>(value: 'light', label: 'Light'),
              ],
            ),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    final arrow = find.descendant(
      of: find.byKey(const ValueKey('miuix-cascading-menu-arrow')),
      matching: find.byKey(const ValueKey('miuix-vertical-disclosure-arrow')),
    );
    expect(tester.widget<AnimatedRotation>(arrow).turns, -.25);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);

    await tester.tap(find.text('Display'));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<AnimatedRotation>(arrow).turns, .25);
  });

  testWidgets('cascading menu honors reduced disclosure motion', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MiuixCascadingMenu<String>(
          items: const <MiuixCascadingMenuItem<String>>[
            MiuixCascadingMenuItem<String>(
              label: 'Display',
              children: <MiuixDropdownEntry<String>>[
                MiuixDropdownEntry<String>(value: 'light', label: 'Light'),
              ],
            ),
          ],
          onSelected: (_) {},
        ),
      ),
    );

    final arrow = find.descendant(
      of: find.byKey(const ValueKey('miuix-cascading-menu-arrow')),
      matching: find.byKey(const ValueKey('miuix-vertical-disclosure-arrow')),
    );
    expect(tester.widget<AnimatedRotation>(arrow).duration, Duration.zero);
    expect(find.byType(AnimatedCrossFade), findsNothing);
    await tester.tap(find.text('Display'));
    await tester.pump();
    expect(tester.widget<AnimatedRotation>(arrow).turns, .25);
    expect(find.text('Light'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inline alert and banner expose dismissible live regions', (
    tester,
  ) async {
    var alertDismissed = false;
    var bannerDismissed = false;
    await pumpComposite(
      tester,
      Column(
        children: <Widget>[
          MiuixInlineAlert(
            title: 'Warning',
            message: 'Check this value',
            glass: true,
            onDismissed: () => alertDismissed = true,
          ),
          MiuixBanner(
            title: 'Update',
            message: 'A new version is ready',
            liveRegion: true,
            leading: const Icon(Icons.system_update_rounded),
            onDismissed: () => bannerDismissed = true,
          ),
        ],
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded).first);
    await tester.tap(find.byIcon(Icons.close_rounded).last);
    expect(alertDismissed, isTrue);
    expect(bannerDismissed, isTrue);
  });

  testWidgets('loading dialog reports cancellation once', (tester) async {
    var cancellations = 0;
    await pumpComposite(
      tester,
      Builder(
        builder: (context) => MiuixButton(
          label: 'Load',
          onPressed: () => MiuixLoadingDialog.show<void>(
            context: context,
            message: 'Preparing',
            details: 'Almost ready',
            progress: .5,
            cancelable: true,
            cancelLabel: 'Stop',
            onCancel: () => cancellations++,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Load'));
    await tester.pumpAndSettle();
    expect(
      find.byType(MiuixGlass),
      findsOneWidget,
      reason: 'loading dialog owns one clipped glass layer, never two',
    );
    expect(
      tester
          .widget<MiuixGlass>(
            find.byKey(const ValueKey('miuix-dialog-surface')),
          )
          .enabled,
      isTrue,
    );
    expect(find.text('Almost ready'), findsOneWidget);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(cancellations, 1);
  });

  testWidgets('action sheet and loading dialog keep explicit opaque opt-out', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      Builder(
        builder: (context) => Column(
          children: <Widget>[
            MiuixButton(
              label: 'Opaque sheet',
              onPressed: () => MiuixActionSheet.show(
                context: context,
                glass: false,
                actions: <MiuixActionSheetItem>[
                  MiuixActionSheetItem(label: 'Close', onTap: () {}),
                ],
              ),
            ),
            MiuixButton(
              label: 'Opaque loading',
              onPressed: () => MiuixLoadingDialog.show<void>(
                context: context,
                message: 'Loading',
                progress: .5,
                glass: false,
                cancelable: true,
                cancelLabel: 'Stop',
              ),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Opaque sheet'));
    await tester.pumpAndSettle();
    final sheetSurface = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    expect(sheetSurface.enabled, isFalse);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opaque loading'));
    await tester.pumpAndSettle();
    final dialogSurface = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-dialog-surface')),
    );
    expect(dialogSurface.enabled, isFalse);
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
  });

  testWidgets('toast exposes action, duration, dismiss, and controller', (
    tester,
  ) async {
    var acted = false;
    late MiuixSnackbarController controller;
    await pumpComposite(
      tester,
      Builder(
        builder: (context) => MiuixButton(
          label: 'Toast',
          onPressed: () {
            controller = MiuixToast.show(
              context,
              'Saved',
              actionLabel: 'Undo',
              onAction: () => acted = true,
              duration: MiuixSnackbarDuration.indefinite,
              withDismissAction: true,
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Toast'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(acted, isTrue);
    await controller.closed;
  });

  testWidgets('empty-state view supports compact glass presentation', (
    tester,
  ) async {
    await pumpComposite(
      tester,
      const MiuixEmptyStateView(
        title: 'No results',
        message: 'Try another query',
        type: MiuixEmptyStateType.noResults,
        compact: true,
        glass: true,
      ),
    );

    expect(find.byType(MiuixGlass), findsOneWidget);
    expect(find.text('Try another query'), findsOneWidget);
  });
}
