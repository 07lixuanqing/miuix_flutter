part of 'main.dart';

/// Exposes the removed historical page only as a focused component fixture.
///
/// Current upstream no longer places `DropdownPage` in the root pager, but its
/// popup geometry remains useful for regression tests of the dropdown library.
@visibleForTesting
Widget debugReferenceDropdownPage() {
  return const _MiuixReferenceDropdownPage(
    wide: false,
    // Preserve the viewport available when this historical page occupied the
    // fourth root destination, without rendering the now-obsolete root item.
    bottomContentInset: 64.75,
    showTopBar: true,
    enableBlur: false,
  );
}

/// Localized reconstruction of the current upstream `DropdownPage`.
///
/// The original alternates overlay-hosted and window-hosted preferences in one
/// continuous six-row surface. Pulling past the top waits 200 ms and appends a
/// further six rows, preserving the same shared selection across every row.
class _MiuixReferenceDropdownPage extends StatefulWidget {
  const _MiuixReferenceDropdownPage({
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
  State<_MiuixReferenceDropdownPage> createState() =>
      _MiuixReferenceDropdownPageState();
}

class _MiuixReferenceDropdownPageState
    extends State<_MiuixReferenceDropdownPage> {
  static const _items = ['选项 1', '选项 2', '选项 3', '选项 4'];

  int _selected = 0;
  int _rowCount = 6;
  bool _isRefreshing = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Mirrors the source's synchronous callback and hoisted loading state.
  void _refresh() {
    if (_isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    unawaited(_finishRefresh());
  }

  /// `LaunchedEffect(isRefreshing)` in the source appends six rows after 200ms.
  Future<void> _finishRefresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (mounted) {
      setState(() {
        _rowCount += 6;
        _isRefreshing = false;
      });
    }
  }

  BorderRadius _rowRadius(int index) {
    const radius = Radius.circular(16);
    if (index == 0) {
      return const BorderRadius.vertical(top: radius);
    }
    if (index == _rowCount - 1) {
      return const BorderRadius.vertical(bottom: radius);
    }
    return BorderRadius.zero;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _ReferencePageScaffold(
      title: '下拉菜单',
      wide: widget.wide,
      showTopBar: widget.showTopBar,
      enableBlur: widget.enableBlur,
      bodyBuilder: (context, topContentInset) {
        final sourcePageMargin = _referenceRoundedDp(context, 12);
        final contentPadding = EdgeInsets.fromLTRB(
          12,
          topContentInset + sourcePageMargin,
          12,
          widget.bottomContentInset,
        );
        return MiuixPullToRefresh(
          onRefresh: _refresh,
          isRefreshing: _isRefreshing,
          contentPadding: EdgeInsets.only(
            top: topContentInset + sourcePageMargin,
          ),
          refreshTexts: const ['下拉刷新', '松开刷新', '正在刷新…', '刷新成功'],
          child: MiuixVerticalScrollBar(
            key: const ValueKey('reference-dropdown-scrollbar'),
            controller: _scrollController,
            trackPadding: contentPadding,
            child: ListView.builder(
              key: const PageStorageKey('miuix-reference-dropdown'),
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: contentPadding,
              itemCount: _rowCount + 1,
              itemBuilder: (context, index) {
                // DropdownPage.kt appends an independent 12dp spacer after the
                // final rounded preference rather than folding it into list
                // content padding.
                if (index == _rowCount) {
                  return SizedBox(height: sourcePageMargin);
                }
                final shape = MiuixSquircleBorder(
                  borderRadius: _rowRadius(index),
                );
                final preference = index.isEven
                    ? MiuixOverlayDropdownPreference.source(
                        key: ValueKey('overlay-dropdown-${index + 1}'),
                        title: '叠加下拉偏好 ${index + 1}',
                        selectedIndex: _selected,
                        items: _items,
                        onSelectedIndexChange: (selectedIndex) =>
                            setState(() => _selected = selectedIndex),
                      )
                    : MiuixWindowDropdownPreference.source(
                        key: ValueKey('window-dropdown-${index + 1}'),
                        title: '窗口下拉偏好 ${index + 1}',
                        selectedIndex: _selected,
                        items: _items,
                        onSelectedIndexChange: (selectedIndex) =>
                            setState(() => _selected = selectedIndex),
                      );
                return ClipPath(
                  clipper: ShapeBorderClipper(shape: shape),
                  child: ColoredBox(
                    color: scheme.surfaceContainer,
                    child: preference,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
