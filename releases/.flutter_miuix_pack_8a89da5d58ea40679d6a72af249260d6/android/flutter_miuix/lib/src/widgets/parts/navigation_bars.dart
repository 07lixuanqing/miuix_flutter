part of '../miuix_widgets.dart';

/// Source-compatible display modes for regular MIUIX navigation items.
enum MiuixNavigationBarDisplayMode {
  /// Keep both the 26dp icon and the 12sp label visible.
  iconAndText,

  /// Center the icon and hide every label.
  iconOnly,

  /// Center the 14sp label and hide every icon.
  textOnly,

  /// Keep icons visible and reveal only the selected item's label.
  iconWithSelectedLabel,
}

/// Source display modes for MIUIX's distinct floating navigation component.
enum MiuixFloatingNavigationBarDisplayMode {
  /// Show a 24dp icon with a 12sp label below it.
  iconAndText,

  /// Show only the source 28dp icon.
  iconOnly,

  /// Show only a 14sp label.
  textOnly,
}

/// Horizontal placement of a [MiuixFloatingNavigationBar].
enum MiuixFloatingNavigationBarAlignment {
  /// Align the floating surface to the leading edge.
  start,

  /// Center the floating surface.
  center,

  /// Align the floating surface to the trailing edge.
  end,
}

/// Bottom navigation bar matching the current MIUIX three-mode component.
class MiuixNavigationBar extends StatelessWidget {
  /// Creates a regular navigation bar with a 64dp item row.
  ///
  /// When [showDivider] is true, the source's separate 0.75dp divider is
  /// measured above that row rather than painted inside its bounds.
  const MiuixNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.displayMode = MiuixNavigationBarDisplayMode.iconAndText,
    this.color,
    this.glass = false,
    this.showDivider = true,
    this.defaultWindowInsetsPadding = true,
  });

  /// Destination list; the original component supports two to five items.
  final List<MiuixNavigationItem> items;

  /// Current selected destination.
  final int selectedIndex;

  /// Selection callback.
  final ValueChanged<int> onDestinationSelected;

  /// Icon and label visibility mode.
  final MiuixNavigationBarDisplayMode displayMode;

  /// Optional surface color.
  final Color? color;

  /// Whether the bar samples and blurs page content behind its surface.
  final bool glass;

  /// Whether to draw the source divider above the bar.
  final bool showDivider;

  /// Whether to apply the bottom system inset.
  final bool defaultWindowInsetsPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeSelected = items.isEmpty
        ? -1
        : selectedIndex.clamp(0, items.length - 1);
    final content = SizedBox(
      height: 64,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++)
            Expanded(
              child: _MiuixNavigationBarItem(
                item: items[index],
                selected: index == safeSelected,
                displayMode: displayMode,
                onTap: () => onDestinationSelected(index),
              ),
            ),
        ],
      ),
    );
    final insetContent = defaultWindowInsetsPadding
        ? SafeArea(top: false, child: content)
        : content;
    // NavigationBar.kt places HorizontalDivider as the first child of its
    // Column. It contributes 0.75dp to measured height while leaving the 64dp
    // item row at the same screen coordinate. A decoration border instead
    // paints inward and made both total height and divider color incorrect.
    final barContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDivider)
          const MiuixHorizontalDivider(key: ValueKey('navigation-bar-divider')),
        insetContent,
      ],
    );
    if (glass) {
      return MiuixGlass(
        key: const ValueKey('navigation-bar-glass'),
        blur: 4,
        opacity: .48,
        color: color ?? scheme.surface,
        radius: 0,
        padding: EdgeInsets.zero,
        child: barContent,
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: color ?? scheme.surface),
      child: barContent,
    );
  }
}

class _MiuixNavigationBarItem extends StatefulWidget {
  const _MiuixNavigationBarItem({
    required this.item,
    required this.selected,
    required this.displayMode,
    required this.onTap,
  });

  final MiuixNavigationItem item;
  final bool selected;
  final MiuixNavigationBarDisplayMode displayMode;
  final VoidCallback onTap;

  @override
  State<_MiuixNavigationBarItem> createState() =>
      _MiuixNavigationBarItemState();
}

