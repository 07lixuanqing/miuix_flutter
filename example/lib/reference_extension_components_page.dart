part of 'main.dart';

/// Demonstrates package extensions without owning any component behavior.
///
/// Every widget below is imported from the public flutter_miuix barrel. This
/// page deliberately contains only sample state and callbacks so copying or
/// removing the example cannot change the distributed library implementation.
class _ReferenceExtensionComponentsPage extends StatefulWidget {
  const _ReferenceExtensionComponentsPage({
    required this.showTopBar,
    required this.enableBlur,
  });

  final bool showTopBar;
  final bool enableBlur;

  @override
  State<_ReferenceExtensionComponentsPage> createState() =>
      _ReferenceExtensionComponentsPageState();
}

class _ReferenceExtensionComponentsPageState
    extends State<_ReferenceExtensionComponentsPage> {
  final MiuixCalendarController _calendar = MiuixCalendarController();
  final MiuixMultiSelectController<String> _multiSelect =
      MiuixMultiSelectController<String>(selected: const <String>['push']);
  final MiuixRatingController _rating = MiuixRatingController(value: 3.5);
  final MiuixDialController _dial = MiuixDialController(value: 55);
  final MiuixCarouselController _carousel = MiuixCarouselController();
  final MiuixSwipeActionController _swipe = MiuixSwipeActionController();
  final TextEditingController _pin = TextEditingController();

  @override
  void dispose() {
    _calendar.dispose();
    _multiSelect.dispose();
    _rating.dispose();
    _dial.dispose();
    _carousel.dispose();
    _swipe.dispose();
    _pin.dispose();
    super.dispose();
  }

  Widget _title(String title) =>
      MiuixSmallTitle(title, insideMargin: _referencePageSmallTitlePadding);

  @override
  Widget build(BuildContext context) {
    return _ReferencePageScaffold(
      title: '扩展控件',
      wide: MediaQuery.sizeOf(context).width >= 840,
      showTopBar: widget.showTopBar,
      enableBlur: widget.enableBlur,
      leading: Navigator.of(context).canPop()
          ? MiuixIconButton(
              icon: Icon(
                _miuixIcon('Back'),
                color: MiuixSemanticColors.of(context)['onBackground'],
              ),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      bodyBuilder: (context, topContentInset) => ListView(
        padding: _referencePagePadding(
          context: context,
          topContentInset: topContentInset,
          bottomContentInset: 24,
        ),
        children: <Widget>[
          _title('日期与时间'),
          MiuixCalendar(
            controller: _calendar,
            selectionMode: MiuixCalendarSelectionMode.range,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              MiuixButton(
                label: '日期',
                onPressed: () => MiuixDatePicker.show(context: context),
              ),
              MiuixButton(
                label: '时间',
                onPressed: () => MiuixTimePicker.show(context: context),
              ),
              MiuixButton(
                label: '日期时间',
                onPressed: () => MiuixDateTimePicker.show(context: context),
              ),
              MiuixButton(
                label: '时长',
                onPressed: () => MiuixDurationPicker.show(
                  context: context,
                  showSeconds: true,
                ),
              ),
            ],
          ),
          _title('输入与表单'),
          MiuixPinInput(controller: _pin, length: 6),
          const SizedBox(height: 10),
          MiuixAutoCompleteField<String>(
            label: '城市',
            displayStringForOption: (value) => value,
            optionsBuilder: (editing) => const <String>[
              '北京',
              '上海',
              '深圳',
              '广州',
            ].where((city) => city.contains(editing.text)),
          ),
          const SizedBox(height: 10),
          MiuixFormSection(
            title: '通知渠道',
            children: <Widget>[
              MiuixFormField<Set<String>>(
                label: '至少选择一种',
                initialValue: _multiSelect.selected,
                validator: (value) =>
                    value == null || value.isEmpty ? '请选择通知渠道' : null,
                fieldBuilder: (field) => MiuixMultiSelect<String>(
                  controller: _multiSelect,
                  options: const <MiuixMultiSelectOption<String>>[
                    MiuixMultiSelectOption(value: 'push', label: '推送'),
                    MiuixMultiSelectOption(value: 'mail', label: '邮件'),
                    MiuixMultiSelectOption(value: 'sms', label: '短信'),
                  ],
                  onChanged: field.didChange,
                ),
              ),
            ],
          ),
          _title('手势与状态'),
          MiuixSwipeAction(
            controller: _swipe,
            endActions: <MiuixSwipeActionItem>[
              MiuixSwipeActionItem(
                label: '标记',
                backgroundColor: const Color(0xFF3482FF),
                onPressed: () {},
              ),
              MiuixSwipeActionItem(
                label: '删除',
                backgroundColor: const Color(0xFFE94634),
                onPressed: () {},
              ),
            ],
            child: const SizedBox(
              height: 72,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text('向左滑动查看等宽操作'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const MiuixContextMenuRegion<String>(
            items: <MiuixContextMenuItem<String>>[
              MiuixContextMenuItem(value: 'copy', label: '复制'),
              MiuixContextMenuItem(
                value: 'delete',
                label: '删除',
                destructive: true,
                separatorBefore: true,
              ),
            ],
            child: MiuixCard(
              insideMargin: EdgeInsets.all(16),
              child: Text('长按或鼠标右键'),
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: <Widget>[
              MiuixSkeleton(width: 52, height: 52, shape: BoxShape.circle),
              SizedBox(width: 12),
              Expanded(child: MiuixShimmer(height: 20)),
            ],
          ),
          _title('数据展示与选择'),
          MiuixListSection(
            title: '玻璃分组',
            glass: widget.enableBlur,
            children: const <Widget>[
              SizedBox(
                height: 52,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('第一项'),
                  ),
                ),
              ),
              SizedBox(
                height: 52,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text('第二项'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          MiuixRating(controller: _rating, allowHalf: true),
          const SizedBox(height: 14),
          Center(
            child: MiuixDial(
              controller: _dial,
              minimum: 0,
              maximum: 100,
              divisions: 20,
            ),
          ),
          const MiuixTimeline(
            items: <MiuixTimelineItem>[
              MiuixTimelineItem(
                title: '已创建',
                state: MiuixTimelineItemState.completed,
              ),
              MiuixTimelineItem(
                title: '处理中',
                state: MiuixTimelineItemState.current,
              ),
              MiuixTimelineItem(title: '待完成'),
            ],
          ),
          MiuixCarousel(
            controller: _carousel,
            height: 150,
            children: const <Widget>[
              MiuixCard(
                insideMargin: EdgeInsets.all(20),
                child: Center(child: Text('轮播一')),
              ),
              MiuixCard(
                insideMargin: EdgeInsets.all(20),
                child: Center(child: Text('轮播二')),
              ),
              MiuixCard(
                insideMargin: EdgeInsets.all(20),
                child: Center(child: Text('轮播三')),
              ),
            ],
          ),
          _ReferenceExtensionCalendarSection(enableBlur: widget.enableBlur),
          _ReferenceExtensionCollectionSection(enableBlur: widget.enableBlur),
          _ReferenceExtensionLayoutSection(enableBlur: widget.enableBlur),
          const MiuixEmptyStateView(
            title: '没有更多内容',
            message: '这里展示标准空状态的标题和说明层级。',
          ),
        ],
      ),
    );
  }
}
