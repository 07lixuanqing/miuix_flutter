import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  for (final card in [false, true]) {
    testWidgets(
      'icon metadata follows accepted taps and cancellation card=$card',
      (tester) async {
        MiuixIconInteraction? signal;
        var calls = 0;
        final child = Builder(
          builder: (context) {
            signal = MiuixIconInteraction.maybeOf(context);
            return const SizedBox(width: 24, height: 24);
          },
        );
        await tester.pumpWidget(
          MaterialApp(
            home: MiuixTheme(
              data: MiuixThemeData.defaults(),
              child: Scaffold(
                body: Center(
                  child: card
                      ? MiuixCard(onTap: () => calls++, child: child)
                      : MiuixIconButton(onPressed: () => calls++, icon: child),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final target = find.byWidget(child);
        final bounds = tester.getRect(target);
        final down = await tester.startGesture(bounds.center);
        await tester.pump(const Duration(milliseconds: 120));
        expect(signal!.pressed, isTrue);
        await down.cancel();
        await tester.pumpAndSettle();
        expect(signal!.pressed, isFalse);
        expect(signal!.activation, 0);
        await tester.tap(target, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(signal!.activation, 1);
        expect(tester.getRect(target), bounds);
      },
    );
  }
}
