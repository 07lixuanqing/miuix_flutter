import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets('captured surface artwork preserves size and interaction', (
    tester,
  ) async {
    var taps = 0;
    ShapeBorder? receivedShape;
    Color? receivedColor;
    const shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(mode: MiuixColorMode.light),
          child: MiuixSurfaceTheme(
            decorate: (context, border, color, child) {
              receivedShape = border;
              receivedColor = color;
              return DecoratedBox(
                key: const ValueKey('artwork'),
                decoration: const BoxDecoration(),
                child: child,
              );
            },
            child: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => Center(
                    child: MiuixSurface(
                      shape: shape,
                      color: Colors.red,
                      onTap: () => taps++,
                      child: const SizedBox(
                        width: 120,
                        height: 60,
                        child: Center(child: Text('Surface action')),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(receivedShape, shape);
    expect(receivedColor, Colors.red);
    expect(
      tester.getSize(find.byKey(const ValueKey('artwork'))),
      const Size(120, 60),
    );
    await tester.tap(find.text('Surface action'));
    await tester.pumpAndSettle();
    expect(taps, 1);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'buttons use theme radius while explicit and source geometry win',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(buttonCornerRadius: 12),
            ),
            child: Column(
              children: [
                MiuixButton(label: 'themed', onPressed: () {}),
                MiuixButton(
                  label: 'explicit',
                  cornerRadius: 24,
                  onPressed: () {},
                ),
                MiuixButton.source(label: 'source', onPressed: () {}),
                MiuixTextButton(label: 'text', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      final boxes = tester
          .widgetList<DecoratedBox>(
            find.byKey(const ValueKey('miuix-button-surface')),
          )
          .toList();
      final radii = boxes.map(
        (box) =>
            ((box.decoration as ShapeDecoration).shape as MiuixSquircleBorder)
                .borderRadius,
      );
      expect(radii, [
        BorderRadius.circular(12),
        BorderRadius.circular(24),
        BorderRadius.circular(MiuixButtonDefaults.legacyCornerRadius),
        BorderRadius.circular(12),
      ]);
    },
  );
  testWidgets(
    'field theme changes preserve editing state and explicit radius',
    (tester) async {
      final controller = TextEditingController(text: 'draft');
      addTearDown(controller.dispose);
      final focus = FocusNode();
      addTearDown(focus.dispose);
      Widget scene(double radius) => MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: MiuixHyperOs4Tokens(textFieldCornerRadius: radius),
          ),
          child: Scaffold(
            body: MiuixTextField(controller: controller, focusNode: focus),
          ),
        ),
      );
      await tester.pumpWidget(scene(28));
      focus.requestFocus();
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'kept draft');
      final editing = tester.state(find.byType(EditableText));
      await tester.pumpWidget(scene(12));
      await tester.pumpAndSettle();
      expect(controller.text, 'kept draft');
      expect(focus.hasFocus, true);
      expect(tester.state(find.byType(EditableText)), same(editing));
      expect(tester.takeException(), isNull);
    },
  );
}
