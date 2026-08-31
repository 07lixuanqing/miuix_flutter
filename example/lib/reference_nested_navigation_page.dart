part of 'main.dart';

/// CJK line-box compensation for the native 420-dpi hint card.
///
/// The localized CJK paragraph has the same three visual lines as the source
/// English copy, but SkParagraph's final line box is two physical pixels
/// shorter than Compose's. Keeping those pixels after the component preserves
/// its original top alignment and the source's measured 265px card height.
const double _referenceNestedHintBottomCompensation = 2 / 2.625;

final class _ReferenceInnerRoute implements MiuixNavKey {
  const _ReferenceInnerRoute(this.depth);

  final int depth;

  @override
  bool operator ==(Object other) =>
      other is _ReferenceInnerRoute && other.depth == depth;

  @override
  int get hashCode => depth.hashCode;
}

/// Localized port of the current upstream `NestedNavTestPage`.
///
/// The inner stack owns Back while it has more than one level. At its root,
/// Back falls through to the outer Navigator and closes this whole page.
class _ReferenceNestedNavigationPage extends StatefulWidget {
  const _ReferenceNestedNavigationPage({
    this.showTopBar = true,
    this.enableBlur = false,
    required this.enableScrollEndHaptic,
  });

  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_ReferenceNestedNavigationPage> createState() =>
      _ReferenceNestedNavigationPageState();
}

class _ReferenceNestedNavigationPageState
    extends State<_ReferenceNestedNavigationPage> {
  final ScrollController _scrollController = ScrollController();
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;
  late final MiuixNavBackStack<_ReferenceInnerRoute> _innerBackStack;

  @override
  void initState() {
    super.initState();
    _scrollBehavior = MiuixTopAppBarScrollBehavior();
    _scrollBehavior.addListener(_handleTopBarChanged);
    _innerBackStack = miuixNavBackStackOf<_ReferenceInnerRoute>(const [
      _ReferenceInnerRoute(1),
    ]);
  }

  void _handleTopBarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollBehavior
      ..removeListener(_handleTopBarChanged)
      ..dispose();
    _innerBackStack.dispose();
    super.dispose();
  }

  /// Adds one unique inner route to the real shared-depth display.
  void _pushInner() {
    _innerBackStack.add(_ReferenceInnerRoute(_innerBackStack.last.depth + 1));
  }

  /// Removes the inner top route before the outer page receives Back.
  void _popInner() {
    if (_innerBackStack.length > 1) _innerBackStack.removeLast();
  }

  void _pushOuter() {
    Navigator.of(context).push<void>(
      _referenceNavigationPageRoute(
        context: context,
        index: 1,
        showTopBar: widget.showTopBar,
        enableBlur: widget.enableBlur,
        enableScrollEndHaptic: widget.enableScrollEndHaptic,
      ),
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
    final bottomInset = _referenceRoundedDp(context, 12);
    return MiuixScaffold(
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: '嵌套导航',
              large: !wide,
              defaultWindowInsetsPadding: !wide,
              scrollBehavior: wide ? null : _scrollBehavior,
              glass: widget.enableBlur,
              leading: MiuixIconButton(
                icon: Icon(
                  _miuixIcon('Back'),
                  color: MiuixSemanticColors.of(context)['onBackground'],
                ),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: MiuixScrollEndHaptic(
        enabled: widget.enableScrollEndHaptic,
        child: MiuixVerticalScrollBar(
          key: const ValueKey('reference-nested-navigation-scrollbar'),
          controller: _scrollController,
          trackPadding: EdgeInsets.only(
            top: topContentInset,
            bottom: bottomInset,
          ),
          child: ListView(
            key: const PageStorageKey('miuix-reference-nested-navigation'),
            controller: _scrollController,
            padding: EdgeInsets.only(top: topContentInset, bottom: bottomInset),
            children: [
              const MiuixSmallTitle('返回语义'),
              Padding(
                // Compose rounds this bottom modifier independently to 32px
                // at 420dpi; retaining 31.5px moves the next card up 1px.
                padding: EdgeInsets.fromLTRB(
                  12,
                  0,
                  12,
                  _referenceRoundedDp(context, 12),
                ),
                child: const MiuixCard(
                  key: ValueKey('nested-navigation-hint-card'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MiuixBasicComponent(
                        title: '同一返回流中的嵌套导航',
                        summary:
                            '系统返回会先弹出下方内部栈。内部处于第 1 层时，'
                            '返回会继续关闭本页；本页被另一个外部页面覆盖时，'
                            '返回不会改动内部栈。',
                      ),
                      SizedBox(height: _referenceNestedHintBottomCompensation),
                    ],
                  ),
                ),
              ),
              const MiuixSmallTitle('内部栈'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: MiuixCard(
                  key: const ValueKey('nested-navigation-stack-card'),
                  padding: EdgeInsets.zero,
                  child: SizedBox(
                    height: 420,
                    child: _buildInnerNavigationDisplay(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders the nested source stack through the public shared-depth display.
  Widget _buildInnerNavigationDisplay(BuildContext context) {
    final surface = MiuixSemanticColors.of(context)['surfaceContainer'];
    return ColoredBox(
      color: surface,
      child: MiuixNavDisplay<_ReferenceInnerRoute>(
        key: const ValueKey('nested-navigation-display'),
        backStack: _innerBackStack,
        effects: MiuixNavDisplayEffects(backdropColor: surface, dimAmount: .5),
        entries: (entries) {
          entries.entry<_ReferenceInnerRoute>(
            contentKey: (route) => 'nested-navigation-entry-${route.depth}',
            builder: (_, route) => _buildInnerLevel(route.depth),
          );
        },
      ),
    );
  }

  /// Builds one source `InnerRoute.Level` entry inside the 420dp host.
  Widget _buildInnerLevel(int depth) {
    final levelPath = List<String>.generate(
      depth,
      (index) => '${index + 1}',
    ).join(' / ');
    return ColoredBox(
      key: ValueKey('nested-navigation-depth-$depth'),
      color: MiuixSemanticColors.of(context)['surfaceContainer'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MiuixSmallTitle('层级 $levelPath'),
          MiuixArrowPreference.source(
            title: '推入内部层级',
            summary: '系统返回会先弹出这个层级',
            onClick: _pushInner,
          ),
          if (depth > 1)
            MiuixArrowPreference.source(title: '弹出内部层级', onClick: _popInner),
          MiuixArrowPreference.source(
            title: '在上方推入外部页面',
            summary: '返回将弹出外部页面，而不是此内部栈',
            onClick: _pushOuter,
          ),
        ],
      ),
    );
  }
}
