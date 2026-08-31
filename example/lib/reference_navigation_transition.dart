part of 'main.dart';

/// Supplies the four live NavDisplay transition flags to every pushed route.
class _ReferenceTransitionScope extends InheritedWidget {
  const _ReferenceTransitionScope({
    required this.settings,
    required this.platformScreenCornerRadius,
    required super.child,
  });

  final _MiuixExampleSettings settings;
  final double platformScreenCornerRadius;

  /// Returns live root settings when a page belongs to the complete example.
  ///
  /// Isolated component fixtures intentionally omit the root navigation
  /// transition scope; those pages retain source-default settings instead of
  /// requiring an unrelated shell solely to render their own scaffold.
  static _MiuixExampleSettings? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_ReferenceTransitionScope>()
      ?.settings;

  @override
  bool updateShouldNotify(_ReferenceTransitionScope oldWidget) =>
      settings != oldWidget.settings ||
      platformScreenCornerRadius != oldWidget.platformScreenCornerRadius;
}

/// Uses the same page builder on every target supported by the example.
const _referencePageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: _ReferenceNavPageTransitionsBuilder(),
    TargetPlatform.iOS: _ReferenceNavPageTransitionsBuilder(),
    TargetPlatform.macOS: _ReferenceNavPageTransitionsBuilder(),
    TargetPlatform.windows: _ReferenceNavPageTransitionsBuilder(),
    TargetPlatform.linux: _ReferenceNavPageTransitionsBuilder(),
    TargetPlatform.fuchsia: _ReferenceNavPageTransitionsBuilder(),
  },
);

/// Keeps every sample destination on MIUIX's 500 ms navigation timeline.
///
/// [PageTransitionsBuilder] controls geometry but cannot change a route's
/// duration, so the sample uses this route instead of Flutter's 300 ms
/// [MaterialPageRoute] default.
class _ReferenceMaterialPageRoute<T> extends MaterialPageRoute<T> {
  // Compose keeps every NavDisplay entry live throughout a transition.
  // Flutter route snapshots can freeze animated shaders and backdrop filters
  // until late in pop, which reads as a pause followed by a jump.
  _ReferenceMaterialPageRoute({
    required BuildContext context,
    required super.builder,
    super.settings,
    super.allowSnapshotting = false,
  }) : _crossActivityStyle =
           _ReferenceTransitionScope.maybeOf(
             context,
           )?.navigationTransitionStyle ==
           'aosp';

  final bool _crossActivityStyle;

  @override
  Duration get transitionDuration =>
      Duration(milliseconds: _crossActivityStyle ? 450 : 500);

  @override
  Duration get reverseTransitionDuration => transitionDuration;

  /// CrossActivity uses a critically damped 1500-stiffness cancel spring.
  ///
  /// Flutter's default predictive-back cancellation is a duration-scaled
  /// linear controller run. Owning this branch at the route level preserves
  /// the source spring without changing the established MIUIX slide preset.
  @override
  void handleCancelBackGesture() {
    if (!_crossActivityStyle || controller == null || controller!.isCompleted) {
      super.handleCancelBackGesture();
      return;
    }
    final simulation = SpringSimulation(
      SpringDescription.withDampingRatio(mass: 1, stiffness: 1500, ratio: 1),
      controller!.value,
      1,
      0,
      tolerance: const Tolerance(distance: 0.001, velocity: 0.001),
    );
    controller!.animateWith(simulation).whenCompleteOrCancel(() {
      navigator?.didStopUserGesture();
    });
  }
}

