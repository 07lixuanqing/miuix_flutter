part of '../miuix_widgets.dart';

/// iOS-like liquid-glass navigation used by the upstream MIUIX example.
///
/// This is intentionally separate from [MiuixFloatingNavigationBar]. The
/// upstream sample exposes both surfaces as two styles: the regular floating
/// MIUIX toolbar and this full-width liquid selector. Keeping a dedicated
/// widget preserves their different metrics, selection treatment, and drag
/// interaction instead of reducing the choice to a color change.
class MiuixIosLiquidGlassNavigationBar extends StatefulWidget {
  /// Creates the source-compatible iOS-like floating navigation surface.
  const MiuixIosLiquidGlassNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showBlur = true,
    this.defaultWindowInsetsPadding = true,
  }) : assert(items.length >= 2 && items.length <= 5);

  /// Two to five destinations displayed at equal widths.
  final List<MiuixNavigationItem> items;

  /// Index selected by the owning pager.
  final int selectedIndex;

  /// Called after a tap or after a horizontal drag settles on a destination.
  final ValueChanged<int> onDestinationSelected;

  /// Whether the liquid surface may sample and blur the content behind it.
  final bool showBlur;

  /// Whether to retain the original system-navigation bottom inset behavior.
  final bool defaultWindowInsetsPadding;

  @override
  State<MiuixIosLiquidGlassNavigationBar> createState() =>
      _MiuixIosLiquidGlassNavigationBarState();
}

