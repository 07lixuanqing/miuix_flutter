part of '../miuix_widgets.dart';

/// Blur pipelines exposed by the current MIUIX example's `BlurredBar` helper.
///
/// This enum describes the rendering pipeline, not merely an animation style.
/// The modes use different radii, tint profiles, and scroll rules.
/// Keeping that distinction in the component library lets applications build
/// the same settings surface as the upstream sample without reimplementing its
/// private `BlurredBar` wrapper around every [MiuixTopAppBar].
///
/// Both modes require [MiuixTopAppBar.glass] to be true. When glass is false,
/// the requested mode is retained as configuration but the bar paints the same
/// opaque MIUIX surface as the original example does on unsupported devices.
/// This makes it safe to preserve a user's selection while runtime blur support
/// is temporarily unavailable or disabled for performance reasons.
enum MiuixTopAppBarBlurStyle {
  /// Uniform 25dp texture blur with an 80% surface blend.
  gaussian,

  /// Top-heavy 10dp blur that fades clear toward the lower edge.
  progressive,

  /// Persistent top-to-bottom HyperOS glass gradient.
  ///
  /// Unlike [progressive], this material is visible before the page scrolls.
  /// It is the default HyperOS 4 presentation; the older uniform and
  /// scroll-revealed pipelines remain available explicitly.
  gradient,
}

/// Visual treatment for compact top-app-bar action slots.
///
/// This controls the action surfaces only. Every action child retains its own
/// callback, focus state, popup anchor, tooltip, semantics, and indication.
/// The wrapper therefore works with icon buttons and arbitrary popup triggers
/// without turning the group into a second competing gesture target.
enum MiuixTopAppBarActionStyle {
  /// HyperOS 4 glass actions: every action owns an independent circle.
  ///
  /// The compact row already spaces icon centers by 40dp and exposes 48dp
  /// Android semantic targets. The shared material follows those established
  /// measurements: every item is 48 by 48dp with a true circular shape and an
  /// 8dp visual gap. This keeps multiple compact actions from becoming one
  /// elongated oval while retaining 48dp popup anchors and semantic targets.
  ///
  /// Only the circular silhouettes sample the backdrop. Their 8dp gaps and all
  /// other empty title space remain part of the top-bar material instead of
  /// gaining a second opaque rectangle. Each circle reads the same global
  /// glass intensity and clips its filter to its own non-overlapping bounds.
  glass,

  /// Source-compatible icon-only slots without a shared background.
  ///
  /// Use this during migration when an application already provides its own
  /// action container. It removes only the shared glass surface and leaves the
  /// action layout, minimum target, title avoidance, and callbacks unchanged.
  plain,
}

/// Public source metrics shared by large and compact top app bars.
abstract final class MiuixTopAppBarDefaults {
  static const double titlePadding = 26;
  static const double navigationIconPadding = 16;
  static const double actionIconPadding = 16;
  static const double collapsedHeight = 52;
  static const double smallTopAppBarCenterHeight = 50;
  static const double largeTitleBottomPadding = 4;
  static const double subtitleBottomPadding = 8;
}

/// Hoistable source state for a collapsing [MiuixTopAppBar].
class MiuixTopAppBarState extends ChangeNotifier {
  MiuixTopAppBarState({
    double initialHeightOffsetLimit = -double.maxFinite,
    double initialHeightOffset = 0,
    double initialContentOffset = 0,
  }) : _heightOffsetLimit = initialHeightOffsetLimit.isFinite
           ? math.min(0.0, initialHeightOffsetLimit)
           : -double.maxFinite,
       _heightOffset = 0,
       _contentOffset = initialContentOffset.isFinite
           ? initialContentOffset
           : 0 {
    _heightOffset = _coerceHeight(initialHeightOffset);
  }

  double _heightOffsetLimit;
  double _heightOffset;
  double _contentOffset;

  double get heightOffsetLimit => _heightOffsetLimit;

  set heightOffsetLimit(double value) {
    final next = value.isFinite ? math.min(0.0, value) : -double.maxFinite;
    final nextHeight = _coerceHeight(_heightOffset, limit: next);
    if (next == _heightOffsetLimit && nextHeight == _heightOffset) return;
    _heightOffsetLimit = next;
    _heightOffset = nextHeight;
    notifyListeners();
  }

  double get heightOffset => _heightOffset;

  set heightOffset(double value) {
    final next = _coerceHeight(value);
    if (next == _heightOffset) return;
    _heightOffset = next;
    notifyListeners();
  }

  double get contentOffset => _contentOffset;

  set contentOffset(double value) {
    final next = value.isFinite ? value : 0.0;
    if (next == _contentOffset) return;
    _contentOffset = next;
    notifyListeners();
  }

  double get collapsedFraction {
    if (_heightOffsetLimit == 0) return 0;
    return (_heightOffset / _heightOffsetLimit).clamp(0.0, 1.0);
  }

  double get overlappedFraction {
    if (_heightOffsetLimit == 0) return 0;
    final overlap = (_heightOffsetLimit - _contentOffset).clamp(
      _heightOffsetLimit,
      0.0,
    );
    return (1 - overlap / _heightOffsetLimit).clamp(0.0, 1.0);
  }

  double _coerceHeight(double value, {double? limit}) {
    final minimum = limit ?? _heightOffsetLimit;
    final finite = value.isFinite ? value : 0.0;
    return finite.clamp(minimum, 0.0);
  }

  void _replace({
    required double heightOffsetLimit,
    required double heightOffset,
    required double contentOffset,
  }) {
    final nextLimit = math.min(0.0, heightOffsetLimit);
    final nextHeight = _coerceHeight(heightOffset, limit: nextLimit);
    final nextContent = contentOffset.isFinite ? contentOffset : 0.0;
    if (nextLimit == _heightOffsetLimit &&
        nextHeight == _heightOffset &&
        nextContent == _contentOffset) {
      return;
    }
    _heightOffsetLimit = nextLimit;
    _heightOffset = nextHeight;
    _contentOffset = nextContent;
    notifyListeners();
  }
}

