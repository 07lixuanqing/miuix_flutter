part of 'main.dart';

/// Builds the historical shape-comparison extension for focused tests.
///
/// Current official `main` removed this chapter from Home. Retaining the
/// fixture protects the reusable G2 renderer without altering source order.
@visibleForTesting
Widget debugReferenceShapeComparisonSection() {
  return const _ReferenceShapeComparisonSection();
}

/// Historical G2-versus-circular corner comparison extension.
class _ReferenceShapeComparisonSection extends StatefulWidget {
  const _ReferenceShapeComparisonSection();

  @override
  State<_ReferenceShapeComparisonSection> createState() =>
      _ReferenceShapeComparisonSectionState();
}

class _ReferenceShapeComparisonSectionState
    extends State<_ReferenceShapeComparisonSection> {
  double _radius = 48;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final sourcePreviewHeight = _referenceRoundedDp(context, 160);
    final sourceSliderTop = _referenceRoundedDp(context, 8);
    final sourceSliderBottom = _referenceRoundedDp(context, 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '形状对比',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        // The page list already owns the source section's 12 dp inset. Keeping
        // another Padding here made this one section start at 24 dp while the
        // Compose preview, cards, and blur demos all start at 12 dp.
        RepaintBoundary(
          key: const ValueKey('shape-comparison-golden'),
          child: Column(
            children: [
              SizedBox(
                key: const ValueKey('shape-comparison-preview'),
                height: sourcePreviewHeight,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ReferenceShapeBasePainter(
                    radius: _radius,
                    primary: scheme.primary,
                  ),
                  // drawWithContent in the Compose sample paints the label
                  // between the blue base and the red XOR difference layer.
                  foregroundPainter: _ReferenceShapeDifferencePainter(
                    radius: _radius,
                    difference: scheme.error,
                  ),
                  child: Center(
                    child: Text(
                      // ShapeComparisonSection.kt formats the continuous
                      // slider value with Float.toInt(), so 48.9 remains 48.
                      '红色 = 差异，圆角 = ${_radius.toInt()}dp',
                      style: TextStyle(color: scheme.onPrimary),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: sourceSliderTop,
                  bottom: sourceSliderBottom,
                ),
                child: MiuixSlider(
                  value: _radius,
                  min: 0,
                  max: 80,
                  onChanged: (value) => setState(() => _radius = value),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferenceShapeBasePainter extends CustomPainter {
  const _ReferenceShapeBasePainter({
    required this.radius,
    required this.primary,
  });

  final double radius;
  final Color primary;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circular = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawPath(circular, Paint()..color = primary);
  }

  @override
  bool shouldRepaint(covariant _ReferenceShapeBasePainter oldDelegate) {
    return radius != oldDelegate.radius || primary != oldDelegate.primary;
  }
}

/// Red XOR overlay painted after the centered label, matching drawWithContent.
class _ReferenceShapeDifferencePainter extends CustomPainter {
  const _ReferenceShapeDifferencePainter({
    required this.radius,
    required this.difference,
  });

  final double radius;
  final Color difference;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final circular = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final smooth = MiuixSquircleBorder(
      borderRadius: BorderRadius.circular(radius),
    ).getOuterPath(rect);
    canvas.saveLayer(rect, Paint());
    canvas.drawPath(smooth, Paint()..color = difference);
    canvas.drawPath(
      circular,
      Paint()
        ..color = difference
        ..blendMode = BlendMode.xor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReferenceShapeDifferencePainter oldDelegate) {
    return radius != oldDelegate.radius || difference != oldDelegate.difference;
  }
}
