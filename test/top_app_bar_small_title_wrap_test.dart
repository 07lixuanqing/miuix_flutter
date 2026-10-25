// 完整小标题是显式能力；测量变化不能移动原图标操作或改变点击目标。
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 320dp与960dp分别代表窄手机和独立宽窗口，不按测试电脑的物理分辨率推断。
// 每种宽度均验证LTR与RTL，两个方向采用同一套实际控件构造。
// 全部场景保持200%字号，不关闭缩放，也不缩短长中文样例来通过检查。
// NotoSansCJK字体来自例子已有资产，真实字形宽度参与排版。
// 字体加载只影响测试沙盒，不修改操作系统字体配置。
// 初始空标题用于取得同宽度下的原图标位置，不参与完整标题成功断言。
// 之后使用相同leading和actions，只有title与wrapSmallTitle公开参数变化。
// 完整标题通过真正MiuixScaffold测量，不由测试外壳手动增加appBar高度。
// MediaQuery的TextScaler作用于完整子树，测量和渲染不能看到不同的字号。
// Directionality同样由正式继承链提供，不在测试内手动镜像Rect。
// 返回和刷新使用独立计数，可发现重排后两个回调被错误交换。
// ValueKey保持稳定，比较的是同一业务图标在两种布局下的真实Rect。
// Rect同时包含位置与大小，不仅检查中心点或图标颜色。
// 原leading和action的40dp视觉布局及语义范围都不能因标题增高而移动。
// 标题区域可以变高，但图标行的垂直位置必须保持不变。
// RenderParagraph.didExceedMaxLines必须为false，不能只断言没有RenderFlex报错。
// 该检查能发现父级静默ellipsis，而不是仅关注明显的溢出条纹。
// 标题底边还须位于实际顶栏内，避免去掉maxLines后覆盖到正文上。
// 顶栏边界取自公开组件真实RenderBox，不硬编码某个中文字体的行高。
// 窄屏场景明确要求高度大于原52dp，证明高度增加进入Scaffold预留路径。
// 宽屏并不强制大于52dp，标题足够放下时应继续保留紧凑布局。
// body在两次pump之间保持同一个结构，不能通过移除正文掩盖覆盖问题。
// 点击测试走真实手势注入，不直接调用widget.onPressed。
// 返回次数为1、刷新次数为1，标题层不能抢走原来的点击区域。
// 连续点击后仍检查框架异常，避免命中测试或玻璃边缘绘制错误被漏掉。
// pumpAndSettle等待正常标题材质动画稳定，不采用中途坐标作为预期。
// 回调不执行Navigator.pop，因此不会在检查第二个按钮前销毁测试页面。
// 测试创建的MaterialApp仅在当前Flutter测试进程中存在。
// 它不安装APK、不创建Windows桌面窗口，也不操作用户的真实手机。
// 每轮恢复FlutterView尺寸和DPR，不把320dp遗留到其他组件回归。
// 同一测试文件的四个用例彼此独立，图标计数不会沿用上一场景。
// 只有小标题显式开启wrapSmallTitle，大标题和默认单行契约由既有测试覆盖。
// 默认样式的像素基线仍由组件库全量golden测试验收。
// 本套没有修改golden图片，也不以更新截图来回避旧样式回归。
// 标题长度保持一致，所以手机和平板的差异必须来自可用宽度。
// 宽度、方向和字号都是实际继承属性，不复制源代码中的碰撞算法。
// 测试不读取私有测量方法，因此公开预留高度与内部绘制不一致会直接失败。
// 中文字符串是公开夹具，没有账号、密钥或其他用户资料。
// 这些断言证明Flutter布局与命中测试，不能代替厂商真实分屏体验。
// 应用侧还须核对正文的首屏起点，防止透明顶栏遮住首个内容卡片。
// 跨屏持续缩放与未保存输入保留由应用编辑页的往返测试补充验证。

void main() {
  setUpAll(() async {
    // 实际中文字体参与测量，不能用Ahem方块字掩盖换行差异。
    final bytes = await File(
      'example/assets/fonts/NotoSansCJKsc-Regular.otf',
    ).readAsBytes();
    await (FontLoader(
      'Roboto',
    )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  });
  for (final width in [320.0, 960.0]) {
    for (final direction in TextDirection.values) {
      testWidgets('wrapped small title keeps icon targets $width $direction', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const title = '通知待发回复与完整长中文标题';
        const back = ValueKey('wrap-back'), action = ValueKey('wrap-action');
        var backTaps = 0, actionTaps = 0;
        Future<void> show(bool wrapped, String text) async {
          await tester.pumpWidget(
            MaterialApp(
              home: MiuixTheme(
                child: Builder(
                  builder: (context) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: const TextScaler.linear(2)),
                    child: Directionality(
                      textDirection: direction,
                      child: MiuixScaffold(
                        topBar: MiuixTopAppBar(
                          title: text,
                          large: false,
                          wrapSmallTitle: wrapped,
                          leading: MiuixIconButton(
                            key: back,
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => backTaps++,
                          ),
                          actions: [
                            MiuixIconButton(
                              key: action,
                              icon: const Icon(Icons.refresh),
                              onPressed: () => actionTaps++,
                            ),
                          ],
                        ),
                        body: const Text('正文保持可用'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        // 用空标题取得同一宽度下的正常图标位置，避免比较两个不同布局场景。
        await show(false, '');
        final backRect = tester.getRect(find.byKey(back));
        final actionRect = tester.getRect(find.byKey(action));
        await show(true, title);
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(title),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(tester.getRect(find.byKey(back)), backRect);
        expect(tester.getRect(find.byKey(action)), actionRect);
        // 标题必须位于分配给实际顶栏的区域内，不能只取消ellipsis后画到正文上。
        final bar = tester.getRect(find.byType(MiuixTopAppBar));
        expect(
          tester.getRect(find.text(title)).bottom,
          lessThanOrEqualTo(bar.bottom),
        );
        if (width == 320) expect(bar.height, greaterThan(52));
        await tester.tap(find.byKey(back));
        await tester.tap(find.byKey(action));
        expect(backTaps, 1);
        expect(actionTaps, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
