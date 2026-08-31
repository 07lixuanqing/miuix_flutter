part of 'main.dart';

/// Localized version of `ui.KeyColors` in the current source example.
const _referenceKeyColors = <({String label, Color color})>[
  (label: '蓝色', color: Color(0xFF3482FF)),
  (label: '绿色', color: Color(0xFF36D167)),
  (label: '紫色', color: Color(0xFF7C4DFF)),
  (label: '黄色', color: Color(0xFFFFB21D)),
  (label: '橙色', color: Color(0xFFFF5722)),
  (label: '粉色', color: Color(0xFFE91E63)),
  (label: '青色', color: Color(0xFF00BCD4)),
];

/// Resolves the one-based source index; zero means platform/default Monet.
Color? _referenceKeyColorFor(int index) {
  return index <= 0 || index > _referenceKeyColors.length
      ? null
      : _referenceKeyColors[index - 1].color;
}

/// App-wide switches controlled by the localized settings page.
///
/// Keeping these values above the five pages mirrors the original example's
/// `LocalAppState`: toggles rebuild the real shell instead of changing only a
/// preference row's text.
@immutable
class _MiuixExampleSettings {
  /// Creates the initial settings used by the original sample.
  const _MiuixExampleSettings({
    this.enableSquircle = true,
    // HyperOS 4 uses scroll-revealed soft glass as the application default.
    this.enableBlur = true,
    this.blurStyle = 'gaussian',
    this.glassIntensity = MiuixGlassIntensity.standard,
    this.keyColorIndex = 0,
    this.paletteStyle = MiuixThemePaletteStyle.tonalSpot,
    this.colorSpec = MiuixThemeColorSpec.spec2021,
    this.showFpsMonitor = false,
    this.enableScrollEndHaptic = true,
    this.enableCornerClip = true,
    this.enableDim = true,
    this.blockInputDuringTransition = false,
    this.enableSwipeBack = false,
    this.navigationTransitionStyle = 'miuix',
    this.popDirectionFollowsSwipeEdge = false,
    this.enablePageSwipe = true,
    this.showTopBar = true,
    this.showNavigation = true,
    this.showBadge = false,
    this.navigationMode = 'iconAndText',
    this.useFloatingNavigationBar = true,
    this.floatingNavigationBarMode = 'iconAndText',
    this.floatingNavigationBarStyle = 'iosLike',
    this.floatingNavigationBarAlignment = 'center',
    this.showFloatingToolbar = false,
    this.floatingToolbarPosition = 'centerStart',
    this.floatingToolbarOrientation = 'vertical',
    this.showFloatingButton = false,
    this.floatingActionButtonPosition = 'end',
  });

  /// Enables squircle-like component shapes.
  final bool enableSquircle;

  /// Enables glass and blur surfaces in the active theme.
  final bool enableBlur;

  /// Selects the current Gaussian or Progressive top-bar blur pipeline.
  final String blurStyle;

  /// Selects one of the five global blur and transparency strengths.
  final MiuixGlassIntensity glassIntensity;

  /// Selects Default or one of the seven upstream key colors.
  final int keyColorIndex;

  /// Selects one of the nine upstream Monet palette families.
  final MiuixThemePaletteStyle paletteStyle;

  /// Selects the 2021 or 2025 Material dynamic-color specification.
  final MiuixThemeColorSpec colorSpec;

  /// Shows the source sample's FPS diagnostics overlay.
  final bool showFpsMonitor;

  /// Enables source scroll-end haptic feedback.
  final bool enableScrollEndHaptic;

  /// Clips the top navigation scene during transitions.
  final bool enableCornerClip;

  /// Dims the scene behind the active transition.
  final bool enableDim;

  /// Blocks input on the non-target scene during transitions.
  final bool blockInputDuringTransition;

  /// Enables the current example's gesture-driven pushed-page dismissal.
  final bool enableSwipeBack;

  /// Selects the current MIUIX or AOSP navigation transition family.
  final String navigationTransitionStyle;

  /// Makes pop direction follow the initiating swipe edge.
  final bool popDirectionFollowsSwipeEdge;

  /// Allows users to swipe horizontally between the five root pages.
  final bool enablePageSwipe;

  /// Shows the root top application bar.
  final bool showTopBar;

  /// Shows the bottom navigation bar or wide navigation rail.
  final bool showNavigation;

  /// Shows the sample notification badge on the home destination.
  final bool showBadge;

  /// Selects one of the four display modes in the original component.
  final String navigationMode;

  /// Replaces the regular bar with MIUIX's distinct floating component.
  final bool useFloatingNavigationBar;

