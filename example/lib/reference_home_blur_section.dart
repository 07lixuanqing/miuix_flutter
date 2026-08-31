part of 'main.dart';

/// Test-only switch that holds the shader at its source zero phase.
///
/// Runtime examples leave this false and preserve the official behavior:
/// disabling the dynamic background freezes the current elapsed phase.
@visibleForTesting
bool debugFreezeReferenceBlurBackground = false;

/// Rounds a Dart double through the IEEE-754 binary32 format used by Kotlin's
/// `Float`. The source blur demo stores every adjustable value in a
/// `mutableFloatStateOf`, so retaining Dart's wider binary64 precision changes
/// both the displayed truncation and a few slider-derived shader inputs.
double _referenceFloat32(double value) {
  final storage = Float32List(1)..[0] = value;
  return storage[0];
}

/// Reproduces `(value * factor).toInt() / factor.toFloat()` from the source.
///
/// Quantizing the multiplication and division separately matters for the
/// default noise coefficient: Kotlin's `0.0045f * 10000` is just below 45,
/// therefore the original UI deliberately displays `0.0044`, not `0.0045`.
String _referenceTruncatedFloat(double value, int places) {
  final factor = math.pow(10, places).toDouble();
  final product = _referenceFloat32(
    _referenceFloat32(value) * _referenceFloat32(factor),
  );
  final truncated = product.truncate();
  // Dart widens the binary32 quotient back to binary64, whose `toString`
  // would expose digits such as `0.004399999976158142`. Kotlin's
  // `Float.toString` instead emits the shortest familiar decimal. Fixed-width
  // formatting followed by source-compatible zero trimming reproduces that
  // visible text while keeping at least the `.0` used for whole Float values.
  var text = (truncated / factor).toStringAsFixed(places);
  while (text.endsWith('0') && !text.endsWith('.0')) {
    text = text.substring(0, text.length - 1);
  }
  return text;
}

/// Exact localized reconstruction of the source Texture Blur, Foreground Blur,
/// and Progressive Blur demonstrations. State values, card metrics, preset
/// order, and control ranges follow `component/BlurSection.kt`.
class _ReferenceBlurSection extends StatefulWidget {
  const _ReferenceBlurSection();

  @override
  State<_ReferenceBlurSection> createState() => _ReferenceBlurSectionState();
}

