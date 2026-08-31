part of '../miuix_widgets.dart';

/// Slider preference.
class MiuixSliderPreference extends StatelessWidget {
  /// Creates a slider preference.
  const MiuixSliderPreference({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.summary,
    this.valueText,
    this.onTap,
    this.min = 0,
    this.max = 1,
    this.enabled = true,
  });

  /// Main title.
  final String title;

  /// Optional summary.
  final String? summary;

  /// Optional formatted value shown at the end of the title row.
  final String? valueText;

  /// Optional row action independent of dragging the slider.
  final VoidCallback? onTap;

  /// Current value.
  final double value;

  /// Change callback.
  final ValueChanged<double> onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Whether the preference slider is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final range = _safeRange(min, max);
    final safeValue = _normalizeSliderCallbackValue(value, range);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixPreference(
          title: title,
          summary: summary,
          enabled: enabled,
          onTap: enabled ? onTap : null,
          trailing: Text(valueText ?? safeValue.toStringAsFixed(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MiuixSlider(
            value: safeValue,
            min: range.min,
            max: range.max,
            enabled: enabled,
            onChanged: (next) =>
                onChanged(_normalizeSliderCallbackValue(next, range)),
          ),
        ),
      ],
    );
  }
}

/// Placement of the radio mark inside a radio preference row.
///
/// MIUIX 1.0.9 places the mark at the start by default.  The explicit enum
/// mirrors the source API so callers can opt into the less common end layout
/// without rebuilding the preference from lower-level widgets.
enum MiuixRadioButtonLocation {
  /// Place the radio before the title and summary.
  start,

  /// Place the radio after the title and summary.
  end,
}

/// Radio preference for exclusive settings choices.
class MiuixRadioButtonPreference<T> extends StatelessWidget {
  /// Creates a radio preference row.
  const MiuixRadioButtonPreference({
    super.key,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.summary,
    this.titleColor,
    this.summaryColor,
    this.leading,
    this.secondaryAction,
    this.radioButtonColors,
    this.bottomAction,
    this.insideMargin = MiuixBasicComponentDefaults.insideMargin,
    this.holdDown = false,
    this.radioButtonLocation = MiuixRadioButtonLocation.start,
    this.enabled = true,
  });

  /// Creates the upstream non-generic `RadioButtonPreference` surface.
  static MiuixRadioButtonPreference<bool> source({
    Key? key,
    required String title,
    required bool selected,
    required VoidCallback? onClick,
    MiuixBasicComponentColors? titleColor,
    String? summary,
    MiuixBasicComponentColors? summaryColor,
    MiuixRadioButtonColors? radioButtonColors,
    Widget? endActions,
    MiuixRadioButtonLocation radioButtonLocation =
        MiuixRadioButtonLocation.start,
    Widget? bottomAction,
    EdgeInsetsGeometry insideMargin = MiuixBasicComponentDefaults.insideMargin,
    bool holdDownState = false,
    bool enabled = true,
  }) {
    return MiuixRadioButtonPreference<bool>(
      key: key,
      title: title,
      value: true,
      groupValue: selected,
      onChanged: onClick == null ? null : (_) => onClick(),
      titleColor: titleColor,
      summary: summary,
      summaryColor: summaryColor,
      secondaryAction: endActions,
      radioButtonColors: radioButtonColors,
      radioButtonLocation: radioButtonLocation,
      bottomAction: bottomAction,
      insideMargin: insideMargin,
      holdDown: holdDownState,
      enabled: enabled,
    );
  }

  /// Main title.
  final String title;

  /// Optional summary.
  final String? summary;

  /// Source title foreground pair.
  final MiuixBasicComponentColors? titleColor;

  /// Source summary foreground pair.
  final MiuixBasicComponentColors? summaryColor;

  /// Optional leading widget.
  ///
  /// This remains available for compatibility. When supplied with the
  /// default start location it replaces the standard start radio action.
  final Widget? leading;

  /// Optional caller content before an end-positioned radio.
  final Widget? secondaryAction;

