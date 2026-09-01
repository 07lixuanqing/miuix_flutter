part of 'main.dart';

// Option order mirrors the current SettingsPage.kt declarations exactly.

const _referenceColorModeEntries = <MiuixDropdownEntry<MiuixColorMode>>[
  MiuixDropdownEntry(value: MiuixColorMode.system, label: '跟随系统'),
  MiuixDropdownEntry(value: MiuixColorMode.light, label: '浅色'),
  MiuixDropdownEntry(value: MiuixColorMode.dark, label: '深色'),
  MiuixDropdownEntry(value: MiuixColorMode.monetSystem, label: 'Monet 跟随系统'),
  MiuixDropdownEntry(value: MiuixColorMode.monetLight, label: 'Monet 浅色'),
  MiuixDropdownEntry(value: MiuixColorMode.monetDark, label: 'Monet 深色'),
];

const _referencePaletteStyleEntries =
    <MiuixDropdownEntry<MiuixThemePaletteStyle>>[
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.tonalSpot, label: '色调点'),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.neutral, label: '中性'),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.vibrant, label: '鲜艳'),
      MiuixDropdownEntry(
        value: MiuixThemePaletteStyle.expressive,
        label: '表现力',
      ),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.rainbow, label: '彩虹'),
      MiuixDropdownEntry(
        value: MiuixThemePaletteStyle.fruitSalad,
        label: '水果沙拉',
      ),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.monochrome, label: '单色'),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.fidelity, label: '保真'),
      MiuixDropdownEntry(value: MiuixThemePaletteStyle.content, label: '内容'),
    ];

const _referenceColorSpecEntries = <MiuixDropdownEntry<MiuixThemeColorSpec>>[
  MiuixDropdownEntry(value: MiuixThemeColorSpec.spec2021, label: '规范 2021'),
  MiuixDropdownEntry(value: MiuixThemeColorSpec.spec2025, label: '规范 2025'),
];

const _referenceNavigationModeEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'iconAndText', label: '图标和文字'),
  MiuixDropdownEntry(value: 'iconOnly', label: '仅图标'),
  MiuixDropdownEntry(value: 'textOnly', label: '仅文字'),
  MiuixDropdownEntry(value: 'iconWithSelectedLabel', label: '仅选中项显示文字'),
];

const _referenceBlurStyleEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'gradient', label: '渐变模糊'),
  MiuixDropdownEntry(value: 'gaussian', label: '均匀模糊'),
  MiuixDropdownEntry(value: 'progressive', label: '滚动渐显模糊'),
];

const _referenceNavigationTransitionEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'miuix', label: 'MIUIX'),
  MiuixDropdownEntry(value: 'aosp', label: 'AOSP'),
];

const _referenceFloatingNavigationModeEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'iconAndText', label: '图标和文字'),
  MiuixDropdownEntry(value: 'iconOnly', label: '仅图标'),
  MiuixDropdownEntry(value: 'textOnly', label: '仅文字'),
];

const _referenceFloatingToolbarPositionEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'topStart', label: '左上'),
  MiuixDropdownEntry(value: 'centerStart', label: '左侧居中'),
  MiuixDropdownEntry(value: 'bottomStart', label: '左下'),
  MiuixDropdownEntry(value: 'topEnd', label: '右上'),
  MiuixDropdownEntry(value: 'centerEnd', label: '右侧居中'),
  MiuixDropdownEntry(value: 'bottomEnd', label: '右下'),
  MiuixDropdownEntry(value: 'topCenter', label: '顶部居中'),
  MiuixDropdownEntry(value: 'bottomCenter', label: '底部居中'),
];

const _referenceFloatingToolbarOrientationEntries =
    <MiuixDropdownEntry<String>>[
      MiuixDropdownEntry(value: 'horizontal', label: '横向'),
      MiuixDropdownEntry(value: 'vertical', label: '纵向'),
    ];

const _referenceFabPositionEntries = <MiuixDropdownEntry<String>>[
  MiuixDropdownEntry(value: 'start', label: '靠左'),
  MiuixDropdownEntry(value: 'center', label: '居中'),
  MiuixDropdownEntry(value: 'end', label: '靠右'),
  MiuixDropdownEntry(value: 'endOverlay', label: '右侧覆盖'),
];

const _referenceGlassIntensityEntries =
    <MiuixDropdownEntry<MiuixGlassIntensity>>[
      MiuixDropdownEntry(value: MiuixGlassIntensity.subtle, label: '1 档 · 轻微'),
      MiuixDropdownEntry(value: MiuixGlassIntensity.light, label: '2 档 · 较轻'),
      MiuixDropdownEntry(
        value: MiuixGlassIntensity.standard,
        label: '3 档 · 标准',
      ),
      MiuixDropdownEntry(value: MiuixGlassIntensity.strong, label: '4 档 · 较强'),
      MiuixDropdownEntry(value: MiuixGlassIntensity.intense, label: '5 档 · 最强'),
    ];

/// Builds Default plus the seven localized source key-color options.
List<MiuixDropdownEntry<int>> _referenceKeyColorEntries() => [
  const MiuixDropdownEntry(value: 0, label: '默认'),
  for (var index = 0; index < _referenceKeyColors.length; index++)
    MiuixDropdownEntry(
      value: index + 1,
      label: _referenceKeyColors[index].label,
    ),
];

/// Whether the selected mode is one of the three Monet modes.
bool _isReferenceMonetMode(MiuixColorMode mode) => switch (mode) {
  MiuixColorMode.monetSystem ||
  MiuixColorMode.monetLight ||
  MiuixColorMode.monetDark => true,
  _ => false,
};
