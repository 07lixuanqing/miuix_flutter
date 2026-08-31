part of 'main.dart';

/// Immutable sample shown by the source FPS monitor.
@immutable
class ReferenceFpsStats {
  /// Creates one average and one slowest-one-percent measurement.
  const ReferenceFpsStats({required this.average, required this.lowOnePercent});

  /// Empty state used until the source minimum of thirty frames is available.
  static const empty = ReferenceFpsStats(average: 0, lowOnePercent: 0);

  /// Average frames per second across the rolling window.
  final int average;

  /// Average FPS of the slowest one percent of frames in the window.
  final int lowOnePercent;
}

/// Reproduces `computeFpsStats` from the current Kotlin example.
///
/// Durations are expressed in microseconds because Dart's [Duration] exposes
/// that resolution. Integer truncation intentionally matches Kotlin `toInt()`.
@visibleForTesting
ReferenceFpsStats computeReferenceFpsStats(
  Iterable<int> frameDurationsMicroseconds,
) {
  final sorted = frameDurationsMicroseconds.toList()..sort();
  if (sorted.isEmpty) return ReferenceFpsStats.empty;
  final sum = sorted.fold<int>(0, (total, value) => total + value);
  final lowCount = math.max(1, sorted.length ~/ 100);
  var lowSum = 0;
  for (var index = sorted.length - lowCount; index < sorted.length; index++) {
    lowSum += sorted[index];
  }
  return ReferenceFpsStats(
    average: (1000000 / (sum / sorted.length)).truncate(),
    lowOnePercent: (1000000 / (lowSum / lowCount)).truncate(),
  );
}

/// Resolves the source red-yellow-green health ramp for one FPS value.
@visibleForTesting
Color referenceFpsHealthColor(int value, int reference) {
  if (reference == 0 || value == 0) return Colors.grey;
  final percentage = (value / reference).clamp(0.0, 1.0);
  if (percentage >= .75) {
    return Color.lerp(
      const Color(0xFFFFB21D),
      const Color(0xFF36D167),
      (percentage - .75) / .25,
    )!;
  }
  if (percentage >= .5) {
    return Color.lerp(
      const Color(0xFFFF5B29),
      const Color(0xFFFFB21D),
      (percentage - .5) / .25,
    )!;
  }
  return const Color(0xFFFF5B29);
}

/// Top-edge diagnostic matching `utils/FPSMonitor.kt` in the source example.
///
/// It samples display-frame timestamps, retains a rolling five-second window,
/// reports AVG and the slowest one-percent LOW twice per second, and lets the
/// pill be dragged anywhere inside its full-screen overlay.
class _ReferenceFpsMonitor extends StatefulWidget {
  const _ReferenceFpsMonitor({super.key});

  @override
  State<_ReferenceFpsMonitor> createState() => _ReferenceFpsMonitorState();
}

