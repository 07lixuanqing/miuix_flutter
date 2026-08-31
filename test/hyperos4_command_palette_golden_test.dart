import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('command palette $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 520));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _CommandPaletteFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('command-palette-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_command_palette/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _CommandPaletteFrame extends StatelessWidget {
  const _CommandPaletteFrame({required this.brightness, required this.source});

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
    final palette = source
        ? MiuixCommandPalette.source(autofocus: false, commands: _commands)
        : MiuixCommandPalette(autofocus: false, commands: _commands);
    return RepaintBoundary(
      key: const ValueKey('command-palette-golden'),
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
                  right: -36,
                  top: 36,
                  child: _PaletteOrb(size: 220, color: Color(0x997695ff)),
                ),
                const Positioned(
                  left: -40,
                  bottom: 20,
                  child: _PaletteOrb(size: 190, color: Color(0x99ff789e)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(42, 28, 42, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source ? 'Source command host' : 'HyperOS 4 commands',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 20),
                      palette,
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

  static final _commands = <MiuixCommand>[
    MiuixCommand(
      id: 'open',
      title: 'Open document',
      subtitle: 'Choose a recent workspace',
      icon: const Icon(Icons.folder_open_rounded),
      shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
      onInvoke: () {},
    ),
    MiuixCommand(
      id: 'theme',
      title: 'Switch appearance',
      subtitle: 'Follow the system theme',
      icon: const Icon(Icons.palette_outlined),
      onInvoke: () {},
    ),
    MiuixCommand(
      id: 'disabled',
      title: 'Unavailable command',
      category: 'Workspace',
      enabled: false,
      icon: const Icon(Icons.lock_outline_rounded),
      onInvoke: () {},
    ),
  ];
}

class _PaletteOrb extends StatelessWidget {
  const _PaletteOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
