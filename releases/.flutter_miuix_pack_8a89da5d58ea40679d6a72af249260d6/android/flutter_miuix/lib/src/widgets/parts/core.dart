part of '../miuix_widgets.dart';

/// Navigation item model used by bottom bars, rails, and floating bars.
///
/// A small shared model keeps navigation widgets simple and avoids forcing apps
/// to depend on Material-specific destination classes at their own boundaries.
@immutable
class MiuixNavigationItem {
  /// Creates a navigation item.
  const MiuixNavigationItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.layoutLabel,
    this.enabled = true,
  });

  /// Icon displayed in the normal state.
  final Widget icon;

  /// Text label displayed for the destination.
  final String label;

  /// Optional source label used only to preserve the original intrinsic width.
  ///
  /// Localized labels can be substantially narrower than the labels used by
  /// the reference MIUIX sample. Floating navigation bars may measure this
  /// value invisibly while continuing to paint and announce [label].
  final String? layoutLabel;

  /// Optional selected icon.
  final Widget? selectedIcon;

  /// Whether this destination accepts pointer and semantic activation.
  ///
  /// Upstream navigation bar, floating bar, and rail item composables expose
  /// the same enabled switch. Disabled items keep their ordinary tint but do
  /// not enter the pressed state or invoke their selection callback.
  final bool enabled;
}

/// Dropdown entry model used by popup and preference widgets.
///
/// Entries are intentionally generic so the same component can represent enum
/// values, identifiers, or richer domain objects.
@immutable
class MiuixDropdownEntry<T> {
  /// Creates a dropdown entry.
  const MiuixDropdownEntry({
    required this.value,
    required this.label,
    this.icon,
    this.summary,
    this.enabled = true,
    this.selected = false,
  });

  /// Application value associated with the entry.
  final T value;

  /// Human-readable entry label.
  final String label;

  /// Optional leading icon.
  final Widget? icon;

  /// Optional supporting text shown below the label.
  final String? summary;

  /// Whether the entry can be selected.
  final bool enabled;

  /// Whether the popup renders a selected check mark for this entry.
  final bool selected;

  /// Returns a copy with explicitly overridden menu state.
  MiuixDropdownEntry<T> copyWith({bool? enabled, bool? selected}) {
    return MiuixDropdownEntry<T>(
      value: value,
      label: label,
      icon: icon,
      summary: summary,
      enabled: enabled ?? this.enabled,
      selected: selected ?? this.selected,
    );
  }
}

/// One independently selectable group inside a MIUIX dropdown or spinner.
@immutable
class MiuixDropdownGroup<T> {
  /// Creates a group of popup entries.
  const MiuixDropdownGroup({required this.entries});

  /// Rows in this group, preserving their source order.
  final List<MiuixDropdownEntry<T>> entries;
}

/// Universal row/container primitive for building custom Miuix components.
///
/// This mirrors MIUIX `BasicComponent`: it provides a leading slot, text area,
/// trailing slot, enabled state, and press handling while leaving the concrete
/// behavior to the caller.
class MiuixBasicComponent extends StatelessWidget {
  /// Creates a basic component row.
  const MiuixBasicComponent({
    super.key,
    required this.title,
    this.summary,
    this.titleColors,
    this.summaryColors,
    this.leading,
    this.trailing,
    this.bottomAction,
    this.insideMargin = MiuixBasicComponentDefaults.insideMargin,
    this.onTap,
    this.onLongPress,
    this.feedbackType = MiuixPressFeedbackType.none,
    this.enabled = true,
    this.standalone = true,
  }) : holdDown = false,
       interactionSource = null,
       _sourceContent = null,
       _showTitle = true;

  /// Creates the upstream text-and-summary overload without a card wrapper.
  const MiuixBasicComponent.sourceText({
    super.key,
    String? title,
    this.summary,
    this.titleColors,
    this.summaryColors,
    Widget? startAction,
    Widget? endActions,
    this.bottomAction,
    this.insideMargin = MiuixBasicComponentDefaults.insideMargin,
    VoidCallback? onClick,
    bool holdDownState = false,
    this.enabled = true,
    this.interactionSource,
  }) : title = title ?? '',
       leading = startAction,
       trailing = endActions,
       onTap = onClick,
       onLongPress = null,
       feedbackType = MiuixPressFeedbackType.none,
       holdDown = holdDownState,
       standalone = false,
       _sourceContent = null,
       _showTitle = title != null;

