part of 'main.dart';

/// Demonstrates the package-owned calendar views added beyond the base picker.
class _ReferenceExtensionCalendarSection extends StatefulWidget {
  const _ReferenceExtensionCalendarSection({required this.enableBlur});

  final bool enableBlur;

  @override
  State<_ReferenceExtensionCalendarSection> createState() =>
      _ReferenceExtensionCalendarSectionState();
}

class _ReferenceExtensionCalendarSectionState
    extends State<_ReferenceExtensionCalendarSection> {
  final MiuixMonthPickerController _month = MiuixMonthPickerController();
  final MiuixWeekCalendarController _week = MiuixWeekCalendarController();
  MiuixDateRange? _range;

  @override
  void dispose() {
    _month.dispose();
    _week.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _week.selectedDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MiuixSmallTitle(
          '日期范围、月年与日程',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            MiuixButton(
              label: _range == null
                  ? '选择日期范围'
                  : '${_range!.start.month}/${_range!.start.day} - '
                        '${_range!.end.month}/${_range!.end.day}',
              onPressed: () async {
                final value = await MiuixDateRangePicker.show(
                  context: context,
                  initialRange: _range,
                  title: '选择日期范围',
                );
                if (mounted && value != null) setState(() => _range = value);
              },
            ),
            MiuixButton(
              label: '今年',
              onPressed: () => _month.value = DateTime(
                DateTime.now().year,
                _month.value.month,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        MiuixListSection(
          glass: widget.enableBlur,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(12),
              child: MiuixMonthPicker(controller: _month),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: MiuixYearPicker(
                controller: _month,
                minimumYear: DateTime.now().year - 6,
                maximumYear: DateTime.now().year + 6,
                // All thirteen years fit in the page flow. Avoid an inner
                // vertical gesture owner that would trap the parent list.
                shrinkWrap: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MiuixWeekCalendar(controller: _week, onChanged: (_) => setState(() {})),
        MiuixAgendaView(
          items: <MiuixAgendaItem>[
            MiuixAgendaItem(
              date: selectedDate,
              title: '设计评审',
              subtitle: '10:00 - 11:00',
              leading: const Icon(Icons.event_note_rounded),
            ),
            MiuixAgendaItem(
              date: selectedDate.add(const Duration(days: 1)),
              title: '版本验收',
              subtitle: '15:30',
              leading: const Icon(Icons.fact_check_outlined),
            ),
          ],
        ),
      ],
    );
  }
}
