import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:libmonet/material_color_utilities.dart' as monet;
import 'package:url_launcher/url_launcher.dart';

part 'reference_home_basic_sections.dart';
part 'reference_home_input_sections.dart';
part 'reference_home_feedback_sections.dart';
part 'reference_home_blur_section.dart';
part 'reference_extension_components_page.dart';
part 'reference_extension_calendar_section.dart';
part 'reference_extension_collection_section.dart';
part 'reference_extension_layout_section.dart';
part 'reference_effect_background_controller.dart';
part 'reference_blur_tokens.dart';
part 'reference_home_page.dart';
part 'reference_settings_page.dart';
part 'reference_settings_options.dart';
part 'reference_settings_ui_card.dart';
part 'reference_fps_monitor.dart';
part 'reference_floating_toolbar_content.dart';
part 'reference_bottom_navigation_transition.dart';
part 'reference_page_scaffold.dart';
part 'reference_adaptive_navigation_host.dart';
part 'reference_navigation_transition.dart';
part 'reference_navigation_test_page.dart';
part 'reference_nested_navigation_page.dart';
part 'reference_overscroll_load_more_page.dart';
part 'reference_pull_to_refresh_page.dart';
part 'reference_multi_scaffold_page.dart';
part 'reference_icon_page.dart';
part 'reference_color_page.dart';
part 'reference_dropdown_page.dart';
part 'reference_text_style_page.dart';
part 'reference_shape_section.dart';
part 'reference_about_page.dart';
part 'reference_license_page.dart';
part 'reference_android_dynamic_colors.dart';
part 'example_app_settings.dart';

/// Version label displayed by the current upstream v1.0.9 example build.
///
/// The source generates this value from its Git commit count. The localized
/// reconstruction keeps the captured upstream value so Settings and About do
/// not expose Flutter's unrelated, monotonic APK installation version code.
const _referenceSourceVersionLabel = 'v1.0.9 (228)';

/// HyperOS tab clicks briefly fade out before replacing the page directly.
@visibleForTesting
Duration debugReferenceTabFadeOutDuration() => const Duration(milliseconds: 80);

/// The target page returns more gently than the outgoing page disappears.
@visibleForTesting
Duration debugReferenceTabFadeInDuration() => const Duration(milliseconds: 180);

/// Easing shared by the root tab fade channels.
@visibleForTesting
Curve debugReferenceTabFadeCurve() => Curves.easeOutCubic;

/// Compose's default spring used by `PagerState.animateScrollToPage`.
///
/// The source TabRow demo does not pass an animation spec, so AndroidX uses
/// its no-bounce, medium-stiffness default: damping ratio 1 and stiffness 1500.
@visibleForTesting
SpringDescription debugReferenceTabPagerSpring() =>
    SpringDescription.withDampingRatio(mass: 1, stiffness: 1500, ratio: 1);

/// Compose's medium-low enter/exit spring used by `AnimatedVisibility`.
@visibleForTesting
SpringDescription debugReferenceVisibilitySpring() =>
    SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 1);

/// Mirrors `shouldShowSplitPane()` from the original adaptive utilities.
///
/// A portrait tablet switches at 840dp. A smaller window switches from 600dp
/// only when its height-to-width ratio is strictly below 1.2, which preserves
/// compact bottom navigation on narrow portrait and square layouts.
@visibleForTesting
bool debugReferenceShouldShowSplitPane(Size containerSize) {
  final width = containerSize.width;
  if (!width.isFinite || width <= 0) {
    return width == double.infinity;
  }
  final ratio = containerSize.height / width;
  return width >= 840 || (width >= 600 && ratio < 1.2);
}