  /// Optional source radio palette.
  final MiuixRadioButtonColors? radioButtonColors;

  /// Optional full-width source content below the primary row.
  final Widget? bottomAction;

  /// Directional padding inside the complete preference.
  final EdgeInsetsGeometry insideMargin;

  /// Location of the radio mark; MIUIX defaults to the start edge.
  final MiuixRadioButtonLocation radioButtonLocation;

  /// Radio value for this row.
  final T value;

  /// Currently selected group value.
  final T? groupValue;

  /// Change callback.
  final ValueChanged<T?>? onChanged;

  /// Whether the pressed indication remains held.
  final bool holdDown;

  /// Whether the preference and its radio are interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    void selectFromRow() {
      // RadioButtonPreference.kt invokes the row callback without haptics.
      // ToggleOn/ToggleOff belongs exclusively to the nested RadioButton.
      onChanged?.call(value);
    }

    final radio = MiuixRadio<T>(
      value: value,
      groupValue: groupValue,
      enabled: enabled,
      onChanged: onChanged,
      colors: radioButtonColors,
    );
    final radioAtStart = radioButtonLocation == MiuixRadioButtonLocation.start;
    return MiuixPreference(
      title: title,
      summary: summary,
      titleColors: titleColor,
      summaryColors: summaryColor,
      leading: radioAtStart
          ? leading ??
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: radio,
                )
          : leading,
      bottomAction: bottomAction,
      insideMargin: insideMargin,
      holdDown: holdDown,
      enabled: enabled,
      onTap: enabled ? selectFromRow : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (secondaryAction != null) Flexible(child: secondaryAction!),
          // RadioButtonPreference.kt retains this for empty endActions.
          const SizedBox(width: 8),
          if (!radioAtStart) radio,
        ],
      ),
    );
  }
}

/// Range slider preference for two-value settings.
class MiuixRangeSliderPreference extends StatelessWidget {
  /// Creates a range slider preference.
  const MiuixRangeSliderPreference({
    super.key,
    required this.title,
    required this.values,
    required this.onChanged,
    this.summary,
    this.min = 0,
    this.max = 1,
    this.enabled = true,
  });

  /// Main title.
  final String title;

  /// Optional summary.
  final String? summary;

  /// Current range.
  final RangeValues values;

  /// Change callback.
  final ValueChanged<RangeValues> onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Whether the preference range slider is interactive.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final range = _safeRange(min, max);
    final safeValues = _normalizeSliderCallbackRange(values, range);
    final label =
        '${safeValues.start.toStringAsFixed(2)} - ${safeValues.end.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixPreference(
          title: title,
          summary: summary,
          enabled: enabled,
          trailing: Text(label),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: MiuixRangeSlider(
            values: safeValues,
            min: range.min,
            max: range.max,
            enabled: enabled,
            onChanged: (next) =>
                onChanged(_normalizeSliderCallbackRange(next, range)),
          ),
        ),
      ],
    );
  }
}

/// Group container for settings pages.
class MiuixSettingsGroup extends StatelessWidget {
  /// Creates a settings group.
  const MiuixSettingsGroup({
    super.key,
    required this.children,
    this.title,
    this.showDividers = false,
  });

  /// Optional section title.
  final String? title;

  /// Preference rows.
  final List<Widget> children;

  /// Whether to add separators that are not present in MIUIX `Card` itself.
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    if (children.isEmpty) {
      return title == null
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(
                theme.spacing.lg,
                theme.spacing.lg,
                theme.spacing.lg,
                theme.spacing.sm,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              theme.spacing.lg,
              theme.spacing.lg,
              theme.spacing.lg,
              theme.spacing.xs,
            ),
            child: Text(
              title!,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        MiuixSurface(
          padding: EdgeInsets.zero,
          radius: 18,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          border: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: .10),
            width: .5,
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (showDividers && index != children.length - 1)
                  Divider(
                    height: 1,
                    thickness: .5,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .24),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
