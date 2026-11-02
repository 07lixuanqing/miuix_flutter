import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

// 使用真实表面和响应式子项，不以两个固定空盒掩盖卡片背景问题。
// LayoutBuilder 是关键边界：IntrinsicHeight 无法对它查询固有尺寸。
// 内层 Column 接受最小高度，使背景实际补齐到同行底部。
// 短文本让测试专注几何，完整长中文由后面的独立场景覆盖。
// 可选回调用于验证增高后的底部不是只能展示、无法点击。
Widget card(String id, double height, {VoidCallback? onTap}) => MiuixCard(
  key: ValueKey(id),
  // 关闭玻璃避免背景模糊层影响几何测试的执行开销。
  glass: false,
  onTap: onTap,
  child: LayoutBuilder(
    builder: (context, constraints) => Column(
      children: [SizedBox(height: height, child: Text('完整中文内容 $id'))],
    ),
  ),
);

// 宽度由滚动页面提供，高度由内容确定，与首页的实际约束一致。
// 不套固定高度或 IntrinsicHeight，否则会掩盖自然测量错误。
// 本地字号直接作用于正文，不只把最终截图按比例放大。
// Directionality 显式设置，避免测试机器语言改变左右断言。
// 使用 MaterialApp 提供 MiuixCard 所需的正常主题环境。
// 每次挂载均由测试框架卸载，夹具本身不持有长期订阅。
Widget page(Widget child, {bool rtl = false, double scale = 1}) => MaterialApp(
  home: Directionality(
    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  ),
);

