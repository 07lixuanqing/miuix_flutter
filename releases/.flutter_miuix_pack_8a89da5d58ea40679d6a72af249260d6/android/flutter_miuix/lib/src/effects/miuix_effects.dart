import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../theme/miuix_semantic_colors.dart';
import '../theme/miuix_theme.dart';

/// Press feedback variants used by Miuix controls.
enum MiuixPressFeedbackType {
  /// Scale the child down while pressed.
  sink,

  /// Keep layout stable and only expose hover/press callbacks.
  none,

  /// Rotate the child subtly toward the pointer position while pressed.
  tilt,
}

/// Observable press state shared by source-compatible MIUIX controls.
///
/// Compose accepts a nullable `MutableInteractionSource` on controls such as
/// `TabRow`. Flutter owns its gesture recognizers inside [MiuixPressable], so
/// this small adapter publishes the same externally observable pressed state
/// without exposing framework-specific pointer events.
class MiuixInteractionSource extends ChangeNotifier {
  bool _pressed = false;
  bool _focused = false;

  /// Whether a pointer is currently pressing a connected control.
  bool get pressed => _pressed;

  /// Whether a connected focusable control currently owns focus.
  bool get focused => _focused;

  /// Publishes a new pressed state.
  void setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    _pressed = value;
    notifyListeners();
  }

  /// Publishes a new focus state.
  ///
  /// Compose uses the same `MutableInteractionSource` for press and focus
  /// interactions. Keeping both signals here lets source-compatible input
  /// fields expose the same observable state without leaking a [FocusNode].
  void setFocused(bool value) {
    if (_focused == value) {
      return;
    }
    _focused = value;
    notifyListeners();
  }
}

/// Exact spring used by MIUIX `SinkFeedback`.
@visibleForTesting
SpringDescription debugMiuixSinkSpring({
  double dampingRatio = .8,
  double stiffness = 600,
}) => SpringDescription.withDampingRatio(
  mass: 1,
  stiffness: stiffness,
  ratio: dampingRatio,
);

/// Exact spring used by MIUIX `TiltFeedback`.
@visibleForTesting
SpringDescription debugMiuixTiltSpring() =>
    SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: .6);

/// Flutter projective entry matching MIUIX's 12-density camera distance.
///
/// Android and Matrix4 use opposite camera-axis conventions. A positive entry
/// expands the far edge and then lets the outer clip disguise the tilt; the
/// negative entry makes the far edge recede like the source graphics layer.
@visibleForTesting
double debugMiuixTiltPerspective() => -.0012;

/// Resolves the quadrant pivot and ±8-degree rotation from the source node.
@visibleForTesting
({Alignment origin, double rotationXDegrees, double rotationYDegrees})
debugMiuixTiltTarget(Offset localPosition, Size size) {
  if (size.isEmpty) {
    return (origin: Alignment.center, rotationXDegrees: 0, rotationYDegrees: 0);
  }
  final pressOnLeft = localPosition.dx < size.width / 2;
  final pressOnTop = localPosition.dy < size.height / 2;
  return (
    // Compose uses the opposite corner as TransformOrigin.
    origin: Alignment(pressOnLeft ? 1 : -1, pressOnTop ? 1 : -1),
    rotationXDegrees: pressOnTop ? 8 : -8,
    rotationYDegrees: pressOnLeft ? -8 : 8,
  );
}

/// Blend operations supported by MIUIX texture-blur color layers.
///
/// Standard entries use native Skia operations. MIUIX's Lab and extended
/// entries are evaluated by the package runtime shader when Impeller supports
/// shader image filters, with a chroma-preserving Skia fallback elsewhere.
enum MiuixBlurBlendMode {
  /// Draw the source color over the blurred destination.
  srcOver,

  /// Screen blend.
  screen,

  /// Multiply blend.
  multiply,

  /// Overlay blend.
  overlay,

  /// Soft-light blend.
  softLight,

  /// Hard-light blend.
  hardLight,

  /// Color-dodge blend.
  colorDodge,

  /// Color-burn blend.
  colorBurn,

  /// Linear-light source mode, rendered with portable hard light.
  linearLight,

  /// Greyscale linear-light source mode.
  linearLightWithGreyscale,

  /// Lab linear-light source mode.
  linearLightLab,

  /// Lab source color mode.
  lab,

  /// Lab lightening mode.
  labLightenWithGreyscale,

  /// Lab darkening mode.
  labDarkenWithGreyscale,

  /// MIUI difference mode.
  miDifference,

  /// MIUI color-dodge mode.
  miColorDodge,

  /// MIUI color-burn mode.
  miColorBurn,

  /// Additive lightening mode.
  plusLighter,

  /// Additive darkening mode.
  plusDarker,

  /// Luminosity blend.
  luminosity,
}

/// One ordered color layer applied after backdrop blur.
@immutable
class MiuixBlurBlendEntry {
  /// Creates a color and blend-operation pair.
  const MiuixBlurBlendEntry(this.color, this.mode);

  /// Color, including the layer's source alpha.
  final Color color;

  /// Operation used to composite [color] over the blurred destination.
  final MiuixBlurBlendMode mode;
}

/// Color configuration for blur and glass surfaces.
@immutable
class MiuixBlurColors {
  /// Creates a blur color set.
  const MiuixBlurColors({
    this.tint,
    this.border,
    this.highlight,
    this.opacity = 0.72,
    this.blendColors = const [],
  });

  /// Optional surface tint.
  final Color? tint;

  /// Optional outline color.
  final Color? border;

  /// Optional highlight color.
  final Color? highlight;

  /// Tint opacity used by glass surfaces.
  final double opacity;

  /// Ordered MIUIX blend-color layers painted over the sampled backdrop.
  final List<MiuixBlurBlendEntry> blendColors;
}

/// Light position used by highlight effects.
@immutable
class MiuixLightPosition {
  /// Creates a normalized light position.
  const MiuixLightPosition({this.dx = -0.35, this.dy = -0.85});

  /// Horizontal light offset.
  final double dx;

  /// Vertical light offset.
  final double dy;
}

/// Highlight configuration for glass and liquid-like panels.
@immutable
class MiuixHighlight {
  /// Creates a highlight description.
  const MiuixHighlight({
    this.color = const Color(0x66FFFFFF),
    this.blur = 18,
    this.position = const MiuixLightPosition(),
  });

  /// Highlight color.
  final Color color;

  /// Softness applied by the painter.
  final double blur;

