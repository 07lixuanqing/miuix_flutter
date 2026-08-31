part of 'main.dart';

// This file contains the feedback, overlay, and effects chapters from the
// original Compose sample. Keeping these stateful demonstrations out of the
// page shell makes the source map one-to-one with the upstream section files.

/// Overlay- and window-hosted dialog variants from the source sample.
class _ReferenceDialogSection extends StatefulWidget {
  const _ReferenceDialogSection();

  @override
  State<_ReferenceDialogSection> createState() =>
      _ReferenceDialogSectionState();
}

class _ReferenceDialogSectionState extends State<_ReferenceDialogSection> {
  bool _overlayHeld = false;
  bool _windowHeld = false;
  bool _wideOverlayHeld = false;
  bool _wideWindowHeld = false;
  bool _centeredHeld = false;

  Widget _ordinaryActions(VoidCallback dismiss) {
    final sourceActionSpacing = _referenceRoundedDp(context, 20);
    return Row(
      children: [
        Expanded(
          child: MiuixTextButton(label: '取消', onPressed: dismiss),
        ),
        SizedBox(width: sourceActionSpacing),
        Expanded(
          child: MiuixTextButton(
            label: '确认',
            colors: MiuixButtonDefaults.textButtonColors(
              context,
              primary: true,
            ),
            onPressed: dismiss,
          ),
        ),
      ],
    );
  }

  Widget _wideAction(
    BuildContext context,
    String label,
    VoidCallback dismiss, {
    bool primary = false,
  }) {
    return SizedBox(
      width: double.infinity,
      child: MiuixTextButton(
        label: label,
        colors: primary
            ? MiuixButtonDefaults.textButtonColors(context, primary: true)
            : null,
        onPressed: dismiss,
      ),
    );
  }

