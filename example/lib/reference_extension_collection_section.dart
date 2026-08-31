part of 'main.dart';

/// Demonstrates package-level collection, workflow, and desktop interaction.
class _ReferenceExtensionCollectionSection extends StatefulWidget {
  const _ReferenceExtensionCollectionSection({required this.enableBlur});

  final bool enableBlur;

  @override
  State<_ReferenceExtensionCollectionSection> createState() =>
      _ReferenceExtensionCollectionSectionState();
}

class _ReferenceExtensionCollectionSectionState
    extends State<_ReferenceExtensionCollectionSection> {
  final MiuixProcessStepperController _process =
      MiuixProcessStepperController();
  final MiuixDataTableController _table = MiuixDataTableController();
  final MiuixFileDropController _files = MiuixFileDropController();
  final List<String> _ordered = <String>['收集需求', '完成设计', '构建发布'];
  var _filterSelected = false;

  @override
  void dispose() {
    _process.dispose();
    _table.dispose();
    _files.dispose();
    super.dispose();
  }

  Future<List<MiuixDroppedFile>> _pickSampleFile() async {
    return const <MiuixDroppedFile>[
      MiuixDroppedFile(
        path: 'example/design-notes.txt',
        name: 'design-notes.txt',
        mimeType: 'text/plain',
        length: 2048,
      ),
    ];
  }

  List<MiuixCommand> _commands(BuildContext context) => <MiuixCommand>[
    MiuixCommand(
      id: 'new',
      title: '新建项目',
      subtitle: '创建一个空白项目',
      icon: const Icon(Icons.add_rounded),
      shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true),
      onInvoke: () => MiuixToast.show(context, '已执行“新建项目”'),
    ),
    MiuixCommand(
      id: 'theme',
      title: '切换颜色模式',
      keywords: const <String>['dark', 'light'],
      icon: const Icon(Icons.contrast_rounded),
      onInvoke: () => MiuixToast.show(context, '命令面板仅负责调用宿主逻辑'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const MiuixSmallTitle(
          '集合、选择与标签',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            MiuixChip(
              label: '过滤 Chip',
              variant: MiuixChipVariant.filter,
              selected: _filterSelected,
              glass: widget.enableBlur,
              onSelected: (value) => setState(() => _filterSelected = value),
            ),
            MiuixChip(
              label: '可删除标签',
              variant: MiuixChipVariant.input,
              onDeleted: () {},
            ),
            MiuixChip(
              label: '建议操作',
              variant: MiuixChipVariant.suggestion,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: 10),
        const MiuixSearchableSelect<String>(
          label: '参与成员',
          multiple: true,
          initialSelected: <String>['design'],
          options: <MiuixSearchableSelectOption<String>>[
            MiuixSearchableSelectOption(value: 'design', label: '设计'),
            MiuixSearchableSelectOption(value: 'develop', label: '开发'),
            MiuixSearchableSelectOption(value: 'test', label: '测试'),
          ],
        ),
        const SizedBox(height: 10),
        MiuixTagInput(
          label: '关键词',
          initialTags: const <String>['MIUIX', 'Flutter'],
          maximumTags: 6,
          glass: widget.enableBlur,
        ),
        const SizedBox(height: 12),
        const MiuixTreeView<String>(
          nodes: <MiuixTreeNode<String>>[
            MiuixTreeNode<String>(
              value: 'src',
              label: 'lib/src',
              icon: Icon(Icons.folder_outlined),
              expandedIcon: Icon(Icons.folder_open_outlined),
              children: <MiuixTreeNode<String>>[
                MiuixTreeNode<String>(
                  value: 'widgets',
                  label: 'widgets',
                  icon: Icon(Icons.folder_outlined),
                ),
                MiuixTreeNode<String>(
                  value: 'extensions',
                  label: 'extensions',
                  icon: Icon(Icons.extension_outlined),
                ),
              ],
            ),
          ],
        ),
        const MiuixSmallTitle(
          '重排列表与流程',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixListSection(
          glass: widget.enableBlur,
          children: <Widget>[
            MiuixReorderableList<String>(
              items: _ordered,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemKey: (item) => ValueKey<String>(item),
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _ordered.removeAt(oldIndex);
                  _ordered.insert(newIndex, item);
                });
              },
              itemBuilder: (context, item, index) => MiuixReorderableItem(
                index: index,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                  child: Row(
                    children: <Widget>[
                      Expanded(child: Text(item)),
                      MiuixDragHandle(index: index),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MiuixProcessStepper(
          controller: _process,
          showDefaultActions: false,
          steps: const <MiuixProcessStep>[
            MiuixProcessStep(title: '基本信息', content: Text('填写项目名称与说明')),
            MiuixProcessStep(title: '界面设置', content: Text('选择主题与布局')),
            MiuixProcessStep(title: '确认', content: Text('检查并保存设置')),
          ],
        ),
        const MiuixSmallTitle(
          '数据表、文件与命令',
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixDataTable<Map<String, Object>>(
          controller: _table,
          height: 260,
          shrinkWrapRows: true,
          selectable: true,
          glass: widget.enableBlur,
          items: const <Map<String, Object>>[
            <String, Object>{'id': 1, 'name': '设计稿', 'state': '已完成'},
            <String, Object>{'id': 2, 'name': '组件测试', 'state': '进行中'},
            <String, Object>{'id': 3, 'name': '发布文档', 'state': '待处理'},
          ],
          rowKey: (item) => item['id']!,
          columns: <MiuixDataColumn<Map<String, Object>>>[
            MiuixDataColumn<Map<String, Object>>(
              id: 'name',
              label: '名称',
              width: 220,
              comparator: (a, b) => '${a['name']}'.compareTo('${b['name']}'),
              cellBuilder: (context, item) => Text('${item['name']}'),
            ),
            MiuixDataColumn<Map<String, Object>>(
              id: 'state',
              label: '状态',
              cellBuilder: (context, item) => Text('${item['state']}'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MiuixFileDropZone(
          controller: _files,
          acceptedExtensions: const <String>['txt', 'md'],
          onBrowseRequested: _pickSampleFile,
          glass: widget.enableBlur,
        ),
        const SizedBox(height: 10),
        MiuixButton(
          label: '打开命令面板',
          icon: const Icon(Icons.terminal_rounded),
          onPressed: () => MiuixCommandPalette.show(
            context: context,
            commands: _commands(context),
          ),
        ),
      ],
    );
  }
}
