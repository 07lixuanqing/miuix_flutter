part of '../miuix_widgets.dart';

// Dialog motion source contract
// -----------------------------
// The authoritative implementation is DialogContentLayout.kt in MIUIX.
// OverlayDialog and WindowDialog both delegate their motion to that layout.
// They therefore share panel geometry, timing, easing, and dim behavior.
// Flutter's stock showGeneralDialog does not preserve all of those details.
// In particular, it gives the panel and modal barrier one normalized curve.
// It also uses the same duration for the forward and reverse route by default.
// The source runs its panel and dim animations concurrently but independently.
// This file keeps that separation even though both values use one route clock.
// The route clock lasts 520ms while the entrance spring finishes settling.
// The dim curve consumes only the first 300ms of that forward route clock.
// The reverse route clock lasts 260ms, matching the source panel tween.
// The reverse dim consumes 250ms and remains transparent for the final 10ms.
// Compact dialogs animate along the vertical axis from one viewport below.
// Large dialogs animate opacity and scale from 0.8 around their center.
// The compact spring uses dampingRatio 0.88 and stiffness 450 exactly.
// The large spring uses dampingRatio 0.9 and stiffness about 438.6 exactly.
// That large stiffness is derived by folmeSpring from a 0.3 second response.
// Neither spring should be replaced by easeOutCubic or a Material curve.
// A cubic curve removes the small settling motion visible in the original.
// It also reaches the final position much too early on high-refresh displays.
// Compose treats mass as one, so natural frequency is sqrt(stiffness).
// For an underdamped spring, damped frequency is wn*sqrt(1-zeta squared).
// The unit-step response begins at zero and converges toward one.
// It may cross one slightly; that small overshoot is intentional MIUIX motion.
// Flutter permits a Curve to return a value just outside the zero-to-one range.
// The final route tick is forced to exactly one by CurvedAnimation itself.
// This prevents any residual subpixel offset after the route becomes idle.
// The source visibility threshold is 0.0001 for the compact entrance spring.
// A 520ms sampling window reaches that threshold for the upstream parameters.
// Reducing the window makes the panel visibly snap during its final approach.
// Increasing it delays focus and interaction longer than the original does.
// Entrance dimming uses Android DecelerateInterpolator with factor 1.5.
// Its exact equation is one minus one-minus-t raised to the third power.
// Flutter's named ease-out curves are close but do not use that equation.
// Exit panel motion uses the same DecelerateEasing over exactly 260ms.
// On a descending route clock, its remaining value is t raised to the third.
// Exit dimming uses the same easing independently over exactly 250ms.
// The ten millisecond timing difference is preserved instead of rounded away.
// The barrier color comes from MIUIX windowDimming semantic color.
// It must not be replaced by Material's default black 54-percent scrim.
// A transparent barrier still owns taps so background content cannot activate.
// Barrier dismissal follows the caller's barrierDismissible setting.
// System Back must request dismissal before the route or host entry is removed.
// onDismissRequest fires once when dismissal begins, never after completion.
// onDismissFinished fires after the reverse animation and physical removal.
// Overlay-hosted dialogs do not push a Navigator route of their own.
// The popup host therefore owns a PopScope while any hosted entry is present.
// That PopScope remains locked throughout the reverse animation.
// A second fast Back press must not escape to and close the application page.
// Window dialogs do push a root Navigator route for platform-level coverage.
// Their custom RawDialogRoute supplies a distinct reverseTransitionDuration.
// The custom modal barrier gives dimming its independent source timing.
// Page content is wrapped in the caller's captured Theme for route stability.
// Compact and large mode are decided from the pre-route MediaQuery size.
// The source threshold requires width at least 840 and height at least 480.
// Matching only width would incorrectly center dialogs in short desktop panes.
// Compact content remains bottom-centered throughout every animation frame.
// Its system bottom inset is added before the explicit 12dp outside margin.
// SafeArea.minimum cannot express that sum and must not be used here.
// IME and navigation insets are mutually obstructive in this dialog context.
// The larger bottom obstruction is therefore used before adding the margin.
// Left and right outside margins remain 12dp on compact screens.
// The compact panel maximum width remains 420dp, matching the source default.
// Content padding remains 24dp on all four sides inside the smooth shape.
// The minimum bottom corner radius remains 32dp before platform adjustment.
// MIUIX smooth G2 geometry is used whenever the squircle option is enabled.
// A circular RoundedRectangleBorder is not equivalent near the side arcs.
// The ShapeBorder also clips descendants so children cannot leak at corners.
// Dialog title metrics remain 18sp, medium weight, and centered.
// Summary metrics remain 16sp and use onSurfaceSecondary semantic color.
// Title and summary each reserve 12dp below their text when present.
// Action layout belongs to the content surface and moves with the same panel.
// Predictive-back deformation is a separate upstream behavior not modeled here.
// Adding it later must compose with these timings rather than replace them.
// Reduced-motion policy may shorten animation, but default motion stays exact.
// Widget tests wait through 280ms before checking completed reverse lifecycle.
// Golden expanded states wait 600ms so they never capture a settling half-frame.
// Runtime screenshots compare the fully settled geometry, not transition blur.
// On the Android reference emulator the center edge differs by at most one px.
// The smooth side arc differs by at most two px after device rasterization.
// The outermost antialias fringe can vary because Flutter and Skia sample edges.
// Such fringe differences must not be "fixed" by changing the logical radius.
// The numerical curve classes below are private implementation details.
// Public callers continue to use MiuixDialog, OverlayDialog, or WindowDialog.
// Keeping constants private prevents apps from depending on temporary clocks.
// Source changes should be reconciled here and in the lifecycle tests together.
// Any duration change also requires checking popup-host Back ownership timing.
// Any shape change also requires regenerating only the affected golden images.
// Static analyzer success is required after route or barrier overrides change.
// Android runtime verification is required because widget tests lack system Back.
// Windows verification is required because large-screen mode follows another path.
// These notes intentionally document invariants beside the implementation.
// They are maintenance constraints, not a substitute for executable tests.

