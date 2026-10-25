import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'predictive_back_ownership_test.dart' show back, theme;

void main() {
  // 测试范围包括页面、对话框、底部浮层和菜单四种返回所有者。
  // 每个场景创建新 Navigator，避免前一个场景留下栈状态。
  // theme 固定 Android，Windows 测试机也走 Android 页面过渡。
  // 平台消息经 flutter/backgesture 送入，不直接调用路由私有方法。
  // start 的布尔回执证明组件确实接管了连续手势。
  // 只断言最终退栈会漏掉“结束时才返回”的错误实现。
  // update 与 start 分开发送，覆盖平台分阶段推送的真实顺序。
  // 取消后等待复位，再从同一页面开始下一轮手势。
  // 关闭开关后保留原路由，不重新 push 来规避缓存旧设置。
  // scope 放在 Navigator 外，覆盖根路由创建的所有浮层。
  // 通知器模拟设置保存成功后的界面通知。
  // child 被复用，测试依赖必须传播到已有页面而非仅新页面。
  // 开关只影响预览，正常返回仍需通过 Flutter 的原导航通路。
  // 未接管 start 后仍发送 update，检测观察者是否错误地移动页面。
  // 没有预测所有者时，Flutter 把 commit 转交普通返回。
  // 浮层场景保留一张详情页，用来发现同一事件引起两次 pop。
  // 页面场景应退到根；浮层场景应只关闭最上层内容。
  // isCurrent 比界面文字更能发现详情页被错误地一并弹出。
  // 页面动画值必须保持 1，不能先预览再通过补动画掩盖错误。
  // 页面的 isActive 同时验证取消后没有把路由提前销毁。
  // 对话框使用正式 show API，包含真实遮罩与观察者。
  // 底部浮层使用自己的驱动，防止只关闭页面预览而遗漏浮层。
  // 菜单通过实际按钮打开，覆盖菜单挂载和所有者注册顺序。
  // 页面先等待入场结束，避免把入场期间的拒绝误当成正常行为。
  // 偏好通知器在场景结束释放，不能影响后续所有者仲裁。
  // 所有框架异常最后集中检查，覆盖失效控制器和重复退栈。
  // 结果测试使用公开结果组件，不直接改路由的私有读取器。
  // 读取器中的值与 widget 分开，模拟相机控制器内部状态变化。
  // 第一次手势开始时值为 1，取消之后才改成 42。
  // 若路由过早冻结结果，最后一次断言将得到错误的旧值。
  // push Future 的完成次数用于发现拦截后补 pop 的双重完成问题。
  // 取消不得完成 Future，也不得卸载持有读取器的页面。
  // 提交结果必须通过 Navigator 的正常完成逻辑送回调用方。
  // 测试没有通过显式 pop(42) 绕过 currentResult。
  // 历史预览使用实际绘制边界，不用预制图片代替捕获逻辑。
  // 根页面先完成绘制，再进入详情，确保有真实来源帧。
  // history 每次给新列表，不依赖原地修改列表的未定义行为。
  // 列表只含位置编号，不含测试数据或业务控制器。
  // 根位置保持不变，不同详情使用不同编号。
  // 每轮退回根再重新进入，覆盖已有来源帧的替换。
  // 每轮交替从两个物理边缘开始，不能只验证左边缘。
  // 进度固定便于断言，不依赖测试机的墙上时间。
  // 一轮包含三次取消，覆盖动画驱动重复启动和复位。
  // 每次取消后的提交次数应等于之前已经完成的轮数。
  // 下一次 start 必须仍被接受，不能卡在上一次取消状态。
  // RawImage 的存在证明展示了来源帧，而非只移动一张空白页面。
  // 真正退栈只有 onBack 一个入口，取消不能碰 committed。
  // 提交后必须显示真实根页面，预览图不能继续挡住交互。
  // 图片离开栈后会释放，重复多轮也覆盖图像生命周期。
  // 测试不把垃圾回收完成当作资源释放的依据。
  // busy 场景在页面入场完成后设置确定的退出限制。
  // canPop 在开始手势前已经可读，不等提交后再询问。
  // 对该页面发送 commit 也不能绕过 PopScope 的拒绝。
  // busy 测试没有 scope，覆盖旧应用默认开启时的兼容行为。
  // 检查最终动画值，防止被拒绝的页面出现半途预览。
  // 本组不操作 Activity，不声称覆盖系统返回桌面的动画。
  // 本组不操作输入法，键盘收起仍由 Android 输入系统处理。
  // 本组不伪造系统授权或修改宿主的锁屏状态。
  // 物理边缘消息由测试提供，不通过屏幕滑动坐标猜测返回类型。
  // 嵌套栈覆盖由同目录 ownership 测试补充，二者复用同一消息助手。
  // 所有者仲裁若被改成广播，浮层下方详情的检查会失败。
  // scope 若只在 initState 读取，动态关闭的检查会失败。
  // 结果若依赖 onPopInvoked 补返回，取消和完成次数检查会失败。
  // 历史预览若重建当前页面，后续应用级控制器身份检查会失败。
  // 这些场景用于验证通用控件，不引入应用专属页面规则。
  // 测试数据不包含真实账号、健康记录或任何认证凭据。
  // 动画通过 pumpAndSettle 等待，不依赖固定的主机 sleep。
  // 取消与提交分别使用平台终止消息，不能用手动设置进度结束。
  // 根页不会通过本组测试退出到桌面，以免平台通道掩盖路由错误。
  // 所有断言读取实际路由和控件，没有另外实现一套预测算法。
  // 关闭状态无需移除观察者；事件到来时应读取最新 scope。
  // 页面仍在栈中时切换偏好，是本次缓存修复的主要回归边界。
  // 三类浮层采用相同检查流程，防止某类控件遗漏全局开关。
  // 最后的异常检查也覆盖 RawImage 使用已释放句柄的错误。
  // 保护层在已开始的手势中出现，覆盖提交晚于后台切换的竞态。
  // blocked 与 enabled 同时切换，检查两种策略没有混为一个开关。
  // 保护期间页面是否 current 必须保持不变，浮层也不能悄悄被关闭。
  // Overlay 菜单另跑一次，覆盖兼容返回回调早于 PopScope 的路径。
  // 解除保护后再关闭动画返回，能发现菜单已在遮罩后被错误移除。
  // 返回主页面不能当作浮层关闭成功，这种多退一层会使最终断言失败。
  for (final overlay in ['page', 'dialog', 'sheet', 'menu', 'menu-overlay']) {
    testWidgets('global switch controls $overlay without losing normal Back', (
      tester,
    ) async {
      final enabled = ValueNotifier(true);
      var blocked = false;
      final navigator = GlobalKey<NavigatorState>();
      late BuildContext pageContext;
      addTearDown(enabled.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          navigatorKey: navigator,
          // Scope 位于 Navigator 外，弹窗也必须遵守同一个设置。
          builder: (context, child) => ValueListenableBuilder(
            valueListenable: enabled,
            builder: (_, value, _) => MiuixBackGestureScope(
              enabled: value,
              blocked: blocked,
              child: child!,
            ),
          ),
          home: const Scaffold(body: Text('root')),
        ),
      );
      final page = MiuixPageRoute<void>(
        builder: (context) {
          pageContext = context;
          return MiuixTheme(
            child: MiuixScaffold(
              body: Column(
                children: [
                  const Text('detail'),
                  MiuixIconCascadingDropdownMenu<String>(
                    icon: const Icon(Icons.more_horiz),
                    presentation: overlay == 'menu-overlay'
                        ? MiuixPopupPresentation.overlay
                        : MiuixPopupPresentation.window,
                    groups: const [
                      MiuixDropdownGroup(
                        entries: [
                          MiuixDropdownEntry(value: 'a', label: 'menu item'),
                        ],
                      ),
                    ],
                    onSelected: (_) {},
                  ),
                ],
              ),
            ),
          );
        },
      );
      unawaited(navigator.currentState!.push(page));
      await tester.pumpAndSettle();
      if (overlay == 'dialog') {
        unawaited(
          MiuixDialog.show<void>(
            context: pageContext,
            content: const Text('dialog'),
          ),
        );
      } else if (overlay == 'sheet') {
        unawaited(
          MiuixBottomSheet.show<void>(
            context: pageContext,
            child: const Text('sheet'),
          ),
        );
      } else if (overlay.startsWith('menu')) {
        await tester.tap(find.byIcon(Icons.more_horiz));
      }
      await tester.pumpAndSettle();
      // 开启时真正接管平台连续事件；取消不能弹出页面或浮层。
      expect(await back(tester, 'startBackGesture'), isTrue);
      await back(tester, 'updateBackGestureProgress');
      await tester.pump();
      await back(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(page.isActive, isTrue);
      // 先开始真实拖动，再出现保护层，模拟认证窗口或应用转入后台。
      // 已接管的 commit 也必须取消，不能绕过新注册的 PopScope。
      final wasCurrent = page.isCurrent;
      expect(await back(tester, 'startBackGesture'), isTrue);
      await back(tester, 'updateBackGestureProgress');
      blocked = true;
      enabled.value = false;
      await tester.pump();
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(page.isActive, isTrue);
      expect(page.isCurrent, wasCurrent);
      // 普通返回由 WidgetsApp 先处理，必须靠路由内保护阻止退栈。
      // 只注册根部 WidgetsBindingObserver 来不及阻止这个路径。
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(page.isActive, isTrue);
      expect(page.isCurrent, wasCurrent);
      // 解除保护恢复原内容，随后单独验证用户关闭动画的正常返回。
      blocked = false;
      enabled.value = true;
      await tester.pumpAndSettle();
      // 动态关闭后无须重建页面；提交仍触发一次正常返回。
      enabled.value = false;
      await tester.pumpAndSettle();
      expect(await back(tester, 'startBackGesture'), isFalse);
      await back(tester, 'updateBackGestureProgress');
      await tester.pump();
      expect(page.animation!.value, 1);
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(page.isCurrent, overlay != 'page');
      // 浮层退出后底下的详情页必须保留。
      if (overlay != 'page') expect(find.text('detail'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'predictive result reads latest value and cancellation has no result',
    (tester) async {
      final nav = GlobalKey<NavigatorState>();
      var value = 1, completions = 0;
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          navigatorKey: nav,
          home: const Scaffold(body: Text('root')),
        ),
      );
      final route = MiuixResultPageRoute<int>(
        builder: (_) => MiuixPageResult<int>(
          result: () => value,
          child: const Scaffold(body: Text('result page')),
        ),
      );
      unawaited(
        nav.currentState!.push(route).then((v) {
          result = v;
          completions++;
        }),
      );
      await tester.pumpAndSettle();
      // 手势开始时不预先消耗结果，页面修改可继续更新当前值。
      expect(await back(tester, 'startBackGesture'), isTrue);
      await back(tester, 'updateBackGestureProgress');
      await back(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(completions, 0);
      value = 42;
      expect(await back(tester, 'startBackGesture'), isTrue);
      await back(tester, 'updateBackGestureProgress');
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(result, 42);
      expect(completions, 1);
    },
  );

  testWidgets('local history previews both edges and repeated cancellation', (
    tester,
  ) async {
    final history = ValueNotifier(<Object>[0]);
    var committed = 0;
    addTearDown(history.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: ValueListenableBuilder(
          valueListenable: history,
          builder: (_, value, _) => MiuixBackHistory(
            history: value,
            handlesBack: value.length > 1,
            onBack: () async {
              committed++;
              history.value = value.sublist(0, value.length - 1);
            },
            child: Scaffold(body: Text('scene ${value.last}')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    for (var scene = 1; scene <= 6; scene++) {
      history.value = [0, scene];
      await tester.pumpAndSettle();
      // 同一位置反复取消，不能清空预览帧、重建当前页或执行 onBack。
      for (var repeat = 0; repeat < 3; repeat++) {
        expect(
          await back(tester, 'startBackGesture', edge: repeat % 2),
          isTrue,
        );
        await back(tester, 'updateBackGestureProgress', edge: repeat % 2);
        await tester.pump();
        expect(find.byType(RawImage), findsOneWidget);
        await back(tester, 'cancelBackGesture');
        await tester.pumpAndSettle();
        expect(committed, scene - 1);
        expect(find.text('scene $scene'), findsOneWidget);
      }
      expect(await back(tester, 'startBackGesture'), isTrue);
      await back(tester, 'updateBackGestureProgress');
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(committed, scene);
      expect(find.text('scene 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('busy route never previews or exits under either preference', (
    tester,
  ) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        navigatorKey: nav,
        home: const Scaffold(body: Text('root')),
      ),
    );
    final route = MiuixPageRoute<void>(
      builder: (_) =>
          const PopScope(canPop: false, child: Scaffold(body: Text('saving'))),
    );
    unawaited(nav.currentState!.push(route));
    await tester.pumpAndSettle();
    // 不通过强制 Navigator.pop 绕过可提前判定的保存保护。
    expect(await back(tester, 'startBackGesture'), isFalse);
    await back(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(route.isCurrent, isTrue);
    expect(route.animation!.value, 1);
  });
}
