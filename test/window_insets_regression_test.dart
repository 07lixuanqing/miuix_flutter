import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in ['date', 'dateTime', 'time', 'actions']) {
    testWidgets(
      'window insets $kind survives rotation and keeps confirmation reachable',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(400, 760);
        tester.view.padding = const FakeViewPadding(top: 44, bottom: 48);
        tester.view.viewPadding = const FakeViewPadding(top: 44, bottom: 48);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () {
                      switch (kind) {
                        case 'date':
                          MiuixDatePicker.show(
                            context: context,
                            initialDate: DateTime(2026, 9, 26),
                          );
                        case 'dateTime':
                          MiuixDateTimePicker.show(
                            context: context,
                            initialDateTime: DateTime(2026, 9, 26),
                          );
                        case 'time':
                          MiuixTimePicker.show(context: context);
                        case 'actions':
                          MiuixActionSheet.show(
                            context: context,
                            title: 'Actions',
                            cancelLabel: 'Cancel sheet',
                            actions: [
                              for (var i = 0; i < 15; i++)
                                MiuixActionSheetItem(
                                  label: 'Action $i',
                                  onTap: () {},
                                ),
                            ],
                          );
                      }
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        for (final left in [64.0, 0.0]) {
          tester.view.physicalSize = const Size(760, 360);
          tester.view.padding = FakeViewPadding(
            top: 24,
            left: left,
            right: 64 - left,
            bottom: 24,
          );
          tester.view.viewPadding = tester.view.padding;
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          final confirm = find.text(kind == 'actions' ? 'Cancel sheet' : 'OK');
          await tester.ensureVisible(confirm);
          await tester.pumpAndSettle();
          final rect = tester.getRect(confirm);
          expect(rect.left, greaterThanOrEqualTo(left));
          expect(rect.right, lessThanOrEqualTo(760 - (64 - left)));
          expect(rect.top, greaterThanOrEqualTo(24));
          expect(rect.bottom, lessThanOrEqualTo(360 - 24));
          expect(tester.takeException(), isNull);
        }
        await tester.tap(find.text(kind == 'actions' ? 'Cancel sheet' : 'OK'));
        await tester.pumpAndSettle();
        expect(find.text('Open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