// Compose's DecelerateEasing(1.5) is the Android decelerate interpolator with
// an exponent of three. Keeping it as a named curve avoids substituting a
// visually similar cubic Bezier that drifts most noticeably near the end.
class _MiuixDecelerateCurve extends Curve {
  const _MiuixDecelerateCurve();

  @override
  double transformInternal(double t) => 1 - math.pow(1 - t, 3).toDouble();
}

// When a value animates from one back to zero with DecelerateEasing(1.5), its
// remaining value is t cubed on Flutter's descending route timeline.
class _MiuixAccelerateCurve extends Curve {
  const _MiuixAccelerateCurve();

  @override
  double transformInternal(double t) => t * t * t;
}

// DialogContentLayout.kt uses a physical spring rather than a fixed easing for
// its entrance. This is the closed-form unit-step response for that same
// underdamped spring. The duration only defines the sampled time window; the
// damping and stiffness remain the upstream values.
class _MiuixDialogSpringCurve extends Curve {
  const _MiuixDialogSpringCurve({
    required this.dampingRatio,
    required this.stiffness,
  });

  final double dampingRatio;
  final double stiffness;

  @override
  double transformInternal(double t) {
    const sampledSeconds = .52;
    final naturalFrequency = math.sqrt(stiffness);
    final dampedFactor = math.sqrt(1 - dampingRatio * dampingRatio);
    final dampedFrequency = naturalFrequency * dampedFactor;
    final seconds = t * sampledSeconds;
    final envelope = math.exp(-dampingRatio * naturalFrequency * seconds);
    final oscillation =
        math.cos(dampedFrequency * seconds) +
        dampingRatio / dampedFactor * math.sin(dampedFrequency * seconds);
    return 1 - envelope * oscillation;
  }
}

// The dim layer finishes in 300ms even though the panel spring continues to
// settle. The exit layer follows the source's independent 250ms duration.
class _MiuixDialogDimEnterCurve extends Curve {
  const _MiuixDialogDimEnterCurve();

  @override
  double transformInternal(double t) {
    final sourceProgress = math.min(t * 520 / 300, 1.0);
    return const _MiuixDecelerateCurve().transform(sourceProgress);
  }
}

