import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('liquid lens keeps every Impeller platform on one shader path', () {
    final source = File(
      'lib/src/widgets/parts/navigation_bars_ios.dart',
    ).readAsStringSync();

    expect(
      source,
      isNot(
        contains('defaultTargetPlatform == TargetPlatform.android) return'),
      ),
    );
    expect(source, isNot(contains('stableShaderBackend')));
    expect(
      source,
      contains('shader == null || !ui.ImageFilter.isShaderFilterSupported'),
    );
  });

  test('liquid lens geometry and sampling use the physical texture domain', () {
    final source = File(
      'lib/src/widgets/parts/navigation_bars_ios.dart',
    ).readAsStringSync();
    final shader = File('shaders/miuix_liquid_lens.frag').readAsStringSync();

    expect(source, contains('final scale = devicePixelRatio;'));
    expect(source, contains('shapeSize.width * scale'));
    expect(source, contains('-padding * scale'));
    expect(shader, contains('uniform vec2 u_size;'));
    expect(shader, contains('FlutterFragCoord().xy'));
    expect(shader, contains('#ifdef IMPELLER_TARGET_OPENGLES'));
  });

  test('liquid panel matches AndroidLiquidGlass optical material chain', () {
    final source = File(
      'lib/src/widgets/parts/navigation_bars_ios.dart',
    ).readAsStringSync();
    final shader = File('shaders/miuix_liquid_lens.frag').readAsStringSync();

    expect(source, contains('blurSigma: intensity.resolveBlur(8)'));
    expect(source, contains('vibrancy: 1.5'));
    expect(source, contains('samplePadding: 0'));
    expect(source, isNot(contains('samplePadding: 40')));
    expect(source, contains('setFloat(14, widget.vibrancy)'));
    expect(shader, contains('uniform float u_vibrancy;'));
    expect(shader, contains('vec3(0.213, 0.715, 0.072)'));
    expect(
      shader,
      contains('mix(vec3(luminance), sampled_color.rgb, u_vibrancy)'),
    );
  });
}