/// Resolves the root Scaffold bottom padding reported to compact pages.
///
/// MIUIX lays the pager out at full window height, paints the bottom bar over
/// it, and reports the measured bar height as content padding. Hidden bars
/// report only the system inset. Floating variants include their platform gap.
@visibleForTesting
double debugReferenceRootBottomContentInset({
  required bool navigationVisible,
  required bool floating,
  required bool iosLike,
  required TargetPlatform platform,
  required double systemBottom,
  MiuixFloatingNavigationBarDisplayMode floatingDisplayMode =
      MiuixFloatingNavigationBarDisplayMode.iconOnly,
}) {
  final safeBottom = systemBottom.isFinite
      ? math.max(0.0, systemBottom).toDouble()
      : 0.0;
  if (!navigationVisible) return safeBottom;
  // The source measures HorizontalDivider (0.75dp) before its 64dp item row.
  if (!floating) return 64.75 + safeBottom;
  if (iosLike) {
    // The default HyperOS 4 liquid panel is 56dp tall. The explicit
    // `MiuixIosLiquidGlassNavigationBar.source` constructor retains the
    // historical 64dp Compose sample, but the application shell does not use
    // that compatibility geometry. Keeping 64 here left an invisible 8dp gap
    // between scroll content and the actually painted navigation panel.
    return 56 + (safeBottom == 0 ? 36 : 8 + safeBottom);
  }
  final platformGap = switch (platform) {
    TargetPlatform.android => safeBottom == 0 ? 36.0 : 26.0 + safeBottom,
    TargetPlatform.iOS => 36.0,
    _ => 36.0,
  };
  // The source Row is never shorter than 52dp, even though its icon-only item
  // is 48dp tall. Extension display modes retain that same capsule minimum.
  return 52 + platformGap;
}

/// Runs the localized reconstruction of the original MIUIX example.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // MIUIX draws its surfaces into both Android system-bar regions. Controls
  // keep their own SafeArea padding while glass and page backgrounds remain
  // continuous behind the status bar and gesture-navigation indicator.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // Current MIUIX static surfaces use a baked SDF on API 33+ and Windows.
  // Preload it so Card/Button/Dialog corners are source-exact on frame one.
  await preloadMiuixSquircleShader();
  runApp(const MiuixExampleApp());
}

/// Five-page application shell matching the original sample navigation.
class MiuixExampleApp extends StatefulWidget {
  /// Creates the example application.
  const MiuixExampleApp({super.key});

  @override
  State<MiuixExampleApp> createState() => _MiuixExampleAppState();
}

