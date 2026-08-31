part of '../miuix_widgets.dart';

/// Immutable colors consumed by the source-level dropdown row.
///
/// MIUIX deliberately keeps the selected and ordinary container channels
/// separate even though both defaults currently resolve to `surfaceContainer`.
/// Keeping four fields prevents a custom selected foreground from implicitly
/// changing the popup surface.
@immutable
class MiuixDropdownColors {
  /// Creates a complete dropdown color set.
  const MiuixDropdownColors({
    required this.contentColor,
    required this.containerColor,
    required this.selectedContentColor,
    required this.selectedContainerColor,
  });

  /// Foreground for an ordinary option.
  final Color contentColor;

  /// Background for an ordinary option.
  final Color containerColor;

  /// Foreground and check tint for the selected option.
  final Color selectedContentColor;

  /// Background for the selected option.
  final Color selectedContainerColor;
}

/// Source defaults for [MiuixDropdownImpl].
abstract final class MiuixDropdownDefaults {
  /// Resolves the four upstream semantic color roles.
  static MiuixDropdownColors colors(
    BuildContext context, {
    Color? contentColor,
    Color? containerColor,
    Color? selectedContentColor,
    Color? selectedContainerColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    return MiuixDropdownColors(
      contentColor: contentColor ?? semantic['onSurfaceContainer'],
      containerColor: containerColor ?? semantic['surfaceContainer'],
      selectedContentColor:
          selectedContentColor ?? Theme.of(context).colorScheme.primary,
      selectedContainerColor:
          selectedContainerColor ?? semantic['surfaceContainer'],
    );
  }
}

/// Immutable colors consumed by the source-level spinner row.
@immutable
class MiuixSpinnerColors {
  /// Creates a complete spinner color set.
  const MiuixSpinnerColors({
    required this.contentColor,
    required this.summaryColor,
    required this.containerColor,
    required this.selectedContentColor,
    required this.selectedSummaryColor,
    required this.selectedContainerColor,
    required this.selectedIndicatorColor,
  });

  /// Ordinary title tint.
  final Color contentColor;

  /// Ordinary summary tint.
  final Color summaryColor;

  /// Ordinary row background.
  final Color containerColor;

  /// Selected title tint.
  final Color selectedContentColor;

  /// Selected summary tint.
  final Color selectedSummaryColor;

  /// Selected row background.
  final Color selectedContainerColor;