  /// Creates the upstream arbitrary-content overload without a card wrapper.
  const MiuixBasicComponent.source({
    super.key,
    required Widget content,
    Widget? startAction,
    Widget? endActions,
    this.bottomAction,
    this.insideMargin = MiuixBasicComponentDefaults.insideMargin,
    VoidCallback? onClick,
    bool holdDownState = false,
    this.enabled = true,
    this.interactionSource,
  }) : title = '',
       summary = null,
       titleColors = null,
       summaryColors = null,
       leading = startAction,
       trailing = endActions,
       onTap = onClick,
       onLongPress = null,
       feedbackType = MiuixPressFeedbackType.none,
       holdDown = holdDownState,
       standalone = false,
       _sourceContent = content,
       _showTitle = false;

  /// Main title.
  final String title;

  /// Optional supporting text.
  final String? summary;

  /// Optional source title foreground pair.
  final MiuixBasicComponentColors? titleColors;

  /// Optional source summary foreground pair.
  final MiuixBasicComponentColors? summaryColors;

  /// Optional leading slot.
  final Widget? leading;

  /// Optional trailing slot.
  final Widget? trailing;

  /// Optional full-width action shown eight pixels below the main row.
  final Widget? bottomAction;

  /// Padding around the row and optional bottom action.
  final EdgeInsetsGeometry insideMargin;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long-press callback.
  final VoidCallback? onLongPress;

  /// MIUIX press-feedback style used by this card.
  final MiuixPressFeedbackType feedbackType;

  /// Whether source indication remains held without a pointer.
  final bool holdDown;

  /// Whether the row is interactive.
  final bool enabled;

  /// Whether to supply its own card surface instead of joining a parent card.
  final bool standalone;

  /// Optional observer shared with source press interactions.
  final MiuixInteractionSource? interactionSource;

  final Widget? _sourceContent;
  final bool _showTitle;

  @override
  Widget build(BuildContext context) {
    final preference = MiuixPreference(
      title: title,
      summary: summary,
      titleColors: titleColors,
      summaryColors: summaryColors,
      showTitle: _showTitle,
      leading: leading,
      trailing: trailing,
      centerContent: _sourceContent,
      bottomAction: bottomAction,
      insideMargin: insideMargin,
      enabled: enabled,
      onTap: standalone ? null : (enabled ? onTap : null),
      holdDown: holdDown,
      interactionSource: interactionSource,
    );
    if (!standalone) {
      return preference;
    }
    return MiuixCard(
      onTap: enabled ? onTap : null,
      onLongPress: enabled ? onLongPress : null,
      feedbackType: feedbackType,
      padding: EdgeInsets.zero,
      child: preference,
    );
  }
}

/// Immutable container and foreground colors used by [MiuixCard].
///
/// MIUIX keeps these two channels independent. In particular, changing the
/// card fill must not silently replace the locally inherited text/icon color.
@immutable
class MiuixCardColors {
  /// Creates a card color pair.
  const MiuixCardColors({required this.color, required this.contentColor});

  /// Background painted inside the card shape.
  final Color color;

  /// Color inherited by text and icons in the card.
  final Color contentColor;

  /// Returns a copy with independently replaced color channels.
  MiuixCardColors copyWith({Color? color, Color? contentColor}) {
    return MiuixCardColors(
      color: color ?? this.color,
      contentColor: contentColor ?? this.contentColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MiuixCardColors &&
            other.color == color &&
            other.contentColor == contentColor;
  }

  @override
  int get hashCode => Object.hash(color, contentColor);
}

/// Source defaults for the MIUIX v1.0.9 card.
abstract final class MiuixCardDefaults {
  /// Default continuous-corner radius.
  static const double cornerRadius = 16;

  /// Default padding inside the card.
  static const EdgeInsets insideMargin = EdgeInsets.zero;

  /// Resolves the default color pair with independent caller overrides.
  static MiuixCardColors colors(
    BuildContext context, {
    Color? color,
    Color? contentColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    return MiuixCardColors(
      color: color ?? semantic['surfaceContainer'],
      contentColor: contentColor ?? semantic['onSurfaceContainer'],
    );
  }
}

/// Card component with Miuix shape, color, and press feedback.
class MiuixCard extends StatelessWidget {
  /// Creates a card.
  const MiuixCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.feedbackType = MiuixPressFeedbackType.none,
    this.padding,
    this.insideMargin,
    this.margin,
    this.glass = false,
    this.color,
    this.colors,
    this.cornerRadius = MiuixCardDefaults.cornerRadius,
    this.showIndication = false,
  }) : assert(
         padding == null || insideMargin == null,
         'Use either padding or insideMargin, not both.',
       ),
       assert(cornerRadius >= 0);

