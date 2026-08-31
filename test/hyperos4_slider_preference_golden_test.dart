import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('slider preference hierarchy $mode ${brightness.name}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(620, 560));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _SliderPreferenceFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('slider-preference-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_slider_preference/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _SliderPreferenceFrame extends StatelessWidget {
  const _SliderPreferenceFrame({
    required this.brightness,
    required this.source,
  });

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff487eff),
      brightness: brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('slider-preference-golden'),
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
                        Color(0xff11182c),
                        Color(0xff352441),
                        Color(0xff16393d),
                      ]
                    : const <Color>[
                        Color(0xffd3e5ff),
                        Color(0xffffdbe8),
                        Color(0xffcef2e5),
                      ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 28, 32, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    source ? 'Source slider rows' : 'HyperOS 4 slider rows',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _group(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _group() => source
      ? MiuixSettingsGroup.source(
          title: 'SOUND AND DISPLAY',
          showDividers: true,
          children: <Widget>[
            MiuixSliderPreference.source(
              title: 'Media volume',
              summary: 'Calls use a separate level',
              valueText: '62%',
              value: .62,
              steps: 4,
              showKeyPoints: true,
              onValueChange: _setDouble,
            ),
            MiuixRangeSliderPreference.source(
              title: 'Reading brightness',
              summary: 'Adaptive range during the day',
              valueText: '24% – 78%',
              value: const RangeValues(.24, .78),
              steps: 4,
              showKeyPoints: true,
              onValueChange: _setRange,
            ),
          ],
        )
      : const MiuixSettingsGroup(
          title: 'SOUND AND DISPLAY',
          showDividers: true,
          children: <Widget>[
            MiuixSliderPreference(
              title: 'Media volume',
              summary: 'Calls use a separate level',
              valueText: '62%',
              value: .62,
              divisions: 5,
              showKeyPoints: true,
              onChanged: _setDouble,
            ),
            MiuixRangeSliderPreference(
              title: 'Reading brightness',
              summary: 'Adaptive range during the day',
              valueText: '24% – 78%',
              values: RangeValues(.24, .78),
              divisions: 5,
              showKeyPoints: true,
              onChanged: _setRange,
            ),
          ],
        );

  static void _setDouble(double _) {}
  static void _setRange(RangeValues _) {}
}
