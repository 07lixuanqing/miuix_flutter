part of 'main.dart';

/// Shared padding used by localized reference pages.
EdgeInsets _referencePagePadding({
  required BuildContext context,
  required double bottomContentInset,
  double topContentInset = 0,
}) {
  // Every source section contributes an independently measured 12 dp margin.
  // This translated list owns the shared horizontal copy of that margin, so
  // resolve it to the same integer physical pixel before laying out children.
  final sourceHorizontalInset = _referenceRoundedDp(context, 12);
  return EdgeInsets.fromLTRB(
    sourceHorizontalInset,
    topContentInset,
    sourceHorizontalInset,
    bottomContentInset,
  );
}

/// Source SmallTitle starts 28dp from the screen edge on these 12dp lists.
const _referencePageSmallTitlePadding = EdgeInsets.symmetric(
  horizontal: 16,
  vertical: 8,
);

/// Intrinsic width of MainPage.kt's English cascading menu at 420dpi.
///
/// The visible labels are localized, but the reference app keeps the original
/// 573px surface width so translation cannot silently change popup geometry.
const _referenceHomeCascadingPopupWidth = 573 / 2.625;

/// Intrinsic width of MainPage.kt's English multi-select menu at 420dpi.
///
/// Its longest `Multi selection ...` label expands ListPopupColumn from the
/// 200dp floor to exactly 546px. The shorter Chinese translation must retain
/// that source surface width and its trailing-edge anchor.
const _referenceHomeMultiPopupWidth = 546 / 2.625;

/// Chinese reconstruction of the original component home page.
class _MiuixReferenceHomePage extends StatefulWidget {
  const _MiuixReferenceHomePage({
    required this.wide,
    required this.bottomContentInset,
    required this.snackbarHostState,
    required this.showTopBar,
    required this.enableBlur,
    required this.enableScrollEndHaptic,
  });

  final bool wide;
  final double bottomContentInset;
  final MiuixSnackbarHostState snackbarHostState;
  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_MiuixReferenceHomePage> createState() =>
      _MiuixReferenceHomePageState();
}