class _MiuixDialogDimExitCurve extends Curve {
  const _MiuixDialogDimExitCurve();

  @override
  double transformInternal(double t) {
    final sourceProgress = ((t * 260 - 10) / 250).clamp(0.0, 1.0);
    return const _MiuixAccelerateCurve().transform(sourceProgress);
  }
}

const _miuixDialogEnterDuration = Duration(milliseconds: 520);
const _miuixDialogExitDuration = Duration(milliseconds: 260);

class _MiuixDialogRoute<T> extends RawDialogRoute<T> {
  _MiuixDialogRoute({
    required super.pageBuilder,
    required super.barrierDismissible,
    required super.barrierColor,
    required super.barrierLabel,
    required super.transitionBuilder,
  }) : super(transitionDuration: _miuixDialogEnterDuration);

  @override
  Duration get reverseTransitionDuration => _miuixDialogExitDuration;

  @override
  Widget buildModalBarrier() {
    final color = barrierColor;
    if (color == null || color.a == 0 || offstage) {
      return super.buildModalBarrier();
    }
    final opacity = CurvedAnimation(
      parent: animation!,
      curve: const _MiuixDialogDimEnterCurve(),
      reverseCurve: const _MiuixDialogDimExitCurve(),
    );
    return AnimatedModalBarrier(
      color: opacity.drive(
        ColorTween(begin: color.withValues(alpha: 0), end: color),
      ),
      dismissible: barrierDismissible,
      semanticsLabel: barrierLabel,
      barrierSemanticsDismissible: semanticsDismissible,
    );
  }
}

/// Dialog helper matching Miuix naming.
// Source parity notes for DialogContentLayout.kt:
// - Compact windows align the panel to BottomCenter.
// - Large windows require both width >= 840 and height >= 480.
// - The compact panel keeps 12dp outside margins on three visible edges.
// - Its bottom margin is added after the navigation/caption-bar inset.
// - The panel background is the MIUIX `background` semantic role.
// - The minimum compact corner is 32dp.
// - Content padding is 24dp on every side.
// - The title uses title4 size, which is 18sp in the default text table.
// - The title weight is Medium and its alignment is centered.
// - A summary uses body1 size, 16sp, and onSurfaceSecondary.
// - Title and summary each reserve 12dp beneath themselves.
// - Compact entrance moves vertically from one full viewport below.
// - Wide entrance fades and scales from 0.8 around the center.
// - Window dimming comes from the semantic palette, not Material scrim.
// These rules deliberately live beside the widget instead of only in tests.
// That makes later visual refactors preserve MIUIX behavior by construction.
class MiuixDialog extends StatelessWidget {
  /// Creates a dialog.
  const MiuixDialog({
    super.key,
    required this.title,
    this.summary,
    required this.content,
    this.actions = const [],
  });

  /// Dialog title.
  final String title;

  /// Optional centered summary below the title.
  final String? summary;

  /// Dialog content.
  final Widget content;

  /// Action widgets.
  final List<Widget> actions;

  /// Shows the dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? summary,
    required Widget content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    if (!context.mounted) {
      return Future<T?>.value();
    }
    final routeTheme = Theme.of(context);
    final semantic = MiuixSemanticColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final largeScreen = size.width >= 840 && size.height >= 480;
    var dismissRequested = false;
    void requestDismiss() {
      if (!dismissRequested) {
        dismissRequested = true;
        onDismissRequest?.call();
      }
    }