void main() {
  // 两个不等高卡片最容易暴露仅靠 Row 顶端对齐的旧行为。
  // 只有一次 pumpWidget，不能等待后置测量再掩盖首帧跳动。
  // 尺寸比较针对 MiuixCard，不比较本来就等高的外层行。
  // 左右间距也检查，避免用重叠两个表面实现假对齐。
  // 卡片背景属于完整可点击区域，不让补齐底部成为死区。
  // 手势仍由原卡片处理，行组件不拦截用户输入。
  // takeException 检查可能被渲染框架暂存的溢出错误。
  // 测量中的 LayoutBuilder 必须正常运行，不能跳过其子树。
  testWidgets('equal cards measure LayoutBuilder before the first paint', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      page(
        MiuixEqualHeightRow(
          children: [
            card('a', 50, onTap: () => tapped = true),
            card('b', 180),
          ],
        ),
      ),
    );
    // 首次布局已完成，不允许依赖第二帧 setState 来追平高度。
    final a = find.byKey(const ValueKey('a'));
    // 稳定键区分两张卡片，不依赖树中的偶然出现顺序。
    final b = find.byKey(const ValueKey('b'));
    // 同尺寸和同顶边一起成立，才能保证底边也一致。
    expect(tester.getRect(a).size, tester.getRect(b).size);
    expect(tester.getRect(a).top, tester.getRect(b).top);
    expect(tester.getRect(a).right + 16, tester.getRect(b).left);
    // 点击补齐区域也必须进入原卡片，不能成为空白死区。
    await tester.tapAt(tester.getRect(a).bottomCenter - const Offset(0, 8));
    expect(tapped, isTrue);
    // 构建成功不代表布局成功，必须读取框架记录的异常。
    expect(tester.takeException(), isNull);
  });

  // 子项自主刷新与父页面整体重建的触发布局路径不同。
  // 测试故意不重新 pumpWidget，让旧行保持同一个 RenderObject。
  // 先增高再缩短，同时防止首次测量锁死和历史最大值缓存。
  // 数字均明显大于文本行高，尺寸差不会被字体舍入掩盖。
  // ValueNotifier 模拟健康摘要或网络数据在稍后返回。
  // 父行必须使用子尺寸依赖，不能由紧约束隔断更新传播。
  // 一次 pump 应完成当前数据的布局，不额外等待动画兜底。
  // 用原始高度作参照，避免仅验证两个错误的高度碰巧相等。
  testWidgets('async content can grow and shrink the whole row', (
    tester,
  ) async {
    final height = ValueNotifier(180.0);
    // 每项测试释放监听对象，不让并行回归残留跨测试更新。
    addTearDown(height.dispose);
    await tester.pumpWidget(
      page(
        MiuixEqualHeightRow(
          children: [
            card('a', 50),
            // 仅子项重建，验证内容变化仍能通知父布局重新测量。
            ValueListenableBuilder<double>(
              valueListenable: height,
              builder: (context, value, _) => card('b', value),
            ),
          ],
        ),
      ),
    );
    final a = find.byKey(const ValueKey('a'));
    final b = find.byKey(const ValueKey('b'));
    // 原高度在数据变化前采样，后续两轮更新使用相同节点。
    final original = tester.getSize(a).height;
    // 增长只来自右侧卡片，左侧内容始终保持不变。
    height.value = 260;
    await tester.pump();
    expect(tester.getSize(a).height, greaterThan(original));
    // 短卡背景要同步增长，不能只改变较长卡片。
    expect(tester.getSize(a), tester.getSize(b));
    // 再减少内容，左侧不能继续保持之前的高卡高度。
    height.value = 60;
    await tester.pump();
    expect(tester.getSize(a).height, lessThan(original));
    // 高度缩回后仍须对齐，不能残留第二次布局的最小高度。
    expect(tester.getSize(a), tester.getSize(b));
    expect(tester.takeException(), isNull);
  });

  // 大字号正文自然换行，卡片不能以固定高度或行数裁切。
  // 长中文不含空格，覆盖与拉丁文本不同的断行方式。
  // 同时使用 RTL，确保几何翻转不会改变阅读和测量规则。
  // 长内容放在第一项，补充上一项长内容位于第二项的情形。
  // 这里不依赖某个字体的精确像素高度，只比较必要关系。
  // ScrollView 提供正文所需空间，超一屏也允许继续阅读。
  // RenderParagraph 检查所有已挂载段落，包括视口之外正文。
  // 不能通过缩短字符串或仅检查图片文件是否存在通过测试。
  testWidgets('RTL and 200 percent text retain all natural height', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(
        MiuixEqualHeightRow(
          children: [
            MiuixCard(
              key: const ValueKey('long'),
              child: Text(List.filled(12, '长中文说明必须完整展示').join('，')),
            ),
            card('short', 50),
          ],
        ),
        rtl: true,
        scale: 2,
      ),
    );
    final long = find.byKey(const ValueKey('long'));
    // 文字内容独立于方向，换方向不应交换两人的业务资料。
    final short = find.byKey(const ValueKey('short'));
    // 方向改变只调整位置，不改变两列的尺寸或完整阅读能力。
    expect(tester.getSize(long), tester.getSize(short));
    expect(tester.getRect(long).left, greaterThan(tester.getRect(short).left));
    for (final node in find.byType(RichText).evaluate()) {
      // 字形可能因测试字体不同而变化，但不得提前省略正文。
      final paragraph = node.renderObject! as RenderParagraph;
      expect(paragraph.didExceedMaxLines, isFalse);
    }
    expect(tester.takeException(), isNull);
  });

  // 初次数据为空或筛选后只剩一张卡片也是合法页面状态。
  // 空行必须有已定义尺寸，不能发生除以零或 NaN 几何。
  // 默认父级没有最小高度，因此空行不占据额外纵向空间。
  // 单项占满父级宽度，不沿用双列时的间距和半宽。
  // 两次挂载用于覆盖从空集合变为非空集合的生命周期。
  // 不需要添加无语义的空卡片来填满第二列。
  // 此处只检查公共几何契约，不复制内部列宽计算公式。
  testWidgets('empty and single rows keep valid geometry', (tester) async {
    await tester.pumpWidget(page(const MiuixEqualHeightRow(children: [])));
    // 空状态先完成真实布局，后续才添加数据。
    expect(tester.getSize(find.byType(MiuixEqualHeightRow)).height, 0);
    await tester.pumpWidget(
      page(MiuixEqualHeightRow(children: [card('only', 60)])),
    );
    // 单项应使用全部宽度，不能留下不存在的第二列或间距。
    expect(
      tester.getSize(find.byKey(const ValueKey('only'))).width,
      tester.getSize(find.byType(MiuixEqualHeightRow)).width,
    );
    expect(tester.takeException(), isNull);
  });
}
