part of '../miuix_widgets.dart';

/// Immutable color contract used by [MiuixButton].
///
/// The four values map directly to `ButtonColors` in the upstream MIUIX
/// component. Keeping enabled and disabled pairs together prevents a caller
/// from changing only the painted surface while accidentally retaining an
/// unreadable inherited content color.
@immutable
class MiuixButtonColors {
  /// Creates an explicit button color set.
  const MiuixButtonColors({
    required this.color,
    required this.disabledColor,
    required this.contentColor,
    required this.disabledContentColor,
  });

  /// Enabled container color.
  final Color color;

  /// Disabled container color.
  final Color disabledColor;

  /// Enabled local content color.
  final Color contentColor;

  /// Disabled local content color.
  final Color disabledContentColor;
}

/// Immutable source color contract used by [MiuixTextButton].
@immutable
class MiuixTextButtonColors {
  /// Creates an explicit text-button color set.
  const MiuixTextButtonColors({
    required this.color,
    required this.disabledColor,
    required this.textColor,
    required this.disabledTextColor,
  });

  /// Enabled container color.
  final Color color;

  /// Disabled container color.
  final Color disabledColor;

  /// Enabled label color.
  final Color textColor;

  /// Disabled label color.
  final Color disabledTextColor;
}

/// Source defaults and theme-resolved color factories for MIUIX buttons.
abstract final class MiuixButtonDefaults {
  /// Default minimum width from `ButtonDefaults.MinWidth`.
  static const double minWidth = 58;

  /// Default minimum height from `ButtonDefaults.MinHeight`.
  static const double minHeight = 40;

  /// Default continuous-corner radius.
  static const double cornerRadius = 16;

  /// Default internal padding from `ButtonDefaults.InsideMargin`.
  static const EdgeInsets insideMargin = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 13,
  );

  /// Resolves the ordinary or primary `ButtonColors` source factory.
  ///
  /// Optional values override only their matching source field. This is useful
  /// for branded buttons while retaining the MIUIX disabled-state contract.
  static MiuixButtonColors buttonColors(
    BuildContext context, {
    bool primary = false,
    Color? color,
    Color? disabledColor,
    Color? contentColor,
    Color? disabledContentColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    return MiuixButtonColors(
      color: color ?? semantic[primary ? 'primary' : 'secondaryVariant'],
      disabledColor:
          disabledColor ??
          semantic[primary
              ? 'disabledPrimaryButton'
              : 'disabledSecondaryVariant'],
      contentColor:
          contentColor ??
          semantic[primary ? 'onPrimary' : 'onSecondaryVariant'],
      disabledContentColor:
          disabledContentColor ??
          semantic[primary
              ? 'disabledOnPrimaryButton'
              : 'disabledOnSecondaryVariant'],
    );
  }

  /// Resolves the ordinary or primary `TextButtonColors` source factory.
  static MiuixTextButtonColors textButtonColors(
    BuildContext context, {
    bool primary = false,
    Color? color,
    Color? disabledColor,
    Color? textColor,
    Color? disabledTextColor,
  }) {
    final button = buttonColors(
      context,
      primary: primary,
      color: color,
      disabledColor: disabledColor,
      contentColor: textColor,
      disabledContentColor: disabledTextColor,
    );
    return MiuixTextButtonColors(
      color: button.color,
      disabledColor: button.disabledColor,
      textColor: button.contentColor,
      disabledTextColor: button.disabledContentColor,
    );
  }
}

