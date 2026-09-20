import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    testWidgets('small top actions ${brightness.name}', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 160));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);

      final scheme = ColorScheme.fromSeed(
        seedColor: const Color(0xff3482ff),
        brightness: brightness,
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('small-top-actions-golden'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(colorScheme: scheme, brightness: brightness),
            home: MiuixTheme(
              data: MiuixThemeData.defaults(
                mode: brightness == Brightness.dark
                    ? MiuixColorMode.dark
                    : MiuixColorMode.light,
              ),
              child: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: MiuixSmallTopAppBar(
                  title: 'Gallery',
                  glass: true,
                  actions: [
                    MiuixIconButton(
                      selected: true,
                      onPressed: () {},
                      icon: const Icon(Icons.grid_view_rounded),
                    ),
                    MiuixIconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert_rounded),
                    ),
                  ],
                ),
                body: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xff35c5f0),
                        Color(0xff6f50ed),
                        Color(0xffff5c8a),
                      ],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(const ValueKey('small-top-actions-golden')),
        matchesGoldenFile(
          'goldens/hyperos4_top_actions/${brightness.name}.png',
        ),
      );
    });
  }
}