class _ReferenceFpsMonitorState extends State<_ReferenceFpsMonitor>
    with TickerProviderStateMixin {
  static const _windowMicroseconds = 5000000;
  static const _windowFrameCap = 1200;
  static const _minimumSamples = 30;
  static const _refreshMicroseconds = 500000;
  static const _idleThresholdMicroseconds = 500000;
  static const _referenceHistoryMicroseconds = 30000000;
  static const _referenceHistoryCap = 120;

  final ListQueue<int> _samples = ListQueue<int>();
  final ListQueue<_ReferenceAverageTick> _averageHistory =
      ListQueue<_ReferenceAverageTick>();
  final GlobalKey _pillKey = GlobalKey();

  late final Ticker _frameTicker;
  late final AnimationController _averageColorProgress;
  late final AnimationController _lowColorProgress;

  ReferenceFpsStats _stats = ReferenceFpsStats.empty;
  int _sampleSumMicroseconds = 0;
  int? _lastFrameMicroseconds;
  int _nextRefreshMicroseconds = 0;
  Size _parentSize = Size.zero;
  Size _pillSize = Size.zero;
  Offset _offset = Offset.zero;

  Color _averageColorBegin = Colors.grey;
  Color _averageColorTarget = Colors.grey;
  Color _lowColorBegin = Colors.grey;
  Color _lowColorTarget = Colors.grey;

  /// Test-only visibility into the same measurements used by drag clamping.
  Size get debugParentSize => _parentSize;
  Size get debugPillSize => _pillSize;
  Offset get debugOffset => _offset;

  @override
  void initState() {
    super.initState();
    _averageColorProgress = AnimationController.unbounded(vsync: this, value: 1)
      ..addListener(_rebuildForColor);
    _lowColorProgress = AnimationController.unbounded(vsync: this, value: 1)
      ..addListener(_rebuildForColor);
    _frameTicker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    _frameTicker.dispose();
    _averageColorProgress
      ..removeListener(_rebuildForColor)
      ..dispose();
    _lowColorProgress
      ..removeListener(_rebuildForColor)
      ..dispose();
    super.dispose();
  }

  void _rebuildForColor() {
    if (mounted) setState(() {});
  }

  void _onFrame(Duration elapsed) {
    final frameMicroseconds = elapsed.inMicroseconds;
    final previous = _lastFrameMicroseconds;
    if (previous != null) {
      final delta = frameMicroseconds - previous;
      if (delta >= 1 && delta <= _idleThresholdMicroseconds) {
        _samples.addLast(delta);
        _sampleSumMicroseconds += delta;
        while (_sampleSumMicroseconds > _windowMicroseconds &&
            _samples.length > _minimumSamples) {
          _sampleSumMicroseconds -= _samples.removeFirst();
        }
        while (_samples.length > _windowFrameCap) {
          _sampleSumMicroseconds -= _samples.removeFirst();
        }
        if (frameMicroseconds >= _nextRefreshMicroseconds &&
            _samples.length >= _minimumSamples) {
          _publishStats(frameMicroseconds);
        }
      }
    }
    // The source advances this timestamp even for an ignored idle gap.
    _lastFrameMicroseconds = frameMicroseconds;
  }

  void _publishStats(int frameMicroseconds) {
    final nextStats = computeReferenceFpsStats(_samples);
    _averageHistory.addLast(
      _ReferenceAverageTick(frameMicroseconds, nextStats.average),
    );
    while (_averageHistory.length > 1 &&
        frameMicroseconds - _averageHistory.first.timeMicroseconds >
            _referenceHistoryMicroseconds) {
      _averageHistory.removeFirst();
    }
    while (_averageHistory.length > _referenceHistoryCap) {
      _averageHistory.removeFirst();
    }
    var nextReference = 0;
    for (final tick in _averageHistory) {
      nextReference = math.max(nextReference, tick.average);
    }
    _retargetColor(
      controller: _averageColorProgress,
      current: _averageColor,
      target: referenceFpsHealthColor(nextStats.average, nextReference),
      average: true,
    );
    _retargetColor(
      controller: _lowColorProgress,
      current: _lowColor,
      target: referenceFpsHealthColor(nextStats.lowOnePercent, nextReference),
      average: false,
    );
    setState(() {
      _stats = nextStats;
      _nextRefreshMicroseconds = frameMicroseconds + _refreshMicroseconds;
    });
  }

  void _retargetColor({
    required AnimationController controller,
    required Color current,
    required Color target,
    required bool average,
  }) {
    final oldTarget = average ? _averageColorTarget : _lowColorTarget;
    if (target == oldTarget) return;
    if (average) {
      _averageColorBegin = current;
      _averageColorTarget = target;
    } else {
      _lowColorBegin = current;
      _lowColorTarget = target;
    }
    controller
      ..value = 0
      ..animateWith(
        SpringSimulation(
          debugReferenceTabPagerSpring(),
          0,
          1,
          0,
          tolerance: const Tolerance(distance: .01, velocity: .01),
        ),
      );
  }

  Color get _averageColor => Color.lerp(
    _averageColorBegin,
    _averageColorTarget,
    _averageColorProgress.value.clamp(0.0, 1.0),
  )!;

  Color get _lowColor => Color.lerp(
    _lowColorBegin,
    _lowColorTarget,
    _lowColorProgress.value.clamp(0.0, 1.0),
  )!;

  Offset _clampOffset(Offset raw) {
    final xRange = math.max(0.0, (_parentSize.width - _pillSize.width) / 2);
    final yMaximum = math.max(0.0, _parentSize.height - _pillSize.height);
    return Offset(raw.dx.clamp(-xRange, xRange), raw.dy.clamp(0.0, yMaximum));
  }

  void _updateMeasuredSizes(Size parentSize) {
    final pillContext = _pillKey.currentContext;
    final pillRenderBox = pillContext?.findRenderObject();
    final pillSize = pillRenderBox is RenderBox
        ? pillRenderBox.size
        : Size.zero;
    if (_parentSize == parentSize && _pillSize == pillSize) return;
    _parentSize = parentSize;
    _pillSize = pillSize;
    final clamped = _clampOffset(_offset);
    if (clamped != _offset && mounted) {
      setState(() => _offset = clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final materialScheme = Theme.of(context).colorScheme;
    final secondary = MiuixSemanticColors.of(context)['onSurfaceSecondary'];
    final style = theme.textTheme.bodySmall ?? const TextStyle(fontSize: 14);
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentSize = constraints.biggest;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateMeasuredSizes(parentSize);
        });
        return Semantics(
          label: '帧率监视器',
          child: SizedBox.expand(
            child: Align(
              alignment: Alignment.topCenter,
              child: Transform.translate(
                key: const ValueKey('reference-fps-offset'),
                offset: _offset,
                child: Listener(
                  key: _pillKey,
                  behavior: HitTestBehavior.opaque,
                  onPointerMove: (event) {
                    setState(
                      () => _offset = _clampOffset(_offset + event.delta),
                    );
                  },
                  child: Material(
                    key: const ValueKey('reference-fps-pill'),
                    color: materialScheme.surfaceContainerHigh.withValues(
                      alpha: .5,
                    ),
                    shape: const MiuixSquircleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: _stats.average == 0
                          ? Text(
                              '--',
                              key: const ValueKey('reference-fps-empty'),
                              style: style.copyWith(color: secondary),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ReferenceFpsMetric(
                                  key: const ValueKey('reference-fps-average'),
                                  label: 'AVG ',
                                  value: _stats.average,
                                  color: _averageColor,
                                  secondary: secondary,
                                  style: style,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: Text(
                                    '·',
                                    style: style.copyWith(color: secondary),
                                  ),
                                ),
                                _ReferenceFpsMetric(
                                  key: const ValueKey('reference-fps-low'),
                                  label: 'LOW ',
                                  value: _stats.lowOnePercent,
                                  color: _lowColor,
                                  secondary: secondary,
                                  style: style,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReferenceFpsMetric extends StatelessWidget {
  const _ReferenceFpsMetric({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.secondary,
    required this.style,
  });

  final String label;
  final int value;
  final Color color;
  final Color secondary;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: label,
          style: TextStyle(color: secondary),
        ),
        TextSpan(
          text: '$value',
          style: TextStyle(color: color),
        ),
      ],
    ),
    style: style,
  );
}

class _ReferenceAverageTick {
  const _ReferenceAverageTick(this.timeMicroseconds, this.average);

  final int timeMicroseconds;
  final int average;
}
