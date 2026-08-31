part of '../miuix_widgets.dart';

/// Source constants used by [MiuixFloatingActionButton].
abstract final class MiuixFloatingActionButtonDefaults {
  /// Default minimum width in logical pixels.
  static const double minWidth = 60;

  /// Default minimum height in logical pixels.
  static const double minHeight = 60;

  /// Default graphics-layer shadow elevation in logical pixels.
  static const double shadowElevation = 4;
}

/// Floating action button matching MIUIX's source surface contract.
///
/// The upstream component is a clickable capsule surface with a 60dp minimum
/// size and 4dp elevation. It does not impose a maximum size or force its
/// arbitrary content into a smaller icon box.
class MiuixFloatingActionButton extends StatelessWidget {
  /// Creates a floating action button.
  const MiuixFloatingActionButton({
    super.key,
    this.icon,
    this.child,
    required this.onPressed,
    this.label,
    this.shape,
    this.containerColor,
    this.contentColor,
    this.shadowElevation = MiuixFloatingActionButtonDefaults.shadowElevation,
    this.minWidth = MiuixFloatingActionButtonDefaults.minWidth,
    this.minHeight = MiuixFloatingActionButtonDefaults.minHeight,
  }) : assert(icon != null || child != null),
       assert(label == null || child == null),
       assert(shadowElevation >= 0),
       assert(minWidth >= 0),
       assert(minHeight >= 0);

  /// Convenience icon displayed inside the source-sized content box.
  ///
  /// Use [child] instead when the content is not an icon.
  final Widget? icon;

  /// Arbitrary source-style content.
  ///
  /// This mirrors the Compose content slot and takes precedence over the
  /// icon convenience layout.
  final Widget? child;

  /// Optional Flutter convenience label placed beside [icon].
  ///
  /// MIUIX itself exposes arbitrary [child] content rather than a separate
  /// extended variant. This adapter retains the older package API while still
  /// using the source 60dp minimum height and capsule shape.
  final String? label;

  /// Press callback.
  ///
  /// Upstream requires a callback. A nullable value is retained as a Flutter
  /// compatibility adapter for disabled application states.
  final VoidCallback? onPressed;

  /// Optional exact capsule or custom surface shape.
  final ShapeBorder? shape;

  /// Optional container color; defaults to MIUIX `primary`.
  final Color? containerColor;

  /// Optional inherited icon/text color.
  ///
  /// The source `Surface` supplies `onSurface`. Its example explicitly passes
  /// `onPrimary` to the link icon.
  final Color? contentColor;

  /// Source shadow elevation in logical pixels.
  final double shadowElevation;

  /// Minimum source surface width.
  final double minWidth;

  /// Minimum source surface height.
  final double minHeight;

  /// Creates the source capsule selected by the smooth-rounding theme switch.
  ShapeBorder _defaultShape(BuildContext context) {
    return MiuixTheme.of(context).enableSquircle
        ? const MiuixCapsuleBorder()
        : const StadiumBorder();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onPressed != null;
    final foreground = contentColor ?? scheme.onSurface;
    final background = containerColor ?? scheme.primary;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Compose defaultMinSize resolves each Dp constraint to an integer
    // physical pixel. At 420dpi the 60dp defaults are therefore 158px, not
    // Flutter's fractional 157.5px layout.
    final effectiveMinWidth = _miuixRoundLogicalDimension(minWidth, pixelRatio);
    final effectiveMinHeight = _miuixRoundLogicalDimension(
      minHeight,
      pixelRatio,
    );
    final effectiveShape = shape ?? _defaultShape(context);
    final effectiveChild =
        child ??
        (label == null
            ? Align(widthFactor: 1, heightFactor: 1, child: icon)
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon!,
                    const SizedBox(width: 10),
                    Text(
                      label!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ));
    // FloatingActionButton.kt delegates its complete surface to Surface. This
    // local decoration keeps that already-verified shadow/indication geometry
    // while the capsule itself now follows the final laid-out dimensions.
    final button = DecoratedBox(
      key: const ValueKey('miuix-floating-action-button-surface'),
      decoration: ShapeDecoration(
        color: background,
        shape: effectiveShape,
        shadows: shadowElevation <= 0
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: .20),
                  blurRadius: shadowElevation * 2,
                  offset: Offset(0, shadowElevation / 2),
                ),
              ],
      ),
      child: MiuixPressable(
        onTap: onPressed,
        shape: effectiveShape,
        feedbackType: MiuixPressFeedbackType.none,
        showIndication: enabled,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: effectiveMinWidth,
            minHeight: effectiveMinHeight,
          ),
          child: _MiuixContentColor(
            color: foreground,
            child: IconTheme(
              data: IconThemeData(color: foreground, size: 24),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: foreground),
                child: effectiveChild,
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(button: true, enabled: enabled, child: button);
  }
}
