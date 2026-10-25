part of '../miuix_flutter_test.dart';

/// Deterministic canvas artwork used to exercise the painter Icon overload.
class _MiuixIconTestPainter extends CustomPainter {
  /// Creates the immutable test painter.
  const _MiuixIconTestPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MiuixTestScrollBarAdapter extends ChangeNotifier
    implements MiuixScrollBarAdapter {
  _MiuixTestScrollBarAdapter({
    required this.contentSize,
    required this.viewportSize,
    this.scrollOffset = 0,
  });

  @override
  final double contentSize;

  @override
  final double viewportSize;

  @override
  double scrollOffset;

  @override
  Future<void> scrollTo(double value) async {
    scrollOffset = value;
    notifyListeners();
  }

  void jumpTo(double value) {
    scrollOffset = value;
    notifyListeners();
  }
}

void _registerCoreWidgetTests() {
  test('platform and dialog policy expose truthful Flutter host ownership', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(miuixPlatform, MiuixPlatform.android);
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(miuixPlatform, MiuixPlatform.macOS);

    const expected = MiuixPlatformDialogProperties();
    expect(miuixPlatformDialogProperties(), expected);
    expect(expected.dismissOnBackPress, isFalse);
    expect(expected.usePlatformDefaultWidth, isFalse);
    expect(expected.usePlatformInsets, isFalse);
    expect(expected.transparentScrim, isTrue);
    expect(expected.animatePlatformTransition, isFalse);
    expect(() => removeMiuixPlatformDialogDefaultEffects(), returnsNormally);
  });

  test(
    'shader capability separates source compilation from bundled assets',
    () {
      expect(miuixIsRuntimeShaderSupported(), isFalse);
      expect(
        miuixIsBundledFragmentShaderSupported(),
        ImageFilter.isShaderFilterSupported,
      );
      expect(miuixIsRenderEffectSupported(), isTrue);
    },
  );

  testWidgets(
    'squircle defaults and theme capability share one public source',
    (tester) async {
      expect(MiuixSquircleDefaults.extension, 1.1);
      expect(MiuixSquircleDefaults.extensionMin, 1);
      expect(MiuixSquircleDefaults.extensionMax, 2);
      bool? enabled;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(enableSquircle: false),
            child: Builder(
              builder: (context) {
                enabled = miuixIsSquircleEnabled(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      expect(enabled, isFalse);
    },
  );

  test('surface defaults expose the current source shape and elevation', () {
    expect(MiuixSurfaceDefaults.shape, const RoundedRectangleBorder());
    expect(MiuixSurfaceDefaults.shadowElevation, 0);
    final surface = MiuixSurface.source(content: const SizedBox());
    expect(surface.shape, MiuixSurfaceDefaults.shape);
    expect(surface.shadowElevation, MiuixSurfaceDefaults.shadowElevation);
    expect(surface.glass, isFalse);
  });

  test('theme exposes all source color modes and Monet palette families', () {
    expect(MiuixColorMode.values, hasLength(6));
    expect(MiuixThemePaletteStyle.values, hasLength(9));
    expect(MiuixThemeColorSpec.values, hasLength(2));

    const seed = Color(0xFF36D167);
    final tonal = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetLight,
      seedColor: seed,
      paletteStyle: MiuixThemePaletteStyle.tonalSpot,
    );
    final expressive = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetLight,
      seedColor: seed,
      paletteStyle: MiuixThemePaletteStyle.expressive,
      colorSpec: MiuixThemeColorSpec.spec2025,
    );
    final dark = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetDark,
      seedColor: seed,
    );
    final source = MiuixThemeData.defaults();

    expect(tonal.schemeFor(Brightness.dark).brightness, Brightness.light);
    expect(dark.schemeFor(Brightness.light).brightness, Brightness.dark);
    expect(expressive.lightScheme.primary, isNot(tonal.lightScheme.primary));
    expect(expressive.paletteStyle, MiuixThemePaletteStyle.expressive);
    expect(expressive.colorSpec, MiuixThemeColorSpec.spec2025);
    expect(source.lightScheme.surface, const Color(0xFFF7F7F7));
    expect(source.lightScheme.surfaceContainerHigh, const Color(0xFFE8E8E8));
    expect(source.lightScheme.onSecondaryContainer, const Color(0xFFA9A9A9));
    expect(source.darkScheme.surface, const Color(0xFF000000));
    expect(source.darkScheme.surfaceContainer, const Color(0xFF242424));
    expect(source.darkScheme.surfaceContainerHighest, const Color(0xFF2D2D2D));
    expect(source.hyperOs4.floatingNavigationHeight, 58);
    expect(source.hyperOs4.floatingNavigationItemWidth(2), 104);
    expect(source.hyperOs4.floatingNavigationItemWidth(5), 68);
    expect(source.hyperOs4.floatingNavigationItemHeight, 52);
    expect(source.hyperOs4.floatingNavigationItemSpacing, 0);
    expect(source.hyperOs4.floatingNavigationSelectionInset, 2);
    expect(source.hyperOs4.floatingNavigationSelectionHeight, 52);
    expect(source.hyperOs4.floatingNavigationDragSelectionInset, 2);
    expect(source.hyperOs4.floatingNavigationContentSpacing, 5);
    expect(source.hyperOs4.emptyStateMaximumWidth, 360);
    expect(source.hyperOs4.emptyStatePadding, 24);
    expect(source.hyperOs4.emptyStateIconSize, 64);
    expect(source.hyperOs4.emptyStateTitleSpacing, 14);
    expect(source.hyperOs4.emptyStateMessageSpacing, 6);
    expect(source.hyperOs4.emptyStateActionSpacing, 18);
    expect(source.hyperOs4.carouselIndicatorGap, 10);
    expect(source.hyperOs4.contextMenuMinWidth, 200);
    expect(source.hyperOs4.contextMenuMaxWidth, 288);
    expect(source.hyperOs4.contextMenuItemHeight, 52);
    expect(source.hyperOs4.contextMenuHorizontalPadding, 16);
    expect(source.hyperOs4.contextMenuIconSpacing, 12);
    expect(source.hyperOs4.contextMenuVerticalPadding, 6);
    expect(source.hyperOs4.contextMenuScreenMargin, 12);
    expect(source.hyperOs4.contextMenuShadowElevation, 8);
    expect(source.hyperOs4.cardCornerRadius, 20);
    expect(source.hyperOs4.searchHeight, 48);
    expect(source.hyperOs4.searchBlur, 18);
    expect(source.hyperOs4.popupCornerRadius, 20);
    expect(source.hyperOs4.dialogBlur, 30);
    expect(source.hyperOs4.bottomSheetCornerRadius, 32);
    expect(
      source.materialTheme(Brightness.light).appBarTheme.backgroundColor,
      Colors.transparent,
    );
  });

