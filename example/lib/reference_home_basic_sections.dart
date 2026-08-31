part of 'main.dart';

// These widgets mirror the first six component files in the upstream sample.
// Each chapter owns its state so filtering the home list does not couple
// unrelated controls or make the page shell grow into a monolithic fixture.

/// Localizes boolean values without changing the source example's state model.
String _referenceBoolean(bool value) => value ? '是' : '否';

/// Resolves the explicit action-text style used by source example call sites.
///
/// BasicComponent does not recolor arbitrary endActions. Every original demo
/// therefore supplies body2 metrics and either onSurfaceVariantActions or the
/// dedicated disabled role; keeping that choice here prevents plain Text from
/// inheriting the much darker body color.
TextStyle _referenceActionTextStyle(
  BuildContext context, {
  bool disabled = false,
}) {
  final colors = MiuixSemanticColors.of(context);
  return TextStyle(
    color:
        colors[disabled
            ? 'disabledOnSecondaryVariant'
            : 'onSurfaceVariantActions'],
    fontSize: 14,
  );
}

/// Enabled and disabled BasicComponent rows with both action slots populated.
class _ReferenceBasicComponentSection extends StatelessWidget {
  const _ReferenceBasicComponentSection();

  Widget _actions(BuildContext context, bool enabled) {
    final style = _referenceActionTextStyle(context, disabled: !enabled);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('尾部一', style: style),
        const SizedBox(width: 8),
        Text('尾部二', style: style),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '基础组件',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-basic-component-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixBasicComponent.sourceText(
                title: '标题',
                summary: '摘要',
                startAction: const Text('开头'),
                endActions: _actions(context, true),
              ),
              MiuixBasicComponent.sourceText(
                title: '标题',
                summary: '摘要',
                startAction: Text(
                  '开头',
                  style: TextStyle(
                    color: MiuixSemanticColors.of(
                      context,
                    )['disabledOnSecondaryVariant'],
                  ),
                ),
                endActions: _actions(context, false),
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Four raw switches plus expandable and disabled preference variants.
class _ReferenceSwitchSection extends StatefulWidget {
  const _ReferenceSwitchSection();

  @override
  State<_ReferenceSwitchSection> createState() =>
      _ReferenceSwitchSectionState();
}

class _ReferenceSwitchSectionState extends State<_ReferenceSwitchSection> {
  bool _off = false;
  bool _on = true;
  bool _expanded = false;
  bool _nested = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '开关',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-switch-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MiuixSwitch(
                      key: const ValueKey('reference-switch-off'),
                      value: _off,
                      onChanged: (value) => setState(() => _off = value),
                    ),
                    MiuixSwitch(
                      key: const ValueKey('reference-switch-on'),
                      value: _on,
                      onChanged: (value) => setState(() => _on = value),
                    ),
                    MiuixSwitch(
                      key: const ValueKey('reference-switch-disabled-off'),
                      value: false,
                      enabled: false,
                      onChanged: (_) {},
                    ),
                    MiuixSwitch(
                      key: const ValueKey('reference-switch-disabled-on'),
                      value: true,
                      enabled: false,
                      onChanged: (_) {},
                    ),
                  ],
                ),
              ),
              MiuixSwitchPreference.source(
                key: const ValueKey('reference-switch-main-preference'),
                title: '开关',
                summary: '点击以展开一个开关',
                checked: _expanded,
                onCheckedChange: (value) => setState(() => _expanded = value),
              ),
              _ReferenceAnimatedVisibility(
                key: const ValueKey('reference-switch-expanded-visibility'),
                visible: _expanded,
                verticalOnly: true,
                child: MiuixSwitchPreference.source(
                  title: '开关',
                  checked: _nested,
                  endActions: Text(
                    _referenceBoolean(_nested),
                    style: _referenceActionTextStyle(context),
                  ),
                  onCheckedChange: (value) => setState(() => _nested = value),
                ),
              ),
              MiuixSwitchPreference.source(
                key: const ValueKey('reference-switch-disabled-preference'),
                title: '禁用的开关',
                checked: true,
                enabled: false,
                onCheckedChange: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Raw binary/mixed states and both checkbox preference placements.
class _ReferenceCheckboxSection extends StatefulWidget {
  const _ReferenceCheckboxSection();

  @override
  State<_ReferenceCheckboxSection> createState() =>
      _ReferenceCheckboxSectionState();
}

class _ReferenceCheckboxSectionState extends State<_ReferenceCheckboxSection> {
  bool _off = false;
  bool _on = true;
  int _mixedState = 1;
  bool _end = false;
  bool _start = false;

  void _cycleMixed() {
    setState(() => _mixedState = (_mixedState + 1) % 3);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '复选框',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-checkbox-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MiuixCheckbox(
                      key: const ValueKey('reference-checkbox-off'),
                      value: _off,
                      onChanged: (value) =>
                          setState(() => _off = value ?? false),
                    ),
                    MiuixCheckbox(
                      key: const ValueKey('reference-checkbox-on'),
                      value: _on,
                      onChanged: (value) =>
                          setState(() => _on = value ?? false),
                    ),
                    MiuixCheckbox(
                      key: const ValueKey('reference-checkbox-mixed'),
                      value: _mixedState == 2,
                      indeterminate: _mixedState == 1,
                      onChanged: (_) => _cycleMixed(),
                    ),
                    const MiuixCheckbox(
                      value: false,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixCheckbox(
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    const MiuixCheckbox(
                      value: false,
                      indeterminate: true,
                      enabled: false,
                      onChanged: null,
                    ),
                  ],
                ),
              ),
              MiuixCheckboxPreference.source(
                key: const ValueKey('reference-checkbox-end-preference'),
                title: '复选框',
                checked: _end,
                checkboxLocation: MiuixCheckboxLocation.end,
                endActions: Text(
                  _referenceBoolean(_end),
                  style: _referenceActionTextStyle(context),
                ),
                onCheckedChange: (value) => setState(() => _end = value),
              ),
              MiuixCheckboxPreference.source(
                key: const ValueKey('reference-checkbox-start-preference'),
                title: '复选框',
                summary: '状态：${_referenceBoolean(_start)}',
                checked: _start,
                checkboxLocation: MiuixCheckboxLocation.start,
                onCheckedChange: (value) => setState(() => _start = value),
              ),
              MiuixCheckboxPreference.source(
                key: const ValueKey('reference-checkbox-disabled-preference'),
                title: '禁用的复选框',
                checked: true,
                checkboxLocation: MiuixCheckboxLocation.start,
                enabled: false,
                onCheckedChange: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Three selectable radio options followed by the disabled selected state.
class _ReferenceRadioSection extends StatefulWidget {
  const _ReferenceRadioSection();

  @override
  State<_ReferenceRadioSection> createState() => _ReferenceRadioSectionState();
}

class _ReferenceRadioSectionState extends State<_ReferenceRadioSection> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    const labels = ['选项 A', '选项 B', '选项 C'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '单选按钮',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        // RadioButtonSection.kt deliberately gives every option its own Card.
        // Keeping one shared surface here removes the three 12dp gaps and all
        // intermediate rounded corners, which is a visible structural change.
        for (var index = 0; index < labels.length; index++)
          MiuixCard(
            key: ValueKey('reference-radio-card-$index'),
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.zero,
            child: MiuixRadioButtonPreference.source(
              key: ValueKey('reference-radio-option-$index'),
              title: labels[index],
              summary: '已选择：${_referenceBoolean(_selected == index)}',
              selected: _selected == index,
              onClick: () => setState(() => _selected = index),
            ),
          ),
        MiuixCard(
          key: const ValueKey('reference-radio-disabled-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: MiuixRadioButtonPreference.source(
            key: const ValueKey('reference-radio-disabled-preference'),
            title: '禁用的单选按钮',
            summary: '此选项不可用',
            selected: true,
            enabled: false,
            onClick: () {},
          ),
        ),
      ],
    );
  }
}

/// Two interactive text buttons and their two disabled counterparts.
class _ReferenceButtonSection extends StatefulWidget {
  const _ReferenceButtonSection();