  /// Creates the interactive source overload with MIUIX parameter names.
  ///
  /// The ordinary constructor remains available for existing Flutter callers;
  /// this factory makes a direct `Card.kt` translation mechanically obvious.
  factory MiuixCard.source({
    Key? key,
    required Widget content,
    double cornerRadius = MiuixCardDefaults.cornerRadius,
    EdgeInsetsGeometry insideMargin = MiuixCardDefaults.insideMargin,
    MiuixCardColors? colors,
    MiuixPressFeedbackType pressFeedbackType = MiuixPressFeedbackType.none,
    bool showIndication = false,
    VoidCallback? onClick,
    VoidCallback? onLongPress,
  }) {
    return MiuixCard(
      key: key,
      cornerRadius: cornerRadius,
      insideMargin: insideMargin,
      colors: colors,
      feedbackType: pressFeedbackType,
      showIndication: showIndication,
      onTap: onClick,
      onLongPress: onLongPress,
      child: content,
    );
  }

  /// Card content.
  final Widget child;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Optional long-press callback.
  final VoidCallback? onLongPress;

  /// MIUIX press-feedback style used by this card.
  final MiuixPressFeedbackType feedbackType;

  /// Inner padding.
  ///
  /// Compatibility alias for [insideMargin].
  final EdgeInsetsGeometry? padding;

  /// Source-named padding inside the card.
  final EdgeInsetsGeometry? insideMargin;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Whether to render as a glass card.
  final bool glass;

  /// Optional explicit surface color for palette previews and custom cards.
  ///
  /// Compatibility override that takes precedence over [colors].
  final Color? color;

  /// Source color pair for the background and inherited content.
  final MiuixCardColors? colors;

  /// Continuous-corner radius of the card.
  final double cornerRadius;

  /// Whether a pressed overlay is shown independently of motion feedback.
  final bool showIndication;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedColors = colors ?? MiuixCardDefaults.colors(context);
    final effectiveColor =
        color ??
        (glass ? scheme.surface.withValues(alpha: .93) : resolvedColors.color);
    final effectiveInsideMargin =
        insideMargin ?? padding ?? MiuixCardDefaults.insideMargin;
    // Passing a feedback type names Card.kt's interactive overload even when
    // the caller only wants motion and leaves both callbacks null. Compose
    // still installs EmptyClickAction in that case.
    final interactive =
        onTap != null ||
        onLongPress != null ||
        showIndication ||
        feedbackType != MiuixPressFeedbackType.none;
    return MiuixSurface(
      // Compose Card always provides an EmptyClickAction to combinedClickable
      // when indication-only feedback is requested.
      onTap: onTap ?? (interactive ? () {} : null),
      onLongPress: onLongPress,
      feedbackType: feedbackType,
      showIndication: showIndication,
      padding: effectiveInsideMargin,
      margin: margin,
      glass: glass,
      radius: cornerRadius,
      color: effectiveColor,
      contentColor: resolvedColors.contentColor,
      // Upstream BasicCard is only clip + background; it never paints an
      // outline. A faint Material-style border still creates two physical
      // edge pixels on the 420-dpi reference device and changes the apparent
      // card height, so the ordinary MIUIX card deliberately leaves it null.
      child: child,
    );
  }
}

/// Rounds one Compose-like measurement without accumulating sibling values.
///
/// Do not pass a sum of unrelated dimensions here. Compose modifier nodes
/// round their own padding, text, and child measurements independently; the
/// caller must preserve those boundaries to avoid density-dependent drift.
double _miuixRoundLogicalDimension(double logical, double pixelRatio) {
  if (!pixelRatio.isFinite || pixelRatio <= 0) return logical;
  return (logical * pixelRatio).roundToDouble() / pixelRatio;
}

/// Returns the integer-pixel height of a Compose text placeable.
///
/// Text layout encloses fractional font bounds instead of rounding them to the
/// nearest pixel. At 3x density, for example, the MIUIX 17sp button line box is
/// 59.16px and therefore occupies 60px.
double _miuixCeilLogicalDimension(double logical, double pixelRatio) {
  if (!pixelRatio.isFinite || pixelRatio <= 0) return logical;
  return (logical * pixelRatio).ceilToDouble() / pixelRatio;
}

/// Resolves and rounds every inset edge as its own Compose padding dimension.
EdgeInsets _miuixRoundedInsets(
  BuildContext context,
  EdgeInsetsGeometry geometry,
) {
  final resolved = geometry.resolve(Directionality.of(context));
  final ratio = MediaQuery.devicePixelRatioOf(context);
  return EdgeInsets.fromLTRB(
    _miuixRoundLogicalDimension(resolved.left, ratio),
    _miuixRoundLogicalDimension(resolved.top, ratio),
    _miuixRoundLogicalDimension(resolved.right, ratio),
    _miuixRoundLogicalDimension(resolved.bottom, ratio),
  );
}