    return Navigator.of(context, rootNavigator: true)
        .push<T>(
          _MiuixDialogRoute<T>(
            barrierDismissible: barrierDismissible,
            barrierLabel: MaterialLocalizations.of(
              context,
            ).modalBarrierDismissLabel,
            barrierColor: semantic['windowDimming'],
            pageBuilder: (context, animation, secondaryAnimation) =>
                PopScope<Object?>(
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) {
                      requestDismiss();
                    }
                  },
                  child: Theme(
                    data: routeTheme,
                    child: Material(
                      type: MaterialType.transparency,
                      child: MiuixDialog(
                        title: title,
                        summary: summary,
                        content: content,
                        actions: actions,
                      ),
                    ),
                  ),
                ),
            transitionBuilder: (context, animation, secondaryAnimation, child) {
              final curved = CurvedAnimation(
                parent: animation,
                curve: _MiuixDialogSpringCurve(
                  dampingRatio: largeScreen ? .9 : .88,
                  stiffness: largeScreen ? 438.6 : 450,
                ),
                reverseCurve: const _MiuixAccelerateCurve(),
              );
              if (!largeScreen) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                );
              }
              return FadeTransition(
                opacity: curved,
                child: ScaleTransition(
                  scale: Tween<double>(begin: .8, end: 1).animate(curved),
                  child: child,
                ),
              );
            },
          ),
        )
        .whenComplete(() {
          requestDismiss();
          onDismissFinished?.call();
        });
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final media = MediaQuery.of(context);
    final size = media.size;
    final largeScreen = size.width >= 840 && size.height >= 480;
    // Compose applies navigationBarsPadding/captionBarPadding first and then
    // applies DialogDefaults.outsideMargin. SafeArea.minimum takes the larger
    // value instead of adding them, which placed the Flutter panel 12dp too
    // close to Android's gesture handle. IME and system navigation insets are
    // mutually exclusive here, so use their larger bottom obstruction.
    final bottomInset = math.max(
      media.viewInsets.bottom,
      media.viewPadding.bottom,
    );
    const dialogRadius = 32.0;
    final dialogBorderRadius = BorderRadius.circular(dialogRadius);
    final ShapeBorder dialogShape = MiuixTheme.of(context).enableSquircle
        ? const MiuixSquircleBorder(
            borderRadius: BorderRadius.all(Radius.circular(dialogRadius)),
          )
        : RoundedRectangleBorder(borderRadius: dialogBorderRadius);
    final surface = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 420,
        maxHeight: largeScreen ? size.height * (2 / 3) : double.infinity,
      ),
      child: SizedBox(
        width: largeScreen ? null : double.infinity,
        child: DecoratedBox(
          key: const ValueKey('miuix-dialog-surface'),
          decoration: ShapeDecoration(
            color: semantic['background'],
            shape: dialogShape,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: dialogShape),
            child: DefaultTextStyle(
              style:
                  (Theme.of(context).textTheme.bodyLarge ??
                          const TextStyle(fontSize: 17))
                      .copyWith(color: semantic['onSurface']),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: semantic['onBackground'],
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (summary != null) ...[
                      Text(
                        summary!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: semantic['onSurfaceSecondary'],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    content,
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 6,
                        runSpacing: 6,
                        children: actions,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          media.viewPadding.top,
          12,
          bottomInset + 12,
        ),
        child: Align(
          alignment: largeScreen ? Alignment.center : Alignment.bottomCenter,
          child: surface,
        ),
      ),
    );
  }
}

/// Mutable behavior state for a visible MIUIX bottom sheet.
///
/// Flutter routes are created once, while the source Compose demo can update
/// `allowDismiss` and `enableNestedScroll` through recomposition. This
/// controller provides the equivalent live contract and also gives title-bar
/// actions a host-independent way to close either an overlay or window sheet.
class MiuixBottomSheetController extends ChangeNotifier {
  /// Creates bottom-sheet behavior state.
  MiuixBottomSheetController({
    bool allowDismiss = true,
    bool enableNestedScroll = true,
  }) : _allowDismiss = allowDismiss,
       _enableNestedScroll = enableNestedScroll;

  bool _allowDismiss;
  bool _enableNestedScroll;
  VoidCallback? _dismiss;

  /// Whether outside taps, back gestures, and downward drags may dismiss.
  bool get allowDismiss => _allowDismiss;

  set allowDismiss(bool value) {
    if (_allowDismiss != value) {
      _allowDismiss = value;
      notifyListeners();
    }
  }

  /// Whether sheet dragging participates with its scrollable child.
  bool get enableNestedScroll => _enableNestedScroll;

  set enableNestedScroll(bool value) {
    if (_enableNestedScroll != value) {
      _enableNestedScroll = value;
      notifyListeners();
    }
  }

  /// Closes the attached sheet even when gesture dismissal is disabled.
  void dismiss() => _dismiss?.call();

  void _attach(VoidCallback dismiss) => _dismiss = dismiss;

