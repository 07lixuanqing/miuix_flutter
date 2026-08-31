part of 'main.dart';

/// Four local popup hosts matching MIUIX's multi-scaffold fixture.
class _ReferenceMultiScaffoldPage extends StatefulWidget {
  const _ReferenceMultiScaffoldPage({
    this.showTopBar = true,
    this.enableBlur = false,
    this.enableScrollEndHaptic = true,
  });

  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_ReferenceMultiScaffoldPage> createState() =>
      _ReferenceMultiScaffoldPageState();
}

class _ReferenceMultiScaffoldPageState
    extends State<_ReferenceMultiScaffoldPage> {
  final List<int> _selectedIndices = [0, 0, 0, 0];
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

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final topContentInset = _referenceTopContentInset(
      context,
      showTopBar: widget.showTopBar,
      wide: wide,
      scrollBehavior: wide ? null : _scrollBehavior,
    );
    return MiuixScaffold(
      key: const ValueKey('multi-scaffold-page'),
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: '多脚手架测试',
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
      body: Padding(
        // MultiScaffoldTestPage.kt adds 12dp after the route padding. That
        // space is part of the weighted Column's constraints: omitting it
        // gives each row an extra 6dp and moves the lower pair too far down.
        padding: EdgeInsets.only(top: topContentInset, bottom: 12),
        child: LayoutBuilder(
          builder: (context, constraints) => MiuixScrollEndHaptic(
            enabled: widget.enableScrollEndHaptic,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _quadrant(0, '左上')),
                          Expanded(child: _quadrant(1, '右上')),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: _quadrant(2, '左下')),
                          Expanded(child: _quadrant(3, '右下')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds one independent nested scaffold and keeps its overlay local.
  Widget _quadrant(int index, String title) {
    final sourceHorizontalPadding = _referenceRoundedDp(context, 12);
    return MiuixScaffold(
      key: ValueKey('multi-scaffold-quadrant-$index'),
      // The upstream modifier places surfaceVariant behind the nested
      // Scaffold. Scaffold then paints its own surface over that modifier, so
      // only the Card remains surfaceVariant in the final frame. Coloring the
      // Flutter body directly made the entire quadrant grey and erased the
      // card outline.
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MiuixSmallTitle(title),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sourceHorizontalPadding),
            child: MiuixCard(
              child: MiuixOverlayDropdownPreference.source(
                title: '下拉菜单',
                selectedIndex: _selectedIndices[index],
                items: const ['A', 'B', 'C'],
                renderInRootScaffold: false,
                onSelectedIndexChange: (selectedIndex) =>
                    setState(() => _selectedIndices[index] = selectedIndex),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
