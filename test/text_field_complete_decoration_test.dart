/// 长标签与提示的完整阅读回归：实际段落、编辑器位置和输入状态同时核对。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

const labelText = '重复间隔与有效次数：请完整核对开始日期、结束条件以及周一至周五不按调休的规则';

// 页面只提供主题和有限宽度，不替换真实输入框或渲染对象。
// 大字号来自 MediaQuery，与应用实际系统缩放走相同控件分支。
// 输入本身保持单行，装饰文字换行不能偷偷改变 maxLines 契约。
// 普通与 source API 共享实现，分别验证实际转接后的效果。
Widget page(
  TextEditingController input,
  double width, {
  bool source = false,
  String? label = labelText,
  String? hint,
  FocusNode? focus,
}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
      child: MiuixTheme(
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: width,
                child: source
                    ? MiuixTextField.source(
                        controller: input,
                        label: label ?? '',
                        interactionSource: focus,
                        singleLine: true,
                        trailingIcon: const Icon(Icons.event),
                      )
                    : MiuixTextField(
                        controller: input,
                        label: label,
                        hint: hint,
                        focusNode: focus,
                        singleLine: true,
                      ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

// 渲染段落必须完整，不以 widget 的原始字符串存在代替画面阅读。
// 背景也要包含整段文字，防止只移除省略号却仍被固定高度挡住。
// 浮动状态的编辑器必须在标签下面，不能将完整标签覆盖到输入值上。
// 这些检查互补，单独无框架异常不能证明文字没有被省略。
void readable(WidgetTester tester, String text, {required bool entered}) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  expect(paragraph.didExceedMaxLines, isFalse);
  final label = tester.getRect(find.text(text));
  final field = tester.getRect(find.byType(MiuixTextField));
  expect(label.top, greaterThanOrEqualTo(field.top - .5));
  expect(label.bottom, lessThanOrEqualTo(field.bottom + .5));
  if (entered) {
    final editor = tester.getRect(find.byType(EditableText));
    expect(editor.top, greaterThanOrEqualTo(label.bottom - .5));
  }
  expect(tester.widget<EditableText>(find.byType(EditableText)).maxLines, 1);
  expect(tester.takeException(), isNull);
}

void main() {
  // 每例建立自己的文本控制器，不沿用上一个用例的选区或内容。
  // 窗口宽度大于字段，避免用父级横向溢出影响测量结论。
  // 240、320 和 600 覆盖窄字段、手机与平板分栏。
  // 空标签与输入后的浮动标签都需要完整显示。
  // source 模式还提供尾部图标，测量必须使用扣除插槽后的真实宽度。
  // 结束后卸载组件再释放控制器，避免遗留焦点或弹簧回调。
  for (final width in [240.0, 320.0, 600.0]) {
    for (final source in [false, true]) {
      for (final entered in [false, true]) {
        testWidgets(
          'complete label width=$width source=$source entered=$entered',
          (tester) async {
            tester.view.physicalSize = Size(width + 40, 1000);
            tester.view.devicePixelRatio = 1;
            final input = TextEditingController(text: entered ? '09:00' : '');
            await tester.pumpWidget(page(input, width, source: source));
            await tester.pumpAndSettle();
            readable(tester, labelText, entered: entered);
            await tester.pumpWidget(const SizedBox());
            input.dispose();
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          },
        );
      }
    }
    // 没有 label 的长提示同样属于操作说明，不能继续单行省略。
    // 输入为空时提示完整，输入后其隐藏语义不改变。
    // 提示与空编辑器按占位方式重叠，不要求空光标挪到提示下方。
    testWidgets('complete hint width=$width', (tester) async {
      tester.view.physicalSize = Size(width + 40, 1000);
      tester.view.devicePixelRatio = 1;
      final input = TextEditingController();
      await tester.pumpWidget(page(input, width, label: null, hint: labelText));
      await tester.pumpAndSettle();
      readable(tester, labelText, entered: false);
      await tester.enterText(find.byType(EditableText), '12:34');
      await tester.pumpAndSettle();
      expect(find.text(labelText), findsNothing);
      expect(input.text, '12:34');
      await tester.pumpWidget(const SizedBox());
      input.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
  for (final source in [false, true]) {
    // 两个汉字也可能因字号增大超过原浮动带高度。
    // 该测试不依赖多行，单独发现标签与值垂直重叠。
    testWidgets('short floating label has readable band source=$source', (
      tester,
    ) async {
      final input = TextEditingController(text: '09:00');
      await tester.pumpWidget(page(input, 320, source: source, label: '日期'));
      await tester.pumpAndSettle();
      readable(tester, '日期', entered: true);
      await tester.pumpWidget(const SizedBox());
      input.dispose();
    });
    // 宽度变化会重新测量装饰，但不能重新建立一份编辑器丢掉选区。
    // 同一个 FocusNode 和控制器贯穿宽、窄、再宽三个布局。
    // 先取得焦点，再改变宽度，观察真实输入仍然能够继续。
    // 选择器、长按和键盘行为由原组件处理，没有测试专用替身。
    testWidgets('readable reflow preserves focus and editing source=$source', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1;
      final input = TextEditingController(text: '09:00');
      final focus = FocusNode();
      for (final width in [600.0, 240.0, 600.0]) {
        await tester.pumpWidget(
          page(input, width, source: source, focus: focus),
        );
        await tester.pumpAndSettle();
        focus.requestFocus();
        await tester.pumpAndSettle();
        readable(tester, labelText, entered: true);
        expect(focus.hasFocus, isTrue);
      }
      await tester.enterText(find.byType(EditableText), '12:34');
      await tester.pumpAndSettle();
      expect(input.text, '12:34');
      expect(focus.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      input.dispose();
      focus.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }
}
