part of '../miuix_widgets.dart';

/// Dropdown preference for option selection.
class MiuixDropdownPreference<T> extends StatefulWidget {
  /// Creates a dropdown preference.
  const MiuixDropdownPreference({
    super.key,
    required this.title,
    required this.value,
    required this.entries,
    required this.onChanged,
    this.summary,
    this.presentation = MiuixPopupPresentation.window,
    this.enabled = true,
    this.renderInRootScaffold = true,
    this.onExpandedChange,
    this.closeOnSelection = true,
    this.dialogConfirmLabel,
    this.popupMinWidth = 200,
    this.popupAnchorOffset = Offset.zero,
    this.titleColors,
    this.summaryColors,
    this.leading,
    this.bottomAction,
    this.insideMargin = MiuixBasicComponentDefaults.insideMargin,
    this.maxHeight,
    this.showValue = true,
    this.dropdownColors,
    this.sourceMode = false,
  });

  /// Main title.
  final String title;

  /// Optional summary.
  final String? summary;

  /// Selected value.
  final T value;

  /// Available entries.
  final List<MiuixDropdownEntry<T>> entries;

  /// Change callback.
  final ValueChanged<T> onChanged;

  /// Popup route family used by this preference.
  final MiuixPopupPresentation presentation;

  /// Whether the preference can open its popup.
  final bool enabled;

  /// Whether Overlay presentation uses the outermost Scaffold host.
  final bool renderInRootScaffold;

  /// Called when popup expansion starts or finishes.
  final ValueChanged<bool>? onExpandedChange;

  /// Whether choosing a popup row immediately closes the menu.
  final bool closeOnSelection;

  /// When non-null, presents spinner choices in a confirmable dialog.
  final String? dialogConfirmLabel;

  /// Minimum popup width before the source 288dp upper clamp is applied.
  final double popupMinWidth;

  /// Additional logical offset applied to the measured end-action anchor.
  ///
  /// The component already applies MIUIX's one-physical-pixel text-anchor
  /// correction. Use this only for a deliberately customized trailing layout.
  final Offset popupAnchorOffset;

  /// Optional source title foreground pair.
  final MiuixBasicComponentColors? titleColors;

  /// Optional source summary foreground pair.
  final MiuixBasicComponentColors? summaryColors;

  /// Optional source start action.
  final Widget? leading;

  /// Optional source bottom action.
  final Widget? bottomAction;

  /// Directional source inside margin.
  final EdgeInsetsGeometry insideMargin;

  /// Optional source popup height limit.
  final double? maxHeight;

  /// Whether the selected value is rendered before the dropdown arrow.
  final bool showValue;

  /// Optional source popup-row color set.
  final MiuixDropdownColors? dropdownColors;

  /// Whether this instance follows the exact index-based upstream contract.
  @protected
  final bool sourceMode;

  @override
  State<MiuixDropdownPreference<T>> createState() =>
      _MiuixDropdownPreferenceState<T>();
}