  @override
  State<_ReferenceButtonSection> createState() =>
      _ReferenceButtonSectionState();
}

class _ReferenceButtonSectionState extends State<_ReferenceButtonSection> {
  int _cancelClicks = 0;
  int _submitClicks = 0;

  Widget _button(
    BuildContext context,
    String label,
    VoidCallback callback, {
    bool primary = false,
    bool enabled = true,
  }) {
    return Expanded(
      child: MiuixTextButton(
        label: label,
        onPressed: callback,
        enabled: enabled,
        colors: primary
            ? MiuixButtonDefaults.textButtonColors(context, primary: true)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceSpacing = _referenceRoundedDp(context, 12);
    return Column(
      key: const ValueKey('reference-button-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '按钮',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        Row(
          children: [
            _button(
              context,
              _cancelClicks == 0 ? '取消' : '点击：$_cancelClicks',
              () => setState(() => _cancelClicks++),
            ),
            SizedBox(width: sourceSpacing),
            _button(
              context,
              _submitClicks == 0 ? '提交' : '点击：$_submitClicks',
              () => setState(() => _submitClicks++),
              primary: true,
            ),
          ],
        ),
        SizedBox(height: sourceSpacing),
        Row(
          children: [
            _button(context, '禁用', () {}, enabled: false),
            SizedBox(width: sourceSpacing),
            _button(context, '禁用', () {}, primary: true, enabled: false),
          ],
        ),
        SizedBox(height: sourceSpacing),
      ],
    );
  }
}

/// Three-tab row and six-tab contoured pager from the source sample.
class _ReferenceTabSection extends StatefulWidget {
  const _ReferenceTabSection();