/// Drives the collapse state of a MIUIX large [MiuixTopAppBar].
///
/// The original component consumes vertical nested-scroll movement, then snaps
/// to the expanded or collapsed state when scrolling stops. [MiuixScaffold]
/// wires this object to descendant scrollables automatically.
class MiuixTopAppBarScrollBehavior extends ChangeNotifier {
  /// Creates a scroll behavior in its fully expanded state.
  MiuixTopAppBarScrollBehavior({
    this.snapDuration = const Duration(milliseconds: 300),
    MiuixTopAppBarState? state,
  }) : state = state ?? MiuixTopAppBarState() {
    final sourceLimit = this.state.heightOffsetLimit;
    if (sourceLimit.isFinite && sourceLimit < 0 && sourceLimit > -1000000) {
      _collapseExtent = -sourceLimit;
      _collapseFraction = this.state.collapsedFraction;
    }
    _contentOffset = this.state.contentOffset;
    this.state.addListener(_handleHoistedStateChange);
    _syncHoistedState();
    _settleTicker = Ticker(_tickSettle);
  }

  /// Maximum time allowed for the final source spring.
  ///
  /// The current MIUIX component uses a critically damped spring with a
  /// stiffness of 2500 rather than a duration tween. This compatibility value
  /// remains public so existing callers can disable settling with
  /// [Duration.zero] or cap an unusually long custom frame sequence.
  final Duration snapDuration;

  /// Independently observable source height and content offsets.
  final MiuixTopAppBarState state;

  bool _syncingHoistedState = false;

  double _collapseFraction = 0;
  double _collapseExtent = 38;
  double _contentOffset = 0;
  late final Ticker _settleTicker;
  Simulation? _settleSimulation;
  Duration? _settleSimulationStart;
  bool _settleIsDecay = false;
  double _settleTargetHeight = 0;
  bool _hasExplicitCollapseState = false;
  bool _restorationConsumed = false;
  // SmallTopAppBar pins the shared source height range to zero without losing
  // the independently accumulated content offset. A later large bar uses this
  // marker to restore its collapsed/expanded endpoint from that offset.
  bool _pinnedBySmallTopAppBar = false;
  bool _smallTopBarPinScheduled = false;
  bool _listenerNotificationScheduled = false;
  int _topBarModeGeneration = 0;
  bool _disposed = false;
  bool _reduceMotion = false;

  /// Zero is fully expanded and one is fully collapsed.
  double get collapseFraction => _collapseFraction;

  /// Signed source content offset used by progressive top-bar blur.
  ///
  /// Upward scrolling is negative, matching Compose's nested-scroll state.
  /// The blur helper reaches full opacity after 48 logical pixels of upward
  /// content movement, independently of the large title's collapse extent.
  ///
  /// This value intentionally differs from [collapseFraction]. The large title
  /// saturates after its measured title column has collapsed, while list
  /// content can continue travelling behind the compact bar. Upstream keeps
  /// both quantities in its scroll state and uses the unbounded content offset
  /// for the progressive effect. Deriving one from the other would stop a
  /// title-only bar at roughly 79% blur because its source collapse extent is
  /// 38dp but the blur reveal distance is 48dp.
  ///
  /// Calls to [syncMetrics] preserve the raw scroll distance. Direct calls to
  /// [setCollapseFraction] synthesize the equivalent title-column distance so
  /// existing animation and test clients still receive deterministic state.
  /// Overscroll above the leading edge resolves to zero because the source
  /// blur does not appear while content is being pulled downward.
  double get contentOffset => _contentOffset;

  /// Applies a normalized collapse value.
  void setCollapseFraction(double value) {
    _cancelSettle();
    _hasExplicitCollapseState = true;
    final next = value.clamp(0.0, 1.0);
    final nextOffset = -next * _collapseExtent;
    if ((next - _collapseFraction).abs() < .0001 &&
        (nextOffset - _contentOffset).abs() < .0001) {
      return;
    }
    _collapseFraction = next;
    _contentOffset = nextOffset;
    _notifyStateAndListeners();
  }

  /// Expands the bar immediately, for example after changing root pages.
  void expand() {
    _cancelSettle();
    setCollapseFraction(0);
  }

  /// Synchronizes the bar with metrics restored without a drag notification.
  ///
  /// PageStorage and platform state restoration can place a ScrollPosition at
  /// a non-zero offset during layout. Compose derives its height offset from
  /// nested-scroll state, while Flutter emits only a metrics notification for
  /// this restoration path; consuming it prevents an expanded title over a
  /// deeply restored list.
  void syncMetrics(ScrollMetrics metrics) {
    if (metrics.axis != Axis.vertical) return;
    _cancelSettle();
    // PageStorage and programmatic jumps can bypass handleNotification. A
    // shared SmallTopAppBar still pins heightOffset to zero on that path while
    // retaining the absolute content position for later large-bar recovery.
    final nextFraction = _pinnedBySmallTopAppBar
        ? 0.0
        : (metrics.pixels / _collapseExtent).clamp(0.0, 1.0);
    final nextOffset = -math.max(0.0, metrics.pixels);
    if ((nextFraction - _collapseFraction).abs() < .0001 &&
        (nextOffset - _contentOffset).abs() < .0001) {
      return;
    }
    _collapseFraction = nextFraction;
    _contentOffset = nextOffset;
    _notifyStateAndListeners();
  }

  /// Restores from an attached ScrollPosition unless the owner already set an
  /// authoritative top-bar state. Compose saves the two states separately;
  /// attaching a list must not overwrite an explicitly restored bar fraction.
  void _restoreFromMetrics(ScrollMetrics metrics) {
    if (_restorationConsumed) return;
    _restorationConsumed = true;
    if (_hasExplicitCollapseState) return;
    syncMetrics(metrics);
  }

  /// Keeps restored scroll metrics tied to the measured large-title column.
  ///
  /// Compose sets `heightOffsetLimit` to the height of that column, rather
  /// than to the visible difference between the expanded and collapsed
  /// surfaces. The Flutter widget supplies the matching source-calibrated
  /// extent because a scroll behavior can be created before its bar exists.
  void _attachCollapseExtent(double value) {
    if (!value.isFinite || value <= 0) return;
    final extentChanged = (value - _collapseExtent).abs() >= .0001;
    if (_smallTopBarPinScheduled) {
      // A large bar replaced the compact bar before its SideEffect frame.
      // Invalidate that deferred pin so it cannot overwrite the new owner.
      _topBarModeGeneration++;
      _smallTopBarPinScheduled = false;
    }
    _collapseExtent = value;
    if (!_pinnedBySmallTopAppBar) {
      if (extentChanged) _scheduleListenerNotification();
      return;
    }
    // Current TopAppBar.kt restores a shared state to the collapsed endpoint
    // whenever content moved upward while the compact bar kept height at zero.
    _collapseFraction = _contentOffset < 0 ? 1 : 0;
    _pinnedBySmallTopAppBar = false;
    _hasExplicitCollapseState = true;
    _scheduleListenerNotification();
  }

