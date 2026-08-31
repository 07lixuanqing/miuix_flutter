part of '../miuix_widgets.dart';

/// MIUIX color picker supporting HSV, OKHSV, OKLab, and OKLCH.
class MiuixColorPicker extends StatefulWidget {
  /// Creates a color picker.
  const MiuixColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.colorSpace = MiuixColorSpace.hsv,
    this.showPreview = true,
  });

  /// Current color.
  final Color color;

  /// Change callback.
  final ValueChanged<Color> onChanged;

  /// Color space used by the channel controls.
  final MiuixColorSpace colorSpace;

  /// Whether the selected-color capsule is visible.
  final bool showPreview;

  @override
  State<MiuixColorPicker> createState() => _MiuixColorPickerState();
}

class _MiuixColorPickerState extends State<MiuixColorPicker> {
  late double _channel1;
  late double _channel2;
  late double _channel3;
  late double _alpha;
  late int _lastExternalColor;

  @override
  void initState() {
    super.initState();
    _syncFromExternalColor();
  }

  @override
  void didUpdateWidget(covariant MiuixColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final external = widget.color.toARGB32();
    final internal = _selectedColor.toARGB32();
    if (oldWidget.colorSpace != widget.colorSpace ||
        (external != _lastExternalColor && external != internal)) {
      _syncFromExternalColor();
    } else if (external == internal) {
      _lastExternalColor = external;
    }
  }

  Color get _selectedColor {
    return switch (widget.colorSpace) {
      MiuixColorSpace.hsv => HSVColor.fromAHSV(
        _alpha,
        _channel1 * 360,
        _channel2,
        _channel3,
      ).toColor(),
      MiuixColorSpace.okHsv => MiuixOkHsv(
        hue: _channel1,
        saturation: _channel2,
        value: _channel3,
        alpha: _alpha,
      ).toColor(),
      MiuixColorSpace.okLab => MiuixOkLab(
        lightness: _channel1,
        a: _channel2 * .8 - .4,
        b: _channel3 * .8 - .4,
        alpha: _alpha,
      ).toColor(),
      MiuixColorSpace.okLch => MiuixOkLch(
        lightness: _channel2,
        chroma: _channel3 * .4,
        hue: _channel1 * 360,
        alpha: _alpha,
      ).toColor(),
    };
  }

  void _syncFromExternalColor() {
    switch (widget.colorSpace) {
      case MiuixColorSpace.hsv:
        final hsv = HSVColor.fromColor(widget.color);
        _channel1 = (_finiteOr(hsv.hue, 0) / 360).clamp(0.0, 1.0);
        _channel2 = _finiteOr(hsv.saturation, 0).clamp(0.0, 1.0);
        _channel3 = _finiteOr(hsv.value, 0).clamp(0.0, 1.0);
      case MiuixColorSpace.okHsv:
        final ok = MiuixOkHsv.fromColor(widget.color);
        _channel1 = _finiteOr(ok.hue, 0).clamp(0.0, 1.0);
        _channel2 = _finiteOr(ok.saturation, 0).clamp(0.0, 1.0);
        _channel3 = _finiteOr(ok.value, 0).clamp(0.0, 1.0);
      case MiuixColorSpace.okLab:
        final ok = MiuixOkLab.fromColor(widget.color);
        _channel1 = _finiteOr(ok.lightness, 0).clamp(0.0, 1.0);
        _channel2 = ((_finiteOr(ok.a, 0) + .4) / .8).clamp(0.0, 1.0);
        _channel3 = ((_finiteOr(ok.b, 0) + .4) / .8).clamp(0.0, 1.0);
      case MiuixColorSpace.okLch:
        final ok = MiuixOkLch.fromColor(widget.color);
        _channel1 = (_finiteOr(ok.hue, 0) / 360).clamp(0.0, 1.0);
        _channel2 = _finiteOr(ok.lightness, 0).clamp(0.0, 1.0);
        _channel3 = (_finiteOr(ok.chroma, 0) / .4).clamp(0.0, 1.0);
    }
    _alpha = _finiteOr(widget.color.a, 1).clamp(0.0, 1.0);
    _lastExternalColor = widget.color.toARGB32();
  }

