part of '../miuix_widgets.dart';

/// Source display modes for the MIUIX wide-screen navigation rail.
enum MiuixNavigationRailDisplayMode {
  /// Show a 28dp icon with a 12sp label.
  iconAndText,

  /// Show only the icon.
  iconOnly,

  /// Show only a 14sp label.
  textOnly,

  /// Keep every icon and reveal the label only for the selected destination.
  iconWithSelectedLabel,
}

/// Exact values exposed by upstream `NavigationRailDefaults`.
abstract final class MiuixNavigationRailDefaults {
  /// Default width of the rail column, excluding its optional divider.
  static const double minWidth = 80;

  /// Vertical padding around the complete scrollable rail content.
  static const double verticalPadding = 24;

  /// Space inserted after a non-null header.
  static const double headerSpacing = 24;

  /// Width and height of every source icon.
  static const double iconSize = 28;

  /// Space between an icon and its visible label.
  static const double iconTextSpacing = 4;

  /// Vertical padding applied outside every destination.
  static const double itemVerticalPadding = 12;

  /// Font size of labels in icon-and-text modes.
  static const double labelFontSize = 12;

  /// Font size used by text-only mode.
  static const double textOnlyFontSize = 14;

  /// Extra vertical padding around a text-only label.
  static const double textOnlyVerticalPadding = 4;

  /// Selected destination alpha while pressed.
  static const double selectedPressedAlpha = .5;

  /// Unselected destination alpha while pressed.
  static const double unselectedPressedAlpha = .6;

  /// Idle alpha of an unselected destination.
  static const double unselectedAlpha = .4;
}

/// Default `animateContentSize` spring used by rail destinations.
@visibleForTesting
SpringDescription debugMiuixNavigationRailSizeSpring() =>
    SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 1);

/// Inherited counterpart of upstream `LocalNavigationRailDisplayMode`.
class _MiuixNavigationRailDisplayModeScope extends InheritedWidget {
  const _MiuixNavigationRailDisplayModeScope({
    required this.mode,
    required super.child,
  });

  final MiuixNavigationRailDisplayMode mode;

  static MiuixNavigationRailDisplayMode of(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<
              _MiuixNavigationRailDisplayModeScope
            >()
            ?.mode ??
        MiuixNavigationRailDisplayMode.iconAndText;
  }

  @override
  bool updateShouldNotify(_MiuixNavigationRailDisplayModeScope oldWidget) {
    return mode != oldWidget.mode;
  }
}

/// Side navigation rail translated from MIUIX `NavigationRail.kt`.
///
/// Source geometry is intentionally expressed as separate placeables:
///
/// - the rail column owns an 80dp default width;
/// - the optional divider is a following 0.75dp canvas;
/// - the divider therefore increases total occupied width to 80.75dp;
/// - the column owns 24dp vertical content padding;
/// - an optional header is followed by a separate 24dp spacer;
/// - every item owns 12dp vertical outer padding;
/// - the complete column scrolls when its content exceeds the window.
///
/// The earlier adapter used a half-dp decoration border inside an 80dp box.
/// That made the pager begin 0.75dp too early and painted the wrong semantic
/// color. Keeping [MiuixVerticalDivider] as a sibling follows the original
/// Compose Row measurement and preserves its density-aware fractional raster.
///
/// Source paint and interaction contract:
///
/// - the background is the opaque `surface` token;
/// - selected content uses `onSurfaceContainer`;
/// - unselected content uses that token at 0.4 alpha;
/// - selected pressed content uses 0.5 alpha;
/// - unselected pressed content uses 0.6 alpha;
/// - disabled destinations retain idle tint without accepting input;
/// - compact destinations do not paint a selection capsule;
/// - compact destinations do not scale or ripple on press;
/// - no tooltip is synthesized around the source item.
class MiuixNavigationRail extends StatelessWidget {
  /// Creates a source-style navigation rail.
  const MiuixNavigationRail({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.header,
    this.color,
    this.showDivider = true,
    this.defaultWindowInsetsPadding = true,
    this.extended = false,
    this.displayMode = MiuixNavigationRailDisplayMode.iconAndText,
    this.minWidth = MiuixNavigationRailDefaults.minWidth,
  }) : sourceChildren = null;

  /// Creates the original arbitrary-content `NavigationRail` parameter form.
  const MiuixNavigationRail.source({
    super.key,
    this.header,
    this.color,
    this.showDivider = true,
    this.defaultWindowInsetsPadding = true,
    this.minWidth = MiuixNavigationRailDefaults.minWidth,
    MiuixNavigationRailDisplayMode mode =
        MiuixNavigationRailDisplayMode.iconAndText,
    required List<Widget> children,
  }) : items = const [],
       selectedIndex = -1,
       onDestinationSelected = null,
       extended = false,
       displayMode = mode,
       sourceChildren = children;

