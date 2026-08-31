part of '../miuix_widgets.dart';

/// List popup surface that can be hosted in dialogs, sheets, or popovers.
class MiuixListPopup<T> extends StatefulWidget {
  /// Creates a list popup.
  const MiuixListPopup({
    super.key,
    required this.entries,
    required this.onSelected,
    this.groups = const [],
    this.minWidth = 200,
  }) : assert(minWidth >= 0 && minWidth <= 288);

  /// Entries to display.
  final List<MiuixDropdownEntry<T>> entries;

  /// Optional independent entry groups separated by MIUIX dividers.
  final List<MiuixDropdownGroup<T>> groups;

  /// Minimum intrinsic popup width, capped by the source 288dp maximum.
  ///
  /// Localized labels can be shorter than the source strings. Callers that
  /// reproduce a translated reference UI may retain the original intrinsic
  /// width without inserting invisible text into the menu.
  final double minWidth;

  /// Selection callback.
  final ValueChanged<T> onSelected;

  @override
  State<MiuixListPopup<T>> createState() => _MiuixListPopupState<T>();
}

/// Keeps every popup group's active row visible while the popup remains open.
class _MiuixListPopupState<T> extends State<MiuixListPopup<T>> {
  late List<T?> _selectedValues;

  List<MiuixDropdownGroup<T>> get _resolvedGroups => widget.groups.isEmpty
      ? [MiuixDropdownGroup<T>(entries: widget.entries)]
      : widget.groups;

  @override
  void initState() {
    super.initState();
    _syncSelectedValues();
  }

  @override
  void didUpdateWidget(covariant MiuixListPopup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entries != widget.entries ||
        oldWidget.groups != widget.groups) {
      _syncSelectedValues();
    }
  }

  /// Reads the caller's initial selection once for each independent group.
  void _syncSelectedValues() {
    _selectedValues = _resolvedGroups
        .map<T?>((group) {
          for (final entry in group.entries) {
            if (entry.selected) return entry.value;
          }
          return null;
        })
        .toList(growable: false);
  }

  /// Updates the check mark locally before notifying the owning preference.
  void _select(int groupIndex, MiuixDropdownEntry<T> entry) {
    setState(() => _selectedValues[groupIndex] = entry.value);
    widget.onSelected(entry.value);
  }

  /// Builds the exact DropdownImpl row, including the transparent check slot.
  ///
  /// Compose always measures the 20dp check image and its 12dp start padding,
  /// even for an unselected row whose check color is transparent. Reserving
  /// that slot is required for the same intrinsic popup width and text column.
  Widget _buildEntry(
    BuildContext context,
    int groupIndex,
    int entryIndex, {
    required bool isFirst,
    required bool isLast,
  }) {
    final entry = _resolvedGroups[groupIndex].entries[entryIndex];
    final selected = _selectedValues[groupIndex] == entry.value;
    return _MiuixMenuRow(
      enabled: entry.enabled,
      icon: entry.icon,
      label: entry.label,
      summary: entry.summary,
      isFirst: isFirst,
      isLast: isLast,
      selected: selected,
      trailing: _MiuixDropdownCheck(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
      ),
      onTap: entry.enabled ? () => _select(groupIndex, entry) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolvedGroups = _resolvedGroups;
    final rowCount = resolvedGroups.fold<int>(
      0,
      (total, group) => total + group.entries.length,
    );
    final scheme = Theme.of(context).colorScheme;
    // ListPopupColumn, rather than Flutter IntrinsicWidth, measures only the
    // first eight rows before clamping the result to the source 200..288dp
    // interval. Later long rows therefore scroll/truncate without silently
    // widening an already measured popup.
    final children = <Widget>[
      if (rowCount == 0)
        const _MiuixMenuRow(
          label: 'No actions',
          enabled: false,
          isFirst: true,
          isLast: true,
        )
      else
        for (
          var groupIndex = 0;
          groupIndex < resolvedGroups.length;
          groupIndex++
        ) ...[
          if (groupIndex > 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: MiuixHorizontalDivider(indent: 0, endIndent: 0),
            ),
          for (
            var entryIndex = 0;
            entryIndex < resolvedGroups[groupIndex].entries.length;
            entryIndex++
          )
            _buildEntry(
              context,
              groupIndex,
              entryIndex,
              isFirst: groupIndex == 0 && entryIndex == 0,
              isLast:
                  groupIndex == resolvedGroups.length - 1 &&
                  entryIndex == resolvedGroups[groupIndex].entries.length - 1,
            ),
        ],
    ];
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth, maxWidth: 288),
      child: MiuixSurface(
        padding: EdgeInsets.zero,
        radius: MiuixListPopupDefaults.cornerRadius,
        color: scheme.surfaceContainer,
        child: MiuixListPopupColumn(children: children),
      ),
    );
  }
}

