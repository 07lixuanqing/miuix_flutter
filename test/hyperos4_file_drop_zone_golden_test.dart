import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('file drop $mode ${brightness.name} visual baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(560, 520));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _FileDropFrame(brightness: brightness, source: source),
        );
        await tester.pump();
        final activeTarget = tester.widget<DropTarget>(
          find.byType(DropTarget).at(1),
        );
        activeTarget.onDragEntered!(
          DropEventDetails(
            localPosition: const Offset(120, 80),
            globalPosition: const Offset(120, 300),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        await expectLater(
          find.byKey(const ValueKey('file-drop-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_file_drop_zone/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _FileDropFrame extends StatelessWidget {
  const _FileDropFrame({required this.brightness, required this.source});

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
      key: const ValueKey('file-drop-golden'),
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
                  right: 12,
                  top: 40,
                  child: _DropBackdropOrb(size: 180, color: Color(0x887695ff)),
                ),
                const Positioned(
                  left: -24,
                  bottom: 20,
                  child: _DropBackdropOrb(size: 150, color: Color(0x88ff789e)),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: <Widget>[
                      _zone(),
                      const SizedBox(height: 24),
                      _zone(),
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

  Widget _zone() {
    Widget builder(
      BuildContext context,
      bool dragging,
      List<MiuixDroppedFile> files,
    ) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _DropGlyph(active: dragging),
          const SizedBox(height: 12),
          Text(
            dragging ? 'Release to add files' : 'Drop files here',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
    return source
        ? MiuixFileDropZone.source(builder: builder)
        : MiuixFileDropZone(builder: builder);
  }
}

class _DropGlyph extends StatelessWidget {
  const _DropGlyph({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active
        ? MiuixSemanticColors.of(context)['primary']
        : MiuixSemanticColors.of(context)['onSurface'];
    return SizedBox(
      width: 42,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 1,
            child: Container(width: 30, height: 3, color: color),
          ),
          Transform.rotate(
            angle: active ? 3.141593 : 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(width: 3, height: 21, color: color),
                Transform.rotate(
                  angle: .785398,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: color, width: 3),
                        bottom: BorderSide(color: color, width: 3),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropBackdropOrb extends StatelessWidget {
  const _DropBackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
