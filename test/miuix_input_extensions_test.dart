import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpInput(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MiuixTheme(
      child: MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 420, child: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('PIN input limits text and reports completion', (tester) async {
    String? completed;
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            inputStateMotion: Duration(milliseconds: 777),
            textFieldCornerRadius: 21,
          ),
        ),
        child: MiuixPinInput(
          length: 4,
          onCompleted: (value) => completed = value,
        ),
      ),
    );

    expect(find.byType(MiuixPinInput), findsOneWidget);
    expect(
      tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MiuixPinInput),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .every((cell) => cell.duration == const Duration(milliseconds: 777)),
      isTrue,
    );
    final firstCell = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(MiuixPinInput),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(
      (firstCell.decoration! as BoxDecoration).borderRadius,
      BorderRadius.circular(21),
    );
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(completed, '1234');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('PIN normalizes invalid length and ignores cursor-only updates', (
    tester,
  ) async {
    final controller = TextEditingController();
    final completions = <String>[];
    addTearDown(controller.dispose);
    await pumpInput(
      tester,
      MiuixPinInput(
        controller: controller,
        length: 0,
        obscureText: true,
        obscuringCharacter: '',
        onCompleted: completions.add,
      ),
    );

    expect(
      find.descendant(
        of: find.byType(MiuixPinInput),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(MiuixPinInputDefaults.length),
    );
    await tester.enterText(find.byType(TextField), '1234567');
    await tester.pump();
    expect(controller.text, '123456');
    expect(completions, <String>['123456']);

    controller.selection = const TextSelection.collapsed(offset: 3);
    await tester.pump();
    expect(completions, <String>['123456']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN reduced motion snaps every cell outline', (tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await pumpInput(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MiuixPinInput(
          controller: controller,
          focusNode: focusNode,
          length: 4,
        ),
      ),
    );

    final cells = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixPinInput),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(cells, hasLength(4));
    expect(cells.every((cell) => cell.duration == Duration.zero), isTrue);
    await tester.tap(find.byType(MiuixPinInput));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    final focusedCell = tester.widget<AnimatedContainer>(
      find
          .descendant(
            of: find.byType(MiuixPinInput),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    final decoration = focusedCell.decoration! as BoxDecoration;
    expect((decoration.border! as Border).top.width, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('OTP facade preserves the public PIN contract', (tester) async {
    await pumpInput(tester, const MiuixOtpInput(length: 5));
    expect(find.byType(MiuixOtpInput), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('PIN source keeps the former 14dp cell geometry', (tester) async {
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(textFieldCornerRadius: 26),
        ),
        child: const MiuixPinInput.source(length: 4),
      ),
    );

    final cells = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixPinInput),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(cells, hasLength(4));
    expect(
      cells.every(
        (cell) =>
            (cell.decoration! as BoxDecoration).borderRadius ==
            BorderRadius.circular(MiuixPinInputDefaults.cornerRadius),
      ),
      isTrue,
    );
  });

  testWidgets('PIN keeps internal text when only its focus node changes', (
    tester,
  ) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    var focusNode = firstFocus;
    late StateSetter rebuildHost;
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixPinInput(length: 4, focusNode: focusNode);
        },
      ),
    );

    await tester.enterText(find.byType(TextField), '12');
    rebuildHost(() => focusNode = secondFocus);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '12');
    expect(tester.takeException(), isNull);
  });

  testWidgets('PIN keeps internal focus when only its controller changes', (
    tester,
  ) async {
    final firstController = TextEditingController();
    final secondController = TextEditingController(text: '7');
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    var controller = firstController;
    late StateSetter rebuildHost;
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixPinInput(length: 4, controller: controller);
        },
      ),
    );

    await tester.tap(find.byType(MiuixPinInput));
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byType(TextField)).focusNode!.hasFocus,
      isTrue,
    );
    rebuildHost(() => controller = secondController);
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller, same(secondController));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete filters and accepts a typed option', (
    tester,
  ) async {
    final controller = MiuixAutoCompleteController<String>();
    await pumpInput(
      tester,
      MiuixAutoCompleteField<String>(
        controller: controller,
        label: 'City',
        displayStringForOption: (option) => option,
        optionsBuilder: (value) =>
            <String>['Beijing', 'Berlin', 'Shanghai'].where(
              (option) =>
                  option.toLowerCase().contains(value.text.toLowerCase()),
            ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'bei');
    await tester.pumpAndSettle();
    expect(find.text('Beijing'), findsOneWidget);
    await tester.tap(find.text('Beijing'));
    await tester.pumpAndSettle();
    expect(controller.selected, 'Beijing');
  });

  testWidgets('autocomplete preserves internal text when focus node changes', (
    tester,
  ) async {
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(firstFocus.dispose);
    addTearDown(secondFocus.dispose);
    var focus = firstFocus;
    late StateSetter rebuildHost;
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixAutoCompleteField<String>(
            focusNode: focus,
            displayStringForOption: (option) => option,
            optionsBuilder: (_) => const <String>['Berlin'],
          );
        },
      ),
    );

    await tester.enterText(find.byType(EditableText), 'ber');
    await tester.pump();
    rebuildHost(() => focus = secondFocus);
    await tester.pump();

    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'ber',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete preserves internal focus when controller changes', (
    tester,
  ) async {
    final first = MiuixAutoCompleteController<String>(text: 'first');
    final second = MiuixAutoCompleteController<String>(text: 'second');
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var controller = first;
    late StateSetter rebuildHost;
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixAutoCompleteField<String>(
            controller: controller,
            displayStringForOption: (option) => option,
            optionsBuilder: (_) => const <String>['first', 'second'],
          );
        },
      ),
    );

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    final originalFocus = tester
        .widget<MiuixTextField>(find.byType(MiuixTextField))
        .focusNode!;
    expect(originalFocus.hasFocus, isTrue);
    rebuildHost(() => controller = second);
    await tester.pump();

    final field = tester.widget<MiuixTextField>(find.byType(MiuixTextField));
    expect(field.focusNode, same(originalFocus));
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller, same(second.textController));
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete popup uses glass and collection row tokens', (
    tester,
  ) async {
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            popupBlur: 31,
            popupTintOpacity: .44,
            popupCornerRadius: 27,
            textFieldCornerRadius: 25,
            collectionRowMotion: Duration(milliseconds: 777),
            collectionRowCornerRadius: 23,
          ),
        ),
        child: MiuixAutoCompleteField<String>(
          displayStringForOption: (option) => option,
          optionsBuilder: (value) => const <String>['Alpha', 'Beta'],
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'a');
    await tester.pumpAndSettle();
    final popupFinder = find.byKey(const ValueKey('miuix-autocomplete-popup'));
    final popup = tester.widget<MiuixSurface>(popupFinder);
    expect(popup.glass, isTrue);
    expect(popup.glassBlur, 31);
    expect(popup.glassOpacity, .44);
    expect(popup.glassOptics, same(MiuixGlassOptics.transient));
    expect(popup.radius, 27);
    expect(popup.showGlassSpecular, isTrue);
    expect(tester.getSize(popupFinder).width, 420);
    expect(
      tester.widget<MiuixTextField>(find.byType(MiuixTextField)).cornerRadius,
      25,
    );

    final alphaMotion = find.ancestor(
      of: find.text('Alpha'),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(alphaMotion).duration,
      const Duration(milliseconds: 777),
    );
    final alphaSurface = tester.widget<MiuixSurface>(
      find.byKey(
        const ValueKey<Object>(('miuix-autocomplete-option', 'Alpha')),
      ),
    );
    expect(alphaSurface.radius, 23);
  });

  testWidgets('autocomplete separates custom, solid, and source materials', (
    tester,
  ) async {
    Widget field({required String mode}) {
      if (mode == 'source') {
        return MiuixAutoCompleteField<String>.source(
          displayStringForOption: (option) => option,
          optionsBuilder: (_) => const <String>['Source'],
        );
      }
      return MiuixAutoCompleteField<String>(
        displayStringForOption: (option) => option,
        optionsBuilder: (_) => <String>[mode],
        popupGlass: mode != 'solid',
        popupGlassBlur: 37,
        popupGlassOpacity: .39,
        showPopupGlassSpecular: false,
        popupCornerRadius: mode == 'solid' ? 29 : 26,
        fieldCornerRadius: mode == 'solid' ? 28 : 24,
      );
    }

    for (final mode in <String>['custom', 'solid', 'source']) {
      await pumpInput(tester, field(mode: mode));
      await tester.enterText(find.byType(EditableText), mode.substring(0, 1));
      await tester.pumpAndSettle();

      final popup = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey('miuix-autocomplete-popup')),
      );
      final textField = tester.widget<MiuixTextField>(
        find.byType(MiuixTextField),
      );
      if (mode == 'source') {
        expect(popup.glass, isFalse);
        expect(popup.showGlassSpecular, isFalse);
        expect(popup.radius, MiuixAutoCompleteDefaults.cornerRadius);
        expect(
          textField.cornerRadius,
          MiuixTextFieldDefaults.legacyCornerRadius,
        );
        expect(
          tester
              .getSize(find.byKey(const ValueKey('miuix-autocomplete-popup')))
              .width,
          420,
        );
      } else {
        expect(popup.glass, mode == 'custom');
        expect(popup.glassBlur, 37);
        expect(popup.glassOpacity, .39);
        expect(popup.showGlassSpecular, isFalse);
        expect(popup.radius, mode == 'solid' ? 29 : 26);
        expect(textField.cornerRadius, mode == 'solid' ? 28 : 24);
      }
    }
  });

  testWidgets('autocomplete popup stays inside a narrow field anchor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MiuixTheme(
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 160,
                child: MiuixAutoCompleteField<String>(
                  displayStringForOption: (option) => option,
                  optionsBuilder: (_) => const <String>['Narrow option'],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'n');
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-autocomplete-popup')))
          .width,
      160,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete caps wide fields and supports compact planes', (
    tester,
  ) async {
    Future<double> popupWidth({required bool matchFieldWidth}) async {
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 600,
                  child: MiuixAutoCompleteField<String>(
                    displayStringForOption: (option) => option,
                    optionsBuilder: (_) => const <String>['Wide option'],
                    minimumOptionsWidth: 236,
                    maximumOptionsWidth: 420,
                    matchFieldWidth: matchFieldWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'w');
      await tester.pumpAndSettle();
      return tester
          .getSize(find.byKey(const ValueKey('miuix-autocomplete-popup')))
          .width;
    }

    expect(await popupWidth(matchFieldWidth: true), 420);
    expect(await popupWidth(matchFieldWidth: false), 236);
  });

  testWidgets('autocomplete normalizes invalid public popup geometry', (
    tester,
  ) async {
    await pumpInput(
      tester,
      Center(
        child: SizedBox(
          width: 300,
          child: MiuixAutoCompleteField<String>(
            maximumOptionsHeight: double.nan,
            minimumOptionsWidth: double.negativeInfinity,
            maximumOptionsWidth: -40,
            optionsBuilder: (_) => const <String>['Alpha', 'Beta'],
            displayStringForOption: (option) => option,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixTextField));
    await tester.enterText(find.byType(MiuixTextField), 'a');
    await tester.pumpAndSettle();

    final popup = find.byKey(const ValueKey('miuix-autocomplete-popup'));
    expect(popup, findsOneWidget);
    final size = tester.getSize(popup);
    expect(size.width, 300);
    expect(size.height, lessThanOrEqualTo(280));
    expect(size.width.isFinite && size.height.isFinite, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('autocomplete keeps down and automatic-up edges anchored', (
    tester,
  ) async {
    Future<(Rect, Rect)> geometry({
      required Alignment alignment,
      required OptionsViewOpenDirection direction,
    }) async {
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: alignment,
                child: SizedBox(
                  width: 300,
                  child: MiuixAutoCompleteField<String>(
                    openDirection: direction,
                    displayStringForOption: (option) => option,
                    optionsBuilder: (_) => const <String>['One', 'Two'],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'o');
      await tester.pumpAndSettle();
      return (
        tester.getRect(find.byKey(const ValueKey('miuix-autocomplete-field'))),
        tester.getRect(find.byKey(const ValueKey('miuix-autocomplete-popup'))),
      );
    }

    final down = await geometry(
      alignment: Alignment.topLeft,
      direction: OptionsViewOpenDirection.down,
    );
    expect(down.$2.top, closeTo(down.$1.bottom, .001));
    expect(down.$2.left, closeTo(down.$1.left, .001));

    final up = await geometry(
      alignment: Alignment.bottomLeft,
      direction: OptionsViewOpenDirection.mostSpace,
    );
    expect(up.$2.bottom, closeTo(up.$1.top, .001));
    expect(up.$2.left, closeTo(up.$1.left, .001));
  });

  test('multi-select controller publishes immutable typed values', () {
    final controller = MiuixMultiSelectController<int>(selected: <int>[1]);
    controller.toggle(2);
    expect(controller.selected, <int>{1, 2});
    controller.toggle(1);
    expect(controller.selected, <int>{2});
  });

  testWidgets('multi-select reconciles live options and keyboard-opens', (
    tester,
  ) async {
    final controller = MiuixMultiSelectController<String>(
      selected: <String>['stale', 'b', 'c'],
    );
    final published = <Set<String>>[];
    late StateSetter rebuild;
    var maximum = 2;
    var options = const <MiuixMultiSelectOption<String>>[
      MiuixMultiSelectOption<String>(value: 'a', label: 'Alpha'),
      MiuixMultiSelectOption<String>(value: 'b', label: 'Beta'),
      MiuixMultiSelectOption<String>(value: 'c', label: 'Gamma'),
    ];
    addTearDown(controller.dispose);
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MiuixMultiSelect<String>(
            controller: controller,
            options: options,
            maximumSelection: maximum,
            placeholder: 'None',
            onChanged: published.add,
            glass: false,
          );
        },
      ),
    );

    expect(controller.selected, <String>{'b', 'c'});
    expect(published, isEmpty);
    rebuild(() {
      options = const <MiuixMultiSelectOption<String>>[
        MiuixMultiSelectOption<String>(value: 'a', label: 'Alpha'),
        MiuixMultiSelectOption<String>(value: 'c', label: 'Gamma'),
      ];
      maximum = 1;
    });
    await tester.pump();
    expect(controller.selected, <String>{'c'});
    expect(published, isEmpty);

    controller.selected = <String>{'missing', 'a', 'c'};
    await tester.pump();
    expect(controller.selected, <String>{'a'});
    expect(published, isEmpty);

    final trigger = find.byKey(
      const ValueKey<String>('miuix-multi-select-trigger'),
    );
    final triggerFocus = Focus.of(tester.element(trigger));
    triggerFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(MiuixDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(triggerFocus.hasFocus, isTrue);
    expect(controller.selected, <String>{'a'});
    expect(published, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty multi-select disables pointer and keyboard activation', (
    tester,
  ) async {
    final controller = MiuixMultiSelectController<String>(
      selected: <String>['stale'],
    );
    addTearDown(controller.dispose);
    await pumpInput(
      tester,
      MiuixMultiSelect<String>(
        controller: controller,
        options: const <MiuixMultiSelectOption<String>>[],
        placeholder: 'None',
      ),
    );

    expect(controller.selected, isEmpty);
    final trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<String>('miuix-multi-select-trigger')),
    );
    expect(trigger.onTap, isNull);
    expect(trigger.enabled, isFalse);
    final focus = tester
        .widgetList<Focus>(
          find.ancestor(
            of: find.byKey(
              const ValueKey<String>('miuix-multi-select-trigger'),
            ),
            matching: find.byType(Focus),
          ),
        )
        .firstWhere((candidate) => candidate.canRequestFocus == false);
    expect(focus.canRequestFocus, isFalse);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-select dialog keyboard skips disabled and limited rows', (
    tester,
  ) async {
    final controller = MiuixMultiSelectController<String>();
    addTearDown(controller.dispose);
    await pumpInput(
      tester,
      MiuixMultiSelect<String>(
        controller: controller,
        placeholder: 'None',
        maximumSelection: 1,
        options: const <MiuixMultiSelectOption<String>>[
          MiuixMultiSelectOption(
            value: 'disabled',
            label: 'Disabled',
            enabled: false,
          ),
          MiuixMultiSelectOption(value: 'a', label: 'Alpha'),
          MiuixMultiSelectOption(value: 'b', label: 'Beta'),
        ],
      ),
    );

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();

    Semantics rowSemantics(String value) => tester.widget<Semantics>(
      find.byKey(ValueKey<Object>(('miuix-multi-select-row-semantics', value))),
    );

    expect(rowSemantics('disabled').properties.focused, isFalse);
    expect(rowSemantics('a').properties.focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rowSemantics('b').properties.focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(rowSemantics('b').properties.selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(rowSemantics('b').properties.focused, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(rowSemantics('a').properties.focused, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(controller.selected, <String>{'a'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi-select field shows selected values as equal chips', (
    tester,
  ) async {
    final controller = MiuixMultiSelectController<String>(
      selected: <String>['a', 'b'],
    );
    await pumpInput(
      tester,
      MiuixMultiSelect<String>(
        controller: controller,
        options: const <MiuixMultiSelectOption<String>>[
          MiuixMultiSelectOption(value: 'a', label: 'Alpha'),
          MiuixMultiSelectOption(value: 'b', label: 'Beta'),
        ],
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(find.byType(MiuixChip), findsNWidgets(2));
    for (final chip in find.byType(MiuixChip).evaluate()) {
      final size = tester.getSize(find.byWidget(chip.widget));
      expect(size.height, 32);
      expect(size.width, lessThan(150));
    }
  });

  testWidgets('multi-select dialog animates the complete selected row', (
    tester,
  ) async {
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            textFieldCornerRadius: 24,
            collectionRowMotion: Duration(milliseconds: 777),
            collectionRowCornerRadius: 23,
          ),
        ),
        child: const MiuixMultiSelect<String>(
          label: 'Choices',
          placeholder: 'None',
          options: <MiuixMultiSelectOption<String>>[
            MiuixMultiSelectOption(value: 'a', label: 'Alpha'),
            MiuixMultiSelectOption(value: 'b', label: 'Beta'),
          ],
        ),
      ),
    );

    final triggerSurface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixMultiSelect<String>),
        matching: find.byType(MiuixSurface),
      ),
    );
    expect(triggerSurface.radius, 24);
    expect(triggerSurface.glass, isTrue);
    expect(triggerSurface.glassBlur, 24);
    expect(triggerSurface.glassOpacity, .68);
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    final alphaMotion = find.ancestor(
      of: find.text('Alpha'),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(alphaMotion).duration,
      const Duration(milliseconds: 777),
    );
    MiuixSurface alphaSurface() => tester.widget<MiuixSurface>(
      find.ancestor(
        of: find.text('Alpha'),
        matching: find.byType(MiuixSurface),
      ),
    );
    expect(alphaSurface().radius, 23);
    expect(alphaSurface().color, Colors.transparent);
    await tester.tap(find.text('Alpha'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(alphaSurface().color, isNot(Colors.transparent));
  });

  testWidgets('multi-select separates token glass, solid, and source fields', (
    tester,
  ) async {
    const options = <MiuixMultiSelectOption<String>>[
      MiuixMultiSelectOption(value: 'a', label: 'Alpha'),
    ];
    Widget field(int presentation) => switch (presentation) {
      0 => const MiuixMultiSelect<String>(options: options),
      1 => const MiuixMultiSelect<String>(
        options: options,
        glass: false,
        cornerRadius: 29,
      ),
      _ => const MiuixMultiSelect<String>.source(options: options),
    };

    Future<void> pumpField(int presentation) => pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            contentSurfaceBlur: 34,
            contentSurfaceTintOpacity: .43,
            textFieldCornerRadius: 26,
          ),
        ),
        child: field(presentation),
      ),
    );

    await pumpField(0);
    var trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-multi-select-trigger')),
    );
    expect(trigger.glass, isTrue);
    expect(trigger.glassBlur, 34);
    expect(trigger.glassOpacity, .43);
    expect(trigger.radius, 26);
    expect(trigger.showGlassSpecular, isTrue);

    await pumpField(1);
    trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-multi-select-trigger')),
    );
    expect(trigger.glass, isFalse);
    expect(trigger.radius, 29);

    await pumpField(2);
    trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-multi-select-trigger')),
    );
    expect(trigger.glass, isFalse);
    expect(trigger.radius, 16);
    expect(trigger.showGlassSpecular, isFalse);
  });

  testWidgets('multi-select rejects a result owned by a replaced controller', (
    tester,
  ) async {
    final first = MiuixMultiSelectController<String>();
    final second = MiuixMultiSelectController<String>();
    final published = <Set<String>>[];
    var active = first;
    late StateSetter rebuild;
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpInput(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MiuixMultiSelect<String>(
            controller: active,
            placeholder: 'None',
            onChanged: published.add,
            options: const <MiuixMultiSelectOption<String>>[
              MiuixMultiSelectOption(value: 'a', label: 'Alpha'),
              MiuixMultiSelectOption(value: 'b', label: 'Beta'),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    rebuild(() => active = second);
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(first.selected, isEmpty);
    expect(second.selected, isEmpty);
    expect(published, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('form field exposes validation inside a grouped section', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            inputStateMotion: Duration(milliseconds: 777),
            settingsGroupCornerRadius: 27,
            contentSurfaceBlur: 34,
            contentSurfaceTintOpacity: .43,
            formSectionHorizontalPadding: 21,
            formSectionVerticalPadding: 15,
            formFieldContentSpacing: 11,
            formErrorSpacing: 7,
          ),
        ),
        child: Form(
          key: formKey,
          child: MiuixFormSection(
            title: 'Account',
            children: <Widget>[
              MiuixFormField<String>(
                label: 'Name',
                required: true,
                validator: (value) => value == null ? 'Required' : null,
                fieldBuilder: (field) => MiuixButton(
                  label: 'Set value',
                  onPressed: () => field.didChange('Ada'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSize>(find.byType(AnimatedSize)).duration,
      const Duration(milliseconds: 777),
    );
    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-form-section-surface')),
    );
    expect(surface.radius, 27);
    expect(surface.glass, isTrue);
    expect(surface.glassBlur, 34);
    expect(surface.glassOpacity, .43);
    expect(
      surface.padding,
      const EdgeInsets.symmetric(horizontal: 21, vertical: 15),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('miuix-form-field-content-spacing')),
          )
          .height,
      11,
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Required'), findsOneWidget);
    expect(
      tester
          .widget<Padding>(find.byKey(const ValueKey('miuix-form-field-error')))
          .padding,
      const EdgeInsets.only(top: 7),
    );
    await tester.tap(find.text('Set value'));
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('form source constructors preserve fixed opaque geometry', (
    tester,
  ) async {
    await pumpInput(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            settingsGroupCornerRadius: 30,
            formSectionHorizontalPadding: 24,
            formSectionVerticalPadding: 20,
            formFieldContentSpacing: 13,
            formErrorSpacing: 9,
          ),
        ),
        child: MiuixFormSection.source(
          children: <Widget>[
            MiuixFormField<String>.source(
              label: 'Source field',
              initialValue: 'ok',
              validator: (_) => 'Source error',
              fieldBuilder: (_) => const SizedBox(height: 20),
            ),
          ],
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-form-section-surface')),
    );
    expect(surface.radius, MiuixFormDefaults.sectionRadius);
    expect(surface.glass, isFalse);
    expect(surface.padding, MiuixFormDefaults.sectionPadding);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('miuix-form-field-content-spacing')),
          )
          .height,
      MiuixFormDefaults.contentSpacing,
    );
  });

  testWidgets('form reduced motion swaps validation structure directly', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await pumpInput(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Form(
          key: formKey,
          child: MiuixFormField<String>(
            label: 'Reduced field',
            validator: (value) => value == null ? 'Reduced error' : null,
            fieldBuilder: (field) => MiuixButton(
              label: 'Accept value',
              onPressed: () => field.didChange('accepted'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedSize), findsNothing);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Reduced error'), findsOneWidget);
    expect(find.byType(AnimatedSize), findsNothing);
    await tester.tap(find.text('Accept value'));
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Reduced error'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