class _ReferenceBlurSectionState extends State<_ReferenceBlurSection>
    with TickerProviderStateMixin {
  static const double _previewHeight = 280;
  static final double _defaultNoise = _referenceFloat32(.0045);

  double _textureBlur = 100;
  double _textureNoise = _defaultNoise;
  double _textureBrightness = 0;
  double _textureContrast = 1;
  double _textureSaturation = 1;
  int _textureBlendIndex = 5;
  int _textureHighlightIndex = 3;

  double _foregroundBlur = 200;
  double _foregroundNoise = _defaultNoise;
  double _foregroundBrightness = 0;
  double _foregroundContrast = 1;
  double _foregroundSaturation = 1;
  int _foregroundBlendIndex = 1;
  bool _dynamicBackground = true;
  bool _foregroundOs3 = true;

  double _progressiveBlur = 20;
  double _progressiveNoise = MiuixBlurDefaults.progressiveNoiseCoefficient;
  double _progressiveStart = 0;
  double _progressiveEnd = 1;
  double _progressiveCurve = 1;
  int _progressiveBlendIndex = 0;
  int _progressiveDirectionIndex = 0;

  MiuixDeviceTilt _deviceTilt = MiuixDeviceTilt.zero;
  StreamSubscription<MiuixDeviceTilt>? _tiltSubscription;

  late final _ReferenceEffectBackgroundController _backgroundMotion;
  ui.FragmentShader? _effectBackgroundShader;

  @override
  void initState() {
    super.initState();
    _backgroundMotion = _ReferenceEffectBackgroundController(
      vsync: this,
      dynamic: _dynamicBackground,
      os3: _foregroundOs3,
      freeze: debugFreezeReferenceBlurBackground,
    );
    _tiltSubscription = MiuixDeviceTiltSensor.events.listen(
      (tilt) {
        if (mounted) setState(() => _deviceTilt = tilt);
      },
      // Desktop, widget-test, and Android hosts that omit the plugin preserve
      // the source's neutral no-sensor fallback instead of failing the page.
      onError: (Object _) {},
    );
    unawaited(_loadEffectBackgroundShader());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: _dynamicBackground,
      os3: _foregroundOs3,
    );
  }

  Future<void> _loadEffectBackgroundShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/miuix_effect_background.frag',
    );
    if (!mounted) return;
    setState(() => _effectBackgroundShader = program.fragmentShader());
  }

  @override
  void dispose() {
    unawaited(_tiltSubscription?.cancel());
    _backgroundMotion.dispose();
    _effectBackgroundShader?.dispose();
    super.dispose();
  }

  void _setDynamicBackground(bool value) {
    setState(() => _dynamicBackground = value);
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: value,
      os3: _foregroundOs3,
    );
  }

  void _setForegroundOs3(int index) {
    setState(() => _foregroundOs3 = index == 1);
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: _dynamicBackground,
      os3: _foregroundOs3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textureConfigs = _referenceTextureBlendConfigs(
      context,
    ).take(10).toList(growable: false);
    final foregroundConfigs = _referenceForegroundBlendConfigs(
      context,
    ).take(8).toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '纹理模糊',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        _buildTextureDemo(textureConfigs),
        const MiuixSmallTitle(
          '前景模糊',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        _buildForegroundDemo(foregroundConfigs),
        const MiuixSmallTitle(
          '渐进模糊',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        _buildProgressiveDemo(textureConfigs),
      ],
    );
  }

  Widget _buildTextureDemo(List<_ReferenceBlendConfig> configs) {
    final current = configs[_textureBlendIndex];
    final textureColors = MiuixBlurColors(
      tint: Colors.transparent,
      border: Colors.transparent,
      opacity: 0,
      blendColors: current.entries,
      brightness: _textureBrightness,
      contrast: _textureContrast,
      saturation: _textureSaturation,
    );
    final sourceOverlayHeight = _referenceRoundedDp(context, 140);
    final sourceTextSpacing = _referenceRoundedDp(context, 4);
    const highlightItems = ['禁用', '大容器', '中容器', '小容器'];
    return MiuixCard(
      key: const ValueKey('reference-texture-blur-controls'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          RepaintBoundary(
            key: const ValueKey('reference-texture-blur-preview'),
            child: SizedBox(
              height: _previewHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/blur_test.png', fit: BoxFit.cover),
                  Align(
                    child: FractionallySizedBox(
                      widthFactor: .8,
                      child: SizedBox(
                        key: const ValueKey('texture-blur-overlay'),
                        height: sourceOverlayHeight,
                        child:
                            MiuixBackdropEffectScope(
                              backdrop: MiuixBackdrop(
                                highlight: _textureHighlight(),
                              ),
                              radius: 24,
                              padding: EdgeInsets.zero,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '纹理模糊 | 半径=${_textureBlur.toInt()}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: sourceTextSpacing),
                                    Text(
                                      '${current.label} | '
                                      '${highlightItems[_textureHighlightIndex]}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: MiuixSemanticColors.of(
                                          context,
                                        )['onSurfaceVariantActions'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).textureBlurEffect(
                              blurRadiusX: _textureBlur,
                              noiseCoefficient: _textureNoise,
                              colors: textureColors,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _dropdownControl(
            title: '混合模式',
            items: configs.map((config) => config.label).toList(),
            selectedIndex: _textureBlendIndex,
            onSelected: (index) => setState(() => _textureBlendIndex = index),
          ),
          _dropdownControl(
            title: '高光',
            items: highlightItems,
            selectedIndex: _textureHighlightIndex,
            onSelected: (index) =>
                setState(() => _textureHighlightIndex = index),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MiuixHorizontalDivider(),
          ),
          _sliderControl(
            title: '模糊半径',
            valueText: '${_textureBlur.toInt()}',
            value: _textureBlur / 200,
            onChanged: (value) =>
                setState(() => _textureBlur = _referenceFloat32(value * 200)),
          ),
          _sliderControl(
            title: '噪点',
            valueText: _shortDecimal(_textureNoise, 4),
            value: _textureNoise / .1,
            onChanged: (value) =>
                setState(() => _textureNoise = _referenceFloat32(value * .1)),
          ),
          _sliderControl(
            title: '亮度',
            valueText: _shortDecimal(_textureBrightness, 2),
            value: (_textureBrightness + 1) / 2,
            onChanged: (value) => setState(
              () => _textureBrightness = _referenceFloat32(value * 2 - 1),
            ),
          ),
          _sliderControl(
            title: '对比度',
            valueText: _shortDecimal(_textureContrast, 2),
            value: _textureContrast / 3,
            onChanged: (value) =>
                setState(() => _textureContrast = _referenceFloat32(value * 3)),
          ),
          _sliderControl(
            title: '饱和度',
            valueText: _shortDecimal(_textureSaturation, 2),
            value: _textureSaturation / 3,
            last: true,
            onChanged: (value) => setState(
              () => _textureSaturation = _referenceFloat32(value * 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForegroundDemo(List<_ReferenceBlendConfig> configs) {
    final current = configs[_foregroundBlendIndex];
    return MiuixCard(
      key: const ValueKey('reference-foreground-blur-controls'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          RepaintBoundary(
            key: const ValueKey('reference-foreground-blur-preview'),
            child: SizedBox(
              height: _previewHeight,
              child: AnimatedBuilder(
                animation: _backgroundMotion,
                builder: (context, child) => Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: _ReferenceEffectBackgroundPainter(
                        scheme: Theme.of(context).colorScheme,
                        elapsedSeconds: _backgroundMotion.elapsedSeconds,
                        colorStage: _backgroundMotion.stage,
                        shader: _effectBackgroundShader,
                        heightFraction: 1,
                        os3: _foregroundOs3,
                      ),
                    ),
                    Center(
                      child: MiuixForegroundBlurText(
                        text: '前景模糊\nMIUIX 演示',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall!
                            .copyWith(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                        backdrop: _backdrop(
                          blur: _foregroundBlur,
                          noise: _foregroundNoise,
                          brightness: _foregroundBrightness,
                          contrast: _foregroundContrast,
                          saturation: _foregroundSaturation,
                          entries: current.entries,
                        ),
                        fallbackGradient: _referenceLogoFallbackGradient(
                          Theme.of(context).brightness,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _dropdownControl(
            title: '效果版本',
            items: const ['OS2', 'OS3'],
            selectedIndex: _foregroundOs3 ? 1 : 0,
            onSelected: _setForegroundOs3,
          ),
          _dropdownControl(
            title: '混合模式',
            items: configs.map((config) => config.label).toList(),
            selectedIndex: _foregroundBlendIndex,
            onSelected: (index) =>
                setState(() => _foregroundBlendIndex = index),
          ),
          MiuixSwitchPreference.source(
            title: '动态背景',
            checked: _dynamicBackground,
            onCheckedChange: _setDynamicBackground,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MiuixHorizontalDivider(),
          ),
          _sliderControl(
            title: '模糊半径',
            valueText: '${_foregroundBlur.toInt()}',
            value: _foregroundBlur / 200,
            onChanged: (value) => setState(
              () => _foregroundBlur = _referenceFloat32(value * 200),
            ),
          ),
          _sliderControl(
            title: '噪点',
            valueText: _shortDecimal(_foregroundNoise, 4),
            value: _foregroundNoise / .1,
            onChanged: (value) => setState(
              () => _foregroundNoise = _referenceFloat32(value * .1),
            ),
          ),
          _sliderControl(
            title: '亮度',
            valueText: _shortDecimal(_foregroundBrightness, 2),
            value: (_foregroundBrightness + 1) / 2,
            onChanged: (value) => setState(
              () => _foregroundBrightness = _referenceFloat32(value * 2 - 1),
            ),
          ),
          _sliderControl(
            title: '对比度',
            valueText: _shortDecimal(_foregroundContrast, 2),
            value: _foregroundContrast / 3,
            onChanged: (value) => setState(
              () => _foregroundContrast = _referenceFloat32(value * 3),
            ),
          ),
          _sliderControl(
            title: '饱和度',
            valueText: _shortDecimal(_foregroundSaturation, 2),
            value: _foregroundSaturation / 3,
            last: true,
            onChanged: (value) => setState(
              () => _foregroundSaturation = _referenceFloat32(value * 3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressiveDemo(List<_ReferenceBlendConfig> configs) {
    final current = configs[_progressiveBlendIndex];
    const directionItems = ['顶部', '底部', '左侧', '右侧'];
    const directions = [
      MiuixProgressiveBlur.top,
      MiuixProgressiveBlur.bottom,
      MiuixProgressiveBlur.left,
      MiuixProgressiveBlur.right,
    ];
    final gradient = directions[_progressiveDirectionIndex].copyWith(
      startFraction: _progressiveStart,
      endFraction: _progressiveEnd,
      curve: _progressiveCurve,
    );
    return MiuixCard(
      key: const ValueKey('reference-progressive-blur-controls'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          RepaintBoundary(
            key: const ValueKey('reference-progressive-blur-preview'),
            child: SizedBox(
              height: _previewHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset('assets/images/blur_test.png', fit: BoxFit.cover),
                  MiuixProgressiveLayerBackdrop(
                    gradient: gradient,
                    backdrop: _backdrop(
                      blur: _progressiveBlur,
                      noise: _progressiveNoise,
                      brightness: 0,
                      contrast: 1,
                      saturation: 1,
                      entries: current.entries,
                    ),
                    child: Center(
                      child: Text(
                        '渐进模糊\n${directionItems[_progressiveDirectionIndex]} '
                        '| 半径=${_progressiveBlur.toInt()} | ${current.label}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _dropdownControl(
            title: '方向',
            items: directionItems,
            selectedIndex: _progressiveDirectionIndex,
            onSelected: (index) =>
                setState(() => _progressiveDirectionIndex = index),
          ),
          _dropdownControl(
            title: '混合模式',
            items: configs.map((config) => config.label).toList(),
            selectedIndex: _progressiveBlendIndex,
            onSelected: (index) =>
                setState(() => _progressiveBlendIndex = index),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: MiuixHorizontalDivider(),
          ),
          _sliderControl(
            title: '模糊半径',
            valueText: '${_progressiveBlur.toInt()}',
            value: _progressiveBlur / 50,
            onChanged: (value) => setState(
              () => _progressiveBlur = _referenceFloat32(value * 50),
            ),
          ),
          _sliderControl(
            title: '噪点',
            valueText: _shortDecimal(_progressiveNoise, 4),
            value: _progressiveNoise / .1,
            onChanged: (value) => setState(
              () => _progressiveNoise = _referenceFloat32(value * .1),
            ),
          ),
          _sliderControl(
            title: '起点',
            valueText: _shortDecimal(_progressiveStart, 2),
            value: _progressiveStart,
            onChanged: (value) =>
                setState(() => _progressiveStart = _referenceFloat32(value)),
          ),
          _sliderControl(
            title: '终点',
            valueText: _shortDecimal(_progressiveEnd, 2),
            value: _progressiveEnd,
            onChanged: (value) =>
                setState(() => _progressiveEnd = _referenceFloat32(value)),
          ),
          _sliderControl(
            title: '曲线',
            valueText: _shortDecimal(_progressiveCurve, 2),
            value: (_progressiveCurve - .25) / 2.75,
            last: true,
            onChanged: (value) => setState(
              () => _progressiveCurve = _referenceFloat32(.25 + value * 2.75),
            ),
          ),
        ],
      ),
    );
  }

  MiuixBackdrop _backdrop({
    required double blur,
    required double noise,
    required double brightness,
    required double contrast,
    required double saturation,
    required List<MiuixBlurBlendEntry> entries,
    MiuixHighlight? highlight,
  }) {
    return MiuixBackdrop(
      blur: blur,
      noise: noise,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      colors: MiuixBlurColors(
        tint: Colors.transparent,
        border: Colors.transparent,
        opacity: 0,
        blendColors: entries,
      ),
      highlight: highlight,
    );
  }

  MiuixHighlight? _textureHighlight() {
    if (_textureHighlightIndex == 0) return null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = switch ((_textureHighlightIndex, dark)) {
      (1, false) => MiuixHighlight.glassStrokeBigLight,
      (1, true) => MiuixHighlight.glassStrokeBigDark,
      (2, false) => MiuixHighlight.glassStrokeMiddleLight,
      (2, true) => MiuixHighlight.glassStrokeMiddleDark,
      (3, false) => MiuixHighlight.glassStrokeSmallLight,
      _ => MiuixHighlight.glassStrokeSmallDark,
    };
    // Upstream rememberContainerHighlight drives both BloomStroke lights from
    // rotation-vector pitch/roll with independent .15 and .12 sensitivities.
    return base.drivenByTilt(_deviceTilt);
  }

  Widget _sliderControl({
    required String title,
    required String valueText,
    required double value,
    required ValueChanged<double> onChanged,
    bool last = false,
  }) {
    return MiuixSliderPreference.source(
      title: title,
      valueText: valueText,
      value: value.clamp(0.0, 1.0),
      onValueChange: onChanged,
      insideMargin: last
          ? MiuixBasicComponentDefaults.insideMargin
          : const EdgeInsets.fromLTRB(16, 16, 16, 0),
    );
  }

  Widget _dropdownControl({
    required String title,
    required List<String> items,
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return MiuixOverlayDropdownPreference.source(
      title: title,
      items: items,
      selectedIndex: selectedIndex,
      onSelectedIndexChange: onSelected,
    );
  }

  String _shortDecimal(double value, int places) {
    return _referenceTruncatedFloat(value, places);
  }
}

Gradient _referenceLogoFallbackGradient(Brightness brightness) {
  return LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: brightness == Brightness.dark
        ? const [Color(0xFFC4A8FF), Color(0xFFFFC09A)]
        // Median glyph colors measured from the original Android sample's
        // PHONE_LIGHT Logo Blend frame: 91,26,168 and 136,71,44.
        : const [Color(0xFF5B1AA8), Color(0xFF88472C)],
  );
}

/// Paints the selected source OS2/OS3 background effect with its runtime shader.
///
/// Android and Windows both compile the fragment program from the example
/// bundle. The temporary surface fill is visible only during asynchronous
/// program loading and on platforms where runtime effects are unavailable.
class _ReferenceEffectBackgroundPainter extends CustomPainter {
  const _ReferenceEffectBackgroundPainter({
    required this.scheme,
    required this.elapsedSeconds,
    required this.shader,
    required this.heightFraction,
    this.colorStage = 0,
    this.os3 = true,
  });

  final ColorScheme scheme;
  final double elapsedSeconds;
  final double colorStage;
  final ui.FragmentShader? shader;
  final double heightFraction;
  final bool os3;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = scheme.surface);
    final effect = shader;
    if (effect == null) return;

    // Uniform order follows miuix_effect_background.frag. The original
    // BgEffectPainter chooses PHONE_LIGHT/PHONE_DARK for this demo because it
    // never overrides its default DeviceType.PHONE preset.
    effect
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, elapsedSeconds)
      ..setFloat(3, scheme.brightness == Brightness.dark ? 1 : 0)
      // BgEffectPainter.updateBound() uses the same portrait-phone tuple.
      ..setFloat(4, 0)
      ..setFloat(5, 1 - heightFraction)
      ..setFloat(6, 1)
      ..setFloat(7, heightFraction)
      ..setFloat(8, os3 ? 1 : 0)
      ..setFloat(9, colorStage);
    canvas.drawRect(Offset.zero & size, Paint()..shader = effect);
  }

  @override
  bool shouldRepaint(covariant _ReferenceEffectBackgroundPainter oldDelegate) {
    return oldDelegate.elapsedSeconds != elapsedSeconds ||
        oldDelegate.colorStage != colorStage ||
        oldDelegate.scheme != scheme ||
        oldDelegate.shader != shader ||
        oldDelegate.heightFraction != heightFraction ||
        oldDelegate.os3 != os3;
  }
}