  test('theme controller follows the source fixed and Monet branch table', () {
    final fixedLight = ColorScheme.fromSeed(seedColor: const Color(0xFFE94634));
    final fixedDark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF36D167),
      brightness: Brightness.dark,
    );
    final platformLight = ColorScheme.fromSeed(
      seedColor: const Color(0xFFFFB21D),
    );
    final platformDark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF9B66FF),
      brightness: Brightness.dark,
    );
    final controller = MiuixThemeController(
      colorSchemeMode: MiuixColorMode.system,
      lightColors: fixedLight,
      darkColors: fixedDark,
      keyColor: const Color(0xFF3482FF),
      isDark: true,
      platformDynamicLightColors: platformLight,
      platformDynamicDarkColors: platformDark,
    );

    // A key color is ignored outside Monet, while source isDark overrides the
    // caller's platform brightness in System mode.
    expect(controller.lightColors, same(fixedLight));
    expect(controller.darkColors, same(fixedDark));
    expect(
      controller.currentColors(Brightness.light).primary,
      fixedDark.primary,
    );
    controller.setKeyColor(const Color(0xFF36D167));
    expect(controller.data.lightScheme.primary, fixedLight.primary);

    // A non-null key generates Monet; null delegates to platform colors.
    controller.setMode(MiuixColorMode.monetLight);
    expect(controller.data.isDynamicColor, isTrue);
    expect(controller.data.lightScheme.primary, isNot(platformLight.primary));
    controller.setKeyColor(null);
    expect(controller.keyColor, isNull);
    expect(controller.data.lightScheme.primary, platformLight.primary);
    expect(controller.data.darkScheme.primary, platformDark.primary);
  });

  test('current theme constructor names win over deprecated aliases', () {
    const currentKey = Color(0xFF3482FF);
    const legacyKey = Color(0xFFE94634);
    final controller = MiuixThemeController(
      colorSchemeMode: MiuixColorMode.monetDark,
      keyColor: currentKey,
      // Supplying both names can happen while an application is migrating.
      // The current API must remain deterministic in release builds too.
      // ignore: deprecated_member_use_from_same_package
      mode: MiuixColorMode.light,
      // ignore: deprecated_member_use_from_same_package
      seedColor: legacyKey,
    );

    expect(controller.colorSchemeMode, MiuixColorMode.monetDark);
    expect(controller.keyColor, currentKey);
    expect(controller.data.darkScheme.brightness, Brightness.dark);
  });

  testWidgets(
    'MiuixTheme controller overload rebuilds and exposes source mode',
    (tester) async {
      final light = ColorScheme.fromSeed(seedColor: const Color(0xFFE94634));
      final dark = ColorScheme.fromSeed(
        seedColor: const Color(0xFF36D167),
        brightness: Brightness.dark,
      );
      final controller = MiuixThemeController(
        colorSchemeMode: MiuixColorMode.light,
        lightColors: light,
        darkColors: dark,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            // The controller is the live overload, so it must win over stale
            // direct data when both are temporarily present during migration.
            data: MiuixThemeData.defaults(
              mode: MiuixColorMode.light,
              seedColor: const Color(0xFFFFB21D),
            ),
            controller: controller,
            child: Builder(
              builder: (context) => ColoredBox(
                key: const ValueKey('controller-theme-probe'),
                color: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${MiuixTheme.colorSchemeModeOf(context)} '
                  '${MiuixTheme.isDynamicColorOf(context)}',
                ),
              ),
            ),
          ),
        ),
      );
      var probe = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('controller-theme-probe')),
      );
      expect(probe.color, light.primary);
      expect(find.text('MiuixColorMode.light false'), findsOneWidget);

      controller.setMode(MiuixColorMode.dark);
      await tester.pump();
      probe = tester.widget<ColoredBox>(
        find.byKey(const ValueKey('controller-theme-probe')),
      );
      expect(probe.color, dark.primary);
      expect(find.text('MiuixColorMode.dark false'), findsOneWidget);

      controller.setMode(MiuixColorMode.monetDark);
      await tester.pump();
      expect(find.text('MiuixColorMode.monetDark true'), findsOneWidget);
    },
  );

  test('Monet color specs follow the upstream 2025 support matrix', () {
    const seed = Color(0xFF3482FF);

    ColorScheme schemeFor(
      MiuixThemePaletteStyle style,
      MiuixThemeColorSpec spec,
    ) {
      return MiuixThemeData.defaults(
        mode: MiuixColorMode.monetLight,
        seedColor: seed,
        paletteStyle: style,
        colorSpec: spec,
      ).lightScheme;
    }

    List<int> fingerprint(ColorScheme scheme) => <int>[
      scheme.primary.toARGB32(),
      scheme.primaryContainer.toARGB32(),
      scheme.secondary.toARGB32(),
      scheme.tertiaryContainer.toARGB32(),
      scheme.surface.toARGB32(),
      scheme.surfaceContainerHigh.toARGB32(),
      scheme.outline.toARGB32(),
    ];

    // These are the four variants accepted by MaterialKolor's SPEC_2025
    // implementation in ThemeController.kt.
    const supported = <MiuixThemePaletteStyle>[
      MiuixThemePaletteStyle.tonalSpot,
      MiuixThemePaletteStyle.neutral,
      MiuixThemePaletteStyle.vibrant,
      MiuixThemePaletteStyle.expressive,
    ];
    for (final style in supported) {
      expect(
        fingerprint(schemeFor(style, MiuixThemeColorSpec.spec2025)),
        isNot(
          equals(fingerprint(schemeFor(style, MiuixThemeColorSpec.spec2021))),
        ),
        reason: '${style.name} must retain the requested 2025 algorithm',
      );
    }

    // Unsupported source variants must gracefully resolve to SPEC_2021.
    const fallback = <MiuixThemePaletteStyle>[
      MiuixThemePaletteStyle.rainbow,
      MiuixThemePaletteStyle.fruitSalad,
      MiuixThemePaletteStyle.monochrome,
      MiuixThemePaletteStyle.fidelity,
      MiuixThemePaletteStyle.content,
    ];
    for (final style in fallback) {
      expect(
        fingerprint(schemeFor(style, MiuixThemeColorSpec.spec2025)),
        fingerprint(schemeFor(style, MiuixThemeColorSpec.spec2021)),
        reason: '${style.name} must use the source 2021 fallback',
      );
    }

    // Lock representative roles to the same deterministic seed used by the
    // example. This catches a future accidental return to Flutter's bundled
    // 2021-only ColorScheme.fromSeed implementation.
    final tonal2021 = schemeFor(
      MiuixThemePaletteStyle.tonalSpot,
      MiuixThemeColorSpec.spec2021,
    );
    final tonal2025 = schemeFor(
      MiuixThemePaletteStyle.tonalSpot,
      MiuixThemeColorSpec.spec2025,
    );
    expect(tonal2021.primary, const Color(0xFF455E91));
    expect(tonal2021.primaryContainer, const Color(0xFFD8E2FF));
    expect(tonal2025.primary, const Color(0xFF4A5F8B));
    expect(tonal2025.primaryContainer, const Color(0xFFB7CCFF));
    expect(tonal2025.surfaceContainerHigh, const Color(0xFFE7E7F1));
  });

  test('generated semantic colors preserve distinct Material roles', () {
    final generated = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetLight,
      colorSpec: MiuixThemeColorSpec.spec2025,
    ).lightScheme;
    // Distinct sentinels prove the adapter does not silently substitute the
    // newer nearest-role aliases for values still consumed by MIUIX.
    // ignore: deprecated_member_use
    final scheme = generated.copyWith(
      // ignore: deprecated_member_use
      background: const Color(0xFF102030),
      // ignore: deprecated_member_use
      onBackground: const Color(0xFFF1F2F3),
      // ignore: deprecated_member_use
      surfaceVariant: const Color(0xFF405060),
      surfaceContainerHighest: const Color(0xFF708090),
    );
    final colors = MiuixSemanticColors.fromScheme(scheme);

    expect(colors['background'], const Color(0xFF102030));
    expect(colors['onBackground'], const Color(0xFFF1F2F3));
    expect(colors['surfaceVariant'], const Color(0xFF405060));
    expect(colors['surfaceVariant'], isNot(scheme.surfaceContainerHighest));
  });

  test('glass intensity exposes five monotonic source modifiers', () {
    const levels = MiuixGlassIntensity.values;
    expect(levels, hasLength(5));

    final blurs = levels.map((level) => level.resolveBlur(20)).toList();
    final opacities = levels.map((level) => level.resolveOpacity(.72)).toList();
    for (var index = 1; index < levels.length; index++) {
      expect(blurs[index], greaterThan(blurs[index - 1]));
      expect(opacities[index], lessThan(opacities[index - 1]));
    }
    expect(MiuixGlassIntensity.standard.resolveBlur(20), 20);
    expect(MiuixGlassIntensity.standard.resolveOpacity(.72), .72);
    expect(MiuixGlassIntensity.intense.resolveBlur(20), 45);
    expect(
      MiuixGlassIntensity.intense.resolveOpacity(.72),
      closeTo(.1584, .000001),
    );
  });

  test('navigation optics keep strong glass clear and structured', () {
    const optics = MiuixGlassOptics.navigation;
    const levels = MiuixGlassIntensity.values;
    final blurs = levels.map((level) => optics.resolveBlur(28, level)).toList();
    final opacities = levels
        .map((level) => optics.resolveOpacity(.58, level))
        .toList();

    // The five settings remain ordered, but the clearest navigation material
    // caps blur well below the legacy 2.25x scaling that erased page detail.
    for (var index = 1; index < levels.length; index++) {
      expect(blurs[index], greaterThan(blurs[index - 1]));
      expect(opacities[index], lessThan(opacities[index - 1]));
    }
    expect(blurs[MiuixGlassIntensity.standard.index], 28);
    expect(blurs.last, closeTo(34.72, .000001));
    expect(opacities[MiuixGlassIntensity.standard.index], .58);
    expect(opacities.last, closeTo(.0928, .000001));
  });

  test('transient optics keep five popup levels ordered and readable', () {
    const optics = MiuixGlassOptics.transient;
    const levels = MiuixGlassIntensity.values;
    final blurs = levels.map((level) => optics.resolveBlur(24, level)).toList();
    final opacities = levels
        .map((level) => optics.resolveOpacity(.66, level))
        .toList();

    for (var index = 1; index < levels.length; index++) {
      expect(blurs[index], greaterThan(blurs[index - 1]));
      expect(opacities[index], lessThan(opacities[index - 1]));
    }
    // Standard popups are clearer than ordinary content cards, while level
    // five still retains enough tint to separate text from complex imagery.
    expect(blurs[MiuixGlassIntensity.standard.index], 24);
    expect(opacities[MiuixGlassIntensity.standard.index], closeTo(.5412, 1e-9));
    expect(opacities.last, closeTo(.1188, 1e-9));
  });

  testWidgets('glass adds blur and a visible reflection only when enabled', (
    tester,
  ) async {
    Future<void> pumpGlass(bool enabled) {
      return tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              enableGlass: enabled,
              glassIntensity: MiuixGlassIntensity.intense,
            ),
            child: const Center(
              child: MiuixGlass(
                key: ValueKey('glass-under-test'),
                opacity: .40,
                padding: EdgeInsets.all(12),
                child: Text('Glass'),
              ),
            ),
          ),
        ),
      );
    }

    await pumpGlass(true);
    final glass = find.byKey(const ValueKey('glass-under-test'));
    expect(
      find.descendant(of: glass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: glass,
        matching: find.byKey(const ValueKey('miuix-glass-specular-highlight')),
      ),
      findsOneWidget,
    );
    final tintedSurface = tester.widget<DecoratedBox>(
      find.descendant(of: glass, matching: find.byType(DecoratedBox)).first,
    );
    expect(
      (tintedSurface.decoration as ShapeDecoration).color!.a,
      closeTo(.088, .001),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Glass')),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: glass,
        matching: find.byKey(const ValueKey('miuix-glass-interactive-light')),
      ),
      findsOneWidget,
    );
    await gesture.moveBy(const Offset(18, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pump();

    await pumpGlass(false);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(
      find.byKey(const ValueKey('miuix-glass-specular-highlight')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('glass keeps tint reflection and clipping on an explicit shape', (
    tester,
  ) async {
    const shape = StadiumBorder();
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 112,
              height: 56,
              child: MiuixGlass(
                key: ValueKey('shaped-glass'),
                shape: shape,
                border: BorderSide(color: Colors.red, width: 1),
                padding: EdgeInsets.zero,
                child: Text('Action'),
              ),
            ),
          ),
        ),
      ),
    );

    final glass = find.byKey(const ValueKey('shaped-glass'));
    final clip = tester.widget<ClipPath>(
      find.descendant(of: glass, matching: find.byType(ClipPath)),
    );
    expect((clip.clipper! as ShapeBorderClipper).shape, shape);
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(of: glass, matching: find.byType(DecoratedBox)),
        )
        .map((widget) => widget.decoration)
        .whereType<ShapeDecoration>()
        .toList();
    expect(decorations, hasLength(2));
    expect(
      decorations.every((decoration) => decoration.shape == shape),
      isTrue,
    );
    expect(
      find.descendant(of: glass, matching: find.byType(CustomPaint)),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic component supports source bottom action and margin', (
    tester,
  ) async {
    const margin = EdgeInsets.fromLTRB(16, 16, 16, 0);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixCard(
              child: MiuixBasicComponent(
                title: 'Blur Radius',
                trailing: Text('100'),
                bottomAction: SizedBox(
                  key: ValueKey('basic-bottom-action'),
                  height: 28,
                ),
                insideMargin: margin,
                standalone: false,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('basic-bottom-action')), findsOneWidget);
    final paddings = tester.widgetList<Padding>(
      find.descendant(
        of: find.byType(MiuixBasicComponent),
        matching: find.byType(Padding),
      ),
    );
    expect(paddings.any((padding) => padding.padding == margin), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('layer backdrop paints ordered MIUIX blend colors', (
    tester,
  ) async {
    // The Compose public API interprets 100 as dp. It multiplies by density
    // before rasterization; Flutter's logical sigma is therefore 100 * 0.45
    // at every DPR rather than dividing by density a second time.
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            // TextureBlur has its own enabled flag in MIUIX. It must not be
            // disabled by the separate app-wide component-glass setting.
            enableGlass: false,
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: const Scaffold(
            body: Center(
              child: MiuixLayerBackdrop(
                backdrop: MiuixBackdrop(
                  blur: 100,
                  colors: MiuixBlurColors(
                    opacity: 0,
                    blendColors: [
                      MiuixBlurBlendEntry(
                        Color(0x803F3F3F),
                        MiuixBlurBlendMode.overlay,
                      ),
                      MiuixBlurBlendEntry(
                        Color(0x1CE6E6E6),
                        MiuixBlurBlendMode.plusLighter,
                      ),
                    ],
                  ),
                ),
                child: SizedBox(width: 200, height: 100),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('miuix-blur-blend-layers')),
      ImageFilter.isShaderFilterSupported ? findsNothing : findsOneWidget,
    );
    expect(find.byType(BackdropFilter), findsOneWidget);
    const sourceSigma = 100 * .45;
    expect(
      tester
          .widgetList<MiuixGlass>(find.byType(MiuixGlass))
          .every((glass) => (glass.blur - sourceSigma).abs() < 1e-9),
      isTrue,
    );
    // Explicit texture blur deliberately omits the iOS reflection used by
    // navigation glass; its numeric radius remains independent of level five.
    expect(
      find.byKey(const ValueKey('miuix-glass-specular-highlight')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('foreground blur uses a DstIn glyph mask and plain fallback', (
    tester,
  ) async {
    // The Android reference device is 3x. Keeping the production density here
    // prevents a DPR=1-only test from accepting an inverted mask transform.
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> pumpForeground({required bool enabled}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Color(0xFF4D8EFF)),
                  Center(
                    child: MiuixForegroundBlurText(
                      text: 'MIUIX',
                      fillWidth: false,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                      ),
                      backdrop: MiuixBackdrop(
                        blur: 40,
                        enabled: enabled,
                        colors: const MiuixBlurColors(
                          tint: Colors.transparent,
                          opacity: 0,
                        ),
                      ),
                      fallbackGradient: const LinearGradient(
                        colors: [Color(0xFF5B1AA8), Color(0xFF88472C)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
    }

    await pumpForeground(enabled: true);
    final mask = find.byKey(const ValueKey('miuix-foreground-blur-mask'));
    expect(mask, findsOneWidget);
    final fallbackText = find.descendant(
      of: mask,
      matching: find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == 'MIUIX',
      ),
    );
    expect(fallbackText, findsOneWidget);
    expect(tester.widget<Text>(fallbackText).textSpan, isNull);
    expect(find.byType(BackdropFilter), findsNothing);
    await expectLater(
      mask,
      matchesGoldenFile('goldens/foreground_blur/dpr3_mask.png'),
    );

    await pumpForeground(enabled: false);
    expect(mask, findsNothing);
    expect(find.text('MIUIX'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('smooth corner border differs from a circular rounded rectangle', () {
    const rect = Rect.fromLTWH(0, 0, 120, 80);
    const smoothBorder = MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
    final smooth = smoothBorder.getOuterPath(rect);
    final circular = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(24)));
    var foundDifference = false;
    for (var y = 0.0; y <= 32 && !foundDifference; y += 1) {
      for (var x = 0.0; x <= 32; x += 1) {
        final point = Offset(x, y);
        if (smooth.contains(point) != circular.contains(point)) {
          foundDifference = true;
          break;
        }
      }
    }
    expect(foundDifference, isTrue);

    final rectangle = const MiuixSquircleBorder(
      borderRadius: BorderRadius.zero,
    ).getOuterPath(rect);
    expect(rectangle.contains(const Offset(1, 1)), isTrue);
    expect(rectangle.contains(const Offset(-1, -1)), isFalse);
  });

  test('squircle border follows current upstream cubic constants', () {
    const rect = Rect.fromLTWH(0, 0, 120, 80);
    const radius = 24.0;
    const extension = 1.1;
    const control = .643;
    const tile = radius * extension;
    const handle = tile * (1 - control);
    final expected = Path()
      ..moveTo(tile, 0)
      ..lineTo(rect.right - tile, 0)
      ..cubicTo(rect.right - handle, 0, rect.right, handle, rect.right, tile)
      ..lineTo(rect.right, rect.bottom - tile)
      ..cubicTo(
        rect.right,
        rect.bottom - handle,
        rect.right - handle,
        rect.bottom,
        rect.right - tile,
        rect.bottom,
      )
      ..lineTo(tile, rect.bottom)
      ..cubicTo(
        handle,
        rect.bottom,
        0,
        rect.bottom - handle,
        0,
        rect.bottom - tile,
      )
      ..lineTo(0, tile)
      ..cubicTo(0, handle, handle, 0, tile, 0)
      ..close();
    final actual = const MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(radius)),
    ).getOuterPath(rect);

    // Paths have no geometric equality operator. Sampling quarter-pixel
    // centers catches both the former 1.2 extension and 0.63 control ratio.
    Offset? mismatch;
    for (var y = .125; y < 40 && mismatch == null; y += .25) {
      for (var x = .125; x < 40; x += .25) {
        final point = Offset(x, y);
        if (actual.contains(point) != expected.contains(point)) {
          mismatch = point;
          break;
        }
      }
    }
    expect(mismatch, isNull, reason: 'first differing sample: $mismatch');
  });

  test(
    'static squircle asset preserves the exact upstream SDF bytes',
    () async {
      ByteData encoded;
      try {
        encoded = await rootBundle.load(
          'packages/flutter_miuix/assets/squircle/miuix_squircle_sdf.png',
        );
      } catch (_) {
        encoded = await rootBundle.load(
          'assets/squircle/miuix_squircle_sdf.png',
        );
      }
      final codec = await ui.instantiateImageCodec(
        encoded.buffer.asUint8List(
          encoded.offsetInBytes,
          encoded.lengthInBytes,
        ),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      expect(frame.image.width, 512);
      expect(frame.image.height, 512);
      final rgba = await frame.image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      expect(rgba, isNotNull);
      final pixels = rgba!.buffer.asUint8List(
        rgba.offsetInBytes,
        rgba.lengthInBytes,
      );
      var alphaCount = 0;
      var fingerprint = 0x811c9dc5;
      for (var index = 3; index < pixels.length; index += 4) {
        fingerprint = ((fingerprint ^ pixels[index]) * 0x01000193) & 0xffffffff;
        alphaCount++;
      }
      frame.image.dispose();

      // FNV-1a covers all 262,144 upstream alpha values. It changes if the
      // generator, PNG decoding, or checked-in BakedSquircleSdf table drifts.
      expect(alphaCount, 512 * 512);
      expect(fingerprint, 0x7568ac5a);
    },
  );

  testWidgets('surface follows the global smooth-rounding switch', (
    tester,
  ) async {
    Future<void> pump({required bool enabled}) => tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(enableSquircle: enabled),
          child: const Center(
            child: MiuixSurface(
              key: ValueKey('shape-switch-surface'),
              child: Text('Shape'),
            ),
          ),
        ),
      ),
    );

    ShapeBorder currentShape() {
      final clipFinder = find.descendant(
        of: find.byKey(const ValueKey('shape-switch-surface')),
        matching: find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == '_MiuixSurfaceClip',
        ),
      );
      final dynamic clip = tester.widget(clipFinder);
      return (clip.clipper as ShapeBorderClipper).shape;
    }

    await pump(enabled: true);
    expect(currentShape(), isA<MiuixSquircleBorder>());
    final surfacePadding = tester.widget<Padding>(
      find.descendant(
        of: find.byKey(const ValueKey('shape-switch-surface')),
        matching: find.byType(Padding),
      ),
    );
    final surfaceFill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(const ValueKey('shape-switch-surface')),
        matching: find.byType(ColoredBox),
      ),
    );
    // Surface.kt defaults are RectangleShape, surface, zero inset/elevation.
    expect(surfacePadding.padding, EdgeInsets.zero);
    expect(
      surfaceFill.color,
      Theme.of(tester.element(find.text('Shape'))).colorScheme.surface,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('shape-switch-surface')),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
    expect(
      (currentShape() as MiuixSquircleBorder).borderRadius,
      BorderRadius.zero,
    );
    await pump(enabled: false);
    expect(currentShape(), isA<RoundedRectangleBorder>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface normalizes invalid radius in every render branch', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Row(
            children: <Widget>[
              MiuixSurface(
                key: ValueKey('invalid-solid-radius'),
                radius: -8,
                child: SizedBox.square(dimension: 20),
              ),
              MiuixSurface(
                key: ValueKey('invalid-glass-radius'),
                radius: double.nan,
                glass: true,
                child: SizedBox.square(dimension: 20),
              ),
            ],
          ),
        ),
      ),
    );

    final solid = tester.widget<MiuixSquircleSurface>(
      find.descendant(
        of: find.byKey(const ValueKey('invalid-solid-radius')),
        matching: find.byType(MiuixSquircleSurface),
      ),
    );
    final glass = tester.widget<MiuixGlass>(
      find.descendant(
        of: find.byKey(const ValueKey('invalid-glass-radius')),
        matching: find.byType(MiuixGlass),
      ),
    );
    expect(solid.borderRadius, BorderRadius.zero);
    expect(glass.radius, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface exposes source shape content color and enabled state', (
    tester,
  ) async {
    const surfaceKey = ValueKey('source-surface');
    const textKey = ValueKey('source-surface-text');
    const iconKey = ValueKey('source-surface-icon');
    const shape = StadiumBorder();
    const foreground = Color(0xff12abef);
    const background = Color(0xff203040);
    var taps = 0;

    Widget buildSurface({required bool enabled}) {
      return MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixSurface(
              key: surfaceKey,
              color: background,
              contentColor: foreground,
              shape: shape,
              border: const BorderSide(color: Colors.amber, width: 2),
              shadowElevation: 4,
              enabled: enabled,
              onTap: () => taps++,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiuixIcon(Icons.star, key: iconKey),
                  Text('Surface', key: textKey),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildSurface(enabled: false));
    final fill = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(ColoredBox),
      ),
    );
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(surfaceKey),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((box) => box.decoration)
        .whereType<ShapeDecoration>()
        .toList(growable: false);
    final shadowDecoration = decorations.singleWhere(
      (decoration) => decoration.shadows?.isNotEmpty ?? false,
    );
    expect(fill.color, background);
    expect(shadowDecoration.color, Colors.transparent);
    expect(shadowDecoration.shape, same(shape));
    expect(shadowDecoration.shadows, hasLength(1));
    expect(
      DefaultTextStyle.of(tester.element(find.byKey(textKey))).style.color,
      foreground,
    );
    expect(IconTheme.of(tester.element(find.byKey(iconKey))).color, foreground);
    expect(
      tester
          .widget<Icon>(
            find.descendant(
              of: find.byKey(iconKey),
              matching: find.byType(Icon),
            ),
          )
          .color,
      foreground,
    );
    final disabledPressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(disabledPressable.onTap, isNull);
    expect(disabledPressable.showIndication, isFalse);
    expect(disabledPressable.shape, same(shape));
    expect(disabledPressable.borderRadius, isNull);
    final disabledSemantics = tester
        .widgetList<Semantics>(
          find.descendant(
            of: find.byKey(surfaceKey),
            matching: find.byType(Semantics),
          ),
        )
        .where((semantics) => semantics.properties.enabled == false);
    expect(disabledSemantics, isNotEmpty);
    await tester.tap(find.byKey(surfaceKey));
    await tester.pump();
    expect(taps, 0);

    await tester.pumpWidget(buildSurface(enabled: true));
    final enabledPressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(surfaceKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(enabledPressable.onTap, isNotNull);
    expect(enabledPressable.showIndication, isTrue);
    expect(enabledPressable.shape, same(shape));
    await tester.tap(find.byKey(surfaceKey));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface outer margin is excluded from its click target', (
    tester,
  ) async {
    const surfaceKey = ValueKey('margin-surface');
    const margin = 20.0;
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixSurface(
              key: surfaceKey,
              margin: const EdgeInsets.all(margin),
              color: Colors.blue,
              onTap: () => taps++,
              child: const SizedBox(width: 100, height: 40),
            ),
          ),
        ),
      ),
    );

    final completeRect = tester.getRect(find.byKey(surfaceKey));
    expect(completeRect.size, const Size(140, 80));
    // The old implementation wrapped margin inside GestureDetector, so this
    // transparent point incorrectly activated the surface. Compose applies a
    // caller padding modifier outside `.surface().clickable()`.
    await tester.tapAt(
      Offset(completeRect.left + 5, completeRect.top + completeRect.height / 2),
    );
    await tester.pump();
    expect(taps, 0);

    await tester.tapAt(completeRect.center);
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary surface propagates incoming minimum constraints', (
    tester,
  ) async {
    const surfaceKey = ValueKey('minimum-surface');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 120, minHeight: 80),
              child: const MiuixSurface(
                key: surfaceKey,
                child: SizedBox(width: 10, height: 10),
              ),
            ),
          ),
        ),
      ),
    );

    // This mirrors Box(propagateMinConstraints = true) in Surface.kt. The
    // content remains small, but the surface and its semantic group retain the
    // complete minimum supplied by the caller.
    expect(tester.getSize(find.byKey(surfaceKey)), const Size(120, 80));
    final surfaceSemantics = tester.getSemantics(find.byKey(surfaceKey));
    expect(surfaceSemantics.rect.size, const Size(120, 80));
    expect(tester.takeException(), isNull);
  });

  testWidgets('surface hold state cannot manufacture a clickable overload', (
    tester,
  ) async {
    const surfaceKey = ValueKey('callback-free-held-surface');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixSurface(
              key: surfaceKey,
              holdDown: true,
              showIndication: true,
              feedbackType: MiuixPressFeedbackType.sink,
              child: Text('Ordinary surface'),
            ),
          ),
        ),
      ),
    );

    final surface = find.byKey(surfaceKey);
    // Surface.kt's non-clickable overload owns traversal semantics only. A
    // package-only held flag must not synthesize the clickable overload or
    // install pointer, hover, focus, keyboard, or accessibility activation.
    expect(
      find.descendant(of: surface, matching: find.byType(MiuixPressable)),
      findsNothing,
    );
    final semantics = tester.getSemantics(surface).getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);
    expect(semantics.hasAction(SemanticsAction.longPress), isFalse);
    expect(semantics.flagsCollection.isButton, isFalse);
    expect(
      find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('application cards separate HyperOS glass and source material', (
    tester,
  ) async {
    List<Widget> cards({required bool source}) => source
        ? <Widget>[
            const MiuixAccountHeader.source(
              key: ValueKey('account-card'),
              name: 'Account',
            ),
            const MiuixDeviceCard.source(
              key: ValueKey('device-card'),
              name: 'Phone',
              status: 'Connected',
            ),
            const MiuixAppListTile.source(
              key: ValueKey('app-card'),
              name: 'Settings',
            ),
            const MiuixNotificationCard.source(
              key: ValueKey('notification-card'),
              title: 'Ready',
              body: 'Update ready',
            ),
            MiuixPermissionCard.source(
              key: const ValueKey('permission-card'),
              permission: 'Camera',
              description: 'Used to scan codes',
              onAllow: () {},
              onDeny: () {},
            ),
            const MiuixUpdateCard.source(
              key: ValueKey('update-card'),
              version: '1.0',
              summary: 'Stable update',
            ),
          ]
        : <Widget>[
            const MiuixAccountHeader(
              key: ValueKey('account-card'),
              name: 'Account',
            ),
            const MiuixDeviceCard(
              key: ValueKey('device-card'),
              name: 'Phone',
              status: 'Connected',
            ),
            const MiuixAppListTile(key: ValueKey('app-card'), name: 'Settings'),
            const MiuixNotificationCard(
              key: ValueKey('notification-card'),
              title: 'Ready',
              body: 'Update ready',
            ),
            MiuixPermissionCard(
              key: const ValueKey('permission-card'),
              permission: 'Camera',
              description: 'Used to scan codes',
              onAllow: () {},
              onDeny: () {},
            ),
            const MiuixUpdateCard(
              key: ValueKey('update-card'),
              version: '1.0',
              summary: 'Stable update',
            ),
          ];

    Future<void> pumpCards({required bool source}) => tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              cardCornerRadius: 27,
              contentSurfaceBlur: 33,
              contentSurfaceTintOpacity: .42,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(children: cards(source: source)),
          ),
        ),
      ),
    );

    const keys = <String>[
      'account-card',
      'device-card',
      'app-card',
      'notification-card',
      'permission-card',
      'update-card',
    ];

    await pumpCards(source: false);
    for (final key in keys) {
      final host = find.byKey(ValueKey<String>(key));
      final cardFinder = find.descendant(
        of: host,
        matching: find.byType(MiuixCard),
      );
      final surface = tester.widget<MiuixSurface>(
        find
            .descendant(of: cardFinder, matching: find.byType(MiuixSurface))
            .first,
      );
      expect(surface.glass, isTrue, reason: key);
      expect(surface.glassBlur, 33, reason: key);
      expect(surface.glassOpacity, .42, reason: key);
      expect(surface.showGlassSpecular, isTrue, reason: key);
      expect(surface.radius, 27, reason: key);
    }

    await pumpCards(source: true);
    for (final key in keys) {
      final host = find.byKey(ValueKey<String>(key));
      final cardFinder = find.descendant(
        of: host,
        matching: find.byType(MiuixCard),
      );
      final card = tester.widget<MiuixCard>(cardFinder);
      expect(card.glass, isFalse, reason: key);
      expect(card.showGlassSpecular, isFalse, reason: key);
      expect(card.cornerRadius, MiuixCardDefaults.legacyCornerRadius);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixAccountHeader(
            name: 'Custom',
            glass: false,
            glassBlur: 37,
            glassOpacity: .31,
            showGlassSpecular: false,
            cornerRadius: 35,
          ),
        ),
      ),
    );
    final customSurface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixAccountHeader),
        matching: find.byType(MiuixSurface),
      ),
    );
    expect(customSurface.glass, isFalse);
    expect(customSurface.glassBlur, 37);
    expect(customSurface.glassOpacity, .31);
    expect(customSurface.showGlassSpecular, isFalse);
    expect(customSurface.radius, 35);
  });

  testWidgets('builds theme, preferences, navigation, and effects', (
    tester,
  ) async {
    var selected = 0;
    var enabled = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return MiuixScaffold(
                topBar: const MiuixSmallTopAppBar(title: 'Test'),
                bottomBar: MiuixNavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (index) =>
                      setState(() => selected = index),
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
                body: ListView(
                  children: [
                    const MiuixCard(child: Text('Card')),
                    const MiuixBasicComponent(title: 'Basic'),
                    const MiuixTextButton(
                      label: 'Text action',
                      onPressed: null,
                    ),
                    const MiuixBadgedBox(
                      badge: MiuixBadge(label: '1', child: SizedBox.shrink()),
                      child: Icon(Icons.mail_outline),
                    ),
                    const MiuixHorizontalDivider(),
                    const SizedBox(height: 24, child: MiuixVerticalDivider()),
                    MiuixSwitchPreference(
                      title: 'Switch',
                      value: enabled,
                      onChanged: (value) => setState(() => enabled = value),
                    ),
                    MiuixRadioButtonPreference<int>(
                      title: 'Radio',
                      value: 1,
                      groupValue: 1,
                      onChanged: (_) {},
                    ),
                    MiuixRangeSliderPreference(
                      title: 'Range',
                      values: const RangeValues(0.2, 0.8),
                      onChanged: (_) {},
                    ),
                    MiuixColorPalette(
                      colors: const [Colors.blue, Colors.green, Colors.red],
                      selected: Colors.blue,
                      onSelected: (_) {},
                    ),
                    MiuixColorPicker(color: Colors.blue, onChanged: (_) {}),
                    MiuixHsvHueSlider(value: 120, onChanged: (_) {}),
                    MiuixOkLabAChannelSlider(value: 0, onChanged: (_) {}),
                    MiuixVerticalSlider(value: 0.4, onChanged: (_) {}),
                    const MiuixLinearProgressIndicator(value: 0.3),
                    const MiuixCircularProgressIndicator(value: 0.5),
                    const MiuixInfiniteProgressIndicator(),
                    const MiuixVerticalScrollBar(
                      child: SizedBox(
                        height: 48,
                        child: SingleChildScrollView(
                          child: Text('Scroll adapter'),
                        ),
                      ),
                    ),
                    const MiuixOverscrollEffect(
                      child: SizedBox(height: 24, child: Text('Overscroll')),
                    ),
                    MiuixFloatingToolbar(
                      children: [
                        MiuixIconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const MiuixTooltipBox(
                      message: 'Tooltip',
                      child: Text('Tooltip target'),
                    ),
                    const MiuixRichTooltipBox(
                      message: 'Rich tooltip',
                      content: Text('Details'),
                      child: Text('Rich tooltip target'),
                    ),
                    const MiuixSnackbarHost(child: Text('Snackbar host')),
                    const MiuixLayerBackdrop(child: Text('Backdrop')),
                    MiuixControlSliderTile(
                      icon: const Icon(Icons.brightness_6),
                      label: 'Brightness',
                      value: 0.6,
                      onChanged: (_) {},
                    ),
                    const MiuixAccountHeader(
                      name: 'Mi Account',
                      subtitle: 'Signed in',
                    ),
                    const MiuixDeviceCard(
                      name: 'Xiaomi Phone',
                      status: 'Connected',
                      battery: 88,
                    ),
                    const MiuixAppListTile(
                      name: 'Settings',
                      packageName: 'com.android.settings',
                    ),
                    const MiuixNotificationCard(
                      title: 'Update ready',
                      body: 'A system update is available.',
                    ),
                    MiuixPermissionCard(
                      permission: 'Location',
                      description: 'Allow access while using the app.',
                      onAllow: () {},
                      onDeny: () {},
                    ),
                    MiuixUpdateCard(
                      version: 'HyperOS 2.0',
                      summary: 'Security patch and stability improvements.',
                      progress: 0.4,
                      onUpdate: () {},
                    ),
                    const MiuixInlineAlert(message: 'Security scan complete.'),
                    const MiuixBanner(
                      title: 'Tips',
                      message: 'Tune your quick settings layout.',
                    ),
                    const MiuixEmptyState(
                      title: 'No devices',
                      message: 'Pair a device to continue.',
                    ),
                    const MiuixExpandableCard(
                      title: 'Advanced',
                      children: [MiuixText('Advanced settings')],
                    ),
                    const MiuixPageIndicator(count: 3, index: 1),
                    const MiuixGlass(child: Text('Glass')),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Card'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    final controller = MiuixThemeController();
    controller.setMode(MiuixColorMode.dark);
    expect(controller.data.mode, MiuixColorMode.dark);
    expect(MiuixHsv.fromColor(Colors.blue).toColor(), isA<Color>());
    expect(MiuixIcons.basic.search, MiuixBasicIconCatalog.search);
    expect(MiuixIcons.basic.search.fontFamily, 'MiuixIconsBasic');
  });

  testWidgets('builds source parity adapters without lazy scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  const MiuixTextButton(label: 'Text adapter', onPressed: null),
                  const MiuixBadgedBox(
                    badge: MiuixBadge(label: '2', child: SizedBox.shrink()),
                    child: Icon(Icons.mail_outline),
                  ),
                  const MiuixHorizontalDivider(),
                  const SizedBox(height: 24, child: MiuixVerticalDivider()),
                  MiuixHsvHueSlider(value: 180, onChanged: (_) {}),
                  MiuixOkLchHueSlider(value: 90, onChanged: (_) {}),
                  MiuixVerticalSlider(value: 0.5, onChanged: (_) {}),
                  const MiuixLinearProgressIndicator(value: 0.2),
                  const MiuixCircularProgressIndicator(value: 0.4),
                  const MiuixInfiniteProgressIndicator(circular: true),
                  const MiuixVerticalScrollBar(
                    child: SizedBox(
                      height: 48,
                      child: SingleChildScrollView(
                        child: Text('Scroll adapter'),
                      ),
                    ),
                  ),
                  const MiuixOverscrollEffect(child: Text('Overscroll')),
                  const MiuixTooltipBox(
                    message: 'Tooltip',
                    child: Text('Tooltip target'),
                  ),
                  const MiuixRichTooltipBox(
                    message: 'Rich tooltip',
                    content: Text('Details'),
                    child: Text('Rich tooltip target'),
                  ),
                  const MiuixSnackbarHost(child: Text('Snackbar host')),
                  const MiuixLayerBackdrop(child: Text('Backdrop')),
                  const MiuixGlass(child: Text('Glass')),
                  const MiuixPopupHost.scope(
                    child: MiuixDialogLayout(child: Text('Dialog layout')),
                  ),
                  MiuixDropdownImpl(
                    text: 'Dropdown impl',
                    optionSize: 1,
                    isSelected: true,
                    index: 0,
                    onSelectedIndexChange: (_) {},
                  ),
                  MiuixInputField(
                    query: '',
                    onQueryChange: (_) {},
                    onSearch: (_) {},
                    expanded: false,
                    onExpandedChange: (_) {},
                    label: 'Input field',
                  ),
                  DefaultTabController(
                    length: 2,
                    child: MiuixTabRow(tabs: const ['A', 'B'], onTap: (_) {}),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Text adapter'), findsOneWidget);
    expect(find.text('Backdrop'), findsOneWidget);
    expect(find.text('Glass'), findsOneWidget);
    expect(find.text('Dialog layout'), findsOneWidget);
    final inlineDialogSurface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixDialogLayout),
        matching: find.byType(MiuixSurface),
      ),
    );
    expect(inlineDialogSurface.glass, isTrue);
    expect(inlineDialogSurface.glassOptics, same(MiuixGlassOptics.transient));
    final source = MiuixInteractionSource()..setPressed(true);
    expect(source.pressed, isTrue);
    expect(MiuixColor.fromARGB32(0xFF0000FF).value, isA<Color>());
    expect(const MiuixRuntimeShader(name: 'test').name, 'test');
  });

  testWidgets('page indicator uses HyperOS motion and settles when reduced', (
    tester,
  ) async {
    var index = 0;
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
                data: MiuixThemeData.defaults().copyWith(
                  hyperOs4: const MiuixHyperOs4Tokens(
                    pageIndicatorMotion: Duration(milliseconds: 444),
                    pageIndicatorDotSize: 8,
                    pageIndicatorActiveWidth: 22,
                    pageIndicatorSpacing: 3,
                  ),
                ),
                child: Scaffold(
                  body: Center(
                    child: MiuixPageIndicator(count: 2, index: index),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    Finder dots() => find.descendant(
      of: find.byType(MiuixPageIndicator),
      matching: find.byType(AnimatedContainer),
    );
    List<double> widths() => List<double>.generate(
      dots().evaluate().length,
      (dotIndex) => tester.getSize(dots().at(dotIndex)).width,
      growable: false,
    );
    expect(
      tester
          .widgetList<AnimatedContainer>(dots())
          .every((dot) => dot.duration == const Duration(milliseconds: 444)),
      isTrue,
    );
    // Rendered extents include the tokenized 3dp margin on both sides.
    expect(widths(), const <double>[28, 14]);

    updateHost(() => index = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final intermediate = widths();
    expect(intermediate[0], inExclusiveRange(14, 28));
    expect(intermediate[1], inExclusiveRange(14, 28));

    // Changing the inherited policy while both dots are animating must
    // discard their sampled widths and rebuild the exact controlled state.
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(widths(), const <double>[14, 28]);
    expect(
      tester
          .widgetList<AnimatedContainer>(dots())
          .every((dot) => dot.duration == Duration.zero),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('page indicator source constructor retains former geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              pageIndicatorDotSize: 12,
              pageIndicatorActiveWidth: 30,
              pageIndicatorSpacing: 7,
            ),
          ),
          child: const MiuixPageIndicator.source(count: 2, index: 0),
        ),
      ),
    );

    final dots = find.descendant(
      of: find.byType(MiuixPageIndicator),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(dots.at(0)), const Size(21, 6));
    expect(tester.getSize(dots.at(1)), const Size(11, 6));
  });

  testWidgets('guards unstable inputs without framework assertions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  MiuixSlider(
                    value: double.nan,
                    min: 10,
                    max: 2,
                    divisions: -4,
                    onChanged: (_) {},
                  ),
                  MiuixRangeSlider(
                    values: const RangeValues(8, -3),
                    min: 5,
                    max: 5,
                    divisions: 0,
                    onChanged: (_) {},
                  ),
                  MiuixControlSliderTile(
                    icon: const Icon(Icons.volume_up),
                    label: 'Volume',
                    value: double.infinity,
                    min: 1,
                    max: 1,
                    onChanged: (_) {},
                  ),
                  MiuixNumberPicker(
                    value: 999,
                    min: 10,
                    max: 0,
                    step: 0,
                    onChanged: (_) {},
                  ),
                  const MiuixPageIndicator(count: -1, index: 99),
                  MiuixColorPalette(
                    colors: const [Colors.blue, Colors.red],
                    selected: Colors.blue,
                    columns: 0,
                    onSelected: (_) {},
                  ),
                  MiuixColorPalette(
                    colors: const [],
                    selected: Colors.green,
                    columns: -3,
                    onSelected: (_) {},
                  ),
                  MiuixDropdownMenuButton<String>(
                    entries: const [],
                    onSelected: (_) {},
                    child: const Text('Empty menu'),
                  ),
                  MiuixDropdownPreference<String>(
                    title: 'Empty preference',
                    value: 'missing',
                    entries: const [],
                    onChanged: (_) {},
                  ),
                  MiuixDropdownPreference<String>(
                    title: 'Missing preference value',
                    value: 'missing',
                    entries: const [
                      MiuixDropdownEntry(value: 'one', label: 'One'),
                    ],
                    onChanged: (_) {},
                  ),
                  MiuixNavigationBar(
                    selectedIndex: 99,
                    onDestinationSelected: (_) {},
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
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('Empty menu'), findsOneWidget);
    expect(find.text('Empty preference'), findsOneWidget);
  });

  testWidgets('context menu uses source horizontal margin and zero gap', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const anchorKey = ValueKey('context-menu-anchor');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 100,
                right: 16,
                child: MiuixDropdownMenuButton<String>(
                  positioning: MiuixPopupPositioning.contextMenu,
                  alignment: MiuixPopupAlignment.bottomEnd,
                  entries: const [
                    MiuixDropdownEntry(value: 'one', label: 'One'),
                    MiuixDropdownEntry(value: 'two', label: 'Two'),
                  ],
                  onSelected: (_) {},
                  child: const SizedBox(key: anchorKey, width: 40, height: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byKey(anchorKey)));
    await tester.pumpAndSettle();
    final anchorRect = tester.getRect(find.byKey(anchorKey));
    final popupRect = tester.getRect(find.byType(MiuixListPopup<String>));
    expect(popupRect.right, closeTo(anchorRect.right - 20, .001));
    expect(popupRect.top, closeTo(anchorRect.bottom, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown sanitizes non-finite and oversized anchor geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const anchorKey = ValueKey('unstable-popup-anchor');

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: MiuixDropdownMenuButton<String>(
                entries: const [MiuixDropdownEntry(value: 'one', label: 'One')],
                onSelected: (_) {},
                popupAnchorInsets: const EdgeInsets.fromLTRB(
                  double.nan,
                  double.infinity,
                  100,
                  100,
                ),
                popupAnchorOffset: const Offset(double.infinity, double.nan),
                child: const SizedBox(key: anchorKey, width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byKey(anchorKey)));
    await tester.pumpAndSettle();
    final popupRect = tester.getRect(find.byType(MiuixListPopup<String>));
    expect(popupRect.left.isFinite, isTrue);
    expect(popupRect.top.isFinite, isTrue);
    expect(popupRect.width, inInclusiveRange(200, 288));
    expect(tester.takeException(), isNull);
  });

  testWidgets('large top app bar keeps source forty-dp action slot', (
    tester,
  ) async {
    const actionKey = ValueKey('top-app-bar-action-slot');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox.expand(),
          appBar: MiuixTopAppBar(
            title: 'Title',
            large: true,
            actions: [SizedBox(key: actionKey, width: 40, height: 40)],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(actionKey)), const Size(40, 40));
    expect(tester.takeException(), isNull);
  });

  test('theme button styles resolve MIUIX state colors directly', () {
    final materialTheme = MiuixThemeData.defaults().materialTheme(
      Brightness.light,
    );
    final semantic = materialTheme.extension<MiuixSemanticColors>()!;
    final filledStyle = materialTheme.filledButtonTheme.style!;
    final textStyle = materialTheme.textButtonTheme.style!;

    expect(filledStyle.backgroundColor!.resolve({}), semantic['primary']);
    expect(
      filledStyle.backgroundColor!.resolve({WidgetState.disabled}),
      semantic['disabledPrimaryButton'],
    );
    expect(
      filledStyle.foregroundColor!.resolve({WidgetState.disabled}),
      semantic['disabledOnPrimaryButton'],
    );
    expect(
      textStyle.backgroundColor!.resolve({}),
      semantic['secondaryVariant'],
    );
    expect(
      textStyle.foregroundColor!.resolve({WidgetState.disabled}),
      semantic['disabledOnSecondaryVariant'],
    );
  });

  test('button color models keep Kotlin data-class value semantics', () {
    const button = MiuixButtonColors(
      color: Color(0xff102030),
      disabledColor: Color(0xff405060),
      contentColor: Color(0xff708090),
      disabledContentColor: Color(0xffa0b0c0),
    );
    const text = MiuixTextButtonColors(
      color: Color(0xff112233),
      disabledColor: Color(0xff445566),
      textColor: Color(0xff778899),
      disabledTextColor: Color(0xffaabbcc),
    );

    expect(button.copyWith(), button);
    expect(button.copyWith(contentColor: Colors.red).contentColor, Colors.red);
    expect(button.copyWith().hashCode, button.hashCode);
    expect(text.copyWith(), text);
    expect(
      text.copyWith(disabledTextColor: Colors.blue).disabledTextColor,
      Colors.blue,
    );
    expect(text.copyWith().hashCode, text.hashCode);
  });

  testWidgets(
    'source-named primary button factories expose all four channels',
    (tester) async {
      late MiuixButtonColors button;
      late MiuixTextButtonColors text;
      const customDisabledText = Color(0xff123456);
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Builder(
              builder: (context) {
                button = MiuixButtonDefaults.buttonColorsPrimary(context);
                text = MiuixButtonDefaults.textButtonColorsPrimary(
                  context,
                  disabledTextColor: customDisabledText,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(SizedBox));
      final semantic = MiuixSemanticColors.of(context);
      expect(button.color, semantic['primary']);
      expect(button.disabledColor, semantic['disabledPrimaryButton']);
      expect(button.contentColor, semantic['onPrimary']);
      expect(button.disabledContentColor, semantic['disabledOnPrimaryButton']);
      expect(text.color, semantic['primary']);
      expect(text.disabledColor, semantic['disabledPrimaryButton']);
      expect(text.textColor, semantic['onPrimary']);
      expect(text.disabledTextColor, customDisabledText);
    },
  );

  testWidgets('button defaults use MIUIX tonal colors before primary colors', (
    tester,
  ) async {
    const defaultKey = ValueKey('default-button');
    const primaryKey = ValueKey('primary-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              MiuixButton(key: defaultKey, label: 'OK', onPressed: () {}),
              MiuixButton(
                key: primaryKey,
                label: 'OK',
                filled: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    final context = tester.element(find.byKey(defaultKey));
    final scheme = Theme.of(context).colorScheme;
    final semantic = MiuixSemanticColors.of(context);
    final defaultDecoration =
        tester
                .widgetList<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(defaultKey),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .single
                .decoration
            as ShapeDecoration;
    final primaryDecoration =
        tester
                .widgetList<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(primaryKey),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .single
                .decoration
            as ShapeDecoration;

    expect(defaultDecoration.color, semantic['secondaryVariant']);
    expect(primaryDecoration.color, scheme.primary);
    expect(defaultDecoration.shape, isA<MiuixSquircleBorder>());
    expect(
      (defaultDecoration.shape as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(24),
    );
    expect(
      (defaultDecoration.shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    expect(
      (primaryDecoration.shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    expect(
      tester.getSize(find.byKey(defaultKey)).height,
      greaterThanOrEqualTo(48),
    );
    final defaultText = tester.widget<Text>(find.text('OK').first);
    expect(defaultText.style?.fontSize, 17);
    expect(defaultText.style?.fontWeight, FontWeight.w400);
    expect(defaultText.style?.color, semantic['onSecondaryVariant']);
    final buttonPressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(defaultKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(buttonPressable.feedbackType, MiuixPressFeedbackType.none);
    expect(buttonPressable.showIndication, isTrue);
    expect(buttonPressable.shape, same(defaultDecoration.shape));
    expect(buttonPressable.borderRadius, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button follows the HyperOS smooth-rounding theme switch', (
    tester,
  ) async {
    final theme = MiuixThemeData.defaults().copyWith(enableSquircle: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: theme,
          child: Center(
            child: MiuixButton(label: 'Button', onPressed: () {}),
          ),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-button-surface')),
    );
    final decoration = surface.decoration as ShapeDecoration;
    final pressable = tester.widget<MiuixPressable>(
      find.ancestor(
        of: find.byKey(surface.key!),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(decoration.shape, isA<RoundedRectangleBorder>());
    expect(
      (decoration.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(24),
    );
    expect(pressable.shape, same(decoration.shape));
    expect(tester.takeException(), isNull);
  });

  testWidgets('button exposes the complete source content and state contract', (
    tester,
  ) async {
    const buttonKey = ValueKey('source-contract-button');
    const customContentKey = ValueKey('source-contract-content');
    const enabledColor = Color(0xff123456);
    const disabledColor = Color(0xff334455);
    const enabledContent = Color(0xffabcdef);
    const disabledContent = Color(0xfffedcba);
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixButton(
              key: buttonKey,
              onPressed: () => taps++,
              enabled: false,
              cornerRadius: 9,
              minWidth: 140,
              minHeight: 64,
              insideMargin: const EdgeInsets.all(4),
              showIndication: false,
              colors: const MiuixButtonColors(
                color: enabledColor,
                disabledColor: disabledColor,
                contentColor: enabledContent,
                disabledContentColor: disabledContent,
              ),
              child: const SizedBox(
                key: customContentKey,
                width: 80,
                height: 20,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12),
                    SizedBox(width: 7),
                    Text('X'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Button.kt applies defaultMinSize to the complete padded Row. Disabled
    // state changes both source color fields and removes click/indication, but
    // it does not replace or discard the caller's arbitrary content.
    expect(find.byKey(customContentKey), findsOneWidget);
    expect(tester.getSize(find.byKey(buttonKey)), const Size(140, 64));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(buttonKey),
                    matching: find.byKey(
                      const ValueKey('miuix-button-surface'),
                    ),
                  ),
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, disabledColor);
    expect(decoration.shape, isA<MiuixSquircleBorder>());
    expect(
      (decoration.shape as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(9),
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(buttonKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.onTap, isNull);
    expect(pressable.showIndication, isFalse);
    final inheritedText = DefaultTextStyle.of(tester.element(find.text('X')));
    final inheritedIcon = IconTheme.of(tester.element(find.byIcon(Icons.star)));
    expect(inheritedText.style.color, disabledContent);
    expect(inheritedIcon.color, disabledContent);
    expect(
      tester.getSemantics(find.byKey(buttonKey)).flagsCollection.isEnabled,
      Tristate.isFalse,
    );
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('button minimum dimensions remain floors for larger content', (
    tester,
  ) async {
    const buttonKey = ValueKey('large-content-button');
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixButton(
              key: buttonKey,
              onPressed: () => taps++,
              minWidth: 58,
              minHeight: 40,
              insideMargin: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 3,
              ),
              child: const SizedBox(width: 180, height: 70),
            ),
          ),
        ),
      ),
    );

    // `defaultMinSize` never imposes a maximum. The arbitrary child keeps its
    // 180x70 extent and each source padding edge remains part of the surface.
    expect(tester.getSize(find.byKey(buttonKey)), const Size(190, 76));
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(buttonKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.none);
    expect(pressable.showIndication, isTrue);
    await tester.tap(find.byKey(buttonKey));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text button accepts source geometry and color parameters', (
    tester,
  ) async {
    const buttonKey = ValueKey('source-text-button');
    const enabledColor = Color(0xff102030);
    const disabledColor = Color(0xff405060);
    const enabledText = Color(0xff708090);
    const disabledText = Color(0xffa0b0c0);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixTextButton(
              key: buttonKey,
              label: '文本',
              onPressed: () {},
              cornerRadius: 7,
              minWidth: 120,
              minHeight: 56,
              insideMargin: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              colors: const MiuixTextButtonColors(
                color: enabledColor,
                disabledColor: disabledColor,
                textColor: enabledText,
                disabledTextColor: disabledText,
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(buttonKey)), const Size(120, 56));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(buttonKey),
                    matching: find.byKey(
                      const ValueKey('miuix-button-surface'),
                    ),
                  ),
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, enabledColor);
    expect(
      (decoration.shape as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(7),
    );
    expect(tester.widget<Text>(find.text('文本')).style?.color, enabledText);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text button forwards current source style and natural wrap', (
    tester,
  ) async {
    const buttonKey = ValueKey('styled-source-text-button');
    const explicitTextColor = Color(0xffcc3366);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 92,
              child: MiuixTextButton(
                key: buttonKey,
                label: 'Alpha beta gamma',
                onPressed: () {},
                minWidth: 0,
                minHeight: 0,
                insideMargin: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                textStyle: const TextStyle(
                  color: explicitTextColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .7,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Alpha beta gamma'));
    expect(label.style?.color, explicitTextColor);
    expect(label.style?.fontSize, 14);
    expect(label.style?.height, 1.5);
    expect(label.style?.fontWeight, FontWeight.w700);
    expect(label.style?.letterSpacing, .7);
    expect(label.maxLines, isNull);
    expect(label.softWrap, isTrue);
    expect(label.overflow, TextOverflow.clip);
    expect(
      tester.getSize(find.text('Alpha beta gamma')).height,
      greaterThan(21),
    );
    expect(tester.getSize(find.byKey(buttonKey)).width, 92);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text button style without color inherits its state color', (
    tester,
  ) async {
    const inheritedColor = Color(0xff2468ac);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixTextButton(
              label: 'Inherited',
              onPressed: () {},
              textStyle: const TextStyle(
                fontSize: 15,
                fontStyle: FontStyle.italic,
              ),
              colors: const MiuixTextButtonColors(
                color: Color(0xff102030),
                disabledColor: Color(0xff405060),
                textColor: inheritedColor,
                disabledTextColor: Color(0xff708090),
              ),
            ),
          ),
        ),
      ),
    );

    final label = tester.widget<Text>(find.text('Inherited'));
    expect(label.style?.color, inheritedColor);
    expect(label.style?.fontSize, 15);
    expect(label.style?.fontStyle, FontStyle.italic);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text button default style wraps with physical line boxes', (
    tester,
  ) async {
    const density = 2.625;
    const buttonKey = ValueKey('default-wrapping-text-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: density),
          child: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 92,
                child: MiuixTextButton(
                  key: buttonKey,
                  label: 'Alpha beta gamma',
                  onPressed: () {},
                  minWidth: 0,
                  minHeight: 0,
                  insideMargin: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final textHeight = tester.getSize(find.text('Alpha beta gamma')).height;
    final lineCount = (textHeight / 20).round();
    expect(lineCount, greaterThan(1));
    final sourceTextPixels = (17 * 1.16 * lineCount * density).ceil();
    final sourcePaddingPixels = 2 * (4 * density).round();
    expect(
      tester.getSize(find.byKey(buttonKey)).height * density,
      closeTo(sourceTextPixels + sourcePaddingPixels, 1e-9),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button defaults match HyperOS transparent surface', (
    tester,
  ) async {
    const defaultKey = ValueKey('default-icon-button');
    const selectedKey = ValueKey('selected-icon-button');
    const disabledKey = ValueKey('disabled-icon-button');
    const disabledBackground = Color(0xff6750a4);
    const disabledForeground = Color(0xffffb74d);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              MiuixIconButton(
                key: defaultKey,
                icon: const Icon(Icons.search),
                onPressed: () {},
              ),
              MiuixIconButton(
                key: selectedKey,
                icon: const Icon(Icons.check),
                selected: true,
                onPressed: () {},
              ),
              MiuixIconButton(
                key: disabledKey,
                icon: const Icon(Icons.close),
                backgroundColor: disabledBackground,
                contentColor: disabledForeground,
                enabled: false,
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    ShapeDecoration decorationFor(Key key) {
      return tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .single
              .decoration
          as ShapeDecoration;
    }

    final scheme = Theme.of(tester.element(find.byKey(defaultKey))).colorScheme;

    expect(tester.getSize(find.byKey(defaultKey)), const Size.square(44));
    expect(decorationFor(defaultKey).color, Colors.transparent);
    // IconButton.kt removes only the clickable modifier when disabled. It does
    // not replace the caller's fill or content tint with disabled colors.
    expect(decorationFor(disabledKey).color, disabledBackground);
    expect(decorationFor(selectedKey).color, scheme.primaryContainer);
    expect(decorationFor(defaultKey).shape, isA<MiuixSquircleBorder>());
    expect(
      (decorationFor(defaultKey).shape as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(22),
    );
    expect(
      (decorationFor(defaultKey).shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    expect(
      (decorationFor(selectedKey).shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    // IconButton.kt does not install a LocalContentColor of its own. Compare
    // the effective icon value with the local inherited at the button entry.
    expect(
      IconTheme.of(tester.element(find.byIcon(Icons.search))).color,
      IconTheme.of(tester.element(find.byKey(defaultKey))).color,
    );
    final disabledIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.close),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.color == disabledForeground);
    expect(disabledIconTheme.data.color, disabledForeground);
    final defaultIndication = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byKey(defaultKey),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );
    final disabledIndication = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byKey(disabledKey),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );
    expect(defaultIndication.opacity.value, 0);
    expect(disabledIndication.opacity.value, 0);
    final selectedSemantics = tester
        .getSemantics(find.byKey(selectedKey))
        .getSemanticsData();
    expect(selectedSemantics.flagsCollection.isSelected, Tristate.isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'icon button preserves inherited content locals and merges its label',
    (tester) async {
      const inherited = Color(0xff7b1fa2);
      const explicit = Color(0xff00acc1);
      const inheritedKey = ValueKey('inherited-content-icon-button');
      const explicitKey = ValueKey('explicit-content-icon-button');
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: IconTheme(
              data: const IconThemeData(color: inherited, size: 21),
              child: Row(
                children: [
                  MiuixIconButton(
                    key: inheritedKey,
                    icon: const Icon(Icons.search, semanticLabel: '搜索'),
                    onPressed: () {},
                  ),
                  MiuixIconButton(
                    key: explicitKey,
                    contentColor: explicit,
                    icon: const Icon(Icons.edit, semanticLabel: '编辑'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.search))).color,
        inherited,
      );
      expect(IconTheme.of(tester.element(find.byIcon(Icons.search))).size, 21);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.edit))).color,
        explicit,
      );
      final inheritedSemantics = tester
          .getSemantics(find.byKey(inheritedKey))
          .getSemanticsData();
      expect(inheritedSemantics.label, '搜索');
      expect(inheritedSemantics.flagsCollection.isButton, isTrue);
      expect(inheritedSemantics.flagsCollection.isSelected, Tristate.none);
      expect(inheritedSemantics.hasAction(SemanticsAction.tap), isTrue);
      expect(find.bySemanticsLabel('搜索'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('icon button mirrors source parameters and arbitrary content', (
    tester,
  ) async {
    const buttonKey = ValueKey('custom-icon-button');
    const background = Color(0xff123456);
    const foreground = Color(0xfffedcba);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              onPressed: () {},
              backgroundColor: background,
              contentColor: foreground,
              cornerRadius: 13,
              minWidth: 58,
              minHeight: 44,
              child: const Text('任意内容'),
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byKey(buttonKey));
    expect(size.width, greaterThanOrEqualTo(58));
    // defaultMinSize is a floor: the localized text line box may legitimately
    // make the source placeable taller than the requested 44dp minimum.
    expect(size.height, greaterThanOrEqualTo(44));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byKey(buttonKey),
                    matching: find.byKey(
                      const ValueKey('miuix-icon-button-surface'),
                    ),
                  ),
                )
                .decoration
            as ShapeDecoration;
    expect(decoration.color, background);
    expect(decoration.shape, isA<MiuixSquircleBorder>());
    expect(
      (decoration.shape as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(13),
    );
    expect(tester.widget<Text>(find.text('任意内容')).style?.color, isNull);
    expect(
      tester
          .widgetList<DefaultTextStyle>(
            find.ancestor(
              of: find.text('任意内容'),
              matching: find.byType(DefaultTextStyle),
            ),
          )
          .any((style) => style.style.color == foreground),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button keeps 44dp layout and exposes 48dp Android target', (
    tester,
  ) async {
    const buttonKey = ValueKey('expanded-target-icon-button');
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              icon: const Icon(Icons.add),
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    final visualRect = tester.getRect(find.byKey(buttonKey));
    expect(visualRect.size, const Size.square(44));
    final semantics = tester.getSemantics(find.byKey(buttonKey));
    expect(semantics.rect.size, const Size.square(48));
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // The accessibility target extends two dp beyond the painted placeable.
    // A tap one dp beyond the painted right edge must still activate it.
    await tester.tapAt(Offset(visualRect.right + 1, visualRect.center.dy));
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top bar rounds fractional Android icon targets like Compose', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    const buttonKey = ValueKey('fractional-top-bar-icon-button');
    const actionKey = ValueKey('fractional-top-bar-action-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            appBar: MiuixTopAppBar(
              title: '标题',
              large: true,
              leading: MiuixIconButton(
                key: buttonKey,
                icon: const Icon(Icons.arrow_back),
                onPressed: () {},
              ),
              actions: [
                MiuixIconButton(
                  key: actionKey,
                  icon: const Icon(Icons.edit),
                  onPressed: () {},
                ),
              ],
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byKey(buttonKey));
    expect(semantics.rect.size, const Size.square(48));
    // The top bar retains its 40dp authored action slot while the ordinary
    // standalone icon button uses the larger HyperOS painted default.
    expect(semantics.rect.top, closeTo(-4 + 1 / 2.625, 1e-6));
    expect(semantics.rect.left, -4);
    final actionSemantics = tester.getSemantics(find.byKey(actionKey));
    expect(actionSemantics.rect.left, closeTo(-4 / 2.625, 1e-6));
    expect(actionSemantics.rect.right, closeTo(46 + .25 / 2.625, 1e-6));
    // The raw span is 125 physical pixels; Android's outward end conversion
    // reports the same 126-pixel integer node as Compose.
    expect((actionSemantics.rect.width * 2.625).round(), 125);
    expect(tester.getSize(find.byKey(buttonKey)), const Size.square(40));
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button hold-down supersedes the pointer indication', (
    tester,
  ) async {
    const buttonKey = ValueKey('held-icon-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              icon: const Icon(Icons.edit),
              holdDownState: true,
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    FadeTransition indication() => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byKey(buttonKey),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );

    expect(indication().opacity.value, 0);
    // The initial HoldDown interaction is emitted after the indication node
    // attaches; give its ticker a zero-time first frame before sampling it.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(indication().opacity.value, greaterThan(0));
    expect(indication().opacity.value, lessThan(.10));
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.10, .001));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(buttonKey)),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    // Current MiuixIndication excludes the press delta while HoldDown is true.
    expect(indication().opacity.value, closeTo(.10, .001));
    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.10, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button uses source hover focus and press springs', (
    tester,
  ) async {
    const buttonKey = ValueKey('desktop-icon-button');
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              icon: const Icon(Icons.edit),
              onPressed: () => activations += 1,
            ),
          ),
        ),
      ),
    );

    FadeTransition indication() => tester.widget<FadeTransition>(
      find.descendant(
        of: find.byKey(buttonKey),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );
    final center = tester.getCenter(find.byKey(buttonKey));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(indication().opacity.value, inExclusiveRange(0, .06));
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.06, .001));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.14, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);

    final touch = await tester.startGesture(center);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.24, .001));
    await touch.up();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.14, .001));
    await mouse.removePointer();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.08, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button publishes reduced-motion states without a spring', (
    tester,
  ) async {
    const buttonKey = ValueKey('reduced-motion-icon-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Center(
              child: MiuixIconButton(
                key: const ValueKey('reduced-motion-icon-button'),
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    double alpha() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byKey(buttonKey),
            matching: find.byKey(const ValueKey('miuix-press-indication')),
          ),
        )
        .opacity
        .value;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(buttonKey)),
    );
    await tester.pump();
    expect(alpha(), closeTo(.10, .0001));
    await gesture.up();
    await tester.pump();
    expect(alpha(), 0);
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button carries velocity into a layered press', (
    tester,
  ) async {
    const buttonKey = ValueKey('velocity-icon-button');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    double alpha() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byKey(buttonKey),
            matching: find.byKey(const ValueKey('miuix-press-indication')),
          ),
        )
        .opacity
        .value;
    final center = tester.getCenter(find.byKey(buttonKey));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 29));
    final alphaAt29 = alpha();
    await tester.pump(const Duration(milliseconds: 1));
    final alphaAt30 = alpha();
    final inboundDelta = alphaAt30 - alphaAt29;
    expect(inboundDelta, greaterThan(0));

    final touchTarget = tester.renderObject(find.byKey(buttonKey)) as dynamic;
    touchTarget.onTapDown();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    // Adding the 10% press channel interrupts HoverEnter. Compose carries the
    // positive velocity, so the next-frame delta stays close to the inbound
    // rate instead of restarting almost motionless from the sampled alpha.
    expect(alpha() - alphaAt30, greaterThan(inboundDelta * .5));

    touchTarget.onTapCancel();
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(alpha(), closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled icon button removes click and held indication', (
    tester,
  ) async {
    const buttonKey = ValueKey('explicitly-disabled-icon-button');
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixIconButton(
              key: buttonKey,
              icon: const Icon(Icons.close),
              enabled: false,
              holdDownState: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    final indication = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byKey(buttonKey),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );
    expect(indication.opacity.value, 0);
    expect(
      tester
          .getSemantics(find.byKey(buttonKey))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.tap(find.byKey(buttonKey), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'icon button safely enables its callback and semantics together',
    (tester) async {
      final enabled = ValueNotifier<bool>(false);
      addTearDown(enabled.dispose);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: ValueListenableBuilder<bool>(
              valueListenable: enabled,
              builder: (context, value, child) => MiuixIconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: value ? () => taps++ : null,
              ),
            ),
          ),
        ),
      );

      enabled.value = true;
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(MiuixIconButton));
      await tester.pump();
      expect(taps, 1);
      expect(
        tester
            .getSemantics(find.byType(MiuixIconButton))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
    },
  );

  testWidgets('color palette exposes MIUIX HSV grid metrics safely', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixColorPalette.hsv(
              color: Colors.blue,
              rows: 0,
              hueColumns: -4,
              indicatorRadius: double.nan,
              onColorChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final paletteCanvas = find.byKey(
      const ValueKey('miuix-hsv-palette-canvas'),
    );
    final alphaSlider = find.byKey(const ValueKey('miuix-hsv-alpha-slider'));
    expect(tester.getSize(paletteCanvas).height, 180);
    expect(tester.getSize(alphaSlider).height, 26);
    expect(tester.getSize(find.byType(MiuixColorPalette)).height, 256);
    expect(
      find.descendant(
        of: find.byType(MiuixColorPalette),
        matching: find.byType(MiuixSurface),
      ),
      findsNothing,
    );

    await tester.tap(paletteCanvas);
    await tester.pump();
    await tester.drag(alphaSlider, const Offset(-180, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.a, lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color palette maps RTL cells like the source grid', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 260,
                child: MiuixColorPalette.hsv(
                  color: Colors.blue,
                  showPreview: false,
                  cornerRadius: 20,
                  onColorChanged: (value) => changed = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final paletteCanvas = find.byKey(
      const ValueKey('miuix-hsv-palette-canvas'),
    );
    final rect = tester.getRect(paletteCanvas);
    await tester.tapAt(Offset(rect.left + 5, rect.center.dy));
    await tester.pump();

    expect(changed, isNotNull);
    expect(HSVColor.fromColor(changed!).saturation, lessThan(.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color palette accepts pointer input below one pixel wide', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: .5,
              child: MiuixColorPalette.hsv(
                color: Colors.blue,
                showPreview: false,
                onColorChanged: (value) => changed = value,
              ),
            ),
          ),
        ),
      ),
    );

    final palette = find.byKey(const ValueKey('miuix-hsv-palette-canvas'));
    expect(tester.getSize(palette).width, .5);
    await tester.tapAt(tester.getCenter(palette));
    await tester.pump();

    expect(changed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'color palette keeps emitted preview before its parent echoes the color',
    (tester) async {
      Color? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: SizedBox(
                width: 260,
                child: MiuixColorPalette.hsv(
                  color: Colors.blue,
                  onColorChanged: (value) => changed = value,
                ),
              ),
            ),
          ),
        ),
      );

      final palette = find.byKey(const ValueKey('miuix-hsv-palette-canvas'));
      final paletteRect = tester.getRect(palette);
      final gesture = await tester.startGesture(
        Offset(paletteRect.left + 20, paletteRect.top + 20),
      );
      await tester.pump();
      await gesture.up();
      expect(changed, isNotNull);

      final preview = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('miuix-color-palette-preview-clip')),
          matching: find.byType(DecoratedBox),
        ),
      );
      expect((preview.decoration as BoxDecoration).color, changed);
      expect(changed, isNot(Colors.blue));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('color palette publishes one value per source pointer sample', (
    tester,
  ) async {
    final changed = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              width: 260,
              child: MiuixColorPalette.hsv(
                color: Colors.blue,
                showPreview: false,
                onColorChanged: changed.add,
              ),
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(
      find.byKey(const ValueKey('miuix-hsv-palette-canvas')),
    );
    final gesture = await tester.startGesture(
      Offset(rect.left + 10, rect.top + 10),
    );
    await tester.pump();
    expect(changed, hasLength(1));

    await gesture.moveTo(Offset(rect.left + 40, rect.top + 40));
    await tester.pump();
    expect(changed, hasLength(2));
    await gesture.up();
    expect(tester.takeException(), isNull);
  });

  testWidgets('color controls follow the source smooth-rounding switch', (
    tester,
  ) async {
    Future<void> pumpControls({required bool enableSquircle}) {
      return tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              enableSquircle: enableSquircle,
            ),
            child: Scaffold(
              body: Column(
                children: [
                  MiuixColorPalette.hsv(
                    color: Colors.blue,
                    onColorChanged: (_) {},
                  ),
                  MiuixColorPicker(color: Colors.blue, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );
    }

    MiuixSquircleSurface surfaceFor(Key key) =>
        tester.widget<MiuixSquircleSurface>(find.byKey(key).first);

    await pumpControls(enableSquircle: true);
    expect(
      surfaceFor(const ValueKey('miuix-color-palette-canvas-clip')).enabled,
      isTrue,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-palette-preview-clip')).enabled,
      isTrue,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-picker-preview-clip')).enabled,
      isTrue,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-slider-shape-clip')).enabled,
      isTrue,
    );

    await pumpControls(enableSquircle: false);
    expect(
      surfaceFor(const ValueKey('miuix-color-palette-canvas-clip')).enabled,
      isFalse,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-palette-preview-clip')).enabled,
      isFalse,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-picker-preview-clip')).enabled,
      isFalse,
    );
    expect(
      surfaceFor(const ValueKey('miuix-color-slider-shape-clip')).enabled,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  test(
    'color controls expose source constructors and checkerboard defaults',
    () {
      void onColorChanged(Color _) {}

      final picker = MiuixColorPicker.source(
        color: Colors.red,
        onColorChanged: onColorChanged,
        colorSpace: MiuixColorSpace.okLab,
        showPreview: false,
        hapticEffect: MiuixSliderHapticEffect.none,
      );
      expect(picker.color, Colors.red);
      expect(picker.onChanged, same(onColorChanged));
      expect(picker.colorSpace, MiuixColorSpace.okLab);
      expect(picker.showPreview, isFalse);
      expect(picker.hapticEffect, MiuixSliderHapticEffect.none);

      final palette = MiuixColorPalette.source(
        color: Colors.blue,
        onColorChanged: onColorChanged,
        rows: 5,
        hueColumns: 8,
        includeGrayColumn: false,
        showPreview: false,
        cornerRadius: 18,
        indicatorRadius: 9,
      );
      expect(palette.selected, Colors.blue);
      expect(palette.onSelected, same(onColorChanged));
      expect(palette.rows, 5);
      expect(palette.hueColumns, 8);
      expect(palette.includeGrayColumn, isFalse);
      expect(palette.showPreview, isFalse);
      expect(palette.cornerRadius, 18);
      expect(palette.indicatorRadius, 9);

      const checkerboard = MiuixCheckerboard(child: SizedBox());
      expect(checkerboard.cellSize, 3);
      expect(checkerboard.lightColor, const Color(0xFFCCCCCC));
      expect(checkerboard.darkColor, const Color(0xFFAAAAAA));

      final labA = MiuixOkLabAChannelSlider.source(
        currentL: .7,
        currentA: .1,
        currentB: -.1,
        onAChanged: (_) {},
      );
      expect(labA.lightness, .7);
      expect(labA.value, .1);
      expect(labA.b, -.1);

      final lchAlpha = MiuixOkLchAlphaSlider.source(
        currentL: .8,
        currentC: .5,
        currentH: .25,
        currentAlpha: .6,
        onAlphaChanged: (_) {},
      );
      expect(lchAlpha.lightness, .8);
      expect(lchAlpha.chroma, .2);
      expect(lchAlpha.hue, 90);
      expect(lchAlpha.value, .6);
    },
  );

  testWidgets('color picker uses MIUIX HSV channel slider metrics', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixColorPicker(
              color: Colors.blue,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final hueSlider = find.byKey(
      const ValueKey('miuix-color-picker-hue-slider'),
    );
    final saturationSlider = find.byKey(
      const ValueKey('miuix-color-picker-saturation-slider'),
    );
    final valueSlider = find.byKey(
      const ValueKey('miuix-color-picker-value-slider'),
    );
    final alphaSlider = find.byKey(const ValueKey('miuix-hsv-alpha-slider'));

    expect(tester.getSize(hueSlider).height, 26);
    expect(tester.getSize(saturationSlider).height, 26);
    expect(tester.getSize(valueSlider).height, 26);
    expect(tester.getSize(alphaSlider).height, 26);
    expect(tester.getSize(find.byType(MiuixColorPicker)).height, 178);
    expect(
      find.descendant(
        of: find.byType(MiuixColorPicker),
        matching: find.byType(MiuixSurface),
      ),
      findsNothing,
    );

    await tester.drag(alphaSlider, const Offset(-180, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(changed!.a, lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color controls preserve source 420 dpi placeable heights', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixColorPicker(
                  color: Colors.blue,
                  showPreview: false,
                  onChanged: (_) {},
                ),
                MiuixColorPalette.hsv(
                  color: Colors.blue,
                  showPreview: false,
                  onColorChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final hue = find.byKey(const ValueKey('miuix-color-picker-hue-slider'));
    final touchTargets = find.byKey(
      const ValueKey('miuix-color-slider-touch-target'),
    );
    final canvas = find.byKey(const ValueKey('miuix-hsv-palette-canvas'));
    expect(tester.getSize(hue).height * sourceDensity, closeTo(68, .001));
    expect(touchTargets, findsNWidgets(5));
    expect(
      tester.getRect(touchTargets.first).height * sourceDensity,
      closeTo(126, .001),
    );
    expect(
      tester.getSize(find.byType(MiuixColorPicker)).height * sourceDensity,
      closeTo(368, .001),
    );
    expect(tester.getSize(canvas).height * sourceDensity, closeTo(473, .001));
    expect(
      tester.getSize(find.byType(MiuixColorPalette)).height * sourceDensity,
      closeTo(573, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color sliders keep horizontal drags away from a parent pager', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    Color? changed;
    var selectedPage = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: pageController,
              onPageChanged: (value) => selectedPage = value,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: MiuixColorPicker(
                    color: Colors.blue,
                    showPreview: false,
                    onChanged: (value) => changed = value,
                  ),
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    final hueSlider = find.byKey(
      const ValueKey('miuix-color-picker-hue-slider'),
    );
    await tester.drag(hueSlider, const Offset(-240, 0));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(selectedPage, 0);
    expect(pageController.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color sliders expose the source 48dp drag target', (
    tester,
  ) async {
    double? hue;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                height: 100,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 37,
                      height: 26,
                      child: MiuixHsvHueSlider(
                        value: 0,
                        onChanged: (value) => hue = value,
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

    final track = find.byKey(const ValueKey('miuix-color-channel-slider'));
    final visualRect = tester.getRect(track);
    final target = find.byKey(
      const ValueKey('miuix-color-slider-touch-target'),
    );
    expect(tester.getRect(target).height, 48);

    // Twenty logical pixels from center is outside the 13dp visual radius but
    // inside Compose's centered 24dp pointer radius.
    final gesture = await tester.startGesture(
      Offset(visualRect.center.dx - 20, visualRect.center.dy + 20),
    );
    await gesture.moveBy(const Offset(40, 0));
    await gesture.up();
    await tester.pump();

    expect(hue, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('two-dimensional palette consumes a parent pager drag', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    Color? changed;
    var selectedPage = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: pageController,
              onPageChanged: (value) => selectedPage = value,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: MiuixColorPalette.hsv(
                    color: Colors.blue,
                    showPreview: false,
                    onColorChanged: (value) => changed = value,
                  ),
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    final palette = find.byKey(const ValueKey('miuix-hsv-palette-canvas'));
    await tester.drag(palette, const Offset(-240, 35));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(selectedPage, 0);
    expect(pageController.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('standard and range sliders also retain a parent pager drag', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    double? scalarValue;
    RangeValues? rangeValue;
    var selectedPage = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: pageController,
              onPageChanged: (value) => selectedPage = value,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiuixSlider(
                      key: const ValueKey('pager-standard-slider'),
                      value: .7,
                      onChanged: (value) => scalarValue = value,
                    ),
                    MiuixRangeSlider(
                      key: const ValueKey('pager-range-slider'),
                      values: const RangeValues(.3, .8),
                      onChanged: (value) => rangeValue = value,
                    ),
                  ],
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('pager-standard-slider')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(scalarValue, isNotNull);
    expect(selectedPage, 0);
    expect(pageController.page, closeTo(0, .001));

    await tester.drag(
      find.byKey(const ValueKey('pager-range-slider')),
      const Offset(-240, 0),
    );
    await tester.pumpAndSettle();
    expect(rangeValue, isNotNull);
    expect(selectedPage, 0);
    expect(pageController.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal scrollbar only claims drags starting on its thumb', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pager = PageController(initialPage: 1);
    final adapter = _MiuixTestScrollBarAdapter(
      contentSize: 500,
      viewportSize: 100,
      scrollOffset: 100,
    );
    addTearDown(pager.dispose);
    addTearDown(adapter.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: PageView(
            controller: pager,
            children: [
              const SizedBox.expand(),
              MiuixHorizontalScrollBar(
                adapter: adapter,
                thumbVisibility: true,
                child: const ColoredBox(color: Colors.transparent),
              ),
              const Center(child: Text('Pager destination')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final target = tester.getRect(
      find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
    );

    // At this geometry the thumb occupies x=80..160. A drag in the otherwise
    // transparent end strip must remain available to the ancestor pager.
    final outside = await tester.startGesture(
      Offset(target.right - 30, target.center.dy),
    );
    await outside.moveBy(const Offset(-280, 0));
    await outside.up();
    await tester.pumpAndSettle();
    expect(pager.page, closeTo(2, .001));

    pager.jumpToPage(1);
    adapter.jumpTo(100);
    await tester.pumpAndSettle();
    final inside = await tester.startGesture(
      Offset(target.left + 110, target.center.dy),
    );
    await inside.moveBy(const Offset(-80, 0));
    await inside.up();
    await tester.pumpAndSettle();

    expect(adapter.scrollOffset, lessThan(100));
    expect(pager.page, closeTo(1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('slider claims horizontal intent before an ancestor pager slop', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    double? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: pageController,
              children: [
                Center(
                  child: MiuixSlider(
                    value: .5,
                    onChanged: (value) => changed = value,
                  ),
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiuixSlider)),
    );
    // Four logical pixels are below the ordinary 18dp drag threshold but
    // enough to establish unambiguous horizontal intent.
    await gesture.moveBy(const Offset(-4, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(pageController.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal sliders leave vertical drags to an ancestor scroll', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    double? changed;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  MiuixSlider(value: .4, onChanged: (value) => changed = value),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(MiuixSlider), const Offset(0, -240));
    await tester.pumpAndSettle();

    expect(scrollController.offset, greaterThan(0));
    expect(changed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('color picker interaction follows source RTL direction', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                child: MiuixColorPicker(
                  color: Colors.blue,
                  showPreview: false,
                  onChanged: (value) => changed = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final hueSlider = find.byKey(
      const ValueKey('miuix-color-picker-hue-slider'),
    );
    final rect = tester.getRect(hueSlider);

    // ColorPicker.kt installs draggable without clickable, so a stationary
    // track tap must not jump the source value.
    await tester.tapAt(
      Offset(rect.left + 13 + (rect.width - 26) * .25, rect.center.dy),
    );
    await tester.pump();
    expect(changed, isNull);

    // Begin four pixels before the desired position. The real motion qualifies
    // the drag, and the update lands at exactly the logical 25% visual point.
    final desiredX = rect.left + 13 + (rect.width - 26) * .25;
    final gesture = await tester.startGesture(
      Offset(desiredX - 4, rect.center.dy),
    );
    await gesture.moveBy(const Offset(4, 0));
    await gesture.up();
    await tester.pump();

    expect(changed, isNotNull);
    expect(HSVColor.fromColor(changed!).hue, closeTo(270, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('standalone HSV controls use source color tracks', (
    tester,
  ) async {
    double? hue;
    const hueKey = ValueKey('standalone-hsv-hue');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MiuixHsvHueSlider(
                      key: hueKey,
                      value: 0,
                      onChanged: (value) => hue = value,
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

    expect(tester.getSize(find.byKey(hueKey)).height, 26);
    expect(
      find.descendant(of: find.byKey(hueKey), matching: find.byType(Slider)),
      findsNothing,
    );
    final hueTrack = find
        .byKey(const ValueKey('miuix-color-channel-slider'))
        .first;
    final rect = tester.getRect(hueTrack);
    await tester.tapAt(rect.center);
    await tester.pump();
    expect(hue, isNull);

    await tester.drag(hueTrack, const Offset(40, 0));
    await tester.pump();

    expect(hue, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'source HSV hue callback remains normalized to zero through one',
    (tester) async {
      double? hue;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 240,
                child: MiuixHsvHueSlider.source(
                  currentHue: 180,
                  onHueChanged: (value) => hue = value,
                ),
              ),
            ),
          ),
        ),
      );

      final track = find.byKey(const ValueKey('miuix-color-channel-slider'));
      await tester.drag(track, const Offset(24, 0));
      await tester.pump();

      expect(hue, isNotNull);
      expect(hue, inInclusiveRange(0, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('OKLab channel controls use the source minus-point-three range', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 240,
                child: MiuixOkLabAChannelSlider(
                  value: 0,
                  onChanged: (value) => changed = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final track = find.byKey(const ValueKey('miuix-color-channel-slider'));
    final rect = tester.getRect(track);
    final gesture = await tester.startGesture(rect.center);
    await gesture.moveTo(Offset(rect.right + 40, rect.center.dy));
    await gesture.up();
    await tester.pump();

    expect(changed, closeTo(.3, .000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color picker keeps local HSV state before parent echoes color', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixColorPicker(
              color: Colors.blue,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final hueSlider = find.byKey(
      const ValueKey('miuix-color-picker-hue-slider'),
    );
    await tester.drag(hueSlider, const Offset(-220, 0));
    await tester.pump();

    final changedAfterDrag = changed;
    expect(changedAfterDrag, isNotNull);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixColorPicker(
              color: Colors.blue,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    await tester.tap(hueSlider);
    await tester.pump();

    expect(changed, isNot(equals(Colors.blue)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color picker channel sliders remain active when squeezed', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 40,
                child: MiuixColorPicker(
                  color: Colors.blue,
                  onChanged: (value) => changed = value,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final hueSlider = find.byKey(
      const ValueKey('miuix-color-picker-hue-slider'),
    );
    await tester.drag(hueSlider, const Offset(18, 0));
    await tester.pump();

    expect(changed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('control center tiles stay compact under narrow constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              width: 96,
              child: Column(
                children: [
                  MiuixControlCenterTile(
                    icon: Icon(Icons.bluetooth),
                    label: 'Bluetooth device with a long label',
                    value: 'Connected to a long device name',
                  ),
                  MiuixControlSliderTile(
                    icon: Icon(Icons.brightness_6),
                    label: 'Brightness with a long label',
                    value: 0.7,
                    onChanged: _ignoreDouble,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MiuixControlCenterTile), findsOneWidget);
    expect(find.byType(MiuixControlSliderTile), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('control center tile uses HyperOS content glass by default', (
    tester,
  ) async {
    final defaults = MiuixThemeData.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: defaults.copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              cardCornerRadius: 27,
              contentSurfaceBlur: 31,
              contentSurfaceTintOpacity: .43,
              inputStateMotion: Duration(milliseconds: 777),
            ),
          ),
          child: const Center(
            child: MiuixControlCenterTile(
              icon: Icon(Icons.wifi),
              label: 'Wi-Fi',
              value: 'Connected',
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-control-center-tile-surface')),
    );
    final stateColor = tester.widget<TweenAnimationBuilder<Color?>>(
      find.ancestor(
        of: find.byKey(const ValueKey('miuix-control-center-tile-surface')),
        matching: find.byType(TweenAnimationBuilder<Color?>),
      ),
    );
    expect(surface.glass, isTrue);
    expect(surface.radius, 27);
    expect(surface.glassBlur, 31);
    expect(surface.glassOpacity, .43);
    expect(stateColor.duration, const Duration(milliseconds: 777));
    expect(find.byType(MiuixGlass), findsOneWidget);
  });

  testWidgets(
    'control center source tile keeps its opaque compatibility path',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixControlCenterTile.source(
                icon: Icon(Icons.wifi),
                label: 'Wi-Fi',
              ),
            ),
          ),
        ),
      );

      final surface = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-control-center-tile-surface')),
      );
      expect(surface.glass, isFalse);
      expect(surface.radius, 20);
      expect(find.byType(MiuixGlass), findsNothing);
    },
  );

  testWidgets('control slider tile uses HyperOS content glass by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              cardCornerRadius: 26,
              contentSurfaceBlur: 32,
              contentSurfaceTintOpacity: .42,
            ),
          ),
          child: const Center(
            child: MiuixControlSliderTile(
              icon: Icon(Icons.volume_up),
              label: 'Volume',
              value: .6,
              onChanged: _ignoreDouble,
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-control-slider-tile-surface')),
    );
    expect(surface.glass, isTrue);
    expect(surface.radius, 26);
    expect(surface.glassBlur, 32);
    expect(surface.glassOpacity, .42);
    expect(find.byType(MiuixGlass), findsOneWidget);
  });

  testWidgets('control slider source tile keeps its opaque 18dp path', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixControlSliderTile.source(
              icon: Icon(Icons.volume_up),
              label: 'Volume',
              value: .6,
              onChanged: _ignoreDouble,
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-control-slider-tile-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.radius, 18);
    expect(find.byType(MiuixGlass), findsNothing);
  });

  testWidgets('control slider owns a horizontal drag above a page view', (
    tester,
  ) async {
    final pageController = PageController();
    addTearDown(pageController.dispose);
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: PageView(
            controller: pageController,
            children: [
              Center(
                child: SizedBox(
                  width: 300,
                  child: MiuixControlSliderTile(
                    icon: const Icon(Icons.volume_up),
                    label: 'Volume',
                    value: .75,
                    onChanged: (value) => changed = value,
                  ),
                ),
              ),
              const Center(child: Text('Second page')),
            ],
          ),
        ),
      ),
    );

    await tester.drag(find.byType(MiuixSlider), const Offset(-120, 0));
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!, lessThan(.75));
    expect(pageController.page, closeTo(0, .001));
  });

  testWidgets('stepper state shares process motion and row geometry', (
    tester,
  ) async {
    var state = MiuixStepperRowState.pending;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              processStateMotion: Duration(milliseconds: 777),
              collectionRowCornerRadius: 25,
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MiuixStepperRow(
                index: 1,
                title: 'Install',
                state: state,
                onTap: () {},
              );
            },
          ),
        ),
      ),
    );

    var switcher = tester.widget<AnimatedSwitcher>(
      find.byType(AnimatedSwitcher),
    );
    final pressable = tester.widget<MiuixPressable>(
      find.byType(MiuixPressable),
    );
    expect(switcher.duration, const Duration(milliseconds: 777));
    expect((pressable.borderRadius as BorderRadius).topLeft.x, 25);

    updateHost(() => state = MiuixStepperRowState.completed);
    await tester.pump();
    switcher = tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher));
    expect(switcher.duration, const Duration(milliseconds: 777));
    expect(
      find.byKey(
        const ValueKey<MiuixStepperRowState>(MiuixStepperRowState.completed),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 777));
    expect(tester.takeException(), isNull);
  });

  testWidgets('stepper reduced motion publishes the final state immediately', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: MiuixStepperRow(
              index: 2,
              title: 'Done',
              state: MiuixStepperRowState.completed,
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
      Duration.zero,
    );
    expect(
      find.byKey(
        const ValueKey<MiuixStepperRowState>(MiuixStepperRowState.completed),
      ),
      findsOneWidget,
    );
  });

  testWidgets('surface press feedback preserves MIUIX card radius', (
    tester,
  ) async {
    var tapped = false;
    const cardKey = ValueKey('radius-card');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              onTap: () => tapped = true,
              child: const SizedBox(width: 96, height: 48),
            ),
          ),
        ),
      ),
    );

    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    final clips = tester.widgetList<ClipPath>(
      find.descendant(of: find.byKey(cardKey), matching: find.byType(ClipPath)),
    );
    final glass = tester.widget<MiuixGlass>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(MiuixGlass),
      ),
    );

    // The public shape metadata remains the G2 outline. Glass owns the exact
    // backdrop clip, while Pressable clips only a requested indication so the
    // translucent edge is never antialiased twice.
    expect(pressable.borderRadius, isNull);
    expect(pressable.shape, isA<MiuixSquircleBorder>());
    expect(
      (pressable.shape! as MiuixSquircleBorder).borderRadius,
      BorderRadius.circular(20),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.none);
    expect(glass.blur, 24);
    expect(glass.opacity, .68);
    expect(glass.radius, 20);
    expect(pressable.contentClipBuilder, isNull);
    expect(pressable.contentAlreadyClipped, isTrue);
    expect(
      clips.any((clip) {
        final clipper = clip.clipper;
        return clipper is ShapeBorderClipper &&
            clipper.shape is MiuixSquircleBorder &&
            (clipper.shape as MiuixSquircleBorder).borderRadius ==
                BorderRadius.circular(20);
      }),
      isTrue,
    );
    await tester.tap(find.byKey(cardKey));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card exposes source colors defaults and named parameters', (
    tester,
  ) async {
    late MiuixCardColors defaults;
    const custom = MiuixCardColors(
      color: Color(0xFF123456),
      contentColor: Color(0xFFABCDEF),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixCardDefaults.colors(context);
              return Center(
                child: MiuixCard.source(
                  content: const SizedBox(width: 100, height: 40),
                  cornerRadius: 13,
                  insideMargin: const EdgeInsets.fromLTRB(1, 2, 3, 4),
                  colors: custom,
                  pressFeedbackType: MiuixPressFeedbackType.sink,
                  holdDownState: true,
                ),
              );
            },
          ),
        ),
      ),
    );

    const semantic = MiuixSemanticColors.light();
    expect(MiuixCardDefaults.cornerRadius, 20);
    expect(MiuixCardDefaults.legacyCornerRadius, 16);
    expect(MiuixCardDefaults.insideMargin, EdgeInsets.zero);
    expect(defaults.color, semantic['surfaceContainer']);
    expect(defaults.contentColor, semantic['onSurfaceContainer']);
    expect(
      custom.copyWith(color: Colors.red).contentColor,
      custom.contentColor,
    );
    expect(custom.copyWith(contentColor: Colors.green).color, custom.color);
    expect(
      custom,
      const MiuixCardColors(
        color: Color(0xFF123456),
        contentColor: Color(0xFFABCDEF),
      ),
    );

    final card = tester.widget<MiuixCard>(find.byType(MiuixCard));
    final surface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixCard),
        matching: find.byType(MiuixSurface),
      ),
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixCard),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(card.cornerRadius, 13);
    expect(card.glass, isFalse);
    expect(card.insideMargin, const EdgeInsets.fromLTRB(1, 2, 3, 4));
    expect(card.holdDown, isTrue);
    expect(surface.radius, 13);
    expect(surface.glass, isFalse);
    expect(surface.padding, const EdgeInsets.fromLTRB(1, 2, 3, 4));
    expect(surface.color, custom.color);
    expect(surface.contentColor, custom.contentColor);
    // The callback-free BasicCard remains static; only the source outer
    // pressable observes this externally held Sink state.
    expect(surface.holdDown, isFalse);
    // HoldDownObserver can drive the outer source pressable even though the
    // callback-free Card never installs combinedClickable.
    expect(pressable.onTap, isNull);
    expect(pressable.pointerInputEnabled, isFalse);
    expect(pressable.feedbackType, MiuixPressFeedbackType.sink);
    expect(pressable.holdDown, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card resolves HyperOS material geometry from theme tokens', (
    tester,
  ) async {
    final defaults = MiuixThemeData.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: defaults.copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              cardCornerRadius: 27,
              contentSurfaceBlur: 13,
              contentSurfaceTintOpacity: .44,
            ),
          ),
          child: const Center(
            child: MiuixCard(child: SizedBox(width: 120, height: 60)),
          ),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(find.byType(MiuixSurface));
    final glass = tester.widget<MiuixGlass>(find.byType(MiuixGlass));
    expect(surface.radius, 27);
    expect(surface.glass, isTrue);
    expect(glass.blur, 13);
    expect(glass.opacity, .44);
    expect(glass.radius, 27);
  });

  testWidgets('card source default keeps the legacy opaque 16dp silhouette', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard.source(
              content: const SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      ),
    );

    final card = tester.widget<MiuixCard>(find.byType(MiuixCard));
    final surface = tester.widget<MiuixSurface>(find.byType(MiuixSurface));
    expect(card.glass, isFalse);
    expect(card.cornerRadius, MiuixCardDefaults.legacyCornerRadius);
    expect(surface.glass, isFalse);
    expect(surface.radius, 16);
    expect(find.byType(MiuixGlass), findsNothing);
  });

  test('card feedback exposes the exact MIUIX spring and tilt constants', () {
    final sink = debugMiuixSinkSpring();
    final selectorSink = debugMiuixSinkSpring(
      dampingRatio: .99,
      stiffness: 986.96,
    );
    final tilt = debugMiuixTiltSpring();
    final topLeft = debugMiuixTiltTarget(
      const Offset(10, 10),
      const Size(120, 60),
    );
    final bottomRight = debugMiuixTiltTarget(
      const Offset(110, 50),
      const Size(120, 60),
    );

    expect(sink.mass, 1);
    expect(sink.stiffness, 600);
    expect(sink.damping, closeTo(2 * math.sqrt(600) * .8, .0001));
    expect(selectorSink.stiffness, 986.96);
    expect(selectorSink.damping, closeTo(2 * math.sqrt(986.96) * .99, .0001));
    expect(tilt.mass, 1);
    expect(tilt.stiffness, 400);
    expect(tilt.damping, 24);
    expect(debugMiuixTiltPerspective(), -.0012);
    expect(topLeft.origin, Alignment.bottomRight);
    expect(topLeft.rotationXDegrees, 8);
    expect(topLeft.rotationYDegrees, -8);
    expect(bottomRight.origin, Alignment.topLeft);
    expect(bottomRight.rotationXDegrees, -8);
    expect(bottomRight.rotationYDegrees, 8);

    // With the source's opposite-corner pivot, the top-left far edge must
    // recede inward. The former positive camera-axis sign expanded it outside
    // the card and the outer clip made the live example look almost flat.
    final perspective = Matrix4.identity()
      ..setEntry(3, 2, debugMiuixTiltPerspective())
      ..rotateX(8 * math.pi / 180)
      ..rotateY(-8 * math.pi / 180);
    final projectedTopLeft = MatrixUtils.transformPoint(
      perspective,
      const Offset(-120, -60),
    );
    expect(projectedTopLeft.dx, greaterThan(-120));
    expect(projectedTopLeft.dy, greaterThan(-60));
  });

  testWidgets('checkbox and radio keep their dedicated source sink spring', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              MiuixCheckbox(value: true, onChanged: (_) {}),
              MiuixRadio<int>(value: 1, groupValue: 1, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );

    final pressables = tester.widgetList<MiuixPressable>(
      find.byType(MiuixPressable),
    );
    expect(pressables, hasLength(2));
    for (final pressable in pressables) {
      expect(pressable.feedbackType, MiuixPressFeedbackType.sink);
      expect(pressable.scale, .85);
      expect(pressable.sinkDampingRatio, .99);
      expect(pressable.sinkStiffness, 986.96);
      expect(pressable.showIndication, isFalse);
    }
  });

  testWidgets('sink card reaches the source scale and springs back', (
    tester,
  ) async {
    const cardKey = ValueKey('source-sink-card');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              feedbackType: MiuixPressFeedbackType.sink,
              onTap: () {},
              child: const SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      ),
    );

    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.sink);
    expect(pressable.scale, .94);
    final detector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(GestureDetector),
      ),
    );
    detector.onTapDown!(TapDownDetails(localPosition: const Offset(60, 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    Transform sinkTransform() => tester.widget<Transform>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byKey(const ValueKey('miuix-sink-transform')),
      ),
    );

    expect(sinkTransform().transform.entry(0, 0), closeTo(.94, .002));
    detector.onTapCancel!();
    await tester.pumpAndSettle();
    expect(sinkTransform().transform.entry(0, 0), closeTo(1, .0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sink feedback carries velocity through a quick release', (
    tester,
  ) async {
    const cardKey = ValueKey('source-sink-velocity-card');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              feedbackType: MiuixPressFeedbackType.sink,
              onTap: () {},
              child: const SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      ),
    );

    double scale() => tester
        .widget<Transform>(
          find.descendant(
            of: find.byKey(cardKey),
            matching: find.byKey(const ValueKey('miuix-sink-transform')),
          ),
        )
        .transform
        .entry(0, 0);
    final detector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(GestureDetector),
      ),
    );
    detector.onTapDown!(TapDownDetails(localPosition: const Offset(60, 30)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final beforeRelease = scale();
    expect(beforeRelease, lessThan(1));

    detector.onTapCancel!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    // Animatable retains the inward velocity at the target change, so the
    // surface moves inward briefly before the return spring turns it around.
    expect(scale(), lessThan(beforeRelease));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(1, .0001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pressable snaps an in-flight transform when reduced motion turns on',
    (tester) async {
      const cardKey = ValueKey('runtime-reduced-motion-card');

      Widget frame(bool reduceMotion) => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: MiuixTheme(
            child: Center(
              child: MiuixCard(
                key: cardKey,
                feedbackType: MiuixPressFeedbackType.sink,
                showIndication: true,
                onTap: () {},
                child: const SizedBox(width: 120, height: 60),
              ),
            ),
          ),
        ),
      );

      double scale() => tester
          .widget<Transform>(
            find.descendant(
              of: find.byKey(cardKey),
              matching: find.byKey(const ValueKey('miuix-sink-transform')),
            ),
          )
          .transform
          .entry(0, 0);
      double alpha() => tester
          .widget<FadeTransition>(
            find.descendant(
              of: find.byKey(cardKey),
              matching: find.byKey(const ValueKey('miuix-press-indication')),
            ),
          )
          .opacity
          .value;

      await tester.pumpWidget(frame(false));
      var detector = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(GestureDetector),
        ),
      );
      detector.onTapDown!(TapDownDetails(localPosition: const Offset(60, 30)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      expect(scale(), inExclusiveRange(.94, 1));
      expect(alpha(), inExclusiveRange(0, .10));

      await tester.pumpWidget(frame(true));
      await tester.pump();
      expect(scale(), closeTo(.94, .0001));
      expect(alpha(), closeTo(.10, .0001));
      detector = tester.widget<GestureDetector>(
        find.descendant(
          of: find.byKey(cardKey),
          matching: find.byType(GestureDetector),
        ),
      );
      detector.onTapCancel!();
      await tester.pump();
      expect(scale(), closeTo(1, .0001));
      expect(alpha(), 0);
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('cards forward tilt and long-press feedback', (tester) async {
    var longPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              feedbackType: MiuixPressFeedbackType.tilt,
              onLongPress: () => longPressed = true,
              child: const SizedBox(width: 120, height: 60),
            ),
          ),
        ),
      ),
    );

    final pressable = tester.widget<MiuixPressable>(
      find.byType(MiuixPressable),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.tilt);
    expect(pressable.scale, .94);
    expect(pressable.onLongPress, isNotNull);

    final cardRect = tester.getRect(find.byType(MiuixCard));
    final tiltGesture = await tester.startGesture(
      cardRect.topLeft + const Offset(10, 10),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final tiltTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-tilt-transform')),
    );
    expect(tiltTransform.alignment, Alignment.bottomRight);
    expect(tiltTransform.transform, isNot(Matrix4.identity()));

    // Flutter cancels the competing tap recognizer when the long-press
    // recognizer wins. MIUIX keeps the same tilt held after that transition,
    // rather than flashing briefly and returning to a flat card.
    final detector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(MiuixCard),
        matching: find.byType(GestureDetector),
      ),
    );
    detector.onTapCancel!();
    await tester.pump(const Duration(milliseconds: 250));
    final transitioningTiltTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-tilt-transform')),
    );
    expect(transitioningTiltTransform.alignment, Alignment.bottomRight);
    expect(transitioningTiltTransform.transform, isNot(Matrix4.identity()));

    await tester.pump(const Duration(milliseconds: 600));
    final heldTiltTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-tilt-transform')),
    );
    expect(heldTiltTransform.alignment, Alignment.bottomRight);
    expect(heldTiltTransform.transform, isNot(Matrix4.identity()));
    final heldClips = tester.widgetList<ClipPath>(
      find.descendant(
        of: find.byKey(const ValueKey('miuix-tilt-transform')),
        matching: find.byType(ClipPath),
      ),
    );
    // MiuixGlass owns exactly one silhouette clip below the Transform; the
    // feedback wrapper does not antialias the already-clipped edge again.
    expect(heldClips, hasLength(1));
    for (final clip in heldClips) {
      expect(clip.clipper, isA<ShapeBorderClipper>());
      expect(
        (clip.clipper! as ShapeBorderClipper).shape,
        isA<MiuixSquircleBorder>(),
      );
    }
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('miuix-tilt-transform')),
        matching: find.byType(ClipPath),
      ),
      findsNothing,
    );

    await tiltGesture.up();
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(MiuixCard));
    await tester.pumpAndSettle();
    expect(longPressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card does not invent input from indication or feedback', (
    tester,
  ) async {
    const cardKey = ValueKey('indication-only-card');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              feedbackType: MiuixPressFeedbackType.sink,
              showIndication: true,
              child: SizedBox(
                width: 140,
                height: 64,
                child: Center(child: Text('Static card')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(MiuixPressable),
      ),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('miuix-press-indication')), findsNothing);
    final semantics = tester.getSemantics(find.text('Static card'));
    expect(
      semantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.tap(find.byKey(cardKey));
    expect(tester.takeException(), isNull);
  });

  testWidgets('callback-free held card animates without accepting input', (
    tester,
  ) async {
    const cardKey = ValueKey('held-card-without-callback');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              feedbackType: MiuixPressFeedbackType.sink,
              holdDown: true,
              child: SizedBox(
                width: 140,
                height: 64,
                child: Center(child: Text('Held card')),
              ),
            ),
          ),
        ),
      ),
    );

    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byKey(cardKey),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.onTap, isNull);
    expect(pressable.onLongPress, isNull);
    expect(pressable.pointerInputEnabled, isFalse);
    expect(pressable.holdDown, isTrue);
    double scale() => tester
        .widget<Transform>(find.byKey(const ValueKey('miuix-sink-transform')))
        .transform
        .entry(0, 0);
    // Source SinkFeedbackNode starts at 1. HoldDownObserver emits after the
    // node attaches, then its ordinary 0.8 / 600 spring approaches 0.94.
    expect(scale(), 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(scale(), inExclusiveRange(.94, 1));
    await tester.pumpAndSettle();
    expect(scale(), closeTo(.94, .0001));
    final semantics = tester.getSemantics(find.text('Held card'));
    expect(
      semantics.getSemanticsData().hasAction(SemanticsAction.tap),
      isFalse,
    );
    await tester.tap(find.byKey(cardKey));
    await tester.pump(const Duration(milliseconds: 100));
    expect(scale(), closeTo(.94, .0001));
    expect(tester.takeException(), isNull);
  });

  test('current indication exposes all four source spring pairs', () {
    final pressEnter = debugMiuixIndicationSpring(entering: true);
    final pressExit = debugMiuixIndicationSpring(entering: false);
    final hoverEnter = debugMiuixIndicationSpring(
      entering: true,
      hoverOrFocus: true,
    );
    final hoverExit = debugMiuixIndicationSpring(
      entering: false,
      hoverOrFocus: true,
    );

    void expectSpring(
      SpringDescription spring, {
      required double response,
      required double dampingRatio,
    }) {
      final frequency = 2 * math.pi / response;
      expect(spring.stiffness, closeTo(frequency * frequency, .001));
      expect(spring.damping, closeTo(2 * dampingRatio * frequency, .001));
    }

    expectSpring(pressEnter, response: .2, dampingRatio: 1);
    expectSpring(pressExit, response: .35, dampingRatio: .95);
    expectSpring(hoverEnter, response: .6, dampingRatio: 1);
    expectSpring(hoverExit, response: .2, dampingRatio: .96);
  });

  testWidgets('card indication adds source hover focus and press channels', (
    tester,
  ) async {
    var activations = 0;
    const cardKey = ValueKey('desktop-indication-card');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixCard(
              key: cardKey,
              showIndication: true,
              onTap: () => activations += 1,
              child: const SizedBox(width: 160, height: 72),
            ),
          ),
        ),
      ),
    );

    FadeTransition indication() => tester.widget<FadeTransition>(
      find.byKey(const ValueKey('miuix-press-indication')),
    );
    final center = tester.getCenter(find.byKey(cardKey));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(1, 1));
    await mouse.moveTo(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(indication().opacity.value, greaterThan(0));
    expect(indication().opacity.value, lessThan(.06));
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.06, .001));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(indication().opacity.value, greaterThan(.06));
    expect(indication().opacity.value, lessThan(.14));
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.14, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(activations, 1);

    final touch = await tester.startGesture(center);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(indication().opacity.value, greaterThan(.14));
    expect(indication().opacity.value, lessThan(.24));
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.24, .001));
    await touch.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(indication().opacity.value, greaterThan(.14));
    expect(indication().opacity.value, lessThan(.24));
    // The source resting job resumes after the completed positive job; expose
    // that microtask-scheduled spring to the deterministic test clock.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.14, .001));
    await mouse.removePointer();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(indication().opacity.value, greaterThan(.08));
    expect(indication().opacity.value, lessThan(.14));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(indication().opacity.value, closeTo(.08, .001));
    expect(tester.takeException(), isNull);
  });

  test('basic and arrow color models retain independent source channels', () {
    const basic = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const arrow = MiuixArrowPreferenceEndActionColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );

    expect(basic.resolve(true), Colors.red);
    expect(basic.resolve(false), Colors.blue);
    expect(
      basic.copyWith(color: Colors.purple),
      const MiuixBasicComponentColors(
        color: Colors.purple,
        disabledColor: Colors.blue,
      ),
    );
    expect(arrow.resolve(true), Colors.green);
    expect(arrow.resolve(false), Colors.orange);
    expect(
      arrow.copyWith(disabledColor: Colors.black),
      const MiuixArrowPreferenceEndActionColors(
        color: Colors.green,
        disabledColor: Colors.black,
      ),
    );
  });

  testWidgets('basic component source overload owns all three slots', (
    tester,
  ) async {
    final interactionSource = MiuixInteractionSource();
    var activations = 0;
    addTearDown(interactionSource.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 240,
              child: MiuixBasicComponent.source(
                startAction: const SizedBox(
                  key: ValueKey('basic-source-start'),
                  width: 20,
                  height: 30,
                ),
                endActions: const SizedBox(
                  key: ValueKey('basic-source-end'),
                  width: 30,
                  height: 10,
                ),
                bottomAction: const SizedBox(
                  key: ValueKey('basic-source-bottom'),
                  height: 10,
                ),
                onClick: () => activations += 1,
                interactionSource: interactionSource,
                content: const SizedBox(
                  key: ValueKey('basic-source-center'),
                  width: 400,
                  height: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final start = find.byKey(const ValueKey('basic-source-start'));
    final center = find.byKey(const ValueKey('basic-source-center'));
    final end = find.byKey(const ValueKey('basic-source-end'));
    final component = find.byType(MiuixBasicComponent);
    expect(tester.getSize(component), const Size(240, 80));
    expect(tester.getSize(center).width, closeTo(142, .001));
    expect(tester.getTopLeft(center).dx - tester.getTopRight(start).dx, 8);
    expect(tester.getTopLeft(end).dx - tester.getTopRight(center).dx, 8);
    expect(find.byKey(const ValueKey('basic-source-bottom')), findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(component));
    await tester.pump();
    expect(interactionSource.pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(interactionSource.pressed, isFalse);
    expect(activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic source forwards click label and accessibility role', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var activations = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixBasicComponent.sourceText(
            title: '网络设置',
            onClick: () => activations += 1,
            onClickLabel: '打开网络设置',
            role: MiuixAccessibilityRole.button,
          ),
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(MiuixBasicComponent));
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(node.hintOverrides?.onTapHint, '打开网络设置');
    await tester.tap(find.byType(MiuixBasicComponent));
    expect(activations, 1);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('basic accessibility roles map to Flutter platform semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    Future<SemanticsNode> pumpRole(
      MiuixAccessibilityRole role, {
      bool? checked,
      bool? toggled,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixPreference(
              key: const ValueKey('role-row'),
              title: '语义角色',
              onTap: () {},
              role: role,
              semanticChecked: checked,
              semanticToggled: toggled,
            ),
          ),
        ),
      );
      return tester.getSemantics(find.byKey(const ValueKey('role-row')));
    }

    var node = await pumpRole(MiuixAccessibilityRole.button);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);

    node = await pumpRole(MiuixAccessibilityRole.checkbox, checked: true);
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );

    node = await pumpRole(MiuixAccessibilityRole.switchControl, toggled: true);
    expect(
      node.getSemanticsData().flagsCollection.isToggled.toBoolOrNull(),
      isTrue,
    );

    node = await pumpRole(MiuixAccessibilityRole.radioButton, checked: true);
    expect(
      node.getSemanticsData().flagsCollection.isChecked,
      CheckedState.isTrue,
    );
    expect(
      node.getSemanticsData().flagsCollection.isInMutuallyExclusiveGroup,
      isTrue,
    );

    node = await pumpRole(MiuixAccessibilityRole.tab);
    expect(node.role, SemanticsRole.tab);

    node = await pumpRole(MiuixAccessibilityRole.image);
    expect(node.getSemanticsData().flagsCollection.isImage, isTrue);

    node = await pumpRole(MiuixAccessibilityRole.dropdownList);
    expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
    semantics.dispose();
  });

  testWidgets('source text and arrow preference resolve exact color channels', (
    tester,
  ) async {
    late MiuixBasicComponentColors defaultTitleColors;
    late MiuixBasicComponentColors defaultSummaryColors;
    late MiuixArrowPreferenceEndActionColors defaultArrowColors;
    late MiuixSemanticColors semanticColors;
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );
    const arrowColors = MiuixArrowPreferenceEndActionColors(
      color: Colors.purple,
      disabledColor: Colors.brown,
    );
    const longTitle = '这是用于验证原版箭头尾距的超长中文标题文字内容';

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaultTitleColors = MiuixBasicComponentDefaults.titleColor(
                context,
              );
              defaultSummaryColors = MiuixBasicComponentDefaults.summaryColor(
                context,
              );
              defaultArrowColors = MiuixArrowPreferenceDefaults.endActionColors(
                context,
              );
              semanticColors = MiuixSemanticColors.of(context);
              return const Center(
                child: SizedBox(
                  width: 320,
                  child: MiuixArrowPreference.source(
                    title: longTitle,
                    summary: '已禁用',
                    titleColor: titleColors,
                    summaryColor: summaryColors,
                    endActionColors: arrowColors,
                    enabled: false,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final title = tester.widget<Text>(find.text(longTitle));
    final summary = tester.widget<Text>(find.text('已禁用'));
    expect(defaultTitleColors.color, semanticColors['onBackground']);
    expect(
      defaultSummaryColors.color,
      semanticColors['onSurfaceVariantSummary'],
    );
    expect(defaultArrowColors.color, semanticColors['onSurfaceVariantActions']);
    expect(
      defaultArrowColors.disabledColor,
      semanticColors['disabledOnSecondaryVariant'],
    );
    expect(title.style?.color, Colors.blue);
    expect(summary.style?.color, Colors.orange);
    // 320 - 32 inside padding - 8 BasicComponent end gap - 10 arrow width
    // - 8 always-present endActions end padding = 262dp.
    expect(tester.getSize(find.text(longTitle)).width, closeTo(262, .001));
    final arrowPaint = find
        .descendant(
          of: find.byType(MiuixArrowPreference),
          matching: find.byType(CustomPaint),
        )
        .first;
    expect(tester.getSize(arrowPaint), const Size(10, 16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('basic source text permits summary without a title node', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(child: MiuixBasicComponent.sourceText(summary: '仅摘要')),
      ),
    );

    expect(find.text('仅摘要'), findsOneWidget);
    expect(
      tester
          .widgetList<Text>(find.byType(Text))
          .where((text) => text.data == ''),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch preference source forwards slots colors and row toggle', (
    tester,
  ) async {
    const longTitle = '这是用于验证原版开关偏好尾部间距的超长中文标题';
    var checked = false;
    late MiuixSwitchColors switchColors;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              switchColors = MiuixSwitchDefaults.switchColors(context);
              return Center(
                child: SizedBox(
                  width: 320,
                  child: MiuixSwitchPreference.source(
                    title: longTitle,
                    checked: checked,
                    switchColors: switchColors,
                    bottomAction: const SizedBox(
                      key: ValueKey('switch-preference-bottom'),
                      height: 10,
                    ),
                    onCheckedChange: (next) => checked = next,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(tester.getSize(find.text(longTitle)).width, closeTo(223, .001));
    expect(
      tester.widget<MiuixSwitch>(find.byType(MiuixSwitch)).colors,
      same(switchColors),
    );
    expect(
      find.byKey(const ValueKey('switch-preference-bottom')),
      findsOneWidget,
    );
    await tester.tap(find.text(longTitle));
    await tester.pump();
    expect(checked, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox preference defaults to source start geometry', (
    tester,
  ) async {
    const longTitle = '这是用于验证原版复选框左右槽位间距的超长中文标题';
    var checked = false;
    late MiuixCheckboxColors checkboxColors;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              checkboxColors = MiuixCheckboxDefaults.checkboxColors(context);
              return Center(
                child: SizedBox(
                  width: 320,
                  child: MiuixCheckboxPreference.source(
                    title: longTitle,
                    checked: checked,
                    checkboxColors: checkboxColors,
                    onCheckedChange: (next) => checked = next,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final checkbox = find.byType(MiuixCheckbox);
    expect(
      tester.getCenter(checkbox).dx,
      lessThan(tester.getTopLeft(find.text(longTitle)).dx),
    );
    // Source uses 5dp inside the checkbox slot before BasicComponent's own
    // occupied-start gap, leaving three more logical pixels for the title.
    expect(tester.getSize(find.text(longTitle)).width, closeTo(233, .001));
    expect(tester.widget<MiuixCheckbox>(checkbox).colors, same(checkboxColors));
    await tester.tap(find.text(longTitle));
    await tester.pump();
    expect(checked, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio preference source retains start and empty end slots', (
    tester,
  ) async {
    const longTitle = '这是用于验证原版单选偏好左右槽位间距的超长中文标题';
    var activations = 0;
    late MiuixRadioButtonColors radioColors;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              radioColors = MiuixRadioButtonDefaults.radioButtonColors(context);
              return Center(
                child: SizedBox(
                  width: 320,
                  child: MiuixRadioButtonPreference.source(
                    title: longTitle,
                    selected: true,
                    radioButtonColors: radioColors,
                    onClick: () => activations += 1,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final radio = find.byType(MiuixRadio<bool>);
    expect(
      tester.getCenter(radio).dx,
      lessThan(tester.getTopLeft(find.text(longTitle)).dx),
    );
    // RadioButtonPreference.kt uses the same 5dp slot inset.
    expect(tester.getSize(find.text(longTitle)).width, closeTo(233, .001));
    expect(tester.widget<MiuixRadio<bool>>(radio).colors, same(radioColors));
    await tester.tap(find.text(longTitle));
    await tester.pump();
    expect(activations, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio preference text follows selected source colors', (
    tester,
  ) async {
    const ordinaryTitle = MiuixBasicComponentColors(
      color: Colors.black,
      disabledColor: Colors.grey,
    );
    const selectedTitle = MiuixBasicComponentColors(
      color: Colors.blue,
      disabledColor: Colors.blueGrey,
    );
    const ordinarySummary = MiuixBasicComponentColors(
      color: Colors.brown,
      disabledColor: Colors.grey,
    );
    const selectedSummary = MiuixBasicComponentColors(
      color: Colors.cyan,
      disabledColor: Colors.blueGrey,
    );
    const colors = MiuixRadioButtonPreferenceColors(
      titleColor: ordinaryTitle,
      selectedTitleColor: selectedTitle,
      summaryColor: ordinarySummary,
      selectedSummaryColor: selectedSummary,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixRadioButtonPreference.source(
                title: '已选标题',
                summary: '已选摘要',
                selected: true,
                colors: colors,
                onClick: null,
              ),
              MiuixRadioButtonPreference.source(
                title: '未选标题',
                summary: '未选摘要',
                selected: false,
                colors: colors,
                onClick: null,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('已选标题')).style?.color, Colors.blue);
    expect(tester.widget<Text>(find.text('已选摘要')).style?.color, Colors.cyan);
    expect(tester.widget<Text>(find.text('未选标题')).style?.color, Colors.black);
    expect(tester.widget<Text>(find.text('未选摘要')).style?.color, Colors.brown);
    expect(colors.copyWith(), colors);
    expect(colors.copyWith().hashCode, colors.hashCode);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection preferences forward source end slots and hold state', (
    tester,
  ) async {
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixSwitchPreference.source(
                key: const ValueKey('source-switch-preference'),
                title: '源式开关',
                summary: '开关摘要',
                checked: false,
                titleColor: titleColors,
                summaryColor: summaryColors,
                startAction: const SizedBox(
                  key: ValueKey('source-switch-start'),
                  width: 12,
                ),
                endActions: const Text('开关尾部'),
                holdDownState: true,
                onCheckedChange: (_) {},
              ),
              const MiuixCheckboxPreference.source(
                key: ValueKey('source-checkbox-preference'),
                title: '源式复选框',
                checked: true,
                titleColor: titleColors,
                summaryColor: summaryColors,
                endActions: Text('复选尾部'),
                checkboxLocation: MiuixCheckboxLocation.end,
                bottomAction: SizedBox(
                  key: ValueKey('source-checkbox-bottom'),
                  height: 8,
                ),
                holdDownState: true,
                onCheckedChange: null,
              ),
              MiuixRadioButtonPreference.source(
                key: const ValueKey('source-radio-preference'),
                title: '源式单选',
                selected: true,
                titleColor: titleColors,
                summaryColor: summaryColors,
                endActions: const Text('单选尾部'),
                radioButtonLocation: MiuixRadioButtonLocation.end,
                bottomAction: const SizedBox(
                  key: ValueKey('source-radio-bottom'),
                  height: 8,
                ),
                holdDownState: true,
                onClick: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byKey(const ValueKey('source-switch-start')), findsOneWidget);
    expect(find.text('开关尾部'), findsOneWidget);
    expect(find.text('复选尾部'), findsOneWidget);
    expect(find.text('单选尾部'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('source-checkbox-bottom')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('source-radio-bottom')), findsOneWidget);
    expect(tester.widget<Text>(find.text('源式开关')).style?.color, Colors.red);
    expect(tester.widget<Text>(find.text('开关摘要')).style?.color, Colors.green);
    for (final key in const [
      ValueKey('source-switch-preference'),
      ValueKey('source-checkbox-preference'),
      ValueKey('source-radio-preference'),
    ]) {
      final preference = find.byKey(key);
      final pressable = tester.widget<MiuixPressable>(
        find
            .descendant(of: preference, matching: find.byType(MiuixPressable))
            .first,
      );
      expect(pressable.holdDown, isTrue);
    }
    expect(
      tester.getCenter(find.byType(MiuixCheckbox)).dx,
      greaterThan(tester.getTopRight(find.text('源式复选框')).dx),
    );
    expect(
      tester.getCenter(find.byType(MiuixRadio<bool>)).dx,
      greaterThan(tester.getTopRight(find.text('源式单选')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown preference source forwards row contract', (
    tester,
  ) async {
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );
    const dropdownColors = MiuixDropdownColors(
      contentColor: Colors.purple,
      containerColor: Colors.black,
      selectedContentColor: Colors.yellow,
      selectedContainerColor: Colors.brown,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixOverlayDropdownPreference.source(
                key: const ValueKey('source-dropdown'),
                items: const ['选项一', '选项二'],
                selectedIndex: 1,
                title: '源式下拉偏好',
                titleColor: titleColors,
                summary: '下拉摘要',
                summaryColor: summaryColors,
                dropdownColors: dropdownColors,
                startAction: const SizedBox(
                  key: ValueKey('source-dropdown-start'),
                  width: 12,
                ),
                bottomAction: const SizedBox(
                  key: ValueKey('source-dropdown-bottom'),
                  height: 7,
                ),
                insideMargin: const EdgeInsetsDirectional.fromSTEB(
                  14,
                  9,
                  16,
                  5,
                ),
                maxHeight: 123,
                showValue: false,
                onSelectedIndexChange: null,
              ),
              MiuixWindowDropdownPreference.source(
                key: const ValueKey('empty-source-dropdown'),
                items: const [],
                selectedIndex: 99,
                title: '空源式下拉偏好',
                onSelectedIndexChange: null,
              ),
            ],
          ),
        ),
      ),
    );

    final source = tester.widget<MiuixOverlayDropdownPreference<int>>(
      find.byKey(const ValueKey('source-dropdown')),
    );
    expect(source.value, 1);
    expect(source.entries.map((entry) => entry.label), ['选项一', '选项二']);
    expect(source.titleColors, same(titleColors));
    expect(source.summaryColors, same(summaryColors));
    expect(source.dropdownColors, same(dropdownColors));
    expect(
      source.insideMargin,
      const EdgeInsetsDirectional.fromSTEB(14, 9, 16, 5),
    );
    expect(source.maxHeight, 123);
    expect(source.showValue, isFalse);
    expect(find.byKey(const ValueKey('source-dropdown-start')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('source-dropdown-bottom')),
      findsOneWidget,
    );
    expect(find.text('选项二'), findsNothing);
    expect(find.text('No actions'), findsNothing);
    expect(find.text('Unavailable'), findsNothing);
    expect(tester.widget<Text>(find.text('源式下拉偏好')).style?.fontSize, 17);
    expect(tester.widget<Text>(find.text('下拉摘要')).style?.fontSize, 14);

    final emptyPreference = tester.widget<MiuixPreference>(
      find.descendant(
        of: find.byKey(const ValueKey('empty-source-dropdown')),
        matching: find.byType(MiuixPreference),
      ),
    );
    expect(emptyPreference.enabled, isFalse);
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(const ValueKey('empty-source-dropdown')),
              matching: find.byType(CustomPaint),
            ),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  test('preference source factories normalize stale selected indexes', () {
    const dropdownItems = ['一', '二'];
    const spinnerItems = [
      MiuixSpinnerEntry(title: '一'),
      MiuixSpinnerEntry(title: '二'),
    ];

    // Persisted settings can outlive a shortened option list. Both host
    // families must project that stale value into the current valid domain.
    expect(
      MiuixOverlayDropdownPreference.source(
        items: dropdownItems,
        selectedIndex: -7,
        title: 'Overlay dropdown',
      ).value,
      0,
    );
    expect(
      MiuixWindowDropdownPreference.source(
        items: dropdownItems,
        selectedIndex: 99,
        title: 'Window dropdown',
      ).value,
      1,
    );
    expect(
      MiuixOverlaySpinnerPreference.source(
        items: spinnerItems,
        selectedIndex: -7,
        title: 'Overlay spinner',
      ).value,
      0,
    );
    expect(
      MiuixWindowSpinnerPreference.source(
        items: spinnerItems,
        selectedIndex: 99,
        title: 'Window spinner',
      ).value,
      1,
    );
  });

  testWidgets('spinner preference source forwards rich row contract', (
    tester,
  ) async {
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );
    const spinnerColors = MiuixSpinnerColors(
      contentColor: Colors.purple,
      summaryColor: Colors.orange,
      containerColor: Colors.black,
      selectedContentColor: Colors.yellow,
      selectedSummaryColor: Colors.green,
      selectedContainerColor: Colors.brown,
      selectedIndicatorColor: Colors.cyan,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixOverlaySpinnerPreference.source(
                key: const ValueKey('source-spinner'),
                items: const [
                  MiuixSpinnerEntry(title: '富选项一', summary: '摘要一'),
                  MiuixSpinnerEntry(title: '富选项二', summary: '摘要二'),
                ],
                selectedIndex: 1,
                title: '源式选择器',
                titleColor: titleColors,
                summary: '源式摘要',
                summaryColor: summaryColors,
                spinnerColors: spinnerColors,
                startAction: const SizedBox(
                  key: ValueKey('source-spinner-start'),
                ),
                bottomAction: const SizedBox(
                  key: ValueKey('source-spinner-bottom'),
                ),
                insideMargin: const EdgeInsetsDirectional.fromSTEB(
                  14,
                  9,
                  16,
                  5,
                ),
                maxHeight: 123,
                showValue: false,
                onSelectedIndexChange: null,
              ),
              MiuixWindowSpinnerPreference.source(
                key: const ValueKey('empty-source-spinner'),
                items: const [],
                selectedIndex: 99,
                title: '空源式选择器',
                onSelectedIndexChange: null,
              ),
            ],
          ),
        ),
      ),
    );

    final source = tester.widget<MiuixOverlaySpinnerPreference<int>>(
      find.byKey(const ValueKey('source-spinner')),
    );
    expect(source.titleColors, same(titleColors));
    expect(source.summaryColors, same(summaryColors));
    expect(source.spinnerColors, same(spinnerColors));
    expect(
      source.insideMargin,
      const EdgeInsetsDirectional.fromSTEB(14, 9, 16, 5),
    );
    expect(tester.widget<Text>(find.text('源式选择器')).style?.fontSize, 17);
    expect(tester.widget<Text>(find.text('源式摘要')).style?.fontSize, 14);
    expect(source.maxHeight, 123);
    expect(source.showValue, isFalse);
    expect(find.byKey(const ValueKey('source-spinner-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-spinner-bottom')), findsOneWidget);
    expect(find.text('富选项二'), findsNothing);

    final emptyPreference = tester.widget<MiuixPreference>(
      find.descendant(
        of: find.byKey(const ValueKey('empty-source-spinner')),
        matching: find.byType(MiuixPreference),
      ),
    );
    expect(emptyPreference.enabled, isFalse);
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byKey(const ValueKey('empty-source-spinner')),
              matching: find.byType(CustomPaint),
            ),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('slider preference exposes the complete source end area', (
    tester,
  ) async {
    var taps = 0;
    var value = .5;
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 320,
              child: MiuixSliderPreference.source(
                key: const ValueKey('source-slider-preference'),
                value: value,
                onValueChange: (next) => value = next,
                title: 'Volume',
                titleColor: titleColors,
                summary: 'Summary',
                summaryColor: summaryColors,
                startAction: const SizedBox(
                  key: ValueKey('source-slider-start'),
                  width: 24,
                  height: 24,
                ),
                valueText: '50%',
                endActions: const SizedBox(
                  key: ValueKey('source-slider-end'),
                  width: 12,
                  height: 12,
                ),
                bottomAction: const SizedBox(
                  key: ValueKey('source-slider-bottom'),
                  height: 6,
                ),
                onClick: () => taps++,
                holdDownState: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final root = find.byKey(const ValueKey('source-slider-preference'));
    expect(find.byKey(const ValueKey('source-slider-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-slider-end')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-slider-bottom')), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Volume')).style?.color, Colors.red);
    expect(
      tester.widget<Text>(find.text('Summary')).style?.color,
      Colors.green,
    );
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(of: root, matching: find.byType(CustomPaint)),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(of: root, matching: find.byType(MiuixPressable)).first,
    );
    expect(pressable.holdDown, isTrue);
    await tester.tap(find.text('Volume'));
    await tester.pump();
    expect(taps, 1);
    tester.widget<MiuixSlider>(find.byType(MiuixSlider)).onChanged?.call(.75);
    expect(value, .75);
    expect(tester.takeException(), isNull);
  });

  testWidgets('range slider preference exposes the complete source surface', (
    tester,
  ) async {
    var taps = 0;
    var value = const RangeValues(.2, .8);
    const titleColors = MiuixBasicComponentColors(
      color: Colors.red,
      disabledColor: Colors.blue,
    );
    const summaryColors = MiuixBasicComponentColors(
      color: Colors.green,
      disabledColor: Colors.orange,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 420,
              child: MiuixRangeSliderPreference.source(
                key: const ValueKey('source-range-slider-preference'),
                value: value,
                onValueChange: (next) => value = next,
                title: 'Range',
                titleColor: titleColors,
                summary: 'Summary',
                summaryColor: summaryColors,
                startAction: const SizedBox(
                  key: ValueKey('source-range-slider-start'),
                  width: 24,
                  height: 24,
                ),
                valueText: '20% - 80%',
                endActions: const SizedBox(
                  key: ValueKey('source-range-slider-end'),
                  width: 12,
                  height: 12,
                ),
                bottomAction: const SizedBox(
                  key: ValueKey('source-range-slider-bottom'),
                  height: 6,
                ),
                onClick: () => taps++,
                holdDownState: true,
                min: 0,
                max: 10,
                steps: 9,
                showKeyPoints: true,
                keyPoints: const [0, 2, 4, 6, 8, 10],
                magnetThreshold: .03,
                sliderHeight: 30,
                hapticEffect: MiuixSliderHapticEffect.step,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final root = find.byKey(const ValueKey('source-range-slider-preference'));
    expect(
      find.byKey(const ValueKey('source-range-slider-start')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('source-range-slider-end')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('source-range-slider-bottom')),
      findsOneWidget,
    );
    expect(find.text('20% - 80%'), findsOneWidget);
    expect(tester.widget<Text>(find.text('Range')).style?.color, Colors.red);
    expect(
      tester.widget<Text>(find.text('Summary')).style?.color,
      Colors.green,
    );
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(of: root, matching: find.byType(CustomPaint)),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(of: root, matching: find.byType(MiuixPressable)).first,
    );
    expect(pressable.holdDown, isTrue);
    final slider = tester.widget<MiuixRangeSlider>(
      find.descendant(of: root, matching: find.byType(MiuixRangeSlider)),
    );
    expect(slider.divisions, 10);
    expect(slider.height, 30);
    expect(slider.showKeyPoints, isTrue);
    expect(slider.keyPoints, const [0, 2, 4, 6, 8, 10]);
    expect(slider.magnetThreshold, .03);
    expect(slider.hapticEffect, MiuixSliderHapticEffect.step);
    await tester.tap(find.text('Range'));
    await tester.pump();
    expect(taps, 1);
    slider.onChanged?.call(const RangeValues(3, 7));
    expect(value, const RangeValues(3, 7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('slider preferences route HyperOS 4 and source row metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                const MiuixSliderPreference(
                  title: 'Hyper volume',
                  summary: 'Hyper summary',
                  value: .45,
                  onChanged: _ignoreSliderPreferenceDouble,
                ),
                MiuixSliderPreference.source(
                  title: 'Source volume',
                  summary: 'Source summary',
                  value: .45,
                  onValueChange: _ignoreSliderPreferenceDouble,
                ),
                const MiuixRangeSliderPreference(
                  title: 'Hyper range',
                  summary: 'Hyper range summary',
                  values: RangeValues(.2, .8),
                  onChanged: _ignoreSliderPreferenceRange,
                ),
                MiuixRangeSliderPreference.source(
                  title: 'Source range',
                  summary: 'Source range summary',
                  value: const RangeValues(.2, .8),
                  onValueChange: _ignoreSliderPreferenceRange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.widget<Text>(find.text('Hyper volume')).style?.fontSize, 16);
    expect(tester.widget<Text>(find.text('Hyper summary')).style?.fontSize, 13);
    expect(tester.widget<Text>(find.text('Source volume')).style?.fontSize, 17);
    expect(
      tester.widget<Text>(find.text('Source summary')).style?.fontSize,
      14,
    );
    expect(tester.widget<Text>(find.text('Hyper range')).style?.fontSize, 16);
    expect(
      tester.widget<Text>(find.text('Hyper range summary')).style?.fontSize,
      13,
    );
    expect(tester.widget<Text>(find.text('Source range')).style?.fontSize, 17);
    expect(
      tester.widget<Text>(find.text('Source range summary')).style?.fontSize,
      14,
    );

    final rows = tester.widgetList<MiuixPreference>(
      find.byType(MiuixPreference),
    );
    expect(rows.map((row) => row.sourceStyle), <bool>[
      false,
      true,
      false,
      true,
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow preference supports source bottom action and hold-down', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 320,
              child: MiuixCard(
                padding: EdgeInsets.zero,
                child: MiuixArrowPreference.source(
                  key: const ValueKey('held-arrow'),
                  title: 'Arrow + Slider + Dialog',
                  startAction: const Icon(
                    Icons.person_outline,
                    key: ValueKey('arrow-source-leading-icon'),
                  ),
                  endActions: const Text('50%'),
                  bottomAction: const MiuixSlider(
                    key: ValueKey('arrow-bottom-slider'),
                    value: .5,
                    onChanged: _ignoreDouble,
                  ),
                  holdDownState: true,
                  onClick: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final arrow = find.byKey(const ValueKey('held-arrow'));
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(of: arrow, matching: find.byType(MiuixPressable)),
    );
    expect(find.byKey(const ValueKey('arrow-bottom-slider')), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('arrow-source-leading-icon'))),
      const Size.square(24),
    );
    expect(pressable.holdDown, isTrue);
    expect(pressable.feedbackType, MiuixPressFeedbackType.none);
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(of: arrow, matching: find.byType(CustomPaint)),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    expect(find.byIcon(Icons.chevron_right), findsNothing);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final indication = tester.widget<FadeTransition>(
      find.descendant(
        of: arrow,
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
    );
    expect(indication.opacity.value, inExclusiveRange(0, .10));
    await tester.pumpAndSettle();
    expect(indication.opacity.value, closeTo(.10, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow preference forwards independent text style overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixArrowPreference(
            title: 'Platform title',
            summary: 'Platform summary',
            titleStyle: TextStyle(fontFamily: 'Roboto', letterSpacing: .25),
            summaryStyle: TextStyle(fontFamily: 'Roboto', letterSpacing: .5),
          ),
        ),
      ),
    );

    // Consumers can restore a platform Latin face without losing the active
    // HyperOS role's weight, size, line height, or semantic foreground.
    final title = tester.widget<Text>(find.text('Platform title'));
    final summary = tester.widget<Text>(find.text('Platform summary'));
    expect(title.style?.fontFamily, 'Roboto');
    expect(title.style?.fontSize, 16);
    expect(title.style?.fontWeight, FontWeight.w500);
    expect(title.style?.letterSpacing, .25);
    expect(summary.style?.fontFamily, 'Roboto');
    expect(summary.style?.fontSize, 13);
    expect(summary.style?.letterSpacing, .5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backdrop exposes MIUIX texture adjustment parameters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixLayerBackdrop(
              backdrop: MiuixBackdrop(
                blur: 80,
                noise: .04,
                brightness: .1,
                contrast: 1.2,
                saturation: .8,
              ),
              child: Text('Texture blur'),
            ),
          ),
        ),
      ),
    );

    // Non-neutral texture parameters add both the color matrix and the grain
    // layer while retaining the shared MiuixGlass implementation.
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.byType(MiuixGlass), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    final effectContent = tester
        .widgetList<Stack>(
          find.descendant(
            of: find.byType(MiuixLayerBackdrop),
            matching: find.byType(Stack),
          ),
        )
        .singleWhere(
          (stack) => stack.children.any(
            (child) => child.key == const ValueKey('miuix-blur-noise-layer'),
          ),
        );
    expect(
      effectContent.children.first.key,
      const ValueKey('miuix-blur-noise-layer'),
    );
    expect(effectContent.children.last, isA<Text>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('blur color controls precede source blend layers', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixLayerBackdrop(
              backdrop: MiuixBackdrop(
                brightness: .1,
                contrast: 1.2,
                saturation: .8,
                colors: MiuixBlurColors(
                  blendColors: [
                    MiuixBlurBlendEntry(
                      Color(0x803F3F3F),
                      MiuixBlurBlendMode.overlay,
                    ),
                  ],
                ),
              ),
              child: Text('Ordered texture effect'),
            ),
          ),
        ),
      ),
    );

    final fallbackLayers = find.byKey(
      const ValueKey('miuix-blur-blend-layers'),
    );
    final matrix = find.byKey(const ValueKey('miuix-blur-color-controls'));
    if (ImageFilter.isShaderFilterSupported) {
      // The accelerated shader performs the source nonlinear color controls
      // before dispatching its ordered blend entries.
      expect(fallbackLayers, findsNothing);
      expect(matrix, findsNothing);
    } else {
      expect(fallbackLayers, findsOneWidget);
      expect(matrix, findsOneWidget);
      expect(
        find.descendant(of: fallbackLayers, matching: matrix),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  test('backdrop fallback matrix uses current Rec.709 luma constants', () {
    final matrix = debugMiuixBackdropColorMatrix(
      const MiuixBackdrop(brightness: .1, contrast: 1.2, saturation: .8),
    );
    expect(matrix[0], closeTo(1.011024, 1e-9));
    expect(matrix[1], closeTo(.171648, 1e-9));
    expect(matrix[2], closeTo(.017328, 1e-9));
    expect(matrix[5], closeTo(.051024, 1e-9));
    expect(matrix[6], closeTo(1.131648, 1e-9));
    expect(matrix[12], closeTo(.977328, 1e-9));
    expect(matrix[4], closeTo(0, 1e-9));
    expect(matrix[9], closeTo(0, 1e-9));
    expect(matrix[14], closeTo(0, 1e-9));
  });

  test(
    'progressive blur exposes the current source defaults and directions',
    () {
      expect(MiuixBlurDefaults.blurRadius, 20);
      expect(MiuixBlurDefaults.noiseCoefficient, .0045);
      expect(MiuixBlurDefaults.progressiveNoiseCoefficient, 0);
      expect(MiuixBlurDefaults.maxBlurRadius, 150);
      expect(MiuixProgressiveBlur.top.angle, 90);
      expect(MiuixProgressiveBlur.bottom.angle, 270);
      expect(MiuixProgressiveBlur.left.angle, 0);
      expect(MiuixProgressiveBlur.right.angle, 180);
      expect(
        MiuixProgressiveBlur.top.copyWith(curve: 2),
        const MiuixProgressiveBlur(curve: 2),
      );
    },
  );

  test('source blur radius remains in dp before the 0.45 sigma conversion', () {
    expect(debugMiuixSourceBlurSigma(100), 45);
    expect(debugMiuixSourceBlurSigma(20), 9);
    expect(debugMiuixSourceBlurSigma(-10), 0);
    expect(debugMiuixSourceBlurSigma(double.nan), 0);
  });

  test('both foreground Logo Blend themes select the lean Lab shader', () {
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(Color(0xCC4A4A4A), MiuixBlurBlendMode.colorBurn),
        MiuixBlurBlendEntry(Color(0xFF4F4F4F), MiuixBlurBlendMode.linearLight),
        MiuixBlurBlendEntry(Color(0xFF1AF200), MiuixBlurBlendMode.lab),
      ]),
      'shaders/miuix_texture_blend_logo.frag',
    );
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(Color(0xE6A1A1A1), MiuixBlurBlendMode.colorDodge),
        MiuixBlurBlendEntry(Color(0x4DE6E6E6), MiuixBlurBlendMode.linearLight),
        MiuixBlurBlendEntry(Color(0xFF1AF500), MiuixBlurBlendMode.lab),
      ]),
      'shaders/miuix_texture_blend_logo.frag',
    );
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(Color(0x803F3F3F), MiuixBlurBlendMode.overlay),
      ]),
      'shaders/miuix_texture_blend_standard.frag',
    );
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(Color(0xFFFFFFFF), MiuixBlurBlendMode.plusLighter),
      ]),
      'shaders/miuix_texture_blend_arithmetic.frag',
    );
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(Color(0x4DA9A9A9), MiuixBlurBlendMode.luminosity),
        MiuixBlurBlendEntry(Color(0x1A9C9C9C), MiuixBlurBlendMode.plusDarker),
      ]),
      'shaders/miuix_texture_blend_arithmetic.frag',
    );
    expect(
      debugMiuixBlendShaderAsset(const [
        MiuixBlurBlendEntry(
          Color(0xFFFFFFFF),
          MiuixBlurBlendMode.linearLightLab,
        ),
      ]),
      'shaders/miuix_texture_blend_lab.frag',
    );
  });

  testWidgets('progressive backdrop builds the source three-level stack', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 240,
            height: 120,
            child: MiuixProgressiveLayerBackdrop(
              gradient: MiuixProgressiveBlur.right,
              child: Text('Sharp foreground'),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('miuix-progressive-blur-level-13')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('miuix-progressive-blur-level-40')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('miuix-progressive-blur-level-100')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('miuix-progressive-post-effect-mask')),
      findsOneWidget,
    );
    expect(find.byType(ShaderMask), findsNWidgets(4));
    expect(find.byType(MiuixLayerBackdrop), findsOneWidget);
    expect(find.text('Sharp foreground'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixProgressiveLayerBackdrop(
            backdrop: MiuixBackdrop(enabled: false),
            child: Text('Disabled effect'),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('miuix-progressive-blur-level-100')),
      findsNothing,
    );
    expect(find.text('Disabled effect'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('backdrop uses the source two-light highlight presets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 240,
            height: 120,
            child: MiuixLayerBackdrop(
              backdrop: MiuixBackdrop(
                highlight: MiuixHighlight.glassStrokeSmallDark,
              ),
              child: Text('Highlighted'),
            ),
          ),
        ),
      ),
    );

    const highlight = MiuixHighlight.glassStrokeSmallDark;
    expect(highlight.width, .8);
    expect(highlight.blur, 2.3);
    expect(highlight.primaryIntensity, .6);
    expect(highlight.secondaryIntensity, .25);
    expect(highlight.secondaryPosition.dy, .95);
    expect(highlight.secondaryPosition.z, -.36);
    expect(
      find.byKey(const ValueKey('miuix-backdrop-highlight')),
      findsOneWidget,
    );
    expect(find.text('Highlighted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('blur source models retain controls, entry defaults, and raw codes', () {
    const entry = MiuixBlendColorEntry(Color(0x66336699));
    final colors = MiuixBlurDefaults.blurColors(
      blendColors: const [entry],
      brightness: .12,
      contrast: 1.08,
      saturation: .82,
    );

    expect(entry.mode, MiuixBlurBlendMode.srcOver);
    expect(colors.blendColors, const [entry]);
    expect(colors.brightness, .12);
    expect(colors.contrast, 1.08);
    expect(colors.saturation, .82);
    expect(colors.copyWith(brightness: -.2).brightness, -.2);
    expect(colors.copyWith(brightness: -.2).blendColors, const [entry]);
    expect(debugMiuixBlurBlendModeValue(MiuixBlurBlendMode.clear), 0);
    expect(debugMiuixBlurBlendModeValue(MiuixBlurBlendMode.luminosity), 28);
    expect(debugMiuixBlurBlendModeValue(MiuixBlurBlendMode.linearLight), 100);
    expect(debugMiuixBlurBlendModeValue(MiuixBlurBlendMode.alphaBlend), 200);
    expect(debugMiuixBlurBlendModeValue(MiuixBlurBlendMode.miLuminance), 203);
    expect(
      debugCanUseMiuixBlendShader(const [
        MiuixBlendColorEntry(Colors.white, MiuixBlurBlendMode.alphaBlend),
      ]),
      isTrue,
    );
    expect(
      debugCanUseMiuixBlendShader(const [
        MiuixBlendColorEntry(Colors.white, MiuixBlurBlendMode.srcIn),
      ]),
      isFalse,
      reason: 'Flutter native blending is exact for the remaining Skia modes',
    );

    final scope = const MiuixBackdropEffectScope(
      child: SizedBox(),
    ).blendColors(colors);
    expect(scope.backdrop.colors, colors);
    expect(scope.backdrop.brightness, .12);
    expect(scope.backdrop.contrast, 1.08);
    expect(scope.backdrop.saturation, .82);
  });

  test('highlight source hierarchy selects single and dual bloom programs', () {
    const primary = MiuixLightSource(
      position: MiuixLightPosition(dx: .2, dy: .4, z: -.3),
      color: Color(0xCCFFEEDD),
      intensity: .7,
    );
    const dualStyle = MiuixBloomStroke(
      blendMode: BlendMode.screen,
      innerBlurRadius: 3.2,
      primaryLight: primary,
      secondaryLight: MiuixLightSource(
        position: MiuixLightPosition(dx: .8, dy: .9, z: -.2),
        intensity: 0,
      ),
      dualPeak: true,
    );
    const dual = MiuixHighlight(width: 1.1, alpha: .8, style: dualStyle);

    expect(dual.resolvedStyle, dualStyle);
    expect(dualStyle.primaryLight, primary);
    expect(dualStyle.blendMode, BlendMode.screen);
    expect(
      debugMiuixHighlightShaderAsset(dual),
      'shaders/miuix_bloom_stroke_dual.frag',
    );
    expect(
      debugMiuixHighlightShaderAsset(MiuixHighlight.glassStrokeMiddleLight),
      'shaders/miuix_bloom_stroke.frag',
    );
    expect(
      MiuixHighlightStyle.defaultStyle,
      MiuixBloomStroke.glassStrokeMiddleLight,
    );
  });

  testWidgets(
    'standalone highlight overlay preserves content and shader path',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 220,
              height: 64,
              child: MiuixHighlightOverlay(
                highlight: const MiuixHighlight(
                  width: 1,
                  blur: 2,
                  primaryIntensity: 1,
                  secondaryIntensity: .4,
                ),
                radius: 32,
                child: Semantics(
                  label: 'Liquid navigation content',
                  child: const ColoredBox(color: Color(0x22000000)),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The focused renderer must not replace, duplicate, or intercept the
      // component content it decorates. Runtime-capable hosts use BloomStroke;
      // other hosts retain the library's deterministic gradient fallback.
      expect(find.byType(MiuixHighlightOverlay), findsOneWidget);
      expect(
        find.bySemanticsLabel('Liquid navigation content'),
        findsOneWidget,
      );
      final runtime = find.byKey(
        const ValueKey('miuix-highlight-overlay-runtime'),
      );
      final fallback = find.byKey(
        const ValueKey('miuix-highlight-overlay-fallback'),
      );
      expect(runtime.evaluate().length + fallback.evaluate().length, 1);
      expect(tester.takeException(), isNull);
    },
  );

  test('tilt-driven highlights use the source pitch and roll equations', () {
    const base = MiuixHighlight.glassStrokeSmallLight;
    const tilt = MiuixDeviceTilt(
      pitch: .4,
      roll: -.2,
      gravityX: .1,
      gravityY: -.3,
    );

    final driven = base.drivenByTilt(tilt);

    // rememberContainerHighlight uses .15 for the primary light and .12 for
    // the secondary light. Both preserve their original signed depth.
    expect(driven.position.dx, closeTo(.47, .000001));
    expect(driven.position.dy, closeTo(.44, .000001));
    expect(driven.position.z, base.position.z);
    expect(driven.secondaryPosition.dx, closeTo(.476, .000001));
    expect(driven.secondaryPosition.dy, closeTo(.902, .000001));
    expect(driven.secondaryPosition.z, base.secondaryPosition.z);
    // Transforming the immutable preset must not accumulate motion into the
    // shared constants used by another card or a later sensor frame.
    expect(base.position, same(MiuixHighlight.glassStrokeSmallLight.position));
    expect(base.position.dx, .5);
    expect(base.secondaryPosition.dy, .95);
  });

  testWidgets('basic component summary uses MIUIX body2 sizing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixBasicComponent.sourceText(
              title: 'Component title',
              summary: 'Component summary',
            ),
          ),
        ),
      ),
    );

    final summary = tester.widget<Text>(find.text('Component summary'));
    final component = tester.getRect(find.byType(MiuixBasicComponent));

    expect(summary.style?.fontSize, 14);
    expect(summary.style?.height, 1.17);
    // 16dp top/bottom padding plus the source-equivalent 17sp and 14sp line
    // boxes produces the same 68dp two-line row seen in the Compose sample.
    expect(component.height, 68);
    expect(summary.maxLines, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('each basic component rounds its height before siblings add', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixBasicComponent.sourceText(
                key: ValueKey('first-rounded-component'),
                title: 'Title',
                summary: 'Summary',
              ),
              MiuixBasicComponent.sourceText(
                key: ValueKey('second-rounded-component'),
                title: 'Title',
                summary: 'Summary',
              ),
            ],
          ),
        ),
      ),
    );

    final first = tester.getSize(
      find.byKey(const ValueKey('first-rounded-component')),
    );
    final second = tester.getSize(
      find.byKey(const ValueKey('second-rounded-component')),
    );
    expect(first.height * 2.625, closeTo(179, 1e-9));
    expect(second.height * 2.625, closeTo(179, 1e-9));
  });

  testWidgets('button rounds source padding and text stages independently', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixButton.source(label: 'Button', onPressed: () {}),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MiuixButton));
    expect(size.height * 2.625, closeTo(120, 1e-9));
  });

  testWidgets('button keeps 120px paint and exposes the 48dp Android target', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const buttonKey = ValueKey('expanded-target-button');
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MiuixButton.source(
                      key: buttonKey,
                      label: '按钮',
                      onPressed: () => taps++,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );

    final visualRect = tester.getRect(find.byKey(buttonKey));
    expect(visualRect.height * 2.625, closeTo(120, 1e-9));
    final semantics = tester.getSemantics(find.byKey(buttonKey));
    expect(semantics.rect.height * 2.625, closeTo(126, 1e-9));
    expect(semantics.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

    // Two physical pixels above the paint remain inside Compose's three-pixel
    // top expansion at 420dpi. This pointer must show indication and activate.
    final gesture = await tester.startGesture(
      Offset(visualRect.center.dx, visualRect.top - (2 / 2.625)),
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.widget<MiuixPressable>(find.byType(MiuixPressable)).holdDown,
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 40));
    final indication = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('miuix-press-indication')),
    );
    expect(indication.opacity.value, greaterThan(0));
    await gesture.up();
    await tester.pump();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field keeps the source physical single-line height', (
    tester,
  ) async {
    final multilineController = TextEditingController(text: 'one\ntwo');
    addTearDown(multilineController.dispose);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 320, child: MiuixTextField()),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(MiuixTextField));
    expect(size.height * 2.625, closeTo(136, 1e-9));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: MiuixTextField(controller: multilineController),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MiuixTextField)).height * 2.625,
      closeTo(188, 1e-9),
    );
  });

  testWidgets(
    'preference row follows source height padding and title metrics',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: MiuixPreference.source(
                    key: ValueKey('source-preference-row'),
                    title: 'Source title',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // BasicComponent.kt specifies heightIn(min = 56.dp), 16dp inside margin,
      // and the 17sp medium headline1 style for the title.
      final row = tester.getRect(
        find.byKey(const ValueKey('source-preference-row')),
      );
      final title = tester.widget<Text>(find.text('Source title'));
      final titleRect = tester.getRect(find.text('Source title'));
      expect(row.height, 56);
      expect(title.style?.fontSize, 17);
      expect(title.style?.fontWeight, FontWeight.w500);
      expect(title.maxLines, isNull);
      expect(titleRect.left - row.left, 16);
      expect(row.right - titleRect.right, greaterThanOrEqualTo(16));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'preference rows separate HyperOS hierarchy from source metrics',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    const SizedBox(
                      key: ValueKey('standard-row-host'),
                      width: 320,
                      child: MiuixPreference(title: 'Standard direct'),
                    ),
                    const SizedBox(
                      key: ValueKey('source-row-host'),
                      width: 320,
                      child: MiuixPreference.source(title: 'Source direct'),
                    ),
                    const MiuixPreference(
                      title: 'Standard supporting host',
                      summary: 'Standard summary',
                    ),
                    const MiuixPreference.source(
                      title: 'Source supporting host',
                      summary: 'Source summary',
                    ),
                    const MiuixBasicComponent(
                      title: 'Standard basic',
                      standalone: false,
                    ),
                    const MiuixBasicComponent.sourceText(title: 'Source basic'),
                    MiuixArrowPreference(title: 'Standard arrow', onTap: () {}),
                    MiuixArrowPreference.source(
                      title: 'Source arrow',
                      onClick: () {},
                    ),
                    MiuixSwitchPreference(
                      title: 'Standard switch',
                      value: true,
                      onChanged: (_) {},
                    ),
                    MiuixSwitchPreference.source(
                      title: 'Source switch',
                      checked: true,
                      onCheckedChange: (_) {},
                    ),
                    MiuixCheckboxPreference(
                      title: 'Standard checkbox',
                      value: true,
                      onChanged: (_) {},
                    ),
                    MiuixCheckboxPreference.source(
                      title: 'Source checkbox',
                      checked: true,
                      onCheckedChange: (_) {},
                    ),
                    MiuixRadioButtonPreference<int>(
                      title: 'Standard radio',
                      value: 1,
                      groupValue: 1,
                      onChanged: (_) {},
                    ),
                    MiuixRadioButtonPreference.source(
                      title: 'Source radio',
                      selected: true,
                      onClick: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      Text text(String label) => tester.widget<Text>(find.text(label));
      for (final label in <String>[
        'Standard direct',
        'Standard basic',
        'Standard arrow',
        'Standard switch',
        'Standard checkbox',
        'Standard radio',
      ]) {
        expect(text(label).style?.fontSize, 16, reason: label);
        expect(text(label).style?.fontWeight, FontWeight.w500, reason: label);
      }
      for (final label in <String>[
        'Source direct',
        'Source basic',
        'Source arrow',
        'Source switch',
        'Source checkbox',
        'Source radio',
      ]) {
        expect(text(label).style?.fontSize, 17, reason: label);
        expect(text(label).style?.fontWeight, FontWeight.w500, reason: label);
      }
      expect(text('Standard summary').style?.fontSize, 13);
      expect(text('Source summary').style?.fontSize, 14);
      expect(
        tester.getSize(find.byKey(const ValueKey('standard-row-host'))).height,
        60,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('source-row-host'))).height,
        greaterThanOrEqualTo(56),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'settings group resolves HyperOS glass tokens and local overrides',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                settingsGroupCornerRadius: 27,
                contentSurfaceBlur: 34,
                contentSurfaceTintOpacity: .36,
              ),
            ),
            child: const MiuixSettingsGroup(
              children: <Widget>[MiuixPreference(title: 'Account')],
            ),
          ),
        ),
      );

      var surface = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-settings-group-surface')),
      );
      expect(surface.glass, isTrue);
      expect(surface.glassBlur, 34);
      expect(surface.glassOpacity, .36);
      expect(surface.showGlassSpecular, isTrue);
      expect(surface.radius, 27);

      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: MiuixSettingsGroup(
              glass: false,
              glassBlur: 39,
              glassOpacity: .24,
              showGlassSpecular: false,
              cornerRadius: 31,
              surfaceColor: Color(0xff123456),
              border: BorderSide(color: Color(0xffabcdef), width: 2),
              children: <Widget>[MiuixPreference(title: 'Custom')],
            ),
          ),
        ),
      );
      surface = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-settings-group-surface')),
      );
      expect(surface.glass, isFalse);
      expect(surface.glassBlur, 39);
      expect(surface.glassOpacity, .24);
      expect(surface.showGlassSpecular, isFalse);
      expect(surface.radius, 31);
      expect(surface.color, const Color(0xff123456));
      expect(
        surface.border,
        const BorderSide(color: Color(0xffabcdef), width: 2),
      );
    },
  );

  testWidgets(
    'settings group source stays opaque and rows are divider-free by default',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: MiuixSettingsGroup.source(
                children: [
                  MiuixPreference(title: 'First'),
                  MiuixPreference(title: 'Second'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upstream Card.kt simply places its composables in a Column. Consumers
      // can still request separators explicitly for non-source screens.
      expect(find.byType(Divider), findsNothing);
      final surface = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-settings-group-surface')),
      );
      expect(surface.glass, isFalse);
      expect(surface.showGlassSpecular, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('top app bar uses MIUIX title metrics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            appBar: MiuixSmallTopAppBar(title: 'Centered title'),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );

    final compactTitle = tester.widget<Text>(find.text('Centered title'));
    final compactCenter = tester.getCenter(find.text('Centered title'));

    expect(const MiuixSmallTopAppBar(title: 'x').preferredSize.height, 52);
    expect(compactTitle.style?.fontSize, 20);
    expect(compactTitle.style?.fontWeight, FontWeight.w500);
    expect(compactCenter.dx, closeTo(400, 2));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 220,
              height: 52,
              child: MiuixSmallTopAppBar(
                title: 'A very long centered title',
                leading: SizedBox(
                  key: ValueKey('top-leading'),
                  width: 40,
                  height: 40,
                ),
                actions: [
                  SizedBox(key: ValueKey('top-action'), width: 40, height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final narrowTitleRect = tester.getRect(
      find.text('A very long centered title'),
    );
    final leadingRect = tester.getRect(
      find.byKey(const ValueKey('top-leading')),
    );
    final actionRect = tester.getRect(find.byKey(const ValueKey('top-action')));

    expect(leadingRect.left, closeTo(306, 1));
    expect(actionRect.right, closeTo(494, 1));
    expect(narrowTitleRect.left, greaterThanOrEqualTo(leadingRect.right));
    expect(narrowTitleRect.right, lessThanOrEqualTo(actionRect.left));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            appBar: MiuixTopAppBar(title: 'Large title'),
            body: SizedBox.shrink(),
          ),
        ),
      ),
    );

    // The native layout keeps both title nodes mounted: the expanded 32sp
    // title is visible while the compact 20sp title remains at zero alpha.
    final expandedTitleFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Text &&
          widget.data == 'Large title' &&
          widget.style?.fontSize == 32,
    );
    final largeTitle = tester.widget<Text>(expandedTitleFinder);

    expect(const MiuixTopAppBar(title: 'x').preferredSize.height, 94);
    expect(largeTitle.style?.fontSize, 32);
    expect(largeTitle.style?.fontWeight, FontWeight.w400);
    expect(tester.getTopLeft(expandedTitleFinder).dx, closeTo(26, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'top app bar keeps top system inset when optional side insets are disabled',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, left: 12, right: 10);
      tester.view.viewPadding = const FakeViewPadding(
        top: 24,
        left: 12,
        right: 10,
      );
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.topCenter,
              child: MiuixSmallTopAppBar(
                title: 'Wide title',
                defaultWindowInsetsPadding: false,
                leading: SizedBox(
                  key: ValueKey('wide-top-leading'),
                  width: 40,
                  height: 40,
                ),
              ),
            ),
          ),
        ),
      );

      final surface = tester.getRect(
        find.byKey(const ValueKey('top-app-bar-progressive-glass')),
      );
      final title = tester.getRect(find.text('Wide title'));
      final leading = tester.getRect(
        find.byKey(const ValueKey('wide-top-leading')),
      );

      // Source SmallTopAppBar is the unconditional 24px top inset plus its
      // 52dp layout. Disabling default insets does not move content into the
      // status bar and does not retain the optional 12px left safe area.
      expect(surface.height, 76);
      expect(title.center.dy, closeTo(49, 1));
      expect(leading.left, 16);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large top app bar follows its source scroll behavior', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    final bar = MiuixTopAppBar(
      title: 'Collapsible title',
      scrollBehavior: behavior,
    );

    expect(bar.preferredSize.height, 94);
    behavior.setCollapseFraction(.5);
    expect(bar.preferredSize.height, 75);
    behavior.setCollapseFraction(1);
    expect(bar.preferredSize.height, 56);
  });

  testWidgets('progressive top bar uses gradient blur and scroll reveal', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            topBar: MiuixTopAppBar(
              title: 'Progressive',
              glass: true,
              blurStyle: MiuixTopAppBarBlurStyle.progressive,
              scrollBehavior: behavior,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('top-app-bar-glass')), findsNothing);
    expect(find.byType(ShaderMask), findsNothing);
    expect(
      find.byKey(const ValueKey('top-app-bar-gradient-filter')),
      findsNothing,
    );

    // BlurredBar.kt derives alpha from -contentOffset / 48dp rather than from
    // title collapse alone. Retain the independent raw scroll distance.
    behavior.syncMetrics(
      FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 500,
        pixels: 48,
        viewportDimension: 800,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
    );
    await tester.pump();
    expect(behavior.contentOffset, -48);
    expect(
      find.byKey(const ValueKey('top-app-bar-gradient-filter')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('top-app-bar-progressive-glass')),
        matching: find.byType(BackdropFilter),
      ),
      findsNWidgets(17),
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top app bar collapses its source bottom-content top inset', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    final bar = MiuixTopAppBar(
      title: 'Icon',
      scrollBehavior: behavior,
      bottomContentHeight: 51,
      bottomContentExpandedTopPadding: 12,
      bottomContent: const ColoredBox(
        key: ValueKey('dynamic-bottom-content'),
        color: Colors.red,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(topBar: bar, body: const SizedBox.expand()),
        ),
      ),
    );

    // IconPage.kt measures a 12dp layout inset above the 51dp search field.
    // The inset shrinks with the same fraction as the large-title column.
    final content = find.byKey(const ValueKey('dynamic-bottom-content'));
    expect(bar.preferredSize.height, 157);
    expect(tester.getTopLeft(content).dy, 106);
    expect(tester.getSize(content).height, 51);

    behavior.setCollapseFraction(.5);
    await tester.pump();
    expect(bar.preferredSize.height, 132);
    expect(tester.getTopLeft(content).dy, 81);

    behavior.setCollapseFraction(1);
    await tester.pump();
    expect(bar.preferredSize.height, 107);
    expect(tester.getTopLeft(content).dy, 56);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top app bars ignore empty subtitles and place real subtitles', (
    tester,
  ) async {
    const emptyLarge = MiuixTopAppBar(title: 'Title', subtitle: '');
    const emptySmall = MiuixSmallTopAppBar(title: 'Title', subtitle: '');
    const supportingSmall = MiuixSmallTopAppBar(
      title: 'Title',
      subtitle: 'Summary',
    );

    expect(emptyLarge.preferredSize.height, 94);
    expect(emptySmall.preferredSize.height, 52);
    expect(supportingSmall.preferredSize.height, 62);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(alignment: Alignment.topCenter, child: supportingSmall),
        ),
      ),
    );

    final titleRect = tester.getRect(find.text('Title'));
    final subtitleRect = tester.getRect(find.text('Summary'));
    expect(titleRect.center.dy, closeTo(25, 1));
    expect(subtitleRect.top, closeTo(titleRect.bottom, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('top app bar normalizes unstable public geometry', (
    tester,
  ) async {
    const bar = MiuixTopAppBar(
      title: 'Safe title',
      expandedHeight: double.nan,
      collapsedTitleAreaHeight: -10,
      collapseFraction: double.nan,
      titlePadding: double.nan,
      navigationIconPadding: -4,
      actionIconPadding: double.infinity,
      bottomContentHeight: double.nan,
      bottomContentExpandedTopPadding: double.infinity,
      bottomContent: SizedBox.shrink(),
    );
    expect(bar.preferredSize.height, 94);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(topBar: bar, body: SizedBox.expand()),
        ),
      ),
    );

    expect(find.text('Safe title'), findsWidgets);
    expect(tester.getSize(find.byType(MiuixTopAppBar)).height, 94);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar follows source surface and orientation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return Center(
                child: MiuixFloatingToolbar.source(
                  color: scheme.primary,
                  cornerRadius: 20,
                  orientation: MiuixFloatingToolbarOrientation.vertical,
                  contentPadding: const EdgeInsets.all(8),
                  spacing: 8,
                  // The current source treats every positive value as the
                  // same fixed shadow instead of scaling by this magnitude.
                  shadowElevation: 7,
                  children: const [
                    SizedBox(
                      key: ValueKey('toolbar-first'),
                      width: 40,
                      height: 40,
                    ),
                    SizedBox(
                      key: ValueKey('toolbar-second'),
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final toolbarSize = tester.getSize(find.byType(MiuixFloatingToolbar));
    final firstRect = tester.getRect(
      find.byKey(const ValueKey('toolbar-first')),
    );
    final secondRect = tester.getRect(
      find.byKey(const ValueKey('toolbar-second')),
    );
    final scheme = Theme.of(
      tester.element(find.byType(MiuixFloatingToolbar)),
    ).colorScheme;
    final fill = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-floating-toolbar-fill')),
    );
    final shadow = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-floating-toolbar-shadow')),
    );
    final decoration = shadow.decoration as ShapeDecoration;

    expect(toolbarSize, const Size(80, 120));
    expect(firstRect.center.dx, secondRect.center.dx);
    expect(secondRect.top - firstRect.bottom, 8);
    expect(fill.color, scheme.primary);
    expect(fill.borderRadius, BorderRadius.circular(20));
    expect(fill.enabled, isTrue);
    expect(decoration.shape, isA<RoundedRectangleBorder>());
    expect(
      (decoration.shape as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(20),
    );
    expect(decoration.shadows?.single.blurRadius, 10);
    expect(decoration.shadows?.single.offset, Offset.zero);
    expect(decoration.shadows?.single.color.a, closeTo(.1, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar exposes source defaults child and divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixFloatingToolbar.source(
              outSidePadding: EdgeInsets.zero,
              // FloatingToolbar.kt checks only `> 0.dp`; negative values are
              // valid and disable the projection just like zero.
              shadowElevation: -4,
              showDivider: true,
              child: SizedBox(
                key: ValueKey('toolbar-source-child'),
                width: 40,
                height: 40,
                child: Text('Action'),
              ),
            ),
          ),
        ),
      ),
    );

    final toolbar = find.byType(MiuixFloatingToolbar);
    final context = tester.element(toolbar);
    final semantic = MiuixSemanticColors.of(context);
    final fill = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-floating-toolbar-fill')),
    );
    final divider = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-floating-toolbar-divider')),
    );

    expect(MiuixFloatingToolbarDefaults.cornerRadius, 50);
    expect(
      MiuixFloatingToolbarDefaults.outSidePadding,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    expect(
      MiuixFloatingToolbarDefaults.defaultColor(context),
      semantic['surfaceContainer'],
    );
    final dividerInset =
        (.75 * tester.view.devicePixelRatio).round() /
        tester.view.devicePixelRatio;
    expect(tester.getSize(toolbar), Size.square(40 + dividerInset * 2));
    expect(
      tester.getSize(find.byKey(const ValueKey('toolbar-source-child'))),
      const Size(40, 40),
    );
    expect(fill.color, semantic['surfaceContainer']);
    // Upstream squircleBackground paints a shaped fill but explicitly leaves
    // arbitrary descendants unclipped. A ClipPath here would change that API.
    expect(
      find.descendant(of: toolbar, matching: find.byType(ClipPath)),
      findsNothing,
    );
    expect(fill.borderRadius, BorderRadius.circular(50));
    expect(fill.enabled, isTrue);
    expect(divider.color, semantic['dividerLine']);
    expect(divider.borderRadius, fill.borderRadius);
    expect(
      find.byKey(const ValueKey('miuix-floating-toolbar-shadow')),
      findsNothing,
    );
    expect(
      tester
          .getSemantics(find.text('Action'))
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar normalizes dynamic geometry', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingToolbar(
              outSidePadding: EdgeInsets.zero,
              cornerRadius: double.nan,
              spacing: -12,
              shadowElevation: double.nan,
              glass: false,
              children: <Widget>[
                SizedBox(
                  key: ValueKey('safe-toolbar-first'),
                  width: 30,
                  height: 30,
                ),
                SizedBox(
                  key: ValueKey('safe-toolbar-second'),
                  width: 30,
                  height: 30,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final first = tester.getRect(
      find.byKey(const ValueKey('safe-toolbar-first')),
    );
    final second = tester.getRect(
      find.byKey(const ValueKey('safe-toolbar-second')),
    );
    final fill = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-floating-toolbar-fill')),
    );
    expect(second.left, first.right);
    expect(fill.borderRadius, BorderRadius.circular(50));
    expect(
      find.byKey(const ValueKey('miuix-floating-toolbar-shadow')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar defaults to HyperOS glass with source opt-in', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              MiuixFloatingToolbar(
                outSidePadding: EdgeInsets.zero,
                shadowElevation: 0,
                child: SizedBox.square(dimension: 40),
              ),
              MiuixFloatingToolbar.source(
                outSidePadding: EdgeInsets.zero,
                shadowElevation: 0,
                child: SizedBox.square(dimension: 40),
              ),
            ],
          ),
        ),
      ),
    );

    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('floating-toolbar-glass')),
    );
    expect(glass.blur, 24);
    expect(glass.opacity, .60);
    expect(glass.radius, 50);
    expect(
      find.byKey(const ValueKey('miuix-floating-toolbar-fill')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('small title separates HyperOS hierarchy and source typography', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixSmallTitle('Account and security'),
          ),
        ),
      ),
    );

    final title = find.byType(MiuixSmallTitle);
    var padding = tester.widget<Padding>(
      find.descendant(of: title, matching: find.byType(Padding)),
    );
    var text = tester.widget<Text>(
      find.descendant(of: title, matching: find.byType(Text)),
    );
    expect(
      padding.padding.resolve(TextDirection.ltr),
      MiuixSmallTitleDefaults.hyperOs4InsideMargin,
    );
    expect(text.style?.fontSize, 15);
    expect(text.style?.height, 1.2);
    expect(text.style?.fontWeight, FontWeight.w600);
    expect(
      text.style?.color,
      MiuixSemanticColors.of(tester.element(title))['onSurfaceSecondary'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixSmallTitle(
            'Custom hierarchy',
            textColor: Color(0xff3355aa),
            insideMargin: EdgeInsets.all(6),
            textStyle: TextStyle(
              color: Color(0xffff0000),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
    padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(MiuixSmallTitle),
        matching: find.byType(Padding),
      ),
    );
    text = tester.widget<Text>(find.text('Custom hierarchy'));
    expect(padding.padding, const EdgeInsets.all(6));
    expect(text.style?.fontSize, 18);
    expect(text.style?.fontWeight, FontWeight.w500);
    expect(text.style?.color, const Color(0xff3355aa));
  });

  testWidgets('small title uses exact source padding typography and color', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixSmallTitle.source('颜色选择器'),
          ),
        ),
      ),
    );

    final title = find.byType(MiuixSmallTitle);
    final padding = tester.widget<Padding>(
      find.descendant(of: title, matching: find.byType(Padding)),
    );
    final text = tester.widget<Text>(
      find.descendant(of: title, matching: find.byType(Text)),
    );

    final resolvedPadding = padding.padding.resolve(TextDirection.ltr);
    expect(resolvedPadding.left * 2.625, closeTo(74, 1e-9));
    expect(resolvedPadding.top * 2.625, closeTo(21, 1e-9));
    expect(tester.getSize(title).height * 2.625, closeTo(85, 1e-9));
    expect(text.style?.fontSize, 14);
    expect(text.style?.height, 1.16);
    expect(text.style?.fontWeight, FontWeight.w700);
    expect(text.style?.letterSpacing, 0);
    expect(text.style?.color, const Color(0xFF8C93B0));
    expect(text.strutStyle?.forceStrutHeight, isTrue);
    expect(text.strutStyle?.fontSize, 14);
    expect(text.strutStyle?.height, closeTo((43 / 2.625) / 14, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'small title exposes source defaults custom color and RTL insets',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const customColor = Color(0xFFCC4488);
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.topRight,
                child: MiuixSmallTitle.source(
                  'عنوان',
                  key: ValueKey('rtl-small-title'),
                  textColor: customColor,
                  insideMargin: EdgeInsetsDirectional.fromSTEB(10, 4, 20, 6),
                ),
              ),
            ),
          ),
        ),
      );

      const widget = MiuixSmallTitle.source('alias');
      expect(widget.title, 'alias');
      expect(widget.text, 'alias');
      expect(
        MiuixSmallTitleDefaults.insideMargin,
        const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      );
      final title = find.byKey(const ValueKey('rtl-small-title'));
      final padding = tester.widget<Padding>(
        find.descendant(of: title, matching: find.byType(Padding)),
      );
      final resolved = padding.padding.resolve(TextDirection.rtl);
      expect(resolved.left * 2.625, closeTo(53, 1e-9));
      expect(resolved.right * 2.625, closeTo(26, 1e-9));
      expect(resolved.top * 2.625, closeTo(11, 1e-9));
      expect(resolved.bottom * 2.625, closeTo(16, 1e-9));
      final text = tester.widget<Text>(
        find.descendant(of: title, matching: find.byType(Text)),
      );
      expect(text.style?.color, customColor);
      expect(text.textDirection, TextDirection.rtl);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small title wraps and grows beyond its one-line source minimum',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 160,
                child: MiuixSmallTitle.source('这是一个必须自然换行并保持完整语义的较长分组标题'),
              ),
            ),
          ),
        ),
      );

      final title = find.byType(MiuixSmallTitle);
      final text = tester.widget<Text>(
        find.descendant(of: title, matching: find.byType(Text)),
      );
      expect(tester.getSize(title).width, 160);
      expect(tester.getSize(title).height * 2.625, greaterThan(85));
      expect(text.softWrap, isTrue);
      expect(text.maxLines, isNull);
      expect(
        tester.getSemantics(find.text('这是一个必须自然换行并保持完整语义的较长分组标题')),
        matchesSemantics(label: '这是一个必须自然换行并保持完整语义的较长分组标题'),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('text separates HyperOS body and source Main roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MiuixText('Standard body', key: ValueKey('standard-text')),
              MiuixText.source('Source body', key: ValueKey('source-text')),
              MiuixText.rich(
                TextSpan(text: 'Standard rich'),
                key: ValueKey('standard-rich-text'),
              ),
              MiuixText.sourceRich(
                TextSpan(text: 'Source rich'),
                key: ValueKey('source-rich-text'),
              ),
            ],
          ),
        ),
      ),
    );

    Text rendered(String key) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Text),
      ),
    );
    expect(rendered('standard-text').style?.fontSize, 16);
    expect(rendered('source-text').style?.fontSize, 17);
    expect(rendered('standard-rich-text').style?.fontSize, 16);
    expect(rendered('source-rich-text').style?.fontSize, 17);
    expect(rendered('standard-text').style?.fontWeight, FontWeight.w400);
    expect(rendered('source-text').style?.fontWeight, FontWeight.w400);
    expect(rendered('standard-text').style?.height, 1.16);
    expect(rendered('source-text').style?.height, 1.16);
  });

  testWidgets('text defaults to the source Main role and line box', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MiuixTheme(child: MiuixText.source('正文'))),
    );

    final text = tester.widget<Text>(find.text('正文'));
    expect(text.style?.fontSize, 17);
    expect(text.style?.height, 1.16);
    expect(text.style?.fontWeight, FontWeight.w400);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text follows source content-color precedence and style merge', (
    tester,
  ) async {
    const localColor = Color(0xFFAA3300);
    const styleColor = Color(0xFF0066AA);
    const explicitColor = Color(0xFF22AA55);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixSurface(
            contentColor: localColor,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixText.source('local', key: ValueKey('text-local')),
                MiuixText.source(
                  'style',
                  key: ValueKey('text-style'),
                  style: TextStyle(color: styleColor),
                ),
                MiuixText.source(
                  'explicit',
                  key: ValueKey('text-explicit'),
                  color: explicitColor,
                  style: TextStyle(color: styleColor),
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  fontFamily: 'sans-serif',
                  letterSpacing: 2,
                  textDecoration: TextDecoration.underline,
                  lineHeight: 1.4,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Text rendered(String key) => tester.widget<Text>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Text),
      ),
    );

    expect(rendered('text-local').style?.color, localColor);
    expect(rendered('text-style').style?.color, styleColor);
    final explicit = rendered('text-explicit').style!;
    expect(explicit.color, explicitColor);
    expect(explicit.fontSize, 21);
    expect(explicit.fontWeight, FontWeight.w700);
    expect(explicit.fontStyle, FontStyle.italic);
    expect(explicit.fontFamily, 'sans-serif');
    expect(explicit.letterSpacing, 2);
    expect(explicit.decoration, TextDecoration.underline);
    expect(explicit.height, 1.4);
    expect(explicit.inherit, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rich text injects source link style and retains inline content',
    (tester) async {
      final recognizer = TapGestureRecognizer();
      final styledRecognizer = TapGestureRecognizer();
      addTearDown(recognizer.dispose);
      addTearDown(styledRecognizer.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixText.sourceRich(
              TextSpan(
                text: '普通 ',
                children: [
                  TextSpan(text: '链接', recognizer: recognizer),
                  TextSpan(
                    text: '自定义链接',
                    style: const TextStyle(color: Color(0xFF8844CC)),
                    recognizer: styledRecognizer,
                  ),
                  const WidgetSpan(
                    child: SizedBox(
                      key: ValueKey('text-inline-content'),
                      width: 12,
                      height: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final rendered = tester.widget<Text>(find.byType(Text));
      final root = rendered.textSpan! as TextSpan;
      final link = root.children!.first as TextSpan;
      final primary = Theme.of(
        tester.element(find.byType(MiuixText)),
      ).colorScheme.primary;
      expect(link.style?.color, primary);
      expect(link.style?.decoration, TextDecoration.underline);
      expect(link.recognizer, same(recognizer));
      final styledLink = root.children![1] as TextSpan;
      expect(styledLink.style?.color, const Color(0xFF8844CC));
      expect(styledLink.style?.decoration, isNull);
      expect(styledLink.recognizer, same(styledRecognizer));
      expect(find.byKey(const ValueKey('text-inline-content')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rich text auto-size measures live inline placeholders', (
    tester,
  ) async {
    MiuixTextLayoutResult? layout;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 60,
              child: MiuixText.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'AAAAAA'),
                    WidgetSpan(child: SizedBox(width: 40, height: 20)),
                  ],
                ),
                maxLines: 1,
                autoSize: const MiuixTextAutoSize(
                  minFontSize: 8,
                  maxFontSize: 30,
                ),
                onTextLayout: (result) => layout = result,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.style?.fontSize, inInclusiveRange(8, 30));
    expect(rendered.style?.fontSize, lessThan(30));
    expect(layout, isNotNull);
    expect(layout!.fontSize, rendered.style?.fontSize);
    expect(layout!.lineCount, 1);
    expect(layout!.size, const Size(120, 60));
    expect(tester.takeException(), isNull);
  });

  testWidgets('text honors min lines automatic size and layout callback', (
    tester,
  ) async {
    MiuixTextLayoutResult? layout;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 110,
              height: 90,
              child: MiuixText(
                '自动字号需要适应这个有限的文本区域',
                minLines: 2,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                autoSize: const MiuixTextAutoSize(
                  minFontSize: 8,
                  maxFontSize: 30,
                  stepGranularity: 1,
                ),
                onTextLayout: (result) => layout = result,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.maxLines, 2);
    expect(rendered.softWrap, isTrue);
    expect(rendered.overflow, TextOverflow.ellipsis);
    expect(rendered.style?.fontSize, inInclusiveRange(8, 30));
    expect(rendered.style?.fontSize, lessThan(30));
    expect(layout, isNotNull);
    expect(layout!.fontSize, rendered.style?.fontSize);
    expect(layout!.plainText, '自动字号需要适应这个有限的文本区域');
    expect(layout!.size.width, 110);
    expect(layout!.size.height, 90);
    expect(layout!.lineCount, lessThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('text minLines expands an otherwise single-line paragraph', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixText('一行', minLines: 3),
          ),
        ),
      ),
    );

    final rendered = tester.widget<Text>(find.byType(Text));
    final linePainter = TextPainter(
      text: TextSpan(text: ' ', style: rendered.style),
      textDirection: TextDirection.ltr,
    )..layout();
    addTearDown(linePainter.dispose);
    expect(
      tester.getSize(find.byType(MiuixText)).height,
      closeTo(linePainter.preferredLineHeight * 3, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon inherits content tint and exposes the source image role', (
    tester,
  ) async {
    const inheritedColor = Color(0xFF2468AC);
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: IconTheme(
            data: IconThemeData(color: inheritedColor, size: 42),
            child: Align(
              alignment: Alignment.topLeft,
              child: MiuixIcon(Icons.palette, contentDescription: '调色板'),
            ),
          ),
        ),
      ),
    );

    final rendered = tester.widget<Icon>(
      find.descendant(of: find.byType(MiuixIcon), matching: find.byType(Icon)),
    );
    // Upstream supplies 24dp only when the artwork itself has no intrinsic
    // size, so the inherited IconTheme size must not replace that fallback.
    expect(rendered.size, MiuixIcon.defaultSize);
    expect(rendered.color, inheritedColor);
    expect(
      tester.getSemantics(find.byType(MiuixIcon)),
      matchesSemantics(label: '调色板', isImage: true),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon bitmap keeps intrinsic sizing and supports no tint', (
    tester,
  ) async {
    // Valid one-pixel transparent PNG. Its actual dimensions are deliberately
    // left to the image provider, matching BitmapPainter intrinsic sizing.
    final image = MemoryImage(
      Uint8List.fromList(const <int>[
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        13,
        73,
        68,
        65,
        84,
        8,
        215,
        99,
        96,
        96,
        96,
        0,
        0,
        0,
        4,
        0,
        1,
        39,
        52,
        39,
        10,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130,
      ]),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixIcon.image(image, applyTint: false),
          ),
        ),
      ),
    );
    await tester.pump();

    final rendered = tester.widget<Image>(find.byType(Image));
    expect(rendered.width, isNull);
    expect(rendered.height, isNull);
    expect(rendered.fit, BoxFit.contain);
    expect(rendered.color, isNull);
    expect(rendered.excludeFromSemantics, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon painter uses 24dp fallback and reactive tint producer', (
    tester,
  ) async {
    final tint = ValueNotifier<Color?>(const Color(0xFFAA2244));
    addTearDown(tint.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixIcon.painter(
              const _MiuixIconTestPainter(),
              tintListenable: tint,
            ),
          ),
        ),
      ),
    );

    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(MiuixIcon),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.size, const Size.square(MiuixIcon.defaultSize));
    expect(find.byType(ColorFiltered), findsOneWidget);

    // The ColorProducer overload can remove tint without reconstructing the
    // icon, and ValueListenable provides the same observable update in Flutter.
    tint.value = null;
    await tester.pump();
    expect(find.byType(ColorFiltered), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('divider exposes source defaults and vertical thickness name', (
    tester,
  ) async {
    const horizontalKey = ValueKey('source-horizontal-divider');
    const verticalKey = ValueKey('source-vertical-divider');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 100,
                  child: MiuixHorizontalDivider(key: horizontalKey),
                ),
                SizedBox(
                  height: 40,
                  child: MiuixVerticalDivider(
                    key: verticalKey,
                    thickness: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(MiuixDividerDefaults.thickness, .75);
    expect(tester.getSize(find.byKey(horizontalKey)), const Size(100, .75));
    expect(tester.getSize(find.byKey(verticalKey)), const Size(1.25, 40));
    final vertical = tester.widget<MiuixVerticalDivider>(
      find.byKey(verticalKey),
    );
    expect(vertical.thickness, 1.25);
    expect(vertical.width, 1.25);
    final context = tester.element(find.byKey(horizontalKey));
    expect(
      MiuixDividerDefaults.dividerColor(context),
      MiuixSemanticColors.of(context)['dividerLine'],
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dividers normalize insets and prefer source thickness alias', (
    tester,
  ) async {
    const verticalKey = ValueKey('normalized-vertical-divider');
    const horizontalKey = ValueKey('normalized-horizontal-divider');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 40,
                child: MiuixVerticalDivider(
                  key: verticalKey,
                  thickness: 2,
                  width: 8,
                  indent: double.nan,
                  endIndent: double.infinity,
                ),
              ),
              SizedBox(
                width: 40,
                child: MiuixHorizontalDivider(
                  key: horizontalKey,
                  indent: double.nan,
                  endIndent: double.infinity,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final vertical = tester.widget<MiuixVerticalDivider>(
      find.byKey(verticalKey),
    );
    expect(vertical.thickness, 2);
    expect(vertical.width, 2);
    expect(tester.getSize(find.byKey(verticalKey)), const Size(2, 40));
    expect(tester.getSize(find.byKey(horizontalKey)), const Size(40, .75));
    expect(tester.takeException(), isNull);
  });

  test('scrollbar defaults and colors expose the source value contract', () {
    expect(MiuixScrollBarDefaults.thumbWidth, 3.64);
    expect(MiuixScrollBarDefaults.endPadding, 3.46);
    expect(MiuixScrollBarDefaults.thumbMinLength, 36);
    expect(MiuixScrollBarDefaults.cornerRadius, isNull);
    expect(
      MiuixScrollBarDefaults.fadeDelay,
      const Duration(milliseconds: 1000),
    );
    expect(
      MiuixScrollBarDefaults.fadeDuration,
      const Duration(milliseconds: 500),
    );
    expect(MiuixScrollBarDefaults.touchTargetWidth, 48);
    expect(MiuixScrollBarDefaults.dragThumbWidth, 6);
    expect(MiuixScrollBarDefaults.thumbAlpha, .1);
    expect(MiuixScrollBarDefaults.dragThumbAlpha, .3);
    expect(
      MiuixScrollBarDefaults.dragAnimationDuration,
      const Duration(milliseconds: 150),
    );

    const colors = MiuixScrollBarColors(
      thumbColor: Color(0x80123456),
      trackColor: Color(0x40345678),
    );
    expect(
      colors,
      MiuixScrollBarDefaults.scrollBarColors(
        thumbColor: const Color(0x80123456),
        trackColor: const Color(0x40345678),
      ),
    );
    expect(
      colors.copyWith(clearTrackColor: true),
      const MiuixScrollBarColors(thumbColor: Color(0x80123456)),
    );
  });

  testWidgets('scrollbar source adapter drives a standalone overlay', (
    tester,
  ) async {
    final controller = ScrollController();
    final adapter = MiuixScrollControllerAdapter(controller);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                children: [
                  ListView.builder(
                    controller: controller,
                    itemExtent: 100,
                    itemCount: 20,
                    itemBuilder: (_, index) => Text('Adapter row $index'),
                  ),
                  Positioned.fill(
                    child: MiuixVerticalScrollBar(
                      key: const ValueKey('adapter-scrollbar'),
                      adapter: adapter,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(adapter.viewportSize, 200);
    expect(adapter.contentSize, 2000);
    await adapter.scrollTo(200);
    await tester.pump();
    expect(adapter.scrollOffset, 200);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('adapter-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollbar animates hover colors width and custom radius', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const colors = MiuixScrollBarColors(
      thumbColor: Color(0x80123456),
      trackColor: Color(0x40345678),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: MiuixVerticalScrollBar(
                key: const ValueKey('hover-scrollbar'),
                controller: controller,
                colors: colors,
                cornerRadius: 1.25,
                child: ListView.builder(
                  controller: controller,
                  itemExtent: 100,
                  itemCount: 20,
                  itemBuilder: (_, index) => Text('Hover row $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(200);
    await tester.pump();

    dynamic painter() => tester
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.byKey(const ValueKey('hover-scrollbar')),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .painter;

    expect(painter().thickness, closeTo(3.64, .001));
    expect(painter().thumbAlpha, closeTo(colors.thumbColor!.a, .001));
    expect(painter().cornerRadius, 1.25);
    expect(painter().showTrack, isTrue);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(198, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(painter().thickness, inExclusiveRange(3.64, 6));
    // An explicit source thumb retains its own alpha while only width changes.
    expect(painter().thumbAlpha, closeTo(colors.thumbColor!.a, .001));
    await tester.pump(const Duration(milliseconds: 75));
    expect(painter().thickness, closeTo(6, .001));
    await mouse.moveTo(const Offset(150, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(painter().thickness, closeTo(3.64, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollbar reduced motion settles fade and highlight endpoints', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var reduceMotion = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                height: 200,
                child: MiuixVerticalScrollBar(
                  key: const ValueKey('reduced-motion-scrollbar'),
                  controller: controller,
                  child: ListView.builder(
                    controller: controller,
                    itemExtent: 100,
                    itemCount: 20,
                    itemBuilder: (_, index) => Text('Reduced row $index'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(200);
    await tester.pump();

    dynamic painter() => tester
        .widget<CustomPaint>(
          find
              .descendant(
                of: find.byKey(const ValueKey('reduced-motion-scrollbar')),
                matching: find.byType(CustomPaint),
              )
              .first,
        )
        .painter;

    // Begin the ordinary 150ms hover expansion and prove it is in flight.
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(198, 30));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(painter().thickness, inExclusiveRange(3.64, 6));

    // An inherited accessibility change completes the active endpoint now.
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(painter().thickness, closeTo(6, .001));
    await mouse.moveTo(const Offset(150, 30));
    await tester.pump();
    expect(painter().thickness, closeTo(3.64, .001));

    // Restore ordinary timing, enter the 500ms fade, then enable the setting
    // mid-flight. The recorded hide destination must remove the overlay now.
    updateHost(() => reduceMotion = false);
    await tester.pump();
    controller.jumpTo(300);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1001));
    await tester.pump(const Duration(milliseconds: 250));
    expect(painter().opacity, inExclusiveRange(0, 1));
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reduced-motion-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical scrollbar remains on the physical right in RTL', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MiuixTheme(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 200,
                height: 200,
                child: MiuixVerticalScrollBar(
                  controller: controller,
                  child: ListView.builder(
                    controller: controller,
                    itemExtent: 100,
                    itemCount: 20,
                    itemBuilder: (_, index) => Text('RTL row $index'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(0);
    await tester.pump();

    // A left-edge drag must remain a page gesture; the source strip is right.
    await tester.dragFrom(const Offset(2, 20), const Offset(0, 30));
    await tester.pump();
    expect(controller.offset, 0);

    // The same movement over the physical-right thumb controls the content.
    await tester.dragFrom(const Offset(198, 20), const Offset(0, 30));
    await tester.pump();
    expect(controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollbar paints neither track nor thumb on a tiny track', (
    tester,
  ) async {
    final controller = ScrollController();
    const boundaryKey = ValueKey('tiny-scrollbar-boundary');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: 200,
                height: 30,
                child: MiuixVerticalScrollBar(
                  controller: controller,
                  thumbVisibility: true,
                  colors: const MiuixScrollBarColors(
                    thumbColor: Color(0xFFFF0000),
                    trackColor: Color(0xFF00FF00),
                  ),
                  child: ListView.builder(
                    controller: controller,
                    itemExtent: 100,
                    itemCount: 20,
                    itemBuilder: (_, _) =>
                        const ColoredBox(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // The 36-pixel minimum exceeds this 30-pixel track, so Compose returns
    // before drawing either the explicit green track or red thumb.
    expect(
      find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
      findsNothing,
    );
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(boundaryKey),
    );
    final sampledPixel = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);
      final pixelOffset = (15 * image.width + 194) * 4;
      final rgba = <int>[
        bytes!.getUint8(pixelOffset),
        bytes.getUint8(pixelOffset + 1),
        bytes.getUint8(pixelOffset + 2),
        bytes.getUint8(pixelOffset + 3),
      ];
      image.dispose();
      return rgba;
    });
    expect(sampledPixel, <int>[255, 255, 255, 255]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollbar normalizes invalid public geometry consistently', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 200,
            height: 200,
            child: MiuixVerticalScrollBar(
              key: const ValueKey('safe-geometry-scrollbar'),
              controller: controller,
              thumbVisibility: true,
              thumbWidth: double.nan,
              thumbMinLength: double.infinity,
              endPadding: double.negativeInfinity,
              cornerRadius: double.nan,
              child: ListView.builder(
                controller: controller,
                itemExtent: 100,
                itemCount: 20,
                itemBuilder: (_, index) => Text('Safe row $index'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(200);
    await tester.pump();

    final customPaint = tester.widget<CustomPaint>(
      find
          .descendant(
            of: find.byKey(const ValueKey('safe-geometry-scrollbar')),
            matching: find.byType(CustomPaint),
          )
          .first,
    );
    final dynamic painter = customPaint.painter;
    expect(painter.thickness, MiuixScrollBarDefaults.thumbWidth);
    expect(painter.thumbMinLength, MiuixScrollBarDefaults.thumbMinLength);
    expect(painter.endPadding, MiuixScrollBarDefaults.endPadding);
    expect(painter.cornerRadius, isNull);
    final dragTargetSize = tester.getSize(
      find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
    );
    expect(
      dragTargetSize.width,
      closeTo(
        MiuixScrollBarDefaults.thumbWidth +
            MiuixScrollBarDefaults.endPadding * 2,
        .001,
      ),
    );
    expect(dragTargetSize.height.isFinite, isTrue);
    expect(dragTargetSize.height, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reverse scrollbar inverts position and drag direction', (
    tester,
  ) async {
    final controller = ScrollController(initialScrollOffset: 400);
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: MiuixVerticalScrollBar(
                controller: controller,
                reverseLayout: true,
                child: ListView.builder(
                  controller: controller,
                  itemExtent: 100,
                  itemCount: 20,
                  itemBuilder: (_, index) => Text('Reverse row $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(400);
    await tester.pump();

    // Reverse position is near the lower end at this early content offset.
    await tester.dragFrom(const Offset(198, 140), const Offset(0, 24));
    await tester.pump();
    expect(controller.offset, lessThan(400));
    expect(tester.takeException(), isNull);
  });

  testWidgets('vertical scrollbar uses source metrics fade and thumb drag', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 200,
              height: 200,
              child: MiuixVerticalScrollBar(
                key: const ValueKey('source-scrollbar'),
                controller: controller,
                trackPadding: const EdgeInsets.only(top: 10, bottom: 20),
                child: ListView.builder(
                  controller: controller,
                  itemExtent: 100,
                  itemCount: 20,
                  itemBuilder: (_, index) => Text('Row $index'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<MiuixVerticalScrollBar>(
      find.byKey(const ValueKey('source-scrollbar')),
    );
    expect(bar.thumbWidth, 3.64);
    expect(bar.thumbMinLength, 36);
    expect(bar.endPadding, 3.46);

    controller.jumpTo(200);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('source-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    final dragTarget = find.byKey(
      const ValueKey('miuix-scrollbar-drag-target'),
    );
    expect(dragTarget, findsOneWidget);
    final dragRect = tester.getRect(dragTarget);
    expect(
      dragRect.contains(const Offset(195, 30)),
      isTrue,
      reason: 'drag point must be inside $dragRect',
    );

    // The source accepts a drag only when it starts on the 36dp minimum
    // thumb, then maps track travel back to the attached scroll controller.
    await tester.dragFrom(const Offset(195, 30), const Offset(0, 50));
    await tester.pump();
    expect(controller.offset, greaterThan(200));

    // MIUIX holds full opacity for 1000ms and fades for the following 500ms.
    await tester.pump(const Duration(milliseconds: 1001));
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('source-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrollbar ignores nested editable and viewport notifications', (
    tester,
  ) async {
    final outerController = ScrollController();
    final innerController = ScrollController();
    addTearDown(outerController.dispose);
    addTearDown(innerController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            height: 240,
            child: MiuixVerticalScrollBar(
              key: const ValueKey('nested-scrollbar'),
              controller: outerController,
              child: ListView(
                controller: outerController,
                children: [
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      controller: innerController,
                      itemExtent: 60,
                      itemCount: 10,
                      itemBuilder: (_, index) => Text('Inner $index'),
                    ),
                  ),
                  const SizedBox(height: 600),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    innerController.jumpTo(60);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('nested-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsNothing,
    );

    outerController.jumpTo(60);
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('nested-scrollbar')),
        matching: find.byType(CustomPaint),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('badge and breadcrumb defaults match the current source contract', () {
    expect(MiuixBadgeDefaults.size, 6);
    expect(MiuixBadgeDefaults.largeSize, 16);
    expect(MiuixBadgeDefaults.contentHorizontalPadding, 4);
    expect(
      MiuixBreadcrumbBarDefaults.insideMargin,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    expect(MiuixBreadcrumbBarDefaults.itemHeight, 32);
    expect(MiuixBreadcrumbBarDefaults.itemHorizontalPadding, 10);
    expect(MiuixBreadcrumbBarDefaults.itemMaxWidth, 160);

    const items = [
      MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
      MiuixBreadcrumbItem(path: 'DataBackup'),
      MiuixBreadcrumbItem(path: 'apps'),
    ];
    expect(
      miuixJoinBreadcrumbPath(items),
      '/storage/emulated/0/DataBackup/apps',
    );
    expect(
      miuixJoinBreadcrumbPath(items, separator: ' > '),
      '/storage/emulated/0 > DataBackup > apps',
    );
    expect(
      items.first.copyWith(text: '存储'),
      const MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '存储'),
    );
  });

  testWidgets('breadcrumb separates HyperOS bar material and source capsules', (
    tester,
  ) async {
    const items = <MiuixBreadcrumbItem>[
      MiuixBreadcrumbItem(path: 'root'),
      MiuixBreadcrumbItem(path: 'folder'),
    ];
    const barKey = ValueKey('miuix-breadcrumb-bar-surface');
    const rootKey = ValueKey<Object>(('miuix-breadcrumb-segment', 'root'));
    const folderKey = ValueKey<Object>(('miuix-breadcrumb-segment', 'folder'));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              inlineSurfaceBlur: 31,
              inlineSurfaceTintOpacity: .47,
              inlineSurfaceCornerRadius: 26,
            ),
          ),
          child: MiuixBreadcrumbBar(
            items: items,
            highlightIndex: 1,
            onItemClick: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    var bar = tester.widget<MiuixSurface>(find.byKey(barKey));
    expect(bar.glass, isTrue);
    expect(bar.glassBlur, 31);
    expect(bar.glassOpacity, .47);
    expect(bar.radius, 26);
    expect(bar.showGlassSpecular, isTrue);
    expect(tester.getSize(find.byKey(rootKey)).height, 36);
    expect(tester.getSize(find.byKey(folderKey)).height, 36);
    expect(
      tester.widget<MiuixSurface>(find.byKey(rootKey)).color,
      Colors.transparent,
    );
    expect(
      tester.widget<MiuixSurface>(find.byKey(folderKey)).color,
      isNot(Colors.transparent),
    );
    expect(find.byType(MiuixGlass), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixBreadcrumbBar(
            items: items,
            highlightIndex: 1,
            glass: false,
            showGlassSpecular: false,
            cornerRadius: 24,
            onItemClick: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    bar = tester.widget<MiuixSurface>(find.byKey(barKey));
    expect(bar.glass, isFalse);
    expect(bar.radius, 24);
    expect(bar.showGlassSpecular, isFalse);
    expect(find.byType(MiuixGlass), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixBreadcrumbBar.source(
            items: items,
            highlightIndex: 1,
            onItemClick: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(barKey), findsNothing);
    expect(find.byType(MiuixGlass), findsNothing);
    expect(tester.getSize(find.byKey(rootKey)).height, 32);
    expect(
      tester.widget<MiuixSurface>(find.byKey(rootKey)).color,
      isNot(Colors.transparent),
    );
  });

  testWidgets('breadcrumb selection retargets and reduced motion settles', (
    tester,
  ) async {
    final highlight = ValueNotifier<int>(0);
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(highlight.dispose);
    addTearDown(reduceMotion.dispose);
    const folderKey = ValueKey<Object>(('miuix-breadcrumb-segment', 'folder'));
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, reduced, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  collectionRowMotion: Duration(milliseconds: 600),
                ),
              ),
              child: ValueListenableBuilder<int>(
                valueListenable: highlight,
                builder: (context, selected, child) => MiuixBreadcrumbBar(
                  items: const <MiuixBreadcrumbItem>[
                    MiuixBreadcrumbItem(path: 'root'),
                    MiuixBreadcrumbItem(path: 'folder'),
                  ],
                  highlightIndex: selected,
                  onItemClick: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = tester.widget<MiuixSurface>(find.byKey(folderKey)).color;
    expect(initial, Colors.transparent);

    highlight.value = 1;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = tester
        .widget<MiuixSurface>(find.byKey(folderKey))
        .color;
    expect(intermediate, isNot(initial));
    await tester.pumpAndSettle();
    final endpoint = tester.widget<MiuixSurface>(find.byKey(folderKey)).color;
    expect(endpoint, isNot(intermediate));

    highlight.value = 0;
    reduceMotion.value = true;
    await tester.pump();
    expect(tester.widget<MiuixSurface>(find.byKey(folderKey)).color, initial);
    final motion = find.ancestor(
      of: find.byKey(folderKey),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(motion).duration,
      Duration.zero,
    );
  });

  testWidgets(
    'breadcrumb selection keeps source weight without label width hacks',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget bar(String key, String label, int highlightIndex) {
        return MiuixBreadcrumbBar.source(
          key: ValueKey(key),
          items: [MiuixBreadcrumbItem(path: label)],
          onItemClick: (_) {},
          highlightIndex: highlightIndex,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar('apps-normal', 'apps', -1),
                bar('apps-selected', 'apps', 0),
                bar('backup-normal', 'DataBackup', -1),
                bar('backup-selected', 'DataBackup', 0),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      double surfaceWidth(String key) {
        final barFinder = find.byKey(ValueKey(key));
        final surface = find.descendant(
          of: barFinder,
          matching: find.byType(MiuixSurface),
        );
        return tester.getSize(surface).width * density;
      }

      // Widget tests deliberately substitute Flutter's square test font, so
      // its absolute widths cannot stand in for Roboto measurements from the
      // 420dpi device. It can still prove that selection does not introduce a
      // text-length-dependent contraction merely to alter semantic rounding.
      expect(
        surfaceWidth('apps-normal'),
        closeTo(surfaceWidth('apps-selected'), .01),
      );
      expect(
        surfaceWidth('backup-normal'),
        closeTo(surfaceWidth('backup-selected'), .01),
      );
      final normalText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('apps-normal')),
          matching: find.text('apps'),
        ),
      );
      final selectedText = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('apps-selected')),
          matching: find.text('apps'),
        ),
      );
      expect(normalText.style?.letterSpacing, -.12);
      expect(selectedText.style?.letterSpacing, -.12);
      expect(normalText.style?.fontWeight, FontWeight.w400);
      expect(selectedText.style?.fontWeight, FontWeight.w500);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('source BadgedBox keeps anchor size and source offsets', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixBadgedBox.source(
              key: ValueKey('dot-box'),
              badge: MiuixBadge.source(key: ValueKey('dot')),
              child: SizedBox(
                key: ValueKey('dot-anchor'),
                width: 28,
                height: 28,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final boxRect = tester.getRect(find.byKey(const ValueKey('dot-box')));
    final anchorRect = tester.getRect(find.byKey(const ValueKey('dot-anchor')));
    final dotRect = tester.getRect(find.byKey(const ValueKey('dot')));
    expect(boxRect.size, const Size(28, 28));
    expect(anchorRect, boxRect);
    expect(dotRect.size, const Size(6, 6));
    expect(dotRect.top, anchorRect.top);
    expect(dotRect.left, anchorRect.right - 6);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixBadgedBox.source(
              key: ValueKey('text-box'),
              badge: MiuixBadge.source(
                key: ValueKey('text-badge'),
                content: Text('8'),
              ),
              child: SizedBox(
                key: ValueKey('text-anchor'),
                width: 28,
                height: 28,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final textAnchor = tester.getRect(
      find.byKey(const ValueKey('text-anchor')),
    );
    final textBadge = tester.getRect(find.byKey(const ValueKey('text-badge')));
    final textBadgeDecoration = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(const ValueKey('text-badge')),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(textBadge.width, greaterThanOrEqualTo(16));
    expect(textBadge.height, 16);
    expect(textBadge.left, textAnchor.right - 12);
    expect(textBadge.top, textAnchor.top - 2);
    expect(textBadgeDecoration.decoration, isA<ShapeDecoration>());
    expect(
      (textBadgeDecoration.decoration as ShapeDecoration).shape,
      isNot(isA<CircleBorder>()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('source BadgedBox retains the incoming minimum width for badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox.square(
              dimension: 28,
              child: MiuixBadgedBox.source(
                badge: MiuixBadge.source(
                  key: ValueKey('tight-source-badge'),
                  content: Text('8'),
                ),
                child: SizedBox.square(dimension: 28),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Badge.kt uses constraints.copy(minHeight = 0): the tight 28dp minimum
    // width survives, while the content badge keeps its authored 16dp height.
    expect(
      tester.getSize(find.byKey(const ValueKey('tight-source-badge'))),
      const Size(28, 16),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'breadcrumb bar scrolls highlights and keeps disabled scrolling',
    (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);
      var selected = -1;
      const items = [
        MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
        MiuixBreadcrumbItem(path: 'DataBackup'),
        MiuixBreadcrumbItem(path: 'apps'),
        MiuixBreadcrumbItem(path: 'com.tencent.mobileqq'),
        MiuixBreadcrumbItem(path: 'user_0'),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 220,
                child: MiuixBreadcrumbBar.source(
                  key: const ValueKey('breadcrumbs'),
                  items: items,
                  onItemClick: (index) => selected = index,
                  highlightIndex: 4,
                  scrollController: controller,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byKey(const ValueKey('breadcrumbs'))).height,
        48,
      );
      expect(controller.offset, greaterThan(0));
      for (var index = 1; index < items.length; index++) {
        expect(
          find.byKey(ValueKey('miuix-breadcrumb-separator-$index')),
          findsOneWidget,
        );
      }
      final userSurface = find.ancestor(
        of: find.text('user_0'),
        matching: find.byType(MiuixSurface),
      );
      final longSurface = find.ancestor(
        of: find.text('com.tencent.mobileqq'),
        matching: find.byType(MiuixSurface),
      );
      expect(tester.getSize(userSurface).height, 32);
      expect(tester.getSize(userSurface).width, lessThan(160));
      expect(tester.getSize(longSurface).width, 160);
      final userRect = tester.getRect(userSurface);
      expect(tester.getSemantics(userSurface).rect.height, 48);
      await tester.tapAt(Offset(userRect.center.dx, userRect.top - 4));
      await tester.pump();
      expect(selected, 4);

      selected = -1;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: SizedBox(
              width: 220,
              child: MiuixBreadcrumbBar.source(
                items: items,
                onItemClick: (index) => selected = index,
                enabled: false,
                highlightIndex: -1,
                scrollController: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      controller.jumpTo(0);
      await tester.pump();
      final disabledSurface = find.ancestor(
        of: find.text('内部存储'),
        matching: find.byType(MiuixSurface),
      );
      await tester.tapAt(tester.getRect(disabledSurface).center);
      await tester.pump();
      expect(selected, -1);
      expect(
        tester
            .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
            .scrollDirection,
        Axis.horizontal,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('breadcrumb highlight uses the source spring and pixel target', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var highlight = 4;
    late void Function(int value) select;
    const items = [
      MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
      MiuixBreadcrumbItem(path: 'DataBackup'),
      MiuixBreadcrumbItem(path: 'apps'),
      MiuixBreadcrumbItem(path: 'com.tencent.mobileqq'),
      MiuixBreadcrumbItem(path: 'user_0'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              select = (value) => setState(() => highlight = value);
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 220,
                  child: MiuixBreadcrumbBar.source(
                    items: items,
                    onItemClick: select,
                    highlightIndex: highlight,
                    scrollController: controller,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // ScrollState works in physical pixels and the source calls toInt() after
    // clamping. Fractional-density Flutter must therefore stop on the same
    // integer-pixel maximum instead of retaining a subpixel scroll transform.
    final initial = controller.offset;
    final sourceInitial =
        (controller.position.maxScrollExtent * density).truncate() / density;
    expect(initial, closeTo(sourceInitial, 1e-7));
    expect(initial, greaterThan(0));

    select(0);
    await tester.pump();
    // The post-frame source effect starts its ticker after this rebuild. Give
    // that ticker its zero-time first frame before sampling 50 ms of motion.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final expectedSpring = SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1500, ratio: 1),
      initial,
      0,
      0,
    );
    expect(controller.offset, closeTo(expectedSpring.x(.05), .02));
    // A 300ms ease-in-out tween would still retain nearly all the original
    // offset here. This bound keeps that previous non-source motion out.
    expect(controller.offset, lessThan(initial * .5));
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(0, 1e-7));

    // User scrolling has the higher mutation priority in Compose and cancels
    // animateScrollTo. The canceled animation must not later snap back to its
    // stale highlighted target.
    select(4);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.offset, greaterThan(0));
    controller.jumpTo(100);
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.offset, closeTo(100, 1e-7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('breadcrumb centering keeps the source root-space inset', (
    tester,
  ) async {
    const viewportWidth = 220.0;
    const leftInset = 12.0;
    final controller = ScrollController();
    addTearDown(controller.dispose);
    const items = [
      MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
      MiuixBreadcrumbItem(path: 'DataBackup'),
      MiuixBreadcrumbItem(path: 'apps'),
      MiuixBreadcrumbItem(path: 'com.tencent.mobileqq'),
      MiuixBreadcrumbItem(path: 'user_0'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: leftInset),
              child: SizedBox(
                width: viewportWidth,
                child: MiuixBreadcrumbBar.source(
                  items: items,
                  onItemClick: (_) {},
                  highlightIndex: 2,
                  scrollController: controller,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appsSurface = find.ancestor(
      of: find.text('apps'),
      matching: find.byType(MiuixSurface),
    );
    // The source centers against the viewport's local width while feeding it
    // a root-space item x. Its selected center is therefore viewportWidth/2,
    // not leftInset + viewportWidth/2.
    const viewportCenter = leftInset + viewportWidth / 2;
    expect(
      tester.getRect(appsSurface).center.dx,
      // Source truncates its physical scroll target to an integer, so the
      // final center can retain less than one logical pixel of remainder.
      closeTo(viewportCenter - leftInset, 1),
    );
    expect(controller.offset, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('breadcrumb reduced motion stops and jumps to highlight', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    var highlight = 4;
    var reduceMotion = false;
    late void Function(int value) select;
    late void Function(bool value) setReducedMotion;
    const items = [
      MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
      MiuixBreadcrumbItem(path: 'DataBackup'),
      MiuixBreadcrumbItem(path: 'apps'),
      MiuixBreadcrumbItem(path: 'com.tencent.mobileqq'),
      MiuixBreadcrumbItem(path: 'user_0'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            select = (value) => setState(() => highlight = value);
            setReducedMotion = (value) => setState(() => reduceMotion = value);
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: MiuixTheme(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 220,
                    child: MiuixBreadcrumbBar.source(
                      items: items,
                      onItemClick: select,
                      highlightIndex: highlight,
                      scrollController: controller,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = controller.offset;
    expect(initial, greaterThan(0));

    select(0);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(controller.offset, inExclusiveRange(0, initial));

    setReducedMotion(true);
    await tester.pump();
    await tester.pump();
    expect(controller.offset, closeTo(0, 1e-7));
    await tester.pump(const Duration(milliseconds: 500));
    expect(controller.offset, closeTo(0, 1e-7));

    // Direct scrolling remains available while autonomous centering is off.
    controller.jumpTo(80);
    await tester.pump();
    expect(controller.offset, closeTo(80, 1e-7));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown trigger opacity snaps with reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Column(
              children: [
                MiuixDropdownMenuButton<String>(
                  entries: [],
                  enabled: false,
                  onSelected: _ignoreString,
                  child: Text('Reduced dropdown'),
                ),
                MiuixIconCascadingDropdownMenu<String>(
                  icon: Icon(Icons.more_horiz),
                  items: [
                    MiuixCascadingMenuItem<String>(
                      label: 'Disabled parent',
                      children: [
                        MiuixDropdownEntry<String>(
                          value: 'disabled',
                          label: 'Disabled child',
                        ),
                      ],
                    ),
                  ],
                  enabled: false,
                  onSelected: _ignoreString,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final opacityWidgets = tester.widgetList<AnimatedOpacity>(
      find.byType(AnimatedOpacity),
    );
    expect(opacityWidgets, hasLength(2));
    expect(
      opacityWidgets.every((widget) => widget.duration == Duration.zero),
      isTrue,
    );
    expect(opacityWidgets.every((widget) => widget.opacity == .38), isTrue);
  });

  testWidgets('breadcrumb forwards source interaction and indication', (
    tester,
  ) async {
    const customColor = Color(0xFF7A3211);
    final interactionSource = MiuixInteractionSource();
    addTearDown(interactionSource.dispose);
    const items = [
      MiuixBreadcrumbItem(path: 'root'),
      MiuixBreadcrumbItem(path: 'folder'),
    ];

    Widget build({MiuixIndication? indication = const MiuixIndication()}) {
      return MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixBreadcrumbBar.source(
              key: const ValueKey('source-breadcrumb'),
              items: items,
              onItemClick: (_) {},
              interactionSource: interactionSource,
              indication: indication,
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(
      build(indication: const MiuixIndication(color: customColor)),
    );
    await tester.pumpAndSettle();
    final root = find.text('root');
    final gesture = await tester.startGesture(tester.getCenter(root));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(interactionSource.pressed, isTrue);
    final indications = find.descendant(
      of: find.byKey(const ValueKey('source-breadcrumb')),
      matching: find.byKey(const ValueKey('miuix-press-indication')),
    );
    expect(indications, findsNWidgets(2));
    final active = tester
        .widgetList<FadeTransition>(indications)
        .where((fade) => fade.opacity.value > 0)
        .single;
    final activeBox = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byWidget(active),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(activeBox.color, customColor);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(interactionSource.pressed, isFalse);

    await tester.pumpWidget(build(indication: null));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('source-breadcrumb')),
        matching: find.byKey(const ValueKey('miuix-press-indication')),
      ),
      findsNothing,
    );
    await tester.tap(find.text('root'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('tooltip defaults and placement match the current source contract', () {
    expect(MiuixTooltipDefaults.spacingBetweenTooltipAndAnchor, 8);
    expect(MiuixTooltipDefaults.caretSize, const Size(16, 8));
    expect(MiuixTooltipDefaults.plainTooltipMaxWidth, 200);
    expect(MiuixTooltipDefaults.plainTooltipCornerRadius, 12);
    expect(
      MiuixTooltipDefaults.plainTooltipInsideMargin,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
    expect(MiuixTooltipDefaults.richTooltipMaxWidth, 320);
    expect(MiuixTooltipDefaults.richTooltipCornerRadius, 16);
    expect(
      MiuixTooltipDefaults.richTooltipInsideMargin,
      const EdgeInsets.all(16),
    );
    expect(MiuixTooltipDefaults.richTooltipActionCornerRadius, 8);
    expect(
      MiuixTooltipDefaults.richTooltipActionInsideMargin,
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );

    const anchor = Rect.fromLTWH(120, 80, 20, 20);
    const window = Size(300, 200);
    const tooltip = Size(100, 40);
    Offset position(
      MiuixTooltipAnchorPosition placement, {
      TextDirection direction = TextDirection.ltr,
    }) {
      return debugMiuixTooltipPosition(
        anchor: anchor,
        windowSize: window,
        tooltipSize: tooltip,
        positioning: placement,
        textDirection: direction,
      );
    }

    expect(position(MiuixTooltipAnchorPosition.below), const Offset(80, 108));
    expect(position(MiuixTooltipAnchorPosition.above), const Offset(80, 32));
    expect(position(MiuixTooltipAnchorPosition.left), const Offset(12, 70));
    expect(position(MiuixTooltipAnchorPosition.right), const Offset(148, 70));
    expect(position(MiuixTooltipAnchorPosition.start), const Offset(12, 70));
    expect(
      position(MiuixTooltipAnchorPosition.start, direction: TextDirection.rtl),
      const Offset(148, 70),
    );
    expect(position(MiuixTooltipAnchorPosition.end), const Offset(148, 70));
    expect(
      position(MiuixTooltipAnchorPosition.end, direction: TextDirection.rtl),
      const Offset(12, 70),
    );

    expect(
      debugMiuixTooltipPosition(
        anchor: const Rect.fromLTWH(120, 170, 20, 20),
        windowSize: window,
        tooltipSize: tooltip,
        positioning: MiuixTooltipAnchorPosition.below,
        textDirection: TextDirection.ltr,
      ),
      const Offset(80, 122),
    );
    expect(
      debugMiuixTooltipPosition(
        anchor: const Rect.fromLTWH(0, 2, 20, 20),
        windowSize: window,
        tooltipSize: tooltip,
        positioning: MiuixTooltipAnchorPosition.above,
        textDirection: TextDirection.ltr,
      ),
      const Offset(0, 30),
    );
  });

  testWidgets('tooltip state is global and programmatic shows time out', (
    tester,
  ) async {
    final first = MiuixTooltipState(isPersistent: true);
    final second = MiuixTooltipState();
    addTearDown(first.dispose);
    addTearDown(second.dispose);

    unawaited(first.show());
    expect(first.targetVisible, isTrue);
    unawaited(second.show());
    expect(first.targetVisible, isFalse);
    expect(second.targetVisible, isTrue);

    await tester.pump(const Duration(milliseconds: 1499));
    expect(second.targetVisible, isTrue);
    await tester.pump(const Duration(milliseconds: 1));
    expect(second.targetVisible, isFalse);
  });

  testWidgets('rich tooltip keeps input shows open and action dismisses it', (
    tester,
  ) async {
    final state = MiuixTooltipState(isPersistent: true);
    addTearDown(state.dispose);
    var actionCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixRichTooltipBox.source(
                state: state,
                title: '标题',
                text: '详细说明',
                actionText: '知道了',
                onActionClick: () => actionCount += 1,
                child: const Text('锚点'),
              ),
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('锚点')),
    );
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('标题'), findsOneWidget);
    expect(find.text('详细说明'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
    expect(find.byType(MiuixGlass), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-tooltip-surface'))).width,
      lessThanOrEqualTo(320),
    );

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('详细说明'), findsOneWidget);

    await tester.tap(find.text('知道了'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(actionCount, 1);
    expect(find.text('详细说明'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rich tooltip default shares the HyperOS popup material', (
    tester,
  ) async {
    final state = MiuixTooltipState(initialIsVisible: true, isPersistent: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixRichTooltip(
                state: state,
                message: '详情',
                content: const Text('说明内容'),
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-tooltip-fill')),
    );
    expect(find.byType(MiuixGlass), findsOneWidget);
    expect(glass.blur, 24);
    expect(glass.opacity, .66);
    expect(glass.optics, same(MiuixGlassOptics.transient));
    expect(glass.radius, 20);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip follows its anchor through programmatic scrolling', (
    tester,
  ) async {
    final state = MiuixTooltipState(initialIsVisible: true, isPersistent: true);
    final scroll = ScrollController();
    addTearDown(state.dispose);
    addTearDown(scroll.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: ListView(
              controller: scroll,
              children: [
                const SizedBox(height: 180),
                Center(
                  child: MiuixTooltip(
                    state: state,
                    message: '跟随提示',
                    positioning: MiuixTooltipAnchorPosition.below,
                    child: const SizedBox(
                      key: ValueKey('moving-tooltip-anchor'),
                      width: 80,
                      height: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 1000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final surface = find.byKey(const ValueKey('miuix-tooltip-surface'));
    final before = tester.getRect(surface);
    scroll.jumpTo(60);
    // First frame moves the composited anchor and samples its new global rect;
    // the second rebuilds the root OverlayEntry from that rect.
    await tester.pump();
    await tester.pump();
    final after = tester.getRect(surface);
    expect(after.top, closeTo(before.top - 60, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip skips enter and exit frames with reduced motion', (
    tester,
  ) async {
    final state = MiuixTooltipState(initialIsVisible: true, isPersistent: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixTooltip(
                state: state,
                message: '即时提示',
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final surface = find.byKey(const ValueKey('miuix-tooltip-surface'));
    expect(surface, findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: surface, matching: find.byType(Opacity)).first,
    );
    final scale = tester.widget<Transform>(
      find.ancestor(of: surface, matching: find.byType(Transform)).first,
    );
    expect(opacity.opacity, 1);
    expect(scale.transform.entry(0, 0), closeTo(1, .0001));

    state.dismiss();
    await tester.pump();
    await tester.pump();
    expect(surface, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip text placeables retain source 420dpi line boxes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final plainState = MiuixTooltipState(
      initialIsVisible: true,
      isPersistent: true,
    );
    addTearDown(plainState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixTooltipBox(
                state: plainState,
                message: '编辑',
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final plainSurface = tester.getSize(
      find.byKey(const ValueKey('miuix-tooltip-surface')),
    );
    // PlainTooltip is 21px top padding + one 43px body2 line + 21px bottom.
    expect(plainSurface.height * 2.625, closeTo(85, .01));

    final richState = MiuixTooltipState(
      initialIsVisible: true,
      isPersistent: true,
    );
    addTearDown(richState.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixRichTooltipBox.source(
                state: richState,
                title: '丰富工具提示',
                text: '第一行\n第二行\n第三行',
                actionText: '知道了',
                onActionClick: () {},
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final richAction = tester.getSize(
      find.descendant(
        of: find.byKey(const ValueKey('miuix-tooltip-surface')),
        matching: find.byKey(const ValueKey('miuix-button-surface')),
      ),
    );
    expect(richAction.height * 2.625, closeTo(84, .01));
    final richSurface = tester.getSize(
      find.byKey(const ValueKey('miuix-tooltip-surface')),
    );
    // 84px padding + 43px title + 42px gaps + 129px body + 84px action.
    expect(richSurface.height * 2.625, closeTo(382, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tooltip defaults to one HyperOS glass surface and G2 shadow', (
    tester,
  ) async {
    final state = MiuixTooltipState(initialIsVisible: true, isPersistent: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(enableSquircle: true),
          child: Scaffold(
            body: Center(
              child: MiuixTooltipBox(
                state: state,
                message: '编辑',
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-tooltip-fill')),
    );
    expect(find.byType(MiuixGlass), findsOneWidget);
    expect(glass.blur, 24);
    expect(glass.opacity, .66);
    expect(glass.radius, 20);
    expect(glass.showSpecular, isTrue);

    final shadow = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-tooltip-shadow')),
    );
    final decoration = shadow.decoration as ShapeDecoration;
    expect(decoration.shape, isA<MiuixSquircleBorder>());
    final shape = decoration.shape as MiuixSquircleBorder;
    expect(shape.borderRadius, BorderRadius.circular(20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('source tooltip keeps rounded shadow outside squircle fill', (
    tester,
  ) async {
    final state = MiuixTooltipState(initialIsVisible: true, isPersistent: true);
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(enableSquircle: true),
          child: Scaffold(
            body: Center(
              child: MiuixTooltipBox.source(
                state: state,
                message: '编辑',
                child: const SizedBox.square(dimension: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final shadow = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-tooltip-shadow')),
    );
    final decoration = shadow.decoration as ShapeDecoration;
    // Tooltip.kt deliberately shadows RoundedCornerShape even though the
    // surface nested inside it is painted by squircleBackground.
    expect(decoration.shape, isA<RoundedRectangleBorder>());
    final rounded = decoration.shape as RoundedRectangleBorder;
    expect(rounded.borderRadius, BorderRadius.circular(12));
    expect(decoration.shadows, hasLength(1));
    expect(decoration.shadows!.single.blurRadius, 10);
    expect(decoration.shadows!.single.spreadRadius, 0);
    expect(decoration.shadows!.single.offset, Offset.zero);
    expect(
      decoration.shadows!.single.color,
      Colors.black.withValues(alpha: .1),
    );

    final fill = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tooltip-fill')),
    );
    expect(find.byType(MiuixGlass), findsNothing);
    expect(fill.enabled, isTrue);
    expect(fill.borderRadius, BorderRadius.circular(12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('button normalizes Release geometry and content conflicts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: <Widget>[
              const MiuixButton(
                onPressed: null,
                cornerRadius: double.nan,
                minWidth: double.negativeInfinity,
                minHeight: -20,
              ),
              MiuixButton(
                label: 'ignored label',
                icon: const Icon(Icons.add),
                onPressed: () {},
                child: const Text('arbitrary child wins'),
              ),
            ],
          ),
        ),
      ),
    );

    // Release mode retains deterministic content precedence instead of
    // depending on constructor assertions which the compiler removes.
    expect(find.text('arbitrary child wins'), findsOneWidget);
    expect(find.text('ignored label'), findsNothing);
    expect(find.byType(MiuixButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon normalizes invalid extents and alias precedence', (
    tester,
  ) async {
    const tint = Color(0xFF2468AC);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixIcon(
            Icons.palette,
            size: double.nan,
            color: Colors.red,
            tint: tint,
            semanticLabel: 'compatibility label',
            contentDescription: 'source description',
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.size, MiuixIcon.defaultSize);
    expect(icon.color, tint);
    expect(
      tester.getSemantics(find.byType(MiuixIcon)),
      matchesSemantics(label: 'source description', isImage: true),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('text normalizes invalid line and automatic-size policy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 120,
            height: 48,
            child: MiuixText(
              'runtime text policy',
              fontSize: double.nan,
              lineHeight: -1,
              minLines: 0,
              maxLines: -3,
              autoSize: MiuixTextAutoSize(
                minFontSize: double.nan,
                maxFontSize: -20,
                stepGranularity: 0,
              ),
            ),
          ),
        ),
      ),
    );

    final rendered = tester.widget<Text>(find.byType(Text));
    expect(rendered.maxLines, 1);
    expect(rendered.style?.fontSize?.isFinite, isTrue);
    expect(rendered.style?.fontSize, greaterThan(0));
    expect(tester.getSize(find.byType(MiuixText)).isFinite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('icon button normalizes Release geometry and slot conflicts', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            children: <Widget>[
              MiuixIconButton(
                onPressed: () {},
                cornerRadius: double.nan,
                minWidth: double.negativeInfinity,
                minHeight: -8,
              ),
              MiuixIconButton(
                onPressed: () {},
                icon: const Icon(Icons.close),
                child: const SizedBox.square(
                  key: ValueKey('custom-icon-button-slot'),
                  dimension: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('custom-icon-button-slot')), findsOne);
    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byType(MiuixIconButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating action normalizes Release geometry and empty slots', (
    tester,
  ) async {
    const emptyKey = ValueKey('safe-empty-fab');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Wrap(
            children: <Widget>[
              const MiuixFloatingActionButton(
                key: emptyKey,
                onPressed: null,
                minWidth: double.nan,
                minHeight: double.negativeInfinity,
                shadowElevation: double.nan,
              ),
              MiuixFloatingActionButton(label: 'Label only', onPressed: () {}),
              MiuixFloatingActionButton(
                label: 'Ignored label',
                icon: const Icon(Icons.close),
                onPressed: () {},
                child: const SizedBox.square(
                  key: ValueKey('custom-fab-slot'),
                  dimension: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(emptyKey)), const Size.square(60));
    final emptySurface = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(emptyKey),
        matching: find.byKey(
          const ValueKey('miuix-floating-action-button-surface'),
        ),
      ),
    );
    expect((emptySurface.decoration as ShapeDecoration).shadows, isEmpty);
    expect(find.text('Label only'), findsOneWidget);
    expect(find.text('Ignored label'), findsNothing);
    expect(find.byKey(const ValueKey('custom-fab-slot')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('breadcrumb normalizes a non-finite item width', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixBreadcrumbBar(
            itemMaxWidth: double.nan,
            items: const <MiuixBreadcrumbItem>[
              MiuixBreadcrumbItem(
                path: '/a/very/long/runtime/breadcrumb/destination',
              ),
            ],
            onItemClick: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    final segment = find.byKey(
      const ValueKey<Object>((
        'miuix-breadcrumb-segment',
        '/a/very/long/runtime/breadcrumb/destination',
      )),
    );
    expect(
      tester.getSize(segment).width,
      lessThanOrEqualTo(MiuixBreadcrumbBarDefaults.hyperOs4ItemMaxWidth),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field and card resolve compatibility conflicts', (
    tester,
  ) async {
    const sourceLeading = ValueKey('source-leading-slot');
    const compatibilityLeading = ValueKey('compatibility-leading-slot');
    const sourceTrailing = ValueKey('source-trailing-slot');
    const compatibilityTrailing = ValueKey('compatibility-trailing-slot');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MiuixTextField(
                leadingIcon: SizedBox(key: sourceLeading),
                prefixIcon: SizedBox(key: compatibilityLeading),
                trailingIcon: SizedBox(key: sourceTrailing),
                suffixIcon: SizedBox(key: compatibilityTrailing),
                prefixIconSpacing: double.nan,
              ),
              MiuixCard(
                padding: EdgeInsets.all(40),
                insideMargin: EdgeInsets.all(6),
                cornerRadius: -20,
                child: SizedBox.square(dimension: 20),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(sourceLeading), findsOneWidget);
    expect(find.byKey(sourceTrailing), findsOneWidget);
    expect(find.byKey(compatibilityLeading), findsNothing);
    expect(find.byKey(compatibilityTrailing), findsNothing);
    final cardSurface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixCard),
        matching: find.byType(MiuixSurface),
      ),
    );
    expect(cardSurface.padding, const EdgeInsets.all(6));
    expect(cardSurface.radius, 0);
    expect(tester.takeException(), isNull);
  });
}

void _ignoreSliderPreferenceDouble(double _) {}

void _ignoreSliderPreferenceRange(RangeValues _) {}
