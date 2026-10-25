import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final squircle in [false, true]) {
    testWidgets('floating shadow leaves glass interior clear ($squircle)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(enableSquircle: squircle),
            child: Scaffold(
              body: MiuixFloatingNavigationBar(
                items: const [
                  MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                  MiuixNavigationItem(icon: Icon(Icons.star), label: 'Saved'),
                ],
                selectedIndex: 0,
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final shadow = find.byKey(const ValueKey('floating-navigation-shadow'));
      final painter = tester.widget<CustomPaint>(shadow).painter!;
      // 独立采样阴影层：内部必须透明，轮廓外仍须有柔和投影。
      // Sample the actual painter: clear inside, visible halo outside.
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)..translate(30, 30);
        final previousDisableShadows = debugDisableShadows;
        try {
          debugDisableShadows = false;
          painter.paint(canvas, const Size(240, 58));
        } finally {
          debugDisableShadows = previousDisableShadows;
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(300, 118);
        final rgba = (await image.toByteData())!;
        int alpha(int x, int y) => rgba.getUint8((y * 300 + x) * 4 + 3);
        expect(alpha(150, 59), 0, reason: 'no black fill behind clear glass');
        expect(alpha(150, 33), 0, reason: 'clear up to the inner top edge');
        expect(alpha(150, 27), greaterThan(0), reason: 'retain the outer halo');
        expect(alpha(150, 91), greaterThan(0));
        image.dispose();
        picture.dispose();
      });
    });
  }
}
