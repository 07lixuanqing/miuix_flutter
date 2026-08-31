part of 'main.dart';

/// Drives the two independent clocks used by the current source background.
///
/// `BgEffectModifier` advances point/noise time continuously, while
/// `BgEffectBackground` advances a separate four-stage color cycle after a
/// preset-specific delay. Keeping both clocks here lets the Blur and About
/// examples share identical pause, resume, theme-change, and disposal rules.
class _ReferenceEffectBackgroundController extends ChangeNotifier {
  _ReferenceEffectBackgroundController({
    required TickerProvider vsync,
    required bool dynamic,
    required bool os3,
    bool freeze = false,
  }) : _dynamic = dynamic,
       _os3 = os3,
       _freeze = freeze,
       elapsed = AnimationController(
         vsync: vsync,
         duration: const Duration(hours: 1),
       ),
       colorStage = AnimationController.unbounded(vsync: vsync, value: 0) {
    elapsed.addListener(notifyListeners);
    colorStage.addListener(notifyListeners);
    if (_dynamic && !_freeze) elapsed.forward();
  }

  /// Long-running source point/noise clock.
  final AnimationController elapsed;

  /// Spring-driven `colors2 -> colors1 -> colors2 -> colors3` stage.
  final AnimationController colorStage;

  final bool _freeze;
  bool _dynamic;
  bool _os3;
  Brightness? _brightness;
  int _loopGeneration = 0;

  /// Current point/noise time in seconds.
  double get elapsedSeconds => elapsed.value * 3600;

  /// Current fractional source color stage.
  double get stage => colorStage.value;

  /// Applies state that Compose uses as `LaunchedEffect` keys.
  void configure({
    required Brightness brightness,
    required bool dynamic,
    required bool os3,
  }) {
    final changed =
        _brightness != brightness || _dynamic != dynamic || _os3 != os3;
    if (!changed) return;
    _brightness = brightness;
    _dynamic = dynamic;
    _os3 = os3;
    if (_dynamic && !_freeze) {
      elapsed.forward();
    } else {
      elapsed.stop();
    }
    _restartColorLoop();
  }

  void _restartColorLoop() {
    final generation = ++_loopGeneration;
    colorStage.stop();
    if (!_dynamic || !_os3 || _freeze || _brightness == null) return;
    unawaited(_runColorLoop(generation, _brightness!));
  }

  Future<void> _runColorLoop(int generation, Brightness brightness) async {
    // The PHONE_LIGHT/PHONE_DARK periods are 5s and 8s. The source waits half
    // that period before every spring transition.
    final delay = brightness == Brightness.dark
        ? const Duration(seconds: 4)
        : const Duration(milliseconds: 2500);
    const stiffness = 35.0;
    final spring = SpringDescription(
      mass: 1,
      stiffness: stiffness,
      damping: 2 * .9 * math.sqrt(stiffness),
    );
    var target = colorStage.value.floorToDouble() + 1;
    while (!_disposed && generation == _loopGeneration) {
      try {
        // A ticker-backed stationary simulation reproduces delay() but is
        // immediately cancelable when the owning route leaves the tree.
        await colorStage
            .animateWith(
              _ReferenceHoldSimulation(
                colorStage.value,
                delay.inMicroseconds / Duration.microsecondsPerSecond,
              ),
            )
            .orCancel;
        if (_disposed || generation != _loopGeneration) return;
        await colorStage
            .animateWith(
              SpringSimulation(
                spring,
                colorStage.value,
                target,
                0,
                snapToEnd: true,
                tolerance: const Tolerance(distance: .01, velocity: .01),
              ),
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
      target += 1;
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    _loopGeneration++;
    elapsed.dispose();
    colorStage.dispose();
    super.dispose();
  }
}

/// Cancelable ticker-backed equivalent of the source coroutine's delay.
class _ReferenceHoldSimulation extends Simulation {
  _ReferenceHoldSimulation(this.value, this.seconds);

  final double value;
  final double seconds;

  @override
  double x(double time) => value;

  @override
  double dx(double time) => 0;

  @override
  bool isDone(double time) => time >= seconds;
}