  void _update({double? first, double? second, double? third, double? alpha}) {
    final nextFirst = _finiteOr(first ?? _channel1, _channel1).clamp(0.0, 1.0);
    final nextSecond = _finiteOr(
      second ?? _channel2,
      _channel2,
    ).clamp(0.0, 1.0);
    final nextThird = _finiteOr(third ?? _channel3, _channel3).clamp(0.0, 1.0);
    final nextAlpha = _finiteOr(alpha ?? _alpha, _alpha).clamp(0.0, 1.0);
    if (nextFirst == _channel1 &&
        nextSecond == _channel2 &&
        nextThird == _channel3 &&
        nextAlpha == _alpha) {
      return;
    }
    setState(() {
      _channel1 = nextFirst;
      _channel2 = nextSecond;
      _channel3 = nextThird;
      _alpha = nextAlpha;
    });
    final color = _selectedColor;
    _lastExternalColor = color.toARGB32();
    if (color.toARGB32() != widget.color.toARGB32()) {
      widget.onChanged(color);
    }
  }

  List<Color> _firstChannelColors() {
    return switch (widget.colorSpace) {
      MiuixColorSpace.hsv => _hsvHueSliderColors(),
      MiuixColorSpace.okHsv => [
        for (var index = 0; index <= 36; index++)
          MiuixOkHsv(hue: index / 36, saturation: 1, value: 1).toColor(),
      ],
      MiuixColorSpace.okLab => [
        for (var index = 0; index <= 16; index++)
          MiuixOkLab(
            lightness: index / 16,
            a: _channel2 * .8 - .4,
            b: _channel3 * .8 - .4,
          ).toColor(),
      ],
      MiuixColorSpace.okLch => [
        for (var index = 0; index <= 36; index++)
          MiuixOkLch(
            lightness: _channel2,
            chroma: _channel3 * .4,
            hue: index * 10,
          ).toColor(),
      ],
    };
  }

  List<Color> _secondChannelColors() {
    return switch (widget.colorSpace) {
      MiuixColorSpace.hsv => [
        HSVColor.fromAHSV(1, _channel1 * 360, 0, 1).toColor(),
        HSVColor.fromAHSV(1, _channel1 * 360, 1, 1).toColor(),
      ],
      MiuixColorSpace.okHsv => [
        MiuixOkHsv(hue: _channel1, saturation: 0, value: _channel3).toColor(),
        MiuixOkHsv(hue: _channel1, saturation: 1, value: _channel3).toColor(),
      ],
      MiuixColorSpace.okLab => [
        MiuixOkLab(
          lightness: _channel1,
          a: -.4,
          b: _channel3 * .8 - .4,
        ).toColor(),
        MiuixOkLab(
          lightness: _channel1,
          a: .4,
          b: _channel3 * .8 - .4,
        ).toColor(),
      ],
      MiuixColorSpace.okLch => [
        MiuixOkLch(
          lightness: 0,
          chroma: _channel3 * .4,
          hue: _channel1 * 360,
        ).toColor(),
        MiuixOkLch(
          lightness: 1,
          chroma: _channel3 * .4,
          hue: _channel1 * 360,
        ).toColor(),
      ],
    };
  }

