import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 恢复标题高度和内容距离是两个公开操作，但不能互相读回过期值。
// 本例在真实布局阶段初始化，不用普通事件阶段掩盖延迟通知的问题。
// 只使用公开状态接口，不直接修改私有折叠字段。
// 采样在 initState 内完成，不能靠帧后的补偿掩盖当帧不一致。
// 真实 Scaffold 与标题栏参与布局，不使用一个假的同步模型代替。
// 高度比例和内容距离是两个独立状态，深列表不能被裁成标题行程。
// 所有数值来自控件 getter，而不是由测试复制一套恢复算法计算。
// 这里不包含日期、账号、网络或真实偏好资料。
class _RestoreHost extends StatefulWidget {
  const _RestoreHost({super.key, required this.writeContent});
  final bool writeContent;
  @override
  State<_RestoreHost> createState() => _RestoreHostState();
}

class _RestoreHostState extends State<_RestoreHost> {
  // 每例持有自己的控制器，不继承上一次测试的延迟通知。
  // 分别记录数值和通知阶段，正确终值不能替代安全时序。
  // 状态监听器只采样，不在布局中主动 setState 制造另一种错误。
  final behavior = MiuixTopAppBarScrollBehavior();
  final phases = <SchedulerPhase>[];
  final stateSnapshots = <(double, double)>[];
  late double firstStateFraction, fractionAfterContent;
  @override
  void initState() {
    super.initState();
    // 监听器只记录事实，不在布局中主动调用 setState。
    // 组件自身的通知发布应安全延后，实际状态字段却必须立即一致。
    behavior.addListener(
      () => phases.add(SchedulerBinding.instance.schedulerPhase),
    );
    behavior.state.addListener(
      () => stateSnapshots.add((
        behavior.state.collapsedFraction,
        behavior.state.contentOffset,
      )),
    );
    // 非端点比例可检出只修复完全展开或完全折叠的情况。
    // 内容恢复故意放在高度恢复之后，复现旧公开状态覆盖新高度的路径。
    // 调用普通 API，不访问任何用于绕开生产分发的测试后门。
    behavior.setCollapseFraction(.65);
    firstStateFraction = behavior.state.collapsedFraction;
    if (widget.writeContent) behavior.state.contentOffset = -230;
    fractionAfterContent = behavior.collapseFraction;
  }

  @override
  // 测试失败也通过产品 dispose 释放 ticker，不直接清空内部监听器。
  // 不保留跨用例全局状态，避免排队的旧通知污染下一场景。
  // 组件销毁后的迟到回调仍遵循控件自己的存活检查。
  void dispose() {
    behavior.dispose();
    super.dispose();
  }

  @override
  // 正文不发送滚动通知，避免 metrics 恰好纠正错误状态而假通过。
  // 标题明确启用可折叠模式，小标题固定零高度不能代替这个场景。
  // 布局仍由实际控件完成，不调用私有的尺寸测量方法。
  // 真实长列表的首帧位置由应用专项回归另行检查。
  Widget build(BuildContext context) => MiuixScaffold(
    topBar: MiuixTopAppBar(
      title: '恢复后的完整页面标题',
      large: true,
      scrollBehavior: behavior,
    ),
    body: const SizedBox.expand(child: ColoredBox(color: Colors.white)),
  );
}

void main() {
  for (final content in [false, true]) {
    testWidgets(
      'layout restoration keeps hoisted fields coherent content=$content',
      (tester) async {
        final key = GlobalKey<_RestoreHostState>();
        // 框架构建子树时处于 persistentCallbacks，进入控件的通知延迟分支。
        // 初始化后立即采样，不能先 pump 下一帧再检查已经纠正的状态。
        await tester.pumpWidget(
          MiuixTheme(
            child: MaterialApp(
              home: _RestoreHost(key: key, writeContent: content),
            ),
          ),
        );
        // 读取的是初始化阶段保存的值，不是重新从已经纠正后的组件取值。
        // 只恢复高度与连续恢复两个字段分开验证，两条路径都不能丢通知。
        // 同一字段没有变化时，待发布标记仍应保证一次真正的帧后通知。
        final state = key.currentState!;
        // 第一次 setter 返回时，公开 state 不能仍是展开的旧高度。
        expect(state.firstStateFraction, closeTo(.65, 1e-9));
        expect(state.fractionAfterContent, closeTo(.65, 1e-9));
        await tester.pumpAndSettle();
        expect(state.behavior.collapseFraction, closeTo(.65, 1e-9));
        expect(state.behavior.state.collapsedFraction, closeTo(.65, 1e-9));
        if (content) {
          // 第二次内容恢复不能覆盖刚保存的高度，且两份状态应一致。
          expect(state.behavior.contentOffset, -230);
          expect(state.behavior.state.contentOffset, -230);
          expect(state.stateSnapshots.single, (.65, -230.0));
        } else {
          // 当字段已经提前同步，帧后的实际通知仍不能被同值去重吞掉。
          expect(state.stateSnapshots, hasLength(1));
          expect(state.stateSnapshots.single.$1, closeTo(.65, 1e-9));
        }
        // 不能靠完全关闭通知来避免布局错误，订阅者最终仍需得到更新。
        // 通知不得发布在 persistentCallbacks，否则会导致构建期间 setState。
        // 事件阶段的同步合同由下面的独立用例保留。
        expect(state.phases, isNotEmpty);
        expect(
          state.phases,
          isNot(contains(SchedulerPhase.persistentCallbacks)),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  // 布局保护不能改变普通手指事件中的同步反馈。
  // 每次真正变化应发布一次，延迟标记不能导致重复回执。
  // 这里不推进 Widget 帧来等待结果，直接检查原有事件阶段合同。
  // 同时核对内部和公开状态，计数正确不代表数值必然正确。
  test(
    'outside layout setters still publish synchronously once per change',
    () {
      final behavior = MiuixTopAppBarScrollBehavior();
      // 纯状态测试也主动释放资源，避免与 Widget 用例共享排队任务。
      // 两次写入代表两次不同变化，计数必须精确匹配。
      addTearDown(behavior.dispose);
      var calls = 0;
      behavior.state.addListener(() => calls++);
      // 原事件阶段合同不变，不能为了布局安全把所有通知都变成异步。
      behavior.setCollapseFraction(.5);
      expect(calls, 1);
      behavior.state.contentOffset = -210;
      expect(calls, 2);
      expect(behavior.collapseFraction, .5);
      expect(behavior.contentOffset, -210);
    },
  );
}
