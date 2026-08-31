import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('tooltip $mode ${brightness.name} complex backdrop', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(440, 520));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);
        final state = MiuixTooltipState(
          initialIsVisible: true,
          isPersistent: true,
        );
        addTearDown(state.dispose);

        await tester.pumpWidget(
          _TooltipGoldenFrame(
            brightness: brightness,
            source: source,
            state: state,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Backdrop-aware tooltip'), findsOneWidget);
        await expectLater(
          find.byKey(const ValueKey('tooltip-complex-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_tooltip/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _TooltipGoldenFrame extends StatelessWidget {
  const _TooltipGoldenFrame({
    required this.brightness,
    required this.source,
    required this.state,
  });

  final Brightness brightness;
  final bool source;
  final MiuixTooltipState state;

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
    final anchor = Container(
      width: 112,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .42),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        width: source ? 42 : 54,
        height: 6,
        decoration: BoxDecoration(
          color: scheme.primary.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    return RepaintBoundary(
      key: const ValueKey('tooltip-complex-golden'),
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
                        Color(0xff151a31),
                        Color(0xff352550),
                        Color(0xff123b41),
                      ]
                    : const <Color>[
                        Color(0xffcfe1ff),
                        Color(0xffffd8e5),
                        Color(0xffcaf4e7),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  top: 112,
                  left: 64,
                  child: _Orb(color: Color(0xaa6c89ff), size: 150),
                ),
                const Positioned(
                  top: 216,
                  right: 28,
                  child: _Orb(color: Color(0x99ff6f9d), size: 136),
                ),
                Center(
                  child: source
                      ? MiuixTooltip.source(
                          state: state,
                          positioning: MiuixTooltipAnchorPosition.below,
                          message: 'Backdrop-aware tooltip',
                          child: anchor,
                        )
                      : MiuixTooltip(
                          state: state,
                          positioning: MiuixTooltipAnchorPosition.below,
                          message: 'Backdrop-aware tooltip',
                          child: anchor,
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

class _Orb extends StatelessWidget {
  const _Orb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

Future<void> _loadGoldenFonts() async {
  final materialFonts = _findMaterialFontDirectory();

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final name in files) {
      final bytes = await File(
        '${materialFonts.path}${Platform.pathSeparator}$name',
      ).readAsBytes();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', const <String>[
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]);
}

Directory _findMaterialFontDirectory() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <Directory>[
    if (flutterRoot != null)
      Directory(
        '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
        'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
        'material_fonts',
      ),
  ];
  var cursor = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 8; depth++) {
    candidates.addAll(<Directory>[
      Directory(
        '${cursor.path}${Platform.pathSeparator}artifacts'
        '${Platform.pathSeparator}material_fonts',
      ),
      Directory(
        '${cursor.path}${Platform.pathSeparator}cache'
        '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
        'material_fonts',
      ),
    ]);
    cursor = cursor.parent;
  }
  return candidates.firstWhere(
    (directory) => File(
      '${directory.path}${Platform.pathSeparator}roboto-regular.ttf',
    ).existsSync(),
    orElse: () => throw StateError(
      'Could not locate Flutter material fonts for golden tests.',
    ),
  );
}
