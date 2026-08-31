part of '../miuix_flutter_test.dart';

void _ignoreNullableInt(int? _) {}

void _registerSelectionProgressTests() {
  testWidgets('text fields normalize multiline constraints safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixTextField(
                  hint: 'Invalid lines',
                  minLines: -2,
                  maxLines: 0,
                ),
                MiuixTextField(hint: 'Multiline', minLines: 2, maxLines: 4),
                MiuixTextField(
                  hint: 'Secret',
                  obscureText: true,
                  minLines: 3,
                  maxLines: 5,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final editors = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .toList();
    expect(editors[0].minLines, 1);
    expect(editors[0].maxLines, 1);
    expect(editors[1].minLines, 2);
    expect(editors[1].maxLines, 4);
    expect(editors[2].minLines, 1);
    expect(editors[2].maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field label follows MIUIX floating rule', (tester) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixTextField(controller: controller, label: 'Account'),
          ),
        ),
      ),
    );

    expect(
      debugMiuixTextFieldLabelFloats(label: 'Account', hasText: false),
      isFalse,
    );
    expect(
      debugMiuixTextFieldLabelFloats(label: 'Account', hasText: true),
      isTrue,
    );

    await tester.tap(find.byType(MiuixTextField));
    await tester.pumpAndSettle();
    expect(
      debugMiuixTextFieldLabelFloats(
        label: 'Account',
        hasText: controller.text.isNotEmpty,
      ),
      isFalse,
    );

    await tester.enterText(find.byType(EditableText), 'miuix');
    await tester.pumpAndSettle();
    expect(
      debugMiuixTextFieldLabelFloats(
        label: 'Account',
        hasText: controller.text.isNotEmpty,
      ),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field label and editor preserve source paired motion', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixTextField(controller: controller, label: 'Account'),
          ),
        ),
      ),
    );

    List<Transform> fieldTransforms() => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(MiuixTextField),
            matching: find.byType(Transform),
          ),
        )
        .toList();
    DefaultTextStyle labelStyle() => tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Account'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );

    // TextField.kt keeps an empty label at the normal 17sp position even
    // after focus is obtained. Focus changes only the independent border
    // animation channel.
    expect(labelStyle().style.fontSize, 17);
    expect(fieldTransforms()[0].transform.getTranslation().y, 0);
    expect(fieldTransforms()[1].transform.getTranslation().y, 0);
    await tester.tap(find.byType(MiuixTextField));
    await tester.pumpAndSettle();
    expect(labelStyle().style.fontSize, 17);
    expect(fieldTransforms()[0].transform.getTranslation().y, 0);
    expect(fieldTransforms()[1].transform.getTranslation().y, 0);

    // Entered text changes LabelAnimState to Floating. The source caption
    // becomes 10sp and moves up by half the 16dp vertical inset, while the
    // editable text moves down by the same distance.
    await tester.enterText(find.byType(EditableText), 'miuix');
    await tester.pumpAndSettle();
    expect(labelStyle().style.fontSize, 10);
    expect(fieldTransforms()[0].transform.getTranslation().y, -8);
    expect(fieldTransforms()[1].transform.getTranslation().y, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field reduced motion settles focus and label springs', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var reduceMotion = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: MiuixTheme(
              child: Scaffold(
                body: MiuixTextField(
                  controller: controller,
                  label: 'Reduced account',
                ),
              ),
            ),
          );
        },
      ),
    );

    ShapeDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(
                          const ValueKey('miuix-text-field-surface'),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    double borderWidth() =>
        (decoration().shape as MiuixSquircleBorder).side.width;
    DefaultTextStyle labelStyle() => tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('Reduced account'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    List<Transform> fieldTransforms() => tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(MiuixTextField),
            matching: find.byType(Transform),
          ),
        )
        .toList();

    await tester.tap(find.byType(MiuixTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(borderWidth(), inExclusiveRange(0, 2));
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(borderWidth(), 2);

    // Restore ordinary motion, begin the floating-label spring, then switch
    // the preference on while that independent channel is still in flight.
    updateHost(() => reduceMotion = false);
    await tester.pump();
    await tester.enterText(find.byType(EditableText), 'miuix');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(labelStyle().style.fontSize, inExclusiveRange(10, 17));
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(labelStyle().style.fontSize, 10);
    expect(fieldTransforms()[0].transform.getTranslation().y, -8);
    expect(fieldTransforms()[1].transform.getTranslation().y, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field preserves source border and placeholder metrics', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixTextField(
              controller: controller,
              label: 'Placeholder',
              useLabelAsPlaceholder: true,
            ),
          ),
        ),
      ),
    );

    // The ordinary constructor uses the project-calibrated HyperOS 4 radius,
    // while retaining the source inset and focus-outline behavior.
    ShapeDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(
                          const ValueKey('miuix-text-field-surface'),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    MiuixSquircleBorder shape() => decoration().shape as MiuixSquircleBorder;
    expect(shape().borderRadius, BorderRadius.circular(20));
    expect(shape().side.width, 0);
    final contentPadding = tester
        .widgetList<Padding>(
          find.descendant(
            of: find.byType(MiuixTextField),
            matching: find.byType(Padding),
          ),
        )
        .map((widget) => widget.padding)
        .whereType<EdgeInsets>()
        .firstWhere((padding) => padding == const EdgeInsets.all(16));
    expect(contentPadding, const EdgeInsets.all(16));

    await tester.tap(find.byType(MiuixTextField));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(shape().side.width, inExclusiveRange(0, 2));
    await tester.pumpAndSettle();
    expect(shape().side.width, 2);
    expect(find.text('Placeholder'), findsOneWidget);

    // useLabelAsPlaceholder maps the entered state to Placeholder in the
    // source state machine, so the label vanishes instead of floating.
    await tester.enterText(find.byType(EditableText), 'miuix');
    await tester.pumpAndSettle();
    expect(find.text('Placeholder'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('text field uses Compose default animate-as-state spring', () {
    final spring = debugMiuixTextFieldSpring();
    expect(spring.mass, 1);
    expect(spring.stiffness, 1500);
    expect(spring.damping, closeTo(2 * math.sqrt(1500), .0001));
  });

  testWidgets('text field source palette is immutable and wired by channel', (
    tester,
  ) async {
    const palette = MiuixTextFieldColors(
      backgroundColor: Color(0xFF102030),
      labelColor: Color(0xFF405060),
      borderColor: Color(0xFF708090),
    );
    const backgroundOverride = Color(0xFFA0B0C0);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    MiuixTextFieldColors? defaults;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(enableSquircle: false),
          child: Builder(
            builder: (context) {
              defaults = MiuixTextFieldDefaults.colors(context);
              return Scaffold(
                body: MiuixTextField(
                  label: 'Palette',
                  colors: palette,
                  backgroundColor: backgroundOverride,
                  focusNode: focusNode,
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(defaults, isNotNull);
    expect(defaults!.backgroundColor, isNot(defaults!.borderColor));
    expect(
      palette.copyWith(labelColor: Colors.white),
      const MiuixTextFieldColors(
        backgroundColor: Color(0xFF102030),
        labelColor: Colors.white,
        borderColor: Color(0xFF708090),
      ),
    );
    ShapeDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(
                          const ValueKey('miuix-text-field-surface'),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    expect(decoration().color, backgroundOverride);

    focusNode.requestFocus();
    await tester.pumpAndSettle();
    final focusedShape = decoration().shape as RoundedRectangleBorder;
    expect(focusedShape.side.color, palette.borderColor);
    expect(focusedShape.side.width, 2);
    final labelContext = tester.element(find.text('Palette'));
    expect(DefaultTextStyle.of(labelContext).style.color, palette.labelColor);
  });

  testWidgets('text field forwards source configuration and shape switch', (
    tester,
  ) async {
    final theme = MiuixThemeData.defaults().copyWith(enableSquircle: false);
    const background = Color(0xFF102030);
    const border = Color(0xFF405060);
    const label = Color(0xFF708090);
    const cursor = Color(0xFFA0B0C0);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: theme,
          child: const Scaffold(
            body: MiuixTextField(
              label: 'Configured',
              backgroundColor: background,
              borderColor: border,
              labelColor: label,
              cursorColor: cursor,
              cornerRadius: 18,
              insideMargin: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              textStyle: TextStyle(color: Color(0xFFD0E0F0), fontSize: 17),
            ),
          ),
        ),
      ),
    );

    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byKey(
                          const ValueKey('miuix-text-field-surface'),
                        ),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as ShapeDecoration;
    final shape = decoration.shape as RoundedRectangleBorder;
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(decoration.color, background);
    expect(shape.borderRadius, BorderRadius.circular(18));
    expect(shape.side.color, background);
    expect(editor.readOnly, isTrue);
    expect(editor.keyboardType, TextInputType.emailAddress);
    expect(editor.textInputAction, TextInputAction.done);
    expect(editor.cursorColor, cursor);
    expect(editor.style.color, const Color(0xFFD0E0F0));
    expect(
      tester
          .widget<Padding>(
            find
                .descendant(
                  of: find.byType(MiuixTextField),
                  matching: find.byType(Padding),
                )
                .first,
          )
          .padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field source API forwards state and exact content slots', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final scrollController = ScrollController();
    MiuixTextFieldLayoutResult? layoutResult;
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: MiuixTextField.source(
                  key: const ValueKey('source-text-field'),
                  controller: controller,
                  label: 'Source',
                  leadingIcon: const SizedBox(
                    key: ValueKey('source-leading'),
                    width: 24,
                    height: 24,
                  ),
                  trailingIcon: const SizedBox(
                    key: ValueKey('source-trailing'),
                    width: 28,
                    height: 24,
                  ),
                  interactionSource: focusNode,
                  scrollState: scrollController,
                  inputTransformation: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onTextLayout: (result) => layoutResult = result,
                  onValueChange: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(MiuixTextFieldDefaults.cornerRadius, 20);
    expect(MiuixTextFieldDefaults.legacyCornerRadius, 16);
    expect(MiuixTextFieldDefaults.insideMargin, const EdgeInsets.all(16));
    final field = tester.widget<MiuixTextField>(
      find.byKey(const ValueKey('source-text-field')),
    );
    expect(field.controller, same(controller));
    expect(field.cornerRadius, MiuixTextFieldDefaults.legacyCornerRadius);
    expect(field.focusNode, same(focusNode));
    expect(field.scrollController, same(scrollController));
    expect(field.leadingIcon, isNotNull);
    expect(field.trailingIcon, isNotNull);
    expect(field.inputFormatters, hasLength(1));

    // TextFieldDecorationBox invokes both source slots directly. With both
    // present, its middle box receives vertical padding only.
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('miuix-text-field-surface')),
    );
    final leadingRect = tester.getRect(
      find.byKey(const ValueKey('source-leading')),
    );
    final trailingRect = tester.getRect(
      find.byKey(const ValueKey('source-trailing')),
    );
    expect(leadingRect.left, surfaceRect.left);
    expect(trailingRect.right, surfaceRect.right);
    final contentPadding = tester.widget<Padding>(
      find.byKey(const ValueKey('miuix-text-field-content-padding')),
    );
    expect(contentPadding.padding, const EdgeInsets.symmetric(vertical: 16));
    final editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.scrollController, same(scrollController));

    await tester.tap(find.byKey(const ValueKey('source-text-field')));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    await tester.enterText(find.byType(EditableText), 'abc123');
    await tester.pump();
    await tester.pump();
    expect(controller.text, '123');
    expect(layoutResult?.text, '123');
    expect(layoutResult?.lineCount, 1);
    expect(layoutResult?.didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field source slots retain directional inside margins', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    Future<EdgeInsetsGeometry> pumpPadding({
      required TextDirection direction,
      Widget? leading,
      Widget? trailing,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MiuixTheme(
              child: Scaffold(
                body: SizedBox(
                  width: 320,
                  child: MiuixTextField.source(
                    controller: controller,
                    leadingIcon: leading,
                    trailingIcon: trailing,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester
          .widget<Padding>(
            find.byKey(const ValueKey('miuix-text-field-content-padding')),
          )
          .padding;
    }

    expect(
      await pumpPadding(
        direction: TextDirection.ltr,
        leading: const SizedBox(width: 24, height: 24),
      ),
      const EdgeInsets.fromLTRB(0, 16, 16, 16),
    );
    expect(
      await pumpPadding(
        direction: TextDirection.ltr,
        trailing: const SizedBox(width: 24, height: 24),
      ),
      const EdgeInsets.fromLTRB(16, 16, 0, 16),
    );
    expect(
      await pumpPadding(
        direction: TextDirection.rtl,
        leading: const SizedBox(width: 24, height: 24),
      ),
      const EdgeInsets.fromLTRB(16, 16, 0, 16),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field inherits source content color unless overridden', (
    tester,
  ) async {
    const inherited = Color(0xFF123456);
    const explicit = Color(0xFFABCDEF);
    final controller = TextEditingController(text: 'MIUIX');
    addTearDown(controller.dispose);

    Future<Color?> pumpColor(TextStyle? style) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: MiuixSurface(
                contentColor: inherited,
                child: MiuixTextField(controller: controller, textStyle: style),
              ),
            ),
          ),
        ),
      );
      return tester.widget<EditableText>(find.byType(EditableText)).style.color;
    }

    expect(await pumpColor(null), inherited);
    expect(await pumpColor(const TextStyle(color: explicit)), explicit);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom selection controls toggle without Material wrappers', (
    tester,
  ) async {
    var switchValue = false;
    var checkboxValue = false;
    var radioValue = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixSwitch(
                      value: switchValue,
                      onChanged: (value) => setState(() => switchValue = value),
                    ),
                    MiuixCheckbox(
                      value: checkboxValue,
                      onChanged: (value) =>
                          setState(() => checkboxValue = value ?? false),
                    ),
                    MiuixRadio<int>(
                      value: 1,
                      groupValue: radioValue,
                      onChanged: (value) =>
                          setState(() => radioValue = value ?? 0),
                    ),
                    const MiuixSwitch(
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixCheckbox(
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixRadio<int>(
                      value: 2,
                      groupValue: 1,
                      enabled: false,
                      onChanged: null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixSwitch).first);
    await tester.tap(find.byType(MiuixCheckbox).first);
    await tester.tap(find.byType(MiuixRadio<int>).first);
    await tester.pumpAndSettle();

    expect(switchValue, isTrue);
    expect(checkboxValue, isTrue);
    expect(radioValue, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'selection controls expand enabled targets without changing layout',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const enabledCheckboxKey = ValueKey('enabled-checkbox-target');
      const disabledCheckboxKey = ValueKey('disabled-checkbox-target');
      const disabledCallbackCheckboxKey = ValueKey(
        'disabled-callback-checkbox-target',
      );
      const enabledRadioKey = ValueKey('enabled-radio-target');
      const disabledRadioKey = ValueKey('disabled-radio-target');
      const disabledCallbackRadioKey = ValueKey(
        'disabled-callback-radio-target',
      );
      var checkboxValue = false;
      var radioValue = 0;
      var disabledCheckboxCalls = 0;
      var disabledRadioCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: enabledCheckboxKey,
                              value: checkboxValue,
                              onChanged: (value) => setState(
                                () => checkboxValue = value ?? false,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: disabledCheckboxKey,
                              value: false,
                              enabled: false,
                              onChanged: null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixCheckbox(
                              key: disabledCallbackCheckboxKey,
                              value: true,
                              enabled: false,
                              onChanged: (_) => disabledCheckboxCalls++,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: enabledRadioKey,
                              value: 1,
                              groupValue: radioValue,
                              onChanged: (value) =>
                                  setState(() => radioValue = value ?? 0),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: disabledRadioKey,
                              value: 2,
                              groupValue: 0,
                              enabled: false,
                              onChanged: null,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Center(
                            child: MiuixRadio<int>(
                              key: disabledCallbackRadioKey,
                              value: 3,
                              groupValue: 3,
                              enabled: false,
                              onChanged: (_) => disabledRadioCalls++,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      Finder semanticTarget(Finder control, ValueKey<String> key) =>
          find.descendant(of: control, matching: find.byKey(key));
      final enabledCheckbox = find.byKey(enabledCheckboxKey);
      final disabledCheckbox = find.byKey(disabledCheckboxKey);
      final disabledCallbackCheckbox = find.byKey(disabledCallbackCheckboxKey);
      final enabledRadio = find.byKey(enabledRadioKey);
      final disabledRadio = find.byKey(disabledRadioKey);
      final disabledCallbackRadio = find.byKey(disabledCallbackRadioKey);
      final enabledCheckboxSemantics = semanticTarget(
        enabledCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final disabledCheckboxSemantics = semanticTarget(
        disabledCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final disabledCallbackCheckboxSemantics = semanticTarget(
        disabledCallbackCheckbox,
        const ValueKey('miuix-checkbox-semantics'),
      );
      final enabledRadioSemantics = semanticTarget(
        enabledRadio,
        const ValueKey('miuix-radio-semantics'),
      );
      final disabledRadioSemantics = semanticTarget(
        disabledRadio,
        const ValueKey('miuix-radio-semantics'),
      );
      final disabledCallbackRadioSemantics = semanticTarget(
        disabledCallbackRadio,
        const ValueKey('miuix-radio-semantics'),
      );

      // Compose measures every control at 26dp, then expands only interactive
      // pointer and accessibility bounds to the platform 48dp minimum.
      for (final control in [
        enabledCheckbox,
        disabledCheckbox,
        disabledCallbackCheckbox,
        enabledRadio,
        disabledRadio,
        disabledCallbackRadio,
      ]) {
        expect(
          tester.getSize(control).width * sourceDensity,
          closeTo(68, .001),
        );
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(68, .001),
        );
      }
      for (final target in [
        enabledCheckboxSemantics,
        disabledCallbackCheckboxSemantics,
        enabledRadioSemantics,
        disabledCallbackRadioSemantics,
      ]) {
        expect(
          tester.getRect(target).width * sourceDensity,
          closeTo(126, .001),
        );
        expect(
          tester.getRect(target).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      for (final target in [
        disabledCheckboxSemantics,
        disabledRadioSemantics,
      ]) {
        expect(tester.getRect(target).width * sourceDensity, closeTo(68, .001));
        expect(
          tester.getRect(target).height * sourceDensity,
          closeTo(68, .001),
        );
      }

      // Twenty logical pixels is outside the 13dp visual radius but inside the
      // expanded 24dp hit radius, so these taps prove the target is functional.
      await tester.tapAt(
        tester.getRect(enabledCheckboxSemantics).center + const Offset(20, 0),
      );
      await tester.tapAt(
        tester.getRect(enabledRadioSemantics).center + const Offset(20, 0),
      );
      await tester.tapAt(
        tester.getRect(disabledCallbackCheckboxSemantics).center,
      );
      await tester.tapAt(tester.getRect(disabledCallbackRadioSemantics).center);
      await tester.pumpAndSettle();
      expect(checkboxValue, isTrue);
      expect(radioValue, 1);
      expect(disabledCheckboxCalls, 0);
      expect(disabledRadioCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('switch exposes the exact MIUIX motion springs', () {
    final offset = debugMiuixSwitchThumbOffsetSpring();
    final scale = debugMiuixSwitchThumbScaleSpring();
    final track = debugMiuixSwitchTrackColorSpring();
    final thumbColor = debugMiuixSwitchThumbColorSpring();

    expect(offset.stiffness, 987);
    expect(offset.damping, closeTo(2 * math.sqrt(987) * .7, .0001));
    expect(scale.stiffness, 987);
    expect(scale.damping, closeTo(2 * math.sqrt(987) * .6, .0001));
    expect(track.stiffness, 438.6);
    expect(track.damping, closeTo(2 * math.sqrt(438.6) * .99, .0001));
    expect(thumbColor.stiffness, 1500);
    expect(thumbColor.damping, closeTo(2 * math.sqrt(1500), .0001));
  });

  test('switch colors preserve all eight source data channels', () {
    const colors = MiuixSwitchColors(
      checkedThumbColor: Color(0xFF000001),
      uncheckedThumbColor: Color(0xFF000002),
      disabledCheckedThumbColor: Color(0xFF000003),
      disabledUncheckedThumbColor: Color(0xFF000004),
      checkedTrackColor: Color(0xFF000005),
      uncheckedTrackColor: Color(0xFF000006),
      disabledCheckedTrackColor: Color(0xFF000007),
      disabledUncheckedTrackColor: Color(0xFF000008),
    );
    expect(colors.thumb(checked: true, enabled: true), const Color(0xFF000001));
    expect(
      colors.thumb(checked: false, enabled: true),
      const Color(0xFF000002),
    );
    expect(
      colors.thumb(checked: true, enabled: false),
      const Color(0xFF000003),
    );
    expect(
      colors.thumb(checked: false, enabled: false),
      const Color(0xFF000004),
    );
    expect(colors.track(checked: true, enabled: true), const Color(0xFF000005));
    expect(
      colors.track(checked: false, enabled: true),
      const Color(0xFF000006),
    );
    expect(
      colors.track(checked: true, enabled: false),
      const Color(0xFF000007),
    );
    expect(
      colors.track(checked: false, enabled: false),
      const Color(0xFF000008),
    );
    expect(colors.copyWith(), colors);
    expect(MiuixSwitchDefaults.width, 49);
    expect(MiuixSwitchDefaults.height, 28);
    expect(MiuixSwitchDefaults.thumbSize, 20);
    expect(MiuixSwitchDefaults.dragDistance, 21);
  });

  testWidgets('switch source adapter and custom colors drive real painting', (
    tester,
  ) async {
    late MiuixSwitchColors defaults;
    var value = false;
    const custom = MiuixSwitchColors(
      checkedThumbColor: Color(0xFF102030),
      uncheckedThumbColor: Color(0xFF203040),
      disabledCheckedThumbColor: Color(0xFF304050),
      disabledUncheckedThumbColor: Color(0xFF405060),
      checkedTrackColor: Color(0xFF506070),
      uncheckedTrackColor: Color(0xFF607080),
      disabledCheckedTrackColor: Color(0xFF708090),
      disabledUncheckedTrackColor: Color(0xFF8090A0),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixSwitchDefaults.switchColors(context);
              return StatefulBuilder(
                builder: (context, setState) => MiuixSwitch.source(
                  checked: value,
                  onCheckedChange: (next) => setState(() => value = next),
                  colors: custom,
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(
      defaults.checkedTrackColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledUncheckedThumbColor,
      const MiuixSemanticColors.light()['disabledOnSecondary'],
    );
    BoxDecoration trackDecoration() =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-track')),
                )
                .decoration
            as BoxDecoration;
    BoxDecoration thumbDecoration() =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-thumb')),
                )
                .decoration
            as BoxDecoration;
    expect(
      trackDecoration().color?.toARGB32(),
      custom.uncheckedTrackColor.toARGB32(),
    );
    expect(
      thumbDecoration().color?.toARGB32(),
      custom.uncheckedThumbColor.toARGB32(),
    );
    await tester.tap(find.byType(MiuixSwitch));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(
      trackDecoration().color?.toARGB32(),
      custom.checkedTrackColor.toARGB32(),
    );
    expect(
      thumbDecoration().color?.toARGB32(),
      custom.checkedThumbColor.toARGB32(),
    );
    expect(tester.takeException(), isNull);
  });

  test('checkbox colors preserve all eight source data channels', () {
    const colors = MiuixCheckboxColors(
      checkedForegroundColor: Color(0xFF000001),
      uncheckedForegroundColor: Color(0xFF000002),
      disabledCheckedForegroundColor: Color(0xFF000003),
      disabledUncheckedForegroundColor: Color(0xFF000004),
      checkedBackgroundColor: Color(0xFF000005),
      uncheckedBackgroundColor: Color(0xFF000006),
      disabledCheckedBackgroundColor: Color(0xFF000007),
      disabledUncheckedBackgroundColor: Color(0xFF000008),
    );
    expect(
      colors.foreground(checked: true, enabled: true),
      const Color(0xFF000001),
    );
    expect(
      colors.foreground(checked: false, enabled: true),
      const Color(0xFF000002),
    );
    expect(
      colors.foreground(checked: true, enabled: false),
      const Color(0xFF000003),
    );
    expect(
      colors.foreground(checked: false, enabled: false),
      const Color(0xFF000004),
    );
    expect(
      colors.background(checked: true, enabled: true),
      const Color(0xFF000005),
    );
    expect(
      colors.background(checked: false, enabled: true),
      const Color(0xFF000006),
    );
    expect(
      colors.background(checked: true, enabled: false),
      const Color(0xFF000007),
    );
    expect(
      colors.background(checked: false, enabled: false),
      const Color(0xFF000008),
    );
    expect(colors.copyWith(), colors);
    expect(
      colors.copyWith(checkedBackgroundColor: const Color(0xFF123456)),
      const MiuixCheckboxColors(
        checkedForegroundColor: Color(0xFF000001),
        uncheckedForegroundColor: Color(0xFF000002),
        disabledCheckedForegroundColor: Color(0xFF000003),
        disabledUncheckedForegroundColor: Color(0xFF000004),
        checkedBackgroundColor: Color(0xFF123456),
        uncheckedBackgroundColor: Color(0xFF000006),
        disabledCheckedBackgroundColor: Color(0xFF000007),
        disabledUncheckedBackgroundColor: Color(0xFF000008),
      ),
    );
    expect(MiuixCheckboxDefaults.size, 26);
    expect(MiuixCheckboxDefaults.touchTargetSize, 48);
  });

  testWidgets('checkbox source defaults and tristate adapter drive painting', (
    tester,
  ) async {
    late MiuixCheckboxColors defaults;
    var clicks = 0;
    const custom = MiuixCheckboxColors(
      checkedForegroundColor: Color(0xFF102030),
      uncheckedForegroundColor: Color(0xFF203040),
      disabledCheckedForegroundColor: Color(0xFF304050),
      disabledUncheckedForegroundColor: Color(0xFF405060),
      checkedBackgroundColor: Color(0xFF506070),
      uncheckedBackgroundColor: Color(0xFF607080),
      disabledCheckedBackgroundColor: Color(0xFF708090),
      disabledUncheckedBackgroundColor: Color(0xFF8090A0),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixCheckboxDefaults.checkboxColors(context);
              return MiuixCheckbox.tristate(
                state: null,
                onClick: () => clicks++,
                colors: custom,
              );
            },
          ),
        ),
      ),
    );

    expect(
      defaults.checkedBackgroundColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledUncheckedBackgroundColor,
      const MiuixSemanticColors.light()['disabledSecondary'],
    );
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-checkbox-canvas')),
                )
                .painter
            as dynamic;
    expect(painter.background, custom.checkedBackgroundColor);
    expect(painter.foreground, custom.checkedForegroundColor);
    expect(painter.crossCenterGravitation, 1);
    await tester.tap(find.byType(MiuixCheckbox));
    expect(clicks, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only checkbox retains source press feedback only', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(child: MiuixCheckbox(value: false, onChanged: null)),
        ),
      ),
    );
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackOnly, isTrue);
    final semantics = tester
        .getSemantics(find.byKey(const ValueKey('miuix-checkbox-semantics')))
        .getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);

    final detector = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byType(GestureDetector),
      ),
    );
    detector.onTapDown!(TapDownDetails(localPosition: const Offset(13, 13)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final sink = tester.widget<Transform>(
      find.descendant(
        of: find.byType(MiuixCheckbox),
        matching: find.byKey(const ValueKey('miuix-sink-transform')),
      ),
    );
    expect(sink.transform.entry(0, 0), closeTo(.85, .002));
    detector.onTapCancel!();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('radio colors preserve source data and defaults dimensions', () {
    const colors = MiuixRadioButtonColors(
      selectedColor: Color(0xFF112233),
      disabledSelectedColor: Color(0xFF445566),
    );
    expect(colors.color(enabled: true), const Color(0xFF112233));
    expect(colors.color(enabled: false), const Color(0xFF445566));
    expect(colors.copyWith(), colors);
    expect(
      colors.copyWith(selectedColor: const Color(0xFF778899)),
      const MiuixRadioButtonColors(
        selectedColor: Color(0xFF778899),
        disabledSelectedColor: Color(0xFF445566),
      ),
    );
    expect(MiuixRadioButtonDefaults.size, 26);
    expect(MiuixRadioButtonDefaults.touchTargetSize, 48);
  });

  testWidgets('radio source adapter colors and read-only feedback are exact', (
    tester,
  ) async {
    late MiuixRadioButtonColors defaults;
    var clicks = 0;
    const custom = MiuixRadioButtonColors(
      selectedColor: Color(0xFF123456),
      disabledSelectedColor: Color(0xFF654321),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixRadioButtonDefaults.radioButtonColors(context);
              return Column(
                children: [
                  MiuixRadioButton.source(
                    selected: true,
                    onClick: () => clicks++,
                    colors: custom,
                  ),
                  MiuixRadioButton.source(
                    selected: true,
                    onClick: null,
                    colors: custom,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    expect(
      defaults.selectedColor,
      const MiuixSemanticColors.light()['primary'],
    );
    expect(
      defaults.disabledSelectedColor,
      const MiuixSemanticColors.light()['disabledPrimary'],
    );
    final firstPainter =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-radio-canvas')).first,
                )
                .painter
            as dynamic;
    expect(firstPainter.color, custom.selectedColor);
    await tester.tap(find.byType(MiuixRadioButton<bool>).first);
    expect(clicks, 1);

    final readOnly = find.byType(MiuixRadioButton<bool>).last;
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(of: readOnly, matching: find.byType(MiuixPressable)),
    );
    expect(pressable.feedbackOnly, isTrue);
    final semantics = tester
        .getSemantics(
          find.descendant(
            of: readOnly,
            matching: find.byKey(const ValueKey('miuix-radio-semantics')),
          ),
        )
        .getSemanticsData();
    expect(semantics.hasAction(SemanticsAction.tap), isFalse);
    expect(tester.takeException(), isNull);
  });

  test('checkbox preserves every MIUIX transition channel and keyframe', () {
    // Off -> On: visibility finishes at 10 ms, start trim at 200 ms, while
    // the first end-trim leg is linear and deliberately peaks at .85.
    final enteringMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 5,
    );
    expect(
      enteringMidpoint.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      enteringMidpoint.trimStart,
      closeTo(.1 + .086 * Curves.fastOutSlowIn.transform(.025), .000001),
    );
    expect(enteringMidpoint.trimEnd, closeTo(.1 + .75 * .025, .000001));

    final firstKeyframe = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 200,
    );
    expect(firstKeyframe.checkAlpha, 1);
    expect(firstKeyframe.trimStart, .186);
    expect(firstKeyframe.trimEnd, .85);

    final secondKeyframeMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimStart: .1,
      fromTrimEnd: .1,
      fromCrossCenterGravitation: 0,
      targetChecked: true,
      targetIndeterminate: false,
      elapsedMilliseconds: 250,
    );
    expect(
      secondKeyframeMidpoint.trimEnd,
      closeTo(.85 + (.803 - .85) * Curves.fastOutSlowIn.transform(.5), .000001),
    );

    // On -> Mixed changes only path gravitation. updateTransition leaves the
    // already-resolved visibility and trim channels untouched.
    final mixedMidpoint = debugMiuixCheckboxTransitionFrame(
      fromCheckAlpha: 1,
      fromTrimStart: .186,
      fromTrimEnd: .803,
      fromCrossCenterGravitation: 0,
      targetChecked: false,
      targetIndeterminate: true,
      elapsedMilliseconds: 100,
    );
    expect(mixedMidpoint.checkAlpha, 1);
    expect(mixedMidpoint.trimStart, .186);
    expect(mixedMidpoint.trimEnd, .803);
    expect(
      mixedMidpoint.crossCenterGravitation,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
  });

  test('radio keeps source alpha and trim durations independent', () {
    final entering = debugMiuixRadioTransitionFrame(
      fromCheckAlpha: 0,
      fromTrimEnd: 0,
      targetSelected: true,
      elapsedMilliseconds: 5,
    );
    expect(
      entering.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      entering.trimEnd,
      closeTo(Curves.fastOutSlowIn.transform(5 / 300), .000001),
    );

    final exiting = debugMiuixRadioTransitionFrame(
      fromCheckAlpha: 1,
      fromTrimEnd: 1,
      targetSelected: false,
      elapsedMilliseconds: 75,
    );
    expect(
      exiting.checkAlpha,
      closeTo(1 - Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      exiting.trimEnd,
      closeTo(1 - Curves.fastOutSlowIn.transform(.25), .000001),
    );
  });

  testWidgets('selection painters follow source timelines and disabled roles', (
    tester,
  ) async {
    var checked = false;
    var selected = false;
    late StateSetter updateFixture;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateFixture = setState;
              return Column(
                children: [
                  MiuixCheckbox(value: checked, onChanged: (_) {}),
                  MiuixRadio<int>(
                    value: 1,
                    groupValue: selected ? 1 : 0,
                    onChanged: (_) {},
                  ),
                  const MiuixCheckbox(
                    value: true,
                    enabled: false,
                    onChanged: null,
                  ),
                  const MiuixRadio<int>(
                    value: 1,
                    groupValue: 1,
                    enabled: false,
                    onChanged: null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    // Disabled controls use the fixed-light palette's dedicated roles. This
    // prevents a future generic Opacity wrapper from silently returning.
    final disabledCheckbox =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-checkbox-canvas')).last,
                )
                .painter
            as dynamic;
    final disabledRadio =
        tester
                .widget<CustomPaint>(
                  find.byKey(const ValueKey('miuix-radio-canvas')).last,
                )
                .painter
            as dynamic;
    expect(disabledCheckbox.background, const Color(0xFFC2D9FF));
    expect(disabledCheckbox.foreground, const Color(0xFFF3F8FF));
    expect(disabledRadio.color, const Color(0xFFC2D9FF));

    updateFixture(() {
      checked = true;
      selected = true;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 5));

    dynamic checkboxPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')).first,
        )
        .painter;
    dynamic radioPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-radio-canvas')).first,
        )
        .painter;
    expect(
      checkboxPainter.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );
    expect(
      radioPainter.checkAlpha,
      closeTo(Curves.fastOutSlowIn.transform(.5), .000001),
    );

    await tester.pump(const Duration(milliseconds: 195));
    checkboxPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')).first,
        )
        .painter;
    radioPainter = tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-radio-canvas')).first,
        )
        .painter;
    expect(checkboxPainter.trimEnd, closeTo(.85, .000001));
    expect(
      radioPainter.trimEnd,
      closeTo(Curves.fastOutSlowIn.transform(2 / 3), .000001),
    );
  });

  testWidgets('selection controls snap active motion when animations disable', (
    tester,
  ) async {
    var selected = false;
    var reduceMotion = false;
    late StateSetter updateFixture;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateFixture = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Column(
                  children: [
                    MiuixSwitch(value: selected, onChanged: (_) {}),
                    MiuixCheckbox(value: selected, onChanged: (_) {}),
                    MiuixRadio<int>(
                      value: 1,
                      groupValue: selected ? 1 : 0,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    double thumbLeft() => tester
        .widget<Positioned>(
          find.ancestor(of: thumb, matching: find.byType(Positioned)).first,
        )
        .left!;
    dynamic checkboxPainter() => tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-checkbox-canvas')),
        )
        .painter;
    dynamic radioPainter() => tester
        .widget<CustomPaint>(find.byKey(const ValueKey('miuix-radio-canvas')))
        .painter;

    updateFixture(() => selected = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    expect(
      thumbLeft(),
      inExclusiveRange(
        MiuixSwitchDefaults.uncheckedThumbOffset,
        MiuixSwitchDefaults.checkedThumbOffset,
      ),
    );
    expect(checkboxPainter().trimEnd, inExclusiveRange(.1, .803));
    expect(radioPainter().trimEnd, inExclusiveRange(0, 1));

    updateFixture(() => reduceMotion = true);
    await tester.pump();
    expect(thumbLeft(), MiuixSwitchDefaults.checkedThumbOffset);
    final switchContext = tester.element(find.byType(MiuixSwitch));
    final switchColors = MiuixSwitchDefaults.switchColors(switchContext);
    final trackDecoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-switch-track')),
                )
                .decoration
            as BoxDecoration;
    final thumbDecoration =
        tester.widget<DecoratedBox>(thumb).decoration as BoxDecoration;
    expect(trackDecoration.color, switchColors.checkedTrackColor);
    expect(thumbDecoration.color, switchColors.checkedThumbColor);
    expect(checkboxPainter().checkAlpha, 1);
    expect(checkboxPainter().trimEnd, .803);
    expect(radioPainter().checkAlpha, 1);
    expect(radioPainter().trimEnd, 1);

    updateFixture(() => selected = false);
    await tester.pump();
    expect(thumbLeft(), MiuixSwitchDefaults.uncheckedThumbOffset);
    expect(checkboxPainter().checkAlpha, 0);
    expect(checkboxPainter().trimStart, .1);
    expect(checkboxPainter().trimEnd, .1);
    expect(radioPainter().checkAlpha, 0);
    expect(radioPainter().trimEnd, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch matches MIUIX size and drag threshold', (tester) async {
    var switchValue = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixSwitch(
                      value: switchValue,
                      onChanged: (value) => setState(() => switchValue = value),
                    ),
                    const MiuixSwitch(
                      value: false,
                      enabled: false,
                      onChanged: null,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    final track = find.byKey(const ValueKey('miuix-switch-track')).first;
    final thumb = find.byKey(const ValueKey('miuix-switch-thumb')).first;
    expect(tester.getSize(track), const Size(49, 28));
    expect(tester.getSize(thumb), const Size.square(20));
    // Switch.kt places the 20dp thumb at 4dp when off and 25dp when on. The
    // asymmetric values are deliberate and must not be visually centered by
    // adding a self-designed border or shadow.
    expect(tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx, 4);
    final trackDecoration =
        tester.widget<DecoratedBox>(track).decoration as BoxDecoration;
    final thumbDecoration =
        tester.widget<DecoratedBox>(thumb).decoration as BoxDecoration;
    expect(trackDecoration.color, const Color(0xFFE6E6E6));
    expect(thumbDecoration.color, Colors.white);

    // Disabled switches use dedicated MIUIX roles rather than applying a
    // generic opacity to the enabled colors. These exact values come from the
    // original fixed light palette and guard both semantic-role lookup and the
    // component's state resolution.
    final disabledTrack = find.byKey(const ValueKey('miuix-switch-track')).last;
    final disabledThumb = find.byKey(const ValueKey('miuix-switch-thumb')).last;
    final disabledTrackDecoration =
        tester.widget<DecoratedBox>(disabledTrack).decoration as BoxDecoration;
    final disabledThumbDecoration =
        tester.widget<DecoratedBox>(disabledThumb).decoration as BoxDecoration;
    expect(disabledTrackDecoration.color, const Color(0xFFF0F0F0));
    expect(disabledThumbDecoration.color, const Color(0xFFFCFCFC));

    await tester.drag(thumb, const Offset(44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isTrue);
    expect(
      tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx,
      closeTo(25, .001),
    );

    await tester.drag(thumb, const Offset(-44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isFalse);

    await tester.drag(disabledThumb, const Offset(44, 0));
    await tester.pumpAndSettle();
    expect(switchValue, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch drag starts only on the source thumb hit area', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: MiuixSwitch(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );

    final track = find.byKey(const ValueKey('miuix-switch-track'));
    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    final trackRect = tester.getRect(track);

    // Switch.kt installs draggable on the 20dp thumb, not the 49dp track.
    // Starting at the track's far edge therefore cannot move or commit it.
    await tester.dragFrom(
      Offset(trackRect.right - 2, trackRect.center.dy),
      const Offset(60, 0),
    );
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(
      tester.getTopLeft(thumb).dx - tester.getTopLeft(track).dx,
      closeTo(MiuixSwitchDefaults.uncheckedThumbOffset, .001),
    );

    // The same horizontal motion beginning on the authored thumb does commit.
    await tester.dragFrom(tester.getCenter(thumb), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch retains unclamped drag travel before a small reversal', (
    tester,
  ) async {
    var value = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) => Center(
              child: MiuixSwitch(
                value: value,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    double authoredThumbLeft() => tester
        .widget<Positioned>(
          find.ancestor(of: thumb, matching: find.byType(Positioned)).first,
        )
        .left!;
    final gesture = await tester.startGesture(tester.getCenter(thumb));
    // Several pointer frames mirror a real drag and leave far more raw travel
    // than the visible 21dp projection can show.
    for (var frame = 0; frame < 10; frame += 1) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      authoredThumbLeft(),
      closeTo(MiuixSwitchDefaults.checkedThumbOffset, .1),
    );

    // Compose accumulates the raw pointer delta before clamping. A 10dp
    // reversal after 100dp forward travel must therefore remain at the end.
    await gesture.moveBy(const Offset(-10, 0));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      authoredThumbLeft(),
      closeTo(MiuixSwitchDefaults.checkedThumbOffset, .1),
    );
    await gesture.up();
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch thumb claims horizontal drag inside an ancestor pager', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var value = false;
    var selectedPage = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: PageView(
              controller: controller,
              onPageChanged: (page) => selectedPage = page,
              children: [
                StatefulBuilder(
                  builder: (context, setState) => Center(
                    child: MiuixSwitch(
                      value: value,
                      onChanged: (next) => setState(() => value = next),
                    ),
                  ),
                ),
                const Center(child: Text('第二页')),
              ],
            ),
          ),
        ),
      ),
    );

    final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
    await tester.drag(thumb, const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(selectedPage, 0);
    expect(controller.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switch expands callback targets to 48dp without changing its track',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const enabledKey = ValueKey('switch-enabled-target');
      const disabledCallbackKey = ValueKey('switch-disabled-callback-target');
      const callbacklessKey = ValueKey('switch-callbackless-target');
      var value = false;
      var disabledCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: enabledKey,
                            value: value,
                            onChanged: (next) => setState(() => value = next),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: disabledCallbackKey,
                            value: true,
                            enabled: false,
                            onChanged: (_) => disabledCalls++,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 100,
                        height: 80,
                        child: Center(
                          child: MiuixSwitch(
                            key: callbacklessKey,
                            value: false,
                            enabled: false,
                            onChanged: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      Finder target(Finder control) => find.descendant(
        of: control,
        matching: find.byKey(const ValueKey('miuix-switch-semantics')),
      );
      final enabled = find.byKey(enabledKey);
      final disabledCallback = find.byKey(disabledCallbackKey);
      final callbackless = find.byKey(callbacklessKey);
      for (final control in [enabled, disabledCallback, callbackless]) {
        expect(
          tester.getSize(control).width * sourceDensity,
          closeTo(129, .001),
        );
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(74, .001),
        );
      }
      for (final control in [enabled, disabledCallback]) {
        expect(
          tester.getRect(target(control)).width * sourceDensity,
          closeTo(129, .001),
        );
        expect(
          tester.getRect(target(control)).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      expect(
        tester.getRect(target(callbackless)).height * sourceDensity,
        closeTo(74, .001),
      );

      // Twenty logical pixels is below the source 24dp target radius but
      // outside the 14dp visible half-height.
      await tester.tapAt(
        tester.getRect(target(enabled)).center + const Offset(0, 20),
      );
      await tester.tapAt(tester.getRect(target(disabledCallback)).center);
      await tester.pumpAndSettle();
      expect(value, isTrue);
      expect(disabledCalls, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('checkbox uses MIUIX source checkmark metrics', (tester) async {
    var value = true;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MiuixCheckbox(
                  value: value,
                  onChanged: (next) => setState(() => value = next ?? false),
                ),
              );
            },
          ),
        ),
      ),
    );

    final canvas = find.byKey(const ValueKey('miuix-checkbox-canvas'));
    expect(tester.getSize(canvas), const Size.square(26));

    final metrics = debugMiuixCheckboxMetrics(const Size.square(26));
    expect(metrics.start.dx, closeTo(5.65, 0.01));
    expect(metrics.start.dy, closeTo(10.63, 0.01));
    expect(metrics.middle.dx, closeTo(11.64, 0.01));
    expect(metrics.middle.dy, closeTo(16.84, 0.01));
    expect(metrics.end.dx, closeTo(20.23, 0.01));
    expect(metrics.end.dy, closeTo(5.77, 0.01));
    expect(metrics.strokeWidth, closeTo(2.34, 0.01));

    await tester.tap(find.byType(MiuixCheckbox));
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkbox exposes the MIUIX indeterminate state', (tester) async {
    bool? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixCheckbox(
              value: false,
              indeterminate: true,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    // A mixed-state click progresses to checked, matching the three-state
    // cycle used by the original Checkbox section.
    expect(
      tester.widget<MiuixCheckbox>(find.byType(MiuixCheckbox)).indeterminate,
      isTrue,
    );
    await tester.tap(find.byType(MiuixCheckbox));
    expect(changed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio uses MIUIX source checkmark metrics', (tester) async {
    var value = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MiuixRadio<int>(
                  value: 1,
                  groupValue: value,
                  onChanged: (next) => setState(() => value = next ?? 0),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixRadio<int>));
    await tester.pumpAndSettle();

    final canvas = find.byKey(const ValueKey('miuix-radio-canvas'));
    expect(tester.getSize(canvas), const Size.square(26));

    final metrics = debugMiuixRadioMetrics(const Size.square(26));
    expect(metrics.start.dx, closeTo(5.06, 0.01));
    expect(metrics.start.dy, closeTo(13.46, 0.01));
    expect(metrics.middle.dx, closeTo(10.72, 0.01));
    expect(metrics.middle.dy, closeTo(18.94, 0.01));
    expect(metrics.end.dx, closeTo(20.43, 0.01));
    expect(metrics.end.dy, closeTo(7.43, 0.01));
    expect(metrics.strokeWidth, closeTo(3.25, 0.01));
    expect(value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio preference defaults to source start placement', (
    tester,
  ) async {
    // The upstream RadioButtonPreference API defaults to Start. Keeping both
    // variants in one fixture also guards the opt-in End layout independently.
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixRadioButtonPreference<int>(
                  title: 'Start radio',
                  value: 1,
                  groupValue: 1,
                  onChanged: _ignoreNullableInt,
                ),
                MiuixRadioButtonPreference<int>(
                  title: 'End radio',
                  value: 2,
                  groupValue: 2,
                  radioButtonLocation: MiuixRadioButtonLocation.end,
                  onChanged: _ignoreNullableInt,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final radios = find.byType(MiuixRadio<int>);
    final startText = tester.getRect(find.text('Start radio'));
    final endText = tester.getRect(find.text('End radio'));
    final startRadio = tester.getRect(radios.at(0));
    final endRadio = tester.getRect(radios.at(1));

    expect(startRadio.right, lessThan(startText.left));
    expect(endRadio.left, greaterThan(endText.right));
  });

  testWidgets('custom sliders update from pointer input safely', (
    tester,
  ) async {
    var sliderValue = 0.0;
    var rangeValues = const RangeValues(0.2, 0.8);
    var verticalValue = 0.0;
    var disabledCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(
                  value: sliderValue,
                  divisions: 4,
                  onChanged: (value) => sliderValue = value,
                ),
                MiuixRangeSlider(
                  values: rangeValues,
                  divisions: 4,
                  onChanged: (value) => rangeValues = value,
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: verticalValue,
                    onChanged: (value) => verticalValue = value,
                  ),
                ),
                MiuixSlider(
                  value: 0.5,
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
                MiuixRangeSlider(
                  values: const RangeValues(0.2, 0.8),
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
                MiuixVerticalSlider(
                  value: 0.5,
                  enabled: false,
                  onChanged: (_) => disabledCalls++,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tapAt(tester.getCenter(find.byType(MiuixSlider).first));
    await tester.tapAt(tester.getCenter(find.byType(MiuixRangeSlider).first));
    await tester.tapAt(
      tester.getCenter(find.byType(MiuixVerticalSlider).first),
    );
    await tester.pump();

    // Slider.kt installs draggable but no tap modifier. A stationary track
    // tap therefore leaves every source slider unchanged.
    expect(sliderValue, 0);
    expect(rangeValues, const RangeValues(.2, .8));
    expect(verticalValue, 0);
    expect(disabledCalls, 0);

    await tester.drag(find.byType(MiuixSlider).first, const Offset(120, 0));
    await tester.drag(
      find.byType(MiuixRangeSlider).first,
      const Offset(-80, 0),
    );
    await tester.drag(
      find.byType(MiuixVerticalSlider).first,
      const Offset(0, -80),
    );
    await tester.pumpAndSettle();

    expect(sliderValue, greaterThan(0));
    expect(rangeValues.start <= rangeValues.end, isTrue);
    expect(verticalValue, greaterThan(0));
    expect(disabledCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal sliders round their own source height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(value: .3, onChanged: null),
                MiuixRangeSlider(values: RangeValues(.2, .8), onChanged: null),
                MiuixRangeSlider(
                  values: RangeValues(.2, .8),
                  height: 20,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final singleHeight =
        tester.getSize(find.byType(MiuixSlider)).height * 2.625;
    final rangeHeights = [
      tester.getSize(find.byType(MiuixRangeSlider).at(0)).height * 2.625,
      tester.getSize(find.byType(MiuixRangeSlider).at(1)).height * 2.625,
    ];
    expect(singleHeight, closeTo(74, .001));
    expect(rangeHeights.first, closeTo(74, .001));
    expect(rangeHeights.last, closeTo(53, .001));
  });

  testWidgets(
    'sliders preserve source layout, 48dp target, enabled contract, and semantics',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final semanticsHandle = tester.ensureSemantics();
      const scalarKey = ValueKey('source-scalar-slider');
      const disabledKey = ValueKey('source-disabled-slider');
      const rangeKey = ValueKey('source-range-slider');
      const verticalKey = ValueKey('source-vertical-slider');
      var scalarValue = .3;
      var verticalValue = .3;
      var disabledPointerCalls = 0;
      var rangePointerCalls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixSlider(
                        key: scalarKey,
                        value: scalarValue,
                        onChanged: (next) => scalarValue = next,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixSlider(
                        key: disabledKey,
                        value: .7,
                        enabled: false,
                        onChanged: (_) => disabledPointerCalls++,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 80,
                    child: Center(
                      child: MiuixRangeSlider(
                        key: rangeKey,
                        values: const RangeValues(.3, .7),
                        enabled: false,
                        onChanged: (_) => rangePointerCalls++,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: Center(
                      child: MiuixVerticalSlider(
                        key: verticalKey,
                        value: verticalValue,
                        width: 25,
                        height: 160,
                        onChanged: (next) => verticalValue = next,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      Finder outer(Finder control, String key) =>
          find.descendant(of: control, matching: find.byKey(ValueKey(key)));
      Finder target(Finder control) => find.descendant(
        of: control,
        matching: find.byKey(const ValueKey('miuix-slider-touch-target')),
      );
      final scalar = find.byKey(scalarKey);
      final disabled = find.byKey(disabledKey);
      final range = find.byKey(rangeKey);
      final vertical = find.byKey(verticalKey);

      for (final control in [scalar, disabled, range]) {
        expect(
          tester.getSize(control).height * sourceDensity,
          closeTo(74, .001),
        );
        expect(
          tester.getRect(target(control)).height * sourceDensity,
          closeTo(126, .001),
        );
      }
      expect(tester.getSize(vertical).width * sourceDensity, closeTo(66, .001));
      expect(
        tester.getRect(target(vertical)).width * sourceDensity,
        closeTo(126, .001),
      );
      expect(
        tester.getSize(vertical).height * sourceDensity,
        closeTo(420, .001),
      );

      final scalarSemantics = tester
          .getSemantics(outer(scalar, 'miuix-slider-semantics'))
          .getSemanticsData();
      final disabledSemantics = tester
          .getSemantics(outer(disabled, 'miuix-slider-semantics'))
          .getSemanticsData();
      final rangeSemantics = tester
          .getSemantics(outer(range, 'miuix-range-slider-semantics'))
          .getSemanticsData();
      final verticalSemantics = tester
          .getSemantics(outer(vertical, 'miuix-vertical-slider-semantics'))
          .getSemanticsData();
      for (final data in [
        scalarSemantics,
        disabledSemantics,
        verticalSemantics,
      ]) {
        // Increase/decrease actions map to android.widget.SeekBar without
        // Flutter's isSlider flag, whose engine bridge would inject a false
        // ACTION_CLICK absent from the Compose source.
        expect(data.flagsCollection.isSlider, isFalse);
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
        expect(data.flagsCollection.isFocused, Tristate.none);
        expect(data.hasAction(SemanticsAction.increase), isTrue);
        expect(data.hasAction(SemanticsAction.decrease), isTrue);
        expect(data.hasAction(SemanticsAction.tap), isFalse);
        expect(data.value, isEmpty);
      }
      expect(rangeSemantics.flagsCollection.isSlider, isFalse);
      expect(rangeSemantics.flagsCollection.isEnabled, Tristate.isTrue);
      expect(rangeSemantics.actions, 0);
      expect(rangeSemantics.value, isEmpty);

      // The expanded transparent band owns horizontal/vertical drags, while a
      // stationary tap still follows the source no-op behavior.
      final scalarTarget = tester.getRect(target(scalar));
      await tester.tapAt(scalarTarget.center + const Offset(0, 20));
      expect(scalarValue, .3);
      await tester.dragFrom(
        scalarTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      expect(scalarValue, greaterThan(.3));

      final disabledTarget = tester.getRect(target(disabled));
      await tester.dragFrom(
        disabledTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      final rangeTarget = tester.getRect(target(range));
      await tester.dragFrom(
        rangeTarget.center + const Offset(0, 20),
        const Offset(100, 0),
      );
      expect(disabledPointerCalls, 0);
      expect(rangePointerCalls, 0);

      final verticalTarget = tester.getRect(target(vertical));
      await tester.dragFrom(
        verticalTarget.center + const Offset(20, 0),
        const Offset(0, -70),
      );
      expect(verticalValue, greaterThan(.3));
      semanticsHandle.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vertical slider owns drag ahead of a parent scrollable', (
    tester,
  ) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    double? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ListView(
            controller: scrollController,
            children: [
              const SizedBox(height: 120),
              Center(
                child: MiuixVerticalSlider(
                  value: .3,
                  width: 25,
                  height: 160,
                  onChanged: (value) => changed = value,
                ),
              ),
              const SizedBox(height: 900),
            ],
          ),
        ),
      ),
    );

    final slider = find.byType(MiuixVerticalSlider);
    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(rect.center.dx, rect.bottom - 25),
    );
    await gesture.moveBy(const Offset(0, -80));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(changed, isNotNull);
    expect(changed!, greaterThan(.3));
    expect(scrollController.offset, closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  test('sliders expose the exact source motion constants', () {
    final dragging = debugMiuixSliderProgressSpring(dragging: true);
    final resting = debugMiuixSliderProgressSpring(dragging: false);
    final thumb = debugMiuixSliderThumbScaleSpring();
    final overlay = debugMiuixSliderTrackOverlayMotion();

    expect(dragging.mass, 1);
    expect(dragging.stiffness, 1755);
    expect(dragging.damping, closeTo(2 * math.sqrt(1755) * .9, .0001));
    expect(resting.mass, 1);
    expect(resting.stiffness, 322);
    expect(resting.damping, closeTo(2 * math.sqrt(322) * .96, .0001));
    expect(thumb.mass, 1);
    expect(thumb.stiffness, 987);
    expect(thumb.damping, closeTo(2 * math.sqrt(987) * .6, .0001));
    expect(debugMiuixSliderActiveThumbScale(), 1.127);
    expect(overlay.alpha, .044);
    expect(overlay.duration, const Duration(milliseconds: 150));
  });

  testWidgets('all slider variants settle active motion when reduced', (
    tester,
  ) async {
    var reduceMotion = false;
    var horizontalValue = .1;
    var verticalValue = .2;
    var rangeValues = const RangeValues(.2, .4);
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Column(
                  children: <Widget>[
                    SizedBox(
                      key: const ValueKey('reduced-horizontal-slider'),
                      width: 300,
                      child: MiuixSlider(
                        value: horizontalValue,
                        onChanged: (value) =>
                            updateHost(() => horizontalValue = value),
                      ),
                    ),
                    SizedBox(
                      key: const ValueKey('reduced-vertical-slider'),
                      width: 48,
                      height: 220,
                      child: MiuixVerticalSlider(
                        value: verticalValue,
                        onChanged: (value) =>
                            updateHost(() => verticalValue = value),
                      ),
                    ),
                    SizedBox(
                      key: const ValueKey('reduced-range-slider'),
                      width: 300,
                      child: MiuixRangeSlider(
                        values: rangeValues,
                        onChanged: (value) =>
                            updateHost(() => rangeValues = value),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    CustomPaint sliderPaint(Finder root) => tester
        .widgetList<CustomPaint>(
          find.descendant(of: root, matching: find.byType(CustomPaint)),
        )
        .firstWhere((paint) {
          try {
            debugMiuixSliderPaintSnapshot(paint.painter);
            return true;
          } on ArgumentError {
            return false;
          }
        });
    final horizontal = find.byKey(const ValueKey('reduced-horizontal-slider'));
    final vertical = find.byKey(const ValueKey('reduced-vertical-slider'));
    final range = find.byKey(const ValueKey('reduced-range-slider'));

    updateHost(() {
      horizontalValue = .9;
      verticalValue = .8;
      rangeValues = const RangeValues(.1, .9);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(
      debugMiuixSliderPaintSnapshot(
        sliderPaint(horizontal).painter,
      ).endFraction,
      isNot(closeTo(.9, .0001)),
    );

    updateHost(() => reduceMotion = true);
    await tester.pump();
    final horizontalSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    final verticalSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(vertical).painter,
    );
    final rangeSettled = debugMiuixSliderPaintSnapshot(
      sliderPaint(range).painter,
    );
    expect(horizontalSettled.endFraction, closeTo(.9, .0001));
    expect(verticalSettled.endFraction, closeTo(.2, .0001));
    expect(rangeSettled.startFraction, closeTo(.1, .0001));
    expect(rangeSettled.endFraction, closeTo(.9, .0001));

    final rect = tester.getRect(horizontal);
    final gesture = await tester.startGesture(
      Offset(rect.left + 70, rect.center.dy),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    final dragging = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    expect(dragging.thumbScale, closeTo(1.127, .0001));
    expect(dragging.backgroundOverlayAlpha, closeTo(.044, .0001));

    await gesture.up();
    await tester.pump();
    final released = debugMiuixSliderPaintSnapshot(
      sliderPaint(horizontal).painter,
    );
    expect(released.thumbScale, 1);
    expect(released.backgroundOverlayAlpha, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders follow source RTL and reverse-direction mapping', (
    tester,
  ) async {
    Future<double> dragHorizontal({
      required TextDirection direction,
      required bool reverse,
    }) async {
      double? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 228,
                  child: MiuixSlider(
                    value: .5,
                    reverseDirection: reverse,
                    onChanged: (value) => changed = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MiuixSlider));
      final gesture = await tester.startGesture(
        Offset(rect.left + 40, rect.center.dy),
      );
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      return changed!;
    }

    final ltr = await dragHorizontal(
      direction: TextDirection.ltr,
      reverse: false,
    );
    final reversed = await dragHorizontal(
      direction: TextDirection.ltr,
      reverse: true,
    );
    final rtl = await dragHorizontal(
      direction: TextDirection.rtl,
      reverse: false,
    );
    final rtlReversed = await dragHorizontal(
      direction: TextDirection.rtl,
      reverse: true,
    );

    expect(ltr, lessThan(.5));
    expect(reversed, closeTo(1 - ltr, .000001));
    expect(rtl, closeTo(reversed, .000001));
    expect(rtlReversed, closeTo(ltr, .000001));

    Future<double> dragVertical({required bool reverse}) async {
      double? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.topLeft,
              child: MiuixVerticalSlider(
                value: .5,
                width: 28,
                height: 228,
                reverseDirection: reverse,
                onChanged: (value) => changed = value,
              ),
            ),
          ),
        ),
      );
      final rect = tester.getRect(find.byType(MiuixVerticalSlider));
      final gesture = await tester.startGesture(
        Offset(rect.center.dx, rect.top + 40),
      );
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      return changed!;
    }

    final bottomToTop = await dragVertical(reverse: false);
    final topToBottom = await dragVertical(reverse: true);
    expect(bottomToTop, greaterThan(.5));
    expect(topToBottom, closeTo(1 - bottomToTop, .000001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('range slider hands ownership across equal thumbs', (
    tester,
  ) async {
    RangeValues? latest;
    var finished = 0;

    Future<Rect> pumpRange({
      required Key key,
      TextDirection direction = TextDirection.ltr,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: 228,
                  child: MiuixRangeSlider(
                    key: key,
                    values: const RangeValues(.25, .75),
                    onChanged: (value) => latest = value,
                    onChangeFinished: () => finished++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return tester.getRect(find.byType(MiuixRangeSlider));
    }

    var rect = await pumpRange(key: const ValueKey('forward-handoff'));
    var gesture = await tester.startGesture(
      Offset(rect.left + 64, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 164, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.75, .75));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    expect(latest!.start, .75);
    expect(latest!.end, greaterThan(.75));
    await gesture.up();
    await tester.pump();

    latest = null;
    rect = await pumpRange(key: const ValueKey('backward-handoff'));
    gesture = await tester.startGesture(
      Offset(rect.left + 164, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 64, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.25, .25));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(latest!.start, lessThan(.25));
    expect(latest!.end, .25);
    await gesture.up();
    await tester.pump();

    latest = null;
    rect = await pumpRange(
      key: const ValueKey('rtl-forward-handoff'),
      direction: TextDirection.rtl,
    );
    gesture = await tester.startGesture(
      Offset(rect.left + 164, rect.center.dy),
    );
    await gesture.moveTo(Offset(rect.left + 64, rect.center.dy));
    await tester.pump();
    expect(latest, const RangeValues(.75, .75));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(latest!.start, .75);
    expect(latest!.end, greaterThan(.75));
    await gesture.up();
    await tester.pump();

    expect(finished, 3);
    expect(tester.takeException(), isNull);
  });

  test('slider minimum keeps the active track visually empty', () {
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: false,
        endFraction: 0,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: true,
        endFraction: 1,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: false,
        vertical: false,
        endFraction: 0.25,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderHasActiveTrack(
        range: true,
        vertical: false,
        endFraction: 0,
      ),
      isTrue,
    );
  });

  test('slider painting uses the source semantic color roles', () {
    const semantic = MiuixSemanticColors.light();
    final enabled = debugMiuixSliderResolvedColors(semantic);
    final disabled = debugMiuixSliderResolvedColors(semantic, enabled: false);

    expect(enabled['background'], const Color(0x0F000000));
    expect(enabled['foreground'], const Color(0xFF3482FF));
    expect(enabled['thumb'], const Color(0xFFFFFFFF));
    expect(enabled['keyPoint'], const Color(0x4DA3B3CD));
    expect(enabled['keyPointForeground'], const Color(0xFF6EB5FF));
    expect(disabled['background'], const Color(0xFFF0F0F0));
    expect(disabled['foreground'], const Color(0xFFB8CFF5));
    expect(disabled['thumb'], const Color(0xFFF3F8FF));
  });

  testWidgets('slider colors and defaults expose all source channels', (
    tester,
  ) async {
    late MiuixSliderColors defaults;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixSliderDefaults.sliderColors(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(MiuixSliderDefaults.minHeight, 28);
    expect(MiuixSliderDefaults.keyPointRadius, 3.855);
    expect(
      MiuixSliderDefaults.defaultHapticEffect,
      MiuixSliderHapticEffect.edge,
    );
    expect(defaults.foregroundColor, const Color(0xFF3482FF));
    expect(defaults.disabledForegroundColor, const Color(0xFFB8CFF5));
    expect(defaults.backgroundColor, const Color(0x0F000000));
    expect(defaults.disabledBackgroundColor, const Color(0xFFF0F0F0));
    expect(defaults.thumbColor, const Color(0xFFFFFFFF));
    expect(defaults.disabledThumbColor, const Color(0xFFF3F8FF));
    expect(defaults.keyPointColor, const Color(0x4DA3B3CD));
    expect(defaults.keyPointForegroundColor, const Color(0xFF6EB5FF));
    expect(defaults.copyWith(), defaults);
    expect(tester.takeException(), isNull);
  });

  testWidgets('all slider variants forward a custom source palette', (
    tester,
  ) async {
    const colors = MiuixSliderColors(
      foregroundColor: Color(0xFF000001),
      disabledForegroundColor: Color(0xFF000002),
      backgroundColor: Color(0xFF000003),
      disabledBackgroundColor: Color(0xFF000004),
      thumbColor: Color(0xFF000005),
      disabledThumbColor: Color(0xFF000006),
      keyPointColor: Color(0xFF000007),
      keyPointForegroundColor: Color(0xFF000008),
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: SizedBox(
            width: 240,
            child: Column(
              children: [
                MiuixSlider(
                  value: .4,
                  onChanged: null,
                  colors: colors,
                  showKeyPoints: true,
                  divisions: 4,
                ),
                MiuixRangeSlider(
                  values: RangeValues(.2, .7),
                  onChanged: null,
                  colors: colors,
                ),
                SizedBox(
                  height: 160,
                  child: MiuixVerticalSlider(
                    value: .6,
                    onChanged: null,
                    colors: colors,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    dynamic painterFor(Finder owner) => tester
        .widget<CustomPaint>(
          find.descendant(of: owner, matching: find.byType(CustomPaint)),
        )
        .painter;
    for (final owner in <Finder>[
      find.byType(MiuixSlider),
      find.byType(MiuixRangeSlider),
      find.byType(MiuixVerticalSlider),
    ]) {
      final Map<String, Color> painted =
          painterFor(owner).debugResolvedColors as Map<String, Color>;
      expect(painted['foreground'], colors.foregroundColor);
      expect(painted['background'], colors.backgroundColor);
      expect(painted['thumb'], colors.thumbColor);
      expect(painted['keyPoint'], colors.keyPointColor);
      expect(painted['keyPointForeground'], colors.keyPointForegroundColor);
    }
    expect(tester.takeException(), isNull);
  });

  test('slider source adapters translate interior steps exactly once', () {
    void scalar(double _) {}
    void range(RangeValues _) {}
    final horizontal = MiuixSlider.source(
      value: .3,
      onValueChange: scalar,
      steps: 4,
      keyPoints: const [0, .5, 1],
    );
    final ranged = MiuixRangeSlider.source(
      value: const RangeValues(.2, .8),
      onValueChange: range,
      steps: 4,
    );
    final vertical = MiuixVerticalSlider.source(
      value: .6,
      onValueChange: scalar,
      steps: 4,
      effect: true,
    );

    // Compose `steps` counts only interior values; Flutter compatibility
    // `divisions` counts intervals, so four interior points become five.
    expect(horizontal.divisions, 5);
    expect(ranged.divisions, 5);
    expect(vertical.divisions, 5);
    expect(horizontal.keyPoints, const [0, .5, 1]);
    expect(vertical.effect, isTrue);
    expect(
      MiuixSlider.source(value: .5, onValueChange: scalar).divisions,
      isNull,
    );
  });

  test('infinite progress keeps the source gray default', () {
    expect(
      MiuixInfiniteProgressIndicator.defaultColor,
      const Color(0xFF888888),
    );
  });

  test('slider tick selection follows MIUIX active fill direction', () {
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: false,
        fraction: 0.25,
        startFraction: 0,
        endFraction: 0.5,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: false,
        fraction: 0.75,
        startFraction: 0,
        endFraction: 0.5,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: true,
        fraction: 0.75,
        startFraction: 1,
        endFraction: 0.5,
      ),
      isTrue,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: false,
        vertical: true,
        fraction: 0.25,
        startFraction: 1,
        endFraction: 0.5,
      ),
      isFalse,
    );
    expect(
      debugMiuixSliderTickSelected(
        range: true,
        vertical: false,
        fraction: 0.5,
        startFraction: 0.25,
        endFraction: 0.75,
      ),
      isTrue,
    );
  });

  test('slider key points stay independent from snapping divisions', () {
    expect(debugMiuixSliderKeyPointFractions(divisions: 4), isEmpty);
    expect(
      debugMiuixSliderKeyPointFractions(divisions: 4, showKeyPoints: true),
      orderedEquals(const [0, .25, .5, .75, 1]),
    );
    expect(
      debugMiuixSliderKeyPointFractions(
        min: 0,
        max: 100,
        showKeyPoints: true,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      orderedEquals(const [0, .25, .5, .75, 1]),
    );
    expect(
      debugMiuixSliderKeyPointFractions(
        showKeyPoints: true,
        keyPoints: const [0, .25],
        vertical: true,
      ),
      orderedEquals(const [.75, 1]),
    );
  });

  test('slider uses full source cross-axis geometry', () {
    final horizontal = debugMiuixSliderGeometry(crossAxisExtent: 28);
    expect(horizontal.trackThickness, 28);
    expect(horizontal.trackRadius, 14);
    expect(horizontal.thumbRadius, closeTo(10.08, .000001));
    expect(horizontal.keyPointRadius, closeTo(28 / 7.5, .000001));

    final vertical = debugMiuixSliderGeometry(crossAxisExtent: 25);
    expect(vertical.trackThickness, 25);
    expect(vertical.trackRadius, 12.5);
    expect(vertical.thumbRadius, 9);
    expect(vertical.keyPointRadius, closeTo(25 / 7.5, .000001));
  });

  test('slider applies source step precedence and strict key-point magnet', () {
    // Custom points magnetize only while the pointer is strictly inside the
    // 2% threshold; equality remains a continuous value in Slider.kt.
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .259,
        min: 0,
        max: 100,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      25,
    );
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .27,
        min: 0,
        max: 100,
        keyPoints: const [0, 25, 50, 75, 100],
      ),
      closeTo(27, .000001),
    );
    expect(
      debugMiuixSliderValueFromFraction(
        fraction: .501,
        min: 0,
        max: 200,
        divisions: 200,
        keyPoints: const [0, 50, 100, 150, 200],
      ),
      100,
    );
  });

  testWidgets('slider gesture uses the source custom-point magnet', (
    tester,
  ) async {
    var value = 0.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 228,
              child: MiuixSlider(
                value: value,
                min: 0,
                max: 100,
                keyPoints: const [0, 25, 50, 75, 100],
                onChanged: (next) => value = next,
              ),
            ),
          ),
        ),
      ),
    );

    final rect = tester.getRect(find.byType(MiuixSlider));
    // A 228 x 28 slider has 200 dp between the two 14 dp thumb centers.
    final thumbCenter = rect.topLeft + const Offset(14, 14);
    final firstDrag = await tester.startGesture(thumbCenter);
    await firstDrag.moveTo(rect.topLeft + const Offset(14 + 200 * .259, 14));
    await firstDrag.up();
    expect(value, 25);
    final secondDrag = await tester.startGesture(thumbCenter);
    await secondDrag.moveTo(rect.topLeft + const Offset(14 + 200 * .27, 14));
    await secondDrag.up();
    expect(value, closeTo(27, .000001));
  });

  testWidgets('sliders clamp non-finite and inverted inputs without throwing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixSlider(value: double.nan, onChanged: null),
                MiuixSlider(value: double.infinity, onChanged: null),
                MiuixRangeSlider(
                  values: RangeValues(double.nan, double.infinity),
                  onChanged: null,
                ),
                MiuixRangeSlider(values: RangeValues(.9, .1), onChanged: null),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: double.negativeInfinity,
                    onChanged: null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsNWidgets(2));
    expect(find.byType(MiuixRangeSlider), findsNWidgets(2));
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders tolerate inverted bounds, zero span, and edge drags', (
    tester,
  ) async {
    var horizontal = .5;
    var vertical = .5;
    var range = const RangeValues(.25, .75);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: horizontal,
                    min: 10,
                    max: -10,
                    onChanged: (value) => horizontal = value,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: range,
                    min: 1,
                    max: 1,
                    onChanged: (value) => range = value,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: vertical,
                    min: 2,
                    max: -2,
                    onChanged: (value) => vertical = value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final sliderRect = tester.getRect(find.byType(MiuixSlider));
    final rangeRect = tester.getRect(find.byType(MiuixRangeSlider));
    final verticalRect = tester.getRect(find.byType(MiuixVerticalSlider));

    await tester.dragFrom(
      sliderRect.centerRight - const Offset(2, 0),
      const Offset(-400, 0),
    );
    await tester.tapAt(rangeRect.centerLeft - const Offset(40, 0));
    await tester.dragFrom(
      verticalRect.bottomCenter - const Offset(0, 2),
      const Offset(0, -400),
    );
    await tester.pumpAndSettle();

    expect(horizontal.isFinite, isTrue);
    expect(vertical.isFinite, isTrue);
    expect(range.start.isFinite, isTrue);
    expect(range.end.isFinite, isTrue);
    expect(range.start <= range.end, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders sanitize unstable dimensions and scale inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: .5,
                    divisions: 0,
                    height: double.nan,
                    trackScale: double.nan,
                    thumbScale: double.infinity,
                    onChanged: null,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: RangeValues(.2, .8),
                    divisions: -4,
                    onChanged: null,
                  ),
                ),
                MiuixVerticalSlider(
                  value: .5,
                  divisions: -1,
                  height: double.infinity,
                  width: double.nan,
                  trackScale: double.negativeInfinity,
                  thumbScale: double.nan,
                  onChanged: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsOneWidget);
    expect(find.byType(MiuixRangeSlider), findsOneWidget);
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabled sliders remain interactive under tiny safe scales', (
    tester,
  ) async {
    var sliderValue = .5;
    var verticalValue = .5;
    var rangeValues = const RangeValues(.3, .7);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 220,
                  child: MiuixSlider(
                    value: sliderValue,
                    trackScale: .25,
                    thumbScale: .25,
                    onChanged: (value) => sliderValue = value,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: MiuixRangeSlider(
                    values: rangeValues,
                    onChanged: (value) => rangeValues = value,
                  ),
                ),
                SizedBox(
                  height: 180,
                  child: MiuixVerticalSlider(
                    value: verticalValue,
                    trackScale: .25,
                    thumbScale: .25,
                    onChanged: (value) => verticalValue = value,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(MiuixSlider), const Offset(120, 0));
    await tester.drag(find.byType(MiuixRangeSlider), const Offset(-90, 0));
    await tester.drag(find.byType(MiuixVerticalSlider), const Offset(0, -90));
    await tester.pumpAndSettle();

    expect(sliderValue.isFinite, isTrue);
    expect(verticalValue.isFinite, isTrue);
    expect(rangeValues.start.isFinite, isTrue);
    expect(rangeValues.end.isFinite, isTrue);
    expect(rangeValues.start <= rangeValues.end, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliders collapse safely under tiny layout constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                SizedBox(
                  width: 8,
                  child: MiuixSlider(value: .5, onChanged: null),
                ),
                SizedBox(
                  width: 8,
                  child: MiuixRangeSlider(
                    values: RangeValues(.2, .8),
                    onChanged: null,
                  ),
                ),
                SizedBox(
                  width: 10,
                  height: 20,
                  child: MiuixVerticalSlider(value: .5, onChanged: null),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MiuixSlider), findsOneWidget);
    expect(find.byType(MiuixRangeSlider), findsOneWidget);
    expect(find.byType(MiuixVerticalSlider), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom progress indicators normalize unstable values', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(value: double.nan),
                MiuixLinearProgressIndicator(value: double.infinity),
                MiuixLinearProgressIndicator(value: -1),
                MiuixLinearProgressIndicator(value: 2),
                MiuixCircularProgressIndicator(value: double.nan),
                MiuixCircularProgressIndicator(value: double.infinity),
                MiuixCircularProgressIndicator(value: -1),
                MiuixCircularProgressIndicator(value: 2),
                MiuixProgressIndicator(),
                MiuixProgressIndicator(circular: true),
                MiuixInfiniteProgressIndicator(),
                MiuixInfiniteProgressIndicator(circular: true),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 16));

    expect(find.byType(MiuixLinearProgressIndicator), findsNWidgets(4));
    expect(find.byType(MiuixCircularProgressIndicator), findsNWidgets(4));
    expect(find.byType(MiuixInfiniteProgressIndicator), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  test('progress defaults and colors expose the complete source contract', () {
    expect(
      MiuixProgressIndicatorDefaults.defaultLinearProgressIndicatorHeight,
      6,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultCircularProgressIndicatorStrokeWidth,
      4,
    );
    expect(
      MiuixProgressIndicatorDefaults.defaultCircularProgressIndicatorSize,
      30,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultInfiniteProgressIndicatorStrokeWidth,
      2,
    );
    expect(
      MiuixProgressIndicatorDefaults
          .defaultInfiniteProgressIndicatorOrbitingDotSize,
      2,
    );
    expect(
      MiuixProgressIndicatorDefaults.defaultInfiniteProgressIndicatorSize,
      20,
    );

    const first = MiuixProgressIndicatorColors(
      foregroundColor: Color(0xFF123456),
      disabledForegroundColor: Color(0xFF654321),
      backgroundColor: Color(0xFFABCDEF),
    );
    const equal = MiuixProgressIndicatorColors(
      foregroundColor: Color(0xFF123456),
      disabledForegroundColor: Color(0xFF654321),
      backgroundColor: Color(0xFFABCDEF),
    );
    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(
      first.copyWith(backgroundColor: const Color(0xFF010203)),
      const MiuixProgressIndicatorColors(
        foregroundColor: Color(0xFF123456),
        disabledForegroundColor: Color(0xFF654321),
        backgroundColor: Color(0xFF010203),
      ),
    );
  });

  testWidgets('progress source constructors retain MIUIX metrics and motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator.source(progress: 0.25),
                MiuixCircularProgressIndicator.source(progress: 0.5),
                MiuixProgressIndicator.source(circular: true),
                MiuixInfiniteProgressIndicator.source(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
          .height,
      6,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-circular-progress')).first,
      ),
      const Size.square(30),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
      const Size.square(20),
    );
    expect(debugMiuixCircularIndeterminateSweepDegrees(0), 30);
    expect(debugMiuixCircularIndeterminateSweepDegrees(.5), 120);
    expect(debugMiuixCircularIndeterminateSweepDegrees(1), 30);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-linear-progress')))
          .getSemanticsData()
          .role,
      SemanticsRole.progressBar,
    );
    final finiteRange = tester
        .getSemantics(
          find.byKey(const ValueKey('miuix-circular-progress')).first,
        )
        .getSemanticsData();
    expect(finiteRange.role, SemanticsRole.progressBar);
    expect(finiteRange.value, '50%');
    expect(finiteRange.minValue, '0');
    expect(finiteRange.maxValue, '1');
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('miuix-circular-progress')).last,
          )
          .getSemanticsData()
          .role,
      SemanticsRole.loadingSpinner,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress geometry and clocks follow HyperOS tokens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              progressLinearHeight: 9,
              progressCircularSize: 38,
              progressCircularStrokeWidth: 5,
              progressInfiniteSize: 26,
              progressInfiniteStrokeWidth: 3,
              progressOrbitingDotSize: 4,
              progressLinearMotion: Duration(milliseconds: 2000),
              progressCircularRotationMotion: Duration(milliseconds: 800),
              progressCircularSweepMotion: Duration(milliseconds: 1600),
              progressOrbitMotion: Duration(milliseconds: 400),
            ),
          ),
          child: const Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(),
                MiuixCircularProgressIndicator(),
                MiuixInfiniteProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
          .height,
      9,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-circular-progress'))),
      const Size.square(38),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
      const Size.square(26),
    );

    dynamic linearPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-linear-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic circularPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-circular-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic orbitPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-infinite-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    await tester.pump(const Duration(milliseconds: 200));
    expect(linearPainter().animation, closeTo(.1, .001));
    expect(circularPainter().rotation, closeTo(.25, .001));
    expect(circularPainter().sweepProgress, closeTo(.125, .001));
    expect(orbitPainter().animation, closeTo(.5, .001));
  });

  testWidgets('progress indicators safely freeze non-positive theme clocks', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              progressLinearMotion: Duration(milliseconds: -1),
              progressCircularRotationMotion: Duration.zero,
              progressCircularSweepMotion: Duration(milliseconds: -2),
              progressOrbitMotion: Duration.zero,
            ),
          ),
          child: const Scaffold(
            body: Column(
              children: [
                MiuixLinearProgressIndicator(),
                MiuixCircularProgressIndicator(),
                MiuixInfiniteProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );

    dynamic painterFor(Key key) => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(key),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    await tester.pump(const Duration(seconds: 3));
    expect(painterFor(const ValueKey('miuix-linear-progress')).animation, .5);
    expect(painterFor(const ValueKey('miuix-circular-progress')).rotation, 0);
    expect(
      painterFor(const ValueKey('miuix-circular-progress')).sweepProgress,
      .5,
    );
    expect(painterFor(const ValueKey('miuix-infinite-progress')).animation, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('indeterminate progress freezes when animations are disabled', (
    tester,
  ) async {
    var reduceMotion = false;
    late StateSetter updateFixture;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateFixture = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: const Column(
                  children: [
                    MiuixLinearProgressIndicator(),
                    MiuixCircularProgressIndicator(),
                    MiuixInfiniteProgressIndicator(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    dynamic linearPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-linear-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic circularPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-circular-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;
    dynamic orbitPainter() => tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-infinite-progress')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter;

    // Prove the ordinary mode is genuinely in flight before changing the
    // inherited accessibility setting. This catches implementations that only
    // read MediaQuery during init and leave already-running tickers alive.
    await tester.pump(const Duration(milliseconds: 137));
    expect(linearPainter().animation, isNot(.5));
    expect(circularPainter().rotation, isNot(0));
    expect(orbitPainter().animation, isNot(0));

    updateFixture(() => reduceMotion = true);
    await tester.pump();
    expect(linearPainter().animation, .5);
    expect(circularPainter().rotation, 0);
    expect(circularPainter().sweepProgress, .5);
    expect(orbitPainter().animation, 0);

    // A long pump must not restart any autonomous cycle. Loading semantics are
    // intentionally retained because motion preference does not change state.
    await tester.pump(const Duration(seconds: 3));
    expect(linearPainter().animation, .5);
    expect(circularPainter().rotation, 0);
    expect(circularPainter().sweepProgress, .5);
    expect(orbitPainter().animation, 0);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-infinite-progress')))
          .getSemanticsData()
          .role,
      SemanticsRole.loadingSpinner,
    );

    updateFixture(() => reduceMotion = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 137));
    expect(linearPainter().animation, isNot(.5));
    expect(circularPainter().rotation, isNot(0));
    expect(orbitPainter().animation, isNot(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress color factory resolves theme channels and overrides', (
    tester,
  ) async {
    late MiuixProgressIndicatorColors resolved;
    late Color expectedBackground;
    late Color expectedDisabled;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              expectedBackground = Theme.of(
                context,
              ).colorScheme.secondaryContainer;
              expectedDisabled = MiuixSemanticColors.of(
                context,
              )['disabledPrimarySlider'];
              resolved = MiuixProgressIndicatorDefaults.progressIndicatorColors(
                context,
                foregroundColor: const Color(0xFF102030),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(resolved.foregroundColor, const Color(0xFF102030));
    expect(resolved.disabledForegroundColor, expectedDisabled);
    expect(resolved.backgroundColor, expectedBackground);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress indicators expose source sizing colors and physical rounding',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const colors = MiuixProgressIndicatorColors(
        foregroundColor: Color(0xFF123456),
        disabledForegroundColor: Color(0xFF654321),
        backgroundColor: Color(0xFFABCDEF),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Column(
                children: [
                  MiuixLinearProgressIndicator(
                    value: .25,
                    colors: colors,
                    height: 7,
                  ),
                  MiuixCircularProgressIndicator(
                    value: .5,
                    colors: colors,
                    size: 31,
                    strokeWidth: 5,
                  ),
                  MiuixInfiniteProgressIndicator(
                    color: Color(0xFF2468AC),
                    size: 21,
                    strokeWidth: 3,
                    orbitingDotSize: 2.5,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Compose rounds the modifier's measured dp size to a physical pixel,
      // while the Canvas stroke and dot values remain floating-point dp.
      expect(
        tester
            .getSize(find.byKey(const ValueKey('miuix-linear-progress')))
            .height,
        18 / 2.625,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('miuix-circular-progress'))),
        const Size.square(81 / 2.625),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('miuix-infinite-progress'))),
        const Size.square(55 / 2.625),
      );
      expect(colors.foreground(), const Color(0xFF123456));
      expect(colors.foreground(enabled: false), const Color(0xFF654321));
      final semantics = tester
          .getSemantics(find.byKey(const ValueKey('miuix-linear-progress')))
          .getSemanticsData();
      expect(semantics.value, '25%');
      expect(semantics.minValue, '0');
      expect(semantics.maxValue, '1');
      expect(semantics.role, SemanticsRole.progressBar);
      expect(tester.takeException(), isNull);
    },
  );
}