  /// Where the virtual light source sits.
  final MiuixLightPosition position;
}

/// Backdrop abstraction used by glass and popup adapters.
///
/// MIUIX has a richer Compose backdrop pipeline. Flutter apps can pass this
/// object to keep blur/tint values together without coupling to widget details.
@immutable
class MiuixBackdrop {
  /// Creates backdrop effect data.
  const MiuixBackdrop({
    this.blur = 20,
    this.noise = 0,
    this.brightness = 0,
    this.contrast = 1,
    this.saturation = 1,
    this.colors = const MiuixBlurColors(),
    this.highlight,
    this.enabled = true,
  });

  /// MIUIX blur radius in physical pixels.
  ///
  /// The source runtime converts this radius to a Gaussian sigma with a 0.45
  /// coefficient before sampling. [MiuixLayerBackdrop] also converts that
  /// physical sigma to Flutter logical pixels for the current display.
  final double blur;

  /// Fine grain strength from 0 to 0.1.
  final double noise;

  /// Brightness adjustment from -1 to 1.
  final double brightness;

  /// Contrast multiplier, where 1 is neutral.
  final double contrast;

  /// Saturation multiplier, where 1 is neutral.
  final double saturation;

  /// Tint and border colors.
  final MiuixBlurColors colors;

  /// Optional highlight effect.
  final MiuixHighlight? highlight;

  /// Whether backdrop rendering is active.
  final bool enabled;
}

// GaussianBlurEffect.kt treats the public radius as a physical-pixel value,
// multiplies it by RADIUS_TO_SIGMA (0.45), and only then runs the separable
// kernel. Flutter's ImageFilter.blur receives a logical-pixel sigma, so the
// device ratio must be removed here or a 420-dpi Android device over-blurs the
// source value by 2.625 / 0.45 (about 5.8 times).
double _miuixSourceBlurSigma(double physicalRadius, double pixelRatio) {
  final radius = physicalRadius.isFinite ? math.max(0, physicalRadius) : 0.0;
  final ratio = pixelRatio.isFinite && pixelRatio > 0 ? pixelRatio : 1.0;
  return radius * .45 / ratio;
}

/// Widget adapter for MIUIX LayerBackdrop.
class MiuixLayerBackdrop extends StatefulWidget {
  /// Creates a layer backdrop around [child].
  const MiuixLayerBackdrop({
    super.key,
    required this.child,
    this.backdrop = const MiuixBackdrop(),
    this.radius,
    this.padding,
  });

  /// Content drawn above the backdrop.
  final Widget child;

  /// Backdrop effect data.
  final MiuixBackdrop backdrop;

  /// Optional corner radius.
  final double? radius;

  /// Optional inner padding.
  final EdgeInsetsGeometry? padding;

  @override
  State<MiuixLayerBackdrop> createState() => _MiuixLayerBackdropState();
}

class _MiuixLayerBackdropState extends State<MiuixLayerBackdrop> {
  static Future<FragmentProgram?>? _programFuture;
  FragmentShader? _blendShader;

  @override
  void initState() {
    super.initState();
    _ensureBlendShader();
  }