  void _detach(VoidCallback dismiss) {
    if (identical(_dismiss, dismiss)) {
      _dismiss = null;
    }
  }
}

/// Bottom sheet helper.
class MiuixBottomSheet {
  /// Shows a modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? startAction,
    Widget? endAction,
    MiuixBottomSheetController? controller,
    bool allowDismiss = true,
    bool enableNestedScroll = true,
    bool? glass,
    EdgeInsetsGeometry insideMargin = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    if (!context.mounted) {
      return Future<T?>.value();
    }
    final routeTheme = Theme.of(context);
    final ownsController = controller == null;
    final behavior =
        controller ??
        MiuixBottomSheetController(
          allowDismiss: allowDismiss,
          enableNestedScroll: enableNestedScroll,
        );
    var dismissRequested = false;
    void requestDismiss() {
      if (!dismissRequested) {
        dismissRequested = true;
        onDismissRequest?.call();
      }
    }

    final future = showGeneralDialog<T>(
      context: context,
      useRootNavigator: true,
      // A custom barrier reads the live behavior controller. A route-level
      // ModalBarrier cannot change dismissibility after it is constructed.
      barrierDismissible: false,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Theme(
          data: routeTheme,
          child: Material(
            type: MaterialType.transparency,
            child: _MiuixWindowBottomSheetHost(
              controller: behavior,
              onDismissRequest: requestDismiss,
              child: _MiuixBottomSheetSurface(
                glass: glass ?? MiuixTheme.of(context).enableGlass,
                insideMargin: insideMargin,
                title: title,
                startAction: startAction,
                endAction: endAction,
                controller: behavior,
                child: child,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
    );
    return future.whenComplete(() {
      requestDismiss();
      onDismissFinished?.call();
      if (ownsController) {
        behavior.dispose();
      }
    });
  }
}

class _MiuixWindowBottomSheetHost extends StatefulWidget {
  const _MiuixWindowBottomSheetHost({
    required this.controller,
    required this.onDismissRequest,
    required this.child,
  });

  final MiuixBottomSheetController controller;
  final VoidCallback onDismissRequest;
  final Widget child;

  @override
  State<_MiuixWindowBottomSheetHost> createState() =>
      _MiuixWindowBottomSheetHostState();
}

class _MiuixWindowBottomSheetHostState
    extends State<_MiuixWindowBottomSheetHost> {
  bool _forceDismiss = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_behaviorChanged);
    widget.controller._attach(_dismissFromAction);
  }

  @override
  void didUpdateWidget(covariant _MiuixWindowBottomSheetHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller
        ..removeListener(_behaviorChanged)
        .._detach(_dismissFromAction);
      widget.controller
        ..addListener(_behaviorChanged)
        .._attach(_dismissFromAction);
    }
  }