  /// Defers the source SmallTopAppBar SideEffect until this frame completes.
  void _schedulePinForSmallTopAppBar() {
    if ((_pinnedBySmallTopAppBar && _collapseFraction == 0) ||
        _smallTopBarPinScheduled) {
      return;
    }
    _smallTopBarPinScheduled = true;
    final generation = ++_topBarModeGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || generation != _topBarModeGeneration) return;
      _smallTopBarPinScheduled = false;
      if (_pinnedBySmallTopAppBar && _collapseFraction == 0) return;
      _cancelSettle();
      _pinnedBySmallTopAppBar = true;
      _collapseFraction = 0;
      _hasExplicitCollapseState = true;
      _notifyStateAndListeners();
    });
  }

  /// Notifies external observers after a build-time large-bar restoration.
  void _scheduleListenerNotification() {
    if (_listenerNotificationScheduled) return;
    _listenerNotificationScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;
      _listenerNotificationScheduled = false;
      _notifyStateAndListeners();
    });
  }

  /// Consumes the vertical scroll notifications emitted below the scaffold.
  bool handleNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (_pinnedBySmallTopAppBar) {
      // A compact bar keeps heightOffset at zero, but the same connection must
      // retain contentOffset so a later large bar knows whether its compact
      // title should be visible. It never corrects the child scroll distance.
      if (notification is ScrollStartNotification) {
        _cancelSettle();
      } else if (notification is ScrollUpdateNotification ||
          notification is OverscrollNotification) {
        final nextOffset = -math.max(0.0, notification.metrics.pixels);
        _setContentOffset(nextOffset);
      }
      return false;
    }
    if (notification is ScrollStartNotification) {
      // A fresh pointer sequence owns the state immediately. Compose cancels
      // the running Animatable before applying nested-scroll deltas; retaining
      // a timer here made old settle frames fight a reversed gesture.
      _cancelSettle();
    } else if (notification case ScrollUpdateNotification(
      :final dragDetails,
      :final scrollDelta,
    )) {
      final delta = scrollDelta;
      if (delta == null) return false;
      if (dragDetails == null) {
        // State restoration and explicit jumps have no pointer delta to return
        // through correctBy. Synchronize both saved channels from the absolute
        // position, matching the package's established restoration contract.
        syncMetrics(notification.metrics);
        return false;
      }
      if (delta > 0) {
        // Compose consumes upward movement in onPreScroll until the measured
        // large-title column is fully collapsed. Its implementation returns
        // the complete available Y delta whenever heightOffset changed, even
        // when that single delta crosses the collapse limit. Flutter's
        // ScrollPosition has already accepted the delta when this notification
        // arrives, so return that complete update while the bar is changing.
        final consumed = _consumeCollapse(delta);
        if (consumed > 0) {
          final scrollable = notification.context == null
              ? null
              : Scrollable.maybeOf(notification.context!);
          scrollable?.position.correctBy(-delta);
        }
        if (consumed == 0) {
          _setContentOffset(_contentOffset - delta);
        }
      } else if (delta < 0) {
        // Downward movement belongs to the child until it reaches its leading
        // edge. Only the subsequent negative OverscrollNotification expands
        // the bar, mirroring upstream onPostScroll(available.y > 0).
        _setContentOffset(math.min(0.0, _contentOffset - delta));
      }
    } else if (notification case OverscrollNotification(
      :final dragDetails,
      :final overscroll,
    )) {
      if (dragDetails == null) {
        syncMetrics(notification.metrics);
        return false;
      }
      if (overscroll < 0) {
        _consumeExpand(-overscroll);
        _setContentOffset(0);
      } else if (overscroll > 0) {
        // A short list can reach its trailing boundary before the title is
        // collapsed. Upstream pre-scroll still gives that distance to the bar.
        _consumeCollapse(overscroll);
      }
    } else if (notification is ScrollEndNotification) {
      _settle(notification.dragDetails?.primaryVelocity ?? 0);
    }
    return false;
  }

  double _consumeCollapse(double amount) {
    if (amount <= 0 || _collapseFraction >= 1) return 0;
    final current = _collapseFraction * _collapseExtent;
    final consumed = math.min(amount, _collapseExtent - current);
    _setCollapseFractionPreservingContent(
      (current + consumed) / _collapseExtent,
    );
    return consumed;
  }

  double _consumeExpand(double amount) {
    if (amount <= 0 || _collapseFraction <= 0) return 0;
    final current = _collapseFraction * _collapseExtent;
    final consumed = math.min(amount, current);
    _setCollapseFractionPreservingContent(
      (current - consumed) / _collapseExtent,
    );
    return consumed;
  }

  void _setCollapseFractionPreservingContent(double value) {
    _hasExplicitCollapseState = true;
    final next = value.clamp(0.0, 1.0);
    if ((next - _collapseFraction).abs() < .0001) return;
    _collapseFraction = next;
    _notifyStateAndListeners();
  }

  /// Commits a simulation endpoint without the live-frame de-duplication gap.
  void _setCollapseFractionExact(double value) {
    _hasExplicitCollapseState = true;
    final next = value.clamp(0.0, 1.0);
    if (next == _collapseFraction) return;
    _collapseFraction = next;
    _notifyStateAndListeners();
  }

  void _setContentOffset(double value) {
    if ((value - _contentOffset).abs() < .0001) return;
    _contentOffset = value;
    _notifyStateAndListeners();
  }

  /// Applies the active host's accessibility motion preference.
  ///
  /// A behavior may outlive one concrete TopAppBar, so the widget supplies
  /// this context-dependent signal whenever it builds. An active settle is
  /// stopped immediately and its stable endpoint is committed after the
  /// current frame to avoid notifying an AnimatedBuilder during its build.
  void _setReduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    if (!value || _settleSimulation == null) return;
    final target = _collapseFraction < .5 ? 0.0 : 1.0;
    _cancelSettle();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed || !_reduceMotion) return;
      _setCollapseFractionPreservingContent(target);
    });
  }

  /// Continues a released fling with Android's spline decay before snapping.
  ///
  /// `rememberSplineBasedDecay()` uses Android's platform spline. Flutter's
  /// [ClampingScrollSimulation] is derived from the same SplineOverScroller
  /// equations, so the height-offset channel can keep the source release
  /// velocity without inventing a cubic approximation.
  void _settle(double velocity) {
    _cancelSettle();
    // TopAppBar.kt deliberately skips values below one percent as well as the
    // exactly collapsed endpoint to avoid float-noise settle animations.
    if (_collapseFraction < .01 || _collapseFraction == 1) return;
    if (_reduceMotion || snapDuration == Duration.zero) {
      _setCollapseFractionPreservingContent(_collapseFraction < .5 ? 0 : 1);
      return;
    }
    final height = -_collapseFraction * _collapseExtent;
    if (velocity.abs() > 1) {
      _startSettleSimulation(
        ClampingScrollSimulation(position: height, velocity: velocity),
        isDecay: true,
      );
    } else {
      _startSnapFromHeight(height);
    }
  }

  /// Starts the exact default `spring(stiffness = 2500f)` snap channel.
  void _startSnapFromHeight(double height) {
    final targetFraction = _collapseFraction < .5 ? 0.0 : 1.0;
    final targetHeight = -targetFraction * _collapseExtent;
    if ((height - targetHeight).abs() < .01) {
      _setCollapseFractionExact(targetFraction);
      _cancelSettle();
      return;
    }
    _settleTargetHeight = targetHeight;
    _startSettleSimulation(
      SpringSimulation(
        SpringDescription.withDampingRatio(mass: 1, stiffness: 2500, ratio: 1),
        height,
        targetHeight,
        0,
        tolerance: const Tolerance(distance: .01, velocity: .01),
      ),
      isDecay: false,
    );
  }

  /// Installs one frame-synchronized simulation without recreating the ticker.
  void _startSettleSimulation(Simulation simulation, {required bool isDecay}) {
    _settleSimulation = simulation;
    _settleIsDecay = isDecay;
    _settleSimulationStart = null;
    if (!_settleTicker.isActive) _settleTicker.start();
  }

  /// Samples decay and spring state from Flutter's frame clock.
  void _tickSettle(Duration elapsed) {
    final simulation = _settleSimulation;
    if (simulation == null) return;
    _settleSimulationStart ??= elapsed;
    final stageElapsed = elapsed - _settleSimulationStart!;
    final seconds =
        stageElapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final rawHeight = simulation.x(seconds);
    final height = rawHeight.clamp(-_collapseExtent, 0.0);
    _setCollapseFractionPreservingContent(-height / _collapseExtent);

    if (_settleIsDecay) {
      // Compose stops its decay as soon as more than half a pixel is left
      // unconsumed at either height boundary, then applies the snap only when
      // the bar is still between its endpoints.
      final hitBoundary = (rawHeight - height).abs() > .5;
      if (hitBoundary || simulation.isDone(seconds)) {
        if (_collapseFraction > .01 && _collapseFraction < 1) {
          _startSnapFromHeight(height);
          _settleSimulationStart = elapsed;
        } else {
          _cancelSettle();
        }
      }
      return;
    }

    if (simulation.isDone(seconds) || stageElapsed >= snapDuration) {
      _setCollapseFractionExact(
        (-_settleTargetHeight / _collapseExtent).clamp(0.0, 1.0),
      );
      _cancelSettle();
    }
  }

  /// Stops an in-flight settle without changing its last sampled frame.
  void _cancelSettle() {
    _settleSimulation = null;
    _settleSimulationStart = null;
    if (_settleTicker.isActive) _settleTicker.stop();
  }

  void _handleHoistedStateChange() {
    if (_syncingHoistedState || _disposed) return;
    final sourceLimit = state.heightOffsetLimit;
    if (sourceLimit.isFinite && sourceLimit < 0 && sourceLimit > -1000000) {
      _collapseExtent = -sourceLimit;
    }
    final nextFraction = state.collapsedFraction;
    final nextContent = state.contentOffset;
    if ((nextFraction - _collapseFraction).abs() < .0001 &&
        (nextContent - _contentOffset).abs() < .0001) {
      return;
    }
    _cancelSettle();
    _hasExplicitCollapseState = true;
    _collapseFraction = nextFraction;
    _contentOffset = nextContent;
    notifyListeners();
  }

  void _syncHoistedState() {
    if (_syncingHoistedState) return;
    _syncingHoistedState = true;
    state._replace(
      heightOffsetLimit: _pinnedBySmallTopAppBar ? 0 : -_collapseExtent,
      heightOffset: _pinnedBySmallTopAppBar
          ? 0
          : -_collapseFraction * _collapseExtent,
      contentOffset: _contentOffset,
    );
    _syncingHoistedState = false;
  }

  void _notifyStateAndListeners() {
    _syncHoistedState();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelSettle();
    state.removeListener(_handleHoistedStateChange);
    _settleTicker.dispose();
    super.dispose();
  }
}

