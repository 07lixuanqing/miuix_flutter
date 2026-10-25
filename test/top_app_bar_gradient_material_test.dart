import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android top bar keeps a variable-radius blur gradient', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.binding.setSurfaceSize(const Size(440, 180));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const _GradientTopBarFrame());
      await tester.pumpAndSettle();

      // Mask saveLayers can leave only tint while the backdrop stays sharp.
      // Title passes clip the actual backdrop directly on every renderer.
      expect(find.byType(ShaderMask), findsNothing);
      final gradient = find.byKey(
        const ValueKey('top-app-bar-progressive-glass'),
      );
      expect(gradient, findsOneWidget);
      expect(
        find.descendant(of: gradient, matching: find.byType(BackdropFilter)),
        findsNWidgets(17),
      );
      expect(
        find.byKey(const ValueKey('top-app-bar-gradient-filter')),
        findsOneWidget,
      );
      final tint = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('top-app-bar-gradient-tint')),
      );
      expect(
        (tint.decoration as BoxDecoration).gradient,
        isA<LinearGradient>(),
      );
      await expectLater(
        find.byKey(const ValueKey('top-bar-gradient-frame')),
        matchesGoldenFile('goldens/top_app_bar_gradient_android.png'),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('top bar golden keeps smooth tint gradient and real blur', () async {
    final contrasts = await _horizontalContrasts(
      'test/goldens/top_app_bar_gradient_android.png',
      const <int>[6, 18, 30, 44, 50, 51, 120],
    );
    final lowerEdge = contrasts[5];
    final unfilteredBackdrop = contrasts[6];
    final rowMeans = await _rowMeans(
      'test/goldens/top_app_bar_gradient_android.png',
      const <int>[6, 44],
    );
    final tintDifference = List<double>.generate(
      3,
      (index) => (rowMeans[0][index] - rowMeans[1][index]).abs(),
    ).reduce((first, second) => first + second);
    expect(
      tintDifference,
      greaterThan(8),
      reason: 'the title material must retain a visible vertical gradient',
    );
    expect(
      (lowerEdge - unfilteredBackdrop).abs(),
      lessThan(unfilteredBackdrop * .2),
      reason: 'blur must reach clear continuously at the body edge',
    );
    expect(
      contrasts.take(4).every((value) => value < unfilteredBackdrop),
      isTrue,
      reason: 'every title-region band must soften the page behind it',
    );
    expect(
      contrasts[0],
      lessThan(unfilteredBackdrop * .12),
      reason: 'tint alone reduces contrast but must not pass as real blur',
    );
    expect(
      contrasts[3],
      lessThan(contrasts[4]),
      reason: 'the final title band must progressively release its blur',
    );
  });

  testWidgets('gradient blur stops at the title before bottom content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            appBar: MiuixTopAppBar(
              title: 'Title only',
              large: false,
              defaultWindowInsetsPadding: false,
              bottomContentHeight: 40,
              bottomContent: ColoredBox(
                key: ValueKey('clear-bottom-content'),
                color: Colors.red,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .getSize(find.byKey(const ValueKey('top-app-bar-progressive-glass')))
          .height,
      92,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('top-app-bar-gradient-filter')))
          .height,
      MiuixTopAppBar.collapsedHeight,
    );
    final titleClip = find.byKey(
      const ValueKey('top-app-bar-title-material-clip'),
    );
    expect(titleClip, findsOneWidget);
    expect(tester.getSize(titleClip).height, MiuixTopAppBar.collapsedHeight);
    expect(
      find.descendant(
        of: titleClip,
        matching: find.byKey(const ValueKey('top-app-bar-gradient-filter')),
      ),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('clear-bottom-content'))).dy,
      MiuixTopAppBar.collapsedHeight,
    );
  });
}

Future<List<List<double>>> _rowMeans(String path, List<int> rows) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) {
    image.dispose();
    return <List<double>>[
      for (final _ in rows) const <double>[0, 0, 0],
    ];
  }
  final result = <List<double>>[];
  for (final y in rows) {
    final sums = <double>[0, 0, 0];
    var samples = 0;
    for (var x = 20; x < 400; x++) {
      final pixel = _pixel(rgba, image.width, x, y);
      for (var channel = 0; channel < 3; channel++) {
        sums[channel] += pixel[channel];
      }
      samples++;
    }
    result.add(<double>[for (final sum in sums) sum / samples]);
  }
  image.dispose();
  return result;
}

Future<List<double>> _horizontalContrasts(String path, List<int> rows) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (rgba == null) {
    image.dispose();
    return <double>[double.infinity];
  }
  final result = <double>[];
  for (final y in rows) {
    var difference = 0;
    var channels = 0;
    for (var x = 20; x < 400; x++) {
      final first = _pixel(rgba, image.width, x, y);
      final second = _pixel(rgba, image.width, x + 1, y);
      for (var channel = 0; channel < 3; channel++) {
        difference += (first[channel] - second[channel]).abs();
        channels++;
      }
    }
    result.add(difference / channels);
  }
  image.dispose();
  return result;
}

List<int> _pixel(ByteData data, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return <int>[
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
  ];
}

class _GradientTopBarFrame extends StatelessWidget {
  const _GradientTopBarFrame();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('top-bar-gradient-frame'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MiuixTheme(
        data: MiuixThemeData.defaults(),
        child: const Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _StripePainter())),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: MiuixTopAppBar.collapsedHeight,
                child: MiuixTopAppBar(
                  title: '',
                  large: false,
                  defaultWindowInsetsPadding: false,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StripePainter extends CustomPainter {
  const _StripePainter();

  static const colors = <Color>[
    Color(0xff143cff),
    Color(0xff00d49a),
    Color(0xffffd32a),
    Color(0xffff3c78),
    Color(0xff8a42ff),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 8.0;
    for (var left = 0.0; left < size.width; left += stripeWidth) {
      canvas.drawRect(
        Rect.fromLTWH(left, 0, stripeWidth, size.height),
        Paint()..color = colors[(left / stripeWidth).floor() % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StripePainter oldDelegate) => false;
}
