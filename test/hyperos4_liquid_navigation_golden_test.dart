import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    testWidgets('liquid navigation ${brightness.name} vivid backdrop', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(440, 300));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _LiquidNavigationGoldenFrame(brightness: brightness),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('ios-liquid-panel-source-specular')),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(MiuixIosLiquidGlassNavigationBar),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      final panelRect = tester.getRect(
        find.byKey(const ValueKey('ios-liquid-panel')),
      );
      final backdropRect = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(
        backdropRect,
        panelRect,
        reason: 'the complete pill must share one untruncated blur plane',
      );
      expect(panelRect.height, 56);

      await expectLater(
        find.byKey(const ValueKey('liquid-navigation-vivid-golden')),
        matchesGoldenFile(
          'goldens/hyperos4_liquid_navigation/${brightness.name}.png',
        ),
      );
    });
  }
}

class _LiquidNavigationGoldenFrame extends StatelessWidget {
  const _LiquidNavigationGoldenFrame({required this.brightness});

  final Brightness brightness;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff3482ff),
      brightness: brightness,
    );
    final miuixTheme = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('liquid-navigation-vivid-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, brightness: brightness),
        home: MiuixTheme(
          data: miuixTheme,
          child: Scaffold(
            extendBody: true,
            backgroundColor: Colors.transparent,
            body: const _VividBackdrop(),
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
              selectedIndex: 2,
              onDestinationSelected: (_) {},
              defaultWindowInsetsPadding: false,
              displayMode: MiuixFloatingNavigationBarDisplayMode.iconOnly,
              items: const <MiuixNavigationItem>[
                MiuixNavigationItem(
                  icon: _NavigationGlyph(_NavigationGlyphKind.home),
                  label: 'Home',
                ),
                MiuixNavigationItem(
                  icon: _NavigationGlyph(_NavigationGlyphKind.explore),
                  label: 'Explore',
                ),
                MiuixNavigationItem(
                  icon: _NavigationGlyph(_NavigationGlyphKind.create),
                  selectedIcon: _NavigationGlyph(_NavigationGlyphKind.create),
                  label: 'Create',
                ),
                MiuixNavigationItem(
                  icon: _NavigationGlyph(_NavigationGlyphKind.profile),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VividBackdrop extends StatelessWidget {
  const _VividBackdrop();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[
          Color(0xff1b64f2),
          Color(0xff6a36e8),
          Color(0xffee3f87),
          Color(0xffffae28),
        ],
        stops: <double>[0, .35, .7, 1],
      ),
    ),
    child: Stack(
      children: <Widget>[
        const Positioned(
          left: 28,
          bottom: 18,
          child: _BackdropOrb(color: Color(0xff00d99b), size: 118),
        ),
        const Positioned(
          left: 146,
          bottom: 0,
          child: _BackdropOrb(color: Color(0xffffdd2e), size: 96),
        ),
        const Positioned(
          right: 50,
          bottom: 22,
          child: _BackdropOrb(color: Color(0xff2ac8ff), size: 128),
        ),
        Align(
          alignment: const Alignment(0, .08),
          child: Container(
            width: 286,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(28),
            ),
          ),
        ),
      ],
    ),
  );
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

enum _NavigationGlyphKind { home, explore, create, profile }

class _NavigationGlyph extends StatelessWidget {
  const _NavigationGlyph(this.kind);

  final _NavigationGlyphKind kind;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size.square(22),
    painter: _NavigationGlyphPainter(
      kind: kind,
      color: IconTheme.of(context).color ?? Colors.black,
    ),
  );
}

class _NavigationGlyphPainter extends CustomPainter {
  const _NavigationGlyphPainter({required this.kind, required this.color});

  final _NavigationGlyphKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (kind) {
      case _NavigationGlyphKind.home:
        canvas.drawPath(
          Path()
            ..moveTo(3, 10)
            ..lineTo(11, 3)
            ..lineTo(19, 10)
            ..lineTo(19, 19)
            ..lineTo(13.5, 19)
            ..lineTo(13.5, 13)
            ..lineTo(8.5, 13)
            ..lineTo(8.5, 19)
            ..lineTo(3, 19)
            ..close(),
          paint,
        );
      case _NavigationGlyphKind.explore:
        canvas.drawCircle(const Offset(11, 11), 8, paint);
        canvas.drawPath(
          Path()
            ..moveTo(14.5, 7.5)
            ..lineTo(12.5, 12.5)
            ..lineTo(7.5, 14.5)
            ..lineTo(9.5, 9.5)
            ..close(),
          paint,
        );
      case _NavigationGlyphKind.create:
        canvas.drawPath(
          Path()
            ..moveTo(11, 2)
            ..lineTo(13.2, 8.8)
            ..lineTo(20, 11)
            ..lineTo(13.2, 13.2)
            ..lineTo(11, 20)
            ..lineTo(8.8, 13.2)
            ..lineTo(2, 11)
            ..lineTo(8.8, 8.8)
            ..close(),
          paint,
        );
      case _NavigationGlyphKind.profile:
        canvas.drawCircle(const Offset(11, 7), 4, paint);
        canvas.drawArc(
          const Rect.fromLTWH(3, 11, 16, 10),
          3.35,
          2.73,
          false,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _NavigationGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}
