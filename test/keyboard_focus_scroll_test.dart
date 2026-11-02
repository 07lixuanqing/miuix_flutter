/// 输入焦点通过 MIUIX 滚动物理自动避开软键盘，不改写文本或选区。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  for (final width in [320.0, 600.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final source in [false, true]) {
        // 使用真实 MiuixScaffold、默认弹簧物理和真实 EditableText。
        // 只改变平台键盘遮挡量，不调用 ensureVisible 或跳改滚动位置。
        // 字段在键盘打开前可点，打开后若没有自动滚动就会完全被挡住。
        testWidgets(
          'keyboard reveals caret $width scale=$scale source=$source',
          (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            addTearDown(() {
              tester.view.reset();
              tester.platformDispatcher.clearTextScaleFactorTestValue();
            });
            final input = TextEditingController(text: '09:00');
            final focus = FocusNode();
            final scroll = ScrollController();
            await tester.pumpWidget(
              MaterialApp(
                scrollBehavior: const MiuixScrollBehavior(
                  showScrollbars: false,
                ),
                home: MiuixTheme(
                  child: MiuixScaffold(
                    body: ListView(
                      controller: scroll,
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 420),
                        source
                            ? MiuixTextField.source(
                                controller: input,
                                label: '开始时间',
                                singleLine: true,
                                interactionSource: focus,
                              )
                            : MiuixTextField(
                                controller: input,
                                label: '开始时间',
                                singleLine: true,
                                focusNode: focus,
                              ),
                        const SizedBox(height: 800),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byType(EditableText));
            await tester.pumpAndSettle();
            expect(focus.hasFocus, isTrue);
            final selection = input.selection;
            // 保留焦点状态，旧缺陷将其留在可视区外时仍可测量光标。
            final state = tester.state<EditableTextState>(
              find.byType(EditableText),
            );
            final before = tester.getRect(find.byType(EditableText));
            expect(before.top, greaterThan(400));
            expect(before.bottom, lessThan(800));
            // 400 像素键盘缩短实际 Scaffold viewport，框架发出光标显示请求。
            // 该请求必须越过输入框内部 Scrollable，推进外层列表。
            tester.view.viewInsets = const FakeViewPadding(bottom: 400);
            await tester.pumpAndSettle();
            final render = state.renderEditable;
            final local = render.getLocalRectForCaret(input.selection.extent);
            final bottom = render.localToGlobal(local.bottomRight).dy;
            final top = render.localToGlobal(local.topLeft).dy;
            expect(bottom, lessThanOrEqualTo(400));
            expect(top, greaterThanOrEqualTo(0));
            expect(scroll.offset, greaterThan(0));
            expect(input.text, '09:00');
            expect(input.selection, selection);
            expect(focus.hasFocus, isTrue);
            expect(tester.takeException(), isNull);
            // 先卸载渲染树再释放由用例拥有的控制器。
            await tester.pumpWidget(const SizedBox());
            input.dispose();
            focus.dispose();
            scroll.dispose();
          },
        );
      }
    }
  }
}
