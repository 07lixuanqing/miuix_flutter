part of 'main.dart';

/// Demonstrates adaptive navigation, resizable panes, and the sliver top bar.
class _ReferenceExtensionLayoutSection extends StatefulWidget {
  const _ReferenceExtensionLayoutSection({required this.enableBlur});

  final bool enableBlur;

  @override
  State<_ReferenceExtensionLayoutSection> createState() =>
      _ReferenceExtensionLayoutSectionState();
}

class _ReferenceExtensionLayoutSectionState
    extends State<_ReferenceExtensionLayoutSection> {
  final MiuixSplitViewController _split = MiuixSplitViewController(
    primaryExtent: 140,
  );
  var _destination = 0;

  static final _destinations = <MiuixNavigationItem>[
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Home')),
      selectedIcon: Icon(_miuixIcon('Home')),
      label: '首页',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Folder')),
      selectedIcon: Icon(_miuixIcon('Folder')),
      label: '文件',
    ),
    MiuixNavigationItem(
      icon: Icon(_miuixIcon('Settings')),
      selectedIcon: Icon(_miuixIcon('Settings')),
      label: '设置',
    ),
  ];

  @override
  void dispose() {
    _split.dispose();
    super.dispose();
  }

  void _openSliverTopAppBarDemo(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const _ReferenceSliverTopAppBarDemo(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MiuixSmallTitle(
          '自适应导航与分栏',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: MiuixAdaptiveScaffold(
              items: _destinations,
              selectedIndex: _destination,
              onDestinationSelected: (value) =>
                  setState(() => _destination = value),
              glassNavigation: widget.enableBlur,
              body: ColoredBox(
                color: semantic['surfaceContainer'],
                child: Center(
                  child: Text('当前页：${_destinations[_destination].label}'),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: MiuixSplitView(
              controller: _split,
              minimumPrimaryExtent: 90,
              maximumPrimaryExtent: 260,
              minimumSecondaryExtent: 120,
              primary: MiuixNavigationDrawer(
                items: _destinations,
                selectedIndex: _destination,
                onDestinationSelected: (value) =>
                    setState(() => _destination = value),
                glass: widget.enableBlur,
                defaultWindowInsetsPadding: false,
              ),
              secondary: ColoredBox(
                color: semantic['surface'],
                child: const Center(child: Text('拖动或用方向键调整分栏')),
              ),
            ),
          ),
        ),
        const MiuixSmallTitle(
          'Sliver TopAppBar',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixButton(
          label: '打开 Sliver TopAppBar 示例',
          icon: Icon(_miuixIcon('Link')),
          onPressed: () => _openSliverTopAppBarDemo(context),
        ),
      ],
    );
  }
}

/// Hosts the sliver in its own scroll scene so it owns exactly one vertical
/// gesture arena. Nesting a CustomScrollView inside the extension catalogue's
/// ListView made the two viewports fight over Android drags and produced large
/// jumping gaps that were not a property of the public sliver component.
class _ReferenceSliverTopAppBarDemo extends StatelessWidget {
  const _ReferenceSliverTopAppBarDemo();

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final enableBlur = MiuixTheme.of(context).enableGlass;
    return Scaffold(
      backgroundColor: semantic['surface'],
      body: CustomScrollView(
        slivers: <Widget>[
          MiuixSliverTopAppBar(
            title: '项目',
            subtitle: '滚动收起大标题',
            glass: enableBlur,
            floating: true,
            snap: true,
            leading: MiuixIconButton(
              icon: Icon(
                _miuixIcon('Back'),
                color: MiuixSemanticColors.of(context)['onBackground'],
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverList.builder(
            itemCount: 24,
            itemBuilder: (context, index) => Container(
              height: 52,
              alignment: AlignmentDirectional.centerStart,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              color: index.isEven
                  ? semantic['surface']
                  : semantic['surfaceContainer'],
              child: Text('项目 ${index + 1}'),
            ),
          ),
        ],
      ),
    );
  }
}
