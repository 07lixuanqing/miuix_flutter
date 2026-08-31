import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('structured surfaces $mode ${brightness.name}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(720, 820));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _StructuredSurfaceFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('structured-surfaces-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_structured_surfaces/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _StructuredSurfaceFrame extends StatelessWidget {
  const _StructuredSurfaceFrame({
    required this.brightness,
    required this.source,
  });

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a7cff),
      brightness: brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('structured-surfaces-golden'),
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
                        Color(0xff10182d),
                        Color(0xff362342),
                        Color(0xff14383e),
                      ]
                    : const <Color>[
                        Color(0xffd2e5ff),
                        Color(0xffffd9e7),
                        Color(0xffcdf2e5),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -42,
                  top: 118,
                  child: _MaterialOrb(size: 230, color: Color(0x887a86ff)),
                ),
                const Positioned(
                  left: -48,
                  bottom: 70,
                  child: _MaterialOrb(size: 210, color: Color(0x88ff789d)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 28, 30, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source
                            ? 'Source structured surfaces'
                            : 'HyperOS 4 structured surfaces',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _form(),
                      const SizedBox(height: 16),
                      _process(),
                      const SizedBox(height: 16),
                      Expanded(child: _table()),
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

  Widget _form() {
    final fields = <Widget>[
      MiuixFormField<String>(
        label: 'Account name',
        description: 'Shown to connected devices',
        initialValue: 'Xiaomi Account',
        fieldBuilder: (_) => const Text('Xiaomi Account'),
      ),
    ];
    final sourceFields = <Widget>[
      MiuixFormField<String>.source(
        label: 'Account name',
        description: 'Shown to connected devices',
        initialValue: 'Xiaomi Account',
        fieldBuilder: (_) => const Text('Xiaomi Account'),
      ),
    ];
    return source
        ? MiuixFormSection.source(title: 'ACCOUNT', children: sourceFields)
        : MiuixFormSection(title: 'ACCOUNT', children: fields);
  }

  Widget _process() {
    const steps = <MiuixProcessStep>[
      MiuixProcessStep(
        title: 'Connect device',
        subtitle: 'Nearby pairing is ready',
        content: Text('Keep both devices unlocked during transfer.'),
      ),
      MiuixProcessStep(title: 'Transfer settings'),
    ];
    return source
        ? const MiuixProcessStepper.source(
            steps: steps,
            showDefaultActions: false,
          )
        : const MiuixProcessStepper(steps: steps, showDefaultActions: false);
  }

  Widget _table() {
    final columns = <MiuixDataColumn<int>>[
      MiuixDataColumn<int>(
        id: 'device',
        label: 'Device',
        width: 250,
        cellBuilder: (_, item) => Text('Device $item'),
      ),
      MiuixDataColumn<int>(
        id: 'state',
        label: 'State',
        width: 220,
        cellBuilder: (_, item) => Text(item == 1 ? 'Connected' : 'Available'),
      ),
    ];
    return source
        ? MiuixDataTable<int>.source(
            items: const <int>[1, 2],
            columns: columns,
            rowKey: _rowKey,
            height: 220,
            shrinkWrapRows: true,
          )
        : MiuixDataTable<int>(
            items: const <int>[1, 2],
            columns: columns,
            rowKey: _rowKey,
            height: 220,
            shrinkWrapRows: true,
          );
  }

  static Object _rowKey(int item) => item;
}

class _MaterialOrb extends StatelessWidget {
  const _MaterialOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
