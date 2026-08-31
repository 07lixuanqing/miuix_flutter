part of '../miuix_widgets.dart';

/// Drives the collapse state of a MIUIX large [MiuixTopAppBar].
///
/// The original component consumes vertical nested-scroll movement, then snaps
/// to the expanded or collapsed state when scrolling stops. [MiuixScaffold]
/// wires this object to descendant scrollables automatically.
class MiuixTopAppBarScrollBehavior extends ChangeNotifier {
  /// Creates a scroll behavior in its fully expanded state.
  MiuixTopAppBarScrollBehavior({
    this.snapDuration = const Duration(milliseconds: 300),
  });

  /// Duration of the original-style settle animation.
  final Duration snapDuration;

  double _collapseFraction = 0;
  double _collapseExtent = 38;
  Timer? _settleTimer;

  /// Zero is fully expanded and one is fully collapsed.
  double get collapseFraction => _collapseFraction;

  /// Applies a normalized collapse value.
  void setCollapseFraction(double value) {
    final next = value.clamp(0.0, 1.0);
    if ((next - _collapseFraction).abs() < .0001) {
      return;
    }
    _collapseFraction = next;
    notifyListeners();
  }

  /// Expands the bar immediately, for example after changing root pages.
  void expand() {
    _settleTimer?.cancel();
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
    _settleTimer?.cancel();
    setCollapseFraction(metrics.pixels / _collapseExtent);
  }

  /// Keeps restored scroll metrics tied to the measured large-title column.
  ///
  /// Compose sets `heightOffsetLimit` to the height of that column, rather
  /// than to the visible difference between the expanded and collapsed
  /// surfaces. The Flutter widget supplies the matching source-calibrated
  /// extent because a scroll behavior can be created before its bar exists.
  void _attachCollapseExtent(double value) {
    if (!value.isFinite || value <= 0) return;
    _collapseExtent = value;
  }

