import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets('Windows runtime shader and baked SDF preload together', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(defaultTargetPlatform, TargetPlatform.windows);
    ui.FragmentProgram? directProgram;
    Object? packageShaderError;
    try {
      directProgram = await ui.FragmentProgram.fromAsset(
        'packages/flutter_miuix/shaders/miuix_squircle_mask.frag',
      );
    } catch (error) {
      packageShaderError = error;
      directProgram = await ui.FragmentProgram.fromAsset(
        'shaders/miuix_squircle_mask.frag',
      );
    }
    expect(directProgram, isNotNull, reason: '$packageShaderError');
    final preloaded = await tester.runAsync(preloadMiuixSquircleShader);
    expect(preloaded, isTrue, reason: '$debugMiuixSquircleLastLoadError');
    // flutter_tester's headless software renderer cannot reliably execute a
    // FragmentShader with an image sampler. Loading both compiled resources
    // here still catches missing package keys and shader compilation drift;
    // Release app/device checks own actual GPU painting.
    expect(debugMiuixSquircleLastLoadError, isNull);
    debugDefaultTargetPlatformOverride = null;
  });
}