  @override
  void didUpdateWidget(covariant MiuixLayerBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_blendShader == null && widget.backdrop.colors.blendColors.isNotEmpty) {
      _ensureBlendShader();
    }
  }

  Future<void> _ensureBlendShader() async {
    if (_blendShader != null ||
        widget.backdrop.colors.blendColors.isEmpty ||
        !ImageFilter.isShaderFilterSupported) {
      return;
    }
    _programFuture ??= _loadBlendProgram();
    final program = await _programFuture;
    if (!mounted || program == null) return;
    setState(() => _blendShader = program.fragmentShader());
  }

  static Future<FragmentProgram?> _loadBlendProgram() async {
    try {
      return await FragmentProgram.fromAsset(
        'packages/flutter_miuix/shaders/miuix_texture_blend.frag',
      );
    } catch (_) {
      // Root package tests use the unprefixed key while consuming apps use the
      // package-qualified asset key.
      try {
        return await FragmentProgram.fromAsset(
          'shaders/miuix_texture_blend.frag',
        );
      } catch (_) {
        return null;
      }
    }
  }

  @override
  void dispose() {
    _blendShader?.dispose();
    super.dispose();
  }

  ImageFilter? _textureFilter(double logicalSigma) {
    final shader = _blendShader;
    final entries = widget.backdrop.colors.blendColors;
    if (shader == null || entries.isEmpty) return null;

    // The engine owns float slots 0-1 for the input texture size. Remaining
    // slots follow the fragment shader declarations exactly.
    shader.setFloat(2, entries.length.clamp(0, 8).toDouble());
    for (var index = 0; index < 8; index++) {
      final offset = 3 + index * 4;
      if (index < entries.length) {
        final entry = entries[index];
        final alpha = entry.color.a;
        // The upstream shader receives premultiplied layer colors and
        // unpremultiplies custom modes before dispatch.
        shader
          ..setFloat(offset, entry.color.r * alpha)
          ..setFloat(offset + 1, entry.color.g * alpha)
          ..setFloat(offset + 2, entry.color.b * alpha)
          ..setFloat(offset + 3, alpha);
      } else {
        shader
          ..setFloat(offset, 0)
          ..setFloat(offset + 1, 0)
          ..setFloat(offset + 2, 0)
          ..setFloat(offset + 3, 0);
      }
    }
    for (var index = 0; index < 8; index++) {
      shader.setFloat(
        35 + index,
        index < entries.length ? _sourceBlendMode(entries[index].mode) : 3,
      );
    }
    // The last three uniforms deliberately live inside the accelerated
    // texture filter instead of wrapping its output in ColorFiltered.
    // MIUIX adjusts the sampled backdrop before applying its ordered blend
    // colors; reversing that order changes contrast-sensitive blend modes.
    // Keep these indices synchronized with miuix_texture_blend.frag whenever
    // either the blend entry capacity or shader uniform declarations change.
    // Brightness is an additive signed value, while contrast and saturation
    // are non-negative multipliers whose neutral value is exactly one.
    shader
      ..setFloat(43, widget.backdrop.brightness.clamp(-1.0, 1.0))
      ..setFloat(44, widget.backdrop.contrast.clamp(0.0, 3.0))
      ..setFloat(45, widget.backdrop.saturation.clamp(0.0, 3.0));
    try {
      return ImageFilter.compose(
        outer: ImageFilter.shader(shader),
        inner: ImageFilter.blur(sigmaX: logicalSigma, sigmaY: logicalSigma),
      );
    } on UnsupportedError {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final backdrop = widget.backdrop;
    final tint = backdrop.colors.tint ?? scheme.surface;
    final logicalSigma = _miuixSourceBlurSigma(
      backdrop.blur,
      MediaQuery.devicePixelRatioOf(context),
    );
    final acceleratedFilter = _textureFilter(logicalSigma);
    final fallbackBlendEntries = acceleratedFilter == null
        ? backdrop.colors.blendColors
        : const <MiuixBlurBlendEntry>[];
    final hasColorControls =
        backdrop.brightness != 0 ||
        backdrop.contrast != 1 ||
        backdrop.saturation != 1;
    final content = Stack(
      fit: StackFit.passthrough,
      children: [
        // DrawBackdropModifier applies full-resolution noise after its effect
        // chain, then draws ordinary component content above that backdrop.
        // Keeping noise first prevents it from dirtying labels and icons.
        if (backdrop.noise > 0)
          Positioned.fill(
            key: const ValueKey('miuix-blur-noise-layer'),
            child: IgnorePointer(
              child: CustomPaint(painter: _MiuixNoisePainter(backdrop.noise)),
            ),
          ),
        widget.child,
      ],
    );
    final border = backdrop.colors.border == null
        ? BorderSide(
            color: scheme.outlineVariant.withValues(alpha: .14),
            width: .5,
          )
        : BorderSide(color: backdrop.colors.border!, width: .5);
    final innerDecoration = BoxDecoration(
      // Preserve an explicitly transparent texture-blur tint. Replacing its
      // alpha with .06 introduced a black wash absent from MIUIX.
      // BackdropFilter needs a painted child for its sampled pixels to
      // participate in an outer DstIn ShaderMask. A one-alpha sentinel is
      // visually transparent but keeps foreground-blur glyphs alive on Skia;
      // an actual tint retains its requested alpha semantics.
      color: tint.a == 0
          ? const Color(0x01000000)
          : tint.withValues(alpha: tint.a * 0.06),
      borderRadius: BorderRadius.circular(widget.radius ?? 18),
    );
    Widget glass = MiuixGlass(
      blur: logicalSigma,
      opacity: backdrop.colors.opacity,
      radius: widget.radius,
      padding: widget.padding,
      imageFilter: acceleratedFilter,
      enabled: backdrop.enabled,
      useGlobalIntensity: false,
      showSpecular: false,
      border: border,
      child: DecoratedBox(decoration: innerDecoration, child: content),
    );
    if (fallbackBlendEntries.isNotEmpty) {
      final theme = MiuixTheme.of(context);
      final effectiveRadius = widget.radius ?? theme.radius.lg;
      final ShapeBorder shape = theme.enableSquircle
          ? MiuixSquircleBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(effectiveRadius),
            );
      Widget filteredBackground = MiuixGlass(
        blur: logicalSigma,
        opacity: backdrop.colors.opacity,
        radius: widget.radius,
        padding: EdgeInsets.zero,
        enabled: backdrop.enabled,
        useGlobalIntensity: false,
        showSpecular: false,
        border: border,
        child: DecoratedBox(
          decoration: innerDecoration,
          child: const SizedBox.expand(),
        ),
      );
      if (hasColorControls) {
        filteredBackground = ColorFiltered(
          key: const ValueKey('miuix-blur-color-controls'),
          colorFilter: ColorFilter.matrix(_miuixBackdropColorMatrix(backdrop)),
          child: filteredBackground,
        );
      }
      // A child CustomPaint cannot blend against BackdropFilter's sampled
      // pixels on Skia because they live in a preceding engine layer. Apply
      // native color filters to a background-only blur layer instead, then
      // paint the component content above it so glyphs remain unaffected.
      for (final entry in fallbackBlendEntries) {
        filteredBackground = ColorFiltered(
          colorFilter: ColorFilter.mode(
            entry.color,
            _fallbackBlendMode(entry.mode),
          ),
          child: filteredBackground,
        );
      }
      glass = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            Positioned.fill(
              child: KeyedSubtree(
                key: const ValueKey('miuix-blur-blend-layers'),
                child: filteredBackground,
              ),
            ),
            Padding(
              padding: widget.padding ?? EdgeInsets.all(theme.spacing.lg),
              child: content,
            ),
          ],
        ),
      );
    }
    if (!hasColorControls ||
        acceleratedFilter != null ||
        fallbackBlendEntries.isNotEmpty) {
      return glass;
    }
    return ColorFiltered(
      key: const ValueKey('miuix-blur-color-controls'),
      colorFilter: ColorFilter.matrix(_miuixBackdropColorMatrix(backdrop)),
      child: glass,
    );
  }
}

double _sourceBlendMode(MiuixBlurBlendMode mode) {
  return switch (mode) {
    MiuixBlurBlendMode.srcOver => 3,
    MiuixBlurBlendMode.screen => 14,
    MiuixBlurBlendMode.multiply => 24,
    MiuixBlurBlendMode.overlay => 15,
    MiuixBlurBlendMode.softLight => 21,
    MiuixBlurBlendMode.hardLight => 20,
    MiuixBlurBlendMode.colorDodge => 18,
    MiuixBlurBlendMode.colorBurn => 19,
    MiuixBlurBlendMode.linearLight => 100,
    MiuixBlurBlendMode.linearLightWithGreyscale => 101,
    MiuixBlurBlendMode.miDifference => 102,
    MiuixBlurBlendMode.labLightenWithGreyscale => 103,
    MiuixBlurBlendMode.labDarkenWithGreyscale => 105,
    MiuixBlurBlendMode.lab => 106,
    MiuixBlurBlendMode.linearLightLab => 107,
    MiuixBlurBlendMode.miColorDodge => 118,
    MiuixBlurBlendMode.miColorBurn => 119,
    MiuixBlurBlendMode.plusDarker => 120,
    MiuixBlurBlendMode.plusLighter => 121,
    MiuixBlurBlendMode.luminosity => 28,
  };
}