class _MiuixDropdownPreferenceState<T>
    extends State<MiuixDropdownPreference<T>> {
  /// These identities must survive a parent rebuild while the popup is open.
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();

  /// The source keeps BasicComponent's hold-down interaction active for the
  /// complete lifetime of either popup presentation, not only while the
  /// pointer is physically down.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final summary = widget.summary;
    final value = widget.value;
    final entries = widget.entries;
    final onChanged = widget.onChanged;
    void handleChanged(T next) {
      unawaited(MiuixHaptics.perform(MiuixHapticType.confirm));
      onChanged(next);
    }

    final presentation = widget.presentation;
    final enabled = widget.enabled;
    final renderInRootScaffold = widget.renderInRootScaffold;
    final onExpandedChange = widget.onExpandedChange;
    final closeOnSelection = widget.closeOnSelection;
    final dialogConfirmLabel = widget.dialogConfirmLabel;
    MiuixDropdownEntry<T>? selectedEntry;
    var matchCount = 0;
    var hasEnabledEntry = false;
    for (final entry in entries) {
      if (entry.enabled) {
        hasEnabledEntry = true;
      }
      if (entry.value == value) {
        matchCount++;
        selectedEntry ??= entry;
      }
    }
    final canOpen = enabled && entries.isNotEmpty && hasEnabledEntry;
    final semantic = MiuixSemanticColors.of(context);
    final trailingColor = canOpen
        ? semantic['onSurfaceVariantActions']
        : semantic['disabledOnSecondaryVariant'];
    final selectedLabel = matchCount == 1 ? selectedEntry?.label ?? '' : null;
    // Enabled controls whether the menu may open; it does not change the
    // selected-value end action. MIUIX keeps both the value and 10x16 arrow in
    // a disabled preference and only resolves them with disabled colors.
    final showSelectedLabel = widget.showValue && selectedLabel != null;
    final trailing = showSelectedLabel
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                // Compose's 14sp body2 occupies a 17dp Android line box. A
                // fixed box keeps the popup anchor's vertical bounds equal to
                // the source instead of inheriting Flutter's 16.24dp theme
                // line box and ending one physical pixel too high.
                child: SizedBox(
                  height: 17,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      selectedLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: trailingColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _MiuixDropdownArrow(color: trailingColor),
            ],
          )
        : widget.sourceMode
        ? _MiuixDropdownArrow(color: trailingColor)
        : Text(
            hasEnabledEntry ? 'Unavailable' : 'No actions',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: trailingColor, fontSize: 14),
          );
    final popupEntries = [
      for (final entry in entries)
        entry.copyWith(selected: entry.value == value),
    ];
    // In the source the popup composable lives inside BasicComponent's
    // endActions Row. Its parent bounds are therefore the selected value and
    // 10x16 arrow, not the complete 56dp preference row. Linking the trailing
    // action reproduces both the 16dp end inset and the vertical anchor beside
    // the arrow; anchoring the whole preference makes every popup too low.
    final anchoredTrailing = CompositedTransformTarget(
      link: _link,
      child: SizedBox(key: _anchorKey, child: trailing),
    );
    return MiuixPreference(
      title: title,
      summary: summary,
      titleColors: widget.titleColors,
      summaryColors: widget.summaryColors,
      leading: widget.leading,
      bottomAction: widget.bottomAction,
      insideMargin: widget.insideMargin,
      enabled: canOpen,
      holdDown: _expanded,
      onTap: canOpen
          ? () async {
              if (_expanded) {
                return;
              }
              unawaited(MiuixHaptics.perform(MiuixHapticType.contextClick));
              setState(() => _expanded = true);
              onExpandedChange?.call(true);
              try {
                if (dialogConfirmLabel != null) {
                  await _showMiuixSpinnerSelectionDialog<T>(
                    context: context,
                    title: title,
                    entries: popupEntries,
                    value: value,
                    onChanged: handleChanged,
                    presentation: presentation,
                    confirmLabel: dialogConfirmLabel,
                    renderInRootScaffold: renderInRootScaffold,
                  );
                } else {
                  // Compose truncates the body2 trailing text position before
                  // adding its integer line-box height. Flutter retains the
                  // fractional font metrics, which leaves the calculated far
                  // edge one physical pixel lower. Apply the source correction
                  // here once so every dropdown preference, including one in a
                  // nested Scaffold, shares the same popup origin.
                  final density = View.of(context).devicePixelRatio;
                  final physicalLineHeight = 17 * density;
                  // Integer-density layouts already give the 17dp wrapper an
                  // integral edge. Only a fractional physical line box needs
                  // the one-pixel correction produced by Compose's separate
                  // position truncation and measured-height rounding.
                  final needsPhysicalCorrection =
                      (physicalLineHeight - physicalLineHeight.round()).abs() >
                      1e-6;
                  final sourceAnchorOffset = Offset(
                    widget.sourceMode &&
                            presentation == MiuixPopupPresentation.overlay &&
                            !renderInRootScaffold
                        ? 1 / density
                        : 0,
                    needsPhysicalCorrection ? -1 / density : 0,
                  );
                  await _showMiuixDropdownMenu<T>(
                    context: context,
                    entries: popupEntries,
                    onSelected: handleChanged,
                    popupBuilder: widget.sourceMode
                        ? (select) => _MiuixSourceDropdownPreferencePopup<T>(
                            entries: popupEntries,
                            selectedValue: value,
                            colors: widget.dropdownColors,
                            maxHeight: widget.maxHeight,
                            onSelected: select,
                          )
                        : null,
                    presentation: presentation,
                    link: _link,
                    anchorRect: _anchorKey.currentContext == null
                        ? null
                        : _miuixGlobalRect(_anchorKey.currentContext!),
                    alignment: MiuixPopupAlignment.bottomEnd,
                    renderInRootScaffold: renderInRootScaffold,
                    closeOnSelection: closeOnSelection,
                    popupMinWidth: widget.popupMinWidth,
                    popupAnchorOffset:
                        sourceAnchorOffset + widget.popupAnchorOffset,
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _expanded = false);
                }
                onExpandedChange?.call(false);
              }
            }
          : null,
      trailing: anchoredTrailing,
    );
  }
}

