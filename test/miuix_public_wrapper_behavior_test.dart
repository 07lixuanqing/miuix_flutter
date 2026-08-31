import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpWrapper(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: MiuixTheme(
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

Future<void> _pumpHostedWrapper(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: MiuixTheme(
        child: MiuixScaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'backdrop effect scope keeps anisotropic and custom filter order',
    (tester) async {
      final dilate = ImageFilter.dilate(radiusX: 1, radiusY: 2);
      final erode = ImageFilter.erode(radiusX: 3, radiusY: 4);
      final scope = const MiuixBackdropEffectScope(child: Text('Backdrop'))
          .blur(10, 20)
          .colorControls(brightness: .1, contrast: 1.2, saturation: .8)
          .noiseDither(.02)
          .blendColors(
            const MiuixBlurColors(
              tint: Colors.transparent,
              opacity: 0,
              blendColors: [
                MiuixBlurBlendEntry(
                  Color(0x402196F3),
                  MiuixBlurBlendMode.overlay,
                ),
              ],
            ),
          )
          .effect(dilate)
          .effect(erode);

      expect(scope.backdrop.blur, 10);
      expect(scope.backdrop.blurY, 20);
      expect(scope.backdrop.noise, .02);
      expect(scope.backdrop.colors.blendColors, hasLength(1));
      expect(scope.backdrop.effects, [dilate, erode]);
      expect(scope.noiseDither(0), same(scope));
      final preset = const MiuixBackdropEffectScope(child: SizedBox())
          .textureBlurEffect(
            blurRadiusX: 999,
            blurRadiusY: -4,
            noiseCoefficient: 0,
          );
      expect(preset.backdrop.blur, MiuixBlurDefaults.maxBlurRadius);
      expect(preset.backdrop.blurY, 0);
      expect(preset.backdrop.noise, 0);
      final filter = debugMiuixBackdropImageFilter(scope.backdrop);
      expect(filter.debugShortDescription, contains('blur(4.5, 9.0'));
      expect(
        filter.debugShortDescription,
        contains('dilate(1.0, 2.0) -> erode(3.0, 4.0)'),
      );

      await _pumpWrapper(tester, scope);
      final rendered = tester.widget<BackdropFilter>(
        find.byKey(const ValueKey('miuix-glass-backdrop-filter')),
      );
      expect(rendered.filter!.debugShortDescription, contains('blur(4.5, 9.0'));
      final firstEffect = find.byKey(
        const ValueKey('miuix-backdrop-custom-effect-0'),
      );
      final secondEffect = find.byKey(
        const ValueKey('miuix-backdrop-custom-effect-1'),
      );
      expect(firstEffect, findsOneWidget);
      expect(secondEffect, findsOneWidget);
      expect(
        find.descendant(of: secondEffect, matching: firstEffect),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Backdrop'),
          matching: find.byType(ImageFiltered),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('miuix-blur-noise-layer')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'progressive backdrop scope retains gradient axes and post effects',
    (tester) async {
      final custom = ImageFilter.dilate(radiusX: 1, radiusY: 2);
      final scope =
          const MiuixBackdropEffectScope(
                radius: 24,
                padding: EdgeInsets.all(8),
                child: Text('Progressive foreground'),
              )
              .progressiveTextureBlurEffect(
                blurRadiusX: 30,
                blurRadiusY: 12,
                gradient: MiuixProgressiveBlur.right,
                colors: const MiuixBlurColors(
                  tint: Colors.transparent,
                  opacity: 0,
                ),
              )
              .effect(custom);

      expect(scope, isA<MiuixProgressiveLayerBackdrop>());
      expect(scope.backdrop.blur, 30);
      expect(scope.backdrop.blurY, 12);
      expect(scope.gradient, MiuixProgressiveBlur.right);
      expect(scope.backdrop.effects, [custom]);

      await _pumpWrapper(
        tester,
        SizedBox(width: 240, height: 120, child: scope),
      );
      expect(
        find.byKey(const ValueKey('miuix-progressive-post-effect-mask')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('miuix-backdrop-custom-effect-0')),
        findsOneWidget,
      );
      expect(
        find.ancestor(
          of: find.text('Progressive foreground'),
          matching: find.byType(ImageFiltered),
        ),
        findsNothing,
      );
      expect(find.byType(Padding), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  test('floating navigation source item retains enabled and badge inputs', () {
    const badge = Text('3');
    const item = MiuixFloatingNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
      layoutLabel: 'Homepage',
      enabled: false,
      badge: badge,
    );

    expect(item.enabled, isFalse);
    expect(item.badge, same(badge));
    expect(item.selectedIcon, isA<Icon>());
    expect(item.layoutLabel, 'Homepage');
  });

  testWidgets('command palette shortcut accepts control and meta K', (
    tester,
  ) async {
    var openings = 0;
    await _pumpWrapper(
      tester,
      MiuixCommandPaletteShortcut(
        onOpen: () => openings++,
        child: const Text('shortcut child'),
      ),
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);

    expect(openings, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown wrappers retain disabled trigger ownership', (
    tester,
  ) async {
    const entries = <MiuixDropdownEntry<int>>[
      MiuixDropdownEntry<int>(value: 1, label: 'One'),
    ];
    const groups = <MiuixDropdownGroup<int>>[
      MiuixDropdownGroup<int>(entries: entries),
    ];
    await _pumpWrapper(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const MiuixDropdownArrowEndAction(actionColor: Colors.red),
          MiuixIconDropdownMenu<int>(
            icon: const Icon(Icons.more_vert),
            entries: entries,
            enabled: false,
            onSelected: (_) {},
          ),
          MiuixGroupedDropdownPreference<int>(
            title: 'Grouped',
            groups: groups,
            enabled: false,
            onSelected: (_) {},
          ),
        ],
      ),
    );

    final iconButton = tester.widget<MiuixIconButton>(
      find.descendant(
        of: find.byType(MiuixIconDropdownMenu<int>),
        matching: find.byType(MiuixIconButton),
      ),
    );
    final preference = tester.widget<MiuixPreference>(
      find.descendant(
        of: find.byType(MiuixGroupedDropdownPreference<int>),
        matching: find.byType(MiuixPreference),
      ),
    );
    expect(iconButton.enabled, isFalse);
    expect(iconButton.onPressed, isNull);
    expect(preference.enabled, isFalse);
    expect(preference.onTap, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlay dropdown popup supports current grouped source content',
    (tester) async {
      final selected = <int>[];
      var dismissRequests = 0;
      var dismissFinished = 0;
      await _pumpHostedWrapper(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () {
              unawaited(
                MiuixOverlayDropdownPopup.show<int>(
                  context: context,
                  groups: const [
                    MiuixDropdownGroup(
                      entries: [
                        MiuixDropdownEntry(
                          value: 1,
                          label: 'Overlay one',
                          selected: true,
                        ),
                      ],
                    ),
                    MiuixDropdownGroup(
                      entries: [
                        MiuixDropdownEntry(value: 2, label: 'Overlay two'),
                      ],
                    ),
                  ],
                  onSelected: selected.add,
                  collapseOnSelection: false,
                  onDismissRequest: () => dismissRequests++,
                  onDismissFinished: () => dismissFinished++,
                ),
              );
            },
            child: const Text('open overlay source popup'),
          ),
        ),
      );

      await tester.tap(find.text('open overlay source popup'));
      await tester.pumpAndSettle();
      final popup = tester.widget<MiuixListPopup<int>>(
        find.byType(MiuixListPopup<int>),
      );
      expect(popup.sourceRows, isTrue);
      expect(popup.groups, hasLength(2));
      expect(find.text('Overlay one'), findsOneWidget);
      expect(find.text('Overlay two'), findsOneWidget);

      await tester.tap(find.text('Overlay two'));
      await tester.pumpAndSettle();
      expect(selected, [2]);
      expect(find.text('Overlay one'), findsOneWidget);
      expect(dismissRequests, 0);

      await tester.tapAt(const Offset(2, 2));
      await tester.pumpAndSettle();
      expect(find.text('Overlay one'), findsNothing);
      expect(dismissRequests, 1);
      expect(dismissFinished, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('window dropdown dialog owns title rows and close action', (
    tester,
  ) async {
    final selected = <int>[];
    var dismissRequests = 0;
    var dismissFinished = 0;
    await _pumpHostedWrapper(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            unawaited(
              MiuixWindowDropdownDialog.show<int>(
                context: context,
                title: 'Window choices',
                dialogButtonString: 'Close choices',
                groups: const [
                  MiuixDropdownGroup(
                    entries: [
                      MiuixDropdownEntry(value: 1, label: 'Window one'),
                      MiuixDropdownEntry(value: 2, label: 'Window two'),
                    ],
                  ),
                ],
                onSelected: selected.add,
                collapseOnSelection: false,
                onDismissRequest: () => dismissRequests++,
                onDismissFinished: () => dismissFinished++,
              ),
            );
          },
          child: const Text('open window source dialog'),
        ),
      ),
    );

    await tester.tap(find.text('open window source dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Window choices'), findsOneWidget);
    expect(find.text('Close choices'), findsOneWidget);
    final popup = tester.widget<MiuixListPopup<int>>(
      find.byType(MiuixListPopup<int>),
    );
    expect(popup.sourceRows, isTrue);
    expect(popup.dialogMode, isTrue);
    expect(popup.showSurface, isFalse);

    await tester.tap(find.text('Window two'));
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(find.text('Window choices'), findsOneWidget);

    await tester.tap(find.text('Close choices'));
    await tester.pumpAndSettle();
    expect(find.text('Window choices'), findsNothing);
    expect(dismissRequests, 1);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('window dropdown popup defaults to collapsing one source group', (
    tester,
  ) async {
    final selected = <int>[];
    var dismissRequests = 0;
    var dismissFinished = 0;
    await _pumpHostedWrapper(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            unawaited(
              MiuixWindowDropdownPopup.show<int>(
                context: context,
                entries: const [
                  MiuixDropdownEntry(value: 1, label: 'Window popup one'),
                  MiuixDropdownEntry(value: 2, label: 'Window popup two'),
                ],
                onSelected: selected.add,
                onDismissRequest: () => dismissRequests++,
                onDismissFinished: () => dismissFinished++,
              ),
            );
          },
          child: const Text('open window source popup'),
        ),
      ),
    );

    await tester.tap(find.text('open window source popup'));
    await tester.pumpAndSettle();
    final popup = tester.widget<MiuixListPopup<int>>(
      find.byType(MiuixListPopup<int>),
    );
    expect(popup.sourceRows, isTrue);
    await tester.tap(find.text('Window popup two'));
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(find.text('Window popup one'), findsNothing);
    expect(dismissRequests, 1);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay dropdown dialog keeps multiple source groups open', (
    tester,
  ) async {
    final selected = <int>[];
    await _pumpHostedWrapper(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () {
            unawaited(
              MiuixOverlayDropdownDialog.show<int>(
                context: context,
                title: 'Overlay choices',
                dialogButtonString: 'Close overlay choices',
                groups: const [
                  MiuixDropdownGroup(
                    entries: [
                      MiuixDropdownEntry(value: 1, label: 'Overlay dialog one'),
                    ],
                  ),
                  MiuixDropdownGroup(
                    entries: [
                      MiuixDropdownEntry(value: 2, label: 'Overlay dialog two'),
                    ],
                  ),
                ],
                onSelected: selected.add,
              ),
            );
          },
          child: const Text('open overlay source dialog'),
        ),
      ),
    );

    await tester.tap(find.text('open overlay source dialog'));
    await tester.pumpAndSettle();
    final popup = tester.widget<MiuixListPopup<int>>(
      find.byType(MiuixListPopup<int>),
    );
    expect(popup.sourceRows, isTrue);
    expect(popup.dialogMode, isTrue);
    expect(popup.groups, hasLength(2));
    await tester.tap(find.text('Overlay dialog two'));
    await tester.pumpAndSettle();
    expect(selected, [2]);
    expect(find.text('Overlay choices'), findsOneWidget);
    await tester.tap(find.text('Close overlay choices'));
    await tester.pumpAndSettle();
    expect(find.text('Overlay choices'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list popup content sanitizes non-finite motion inputs', (
    tester,
  ) async {
    await _pumpWrapper(
      tester,
      MiuixListPopupContent(
        fractionProgress: () => double.nan,
        alphaProgress: () => double.infinity,
        popupLayoutPosition: const MiuixPopupLayoutPosition(
          showBelow: true,
          showAbove: false,
          isRightAligned: false,
        ),
        localTransformOrigin: const MiuixTransformOrigin(
          double.nan,
          double.infinity,
        ),
        child: const SizedBox(width: 120, height: 60),
      ),
    );

    final opacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('miuix-list-popup-content-opacity')),
    );
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-list-popup-content-transform')),
    );
    expect(opacity.opacity, 1);
    final popupGlass = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-list-popup-content-glass')),
    );
    expect(popupGlass.glass, isTrue);
    expect(popupGlass.glassOptics, same(MiuixGlassOptics.transient));
    expect(
      transform.transform.storage.every((value) => value.isFinite),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('squircle clip normalizes invalid public radii', (tester) async {
    await _pumpWrapper(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          MiuixSquircleClip(
            radius: double.nan,
            child: SizedBox.square(dimension: 40),
          ),
          MiuixSquircleClip(radius: -12, child: SizedBox.square(dimension: 40)),
        ],
      ),
    );

    for (final clip in tester.widgetList<ClipPath>(find.byType(ClipPath))) {
      final shape = (clip.clipper! as ShapeBorderClipper).shape;
      expect(shape, isA<MiuixSquircleBorder>());
      final border = shape as MiuixSquircleBorder;
      expect(border.borderRadius.topLeft.x.isFinite, isTrue);
      expect(border.borderRadius.topLeft.x, greaterThanOrEqualTo(0));
    }
    expect(tester.takeException(), isNull);
  });
}