/// MIUIX button with the complete v1.0.9 layout contract.
///
/// [label] is the convenient compatibility form used by the Flutter example.
/// [child] is the source-equivalent arbitrary Row content slot. Exactly one
/// must be supplied; [icon] belongs only to the label convenience form.
class MiuixButton extends StatelessWidget {
  /// Creates a MIUIX button.
  const MiuixButton({
    super.key,
    required this.onPressed,
    this.label,
    this.child,
    this.icon,
    this.enabled = true,
    this.filled = false,
    this.expand = false,
    this.colors,
    this.cornerRadius = MiuixButtonDefaults.cornerRadius,
    this.minWidth = MiuixButtonDefaults.minWidth,
    this.minHeight = MiuixButtonDefaults.minHeight,
    this.insideMargin = MiuixButtonDefaults.insideMargin,
    this.showIndication = true,
  }) : assert(
         (label == null) != (child == null),
         'Supply exactly one of label or child.',
       ),
       assert(
         child == null || icon == null,
         'The icon convenience is available only with label.',
       ),
       assert(cornerRadius >= 0),
       assert(minWidth >= 0),
       assert(minHeight >= 0);

  /// Compatibility text label.
  final String? label;

  /// Source-equivalent arbitrary content.
  final Widget? child;

  /// Optional leading icon for the label convenience form.
  final Widget? icon;

  /// Callback invoked by an enabled button.
  final VoidCallback? onPressed;

  /// Whether the source surface installs its click behavior.
  ///
  /// A null [onPressed] also disables activation for Flutter compatibility.
  final bool enabled;

  /// Compatibility shortcut selecting the primary source color factory.
  final bool filled;

  /// Whether a loose horizontal parent is filled.
  ///
  /// This adapter is intentionally outside the source component contract; it
  /// preserves the original Flutter package's convenient full-width form.
  final bool expand;

  /// Explicit enabled and disabled source color pairs.
  final MiuixButtonColors? colors;

  /// Continuous-corner radius.
  final double cornerRadius;

  /// Minimum complete button width, including [insideMargin].
  final double minWidth;

  /// Minimum complete button height, including [insideMargin].
  final double minHeight;

  /// Padding inside the surface and outside its Row content.
  final EdgeInsetsGeometry insideMargin;

  /// Whether the source indication is installed.
  ///
  /// This is the Flutter equivalent of passing a non-null `Indication`.
  final bool showIndication;

  @override
  Widget build(BuildContext context) {
    final resolvedColors =
        colors ?? MiuixButtonDefaults.buttonColors(context, primary: filled);
    final effectiveEnabled = enabled && onPressed != null;
    final foreground = effectiveEnabled
        ? resolvedColors.contentColor
        : resolvedColors.disabledContentColor;
    final content =
        child ??
        _MiuixButtonLabelContent(label: label!, icon: icon, color: foreground);
    final button = _MiuixButtonSurface(
      content: content,
      onPressed: onPressed,
      enabled: effectiveEnabled,
      colors: resolvedColors,
      cornerRadius: cornerRadius,
      minWidth: minWidth,
      minHeight: minHeight,
      insideMargin: insideMargin,
      showIndication: showIndication,
    );
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Text-only adapter matching the upstream `TextButton` overload.
class MiuixTextButton extends StatelessWidget {
  /// Creates a source-style text button.
  const MiuixTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.enabled = true,
    this.colors,
    this.cornerRadius = MiuixButtonDefaults.cornerRadius,
    this.minWidth = MiuixButtonDefaults.minWidth,
    this.minHeight = MiuixButtonDefaults.minHeight,
    this.insideMargin = MiuixButtonDefaults.insideMargin,
    this.showIndication = true,
  }) : assert(cornerRadius >= 0),
       assert(minWidth >= 0),
       assert(minHeight >= 0);

  /// Source text.
  final String label;

  /// Callback invoked by an enabled button.
  final VoidCallback? onPressed;

  /// Compatibility leading icon.
  ///
  /// The upstream TextButton is text-only, but keeping this optional adapter
  /// avoids breaking applications built against earlier Flutter releases.
  final Widget? icon;

  /// Whether the source surface installs its click behavior.
  final bool enabled;

  /// Explicit enabled and disabled text-button colors.
  final MiuixTextButtonColors? colors;

  /// Continuous-corner radius.
  final double cornerRadius;

