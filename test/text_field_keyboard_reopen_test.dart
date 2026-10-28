import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 系统返回收起键盘时，输入框可以继续持有焦点。
// 再点同一个输入框必须重新显示键盘，不能只重复 requestFocus。
// 这里使用框架输入测试口模拟系统隐藏，不伪造产品的焦点变化。
// Android 真正的边缘返回由 LoveStory 的设备脚本另行验收。
// 此处不直接调用组件私有方法，唤起必须由一次真实 Widget 点击产生。
// 首次获得焦点并不足以证明修复，失败发生在焦点已经存在的下一次点击。
// 相同字符位置的重复点击也要覆盖，选区不变不能成为漏发 show 的理由。
// 长按选择与系统输入法的真实组合保留独立设备验收，不由此用例代替。
void main() {
  for (final width in [360.0, 1024.0]) {
    // 不同宽度与字号使用同一份输入内容，不能以更短文本制造适配通过。
    // 每个矩阵项单独创建输入状态，避免上一例已显示的键盘造成假成功。
    for (final scale in [1.0, 2.0]) {
      for (final obscure in [false, true]) {
        testWidgets('focused field reopens keyboard $width $scale $obscure', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, 900);
          // 像素比固定后，测试点击位置与逻辑视口对应，无需按设备密度猜坐标。
          // 文字缩放仍走系统测试接口，保持正式组件自己的字号计算链。
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          // 用实际手机和平板宽度，不通过缩小文字规避窄屏布局。
          // 每例恢复视口与字号，不能让前一例的指标影响后一例。
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
          final text = TextEditingController(
            text: '往返返回后继续输入的长中文草稿，不能因重新弹出键盘被清空或改写',
          );
          final focus = FocusNode();
          // 外部传入对象覆盖调用方持有草稿的常见使用方式。
          // 由用例负责释放，组件不得因为收起键盘而销毁外部对象。
          addTearDown(text.dispose);
          addTearDown(focus.dispose);
          // 同一个 controller 与 FocusNode 跨越全部往返，不重建字段蒙混恢复。
          // 密码和普通文本共用这条合同，显隐差异不能改变唤起能力。
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: MiuixTheme(
                  child: MiuixTextField(
                    controller: text,
                    focusNode: focus,
                    singleLine: true,
                    obscureText: obscure,
                    leadingIcon: const Padding(
                      // 真实前缀占位能暴露只修复文本内部点击、留白仍失效的问题。
                      // 不给前缀配置自己的回调，以保持输入表面的普通点击语义。
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.edit),
                    ),
                  ),
                ),
              ),
            ),
          );
          final surface = find.byKey(
            const ValueKey('miuix-text-field-surface'),
          );
          await tester.tap(surface);
          // 首次点击仅建立输入连接；后面的隐藏与再次点击才构成回归动作。
          // 不关闭动画，等待现有动效稳定后再检查焦点和键盘状态。
          await tester.pumpAndSettle();
          expect(focus.hasFocus, isTrue);
          expect(tester.testTextInput.isVisible, isTrue);
          final original = text.text;
          // 持有 Element 身份，捕获先销毁输入框再建一个新输入框的伪恢复。
          // 草稿全文独立检查；只检查键盘可见会漏掉 controller 重置的问题。
          final editable = tester.element(find.byType(EditableText));
          // 交替点文本区域和前缀留白，整个输入表面都应可再次唤起。
          // 点回已有焦点不能靠先失焦、清空内容或替换 EditableText 实现。
          for (final prefix in [false, true, false]) {
            // hide 不发送 done、不改变 controller，也不主动撤销 FocusNode。
            // 连续三次保证重新显示不只是首次隐藏后偶然生效。
            tester.testTextInput.hide();
            expect(focus.hasFocus, isTrue);
            expect(tester.testTextInput.isVisible, isFalse);
            final rect = tester.getRect(surface);
            // 每轮重新读取控件边界，不能沿用大字号布局前的点击坐标。
            // 中间一次点击前缀留白，两次点击文本区域使用相同字符位置。
            await tester.tapAt(
              prefix ? Offset(rect.left + 8, rect.center.dy) : rect.center,
            );
            await tester.pumpAndSettle();
            expect(tester.testTextInput.isVisible, isTrue);
            expect(focus.hasFocus, isTrue);
            expect(text.text, original);
            expect(tester.element(find.byType(EditableText)), same(editable));
          }
          // 手势委托还须保留长按选字，不能靠屏蔽 EditableText 的交互蒙混唤起。
          // 密码遵守原有隐藏选择策略，普通文本单独检查实际非空选区。
          // 单测不直接修改 controller.selection，必须由长按识别链产生结果。
          // 选字后全文仍须保留，不能把选择范围当成新的输入内容。
          if (!obscure) {
            await tester.longPress(find.byType(EditableText));
            await tester.pumpAndSettle();
            expect(text.selection.isValid, isTrue);
            expect(text.selection.isCollapsed, isFalse);
            expect(text.text, original);
          }
          // 任何大字号溢出或构建阶段错误都要在这里暴露。
          // 字符串是完整长草稿；文本自身的横向滚动不等于丢失内容。
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
  for (final disabled in [false, true]) {
    testWidgets('readonly or disabled field does not open keyboard $disabled', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      // 只读仍允许选择文字，禁用则不响应点击；两者都不能显示输入键盘。
      // 修复不能绕过 readOnly 或 enabled，把所有控件强行变成可输入。
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiuixTheme(
              child: MiuixTextField(
                focusNode: focus,
                readOnly: !disabled,
                enabled: !disabled,
              ),
            ),
          ),
        ),
      );
      tester.testTextInput.hide();
      // 禁用例故意点击无响应表面，只关闭这一例预期的命中警告。
      // 其他场景仍保留命中诊断，焦点和键盘断言不因关闭警告而放宽。
      await tester.tap(
        find.byKey(const ValueKey('miuix-text-field-surface')),
        warnIfMissed: !disabled,
      );
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isFalse);
      expect(focus.hasFocus, !disabled);
      // 只读仍应能获取选择焦点，不能靠让字段完全失效来避免弹出键盘。
      // 禁用则必须保持无焦点，两者的区别需要独立断言。
      expect(tester.takeException(), isNull);
    });
  }
}
