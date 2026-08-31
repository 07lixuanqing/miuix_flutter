import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('small title $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 360));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _SmallTitleFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('small-title-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_small_title/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _SmallTitleFrame extends StatelessWidget {
  const _SmallTitleFrame({required this.brightness, required this.source});

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
      key: const ValueKey('small-title-golden'),
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
          child: ColoredBox(
            color: dark ? const Color(0xff14161d) : const Color(0xfff5f6fa),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 26, 32, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    source ? 'Source section labels' : 'HyperOS 4 hierarchy',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _title('Account and security'),
                  _sampleSurface(scheme, 'Sign-in options'),
                  const SizedBox(height: 10),
                  _title('Connected devices'),
                  _sampleSurface(scheme, 'Nearby sharing'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) =>
      source ? MiuixSmallTitle.source(text) : MiuixSmallTitle(text);

  Widget _sampleSurface(ColorScheme scheme, String label) => Container(
    height: 54,
    alignment: AlignmentDirectional.centerStart,
    padding: const EdgeInsets.symmetric(horizontal: 18),
    decoration: BoxDecoration(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(label, style: TextStyle(color: scheme.onSurface, fontSize: 16)),
  );
}