  void _behaviorChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _dismissFromAction() {
    if (_forceDismiss || !mounted) {
      return;
    }
    setState(() => _forceDismiss = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _dismissFromGesture() {
    if (!widget.controller.allowDismiss) {
      return;
    }
    widget.onDismissRequest();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    widget.controller
      ..removeListener(_behaviorChanged)
      .._detach(_dismissFromAction);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = widget.controller.allowDismiss || _forceDismiss;
    return PopScope<Object?>(
      canPop: canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onDismissRequest();
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _dismissFromGesture,
            child: ColoredBox(
              color: MiuixSemanticColors.of(context)['windowDimming'],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _MiuixBottomSheetSurface extends StatefulWidget {
  const _MiuixBottomSheetSurface({
    required this.child,
    required this.glass,
    this.insideMargin = const EdgeInsets.symmetric(horizontal: 24),
    this.title,
    this.startAction,
    this.endAction,
    this.controller,
  });

  final Widget child;
  final bool glass;
  final EdgeInsetsGeometry insideMargin;
  final String? title;
  final Widget? startAction;
  final Widget? endAction;
  final MiuixBottomSheetController? controller;

  @override
  State<_MiuixBottomSheetSurface> createState() =>
      _MiuixBottomSheetSurfaceState();
}

class _MiuixBottomSheetSurfaceState extends State<_MiuixBottomSheetSurface> {
  // Source parity notes for BottomSheetContentLayout.kt:
  // - The sheet is bottom aligned and content sized.
  // - Its maximum width is 640dp on every platform.
  // - Its maximum height stops at the status-bar-safe top edge.
  // - Default outside margin is zero, so the background reaches the gesture bar.
  // - Default horizontal inside margin is 24dp.
  // - Default vertical inside margin is zero.
  // - Only the two top corners use the 28dp source radius.
  // - The drag handle owns a 24dp-high interaction area.
  // - Its resting painted size is exactly 45 by 4dp.
  // - The handle tint is onSurfaceVariantSummary at 20 percent opacity.
  // - The title/action row adds 6dp above and 12dp below.
  // - The title uses the 18sp Medium title4 token.
  // - Downward motion follows the pointer when dismissal is allowed.
  // - Upward overscroll is damped to one tenth of pointer movement.
  // - A popup-hosted sheet still uses the same vertical slide as a window sheet.
  // - Optional glass follows the global extension; source-default mode stays opaque.
  double _dragOffset = 0;

  void _dragUpdate(DragUpdateDetails details) {
    final controller = widget.controller;
    if (controller == null || !controller.enableNestedScroll) {
      return;
    }
    final delta = details.primaryDelta ?? 0;
    setState(() {
      _dragOffset = (_dragOffset + (delta < 0 ? delta * .1 : delta)).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _dragEnd(DragEndDetails details) {
    final controller = widget.controller;
    if (controller == null) {
      return;
    }
    final velocity = details.primaryVelocity ?? 0;
    if (controller.allowDismiss && (_dragOffset > 150 || velocity > 800)) {
      controller.dismiss();
      return;
    }
    if (_dragOffset != 0) {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    // Compose rounds each modifier padding edge before it measures the child.
    // At 420 dpi the 6dp + 40dp + 12dp title row is therefore
    // 16px + 105px + 32px = 153px. Letting Flutter retain both fractional
    // padding edges made the chrome one pixel shorter and every content-sized
    // sheet begin one pixel too low.
    final titlePadding = _miuixRoundedInsets(
      context,
      const EdgeInsets.only(top: 6, bottom: 12),
    );
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _dragOffset, 0),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          onVerticalDragUpdate: _dragUpdate,
          onVerticalDragEnd: _dragEnd,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.sizeOf(context).height - safeTop,
            ),
            child: SizedBox(
              width: double.infinity,
              child: MiuixGlass(
                key: const ValueKey('miuix-bottom-sheet-surface'),
                enabled: widget.glass,
                blur: 25,
                opacity: .92,
                color: semantic['background'],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                padding: widget.insideMargin,
                child: DefaultTextStyle(
                  style:
                      (Theme.of(context).textTheme.bodyLarge ??
                              const TextStyle(fontSize: 17))
                          .copyWith(color: semantic['onSurface']),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 24,
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: semantic['onSurfaceVariantSummary']
                                  .withValues(alpha: .2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const SizedBox(width: 45, height: 4),
                          ),
                        ),
                      ),
                      if (widget.title != null ||
                          widget.startAction != null ||
                          widget.endAction != null)
                        Padding(
                          padding: titlePadding,
                          child: SizedBox(
                            height: 40,
                            child: Stack(
                              fit: StackFit.expand,
                              alignment: Alignment.center,
                              children: [
                                if (widget.startAction != null)
                                  Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: widget.startAction,
                                  ),
                                if (widget.title != null)
                                  Center(
                                    child: Text(
                                      widget.title!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: semantic['onSurface'],
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (widget.endAction != null)
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: widget.endAction,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay-named dialog adapter matching MIUIX component naming.
class MiuixOverlayDialog {
  /// Shows an overlay dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? summary,
    required Widget content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    bool renderInRootScaffold = true,
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    final nearest = MiuixPopupHostScope.maybeOf(context);
    if (nearest == null) {
      throw FlutterError(
        'MiuixOverlayDialog requires a MiuixScaffold or MiuixPopupHost.',
      );
    }
    final controller = renderInRootScaffold ? nearest.root : nearest;
    return controller.show<T>(
      child: MiuixDialog(
        title: title,
        summary: summary,
        content: content,
        actions: actions,
      ),
      dimBackground: true,
      dimColor: MiuixSemanticColors.of(context)['windowDimming'],
      dialogTransition: true,
      barrierDismissible: barrierDismissible,
      onDismissRequest: onDismissRequest,
      onDismissFinished: onDismissFinished,
    );
  }
}

/// Window-named dialog adapter matching MIUIX component naming.
class MiuixWindowDialog {
  /// Shows a window dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? summary,
    required Widget content,
    List<Widget> actions = const [],
    bool barrierDismissible = true,
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    return MiuixDialog.show<T>(
      context: context,
      title: title,
      summary: summary,
      content: content,
      actions: actions,
      barrierDismissible: barrierDismissible,
      onDismissRequest: onDismissRequest,
      onDismissFinished: onDismissFinished,
    );
  }
}

/// Overlay-named bottom sheet adapter matching MIUIX component naming.
class MiuixOverlayBottomSheet {
  /// Shows an overlay bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? startAction,
    Widget? endAction,
    MiuixBottomSheetController? controller,
    bool allowDismiss = true,
    bool enableNestedScroll = true,
    bool? glass,
    bool renderInRootScaffold = true,
    EdgeInsetsGeometry insideMargin = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    final nearest = MiuixPopupHostScope.maybeOf(context);
    if (nearest == null) {
      throw FlutterError(
        'MiuixOverlayBottomSheet requires a MiuixScaffold or MiuixPopupHost.',
      );
    }
    final popupHost = renderInRootScaffold ? nearest.root : nearest;
    final ownsController = controller == null;
    final behavior =
        controller ??
        MiuixBottomSheetController(
          allowDismiss: allowDismiss,
          enableNestedScroll: enableNestedScroll,
        );
    var dismissRequested = false;
    void requestDismiss() {
      if (!dismissRequested) {
        dismissRequested = true;
        onDismissRequest?.call();
      }
    }

    void dismissFromAction() {
      requestDismiss();
      popupHost.dismissTop<T>();
    }

    behavior._attach(dismissFromAction);
    final future = popupHost.show<T>(
      unanchoredAlignment: Alignment.bottomCenter,
      dimBackground: true,
      dimColor: MiuixSemanticColors.of(context)['windowDimming'],
      bottomSheetTransition: true,
      canDismiss: () => behavior.allowDismiss,
      onDismissRequest: requestDismiss,
      onDismissFinished: onDismissFinished,
      child: _MiuixOverlayBottomSheetHost(
        controller: behavior,
        child: _MiuixBottomSheetSurface(
          glass: glass ?? MiuixTheme.of(context).enableGlass,
          insideMargin: insideMargin,
          title: title,
          startAction: startAction,
          endAction: endAction,
          controller: behavior,
          child: child,
        ),
      ),
    );
    return future.whenComplete(() {
      behavior._detach(dismissFromAction);
      if (ownsController) {
        behavior.dispose();
      }
    });
  }
}

class _MiuixOverlayBottomSheetHost extends StatelessWidget {
  const _MiuixOverlayBottomSheetHost({
    required this.controller,
    required this.child,
  });

  final MiuixBottomSheetController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && controller.allowDismiss) {
          controller.dismiss();
        }
      },
      child: child,
    );
  }
}

/// Window-named bottom sheet adapter matching MIUIX component naming.
class MiuixWindowBottomSheet {
  /// Shows a window bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? startAction,
    Widget? endAction,
    MiuixBottomSheetController? controller,
    bool allowDismiss = true,
    bool enableNestedScroll = true,
    bool? glass,
    EdgeInsetsGeometry insideMargin = const EdgeInsets.symmetric(
      horizontal: 24,
    ),
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    return MiuixBottomSheet.show<T>(
      context: context,
      child: child,
      title: title,
      startAction: startAction,
      endAction: endAction,
      controller: controller,
      allowDismiss: allowDismiss,
      enableNestedScroll: enableNestedScroll,
      glass: glass,
      insideMargin: insideMargin,
      onDismissRequest: onDismissRequest,
      onDismissFinished: onDismissFinished,
    );
  }
}