BlendMode _fallbackBlendMode(MiuixBlurBlendMode mode) {
  return switch (mode) {
    MiuixBlurBlendMode.srcOver => BlendMode.srcOver,
    MiuixBlurBlendMode.screen => BlendMode.screen,
    MiuixBlurBlendMode.multiply => BlendMode.multiply,
    MiuixBlurBlendMode.overlay => BlendMode.overlay,
    MiuixBlurBlendMode.softLight => BlendMode.softLight,
    MiuixBlurBlendMode.hardLight => BlendMode.hardLight,
    MiuixBlurBlendMode.colorDodge => BlendMode.colorDodge,
    MiuixBlurBlendMode.colorBurn => BlendMode.colorBurn,
    MiuixBlurBlendMode.linearLight => BlendMode.hardLight,
    MiuixBlurBlendMode.linearLightWithGreyscale => BlendMode.softLight,
    MiuixBlurBlendMode.linearLightLab => BlendMode.hardLight,
    MiuixBlurBlendMode.lab => BlendMode.color,
    MiuixBlurBlendMode.labLightenWithGreyscale => BlendMode.lighten,
    MiuixBlurBlendMode.labDarkenWithGreyscale => BlendMode.darken,
    MiuixBlurBlendMode.miDifference => BlendMode.difference,
    MiuixBlurBlendMode.miColorDodge => BlendMode.colorDodge,
    MiuixBlurBlendMode.miColorBurn => BlendMode.colorBurn,
    MiuixBlurBlendMode.plusLighter => BlendMode.plus,
    MiuixBlurBlendMode.plusDarker => BlendMode.darken,
    MiuixBlurBlendMode.luminosity => BlendMode.luminosity,
  };
}

// Produces one combined saturation/contrast/brightness matrix. Keeping this
// composition in the effect layer lets examples and applications use the same
// parameters as MIUIX TextureBlur without nesting several filters.
List<double> _miuixBackdropColorMatrix(MiuixBackdrop backdrop) {
  final saturation = backdrop.saturation.clamp(0.0, 3.0);
  final contrast = backdrop.contrast.clamp(0.0, 3.0);
  final brightness = backdrop.brightness.clamp(-1.0, 1.0);
  // BackdropEffectScope.kt uses the exact three luma constants below rather
  // than the higher-precision Rec.709 coefficients.
  const red = .213;
  const green = .715;
  const blue = .072;
  final inverse = 1 - saturation;
  final offset = 255 * (.5 - contrast * .5 + brightness);
  return [
    (red * inverse + saturation) * contrast,
    green * inverse * contrast,
    blue * inverse * contrast,
    0,
    offset,
    red * inverse * contrast,
    (green * inverse + saturation) * contrast,
    blue * inverse * contrast,
    0,
    offset,
    red * inverse * contrast,
    green * inverse * contrast,
    (blue * inverse + saturation) * contrast,
    0,
    offset,
    0,
    0,
    0,
    1,
    0,
  ];
}

/// Returns the exact source color-control matrix for regression tests.
@visibleForTesting
List<double> debugMiuixBackdropColorMatrix(MiuixBackdrop backdrop) =>
    _miuixBackdropColorMatrix(backdrop);

class _MiuixNoisePainter extends CustomPainter {
  const _MiuixNoisePainter(this.strength);

  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final random = math.Random(0x4D495549);
    final count = math.max(24, (size.width * size.height / 180).round());
    final paint = Paint()..strokeWidth = 1;
    for (var index = 0; index < count; index++) {
      final light = random.nextBool();
      paint.color = (light ? Colors.white : Colors.black).withValues(
        alpha: strength.clamp(0.0, .1) * (.35 + random.nextDouble() * .65),
      );
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .5,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiuixNoisePainter oldDelegate) {
    return strength != oldDelegate.strength;
  }
}

/// A G2-style continuous-corner border matching MIUIX `SmoothCornerPath`.
///
/// MIUIX starts each corner farther along the straight edge than a circular
/// rounded rectangle, then uses a cubic Bézier with a 0.63 control ratio. When
/// adjacent corners run out of space, the curve continuously degrades toward a
/// standard 0.5523 circular approximation instead of clipping or overlapping.
class MiuixSquircleBorder extends ShapeBorder {
  /// Creates a MIUIX smooth-corner border.
  const MiuixSquircleBorder({
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.side = BorderSide.none,
  });

  /// Radius used by the approximated continuous corner.
  final BorderRadius borderRadius;

  /// Optional outline side.
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    final inset = side.width;
    final innerRect = rect.deflate(inset);
    if (innerRect.isEmpty) {
      return Path();
    }
    final resolved = borderRadius.resolve(textDirection);
    return _MiuixSmoothCornerPath.build(
      innerRect,
      _subtractRadius(resolved, inset),
    );
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _MiuixSmoothCornerPath.build(
      rect,
      borderRadius.resolve(textDirection),
    );
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side == BorderSide.none || side.width == 0) {
      return;
    }
    final centerRect = rect.deflate(side.width / 2);
    if (centerRect.isEmpty) {
      return;
    }
    final resolved = borderRadius.resolve(textDirection);
    final path = _MiuixSmoothCornerPath.build(
      centerRect,
      _subtractRadius(resolved, side.width / 2),
    );
    canvas.drawPath(path, side.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return MiuixSquircleBorder(
      borderRadius: borderRadius * t,
      side: side.scale(t),
    );
  }

  static BorderRadius _subtractRadius(BorderRadius value, double amount) {
    Radius subtract(Radius radius) => Radius.elliptical(
      math.max(0, radius.x - amount),
      math.max(0, radius.y - amount),
    );
    return BorderRadius.only(
      topLeft: subtract(value.topLeft),
      topRight: subtract(value.topRight),
      bottomRight: subtract(value.bottomRight),
      bottomLeft: subtract(value.bottomLeft),
    );
  }
}

/// A size-aware G2 capsule matching MIUIX `SmoothCapsuleShape`.
///
/// Unlike a squircle with one fixed radius, a capsule recalculates its radius
/// as half of the shorter laid-out dimension. This matters for arbitrary
/// content slots: a 60dp floating button and a 120-by-64 extended button must
/// both keep fully rounded ends without the caller predicting their final size.
class MiuixCapsuleBorder extends ShapeBorder {
  /// Creates a smooth capsule outline.
  const MiuixCapsuleBorder({this.side = BorderSide.none});

  /// Optional painted outline.
  final BorderSide side;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  /// Builds the same equal-radius path used by the source capsule.
  Path _path(Rect rect) {
    if (rect.isEmpty) return Path();
    final radius = math.min(rect.width, rect.height) / 2;
    return _MiuixSmoothCornerPath.build(
      rect,
      BorderRadius.all(Radius.circular(radius)),
    );
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return _path(rect.deflate(side.width));
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return _path(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side == BorderSide.none || side.width == 0) return;
    final centerRect = rect.deflate(side.width / 2);
    if (centerRect.isEmpty) return;
    canvas.drawPath(_path(centerRect), side.toPaint());
  }

