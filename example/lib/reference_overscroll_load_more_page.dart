part of 'main.dart';

/// Localized port of the current upstream `OverscrollLoadMorePage`.
///
/// Reaching the last three rows starts an 800 ms load while MIUIX's ordinary
/// overscroll bounce remains active. Twenty rows are appended per load.
class _ReferenceOverscrollLoadMorePage extends StatefulWidget {
  const _ReferenceOverscrollLoadMorePage({
    this.showTopBar = true,
    this.enableBlur = false,
  });

  final bool showTopBar;
  final bool enableBlur;

  @override
  State<_ReferenceOverscrollLoadMorePage> createState() =>
      _ReferenceOverscrollLoadMorePageState();
}

class _ReferenceOverscrollLoadMorePageState
    extends State<_ReferenceOverscrollLoadMorePage> {
  final ScrollController _scrollController = ScrollController();
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;
  int _itemCount = 30;
  int _loadedPages = 0;
  bool _loadingMore = false;
  bool _wasNearEnd = false;
  bool _resamplingAfterAppend = false;
  bool _loadArmedForScrollSession = true;

  @override
  void initState() {
    super.initState();
    _scrollBehavior = MiuixTopAppBarScrollBehavior();
    _scrollBehavior.addListener(_handleTopBarChanged);
    _scrollController.addListener(_loadWhenNearEnd);
  }

  void _handleTopBarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadWhenNearEnd)
      ..dispose();
    _scrollBehavior
      ..removeListener(_handleTopBarChanged)
      ..dispose();
    super.dispose();
  }

  void _loadWhenNearEnd() {
    if (!_scrollController.hasClients ||
        _loadingMore ||
        _resamplingAfterAppend) {
      return;
    }
    final position = _scrollController.position;
    final nearEnd = _isNearEnd(position);
    if (nearEnd == _wasNearEnd) {
      return;
    }
    _wasNearEnd = nearEnd;
    if (nearEnd && _loadArmedForScrollSession) {
      // snapshotFlow can observe the appended total while the old ballistic
      // activity is still moving. The source example nevertheless loads one
      // page per fling: its instruction explicitly asks for another fling.
      // Consume this scroll session before starting the delayed append so a
      // later near-end transition from the same inertia cannot enqueue again.
      _loadArmedForScrollSession = false;
      setState(() => _loadingMore = true);
      unawaited(_finishLoading());
    }
  }

  bool _handleScrollStart(ScrollStartNotification notification) {
    if (notification.depth == 0 &&
        notification.dragDetails != null &&
        !_loadingMore) {
      // Only a fresh pointer drag is the source's "fling again" boundary.
      // Flutter also sends ScrollStartNotification when an existing ballistic
      // activity is recreated after layout; accepting that engine event would
      // let one physical fling append a second page. Re-arm only: the source's
      // distinctUntilChanged retains the actual current near-end bit, so a
      // drag starting at the bottom cannot load before leaving the threshold.
      _loadArmedForScrollSession = true;
    }
    return false;
  }

  bool _isNearEnd(ScrollPosition position) {
    final density = MediaQuery.devicePixelRatioOf(context);
    // Compose observes `lastVisible >= totalItemsCount - 3`, not an arbitrary
    // 144dp distance. Every source row is one independently rounded 49px
    // body1 line plus two independently rounded 14dp insets. Include the
    // authored 12dp final content padding because it is not a LazyColumn item
    // and therefore does not participate in the source index predicate.
    final bodyLine = (49 / 2.625 * density).round() / density;
    final rowInset = (14 * density).round() / density;
    final bottomInset = (12 * density).round() / density;
    final nearEndExtent = 3 * (bodyLine + 2 * rowInset) + bottomInset;
    return position.extentAfter < nearEndExtent;
  }

  Future<void> _finishLoading() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }
    setState(() {
      _itemCount += 20;
      _loadedPages++;
      _loadingMore = false;
      _resamplingAfterAppend = true;
    });
    // Compose's snapshotFlow is invalidated only after LazyListLayoutInfo has
    // incorporated the appended rows. Re-sample after Flutter's matching
    // layout frame too: resetting inside setState can briefly observe the old
    // max extent and recursively enqueue another page without a new fling.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // The source flow emits false as soon as totalItemsCount expands,
        // even if the old fling reaches the new bottom in the same frame.
        // Ignore old-extent notifications until this point, then allow the
        // next ballistic tick or user fling to produce a fresh true edge.
        _wasNearEnd = false;
        _resamplingAfterAppend = false;
      }
    });
  }

  BorderRadius _rowCorners(int index) {
    const corner = Radius.circular(16);
    return BorderRadius.only(
      topLeft: index == 0 ? corner : Radius.zero,
      topRight: index == 0 ? corner : Radius.zero,
      bottomLeft: index == _itemCount - 1 && !_loadingMore
          ? corner
          : Radius.zero,
      bottomRight: index == _itemCount - 1 && !_loadingMore
          ? corner
          : Radius.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final topContentInset = _referenceTopContentInset(
      context,
      showTopBar: widget.showTopBar,
      wide: wide,
      scrollBehavior: wide ? null : _scrollBehavior,
    );
    final semantic = MiuixSemanticColors.of(context);
    final textTheme = MiuixTheme.of(context).textTheme;
    final density = MediaQuery.devicePixelRatioOf(context);
    // Android's current body1/body2 placeables are 49px and 43px at the
    // authoritative 420dpi density. Force those line boxes so CJK fallback
    // metrics cannot make translated rows three pixels taller than Compose.
    final body1LineHeight = (49 / 2.625 * density).round() / density;
    final body2LineHeight = (43 / 2.625 * density).round() / density;
    final rowInset = (14 * density).round() / density;
    final body1Style = textTheme.bodyMedium!.copyWith(
      height: body1LineHeight / 16,
    );
    final body2Style = textTheme.bodySmall!.copyWith(
      height: body2LineHeight / 14,
    );
    final body1Strut = StrutStyle.fromTextStyle(
      body1Style,
      forceStrutHeight: true,
    );
    final body2Strut = StrutStyle.fromTextStyle(
      body2Style,
      forceStrutHeight: true,
    );

    return MiuixScaffold(
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: '过度滚动与加载更多',
              large: !wide,
              defaultWindowInsetsPadding: !wide,
              scrollBehavior: wide ? null : _scrollBehavior,
              glass: widget.enableBlur,
              leading: MiuixIconButton(
                icon: Icon(
                  _miuixIcon('Back'),
                  color: MiuixSemanticColors.of(context)['onBackground'],
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: MiuixOverscrollEffect(
        child: NotificationListener<ScrollStartNotification>(
          onNotification: _handleScrollStart,
          child: ListView.builder(
            key: const PageStorageKey('miuix-reference-overscroll-load-more'),
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(0, topContentInset + 12, 0, 12),
            itemCount: _itemCount + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return MiuixCard(
                  key: const ValueKey('overscroll-load-more-hint'),
                  // At Android's 420dpi reference density the independently
                  // rasterized lower 8dp gap occupies 20px (the upper gap is
                  // 21px). Preserve that asymmetric pixel coverage so the first
                  // row begins at native y=660 rather than y=661.
                  margin: EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    ((8 * density).round() - 1) / density,
                  ),
                  padding: const EdgeInsets.all(16),
                  cornerRadius: 16,
                  color: semantic['surfaceContainer'],
                  child: Column(
                    // Compose's Column leaves short children at intrinsic width.
                    // The wrapped instruction still occupies the available
                    // width, while the one-line status does not expose a
                    // full-card semantics rectangle.
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: body2LineHeight * 3,
                        child: Text(
                          '快速滑到底部：新项目会在回弹动画仍在播放时加载。'
                          '加载完成后请再次快速滑动——即使列表刚刚追加了项目，'
                          '惯性滚动也必须继续正常工作。',
                          maxLines: 3,
                          style: body2Style.copyWith(
                            color: semantic['onSurface'],
                          ),
                          strutStyle: body2Strut,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: body2LineHeight,
                        child: Text(
                          '项目：$_itemCount · 已加载页数：$_loadedPages',
                          key: const ValueKey('overscroll-load-more-status'),
                          maxLines: 1,
                          style: body2Style.copyWith(
                            color: semantic['onSurfaceVariantSummary'],
                          ),
                          strutStyle: body2Strut,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (index == _itemCount + 1) {
                return _loadingMore
                    ? _ReferenceLoadMoreFooter(
                        color: semantic['surfaceContainer'],
                        textColor: semantic['onSurfaceVariantSummary'],
                        textStyle: body2Style,
                        textStrutStyle: body2Strut,
                        verticalInset: rowInset,
                      )
                    : const SizedBox.shrink();
              }
              final itemIndex = index - 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Material(
                  key: ValueKey('overscroll-load-more-item-${itemIndex + 1}'),
                  color: semantic['surfaceContainer'],
                  shape: MiuixSquircleBorder(
                    borderRadius: _rowCorners(itemIndex),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: rowInset,
                    ),
                    child: SizedBox(
                      height: body1LineHeight,
                      child: Text(
                        '项目 ${itemIndex + 1}',
                        maxLines: 1,
                        style: body1Style.copyWith(
                          color: semantic['onSurface'],
                        ),
                        strutStyle: body1Strut,
                      ),
                    ),
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

class _ReferenceLoadMoreFooter extends StatelessWidget {
  const _ReferenceLoadMoreFooter({
    required this.color,
    required this.textColor,
    required this.textStyle,
    required this.textStrutStyle,
    required this.verticalInset,
  });

  final Color color;
  final Color textColor;
  final TextStyle textStyle;
  final StrutStyle textStrutStyle;
  final double verticalInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: color,
        shape: const MiuixSquircleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: verticalInset),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MiuixInfiniteProgressIndicator(size: 20),
              const SizedBox(width: 8),
              Text(
                '正在加载更多…',
                style: textStyle.copyWith(color: textColor),
                strutStyle: textStrutStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