/// MIUIX top application bar with compact and scroll-collapsing large variants.
class MiuixTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Creates a MIUIX top application bar.
  const MiuixTopAppBar({
    super.key,
    required this.title,
    this.largeTitle,
    this.subtitle,
    this.leading,
    this.actions,
    this.large = true,
    this.scrollBehavior,
    this.collapseFraction,
    this.color,
    this.glass = true,
    this.blurStyle = MiuixTopAppBarBlurStyle.gradient,
    this.actionStyle = MiuixTopAppBarActionStyle.glass,
    this.titleColor,
    this.largeTitleColor,
    this.subtitleColor,
    this.defaultWindowInsetsPadding = true,
    this.titlePadding = MiuixTopAppBarDefaults.titlePadding,
    this.navigationIconPadding = MiuixTopAppBarDefaults.navigationIconPadding,
    this.actionIconPadding = MiuixTopAppBarDefaults.actionIconPadding,
    this.expandedHeight,
    this.collapsedTitleAreaHeight,
    this.bottomContent,
    this.bottomContentHeight = 0,
    this.bottomContentExpandedTopPadding = 0,
  });

  /// Compact title and fallback large title.
  final String title;

  /// Optional text used only by the expanded large-title presentation.
  final String? largeTitle;

  /// Optional supporting title shown below the main title.
  final String? subtitle;

  /// Navigation icon slot.
  final Widget? leading;

  /// Action icon slots.
  final List<Widget>? actions;

  /// Whether this is the source component's collapsible large variant.
  final bool large;

  /// Optional controller used by a large bar to consume body scroll.
  final MiuixTopAppBarScrollBehavior? scrollBehavior;

  /// Optional directly supplied collapse fraction for sliver integration.
  ///
  /// Ordinary scaffold pages should keep using [scrollBehavior]. A
  /// [MiuixSliverTopAppBar] receives its shrink offset during sliver layout,
  /// so passing that normalized value directly avoids notifying a controller
  /// while the render tree is being built.
  final double? collapseFraction;

  /// Background color; defaults to the MIUIX surface color.
  final Color? color;

  /// Whether the bar samples and blurs page content behind its surface.
  final bool glass;

  /// Selects the source uniform or scroll-revealed progressive blur pipeline.
  ///
  /// [MiuixTopAppBarBlurStyle.gaussian] matches `textureBlur` in the sample's
  /// ordinary branch: 25dp blur and an 80% surface blend over the full bar.
  /// [MiuixTopAppBarBlurStyle.progressive] matches its second branch: a 10dp
  /// top-edge blur, a 30% surface blend, and scroll-controlled opacity.
  ///
  /// [MiuixTopAppBarBlurStyle.gradient] is the HyperOS 4 default: it keeps a
  /// real, persistent backdrop sample and smoothly reduces its semantic tint
  /// toward the content edge. Applications can still select the uniform [gaussian] or
  /// older scroll-revealed [progressive] treatment explicitly.
  final MiuixTopAppBarBlurStyle blurStyle;

  /// Shape and material shared by the compact action slots.
  ///
  /// The group keeps the existing 40dp icon-center cadence and 48dp semantic
  /// targets. Every action resolves to its own 48dp circle, including when
  /// several actions are present. These values are project-derived
  /// from current Xiaomi application captures rather than official tokens.
  /// The default is [MiuixTopAppBarActionStyle.glass]; choose
  /// [MiuixTopAppBarActionStyle.plain] explicitly for legacy icon-only pages.
  final MiuixTopAppBarActionStyle actionStyle;

  /// Compact title color.
  final Color? titleColor;

  /// Expanded title color.
  final Color? largeTitleColor;

  /// Subtitle color.
  final Color? subtitleColor;

  /// Whether the bar applies the source's optional horizontal window insets.
  ///
  /// Upstream always applies the top `systemBars` inset. This flag controls
  /// only the additional horizontal display-cutout and navigation-bar insets.
  final bool defaultWindowInsetsPadding;

  /// Horizontal title inset from the original component.
  final double titlePadding;

  /// Start inset for the navigation icon.
  final double navigationIconPadding;

  /// End inset for action icons.
  final double actionIconPadding;

  /// Optional explicit expanded height for unusually tall title content.
  final double? expandedHeight;

  /// Optional large-bar collapsed title-area height.
  ///
  /// Sliver integrations use this to keep their public minimum extent and the
  /// visible title surface identical. A null value retains source geometry.
  final double? collapsedTitleAreaHeight;

  /// Optional source-compatible content placed below the title area.
  final Widget? bottomContent;

  /// Reserved height for [bottomContent].
  final double bottomContentHeight;

  /// Extra space above [bottomContent] while a large bar is expanded.
  ///
  /// The source icon catalogue uses this layout-time inset for its search
  /// capsule. It shrinks linearly to zero with the large-title collapse
  /// fraction and is always zero for a compact bar.
  ///
  /// This value is intentionally separate from [bottomContentHeight]. Compose
  /// measures the inset as its own layout node, rounds it to a physical pixel,
  /// then constrains and places the bottom content below it. Combining both
  /// values before rounding would put the search capsule one pixel away from
  /// the source on common fractional Android densities such as 2.625.
  ///
  /// The inset changes only the visible bar measurement. It does not enlarge
  /// the title column consumed by [MiuixTopAppBarScrollBehavior], so the title
  /// keeps the source 38dp collapse extent while the optional bottom content
  /// follows that already normalized fraction. A page that initially pads its
  /// scrollable below an overlaid bar should include the fully expanded value
  /// in that initial padding, as the source Scaffold sample does.
  final double bottomContentExpandedTopPadding;

  static const double collapsedHeight = MiuixTopAppBarDefaults.collapsedHeight;
  static const double smallTopAppBarCenterHeight =
      MiuixTopAppBarDefaults.smallTopAppBarCenterHeight;
  static const double largeTitleBottomPadding =
      MiuixTopAppBarDefaults.largeTitleBottomPadding;
  static const double subtitleBottomPadding =
      MiuixTopAppBarDefaults.subtitleBottomPadding;
  static const double titleMaxWidthFraction = .9;
  static const double collapsedLargeHeight = 56;
  static const double collapsedSubtitleHeight = 62;

  bool get _hasSubtitle => subtitle?.isNotEmpty == true;

  double get _expandedHeight {
    // PreferredSize is read before build and cannot rely on a later layout
    // clamp. Keep this getter as the single source of truth for both phases.
    final fallback = _hasSubtitle ? 114.0 : 94.0;
    final requested = expandedHeight;
    return requested != null && requested.isFinite && requested > 0
        ? requested
        : fallback;
  }

  double get _collapsedTitleAreaHeight {
    // The collapsed height is also used as the interpolation endpoint and
    // must remain positive even when an external editor clears its field.
    // Invalid overrides fall through to the subtitle-aware source defaults.
    if (collapsedTitleAreaHeight case final value?) {
      if (value.isFinite && value > 0) return value;
    }
    if (!large) {
      return _hasSubtitle ? collapsedSubtitleHeight : collapsedHeight;
    }
    return _hasSubtitle ? collapsedSubtitleHeight : collapsedLargeHeight;
  }

  double get _collapseExtent {
    if (collapsedTitleAreaHeight case final value?) {
      if (value.isFinite && value > 0) {
        return math.max(1, _expandedHeight - value);
      }
    }
    // TopAppBar.kt stores the height of the 32sp large-title Column as its
    // nested-scroll limit. Subtracting the 52dp top region and the source
    // bottom padding from the calibrated expanded height reproduces 38dp for
    // a title and 54dp for a title plus 14sp subtitle.
    final padding = _hasSubtitle
        ? subtitleBottomPadding
        : largeTitleBottomPadding;
    return math.max(1, _expandedHeight - collapsedHeight - padding);
  }

  double get _fraction {
    // Scroll controllers publish a finite fraction, but the direct sliver API
    // is public and can receive transient calculation errors from clients.
    // Treat an unusable sample as expanded rather than poisoning every lerp.
    if (!large) return 1;
    final requested = collapseFraction ?? scrollBehavior?.collapseFraction ?? 0;
    return requested.isFinite ? requested.clamp(0.0, 1.0) : 0.0;
  }

  double get _nominalTitleAreaHeight => large
      ? ui.lerpDouble(_expandedHeight, _collapsedTitleAreaHeight, _fraction)!
      : _collapsedTitleAreaHeight;

  double _sourceCollapsedTitleAreaHeight(BuildContext context) {
    if (collapsedTitleAreaHeight case final value?) {
      if (value.isFinite && value > 0) return value;
    }
    if (!large || _hasSubtitle) {
      return _collapsedTitleAreaHeight;
    }
    final density = MediaQuery.devicePixelRatioOf(context);
    // TopAppBar.kt does not measure the title-only collapsed surface as one
    // 56dp box. Its Layout first rounds the 52dp compact row to Int pixels,
    // then rounds and appends the independent 4dp large-title bottom padding.
    // At 420dpi that is 137px + 11px, while a combined 56dp transform is only
    // 147px. Keep the source measurement order at fractional Android density.
    return _miuixRoundLogicalDimension(collapsedHeight, density) +
        _miuixRoundLogicalDimension(largeTitleBottomPadding, density);
  }

  double _sourceTitleAreaHeight(BuildContext context) {
    final collapsed = _sourceCollapsedTitleAreaHeight(context);
    return large
        ? ui.lerpDouble(_expandedHeight, collapsed, _fraction)!
        : collapsed;
  }

  double _sourceBottomContentTopPadding(BuildContext context) {
    // Padding is rounded independently because Compose measures this modifier
    // before it appends the child height at fractional Android densities.
    // Reject infinity before multiplication: infinity times a collapsed zero
    // is NaN and would otherwise escape even a later non-negative clamp.
    if (bottomContent == null ||
        !bottomContentExpandedTopPadding.isFinite ||
        bottomContentExpandedTopPadding <= 0) {
      return 0;
    }
    final density = MediaQuery.devicePixelRatioOf(context);
    final expandedPadding = large
        ? bottomContentExpandedTopPadding * (1 - _fraction)
        : 0.0;
    // Compose's custom layout rounds this inset before it measures and places
    // the search capsule, rather than rounding the accumulated bar height.
    // Keeping the rounding here also means the bar's PreferredSize and child
    // placement use the same resolved value during every animation frame.
    return _miuixRoundLogicalDimension(expandedPadding, density);
  }

  // Bottom slots participate in both Scaffold reservation and child layout.
  // Normalize before either path adds the value so NaN cannot make the public
  // PreferredSize diverge from the rendered glass surface.
  double get _safeBottomContentHeight =>
      bottomContentHeight.isFinite ? math.max(0.0, bottomContentHeight) : 0.0;

  double get _safeExpandedBottomPadding =>
      bottomContentExpandedTopPadding.isFinite
      ? math.max(0.0, bottomContentExpandedTopPadding)
      : 0.0;

  double _sourceBottomContentHeight(BuildContext context) =>
      bottomContent == null
      ? 0
      : _safeBottomContentHeight + _sourceBottomContentTopPadding(context);

  /// Returns the source measurement for the current Flutter view.
  ///
  /// [PreferredSizeWidget.preferredSize] cannot read a [BuildContext], so its
  /// public value remains the density-independent nominal dp contract. MIUIX
  /// layout needs one additional step at fractional Android densities:
  ///
  /// - resolve the density belonging to this view rather than the first view;
  /// - round the compact row and trailing padding independently;
  /// - interpolate toward that resolved collapsed target;
  /// - append caller-supplied bottom content after the title measurement.
  ///
  /// [MiuixScaffold] asks for this size before constructing Flutter Scaffold's
  /// tight app-bar constraint. That avoids reading global dispatcher state,
  /// remains correct in multi-window applications, and prevents the final
  /// physical pixel from being clipped even though the child measures it.
  Size _sourcePreferredSize(BuildContext context) => Size.fromHeight(
    _preparedSourceTitleAreaHeight(context) +
        _sourceBottomContentHeight(context),
  );

  /// Resolves shared compact-to-large state before Scaffold tightens height.
  double _preparedSourceTitleAreaHeight(BuildContext context) {
    if (large) scrollBehavior?._attachCollapseExtent(_collapseExtent);
    return _sourceTitleAreaHeight(context);
  }

  @override
  Size get preferredSize {
    // Flutter Scaffold reads this before building its appBar child. Restore a
    // shared state here as well as in the context-aware MiuixScaffold path so
    // the first large frame receives the correct tight height.
    if (large) scrollBehavior?._attachCollapseExtent(_collapseExtent);
    return Size.fromHeight(
      _nominalTitleAreaHeight +
          (bottomContent == null
              ? 0
              : _safeBottomContentHeight +
                    (large ? _safeExpandedBottomPadding * (1 - _fraction) : 0)),
    );
  }

  @override
  Widget build(BuildContext context) {
    scrollBehavior?._setReduceMotion(MediaQuery.disableAnimationsOf(context));
    if (large) {
      scrollBehavior?._attachCollapseExtent(_collapseExtent);
    } else {
      scrollBehavior?._schedulePinForSmallTopAppBar();
    }
    final bar = scrollBehavior == null
        ? _buildBar(
            context,
            includeHorizontalSafeArea: defaultWindowInsetsPadding,
          )
        : AnimatedBuilder(
            animation: scrollBehavior!,
            builder: (context, _) => _buildBar(
              context,
              includeHorizontalSafeArea: defaultWindowInsetsPadding,
            ),
          );
    return bar;
  }

  Widget _buildBar(
    BuildContext context, {
    required bool includeHorizontalSafeArea,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hyperOs4 = MiuixTheme.of(context).hyperOs4;
    final fraction = _fraction;
    final height = _sourceTitleAreaHeight(context);
    final supportingText = _hasSubtitle ? subtitle : null;
    final compactVisible = !large || fraction * 3 >= 1;
    final bottomContentTopPadding = _sourceBottomContentTopPadding(context);
    final safeTitlePadding = titlePadding.isFinite
        ? math.max(0.0, titlePadding)
        : MiuixTopAppBarDefaults.titlePadding;
    final safeNavigationIconPadding = navigationIconPadding.isFinite
        ? math.max(0.0, navigationIconPadding)
        : MiuixTopAppBarDefaults.navigationIconPadding;
    final safeActionIconPadding = actionIconPadding.isFinite
        ? math.max(0.0, actionIconPadding)
        : MiuixTopAppBarDefaults.actionIconPadding;
    // Horizontal paddings do not change PreferredSize, yet they still enter
    // Positioned and compact action layout. Normalize them close to both uses
    // so the title and its shaped action group share one finite coordinate
    // system in the opaque, Gaussian, and progressive material branches.
    final largeOpacity = large ? (1 - fraction * 3).clamp(0.0, 1.0) : 0.0;
    final compactStyle = theme.textTheme.titleLarge?.copyWith(
      color: titleColor ?? scheme.onSurface,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );
    final expandedStyle = theme.textTheme.displaySmall?.copyWith(
      color: largeTitleColor ?? titleColor ?? scheme.onSurface,
      fontSize: 32,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );
    final supportingStyle = theme.textTheme.bodyMedium?.copyWith(
      color: subtitleColor ?? scheme.onSurfaceVariant,
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );

    final titleArea = SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          if (large && largeOpacity > 0)
            PositionedDirectional(
              start: safeTitlePadding,
              end: safeTitlePadding,
              bottom: supportingText == null
                  ? largeTitleBottomPadding
                  : subtitleBottomPadding,
              child: Opacity(
                opacity: largeOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      largeTitle ?? title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: expandedStyle,
                    ),
                    if (supportingText case final text?)
                      Text(
                        text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: supportingStyle,
                      ),
                  ],
                ),
              ),
            ),
          Positioned.fill(
            child: _MiuixCompactTopAppBarContent(
              title: title,
              subtitle: supportingText,
              leading: leading,
              actions: actions,
              centerHeight: large
                  ? collapsedHeight
                  : smallTopAppBarCenterHeight,
              titleStyle: compactStyle,
              subtitleStyle: supportingStyle,
              titlePadding: safeTitlePadding,
              navigationIconPadding: safeNavigationIconPadding,
              actionIconPadding: safeActionIconPadding,
              actionStyle: actionStyle,
              includeTopSafeArea: true,
              animateTitle: large,
              titleVisible: compactVisible,
            ),
          ),
        ],
      ),
    );

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        titleArea,
        if (bottomContent != null)
          SizedBox(
            height: _safeBottomContentHeight + bottomContentTopPadding,
            child: Padding(
              padding: EdgeInsets.only(top: bottomContentTopPadding),
              child: bottomContent,
            ),
          ),
      ],
    );
    // Compose applies its background before all window-inset modifiers. Its
    // top system-bar inset is unconditional; `defaultWindowInsetsPadding`
    // gates only the horizontal display-cutout/navigation-bar modifiers.
    // Keeping SafeArea inside the surface reproduces that paint ordering for
    // opaque and glass variants while retaining the status inset on Android
    // tablets and landscape layouts whose adaptive bar disables side insets.
    content = SafeArea(
      left: includeHorizontalSafeArea,
      right: includeHorizontalSafeArea,
      bottom: false,
      child: content,
    );
    if (glass) {
      if (blurStyle != MiuixTopAppBarBlurStyle.gaussian) {
        final scrollReveal = scrollBehavior != null
            ? (-scrollBehavior!.contentOffset / 48).clamp(0.0, 1.0)
            : collapseFraction != null
            ? (collapseFraction! * _collapseExtent / 48).clamp(0.0, 1.0)
            : 1.0;
        final persistent = blurStyle == MiuixTopAppBarBlurStyle.gradient;
        return _MiuixProgressiveTopBarGlass(
          opacity: persistent ? 1 : scrollReveal,
          blur: persistent
              ? hyperOs4.appBarBlur
              : hyperOs4.progressiveAppBarBlur,
          tintOpacity: persistent
              ? hyperOs4.appBarTintOpacity
              : hyperOs4.progressiveAppBarTintOpacity,
          color: color ?? scheme.surface,
          child: content,
        );
      }
      return MiuixGlass(
        key: const ValueKey('top-app-bar-glass'),
        // These are centralized project-calibrated HyperOS 4 values. Global
        // intensity adjusts the complete material while preserving contrast.
        blur: hyperOs4.appBarBlur,
        opacity: hyperOs4.appBarTintOpacity,
        color: color ?? scheme.surface,
        radius: 0,
        padding: EdgeInsets.zero,
        // A page app bar is a flush material plane rather than a floating
        // capsule. Painting the navigation recipe's complete rectangular
        // optical edge made its bottom stroke read as a divider below the
        // title. Keep the same calibrated blur/tint response, but let the
        // scrolling content transition provide the boundary instead.
        showSpecular: false,
        optics: MiuixGlassOptics.navigation,
        // A Scaffold paints its app bar after the body. During route motion
        // both live in one transition saveLayer, where srcOver can composite
        // the sampled backdrop twice and erase the body below the bar.
        blendMode: BlendMode.src,
        child: content,
      );
    }
    // Keep the opaque surface addressable in geometry tests just like the
    // glass branch above.  Both branches own the same overlay bounds.
    return ColoredBox(
      key: const ValueKey('top-app-bar-surface'),
      color: color ?? scheme.surface,
      child: content,
    );
  }
}