class _MiuixNavigationBarItemState extends State<_MiuixNavigationBarItem>
    with SingleTickerProviderStateMixin {
  // Upstream selection motion lasts 300 ms and affects only the selected-label
  // layout; tint and typography switch immediately with the selected state.
  late final AnimationController _selection;

  // Press alpha is transient and deliberately independent of selection motion.
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _selection = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.selected ? 1 : 0,
    )..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant _MiuixNavigationBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      // FastOutSlowIn is the exact MIUIX tween used to raise the icon and reveal
      // the label in iconWithSelectedLabel mode.
      _selection.animateTo(
        widget.selected ? 1 : 0,
        curve: Curves.fastOutSlowIn,
      );
    }
    if (oldWidget.item.enabled && !widget.item.enabled) {
      _pressed = false;
    }
  }

  @override
  void dispose() {
    _selection
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NavigationBarDefaults uses onSurfaceContainer for every destination.
    final baseTint = MiuixSemanticColors.of(context)['onSurfaceContainer'];

    // The controller value already includes the configured easing curve; it
    // must not be transformed a second time during layout.
    final progress = _selection.value;
    final normalTint = widget.selected
        ? baseTint
        : baseTint.withValues(alpha: .4);
    // Source press alpha is .5 for selected and .6 for unselected items.
    final pressedTint = baseTint.withValues(alpha: widget.selected ? .5 : .6);
    final tint = _pressed ? pressedTint : normalTint;
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.item.enabled,
      label: widget.item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.item.enabled ? widget.onTap : null,
        onTapDown: widget.item.enabled ? (_) => _setPressed(true) : null,
        onTapUp: widget.item.enabled ? (_) => _setPressed(false) : null,
        onTapCancel: widget.item.enabled ? () => _setPressed(false) : null,
        child: SizedBox(height: 64, child: _buildMode(context, progress, tint)),
      ),
    );
  }

  Widget _buildMode(BuildContext context, double progress, Color tint) {
    // MIUIX changes display modes structurally; it does not cross-fade or retain
    // the previous icon/text branch.
    return switch (widget.displayMode) {
      MiuixNavigationBarDisplayMode.iconOnly => Center(child: _buildIcon(tint)),
      MiuixNavigationBarDisplayMode.textOnly => Center(
        child: Text(
          widget.item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: tint,
            fontSize: 14,
            fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
      MiuixNavigationBarDisplayMode.iconAndText => Column(
        children: [
          const SizedBox(height: 8),
          _buildIcon(tint),
          // NavigationBar.kt lays Text immediately after the 26dp image. Its
          // paragraph contributes a small font-leading offset, represented by
          // this 1dp gap for Flutter's tighter CJK line box. The old Spacer
          // consumed the row's remaining 10dp and painted every label about
          // 23 physical pixels too low on the 420-dpi reference device.
          const SizedBox(height: 1),
          _buildLabel(context, tint),
          const SizedBox(height: 8),
        ],
      ),
      MiuixNavigationBarDisplayMode.iconWithSelectedLabel => Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            // The icon moves from 19 dp to 8 dp while the label fades in.
            top: ui.lerpDouble(19, 8, progress),
            child: _buildIcon(tint),
          ),
          Positioned(
            // Compose places the label after the animated icon placeable, so
            // both move together from the centered icon-only layout to the
            // selected icon-and-label layout. Pinning the label to the bottom
            // kept it stationary and substantially below the source baseline.
            top: ui.lerpDouble(19, 8, progress)! + 27,
            left: 4,
            right: 4,
            child: Opacity(
              opacity: progress,
              child: _buildLabel(context, tint),
            ),
          ),
        ],
      ),
    };
  }

  Widget _buildIcon(Color tint) {
    return SizedBox(
      width: 26,
      height: 26,
      child: IconTheme(
        data: IconThemeData(color: tint, size: 26),
        child: widget.selected
            ? (widget.item.selectedIcon ?? widget.item.icon)
            : widget.item.icon,
      ),
    );
  }

  Widget _buildLabel(BuildContext context, Color tint) {
    return Text(
      widget.item.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: tint,
        fontSize: 12,
        height: 1,
        fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
      ),
    );
  }
}