// Spinner dialog mode keeps a temporary selection until the user confirms it,
// matching MIUIX `dialogButtonString` rather than treating the dialog as a
// differently positioned dropdown.
Future<void> _showMiuixSpinnerSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<MiuixDropdownEntry<T>> entries,
  required T value,
  required ValueChanged<T> onChanged,
  required MiuixPopupPresentation presentation,
  required String confirmLabel,
  required bool renderInRootScaffold,
}) {
  final host = MiuixPopupHostScope.maybeOf(context);
  final overlayHost = renderInRootScaffold ? host?.root : host;
  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  var pendingValue = value;

  void dismiss() {
    if (presentation == MiuixPopupPresentation.overlay) {
      overlayHost?.dismissTop();
    } else if (navigator?.mounted == true && navigator!.canPop()) {
      navigator.pop();
    }
  }

  final content = StatefulBuilder(
    builder: (dialogContext, setDialogState) {
      return SizedBox(
        height: math.min(420, entries.length * 58 + 64).toDouble(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return _MiuixMenuRow(
                    label: entry.label,
                    summary: entry.summary,
                    icon: entry.icon,
                    enabled: entry.enabled,
                    trailing: entry.value == pendingValue
                        ? const Icon(Icons.check)
                        : null,
                    onTap: entry.enabled
                        ? () => setDialogState(() => pendingValue = entry.value)
                        : null,
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: MiuixButton(
                    label: '取消',
                    filled: false,
                    onPressed: dismiss,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: MiuixButton(
                    label: confirmLabel,
                    onPressed: () {
                      onChanged(pendingValue);
                      dismiss();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  return presentation == MiuixPopupPresentation.overlay
      ? MiuixOverlayDialog.show<void>(
          context: context,
          title: title,
          content: content,
          renderInRootScaffold: renderInRootScaffold,
        )
      : MiuixWindowDialog.show<void>(
          context: context,
          title: title,
          content: content,
        );
}

/// Spinner preference for compact option selection.
class MiuixSpinnerPreference<T> extends MiuixDropdownPreference<T> {
  /// Creates a spinner preference.
  const MiuixSpinnerPreference({
    super.key,
    required super.title,
    required super.value,
    required super.entries,
    required super.onChanged,
    super.summary,
    super.presentation,
    super.enabled,
    super.renderInRootScaffold,
    super.onExpandedChange,
    super.dialogConfirmLabel,
    super.closeOnSelection,
    super.popupMinWidth,
    super.popupAnchorOffset,
  });
}

/// Dropdown preference whose groups keep independent selected entries.
class MiuixGroupedDropdownPreference<T> extends StatefulWidget {
  /// Creates a grouped dropdown or spinner preference.
  const MiuixGroupedDropdownPreference({
    super.key,
    required this.title,
    required this.groups,
    required this.onSelected,
    this.summary,
    this.presentation = MiuixPopupPresentation.window,
    this.enabled = true,
    this.renderInRootScaffold = true,
    this.closeOnSelection = false,
    this.dialogConfirmLabel,
    this.onExpandedChange,
  });

  /// Main preference title.
  final String title;

  /// Optional expansion or mode summary.
  final String? summary;

  /// Independently selectable groups rendered with separators.
  final List<MiuixDropdownGroup<T>> groups;

  /// Receives the value of every enabled row selection.
  final ValueChanged<T> onSelected;

  /// Popup host family.
  final MiuixPopupPresentation presentation;

  /// Whether the preference is interactive.
  final bool enabled;

  /// Whether Overlay presentation uses the outermost scaffold.
  final bool renderInRootScaffold;

  /// Whether a row selection immediately closes the popup.
  final bool closeOnSelection;

  /// Optional dialog confirmation label for grouped spinner mode.
  final String? dialogConfirmLabel;

  /// Called at the start and end of popup visibility.
  final ValueChanged<bool>? onExpandedChange;

  @override
  State<MiuixGroupedDropdownPreference<T>> createState() =>
      _MiuixGroupedDropdownPreferenceState<T>();
}

class _MiuixGroupedDropdownPreferenceState<T>
    extends State<MiuixGroupedDropdownPreference<T>> {
  /// Stable anchoring prevents expansion summaries from unlinking the popup.
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();

  /// Mirrors BasicComponent's persistent hold-down state while expanded.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final summary = widget.summary;
    final groups = widget.groups;
    final onSelected = widget.onSelected;
    void handleSelected(T next) {
      unawaited(MiuixHaptics.perform(MiuixHapticType.confirm));
      onSelected(next);
    }

    final presentation = widget.presentation;
    final enabled = widget.enabled;
    final renderInRootScaffold = widget.renderInRootScaffold;
    final closeOnSelection = widget.closeOnSelection;
    final dialogConfirmLabel = widget.dialogConfirmLabel;
    final onExpandedChange = widget.onExpandedChange;
    final hasEnabledEntry = groups.any(
      (group) => group.entries.any((entry) => entry.enabled),
    );
    final canOpen = enabled && hasEnabledEntry;
    final semantic = MiuixSemanticColors.of(context);
    final color = enabled
        ? semantic['onSurfaceVariantActions']
        : semantic['disabledOnSecondaryVariant'];

    final anchoredTrailing = CompositedTransformTarget(
      link: _link,
      child: SizedBox(
        key: _anchorKey,
        child: _MiuixDropdownArrow(color: color),
      ),
    );
    return MiuixPreference(
      title: title,
      summary: summary,
      enabled: enabled,
      holdDown: _expanded,
      trailing: anchoredTrailing,
      onTap: canOpen
          ? () async {
              if (_expanded) {
                return;
              }
              unawaited(MiuixHaptics.perform(MiuixHapticType.contextClick));
              setState(() => _expanded = true);
              onExpandedChange?.call(true);
              try {
                if (dialogConfirmLabel != null) {
                  await _showMiuixGroupedSelectionDialog<T>(
                    context: context,
                    title: title,
                    groups: groups,
                    onSelected: handleSelected,
                    presentation: presentation,
                    confirmLabel: dialogConfirmLabel,
                    renderInRootScaffold: renderInRootScaffold,
                  );
                } else {
                  await _showMiuixDropdownMenu<T>(
                    context: context,
                    entries: const [],
                    groups: groups,
                    onSelected: handleSelected,
                    presentation: presentation,
                    link: _link,
                    anchorRect: _anchorKey.currentContext == null
                        ? null
                        : _miuixGlobalRect(_anchorKey.currentContext!),
                    alignment: MiuixPopupAlignment.bottomEnd,
                    renderInRootScaffold: renderInRootScaffold,
                    closeOnSelection: closeOnSelection,
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _expanded = false);
                }
                onExpandedChange?.call(false);
              }
            }
          : null,
    );
  }
}

Future<void> _showMiuixGroupedSelectionDialog<T>({
  required BuildContext context,
  required String title,
  required List<MiuixDropdownGroup<T>> groups,
  required ValueChanged<T> onSelected,
  required MiuixPopupPresentation presentation,
  required String confirmLabel,
  required bool renderInRootScaffold,
}) {
  final host = MiuixPopupHostScope.maybeOf(context);
  final overlayHost = renderInRootScaffold ? host?.root : host;
  final navigator = Navigator.maybeOf(context, rootNavigator: true);

  void dismiss() {
    if (presentation == MiuixPopupPresentation.overlay) {
      overlayHost?.dismissTop();
    } else if (navigator?.mounted == true && navigator!.canPop()) {
      navigator.pop();
    }
  }

  final content = SizedBox(
    height: 420,
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: MiuixListPopup<T>(
              entries: const [],
              groups: groups,
              onSelected: onSelected,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: MiuixButton(label: confirmLabel, onPressed: dismiss),
        ),
      ],
    ),
  );
  return presentation == MiuixPopupPresentation.overlay
      ? MiuixOverlayDialog.show<void>(
          context: context,
          title: title,
          content: content,
          renderInRootScaffold: renderInRootScaffold,
        )
      : MiuixWindowDialog.show<void>(
          context: context,
          title: title,
          content: content,
        );
}

/// Overlay-hosted grouped dropdown preference.
class MiuixOverlayGroupedDropdownPreference<T>
    extends MiuixGroupedDropdownPreference<T> {
  /// Creates an overlay grouped dropdown preference.
  const MiuixOverlayGroupedDropdownPreference({
    super.key,
    required super.title,
    required super.groups,
    required super.onSelected,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.closeOnSelection,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-hosted grouped dropdown preference.
class MiuixWindowGroupedDropdownPreference<T>
    extends MiuixGroupedDropdownPreference<T> {
  /// Creates a window grouped dropdown preference.
  const MiuixWindowGroupedDropdownPreference({
    super.key,
    required super.title,
    required super.groups,
    required super.onSelected,
    super.summary,
    super.enabled,
    super.closeOnSelection,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.window);
}

/// Overlay-hosted grouped spinner preference.
class MiuixOverlayGroupedSpinnerPreference<T>
    extends MiuixGroupedDropdownPreference<T> {
  /// Creates an overlay grouped spinner preference.
  const MiuixOverlayGroupedSpinnerPreference({
    super.key,
    required super.title,
    required super.groups,
    required super.onSelected,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.closeOnSelection,
    super.dialogConfirmLabel,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-hosted grouped spinner preference.
class MiuixWindowGroupedSpinnerPreference<T>
    extends MiuixGroupedDropdownPreference<T> {
  /// Creates a window grouped spinner preference.
  const MiuixWindowGroupedSpinnerPreference({
    super.key,
    required super.title,
    required super.groups,
    required super.onSelected,
    super.summary,
    super.enabled,
    super.closeOnSelection,
    super.dialogConfirmLabel,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.window);
}

/// Overlay-named dropdown preference adapter.
class MiuixOverlayDropdownPreference<T> extends MiuixDropdownPreference<T> {
  /// Creates an overlay dropdown preference.
  const MiuixOverlayDropdownPreference({
    super.key,
    required super.title,
    required super.value,
    required super.entries,
    required super.onChanged,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.onExpandedChange,
    super.closeOnSelection,
    super.popupMinWidth,
    super.popupAnchorOffset,
    super.titleColors,
    super.summaryColors,
    super.leading,
    super.bottomAction,
    super.insideMargin,
    super.maxHeight,
    super.showValue,
    super.dropdownColors,
    super.sourceMode,
  }) : super(presentation: MiuixPopupPresentation.overlay);

  /// Creates the exact index-based upstream OverlayDropdownPreference.
  static MiuixOverlayDropdownPreference<int> source({
    Key? key,
    required List<String> items,
    required int selectedIndex,
    required String title,
    MiuixBasicComponentColors? titleColor,
    String? summary,
    MiuixBasicComponentColors? summaryColor,
    MiuixDropdownColors? dropdownColors,
    Widget? startAction,
    Widget? bottomAction,
    EdgeInsetsGeometry insideMargin = MiuixBasicComponentDefaults.insideMargin,
    double? maxHeight,
    bool enabled = true,
    bool showValue = true,
    bool renderInRootScaffold = true,
    ValueChanged<int>? onSelectedIndexChange,
  }) {
    assert(
      items.isEmpty || (selectedIndex >= 0 && selectedIndex < items.length),
      'selectedIndex must identify an item when items is not empty.',
    );
    return MiuixOverlayDropdownPreference<int>(
      key: key,
      title: title,
      value: selectedIndex,
      entries: [
        for (var index = 0; index < items.length; index++)
          MiuixDropdownEntry<int>(value: index, label: items[index]),
      ],
      onChanged: (index) => onSelectedIndexChange?.call(index),
      titleColors: titleColor,
      summary: summary,
      summaryColors: summaryColor,
      dropdownColors: dropdownColors,
      leading: startAction,
      bottomAction: bottomAction,
      insideMargin: insideMargin,
      maxHeight: maxHeight,
      enabled: enabled,
      showValue: showValue,
      renderInRootScaffold: renderInRootScaffold,
      sourceMode: true,
    );
  }
}

/// Window-named dropdown preference adapter.
class MiuixWindowDropdownPreference<T> extends MiuixDropdownPreference<T> {
  /// Creates a window dropdown preference.
  const MiuixWindowDropdownPreference({
    super.key,
    required super.title,
    required super.value,
    required super.entries,
    required super.onChanged,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.onExpandedChange,
    super.closeOnSelection,
    super.popupMinWidth,
    super.popupAnchorOffset,
    super.titleColors,
    super.summaryColors,
    super.leading,
    super.bottomAction,
    super.insideMargin,
    super.maxHeight,
    super.showValue,
    super.dropdownColors,
    super.sourceMode,
  }) : super(presentation: MiuixPopupPresentation.window);

  /// Creates the exact index-based upstream WindowDropdownPreference.
  static MiuixWindowDropdownPreference<int> source({
    Key? key,
    required List<String> items,
    required int selectedIndex,
    required String title,
    MiuixBasicComponentColors? titleColor,
    String? summary,
    MiuixBasicComponentColors? summaryColor,
    MiuixDropdownColors? dropdownColors,
    Widget? startAction,
    Widget? bottomAction,
    EdgeInsetsGeometry insideMargin = MiuixBasicComponentDefaults.insideMargin,
    double? maxHeight,
    bool enabled = true,
    bool showValue = true,
    ValueChanged<int>? onSelectedIndexChange,
  }) {
    assert(
      items.isEmpty || (selectedIndex >= 0 && selectedIndex < items.length),
      'selectedIndex must identify an item when items is not empty.',
    );
    return MiuixWindowDropdownPreference<int>(
      key: key,
      title: title,
      value: selectedIndex,
      entries: [
        for (var index = 0; index < items.length; index++)
          MiuixDropdownEntry<int>(value: index, label: items[index]),
      ],
      onChanged: (index) => onSelectedIndexChange?.call(index),
      titleColors: titleColor,
      summary: summary,
      summaryColors: summaryColor,
      dropdownColors: dropdownColors,
      leading: startAction,
      bottomAction: bottomAction,
      insideMargin: insideMargin,
      maxHeight: maxHeight,
      enabled: enabled,
      showValue: showValue,
      sourceMode: true,
    );
  }
}

/// Source ListPopupColumn used by dropdown preferences.
///
/// The generic compatibility popup supports disabled rows, summaries, icons,
/// and independent groups. The upstream preference instead supplies only a
/// String list and builds DropdownImpl directly for every index.
class _MiuixSourceDropdownPreferencePopup<T> extends StatelessWidget {
  const _MiuixSourceDropdownPreferencePopup({
    required this.entries,
    required this.selectedValue,
    required this.onSelected,
    this.colors,
    this.maxHeight,
  });

  final List<MiuixDropdownEntry<T>> entries;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final MiuixDropdownColors? colors;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final resolvedColors = colors ?? MiuixDropdownDefaults.colors(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: MiuixListPopupDefaults.minWidth,
        maxWidth: MiuixListPopupDefaults.maxWidth,
        maxHeight: maxHeight ?? double.infinity,
      ),
      child: MiuixSurface(
        padding: EdgeInsets.zero,
        radius: MiuixListPopupDefaults.cornerRadius,
        color: resolvedColors.containerColor,
        child: MiuixListPopupColumn(
          children: [
            for (var index = 0; index < entries.length; index++)
              MiuixDropdownImpl(
                text: entries[index].label,
                optionSize: entries.length,
                isSelected: entries[index].value == selectedValue,
                index: index,
                colors: resolvedColors,
                onSelectedIndexChange: (selectedIndex) =>
                    onSelected(entries[selectedIndex].value),
              ),
          ],
        ),
      ),
    );
  }
}

/// Overlay-named spinner preference adapter.
class MiuixOverlaySpinnerPreference<T> extends MiuixSpinnerPreference<T> {
  /// Creates an overlay spinner preference.
  const MiuixOverlaySpinnerPreference({
    super.key,
    required super.title,
    required super.value,
    required super.entries,
    required super.onChanged,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.onExpandedChange,
    super.dialogConfirmLabel,
    super.closeOnSelection,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-named spinner preference adapter.
class MiuixWindowSpinnerPreference<T> extends MiuixSpinnerPreference<T> {
  /// Creates a window spinner preference.
  const MiuixWindowSpinnerPreference({
    super.key,
    required super.title,
    required super.value,
    required super.entries,
    required super.onChanged,
    super.summary,
    super.enabled,
    super.renderInRootScaffold,
    super.onExpandedChange,
    super.dialogConfirmLabel,
    super.closeOnSelection,
  }) : super(presentation: MiuixPopupPresentation.window);
}

/// Exact 10x16 end action used by Dropdown.kt.
///
/// Material's `unfold_more` reserves a square 20dp icon box and uses a
/// different stroke silhouette. The source vector is only 10dp wide, with two
/// rounded chevrons occupying the top and bottom halves. A tiny painter keeps
/// that geometry independent of the platform Material icon font.
class _MiuixDropdownArrow extends StatelessWidget {
  const _MiuixDropdownArrow({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(10, 16),
    painter: _MiuixDropdownArrowPainter(color),
  );
}

class _MiuixDropdownArrowPainter extends CustomPainter {
  const _MiuixDropdownArrowPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // ArrowUpDown.kt uses a roughly 1.52dp rounded stroke over a 10x16
    // viewport. Drawing the center lines reproduces its filled curved path
    // while avoiding scale-dependent Icon font bearings.
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.52
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final up = Path()
      ..moveTo(.92, 5.13)
      ..lineTo(5, 1.05)
      ..lineTo(9.08, 5.13);
    final down = Path()
      ..moveTo(.92, 10.87)
      ..lineTo(5, 14.95)
      ..lineTo(9.08, 10.87);
    canvas
      ..drawPath(up, paint)
      ..drawPath(down, paint);
  }

  @override
  bool shouldRepaint(covariant _MiuixDropdownArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
