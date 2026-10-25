import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'native navigation inset never reduces host rounded-corner safety',
    (tester) async {
      final insets = StreamController<MiuixWindowInsets>.broadcast(sync: true);
      MiuixWindowInsetsObserver.debugEvents = insets.stream;
      addTearDown(() async {
        MiuixWindowInsetsObserver.debugEvents = null;
        await insets.close();
      });
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(400, 800),
              padding: EdgeInsets.only(bottom: 40),
            ),
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MiuixFloatingNavigationBar(
                  selectedIndex: 0,
                  bottomMargin: 4,
                  items: [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      insets.add(
        const MiuixWindowInsets(navigationBarBottom: 8, captionBarBottom: 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.byKey(const ValueKey('floating-navigation-surface')))
            .bottom,
        756,
      );
      insets.add(
        const MiuixWindowInsets(navigationBarBottom: 48, captionBarBottom: 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(find.byKey(const ValueKey('floating-navigation-surface')))
            .bottom,
        748,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
