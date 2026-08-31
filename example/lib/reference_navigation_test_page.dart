part of 'main.dart';

// The current upstream fixture is deliberately separate from the ordinary
// component chapters. Consecutive pushes exercise NavDisplay's shared
// animatedTop spring, while the final card stresses BasicComponent's 2:5:3
// intrinsic-width allocation with the same seven source cases.

const _referenceNavigationRouteName = '/reference/navigation-test';

// Flutter's Navigator does not expose its current route list. Keep only the
// live navigation-test routes so the source's atomic multi-pop can remove
// every hidden intermediate entry before animating the visible page once.
final List<Route<void>> _referenceNavigationRoutes = <Route<void>>[];

/// Creates one route that can be distinguished from its non-navigation entry.
///
/// `NavTestPage.kt` pops only the consecutive `Route.Navigation` entries. A
/// named route gives Flutter the same boundary, including when a navigation
/// test page was opened from the nested-navigation fixture instead of Home.
Route<void> _referenceNavigationPageRoute({
  required BuildContext context,
  required int index,
  required bool showTopBar,
  required bool enableBlur,
  required bool enableScrollEndHaptic,
}) {
  late final Route<void> route;
  route = _ReferenceMaterialPageRoute<void>(
    context: context,
    settings: const RouteSettings(name: _referenceNavigationRouteName),
    builder: (_) => _ReferenceNavigationTestPage(
      index: index,
      showTopBar: showTopBar,
      enableBlur: enableBlur,
      enableScrollEndHaptic: enableScrollEndHaptic,
    ),
  );
  _referenceNavigationRoutes.add(route);
  // Both an ordinary Back pop and the atomic removal path complete `popped`.
  // Removing here prevents a later fixture session from seeing stale routes.
  route.popped.whenComplete(() => _referenceNavigationRoutes.remove(route));
  return route;
}

/// Localized port of the current MIUIX `NavTestPage` fixture.
class _ReferenceNavigationTestPage extends StatefulWidget {
  const _ReferenceNavigationTestPage({
    required this.index,
    this.showTopBar = true,
    this.enableBlur = false,
    this.enableScrollEndHaptic = true,
  });

  final int index;
  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_ReferenceNavigationTestPage> createState() =>
      _ReferenceNavigationTestPageState();
}