  @override
  State<_ReferenceTabSection> createState() => _ReferenceTabSectionState();
}

class _ReferenceTabSectionState extends State<_ReferenceTabSection>
    with SingleTickerProviderStateMixin {
  int _simpleIndex = 0;
  int _contourIndex = 0;
  late final PageController _contourPages;
  late final AnimationController _contourPageMotion;

  @override
  void initState() {
    super.initState();
    _contourPages = PageController();
    _contourPageMotion = AnimationController.unbounded(vsync: this, value: 0)
      ..addListener(_driveContourPager);
  }

  /// Applies the normalized spring position to Flutter's pixel scroll model.
  void _driveContourPager() {
    if (!_contourPages.hasClients) {
      return;
    }
    final position = _contourPages.position;
    final targetPixels = (_contourPageMotion.value * position.viewportDimension)
        .clamp(position.minScrollExtent, position.maxScrollExtent)
        .toDouble();
    if ((position.pixels - targetPixels).abs() > .001) {
      position.jumpTo(targetPixels);
    }
  }

  /// Moves the pager with Compose Pager's exact default spring.
  void _selectContour(int index) {
    if (!_contourPages.hasClients) {
      return;
    }
    final currentPage = _contourPages.page ?? _contourIndex.toDouble();
    final currentVelocity = _contourPageMotion.isAnimating
        ? _contourPageMotion.velocity
        : 0.0;
    _contourPageMotion
      ..stop()
      ..value = currentPage
      ..animateWith(
        SpringSimulation(
          debugReferenceTabPagerSpring(),
          currentPage,
          index.toDouble(),
          currentVelocity,
        ),
      );
  }

  /// Keeps the tab indicator synchronized when the user swipes the page.
  void _pageChanged(int index) {
    if (_contourIndex != index) {
      setState(() => _contourIndex = index);
    }
  }

  /// A direct pointer drag takes ownership from an in-flight programmatic move.
  bool _handleContourScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null && _contourPageMotion.isAnimating) {
      _contourPageMotion.stop(canceled: false);
    }
    return false;
  }

