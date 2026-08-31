import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('text $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 390));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _TextFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('text-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_text/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _TextFrame extends StatelessWidget {
  const _TextFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff3482ff),
      brightness: brightness,
    );
    return RepaintBoundary(
      key: const ValueKey('text-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          brightness: brightness,
          fontFamily: 'Roboto',
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16, height: 1.16),
            bodyLarge: TextStyle(fontSize: 17, height: 1.16),
          ),
        ),
        home: MiuixTheme(
          child: ColoredBox(
            color: dark ? const Color(0xff14161d) : const Color(0xfff5f6fa),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(34, 28, 34, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    source ? 'MIUIX 1.0.9 source' : 'HyperOS 4 content body',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontSize: 27,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: DefaultTextStyle.merge(
                      style: TextStyle(color: scheme.onSurface),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _plain(
                            'This paragraph uses the default content role.',
                          ),
                          const SizedBox(height: 15),
                          _rich(),
                          const SizedBox(height: 15),
                          _plain(
                            'Explicit 20sp caller size stays authoritative.',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _plain(String text, {TextStyle? style}) => source
      ? MiuixText.source(text, style: style)
      : MiuixText(text, style: style);

  Widget _rich() {
    const span = TextSpan(
      text: 'Rich text keeps ',
      children: <InlineSpan>[
        TextSpan(
          text: 'semantic emphasis',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        TextSpan(text: ' within the same body role.'),
      ],
    );
    return source
        ? const MiuixText.sourceRich(span)
        : const MiuixText.rich(span);
  }
}