  /// Destination list.
  final List<MiuixNavigationItem> items;

  /// Current selected index.
  final int selectedIndex;

  /// Selection callback.
  final ValueChanged<int>? onDestinationSelected;

  /// Arbitrary source content slots, normally [MiuixNavigationRailItem]s.
  final List<Widget>? sourceChildren;

  /// Optional source header, usually a logo or floating action button.
  final Widget? header;

  /// Rail background; defaults to the exact opaque surface token.
  final Color? color;

  /// Whether to append the source 0.75dp vertical divider.
  final bool showDivider;

  /// Whether to consume status-bar and logical-start window insets.
  ///
  /// The source consumes status bars vertically and cutout/navigation bars on
  /// the start side. It does not consume the ordinary bottom gesture inset.
  final bool defaultWindowInsetsPadding;

  /// Whether to show the legacy extended compatibility presentation.
  ///
  /// Upstream v1.0.9 exposes only the compact rail plus [displayMode].
  /// This flag remains so existing Flutter consumers are not broken.
  final bool extended;

  /// Icon and label visibility mode.
  final MiuixNavigationRailDisplayMode displayMode;

  /// Source minimum column width.
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final direction = Directionality.of(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final safeSelected = items.isEmpty
        ? -1
        : selectedIndex.clamp(0, items.length - 1);
    final safeMinWidth = minWidth.isFinite && minWidth >= 0
        ? minWidth
        : MiuixNavigationRailDefaults.minWidth;
    final columnWidth = extended ? 240.0 : safeMinWidth;

    // Flutter's SafeArea bottom value combines navigation and gesture bars.
    // MIUIX requests only statusBars on the vertical axis, so apply the known
    // top value and logical-start side explicitly instead of adding a false
    // bottom gap on tablets and desktop-sized Android windows.
    final topInset = defaultWindowInsetsPadding ? viewPadding.top : 0.0;
    final startInset = defaultWindowInsetsPadding
        ? direction == TextDirection.ltr
              ? viewPadding.left
              : viewPadding.right
        : 0.0;

    final railColumn = SizedBox(
      key: const ValueKey('navigation-rail-column'),
      width: columnWidth,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          vertical: MiuixNavigationRailDefaults.verticalPadding,
        ),
        child: Column(
          children: [
            if (header != null) ...[
              header!,
              const SizedBox(
                height: MiuixNavigationRailDefaults.headerSpacing,
              ),
            ],
            if (sourceChildren != null)
              for (final child in sourceChildren!)
                _MiuixNavigationRailDisplayModeScope(
                  mode: displayMode,
                  child: child,
                )
            else
              for (var index = 0; index < items.length; index++)
                _MiuixNavigationRailItem(
                  key: ValueKey('navigation-rail-item-$index'),
                  item: items[index],
                  selected: index == safeSelected,
                  extended: extended,
                  sourceSemantics: false,
                  displayMode: displayMode,
                  onTap: () => onDestinationSelected?.call(index),
                ),
          ],
        ),
      ),
    );

    // Row order is directional. In RTL the column moves to the right edge and
    // the divider remains between the rail and the application pager, matching
    // Compose's `placeRelative` behavior.
    final railAndDivider = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        railColumn,
        if (showDivider)
          const MiuixVerticalDivider(key: ValueKey('navigation-rail-divider')),
      ],
    );

    return ColoredBox(
      color: color ?? scheme.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: startInset, top: topInset),
        child: railAndDivider,
      ),
    );
  }
}

/// Source `NavigationRailItem` widget.
///
/// Unlike [MiuixNavigationItem], this is rendered content with controlled
/// selection and click behavior. Its mode comes from the nearest
/// [MiuixNavigationRail.source], matching the source composition local.
class MiuixNavigationRailItem extends StatelessWidget {
  /// Creates one source rail destination.
  const MiuixNavigationRailItem({
    super.key,
    required this.selected,
    required this.onClick,
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  /// Whether the destination is selected.
  final bool selected;

  /// Invoked after a completed enabled tap.
  final VoidCallback onClick;

  /// Source icon artwork.
  final Widget icon;

  /// Visible label and icon description.
  final String label;

  /// Whether pointer interaction is accepted.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return _MiuixNavigationRailItem(
      item: MiuixNavigationItem(icon: icon, label: label, enabled: enabled),
      selected: selected,
      extended: false,
      sourceSemantics: true,
      displayMode: _MiuixNavigationRailDisplayModeScope.of(context),
      onTap: onClick,
    );
  }
}

