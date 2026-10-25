part of '../miuix_flutter_test.dart';

// 输入框独立注册，避免选择与进度测试继续增长。
void _registerTextFieldTests() {
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
}