/// Exact 56-unit MIUIX basic Check path, painted into DropdownImpl's 20dp box.
class _MiuixDropdownCheck extends StatelessWidget {
  const _MiuixDropdownCheck({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    key: ValueKey(
      color.a == 0
          ? 'miuix-dropdown-check-empty'
          : 'miuix-dropdown-check-selected',
    ),
    size: const Size.square(20),
    painter: _MiuixDropdownCheckPainter(color),
  );
}

class _MiuixDropdownCheckPainter extends CustomPainter {
  const _MiuixDropdownCheckPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(46.8171, 18.1514)
      ..cubicTo(48.0496, 16.6624, 47.8417, 14.4561, 46.3527, 13.2235)
      ..cubicTo(44.8636, 11.991, 42.6573, 12.1989, 41.4247, 13.6879)
      ..lineTo(22.9535, 36.0031)
      ..lineTo(13.4007, 26.4502)
      ..cubicTo(12.0338, 25.0833, 9.8177, 25.0833, 8.4509, 26.4502)
      ..cubicTo(7.0841, 27.817, 7.0841, 30.0331, 8.4509, 31.3999)
      ..lineTo(20.7077, 43.6567)
      ..cubicTo(21.7243, 44.6733, 23.2108, 44.9338, 24.4682, 44.4381)
      ..cubicTo(25.0159, 44.2302, 25.5189, 43.8818, 25.9192, 43.3982)
      ..lineTo(46.8171, 18.1514)
      ..close();
    canvas.save();
    canvas.scale(size.width / 56, size.height / 56);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MiuixDropdownCheckPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Overlay-named list popup adapter.
class MiuixOverlayListPopup<T> extends MiuixListPopup<T> {
  /// Creates an overlay list popup.
  const MiuixOverlayListPopup({
    super.key,
    required super.entries,
    required super.onSelected,
  });

  /// Shows an anchored list inside the nearest Scaffold popup host.
  static Future<void> show<T>({
    required BuildContext context,
    required List<MiuixDropdownEntry<T>> entries,
    required ValueChanged<T> onSelected,
    LayerLink? link,
    MiuixPopupAlignment alignment = MiuixPopupAlignment.bottomStart,
    bool renderInRootScaffold = true,
  }) {
    return _showMiuixDropdownMenu<T>(
      context: context,
      entries: entries,
      onSelected: onSelected,
      presentation: MiuixPopupPresentation.overlay,
      link: link,
      alignment: alignment,
      renderInRootScaffold: renderInRootScaffold,
    );
  }
}

/// Window-named list popup adapter.
class MiuixWindowListPopup<T> extends MiuixListPopup<T> {
  /// Creates a window list popup.
  const MiuixWindowListPopup({
    super.key,
    required super.entries,
    required super.onSelected,
  });

