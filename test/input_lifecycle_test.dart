import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

import 'predictive_back_ownership_test.dart' as predictive;

void main() {
  testWidgets(
    'cancel at zero progress does not retain Back animation ownership',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          theme: predictive.theme,
          home: const Scaffold(),
        ),
      );
      unawaited(
        navigator.currentState!.push(
          MiuixPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Detail')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await predictive.back(tester, 'startBackGesture');
      await predictive.back(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(navigator.currentState!.userGestureInProgress, isFalse);
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final transition = tester.widget<FractionalTranslation>(
        find.ancestor(
          of: find.text('Detail'),
          matching: find.byKey(
            const ValueKey('miuix-navigation-transition-scene'),
          ),
        ),
      );
      expect(transition.translation.dx, greaterThan(0));
      await tester.pumpAndSettle();
    },
  );

  for (final interruption in [
    'cancel-then-remove',
    'replace',
    'background',
    'transition-rebuild',
    'normal-cancel',
    'normal-commit',
    'covered-cancel',
  ]) {
    testWidgets('Back input survives $interruption and another gesture', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      var taps = 0;
      var useMiuix = true;
      late StateSetter update;
      Widget action() => Scaffold(
        body: TextButton(onPressed: () => taps++, child: const Text('Action')),
      );
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MaterialApp(
              navigatorKey: navigator,
              theme: useMiuix
                  ? predictive.theme
                  : ThemeData(platform: TargetPlatform.android),
              home: action(),
            );
          },
        ),
      );
      final route = MiuixPageRoute<void>(builder: (_) => action());
      unawaited(navigator.currentState!.push(route));
      await tester.pumpAndSettle();
      await predictive.back(tester, 'startBackGesture');
      await predictive.back(tester, 'updateBackGestureProgress');
      await tester.pump();
      switch (interruption) {
        case 'cancel-then-remove':
          await predictive.back(tester, 'cancelBackGesture');
          navigator.currentState!.removeRoute(route);
        case 'replace':
          navigator.currentState!.replace(
            oldRoute: route,
            newRoute: MiuixPageRoute<void>(builder: (_) => action()),
          );
        case 'background':
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.hidden,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
        case 'transition-rebuild':
          update(() => useMiuix = false);
        case 'normal-cancel':
          await predictive.back(tester, 'cancelBackGesture');
        case 'normal-commit':
          await predictive.back(tester, 'commitBackGesture');
        case 'covered-cancel':
          unawaited(
            navigator.currentState!.push(
              MiuixPageRoute<void>(builder: (_) => action()),
            ),
          );
          await tester.pumpAndSettle();
          await predictive.back(tester, 'cancelBackGesture');
          await tester.pumpAndSettle();
          navigator.currentState!.pop();
          await tester.pumpAndSettle();
          expect(route.animation!.value, 1);
      }
      await tester.pumpAndSettle();
      expect(navigator.currentState!.userGestureInProgress, isFalse);
      await tester.tap(find.text('Action').hitTestable().last);
      expect(taps, 1);
      update(() => useMiuix = true);
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          MiuixPageRoute<void>(builder: (_) => action()),
        ),
      );
      await tester.pumpAndSettle();
      await predictive.back(tester, 'startBackGesture');
      await predictive.back(tester, 'updateBackGestureProgress');
      await predictive.back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(navigator.currentState!.userGestureInProgress, isFalse);
      await tester.tap(find.text('Action').hitTestable().last);
      expect(taps, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('removing a route during Back releases navigator input', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        theme: predictive.theme,
        home: Scaffold(
          body: TextButton(
            onPressed: () => taps++,
            child: const Text('Root action'),
          ),
        ),
      ),
    );
    final route = MiuixPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Detail')),
    );
    unawaited(navigator.currentState!.push(route));
    await tester.pumpAndSettle();
    await predictive.back(tester, 'startBackGesture');
    await predictive.back(tester, 'updateBackGestureProgress');
    await tester.pump();
    expect(navigator.currentState!.userGestureInProgress, isTrue);
    navigator.currentState!.removeRoute(route);
    await tester.pumpAndSettle();
    await predictive.back(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(navigator.currentState!.userGestureInProgress, isFalse);
    await tester.tap(find.text('Root action'));
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });

  for (final cancel in [false, true]) {
    for (final navigation in [false, true]) {
      testWidgets(
        '${navigation ? 'navigation' : 'glass'} tolerates ${cancel ? 'cancel' : 'up'} after removal',
        (tester) async {
          var show = true;
          var taps = 0;
          late StateSetter update;
          await tester.pumpWidget(
            MaterialApp(
              home: MiuixTheme(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    update = setState;
                    return Center(
                      child: show
                          ? navigation
                                ? MiuixFloatingNavigationBar(
                                    selectedIndex: 0,
                                    onSelected: (_) {},
                                    items: const [
                                      MiuixNavigationItem(
                                        icon: Icon(Icons.home),
                                        label: 'Home',
                                      ),
                                      MiuixNavigationItem(
                                        icon: Icon(Icons.person),
                                        label: 'Profile',
                                      ),
                                    ],
                                  )
                                : const MiuixGlass(
                                    interactiveLight: true,
                                    child: SizedBox(width: 200, height: 100),
                                  )
                          : TextButton(
                              onPressed: () => taps++,
                              child: const Text('Replacement'),
                            ),
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final target = navigation
              ? find.byKey(const ValueKey('floating-navigation-item-0'))
              : find.byType(MiuixGlass);
          final gesture = await tester.startGesture(tester.getCenter(target));
          await tester.pump();
          update(() => show = false);
          await tester.pump();
          await gesture.moveBy(const Offset(20, 0));
          if (cancel) {
            await gesture.cancel();
          } else {
            await gesture.up();
          }
          expect(tester.takeException(), isNull);
          await tester.tap(find.text('Replacement'));
          expect(taps, 1);
        },
      );
    }
  }
}
