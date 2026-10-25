// 逐帧检查拖动位置，不能用等待动画收敛的方式验证跟手性。
// 提供完整主题、方向性和指针宿主。
import 'package:flutter/material.dart';
// 帧时间由测试显式推进，不受主机刷新率影响。
import 'package:flutter_test/flutter_test.dart';
// 只调用公共组件，不把内部动画算法复制到测试中。
import 'package:flutter_miuix/flutter_miuix.dart';

// Positioned 是实际渲染位置，不读取控件内部目标值。
// 查找滑块最近的定位节点，避免拿外层居中容器当作位置。
double _left(WidgetTester tester) => tester
    .widget<Positioned>(
      // 找最近的定位祖先，按下缩放本身不参与水平端点计算。
      find
          .ancestor(
            of: find.byKey(const ValueKey('miuix-switch-thumb')),
            matching: find.byType(Positioned),
          )
          .first,
    )
    .left!;

void main() {
  // 覆盖两种起始状态及常见输入帧间隔，不假设每次拖动都等到下一次动画完成。
  // 开启态与关闭态分别覆盖，方向相反但应使用同一位移比例。
  for (final initial in [false, true]) {
    // 三个帧间隔同时覆盖密集输入和普通显示帧。
    // 这些是测试时钟间隔，不宣称手机实际以 240Hz 显示。
    for (final interval in [4, 8, 16]) {
      testWidgets('switch tracks every pointer frame $initial $interval', (
        tester,
      ) async {
        // 当前值只在正式回调中接受，不跟随视觉拖动提前改变。
        var value = initial;
        // 计数检查手指按下期间有没有提前提交。
        var commits = 0;
        // 保存父组件更新入口，用来模拟页面状态绑定刷新。
        late StateSetter rebuild;
        // 父组件重建时也必须保持正在进行的拖动，不能重启位置动画。
        // 直接使用受控 MiuixSwitch，覆盖回调后的真实重建。
        await tester.pumpWidget(
          MaterialApp(
            // 位置测试沿用正式主题，不能关闭动画伪装成修复。
            home: MiuixTheme(
              child: StatefulBuilder(
                builder: (context, setState) {
                  // 此处拿到的是父级状态，不操作开关内部私有字段。
                  rebuild = setState;
                  return Center(
                    // 每例只渲染一个滑块，后续几何查找必须唯一。
                    child: MiuixSwitch(
                      value: value,
                      // 回调同步接受新值，和常见设置绑定方式一致。
                      onChanged: (next) => setState(() {
                        // 每次真实提交只增加一次，拖动重绘不能增加。
                        commits++;
                        // 最终状态由父组件返回给控件，而非测试直接改控制器。
                        value = next;
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        // 端点采用控件公开尺寸约定，不依赖截图颜色判断。
        final origin = initial ? 25.0 : 4.0;
        // 把同一路径映射到左右两种方向，避免只修复右滑。
        final direction = initial ? -1.0 : 1.0;
        // 按下发生在实际滑块中心，满足现有拖动命中范围。
        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const ValueKey('miuix-switch-thumb'))),
        );
        // 第一次移动越过方向识别阈值，第一帧就应到达相同位移。
        // 移动量超过方向识别阈值，第一帧即可检查已接受的拖动。
        await gesture.moveBy(Offset(direction * 4, 0));
        // 只推进一个输入间隔，不能等待数百毫秒收敛。
        await tester.pump(Duration(milliseconds: interval));
        // 位移必须一比一，不接受旧实现减半后的近似结果。
        expect(_left(tester), closeTo(origin + direction * 4, .01));
        // 记录输入路径上一次位置，生成真实连续 MOVE 的差值。
        var position = 4.0;
        // 手指反向时会有轻微纵向偏移，不能把已开始的横拖重新判成滚动。
        var vertical = 0.0;
        // 固定路径覆盖两个端点和中间反向；每步只推进一个输入帧。
        // 首尾均为 4dp，使下一轮仍能接续同一条指针路径。
        // 路径包括两端、中间大幅反向和一个 dp 的微小反向。
        const route = <double>[
          6,
          9,
          12,
          18,
          21,
          20,
          19,
          15,
          10,
          5,
          1,
          0,
          1,
          2,
          4,
        ];
        // 一段按下事件内反复往返，不让新手势清零掩盖残留。
        for (var round = 0; round < 20; round++) {
          // 每一个输入目标都断言，不能只比较循环结束的端点。
          for (final target in route) {
            // 靠近按下位置时加入 4dp 纵向抖动，覆盖真实往返最易丢失的一段。
            final nextVertical = target <= 2 ? 4.0 : 0.0;
            // 差值按手指物理方向发送，目标值本身不直接写入组件。
            await gesture.moveBy(
              Offset(direction * (target - position), nextVertical - vertical),
            );
            // 累计纵向位置仅用于下一次输入，不改变横向预期。
            vertical = nextVertical;
            await tester.pump(Duration(milliseconds: interval));
            // 容差仅处理浮点坐标，不允许一个可见像素的追赶误差。
            expect(_left(tester), closeTo(origin + direction * target, .01));
            // 下一次移动仍沿同一条路径连续计算。
            position = target;
          }
          // 普通状态绑定重建不能让滑块重新追赶旧目标。
          // 模拟内容无关的父级刷新，不改变当前开关值。
          rebuild(() {});
          await tester.pump(Duration(milliseconds: interval));
          // 父级重建之后的位置不得重新开始弹簧运动。
          expect(_left(tester), closeTo(origin + direction * position, .01));
          // 按下期间无论往返多少次，业务回调都应为空。
          expect(commits, 0);
        }
        // 系统取消必须回到原设置，不能把半途中断当作松手提交。
        // 先移到另一端，确保取消不是只在起点测试。
        await gesture.moveBy(Offset(direction * 40, 0));
        await tester.pump(Duration(milliseconds: interval));
        // 直接发送 PointerCancel，覆盖系统抢占手势的路径。
        await gesture.cancel();
        // 回弹只用于结束后的复位，不参与前面的逐帧跟随判断。
        // 只有取消后的回弹才允许等待动画结束。
        await tester.pumpAndSettle();
        // 系统取消不能替用户确认相反状态。
        expect(value, initial);
        expect(commits, 0);
        // 回弹最终回到父级仍提供的原端点。
        expect(_left(tester), closeTo(origin, .01));
        // 同时检查手势生命周期与布局异常。
        expect(tester.takeException(), isNull);
      });
    }
  }

  // 单独覆盖动画未停稳时再次拖动，避免只测静止起点。
  testWidgets('drag picks up moving thumb and drops a disabled gesture', (
    tester,
  ) async {
    // 第二场景从关闭态开始，随后由外部值启动点击式过渡。
    var value = false;
    // 禁用切换独立于布尔值，用来模拟异步操作防重入。
    var enabled = true;
    var commits = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return Center(
                child: MiuixSwitch(
                  value: value,
                  enabled: enabled,
                  // 外部状态由场景控制，只统计是否错误提交旧手势。
                  onChanged: (_) => commits++,
                ),
              );
            },
          ),
        ),
      ),
    );
    // 先让外部值启动弹簧，随后在动画尚未结束时抓住滑块。
    // 使用正常父级更新启动原有弹簧，不直接控制动画时间线。
    rebuild(() => value = true);
    await tester.pump();
    // 先启动动画再推进 32ms，避免把未开始的第一帧误当运动中。
    // 此时应仍处于途中，尚未到新端点。
    await tester.pump(const Duration(milliseconds: 32));
    // 保存当前真实可见位置，下一步从这里接手。
    final grabbed = _left(tester);
    // 保证场景确实命中运动途中，否则测试没有覆盖意义。
    expect(grabbed, inExclusiveRange(4, 25));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('miuix-switch-thumb'))),
    );
    // 再次从滑块内部按下后沿相同逻辑位移移动。
    await gesture.moveBy(const Offset(4, 0));
    // 只给一个短输入帧，旧弹簧来不及通过收敛过测。
    await tester.pump(const Duration(milliseconds: 8));
    // 不允许抓取瞬间先跳到已提交端点再响应移动。
    expect(_left(tester), closeTo(grabbed + 4, .01));
    // 操作中禁用后必须清理临时位移，剩余指针事件不能提交。
    // 禁用后旧 MOVE 或 UP 失去提交资格。
    rebuild(() => enabled = false);
    await tester.pumpAndSettle();
    // 禁用应清理临时位移并显示父级实际值。
    expect(_left(tester), closeTo(25, .01));
    // 释放旧指针，确认不会补交一个迟到回调。
    await gesture.up();
    await tester.pumpAndSettle();
    expect(commits, 0);
    // 禁用中收到的 UP 也不能给父级补交一个改变请求。
  });
}