/// One source rail destination with pointer-driven tint feedback.
///
/// MIUIX changes tint only while a pointer is held:
///
/// - selected idle alpha is 1.0;
/// - unselected idle alpha is 0.4;
/// - selected pressed alpha is 0.5;
/// - unselected pressed alpha is 0.6.
///
/// No sink scale, ripple, tooltip, or selected background is added to the
/// compact source branch. The legacy extended branch retains its old selected
/// container solely for Flutter API compatibility.
class _MiuixNavigationRailItem extends StatefulWidget {
  const _MiuixNavigationRailItem({
    super.key,
    required this.item,
    required this.selected,
    required this.extended,
    required this.sourceSemantics,
    required this.displayMode,
    required this.onTap,
  });

  /// Shared navigation destination.
  final MiuixNavigationItem item;

  /// Whether this is the active destination.
  final bool selected;

  /// Whether to render the non-source compatibility branch.
  final bool extended;

  /// Whether to preserve the source Image-only accessibility contract.
  final bool sourceSemantics;

  /// Current source display mode.
  final MiuixNavigationRailDisplayMode displayMode;

  /// Callback invoked after a completed enabled tap.
  final VoidCallback onTap;

  @override
  State<_MiuixNavigationRailItem> createState() =>
      _MiuixNavigationRailItemState();
}

class _MiuixNavigationRailItemState extends State<_MiuixNavigationRailItem> {
  /// Transient source pointer state.
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant _MiuixNavigationRailItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.enabled && !widget.item.enabled) {
      _pressed = false;
    }
  }

  /// Updates tint without introducing an unrelated scale animation.
  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final base = MiuixSemanticColors.of(context)['onSurfaceContainer'];
    final tint = _pressed
        ? base.withValues(
            alpha: widget.selected
                ? MiuixNavigationRailDefaults.selectedPressedAlpha
                : MiuixNavigationRailDefaults.unselectedPressedAlpha,
          )
        : widget.selected
        ? base
        : base.withValues(
            alpha: MiuixNavigationRailDefaults.unselectedAlpha,
          );
    final currentIcon = SizedBox.square(
      dimension: MiuixNavigationRailDefaults.iconSize,
      child: FittedBox(
        fit: BoxFit.contain,
        child: IconTheme(
          data: IconThemeData(
            color: tint,
            size: MiuixNavigationRailDefaults.iconSize,
          ),
          // NavigationRail.kt accepts one ImageVector and tints that same
          // vector for every state. Do not substitute a bottom-bar selected
          // glyph here.
          child: widget.item.icon,
        ),
      ),
    );
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: tint,
      fontSize: widget.displayMode == MiuixNavigationRailDisplayMode.textOnly
          ? MiuixNavigationRailDefaults.textOnlyFontSize
          : MiuixNavigationRailDefaults.labelFontSize,
      fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
    );
    final content = widget.extended
        ? _buildExtendedContent(context, currentIcon: currentIcon, tint: tint)
        : _buildSourceContent(currentIcon: currentIcon, labelStyle: labelStyle);

    final gesture = GestureDetector(
      excludeFromSemantics: widget.sourceSemantics,
        behavior: HitTestBehavior.opaque,
        onTap: widget.item.enabled ? widget.onTap : null,
        onTapDown: widget.item.enabled ? (_) => _setPressed(true) : null,
        onTapUp: widget.item.enabled ? (_) => _setPressed(false) : null,
        onTapCancel: widget.item.enabled ? () => _setPressed(false) : null,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 12 : 0,
            vertical: MiuixNavigationRailDefaults.itemVerticalPadding,
          ),
          child: SizedBox(
            width: double.infinity,
            child: _MiuixRailAnimateContentSize(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                constraints: BoxConstraints(
                  minHeight: widget.extended ? 56 : 0,
                  minWidth: widget.extended ? 216 : 0,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.extended ? 14 : 0,
                  vertical: widget.extended ? 14 : 0,
                ),
                decoration: BoxDecoration(
                  color: widget.selected && widget.extended
                      ? scheme.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: content,
              ),
            ),
          ),
        ),
      );
    if (widget.sourceSemantics) {
      // Upstream uses pointerInput rather than clickable, so the item itself
      // contributes no accessibility click action. Its Image publishes the
      // label with Role.Image; preserve that exact (if unusual) contract.
      return Semantics(image: true, label: widget.item.label, child: gesture);
    }
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.item.enabled,
      label: widget.item.label,
      child: gesture,
    );
  }

  /// Builds the four exact structural branches from NavigationRail.kt.
  Widget _buildSourceContent({
    required Widget currentIcon,
    required TextStyle? labelStyle,
  }) {
    return switch (widget.displayMode) {
      MiuixNavigationRailDisplayMode.iconAndText => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          currentIcon,
          const SizedBox(
            height: MiuixNavigationRailDefaults.iconTextSpacing,
          ),
          Text(
            widget.item.label,
            textAlign: TextAlign.center,
            style: labelStyle,
          ),
        ],
      ),
      MiuixNavigationRailDisplayMode.iconOnly => currentIcon,
      MiuixNavigationRailDisplayMode.textOnly => Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MiuixNavigationRailDefaults.textOnlyVerticalPadding,
        ),
        child: Text(
          widget.item.label,
          textAlign: TextAlign.center,
          style: labelStyle,
        ),
      ),
      MiuixNavigationRailDisplayMode.iconWithSelectedLabel => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          currentIcon,
          if (widget.selected) ...[
            const SizedBox(
              height: MiuixNavigationRailDefaults.iconTextSpacing,
            ),
            Text(
              widget.item.label,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ],
        ],
      ),
    };
  }

  /// Preserves the historical 240dp Flutter-only compatibility layout.
  Widget _buildExtendedContent(
    BuildContext context, {
    required Widget currentIcon,
    required Color tint,
  }) {
    return Row(
      children: [
        SizedBox(width: 30, height: 28, child: Center(child: currentIcon)),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            widget.item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tint,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Spring-sized clip matching Compose `Modifier.animateContentSize()`.
///
/// The child adopts its new content immediately. Only the parent measurement
/// interpolates from the currently displayed size to the new target, clipping
/// the child during the transition. This differs from [AnimatedSize], whose
/// duration and cubic curve cannot represent Compose's spring.
class _MiuixRailAnimateContentSize extends StatefulWidget {
  const _MiuixRailAnimateContentSize({required this.child});

  final Widget child;

  @override
  State<_MiuixRailAnimateContentSize> createState() =>
      _MiuixRailAnimateContentSizeState();
}

class _MiuixRailAnimateContentSizeState
    extends State<_MiuixRailAnimateContentSize>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController.unbounded(vsync: this, value: 1);
  }

  void _startSizeSpring() {
    _progress.value = 0;
    _progress.animateWith(
      SpringSimulation(
        debugMiuixNavigationRailSizeSpring(),
        0,
        1,
        0,
        tolerance: const Tolerance(distance: .01, velocity: .01),
      ),
    );
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MiuixRailAnimatedSizeRenderWidget(
      progress: _progress,
      onTargetChanged: _startSizeSpring,
      child: widget.child,
    );
  }
}

class _MiuixRailAnimatedSizeRenderWidget
    extends SingleChildRenderObjectWidget {
  const _MiuixRailAnimatedSizeRenderWidget({
    required this.progress,
    required this.onTargetChanged,
    required super.child,
  });

  final Animation<double> progress;
  final VoidCallback onTargetChanged;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMiuixRailAnimatedSize(progress, onTargetChanged);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMiuixRailAnimatedSize renderObject,
  ) {
    renderObject
      ..progress = progress
      ..onTargetChanged = onTargetChanged;
  }
}