class _MiuixIosLiquidGlassNavigationBarState
    extends State<MiuixIosLiquidGlassNavigationBar>
    with SingleTickerProviderStateMixin {
  // Compose uses a critically damped spring with stiffness 300. Translating
  // that spring to Flutter keeps destination changes quick without the hard
  // linear jump that made the earlier navigation feel mechanical.
  static final SpringDescription _selectionSpring = SpringDescription(
    mass: 1,
    stiffness: 300,
    damping: 2 * math.sqrt(300),
  );

  // Source constants are kept beside the layout so future changes can be
  // compared directly with LiquidGlassNavigationBar.kt.
  static const double _outsideHorizontalPadding = 24;
  static const double _panelHeight = 64;
  static const double _panelPadding = 4;
  static const double _indicatorHeight = 56;
  static const double _iconSize = 22;
  static const double _labelSize = 11;

  late final AnimationController _position;
  double _tabWidth = 0;
  bool _pressed = false;

  int get _safeSelected =>
      widget.selectedIndex.clamp(0, widget.items.length - 1);

  @override
  void initState() {
    super.initState();
    _position = AnimationController.unbounded(
      vsync: this,
      value: _safeSelected.toDouble(),
    );
  }

  @override
  void didUpdateWidget(covariant MiuixIosLiquidGlassNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _safeSelected.toDouble();
    if ((target - _position.value).abs() > .001) {
      _animateTo(target);
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _animateTo(double target, [double velocity = 0]) {
    _position.stop();
    _position.animateWith(
      SpringSimulation(_selectionSpring, _position.value, target, velocity),
    );
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  void _select(int index) {
    final target = index.clamp(0, widget.items.length - 1);
    _animateTo(target.toDouble());
    if (target != widget.selectedIndex) {
      widget.onDestinationSelected(target);
    }
  }

  void _dragStart(DragStartDetails details) {
    _position.stop();
    _setPressed(true);
  }

  void _dragUpdate(DragUpdateDetails details) {
    if (_tabWidth <= 0) {
      return;
    }
    final delta = details.primaryDelta ?? 0;
    _position.value = (_position.value + delta / _tabWidth).clamp(
      0.0,
      widget.items.length - 1.0,
    );
  }

  void _dragEnd(DragEndDetails details) {
    _setPressed(false);
    final target = _position.value.round().clamp(0, widget.items.length - 1);
    final velocity = _tabWidth <= 0
        ? 0.0
        : (details.primaryVelocity ?? 0) / _tabWidth;
    _animateTo(target.toDouble(), velocity);
    if (target != widget.selectedIndex) {
      widget.onDestinationSelected(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaBottom = MediaQuery.paddingOf(context).bottom;
    final bottomPadding = !widget.defaultWindowInsetsPadding
        ? 0.0
        : mediaBottom == 0
        ? 36.0
        : 8.0 + mediaBottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _outsideHorizontalPadding,
        0,
        _outsideHorizontalPadding,
        bottomPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _tabWidth = math.max(
            0,
            (constraints.maxWidth - _panelPadding * 2) / widget.items.length,
          );
          return AnimatedBuilder(
            animation: _position,
            builder: (context, _) => _buildPanel(
              context,
              _position.value.clamp(0.0, widget.items.length - 1.0),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanel(BuildContext context, double visualIndex) {
    final scheme = Theme.of(context).colorScheme;
    final miuixTheme = MiuixTheme.of(context);
    final intensity = miuixTheme.glassIntensity;
    final glassEnabled = widget.showBlur && miuixTheme.enableGlass;
    final radius = BorderRadius.circular(_panelHeight / 2);
    final surfaceColor = glassEnabled
        ? scheme.surfaceContainer.withValues(
            alpha: intensity.resolveOpacity(.4),
          )
        : scheme.surfaceContainer;

    Widget surface = ColoredBox(
      key: const ValueKey('ios-liquid-surface'),
      color: surfaceColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(_panelPadding),
              child: _buildTabRow(
                color: scheme.onSurface,
                interactive: true,
                useSelectedIcons: false,
              ),
            ),
          ),
          PositionedDirectional(
            key: const ValueKey('ios-liquid-indicator'),
            start: _panelPadding + visualIndex * _tabWidth,
            top: _panelPadding,
            width: _tabWidth,
            height: _indicatorHeight,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              scale: _pressed ? 78 / 56 : 1,
              child: _buildIndicator(
                scheme: scheme,
                visualIndex: visualIndex,
                glassEnabled: glassEnabled,
              ),
            ),
          ),
        ],
      ),
    );

    if (glassEnabled) {
      surface = BackdropFilter(
        key: const ValueKey('ios-liquid-backdrop-filter'),
        filter: ui.ImageFilter.blur(
          sigmaX: intensity.resolveBlur(4),
          sigmaY: intensity.resolveBlur(4),
        ),
        child: surface,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _dragStart,
      onHorizontalDragUpdate: _dragUpdate,
      onHorizontalDragEnd: _dragEnd,
      onHorizontalDragCancel: () => _setPressed(false),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 10,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            key: const ValueKey('ios-liquid-panel'),
            height: _panelHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                surface,
                if (glassEnabled)
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required ColorScheme scheme,
    required double visualIndex,
    required bool glassEnabled,
  }) {
    final contentWidth = _tabWidth * widget.items.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(_indicatorHeight / 2),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: glassEnabled
                ? (scheme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black)
                      .withValues(
                        alpha: MiuixTheme.of(
                          context,
                        ).glassIntensity.resolveOpacity(.10),
                      )
                : scheme.primary.withValues(alpha: .15),
          ),
          OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: contentWidth,
            maxWidth: contentWidth,
            child: Transform.translate(
              offset: Offset(-visualIndex * _tabWidth, 0),
              child: SizedBox(
                width: contentWidth,
                height: _indicatorHeight,
                child: _buildTabRow(
                  color: scheme.primary,
                  interactive: false,
                  useSelectedIcons: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow({
    required Color color,
    required bool interactive,
    required bool useSelectedIcons,
  }) {
    return Row(
      children: [
        for (var index = 0; index < widget.items.length; index++)
          SizedBox(
            width: _tabWidth,
            child: _buildTab(
              index: index,
              color: color,
              interactive: interactive,
              useSelectedIcon: useSelectedIcons,
            ),
          ),
      ],
    );
  }

  Widget _buildTab({
    required int index,
    required Color color,
    required bool interactive,
    required bool useSelectedIcon,
  }) {
    final item = widget.items[index];
    final itemInteractive = interactive && item.enabled;
    final icon = useSelectedIcon ? (item.selectedIcon ?? item.icon) : item.icon;
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconTheme(
          data: IconThemeData(color: color, size: _iconSize),
          child: SizedBox(width: _iconSize, height: _iconSize, child: icon),
        ),
        const SizedBox(height: 1),
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: _labelSize,
            fontWeight: FontWeight.w400,
            height: 1,
          ),
        ),
      ],
    );
    // The moving indicator renders a second, clipped copy of every tab solely
    // to tint the selected content.  Keeping those copies out of semantics
    // avoids duplicate labels, keys, and automation targets.
    if (!interactive) {
      return ExcludeSemantics(child: IgnorePointer(child: content));
    }
    return Semantics(
      key: ValueKey('ios-liquid-tab-$index'),
      button: true,
      selected: index == _safeSelected,
      enabled: item.enabled,
      label: item.label,
      child: itemInteractive
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _select(index),
              onTapDown: (_) {
                if (index == _safeSelected) {
                  _setPressed(true);
                }
              },
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              child: content,
            )
          : IgnorePointer(child: content),
    );
  }
}
