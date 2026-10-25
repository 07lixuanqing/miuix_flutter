// MaterialApp 提供方向性、平台主题和测试所需的默认环境。
import 'package:flutter/material.dart';
// 使用 Flutter 指针序列，经过实际手势竞争与动画调度。
import 'package:flutter_test/flutter_test.dart';
// 仅从公共入口导入，确保下游应用获得相同修复。
import 'package:flutter_miuix/flutter_miuix.dart';

// 读取布局位置而非截图颜色，能区分反向移动与仍停在端点。
// 直接使用公开控件，避免只测试一个没有接入手势的算法替身。
double _thumbLeft(WidgetTester tester, Finder thumb) => tester
    // 选择滑块最近的定位节点，不读取外围设置行的位置。
    .widget<Positioned>(
      find.ancestor(of: thumb, matching: find.byType(Positioned)).first,
    )
    .left!;

// 多帧运动先越过手势识别阈值，再制造足够多的端点外移动。
// 本组检查往返端点；逐帧跟随由 tracking 测试单独覆盖。
Future<void> _overdrag(
  WidgetTester tester,
  TestGesture gesture,
  double direction,
) async {
  // 十帧共移动 100dp，明显超过 21dp 的逻辑轨道。
  for (var i = 0; i < 10; i++) {
    // 保持纵向分量为零，避免父容器滚动干扰方向判断。
    await gesture.moveBy(Offset(direction * 10, 0));
    // 帧间隔接近常用刷新周期，而非一次瞬移完成手势。
    await tester.pump(const Duration(milliseconds: 16));
  }
  // 留足弹簧收敛时间，断言不依赖运动中间帧。
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  // 两种初始状态分别覆盖右滑后左滑、左滑后右滑。
  // 减少动态效果时也必须采用相同的端点与提交规则。
  for (final initial in [false, true]) {
    for (final reduced in [false, true]) {
      testWidgets('repeated reversal initial=$initial reduced=$reduced', (
        tester,
      ) async {
        // 业务状态只在松手回调时改变，拖动期间记录所有提交。
        // 使用真实父组件重建，覆盖受控开关的完整调用方式。
        var value = initial;
        final commits = <bool>[];
        // 显式覆盖减少动态效果设置，测试不依赖主机偏好。
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: MiuixTheme(
                child: StatefulBuilder(
                  builder: (context, setState) => Center(
                    // 只放一个滑块，后续按键查找必须唯一命中。
                    child: MiuixSwitch(
                      value: value,
                      onChanged: (next) {
                        // 同时检查回调次数与父组件提供的新状态。
                        commits.add(next);
                        // 模拟下游受控组件在回调后接受新状态。
                        setState(() => value = next);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // 几何参数来自公开约定，测试不另造一套轨道尺寸。
        final direction = initial ? -1.0 : 1.0;
        // 原端点取决于父状态，不能固定假设起点在左边。
        final origin = initial
            ? MiuixSwitchDefaults.checkedThumbOffset
            : MiuixSwitchDefaults.uncheckedThumbOffset;
        final opposite = initial
            // 与起点相反的目标端点用于检查完整往返范围。
            ? MiuixSwitchDefaults.uncheckedThumbOffset
            : MiuixSwitchDefaults.checkedThumbOffset;
        // 从滑块内部开始，符合控件只允许滑块拖动的命中区域。
        final thumb = find.byKey(const ValueKey('miuix-switch-thumb'));
        // 每个测试只创建这一条指针，反向期间不释放手指。
        final gesture = await tester.startGesture(tester.getCenter(thumb));

        // 第一次越界后的小幅反向应立刻移动 10dp。
        // 全程不抬手，避免新手势清零掩盖旧的累计位移问题。
        await _overdrag(tester, gesture, direction);
        // 先确认确实到达端点，再检测反向响应。
        expect(_thumbLeft(tester, thumb), closeTo(opposite, .1));
        await gesture.moveBy(Offset(-10 * direction, 0));
        // 处理输入后的第一帧应已经反向移动。
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        // 容差仅覆盖弹簧收敛的小数误差，远小于预期 5dp 位移。
        expect(
          _thumbLeft(tester, thumb),
          // 反向位移与手指一致，不能靠等待动画收敛来过测。
          closeTo(opposite - 10 * direction, .1),
        );

        // 反向越过起点后再向前，起点同样不能积压不可见位移。
        // 连续往返多次，确保修复不只是第一次反向有效。
        for (var round = 0; round < 3; round++) {
          // 交替制造左右端点越界，检查两侧都丢弃多余位移。
          await _overdrag(tester, gesture, -direction);
          expect(_thumbLeft(tester, thumb), closeTo(origin, .1));
          // 离开起点也必须立即响应，不能只修复目标端点。
          await gesture.moveBy(Offset(10 * direction, 0));
          await tester.pump();
          // 所有普通动画断言都读取收敛位置。
          await tester.pump(const Duration(milliseconds: 400));
          expect(
            _thumbLeft(tester, thumb),
            closeTo(origin + 10 * direction, .1),
          );
          await _overdrag(tester, gesture, direction);
          // 再次到达对端，检查多次往返没有累计误差。
          expect(_thumbLeft(tester, thumb), closeTo(opposite, .1));
          expect(commits, isEmpty);
          // 手指按下时，视觉移动不能提前改动父级业务值。
          expect(value, initial);
        }

        // 停在另一端松手只提交一次，并由父状态驱动最终端点。
        await gesture.up();
        // 回调驱动的父级重建和复位弹簧均完成后再检查。
        await tester.pumpAndSettle();
        expect(commits, [!initial]);
        // 不仅检查次数，也检查提交的实际布尔方向。
        expect(value, !initial);
        // 父值变化后，视觉仍须落在已提交端点。
        expect(_thumbLeft(tester, thumb), closeTo(opposite, .1));

        // 第二次从新状态出发，往返后回到原处松手应不提交。
        // 这同时验证上次手势的位移不会泄漏到下次手势。
        final returning = await tester.startGesture(tester.getCenter(thumb));
        // 新手势的起点是上一次已提交的位置。
        await _overdrag(tester, returning, -direction);
        await _overdrag(tester, returning, direction);
        // 回到新起点时尚未松手，也应位于完整端点。
        expect(_thumbLeft(tester, thumb), closeTo(opposite, .1));
        await returning.up();
        // 等待可能产生的错误回调，防止只检查同步瞬间。
        await tester.pumpAndSettle();
        expect(commits, [!initial]);
        // 未触发第二次提交，说明返回起点没有改变设置。
        // 同时检查框架异常，覆盖布局和手势生命周期错误。
        expect(tester.takeException(), isNull);
      });
    }
  }
}