  /// Shows an anchored list in a root Navigator route.
  static Future<void> show<T>({
    required BuildContext context,
    required List<MiuixDropdownEntry<T>> entries,
    required ValueChanged<T> onSelected,
    LayerLink? link,
    MiuixPopupAlignment alignment = MiuixPopupAlignment.bottomStart,
  }) {
    return _showMiuixDropdownMenu<T>(
      context: context,
      entries: entries,
      onSelected: onSelected,
      presentation: MiuixPopupPresentation.window,
      link: link,
      alignment: alignment,
    );
  }
}

/// Cascading menu item for two-level menus.
@immutable
class MiuixCascadingMenuItem<T> {
  /// Creates a cascading menu item.
  const MiuixCascadingMenuItem({
    required this.label,
    required this.children,
    this.icon,
  });

  /// Parent label.
  final String label;

  /// Optional icon.
  final Widget? icon;

  /// Child entries.
  final List<MiuixDropdownEntry<T>> children;
}

/// Simple two-level cascading menu.
class MiuixCascadingMenu<T> extends StatelessWidget {
  /// Creates a cascading menu.
  const MiuixCascadingMenu({
    super.key,
    required this.items,
    required this.onSelected,
  });

  /// Parent menu items.
  final List<MiuixCascadingMenuItem<T>> items;

  /// Selection callback.
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return MiuixSurface(
      padding: EdgeInsets.zero,
      radius: MiuixTheme.of(context).radius.md,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (items.isEmpty)
            const _MiuixMenuRow(label: 'No actions', enabled: false)
          else
            for (final item in items)
              _MiuixCascadingSection<T>(item: item, onSelected: onSelected),
        ],
      ),
    );
  }
}

class _MiuixCascadingSection<T> extends StatefulWidget {
  const _MiuixCascadingSection({required this.item, required this.onSelected});

  final MiuixCascadingMenuItem<T> item;
  final ValueChanged<T> onSelected;

  @override
  State<_MiuixCascadingSection<T>> createState() =>
      _MiuixCascadingSectionState<T>();
}

