part of '../miuix_widgets.dart';

/// Defaults from MIUIX v1.0.9 `SmallTitleDefaults`.
abstract final class MiuixSmallTitleDefaults {
  /// Default source inside margin: 28dp horizontally and 8dp vertically.
  static const EdgeInsets insideMargin = EdgeInsets.symmetric(
    horizontal: 28,
    vertical: 8,
  );
}

/// Small title label for grouped lists and secondary sections.
///
/// This is the direct Flutter counterpart of `SmallTitle.kt`: it applies the
/// caller-equivalent outer widget constraints first, then source inside
/// padding, and finally the MIUIX subtitle text role.
class MiuixSmallTitle extends StatelessWidget {
  /// Creates a source-equivalent small title.
  const MiuixSmallTitle(
    this.title, {
    super.key,
    this.textColor,
    this.insideMargin,
  });

  /// Title text.
  final String title;

  /// Source-name alias retained alongside the existing [title] field.
  String get text => title;

  /// Optional title color, defaulting to `onBackgroundVariant`.
  final Color? textColor;

  /// Optional source-compatible padding around the label.
  ///
  /// Null resolves to [MiuixSmallTitleDefaults.insideMargin].
  final EdgeInsetsGeometry? insideMargin;

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final padding = _miuixRoundedInsets(
      context,
      insideMargin ?? MiuixSmallTitleDefaults.insideMargin,
    );
    final foreground = textColor ?? semantic['onBackgroundVariant'];
    final style = Theme.of(context).textTheme.titleSmall?.copyWith(
      // Compose uses onBackgroundVariant, not Material's unrelated
      // onSurfaceVariant role, for grouped-list section labels.
      color: foreground,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      letterSpacing: 0,
    );
    final fontSize = MediaQuery.textScalerOf(
      context,
    ).scale(style?.fontSize ?? 14);
    // Text scaling is applied before physical rounding for the same reason
    // Compose converts `sp` through scaledDensity before measuring Text. This
    // keeps accessibility font sizes responsive instead of freezing the label
    // at the default 43px line box used by the reference emulator. Rounding
    // only the minimum line height also lets a wrapped title grow naturally.
    final sourceLineHeight = _miuixRoundLogicalDimension(
      fontSize * (style?.height ?? 1.16),
      pixelRatio,
    );
    return Padding(
      // SmallTitleDefaults.InsideMargin is PaddingValues(28.dp, 8.dp).
      // Compose resolves every padding edge and the text placeable to integer
      // physical pixels before adding them. Keep those stages separate so a
      // 2.625-density Android screen measures 21 + 43 + 21 = 85px rather than
      // Flutter's former 84px combined result. The minimum remains flexible
      // so accessibility scaling and exceptionally long labels can grow.
      padding: padding,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: sourceLineHeight),
        child: MiuixText(title, color: foreground, style: style),
      ),
    );
  }
}