  @override
  void dispose() {
    _contourPageMotion
      ..removeListener(_driveContourPager)
      ..dispose();
    _contourPages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const simpleTabs = ['标签 1', '标签 2', '标签 3'];
    const contourTabs = ['标签 1', '标签 2', '标签 3', '标签 4', '标签 5', '标签 6'];
    final sourceBodyStyle =
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 17, height: 1.16);
    final scaledBodySize = MediaQuery.textScalerOf(
      context,
    ).scale(sourceBodyStyle.fontSize ?? 17);
    final sourceBodyHeight = _referenceRoundedDp(
      context,
      scaledBodySize * (sourceBodyStyle.height ?? 1.16),
    );
    final sourceBodyRatio = sourceBodyHeight / scaledBodySize;
    final sourceContourSpacing = _referenceRoundedDp(context, 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '标签栏',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixTabRow(
          tabs: simpleTabs,
          selectedTabIndex: _simpleIndex,
          onTabSelected: (index) => setState(() => _simpleIndex = index),
        ),
        SizedBox(height: sourceContourSpacing),
        MiuixCard(
          key: const ValueKey('reference-contour-tab-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiuixTabRowWithContour(
                tabs: contourTabs,
                selectedTabIndex: _contourIndex,
                onTabSelected: _selectContour,
              ),
              SizedBox(height: sourceContourSpacing),
              SizedBox(
                key: const ValueKey('reference-tab-content-pager'),
                // HorizontalPager has no explicit height in the source. Its
                // single 17 sp Text placeable therefore contributes the
                // measured 52 px line box at the 420 dpi reference density.
                height: sourceBodyHeight,
                child: NotificationListener<ScrollStartNotification>(
                  onNotification: _handleContourScrollStart,
                  child: PageView.builder(
                    key: const PageStorageKey('reference-contour-tab-pager'),
                    controller: _contourPages,
                    itemCount: contourTabs.length,
                    onPageChanged: _pageChanged,
                    itemBuilder: (context, index) => Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${contourTabs[index]} 的内容',
                        maxLines: 1,
                        style: sourceBodyStyle.copyWith(
                          height: sourceBodyRatio,
                        ),
                        strutStyle: StrutStyle(
                          fontSize: sourceBodyStyle.fontSize ?? 17,
                          height: sourceBodyRatio,
                          forceStrutHeight: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Arrow, clickable volume slider, and disabled arrow states from the source.
class _ReferenceArrowSection extends StatefulWidget {
  const _ReferenceArrowSection();

  @override
  State<_ReferenceArrowSection> createState() => _ReferenceArrowSectionState();
}

class _ReferenceArrowSectionState extends State<_ReferenceArrowSection> {
  double _volume = .5;
  bool _dialogHeld = false;

  void _showVolumeDialog() {
    final host = MiuixPopupHostScope.maybeOf(context)?.root;
    final controller = TextEditingController(
      // Kotlin `Float.toInt()` truncates toward zero; rounding changes values
      // such as 73.9% before the dialog is even shown.
      text: (_volume * 100).truncate().toString(),
    );
    setState(() => _dialogHeld = true);
    MiuixOverlayDialog.show<void>(
      context: context,
      title: '调整音量',
      summary: '输入 0-100',
      onDismissFinished: () {
        controller.dispose();
        if (mounted) {
          setState(() => _dialogHeld = false);
        }
      },
      content: StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final sourceActionSpacing = _referenceRoundedDp(dialogContext, 20);

          void dismiss({bool save = false}) {
            if (save) {
              final parsed = int.tryParse(controller.text);
              // An empty source field preserves the live slider value instead
              // of falling back to a newly invented 50% default.
              final fallback = (_volume * 100).truncate();
              setState(
                () => _volume = (parsed ?? fallback).clamp(0, 100) / 100,
              );
            }
            host?.dismissTop();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiuixTextField(
                controller: controller,
                singleLine: true,
                onChanged: (value) {
                  final digits = value.replaceAll(RegExp('[^0-9]'), '');
                  // The original takes at most the first three digits before
                  // parsing and clamping. Leading zeroes therefore matter:
                  // `0012` becomes `1`, not `12`.
                  final limited = digits.length <= 3
                      ? digits
                      : digits.substring(0, 3);
                  final parsed = int.tryParse(limited);
                  final normalized = parsed == null
                      ? ''
                      : parsed.clamp(0, 100).toString();
                  if (normalized != value) {
                    controller.value = TextEditingValue(
                      text: normalized,
                      selection: TextSelection.collapsed(
                        offset: normalized.length,
                      ),
                    );
                    setDialogState(() {});
                  }
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: MiuixButton(
                      label: '取消',
                      filled: false,
                      onPressed: dismiss,
                    ),
                  ),
                  SizedBox(width: sourceActionSpacing),
                  Expanded(
                    child: MiuixButton(
                      label: '确认',
                      filled: true,
                      onPressed: () => dismiss(save: true),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '箭头',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-arrow-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixArrowPreference.source(
                title: '箭头',
                startAction: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(_miuixIcon('Contacts'), semanticLabel: '个人'),
                ),
                endActions: Text(
                  '尾部',
                  style: _referenceActionTextStyle(context),
                ),
                onClick: () {},
              ),
              MiuixSliderPreference.source(
                title: '音量',
                valueText: '${(_volume * 100).truncate()}%',
                value: _volume,
                onValueChange: (value) => setState(() => _volume = value),
                onClick: _showVolumeDialog,
                holdDownState: _dialogHeld,
              ),
              MiuixArrowPreference.source(
                title: '禁用的箭头',
                endActions: Text(
                  '尾部',
                  style: _referenceActionTextStyle(context, disabled: true),
                ),
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