  List<Color> _thirdChannelColors() {
    return switch (widget.colorSpace) {
      MiuixColorSpace.hsv => [
        Colors.black,
        HSVColor.fromAHSV(1, _channel1 * 360, _channel2, 1).toColor(),
      ],
      MiuixColorSpace.okHsv => [
        Colors.black,
        MiuixOkHsv(hue: _channel1, saturation: _channel2, value: 1).toColor(),
      ],
      MiuixColorSpace.okLab => [
        MiuixOkLab(
          lightness: _channel1,
          a: _channel2 * .8 - .4,
          b: -.4,
        ).toColor(),
        MiuixOkLab(
          lightness: _channel1,
          a: _channel2 * .8 - .4,
          b: .4,
        ).toColor(),
      ],
      MiuixColorSpace.okLch => [
        MiuixOkLch(
          lightness: _channel2,
          chroma: 0,
          hue: _channel1 * 360,
        ).toColor(),
        MiuixOkLch(
          lightness: _channel2,
          chroma: .4,
          hue: _channel1 * 360,
        ).toColor(),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _selectedColor;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final sourceSliderHeight = _miuixRoundLogicalDimension(26, pixelRatio);
    final sourceSpacing = _miuixRoundLogicalDimension(12, pixelRatio);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showPreview) ...[
          _miuixColorShapeClip(
            context,
            clipKey: const ValueKey('miuix-color-picker-preview-clip'),
            radius: sourceSliderHeight / 2,
            child: SizedBox(
              height: sourceSliderHeight,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            ),
          ),
          SizedBox(height: sourceSpacing),
        ],
        _MiuixHsvChannelSlider(
          sliderKey: const ValueKey('miuix-color-picker-hue-slider'),
          value: _channel1,
          colors: _firstChannelColors(),
          onChanged: (value) => _update(first: value),
        ),
        SizedBox(height: sourceSpacing),
        _MiuixHsvChannelSlider(
          sliderKey: const ValueKey('miuix-color-picker-saturation-slider'),
          value: _channel2,
          colors: _secondChannelColors(),
          onChanged: (value) => _update(second: value),
        ),
        SizedBox(height: sourceSpacing),
        _MiuixHsvChannelSlider(
          sliderKey: const ValueKey('miuix-color-picker-value-slider'),
          value: _channel3,
          colors: _thirdChannelColors(),
          onChanged: (value) => _update(third: value),
        ),
        SizedBox(height: sourceSpacing),
        _MiuixHsvAlphaSlider(
          value: _alpha,
          baseColor: color.withValues(alpha: 1),
          onChanged: (value) => _update(alpha: value),
        ),
      ],
    );
  }
}

List<Color> _hsvHueSliderColors() {
  return [
    for (final hue in const [0.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0])
      HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
  ];
}

/// HSV color picker adapter.
class MiuixHsvColorPicker extends MiuixColorPicker {
  /// Creates an HSV color picker.
  const MiuixHsvColorPicker({
    super.key,
    required super.color,
    required super.onChanged,
    super.showPreview,
  }) : super(colorSpace: MiuixColorSpace.hsv);
}

/// OKHSV color picker adapter.
class MiuixOkHsvColorPicker extends MiuixColorPicker {
  /// Creates an OKHSV color picker.
  const MiuixOkHsvColorPicker({
    super.key,
    required super.color,
    required super.onChanged,
    super.showPreview,
  }) : super(colorSpace: MiuixColorSpace.okHsv);
}

/// OKLab color picker adapter.
class MiuixOkLabColorPicker extends MiuixColorPicker {
  /// Creates an OKLab color picker.
  const MiuixOkLabColorPicker({
    super.key,
    required super.color,
    required super.onChanged,
    super.showPreview,
  }) : super(colorSpace: MiuixColorSpace.okLab);
}

/// OKLCH color picker adapter.
class MiuixOkLchColorPicker extends MiuixColorPicker {
  /// Creates an OKLCH color picker.
  const MiuixOkLchColorPicker({
    super.key,
    required super.color,
    required super.onChanged,
    super.showPreview,
  }) : super(colorSpace: MiuixColorSpace.okLch);
}

/// Hue slider adapter for color pickers.
class MiuixHsvHueSlider extends StatelessWidget {
  /// Creates a hue slider.
  const MiuixHsvHueSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// Current hue in degrees from 0 through 360.
  final double value;

  /// Called with the new hue in degrees.
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => _MiuixHsvChannelSlider(
    value: (_finiteOr(value, 0) / 360).clamp(0.0, 1.0),
    colors: _hsvHueSliderColors(),
    onChanged: onChanged == null ? null : (next) => onChanged!(next * 360),
  );
}

/// Saturation slider adapter for color pickers.
class MiuixHsvSaturationSlider extends StatelessWidget {
  /// Creates a saturation slider.
  const MiuixHsvSaturationSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.currentHue = 0,
  });

  /// Current saturation from 0 through 1.
  final double value;

  /// Called with the new saturation.
  final ValueChanged<double>? onChanged;

  /// Hue in degrees used to construct the source gradient.
  final double currentHue;

  @override
  Widget build(BuildContext context) {
    final hue = _finiteOr(currentHue, 0) % 360;
    return _MiuixHsvChannelSlider(
      value: value,
      colors: [
        HSVColor.fromAHSV(1, hue, 0, 1).toColor(),
        HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
      ],
      onChanged: onChanged,
    );
  }
}