class _MiuixReferenceHomePageState extends State<_MiuixReferenceHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _searchExpanded = false;
  final List<int> _optionSelections = [0, 1, 2];
  int _cascadingSortIndex = 0;
  int _cascadingViewIndex = 0;
  int _cascadingFilterIndex = 0;
  final Set<String> _multiSelectedItems = {
    'multi-a-0',
    'multi-b-1',
    'multi-b-2',
  };

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setSearchExpanded(bool value) {
    if (_searchExpanded != value) {
      setState(() => _searchExpanded = value);
    }
  }

  void _cancelSearch() {
    _searchController.clear();
    _setSearchExpanded(false);
  }

  void _selectSuggestion(int index) {
    _searchController.text = '建议 $index';
    _setSearchExpanded(false);
  }

  @override
  Widget build(BuildContext context) {
    return _ReferencePageScaffold(
      title: '主页',
      wide: widget.wide,
      showTopBar: widget.showTopBar,
      enableBlur: widget.enableBlur,
      actions: _buildTopBarActions(),
      bodyBuilder: (context, topContentInset) {
        // SearchBar's bottom padding and the final LazyColumn spacer are
        // separate 12 dp modifiers in MainPage.kt.
        final sourceSectionSpacing = _referenceRoundedDp(context, 12);
        final contentPadding = _referencePagePadding(
          context: context,
          bottomContentInset: widget.bottomContentInset,
          topContentInset: topContentInset,
        );
        final items = <Widget>[
          const MiuixSmallTitle(
            '搜索栏',
            insideMargin: _referencePageSmallTitlePadding,
          ),
          // MainPage.kt lets SearchBar own the complete viewport width and
          // applies its 12dp margin only inside the weighted input box. The
          // surrounding translated list owns a 12dp page inset, so overflow
          // this one child back to the viewport before restoring that margin.
          // This is observable after expansion: suggestions begin at x=42px,
          // not x=74px, and Cancel may consume the trailing source slot.
          LayoutBuilder(
            builder: (context, constraints) {
              // The responsive shell may cap its local content viewport while
              // MediaQuery continues reporting the complete desktop window.
              // Using that global width centers an oversized SearchBar behind
              // the clip and moves its icon, placeholder, and cancel action
              // outside the visible 1200dp plane. Recover exactly the local
              // list viewport by adding back the padding this child overflows.
              final localViewportWidth =
                  constraints.maxWidth + contentPadding.horizontal;
              return OverflowBox(
                alignment: Alignment.center,
                fit: OverflowBoxFit.deferToChild,
                minWidth: localViewportWidth,
                maxWidth: localViewportWidth,
                child: MiuixSearchBar.source(
                  key: const ValueKey('home-reference-search'),
                  inputField: MiuixInputField.controller(
                    controller: _searchController,
                    expanded: _searchExpanded,
                    onExpandedChange: _setSearchExpanded,
                    label: '搜索',
                    onQueryChange: (_) => setState(() {}),
                    onSearch: (_) => _setSearchExpanded(false),
                  ),
                  insideMargin: const Size(12, 0),
                  expanded: _searchExpanded,
                  onExpandedChange: _setSearchExpanded,
                  outsideEndAction: Padding(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                    child: SizedBox(
                      key: const ValueKey('home-search-cancel-slot'),
                      width: 52.5,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GestureDetector(
                          key: const ValueKey('home-search-cancel'),
                          behavior: HitTestBehavior.opaque,
                          onTap: _cancelSearch,
                          child: Text(
                            '取消',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  content: Column(
                    children: [
                      for (var index = 0; index < 4; index++)
                        MiuixBasicComponent(
                          title: '建议 $index',
                          onTap: () => _selectSuggestion(index),
                          standalone: false,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: sourceSectionSpacing),
          if (!_searchExpanded) ...[
            const _ReferenceBasicComponentSection(),
            const _ReferenceSwitchSection(),
            const _ReferenceCheckboxSection(),
            const _ReferenceRadioSection(),
            const _ReferenceButtonSection(),
            const _ReferenceTabSection(),
            const _ReferenceBreadcrumbBarSection(),
            const _ReferenceArrowSection(),
            const _ReferenceDialogSection(),
            const _ReferenceBottomSheetSection(),
            const _ReferenceDropdownSection(),
            const _ReferenceSpinnerSection(),
            _ReferenceSnackbarSection(hostState: widget.snackbarHostState),
            const _ReferenceTextFieldSection(),
            const _ReferenceProgressSection(),
            const _ReferenceSliderSection(),
            const _ReferenceCardSection(),
            const _ReferenceTooltipSection(),
            const _ReferenceBadgeSection(),
            const _ReferenceNumberPickerSection(),
            const _ReferenceColorPickerSection(),
            const _ReferenceBlurSection(),
            _ReferenceOtherSection(
              showTopBar: widget.showTopBar,
              enableBlur: widget.enableBlur,
              enableScrollEndHaptic: widget.enableScrollEndHaptic,
            ),
          ],
          SizedBox(height: sourceSectionSpacing),
        ];
        // Compose LazyColumn creates only the visible section. A builder keeps
        // heavyweight color pickers and animated blur previews out of the tree
        // until the user reaches them, matching both source lifetime and cost.
        return MiuixVerticalScrollBar(
          key: const ValueKey('reference-home-scrollbar'),
          controller: _scrollController,
          trackPadding: contentPadding,
          child: ListView.builder(
            key: const PageStorageKey('miuix-reference-home'),
            controller: _scrollController,
            padding: contentPadding,
            itemCount: items.length,
            itemBuilder: (context, index) => items[index],
          ),
        );
      },
    );
  }

  /// Builds the three current `MainPage` action menus in source order.
  List<Widget> _buildTopBarActions() {
    List<MiuixDropdownEntry<String>> options(
      String group,
      int count,
      int selectedIndex,
    ) {
      return List.generate(
        count,
        (index) => MiuixDropdownEntry(
          value: 'option-$group-$index',
          label: '选项 ${group.toUpperCase()}-${index + 1}',
          selected: selectedIndex == index,
        ),
      );
    }

    final optionGroups = <MiuixDropdownGroup<String>>[
      MiuixDropdownGroup(entries: options('a', 2, _optionSelections[0])),
      MiuixDropdownGroup(entries: options('b', 3, _optionSelections[1])),
      MiuixDropdownGroup(entries: options('c', 4, _optionSelections[2])),
    ];
    final cascadingGroups = <MiuixDropdownGroup<String>>[
      MiuixDropdownGroup(
        entries: [
          MiuixDropdownEntry(
            value: 'cascade-sort-0',
            label: '按拍摄日期排序',
            selected: _cascadingSortIndex == 0,
          ),
          MiuixDropdownEntry(
            value: 'cascade-sort-1',
            label: '按添加日期排序',
            selected: _cascadingSortIndex == 1,
          ),
        ],
      ),
      MiuixDropdownGroup(
        entries: [
          MiuixDropdownEntry(
            value: 'cascade-view',
            label: '查看模式',
            children: [
              MiuixDropdownEntry(
                value: 'cascade-view-0',
                label: '按日期分组',
                selected: _cascadingViewIndex == 0,
              ),
              MiuixDropdownEntry(
                value: 'cascade-view-1',
                label: '紧凑',
                selected: _cascadingViewIndex == 1,
              ),
            ],
          ),
          MiuixDropdownEntry(
            value: 'cascade-filter',
            label: '筛选',
            children: [
              MiuixDropdownEntry(
                value: 'cascade-filter-0',
                label: '全部项目',
                selected: _cascadingFilterIndex == 0,
              ),
              MiuixDropdownEntry(
                value: 'cascade-filter-1',
                label: '相机相册',
                selected: _cascadingFilterIndex == 1,
              ),
            ],
          ),
        ],
      ),
    ];

    List<MiuixDropdownEntry<String>> multiOptions(String group, int count) {
      return List.generate(count, (index) {
        final value = 'multi-$group-$index';
        return MiuixDropdownEntry(
          value: value,
          label: '多选 ${group.toUpperCase()}-${index + 1}',
          selected: _multiSelectedItems.contains(value),
        );
      });
    }

    final multiGroups = <MiuixDropdownGroup<String>>[
      MiuixDropdownGroup(entries: multiOptions('a', 2)),
      MiuixDropdownGroup(entries: multiOptions('b', 3)),
    ];
    final menus = <Widget>[
      MiuixOverlayIconCascadingDropdownMenu<String>(
        key: const ValueKey('home-top-options-menu'),
        tooltip: '选项',
        groups: cascadingGroups,
        collapseOnSelection: true,
        minWidth: _referenceHomeCascadingPopupWidth,
        icon: const Icon(Icons.more_vert, semanticLabel: '更多'),
        onSelected: (value) {
          setState(() {
            if (value.startsWith('cascade-sort-')) {
              _cascadingSortIndex = int.parse(value.split('-').last);
            } else if (value.startsWith('cascade-view-')) {
              _cascadingViewIndex = int.parse(value.split('-').last);
            } else if (value.startsWith('cascade-filter-')) {
              _cascadingFilterIndex = int.parse(value.split('-').last);
            }
          });
        },
      ),
      MiuixOverlayIconDropdownMenu<String>(
        key: const ValueKey('home-top-sort-menu'),
        tooltip: '排序',
        groups: optionGroups,
        collapseOnSelection: false,
        icon: Icon(_miuixIcon('Sort'), semanticLabel: '排序'),
        onSelected: (value) {
          final parts = value.split('-');
          final groupIndex = const {'a': 0, 'b': 1, 'c': 2}[parts[1]]!;
          setState(() => _optionSelections[groupIndex] = int.parse(parts[2]));
        },
      ),
      MiuixOverlayIconDropdownMenu<String>(
        key: const ValueKey('home-top-select-all-menu'),
        tooltip: '全选',
        groups: multiGroups,
        collapseOnSelection: false,
        allowMultipleSelection: true,
        popupMinWidth: _referenceHomeMultiPopupWidth,
        icon: Icon(_miuixIcon('SelectAll'), semanticLabel: '全选'),
        onSelected: (value) {
          setState(() {
            if (!_multiSelectedItems.remove(value)) {
              _multiSelectedItems.add(value);
            }
          });
        },
      ),
    ];
    // HyperOS 4 keeps the compact title action as one circular overflow
    // surface. The complete dropdown variants remain demonstrated in their
    // component sections instead of forming an oversized three-icon capsule.
    return [menus.first];
  }
}