class _ReferenceNavigationTestPageState
    extends State<_ReferenceNavigationTestPage> {
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;
  late final ScrollController _scrollController;
  bool _atomicPopActive = false;
  late int _displayIndex;

  @override
  void initState() {
    super.initState();
    _displayIndex = widget.index;
    _scrollBehavior = MiuixTopAppBarScrollBehavior();
    _scrollBehavior.addListener(_handleTopBarChanged);
    _scrollController = ScrollController();
  }

  void _handleTopBarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollBehavior
      ..removeListener(_handleTopBarChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pushes one or three consecutive navigation routes without awaiting.
  ///
  /// The upstream navigator mutates its back stack three times in one callback
  /// so all new entries share NavDisplay's animatedTop spring. Calling
  /// Navigator.push synchronously preserves that stack mutation pattern; the
  /// route builder derives the displayed index from the current page depth.
  void _pushPages(int count) {
    final navigator = Navigator.of(context);
    for (var offset = 1; offset <= count; offset++) {
      navigator.push<void>(
        _referenceNavigationPageRoute(
          context: context,
          index: widget.index + offset,
          showTopBar: widget.showTopBar,
          enableBlur: widget.enableBlur,
          enableScrollEndHaptic: widget.enableScrollEndHaptic,
        ),
      );
    }
  }

  /// Pops the consecutive navigation pages but preserves their entry route.
  void _popAllNavigationPages() {
    if (_atomicPopActive) {
      return;
    }
    final navigator = Navigator.of(context);
    final topRoute = ModalRoute.of(context);
    if (topRoute == null || !navigator.canPop()) {
      return;
    }
    // Flutter normally animates five Navigator.pop calls as five consecutive
    // 500ms routes. NavDisplay instead changes animatedTop from N to zero and
    // shares one spring across the complete multi-pop. Remove the hidden
    // intermediate navigation entries first, then animate only the visible top
    // route. Route objects are distinct, so all removals can be scheduled in
    // the same Navigator history flush instead of repeatedly targeting the
    // same not-yet-finalized route below the top entry.
    final intermediateRoutes = _referenceNavigationRoutes
        .where(
          (route) =>
              !identical(route, topRoute) &&
              identical(route.navigator, navigator),
        )
        .toList(growable: false);
    // Compose derives this title from the live back stack. `popUntil` removes
    // every Route.Navigation synchronously, so the still-visible outgoing
    // scene recomposes as index 0 before it slides away. Preserve that easily
    // missed source frame instead of leaving the former top index on screen.
    setState(() {
      _displayIndex = 0;
      _atomicPopActive = true;
    });
    for (final route in intermediateRoutes) {
      navigator.removeRoute(route);
    }
    // Route removals are finalized at the end of the current history flush.
    // Pop the still-visible top route on the following frame so Navigator marks
    // it as `popping` and wires both scenes into the normal 500ms transition.
    // Calling pop in the removal callback either serializes the old entries or
    // leaves the controller paused; calling it next frame yields one complete
    // retained-scene translation, dim, and corner-clip timeline.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (navigator.canPop()) {
        navigator.pop();
      }
    });
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
    final sourceSpacing = _composeRoundedDimension(context, 12);
    // Translation metric deltas were measured on the 420dpi reference device.
    // Store them as logical source units so a 1.0-DPR desktop does not turn a
    // 20px Android correction into an invalid 20dp negative bottom inset.
    const sourcePhysicalPixel = 1 / 2.625;
    return MiuixScaffold(
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: '导航测试 $_displayIndex',
              large: !wide,
              scrollBehavior: wide ? null : _scrollBehavior,
              defaultWindowInsetsPadding: !wide,
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
      body: MiuixScrollEndHaptic(
        enabled: widget.enableScrollEndHaptic,
        child: MiuixVerticalScrollBar(
          controller: _scrollController,
          trackPadding: EdgeInsets.only(
            top: topContentInset,
            bottom: sourceSpacing,
          ),
          child: ListView(
            key: const PageStorageKey('miuix-reference-navigation-test'),
            controller: _scrollController,
            padding: EdgeInsets.only(
              top: topContentInset,
              bottom: sourceSpacing,
            ),
            children: [
              const MiuixSmallTitle('连续层级'),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sourceSpacing,
                  0,
                  sourceSpacing,
                  sourceSpacing,
                ),
                child: MiuixCard(
                  key: const ValueKey('navigation-continuous-card'),
                  child: Column(
                    children: [
                      MiuixArrowPreference.source(
                        key: const ValueKey('navigation-push-one'),
                        title: '再推入一个导航页面',
                        summary: '单次推入（animatedTop N → N+1）',
                        onClick: () => _pushPages(1),
                      ),
                      MiuixArrowPreference.source(
                        key: const ValueKey('navigation-push-three'),
                        title: '一次推入三个页面',
                        summary: '连续多次推入（N → N+3，共享同一个弹簧）',
                        onClick: () => _pushPages(3),
                      ),
                      MiuixArrowPreference.source(
                        key: const ValueKey('navigation-pop-all'),
                        title: '弹出所有导航页面',
                        summary: '连续多次弹出，返回入口页面',
                        onClick: _popAllNavigationPages,
                      ),
                    ],
                  ),
                ),
              ),
              const MiuixSmallTitle('手势返回'),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  sourceSpacing,
                  0,
                  sourceSpacing,
                  sourceSpacing,
                ),
                child: const MiuixCard(
                  key: ValueKey('navigation-gesture-card'),
                  child: MiuixBasicComponent.sourceText(
                    title: '滑动返回',
                    summary:
                        '请先在设置中打开“启用滑动返回”，再在已推入的页面上滑动以将其弹出。'
                        '可以先用上面的连续推入叠放多个页面，再依次拖动返回；手势会驱动同一个 animatedTop 弹簧。',
                    // The localized CJK paragraph keeps the source four-line
                    // wrap but its final SkParagraph line box is three
                    // physical pixels shorter than Compose's Latin paragraph
                    // at 420dpi. Add only bottom slack so the title and every
                    // visible baseline stay on the already-matching rows.
                    insideMargin: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      16 + 3 * sourcePhysicalPixel,
                    ),
                  ),
                ),
              ),
              const MiuixSmallTitle('布局测试'),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: sourceSpacing),
                child: MiuixCard(
                  key: const ValueKey('navigation-layout-card'),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < _navigationLayoutCases.length;
                        index++
                      )
                        _buildLayoutCase(index, _navigationLayoutCases[index]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds one of the seven current upstream width-pressure combinations.
  Widget _buildLayoutCase(int index, _NavigationLayoutCase layoutCase) {
    const sourcePhysicalPixel = 1 / 2.625;
    // The translated long title, summary, and trailing text preserve the
    // source line counts. CJK fallback still contributes a small role-specific
    // final descent at 420dpi, so remove only bottom slack; the authored 16dp
    // top inset and every visible baseline remain unchanged.
    final bottomMetricCorrection = switch (index) {
      0 => 11 * sourcePhysicalPixel,
      1 => 20 * sourcePhysicalPixel,
      2 => 1 * sourcePhysicalPixel,
      3 => 1 * sourcePhysicalPixel,
      4 => -1 * sourcePhysicalPixel,
      5 => 11 * sourcePhysicalPixel,
      6 => -1 * sourcePhysicalPixel,
      _ => 0.0,
    };
    return MiuixArrowPreference.source(
      key: ValueKey('navigation-layout-$index'),
      title: layoutCase.title,
      summary: layoutCase.summary,
      insideMargin: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 - bottomMetricCorrection,
      ),
      startAction: layoutCase.leading == null
          ? null
          : Text(layoutCase.leading!),
      endActions: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < layoutCase.trailing.length; index++) ...[
            if (index > 0) const SizedBox(width: 8),
            Flexible(
              child: Text(layoutCase.trailing[index], textAlign: TextAlign.end),
            ),
          ],
        ],
      ),
      onClick: () {},
    );
  }
}