/// Curated icon entry point mirroring MIUIX icon namespaces.
///
/// Flutter uses font icons instead of Kotlin vector objects. These aliases keep
/// MIUIX naming discoverable while returning stable Material [IconData] values.
abstract final class MiuixIcons {
  /// Common basic icons.
  static const basic = MiuixBasicIcons();

  /// Normal-weight icon aliases.
  static const normal = MiuixNormalIcons();

  /// Light-weight icon aliases.
  static const light = MiuixLightIcons();

  /// Medium-weight icon aliases.
  static const medium = MiuixMediumIcons();

  /// Demibold icon aliases.
  static const demibold = MiuixDemiboldIcons();

  /// Extended icon aliases for apps and actions.
  static const extended = MiuixExtendedIcons();
}

/// Basic MIUIX icon aliases.
class MiuixBasicIcons {
  /// Creates a basic icon namespace.
  const MiuixBasicIcons();

  /// Back or forward arrow.
  IconData get arrowRight => Icons.chevron_right;

  /// Up/down sorting arrow.
  IconData get arrowUpDown => Icons.unfold_more;

  /// Check mark.
  IconData get check => Icons.check;

  /// Close mark.
  IconData get close => Icons.close;

  /// Search magnifier.
  IconData get search => Icons.search;

  /// Search cleanup action.
  IconData get searchCleanup => Icons.cancel;

  /// Sidebar action.
  IconData get sidebar => Icons.view_sidebar_outlined;
}

/// Normal icon namespace.
class MiuixNormalIcons extends MiuixBasicIcons {
  /// Creates a normal icon namespace.
  const MiuixNormalIcons();
}

/// Light icon namespace.
class MiuixLightIcons extends MiuixBasicIcons {
  /// Creates a light icon namespace.
  const MiuixLightIcons();
}

/// Medium icon namespace.
class MiuixMediumIcons extends MiuixBasicIcons {
  /// Creates a medium icon namespace.
  const MiuixMediumIcons();
}

/// Demibold icon namespace.
class MiuixDemiboldIcons extends MiuixBasicIcons {
  /// Creates a demibold icon namespace.
  const MiuixDemiboldIcons();
}

/// Extended MIUIX icon aliases commonly used by Xiaomi apps.
class MiuixExtendedIcons extends MiuixBasicIcons {
  /// Creates an extended icon namespace.
  const MiuixExtendedIcons();

  /// Add action.
  IconData get add => Icons.add;

  /// Delete action.
  IconData get delete => Icons.delete_outline;

  /// Home destination.
  IconData get home => Icons.home_outlined;

  /// Info action.
  IconData get info => Icons.info_outline;

  /// Location permission or place.
  IconData get location => Icons.location_on_outlined;

  /// More actions.
  IconData get more => Icons.more_horiz;

  /// Phone device.
  IconData get phone => Icons.phone_android;

  /// Refresh action.
  IconData get refresh => Icons.refresh;

  /// Settings destination.
  IconData get settings => Icons.settings_outlined;

  /// Share action.
  IconData get share => Icons.share_outlined;

  /// Theme action.
  IconData get theme => Icons.palette_outlined;

  /// Update action.
  IconData get update => Icons.system_update_alt;
}

/// Badge helper for unread counts and status dots.
class MiuixBadge extends StatelessWidget {
  /// Creates a badge.
  const MiuixBadge({
    super.key,
    required this.child,
    this.label,
    this.visible = true,
  });

  /// Widget that receives the badge overlay.
  final Widget child;

  /// Optional badge label.
  final String? label;

  /// Whether the badge is visible.
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return child;
    }
    final scheme = Theme.of(context).colorScheme;
    final compactLabel = label != null && label!.isNotEmpty;
    return Badge(
      isLabelVisible: true,
      backgroundColor: scheme.error.withValues(alpha: .96),
      smallSize: 8,
      largeSize: compactLabel ? 18 : 8,
      padding: compactLabel
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5)
          : EdgeInsets.zero,
      label: label == null
          ? null
          : Text(
              label!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onError,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: -.1,
              ),
            ),
      child: child,
    );
  }
}

/// Badge layout adapter matching MIUIX `BadgedBox`.
class MiuixBadgedBox extends StatelessWidget {
  /// Creates a badged box.
  const MiuixBadgedBox({
    super.key,
    required this.child,
    required this.badge,
    this.alignment = Alignment.topRight,
    this.offset = Offset.zero,
    this.unanchoredAlignment = Alignment.center,
  });

  /// Main child.
  final Widget child;

  /// Badge widget.
  final Widget badge;

  /// Badge alignment.
  final AlignmentGeometry alignment;

  /// Fine-grained badge offset.
  final Offset offset;
  final Alignment unanchoredAlignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Transform.translate(offset: offset, child: badge),
          ),
        ),
      ],
    );
  }
}