  @override
  ShapeBorder scale(double t) {
    return MiuixCapsuleBorder(side: side.scale(t));
  }
}

/// Direct Flutter port of MIUIX Shapes' `SmoothCornerPath` constants and math.
class _MiuixSmoothCornerPath {
  const _MiuixSmoothCornerPath._();

  static const double _smoothExtension = 1.2;
  static const double _smoothControlPoint = .63;
  static const double _circleControlPoint = .5523;
  static const double _interpolationThreshold = .6541677;
  static const double _controlPointDelta =
      _smoothControlPoint - _circleControlPoint;
  static const double _extensionDelta = _smoothExtension - 1;

  static Path build(Rect rect, BorderRadius radius) {
    final path = Path();
    if (rect.isEmpty) {
      return path;
    }
    final width = rect.width;
    final height = rect.height;
    final maximumRadius = math.min(width / 2, height / 2);
    double value(Radius corner) =>
        math.min(math.min(corner.x, corner.y), maximumRadius);
    final topLeft = value(radius.topLeft);
    final topRight = value(radius.topRight);
    final bottomRight = value(radius.bottomRight);
    final bottomLeft = value(radius.bottomLeft);
    if (topLeft <= 0 && topRight <= 0 && bottomRight <= 0 && bottomLeft <= 0) {
      return path..addRect(rect);
    }

    final topLeftWeight = _weight(
      topLeft,
      _halfEdge(topLeft, topRight, width, bottomLeft, height),
    );
    final topRightWeight = _weight(
      topRight,
      _halfEdge(topRight, bottomRight, height, topLeft, width),
    );
    final bottomRightWeight = _weight(
      bottomRight,
      _halfEdge(bottomRight, bottomLeft, width, topRight, height),
    );
    final bottomLeftWeight = _weight(
      bottomLeft,
      _halfEdge(bottomLeft, topLeft, height, bottomRight, width),
    );

    double extension(double corner, double weight) =>
        corner * (_smoothExtension - _extensionDelta * weight);
    final topLeftExtension = extension(topLeft, topLeftWeight);
    final topRightExtension = extension(topRight, topRightWeight);
    final bottomRightExtension = extension(bottomRight, bottomRightWeight);
    final bottomLeftExtension = extension(bottomLeft, bottomLeftWeight);

    final topScale = _clampScale(topLeftExtension, topRightExtension, width);
    final rightScale = _clampScale(
      topRightExtension,
      bottomRightExtension,
      height,
    );
    final bottomScale = _clampScale(
      bottomRightExtension,
      bottomLeftExtension,
      width,
    );
    final leftScale = _clampScale(
      bottomLeftExtension,
      topLeftExtension,
      height,
    );

    final topLeftHorizontal = topLeftExtension * topScale;
    final topLeftVertical = topLeftExtension * leftScale;
    final topRightHorizontal = topRightExtension * topScale;
    final topRightVertical = topRightExtension * rightScale;
    final bottomRightHorizontal = bottomRightExtension * bottomScale;
    final bottomRightVertical = bottomRightExtension * rightScale;
    final bottomLeftHorizontal = bottomLeftExtension * bottomScale;
    final bottomLeftVertical = bottomLeftExtension * leftScale;

    double controlPoint(double weight) =>
        _smoothControlPoint - _controlPointDelta * weight;
    final left = rect.left;
    final top = rect.top;
    final right = rect.right;
    final bottom = rect.bottom;
    path.moveTo(left + topLeftHorizontal, top);
    path.lineTo(right - topRightHorizontal, top);
    _corner(
      path,
      right - topRightHorizontal,
      top,
      right,
      top,
      right,
      top + topRightVertical,
      controlPoint(topRightWeight),
    );
    path.lineTo(right, bottom - bottomRightVertical);
    _corner(
      path,
      right,
      bottom - bottomRightVertical,
      right,
      bottom,
      right - bottomRightHorizontal,
      bottom,
      controlPoint(bottomRightWeight),
    );
    path.lineTo(left + bottomLeftHorizontal, bottom);
    _corner(
      path,
      left + bottomLeftHorizontal,
      bottom,
      left,
      bottom,
      left,
      bottom - bottomLeftVertical,
      controlPoint(bottomLeftWeight),
    );
    path.lineTo(left, top + topLeftVertical);
    _corner(
      path,
      left,
      top + topLeftVertical,
      left,
      top,
      left + topLeftHorizontal,
      top,
      controlPoint(topLeftWeight),
    );
    return path..close();
  }

  static void _corner(
    Path path,
    double startX,
    double startY,
    double cornerX,
    double cornerY,
    double endX,
    double endY,
    double controlPoint,
  ) {
    path.cubicTo(
      startX + (cornerX - startX) * controlPoint,
      startY + (cornerY - startY) * controlPoint,
      endX + (cornerX - endX) * controlPoint,
      endY + (cornerY - endY) * controlPoint,
      endX,
      endY,
    );
  }

  static double _halfEdge(
    double radius,
    double adjacentHorizontal,
    double horizontalEdge,
    double adjacentVertical,
    double verticalEdge,
  ) {
    final horizontalSum = radius + adjacentHorizontal;
    final horizontal = horizontalSum > 0
        ? radius + (horizontalEdge - horizontalSum) * (radius / horizontalSum)
        : horizontalEdge / 2;
    final verticalSum = radius + adjacentVertical;
    final vertical = verticalSum > 0
        ? radius + (verticalEdge - verticalSum) * (radius / verticalSum)
        : verticalEdge / 2;
    return math.min(horizontal, vertical);
  }

  static double _weight(double radius, double halfEdge) {
    if (halfEdge <= 0 || radius <= 0) {
      return 1;
    }
    final threshold = halfEdge * _interpolationThreshold;
    final range = halfEdge - threshold;
    return range <= 0 ? 1 : ((radius - threshold) / range).clamp(0.0, 1.0);
  }

  static double _clampScale(
    double firstExtension,
    double secondExtension,
    double edgeLength,
  ) {
    final sum = firstExtension + secondExtension;
    return sum <= edgeLength || sum <= 0 ? 1 : edgeLength / sum;
  }
}