/// Immutable description of one BasicComponent stress case.
class _NavigationLayoutCase {
  const _NavigationLayoutCase({
    required this.title,
    required this.summary,
    required this.trailing,
    this.leading,
  });

  final String title;
  final String summary;
  final String? leading;
  final List<String> trailing;
}

// The order and occupied slots below match current NavigateTestPage.kt. CJK
// repetitions retain the source's width pressure while keeping every visible
// string localized instead of embedding the former English fixture text.
const _navigationLayoutCases = <_NavigationLayoutCase>[
  _NavigationLayoutCase(
    title: '很长很长很长很长很长很长很长很长很长的标题',
    summary: '摘要',
    leading: '开头',
    trailing: ['尾部1', '尾部2'],
  ),
  _NavigationLayoutCase(
    title: '标题',
    summary: '很长很长很长很长很长很长很长的摘要',
    leading: '开头',
    trailing: ['尾部1', '尾部2'],
  ),
  _NavigationLayoutCase(
    title: '标题',
    summary: '摘要',
    leading: '开头',
    trailing: ['很长很长很长很长很长很长的尾部'],
  ),
  _NavigationLayoutCase(
    title: '很长很长很长很长很长很长很长很长很长的标题',
    summary: '摘要',
    leading: '开头',
    trailing: ['很长很长很长很长很长很长的尾部'],
  ),
  _NavigationLayoutCase(
    title: '标题',
    summary: '很长很长很长很长很长很长很长的摘要',
    trailing: ['很长很长很长很长很长很长的尾部'],
  ),
  _NavigationLayoutCase(
    title: '很长很长很长很长很长很长很长很长很长的标题',
    summary: '摘要',
    trailing: ['很长很长很长很长很长很长的尾部'],
  ),
  _NavigationLayoutCase(
    title: '标题',
    summary: '很长很长很长很长很长很长很长的摘要',
    trailing: ['很长很长很长很长很长很长的尾部'],
  ),
];