/// Floating MIUIX navigation bar with source-sized equal destinations.
///
/// This is a distinct source component rather than a regular display mode.
class MiuixFloatingNavigationBar extends StatelessWidget {
  /// Creates the source floating navigation surface.
  const MiuixFloatingNavigationBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    this.onSelected,
    this.onDestinationSelected,
    this.color,
    this.cornerRadius = 50,
    this.displayMode = MiuixFloatingNavigationBarDisplayMode.iconOnly,
    this.alignment = MiuixFloatingNavigationBarAlignment.center,
    this.horizontalOutsidePadding = 36,
    this.shadowElevation = 1,
    this.showDivider = false,
    this.glass = false,
    this.defaultWindowInsetsPadding = true,
    this.itemExtent = double.nan,
  }) : assert(onSelected != null || onDestinationSelected != null);

  /// Destination list.
  final List<MiuixNavigationItem> items;

  /// Current selected destination.
  final int selectedIndex;

  /// Backward-compatible selection callback.
  final ValueChanged<int>? onSelected;

  /// Selection callback using the regular navigation naming.
  final ValueChanged<int>? onDestinationSelected;

  /// Surface color, defaulting to `surfaceContainer`.
  final Color? color;

  /// Original floating-toolbar corner radius.
  final double cornerRadius;

  /// Icon and label visibility mode from the current source component.
  final MiuixFloatingNavigationBarDisplayMode displayMode;

  /// Placement within the full-width host.
  final MiuixFloatingNavigationBarAlignment alignment;

  /// Outside inset applied only on the aligned edge.
  final double horizontalOutsidePadding;

  /// Source graphics-layer elevation used to derive the capsule shadow.
  final double shadowElevation;

  /// Whether to draw the 0.75dp outline around the surface.
  final bool showDivider;

  /// Whether the source surface uses the global liquid-glass treatment.
  final bool glass;

  /// Whether to account for navigation and caption-bar insets.
  final bool defaultWindowInsetsPadding;

  /// Optional square extent assigned to every destination.
  ///
  /// The default NaN sentinel derives the source 48/50dp height and assigns
  /// every destination the average of the original intrinsic widths. This
  /// retains the user's equal-width requirement without widening a five-item
  /// translated bar beyond the native MIUIX capsule. A finite value explicitly
  /// overrides both dimensions for applications that need larger targets.
  final double itemExtent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mediaPadding = MediaQuery.paddingOf(context);
    final miuixTheme = MiuixTheme.of(context);
    // Upstream applies a platform base gap first, then optionally applies its
    // window-inset modifier.  Android's nonzero base gap already contains one
    // navigation-bar inset (`8 + inset`), so the default inset modifier adds
    // the same inset a second time.  On the 24dp gesture-inset reference
    // emulator this produces the measured 56dp pill-to-window gap.
    final systemBottom = mediaPadding.bottom;
    final bottomPadding = switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        systemBottom == 0
            ? 36.0
            : 8.0 + systemBottom * (defaultWindowInsetsPadding ? 2 : 1),
      TargetPlatform.iOS =>
        8.0 + (defaultWindowInsetsPadding ? systemBottom : 0),
      _ => 36.0 + (defaultWindowInsetsPadding ? systemBottom : 0),
    };
    final safeSelected = items.isEmpty
        ? -1
        : selectedIndex.clamp(0, items.length - 1);
    final sourceItemSize = _sourceEqualFloatingItemSize(
      context,
      items,
      displayMode,
    );
    final explicitItemExtent = itemExtent.isFinite
        ? itemExtent.clamp(48.0, 96.0).toDouble()
        : null;
    final safeItemWidth =
        explicitItemExtent ?? sourceItemSize.width.clamp(24.0, 96.0).toDouble();
    final safeItemHeight =
        explicitItemExtent ??
        sourceItemSize.height.clamp(48.0, 96.0).toDouble();
    final row = Row(
      key: const ValueKey('floating-navigation-content-row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(width: 12),
          _MiuixFloatingNavigationBarItem(
            key: ValueKey('floating-navigation-item-$index'),
            selected: safeSelected == index,
            enabled: items[index].enabled,
            onPressed: () => (onDestinationSelected ?? onSelected)!.call(index),
            icon: safeSelected == index
                ? (items[index].selectedIcon ?? items[index].icon)
                : items[index].icon,
            label: items[index].label,
            layoutLabel: items[index].layoutLabel,
            displayMode: displayMode,
            itemWidth: safeItemWidth,
            itemHeight: safeItemHeight,
          ),
        ],
      ],
    );
    final safeElevation = shadowElevation.isFinite
        ? math.max(0.0, shadowElevation)
        : 0.0;
    final shadow = safeElevation > 0
        ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              // Upstream passes the requested dp value to graphicsLayer as
              // physical shadow elevation. The shared Surface implementation
              // maps that elevation to a compact two-times blur and a small
              // downward offset; using a fixed 10dp blur produced a broad
              // rectangular haze beyond the capsule's rounded end cuts.
              blurRadius: safeElevation * 2,
              offset: Offset(0, safeElevation / 2),
            ),
          ]
        : null;
    final Widget bar;
    ShapeBorder navigationShape([BorderSide side = BorderSide.none]) =>
        miuixTheme.enableSquircle
        ? MiuixSquircleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
            side: side,
          )
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cornerRadius),
            side: side,
          );
    if (glass) {
      bar = DecoratedBox(
        key: const ValueKey('floating-navigation-surface'),
        decoration: ShapeDecoration(shape: navigationShape(), shadows: shadow),
        child: MiuixGlass(
          key: const ValueKey('floating-navigation-glass'),
          // The floating pill must reveal the page beneath it. These source
          // values resolve to 9dp blur and 8.8% tint at level five, retaining
          // recognizable blurred rows instead of a uniform white capsule.
          blur: 4,
          opacity: .40,
          color: color ?? scheme.surfaceContainer,
          radius: cornerRadius,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          border: showDivider
              ? BorderSide(color: scheme.outlineVariant, width: .75)
              : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: safeItemHeight),
            child: row,
          ),
        ),
      );
    } else {
      final shape = navigationShape(
        showDivider
            ? BorderSide(color: scheme.outlineVariant, width: .75)
            : BorderSide.none,
      );
      bar = DecoratedBox(
        key: const ValueKey('floating-navigation-surface'),
        decoration: ShapeDecoration(
          color: color ?? scheme.surfaceContainer,
          shape: shape,
          shadows: shadow,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: safeItemHeight),
            child: row,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: alignment == MiuixFloatingNavigationBarAlignment.start
            ? horizontalOutsidePadding
            : 0,
        end: alignment == MiuixFloatingNavigationBarAlignment.end
            ? horizontalOutsidePadding
            : 0,
        bottom: bottomPadding,
      ),
      // A Row fills only the horizontal axis while retaining the bar's
      // intrinsic height. Align would also expand vertically under Scaffold's
      // loose bottom-bar constraints and could consume the whole body area.
      child: Row(
        mainAxisAlignment: switch (alignment) {
          MiuixFloatingNavigationBarAlignment.start => MainAxisAlignment.start,
          MiuixFloatingNavigationBarAlignment.center =>
            MainAxisAlignment.center,
          MiuixFloatingNavigationBarAlignment.end => MainAxisAlignment.end,
        },
        children: [bar],
      ),
    );
  }
}

