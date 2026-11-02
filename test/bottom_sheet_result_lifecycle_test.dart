import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 确认弹层后立即应用主题，结果 Future 会早于退出动画完成。
// 测试重建尚在退出中的真实弹层，不能用先等待动画结束掩盖提前释放。
// 外部行为控制器与内部自建控制器都需要覆盖。
// 减少动态效果分支也必须遵守同样的返回值与所有权约束。
// 不依赖私有手势控制器，公共 show/确认/完成回调足以暴露原问题。
void main() {
  // 外部控制器必须仍可使用，自建控制器则只能由本次路由释放。
  for (final supplied in [false, true]) {
    // 零时长动画也要等待真实卸载，不允许根据时长猜测释放时机。
    for (final reduceMotion in [false, true]) {
      testWidgets(
        'bottom sheet result rebuild supplied=$supplied reduced=$reduceMotion',
        (tester) async {
          // 使用窄屏，返回结果后还会放大字号以触发布局依赖重建。
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          // 一次返回结果同时改变亮暗与字号，迫使退出中的内容重建。
          final changed = ValueNotifier(false);
          // 不取得私有手势对象，避免测试依赖实现细节而绕过公开入口。
          final controller = supplied ? MiuixBottomSheetController() : null;
          // 每例独立记录请求与完成，不能用前一例的回调满足断言。
          var requested = 0, finished = 0;
          // 记录弹层 Future 的实际返回值，保持确认结果的原时序。
          int? result;
          // 主题宿主包围实际 Navigator，覆盖路由正在退出时的依赖通知。
          await tester.pumpWidget(
            ValueListenableBuilder<bool>(
              valueListenable: changed,
              builder: (_, dark, _) => MiuixTheme(
                // 使用正式主题，不以简化弹层替代真实玻璃、手势和布局树。
                data: MiuixThemeData.defaults(),
                child: MaterialApp(
                  // Material 主题变化模拟调用方自动应用新的外观设置。
                  theme: ThemeData(
                    brightness: dark ? Brightness.dark : Brightness.light,
                  ),
                  builder: (context, child) => MediaQuery(
                    // 原生动画设置是事实输入，不修改库的过渡时长来规避竞态。
                    data: MediaQuery.of(context).copyWith(
                      disableAnimations: reduceMotion,
                      textScaler: TextScaler.linear(dark ? 2 : 1),
                    ),
                    // 同一 Overlay 保持存活，不能通过重建整个 Navigator 清理控制器。
                    child: child!,
                  ),
                  home: Scaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        // 调用者拿到结果后马上更新依赖，而不是先等待退出动画。
                        onPressed: () async {
                          result = await MiuixBottomSheet.show<int>(
                            context: context,
                            controller: controller,
                            // 请求仅一次，程序确认和真正退出都会经过幂等保护。
                            onDismissRequest: () => requested++,
                            // 完成事件必须对应实际退出，不能与请求结果混用。
                            onDismissFinished: () => finished++,
                            child: Builder(
                              builder: (context) => TextButton(
                                onPressed: () => Navigator.of(context).pop(42),
                                // 确认是正式弹层内部动作，返回非空值以检查原有结果契约。
                                child: const Text('确认颜色'),
                              ),
                            ),
                          );
                          // 模拟调用方自动保存成功后立即应用主题和系统字号。
                          changed.value = true;
                        },
                        child: const Text('选择颜色'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('选择颜色'));
          // 首次等待只用于展开完成，保证后续确实覆盖一次完整退出。
          await tester.pumpAndSettle();
          // 通过实际确认动作返回结果，不从测试直接移除 Overlay。
          await tester.tap(find.text('确认颜色'));
          await tester.pump();
          // 用户结果不能为了延后资源释放而被拖到退出动画之后。
          expect(result, 42);
          // request 与 dispose 都能经过关闭路径，但不能重复通知调用方。
          expect(requested, 1);
          // 有动画时，完成回调必须等到路由退出，结果仍要立即可用。
          if (!reduceMotion) expect(finished, 0);
          // 再推进一帧，旧实现会在 AnimatedBuilder 更新监听器时抛错。
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.takeException(), isNull);
          await tester.pumpAndSettle();
          // 退出完成只回调一次，减少动态效果也不例外。
          expect(finished, 1);
          expect(find.text('确认颜色'), findsNothing);
          // 外部控制器不归弹层所有，弹层退出后调用者仍能修改它。
          controller?.allowDismiss = false;
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          // 最终由测试作为外部所有者释放，能发现内部提前或重复 dispose。
          controller?.dispose();
          // 关闭测试依赖源，避免下一种矩阵参数继承上一例的通知。
          changed.dispose();
        },
      );
    }
  }
}