  /// Minimum complete width.
  final double minWidth;

  /// Minimum complete height.
  final double minHeight;

  /// Padding around the label.
  final EdgeInsetsGeometry insideMargin;

  /// Whether the source indication is installed.
  final bool showIndication;

  @override
  Widget build(BuildContext context) {
    final textColors = colors ?? MiuixButtonDefaults.textButtonColors(context);
    final buttonColors = MiuixButtonColors(
      color: textColors.color,
      disabledColor: textColors.disabledColor,
      contentColor: textColors.textColor,
      disabledContentColor: textColors.disabledTextColor,
    );
    final effectiveEnabled = enabled && onPressed != null;
    final foreground = effectiveEnabled
        ? textColors.textColor
        : textColors.disabledTextColor;
    return _MiuixButtonSurface(
      content: _MiuixButtonLabelContent(
        label: label,
        icon: icon,
        color: foreground,
      ),
      onPressed: onPressed,
      enabled: effectiveEnabled,
      colors: buttonColors,
      cornerRadius: cornerRadius,
      minWidth: minWidth,
      minHeight: minHeight,
      insideMargin: insideMargin,
      showIndication: showIndication,
    );
  }
}

/// Builds only the compatibility label; arbitrary content remains untouched.
class _MiuixButtonLabelContent extends StatelessWidget {
  const _MiuixButtonLabelContent({
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: color,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      fontSize: 17,
    );
    final ratio = MediaQuery.devicePixelRatioOf(context);
    final scaledFontSize = MediaQuery.textScalerOf(
      context,
    ).scale(textStyle?.fontSize ?? 17);
    final sourceLineHeight = _miuixCeilLogicalDimension(
      scaledFontSize * (textStyle?.height ?? 1.16),
      ratio,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          IconTheme(
            data: IconThemeData(color: color, size: 16),
            child: icon!,
          ),
          const SizedBox(width: 6),
        ],
        SizedBox(
          height: sourceLineHeight,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Shared Surface/Row implementation used by both public button overloads.
class _MiuixButtonSurface extends StatelessWidget {
  const _MiuixButtonSurface({
    required this.content,
    required this.onPressed,
    required this.enabled,
    required this.colors,
    required this.cornerRadius,
    required this.minWidth,
    required this.minHeight,
    required this.insideMargin,
    required this.showIndication,
  });

  final Widget content;
  final VoidCallback? onPressed;
  final bool enabled;
  final MiuixButtonColors colors;
  final double cornerRadius;
  final double minWidth;
  final double minHeight;
  final EdgeInsetsGeometry insideMargin;
  final bool showIndication;

  @override
  Widget build(BuildContext context) {
    final background = enabled ? colors.color : colors.disabledColor;
    final foreground = enabled
        ? colors.contentColor
        : colors.disabledContentColor;
    final radius = BorderRadius.circular(cornerRadius);
    final ShapeBorder shape = MiuixTheme.of(context).enableSquircle
        ? MiuixSquircleBorder(borderRadius: radius)
        : RoundedRectangleBorder(borderRadius: radius);
    final buttonPadding = _miuixRoundedInsets(context, insideMargin);
    final pressable = MiuixPressable(
      onTap: enabled ? onPressed : null,
      // Button.kt gives Surface and LocalIndication the same miuixShape.
      shape: shape,
      feedbackType: MiuixPressFeedbackType.none,
      showIndication: enabled && showIndication,
      child: DecoratedBox(
        key: const ValueKey('miuix-button-surface'),
        decoration: ShapeDecoration(color: background, shape: shape),
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
          child: Padding(
            // Compose rounds each PaddingValues edge independently. Keeping
            // that work above the Row reproduces the 34 + 52 + 34 = 120px
            // reference label height at 420dpi.
            padding: buttonPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  child: IconTheme.merge(
                    data: IconThemeData(color: foreground),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(button: true, enabled: enabled, child: pressable);
  }
}