  /// Consumes the vertical scroll notifications emitted below the scaffold.
  bool handleNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification) {
      _settleTimer?.cancel();
    } else if (notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      // The leading scroll range is the large-title column measured by the
      // owning bar, including its optional subtitle.
      syncMetrics(notification.metrics);
    } else if (notification is ScrollEndNotification) {
      _settleTo(_collapseFraction >= .5 ? 1 : 0);
    }
    return false;
  }

  void _settleTo(double target) {
    _settleTimer?.cancel();
    final start = _collapseFraction;
    if ((target - start).abs() < .0001 || snapDuration == Duration.zero) {
      setCollapseFraction(target);
      return;
    }
    final stopwatch = Stopwatch()..start();
    // Compose's default snap spec is spring(stiffness = 2500f). With the
    // default critical damping ratio, sqrt(stiffness) is angular frequency and
    // the equivalent Folme response is 2π / sqrt(2500).
    final settleCurve = _MiuixCriticallyDampedCurve(
      responseSeconds: 2 * math.pi / math.sqrt(2500),
      durationSeconds:
          snapDuration.inMicroseconds / Duration.microsecondsPerSecond,
    );
    _settleTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      final progress =
          (stopwatch.elapsedMilliseconds / snapDuration.inMilliseconds).clamp(
            0.0,
            1.0,
          );
      final eased = settleCurve.transform(progress);
      setCollapseFraction(start + (target - start) * eased);
      if (progress >= 1) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
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
    this.color,
    this.glass = false,
    this.titleColor,
    this.largeTitleColor,
    this.subtitleColor,
    this.defaultWindowInsetsPadding = true,
    this.titlePadding = 26,
    this.navigationIconPadding = 16,
    this.actionIconPadding = 16,
    this.expandedHeight,
    this.bottomContent,
    this.bottomContentHeight = 0,
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

  /// Background color; defaults to the MIUIX surface color.
  final Color? color;

  /// Whether the bar samples and blurs page content behind its surface.
  final bool glass;

  /// Compact title color.
  final Color? titleColor;

  /// Expanded title color.
  final Color? largeTitleColor;

  /// Subtitle color.
  final Color? subtitleColor;

  /// Whether the bar keeps system-window top padding.
  final bool defaultWindowInsetsPadding;

  /// Horizontal title inset from the original component.
  final double titlePadding;

  /// Start inset for the navigation icon.
  final double navigationIconPadding;

  /// End inset for action icons.
  final double actionIconPadding;

  /// Optional explicit expanded height for unusually tall title content.
  final double? expandedHeight;

  /// Optional source-compatible content placed below the title area.
  final Widget? bottomContent;

  /// Reserved height for [bottomContent].
  final double bottomContentHeight;

  static const double collapsedHeight = 52;
  static const double smallTopAppBarCenterHeight = 50;
  static const double largeTitleBottomPadding = 4;
  static const double subtitleBottomPadding = 8;
  static const double titleMaxWidthFraction = .9;
  static const double collapsedLargeHeight = 56;
  static const double collapsedSubtitleHeight = 62;

  bool get _hasSubtitle => subtitle?.isNotEmpty == true;

  double get _expandedHeight => expandedHeight ?? (_hasSubtitle ? 114 : 94);

  double get _collapsedTitleAreaHeight {
    if (!large) {
      return _hasSubtitle ? collapsedSubtitleHeight : collapsedHeight;
    }
    return _hasSubtitle ? collapsedSubtitleHeight : collapsedLargeHeight;
  }

  double get _collapseExtent {
    // TopAppBar.kt stores the height of the 32sp large-title Column as its
    // nested-scroll limit. Subtracting the 52dp top region and the source
    // bottom padding from the calibrated expanded height reproduces 38dp for
    // a title and 54dp for a title plus 14sp subtitle.
    final padding = _hasSubtitle
        ? subtitleBottomPadding
        : largeTitleBottomPadding;
    return math.max(1, _expandedHeight - collapsedHeight - padding);
  }

  double get _fraction => large ? (scrollBehavior?.collapseFraction ?? 0) : 1;

  double get _titleAreaHeight => large
      ? ui.lerpDouble(_expandedHeight, _collapsedTitleAreaHeight, _fraction)!
      : _collapsedTitleAreaHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(_titleAreaHeight + bottomContentHeight);

  @override
  Widget build(BuildContext context) {
    if (large) {
      scrollBehavior?._attachCollapseExtent(_collapseExtent);
    }
    final bar = scrollBehavior == null
        ? _buildBar(context, includeTopSafeArea: defaultWindowInsetsPadding)
        : AnimatedBuilder(
            animation: scrollBehavior!,
            builder: (context, _) => _buildBar(
              context,
              includeTopSafeArea: defaultWindowInsetsPadding,
            ),
          );
    return bar;
  }

  Widget _buildBar(BuildContext context, {required bool includeTopSafeArea}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = _fraction;
    final height = _titleAreaHeight;
    final supportingText = _hasSubtitle ? subtitle : null;
    final compactVisible = !large || fraction * 3 >= 1;
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
              start: titlePadding,
              end: titlePadding,
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
              titlePadding: titlePadding,
              navigationIconPadding: navigationIconPadding,
              actionIconPadding: actionIconPadding,
              includeTopSafeArea: includeTopSafeArea,
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
          SizedBox(height: bottomContentHeight, child: bottomContent),
      ],
    );
    if (includeTopSafeArea) {
      // Compose applies its background before the systemBars top padding, so
      // the surface itself covers the status-bar region while title controls
      // remain below it. Keeping SafeArea inside the surface reproduces that
      // ordering for opaque and glass variants on edge-to-edge Android.
      content = SafeArea(bottom: false, child: content);
    }
    if (glass) {
      return MiuixGlass(
        key: const ValueKey('top-app-bar-glass'),
        // The theme scales this source radius. Level five resolves it to 9dp:
        // enough to frost text while retaining the color and broad shapes
        // needed to make a transparent bar visibly different from a solid one.
        blur: 4,
        opacity: .46,
        color: color ?? scheme.surface,
        radius: 0,
        padding: EdgeInsets.zero,
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
    super.color,
    super.glass,
    super.titleColor,
    super.subtitleColor,
    super.defaultWindowInsetsPadding,
    super.titlePadding,
    super.navigationIconPadding,
    super.actionIconPadding,
    super.bottomContent,
    super.bottomContentHeight,
  }) : super(large: false);
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
    final duration = visible
        ? const Duration(milliseconds: 300)
        : const Duration(milliseconds: 150);
    final response = visible ? .3 : .15;
    return TweenAnimationBuilder<double>(
      key: const ValueKey('top-app-bar-compact-title-animation'),
      tween: Tween(begin: 0, end: visible ? 1 : 0),
      duration: duration,
      // MIUIX uses folmeSpring(damping = 1), a critically damped spring with
      // response 0.3s when showing and 0.15s when hiding.
      curve: _MiuixCriticallyDampedCurve(
        responseSeconds: response,
        durationSeconds:
            duration.inMicroseconds / Duration.microsecondsPerSecond,
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
  });

  final List<Widget> children;
  final Offset targetOffset;
  final EdgeInsets targetInsets;

  @override
  Widget build(BuildContext context) {
    // Compose keeps adjacent icon centers 40dp apart even though Android
    // exposes a 48dp minimum touch target. The targets therefore overlap by
    // 8dp. A Stack reproduces that geometry without changing title
    // reservation or the popup anchor's center.
    return SizedBox(
      width: children.length * 40 + 8,
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
