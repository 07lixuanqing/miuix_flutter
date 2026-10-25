import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 真实 ScrollPosition 可在布局校正边界时发出结束/无指针更新通知。
// 在 LayoutBuilder 发送公开通知以稳定复现该时序，不依赖一次偶然的 fling。
// 实际 MiuixScaffold 必须订阅同一个 behavior，才能检测同步 setState 错误。
// 不用空监听器替代 Scaffold，也不捕获并丢弃框架异常。
// 旧实现会报告祖先 Scaffold 在子级 LayoutBuilder 布局中请求重建。
// 结束通知走零时长吸附，无指针更新走恢复位置，两条路径分别验证。
// 修正只改变通知阶段，不能丢掉折叠端点、内容偏移或共享状态通知。
// 预期不依赖控件私有测量数值，折叠后的分数一仍是公开契约。
// 固定 metrics 只用于时序夹具，不声称复现某个 Android 厂商的滚动引擎。
// 测试没有修改字体、截图或 golden 基线来绕开错误。
// 每轮创建独立行为，两个分支不共享定时器或滚动存储。
// 帧后通知读取最终值，不能保留一份旧 ScrollMetrics 延迟覆盖新状态。
// 正常手势的同步更新仍由既有拖动和动作呈现用例覆盖。
// 这里只要求布局阶段不能通知重建，不把所有输入都强制延迟一帧。
// 判定使用调度器公开阶段，不能靠取消所有监听器让错误消失。
void main() {
  for (final end in [true, false]) {
    testWidgets('top bar accepts layout scroll notifications end=$end', (
      tester,
    ) async {
      // 零时长吸附模拟减少动态效果，旧实现会在布局阶段立即改变端点。
      // 初始值取中间位置，避免恰好在端点时提前返回掩盖问题。
      final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero)
        ..setCollapseFraction(.6);
      addTearDown(behavior.dispose);
      var sent = false;
      final phases = <SchedulerPhase>[];
      // 两个公开监听器在发送通知前注册，确保不会漏掉错误的同步发布。
      // 同时记录公开状态和 behavior 的通知；两种订阅都不能在布局中重建。
      behavior.addListener(
        () => phases.add(SchedulerBinding.instance.schedulerPhase),
      );
      behavior.state.addListener(
        () => phases.add(SchedulerBinding.instance.schedulerPhase),
      );
      await tester.pumpWidget(
        // 主题与 Scaffold 均为真实组件，通知沿正常父级分发链路传播。
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              topBar: MiuixTopAppBar(title: '示例标题', scrollBehavior: behavior),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  // 只发送一次，后续由控件正常完成吸附与重建，不能由测试修正状态。
                  // 公共固定 metrics 代表一条确实可滚动的列表。
                  if (!sent) {
                    // 标记先置位，防止正常帧后重建再次发送同一事件造成无限循环。
                    sent = true;
                    final metrics = FixedScrollMetrics(
                      // 范围明确非空，避免“无内容就展开”的早退分支掩盖吸附。
                      minScrollExtent: 0,
                      maxScrollExtent: 1000,
                      pixels: end ? 0 : 120,
                      // 更新分支离开顶部，才会实际改变 contentOffset。
                      viewportDimension: 400,
                      axisDirection: AxisDirection.down,
                      devicePixelRatio: 1,
                    );
                    // 类型分别走 settle 与 syncMetrics，覆盖两个实际错误入口。
                    final notification = end
                        ? ScrollEndNotification(
                            metrics: metrics,
                            context: context,
                          )
                        : ScrollUpdateNotification(
                            metrics: metrics,
                            context: context,
                            scrollDelta: 120,
                          );
                    notification.dispatch(context);
                    // dispatch 同步返回后，框架仍处于本次真实布局阶段。
                  }
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );
      // pumpWidget 已经历一次真实布局；不能只检查最终数值而忽略阶段异常。
      expect(sent, isTrue);
      // 先检查首帧再等待稳定，避免后续错误被正常重建掩盖。
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(phases, isNotEmpty);
      // 空通知列表不能算成功；至少要向真正订阅者交付最终状态。
      expect(phases, isNot(contains(SchedulerPhase.persistentCallbacks)));
      // 延迟发布不能丢掉最终折叠和内容位置；两种通知的预期独立给出。
      expect(behavior.collapseFraction, 1);
      // 两个分支都从中间状态吸附到折叠端，不能以保持原值避免异常。
      if (!end) expect(behavior.contentOffset, -120);
      // 内容偏移保留符号，不能误把正的列表位置当作正向顶栏偏移。
      // 先移除实际宿主再销毁共享行为，避免 teardown 自己制造订阅悬挂。
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
