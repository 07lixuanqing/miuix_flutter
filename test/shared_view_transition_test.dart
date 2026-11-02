import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'predictive_back_ownership_test.dart' show back, theme;

// 使用公开来源控件和真实 Navigator，不直接访问动画内部状态。
// 起点、返回点和取消回弹都检查实际布局后的矩形。
// 本文件的矩阵同时覆盖来源生命周期和系统手势生命周期。
// 宽度分别模拟窄手机与平板可用窗口，不改变动画的逻辑像素单位。
// 字号变化传入整棵树，来源文字与详情文字都参与实际布局。
// 左右边缘来自平台事件，不由阅读方向或应用当前语言推断。
// 打开起点按点击时的卡片矩形比较，容差不能扩成另一张卡片的大小。
// 中间帧检查宽度增加，排除只显示两张静态图片的实现。
// 同时检查下层来源位置，防止传统侧滑继续拖走卡片落点。
// 正常终点必须铺满 Navigator，而非停在近似全屏的固定尺寸。
// 连续两次取消沿同一个目标路由执行，不重新创建详情规避状态丢失。
// 取消后能再次开始，是导航所有权已经释放的必要证据。
// 最终提交验证真实退栈，而非只完成一段视觉动画。
// 返回后比较 Element 身份，检查列表与控件没有被重建成另一份实例。
// 后续普通导航不能领取过期来源，避免把旧图像用于无关的操作。
// 本地布局通过不能代替手机 ROM 或 Android ActivityOptions 的真实验收。
void main() {
  // 来源在详情打开期间被数据刷新移除时，返回必须淡出而不是飞向旧位置。
  // 此用例只移除源卡片，目标详情仍保持当前路由，不直接销毁 Navigator。
  // 原始截图若仍存在，也不能被当作来源控件仍然有效的证据。
  // 来源不存在时不强制滚动或创建一个新的占位卡片。
  // 返回动画中读取真实全屏矩形，以区分淡出和飞向旧点。
  // 完成后仍检查导航栈为空，避免淡出只是隐藏画面却没有返回。
  // 释放值监听器与路由归属分别由各自生命周期处理。
  testWidgets('removed source uses fade and releases navigation', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    // 用独立可观察值模拟详情打开后的来源数据刷新。
    // 不通过访问私有状态强行删除来源捕获记录。
    final visible = ValueNotifier<bool>(true);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [MiuixSharedViewObserver()],
        theme: theme,
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: visible,
            builder: (context, show, _) => show
                ? Center(
                    child: SizedBox(
                      width: 200,
                      height: 120,
                      child: MiuixSharedViewSource(
                        builder: (context, open) => TextButton(
                          onPressed: () => open(
                            () => Navigator.of(context).push(
                              MiuixPageRoute<void>(
                                builder: (_) =>
                                    const Scaffold(body: Text('Detail')),
                              ),
                            ),
                          ),
                          child: const Text('Open'),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    // 来源从真实 widget 树移除，GlobalKey 和 RenderObject 都会失效。
    // 这与只把来源设为透明不同，后者仍可能有合法几何位置。
    visible.value = false;
    await tester.pumpAndSettle();
    // 走正常 Navigator 返回，让失效判定参与实际退出动画。
    // 不直接清空动画值或手工把页面替换成根页。
    navigator.currentState!.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 没有真实落点时保持全屏几何，只有透明度变化。
    final flight = find.byKey(const ValueKey('miuix-shared-view-flight'));
    // 全屏宽度来自当前测试窗口与像素比，不能写死某台手机的尺寸。
    // 来源失效只改变关闭效果，不改变返回的目标页面。
    expect(
      tester.getRect(flight).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
    await tester.pumpAndSettle();
    expect(navigator.currentState!.canPop(), false);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 960.0]) {
    for (final scale in [1.0, 2.0]) {
      for (final edge in [0, 1]) {
        testWidgets(
          'shared view roundtrip width=$width scale=$scale edge=$edge',
          (tester) async {
            tester.view.physicalSize = Size(width, 900);
            tester.view.devicePixelRatio = 1;
            // 每个窗口独立清理，不能继承前一组的大字号与来源记录。
            addTearDown(tester.view.reset);
            // 每轮创建独立 Navigator，使前一次手势或来源不能影响本轮。
            // 路由栈由框架持有，测试不维护另一套推测的页面数量。
            // 无关导航测试不经过原来源，不能因为已有快照而自动套用展开。
            // 减少动画的两组输入也不应遗留一个延后才领取的来源。
            final navigator = GlobalKey<NavigatorState>();
            // 来源键只用于定位与元素身份比较，不作为业务记录标识。
            // 同一来源关闭后必须继续使用这个 Element。
            final source = GlobalKey();
            // 观察者和主题一起接入，缺一项时共享转场不应假装通过。
            // 这个实例在整个往返期间保持稳定。
            final observer = MiuixSharedViewObserver();
            // 使用与普通 MIUIX 路由相同的过渡主题，验证真正接入的位置。
            await tester.pumpWidget(
              MaterialApp(
                navigatorKey: navigator,
                navigatorObservers: [observer],
                theme: theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 240,
                      height: 150,
                      child: MiuixSharedViewSource(
                        builder: (context, open) => ColoredBox(
                          key: source,
                          color: Colors.orange,
                          child: TextButton(
                            onPressed: () => open(
                              () => Navigator.of(context).push(
                                MiuixPageRoute<void>(
                                  builder: (_) => const Scaffold(
                                    body: Center(child: Text('Detail')),
                                  ),
                                ),
                              ),
                            ),
                            child: const Text('Open content'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            // 保存真实元素引用，返回后同名文本不能代替身份相同。
            // 定位使用来源容器，不只检查其中某个 Text 的坐标。
            final sourceElement = tester.element(find.byKey(source));
            // 矩形包含来源完整宽高，能够发现仅平移而没有展开的实现。
            // 测量发生在布局稳定后，不使用尚未完成绘制的尺寸。
            final origin = tester.getRect(find.byKey(source));
            // 明确点击来源触发导航，普通程序导航不应自动变成容器展开。
            // 点击沿正式控件的 onTap 处理，不直接给私有捕获对象赋值。
            // 按压准备图层与目标路由领取图层都在这条路径中执行。
            await tester.tap(find.text('Open content'));
            await tester.pump();
            // Flutter 先离屏测量新路由，下一帧才是可见的展开起点。
            await tester.pump();
            // 定位真实裁切容器，不能拿详情页静态外框冒充飞行矩形。
            // 离屏测量帧也保留查找资格，随后的中间帧检查实际可见布局。
            final flight = find
                .byKey(
                  const ValueKey('miuix-shared-view-flight'),
                  skipOffstage: false,
                )
                .last;
            expect(flight, findsOneWidget);
            // 展开起点必须与来源重合，不能从页面中心凭空放大。
            // 这里比较位置和尺寸，而非只比较动画时长。
            expect(tester.getRect(flight), origin);
            // 中间帧应连续扩大，不能只是第一帧和最后一帧两张静态图。
            await tester.pump(const Duration(milliseconds: 100));
            expect(tester.getRect(flight).width, greaterThan(origin.width));
            expect(
              tester.getRect(find.byKey(source, skipOffstage: false)),
              origin,
            );
            // 结束后的完整窗口尺寸必须正确，后续预测性返回才有相同基准。
            // 普通展开完成后再开始手势，避免把两段不同状态混为一谈。
            await tester.pumpAndSettle();
            expect(tester.getRect(flight).width, closeTo(width, .1));
            // 同一详情连续取消两次，确认来源图片和导航所有权仍保持可用。
            for (var i = 0; i < 2; i++) {
              expect(await back(tester, 'startBackGesture', edge: edge), true);
              await back(tester, 'updateBackGestureProgress', edge: edge);
              await tester.pump();
              // 中途矩形必须同时大于卡片、小于页面，说明系统进度真正驱动几何。
              // 只看最终退栈结果无法发现始终保持全屏的伪预览。
              final dragged = tester.getRect(flight);
              expect(dragged.width, greaterThan(origin.width));
              expect(dragged.width, lessThan(width));
              // 左右有相反的横向反馈，几何插值仍指向同一个来源卡片。
              // 中心基准只用于比较左右符号，不复写被测控件的曲线公式。
              // 最终来源相同不意味着左右手指反馈也应相同。
              final centered = (width - dragged.width) / 2;
              expect(
                (dragged.left - centered) * (edge == 0 ? 1 : -1),
                greaterThan(0),
              );
              // 取消由正式平台消息触发，不用 Navigator.pop 再重新 push 模拟。
              // 同一路由和同一来源必须在取消后继续存在。
              await back(tester, 'cancelBackGesture');
              await tester.pumpAndSettle();
              // 取消只复位动画，不能消费当前这层导航。
              // 后面的再次开始用于发现未清除的手势输入锁。
              expect(navigator.currentState!.canPop(), true);
              expect(tester.getRect(flight).width, closeTo(width, .1));
            }
            // 提交只退一层，原卡片的位置、元素身份与点击能力不能丢失。
            expect(await back(tester, 'startBackGesture', edge: edge), true);
            await back(tester, 'updateBackGestureProgress', edge: edge);
            await back(tester, 'commitBackGesture');
            await tester.pumpAndSettle();
            // 提交后只剩根页，不能重复提交导致整个应用退出。
            // 导航数量与最终几何位置分别断言，避免单一条件掩盖另一类错误。
            expect(navigator.currentState!.canPop(), false);
            // 元素相同保证原控件状态得以保留，而不只是重新绘制相似界面。
            // 回到原位后仍要检查系统手势状态已经解除。
            expect(tester.element(find.byKey(source)), same(sourceElement));
            expect(tester.getRect(find.byKey(source)), origin);
            expect(navigator.currentState!.userGestureInProgress, false);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          },
        );
      }
    }
  }

  // 没有路由的点击和减少动画的设置都不能遗留一次稍后才生效的来源。
  // 两组使用相同的无导航点击，只有减少动画这个系统事实不同。
  // 不根据测试分组临时修改核心控件的全局开关。
  // 程序路由在点击回调结束之后发出，模拟稍后发生的无关跳转。
  // 即使存在来源图像，也只能用于同步回调内领取的一个目标。
  // 验证没有飞行容器，不以看不到透明位图作为没有转场的证据。
  // 结束后等待框架完成过渡，检查的异常也包括资源释放回调。
  for (final reduce in [false, true]) {
    testWidgets('shared view ignores unrelated navigation reduced=$reduce', (
      tester,
    ) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          navigatorObservers: [MiuixSharedViewObserver()],
          theme: theme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
            child: child!,
          ),
          home: Scaffold(
            body: MiuixSharedViewSource(
              builder: (context, open) => TextButton(
                onPressed: () => open(() {}),
                child: const Text('No navigation'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // 这次点击明确没有导航，临时图片应在回调完成时释放。
      // 后续程序打开属于另一动作，不允许使用前一次点击位置。
      await tester.tap(find.text('No navigation'));
      await tester.pump();
      // 此处的程序打开与前一次点击无关，不得领取已经失效的来源图片。
      unawaited(
        navigator.currentState!.push(
          MiuixPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Other')),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey('miuix-shared-view-flight')),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
