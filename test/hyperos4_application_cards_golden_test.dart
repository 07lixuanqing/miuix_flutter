import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('application cards $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 920));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _ApplicationCardFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('application-cards-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_application_cards/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _ApplicationCardFrame extends StatelessWidget {
  const _ApplicationCardFrame({required this.brightness, required this.source});

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
      key: const ValueKey('application-cards-golden'),
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
                  right: -36,
                  top: 110,
                  child: _CardBackdropOrb(size: 238, color: Color(0x887695ff)),
                ),
                const Positioned(
                  left: -54,
                  top: 410,
                  child: _CardBackdropOrb(size: 210, color: Color(0x88ff789e)),
                ),
                const Positioned(
                  right: 56,
                  bottom: -36,
                  child: _CardBackdropOrb(size: 190, color: Color(0x8876d9b0)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 32, 32, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source ? 'Source application cards' : 'HyperOS 4 cards',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      ..._cards().expand(
                        (card) => <Widget>[card, const SizedBox(height: 12)],
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

  List<Widget> _cards() => source
      ? <Widget>[
          const MiuixAccountHeader.source(
            name: 'Mi Account',
            subtitle: 'Cloud sync enabled',
          ),
          const MiuixDeviceCard.source(
            name: 'Xiaomi Pad',
            status: 'Connected',
            battery: 86,
          ),
          const MiuixAppListTile.source(
            name: 'Gallery',
            packageName: 'com.miui.gallery',
          ),
          const MiuixNotificationCard.source(
            appName: 'System updater',
            title: 'Update ready',
            body: 'Restart to finish installing the update.',
          ),
          const MiuixPermissionCard.source(
            permission: 'Nearby devices',
            description: 'Find and connect to devices around you.',
            onAllow: _ignore,
            onDeny: _ignore,
          ),
          const MiuixUpdateCard.source(
            version: 'HyperOS 4.0',
            summary: 'Security, continuity, and stability improvements.',
            progress: .64,
          ),
        ]
      : <Widget>[
          const MiuixAccountHeader(
            name: 'Mi Account',
            subtitle: 'Cloud sync enabled',
          ),
          const MiuixDeviceCard(
            name: 'Xiaomi Pad',
            status: 'Connected',
            battery: 86,
          ),
          const MiuixAppListTile(
            name: 'Gallery',
            packageName: 'com.miui.gallery',
          ),
          const MiuixNotificationCard(
            appName: 'System updater',
            title: 'Update ready',
            body: 'Restart to finish installing the update.',
          ),
          const MiuixPermissionCard(
            permission: 'Nearby devices',
            description: 'Find and connect to devices around you.',
            onAllow: _ignore,
            onDeny: _ignore,
          ),
          const MiuixUpdateCard(
            version: 'HyperOS 4.0',
            summary: 'Security, continuity, and stability improvements.',
            progress: .64,
          ),
        ];

  static void _ignore() {}
}

class _CardBackdropOrb extends StatelessWidget {
  const _CardBackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