class _RenderMiuixRailAnimatedSize extends RenderProxyBox {
  _RenderMiuixRailAnimatedSize(this._progress, this.onTargetChanged);

  Animation<double> _progress;
  VoidCallback onTargetChanged;
  Size _fromSize = Size.zero;
  Size _targetSize = Size.zero;
  bool _initialized = false;
  bool _callbackScheduled = false;

  set progress(Animation<double> value) {
    if (identical(value, _progress)) {
      return;
    }
    if (attached) {
      _progress.removeListener(markNeedsLayout);
    }
    _progress = value;
    if (attached) {
      _progress.addListener(markNeedsLayout);
    }
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void performLayout() {
    child?.layout(constraints, parentUsesSize: true);
    final childSize = child?.size ?? constraints.smallest;
    if (!_initialized) {
      _initialized = true;
      _fromSize = childSize;
      _targetSize = childSize;
    } else if (childSize != _targetSize) {
      _fromSize = size;
      _targetSize = childSize;
      if (!_callbackScheduled) {
        _callbackScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _callbackScheduled = false;
          if (attached) {
            onTargetChanged();
          }
        });
      }
    }
    size = constraints.constrain(
      Size.lerp(
        _fromSize,
        _targetSize,
        _progress.value.clamp(0.0, 1.0),
      )!,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null || size.isEmpty) {
      return;
    }
    context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) {
      return false;
    }
    return super.hitTestChildren(result, position: position);
  }
}
