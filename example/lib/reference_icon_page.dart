part of 'main.dart';

/// Chinese reconstruction of the source icon catalogue and search pager.
class _MiuixReferenceIconPage extends StatefulWidget {
  const _MiuixReferenceIconPage({
    required this.wide,
    required this.bottomContentInset,
    required this.showTopBar,
    required this.enableBlur,
  });

  final bool wide;
  final double bottomContentInset;
  final bool showTopBar;
  final bool enableBlur;

  @override
  State<_MiuixReferenceIconPage> createState() =>
      _MiuixReferenceIconPageState();
}

class _MiuixReferenceIconPageState extends State<_MiuixReferenceIconPage>
    with SingleTickerProviderStateMixin {
  static const _searchMoveDuration = Duration(milliseconds: 300);
  static const _linearOutSlowIn = Cubic(0, 0, .2, 1);
  static const _fastOutSlowIn = Cubic(.4, 0, .2, 1);

  final TextEditingController _fakeSearchController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();
  final GlobalKey _fakeSearchKey = GlobalKey();
  late final AnimationController _searchMoveController;
  bool _searchExpanded = false;
  bool _searchOverlayRetained = false;
  bool _searchResultsVisible = false;
  double _searchStartTop = 0;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _searchMoveController = AnimationController(
      vsync: this,
      duration: _searchMoveDuration,
    )..addStatusListener(_handleSearchMoveStatus);
  }

  @override
  void dispose() {
    _fakeSearchController.dispose();
    _searchController.dispose();
    _tableScrollController.dispose();
    _searchMoveController
      ..removeStatusListener(_handleSearchMoveStatus)
      ..dispose();
    super.dispose();
  }

  void _handleSearchMoveStatus(AnimationStatus status) {
    if (!mounted) {
      return;
    }
    if (status == AnimationStatus.completed && _searchExpanded) {
      setState(() => _searchResultsVisible = true);
    } else if (status == AnimationStatus.dismissed && !_searchExpanded) {
      setState(() => _searchOverlayRetained = false);
    }
  }

  void _openSearch() {
    if (!_searchExpanded) {
      final renderObject = _fakeSearchKey.currentContext?.findRenderObject();
      if (renderObject is RenderBox && renderObject.hasSize) {
        _searchStartTop = renderObject.localToGlobal(Offset.zero).dy;
      }
      setState(() {
        _searchExpanded = true;
        _searchOverlayRetained = true;
        _searchResultsVisible = false;
      });
      _searchMoveController.forward(from: 0);
    }
  }

  void _closeSearch() {
    _searchController.clear();
    if (_searchExpanded) {
      setState(() {
        _searchExpanded = false;
        _searchResultsVisible = false;
      });
      _searchMoveController.reverse();
    }
  }

  void _selectResult(MiuixExtendedIconData icon) {
    final index = MiuixExtendedIconCatalog.all.indexOf(icon);
    _closeSearch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_tableScrollController.hasClients) {
        return;
      }
      _tableScrollController.animateTo(
        (index * 36.0).clamp(
          0,
          _tableScrollController.position.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchFake = widget.showTopBar && !_searchExpanded
        ? GestureDetector(
            key: const ValueKey('icon-search-fake'),
            behavior: HitTestBehavior.opaque,
            onTap: _openSearch,
            child: IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: MiuixSearchBar(
                  key: _fakeSearchKey,
                  controller: _fakeSearchController,
                  hint: '搜索图标',
                ),
              ),
            ),
          )
        : null;
    return _ReferencePageScaffold(
      title: '图标',
      wide: widget.wide,
      showTopBar: widget.showTopBar && !_searchExpanded,
      enableBlur: widget.enableBlur,
      bottomContent: searchFake,
      bottomContentHeight: searchFake == null ? 0 : 51,
      bottomContentExpandedTopPadding: searchFake == null ? 0 : 12,
      bodyBuilder: (context, topContentInset) => Stack(
        children: [
          ExcludeSemantics(
            key: const ValueKey('icon-table-search-exclusion'),
            excluding: _searchExpanded,
            child: IgnorePointer(
              key: const ValueKey('icon-table-search-pointer-block'),
              ignoring: _searchExpanded,
              // SearchPager.kt owns the full opaque popup layer while
              // expanded. Keep the lazy table mounted so selecting a result
              // can restore and animate its scroll position, but do not let
              // TalkBack or pointer input reach content hidden behind it.
              child: _buildIconTable(context, topContentInset),
            ),
          ),
          // SearchPager remains mounted while collapsed, just as popupHost
          // does in Compose. This lets Cancel/results observe false-to-true
          // visibility changes instead of appearing already settled.
          _buildSearchPager(context),
        ],
      ),
    );
  }

  Widget _buildIconTable(BuildContext context, double topContentInset) {
    const icons = MiuixExtendedIconCatalog.all;
    final sourceTopSpacing = _referenceRoundedDp(context, 6);
    final sourceBottomSpacing = _referenceRoundedDp(context, 12);
    final contentPadding = EdgeInsets.only(
      top: topContentInset + sourceTopSpacing,
      bottom: widget.bottomContentInset + sourceBottomSpacing,
    );
    return MiuixVerticalScrollBar(
      key: const ValueKey('reference-icon-scrollbar'),
      controller: _tableScrollController,
      trackPadding: contentPadding,
      child: ListView.builder(
        key: const PageStorageKey('miuix-reference-icons'),
        controller: _tableScrollController,
        padding: contentPadding,
        itemCount: icons.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return const _MiuixIconTableHeader();
          }
          final iconIndex = index - 1;
          return _MiuixIconTableRow(
            key: ValueKey('icon-row-$iconIndex'),
            icon: icons[iconIndex],
            last: iconIndex == icons.length - 1,
            expanded: _expandedIndex == iconIndex,
            onTap: () => setState(() {
              _expandedIndex = _expandedIndex == iconIndex ? -1 : iconIndex;
            }),
          );
        },
      ),
    );
  }

  Widget _buildSearchPager(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final query = _searchController.text.trim().toLowerCase();
    final results = query.isEmpty
        ? const <MiuixExtendedIconData>[]
        : MiuixExtendedIconCatalog.all
              .where((icon) => icon.name.toLowerCase().contains(query))
              .toList(growable: false);
    return AnimatedBuilder(
      animation: _searchMoveController,
      builder: (context, _) {
        final progress = _searchMoveController.value;
        final moveProgress = _linearOutSlowIn.transform(progress);
        final surfaceProgress = _fastOutSlowIn.transform(
          (progress * 1.5).clamp(0.0, 1.0),
        );
        final finalTop = MediaQuery.paddingOf(context).top + 24;
        final startTop = _searchStartTop == 0 ? finalTop : _searchStartTop;
        final searchTop = ui.lerpDouble(startTop, finalTop, moveProgress)!;
        return Offstage(
          offstage: !_searchOverlayRetained,
          child: ExcludeSemantics(
            excluding: !_searchOverlayRetained,
            child: IgnorePointer(
              ignoring: !_searchOverlayRetained,
              child: ColoredBox(
                key: const ValueKey('icon-search-pager'),
                color: scheme.surface.withValues(alpha: surfaceProgress),
                child: Column(
                  children: [
                    Opacity(
                      opacity: _searchOverlayRetained ? 1 : 0,
                      child: Padding(
                        // The moving field begins exactly over SearchBarFake.
                        // It settles at systemBars + 12dp from SearchPager and
                        // another 12dp from SearchBar, matching the source.
                        padding: EdgeInsets.only(top: searchTop, bottom: 6),
                        child: MiuixSearchBar(
                          controller: _searchController,
                          hint: '搜索图标',
                          expanded: _searchExpanded,
                          onExpandedChanged: (value) {
                            if (!value) {
                              _closeSearch();
                            }
                          },
                          onChanged: (_) => setState(() {}),
                          outsideEndAction: Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 4,
                              end: 16,
                            ),
                            // Preserve the source English paragraph width after
                            // translating the visible label into Chinese.
                            child: SizedBox(
                              key: const ValueKey('icon-search-cancel'),
                              width: 52.5,
                              height: 45,
                              child: _IconCancelSemanticsTarget(
                                key: const ValueKey(
                                  'icon-search-cancel-semantics',
                                ),
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _closeSearch,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Align(
                                      alignment:
                                          AlignmentDirectional.centerStart,
                                      child: Text(
                                        '取消',
                                        style: TextStyle(
                                          color: scheme.primary,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: AnimatedOpacity(
                        key: const ValueKey('icon-search-results-opacity'),
                        opacity: _searchResultsVisible ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: _fastOutSlowIn,
                        child: ExcludeSemantics(
                          excluding: !_searchResultsVisible,
                          child: IgnorePointer(
                            ignoring: !_searchResultsVisible,
                            child: ListView.builder(
                              key: const ValueKey('icon-search-results'),
                              padding: EdgeInsets.only(
                                bottom: widget.bottomContentInset,
                              ),
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final icon = results[index];
                                return MiuixCard(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  padding: EdgeInsets.zero,
                                  child: MiuixBasicComponent(
                                    title: icon.name,
                                    standalone: false,
                                    leading: Icon(icon.regular, size: 24),
                                    onTap: () => _selectResult(icon),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Gives the localized Cancel action the source 48dp accessibility target.
///
/// The visible row remains 45dp tall, exactly like the InputField capsule.
/// Compose exposes a 48dp semantic node without increasing that layout height,
/// so this render proxy expands semantics only. A quarter-dp logical-start
/// inset reproduces the Android paragraph's final one-pixel horizontal round.
class _IconCancelSemanticsTarget extends SingleChildRenderObjectWidget {
  const _IconCancelSemanticsTarget({super.key, required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderIconCancelSemanticsTarget();
  }
}

/// Render-side boundary that changes accessibility geometry, never layout.
class _RenderIconCancelSemanticsTarget extends RenderProxyBox {
  @override
  Rect get semanticBounds {
    const extra = (48 - 45) / 2;
    return Rect.fromLTRB(.25, -extra, size.width, size.height + extra);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

/// Current source header keeps only the name and comparison affordance visible.
class _MiuixIconTableHeader extends StatelessWidget {
  const _MiuixIconTableHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outerPadding = _referenceRoundedDp(context, 12);
    final innerPadding = _referenceRoundedDp(context, 16);
    final topPadding = _referenceRoundedDp(context, 12);
    final bottomPadding = _referenceRoundedDp(context, 8);
    // Compose's 13 sp header line rounds one physical pixel taller than the
    // equivalent Flutter paragraph on the 420 dpi reference device.
    final physicalPixel = 1 / MediaQuery.devicePixelRatioOf(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPadding),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ColoredBox(
          color: scheme.surfaceContainer,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              innerPadding,
              topPadding,
              innerPadding,
              bottomPadding + physicalPixel,
            ),
            child: Row(
              children: [
                Expanded(child: _headerText(context, '名称')),
                _headerText(context, '点击比较字重', small: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerText(BuildContext context, String text, {bool small = false}) {
    return Text(
      text,
      style: TextStyle(
        color: MiuixSemanticColors.of(context)['onSurfaceVariantActions'],
        fontSize: small ? 11 : 13,
      ),
    );
  }
}

/// One current source accordion row with five optical weights when expanded.
class _MiuixIconTableRow extends StatelessWidget {
  const _MiuixIconTableRow({
    super.key,
    required this.icon,
    required this.last,
    required this.expanded,
    required this.onTap,
  });

  final MiuixExtendedIconData icon;
  final bool last;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final outerPadding = _referenceRoundedDp(context, 12);
    final innerPadding = _referenceRoundedDp(context, 16);
    final rowPadding = _referenceRoundedDp(context, 6);
    final row = ColoredBox(
      color: scheme.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            innerPadding,
            rowPadding,
            innerPadding,
            rowPadding + (last ? rowPadding : 0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      icon.name,
                      style: TextStyle(color: scheme.onSurface, fontSize: 14),
                    ),
                  ),
                  Icon(
                    icon.regular,
                    size: 24,
                    color: MiuixSemanticColors.of(context)['onBackground'],
                  ),
                  SizedBox(width: _referenceRoundedDp(context, 8)),
                  Icon(
                    MiuixExtendedIconCatalog.find(
                      expanded ? 'ExpandLess' : 'ExpandMore',
                    )!.regular,
                    size: 18,
                    color: MiuixSemanticColors.of(
                      context,
                    )['onSurfaceVariantActions'],
                  ),
                ],
              ),
              _ReferenceAnimatedVisibility(
                visible: expanded,
                verticalOnly: true,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: _referenceRoundedDp(context, 10),
                    bottom: _referenceRoundedDp(context, 4),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _weight(context, '细体', icon.light),
                      _weight(context, '标准', icon.normal),
                      _weight(context, '常规', icon.regular),
                      _weight(context, '中等', icon.medium),
                      _weight(context, '半粗', icon.demibold),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: outerPadding),
      child: last
          ? ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              child: row,
            )
          : row,
    );
  }

  Widget _weight(BuildContext context, String label, IconData data) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            data,
            size: 28,
            color: MiuixSemanticColors.of(context)['onBackground'],
          ),
          SizedBox(height: _referenceRoundedDp(context, 4)),
          Text(
            label,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: MiuixSemanticColors.of(context)['onSurfaceVariantActions'],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
