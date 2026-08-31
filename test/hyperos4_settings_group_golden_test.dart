import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('settings group $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(620, 520));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _SettingsGroupFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('settings-group-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_settings_group/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _SettingsGroupFrame extends StatelessWidget {
  const _SettingsGroupFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff437cff),
      brightness: brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('settings-group-golden'),
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
                        Color(0xff12182d),
                        Color(0xff382345),
                        Color(0xff123c3d),
                      ]
                    : const <Color>[
                        Color(0xffcfe3ff),
                        Color(0xffffd7e6),
                        Color(0xffc9f2e4),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -34,
                  top: 86,
                  child: _BackdropOrb(size: 210, color: Color(0x887b6dff)),
                ),
                const Positioned(
                  left: -42,
                  bottom: 34,
                  child: _BackdropOrb(size: 188, color: Color(0x88ff719d)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 30, 32, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        source ? 'Source settings' : 'HyperOS 4 settings',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _group(),
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

  Widget _group() {
    const rows = <Widget>[
      MiuixPreference(
        title: 'Cloud backup',
        summary: 'Synchronize every night',
        leading: Icon(Icons.cloud_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
      MiuixPreference(
        title: 'Nearby devices',
        summary: 'Visible to signed-in devices',
        leading: Icon(Icons.devices_other_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
      MiuixPreference(
        title: 'Privacy protection',
        leading: Icon(Icons.shield_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
    ];
    const sourceRows = <Widget>[
      MiuixPreference.source(
        title: 'Cloud backup',
        summary: 'Synchronize every night',
        leading: Icon(Icons.cloud_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
      MiuixPreference.source(
        title: 'Nearby devices',
        summary: 'Visible to signed-in devices',
        leading: Icon(Icons.devices_other_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
      MiuixPreference.source(
        title: 'Privacy protection',
        leading: Icon(Icons.shield_outlined),
        trailing: Icon(Icons.chevron_right),
      ),
    ];
    return source
        ? const MiuixSettingsGroup.source(
            title: 'ACCOUNT SERVICES',
            showDividers: true,
            children: sourceRows,
          )
        : const MiuixSettingsGroup(
            title: 'ACCOUNT SERVICES',
            showDividers: true,
            children: rows,
          );
  }
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