class _MiuixCascadingSectionState<T> extends State<_MiuixCascadingSection<T>> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MiuixMenuRow(
          icon: widget.item.icon,
          label: widget.item.label,
          onTap: () => setState(() => _expanded = !_expanded),
          trailing: Icon(
            _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            size: 20,
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 180),
          crossFadeState: _expanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final child in widget.item.children)
                _MiuixMenuRow(
                  enabled: child.enabled,
                  icon: child.icon,
                  label: child.label,
                  indent: 32,
                  onTap: child.enabled
                      ? () => widget.onSelected(child.value)
                      : null,
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Overlay-named cascading menu adapter.
class MiuixOverlayCascadingListPopup<T> extends MiuixCascadingMenu<T> {
  /// Creates an overlay cascading list popup.
  const MiuixOverlayCascadingListPopup({
    super.key,
    required super.items,
    required super.onSelected,
  });

  /// Shows cascading content inside the nearest Scaffold popup host.
  static Future<void> show<T>({
    required BuildContext context,
    required List<MiuixCascadingMenuItem<T>> items,
    required ValueChanged<T> onSelected,
    LayerLink? link,
    bool renderInRootScaffold = true,
  }) {
    final host = MiuixPopupHostScope.maybeOf(context);
    final target = renderInRootScaffold ? host?.root : host;
    late final MiuixCascadingMenu<T> popup;
    popup = MiuixCascadingMenu<T>(
      items: items,
      onSelected: (value) {
        target?.dismissTop();
        onSelected(value);
      },
    );
    return _showMiuixOverlayPopupSurface<void>(
      context: context,
      child: popup,
      maxWidth: 360,
      link: link,
      renderInRootScaffold: renderInRootScaffold,
    );
  }
}

/// Window-named cascading menu adapter.
class MiuixWindowCascadingListPopup<T> extends MiuixCascadingMenu<T> {
  /// Creates a window cascading list popup.
  const MiuixWindowCascadingListPopup({
    super.key,
    required super.items,
    required super.onSelected,
  });

  /// Shows cascading content in a root Navigator route.
  static Future<void> show<T>({
    required BuildContext context,
    required List<MiuixCascadingMenuItem<T>> items,
    required ValueChanged<T> onSelected,
    LayerLink? link,
  }) {
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    return _showMiuixWindowPopupSurface<void>(
      context: context,
      maxWidth: 360,
      link: link,
      child: MiuixCascadingMenu<T>(
        items: items,
        onSelected: (value) {
          if (navigator?.mounted == true && navigator!.canPop()) {
            navigator.pop();
          }
          onSelected(value);
        },
      ),
    );
  }
}

/// Icon-triggered cascading dropdown menu.
class MiuixIconCascadingDropdownMenu<T> extends StatelessWidget {
  /// Creates an icon cascading menu.
  const MiuixIconCascadingDropdownMenu({
    super.key,
    required this.icon,
    required this.items,
    required this.onSelected,
    this.tooltip,
    this.presentation = MiuixPopupPresentation.window,
    this.enabled = true,
    this.onExpandedChange,
    this.renderInRootScaffold = true,
  });

  /// Trigger icon.
  final Widget icon;

  /// Optional trigger tooltip.
  final String? tooltip;

  /// Cascading menu items.
  final List<MiuixCascadingMenuItem<T>> items;

  /// Selection callback.
  final ValueChanged<T> onSelected;

  /// Popup route family used by this trigger.
  final MiuixPopupPresentation presentation;

  /// Whether the icon trigger can open the menu.
  final bool enabled;

  /// Called when popup expansion starts or finishes.
  final ValueChanged<bool>? onExpandedChange;

  /// Whether Overlay presentation uses the outermost Scaffold host.
  final bool renderInRootScaffold;

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.maybeOf(context, rootNavigator: true);
    final host = MiuixPopupHostScope.maybeOf(context);
    final link = LayerLink();
    return CompositedTransformTarget(
      link: link,
      child: MiuixPressable(
        onTap: enabled && items.isNotEmpty
            ? () async {
                onExpandedChange?.call(true);
                final popup = MiuixCascadingMenu<T>(
                  items: items,
                  onSelected: (value) {
                    if (presentation == MiuixPopupPresentation.overlay) {
                      (renderInRootScaffold ? host?.root : host)?.dismissTop();
                    } else if (navigator?.mounted == true &&
                        navigator!.canPop()) {
                      navigator.pop();
                    }
                    onSelected(value);
                  },
                );
                try {
                  if (presentation == MiuixPopupPresentation.overlay) {
                    await _showMiuixOverlayPopupSurface<void>(
                      context: context,
                      maxWidth: 360,
                      link: link,
                      renderInRootScaffold: renderInRootScaffold,
                      child: popup,
                    );
                  } else {
                    await _showMiuixWindowPopupSurface<void>(
                      context: context,
                      maxWidth: 360,
                      link: link,
                      child: popup,
                    );
                  }
                } finally {
                  onExpandedChange?.call(false);
                }
              }
            : null,
        feedbackType: MiuixPressFeedbackType.none,
        showIndication: enabled && items.isNotEmpty,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 160),
          opacity: enabled ? 1 : .38,
          child: MiuixTooltip(
            message: tooltip ?? '',
            child: IconTheme.merge(
              data: IconThemeData(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay-named icon cascading dropdown menu.
class MiuixOverlayIconCascadingDropdownMenu<T>
    extends MiuixIconCascadingDropdownMenu<T> {
  /// Creates an overlay icon cascading dropdown menu.
  const MiuixOverlayIconCascadingDropdownMenu({
    super.key,
    required super.icon,
    required super.items,
    required super.onSelected,
    super.tooltip,
    super.enabled,
    super.onExpandedChange,
    super.renderInRootScaffold,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-named icon cascading dropdown menu.
class MiuixWindowIconCascadingDropdownMenu<T>
    extends MiuixIconCascadingDropdownMenu<T> {
  /// Creates a window icon cascading dropdown menu.
  const MiuixWindowIconCascadingDropdownMenu({
    super.key,
    required super.icon,
    required super.items,
    required super.onSelected,
    super.tooltip,
    super.enabled,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.window);
}
