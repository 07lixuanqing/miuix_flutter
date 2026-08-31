part of 'main.dart';

/// Standard card wrapper used by original home-page sections.
class _ReferenceSectionCard extends StatelessWidget {
  const _ReferenceSectionCard({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.cardKey,
  });

  final String title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixSmallTitle(title, insideMargin: _referencePageSmallTitlePadding),
        MiuixCard(
          key: cardKey,
          margin: const EdgeInsets.only(bottom: 12),
          padding: padding,
          child: child,
        ),
      ],
    );
  }
}

/// Overlay/window dropdown variants in the same order as the source sample.
class _ReferenceDropdownSection extends StatefulWidget {
  const _ReferenceDropdownSection();

  @override
  State<_ReferenceDropdownSection> createState() =>
      _ReferenceDropdownSectionState();
}

class _ReferenceDropdownSectionState extends State<_ReferenceDropdownSection> {
  static const _items = ['选项一', '选项二', '选项三', '选项四'];
  static const _longItems = [
    '选项一',
    '非常长选项二',
    '非常长非常长选项三',
    '非常长非常长非常长选项四',
    '非常长非常长非常长非常长选项五',
    '非常长非常长非常长非常长非常长选项六',
    '非常长非常长非常长非常长非常长非常长选项七',
    '非常长非常长非常长非常长非常长非常长非常长选项八',
    '非常长非常长非常长非常长非常长非常长非常长非常长选项九',
    '非常长非常长非常长非常长非常长非常长非常长非常长非常长选项十',
    '非常长非常长非常长非常长非常长非常长非常长非常长非常长非常长选项十一',
    '非常长非常长非常长非常长非常长非常长非常长非常长非常长非常长非常长选项十二',
  ];

  int _overlay = 0;
  int _window = 0;
  int _overlayGroupA = 0;
  int _overlayGroupB = 0;
  int _overlayGroupC = 0;
  int _windowGroupA = 0;
  int _windowGroupB = 0;
  int _windowGroupC = 0;
  bool _overlayExpanded = false;
  bool _windowExpanded = false;
  bool _overlayGroupedExpanded = false;
  bool _windowGroupedExpanded = false;

  /// Builds the three independent source groups for one popup host.
  ///
  /// Values carry their host and group so one callback can update the exact
  /// state slot while the labels remain fully localized. Group C deliberately
  /// disables its odd zero-based rows, matching `index % 2 == 0` upstream.
  List<MiuixDropdownGroup<String>> _groups(
    String host,
    int selectedA,
    int selectedB,
    int selectedC,
  ) => [
    MiuixDropdownGroup(
      entries: [
        for (var index = 0; index < 2; index++)
          MiuixDropdownEntry(
            value: '$host:a:$index',
            label: '选项 A-${index + 1}',
            selected: selectedA == index,
          ),
      ],
    ),
    MiuixDropdownGroup(
      entries: [
        for (var index = 0; index < 3; index++)
          MiuixDropdownEntry(
            value: '$host:b:$index',
            label: '选项 B-${index + 1}',
            selected: selectedB == index,
          ),
      ],
    ),
    MiuixDropdownGroup(
      entries: [
        for (var index = 0; index < 4; index++)
          MiuixDropdownEntry(
            value: '$host:c:$index',
            label: '选项 C-${index + 1}',
            enabled: index.isEven,
            selected: selectedC == index,
          ),
      ],
    ),
  ];