/// Compact top app bar adapter matching MIUIX `SmallTopAppBar`.
class MiuixSmallTopAppBar extends MiuixTopAppBar {
  /// Creates the compact 52dp source variant.
  const MiuixSmallTopAppBar({
    super.key,
    required super.title,
    super.subtitle,
    super.leading,
    super.actions,
    super.scrollBehavior,
    super.color,
    super.glass,
    super.blurStyle,
    super.titleColor,
    super.subtitleColor,
    super.defaultWindowInsetsPadding,
    super.titlePadding,
    super.navigationIconPadding,
    super.actionIconPadding,
    super.bottomContent,
    super.bottomContentHeight,
    super.bottomContentExpandedTopPadding,
  }) : super(large: false);
}

/// Continuous gradient-glass surface used by HyperOS top bars.
///
/// Android Impeller can lose the real page backdrop when a [ShaderMask] or an
/// opacity saveLayer wraps [BackdropFilter]. The bar therefore keeps one
/// directly composited engine blur and paints a smooth three-stop semantic
/// tint gradient inside it. This produces the intended top-to-bottom material
/// fade without transparent title regions or horizontal slice seams.
///
/// Title glyphs, navigation icons, search content, and semantics remain the
/// second stack layer, so none of them are faded by the material gradient.
///
/// [opacity] represents the independent scroll reveal from `BlurredBar.kt`.
/// It scales the direct blur sigma and authored tint colors instead of adding
/// an outer [Opacity]. A zero-offset explicit progressive bar therefore has no
/// saveLayer, while a 48dp upward scroll exposes the complete profile. The
/// default gradient style passes one and stays visible continuously.
///
/// The surface has radius zero because the source passes `RectangleShape` for
/// page bars. Dedicated liquid-glass components retain their separate rounded
/// shapes. Page bars deliberately omit the floating-glass optical outline so
/// the lower edge does not read as a divider beneath the title.
class _MiuixProgressiveTopBarGlass extends StatelessWidget {
  const _MiuixProgressiveTopBarGlass({
    required this.opacity,
    required this.blur,
    required this.tintOpacity,
    required this.color,
    required this.child,
  });