  /// Selects icon-and-text, icon-only, or text-only floating items.
  final String floatingNavigationBarMode;

  /// Legacy persisted style value; the unified example always uses iOS-like.
  final String floatingNavigationBarStyle;

  /// Legacy persisted alignment value; unified full-width placement ignores it.
  final String floatingNavigationBarAlignment;

  /// Shows the root scaffold's floating contextual toolbar.
  final bool showFloatingToolbar;

  /// Selects one of the original Scaffold toolbar positions.
  final String floatingToolbarPosition;

  /// Selects horizontal or vertical toolbar content.
  final String floatingToolbarOrientation;

  /// Shows the root scaffold's floating action button.
  final bool showFloatingButton;

  /// Selects one of the original four FAB positions.
  final String floatingActionButtonPosition;

  /// Returns a new immutable state while retaining unspecified values.
  _MiuixExampleSettings copyWith({
    bool? enableSquircle,
    bool? enableBlur,
    String? blurStyle,
    MiuixGlassIntensity? glassIntensity,
    int? keyColorIndex,
    MiuixThemePaletteStyle? paletteStyle,
    MiuixThemeColorSpec? colorSpec,
    bool? showFpsMonitor,
    bool? enableScrollEndHaptic,
    bool? enableCornerClip,
    bool? enableDim,
    bool? blockInputDuringTransition,
    bool? enableSwipeBack,
    String? navigationTransitionStyle,
    bool? popDirectionFollowsSwipeEdge,
    bool? enablePageSwipe,
    bool? showTopBar,
    bool? showNavigation,
    bool? showBadge,
    String? navigationMode,
    bool? useFloatingNavigationBar,
    String? floatingNavigationBarMode,
    String? floatingNavigationBarStyle,
    String? floatingNavigationBarAlignment,
    bool? showFloatingToolbar,
    String? floatingToolbarPosition,
    String? floatingToolbarOrientation,
    bool? showFloatingButton,
    String? floatingActionButtonPosition,
  }) {
    return _MiuixExampleSettings(
      enableSquircle: enableSquircle ?? this.enableSquircle,
      enableBlur: enableBlur ?? this.enableBlur,
      blurStyle: blurStyle ?? this.blurStyle,
      glassIntensity: glassIntensity ?? this.glassIntensity,
      keyColorIndex: keyColorIndex ?? this.keyColorIndex,
      paletteStyle: paletteStyle ?? this.paletteStyle,
      colorSpec: colorSpec ?? this.colorSpec,
      showFpsMonitor: showFpsMonitor ?? this.showFpsMonitor,
      enableScrollEndHaptic:
          enableScrollEndHaptic ?? this.enableScrollEndHaptic,
      enableCornerClip: enableCornerClip ?? this.enableCornerClip,
      enableDim: enableDim ?? this.enableDim,
      blockInputDuringTransition:
          blockInputDuringTransition ?? this.blockInputDuringTransition,
      enableSwipeBack: enableSwipeBack ?? this.enableSwipeBack,
      navigationTransitionStyle:
          navigationTransitionStyle ?? this.navigationTransitionStyle,
      popDirectionFollowsSwipeEdge:
          popDirectionFollowsSwipeEdge ?? this.popDirectionFollowsSwipeEdge,
      enablePageSwipe: enablePageSwipe ?? this.enablePageSwipe,
      showTopBar: showTopBar ?? this.showTopBar,
      showNavigation: showNavigation ?? this.showNavigation,
      showBadge: showBadge ?? this.showBadge,
      navigationMode: navigationMode ?? this.navigationMode,
      useFloatingNavigationBar:
          useFloatingNavigationBar ?? this.useFloatingNavigationBar,
      floatingNavigationBarMode:
          floatingNavigationBarMode ?? this.floatingNavigationBarMode,
      floatingNavigationBarStyle:
          floatingNavigationBarStyle ?? this.floatingNavigationBarStyle,
      floatingNavigationBarAlignment:
          floatingNavigationBarAlignment ?? this.floatingNavigationBarAlignment,
      showFloatingToolbar: showFloatingToolbar ?? this.showFloatingToolbar,
      floatingToolbarPosition:
          floatingToolbarPosition ?? this.floatingToolbarPosition,
      floatingToolbarOrientation:
          floatingToolbarOrientation ?? this.floatingToolbarOrientation,
      showFloatingButton: showFloatingButton ?? this.showFloatingButton,
      floatingActionButtonPosition:
          floatingActionButtonPosition ?? this.floatingActionButtonPosition,
    );
  }
}
