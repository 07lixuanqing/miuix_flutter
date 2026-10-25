import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

Future<void> back(WidgetTester tester, String method) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall(
        method,
        method == 'startBackGesture' || method == 'updateBackGestureProgress'
            ? {
                'touchOffset': [1.0, 200.0],
                'progress': method == 'startBackGesture' ? 0.0 : .5,
                'swipeEdge': 0,
              }
            : null,
      ),
    ),
    (_) {},
  );
}

class _DependentPage extends StatelessWidget {
  const _DependentPage(this.name, this.builds);
  final String name;
  final Map<String, int> builds;
  @override
  Widget build(BuildContext context) {
    builds[name] = (builds[name] ?? 0) + 1;
    return Text(
      name,
      style: Theme.of(context).textTheme.bodyMedium,
      textScaler: MediaQuery.textScalerOf(context),
    );
  }
}

void main() {
  for (final mode in ['button', 'system', 'gesture']) {
    for (final effects in [true, false]) {
      testWidgets(
        'route content stays mounted and cached for $mode effects=$effects',
        (tester) async {
          final navigator = GlobalKey<NavigatorState>();
          final builds = <String, int>{};
          var dark = false;
          late StateSetter updateTheme;
          await tester.pumpWidget(
            StatefulBuilder(
              builder: (context, change) {
                updateTheme = change;
                return MaterialApp(
                  navigatorKey: navigator,
                  theme: ThemeData(
                    brightness: dark ? Brightness.dark : Brightness.light,
                    platform: TargetPlatform.android,
                    pageTransitionsTheme: PageTransitionsTheme(
                      builders: {
                        TargetPlatform.android:
                            MiuixNavigationPageTransitionsBuilder(
                              enableDim: effects,
                              enableCornerClip: effects,
                            ),
                      },
                    ),
                  ),
                  home: _DependentPage('root', builds),
                );
              },
            ),
          );
          await tester.pumpAndSettle();
          navigator.currentState!.push(
            MiuixPageRoute<void>(
              builder: (_) => _DependentPage('detail', builds),
            ),
          );
          await tester.pumpAndSettle();
          expect(builds, {'root': 1, 'detail': 1});
          if (mode == 'gesture') {
            await back(tester, 'startBackGesture');
            await back(tester, 'updateBackGestureProgress');
            await tester.pump();
            await back(tester, 'cancelBackGesture');
            await tester.pumpAndSettle();
            expect(builds, {'root': 1, 'detail': 1});
            await back(tester, 'startBackGesture');
            await back(tester, 'updateBackGestureProgress');
            await tester.pump();
            await back(tester, 'commitBackGesture');
          } else if (mode == 'system') {
            await tester.binding.handlePopRoute();
          } else {
            navigator.currentState!.pop();
          }
          await tester.pumpAndSettle();
          expect(builds, {'root': 1, 'detail': 1});
          updateTheme(() => dark = true);
          await tester.pumpAndSettle();
          expect(
            builds['root'],
            greaterThan(1),
            reason: 'real theme changes must still rebuild content',
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
