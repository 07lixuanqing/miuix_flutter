part of 'main.dart';

/// Main settings card in the exact current `SettingsContent` row order.
class _ReferenceSettingsUiCard extends StatelessWidget {
  const _ReferenceSettingsUiCard({
    required this.wide,
    required this.colorMode,
    required this.onColorModeChanged,
    required this.settings,
    required this.onSettingsChanged,
  });

  final bool wide;
  final MiuixColorMode colorMode;
  final ValueChanged<MiuixColorMode> onColorModeChanged;
  final _MiuixExampleSettings settings;
  final ValueChanged<_MiuixExampleSettings> onSettingsChanged;

  @override
  Widget build(BuildContext context) {
    final monet = _isReferenceMonetMode(colorMode);
    return MiuixCard(
      key: const ValueKey('reference-settings-ui-card'),
      // The source wraps this complete card in Modifier.padding(12.dp). The
      // list already owns the top and horizontal copies; retain the separately
      // rounded bottom edge before the following SmallTitle.
      margin: EdgeInsets.only(bottom: _referenceRoundedDp(context, 12)),
      child: Column(
        children: [
          MiuixSwitchPreference(
            title: '显示 FPS 监视器',
            value: settings.showFpsMonitor,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(showFpsMonitor: value)),
          ),
          _referenceSettingsDropdown<MiuixColorMode>(
            title: '颜色模式',
            value: colorMode,
            entries: _referenceColorModeEntries,
            onChanged: onColorModeChanged,
          ),
          _ReferenceAnimatedVisibility(
            visible: monet,
            child: _referenceSettingsDropdown<int>(
              title: '关键色',
              value: settings.keyColorIndex,
              entries: _referenceKeyColorEntries(),
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(keyColorIndex: value)),
            ),
          ),
          _ReferenceAnimatedVisibility(
            visible: monet && settings.keyColorIndex > 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _referenceSettingsDropdown<MiuixThemePaletteStyle>(
                  title: '调色板样式',
                  value: settings.paletteStyle,
                  entries: _referencePaletteStyleEntries,
                  onChanged: (value) =>
                      onSettingsChanged(settings.copyWith(paletteStyle: value)),
                ),
                _referenceSettingsDropdown<MiuixThemeColorSpec>(
                  title: '色彩规范',
                  value: settings.colorSpec,
                  entries: _referenceColorSpecEntries,
                  onChanged: (value) =>
                      onSettingsChanged(settings.copyWith(colorSpec: value)),
                ),
              ],
            ),
          ),
          MiuixSwitchPreference(
            title: '启用超椭圆形状',
            value: settings.enableSquircle,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enableSquircle: value)),
          ),
          MiuixSwitchPreference(
            title: '启用模糊效果',
            value: settings.enableBlur,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enableBlur: value)),
          ),
          MiuixSwitchPreference(
            title: '启用滚动结束触觉反馈',
            value: settings.enableScrollEndHaptic,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(enableScrollEndHaptic: value),
            ),
          ),
          MiuixSwitchPreference(
            title: '允许页面横向滑动',
            value: settings.enablePageSwipe,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enablePageSwipe: value)),
          ),
          MiuixSwitchPreference(
            title: '显示顶部栏',
            value: settings.showTopBar,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(showTopBar: value)),
          ),
          _ReferenceAnimatedVisibility(
            visible: settings.showTopBar && settings.enableBlur,
            child: _referenceSettingsDropdown<String>(
              title: '顶部栏模糊样式',
              value: settings.blurStyle,
              entries: _referenceBlurStyleEntries,
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(blurStyle: value)),
            ),
          ),
          MiuixSwitchPreference(
            title: wide ? '显示导航轨' : '显示导航栏',
            value: settings.showNavigation,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(showNavigation: value)),
          ),
          _ReferenceAnimatedVisibility(
            visible: settings.showNavigation,
            child: MiuixSwitchPreference(
              title: '显示导航徽标',
              value: settings.showBadge,
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(showBadge: value)),
            ),
          ),
          _ReferenceAnimatedVisibility(
            visible:
                settings.showNavigation &&
                !wide &&
                !settings.useFloatingNavigationBar,
            child: _referenceSettingsDropdown<String>(
              title: '导航栏模式',
              value: settings.navigationMode,
              entries: _referenceNavigationModeEntries,
              popupMinWidth: 238.5,
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(navigationMode: value)),
            ),
          ),
          _ReferenceAnimatedVisibility(
            visible: settings.showNavigation && !wide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiuixSwitchPreference(
                  title: '使用悬浮导航栏',
                  value: settings.useFloatingNavigationBar,
                  onChanged: (value) => onSettingsChanged(
                    settings.copyWith(useFloatingNavigationBar: value),
                  ),
                ),
              ],
            ),
          ),
          MiuixSwitchPreference(
            title: '显示浮动工具栏',
            value: settings.showFloatingToolbar,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(showFloatingToolbar: value),
            ),
          ),
          _ReferenceAnimatedVisibility(
            visible: settings.showFloatingToolbar,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _referenceSettingsDropdown<String>(
                  title: '浮动工具栏位置',
                  value: settings.floatingToolbarPosition,
                  entries: _referenceFloatingToolbarPositionEntries,
                  onChanged: (value) => onSettingsChanged(
                    settings.copyWith(floatingToolbarPosition: value),
                  ),
                ),
                _referenceSettingsDropdown<String>(
                  title: '浮动工具栏方向',
                  value: settings.floatingToolbarOrientation,
                  entries: _referenceFloatingToolbarOrientationEntries,
                  onChanged: (value) => onSettingsChanged(
                    settings.copyWith(floatingToolbarOrientation: value),
                  ),
                ),
              ],
            ),
          ),
          MiuixSwitchPreference(
            title: '显示浮动操作按钮',
            value: settings.showFloatingButton,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(showFloatingButton: value)),
          ),
          _ReferenceAnimatedVisibility(
            visible: settings.showFloatingButton,
            child: _referenceSettingsDropdown<String>(
              title: '浮动操作按钮位置',
              value: settings.floatingActionButtonPosition,
              entries: _referenceFabPositionEntries,
              onChanged: (value) => onSettingsChanged(
                settings.copyWith(floatingActionButtonPosition: value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds the exact index-based overlay preference used by `SettingsPage.kt`.
///
/// The translated settings state keeps typed values because that makes the
/// surrounding Dart model less error-prone. The source component itself,
/// however, receives an item list and selected index. Converting at this
/// boundary preserves that public contract as well as its overlay popup path.
MiuixOverlayDropdownPreference<int> _referenceSettingsDropdown<T>({
  Key? key,
  required String title,
  required T value,
  required List<MiuixDropdownEntry<T>> entries,
  required ValueChanged<T> onChanged,
  double popupMinWidth = 200,
}) {
  final selectedIndex = entries.indexWhere((entry) => entry.value == value);
  assert(
    selectedIndex >= 0,
    'The selected settings value must identify a dropdown entry.',
  );
  return MiuixOverlayDropdownPreference<int>(
    key: key,
    title: title,
    value: selectedIndex,
    entries: [
      for (var index = 0; index < entries.length; index++)
        MiuixDropdownEntry<int>(value: index, label: entries[index].label),
    ],
    onChanged: (index) => onChanged(entries[index].value),
    popupMinWidth: popupMinWidth,
    sourceMode: true,
  );
}

/// Flutter equivalent of the source settings page's `AnimatedVisibility`.
///
/// The child remains mounted for its exit animation, then is removed so hidden
/// preference rows cannot receive input or appear in semantics and finders.
class ReferenceLayerOpacity extends StatelessWidget {
  const ReferenceLayerOpacity({
    super.key,
    required this.opacity,
    required this.child,
  });

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (opacity >= 1) {
      // Preserve the local graphics-layer boundary used by Compose without
      // filtering or recoloring the resting pixels.
      return RepaintBoundary(child: child);
    }
    if (opacity <= 0) {
      // Zero-opacity children must retain their final layout for the source
      // expand animation, but they do not need to paint a blur layer.
      return Opacity(opacity: 0, child: child);
    }
    // `Opacity` lets Impeller push inherited alpha into a BackdropFilter. That
    // path is invalid for the glass navigation surface. Compose instead fades
    // the completed graphics layer, so multiply final RGBA only while moving.
    // Resting at alpha one returns the original subtree so its paint bounds and
    // golden pixels remain completely unchanged.
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Color.fromRGBO(255, 255, 255, opacity),
        BlendMode.modulate,
      ),
      child: child,
    );
  }
}

class _ReferenceAnimatedVisibility extends StatefulWidget {
  const _ReferenceAnimatedVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.verticalOnly = false,
    this.verticalAlignment = Alignment.bottomCenter,
    this.opacityKey,
    this.alignKey,
    this.hiddenKey,
  });

  final bool visible;
  final Widget child;

  /// Uses `expandVertically` instead of the default two-axis `expandIn`.
  final bool verticalOnly;

  /// Anchor used by source `expandVertically` and `shrinkVertically` calls.
  final Alignment verticalAlignment;

  /// Optional stable keys used by deterministic transition regressions.
  final Key? opacityKey;
  final Key? alignKey;
  final Key? hiddenKey;

  @override
  State<_ReferenceAnimatedVisibility> createState() =>
      _ReferenceAnimatedVisibilityState();
}

