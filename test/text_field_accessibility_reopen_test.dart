import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 触摸手势交给选择委托后，辅助功能仍须能激活真正的文本编辑节点。
// 不调用组件私有方法；动作通过框架 SemanticsOwner 分发。
void main() {
  // 三项标志各自独立，八种组合可以检出只为普通可编辑字段补动作的遗漏。
  // 密码的输入动作与普通文字一致，明文暴露策略则继续由原编辑器负责。
  for (final obscure in [false, true]) {
    // 只读和禁用不是同一状态：只读保留文字选择，禁用不接纳激活。
    // 两种状态也可能同时存在，禁用约束必须优先。
    for (final readOnly in [false, true]) {
      for (final enabled in [false, true]) {
        // 名称保留全部维度，失败日志能定位具体状态而无需读取测试截图。
        // 每个组合独立挂载，不继承上一例的焦点和输入连接。
        testWidgets('accessible input $obscure $readOnly $enabled', (
          tester,
        ) async {
          final semantics = tester.ensureSemantics();
          try {
            // 非空草稿可区分真实编辑值与装饰层的空语义壳。
            // 使用中文同时避免用空字符串掩盖激活时清空草稿的回归。
            final text = TextEditingController(text: '保留原来的中文草稿');
            final focus = FocusNode();
            // 相同对象贯穿首次激活和连续恢复，不以销毁重建输入框代替恢复。
            // 测试结束由调用方释放，不改变控件对外部对象的所有权。
            addTearDown(text.dispose);
            addTearDown(focus.dispose);
            // 挂载正式公开组件，不以 Material TextField 替代被测试实现。
            // MiuixTheme 使用默认主题，避免额外页面封装补回丢失的动作。
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: MiuixTheme(
                    child: MiuixTextField(
                      controller: text,
                      focusNode: focus,
                      // 密码只支持单行，普通文本也用相同几何排除布局差异。
                      // 不设置初始选区，首次无障碍激活必须自己建立有效光标。
                      singleLine: true,
                      enabled: enabled,
                      readOnly: readOnly,
                      obscureText: obscure,
                    ),
                  ),
                ),
              ),
            );
            final owner =
                tester.binding.renderViews.single.owner!.semanticsOwner!;
            // 从当前视图的渲染 owner 取真实语义树，不使用已弃用的全局管线。
            // 测试只有一个视图；意外新增视图应立即失败，不能随意挑一个通过。
            // 定位文本编辑节点而非装饰层；密码标记和文本编辑语义必须共存。
            // 节点身份取自渲染树，不依赖固定编号或预设的 Android 坐标。
            SemanticsNode inputNode() {
              final candidates = <SemanticsNode>[];
              void visit(SemanticsNode current) {
                final data = current.getSemanticsData();
                // 同时要求编辑类型与非空值，单独判断 textField 会选中装饰节点。
                // 密码值允许是掩码，只根据节点标志检查是否保持保密语义。
                if (data.flagsCollection.isTextField && data.value.isNotEmpty) {
                  candidates.add(current);
                }
                current.visitChildren((child) {
                  // 遍历整棵子树，不能遇到装饰层就提前停止。
                  // 返回 true 表示继续访问同级节点，不是在宣布断言成功。
                  visit(child);
                  return true;
                });
              }

              // Scrollable 也有自己的语义边界，不能误把它当作可编辑文本节点。
              // 完整草稿值只属于真正的编辑节点；密码则必须保留掩码值。
              visit(owner.rootSemanticsNode!);
              // 相同草稿若出现两个编辑值，说明产生重复可操作语义，必须暴露。
              // 不能通过取第一个节点掩盖辅助功能需要重复聚焦的问题。
              expect(candidates, hasLength(1));
              return candidates.single;
            }

            var node = inputNode();
            expect(node.getSemanticsData().flagsCollection.isTextField, isTrue);
            expect(node.getSemanticsData().flagsCollection.isObscured, obscure);
            // 编辑点击仅对启用且非只读的字段开放，不能跨越调用方访问限制。
            // 单独检查动作存在性，避免只有实际触摸可用而读屏无入口。
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              enabled && !readOnly,
            );
            // 辅助功能焦点同样要显式存在，读屏可据此进入只读选择状态。
            // 只检查 Flutter FocusNode 获焦不足以证明这个系统入口可见。
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.focus),
              enabled,
            );
            // 禁用必须没有激活动作，不能借修复绕过 enabled 约束。
            // 只读可以获焦以选择文字，但不能因此弹出可编辑键盘。
            if (!enabled) return;
            owner.performAction(node.id, SemanticsAction.focus);
            await tester.pumpAndSettle();
            expect(focus.hasFocus, isTrue);
            expect(tester.testTextInput.isVisible, !readOnly);
            if (readOnly) return;
            // 同时覆盖辅助功能点击与焦点动作，系统可使用其中任一种恢复编辑。
            // hide 保留原焦点，不能先 unfocus 来回避已有焦点的失败场景。
            for (final action in [
              SemanticsAction.tap,
              SemanticsAction.focus,
              SemanticsAction.tap,
            ]) {
              // 隐藏输入法不提交表单、不发送 done，也不改变输入值。
              // 下一次动作必须恢复已有编辑器，不能创建一个空字段来重新获焦。
              tester.testTextInput.hide();
              expect(focus.hasFocus, isTrue);
              node = inputNode();
              owner.performAction(node.id, action);
              // 等待原控件动画和语义更新；不直接调用输入连接的 show 方法。
              // 重取节点后的动作编号属于本轮，避免复用已被框架回收的编号。
              await tester.pumpAndSettle();
              expect(tester.testTextInput.isVisible, isTrue);
              expect(text.text, '保留原来的中文草稿');
              // 框架恢复输入连接后应有可用选区，不能沿用初始化时的无效光标。
              // 密码仍按隐藏语义处理，动作不需要显示明文。
              expect(text.selection.isValid, isTrue);
            }
            // 动作处理期间的框架异常不能因最终键盘可见就被忽略。
            // 保留默认异常捕获，输入连接或语义更新失败都会使本例失败。
            expect(tester.takeException(), isNull);
          } finally {
            // 即使断言失败也释放语义句柄，不能污染下一项矩阵的起始状态。
            // 在测试体结束前释放，满足框架对辅助功能资源的检查。
            semantics.dispose();
          }
        });
      }
    }
  }
}