  final double opacity;
  final double blur;
  final double tintOpacity;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    if (!theme.enableGlass) {
      return ColoredBox(color: color, child: child);
    }
    final reveal = opacity.isFinite ? opacity.clamp(0.0, 1.0) : 0.0;
    final optics = MiuixGlassOptics.navigation;
    final effectiveBlur = optics.resolveBlur(blur, theme.glassIntensity);
    final effectiveTint = optics.resolveOpacity(
      tintOpacity,
      theme.glassIntensity,
    );
    return Stack(
      key: const ValueKey('top-app-bar-progressive-glass'),
      fit: StackFit.passthrough,
      children: [
        if (reveal > 0)
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                key: const ValueKey('top-app-bar-gradient-filter'),
                blendMode: BlendMode.srcOver,
                filter: ui.ImageFilter.blur(
                  sigmaX: effectiveBlur * reveal,
                  sigmaY: effectiveBlur * reveal,
                ),
                child: DecoratedBox(
                  key: const ValueKey('top-app-bar-gradient-tint'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(
                          alpha: color.a * effectiveTint * reveal,
                        ),
                        color.withValues(
                          alpha: color.a * effectiveTint * .58 * reveal,
                        ),
                        color.withValues(
                          alpha: color.a * effectiveTint * .22 * reveal,
                        ),
                      ],
                      stops: const [0, .56, 1],
                    ),
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

/// Reproduces the independent compact-title animation from `TopAppBar.kt`.
///
/// Compose starts this transition only after the collapse fraction crosses
/// one third. The title fades in while moving upward by 20 physical pixels;
/// hiding uses the same critically damped motion with a faster response.
class _MiuixCompactTitleTransition extends StatelessWidget {
  const _MiuixCompactTitleTransition({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // `graphicsLayer.translationY = 20f` is a raw-pixel value in Compose.
    // Dividing by Flutter's device-pixel ratio preserves that exact travel on
    // Android while naturally remaining 20 logical pixels at density 1.
    final travel = 20 / MediaQuery.devicePixelRatioOf(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final authoredDuration = visible
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 150);
    final duration = reduceMotion ? Duration.zero : authoredDuration;
    final response = visible ? .3 : .15;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('top-app-bar-compact-title-animation'),
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: duration,
      // MIUIX uses folmeSpring(damping = 1), a critically damped spring with
      // response 0.3s when showing and 0.15s when hiding.
      curve: reduceMotion
          ? Curves.linear
          : _MiuixCriticallyDampedCurve(
              responseSeconds: response,
              durationSeconds:
                  authoredDuration.inMicroseconds /
                  Duration.microsecondsPerSecond,
            ),
      builder: (context, progress, child) {
        return Transform.translate(
          key: const ValueKey('top-app-bar-compact-title-translation'),
          offset: Offset(0, travel * (1 - progress)),
          child: Opacity(
            key: const ValueKey('top-app-bar-compact-title-opacity'),
            opacity: progress,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Unit-interval form of a zero-velocity critically damped spring response.
///
/// MIUIX computes stiffness as `(2π / response)²`. Its corresponding step
/// response is `1 - (1 + ωt)e^(-ωt)`. Normalization makes the Flutter curve
/// finish exactly at one without altering its source-shaped acceleration.
class _MiuixCriticallyDampedCurve extends Curve {
  const _MiuixCriticallyDampedCurve({
    required this.responseSeconds,
    required this.durationSeconds,
  });

  final double responseSeconds;
  final double durationSeconds;

  double _response(double seconds) {
    final omega = 2 * math.pi / responseSeconds;
    return 1 - (1 + omega * seconds) * math.exp(-omega * seconds);
  }

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    final terminal = _response(durationSeconds);
    if (terminal <= 0) return t;
    return (_response(t * durationSeconds) / terminal).clamp(0.0, 1.0);
  }
}

class _MiuixTopBarActions extends StatelessWidget {
  const _MiuixTopBarActions({
    required this.children,
    required this.targetOffset,
    required this.targetInsets,
    required this.style,
  });

  final List<Widget> children;
  final Offset targetOffset;
  final EdgeInsets targetInsets;
  final MiuixTopAppBarActionStyle style;

  static const double _circleSize = 48;
  static const double _circleGap = 8;

  static double widthFor(int count, MiuixTopAppBarActionStyle style) {
    if (count <= 0) return 0;
    return switch (style) {
      MiuixTopAppBarActionStyle.glass =>
        count * _circleSize + (count - 1) * _circleGap,
      MiuixTopAppBarActionStyle.plain => count * 40 + 8,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Explicit plain/source actions retain Compose's overlapping 40dp center
    // cadence. HyperOS glass actions use the independent circular branch above.
    if (style == MiuixTopAppBarActionStyle.glass) {
      final scheme = Theme.of(context).colorScheme;
      return SizedBox(
        key: const ValueKey('top-app-bar-glass-actions'),
        width: widthFor(children.length, style),
        height: _circleSize,
        child: Row(
          spacing: _circleGap,
          children: [
            for (var index = 0; index < children.length; index++)
              SizedBox.square(
                dimension: _circleSize,
                child: MiuixGlass(
                  key: ValueKey('top-app-bar-glass-action-$index'),
                  blur: MiuixTheme.of(context).hyperOs4.appBarBlur,
                  opacity: MiuixTheme.of(context).hyperOs4.appBarTintOpacity,
                  color: scheme.surfaceContainer,
                  shape: const CircleBorder(),
                  padding: EdgeInsets.zero,
                  optics: MiuixGlassOptics.navigation,
                  child: Center(
                    child: _MiuixIconButtonTargetOffset(
                      offset: targetOffset,
                      insets: targetInsets,
                      child: children[index],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return SizedBox(
      width: widthFor(children.length, style),
      height: 48,
      child: Stack(
        children: [
          for (var index = 0; index < children.length; index++)
            PositionedDirectional(
              start: index * 40,
              width: 48,
              height: 48,
              child: Center(
                child: _MiuixIconButtonTargetOffset(
                  offset: targetOffset,
                  insets: targetInsets,
                  child: children[index],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
