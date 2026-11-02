import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 使用高对比样本测整圈边线，不只检查组件配置里存在 BorderSide。
// 正文与底色固定，只有边线能产生深色像素，避免填充掩盖缺边。
// 七个角色都显式提供，避免默认主题的淡色影响几何断言。
// 白色正文不会被边框取样误认为描边。
// 白色底也不能用填充掩盖裁剪缺口。
// 只有黑色轮廓能让取样通过。
const palette = MiuixChipColors(
  background: Colors.white,
  foreground: Colors.white,
  selectedBackground: Colors.white,
  selectedForeground: Colors.white,
  disabledBackground: Colors.white,
  disabledForeground: Colors.white,
  outline: Colors.black,
);

// 矩阵只改变材质、圆角和交互状态。
// 每例通过公共 MiuixChip 入口渲染。
// 不直接调用内部 painter，因此能发现外层裁剪。
// 旧实现会丢失约百分之十四的轮廓采样。
void main() {
  // 默认玻璃和 source 不透明路径都需要连续边框。
  // 修复不能只适用于当前应用开启玻璃的设置。
  for (final glass in [true, false]) {
    // 全局关闭 G2 后应退回常规胶囊。
    // 此分支也检查重复抗锯齿导致的细线缺口。
    for (final smooth in [true, false]) {
      // 禁用只改变操作资格和配色。
      // 不能因为没有点击回调就少绘制两侧边线。
      for (final enabled in [true, false]) {
        testWidgets(
          'closed chip outline glass=$glass smooth=$smooth enabled=$enabled',
          (tester) async {
            // 三倍像素覆盖曲线抗锯齿；坐标仍以实际逻辑尺寸计算。
            // 颜色透明度不参与本测试，只验证边线是否被另一层裁掉。
            tester.view.devicePixelRatio = 3;
            tester.view.physicalSize = const Size(960, 600);
            addTearDown(tester.view.reset);
            // 只截取芯片自身，避免页面其他深色像素参与判断。
            // 实际尺寸由组件内容布局决定。
            // 不把固定截图坐标当成通用轮廓。
            final boundary = GlobalKey();
            // 不插入额外 ClipRRect 或边框修补宿主。
            // 如果控件内部仍裁掉边框，本例必须失败。
            // 默认无交互态动画，待稳定后读取。
            await tester.pumpWidget(
              MiuixTheme(
                data: MiuixThemeData.defaults().copyWith(
                  enableSquircle: smooth,
                ),
                child: MaterialApp(
                  home: Scaffold(
                    body: Center(
                      child: RepaintBoundary(
                        key: boundary,
                        // 固定正文用于获得非零自然宽度。
                        // 颜色与标签状态仍通过公开 API 传入。
                        // 不使用私有组件替代真实调用链。
                        child: MiuixChip(
                          label: 'Complete',
                          enabled: enabled,
                          glass: glass,
                          glassBlur: 0,
                          colors: palette,
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            // 直接读取实际渲染像素，覆盖玻璃和不透明分支。
            // 轮廓使用公共形状接口，取样位置不依赖旧截图的固定大小。
            await tester.runAsync(() async {
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await render.toImage(pixelRatio: 3);
              // 读取 RGBA 以区分透明黑和实际黑色。
              // 仅检查 RGB 会把透明缺口误判为完整边线。
              // 后续按白色背景合成后再比较。
              // RGBA 索引使用物理像素，不把逻辑尺寸误作字节偏移。
              // alpha 单独读取，透明背景按白色合成。
              final pixels = (await image.toByteData(
                format: ui.ImageByteFormat.rawRgba,
              ))!;
              // 形状计算来自公共组件库契约。
              // G2 胶囊与普通 StadiumBorder 各自使用实际路径。
              // 不以圆形拟合连续圆角。
              final shape = smooth
                  ? const MiuixCapsuleBorder()
                  : const StadiumBorder();
              // 逐段取真实贝塞尔轮廓，包含所有四个圆角。
              // 尺寸随实际标签内容变化，不能只测固定宽度中点。
              final contour = shape
                  .getOuterPath(Offset.zero & render.size)
                  .computeMetrics()
                  .single;
              // 统计整条轮廓的遗漏比例。
              // 上下边线正常但侧边缺失也会被计入。
              // 缺口不能被更多直线取样稀释到任意容差。
              var missed = 0, checked = 0;
              // 沿完整路径逐点检查向内半个像素的边带。
              // 取小邻域容忍抗锯齿，不容忍整段圆角被外层普通圆角裁掉。
              for (
                var distance = .25;
                distance < contour.length;
                distance += 1
              ) {
                // 路径切线给出沿边走向。
                // 顺时针轮廓向内法线为负 dy、正 dx。
                // 沿法线稍向内，采样覆盖真正位于表面内的边带。
                final tangent = contour.getTangentForOffset(distance)!;
                final inward = Offset(-tangent.vector.dy, tangent.vector.dx);
                final point = (tangent.position + inward * .45) * 3;
                // 每个路径位置取很小的像素邻域。
                // 只容忍栅格化对齐差异，不跨到远处找另一条边。
                // 初始白色表示没有发现边线。
                var darkest = 255;
                for (var dy = -1; dy <= 1; dy++) {
                  for (var dx = -1; dx <= 1; dx++) {
                    final x = point.dx.round() + dx, y = point.dy.round() + dy;
                    if (x < 0 ||
                        y < 0 ||
                        x >= image.width ||
                        y >= image.height) {
                      continue;
                    }
                    // 先检查图像范围，避免边缘坐标越界。
                    // 像素索引使用图像物理宽度，不能使用逻辑布局宽度。
                    final index = (y * image.width + x) * 4;
                    // 图像背景透明时不能把黑色透明像素误认为完整边框。
                    final alpha = pixels.getUint8(index + 3) / 255;
                    final value =
                        (pixels.getUint8(index) * alpha + 255 * (1 - alpha))
                            .round();
                    if (value < darkest) darkest = value;
                  }
                }
                if (darkest > 180) missed++;
                checked++;
              }
              // 释放引擎图像，避免矩阵测试积累图像资源。
              // 断言只保留计数，不保存完整像素副本。
              // 释放 GPU 图像后继续使用小型整数计数做断言。
              // 矩阵后续用例不保留前一帧图像资源。
              image.dispose();
              // 允许不到百分之二的亚像素误差，旧裁剪会丢失大段曲线。
              // 这里不是仅抽查上下中点，否则恰好漏掉两侧缺边。
              expect(
                missed / checked,
                lessThan(.02),
                reason: '$missed / $checked outline samples missing',
              );
            });
          },
        );
      }
    }
  }

  testWidgets(
    'long labels wrap at 200 percent and disabled chips remain inert',
    (tester) async {
      var actions = 0;
      // 长文字刻意超过 180 宽与 200% 字号能容纳的单行。
      // 不使用短词作为文字完整性验收样本。
      // 页面另有长中文与实际操作名称的渲染检查。
      const text =
          'Insufficient points for this reward; complete another task first';
      // 使用有限宽度和大字号，确保全文不是只存在于语义树。
      // 没有 maxLines 与省略号时才允许自然增加高度。
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 180,
                    child: MiuixChip(
                      label: text,
                      enabled: false,
                      onPressed: () => actions++,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // 等待布局和材质稳定再读取渲染对象。
      // 真正检查 RenderParagraph 的裁剪结果。
      // 仅在语义树存在全文并不足以通过。
      await tester.pumpAndSettle();
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(text), matching: find.byType(RichText)),
      );
      // 省略号会让这里检测到超行，即使 Text.data 没有变化。
      // 取消最大行数后应允许高度随内容增长。
      // 点击禁用态还要继续保持零操作次数。
      expect(paragraph.didExceedMaxLines, false);
      expect(tester.takeException(), isNull);
      // 视觉修复不能让积分不足等禁用操作变成可点击。
      // 同时检查点击次数，避免只核对 enabled 字段。
      await tester.tap(find.text(text));
      // 没有触发动作是禁用状态的最终行为断言。
      expect(actions, 0);
    },
  );
  testWidgets('tree action row preserves title and summary at large type', (
    tester,
  ) async {
    // 标题和说明都超过一行，分别检查，避免其中一项被另一项挤掉。
    // 测试文本不依赖翻译或产品任务长度。
    const title = 'A long task title that must remain fully readable';
    const summary =
        'Points, ownership, frequency and the reason for this status';
    // 共享布局同样供应用懒加载目录使用，不复制两份窄屏规则。
    // 保留说明全文，不能只把按钮挪开却继续隐藏摘要。
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            // 树行本来位于可滚动列表内；这里保留同样的无界纵向约束。
            // 全文超过视口时滚动阅读，不通过缩短样本避开溢出。
            child: SingleChildScrollView(
              child: SizedBox(
                width: 300,
                child: MiuixTreeRowLayout(
                  // 展开键即使为空也保留原占位，覆盖窄屏剩余宽度。
                  // 不通过去掉前导区让样本变得更容易放下。
                  leading: SizedBox(width: 40),
                  // 两个独立段落自然叠放，不能以一个合成字符串掩盖丢失。
                  // 实际应用也提供标题与元信息列。
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Text(title), Text(summary)],
                  ),
                  trailing: Text('Action'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 动作下移到内容之后，避免争抢同一行有限宽度。
    // 同时核对两个段落均未发生最大行数裁剪。
    // 位置断言证明切换成纵排，而不仅是把文字缩小到横排。
    // 描述的底部仍应位于操作之前。
    // 行内容保持在滚动宿主中，超过屏幕高度也不能被固定行高截断。
    // 坐标来自真实布局，不根据预设字体高度推算。
    expect(
      tester.getTopLeft(find.text('Action')).dy,
      greaterThan(tester.getBottomLeft(find.text(summary)).dy),
    );
    // 两个字段各自对应真实 RichText 渲染对象。
    // 数据模型存在全文不能替代绘制完整性。
    for (final value in [title, summary]) {
      final text = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.text(value), matching: find.byType(RichText)),
      );
      expect(text.didExceedMaxLines, false);
    }
    // 滚动宿主下没有固定行高导致的 RenderFlex 溢出。
    // 不屏蔽错误，也不在测试中吞掉绘制异常。
    expect(tester.takeException(), isNull);
  });
}
