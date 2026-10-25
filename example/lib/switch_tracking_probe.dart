// 独立 Release 验证入口，不接入示例默认首页或正式业务应用。
// 诊断消息使用逐行 JSON，主机只读取固定前缀。
import 'dart:convert';
// 分块只限制日志长度，不参与开关业务判断。
import 'dart:math' as math;

// 同步日志只用于此独立入口，避免调试节流丢掉采样。
import 'package:flutter/foundation.dart';
// 使用真实应用宿主，保留正常主题和手势环境。
import 'package:flutter/material.dart';
// 绘制后采样可观察实际跟随，而不是仅记录目标值。
import 'package:flutter/scheduler.dart';
// 与正式客户端使用同一份外部控件实现。
import 'package:flutter_miuix/flutter_miuix.dart';

// 页面仅包含本地开关，没有账号、权限请求或网络调用。
void main() => runApp(
  // 不装载示例默认首页，避免其他动画或网络工作干扰采样。
  const MaterialApp(
    // 主题和颜色动画保持开启，不通过减少动态效果降低误差。
    home: MiuixTheme(
      child: Scaffold(
        // 几何自动包含系统安全区，主机不硬编码状态栏高度。
        body: SafeArea(
          child: Column(
            // 三个样本居中放置，为两侧越界拖动留出空间。
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('开关验证'),
              // 普通关闭态使用真实圆形滑块命中区域。
              _TraceSwitch(id: 'off', initial: false),
              // 开启态用于验证相反方向是否同样跟随。
              _TraceSwitch(id: 'on', initial: true),
              // 设置行封装覆盖隐私锁同类控件的实际调用形态。
              _TraceSwitch(id: 'preference', initial: false, preference: true),
            ],
          ),
        ),
      ),
    ),
  ),
);

// 三个样本分别覆盖关闭态、开启态及实际设置行封装。
class _TraceSwitch extends StatefulWidget {
  const _TraceSwitch({
    required this.id,
    required this.initial,
    this.preference = false,
  });
  // 标识只区分固定测试样本，不包含用户或设备身份。
  final String id;
  // 所有初始值在测试启动时确定，不读取持久偏好。
  final bool initial, preference;
  @override
  State<_TraceSwitch> createState() => _TraceSwitchState();
}

class _TraceSwitchState extends State<_TraceSwitch> {
  // 只保存当前测试页面状态，关闭后不写任何偏好或数据库。
  // 本地布尔值只接受当前样本的回调。
  late bool _value = widget.initial;
  // 按下状态控制采样，空闲时不主动驱动刷新。
  bool _held = false, _geometrySent = false, _initial = false;
  // 序列号与回调计数让主机发现缺帧、误提交或外部干扰。
  int _sequence = 0, _commits = 0, _startCommits = 0, _lastInput = 0;
  // 记录指针路径的独立预期，以及相对按下点的位移。
  // 指针累计位移与滑块约束位移分开，能识别端点外移动。
  double _expected = 0, _distance = 0;
  // 采样与输入都用同一单调时钟，不能混用系统日期时间。
  final _clock = Stopwatch()..start();
  // 只保留当前手势原始值，结束后分块输出。
  final _samples = <List<num>>[];

  // 只发出人工测试的几何与时序，不读取其他应用日志或用户数据。
  // 固定前缀使主机无需保存应用或系统的其他日志。
  void _emit(Map<String, Object?> value) =>
      debugPrintSynchronously('SWITCH_PROBE ${jsonEncode(value)}');

  // 渲染对象查找只在当前样本子树中进行。
  RenderBox _box(String key) {
    // 不跨样本缓存键，三个相同组件的内部键可各自存在。
    Element? found;
    void visit(Element element) {
      // 匹配控件实际绘制节点，不读取控制器私有状态。
      if (element.widget.key == ValueKey(key)) found = element;
      // 递归到实际组件内部，保持与默认组件层级兼容。
      element.visitChildren(visit);
    }

    // 每次读取当前树，不缓存可能已被父组件重建的渲染对象。
    context.visitChildElements(visit);
    // 缺少节点直接失败，不能返回一个假的正常坐标。
    return found!.findRenderObject()! as RenderBox;
  }