/// Value slider adapter for color pickers.
class MiuixHsvValueSlider extends StatelessWidget {
  /// Creates a value slider.
  const MiuixHsvValueSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.currentHue = 0,
    this.currentSaturation = 1,
  });

  /// Current brightness/value from 0 through 1.
  final double value;

  /// Called with the new brightness/value.
  final ValueChanged<double>? onChanged;

  /// Hue in degrees used to construct the source gradient.
  final double currentHue;

  /// Saturation used to construct the source gradient.
  final double currentSaturation;

  @override
  Widget build(BuildContext context) => _MiuixHsvChannelSlider(
    value: value,
    colors: [
      Colors.black,
      HSVColor.fromAHSV(
        1,
        _finiteOr(currentHue, 0) % 360,
        _finiteOr(currentSaturation, 1).clamp(0.0, 1.0),
        1,
      ).toColor(),
    ],
    onChanged: onChanged,
  );
}

/// Alpha slider adapter for color pickers.
class MiuixHsvAlphaSlider extends StatelessWidget {
  /// Creates an alpha slider.
  const MiuixHsvAlphaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.currentHue = 0,
    this.currentSaturation = 1,
    this.currentValue = 1,
  });

  /// Current alpha from 0 through 1.
  final double value;

  /// Called with the new alpha.
  final ValueChanged<double>? onChanged;

  /// Hue in degrees used to construct the source gradient.
  final double currentHue;

  /// Saturation used to construct the source gradient.
  final double currentSaturation;

  /// Brightness/value used to construct the source gradient.
  final double currentValue;

  @override
  Widget build(BuildContext context) => _MiuixHsvAlphaSlider(
    value: value.clamp(0.0, 1.0),
    baseColor: HSVColor.fromAHSV(
      1,
      _finiteOr(currentHue, 0) % 360,
      _finiteOr(currentSaturation, 1).clamp(0.0, 1.0),
      _finiteOr(currentValue, 1).clamp(0.0, 1.0),
    ).toColor(),
    onChanged: onChanged,
  );
}

class _MiuixPerceptualColorSlider extends StatelessWidget {
  const _MiuixPerceptualColorSlider({
    required this.value,
    required this.onChanged,
    required this.colors,
    this.min = 0,
    this.max = 1,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final List<Color> colors;
  final double min;
  final double max;

  @override
  Widget build(BuildContext context) {
    final span = max - min;
    final normalized = span <= 0
        ? 0.0
        : ((_finiteOr(value, min) - min) / span).clamp(0.0, 1.0);
    return _MiuixHsvChannelSlider(
      value: normalized,
      colors: colors,
      onChanged: onChanged == null
          ? null
          : (next) => onChanged!(min + next * span),
    );
  }
}

/// Perceptually uniform OKHSV hue slider. Values are normalized to 0..1.
class MiuixOkHsvHueSlider extends StatelessWidget {
  const MiuixOkHsvHueSlider({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    return _MiuixPerceptualColorSlider(
      value: value,
      onChanged: onChanged,
      colors: [
        for (var index = 0; index <= 36; index++)
          MiuixOkHsv(hue: index / 36, saturation: 1, value: 1).toColor(),
      ],
    );
  }
}

/// OKHSV saturation slider.
class MiuixOkHsvSaturationSlider extends StatelessWidget {
  const MiuixOkHsvSaturationSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.hue = 0,
    this.brightness = 1,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double hue;
  final double brightness;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      MiuixOkHsv(hue: hue, saturation: 0, value: brightness).toColor(),
      MiuixOkHsv(hue: hue, saturation: 1, value: brightness).toColor(),
    ],
  );
}

/// OKHSV value/brightness slider.
class MiuixOkHsvValueSlider extends StatelessWidget {
  const MiuixOkHsvValueSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.hue = 0,
    this.saturation = 1,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double hue;
  final double saturation;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      Colors.black,
      MiuixOkHsv(hue: hue, saturation: saturation, value: 1).toColor(),
    ],
  );
}