/// Clips its child with the same continuous-corner path as MIUIX Shapes.
///
/// Use this when an image, glass layer, or custom painted child needs the same
/// corner language as cards and popups.
class MiuixSquircleClip extends StatelessWidget {
  /// Creates a squircle clipper widget.
  const MiuixSquircleClip({super.key, required this.child, this.radius});

  /// Content to clip.
  final Widget child;

  /// Optional corner radius. The theme medium radius is used when omitted.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    return ClipPath(
      clipper: ShapeBorderClipper(
        shape: MiuixSquircleBorder(
          borderRadius: BorderRadius.circular(radius ?? theme.radius.md),
        ),
      ),
      child: child,
    );
  }
}

/// Glass blur panel used by popups, floating navigation, and control tiles.
///
/// It uses Flutter's [BackdropFilter] and therefore works on every Flutter
/// platform, though complex blur stacks should still be profiled on low-end
/// Android devices and Web.
class MiuixGlass extends StatelessWidget {
  /// Creates a glass panel.
  const MiuixGlass({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.72,
    this.color,
    this.radius,
    this.borderRadius,
    this.padding,
    this.border,
    this.enabled = true,
    this.useGlobalIntensity = true,
    this.showSpecular = true,
    this.imageFilter,
  });

  /// Content rendered above the glass surface.
  final Widget child;

  /// Sigma value used for the blur filter.
  final double blur;

  /// Surface opacity applied over the blurred backdrop.
  final double opacity;

  /// Optional tint color; defaults to the current surface semantic color.
  final Color? color;

  /// Optional corner radius.
  final double? radius;

  /// Optional non-uniform radius, such as a top-only bottom-sheet shape.
  final BorderRadius? borderRadius;

  /// Optional inner padding.
  final EdgeInsetsGeometry? padding;

  /// Optional border painted over the glass.
  final BorderSide? border;

  /// Whether the blur is active.
  final bool enabled;

  /// Whether the theme's five-level strength scales [blur] and [opacity].
  ///
  /// Component glass uses the global setting. Explicit texture-blur previews
  /// disable it so their numeric controls continue to represent source values.
  final bool useGlobalIntensity;

  /// Whether to paint the directional liquid-glass reflection layer.
  final bool showSpecular;

  /// Optional complete backdrop filter. Texture blur uses this to compose the
  /// source blur with MIUIX's extended blend-mode shader.
  final ImageFilter? imageFilter;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final effectiveRadius = radius ?? theme.radius.lg;
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(effectiveRadius);
    final intensity = theme.glassIntensity;
    // TextureBlur/LayerBackdrop owns an explicit enable switch and disables
    // global intensity scaling. It must therefore keep rendering even when
    // the unrelated application-wide liquid-glass option is off. Ordinary
    // component glass still follows the global enable flag.
    final glassEnabled = enabled && (!useGlobalIntensity || theme.enableGlass);
    final effectiveOpacity = glassEnabled
        ? (useGlobalIntensity ? intensity.resolveOpacity(opacity) : opacity)
        : 1.0;
    final effectiveBlur = useGlobalIntensity
        ? intensity.resolveBlur(blur)
        : blur;
    final tint = color ?? scheme.surface;
    final ShapeBorder shape = theme.enableSquircle
        ? MiuixSquircleBorder(
            borderRadius: effectiveBorderRadius,
            side: border ?? BorderSide.none,
          )
        : RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
            side: border ?? BorderSide.none,
          );
    final decoration = ShapeDecoration(
      // Preserve an explicitly supplied tint alpha. This lets callers request
      // a blur-only transparent layer without accidentally turning
      // `Colors.transparent` into an opaque black surface.
      color: tint.withValues(alpha: tint.a * effectiveOpacity),
      shape: shape,
    );
    final tintedContent = DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: padding ?? EdgeInsets.all(theme.spacing.lg),
        child: child,
      ),
    );
    if (!glassEnabled) {
      return tintedContent;
    }

    // A plain blur plus a tint that matches the page becomes visually
    // indistinguishable from an opaque panel on MIUIX's pale surfaces. Real
    // texture blur retains chroma and adds a directional edge reflection. The
    // two lightweight layers below reproduce those cues without drawing over
    // the component's content or changing its hit-test geometry.
    final level = intensity.index / (MiuixGlassIntensity.values.length - 1);
    // A specular edge should describe the glass, not repaint the whole panel.
    // Keeping this restrained is especially important at level five: a broad
    // 24% white wash made the transparent surface look opaque on the example's
    // nearly white settings page.
    final highlightAlpha = level <= .5
        ? .10 + level * .14
        : lerpDouble(.17, .12, (level - .5) * 2)!;
    final highlightShape = theme.enableSquircle
        ? MiuixSquircleBorder(
            borderRadius: effectiveBorderRadius,
            side: BorderSide(
              color: scheme.onSurface.withValues(alpha: .025 + level * .025),
              width: .5,
            ),
          )
        : RoundedRectangleBorder(
            borderRadius: effectiveBorderRadius,
            side: BorderSide(
              color: scheme.onSurface.withValues(alpha: .025 + level * .025),
              width: .5,
            ),
          );
    final glassContent = Stack(
      fit: StackFit.passthrough,
      children: [
        tintedContent,
        if (showSpecular)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                key: const ValueKey('miuix-glass-specular-highlight'),
                decoration: ShapeDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: const [0, .42, 1],
                    colors: [
                      Colors.white.withValues(alpha: highlightAlpha),
                      Colors.white.withValues(alpha: highlightAlpha * .12),
                      (scheme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withValues(alpha: highlightAlpha * .16),
                    ],
                  ),
                  shape: highlightShape,
                ),
              ),
            ),
          ),
      ],
    );
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter(
        key: const ValueKey('miuix-glass-backdrop-filter'),
        filter:
            imageFilter ??
            ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: glassContent,
      ),
    );
  }
}

