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
      testWidgets('floating action $mode ${brightness.name} complex backdrop', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(440, 520));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _FloatingActionGoldenFrame(brightness: brightness, source: source),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          find.byKey(const ValueKey('create-action-glyph')),
          findsOneWidget,
        );
        expect(
          find.byType(MiuixGlass),
          source ? findsNothing : findsNWidgets(2),
        );
        await expectLater(
          find.byKey(const ValueKey('floating-action-complex-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_floating_action_button/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _FloatingActionGoldenFrame extends StatelessWidget {
  const _FloatingActionGoldenFrame({
    required this.brightness,
    required this.source,
  });

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
      key: const ValueKey('floating-action-complex-golden'),
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
                  top: 92,
                  left: 52,
                  child: _Orb(color: Color(0xaa6c89ff), size: 166),
                ),
                const Positioned(
                  top: 234,
                  right: 30,
                  child: _Orb(color: Color(0xaaff6f9d), size: 148),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _action(source: source, child: const _PlusGlyph()),
                      const SizedBox(height: 44),
                      _action(
                        source: source,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: _CreateGlyph(),
                        ),
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

  Widget _action({required bool source, required Widget child}) {
    return source
        ? MiuixFloatingActionButton.source(onPressed: () {}, child: child)
        : MiuixFloatingActionButton(onPressed: () {}, child: child);
  }
}

class _PlusGlyph extends StatelessWidget {
  const _PlusGlyph();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return SizedBox.square(
      dimension: 24,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: 20,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateGlyph extends StatelessWidget {
  const _CreateGlyph();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.white;
    return Container(
      key: const ValueKey('create-action-glyph'),
      width: 48,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
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
  final loader = FontLoader('Roboto');
  for (final name in const <String>[
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]) {
    final bytes = await File(
      '${materialFonts.path}${Platform.pathSeparator}$name',
    ).readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
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
