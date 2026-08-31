import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final glass in <bool>[true, false]) {
      final mode = glass ? 'hyperos4' : 'solid';
      testWidgets('date range picker $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 620));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _DateRangeFrame(brightness: brightness, glass: glass),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('date-range-picker-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_date_range_picker/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _DateRangeFrame extends StatefulWidget {
  const _DateRangeFrame({required this.brightness, required this.glass});

  final Brightness brightness;
  final bool glass;

  @override
  State<_DateRangeFrame> createState() => _DateRangeFrameState();
}

class _DateRangeFrameState extends State<_DateRangeFrame> {
  late final MiuixDateRangePickerController _controller =
      MiuixDateRangePickerController(
        value: MiuixDateRange(DateTime(2026, 8, 10), DateTime(2026, 8, 18)),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4b7dff),
      brightness: widget.brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('date-range-picker-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          brightness: widget.brightness,
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
                        Color(0xff11182d),
                        Color(0xff352341),
                        Color(0xff12383e),
                      ]
                    : const <Color>[
                        Color(0xffd1e5ff),
                        Color(0xffffd9e7),
                        Color(0xffcdf2e5),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -48,
                  top: 96,
                  child: _CalendarOrb(size: 240, color: Color(0x887987ff)),
                ),
                const Positioned(
                  left: -54,
                  bottom: 42,
                  child: _CalendarOrb(size: 215, color: Color(0x88ff779c)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(30, 24, 30, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        widget.glass
                            ? 'HyperOS 4 date range'
                            : 'Solid material fallback',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      MiuixDateRangePicker(
                        controller: _controller,
                        glass: widget.glass,
                        startLabel: 'START DATE',
                        endLabel: 'END DATE',
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
}

class _CalendarOrb extends StatelessWidget {
  const _CalendarOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
