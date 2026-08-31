import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('autocomplete $mode ${brightness.name} baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(520, 420));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _AutoCompleteFrame(brightness: brightness, source: source),
        );
        await tester.enterText(find.byType(EditableText), 'a');
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('autocomplete-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_autocomplete/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _AutoCompleteFrame extends StatelessWidget {
  const _AutoCompleteFrame({required this.brightness, required this.source});

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
    return RepaintBoundary(
      key: const ValueKey('autocomplete-golden'),
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
                  left: 92,
                  top: 150,
                  child: _BackdropOrb(size: 172, color: Color(0x997695ff)),
                ),
                const Positioned(
                  right: 34,
                  top: 238,
                  child: _BackdropOrb(size: 124, color: Color(0x99ff789e)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 42, 48, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source
                            ? 'Source autocomplete'
                            : 'HyperOS 4 autocomplete',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      source
                          ? MiuixAutoCompleteField<String>.source(
                              label: 'Destination',
                              displayStringForOption: (option) => option,
                              optionsBuilder: _options,
                            )
                          : MiuixAutoCompleteField<String>(
                              label: 'Destination',
                              displayStringForOption: (option) => option,
                              optionsBuilder: _options,
                            ),
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

  static Iterable<String> _options(TextEditingValue value) => const <String>[
    'Hangzhou',
    'Shanghai',
    'Guangzhou',
  ];
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
