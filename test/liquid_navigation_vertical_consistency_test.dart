import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android liquid panel uses one vertically consistent material', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.binding.setSurfaceSize(const Size(440, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const _VerticalInvariantFrame());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const ValueKey('ios-liquid-safe-vibrancy')),
        findsOneWidget,
      );
      final panelRect = tester.getRect(
        find.byKey(const ValueKey('ios-liquid-panel')),
      );
      expect(panelRect, const Rect.fromLTWH(24, 244, 392, 56));
      await expectLater(
        find.byKey(const ValueKey('vertical-consistency-frame')),
        matchesGoldenFile('goldens/liquid_navigation_android_safe.png'),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test(
    'Android safe golden has matching upper and lower material rows',
    () async {
      const path = 'test/goldens/liquid_navigation_android_safe.png';
      expect(
        await _mirroredRowDifferences(
          path,
          const Rect.fromLTWH(24, 244, 392, 56),
        ),
        isEmpty,
        reason: 'a vertically invariant backdrop must not produce two halves',
      );
      final contrasts = await _horizontalContrasts(path, <int>[
        100,
        252,
        259,
        265,
        272,
        279,
        286,
        293,
      ]);
      final backdropContrast = contrasts.first;
      final panelContrasts = contrasts.skip(1).toList();
      expect(
        panelContrasts.every((value) => value < backdropContrast * .7),
        isTrue,
        reason: 'every sampled panel row must visibly soften the stripe edges',
      );
      expect(
        panelContrasts.reduce(math.max) - panelContrasts.reduce(math.min),
        lessThan(.1),
        reason: 'blur strength must stay constant from upper to lower half',
      );
    },
  );
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
    for (var x = 40; x < 300; x++) {
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

Future<List<String>> _mirroredRowDifferences(
  String path,
  Rect panelRect,
) async {
  final codec = await ui.instantiateImageCodec(await File(path).readAsBytes());
  final frame = await codec.getNextFrame();
  codec.dispose();
  final image = frame.image;
  final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final differences = <String>[];
  if (rgba == null) {
    image.dispose();
    return <String>['PNG decoder returned no RGBA bytes'];
  }
  for (final xFraction in <double>[.125, .375, .625]) {
    final x = (panelRect.left + panelRect.width * xFraction).round();
    for (final inset in <int>[7, 13, 20]) {
      final upperY = panelRect.top.round() + inset;
      final lowerY = panelRect.bottom.round() - 1 - inset;
      final upper = _pixel(rgba, image.width, x, upperY);
      final lower = _pixel(rgba, image.width, x, lowerY);
      if (!_near(upper, lower)) {
        differences.add('x=$x inset=$inset upper=$upper lower=$lower');
      }
    }
  }
  image.dispose();
  return differences;
}

List<int> _pixel(ByteData data, int width, int x, int y) {
  final offset = (y * width + x) * 4;
  return <int>[
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

bool _near(List<int> first, List<int> second) {
  for (var channel = 0; channel < first.length; channel++) {
    if ((first[channel] - second[channel]).abs() > 3) return false;
  }
  return true;
}

class _VerticalInvariantFrame extends StatelessWidget {
  const _VerticalInvariantFrame();

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: const ValueKey('vertical-consistency-frame'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MiuixTheme(
        data: MiuixThemeData.defaults(),
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: const CustomPaint(
            painter: _VerticalStripePainter(),
            child: SizedBox.expand(),
          ),
          bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
            selectedIndex: 3,
            onDestinationSelected: (_) {},
            defaultWindowInsetsPadding: false,
            displayMode: MiuixFloatingNavigationBarDisplayMode.iconOnly,
            items: const <MiuixNavigationItem>[
              MiuixNavigationItem(icon: SizedBox.shrink(), label: 'One'),
              MiuixNavigationItem(icon: SizedBox.shrink(), label: 'Two'),
              MiuixNavigationItem(icon: SizedBox.shrink(), label: 'Three'),
              MiuixNavigationItem(icon: SizedBox.shrink(), label: 'Four'),
            ],
          ),
        ),
      ),
    ),
  );
}

class _VerticalStripePainter extends CustomPainter {
  const _VerticalStripePainter();

  static const colors = <Color>[
    Color(0xff143cff),
    Color(0xff00d49a),
    Color(0xffffd32a),
    Color(0xffff3c78),
    Color(0xff8a42ff),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const stripeWidth = 10.0;
    for (var left = 0.0; left < size.width; left += stripeWidth) {
      final color = colors[(left / stripeWidth).floor() % colors.length];
      canvas.drawRect(
        Rect.fromLTWH(left, 0, stripeWidth, size.height),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalStripePainter oldDelegate) => false;
}
