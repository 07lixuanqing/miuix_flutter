part of 'main.dart';

/// Pull-to-refresh page with alternating overlay and window dropdown rows.
class _ReferencePullToRefreshPage extends StatefulWidget {
  const _ReferencePullToRefreshPage({this.enableScrollEndHaptic = true});

  final bool enableScrollEndHaptic;

  @override
  State<_ReferencePullToRefreshPage> createState() =>
      _ReferencePullToRefreshPageState();
}

class _ReferencePullToRefreshPageState
    extends State<_ReferencePullToRefreshPage> {
  int _rowCount = 6;
  int _selected = 0;
  bool _isRefreshing = false;
  bool _settingsVisible = false;
  double _thresholdValue = .25;
  double _currentPullProgress = 0;
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;

  @override
  void initState() {
    super.initState();
    _scrollBehavior = MiuixTopAppBarScrollBehavior()
      ..addListener(_handleTopBarChanged);
  }

  void _handleTopBarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollBehavior
      ..removeListener(_handleTopBarChanged)
      ..dispose();
    super.dispose();
  }

  /// Starts the source page's hoisted refresh state from gesture or toolbar.
  void _requestRefresh() {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    unawaited(_completeRefresh());
  }

  /// Appends the same six-row source batch after its 100 ms loading pulse.
  Future<void> _completeRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        _rowCount += 6;
        _isRefreshing = false;
      });
    }
  }

  /// Opens the original threshold editor as a window-style bottom sheet.
  void _showSettings(BuildContext context) {
    if (_settingsVisible) {
      return;
    }
    final controller = MiuixBottomSheetController();
    setState(() => _settingsVisible = true);
    final future = MiuixWindowBottomSheet.show<void>(
      context: context,
      controller: controller,
      title: '下拉刷新设置',
      onDismissFinished: () {
        if (mounted) {
          setState(() => _settingsVisible = false);
        }
      },
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final semantic = MiuixSemanticColors.of(sheetContext);
          final percent = (_thresholdValue * 100).toInt();
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MiuixCard(
                key: const ValueKey('pull-refresh-settings-card'),
                padding: EdgeInsets.zero,
                color: semantic['secondaryContainer'],
                child: MiuixSliderPreference.source(
                  key: const ValueKey('pull-refresh-threshold-slider'),
                  title: '刷新阈值',
                  summary: _thresholdValue == 0
                      ? '任意下拉即可触发刷新。'
                      : '下拉拖动范围的 $percent% 即可刷新。',
                  value: _thresholdValue,
                  onValueChange: (value) {
                    setState(() => _thresholdValue = value);
                    setSheetState(() {});
                  },
                  min: 0,
                  max: 1,
                  steps: 99,
                  showKeyPoints: true,
                  keyPoints: const [0, .25, .5, .75, 1],
                ),
              ),
              SizedBox(
                height: MediaQuery.viewPaddingOf(sheetContext).bottom + 12,
              ),
            ],
          );
        },
      ),
    );
    unawaited(future.whenComplete(controller.dispose));
  }

  /// Applies 16dp corners only to the outer edges of the source row group.
  BorderRadius _rowCorners(int index) {
    const corner = Radius.circular(16);
    return BorderRadius.only(
      topLeft: index == 0 ? corner : Radius.zero,
      topRight: index == 0 ? corner : Radius.zero,
      bottomLeft: index == _rowCount - 1 ? corner : Radius.zero,
      bottomRight: index == _rowCount - 1 ? corner : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    const items = ['选项一', '选项二', '选项三', '选项四'];
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final topContentInset = _referenceTopContentInset(
      context,
      showTopBar: true,
      wide: wide,
      scrollBehavior: wide ? null : _scrollBehavior,
    );
    final sourcePageMargin = _referenceRoundedDp(context, 12);
    final semantic = MiuixSemanticColors.of(context);
    final density = MediaQuery.devicePixelRatioOf(context);
    // The authoritative 420dpi source places body1/body2 into 49px and 43px
    // boxes. Preserve those Compose line boxes when localized CJK fallback
    // metrics would otherwise make this card eight physical pixels taller.
    final progressLineHeight = 49 / density;
    final thresholdLineHeight = 43 / density;
    final progressStyle = MiuixTheme.of(
      context,
    ).textTheme.bodyMedium!.copyWith(color: semantic['onSurface'], height: 1);
    final thresholdStyle = MiuixTheme.of(context).textTheme.bodySmall!.copyWith(
      color: semantic['onSurfaceVariantSummary'],
      height: 1,
    );
    final progressPercent = (_currentPullProgress * 100).toInt();
    final thresholdPercent = (_thresholdValue * 100).toInt();
    return MiuixScaffold(
      topBar: MiuixTopAppBar(
        title: '弹出菜单',
        large: !wide,
        scrollBehavior: wide ? null : _scrollBehavior,
        defaultWindowInsetsPadding: !wide,
        leading: MiuixIconButton(
          icon: Icon(
            _miuixIcon('Back'),
            color: MiuixSemanticColors.of(context)['onBackground'],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          MiuixIconButton(
            key: const ValueKey('pull-refresh-toolbar-action'),
            icon: Icon(
              _miuixIcon('Refresh'),
              color: MiuixSemanticColors.of(context)['onBackground'],
            ),
            onPressed: _requestRefresh,
          ),
        ],
      ),
      body: MiuixScrollEndHaptic(
        enabled: widget.enableScrollEndHaptic,
        child: MiuixPullToRefresh(
          state: null,
          isRefreshing: _isRefreshing,
          onRefresh: _requestRefresh,
          refreshThreshold: _thresholdValue,
          onPullProgress: (progress) {
            if (mounted && _currentPullProgress != progress) {
              setState(() => _currentPullProgress = progress);
            }
          },
          contentPadding: EdgeInsets.only(
            top: topContentInset + sourcePageMargin,
          ),
          refreshTexts: const ['下拉刷新', '松开刷新', '正在刷新…', '刷新成功'],
          child: ListView.builder(
            key: const ValueKey('pull-refresh-list'),
            padding: EdgeInsets.fromLTRB(
              0,
              topContentInset + sourcePageMargin,
              0,
              MediaQuery.paddingOf(context).bottom + sourcePageMargin,
            ),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: _rowCount + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return MiuixCard(
                  key: const ValueKey('pull-refresh-progress-card'),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  insideMargin: const EdgeInsets.all(16),
                  cornerRadius: 12,
                  color: semantic['surfaceContainer'],
                  feedbackType: MiuixPressFeedbackType.sink,
                  showIndication: true,
                  onTap: () => _showSettings(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: progressLineHeight,
                        child: Text(
                          '下拉进度：$progressPercent%',
                          maxLines: 1,
                          style: progressStyle,
                          strutStyle: StrutStyle(
                            fontSize: progressStyle.fontSize,
                            height:
                                progressLineHeight / progressStyle.fontSize!,
                            forceStrutHeight: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: thresholdLineHeight,
                        child: Text(
                          '刷新阈值：$thresholdPercent%',
                          maxLines: 1,
                          style: thresholdStyle,
                          strutStyle: StrutStyle(
                            fontSize: thresholdStyle.fontSize,
                            height:
                                thresholdLineHeight / thresholdStyle.fontSize!,
                            forceStrutHeight: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }
              final rowIndex = index - 1;
              final title = rowIndex.isEven
                  ? '叠加层下拉偏好 ${rowIndex + 1}'
                  : '窗口下拉偏好 ${rowIndex + 1}';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  key: ValueKey('pull-refresh-row-${rowIndex + 1}'),
                  color: semantic['surfaceContainer'],
                  shape: MiuixSquircleBorder(
                    borderRadius: _rowCorners(rowIndex),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: rowIndex.isEven
                      ? MiuixOverlayDropdownPreference.source(
                          title: title,
                          selectedIndex: _selected,
                          items: items,
                          onSelectedIndexChange: (selectedIndex) =>
                              setState(() => _selected = selectedIndex),
                        )
                      : MiuixWindowDropdownPreference.source(
                          title: title,
                          selectedIndex: _selected,
                          items: items,
                          onSelectedIndexChange: (selectedIndex) =>
                              setState(() => _selected = selectedIndex),
                        ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
