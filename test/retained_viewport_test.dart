import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 记录真正进入 RenderBox 的布局次数，而不是只统计 Widget 存在与否。
// 子列表仍使用正常懒加载，不拿预先画好的图片替代实际列表。
// 探针在子树外层，列表是否执行布局都必须经过它。
// 仅尺寸约束变化才参与对照，不调用产品内部状态。
// 回调不触发 setState，避免计数工具自己制造额外布局。
// 基准与保留分支共用同一个探针实现。
class _LayoutProbe extends SingleChildRenderObjectWidget {
  const _LayoutProbe({required this.onLayout, required super.child});
  final VoidCallback onLayout;
  @override
  // 测量钩子只附着到实际 RenderObject，不根据 Widget 构造次数推算。
  // 每个分支独立挂载，因此回调闭包不会在同一个探针中更换。
  RenderObject createRenderObject(BuildContext context) => _ProbeBox(onLayout);
}

class _ProbeBox extends RenderProxyBox {
  _ProbeBox(this.onLayout);
  final VoidCallback onLayout;
  @override
  // 先记入本次访问，再让真实子列表完成布局。
  // 即使列表内部复用了条目，这一层的重复工作仍会被计入。
  void performLayout() {
    onLayout();
    super.performLayout();
  }
}

void main() {
  testWidgets(
    'hidden pages skip relayout and resume with current constraints',
    (tester) async {
      // 窗口高于被测视口，避免父约束将所有尺寸变化都夹成同一个高度。
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // 结果同时保存布局次数和宿主耗时，便于查明差异来源。
      // 耗时仅作记录，不给 CI 机器设置不稳定的毫秒阈值。
      final results = <String, Object>{};
      // 基准在同一测试进程顺序执行，避免两种实现争用测试窗口。
      // 断言依赖确定的布局计数，不把同时进行的编译负载算作产品退化。
      // 对照使用相同的五页、内容和视口变化；差别仅是保留边界。
      // 每页两万项，但始终只构建视口附近的项目。
      // 这里的耗时是宿主测试时间，不是 Android Release 帧率。
      for (final retained in [false, true]) {
        // 每个分支都从相同标签与尺寸开始，不复用前一轮渲染缓存。
        // 首帧后仍保留全部五个页面，覆盖已经访问过多个标签的情况。
        var active = 0, height = 700.0;
        final layouts = List.filled(5, 0);
        // 每页持有独立控制器，验证隐藏页的位置不会被前台页覆盖。
        // 控制器不共享 ScrollPosition，恢复页必须使用自己的旧位置。
        // 结束时逐个释放，防止比较时留下正在监听的前一轮列表。
        final controllers = List.generate(5, (_) => ScrollController());
        // 页面 Widget 在循环外创建，尺寸变化不会被构造差异干扰。
        // 列表内容数量一致，避免一个分支因数据较少获得不公平优势。
        // itemExtent 只固定行高，列表仍执行正常的视口布局和滚动定位。
        final pages = List.generate(
          5,
          (i) => _LayoutProbe(
            onLayout: () => layouts[i]++,
            child: ListView.builder(
              controller: controllers[i],
              itemCount: 20000,
              itemExtent: 48,
              itemBuilder: (_, row) => Text('页面 $i，记录 $row'),
            ),
          ),
        );
        // 外层只改变可用高度或活动索引，不重建页面数据。
        // 因此隐藏页重复布局可归因到父约束传播，而不是数据更新。
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: StatefulBuilder(
                builder: (_, setState) {
                  update = setState;
                  return SizedBox(
                    width: 390,
                    height: height,
                    child: IndexedStack(
                      // 可见性仍由标准 IndexedStack 负责，保留边界不替换其语义和命中规则。
                      // 首轮保留分支也会建立隐藏页的初始尺寸，不把空页当成优化结果。
                      index: active,
                      children: [
                        for (var i = 0; i < pages.length; i++)
                          if (retained)
                            MiuixRetainedViewport(
                              active: active == i,
                              child: pages[i],
                            )
                          else
                            pages[i],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        // 两边均先建立初始布局和滚动位置，排除首次挂载的费用。
        await tester.pumpAndSettle();
        // 设置非零位置，防止两个分支都在顶部时漏掉错误的滚动纠正。
        // 位置设置发生在测量前，不计入连续改变视口的布局次数。
        controllers[1].jumpTo(4800);
        await tester.pumpAndSettle();
        // 只清计数，不重建 RenderObject；两轮都保留已经布局过的页面。
        // 第一帧高度与初值相同，所以只有后续 119 次触发实际尺寸变化。
        layouts.fillRange(0, layouts.length, 0);
        final watch = Stopwatch()..start();
        // 模拟大标题收起过程中的连续约束变化，每次都真正绘制一帧。
        // 不跳到最后一个尺寸，否则无法暴露逐帧重复布局。
        for (var frame = 0; frame < 120; frame++) {
          update(() => height = 700 - frame % 80);
          await tester.pump(const Duration(milliseconds: 8));
        }
        // 测量截止在隐藏页恢复之前，恢复所需的一次布局不算重复工作。
        // 活动页在两个分支中仍须布局，不能用完全冻结整个界面获得零计数。
        watch.stop();
        // 索引零始终为前台，剩余四页的累计值就是隐藏布局负担。
        // 这里求和的是次数，不将异步耗时相加推算设备帧率。
        final hidden = layouts.skip(1).reduce((a, b) => a + b);
        results[retained ? 'retained' : 'baseline'] = {
          'activeLayouts': layouts.first,
          'hiddenLayouts': hidden,
          'hostElapsedUs': watch.elapsedMicroseconds,
          'itemsPerPage': 20000,
        };
        // 隐藏页的布局必须确实归零，不能只得到一个更好看的耗时数字。
        // 对照页则应随每次尺寸变化排版，证明测试触发了原有瓶颈。
        expect(hidden, retained ? 0 : greaterThan(400));
        // 恢复同一条列表，不能通过销毁重建再重新定位伪造状态保留。
        // 活动标志切换后，冻结边界必须立即放行当前窗口高度。
        update(() => active = 1);
        await tester.pumpAndSettle();
        // 激活后使用最新高度，保留原滚动位置，不先回到顶部再修正。
        expect(controllers[1].position.viewportDimension, height);
        expect(controllers[1].offset, 4800);
        expect(tester.takeException(), isNull);
        // 先卸载滚动宿主，再释放控制器，避免仍挂载的列表访问已销毁对象。
        // 卸载也隔离两种实现，之后的计数不会包含前一分支。
        await tester.pumpWidget(const SizedBox.shrink());
        for (final controller in controllers) {
          controller.dispose();
        }
      }
      // 原始计数随测试输出保留，便于与应用接入后的导航回归一起核对。
      debugPrint('RETAINED_VIEWPORT_BENCHMARK ${jsonEncode(results)}');
    },
  );

  testWidgets('unbounded content keeps natural size and can become bounded', (
    tester,
  ) async {
    // 保留边界不是通用的强制全屏容器；无界方向不能传入无限高度。
    // 该场景同时覆盖先无界、后进入正常页面视口的重新采样。
    var bounded = false;
    late StateSetter update;
    const child = SizedBox(height: 72, child: Text('完整内容'));
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (_, setState) {
            update = setState;
            const viewport = MiuixRetainedViewport(active: false, child: child);
            return bounded
                ? const SizedBox(height: 300, child: viewport)
                : const SingleChildScrollView(child: viewport);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 无界与有界两种宿主均要能访问同一份全文，不以无异常替代内容检查。
    // 这项用例只检查约束退化路径，不要求内容填满无界的滚动方向。
    expect(find.text('完整内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
    update(() => bounded = true);
    await tester.pumpAndSettle();
    expect(find.text('完整内容'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