/// Flutter counterpart of navigation3-ui's default NavDisplay transition.
class _ReferenceNavPageTransitionsBuilder extends PageTransitionsBuilder {
  const _ReferenceNavPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 500);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final transitionScope = context
        .dependOnInheritedWidgetOfExactType<_ReferenceTransitionScope>()!;
    final settings = transitionScope.settings;
    return _ReferencePredictiveBackDetector(
      route: route,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          animation,
          secondaryAnimation,
          _referenceBackGestureState,
        ]),
        child: child,
        builder: (context, child) {
          if (settings.navigationTransitionStyle == 'aosp') {
            final wide = debugReferenceShouldShowSplitPane(
              MediaQuery.sizeOf(context),
            );
            return _buildCrossActivityScene(
              context: context,
              route: route,
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              settings: settings,
              platformScreenCornerRadius: wide
                  ? 0
                  : transitionScope.platformScreenCornerRadius,
              child: child!,
            );
          }
          // Source navigation moves the target from +100% while retaining the
          // previous scene at -25%. The library restarts this spring from
          // elapsed pop time so neither coordinated scene pauses on return.
          final gesture = _referenceBackGestureState;
          final ownsBackGesture = identical(route, gesture.route);
          final hasCoveredPredictiveTrack =
              gesture.route != null &&
              !ownsBackGesture &&
              secondaryAnimation.value > 1e-9;
          final primary = ownsBackGesture
              ? gesture.resolveMiuixTrack(animation.value)
              : MiuixNavigationTransitionMotion.resolve(animation);
          final secondary = hasCoveredPredictiveTrack
              ? gesture.resolveMiuixTrack(secondaryAnimation.value)
              : MiuixNavigationTransitionMotion.resolve(secondaryAnimation);
          final rightEdgePop =
              settings.popDirectionFollowsSwipeEdge &&
              gesture.swipeEdge == SwipeEdge.right;
          final translation = rightEdgePop
              ? ownsBackGesture
                    ? primary - 1
                    : secondary / 4
              : 1 - primary - secondary / 4;

          // MiuixDefault gives the covered page its independent 10% alpha
          // falloff. The fullscreen dim is added after translation below; it
          // must not inherit the previous page's quarter-width parallax.
          Widget scene = Opacity(
            key: const ValueKey('reference-nav-transition-covered-opacity'),
            opacity: (1 - secondary * .1).clamp(.9, 1.0),
            child: child!,
          );

          // The newly added or removed top scene owns the rounded leading edge.
          final topSceneMoving =
              secondaryAnimation.value == 0 &&
              animation.status != AnimationStatus.completed &&
              animation.status != AnimationStatus.dismissed;
          if (settings.enableCornerClip && topSceneMoving) {
            final wide = debugReferenceShouldShowSplitPane(
              MediaQuery.sizeOf(context),
            );
            final radius = wide
                ? 0.0
                : transitionScope.platformScreenCornerRadius;
            scene = ClipPath(
              key: const ValueKey('reference-nav-transition-corner-clip'),
              clipper: ShapeBorderClipper(
                shape: MiuixSquircleBorder(
                  borderRadius: rightEdgePop
                      ? BorderRadius.only(
                          topRight: Radius.circular(radius),
                          bottomRight: Radius.circular(radius),
                        )
                      : BorderRadius.only(
                          topLeft: Radius.circular(radius),
                          bottomLeft: Radius.circular(radius),
                        ),
                ),
              ),
              child: scene,
            );
          }

          // During push the retained route is non-target; during pop the route
          // leaving the stack is non-target. Both consume input in the source.
          final predictivePopActive = gesture.route != null;
          final blockInput =
              settings.blockInputDuringTransition &&
              (predictivePopActive
                  ? ownsBackGesture
                  : secondaryAnimation.status == AnimationStatus.forward ||
                        animation.status == AnimationStatus.reverse);
          final translatedScene = FractionalTranslation(
            key: const ValueKey('reference-nav-transition-scene'),
            translation: Offset(translation, 0),
            child: AbsorbPointer(
              key: const ValueKey('reference-nav-transition-input-block'),
              absorbing: blockInput,
              child: scene,
            ),
          );

          // NavDisplayEffects owns a stationary, window-sized scrim between
          // the retained page and the moving top page. Keeping it outside the
          // translated subtree removes the exposed bright strip during pop.
          if (!settings.enableDim || secondary <= 0) return translatedScene;
          return Stack(
            fit: StackFit.passthrough,
            children: [
              translatedScene,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    key: const ValueKey('reference-nav-transition-dim'),
                    color: Colors.black.withValues(
                      alpha: (secondary * .5).clamp(0.0, .5),
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
}

/// Reconstructs the example's AOSP cross-activity transition selection.
///
/// Programmatic navigation uses Android's classic 96dp activity-open/activity-
/// close pair on a fixed 450ms `fast_out_extra_slow_in` track. Predictive back
/// switches to the reference card treatment: both scenes scale toward 90%, the
/// outgoing scene follows the initiating edge, and only that gesture branch
/// owns the light/dark platform scrim. Flutter does not place a timestamp on
/// [PredictiveBackEvent], so the detector pairs its progress with Flutter's
/// monotonic system-frame timestamp. This reproduces `NavDisplay.kt`'s last-two
/// event release velocity and restores the source fling-bounce scale channel.
Widget _buildCrossActivityScene({
  required BuildContext context,
  required PageRoute<dynamic> route,
  required Animation<double> animation,
  required Animation<double> secondaryAnimation,
  required _MiuixExampleSettings settings,
  required double platformScreenCornerRadius,
  required Widget child,
}) {
  const drift = 96.0;
  final gesture = _referenceBackGestureState;
  final gestureActive = gesture.route != null;
  final ownsGesture = identical(route, gesture.route);
  final isCoveredScene = secondaryAnimation.value > 0.0001;
  final brightness = Theme.of(context).brightness;

  double translationX;
  double translationY = 0;
  double scale = 1;
  double alpha = 1;
  double postLinear = 0;

  if (!gestureActive) {
    // Classic open/close uses the same horizontal geometry in both directions:
    // the top scene occupies 0..+96dp and the retained scene 0..-96dp. Raw
    // animation time drives alpha, while the piecewise curve drives position.
    if (isCoveredScene) {
      final covered = _referenceFastOutExtraSlowIn.transform(
        secondaryAnimation.value.clamp(0.0, 1.0),
      );
      translationX = (-covered * drift).roundToDouble();
    } else {
      final top = _referenceFastOutExtraSlowIn.transform(
        animation.value.clamp(0.0, 1.0),
      );
      translationX = ((1 - top) * drift).roundToDouble();
      if (animation.status == AnimationStatus.forward) {
        final elapsed = animation.value * 450;
        alpha = ((elapsed - 50) / 83).clamp(0.0, 1.0);
      } else if (animation.status == AnimationStatus.reverse) {
        final elapsed = (1 - animation.value) * 450;
        alpha = (1 - (elapsed - 35) / 83).clamp(0.0, 1.0);
      }
    }
  } else {
    // Before commit, Android shapes gesture progress with cubic(0.1, 0.1, 0,
    // 1). At release, keep the commit pose and grow/fly the card to completion.
    // Both Flutter route channels expose the same top-progress axis: primary
    // for the top route, secondary for the retained route. Commit resets the
    // primary controller to 1 before reversing it, so `1 - trackTop` is also
    // the exact fixed 450ms wall-clock fraction used by the source settle.
    final trackTop = (ownsGesture ? animation.value : secondaryAnimation.value)
        .clamp(0.0, 1.0);
    final releaseTop = gesture.releaseTopProgress ?? trackTop;
    postLinear = gesture.committing ? 1 - trackTop : 0.0;
    final post = gesture.committing
        ? _referenceFastOutExtraSlowIn.transform(postLinear)
        : 0.0;
    final liveTop = gesture.committing ? releaseTop : trackTop;
    final shapedTop = 1 - _referenceBackGestureCurve.transform(1 - liveTop);
    final committedScale = .9 + .1 * shapedTop;
    final bounce = gesture.committing
        ? debugReferenceCrossActivityBounceScale(
            releaseVelocity: gesture.releaseVelocity,
            elapsed: Duration(microseconds: (postLinear * 450000).round()),
            gestureProgress: 1 - releaseTop,
            swipeEdge: gesture.swipeEdge,
          )
        : 1.0;
    // The source multiplies the same bounce onto both coordinated layers
    // after their main scale has been resolved. Keeping it before edge
    // snapping also lets the translation quantizer see the final visible
    // bounds, preventing a half-pixel corner shimmer during the dip.
    scale = (committedScale + (1 - committedScale) * post) * bounce;
    final size = MediaQuery.sizeOf(context);

    if (ownsGesture) {
      final hugsRightEdge = gesture.swipeEdge != SwipeEdge.right;
      final hug = math.max(0.0, size.width * .05 - 8);
      translationX = hugsRightEdge ? (1 - shapedTop) * hug : 0;
      translationX += post * drift;
      alpha = gesture.committing ? (1 - postLinear * 5).clamp(0.0, 1.0) : 1;
    } else {
      translationX = -(1 - post) * drift;
    }

    // Both layers follow the source's damped touch-Y channel. Its cap depends
    // on the shared live scale and therefore collapses to zero during commit.
    final initialY = gesture.initialTouchY;
    final currentY = gesture.touchY;
    if (initialY != null && currentY != null && size.height > 0) {
      final delta = currentY - initialY;
      final half = size.height / 2;
      final ratio = math.min(half, delta.abs()) / half;
      final damped = 1 - (1 - ratio) * (1 - ratio);
      final maxShift = math.max(0.0, size.height * (1 - scale) / 2 - 8);
      translationY = maxShift * damped * (delta < 0 ? -1 : 1);
    }
    scale = _referenceSnapScaleToPixelWidth(scale, size.width);
    translationX = _referenceSnapEdgeTranslation(
      translationX,
      scale,
      size.width,
    );
    translationY = _referenceSnapEdgeTranslation(
      translationY,
      scale,
      size.height,
    );
  }

  Widget scene = Stack(
    fit: StackFit.passthrough,
    children: [
      child,
      if (gestureActive &&
          !ownsGesture &&
          settings.enableDim &&
          secondaryAnimation.value > 0)
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              key: const ValueKey('reference-aosp-transition-dim'),
              color: Colors.black.withValues(
                alpha:
                    (brightness == Brightness.dark ? .8 : .2) *
                    (gesture.committing ? 1 - postLinear : 1),
              ),
            ),
          ),
        ),
    ],
  );

  final sceneFractional = gestureActive
      ? ownsGesture
            ? (animation.value > 0 && animation.value < 1) || gesture.committing
            : (secondaryAnimation.value > 0 && secondaryAnimation.value < 1) ||
                  gesture.committing
      : isCoveredScene
      ? secondaryAnimation.value > 0 && secondaryAnimation.value < 1
      : animation.value > 0 && animation.value < 1;
  if (settings.enableCornerClip && sceneFractional) {
    final radius = platformScreenCornerRadius > 0
        ? platformScreenCornerRadius
        : 32.0;
    scene = ClipPath(
      key: const ValueKey('reference-aosp-transition-corner-clip'),
      clipper: ShapeBorderClipper(
        shape: MiuixSquircleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      child: scene,
    );
  }
  final predictivePopActive = gesture.route != null;
  final blockInput =
      settings.blockInputDuringTransition &&
      (predictivePopActive
          ? ownsGesture
          : secondaryAnimation.status == AnimationStatus.forward ||
                animation.status == AnimationStatus.reverse);

  return Transform.translate(
    key: const ValueKey('reference-aosp-transition-scene'),
    offset: Offset(translationX, translationY),
    child: Transform.scale(
      key: const ValueKey('reference-aosp-transition-scale'),
      scale: scale,
      child: Opacity(
        key: const ValueKey('reference-aosp-transition-opacity'),
        opacity: alpha,
        child: AbsorbPointer(
          key: const ValueKey('reference-nav-transition-input-block'),
          absorbing: blockInput,
          child: scene,
        ),
      ),
    ),
  );
}

/// Shares the active Android back edge with both coordinated route scenes.
class _ReferenceBackGestureState extends ChangeNotifier {
  PageRoute<dynamic>? route;
  SwipeEdge? swipeEdge;
  double? initialTouchY;
  double? touchY;
  double? releaseTopProgress;
  double releaseVelocity = 0;
  bool canceling = false;
  bool committing = false;
  double _lastProgress = 0;
  Duration _lastFrameTime = Duration.zero;

  void start(
    PageRoute<dynamic> owner,
    SwipeEdge edge,
    double? y,
    double progress,
    Duration frameTime,
  ) {
    route = owner;
    swipeEdge = edge;
    initialTouchY = y;
    touchY = y;
    releaseTopProgress = null;
    releaseVelocity = 0;
    canceling = false;
    committing = false;
    _lastProgress = progress;
    _lastFrameTime = frameTime;
    notifyListeners();
  }

  void update(double? y, double progress, Duration frameTime) {
    touchY = y ?? touchY;
    // NavDisplay.kt intentionally uses only the last two timestamped events.
    // Do the same here instead of introducing a platform-specific smoothing
    // filter. Warm-up frames can report zero and duplicate callbacks can share
    // a timestamp; neither is allowed to divide by zero or replace the last
    // valid velocity sample.
    if (_lastFrameTime != Duration.zero && frameTime > _lastFrameTime) {
      releaseVelocity = debugReferenceBackProgressVelocity(
        previousProgress: _lastProgress,
        currentProgress: progress,
        previousTime: _lastFrameTime,
        currentTime: frameTime,
      );
    }
    if (frameTime != Duration.zero) {
      _lastProgress = progress;
      _lastFrameTime = frameTime;
    }
    notifyListeners();
  }

  void commit(PageRoute<dynamic> owner) {
    if (!identical(route, owner)) return;
    releaseTopProgress = owner.animation?.value;
    canceling = false;
    committing = true;
    notifyListeners();
  }

  void cancel(PageRoute<dynamic> owner) {
    if (!identical(route, owner)) return;
    releaseTopProgress = owner.animation?.value;
    canceling = true;
    committing = false;
    notifyListeners();
  }

  double resolveMiuixTrack(double rawValue) {
    final raw = rawValue.clamp(0.0, 1.0);
    if (!canceling && !committing) return raw;
    final release = (releaseTopProgress ?? raw).clamp(0.0, 1.0);
    if (committing) {
      final post = MiuixNavigationTransitionMotion.curve.transform(1 - raw);
      return release * (1 - post);
    }
    if (release >= 1 - 1e-9) return 1;
    final cancelProgress = ((raw - release) / (1 - release)).clamp(0.0, 1.0);
    return release +
        (1 - release) *
            MiuixNavigationTransitionMotion.curve.transform(cancelProgress);
  }

  void clear(PageRoute<dynamic> owner, {bool notify = true}) {
    if (!identical(route, owner)) {
      return;
    }
    route = null;
    swipeEdge = null;
    initialTouchY = null;
    touchY = null;
    releaseTopProgress = null;
    releaseVelocity = 0;
    canceling = false;
    committing = false;
    _lastProgress = 0;
    _lastFrameTime = Duration.zero;
    if (notify) notifyListeners();
  }
}

final _referenceBackGestureState = _ReferenceBackGestureState();

/// Connects Android's predictive-back platform channel to a sample route.
class _ReferencePredictiveBackDetector extends StatefulWidget {
  const _ReferencePredictiveBackDetector({
    required this.route,
    required this.child,
  });

  final PageRoute<dynamic> route;
  final Widget child;

  @override
  State<_ReferencePredictiveBackDetector> createState() =>
      _ReferencePredictiveBackDetectorState();
}

class _ReferencePredictiveBackDetectorState
    extends State<_ReferencePredictiveBackDetector>
    with WidgetsBindingObserver {
  void _clearAfterCancel(AnimationStatus status) {
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    widget.route.animation?.removeStatusListener(_clearAfterCancel);
    _referenceBackGestureState.clear(widget.route);
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent ||
        !widget.route.isCurrent ||
        !widget.route.popGestureEnabled) {
      return false;
    }
    _referenceBackGestureState.start(
      widget.route,
      backEvent.swipeEdge,
      backEvent.touchOffset?.dy,
      backEvent.progress,
      SchedulerBinding.instance.currentSystemFrameTimeStamp,
    );
    widget.route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    _referenceBackGestureState.update(
      backEvent.touchOffset?.dy,
      backEvent.progress,
      SchedulerBinding.instance.currentSystemFrameTimeStamp,
    );
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() {
    _referenceBackGestureState.cancel(widget.route);
    widget.route.animation?.addStatusListener(_clearAfterCancel);
    widget.route.handleCancelBackGesture();
  }

  @override
  void handleCommitBackGesture() {
    _referenceBackGestureState.commit(widget.route);
    widget.route.handleCommitBackGesture();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.route.animation?.removeStatusListener(_clearAfterCancel);
    // The descendant AnimatedBuilder is still mounted while this parent state
    // disposes. Silent reset avoids requesting a rebuild during Flutter's
    // locked unmount pass; the retained route is already ticking its final
    // secondary-animation frame and observes the cleared fields.
    _referenceBackGestureState.clear(widget.route, notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Android's exact two-segment `fast_out_extra_slow_in` path.
class _ReferenceFastOutExtraSlowInCurve extends Curve {
  const _ReferenceFastOutExtraSlowInCurve();

  static const _knotX = .166666;
  static const _knotY = .4;
  static const _first = Cubic(.3000012, 0, .8000012, .15);
  static const _second = Cubic(.0500000, .7, .1000005, 1);

  @override
  double transformInternal(double t) => t < _knotX
      ? _knotY * _first.transform(t / _knotX)
      : _knotY + (1 - _knotY) * _second.transform((t - _knotX) / (1 - _knotX));
}

const _referenceFastOutExtraSlowIn = _ReferenceFastOutExtraSlowInCurve();
const _referenceBackGestureCurve = Cubic(.1, .1, 0, 1);

/// Returns the source predictive-back velocity in progress units per second.
///
/// `NavDisplay.kt` samples exactly the last two events and divides their
/// progress delta by their frame-time delta. Invalid or repeated timestamps
/// represent no new sample and therefore resolve to zero.
double debugReferenceBackProgressVelocity({
  required double previousProgress,
  required double currentProgress,
  required Duration previousTime,
  required Duration currentTime,
}) {
  final elapsedMicros = (currentTime - previousTime).inMicroseconds;
  if (elapsedMicros <= 0) return 0;
  return (currentProgress - previousProgress) *
      Duration.microsecondsPerSecond /
      elapsedMicros;
}

/// Returns CrossActivityTransition.kt's velocity-scaled fling bounce.
///
/// The source solves an underdamped oscillator directly on its scale-times-100
/// axis. Predictive edge gestures double the kick, values are capped at 1000,
/// and near-instant commits below ten percent retain the 120-unit floor. The
/// result may shrink either scene but never enlarges it beyond its main scale.
double debugReferenceCrossActivityBounceScale({
  required double releaseVelocity,
  required Duration elapsed,
  required double gestureProgress,
  SwipeEdge? swipeEdge,
}) {
  const stiffness = 200.0;
  const damping = .75;
  const maximumKick = 1000.0;
  const minimumKick = 120.0;
  const minimumScale = .9;
  final edgeFactor = swipeEdge == null ? 1.0 : 2.0;
  final floorKick = gestureProgress < .1 ? minimumKick : 0.0;
  final rawKick = releaseVelocity.abs() * 100 * (1 - minimumScale) * edgeFactor;
  final kick = rawKick.clamp(floorKick, maximumKick).toDouble();
  if (kick <= 0) return 1;
  final omega = math.sqrt(stiffness);
  final omegaD = omega * math.sqrt(1 - damping * damping);
  final seconds = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
  final overlay =
      -(kick / omegaD) *
      math.exp(-damping * omega * seconds) *
      math.sin(omegaD * seconds);
  return math.min(1, (100 + overlay) / 100);
}

/// Pixel-quantizes a centered scale like CrossActivityTransition.kt.
double _referenceSnapScaleToPixelWidth(double scale, double width) =>
    width <= 0 ? scale : (scale * width).roundToDouble() / width;

/// Snaps the transformed leading edge rather than the transform's center.
///
/// Rounding translation alone leaves half-pixel corner shimmer whenever the
/// centered scale changes. The source adds the scale inset before rounding and
/// removes it afterward, aligning both visible edges to device pixels.
double _referenceSnapEdgeTranslation(
  double translation,
  double scale,
  double extent,
) {
  final inset = extent * (1 - scale) / 2;
  return (translation + inset).roundToDouble() - inset;
}