  double _left() {
    // 圆心坐标包含当前按压缩放变换。
    final thumb = _box('miuix-switch-thumb');
    // 轨道坐标提供本地原点，页面居中不影响位移比较。
    final track = _box('miuix-switch-track');
    // 取圆心再扣除半径，按下放大不会被误算成水平拖动。
    // 以实际圆心计算，避免视觉放大被误当成水平移动。
    return thumb.localToGlobal(thumb.size.center(Offset.zero)).dx -
        track.localToGlobal(Offset.zero).dx -
        // 半径来自公开尺寸，不能按某次截图猜测滑块宽度。
        MiuixSwitchDefaults.thumbSize / 2;
  }

  @override
  void initState() {
    super.initState();
    // 首帧布局完成后才能发送有效几何。
    WidgetsBinding.instance.addPostFrameCallback(_frame);
  }

  void _frame(Duration _) {
    // 组件销毁后不再访问渲染树或安排采样。
    if (!mounted) return;
    // Android 首帧可能仍携带启动时的占位尺寸，不能据此生成手机坐标。
    final view = View.of(context);
    // 等窗口指标和 MediaQuery 一致后，再采集实际屏幕几何。
    final media = MediaQuery.of(context);
    if (!_geometrySent &&
        (_clock.elapsedMilliseconds < 600 ||
            view.physicalSize.isEmpty ||
            media.devicePixelRatio != view.devicePixelRatio ||
            media.size != view.physicalSize / view.devicePixelRatio)) {
      // 这里只等待独立验证页面完成布局，不改变真实开关或输入时序。
      SchedulerBinding.instance.scheduleFrame();
      WidgetsBinding.instance.addPostFrameCallback(_frame);
      return;
    }
    // 初始几何只发一次，主机据此生成坐标计划。
    if (!_geometrySent) {
      final track = _box('miuix-switch-track');
      // 转换到当前屏幕的逻辑坐标，像素比由独立字段提供。
      final top = track.localToGlobal(Offset.zero);
      _emit({
        'kind': 'geometry',
        'id': widget.id,
        // 主机只乘一次密度，避免物理与逻辑像素重复换算。
        'ratio': MediaQuery.devicePixelRatioOf(context),
        // 轨道左侧与滑块端点分别保存，便于独立复算中心位置。
        'left': top.dx,
        // 触摸纵坐标取轨道中心，防止垂直手势竞争干扰。
        'centerY': top.dy + track.size.height / 2,
        // 记录真实本地状态，主机检查每次提交是否生效。
        'value': _value,
      });
      // 后续帧只采样位置，不重复发送启动参数。
      _geometrySent = true;
    }
    // 每一段连续按下都会采样完整往返过程。
    if (_held) {
      // 采样发生在绘制后，记录实际布局而不是动画控制器的目标值。
      // 同时记录距离最近输入的时间，便于发现长时间空转。
      final now = _clock.elapsedMicroseconds;
      // 每行保存时间、输入年龄、实际位置、预期位置与指针位移。
      _samples.add([now, now - _lastInput, _left(), _expected, _distance]);
      // 持续采样才能发现指针静止后滑块仍沿旧速度移动的情况。
      // 只有按下期间主动请求帧，保证静止后的旧速度也能被发现。
      SchedulerBinding.instance.scheduleFrame();
    }
    WidgetsBinding.instance.addPostFrameCallback(_frame);
  }