class _MiuixExampleAppState extends State<MiuixExampleApp>
    with SingleTickerProviderStateMixin {
  static const _dynamicColorChannel = MethodChannel(
    'miuix_flutter/platform_dynamic_color',
  );

  int _selectedIndex = 0;
  int _tabSwitchEpoch = 0;
  MiuixColorMode _themeMode = MiuixColorMode.system;
  _MiuixExampleSettings _settings = const _MiuixExampleSettings();
  ColorScheme? _platformDynamicLight;
  ColorScheme? _platformDynamicDark;
  double _platformScreenCornerRadius = 0;
  late final PageController _pageController;
  late final AnimationController _tabPageOpacity;
  late final MiuixSnackbarHostState _snackbarHostState;
  late final MiuixNavigationRailState _navigationRailState;
  final GlobalKey<NavigatorState> _widePaneNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'reference-wide-pane-navigator');
  bool? _lastAutomaticRailExpansion;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabPageOpacity = AnimationController(vsync: this, value: 1);
    _snackbarHostState = MiuixSnackbarHostState();
    _navigationRailState = MiuixNavigationRailState();
    unawaited(_loadPlatformDynamicColors());
    unawaited(_loadPlatformScreenCornerRadius());
  }

  /// Reads the same Android display-corner radius used by NavDisplayEffects.
  ///
  /// Desktop and web intentionally keep zero. The AOSP transition applies the
  /// source's separate 32dp fallback when this platform value is unavailable;
  /// the standard MIUIX slide keeps the flat desktop edge unchanged.
  Future<void> _loadPlatformScreenCornerRadius() async {
    final radius = await loadMiuixNavSystemCornerRadius();
    if (!mounted) return;
    setState(() => _platformScreenCornerRadius = radius);
  }

  /// Loads the same operating-system palette used by platformDynamicColors.
  ///
  /// Android supplies the same secure theme seed, palette style, and color
  /// specification consulted by DynamicColors.android.kt. Other platforms
  /// retain the source library's standard Monet fallback in the Color page.
  Future<void> _loadPlatformDynamicColors() async {
    try {
      final data = await _dynamicColorChannel.invokeMapMethod<String, dynamic>(
        'getSystemPalette',
      );
      final androidLight = debugReferenceAndroidSystemScheme(data, dark: false);
      final androidDark = debugReferenceAndroidSystemScheme(data, dark: true);
      if (androidLight != null && androidDark != null) {
        if (!mounted) return;
        setState(() {
          _platformDynamicLight = androidLight;
          _platformDynamicDark = androidDark;
        });
        return;
      }
      final seedValue = data?['seed'];
      if (seedValue is! int) {
        return;
      }
      final paletteStyle = switch (data?['style']) {
        'VIBRANT' => MiuixThemePaletteStyle.vibrant,
        'EXPRESSIVE' => MiuixThemePaletteStyle.expressive,
        'SPRITZ' || 'NEUTRAL' => MiuixThemePaletteStyle.neutral,
        'RAINBOW' => MiuixThemePaletteStyle.rainbow,
        'FRUIT_SALAD' => MiuixThemePaletteStyle.fruitSalad,
        'MONOCHROMATIC' || 'MONOCHROME' => MiuixThemePaletteStyle.monochrome,
        'FIDELITY' => MiuixThemePaletteStyle.fidelity,
        'CONTENT' => MiuixThemePaletteStyle.content,
        _ => MiuixThemePaletteStyle.tonalSpot,
      };
      final colorSpec = data?['spec'] == 2025
          ? MiuixThemeColorSpec.spec2025
          : MiuixThemeColorSpec.spec2021;
      final platformTheme = MiuixThemeData.defaults(
        mode: MiuixColorMode.monetSystem,
        seedColor: Color(seedValue),
        paletteStyle: paletteStyle,
        colorSpec: colorSpec,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _platformDynamicLight = platformTheme.lightScheme;
        _platformDynamicDark = platformTheme.darkScheme;
      });
    } on PlatformException {
      // Android failures use the deterministic source fallback below.
    } on MissingPluginException {
      // Windows and test bindings intentionally have no Android channel.
    }
  }

  @override
  void dispose() {
    _tabSwitchEpoch++;
    _tabPageOpacity.dispose();
    _pageController.dispose();
    _snackbarHostState.dispose();
    _navigationRailState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usesMonet = switch (_themeMode) {
      MiuixColorMode.monetSystem ||
      MiuixColorMode.monetLight ||
      MiuixColorMode.monetDark => true,
      _ => false,
    };
    final selectedKeyColor = _referenceKeyColorFor(_settings.keyColorIndex);
    // Upstream falls back to its platform Monet seed when no explicit key is
    // chosen. The common fallback in ThemeController.kt is Material purple.
    final effectiveSeedColor = usesMonet
        ? selectedKeyColor ?? const Color(0xFF6750A4)
        : const Color(0xFF3482FF);
    var baseTheme = MiuixThemeData.defaults(
      mode: _themeMode,
      seedColor: effectiveSeedColor,
      paletteStyle: _settings.paletteStyle,
      colorSpec: _settings.colorSpec,
    );
    // A null keyColor asks ThemeController for platformDynamicColors. Android
    // supplies those asynchronously through the native bridge; desktop and
    // tests retain the original deterministic purple fallback. Previously the
    // loaded system palette was shown only on ColorPage, leaving the actual
    // Monet application theme incorrectly purple.
    if (usesMonet && selectedKeyColor == null) {
      baseTheme = baseTheme.copyWith(
        lightScheme: _platformDynamicLight ?? baseTheme.lightScheme,
        darkScheme: _platformDynamicDark ?? baseTheme.darkScheme,
      );
    }
    // Compose resolves Latin through Android Roboto and localized Han glyphs
    // through the system CJK fallback. Bundle both families and preserve that
    // order so translated labels remain portable without changing technical
    // names, version strings, or mixed-script measurements.
    final theme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontFamily: 'Roboto',
        fontFamilyFallback: const ['NotoSansCJKsc'],
      ),
      enableGlass: _settings.enableBlur,
      glassIntensity: _settings.glassIntensity,
      enableSquircle: _settings.enableSquircle,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // The reference application is fully localized to Simplified Chinese.
      // Installing matching Material localizations prevents calendars, date
      // dialogs, agenda headings, and accessibility labels from falling back
      // to English while the surrounding MIUIX fixture remains Chinese.
      locale: const Locale('zh', 'CN'),
      supportedLocales: const <Locale>[Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // MiuixTheme in Compose installs its spring overscroll factory for every
      // scrollable. Keep Flutter's Material stretch/glow out of the sample and
      // use the package's clipped elastic behavior at the same application
      // boundary; explicit MIUIX scrollbars remain owned by each page.
      scrollBehavior: const MiuixScrollBehavior(showScrollbars: false),
      // Navigator overlays are siblings of `home`. Applying MIUIX through the
      // builder keeps pushed About and License routes under the same Chinese
      // font, color scheme, blur switch, and squircle switch as the root pager.
      builder: (context, child) {
        final platformBrightness = MediaQuery.platformBrightnessOf(context);
        final brightness = theme.schemeFor(platformBrightness).brightness;
        final overlayBrightness = brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: overlayBrightness,
            statusBarBrightness: brightness,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: overlayBrightness,
            systemStatusBarContrastEnforced: false,
            systemNavigationBarContrastEnforced: false,
          ),
          child: MiuixTheme(
            data: theme,
            child: Builder(
              builder: (context) {
                // MaterialPageRoute asks the surrounding Theme to animate
                // both the new scene and the retained scene underneath it.
                // Installing the MIUIX builder here also covers the initial
                // home route created internally by MaterialApp.
                final material = Theme.of(context).copyWith(
                  pageTransitionsTheme: _referencePageTransitionsTheme,
                );
                return Theme(
                  data: material,
                  child: _ReferenceTransitionScope(
                    settings: _settings,
                    platformScreenCornerRadius: _platformScreenCornerRadius,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: child ?? const SizedBox.shrink(),
                        ),
                        _ReferenceFpsOverlay(visible: _settings.showFpsMonitor),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
      home: LayoutBuilder(
        builder: (context, constraints) {
          final wide = debugReferenceShouldShowSplitPane(
            Size(constraints.maxWidth, constraints.maxHeight),
          );
          final systemBottom = MediaQuery.paddingOf(context).bottom;
          final shouldExpandRail = constraints.maxWidth >= 1200;
          if (_lastAutomaticRailExpansion == null) {
            _lastAutomaticRailExpansion = shouldExpandRail;
            if (shouldExpandRail) _navigationRailState.expand();
          } else if (_lastAutomaticRailExpansion != shouldExpandRail) {
            _lastAutomaticRailExpansion = shouldExpandRail;
            SchedulerBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (shouldExpandRail) {
                _navigationRailState.expand();
              } else {
                _navigationRailState.collapse();
              }
            });
          }
          final rootBottomContentInset = wide
              ? systemBottom
              : debugReferenceRootBottomContentInset(
                  navigationVisible: _settings.showNavigation,
                  floating: _settings.useFloatingNavigationBar,
                  iosLike: _settings.useFloatingNavigationBar,
                  platform: defaultTargetPlatform,
                  systemBottom: systemBottom,
                  floatingDisplayMode:
                      switch (_settings.floatingNavigationBarMode) {
                        'iconAndText' =>
                          MiuixFloatingNavigationBarDisplayMode.iconAndText,
                        'textOnly' =>
                          MiuixFloatingNavigationBarDisplayMode.textOnly,
                        _ => MiuixFloatingNavigationBarDisplayMode.iconOnly,
                      },
                );
          // MainScreenBackHandler in the source consumes Back whenever the
          // root pager is away from page zero, then runs the same navigation
          // animation used by a destination tap. Only Home lets the platform
          // continue with its normal root-route exit behavior.
          final homeScene = PopScope<void>(
            canPop: _selectedIndex == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _selectedIndex != 0) {
                _selectPage(0);
              }
            },
            child: Stack(
              children: [
                MiuixScaffold(
                  // Compose Scaffold always measures and paints the page at
                  // full height, then places either bottom-bar style over it.
                  // The measured bar height is passed to each list separately
                  // so no opaque rectangular strip or duplicate gap is added.
                  extendBody: !wide,
                  // The source visibility transition wraps the concrete bar,
                  // so expose the current floating mode to the scaffold's
                  // full-window paint and shadow path.
                  bottomBarIsFloating:
                      !wide && _settings.useFloatingNavigationBar,
                  bottomBarShadowPaintExtent: 0,
                  snackbarHost: MiuixSnackbarHost(state: _snackbarHostState),
                  // The source always supplies this Scaffold slot and lets
                  // AnimatedVisibility keep the measured toolbar in place
                  // until its fade-out spring completes.
                  floatingToolbar: _ReferenceFadeOnlyVisibility(
                    visible: _settings.showFloatingToolbar,
                    opacityKey: const ValueKey(
                      'reference-toolbar-visibility-opacity',
                    ),
                    hiddenKey: const ValueKey(
                      'reference-toolbar-visibility-hidden',
                    ),
                    child: MiuixFloatingToolbar(
                      key: const ValueKey('example-floating-toolbar'),
                      color: Theme.of(context).colorScheme.primary,
                      cornerRadius: 20,
                      child: _buildFloatingToolbarContent(context),
                    ),
                  ),
                  floatingToolbarPosition:
                      switch (_settings.floatingToolbarPosition) {
                        'topStart' => MiuixToolbarPosition.topStart,
                        'bottomStart' => MiuixToolbarPosition.bottomStart,
                        'topEnd' => MiuixToolbarPosition.topEnd,
                        'centerEnd' => MiuixToolbarPosition.centerEnd,
                        'bottomEnd' => MiuixToolbarPosition.bottomEnd,
                        'topCenter' => MiuixToolbarPosition.topCenter,
                        'bottomCenter' => MiuixToolbarPosition.bottomCenter,
                        _ => MiuixToolbarPosition.centerStart,
                      },
                  floatingActionButton: _settings.showFloatingButton
                      ? MiuixFloatingActionButton(
                          key: const ValueKey('example-floating-action-button'),
                          icon: Icon(_miuixIcon('Link')),
                          // FloatingActionButton.kt leaves content tint to its
                          // caller; the upstream example explicitly uses
                          // onPrimary for this link glyph.
                          contentColor: Theme.of(context).colorScheme.onPrimary,
                          // LocalUriHandler opens this exact project URL in
                          // AppContent.kt; it does not synthesize a Toast.
                          onPressed: () => _openReferenceUrl(
                            'https://github.com/compose-miuix-ui/miuix',
                          ),
                        )
                      : null,
                  floatingActionButtonPosition:
                      switch (_settings.floatingActionButtonPosition) {
                        'start' => MiuixFabPosition.start,
                        'center' => MiuixFabPosition.center,
                        'endOverlay' => MiuixFabPosition.endOverlay,
                        _ => MiuixFabPosition.end,
                      },
                  bottomBar: wide ? null : _buildReferenceBottomNavigation(),
                  // The wide rail is intentionally not part of this Home
                  // scene. AppContent.kt keeps it outside NavDisplay so every
                  // pushed destination replaces only the right-hand pane.
                  body: FadeTransition(
                    key: const ValueKey('reference-root-tab-fade'),
                    opacity: _tabPageOpacity,
                    child: PageView(
                      controller: _pageController,
                      physics: _settings.enablePageSwipe
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) {
                        if (mounted && index != _selectedIndex) {
                          setState(() => _selectedIndex = index);
                        }
                      },
                      children: [
                        MiuixScrollEndHaptic(
                          enabled: _settings.enableScrollEndHaptic,
                          child: _MiuixReferenceHomePage(
                            wide: wide,
                            bottomContentInset: rootBottomContentInset,
                            snackbarHostState: _snackbarHostState,
                            showTopBar: _settings.showTopBar,
                            enableBlur: _settings.enableBlur,
                            enableScrollEndHaptic:
                                _settings.enableScrollEndHaptic,
                          ),
                        ),
                        MiuixScrollEndHaptic(
                          enabled: _settings.enableScrollEndHaptic,
                          child: _MiuixReferenceIconPage(
                            wide: wide,
                            bottomContentInset: rootBottomContentInset,
                            showTopBar: _settings.showTopBar,
                            enableBlur: _settings.enableBlur,
                          ),
                        ),
                        MiuixScrollEndHaptic(
                          enabled: _settings.enableScrollEndHaptic,
                          child: _MiuixReferenceColorPage(
                            wide: wide,
                            bottomContentInset: rootBottomContentInset,
                            platformDynamicLight: _platformDynamicLight,
                            platformDynamicDark: _platformDynamicDark,
                            showTopBar: _settings.showTopBar,
                            enableBlur: _settings.enableBlur,
                          ),
                        ),
                        MiuixScrollEndHaptic(
                          enabled: _settings.enableScrollEndHaptic,
                          child: _MiuixReferenceTextStylePage(
                            wide: wide,
                            bottomContentInset: rootBottomContentInset,
                            showTopBar: _settings.showTopBar,
                            enableBlur: _settings.enableBlur,
                          ),
                        ),
                        MiuixScrollEndHaptic(
                          enabled: _settings.enableScrollEndHaptic,
                          child: _MiuixReferenceSettingsPage(
                            wide: wide,
                            bottomContentInset: rootBottomContentInset,
                            colorMode: _themeMode,
                            onColorModeChanged: (mode) {
                              setState(() => _themeMode = mode);
                            },
                            settings: _settings,
                            onSettingsChanged: (value) {
                              setState(() => _settings = value);
                            },
                            showTopBar: _settings.showTopBar,
                            enableBlur: _settings.enableBlur,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
          if (!wide) return homeScene;

          // Wide HyperOS layouts keep the local glass rail persistent and
          // clip every route transition to the remaining content pane.
          return Row(
            children: [
              if (_settings.showNavigation)
                MiuixNavigationRail(
                  state: _navigationRailState,
                  items: _navigationItems,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectPage,
                  expandContentDescription: '展开导航栏',
                  collapseContentDescription: '折叠导航栏',
                ),
              Expanded(
                child: MiuixAdaptiveContentFrame(
                  child: KeyedSubtree(
                    key: const ValueKey('reference-wide-content-plane'),
                    child: _ReferenceWidePaneNavigator(
                      navigatorKey: _widePaneNavigatorKey,
                      home: homeScene,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the arbitrary source content slot from AppContent.kt.
  ///
  /// FloatingToolbar itself does not own orientation, padding, spacing, or
  /// action color. Those details belong to the sample's Row/Column content.
  Widget _buildFloatingToolbarContent(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onPrimary;
    final actions = <Widget>[
      MiuixIconButton(
        key: const ValueKey('floating-toolbar-edit'),
        icon: Icon(_miuixIcon('Edit'), color: iconColor, semanticLabel: '编辑'),
        onPressed: () {},
      ),
      MiuixIconButton(
        key: const ValueKey('floating-toolbar-delete'),
        icon: Icon(_miuixIcon('Delete'), color: iconColor, semanticLabel: '删除'),
        onPressed: () {},
      ),
      MiuixIconButton(
        key: const ValueKey('floating-toolbar-more'),
        icon: Icon(_miuixIcon('More'), color: iconColor, semanticLabel: '更多'),
        onPressed: () {},
      ),
    ];
    final horizontal = _settings.floatingToolbarOrientation == 'horizontal';
    return _ReferenceFloatingToolbarAnimatedContent(
      horizontal: horizontal,
      actions: actions,
    );
  }

  Future<void> _selectPage(int index) async {
    // PersistentNavigationRail first returns the pane to Route.Main. This is
    // a no-op on compact layouts because their routes use the root Navigator.
    _widePaneNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    final target = index.clamp(0, _navigationItems.length - 1);
    final currentPage = _pageController.hasClients
        ? (_pageController.page ?? _selectedIndex.toDouble())
        : _selectedIndex.toDouble();
    if (_selectedIndex == target && (currentPage - target).abs() < .001) return;
    if (_selectedIndex != target && mounted) {
      setState(() => _selectedIndex = target);
    }
    if (!_pageController.hasClients) return;

    final epoch = ++_tabSwitchEpoch;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _tabPageOpacity.value = 1;
      _pageController.jumpToPage(target);
      return;
    }

    // A bottom-tab click replaces a destination. It must not scroll through
    // every intermediate tab as PageController.animateToPage would do.
    await _tabPageOpacity.animateTo(
      0,
      duration: debugReferenceTabFadeOutDuration(),
      curve: debugReferenceTabFadeCurve(),
    );
    if (!mounted || epoch != _tabSwitchEpoch) return;
    _pageController.jumpToPage(target);
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted || epoch != _tabSwitchEpoch) return;
    await _tabPageOpacity.animateTo(
      1,
      duration: debugReferenceTabFadeInDuration(),
      curve: debugReferenceTabFadeCurve(),
    );
  }

  List<MiuixNavigationItem> get _navigationItems => [
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Home')),
      selectedIcon: Icon(_miuixIcon('Home')),
      label: '主页',
      layoutLabel: 'Home',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Create')),
      selectedIcon: Icon(_miuixIcon('Create')),
      badge: _navigationBadge(1),
      label: '图标',
      layoutLabel: 'Icon',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Image')),
      selectedIcon: Icon(_miuixIcon('Image')),
      label: '颜色',
      layoutLabel: 'Color',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Edit')),
      selectedIcon: Icon(_miuixIcon('Edit')),
      badge: _navigationBadge(3),
      label: '文本样式',
      layoutLabel: 'TextStyle',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Settings')),
      selectedIcon: Icon(_miuixIcon('Settings')),
      label: '设置',
      layoutLabel: 'Settings',
    ),
  ];

  /// Mirrors the current source's `navigationItemBadge` helper.
  ///
  /// The Icon destination carries the numeric badge and TextStyle carries the
  /// dot. Other destinations remain bare even when badges are enabled.
  Widget? _navigationBadge(int index) {
    if (!_settings.showBadge || (index != 1 && index != 3)) {
      return null;
    }
    return MiuixBadge.source(content: index == 1 ? const Text('8') : null);
  }
}

/// Resolves one authoritative Regular-weight icon for the application shell.
IconData _miuixIcon(String name) {
  final icon = MiuixExtendedIconCatalog.find(name);
  assert(icon != null, 'Missing MIUIX shell icon: $name');
  return icon?.regular ?? Icons.help_outline;
}
