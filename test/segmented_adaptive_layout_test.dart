import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

// 使用长中文和真实控件，不用缩短标签规避窄屏问题。
// 默认未展开也必须适应父卡片，不要求每个使用方临时加 expanded。
// 极窄宽度允许纵向排列，按键和点击仍沿现有索引规则。
// 两种父宽度分别触发横向等分和纵向排列。
// 两种字号分别覆盖普通文字和系统200%设置。
// 标签保留完整中文，不以短文案代替真实内容。
// 视口固定为400宽，控件只能使用其父卡片给出的空间。
// 每次测试单独创建选择回调，避免跨尺寸状态污染。
// 默认 expanded 保持关闭，验证的是自动边界处理。
// 显式 source 高度契约由原套件继续覆盖。
// 当前用例只检查默认自适应路径。
// 实际 RenderParagraph 必须允许全文，而不是仅保留原始 data。
// 点击通过公开命中区域进行，布局不能改变业务选项。
// 独立字号案例在销毁时恢复测试视口。
// 选中列表只有本地人工标签，不访问真实任务。
// 长选项在横排中采用共同高度，底边应始终可访问。
// 纵排仍使用相同值数组，不重排或跳过选项。
// 测试失败应保留渲染溢出，不能通过忽略异常验收。
// 颜色层次由其他用例验证，这里专注布局和交互。
// 键盘导航沿原控制器逻辑，组件没有新增一份索引状态。
// 系统文字缩放通过 MediaQuery 传入。
// 测量与绘制采用同一份选项原文。
// 这些宽度是边界夹具，不是厂商设计令牌。
// 单选行为与原来的受控选择状态保持一致。
// 自动等分只作用于有限父约束，独立选项继续自然布局。
// 纵向排列使用原值数组，点击仍映射到相同值。
// 测量以选中时的较大字重预留安全高度。
// 边界留量覆盖表面边框与内部间距。
// 相同尺寸重复渲染应稳定，不因选项切换跳高。
// 默认控件可增高，调用方无需手写每项高度。
// 测试不改变主题来源或字形缩放的业务偏好。
void main() {
  // 健康图表的紧凑周期选择器使用 source 和固定父高。
  // 三个短选项足够横排，不能被通用窄屏阈值改成纵排。
  // 这里保留真实父约束，避免只在无限高度容器中测试。
  // source 的显式高度与默认自适应模式是不同的几何契约。
  testWidgets('source stays horizontal in compact fixed-height host', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MiuixTheme(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 144,
                height: 50,
                child: MiuixSegmentedControl<String>.source(
                  values: ['日', '周', '月'],
                  selected: {'日'},
                  labelBuilder: _shortLabel,
                  onSelectionChanged: _ignoreSelection,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // 三项共享水平中心线，且最后一项保持在父宽以内。
    // 同时检查框架异常，不能以视觉裁剪隐藏纵向溢出。
    expect(
      tester.getCenter(find.text('日')).dy,
      tester.getCenter(find.text('月')).dy,
    );
    expect(tester.takeException(), isNull);
  });
  for (final width in [100.0, 240.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'segmented default wraps full labels width=$width scale=$scale',
        (tester) async {
          final changes = <Set<String>>[];
          const labels = ['每日健康指标', '完整运动记录', '按周期汇总'];
          // 每一种尺寸单独建树，不继承前一测试的布局状态。
          tester.view.physicalSize = const Size(400, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MiuixTheme(
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: width,
                      child: MiuixSegmentedControl<String>(
                        values: labels,
                        selected: const {'每日健康指标'},
                        labelBuilder: (value) => value,
                        multipleSelection: false,
                        allowEmptySelection: false,
                        onSelectionChanged: changes.add,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          // 完整原文必须可绘制，不仅是在 Text.data 里仍能找到。
          for (final label in labels) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find
                  .descendant(
                    of: find.text(label),
                    matching: find.byType(RichText),
                  )
                  .first,
            );
            expect(paragraph.maxLines, isNull);
            expect(paragraph.didExceedMaxLines, isFalse);
          }
          // 直接点击完整选项，自动换行和排列不能改变选择含义。
          await tester.tap(find.text('完整运动记录'));
          await tester.pumpAndSettle();
          expect(changes, [
            {'完整运动记录'},
          ]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

// const source 夹具使用顶层回调，不引入额外的受控状态。
// 内容保持原样，仅验证兼容模式的几何行为。
String _shortLabel(String value) => value;
void _ignoreSelection(Set<String> values) {}
