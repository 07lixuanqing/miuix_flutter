import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('context menu $mode ${brightness.name} visual baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(440, 360));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _ContextMenuFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('context-menu-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_context_menu/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _ContextMenuFrame extends StatelessWidget {
  const _ContextMenuFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a77ff),
      brightness: brightness,
    );
    final menu = source
        ? MiuixContextMenu<String>.source(items: _items, onSelected: (_) {})
        : MiuixContextMenu<String>(items: _items, onSelected: (_) {});
    return MiuixTheme(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, brightness: brightness),
        home: RepaintBoundary(
          key: const ValueKey('context-menu-golden'),
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
                Positioned(
                  left: 34,
                  top: 30,
                  child: Text(
                    source ? 'Source menu' : 'HyperOS 4 menu',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Positioned(left: 104, top: 96, child: menu),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static const _items = <MiuixContextMenuItem<String>>[
    MiuixContextMenuItem(value: 'copy', label: 'Copy'),
    MiuixContextMenuItem(value: 'rename', label: 'Rename item'),
    MiuixContextMenuItem(
      value: 'delete',
      label: 'Delete',
      destructive: true,
      separatorBefore: true,
    ),
  ];
}