/// OKHSV alpha slider with checkerboard transparency backing.
class MiuixOkHsvAlphaSlider extends StatelessWidget {
  const MiuixOkHsvAlphaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.hue = 0,
    this.saturation = 1,
    this.brightness = 1,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double hue;
  final double saturation;
  final double brightness;

  @override
  Widget build(BuildContext context) => _MiuixHsvAlphaSlider(
    value: value.clamp(0.0, 1.0),
    baseColor: MiuixOkHsv(
      hue: hue,
      saturation: saturation,
      value: brightness,
    ).toColor(),
    onChanged: onChanged,
  );
}

/// OKLab lightness slider.
class MiuixOkLabLightnessSlider extends StatelessWidget {
  const MiuixOkLabLightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.a = 0,
    this.b = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double a;
  final double b;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      for (var index = 0; index <= 16; index++)
        MiuixOkLab(lightness: index / 16, a: a, b: b).toColor(),
    ],
  );
}

/// OKLab green-red A-channel slider in the -0.4..0.4 source range.
class MiuixOkLabAChannelSlider extends StatelessWidget {
  const MiuixOkLabAChannelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.b = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double b;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    min: -.4,
    max: .4,
    onChanged: onChanged,
    colors: [
      MiuixOkLab(lightness: lightness, a: -.4, b: b).toColor(),
      MiuixOkLab(lightness: lightness, a: .4, b: b).toColor(),
    ],
  );
}

/// OKLab blue-yellow B-channel slider in the -0.4..0.4 source range.
class MiuixOkLabBChannelSlider extends StatelessWidget {
  const MiuixOkLabBChannelSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.a = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double a;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    min: -.4,
    max: .4,
    onChanged: onChanged,
    colors: [
      MiuixOkLab(lightness: lightness, a: a, b: -.4).toColor(),
      MiuixOkLab(lightness: lightness, a: a, b: .4).toColor(),
    ],
  );
}

/// OKLab alpha slider.
class MiuixOkLabAlphaSlider extends StatelessWidget {
  const MiuixOkLabAlphaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.a = 0,
    this.b = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double a;
  final double b;

  @override
  Widget build(BuildContext context) => _MiuixHsvAlphaSlider(
    value: value.clamp(0.0, 1.0),
    baseColor: MiuixOkLab(lightness: lightness, a: a, b: b).toColor(),
    onChanged: onChanged,
  );
}

/// OKLCH lightness slider.
class MiuixOkLchLightnessSlider extends StatelessWidget {
  const MiuixOkLchLightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.chroma = .2,
    this.hue = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double chroma;
  final double hue;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      MiuixOkLch(lightness: 0, chroma: chroma, hue: hue).toColor(),
      MiuixOkLch(lightness: 1, chroma: chroma, hue: hue).toColor(),
    ],
  );
}

/// OKLCH chroma slider. Public values are normalized to 0..1.
class MiuixOkLchChromaSlider extends StatelessWidget {
  const MiuixOkLchChromaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.hue = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double hue;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      MiuixOkLch(lightness: lightness, chroma: 0, hue: hue).toColor(),
      MiuixOkLch(lightness: lightness, chroma: .4, hue: hue).toColor(),
    ],
  );
}

/// OKLCH hue slider. Public values are normalized to 0..1.
class MiuixOkLchHueSlider extends StatelessWidget {
  const MiuixOkLchHueSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.chroma = .2,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double chroma;

  @override
  Widget build(BuildContext context) => _MiuixPerceptualColorSlider(
    value: value,
    onChanged: onChanged,
    colors: [
      for (var index = 0; index <= 36; index++)
        MiuixOkLch(
          lightness: lightness,
          chroma: chroma,
          hue: index * 10,
        ).toColor(),
    ],
  );
}

/// OKLCH alpha slider.
class MiuixOkLchAlphaSlider extends StatelessWidget {
  const MiuixOkLchAlphaSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.lightness = .7,
    this.chroma = .2,
    this.hue = 0,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double lightness;
  final double chroma;
  final double hue;

  @override
  Widget build(BuildContext context) => _MiuixHsvAlphaSlider(
    value: value.clamp(0.0, 1.0),
    baseColor: MiuixOkLch(
      lightness: lightness,
      chroma: chroma,
      hue: hue,
    ).toColor(),
    onChanged: onChanged,
  );
}
