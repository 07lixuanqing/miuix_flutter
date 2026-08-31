part of 'main.dart';

// This file mirrors the blend preset tables used by the upstream blur sample.
// Keeping the data separate from the interactive widgets makes it possible to
// compare source entries without turning the section file into another large,
// difficult-to-review monolith.

typedef _ReferenceBlendConfig = ({
  String label,
  List<MiuixBlurBlendEntry> entries,
});

MiuixBlurBlendEntry _blend(int argb, MiuixBlurBlendMode mode) =>
    MiuixBlurBlendEntry(Color(argb), mode);

List<_ReferenceBlendConfig> _referenceTextureBlendConfigs(
  BuildContext context,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final surface = Theme.of(context).colorScheme.surface.withValues(alpha: .6);
  return [
    (label: '无', entries: const []),
    (
      label: '信息轻薄',
      entries: [
        _blend(
          0x801E1E1E,
          dark ? MiuixBlurBlendMode.plusDarker : MiuixBlurBlendMode.plusLighter,
        ),
      ],
    ),
    (
      label: '信息常规',
      entries: [
        _blend(
          0xB3141414,
          dark ? MiuixBlurBlendMode.plusDarker : MiuixBlurBlendMode.plusLighter,
        ),
      ],
    ),
    (label: '彩色轻薄', entries: _coloredThin(dark)),
    (label: '彩色常规', entries: _coloredRegular(dark)),
    (label: '彩色厚重', entries: _coloredThick(dark)),
    (label: '纯色常规', entries: _puredRegular(dark)),
    (label: '纯色厚重', entries: _puredThick(dark)),
    // The source intentionally uses the light thin-overlay token in both
    // themes; retain that asymmetry instead of silently "fixing" it.
    (label: '叠加轻薄', entries: _overlayThinLight()),
    (label: '叠加厚重', entries: _overlayThick(dark)),
    ..._referenceSingleBlendConfigs(surface),
  ];
}

List<_ReferenceBlendConfig> _referenceForegroundBlendConfigs(
  BuildContext context,
) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  // ForegroundBlurDemo.kt uses MiuixTheme.colorScheme.onBackground. In the
  // default dark palette this is translucent white (0xE6FFFFFF), while
  // Material onSurface is opaque 0xFFF2F2F2 and changes every single-mode
  // blend result.
  final onBackground = MiuixSemanticColors.of(context)['onBackground'];
  return [
    (label: '无', entries: const []),
    (label: '徽标混合', entries: _logoBlend(dark)),
    (label: '彩色轻薄', entries: _coloredThin(dark)),
    (label: '彩色常规', entries: _coloredRegular(dark)),
    (label: '彩色厚重', entries: _coloredThick(dark)),
    (label: '纯色常规', entries: _puredRegular(dark)),
    (label: '叠加轻薄', entries: _overlayThinLight()),
    (
      label: '信息彩色',
      entries: [
        _blend(0xFF9C27B0, MiuixBlurBlendMode.colorDodge),
        _blend(0x0FFFFFFF, MiuixBlurBlendMode.plusLighter),
      ],
    ),
    ..._referenceSingleBlendConfigs(onBackground),
  ];
}

/// Presets exposed by the hidden Texture Set panel on the About page.
///
/// This table intentionally differs from the larger Blur demo table. The
/// upstream page starts with its theme-aware default token, then exposes the
/// exact fifteen hardware/custom blend modes in source order.
List<_ReferenceBlendConfig> _referenceAboutBlendConfigs(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  final surface = Theme.of(context).colorScheme.surface.withValues(alpha: .6);
  return [
    (label: '默认', entries: dark ? _overlayThinLight() : _puredRegular(false)),
    (label: '无', entries: const []),
    _single('源叠加', surface, MiuixBlurBlendMode.srcOver),
    _single('滤色', surface, MiuixBlurBlendMode.screen),
    _single('正片叠底', surface, MiuixBlurBlendMode.multiply),
    _single('叠加', surface, MiuixBlurBlendMode.overlay),
    _single('柔光', surface, MiuixBlurBlendMode.softLight),
    _single('线性光', surface, MiuixBlurBlendMode.linearLight),
    _single('线性光（灰度）', surface, MiuixBlurBlendMode.linearLightWithGreyscale),
    _single('线性光（Lab）', surface, MiuixBlurBlendMode.linearLightLab),
    _single('Lab 变亮', surface, MiuixBlurBlendMode.labLightenWithGreyscale),
    _single('Lab 变暗', surface, MiuixBlurBlendMode.labDarkenWithGreyscale),
    _single('MI 差值', surface, MiuixBlurBlendMode.miDifference),
    _single('MI 颜色减淡', surface, MiuixBlurBlendMode.miColorDodge),
    _single('MI 颜色加深', surface, MiuixBlurBlendMode.miColorBurn),
    _single('加亮', surface, MiuixBlurBlendMode.plusLighter),
    _single('加暗', surface, MiuixBlurBlendMode.plusDarker),
  ];
}

