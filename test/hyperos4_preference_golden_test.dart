import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('preference hierarchy $mode ${brightness.name}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(620, 650));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _PreferenceFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('preference-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_preference/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _PreferenceFrame extends StatelessWidget {
  const _PreferenceFrame({required this.brightness, required this.source});

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
      key: const ValueKey('preference-golden'),
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
                    source ? 'Source preference rows' : 'HyperOS 4 hierarchy',
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
          title: 'SYSTEM SERVICES',
          showDividers: true,
          children: <Widget>[
            const MiuixArrowPreference.source(
              title: 'Account security',
              summary: 'Password and sign-in methods',
              onClick: _noop,
            ),
            const MiuixSwitchPreference.source(
              title: 'Cloud synchronization',
              summary: 'Keep settings across devices',
              checked: true,
              onCheckedChange: _setBool,
            ),
            const MiuixCheckboxPreference.source(
              title: 'Usage diagnostics',
              checked: false,
              onCheckedChange: _setBool,
            ),
            MiuixRadioButtonPreference.source(
              title: 'Balanced protection',
              selected: true,
              onClick: _noop,
            ),
          ],
        )
      : const MiuixSettingsGroup(
          title: 'SYSTEM SERVICES',
          showDividers: true,
          children: <Widget>[
            MiuixArrowPreference(
              title: 'Account security',
              summary: 'Password and sign-in methods',
              onTap: _noop,
            ),
            MiuixSwitchPreference(
              title: 'Cloud synchronization',
              summary: 'Keep settings across devices',
              value: true,
              onChanged: _setBool,
            ),
            MiuixCheckboxPreference(
              title: 'Usage diagnostics',
              value: false,
              onChanged: _setBool,
            ),
            MiuixRadioButtonPreference<int>(
              title: 'Balanced protection',
              value: 1,
              groupValue: 1,
              onChanged: _setInt,
            ),
          ],
        );

  static void _noop() {}
  static void _setBool(bool _) {}
  static void _setInt(int? _) {}
}
