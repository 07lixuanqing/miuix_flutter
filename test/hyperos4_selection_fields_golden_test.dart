import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('selection fields $mode ${brightness.name} baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(520, 500));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _SelectionFieldFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('selection-fields-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_selection_fields/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _SelectionFieldFrame extends StatelessWidget {
  const _SelectionFieldFrame({required this.brightness, required this.source});

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
    return RepaintBoundary(
      key: const ValueKey('selection-fields-golden'),
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
                  right: -16,
                  top: 54,
                  child: _SelectionBackdropOrb(
                    size: 176,
                    color: Color(0x887695ff),
                  ),
                ),
                const Positioned(
                  left: -28,
                  bottom: 28,
                  child: _SelectionBackdropOrb(
                    size: 142,
                    color: Color(0x88ff789e),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 42, 32, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source ? 'Source fields' : 'HyperOS 4 fields',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 24),
                      _multiSelect(),
                      const SizedBox(height: 18),
                      _searchableSelect(),
                      const SizedBox(height: 18),
                      _comboBox(),
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

  Widget _multiSelect() => source
      ? const MiuixMultiSelect<String>.source(
          label: 'Tags',
          initialSelected: <String>['a', 'b'],
          options: _multiOptions,
        )
      : const MiuixMultiSelect<String>(
          label: 'Tags',
          initialSelected: <String>['a', 'b'],
          options: _multiOptions,
        );

  Widget _searchableSelect() => source
      ? const MiuixSearchableSelect<int>.source(
          label: 'Regions',
          multiple: true,
          initialSelected: <int>[1, 2],
          options: _searchOptions,
        )
      : const MiuixSearchableSelect<int>(
          label: 'Regions',
          multiple: true,
          initialSelected: <int>[1, 2],
          options: _searchOptions,
        );

  Widget _comboBox() => source
      ? const MiuixComboBox<int>.source(
          label: 'Workspace',
          initialSelected: <int>[2],
          options: _searchOptions,
        )
      : const MiuixComboBox<int>(
          label: 'Workspace',
          initialSelected: <int>[2],
          options: _searchOptions,
        );

  static const _multiOptions = <MiuixMultiSelectOption<String>>[
    MiuixMultiSelectOption<String>(value: 'a', label: 'Design'),
    MiuixMultiSelectOption<String>(value: 'b', label: 'Review'),
  ];

  static const _searchOptions = <MiuixSearchableSelectOption<int>>[
    MiuixSearchableSelectOption<int>(value: 1, label: 'Beijing'),
    MiuixSearchableSelectOption<int>(value: 2, label: 'Shanghai'),
  ];
}

class _SelectionBackdropOrb extends StatelessWidget {
  const _SelectionBackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