class _ReferenceAnimatedVisibilityState
    extends State<_ReferenceAnimatedVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _includeChild;
  int _transitionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _includeChild = widget.visible;
    _controller = AnimationController.unbounded(
      vsync: this,
      value: widget.visible ? 1 : 0,
    )..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant _ReferenceAnimatedVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      setState(() => _includeChild = true);
    }
    _springTo(widget.visible);
  }

  void _springTo(bool visible) {
    final generation = ++_transitionGeneration;
    final target = visible ? 1.0 : 0.0;
    _controller
        .animateWith(
          SpringSimulation(
            debugReferenceVisibilitySpring(),
            _controller.value,
            target,
            _controller.velocity,
            tolerance: const Tolerance(distance: .01, velocity: .01),
          ),
        )
        .whenCompleteOrCancel(() {
          if (!mounted || generation != _transitionGeneration) return;
          _controller.value = target;
          if (!widget.visible) {
            setState(() => _includeChild = false);
          }
        });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_includeChild) return SizedBox.shrink(key: widget.hiddenKey);
    final progress = _controller.value.clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: ClipRect(
          child: Align(
            key: widget.alignKey,
            alignment: widget.verticalOnly
                ? widget.verticalAlignment
                : AlignmentDirectional.bottomEnd,
            widthFactor: widget.verticalOnly ? null : progress,
            heightFactor: progress,
            child: ReferenceLayerOpacity(
              key: widget.opacityKey,
              opacity: progress,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