/// Press feedback wrapper with sink and optional tilt-like scaling.
///
/// The widget centralizes a common MIUI interaction pattern: controls visually
/// settle downward while pressed, then spring back quickly.
class MiuixPressable extends StatefulWidget {
  /// Creates a press feedback wrapper.
  const MiuixPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.94,
    this.sinkDampingRatio = .8,
    this.sinkStiffness = 600,
    this.borderRadius,
    this.shape,
    this.feedbackType = MiuixPressFeedbackType.sink,
    this.holdDown = false,
    this.showIndication = false,
    this.feedbackOnly = false,
    this.interactionSource,
  });

  /// Content that receives feedback.
  final Widget child;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Optional long-press callback.
  final VoidCallback? onLongPress;

  /// Pressed scale.
  final double scale;

  /// Damping ratio used by sink feedback.
  final double sinkDampingRatio;

  /// Spring stiffness used by sink feedback.
  final double sinkStiffness;

  /// Optional material ripple radius.
  final BorderRadius? borderRadius;

  /// Optional exact clip shape for the content and pressed indication.
  ///
  /// MIUIX components commonly use a continuous-corner `miuixShape` rather
  /// than a circular rounded rectangle. When supplied, this takes precedence
  /// over [borderRadius] so the interaction layer shares the painted outline.
  final ShapeBorder? shape;

  /// Feedback style used while the control is pressed.
  final MiuixPressFeedbackType feedbackType;

  /// Whether feedback remains held independently of the pointer lifecycle.
  ///
  /// MIUIX preferences use this while a child dialog remains visible.
  final bool holdDown;

  /// Whether to paint the MIUIX pressed indication over the child.
  final bool showIndication;

  /// Whether pointer presses animate feedback without adding a tap action.
  ///
  /// Source controls such as a read-only Checkbox still install `pressable`
  /// outside their optional toggleable modifier. This mode preserves that
  /// indication while keeping accessibility semantics non-interactive.
  final bool feedbackOnly;

  /// Optional source-compatible observer for pointer press state.
  final MiuixInteractionSource? interactionSource;

  @override
  State<MiuixPressable> createState() => _MiuixPressableState();
}