  /// Applies one grouped selection without coupling Overlay and Window state.
  void _selectGrouped(String encoded) {
    final parts = encoded.split(':');
    final host = parts[0];
    final group = parts[1];
    final index = int.parse(parts[2]);
    setState(() {
      if (host == 'overlay') {
        if (group == 'a') _overlayGroupA = index;
        if (group == 'b') _overlayGroupB = index;
        if (group == 'c') _overlayGroupC = index;
      } else {
        if (group == 'a') _windowGroupA = index;
        if (group == 'b') _windowGroupB = index;
        if (group == 'c') _windowGroupC = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '下拉菜单',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-dropdown-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixOverlayDropdownPreference.source(
                key: const ValueKey('reference-dropdown-overlay'),
                title: '下拉偏好（O）',
                summary: _overlayExpanded ? '已展开' : '已收起',
                selectedIndex: _overlay,
                items: _items,
                onExpandedChange: (expanded) =>
                    setState(() => _overlayExpanded = expanded),
                onSelectedIndexChange: (index) =>
                    setState(() => _overlay = index),
              ),
              MiuixWindowDropdownPreference.source(
                key: const ValueKey('reference-dropdown-window'),
                title: '下拉偏好（W）',
                summary: _windowExpanded ? '已展开' : '已收起',
                selectedIndex: _window,
                items: _longItems,
                onExpandedChange: (expanded) =>
                    setState(() => _windowExpanded = expanded),
                onSelectedIndexChange: (index) =>
                    setState(() => _window = index),
              ),
              MiuixOverlayGroupedDropdownPreference.source<String>(
                key: const ValueKey('reference-dropdown-grouped-overlay'),
                title: '分组下拉偏好（O）',
                summary: _overlayGroupedExpanded ? '已展开' : '已收起',
                groups: _groups(
                  'overlay',
                  _overlayGroupA,
                  _overlayGroupB,
                  _overlayGroupC,
                ),
                onExpandedChange: (expanded) =>
                    setState(() => _overlayGroupedExpanded = expanded),
                onSelected: _selectGrouped,
              ),
              MiuixWindowGroupedDropdownPreference.source<String>(
                key: const ValueKey('reference-dropdown-grouped-window'),
                title: '分组下拉偏好（W）',
                summary: _windowGroupedExpanded ? '已展开' : '已收起',
                groups: _groups(
                  'window',
                  _windowGroupA,
                  _windowGroupB,
                  _windowGroupC,
                ),
                onExpandedChange: (expanded) =>
                    setState(() => _windowGroupedExpanded = expanded),
                onSelected: _selectGrouped,
              ),
              MiuixOverlayDropdownPreference.source(
                key: const ValueKey('reference-dropdown-disabled-overlay'),
                title: '禁用下拉偏好（O）',
                selectedIndex: 0,
                items: const ['选项一'],
                enabled: false,
                onSelectedIndexChange: (_) {},
              ),
              MiuixWindowDropdownPreference.source(
                key: const ValueKey('reference-dropdown-disabled-window'),
                title: '禁用下拉偏好（W）',
                selectedIndex: 0,
                items: const ['选项一'],
                enabled: false,
                onSelectedIndexChange: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Spinner variants corresponding to the source sample's second popup group.
class _ReferenceSpinnerSection extends StatefulWidget {
  const _ReferenceSpinnerSection();

  @override
  State<_ReferenceSpinnerSection> createState() =>
      _ReferenceSpinnerSectionState();
}

class _ReferenceSpinnerSectionState extends State<_ReferenceSpinnerSection> {
  static const _entries = [
    MiuixSpinnerEntry(
      title: '选项一',
      summary: '红色',
      icon: _ReferenceSpinnerSwatch(Color(0xFFFF5B29)),
    ),
    MiuixSpinnerEntry(
      title: '选项二',
      summary: '绿色',
      icon: _ReferenceSpinnerSwatch(Color(0xFF36D167)),
    ),
    MiuixSpinnerEntry(
      title: '选项三',
      summary: '蓝色',
      icon: _ReferenceSpinnerSwatch(Color(0xFF3482FF)),
    ),
    MiuixSpinnerEntry(
      title: '选项四',
      summary: '黄色',
      icon: _ReferenceSpinnerSwatch(Color(0xFFFFB21D)),
    ),
  ];

  int _overlay = 0;
  int _window = 1;
  int _overlayDialog = 2;
  int _windowDialog = 3;
  bool _overlayExpanded = false;
  bool _windowExpanded = false;
  bool _overlayDialogExpanded = false;
  bool _windowDialogExpanded = false;
  bool _overlayGroupedExpanded = false;
  bool _windowGroupedExpanded = false;
  bool _overlayGroupedDialogExpanded = false;
  bool _windowGroupedDialogExpanded = false;
  final _overlayGrouped = <int>[0, 0, 0];
  final _windowGrouped = <int>[0, 0, 0];
  final _overlayGroupedDialog = <int>[0, 0, 0];
  final _windowGroupedDialog = <int>[0, 0, 0];

  List<MiuixDropdownGroup<(int, int)>> _groups(List<int> selected) {
    List<MiuixDropdownEntry<(int, int)>> entriesFor(
      int group,
      Iterable<int> indexes,
    ) {
      final sourceIndexes = indexes.toList(growable: false);
      return [
        for (
          var localIndex = 0;
          localIndex < sourceIndexes.length;
          localIndex++
        )
          MiuixDropdownEntry<(int, int)>(
            value: (group, localIndex),
            label: _entries[sourceIndexes[localIndex]].title!,
            summary: _entries[sourceIndexes[localIndex]].summary,
            icon: _entries[sourceIndexes[localIndex]].icon,
            enabled: group != 2 || localIndex.isEven,
            selected: selected[group] == localIndex,
          ),
      ];
    }

    return [
      MiuixDropdownGroup(entries: entriesFor(0, const [0, 1])),
      MiuixDropdownGroup(entries: entriesFor(1, const [2, 3])),
      MiuixDropdownGroup(entries: entriesFor(2, const [0, 1, 2, 3])),
    ];
  }

  void _selectGrouped(List<int> selected, (int, int) value) {
    setState(() => selected[value.$1] = value.$2);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '选择器',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-spinner-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixOverlaySpinnerPreference.source(
                key: const ValueKey('reference-spinner-popup-overlay'),
                title: '选择器偏好（O）',
                summary: _overlayExpanded ? '已展开' : '已收起',
                selectedIndex: _overlay,
                items: _entries,
                onSelectedIndexChange: (value) =>
                    setState(() => _overlay = value),
                onExpandedChange: (value) =>
                    setState(() => _overlayExpanded = value),
              ),
              MiuixWindowSpinnerPreference.source(
                key: const ValueKey('reference-spinner-popup-window'),
                title: '选择器偏好（W）',
                summary: _windowExpanded ? '已展开' : '已收起',
                selectedIndex: _window,
                items: _entries,
                onSelectedIndexChange: (value) =>
                    setState(() => _window = value),
                onExpandedChange: (value) =>
                    setState(() => _windowExpanded = value),
              ),
              MiuixOverlaySpinnerPreference.source(
                key: const ValueKey('reference-spinner-dialog-overlay'),
                title: '选择器偏好（O）',
                summary:
                    '作为对话框（O）${_overlayDialogExpanded ? '（已展开）' : '（已收起）'}',
                selectedIndex: _overlayDialog,
                items: _entries,
                onSelectedIndexChange: (value) =>
                    setState(() => _overlayDialog = value),
                onExpandedChange: (value) =>
                    setState(() => _overlayDialogExpanded = value),
                dialogButtonString: '确定',
              ),
              MiuixWindowSpinnerPreference.source(
                key: const ValueKey('reference-spinner-dialog-window'),
                title: '选择器偏好（W）',
                summary: '作为对话框（W）${_windowDialogExpanded ? '（已展开）' : '（已收起）'}',
                selectedIndex: _windowDialog,
                items: _entries,
                onSelectedIndexChange: (value) =>
                    setState(() => _windowDialog = value),
                onExpandedChange: (value) =>
                    setState(() => _windowDialogExpanded = value),
                dialogButtonString: '确定',
              ),
              MiuixOverlayGroupedSpinnerPreference.source<(int, int)>(
                key: const ValueKey('reference-spinner-grouped-overlay'),
                title: '分组选择器偏好（O）',
                summary: _overlayGroupedExpanded ? '已展开' : '已收起',
                groups: _groups(_overlayGrouped),
                closeOnSelection: false,
                onSelected: (value) => _selectGrouped(_overlayGrouped, value),
                onExpandedChange: (value) =>
                    setState(() => _overlayGroupedExpanded = value),
              ),
              MiuixWindowGroupedSpinnerPreference.source<(int, int)>(
                key: const ValueKey('reference-spinner-grouped-window'),
                title: '分组选择器偏好（W）',
                summary: _windowGroupedExpanded ? '已展开' : '已收起',
                groups: _groups(_windowGrouped),
                closeOnSelection: false,
                onSelected: (value) => _selectGrouped(_windowGrouped, value),
                onExpandedChange: (value) =>
                    setState(() => _windowGroupedExpanded = value),
              ),
              MiuixOverlayGroupedSpinnerPreference.source<(int, int)>(
                key: const ValueKey('reference-spinner-grouped-dialog-overlay'),
                title: '分组选择器偏好（O）',
                summary:
                    '作为对话框（O）${_overlayGroupedDialogExpanded ? '（已展开）' : '（已收起）'}',
                groups: _groups(_overlayGroupedDialog),
                dialogButtonString: '确定',
                onSelected: (value) =>
                    _selectGrouped(_overlayGroupedDialog, value),
                onExpandedChange: (value) =>
                    setState(() => _overlayGroupedDialogExpanded = value),
              ),
              MiuixWindowGroupedSpinnerPreference.source<(int, int)>(
                key: const ValueKey('reference-spinner-grouped-dialog-window'),
                title: '分组选择器偏好（W）',
                summary:
                    '作为对话框（W）${_windowGroupedDialogExpanded ? '（已展开）' : '（已收起）'}',
                groups: _groups(_windowGroupedDialog),
                dialogButtonString: '确定',
                onSelected: (value) =>
                    _selectGrouped(_windowGroupedDialog, value),
                onExpandedChange: (value) =>
                    setState(() => _windowGroupedDialogExpanded = value),
              ),
              MiuixOverlaySpinnerPreference.source(
                key: const ValueKey('reference-spinner-disabled-overlay'),
                title: '禁用的选择器偏好（O）',
                summary: '已收起',
                selectedIndex: 0,
                items: const [MiuixSpinnerEntry(title: '选项五')],
                enabled: false,
                onSelectedIndexChange: (_) {},
              ),
              MiuixWindowSpinnerPreference.source(
                key: const ValueKey('reference-spinner-disabled-window'),
                title: '禁用的选择器偏好（W）',
                summary: '已收起',
                selectedIndex: 0,
                items: const [MiuixSpinnerEntry(title: '选项六')],
                enabled: false,
                onSelectedIndexChange: (_) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Exact 24dp, 6dp-radius painter used by the source SpinnerSection entries.
class _ReferenceSpinnerSwatch extends StatelessWidget {
  const _ReferenceSpinnerSwatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

/// Four input-field states shown by the original TextField section.
class _ReferenceTextFieldSection extends StatefulWidget {
  const _ReferenceTextFieldSection();

  @override
  State<_ReferenceTextFieldSection> createState() =>
      _ReferenceTextFieldSectionState();
}

class _ReferenceTextFieldSectionState
    extends State<_ReferenceTextFieldSection> {
  final _plain = TextEditingController();
  final _titled = TextEditingController();
  final _stateBased = TextEditingController();
  final _placeholder = TextEditingController();

  @override
  void dispose() {
    _plain.dispose();
    _titled.dispose();
    _stateBased.dispose();
    _placeholder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sourceSpacing = _referenceRoundedDp(context, 12);
    void finishEditing(String _) => FocusScope.of(context).unfocus();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '文本框',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixTextField.source(
          key: const ValueKey('reference-text-field-plain'),
          controller: _plain,
          keyboardOptions: TextInputAction.done,
          onKeyboardAction: finishEditing,
        ),
        SizedBox(height: sourceSpacing),
        MiuixTextField.source(
          key: const ValueKey('reference-text-field-titled'),
          controller: _titled,
          label: '带标题',
          keyboardOptions: TextInputAction.done,
          onKeyboardAction: finishEditing,
        ),
        SizedBox(height: sourceSpacing),
        MiuixTextField.source(
          key: const ValueKey('reference-text-field-state'),
          controller: _stateBased,
          label: '状态式文本框',
          keyboardOptions: TextInputAction.done,
          onKeyboardAction: finishEditing,
        ),
        SizedBox(height: sourceSpacing),
        MiuixTextField.source(
          key: const ValueKey('reference-text-field-placeholder'),
          controller: _placeholder,
          label: '占位标题与单行输入',
          useLabelAsPlaceholder: true,
          singleLine: true,
          keyboardOptions: TextInputAction.done,
          onKeyboardAction: finishEditing,
        ),
        SizedBox(height: sourceSpacing),
      ],
    );
  }
}

/// Horizontal, range, and vertical slider states from the source sample.
class _ReferenceSliderSection extends StatefulWidget {
  const _ReferenceSliderSection();

  @override
  State<_ReferenceSliderSection> createState() =>
      _ReferenceSliderSectionState();
}

class _ReferenceSliderSectionState extends State<_ReferenceSliderSection> {
  double _normal = .3;
  double _steps = 100;
  double _points = 5;
  double _custom = 25;
  RangeValues _range = const RangeValues(.2, .8);
  RangeValues _rangeSteps = const RangeValues(2, 8);
  RangeValues _customRange = const RangeValues(20, 80);
  final List<double> _vertical = [.3, 5, 5, 50, .7];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MiuixSmallTitle(
          '滑块',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-slider-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixSliderPreference.source(
                value: _normal,
                onValueChange: (value) => setState(() => _normal = value),
                title: '普通',
                valueText: '${(_normal * 100).truncate()}%',
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixSliderPreference.source(
                value: _steps,
                onValueChange: (value) => setState(() => _steps = value),
                title: '分段',
                valueText: '${_steps.truncate()}/200',
                min: 0,
                max: 200,
                steps: 199,
                hapticEffect: MiuixSliderHapticEffect.step,
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixSliderPreference.source(
                value: _points,
                onValueChange: (value) => setState(() => _points = value),
                title: '带关键点的分段',
                valueText: '${_points.truncate()}/8',
                min: 0,
                max: 8,
                steps: 7,
                hapticEffect: MiuixSliderHapticEffect.step,
                showKeyPoints: true,
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixSliderPreference.source(
                value: _custom,
                onValueChange: (value) => setState(() => _custom = value),
                title: '自定义关键点',
                valueText: '${_custom.truncate()}%',
                min: 0,
                max: 100,
                hapticEffect: MiuixSliderHapticEffect.step,
                showKeyPoints: true,
                keyPoints: const [0, 25, 50, 75, 100],
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixSliderPreference.source(
                value: .7,
                onValueChange: (_) {},
                title: '禁用',
                valueText: '70%',
                enabled: false,
              ),
            ],
          ),
        ),
        const MiuixSmallTitle(
          '范围滑块',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-range-slider-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              MiuixRangeSliderPreference.source(
                value: _range,
                onValueChange: (value) => setState(() => _range = value),
                title: '范围',
                valueText:
                    '${(_range.start * 100).truncate()}% - '
                    '${(_range.end * 100).truncate()}%',
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixRangeSliderPreference.source(
                value: _rangeSteps,
                onValueChange: (value) => setState(() => _rangeSteps = value),
                title: '带关键点的范围',
                valueText:
                    '${_rangeSteps.start.truncate()} - '
                    '${_rangeSteps.end.truncate()}',
                min: 0,
                max: 8,
                steps: 7,
                hapticEffect: MiuixSliderHapticEffect.step,
                showKeyPoints: true,
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixRangeSliderPreference.source(
                value: _customRange,
                onValueChange: (value) => setState(() => _customRange = value),
                title: '自定义范围点',
                valueText:
                    '${_customRange.start.truncate()}% - '
                    '${_customRange.end.truncate()}%',
                min: 0,
                max: 100,
                hapticEffect: MiuixSliderHapticEffect.step,
                showKeyPoints: true,
                keyPoints: const [0, 20, 40, 60, 80, 100],
                insideMargin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              ),
              MiuixRangeSliderPreference.source(
                value: const RangeValues(.3, .7),
                onValueChange: (_) {},
                title: '禁用',
                valueText: '30% - 70%',
                enabled: false,
              ),
            ],
          ),
        ),
        const MiuixSmallTitle(
          '垂直滑块',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: const ValueKey('reference-vertical-slider-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _verticalSlider(
                '普通\n${(_vertical[0] * 100).truncate()}%',
                0,
                min: 0,
                max: 1,
              ),
              _verticalSlider(
                '分段\n${_vertical[1].truncate()}/6',
                1,
                min: 0,
                max: 6,
                divisions: 6,
              ),
              _verticalSlider(
                '关键点\n${_vertical[2].truncate()}/6',
                2,
                min: 0,
                max: 6,
                divisions: 6,
                showKeyPoints: true,
              ),
              _verticalSlider(
                '自定义\n${_vertical[3].truncate()}%',
                3,
                min: 0,
                max: 100,
                showKeyPoints: true,
                keyPoints: const [0, 25, 50, 75, 100],
              ),
              _verticalSlider('禁用\n70%', 4, min: 0, max: 1, enabled: false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _verticalSlider(
    String label,
    int index, {
    required double min,
    required double max,
    int? divisions,
    bool showKeyPoints = false,
    List<double> keyPoints = const <double>[],
    bool enabled = true,
  }) {
    return Expanded(
      child: Column(
        children: [
          MiuixVerticalSlider(
            value: _vertical[index],
            min: min,
            max: max,
            divisions: divisions,
            showKeyPoints: showKeyPoints,
            keyPoints: keyPoints,
            height: _referenceRoundedDp(context, 160),
            width: _referenceRoundedDp(context, 25),
            hapticEffect: divisions != null || showKeyPoints
                ? MiuixSliderHapticEffect.step
                : MiuixSliderHapticEffect.edge,
            enabled: enabled,
            onChanged: enabled
                ? (value) => setState(() => _vertical[index] = value)
                : (_) {},
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Time-style dual wheel from the original NumberPicker example.
class _ReferenceNumberPickerSection extends StatefulWidget {
  const _ReferenceNumberPickerSection();

  @override
  State<_ReferenceNumberPickerSection> createState() =>
      _ReferenceNumberPickerSectionState();
}

class _ReferenceNumberPickerSectionState
    extends State<_ReferenceNumberPickerSection> {
  int _hour = 16;
  int _minute = 30;

  @override
  Widget build(BuildContext context) {
    const colonStyle = TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
    final density = MediaQuery.devicePixelRatioOf(context);
    final colonPainter = TextPainter(
      text: TextSpan(
        text: ':',
        style: DefaultTextStyle.of(context).style.merge(colonStyle),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    // Compose encloses text placeables on physical-pixel boundaries. The
    // Android Flutter paragraph retains its fractional advance, so round the
    // complete glyph width up before the neighboring weights are allocated.
    final colonWidth = density.isFinite && density > 0
        ? (colonPainter.width * density).ceilToDouble() / density
        : colonPainter.width;
    colonPainter.dispose();
    return _ReferenceSectionCard(
      title: '数字选择器',
      cardKey: const ValueKey('reference-number-picker-card'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bounded = constraints.maxWidth.isFinite && density > 0;
          final totalPhysical = bounded
              ? (constraints.maxWidth * density).round()
              : 0;
          final colonPhysical = bounded ? (colonWidth * density).round() : 0;
          final weightedPhysical = bounded
              ? math.max(0, totalPhysical - colonPhysical)
              : 0;
          // Compose Row distributes weighted children as integer placeables.
          // For the 937px remainder at 420dpi, the first wheel receives 468px
          // and the trailing wheel receives the final 469px remainder.
          final hourWidth = bounded
              ? (weightedPhysical ~/ 2) / density
              : double.infinity;
          final minuteWidth = bounded
              ? (weightedPhysical - weightedPhysical ~/ 2) / density
              : double.infinity;
          return Row(
            children: [
              SizedBox(
                width: hourWidth,
                child: MiuixNumberPicker(
                  value: _hour,
                  min: 0,
                  max: 23,
                  wrapAround: true,
                  label: (value) => value.toString().padLeft(2, '0'),
                  onChanged: (value) => setState(() => _hour = value),
                ),
              ),
              SizedBox(
                key: const ValueKey('reference-number-picker-colon'),
                width: colonWidth,
                child: const Text(':', style: colonStyle),
              ),
              SizedBox(
                width: minuteWidth,
                child: MiuixNumberPicker(
                  value: _minute,
                  min: 0,
                  max: 59,
                  wrapAround: true,
                  label: (value) => value.toString().padLeft(2, '0'),
                  onChanged: (value) => setState(() => _minute = value),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// HSV, OKHSV, OKLAB, OKLCH, and palette variants in source order.
class _ReferenceColorPickerSection extends StatefulWidget {
  const _ReferenceColorPickerSection();

  @override
  State<_ReferenceColorPickerSection> createState() =>
      _ReferenceColorPickerSectionState();
}

class _ReferenceColorPickerSectionState
    extends State<_ReferenceColorPickerSection> {
  late final Map<MiuixColorSpace, Color> _colors;
  late final Map<MiuixColorSpace, TextEditingController> _hexControllers;
  late Color _paletteColor;
  late final TextEditingController _paletteHex;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    // Compose initializes every picker from MiuixTheme.colorScheme.primary.
    // Resolve the equivalent Material color only once so later user edits are
    // preserved when inherited widgets rebuild.
    final primary = Theme.of(context).colorScheme.primary;
    _colors = {for (final space in MiuixColorSpace.values) space: primary};
    _hexControllers = {
      for (final space in MiuixColorSpace.values)
        space: TextEditingController(text: _hex(primary)),
    };
    _paletteColor = primary;
    _paletteHex = TextEditingController(text: _hex(_paletteColor));
    _initialized = true;
  }

  @override
  void dispose() {
    for (final controller in _hexControllers.values) {
      controller.dispose();
    }
    _paletteHex.dispose();
    super.dispose();
  }

  static String _hex(Color color) {
    return color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase();
  }

  static String _rgba(Color color) {
    // ColorPickerSection.kt converts RGB channels with Float.toInt(), which
    // truncates instead of rounding. Its alpha expression rounds to two
    // decimal places and then interpolates the resulting Double, so whole
    // values retain one decimal (`1.0`) while `0.45` is not padded to `0.45`.
    final alpha = (color.a * 100).round() / 100.0;
    return 'RGBA：${(color.r * 255).truncate()}，'
        '${(color.g * 255).truncate()}，${(color.b * 255).truncate()}，$alpha';
  }

  Widget _sourceBodyLine(BuildContext context, String text) {
    final themeStyle =
        Theme.of(context).textTheme.bodyLarge ??
        const TextStyle(fontSize: 17, height: 1.16);
    final scaledFontSize = MediaQuery.textScalerOf(
      context,
    ).scale(themeStyle.fontSize ?? 17);
    final sourceLineHeight = _referenceRoundedDp(
      context,
      scaledFontSize * (themeStyle.height ?? 1.16),
    );
    final sourceHeightRatio = sourceLineHeight / scaledFontSize;
    final sourceStyle = themeStyle.copyWith(height: sourceHeightRatio);
    final sourceStrut = StrutStyle(
      fontSize: themeStyle.fontSize ?? 17,
      height: sourceHeightRatio,
      forceStrutHeight: true,
    );
    return SizedBox(
      height: sourceLineHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          style: sourceStyle,
          strutStyle: sourceStrut,
        ),
      ),
    );
  }

  void _updateSpace(MiuixColorSpace space, Color color) {
    setState(() => _colors[space] = color);
    _hexControllers[space]!.text = _hex(color);
  }

  void _parseHex(String value, ValueChanged<Color> update) {
    final cleaned = value.replaceAll(RegExp('[^0-9a-fA-F]'), '').toUpperCase();
    if (cleaned.length == 8) {
      final parsed = int.tryParse(cleaned, radix: 16);
      if (parsed != null) {
        update(Color(parsed));
      }
    }
  }

  Widget _pickerCard(BuildContext context, MiuixColorSpace space) {
    final color = _colors[space]!;
    final sourceSpacing = _referenceRoundedDp(context, 12);
    return _ReferenceSectionCard(
      title: '颜色选择器（${space.name.toUpperCase()}）',
      cardKey: ValueKey('reference-color-picker-${space.name}-card'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sourceBodyLine(context, _rgba(color)),
          SizedBox(height: sourceSpacing),
          MiuixColorPicker.source(
            color: color,
            colorSpace: space,
            showPreview: false,
            onColorChanged: (value) => _updateSpace(space, value),
          ),
          SizedBox(height: sourceSpacing),
          MiuixTextField.source(
            controller: _hexControllers[space]!,
            leadingIcon: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: _sourceBodyLine(context, 'HEX：#'),
            ),
            singleLine: true,
            inputTransformation: const [_ReferenceHexInputFormatter()],
            onValueChange: (value) =>
                _parseHex(value, (color) => _updateSpace(space, color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sourceSpacing = _referenceRoundedDp(context, 12);
    return Column(
      children: [
        for (final space in MiuixColorSpace.values) _pickerCard(context, space),
        _ReferenceSectionCard(
          title: '调色板',
          cardKey: const ValueKey('reference-color-palette-card'),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sourceBodyLine(context, _rgba(_paletteColor)),
              SizedBox(height: sourceSpacing),
              MiuixColorPalette.source(
                color: _paletteColor,
                showPreview: false,
                onColorChanged: (value) {
                  setState(() => _paletteColor = value);
                  _paletteHex.text = _hex(value);
                },
              ),
              SizedBox(height: sourceSpacing),
              MiuixTextField.source(
                controller: _paletteHex,
                leadingIcon: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _sourceBodyLine(context, 'HEX：#'),
                ),
                singleLine: true,
                inputTransformation: const [_ReferenceHexInputFormatter()],
                onValueChange: (value) => _parseHex(value, (color) {
                  setState(() => _paletteColor = color);
                  _paletteHex.text = _hex(color);
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Controlled hexadecimal edit rule from ColorPickerSection.kt.
///
/// Compose rejects the complete proposed value when it exceeds eight
/// characters or contains any non-hexadecimal character, and uppercases every
/// accepted proposal before storing it. A filtering formatter would instead
/// silently remove just the invalid characters, which is observably different.
class _ReferenceHexInputFormatter extends TextInputFormatter {
  const _ReferenceHexInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.length > 8 ||
        text.runes.any(
          (code) =>
              !(code >= 48 && code <= 57) &&
              !(code >= 65 && code <= 70) &&
              !(code >= 97 && code <= 102),
        )) {
      return oldValue;
    }
    return newValue.copyWith(text: text.toUpperCase());
  }
}