List<_ReferenceBlendConfig> _referenceSingleBlendConfigs(Color color) => [
  _single('源叠加', color, MiuixBlurBlendMode.srcOver),
  _single('滤色', color, MiuixBlurBlendMode.screen),
  _single('正片叠底', color, MiuixBlurBlendMode.multiply),
  _single('叠加', color, MiuixBlurBlendMode.overlay),
  _single('柔光', color, MiuixBlurBlendMode.softLight),
  _single('颜色减淡', color, MiuixBlurBlendMode.colorDodge),
  _single('颜色加深', color, MiuixBlurBlendMode.colorBurn),
  _single('线性光', color, MiuixBlurBlendMode.linearLight),
  _single('线性光（灰度）', color, MiuixBlurBlendMode.linearLightWithGreyscale),
  _single('线性光（Lab）', color, MiuixBlurBlendMode.linearLightLab),
  _single('Lab 变亮', color, MiuixBlurBlendMode.labLightenWithGreyscale),
  _single('Lab 变暗', color, MiuixBlurBlendMode.labDarkenWithGreyscale),
  _single('MI 差值', color, MiuixBlurBlendMode.miDifference),
  _single('MI 颜色减淡', color, MiuixBlurBlendMode.miColorDodge),
  _single('MI 颜色加深', color, MiuixBlurBlendMode.miColorBurn),
  _single('加亮', color, MiuixBlurBlendMode.plusLighter),
  _single('加暗', color, MiuixBlurBlendMode.plusDarker),
];

_ReferenceBlendConfig _single(
  String label,
  Color color,
  MiuixBlurBlendMode mode,
) => (label: label, entries: [MiuixBlurBlendEntry(color, mode)]);

List<MiuixBlurBlendEntry> _coloredThin(bool dark) => dark
    ? [
        _blend(0x1A9C9C9C, MiuixBlurBlendMode.colorBurn),
        _blend(0x337A7A7A, MiuixBlurBlendMode.plusDarker),
      ]
    : [
        _blend(0x991C1C1C, MiuixBlurBlendMode.overlay),
        _blend(0x802B2B2B, MiuixBlurBlendMode.softLight),
      ];

List<MiuixBlurBlendEntry> _coloredRegular(bool dark) => dark
    ? [
        _blend(0x70000000, MiuixBlurBlendMode.overlay),
        _blend(0x14000000, MiuixBlurBlendMode.srcOver),
      ]
    : [
        _blend(0x803F3F3F, MiuixBlurBlendMode.overlay),
        _blend(0x1CE6E6E6, MiuixBlurBlendMode.plusLighter),
      ];

List<MiuixBlurBlendEntry> _coloredThick(bool dark) => dark
    ? [
        _blend(0x667A7A7A, MiuixBlurBlendMode.colorBurn),
        _blend(0x33747474, MiuixBlurBlendMode.overlay),
        _blend(0x322B2B2B, MiuixBlurBlendMode.srcOver),
      ]
    : [
        _blend(0xE6BDBDBD, MiuixBlurBlendMode.overlay),
        _blend(0x992B2B2B, MiuixBlurBlendMode.colorDodge),
        _blend(0x339C9C9C, MiuixBlurBlendMode.srcOver),
      ];

List<MiuixBlurBlendEntry> _puredRegular(bool dark) => dark
    ? [
        _blend(0x75000000, MiuixBlurBlendMode.colorBurn),
        _blend(0x52000000, MiuixBlurBlendMode.srcOver),
      ]
    : [
        _blend(0x340034F9, MiuixBlurBlendMode.overlay),
        _blend(0xB3FFFFFF, MiuixBlurBlendMode.hardLight),
      ];

List<MiuixBlurBlendEntry> _puredThick(bool dark) => dark
    ? [
        _blend(0x4C000000, MiuixBlurBlendMode.colorBurn),
        _blend(0x80030303, MiuixBlurBlendMode.srcOver),
      ]
    : [
        _blend(0x4D000000, MiuixBlurBlendMode.overlay),
        _blend(0x80000000, MiuixBlurBlendMode.srcOver),
      ];

List<MiuixBlurBlendEntry> _overlayThinLight() => [
  _blend(0x4DA9A9A9, MiuixBlurBlendMode.luminosity),
  _blend(0x1A9C9C9C, MiuixBlurBlendMode.plusDarker),
];

List<MiuixBlurBlendEntry> _overlayThick(bool dark) => dark
    ? [
        _blend(0x66A8A8A8, MiuixBlurBlendMode.luminosity),
        _blend(0x999C9C9C, MiuixBlurBlendMode.plusDarker),
      ]
    : [
        _blend(0xA8A8A8A8, MiuixBlurBlendMode.luminosity),
        _blend(0xFF9A9A9A, MiuixBlurBlendMode.overlay),
      ];

List<MiuixBlurBlendEntry> _logoBlend(bool dark) => dark
    ? [
        _blend(0xE6A1A1A1, MiuixBlurBlendMode.colorDodge),
        _blend(0x4DE6E6E6, MiuixBlurBlendMode.linearLight),
        _blend(0xFF1AF500, MiuixBlurBlendMode.lab),
      ]
    : [
        _blend(0xCC4A4A4A, MiuixBlurBlendMode.colorBurn),
        _blend(0xFF4F4F4F, MiuixBlurBlendMode.linearLight),
        _blend(0xFF1AF200, MiuixBlurBlendMode.lab),
      ];
