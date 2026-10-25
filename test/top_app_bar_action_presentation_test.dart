import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets(
      'title actions follow collapse without moving targets $direction',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var backTaps = 0;
        var actionTaps = 0;
        final link = LayerLink();
        const backKey = ValueKey('title-back');
        const actionKey = ValueKey('title-action');
        Future<void> show(double collapse, {bool large = true}) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: MiuixTheme(
                  child: Scaffold(
                    appBar: MiuixTopAppBar(
                      title: 'Title',
                      large: large,
                      collapseFraction: collapse,
                      leading: MiuixIconButton(
                        key: backKey,
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => backTaps++,
                      ),
                      actions: [
                        CompositedTransformTarget(
                          key: const ValueKey('title-menu-anchor'),
                          link: link,
                          child: MiuixIconButton(
                            key: actionKey,
                            tooltip: 'Search',
                            selected: true,
                            icon: const Icon(Icons.search),
                            onPressed: () => actionTaps++,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await show(0);
        final backRect = tester.getRect(find.byKey(backKey));
        final actionRect = tester.getRect(find.byKey(actionKey));
        expect(find.byType(MiuixGlass), findsNothing);
        expect(
          find.byKey(const ValueKey('top-app-bar-gradient-filter')),
          findsOneWidget,
        );
        final selectedSurface = tester.widget<DecoratedBox>(
          find.descendant(
            of: find.byKey(actionKey),
            matching: find.byKey(const ValueKey('miuix-icon-button-surface')),
          ),
        );
        expect((selectedSurface.decoration as ShapeDecoration).color!.a, 0);

        for (final collapse in [1.0, 0.0]) {
          await show(collapse);
          expect(
            find.byType(MiuixGlass),
            collapse == 1 ? findsNWidgets(2) : findsNothing,
          );
          expect(tester.getRect(find.byKey(backKey)), backRect);
          expect(tester.getRect(find.byKey(actionKey)), actionRect);
          expect(
            tester.widget<MiuixIconButton>(find.byKey(backKey)).tooltip,
            'Back',
          );
          expect(
            tester.widget<MiuixIconButton>(find.byKey(actionKey)).tooltip,
            'Search',
          );
          await tester.tap(find.byKey(backKey));
          await tester.tap(find.byKey(actionKey));
          expect(
            tester
                .widget<CompositedTransformTarget>(
                  find.byKey(const ValueKey('title-menu-anchor')),
                )
                .link,
            same(link),
          );
        }
        expect(backTaps, 2);
        expect(actionTaps, 2);
        await show(0, large: false);
        expect(find.byType(MiuixGlass), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