  Widget _wideContent(
    BuildContext context,
    VoidCallback dismiss, {
    required bool landscape,
  }) {
    final sourceSpacing = _referenceRoundedDp(context, 12);
    final actions = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _wideAction(context, '仅允许一次', dismiss, primary: true),
        SizedBox(height: sourceSpacing),
        _wideAction(context, '始终允许', dismiss),
        SizedBox(height: sourceSpacing),
        _wideAction(context, '拒绝', dismiss),
      ],
    );
    if (!landscape) return actions;
    final dividerPadding = _referenceRoundedDp(context, 20);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '宽对话框',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: MiuixSemanticColors.of(context)['onBackground'],
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '旋转为横屏查看效果。',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: MiuixSemanticColors.of(
                      context,
                    )['onSurfaceSecondary'],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dividerPadding),
            child: const MiuixVerticalDivider(),
          ),
          Expanded(child: actions),
        ],
      ),
    );
  }

  void _showOverlay(BuildContext context) {
    final host = MiuixPopupHostScope.maybeOf(context)?.root;
    setState(() => _overlayHeld = true);
    MiuixOverlayDialog.show<void>(
      context: context,
      title: '对话框（O）',
      summary: 'MiuixPopupHost 内部的对话框组件。',
      onDismissFinished: () {
        if (mounted) {
          setState(() => _overlayHeld = false);
        }
      },
      content: _ordinaryActions(host?.dismissTop ?? () {}),
    );
  }

  void _showWindow(BuildContext context) {
    void dismiss() => Navigator.of(context, rootNavigator: true).pop();
    setState(() => _windowHeld = true);
    MiuixWindowDialog.show<void>(
      context: context,
      title: '对话框（W）',
      // The upstream English summary occupies two source body lines. Keep the
      // localized copy on the same two-line rhythm so the compact sheet does
      // not lose one 52px placeable and move its top edge downward.
      summary: '窗口级对话框，无需 MiuixPopupHost\n即可显示。',
      onDismissFinished: () {
        if (mounted) {
          setState(() => _windowHeld = false);
        }
      },
      content: _ordinaryActions(dismiss),
    );
  }

  void _showWideOverlay(BuildContext context) {
    final host = MiuixPopupHostScope.maybeOf(context)?.root;
    setState(() => _wideOverlayHeld = true);
    MiuixOverlayDialog.showBuilder<void>(
      context: context,
      dialogBuilder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final landscape = size.width > size.height;
        return MiuixDialog(
          title: landscape ? null : '宽对话框',
          summary: landscape ? null : '旋转为横屏查看效果。',
          maxWidth: landscape ? 560 : MiuixDialogDefaults.maxWidth,
          content: _wideContent(
            dialogContext,
            host?.dismissTop ?? () {},
            landscape: landscape,
          ),
        );
      },
      onDismissFinished: () {
        if (mounted) setState(() => _wideOverlayHeld = false);
      },
    );
  }

  void _showWideWindow(BuildContext context) {
    void dismiss() => Navigator.of(context, rootNavigator: true).pop();
    setState(() => _wideWindowHeld = true);
    MiuixWindowDialog.showBuilder<void>(
      context: context,
      dialogBuilder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final landscape = size.width > size.height;
        return MiuixDialog(
          title: landscape ? null : '宽对话框',
          summary: landscape ? null : '旋转为横屏查看效果。',
          maxWidth: landscape ? 560 : MiuixDialogDefaults.maxWidth,
          content: _wideContent(dialogContext, dismiss, landscape: landscape),
        );
      },
      onDismissFinished: () {
        if (mounted) setState(() => _wideWindowHeld = false);
      },
    );
  }

  void _showCentered(BuildContext context) {
    final host = MiuixPopupHostScope.maybeOf(context)?.root;
    setState(() => _centeredHeld = true);
    MiuixOverlayDialog.show<void>(
      context: context,
      title: '居中对话框',
      summary: 'largeScreen = true 会在任何窗口尺寸下强制使用居中显示方式。',
      largeScreen: true,
      onDismissFinished: () {
        if (mounted) setState(() => _centeredHeld = false);
      },
      content: _ordinaryActions(host?.dismissTop ?? () {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '对话框',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-dialog-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixArrowPreference.source(
                title: '对话框（O）',
                summary: '点击显示叠加对话框',
                holdDownState: _overlayHeld,
                onClick: () => _showOverlay(context),
              ),
              MiuixArrowPreference.source(
                title: '对话框（W）',
                summary: '点击显示窗口对话框',
                holdDownState: _windowHeld,
                onClick: () => _showWindow(context),
              ),
              MiuixArrowPreference.source(
                title: '宽对话框（O）',
                summary: '竖屏显示普通对话框；横屏显示双栏对话框',
                holdDownState: _wideOverlayHeld,
                onClick: () => _showWideOverlay(context),
              ),
              MiuixArrowPreference.source(
                title: '宽对话框（W）',
                summary: '竖屏显示普通对话框；横屏显示双栏对话框',
                holdDownState: _wideWindowHeld,
                onClick: () => _showWideWindow(context),
              ),
              MiuixArrowPreference.source(
                title: '居中对话框（O）',
                summary: '使用 largeScreen = true 强制采用大屏显示方式',
                holdDownState: _centeredHeld,
                onClick: () => _showCentered(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Overlay- and window-hosted bottom sheets with the original controls.
class _ReferenceBottomSheetSection extends StatefulWidget {
  const _ReferenceBottomSheetSection();

  @override
  State<_ReferenceBottomSheetSection> createState() =>
      _ReferenceBottomSheetSectionState();
}

class _ReferenceBottomSheetSectionState
    extends State<_ReferenceBottomSheetSection> {
  final _overlayBehavior = MiuixBottomSheetController();
  final _windowBehavior = MiuixBottomSheetController();
  bool _overlayHeld = false;
  bool _windowHeld = false;
  int _dropdown = 0;
  bool _switchValue = true;

  void _showOverlay(BuildContext context) {
    void close() => _overlayBehavior.dismiss();

    setState(() => _overlayHeld = true);
    MiuixOverlayBottomSheet.show<void>(
      context: context,
      controller: _overlayBehavior,
      title: '叠加底部弹层',
      startAction: MiuixIconButton(
        key: const ValueKey('overlay-sheet-close'),
        icon: Icon(
          _miuixIcon('Close'),
          color: MiuixSemanticColors.of(context)['onBackground'],
        ),
        onPressed: close,
      ),
      endAction: MiuixIconButton(
        key: const ValueKey('overlay-sheet-confirm'),
        icon: Icon(
          _miuixIcon('Ok'),
          color: MiuixSemanticColors.of(context)['onBackground'],
        ),
        onPressed: close,
      ),
      onDismissFinished: () {
        if (mounted) {
          setState(() => _overlayHeld = false);
        }
      },
      child: _ReferenceBottomSheetContent(
        behavior: _overlayBehavior,
        dropdownTitle: '叠加下拉偏好',
        dropdown: _dropdown,
        onDropdownChanged: (value) => _dropdown = value,
        switchValue: _switchValue,
        onSwitchChanged: (value) => _switchValue = value,
      ),
    );
  }

  void _showWindow(BuildContext context) {
    void close() => _windowBehavior.dismiss();

    setState(() => _windowHeld = true);
    MiuixWindowBottomSheet.show<void>(
      context: context,
      controller: _windowBehavior,
      title: '窗口底部弹层',
      startAction: MiuixIconButton(
        key: const ValueKey('window-sheet-close'),
        icon: Icon(
          _miuixIcon('Close'),
          color: MiuixSemanticColors.of(context)['onBackground'],
        ),
        onPressed: close,
      ),
      endAction: MiuixIconButton(
        key: const ValueKey('window-sheet-confirm'),
        icon: Icon(
          _miuixIcon('Ok'),
          color: MiuixSemanticColors.of(context)['onBackground'],
        ),
        onPressed: close,
      ),
      onDismissFinished: () {
        if (mounted) {
          setState(() => _windowHeld = false);
        }
      },
      child: _ReferenceBottomSheetContent(
        behavior: _windowBehavior,
        dropdownTitle: '窗口下拉偏好',
        dropdown: _dropdown,
        onDropdownChanged: (value) => _dropdown = value,
        switchValue: _switchValue,
        onSwitchChanged: (value) => _switchValue = value,
      ),
    );
  }

  @override
  void dispose() {
    _overlayBehavior.dispose();
    _windowBehavior.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '底部弹层',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-bottom-sheet-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixArrowPreference(
                title: '叠加底部弹层',
                summary: '点击显示叠加底部弹层',
                holdDown: _overlayHeld,
                onTap: () => _showOverlay(context),
              ),
              MiuixArrowPreference(
                title: '窗口底部弹层',
                summary: '点击显示窗口底部弹层',
                holdDown: _windowHeld,
                onTap: () => _showWindow(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stateful content shared by both bottom-sheet hosts.
class _ReferenceBottomSheetContent extends StatefulWidget {
  const _ReferenceBottomSheetContent({
    required this.behavior,
    required this.dropdownTitle,
    required this.dropdown,
    required this.onDropdownChanged,
    required this.switchValue,
    required this.onSwitchChanged,
  });

  final MiuixBottomSheetController behavior;
  final String dropdownTitle;
  final int dropdown;
  final ValueChanged<int> onDropdownChanged;
  final bool switchValue;
  final ValueChanged<bool> onSwitchChanged;

  @override
  State<_ReferenceBottomSheetContent> createState() =>
      _ReferenceBottomSheetContentState();
}

class _ReferenceBottomSheetContentState
    extends State<_ReferenceBottomSheetContent> {
  final _controller = TextEditingController();
  late bool _switchValue;
  late int _dropdown;

  @override
  void initState() {
    super.initState();
    _switchValue = widget.switchValue;
    _dropdown = widget.dropdown;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BottomSheetSection.kt measures every `Modifier.padding(bottom = 12.dp)`
    // independently. At the reference device's 2.625 density each one is
    // 32 physical pixels; four fractional 31.5px gaps otherwise collapse to
    // 126px in Flutter instead of Compose's 128px.
    final sourceBottomSpacing = _referenceRoundedDp(context, 12);
    return ConstrainedBox(
      // The source LazyColumn can use the sheet's remaining height and only
      // scrolls when its content reaches the status-bar-safe upper bound.
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.sizeOf(context).height -
            MediaQuery.paddingOf(context).top -
            82,
      ),
      child: MiuixScrollEndHaptic(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MiuixSmallTitle(
                '行为设置',
                insideMargin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              MiuixCard(
                color: MiuixSemanticColors.of(context)['secondaryContainer'],
                child: Column(
                  children: [
                    MiuixSwitchPreference(
                      title: '允许关闭',
                      summary: '拖动或按返回键关闭',
                      value: widget.behavior.allowDismiss,
                      onChanged: (value) =>
                          setState(() => widget.behavior.allowDismiss = value),
                    ),
                    MiuixSwitchPreference(
                      title: '启用嵌套滚动',
                      summary: '滚动内容或拖动弹层',
                      value: widget.behavior.enableNestedScroll,
                      onChanged: (value) => setState(
                        () => widget.behavior.enableNestedScroll = value,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: sourceBottomSpacing),
              MiuixTextField(controller: _controller, label: '文本框'),
              SizedBox(height: sourceBottomSpacing),
              MiuixCard(
                color: MiuixSemanticColors.of(context)['secondaryContainer'],
                child: Column(
                  children: [
                    MiuixDropdownPreference<int>(
                      title: widget.dropdownTitle,
                      value: _dropdown,
                      entries: const [
                        MiuixDropdownEntry(value: 0, label: '选项一'),
                        MiuixDropdownEntry(value: 1, label: '选项二'),
                      ],
                      onChanged: (value) => setState(() {
                        _dropdown = value;
                        widget.onDropdownChanged(value);
                      }),
                    ),
                    MiuixSwitchPreference(
                      title: '开关偏好',
                      value: _switchValue,
                      onChanged: (value) => setState(() {
                        _switchValue = value;
                        widget.onSwitchChanged(value);
                      }),
                    ),
                  ],
                ),
              ),
              // BottomSheetSection.kt gives the final preference card 12dp of
              // bottom padding before the navigation-bar spacer.  Keeping both
              // gaps is what gives the source sheet its content-sized height.
              SizedBox(height: sourceBottomSpacing),
              SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
            ],
          ),
        ),
      ),
    );
  }
}

/// Complete snackbar queue controls from the original example.
class _ReferenceSnackbarSection extends StatefulWidget {
  const _ReferenceSnackbarSection({required this.hostState});

  final MiuixSnackbarHostState hostState;

  @override
  State<_ReferenceSnackbarSection> createState() =>
      _ReferenceSnackbarSectionState();
}

class _ReferenceSnackbarSectionState extends State<_ReferenceSnackbarSection> {
  String _actionLabel = '操作';

  Widget _button(String label, VoidCallback onPressed, {bool primary = false}) {
    return Expanded(
      child: MiuixTextButton(
        label: label,
        onPressed: onPressed,
        colors: primary
            ? MiuixButtonDefaults.textButtonColors(context, primary: true)
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final host = widget.hostState;
    final sourceSpacing = _referenceRoundedDp(context, 12);
    return _ReferenceSectionCard(
      title: '提示条',
      cardKey: const ValueKey('reference-snackbar-card'),
      child: Column(
        children: [
          Row(
            children: [
              _button('关闭最早项', () async {
                await (await host.oldestSnackbarData())?.dismiss();
              }),
              SizedBox(width: sourceSpacing),
              _button('关闭最新项', () async {
                await (await host.newestSnackbarData())?.dismiss();
              }),
            ],
          ),
          SizedBox(height: sourceSpacing),
          Row(
            children: [
              _button('短时（4 秒）', () {
                host.showSnackbar('这条消息将显示 4 秒。');
              }),
              SizedBox(width: sourceSpacing),
              _button('长时（10 秒）', () {
                host.showSnackbar(
                  '这是一条将显示 10 秒的较长消息。',
                  duration: MiuixSnackbarDuration.long,
                );
              }),
            ],
          ),
          SizedBox(height: sourceSpacing),
          Row(
            children: [
              _button('自定（2 秒）', () {
                host.showSnackbar(
                  '这条消息使用自定义的 2 秒时长。',
                  duration: MiuixSnackbarDuration.custom(
                    const Duration(seconds: 2),
                  ),
                );
              }),
              SizedBox(width: sourceSpacing),
              _button(_actionLabel, () async {
                setState(() => _actionLabel = '操作：等待');
                final result = await host.showSnackbar(
                  '这条消息带有操作按钮。',
                  actionLabel: '撤销',
                );
                if (mounted) {
                  setState(
                    () => _actionLabel =
                        result == MiuixSnackbarResult.actionPerformed
                        ? '操作：已撤销'
                        : '操作：已过期',
                  );
                }
              }, primary: true),
            ],
          ),
          SizedBox(height: sourceSpacing),
          Row(
            children: [
              _button('可关闭', () {
                host.showSnackbar(
                  '点击关闭按钮可关闭这条消息。',
                  withDismissAction: true,
                  duration: MiuixSnackbarDuration.long,
                );
              }),
              SizedBox(width: sourceSpacing),
              _button('无限时', () {
                host.showSnackbar(
                  '这条消息会保留到手动关闭。',
                  withDismissAction: true,
                  duration: MiuixSnackbarDuration.indefinite,
                );
              }),
            ],
          ),
          SizedBox(height: sourceSpacing),
          Row(
            children: [
              _button('操作 + 关闭', () {
                host.showSnackbar(
                  '这条消息同时带有一个操作按钮和一个关闭按钮。',
                  actionLabel: '撤销',
                  withDismissAction: true,
                  duration: MiuixSnackbarDuration.long,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

/// Animated and fixed linear/circular progress values in source order.
class _ReferenceProgressSection extends StatefulWidget {
  const _ReferenceProgressSection();

  @override
  State<_ReferenceProgressSection> createState() =>
      _ReferenceProgressSectionState();
}

class _ReferenceProgressSectionState extends State<_ReferenceProgressSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    // Compose tween(1000) uses FastOutSlowInEasing unless another easing is
    // supplied. RepeatMode.Reverse applies the same curve in both directions.
    _progress = CurvedAnimation(
      parent: _animation,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn,
    );
    _animation.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const values = <double?>[0, .25, .5, .75, 1, null];
    // ProgressIndicatorSection.kt applies one 15dp modifier from the screen
    // edge. This translated list already owns a separately rounded 12dp page
    // inset, so rounding the remaining 3dp again would produce 32px + 8px at
    // 420dpi instead of Compose's single 39px inset. Subtract the placed page
    // pixels from the placed total and keep exactly the remaining seven.
    final sourceHorizontalInset =
        _referenceRoundedDp(context, 15) - _referenceRoundedDp(context, 12);
    final sourceBottomSpacing = _referenceRoundedDp(context, 12);
    final linearPadding = EdgeInsets.fromLTRB(
      sourceHorizontalInset,
      0,
      sourceHorizontalInset,
      sourceBottomSpacing,
    );
    return Column(
      key: const ValueKey('reference-progress-section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '进度指示器',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        Semantics(
          key: const ValueKey('reference-animated-linear-semantics'),
          role: SemanticsRole.progressBar,
          // The source animation reverses forever. Exposing its render value
          // on every frame makes Flutter emit a continuous stream of subtree
          // accessibility changes, while Compose keeps the surrounding lazy
          // list stable. A fixed midpoint preserves a truthful bounded
          // progress role without preventing UIAutomator or TalkBack from
          // reaching the TextField examples that follow this section.
          value: '0.5',
          minValue: '0',
          maxValue: '1',
          child: ExcludeSemantics(
            child: AnimatedBuilder(
              animation: _progress,
              builder: (context, _) => Padding(
                padding: linearPadding,
                child: MiuixLinearProgressIndicator(progress: _progress.value),
              ),
            ),
          ),
        ),
        for (final value in values)
          Padding(
            padding: linearPadding,
            child: MiuixLinearProgressIndicator(value: value),
          ),
        SizedBox(
          // The page already supplies the source's 12 dp horizontal inset.
          // Filling that remaining line reproduces Compose's `fillMaxWidth`;
          // a bare Wrap instead shrink-wraps all items.
          width: double.infinity,
          child: Wrap(
            key: const ValueKey('reference-progress-flow-row'),
            alignment: WrapAlignment.spaceEvenly,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                key: const ValueKey('reference-animated-circular-semantics'),
                role: SemanticsRole.progressBar,
                // Keep semantics stable for the same indefinitely reversing
                // source animation; the painted arc still updates each frame.
                value: '0.5',
                minValue: '0',
                maxValue: '1',
                child: ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) => MiuixCircularProgressIndicator(
                      progress: _progress.value,
                    ),
                  ),
                ),
              ),
              for (final value in values)
                MiuixCircularProgressIndicator(value: value),
              const MiuixInfiniteProgressIndicator(),
            ],
          ),
        ),
        SizedBox(height: sourceBottomSpacing),
      ],
    );
  }
}

/// Normal, sink, tilt, and long-press card demonstrations.
class _ReferenceCardSection extends StatefulWidget {
  const _ReferenceCardSection();

  @override
  State<_ReferenceCardSection> createState() => _ReferenceCardSectionState();
}

class _ReferenceCardSectionState extends State<_ReferenceCardSection> {
  bool _holdDown = false;

  void _showLongPressDialog() {
    final host = MiuixPopupHostScope.maybeOf(context)?.root;
    setState(() => _holdDown = true);
    unawaited(
      MiuixOverlayDialog.show<void>(
        context: context,
        title: '长按操作',
        summary: '通过长按卡片触发。',
        onDismissFinished: () {
          // Card.kt keeps HoldDownInteraction active throughout the complete
          // dialog exit transition and releases it only after removal.
          if (mounted) setState(() => _holdDown = false);
        },
        content: LayoutBuilder(
          builder: (dialogContext, constraints) {
            final density = MediaQuery.devicePixelRatioOf(dialogContext);
            final totalPixels = (constraints.maxWidth * density).round();
            final spacingPixels = (20 * density).round();
            final weightedPixels = totalPixels - spacingPixels;
            // Compose assigns the odd weighted remainder to the final child.
            // Flutter Flex assigns it to the first child at 420dpi, reversing
            // the source's measured 418px / 419px button widths.
            final cancelPixels = weightedPixels ~/ 2;
            final confirmPixels = weightedPixels - cancelPixels;
            return Row(
              children: [
                SizedBox(
                  width: cancelPixels / density,
                  child: MiuixTextButton(
                    label: '取消',
                    onPressed: host?.dismissTop,
                  ),
                ),
                SizedBox(width: spacingPixels / density),
                SizedBox(
                  width: confirmPixels / density,
                  child: MiuixTextButton(
                    label: '确认',
                    colors: MiuixButtonDefaults.textButtonColors(
                      dialogContext,
                      primary: true,
                    ),
                    onPressed: host?.dismissTop,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _sourceTextBlock(
    BuildContext context,
    String text, {
    required TextStyle style,
    required double sourceLineHeight,
    int lines = 1,
    int physicalPixelAdjustment = 0,
  }) {
    final fontSize = style.fontSize ?? 17;
    final scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
    // Compose rounds the complete Text placeable after shaping all of its
    // lines. Round this block once as well; rounding each line separately
    // would make the two-line Paragraph one physical pixel too tall at 420dpi.
    final density = MediaQuery.devicePixelRatioOf(context);
    final roundedBlockHeight = _referenceRoundedDp(
      context,
      scaledFontSize * sourceLineHeight * lines,
    );
    final blockHeight = roundedBlockHeight + physicalPixelAdjustment / density;
    final resolvedHeight = blockHeight / lines / scaledFontSize;
    final resolvedStyle = style.copyWith(height: resolvedHeight);
    final sourceStrut = StrutStyle(
      fontSize: fontSize,
      height: resolvedHeight,
      forceStrutHeight: true,
    );
    return SizedBox(
      height: blockHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: lines,
          overflow: TextOverflow.clip,
          style: resolvedStyle,
          strutStyle: sourceStrut,
        ),
      ),
    );
  }

  Widget _feedbackCard(
    BuildContext context,
    String type,
    MiuixPressFeedbackType feedbackType, {
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    return Expanded(
      child: MiuixCard(
        key: ValueKey('reference-card-feedback-${feedbackType.name}'),
        insideMargin: const EdgeInsets.all(16),
        feedbackType: feedbackType,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sourceTextBlock(
              context,
              '卡片',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              sourceLineHeight: 1.16,
            ),
            _sourceTextBlock(
              context,
              '按压反馈\n类型：$type',
              style: TextStyle(
                color: semantic['onSurfaceVariantSummary'],
                fontSize: 17,
              ),
              sourceLineHeight: 1.2,
              lines: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final sourceSpacing = _referenceRoundedDp(context, 12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '卡片',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-card-indication'),
          margin: const EdgeInsets.only(bottom: 12),
          insideMargin: const EdgeInsets.all(16),
          feedbackType: MiuixPressFeedbackType.none,
          showIndication: true,
          // Surface.kt installs indication only for an interactive surface.
          // Keep this demo honestly tappable instead of labelling a static card
          // as if it could display touch feedback.
          onTap: () {},
          colors: MiuixCardDefaults.colors(
            context,
            color: semantic['primaryVariant'],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sourceTextBlock(
                context,
                '卡片',
                style: TextStyle(
                  color: semantic['onPrimaryVariant'],
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                ),
                sourceLineHeight: 1.16,
              ),
              _sourceTextBlock(
                context,
                '显示触摸指示：是',
                style: TextStyle(
                  color: semantic['onPrimaryVariant'],
                  fontSize: 17,
                ),
                sourceLineHeight: 1.16,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _feedbackCard(
              context,
              '下沉',
              MiuixPressFeedbackType.sink,
              onTap: () {},
            ),
            SizedBox(width: sourceSpacing),
            _feedbackCard(
              context,
              '倾斜',
              MiuixPressFeedbackType.tilt,
              onLongPress: () {},
            ),
          ],
        ),
        SizedBox(height: sourceSpacing),
        MiuixCard.source(
          key: const ValueKey('reference-card-hold-down'),
          insideMargin: const EdgeInsets.all(16),
          pressFeedbackType: MiuixPressFeedbackType.sink,
          showIndication: true,
          holdDownState: _holdDown,
          onLongPress: _showLongPressDialog,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sourceTextBlock(
                context,
                '卡片',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                sourceLineHeight: 1.16,
              ),
              _sourceTextBlock(
                context,
                '长按以显示对话框',
                style: TextStyle(
                  color: semantic['onSurfaceVariantSummary'],
                  fontSize: 17,
                ),
                sourceLineHeight: 1.2,
                // BasicText's single-line Paragraph placeable is one physical
                // pixel shorter than the arithmetic em line height at 420dpi.
                // The original device surface is 192px; without this source
                // font-metric correction Flutter produces 193px.
                physicalPixelAdjustment: -1,
              ),
            ],
          ),
        ),
        SizedBox(height: sourceSpacing),
      ],
    );
  }
}

/// Current-source plain and persistent rich tooltip examples.
class _ReferenceTooltipSection extends StatefulWidget {
  const _ReferenceTooltipSection();

  @override
  State<_ReferenceTooltipSection> createState() =>
      _ReferenceTooltipSectionState();
}

class _ReferenceTooltipSectionState extends State<_ReferenceTooltipSection> {
  late final MiuixTooltipState _richState;

  @override
  void initState() {
    super.initState();
    _richState = MiuixTooltipState(isPersistent: true);
  }

  @override
  void dispose() {
    _richState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ReferenceSectionCard(
      title: '工具提示',
      cardKey: const ValueKey('reference-tooltip-card'),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MiuixTooltipBox(
            message: '编辑',
            child: MiuixIconButton(
              key: const ValueKey('reference-tooltip-plain-anchor'),
              icon: Icon(
                _miuixIcon('Edit'),
                // The original app-level controller supplies onBackground as
                // LocalContentColor for this intentionally untinted icon.
                color: MiuixSemanticColors.of(context)['onBackground'],
              ),
              onPressed: () {},
            ),
          ),
          MiuixRichTooltipBox.source(
            state: _richState,
            title: '丰富工具提示',
            text:
                '丰富工具提示会显示标题、辅助文字与可选操作。'
                '将指针移到提示上可使用操作，或点击外部将其关闭。',
            actionText: '知道了',
            onActionClick: () {},
            child: MiuixIconButton(
              key: const ValueKey('reference-tooltip-rich-anchor'),
              icon: Icon(
                _miuixIcon('Info'),
                color: MiuixSemanticColors.of(context)['onBackground'],
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

/// Reproduces FlowRow's integer-pixel SpaceEvenly distribution.
class _ReferenceSourceEvenFlowRow extends StatelessWidget {
  const _ReferenceSourceEvenFlowRow({
    required this.children,
    required this.itemExtent,
    required this.runSpacing,
  });

  final List<Widget> children;
  final double itemExtent;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final density = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || children.isEmpty) {
          return const SizedBox.shrink();
        }
        final widthPixels = (constraints.maxWidth * density).round();
        final itemPixels = math.max(1, (itemExtent * density).round());
        final spacingPixels = math.max(0, (runSpacing * density).round());
        final itemsPerRun = math.max(
          1,
          math.min(children.length, widthPixels ~/ itemPixels),
        );
        final runCount = (children.length + itemsPerRun - 1) ~/ itemsPerRun;
        final heightPixels =
            runCount * itemPixels + (runCount - 1) * spacingPixels;
        final positioned = <Widget>[];

        // Compose's FlowRow arranges each run in integer-pixel constraints.
        // SpaceEvenly rounds every cumulative share, which distributes the
        // 656px remainder as 131/131/132/131/131 on the reference device.
        for (var run = 0; run < runCount; run++) {
          final first = run * itemsPerRun;
          final count = math.min(itemsPerRun, children.length - first);
          final freePixels = math.max(0, widthPixels - count * itemPixels);
          for (var index = 0; index < count; index++) {
            final cumulativeSpace = ((index + 1) * freePixels / (count + 1))
                .round();
            final leftPixels = index * itemPixels + cumulativeSpace;
            final topPixels = run * (itemPixels + spacingPixels);
            positioned.add(
              Positioned(
                left: leftPixels / density,
                top: topPixels / density,
                width: itemPixels / density,
                height: itemPixels / density,
                // Compose FlowRow measures every child with a zero minimum
                // width and height, then assigns its SpaceEvenly position. A
                // Flutter Positioned cell is tight, so release that cell's
                // constraints before measuring the 28dp BadgedBox anchor.
                child: UnconstrainedBox(child: children[first + index]),
              ),
            );
          }
        }
        return SizedBox(
          width: constraints.maxWidth,
          height: heightPixels / density,
          child: Stack(clipBehavior: Clip.none, children: positioned),
        );
      },
    );
  }
}

/// Current-source dot and numeric badge combinations.
class _ReferenceBadgeSection extends StatelessWidget {
  const _ReferenceBadgeSection();

  @override
  Widget build(BuildContext context) {
    final sourcePadding = _referenceRoundedDp(context, 12);
    final sourceAnchorSize = _referenceRoundedDp(context, 28);
    final sourceRunSpacing = _referenceRoundedDp(context, 16);
    return _ReferenceSectionCard(
      title: '徽标',
      cardKey: const ValueKey('reference-badge-card'),
      padding: EdgeInsets.all(sourcePadding),
      child: _ReferenceSourceEvenFlowRow(
        itemExtent: sourceAnchorSize,
        runSpacing: sourceRunSpacing,
        children: [
          MiuixBadgedBox.source(
            key: const ValueKey('reference-badge-dot-anchor'),
            badge: const MiuixBadge.source(
              key: ValueKey('reference-badge-dot-surface'),
            ),
            child: Semantics(
              label: '消息',
              child: Icon(_miuixIcon('Messages'), size: sourceAnchorSize),
            ),
          ),
          MiuixBadgedBox.source(
            key: const ValueKey('reference-badge-eight-anchor'),
            badge: const MiuixBadge.source(
              key: ValueKey('reference-badge-eight-surface'),
              content: Text('8'),
            ),
            child: Semantics(
              label: '邮件',
              child: Icon(_miuixIcon('Email'), size: sourceAnchorSize),
            ),
          ),
          MiuixBadgedBox.source(
            key: const ValueKey('reference-badge-long-anchor'),
            badge: const MiuixBadge.source(
              key: ValueKey('reference-badge-long-surface'),
              content: Text('99+'),
            ),
            child: Semantics(
              label: '设置',
              child: Icon(_miuixIcon('Settings'), size: sourceAnchorSize),
            ),
          ),
          MiuixBadgedBox.source(
            key: const ValueKey('reference-badge-five-anchor'),
            badge: const MiuixBadge.source(
              key: ValueKey('reference-badge-five-surface'),
              content: Text('5'),
            ),
            child: Semantics(
              label: '收藏',
              child: Icon(_miuixIcon('Favorites'), size: sourceAnchorSize),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive, standalone, and disabled breadcrumb examples.
class _ReferenceBreadcrumbBarSection extends StatefulWidget {
  const _ReferenceBreadcrumbBarSection();

  @override
  State<_ReferenceBreadcrumbBarSection> createState() =>
      _ReferenceBreadcrumbBarSectionState();
}

class _ReferenceBreadcrumbBarSectionState
    extends State<_ReferenceBreadcrumbBarSection> {
  static const _items = [
    MiuixBreadcrumbItem(path: '/storage/emulated/0', text: '内部存储'),
    MiuixBreadcrumbItem(path: 'DataBackup'),
    MiuixBreadcrumbItem(path: 'apps'),
    MiuixBreadcrumbItem(path: 'com.tencent.mobileqq'),
    MiuixBreadcrumbItem(path: 'user_0'),
  ];

  int _highlightIndex = _items.length - 1;

  void _select(int index) {
    setState(() => _highlightIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final summaryColor = MiuixSemanticColors.of(
      context,
    )['onSurfaceVariantSummary'];
    final fullPath = miuixJoinBreadcrumbPath(_items);
    final currentPath = miuixJoinBreadcrumbPath(
      _items.sublist(0, _highlightIndex + 1),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '面包屑导航栏',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MiuixBreadcrumbBar(
            key: const ValueKey('reference-breadcrumb-standalone'),
            items: _items,
            onItemClick: _select,
            highlightIndex: _highlightIndex,
          ),
        ),
        MiuixCard(
          key: const ValueKey('reference-breadcrumb-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiuixBreadcrumbBar(
                items: _items,
                onItemClick: _select,
                highlightIndex: _highlightIndex,
              ),
              const SizedBox(height: 12),
              Text('完整路径：$fullPath', style: TextStyle(color: summaryColor)),
              const SizedBox(height: 12),
              Text('当前位置：$currentPath', style: TextStyle(color: summaryColor)),
              const SizedBox(height: 12),
              MiuixBreadcrumbBar(
                items: _items,
                onItemClick: (_) {},
                enabled: false,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Navigation entries shown at the end of the source home page.
class _ReferenceOtherSection extends StatelessWidget {
  const _ReferenceOtherSection({
    required this.showTopBar,
    required this.enableBlur,
    required this.enableScrollEndHaptic,
  });

  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  Widget build(BuildContext context) {
    void open(Widget page) {
      Navigator.of(context).push(
        _ReferenceMaterialPageRoute<void>(
          context: context,
          builder: (_) => page,
        ),
      );
    }

    return MiuixSettingsGroup(
      title: '其他',
      children: [
        MiuixArrowPreference(
          title: 'flutter_miuix 扩展控件',
          summary: '自适应布局、日期日程、树与表格、文件拖放和命令面板',
          onTap: () => open(
            _ReferenceExtensionComponentsPage(
              showTopBar: showTopBar,
              enableBlur: enableBlur,
            ),
          ),
        ),
        MiuixArrowPreference(
          title: '下拉刷新测试',
          summary: '前往下拉刷新页面',
          onTap: () => open(
            _ReferencePullToRefreshPage(
              enableScrollEndHaptic: enableScrollEndHaptic,
            ),
          ),
        ),
        MiuixArrowPreference(
          title: '导航测试',
          summary: '前往导航页面',
          onTap: () => Navigator.of(context).push<void>(
            _referenceNavigationPageRoute(
              context: context,
              index: 1,
              showTopBar: showTopBar,
              enableBlur: enableBlur,
              enableScrollEndHaptic: enableScrollEndHaptic,
            ),
          ),
        ),
        MiuixArrowPreference(
          title: '多脚手架测试',
          summary: '前往多脚手架页面',
          onTap: () => open(
            _ReferenceMultiScaffoldPage(
              showTopBar: showTopBar,
              enableBlur: enableBlur,
              enableScrollEndHaptic: enableScrollEndHaptic,
            ),
          ),
        ),
        MiuixArrowPreference(
          title: '嵌套导航测试',
          summary: '在一个页面条目中嵌套导航显示',
          onTap: () => open(
            _ReferenceNestedNavigationPage(
              showTopBar: showTopBar,
              enableBlur: enableBlur,
              enableScrollEndHaptic: enableScrollEndHaptic,
            ),
          ),
        ),
        MiuixArrowPreference(
          title: '过度滚动与加载更多测试',
          summary: '快速滑到底部，然后再次快速滑动',
          onTap: () => open(
            _ReferenceOverscrollLoadMorePage(
              showTopBar: showTopBar,
              enableBlur: enableBlur,
            ),
          ),
        ),
      ],
    );
  }
}