  /// Selected trailing-check tint.
  final Color selectedIndicatorColor;
}

/// Source defaults for [MiuixSpinnerItemImpl].
abstract final class MiuixSpinnerDefaults {
  /// Colors used by an anchored spinner popup.
  static MiuixSpinnerColors colors(
    BuildContext context, {
    Color? contentColor,
    Color? summaryColor,
    Color? containerColor,
    Color? selectedContentColor,
    Color? selectedSummaryColor,
    Color? selectedContainerColor,
    Color? selectedIndicatorColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    return MiuixSpinnerColors(
      contentColor: contentColor ?? semantic['onSurfaceContainer'],
      summaryColor: summaryColor ?? semantic['onSurfaceVariantSummary'],
      containerColor: containerColor ?? semantic['surfaceContainer'],
      selectedContentColor: selectedContentColor ?? primary,
      selectedSummaryColor: selectedSummaryColor ?? primary,
      selectedContainerColor:
          selectedContainerColor ?? semantic['surfaceContainer'],
      selectedIndicatorColor: selectedIndicatorColor ?? primary,
    );
  }

  /// Colors used by the spinner's dialog presentation.
  static MiuixSpinnerColors dialogColors(
    BuildContext context, {
    Color? contentColor,
    Color? summaryColor,
    Color? containerColor,
    Color? selectedContentColor,
    Color? selectedSummaryColor,
    Color? selectedContainerColor,
    Color? selectedIndicatorColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    final selected = semantic['onTertiaryContainer'];
    return MiuixSpinnerColors(
      contentColor: contentColor ?? semantic['onSurfaceContainer'],
      summaryColor: summaryColor ?? semantic['onSurfaceVariantSummary'],
      containerColor: containerColor ?? Colors.transparent,
      selectedContentColor: selectedContentColor ?? selected,
      selectedSummaryColor: selectedSummaryColor ?? selected,
      selectedContainerColor:
          selectedContainerColor ?? semantic['tertiaryContainer'],
      selectedIndicatorColor: selectedIndicatorColor ?? selected,
    );
  }
}

/// One source spinner entry.
///
/// Unlike [MiuixDropdownEntry], this mirrors `SpinnerEntry`: title and summary
/// may independently be absent and the icon is presentation-only.
@immutable
class MiuixSpinnerEntry {
  /// Creates a spinner entry.
  const MiuixSpinnerEntry({this.icon, this.title, this.summary});

  /// Optional leading icon.
  final Widget? icon;

  /// Optional primary line.
  final String? title;

  /// Optional secondary line.
  final String? summary;
}

/// The exact 10×16 ArrowUpDown trailing action used by preferences.
class MiuixDropdownArrowEndAction extends StatelessWidget {
  /// Creates the source trailing arrow.
  const MiuixDropdownArrowEndAction({super.key, required this.actionColor});

  /// Arrow tint.
  final Color actionColor;

  @override
  Widget build(BuildContext context) => _MiuixDropdownArrow(color: actionColor);
}

/// Direct Flutter counterpart of MIUIX `DropdownImpl`.
///
/// The first and last rows receive 20dp outer padding; inner edges remain
/// 12dp. A transparent 20dp check is always measured so selected and ordinary
/// rows have identical intrinsic width.
class MiuixDropdownImpl extends StatelessWidget {
  /// Creates one dropdown option row.
  const MiuixDropdownImpl({
    super.key,
    required this.text,
    required this.optionSize,
    required this.isSelected,
    required this.index,
    required this.onSelectedIndexChange,
    this.colors,
  }) : assert(optionSize >= 0),
       assert(index >= 0);

  /// Text of this option.
  final String text;

  /// Total number of options.
  final int optionSize;

  /// Whether this row is selected.
  final bool isSelected;

  /// Index reported when the row is tapped.
  final int index;

  /// Optional explicit color set.
  final MiuixDropdownColors? colors;

  /// Selection callback.
  final ValueChanged<int> onSelectedIndexChange;

  @override
  Widget build(BuildContext context) {
    final resolved = colors ?? MiuixDropdownDefaults.colors(context);
    return _MiuixSourcePopupRow(
      title: text,
      selected: isSelected,
      titleColor: isSelected
          ? resolved.selectedContentColor
          : resolved.contentColor,
      summaryColor: isSelected
          ? resolved.selectedContentColor
          : resolved.contentColor,
      backgroundColor: isSelected
          ? resolved.selectedContainerColor
          : resolved.containerColor,
      indicatorColor: isSelected
          ? resolved.selectedContentColor
          : Colors.transparent,
      topPadding: index == 0 ? 20 : 12,
      bottomPadding: index == optionSize - 1 ? 20 : 12,
      maxLeadingContentWidth: 200,
      onTap: () => onSelectedIndexChange(index),
    );
  }
}

/// Direct Flutter counterpart of MIUIX `SpinnerItemImpl`.
class MiuixSpinnerItemImpl extends StatelessWidget {
  /// Creates one spinner option row.
  const MiuixSpinnerItemImpl({
    super.key,
    required this.entry,
    required this.entryCount,
    required this.isSelected,
    required this.index,
    required this.onSelectedIndexChange,
    this.colors,
    this.dialogMode = false,
  }) : assert(entryCount >= 0),
       assert(index >= 0);

  /// Spinner entry rendered by this row.
  final MiuixSpinnerEntry entry;

  /// Number of sibling entries.
  final int entryCount;

  /// Whether this row is selected.
  final bool isSelected;

  /// Index reported when tapped.
  final int index;

  /// Optional explicit colors.
  final MiuixSpinnerColors? colors;

  /// Whether to use full-width dialog geometry.
  final bool dialogMode;

  /// Selection callback.
  final ValueChanged<int> onSelectedIndexChange;

  @override
  Widget build(BuildContext context) {
    final resolved =
        colors ??
        (dialogMode
            ? MiuixSpinnerDefaults.dialogColors(context)
            : MiuixSpinnerDefaults.colors(context));
    return _MiuixSourcePopupRow(
      title: entry.title,
      summary: entry.summary,
      icon: entry.icon,
      selected: isSelected,
      titleColor: isSelected
          ? resolved.selectedContentColor
          : resolved.contentColor,
      summaryColor: isSelected
          ? resolved.selectedSummaryColor
          : resolved.summaryColor,
      backgroundColor: isSelected
          ? resolved.selectedContainerColor
          : resolved.containerColor,
      indicatorColor: isSelected
          ? resolved.selectedIndicatorColor
          : Colors.transparent,
      horizontalPadding: dialogMode ? 28 : 20,
      topPadding: !dialogMode && index == 0 ? 20 : 12,
      bottomPadding: !dialogMode && index == entryCount - 1 ? 20 : 12,
      minHeight: dialogMode ? 56 : 0,
      minWidth: dialogMode ? 200 : 0,
      fillWidth: dialogMode,
      maxLeadingContentWidth: dialogMode ? null : 216,
      onTap: () => onSelectedIndexChange(index),
    );
  }
}

/// Shared source row for DropdownImpl and SpinnerItemImpl.
///
/// This is intentionally not a Material ListTile. ListTile would force a
/// platform row height and would no longer reproduce the source's text-driven
/// 12/20dp vertical measurements.
class _MiuixSourcePopupRow extends StatelessWidget {
  const _MiuixSourcePopupRow({
    required this.selected,
    required this.titleColor,
    required this.summaryColor,
    required this.backgroundColor,
    required this.indicatorColor,
    required this.topPadding,
    required this.bottomPadding,
    required this.onTap,
    this.title,
    this.summary,
    this.icon,
    this.horizontalPadding = 20,
    this.minHeight = 0,
    this.minWidth = 0,
    this.fillWidth = false,
    this.maxLeadingContentWidth,
  });

  final String? title;
  final String? summary;
  final Widget? icon;
  final bool selected;
  final Color titleColor;
  final Color summaryColor;
  final Color backgroundColor;
  final Color indicatorColor;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;
  final double minHeight;
  final double minWidth;
  final bool fillWidth;
  final double? maxLeadingContentWidth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metrics = debugMiuixDropdownMetrics(
      isFirst: topPadding == 20,
      isLast: bottomPadding == 20,
    );
    final textColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          SizedBox(
            height: summary == null
                ? metrics.textLineHeight
                : metrics.summaryTitleLineHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        if (summary != null)
          SizedBox(
            height: metrics.summaryLineHeight,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: 1,
              child: Text(
                summary!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: summaryColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
    final leading = Row(
      mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (icon != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: icon,
            ),
          ),
          const SizedBox(width: 12),
        ],
        if (fillWidth)
          Expanded(child: textColumn)
        else if (maxLeadingContentWidth != null)
          Flexible(child: textColumn)
        else
          textColumn,
      ],
    );
    final boundedLeading = maxLeadingContentWidth == null
        ? leading
        : ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxLeadingContentWidth!),
            child: leading,
          );
    final row = Row(
      mainAxisSize: fillWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (fillWidth) Expanded(child: boundedLeading) else boundedLeading,
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12),
          child: _MiuixDropdownCheck(color: indicatorColor),
        ),
      ],
    );
    return MiuixPressable(
      onTap: onTap,
      feedbackType: MiuixPressFeedbackType.none,
      showIndication: true,
      child: ColoredBox(
        color: backgroundColor,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding,
              horizontalPadding,
              bottomPadding,
            ),
            child: row,
          ),
        ),
      ),
    );
  }
}