class _MiuixPressableState extends State<MiuixPressable>
    with TickerProviderStateMixin {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;
  Alignment _tiltOrigin = Alignment.center;
  double _tiltTargetX = 0;
  double _tiltTargetY = 0;
  late final AnimationController _sinkController;
  late final AnimationController _tiltXController;
  late final AnimationController _tiltYController;
  late final AnimationController _indicationController;
  late final Listenable _motion;
  TickerFuture? _positiveIndicationAnimation;
  int _indicationRevision = 0;

  bool get _visuallyPressed => _pressed || widget.holdDown;

  /// Sums the four independent alpha channels from `MiuixIndication.kt`.
  double get _indicationTarget {
    if (!widget.showIndication) return 0;
    return (_hovered ? .06 : 0) +
        (_focused ? .08 : 0) +
        (_pressed ? .10 : 0) +
        (widget.holdDown ? .10 : 0);
  }

  @override
  void initState() {
    super.initState();
    _sinkController = AnimationController.unbounded(
      vsync: this,
      value:
          widget.feedbackType == MiuixPressFeedbackType.sink && widget.holdDown
          ? widget.scale
          : 1,
    );
    _tiltXController = AnimationController.unbounded(vsync: this);
    _tiltYController = AnimationController.unbounded(vsync: this);
    _indicationController = AnimationController.unbounded(vsync: this);
    _motion = Listenable.merge([
      _sinkController,
      _tiltXController,
      _tiltYController,
    ]);
    // A pre-held component receives HoldDownInteraction after its indication
    // node attaches. Animate that initial state instead of starting fully lit.
    if (widget.showIndication && widget.holdDown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncIndication();
      });
    }
  }

  @override
  void didUpdateWidget(covariant MiuixPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.interactionSource, widget.interactionSource)) {
      if (_pressed) {
        oldWidget.interactionSource?.setPressed(false);
        widget.interactionSource?.setPressed(true);
      }
    }
    if (oldWidget.feedbackType != widget.feedbackType ||
        oldWidget.holdDown != widget.holdDown ||
        oldWidget.scale != widget.scale ||
        oldWidget.sinkDampingRatio != widget.sinkDampingRatio ||
        oldWidget.sinkStiffness != widget.sinkStiffness) {
      _syncFeedback();
    }
    if (oldWidget.showIndication != widget.showIndication ||
        oldWidget.holdDown != widget.holdDown) {
      _syncIndication();
    }
  }

  @override
  void dispose() {
    if (_pressed) {
      widget.interactionSource?.setPressed(false);
    }
    _sinkController.dispose();
    _tiltXController.dispose();
    _tiltYController.dispose();
    _indicationController.dispose();
    super.dispose();
  }

  void _springTo(
    AnimationController controller,
    double target,
    SpringDescription spring,
  ) {
    controller.animateWith(
      SpringSimulation(spring, controller.value, target, 0),
    );
  }

  void _syncFeedback() {
    final sinkTarget =
        widget.feedbackType == MiuixPressFeedbackType.sink && _visuallyPressed
        ? widget.scale
        : 1.0;
    _springTo(
      _sinkController,
      sinkTarget,
      debugMiuixSinkSpring(
        dampingRatio: widget.sinkDampingRatio,
        stiffness: widget.sinkStiffness,
      ),
    );

    final keepTilt =
        widget.feedbackType == MiuixPressFeedbackType.tilt && _visuallyPressed;
    _springTo(
      _tiltXController,
      keepTilt ? _tiltTargetX : 0,
      debugMiuixTiltSpring(),
    );
    _springTo(
      _tiltYController,
      keepTilt ? _tiltTargetY : 0,
      debugMiuixTiltSpring(),
    );
  }

  /// Runs the source 120ms linear indication state machine.
  ///
  /// MIUIX lets a positive transition finish before it starts the final fade
  /// to zero. New positive states cancel that pending rest transition, which
  /// also keeps hover, focus, press, and hold-down additive.
  void _syncIndication() {
    final target = _indicationTarget;
    final revision = ++_indicationRevision;
    if (target > 0) {
      _indicationController.stop(canceled: true);
      _positiveIndicationAnimation = _indicationController.animateTo(
        target,
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      );
      return;
    }
    final positiveAnimation = _positiveIndicationAnimation;
    () async {
      try {
        await positiveAnimation?.orCancel;
      } catch (_) {
        // A newer positive state intentionally cancels this pending rest.
      }
      if (!mounted ||
          revision != _indicationRevision ||
          _indicationTarget != 0) {
        return;
      }
      _indicationController.animateTo(
        0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.linear,
      );
    }();
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
      widget.interactionSource?.setPressed(value);
      _syncFeedback();
      _syncIndication();
    }
  }

  void _setHovered(bool value) {
    if (_hovered != value) {
      setState(() => _hovered = value);
      _syncIndication();
    }
  }

  void _setFocused(bool value) {
    if (_focused != value) {
      setState(() => _focused = value);
      _syncIndication();
    }
  }

  // Converts the pointer position into the small two-axis rotation used by
  // MIUIX tilt feedback. Values remain normalized so the visual result is
  // independent of the card's concrete size.
  //
  // Keep this helper position-based instead of TapDownDetails-based because a
  // long press owns a second gesture lifecycle. When Flutter's long-press
  // recognizer wins, the competing tap recognizer first reports onTapCancel
  // and then onLongPressStart. Reapplying the source pivot at that transition
  // is what keeps MIUIX tilt visible for the entire hold.
  void _setTiltAt(Offset localPosition) {
    if (widget.feedbackType != MiuixPressFeedbackType.tilt) {
      return;
    }
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) {
      return;
    }
    final target = debugMiuixTiltTarget(localPosition, box.size);
    setState(() {
      _tiltOrigin = target.origin;
      _tiltTargetX = target.rotationXDegrees;
      _tiltTargetY = target.rotationYDegrees;
    });
    _springTo(
      _tiltXController,
      target.rotationXDegrees,
      debugMiuixTiltSpring(),
    );
    _springTo(
      _tiltYController,
      target.rotationYDegrees,
      debugMiuixTiltSpring(),
    );
  }

  void _releaseFeedback() {
    _setPressed(false);
  }

  void _cancelFeedback() {
    setState(() {
      _tiltOrigin = Alignment.center;
      _tiltTargetX = 0;
      _tiltTargetY = 0;
    });
    _releaseFeedback();
  }

  @override
  Widget build(BuildContext context) {
    final indicatedChild = Stack(
      fit: StackFit.passthrough,
      children: [
        widget.child,
        if (widget.showIndication)
          Positioned.fill(
            child: IgnorePointer(
              child: FadeTransition(
                key: const ValueKey('miuix-press-indication'),
                // MiuixIndication.kt linearly animates every state delta for
                // 120ms and adds hover/focus/press/hold alpha independently.
                opacity: _indicationController,
                child: ColoredBox(
                  color: MiuixSemanticColors.of(context)['onBackground'],
                ),
              ),
            ),
          ),
      ],
    );
    // Compose orders Card's `pressable` modifier outside its shape clip. The
    // card is clipped first and that already-rounded layer is then rotated, so
    // tilted corners may paint a few pixels beyond the untransformed bounds.
    // Clipping after Transform instead cuts those pixels off and shortens the
    // held card compared with the source.
    // A ShapeBorder path is required for source components that opt into G2
    // smooth rounding. ClipRRect remains the compatibility path for existing
    // callers that only provide a conventional BorderRadius.
    final sourceClippedChild = widget.shape != null
        ? ClipPath(
            clipper: ShapeBorderClipper(shape: widget.shape!),
            child: indicatedChild,
          )
        : widget.borderRadius == null
        ? indicatedChild
        : ClipRRect(borderRadius: widget.borderRadius!, child: indicatedChild);
    final feedbackChild = AnimatedBuilder(
      animation: _motion,
      child: sourceClippedChild,
      builder: (context, child) {
        Widget transformed = Transform.scale(
          key: const ValueKey('miuix-sink-transform'),
          scale: widget.feedbackType == MiuixPressFeedbackType.sink
              ? _sinkController.value
              : 1,
          transformHitTests: false,
          child: child,
        );
        if (widget.feedbackType == MiuixPressFeedbackType.tilt) {
          final transform = Matrix4.identity()
            ..setEntry(3, 2, debugMiuixTiltPerspective())
            ..rotateX(_tiltXController.value * math.pi / 180)
            ..rotateY(_tiltYController.value * math.pi / 180);
          transformed = Transform(
            key: const ValueKey('miuix-tilt-transform'),
            alignment: _tiltOrigin,
            transform: transform,
            transformHitTests: false,
            child: transformed,
          );
        }
        return transformed;
      },
    );
    final enabled =
        widget.onTap != null ||
        widget.onLongPress != null ||
        widget.showIndication ||
        widget.feedbackOnly ||
        widget.feedbackType != MiuixPressFeedbackType.none;
    final effectiveTap =
        widget.onTap ?? (enabled && !widget.feedbackOnly ? () {} : null);
    final gesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      // Compose's interactive Card installs an empty click action when only
      // indication is requested, so the surface still enters pressed state.
      excludeFromSemantics:
          widget.feedbackOnly &&
          widget.onTap == null &&
          widget.onLongPress == null,
      onTap: effectiveTap ?? (widget.feedbackOnly ? () {} : null),
      onLongPress: widget.onLongPress,
      onTapDown: enabled
          ? (details) {
              _setPressed(true);
              _setTiltAt(details.localPosition);
            }
          : null,
      onTapCancel: enabled
          ? () {
              // A long-press recognizer cancels the competing tap recognizer
              // before it reports start. Keep the surface pressed across that
              // hand-off; onLongPressCancel still releases it when a parent
              // scroll gesture actually wins.
              if (widget.onLongPress == null) {
                _cancelFeedback();
              }
            }
          : null,
      onTapUp: enabled ? (_) => _releaseFeedback() : null,
      // GestureDetector represents tap and long press with competing
      // recognizers. The tap recognizer's cancellation must not terminate the
      // visual feedback after the long press has actually been accepted.
      onLongPressStart: widget.onLongPress == null
          ? null
          : (details) {
              _setPressed(true);
              _setTiltAt(details.localPosition);
            },
      onLongPressEnd: widget.onLongPress == null
          ? null
          : (_) => _releaseFeedback(),
      onLongPressCancel: widget.onLongPress == null ? null : _cancelFeedback,
      child: feedbackChild,
    );
    final focusable = FocusableActionDetector(
      enabled: enabled && !widget.feedbackOnly,
      onFocusChange: _setFocused,
      shortcuts: effectiveTap == null
          ? const <ShortcutActivator, Intent>{}
          : const <ShortcutActivator, Intent>{
              SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
              SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
            },
      actions: effectiveTap == null
          ? const <Type, Action<Intent>>{}
          : <Type, Action<Intent>>{
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (_) {
                  effectiveTap();
                  return null;
                },
              ),
            },
      child: gesture,
    );
    return MouseRegion(
      onEnter: enabled ? (_) => _setHovered(true) : null,
      onExit: enabled ? (_) => _setHovered(false) : null,
      child: focusable,
    );
  }
}
