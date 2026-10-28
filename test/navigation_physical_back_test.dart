import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'predictive_back_ownership_test.dart' show back, theme;

// 这是通用导航控件的方向合同，不依赖某一个业务页面的布局。
// 平台事件由 Widget 测试通道驱动，Android 系统输入另在应用验收中确认。
// 十六组配置同时覆盖物理边缘、阅读方向、窄屏与宽屏和大字号。
// 每组先取消再提交，避免只验证初次进入时看似正确的静态预览。
// 非手势的进出场方向仍由原导航测试覆盖，本例不改变它的阅读方向约定。
// 所有测量来自实际渲染树，不复制被测组件的方向算法作为测试实现。
void main() {
  // 手机与平板使用独立约束，避免宽屏靠拉伸手机截图冒充适配。
  // 每个用例重新挂载导航树，上一用例的返回所有者不能影响下一组。
  // 尺寸与字体缩放不改变物理左右边缘的含义。
  for (final size in [const Size(360, 844), const Size(1024, 800)]) {
    for (final scale in [1.0, 2.0]) {
      for (final reading in [TextDirection.ltr, TextDirection.rtl]) {
        for (final edge in [0, 1]) {
          testWidgets(
            'physical edge $edge $reading ${size.width} scale $scale',
            (tester) async {
              // 测试视口直接限定可用空间，不对页面内容施加额外裁切。
              // 用例结束恢复原视口，避免后续库测试继承错误的像素比例。
              // DPI 固定后，预期位移可以直接与渲染树中的逻辑像素比较。
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1;
              addTearDown(tester.view.reset);
              // 每例独立的 Navigator 记录真实路由移除，测试不维护另一份模拟栈。
              // 退出后能否继续接收返回，由生产路由自己的状态决定。
              final navigator = GlobalKey<NavigatorState>();
              // 两个页面使用完整滚动正文，大字号不能靠裁短内容避开布局。
              // 正文按原文自然换行，滚动容器提供完整访问路径而不限制固定行数。
              // 这里核对约束下的布局和位移，真实中文字体画面另由应用实际截图验收。
              Widget page(String id) => ColoredBox(
                key: ValueKey(id),
                color: id == 'root' ? Colors.white : Colors.blue,
                child: SingleChildScrollView(
                  child: Text(
                    '当前页面、完整中文名称与备注。' * 24,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              );
              // 使用公开页面过渡主题，测试不能直接访问私有返回动画状态。
              // RTL 只改变阅读方向，手指起始边缘仍是平台事件声明的物理边缘。
              // 缩放由 MediaQuery 绑定到整棵树，不只放大某一个测试文本。
              await tester.pumpWidget(
                MaterialApp(
                  navigatorKey: navigator,
                  theme: theme,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: reading,
                      child: child!,
                    ),
                  ),
                  home: page('root'),
                ),
              );
              // push 的 Future 要等到 pop 才完成，因此这里继续观察已经建立的路由。
              // 等待动画稳定后再开始拖动，不能把进场过程混进手势位移。
              // 当前页与来源页都保留真实元素，后续检查不能用一张假图片代替。
              unawaited(
                navigator.currentState!.push(
                  MiuixPageRoute<void>(builder: (_) => page('detail')),
                ),
              );
              // 进入前先让现有动画结束，系统手势必须从稳定页面开始。
              // 所有后续状态都沿这棵树观察，不靠重新挂载恢复正确结果。
              await tester.pumpAndSettle();
              // 保留元素身份，取消返回后必须仍是原实例，输入和滚动状态才可能继续。
              // 原页面不应因动画方向切换而被重建到另一份导航树。
              // 这不是堆内存泄漏证明，资源释放仍由库的生命周期专项覆盖。
              final original = tester.element(
                find.byKey(const ValueKey('detail')),
              );
              // 物理边缘是外部输入事实，测试只据此声明期望的移动符号。
              // 没有调用库的私有方向函数，避免与实现犯相同错误仍一起通过。
              final sign = edge == 0 ? 1.0 : -1.0;
              // 用户手指方向由物理边缘决定，不随应用阅读方向反转。
              expect(await back(tester, 'startBackGesture', edge: edge), true);
              await back(tester, 'updateBackGestureProgress', edge: edge);
              await tester.pump();
              final displacement = tester
                  .getTopLeft(find.byKey(const ValueKey('detail')))
                  .dx;
              // 公共事件助手将进度送为 0.6，位移应线性响应这一输入。
              // 比较整页像素位置，能检出只改变字段却没有作用到渲染结果的情况。
              expect(displacement, closeTo(sign * size.width * .6, .01));
              // 下层视差与上层方向相反，不能只修当前页面而露出错误底层。
              final translations = tester
                  .widgetList<FractionalTranslation>(
                    find.byKey(
                      const ValueKey('miuix-navigation-transition-scene'),
                    ),
                  )
                  .map((scene) => scene.translation.dx);
              expect(
                translations.any((v) => (v + sign * .1).abs() < 1e-9),
                true,
              );
              // 裁剪来自实际 ClipPath 的形状，不能只检查一个未使用的方向字段。
              // 跟随右侧手势时露出右边缘，圆角同样要保持到取消或提交收尾。
              // 两个页面中只有正在移动的上层需要此裁剪，下层保持完整矩形。
              final clipping = tester
                  .widgetList<ClipPath>(find.byType(ClipPath))
                  .where(
                    (w) =>
                        w.clipBehavior != Clip.none &&
                        w.clipper is ShapeBorderClipper,
                  )
                  .where(
                    (w) =>
                        (w.clipper! as ShapeBorderClipper).shape
                            is MiuixSquircleBorder,
                  )
                  .single;
              // 形状必须来自正在裁剪的真实上层节点，静止下层不能被误当作上层。
              // 零圆角与非零圆角分开检查，避免两侧都圆而掩盖方向错误。
              final border =
                  (clipping.clipper! as ShapeBorderClipper).shape
                      as MiuixSquircleBorder;
              final corners = border.borderRadius.resolve(reading);
              // 露出的那一侧才圆角，右侧手势不能仍裁剪左侧边缘。
              expect(corners.topLeft.x > 0, sign > 0);
              expect(corners.topRight.x > 0, sign < 0);
              // 松手瞬间的位移必须连续，不能先跳回逻辑阅读方向再开始回弹。
              // 推进一个中间帧检查符号，覆盖仅最终归零断言遗漏的瞬间反向。
              // 取消不能移除路由或留下 Navigator 的手势输入锁。
              await back(tester, 'cancelBackGesture');
              await tester.pump();
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx,
                closeTo(displacement, .01),
              );
              // 取消回弹保持同一方向和原元素，不能在松手时突然镜像翻转。
              // 默认五百毫秒收尾中的六十毫秒是中间样本，不是一个新的产品时长。
              // 最终归零无法发现一帧反向跳变，因此先保留这个中间检查点。
              await tester.pump(const Duration(milliseconds: 60));
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx *
                    sign,
                greaterThan(0),
              );
              await tester.pumpAndSettle();
              expect(
                tester.element(find.byKey(const ValueKey('detail'))),
                same(original),
              );
              // 原生手势取消后仍保留当前路由，框架的输入锁也必须释放。
              // 后面的第二轮拖动由同一路由处理，不使用新建页面规避失效状态。
              expect(navigator.currentState!.userGestureInProgress, false);
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx,
                closeTo(0, .01),
              );
              // 同一路由紧接着重新开始并提交，覆盖取消后的下一轮手势。
              expect(await back(tester, 'startBackGesture', edge: edge), true);
              await back(tester, 'updateBackGestureProgress', edge: edge);
              await tester.pump();
              // 提交收尾继续沿本轮手指方向离开，不能突然反向完成 pop。
              // 开始收尾时保持释放位置，随后位移增加直到当前页被移除。
              // 如果动画直接移除了页面，后面的中间帧位置检查也会真实失败。
              await back(tester, 'commitBackGesture');
              await tester.pump();
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx,
                closeTo(displacement, .01),
              );
              await tester.pump(const Duration(milliseconds: 60));
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('detail'))).dx *
                    sign,
                greaterThan(displacement * sign),
              );
              await tester.pumpAndSettle();
              // 提交只移除一层，Navigator 的手势状态和根页位置都须复位。
              // 最后检查真实导航栈与根页几何位置，避免仅完成一段视觉动画却未退栈。
              // 返回状态必须解除，后续页面仍可以接收触摸和新的系统返回。
              // 长正文在大字号下仍使用自然滚动，不以省略号掩盖排版错误。
              expect(find.byKey(const ValueKey('detail')), findsNothing);
              expect(navigator.currentState!.canPop(), false);
              expect(navigator.currentState!.userGestureInProgress, false);
              expect(
                tester.getTopLeft(find.byKey(const ValueKey('root'))).dx,
                closeTo(0, .01),
              );
              // 收集本例的布局异常，窄屏和大字号不能产生 RenderFlex 溢出。
              // 这些断言只证明组件矩阵，不声称已经覆盖厂商系统或所有业务页面。
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
}
