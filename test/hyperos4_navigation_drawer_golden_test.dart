import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('navigation drawer $mode ${brightness.name} baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(500, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _NavigationDrawerFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('navigation-drawer-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_navigation_drawer/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _NavigationDrawerFrame extends StatelessWidget {
  const _NavigationDrawerFrame({
    required this.brightness,
    required this.source,
  });

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a77ff),
      brightness: brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    final miuixTheme = defaults.copyWith(
      textTheme: defaults.textTheme.apply(fontFamily: 'Roboto'),
    );
    final drawer = source
        ? MiuixNavigationDrawer.source(
            items: _items,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            header: const _DrawerHeader(source: true),
            footer: const _DrawerFooter(),
          )
        : MiuixNavigationDrawer(
            items: _items,
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            header: const _DrawerHeader(source: false),
            footer: const _DrawerFooter(),
          );
    return RepaintBoundary(
      key: const ValueKey('navigation-drawer-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          brightness: brightness,
          fontFamily: 'Roboto',
        ),
        home: MiuixTheme(
          data: miuixTheme,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const <Color>[
                        Color(0xff11182e),
                        Color(0xff302348),
                        Color(0xff12373f),
                      ]
                    : const <Color>[
                        Color(0xffd4e5ff),
                        Color(0xffffdae7),
                        Color(0xffcff3e8),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -32,
                  top: 96,
                  child: _BackdropOrb(size: 188, color: Color(0x887695ff)),
                ),
                const Positioned(
                  right: 18,
                  bottom: 72,
                  child: _BackdropOrb(size: 132, color: Color(0x88ff789e)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    drawer,
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 34, 16, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Workspace',
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Expanded(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surface.withValues(alpha: .42),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _items = <MiuixNavigationItem>[
    MiuixNavigationItem(
      icon: _DrawerGlyph(shape: _DrawerGlyphShape.circle),
      selectedIcon: _DrawerGlyph(
        shape: _DrawerGlyphShape.circle,
        selected: true,
      ),
      label: 'Overview',
    ),
    MiuixNavigationItem(
      icon: _DrawerGlyph(shape: _DrawerGlyphShape.square),
      label: 'Documents',
    ),
    MiuixNavigationItem(
      icon: _DrawerGlyph(shape: _DrawerGlyphShape.diamond),
      label: 'Automation',
    ),
  ];
}

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({required this.source});

  final bool source;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(22, 28, 18, 18),
    child: Text(
      source ? 'Source drawer' : 'HyperOS 4',
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
    ),
  );
}

class _DrawerFooter extends StatelessWidget {
  const _DrawerFooter();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Text('Settings', style: Theme.of(context).textTheme.bodyLarge),
  );
}

enum _DrawerGlyphShape { circle, square, diamond }

class _DrawerGlyph extends StatelessWidget {
  const _DrawerGlyph({required this.shape, this.selected = false});

  final _DrawerGlyphShape shape;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.black;
    final radius = switch (shape) {
      _DrawerGlyphShape.circle => 999.0,
      _DrawerGlyphShape.square => 5.0,
      _DrawerGlyphShape.diamond => 4.0,
    };
    final glyph = Container(
      width: selected ? 19 : 18,
      height: selected ? 19 : 18,
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    return shape == _DrawerGlyphShape.diamond
        ? Transform.rotate(angle: .785398, child: glyph)
        : glyph;
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
