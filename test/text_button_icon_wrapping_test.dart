// 测试公开文字按钮入口，避免应用自行包一层不同的图标布局。
import 'package:flutter/material.dart';
// 布局与点击使用框架真实管线，不手写结果替身。
import 'package:flutter_test/flutter_test.dart';
// 公开包入口与下游应用相同，确保修复能被实际依赖取得。
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  // 普通标签按钮和文字按钮共用完整阅读契约，不能只修后者。
  for (final ordinary in [false, true]) {
    // 同时检查手机窄区和普通卡片宽度，不只覆盖平板宽屏。
    for (final width in [120.0, 244.0]) {
      // 字号通过系统缩放传入，标签内容在两个场景中保持相同。
      for (final scale in [1.0, 2.0]) {
        // 方向性变化不能导致图标挤压文字或破坏操作顺序。
        for (final direction in TextDirection.values) {
          testWidgets(
            'icon button wraps ordinary=$ordinary $width $scale $direction',
            (tester) async {
              // 长标签包含连续中文，真实应用还会使用正式中文字体复测。
              const label = '管理系统权限并查看健康数据用途与隐私说明';
              // 每例独立计数，捕获重排造成的重复回调。
              var taps = 0;
              // 提供正常主题与方向性依赖，避免缺失宿主导致假失败。
              await tester.pumpWidget(
                MaterialApp(
                  home: MediaQuery(
                    // 系统缩放作用于整个按钮，标签原文始终保持不变。
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    // 使用库默认样式，不替换为测试专用可换行控件。
                    child: MiuixTheme(
                      child: Directionality(
                        // RTL 只改变图标排列方向，不改变可用宽度约束。
                        textDirection: direction,
                        child: Center(
                          // 有限宽度来自父卡片，按钮不应靠扩大卡片躲过溢出。
                          child: SizedBox(
                            // 这是父布局上界，长内容应自然长高而不能撑宽卡片。
                            width: width,
                            child: ordinary
                                ? MiuixButton(
                                    // 与文字按钮使用同样原文、图标及边距，不为主按钮缩短标签。
                                    label: label,
                                    icon: const Icon(
                                      Icons.privacy_tip_outlined,
                                      size: 18,
                                    ),
                                    insideMargin: const EdgeInsets.all(6),
                                    onPressed: () => taps++,
                                  )
                                : MiuixTextButton(
                                    // 同时提供标签和图标，命中本次修复的兼容路径。
                                    label: label,
                                    icon: const Icon(
                                      Icons.privacy_tip_outlined,
                                      size: 18,
                                    ),
                                    // 明确正文字号，和健康设置页的次要操作一致。
                                    textStyle: const TextStyle(fontSize: 14),
                                    // 保留图标两侧留白，不能靠去掉内边距规避溢出。
                                    insideMargin: const EdgeInsets.all(6),
                                    // 换行后的整颗按钮仍只有同一个点击动作。
                                    onPressed: () => taps++,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              // 布局和按压状态完成后再读取实际几何。
              await tester.pumpAndSettle();
              // 检查实际框架异常，不能把溢出当作截图上的轻微装饰。
              expect(tester.takeException(), isNull);
              // 检查正式 Text 的配置，不只看一张可能被裁剪的截图。
              final text = tester.widget<Text>(find.text(label));
              // 标签必须全部保留，自然换行而非省略号或强制一行。
              expect(text.maxLines, isNull);
              // 行数无限之外，还要确认实际允许换行。
              expect(text.softWrap, isTrue);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
              // 矩形来自正式渲染对象，不能用理论字宽替代实际布局。
              final buttonFinder = find.byType(
                ordinary ? MiuixButton : MiuixTextButton,
              );
              final button = tester.getRect(buttonFinder);
              // 同时核对全文所在区域，覆盖图标与标签的宽度分配。
              final content = tester.getRect(find.text(label));
              // 文本要处在按钮内部，方向性不改变可读区域边界。
              expect(button.contains(content.topLeft), isTrue);
              expect(
                // 右下边界不包含自身，因此只放宽极小的边界数值误差。
                button.contains(content.bottomRight - const Offset(.01, .01)),
                isTrue,
              );
              // 换行不能牺牲可点击性；完整操作只发送一次回调。
              // 点击实际可交互区域，不直接调用回调。
              await tester.tap(buttonFinder);
              await tester.pumpAndSettle();
              // 松手后回调必须恰好一次，避免多行文字引起重复点击。
              // 输入过程也不能让已经适配的布局再次溢出。
              expect(taps, 1);
            },
          );
        }
      }
    }
  }
}
