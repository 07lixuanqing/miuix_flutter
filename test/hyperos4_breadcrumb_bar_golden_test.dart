import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('breadcrumb bar $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 280));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _BreadcrumbFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('breadcrumb-bar-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_breadcrumb_bar/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _BreadcrumbFrame extends StatelessWidget {
  const _BreadcrumbFrame({required this.brightness, required this.source});

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
    final bar = source
        ? MiuixBreadcrumbBar.source(
            items: _items,
            highlightIndex: 2,
            onItemClick: (_) {},
          )
        : MiuixBreadcrumbBar(
            items: _items,
            highlightIndex: 2,
            onItemClick: (_) {},
          );
    return RepaintBoundary(
      key: const ValueKey('breadcrumb-bar-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          brightness: brightness,
          fontFamily: 'Roboto',
        ),
        home: MiuixTheme(
          data: defaults.copyWith(
            textTheme: defaults.textTheme.apply(fontFamily: 'Roboto'),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const <Color>[
                        Color(0xff10182f),
                        Color(0xff302143),
                        Color(0xff123940),
                      ]
                    : const <Color>[
                        Color(0xffd4e6ff),
                        Color(0xffffd9e7),
                        Color(0xffcef5eb),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -34,
                  top: 22,
                  child: _BreadcrumbOrb(size: 180, color: Color(0x997695ff)),
                ),
                const Positioned(
                  left: -38,
                  bottom: -42,
                  child: _BreadcrumbOrb(size: 160, color: Color(0x99ff789e)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 30, 32, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source ? 'Source path capsules' : 'HyperOS 4 path',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 26),
                      bar,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _items = <MiuixBreadcrumbItem>[
    MiuixBreadcrumbItem(path: 'storage', text: 'Storage'),
    MiuixBreadcrumbItem(path: 'pictures', text: 'Pictures'),
    MiuixBreadcrumbItem(path: 'summer', text: 'Summer album'),
  ];
}

class _BreadcrumbOrb extends StatelessWidget {
  const _BreadcrumbOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