  // 新手势从当前可见位置开始，不能假设它已经静止在端点。
  void _down(PointerDownEvent event) {
    // 每个样本独立递增，主机据计划逐段匹配。
    _sequence++;
    // 保存真实起始值，取消或原路返回后必须保持相同。
    _initial = _value;
    // 仅统计本段产生的回调，前一段提交不会污染结果。
    _startCommits = _commits;
    // 预期从实际抓取位置起算，支持检查动画途中的接手。
    _expected = _left();
    _distance = 0;
    // 输入与采样共享时钟，时间差不会受到时区影响。
    _lastInput = _clock.elapsedMicroseconds;
    // 每段重新保存帧，避免跨段混入旧轨迹。
    _samples.clear();
    // 采样本身不修改开关值，也不主动触发业务回调。
    _held = true;
    SchedulerBinding.instance.scheduleFrame();
  }

  // 父级监听仅观察输入，不拦截子控件的真实手势竞争。
  void _move(PointerMoveEvent event) {
    // 忽略已经结束之后的孤立移动事件。
    if (!_held) return;
    _lastInput = _clock.elapsedMicroseconds;
    // 保留原始方向，不能把正反运动都累计成绝对距离。
    _distance += event.delta.dx;
    // 这是测试预期：一比一位移且两端不积压，实际值独立取渲染圆心。
    // 端点范围是测试约定；实际位置来自另一条渲染读取链路。
    _expected = (_expected + event.delta.dx).clamp(4.0, 25.0);
  }

  // UP 与 CANCEL 分别记录，主机核对取消有没有误提交。
  void _finish({required bool cancelled}) {
    if (!_held) return;
    // 结束后停止主动采样，避免空闲帧混入拖动误差。
    _held = false;
    // 复制当前帧引用列表，下一段清空容器不会破坏本段数据。
    final frames = List<List<num>>.of(_samples);
    // 把序列和开始计数固化，供提交后的异步输出使用。
    final sequence = _sequence,
        initial = _initial,
        startCommits = _startCommits;
    // Listener 先于手势提交收到 UP，等本帧结束后再读取最终回调结果。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emit({
        'kind': 'result',
        'id': widget.id,
        'sequence': sequence,
        // 结束消息保留起始值，不能只观察最后一帧位置。
        'initial': initial,
        'value': _value,
        // 区分视觉到端点和真正触发了受控值回调。
        'commits': _commits - startCommits,
        // 取消段不允许出现正常提交，测试结果由主机判断。
        'cancelled': cancelled,
        // 声明帧数供主机检查日志是否被截断。
        'frames': frames.length,
      });
      // 每行限制大小，防止 Android 日志行上限截掉长序列。
      // 每块最多十六帧，保持单条日志远小于系统行长上限。
      for (var i = 0; i < frames.length; i += 16) {
        _emit({
          'kind': 'frames',
          'id': widget.id,
          'sequence': sequence,
          // 最后不足一块时只输出真实记录，不补造空帧。
          'rows': frames.sublist(i, math.min(i + 16, frames.length)),
        });
      }
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  // 只记录控件回调，不替它实现阈值或拖动逻辑。
  void _changed(bool value) => setState(() {
    // 父级同步接受新状态，让下一手势走真实受控组件流程。
    _value = value;
    // 每次回调都计数，便于检出重复提交。
    _commits++;
  });

  @override
  Widget build(BuildContext context) => Padding(
    // 内边距只用于安排测试位置，不改变控件轨道几何。
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
    // 监听不消耗事件，真正的拖动仍由库内识别器处理。
    child: Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: (_) => _finish(cancelled: false),
      // 系统取消与正常松手分别进入结果记录。
      onPointerCancel: (_) => _finish(cancelled: true),
      // 切换的是封装形态，底层开关实现没有另一套替身。
      child: widget.preference
          ? MiuixSwitchPreference(
              title: '设置开关',
              value: _value,
              onChanged: _changed,
            )
          : Column(
              children: [
                Text(widget.id),
                const SizedBox(height: 12),
                MiuixSwitch(value: _value, onChanged: _changed),
              ],
            ),
    ),
  );
}