/// Returns equal item dimensions while preserving the source intrinsic total.
///
/// Compose lets floating destinations keep their intrinsic label widths. The
/// localized sample deliberately equalizes them, so assigning the average
/// source width to all items preserves both requirements: five equal hit
/// regions and the exact total native capsule width.
///
/// The source measurements represented here are:
///
/// - icon-only: a 28dp glyph with 10dp above and below, yielding 48dp;
/// - icon-and-text: 6dp top and bottom around a 24dp glyph and 12sp label;
/// - text-only: 16dp vertical padding around a centered 14sp label;
/// - 12dp between neighboring destinations;
/// - 12dp surface padding at each horizontal edge.
///
/// `layoutLabel` intentionally retains the untranslated source label for
/// measurement while the visible `label` remains localized. Measuring the
/// Chinese strings would make the capsule depend on translation length and
/// would no longer reproduce the upstream sample's physical width. Taking the
/// arithmetic mean after measuring all source labels keeps every localized
/// destination equal without changing the sum of the upstream intrinsic
/// widths. This also keeps tap regions equal, as requested by the sample app.
///
/// Logical widths stay fractional until Flutter performs the final device
/// transform. Individual Android pixels can therefore alternate by one pixel
/// across items at 2.625 density, just as Compose's independently rounded
/// placements do. Tests compare the total source geometry while separately
/// requiring every logical item width to be identical.
Size _sourceEqualFloatingItemSize(
  BuildContext context,
  List<MiuixNavigationItem> items,
  MiuixFloatingNavigationBarDisplayMode mode,
) {
  if (mode == MiuixFloatingNavigationBarDisplayMode.iconOnly || items.isEmpty) {
    return const Size.square(48);
  }
  final fontSize = mode == MiuixFloatingNavigationBarDisplayMode.iconAndText
      ? 12.0
      : 14.0;
  var totalWidth = 0.0;
  for (final item in items) {
    final painter = TextPainter(
      text: TextSpan(
        text: item.layoutLabel ?? item.label,
        style: _floatingSourceLayoutStyle(
          context,
          fontSize: fontSize,
          translated: item.layoutLabel != null,
        ),
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final labelWidth = painter.width;
    painter.dispose();
    totalWidth += mode == MiuixFloatingNavigationBarDisplayMode.iconAndText
        ? math.max(24, labelWidth)
        : labelWidth + 4;
  }
  return Size(
    totalWidth / items.length,
    mode == MiuixFloatingNavigationBarDisplayMode.iconAndText ? 50 : 48,
  );
}

/// Uses the source Latin measurement for an untranslated layout label.
TextStyle _floatingSourceLayoutStyle(
  BuildContext context, {
  required double fontSize,
  required bool translated,
}) {
  final base = Theme.of(context).textTheme.labelMedium ?? const TextStyle();
  // Compose and SkParagraph do not produce exactly the same Roboto Bold
  // advances. The discrepancy also changes slightly between the source's
  // 12sp icon-label mode and its 14sp text-only mode, so keep the two measured
  // conversion factors instead of allowing the wider mode to accumulate a
  // several-pixel capsule error across all five destinations.
  final sourceAdvanceScale = fontSize <= 12 ? 11.87 / 12 : 11.827 / 12;
  return base.copyWith(
    fontSize: translated ? fontSize * sourceAdvanceScale : fontSize,
    fontWeight: FontWeight.w700,
    fontFamily: translated ? 'Roboto' : base.fontFamily,
    fontFamilyFallback: translated
        ? const ['sans-serif']
        : base.fontFamilyFallback,
  );
}

class _MiuixFloatingNavigationBarItem extends StatefulWidget {
  const _MiuixFloatingNavigationBarItem({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.layoutLabel,
    required this.displayMode,
    required this.itemWidth,
    required this.itemHeight,
  });

  final bool selected;
  final bool enabled;
  final VoidCallback onPressed;
  final Widget icon;
  final String label;
  final String? layoutLabel;
  final MiuixFloatingNavigationBarDisplayMode displayMode;
  final double itemWidth;
  final double itemHeight;

  @override
  State<_MiuixFloatingNavigationBarItem> createState() =>
      _MiuixFloatingNavigationBarItemState();
}

class _MiuixFloatingNavigationBarItemState
    extends State<_MiuixFloatingNavigationBarItem> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) {
      setState(() => _pressed = value);
    }
  }

  @override
  void didUpdateWidget(covariant _MiuixFloatingNavigationBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled && !widget.enabled) {
      _pressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = MiuixSemanticColors.of(context)['onSurfaceContainer'];
    final tint = _pressed
        ? base.withValues(alpha: widget.selected ? .5 : .6)
        : widget.selected
        ? base
        : base.withValues(alpha: .4);
    return Semantics(
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onPressed : null,
        onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
        onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
        onTapCancel: widget.enabled ? () => _setPressed(false) : null,
        child: _buildMode(context, tint),
      ),
    );
  }

  Widget _buildMode(BuildContext context, Color tint) {
    final selectedWeight = widget.selected ? FontWeight.w700 : FontWeight.w400;
    Widget stableLabel({required double fontSize}) {
      final style = Theme.of(context).textTheme.labelMedium?.copyWith(
        color: tint,
        fontSize: fontSize,
        fontWeight: selectedWeight,
      );
      // A localized example may replace the complete text theme with a CJK
      // family. The invisible layout label still represents the untranslated
      // source label, so measure it with the source platform's Latin face;
      // otherwise Noto CJK makes the floating pill about 34dp too wide.
      // SkParagraph's Roboto Bold advances are about 8.3% wider than Compose's
      // platform paragraph. The shared calibrated style is also used by the
      // parent to preserve the source total width before equal distribution.
      final sourceLayoutStyle = _floatingSourceLayoutStyle(
        context,
        fontSize: fontSize,
        translated: widget.layoutLabel != null,
      );
      return Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: Text(
              widget.layoutLabel ?? widget.label,
              maxLines: 1,
              style: sourceLayoutStyle,
            ),
          ),
          Text(widget.label, maxLines: 1, style: style),
        ],
      );
    }

    return SizedBox(
      width: widget.itemWidth,
      height: widget.itemHeight,
      child: Center(
        child: switch (widget.displayMode) {
          MiuixFloatingNavigationBarDisplayMode.iconOnly => Padding(
            padding: const EdgeInsets.all(10),
            child: IconTheme(
              data: IconThemeData(color: tint, size: 28),
              child: SizedBox(width: 28, height: 28, child: widget.icon),
            ),
          ),
          MiuixFloatingNavigationBarDisplayMode.iconAndText => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTheme(
                  data: IconThemeData(color: tint, size: 24),
                  child: SizedBox(width: 24, height: 24, child: widget.icon),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: stableLabel(fontSize: 12),
                ),
              ],
            ),
          ),
          MiuixFloatingNavigationBarDisplayMode.textOnly => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: stableLabel(fontSize: 14),
            ),
          ),
        },
      ),
    );
  }
}
