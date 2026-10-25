import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets(
    'normal and source text fields forward optional autofill semantics',
    (tester) async {
      final input = TextEditingController();
      addTearDown(input.dispose);
      for (final source in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MiuixTheme(
                child: AutofillGroup(
                  child: source
                      ? MiuixTextField.source(
                          controller: input,
                          autofillHints: const [AutofillHints.username],
                        )
                      : MiuixTextField(
                          controller: input,
                          autofillHints: const [AutofillHints.newPassword],
                          obscureText: true,
                        ),
                ),
              ),
            ),
          ),
        );
        final editable = tester.widget<EditableText>(find.byType(EditableText));
        expect(
          editable.autofillHints,
          source ? [AutofillHints.username] : [AutofillHints.newPassword],
        );
        expect(editable.obscureText, !source);
      }
    },
  );
}
