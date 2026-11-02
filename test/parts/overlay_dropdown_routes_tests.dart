part of '../miuix_flutter_test.dart';

// 保留原测试注册顺序和公共夹具；按弹层职责拆分超长文件。
void _registerOverlayDropdownRoutesTests() {
  testWidgets('dropdown popup flips above a low anchor and stays compact', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const Spacer(),
              MiuixDropdownPreference<String>(
                title: 'Low display mode',
                value: 'Balanced',
                entries: const [
                  MiuixDropdownEntry(value: 'Balanced', label: 'Balanced'),
                  MiuixDropdownEntry(value: 'Compact', label: 'Compact'),
                  MiuixDropdownEntry(value: 'Expressive', label: 'Expressive'),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    final preference = find.byType(MiuixDropdownPreference<String>);
    final anchor = tester.getRect(
      find.descendant(
        of: preference,
        matching: find.byType(CompositedTransformTarget),
      ),
    );
    await tester.tap(find.text('Low display mode'));
    await tester.pumpAndSettle();

    final popup = tester.getRect(find.byType(MiuixListPopup<String>));
    expect(popup.height, lessThan(220));
    // ListPopupLayout truncates positionInWindow before it performs IntOffset
    // arithmetic. Compare the painted pixel, not Flutter's fractional anchor.
    final sourceAnchorTop = anchor.top.truncate();
    final sourceAnchorLeft = anchor.left.truncate();
    final sourceAnchorWidth = anchor.width.round();
    expect(popup.bottom.round(), sourceAnchorTop - 8);
    expect(popup.left, greaterThanOrEqualTo(0));
    expect(popup.right.round(), sourceAnchorLeft + sourceAnchorWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown popup opens below an anchor when space is available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SizedBox(height: 180),
              MiuixDropdownPreference<String>(
                title: 'Display mode',
                value: 'Balanced',
                entries: const [
                  MiuixDropdownEntry(value: 'Balanced', label: 'Balanced'),
                  MiuixDropdownEntry(value: 'Compact', label: 'Compact'),
                  MiuixDropdownEntry(value: 'Expressive', label: 'Expressive'),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final preference = find.byType(MiuixDropdownPreference<String>);
    final anchor = tester.getRect(
      find.descendant(
        of: preference,
        matching: find.byType(CompositedTransformTarget),
      ),
    );
    await tester.tap(find.text('Display mode'));
    await tester.pumpAndSettle();

    final popup = tester.getRect(find.byType(MiuixListPopup<String>));
    // Compose adds the measured integer height to a separately truncated
    // position, rather than rounding Flutter's fractional far edge.
    final sourceAnchorLeft = anchor.left.truncate();
    final sourceAnchorTop = anchor.top.truncate();
    final sourceAnchorWidth = anchor.width.round();
    final sourceAnchorHeight = anchor.height.round();
    expect(popup.top.round(), sourceAnchorTop + sourceAnchorHeight + 8);
    expect(popup.bottom, lessThanOrEqualTo(800));
    expect(popup.right.round(), sourceAnchorLeft + sourceAnchorWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'fractional-density dropdown preserves localized anchor and width',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixScaffold(
            body: Column(
              children: [
                const SizedBox(height: 120),
                MiuixOverlayDropdownPreference<String>(
                  title: 'Fractional dropdown',
                  value: 'one',
                  popupMinWidth: 238.5,
                  entries: const [
                    MiuixDropdownEntry(value: 'one', label: 'One'),
                    MiuixDropdownEntry(value: 'two', label: 'Two'),
                  ],
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );

      final preference = find.byType(MiuixOverlayDropdownPreference<String>);
      final anchor = tester.getRect(
        find.descendant(
          of: preference,
          matching: find.byType(CompositedTransformTarget),
        ),
      );
      await tester.tap(find.text('Fractional dropdown'));
      await tester.pumpAndSettle();

      final popup = tester.getRect(find.byType(MiuixListPopup<String>));
      final sourceTopPixels =
          (anchor.top * density).truncate() +
          (anchor.height * density).round() +
          (8 * density).round() -
          1;
      expect((popup.top * density).round(), sourceTopPixels);
      expect(popup.width, closeTo(238.5, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('source dropdown popup honors colors height and index callback', (
    tester,
  ) async {
    const colors = MiuixDropdownColors(
      contentColor: Colors.purple,
      containerColor: Colors.black,
      selectedContentColor: Colors.yellow,
      selectedContainerColor: Colors.brown,
    );
    var selectedIndex = -1;
    final items = List<String>.generate(12, (index) => '源选项 $index');

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: MiuixOverlayDropdownPreference.source(
                items: items,
                selectedIndex: 0,
                title: '源式下拉菜单',
                dropdownColors: colors,
                maxHeight: 120,
                onSelectedIndexChange: (index) => selectedIndex = index,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('源式下拉菜单'));
    await tester.pumpAndSettle();

    final rows = find.byType(MiuixDropdownImpl);
    expect(rows, findsNWidgets(12));
    expect(tester.getSize(find.byType(MiuixListPopupColumn)).height, 120);
    for (final row in tester.widgetList<MiuixDropdownImpl>(rows)) {
      expect(row.colors, same(colors));
    }

    await tester.tap(find.text('源选项 1'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);
    expect(find.byType(MiuixListPopupColumn), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current dropdown exposes all seven independent color channels', (
    tester,
  ) async {
    const colors = MiuixDropdownColors(
      contentColor: Colors.purple,
      summaryColor: Colors.orange,
      containerColor: Colors.black,
      selectedContentColor: Colors.yellow,
      selectedSummaryColor: Colors.green,
      selectedContainerColor: Colors.brown,
      selectedIndicatorColor: Colors.cyan,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixDropdownImpl(
            text: '当前标题',
            summary: '当前摘要',
            optionSize: 1,
            isSelected: true,
            index: 0,
            colors: colors,
            onSelectedIndexChange: _ignoreDropdownIndex,
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.text('当前标题')).style?.color, Colors.yellow);
    expect(tester.widget<Text>(find.text('当前摘要')).style?.color, Colors.green);
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((box) => box.color == Colors.brown),
      isTrue,
    );
    expect(colors.selectedIndicatorColor, Colors.cyan);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'current grouped dropdown filters empty groups but opens disabled items',
    (tester) async {
      var selectionCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              body: MiuixOverlayGroupedDropdownPreference.source<int>(
                title: '当前分组下拉',
                groups: const [
                  MiuixDropdownGroup(entries: []),
                  MiuixDropdownGroup(
                    enabled: false,
                    entries: [
                      MiuixDropdownEntry(
                        value: 1,
                        label: '禁用选项',
                        summary: '仍可查看',
                        selected: true,
                      ),
                    ],
                  ),
                ],
                onSelected: (_) => selectionCalls++,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('当前分组下拉'));
      await tester.pumpAndSettle();
      final popup = find.byType(MiuixListPopup<int>);
      final row = find.byType(MiuixDropdownImpl);
      expect(popup, findsOneWidget);
      expect(row, findsOneWidget);
      expect(tester.widget<MiuixDropdownImpl>(row).enabled, isFalse);
      expect(find.byType(MiuixHorizontalDivider), findsNothing);
      final disabledSemantics = tester
          .getSemantics(find.text('禁用选项').last)
          .getSemanticsData();
      expect(disabledSemantics.hasAction(SemanticsAction.tap), isFalse);

      await tester.tap(row);
      await tester.pump();
      expect(selectionCalls, 0);
      expect(popup, findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('source spinner popup uses rich rows colors and index callback', (
    tester,
  ) async {
    const colors = MiuixSpinnerColors(
      contentColor: Colors.purple,
      summaryColor: Colors.orange,
      containerColor: Colors.black,
      selectedContentColor: Colors.yellow,
      selectedSummaryColor: Colors.green,
      selectedContainerColor: Colors.brown,
      selectedIndicatorColor: Colors.cyan,
    );
    var selectedIndex = -1;
    final items = List<MiuixSpinnerEntry>.generate(
      12,
      (index) => MiuixSpinnerEntry(
        icon: SizedBox.square(
          key: ValueKey('source-spinner-icon-$index'),
          dimension: 24,
        ),
        title: '源选择 $index',
        summary: '源摘要 $index',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: MiuixOverlaySpinnerPreference.source(
                items: items,
                selectedIndex: 0,
                title: '源式选择器',
                spinnerColors: colors,
                maxHeight: 120,
                onSelectedIndexChange: (index) => selectedIndex = index,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('源式选择器'));
    await tester.pumpAndSettle();

    final rows = find.byType(MiuixSpinnerItemImpl);
    expect(rows, findsNWidgets(12));
    expect(tester.getSize(find.byType(MiuixListPopupColumn)).height, 120);
    for (final row in tester.widgetList<MiuixSpinnerItemImpl>(rows)) {
      expect(row.colors, same(colors));
      expect(row.dialogMode, isFalse);
    }
    final firstIcon = tester.getRect(
      find.byKey(const ValueKey('source-spinner-icon-0')),
    );
    final firstTitle = tester.getRect(
      find.descendant(
        of: find.byType(MiuixListPopupColumn),
        matching: find.text('源选择 0'),
      ),
    );
    // SpinnerItemImpl's supplied modifier is
    // sizeIn(minWidth: 26, minHeight: 26).padding(end: 12). The 26dp minimum
    // wraps the already padded icon; it must not become a 26dp icon slot plus
    // another 12dp gap. A 24dp icon therefore leaves exactly 12dp before text.
    expect(firstTitle.left - firstIcon.right, closeTo(12, .001));

    await tester.tap(find.text('源选择 1'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 1);
    expect(find.byType(MiuixListPopupColumn), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source spinner rows round horizontal modifiers like Compose', (
    tester,
  ) async {
    const density = 2.625;
    const popupRowKey = ValueKey('source-popup-spinner-row');
    const dialogRowKey = ValueKey('source-dialog-spinner-row');
    const popupIconKey = ValueKey('source-popup-spinner-icon');
    const dialogIconKey = ValueKey('source-dialog-spinner-icon');
    tester.view.devicePixelRatio = density;
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiuixSpinnerItemImpl(
                key: popupRowKey,
                entry: const MiuixSpinnerEntry(
                  icon: SizedBox.square(key: popupIconKey, dimension: 24),
                  title: '弹出标题',
                  summary: '弹出摘要',
                ),
                entryCount: 1,
                isSelected: true,
                index: 0,
                onSelectedIndexChange: (_) {},
              ),
              MiuixSpinnerItemImpl(
                key: dialogRowKey,
                entry: const MiuixSpinnerEntry(
                  icon: SizedBox.square(key: dialogIconKey, dimension: 24),
                  title: '对话框标题',
                  summary: '对话框摘要',
                ),
                entryCount: 1,
                isSelected: true,
                index: 0,
                dialogMode: true,
                onSelectedIndexChange: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final popupRow = tester.getRect(find.byKey(popupRowKey));
    final popupIcon = tester.getRect(find.byKey(popupIconKey));
    final popupTitle = tester.getRect(find.text('弹出标题'));
    final dialogRow = tester.getRect(find.byKey(dialogRowKey));
    final dialogIcon = tester.getRect(find.byKey(dialogIconKey));
    final dialogTitle = tester.getRect(find.text('对话框标题'));

    // Compose roundToPx: 20dp -> 53px, 28dp -> 74px, 12dp -> 32px.
    expect((popupIcon.left - popupRow.left) * density, closeTo(53, .001));
    expect((dialogIcon.left - dialogRow.left) * density, closeTo(74, .001));
    expect((popupTitle.left - popupIcon.right) * density, closeTo(32, .001));
    expect((dialogTitle.left - dialogIcon.right) * density, closeTo(32, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'source spinner dialog selects immediately and button dismisses',
    (tester) async {
      var selectedIndex = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return MiuixTheme(
                child: Scaffold(
                  body: MiuixWindowSpinnerPreference.source(
                    title: '源式对话框选择器',
                    items: const [
                      MiuixSpinnerEntry(title: '对话框选项一', summary: '摘要一'),
                      MiuixSpinnerEntry(title: '对话框选项二', summary: '摘要二'),
                    ],
                    selectedIndex: selectedIndex,
                    dialogButtonString: '取消',
                    onSelectedIndexChange: (index) {
                      setState(() => selectedIndex = index);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('源式对话框选择器'));
      await tester.pumpAndSettle();
      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey('miuix-dialog-surface')),
      );
      final firstRow = find.byType(MiuixSpinnerItemImpl).first;
      final firstRowRect = tester.getRect(firstRow);
      expect(firstRowRect.left, surfaceRect.left);
      expect(firstRowRect.right, surfaceRect.right);
      expect(tester.widget<MiuixSpinnerItemImpl>(firstRow).dialogMode, isTrue);

      await tester.tap(find.text('对话框选项二'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
      expect(find.text('取消'), findsNothing);

      await tester.tap(find.text('源式对话框选择器'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
      expect(find.text('取消'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'source spinner dialog rounds compact geometry like Compose at 420dpi',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: MiuixWindowSpinnerPreference.source(
                title: '选择器偏好',
                items: const [
                  MiuixSpinnerEntry(title: '选项一', summary: '红色'),
                  MiuixSpinnerEntry(title: '选项二', summary: '绿色'),
                  MiuixSpinnerEntry(title: '选项三', summary: '蓝色'),
                  MiuixSpinnerEntry(title: '选项四', summary: '黄色'),
                ],
                selectedIndex: 2,
                dialogButtonString: '取消',
                onSelectedIndexChange: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('选择器偏好').first);
      await tester.pumpAndSettle();

      final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
      final title = find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey('miuix-dialog-title-placeable')),
      );
      final rows = find.byType(MiuixSpinnerItemImpl);
      final button = find.widgetWithText(MiuixTextButton, '取消');
      final surfaceRect = tester.getRect(surface);
      final titleRect = tester.getRect(title);
      final firstRowRect = tester.getRect(rows.first);
      final lastRowRect = tester.getRect(rows.last);
      final buttonRect = tester.getRect(button);

      // Native SpinnerSection capture on the same 1080x2400 / 420dpi device:
      // outer [32,1304]..[1048,2305], first row y=1455, the four rows
      // are 156px each, both 12dp gaps are 32px, and the button is 131px.
      expect(surfaceRect.left * density, closeTo(32, .001));
      expect(surfaceRect.right * density, closeTo(1048, .001));
      expect(surfaceRect.top * density, closeTo(1304, .001));
      expect(surfaceRect.bottom * density, closeTo(2305, .001));
      expect(titleRect.top * density, closeTo(1367, .001));
      expect(firstRowRect.top * density, closeTo(1455, .001));
      expect(firstRowRect.height * density, closeTo(156, .001));
      expect(lastRowRect.bottom * density, closeTo(2079, .001));
      expect(
        (firstRowRect.top - titleRect.bottom) * density,
        closeTo(32, .001),
      );
      expect(
        (buttonRect.top - lastRowRect.bottom) * density,
        closeTo(32, .001),
      );
      expect(buttonRect.height * density, closeTo(131, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'current grouped spinner popup keeps groups open and disables source rows',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final selected = <int>[0, 0, 0];
      final calls = <(int, int)>[];

      List<MiuixDropdownGroup<(int, int)>> groups() => [
        MiuixDropdownGroup(
          entries: [
            for (var index = 0; index < 2; index++)
              MiuixDropdownEntry(
                value: (0, index),
                label: 'A${index + 1}',
                summary: '甲${index + 1}',
                selected: selected[0] == index,
              ),
          ],
        ),
        MiuixDropdownGroup(
          entries: [
            for (var index = 0; index < 2; index++)
              MiuixDropdownEntry(
                value: (1, index),
                label: 'B${index + 1}',
                summary: '乙${index + 1}',
                selected: selected[1] == index,
              ),
          ],
        ),
        MiuixDropdownGroup(
          entries: [
            for (var index = 0; index < 4; index++)
              MiuixDropdownEntry(
                value: (2, index),
                label: 'C${index + 1}',
                summary: '丙${index + 1}',
                enabled: index.isEven,
                selected: selected[2] == index,
              ),
          ],
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => MiuixTheme(
              child: Scaffold(
                body: MiuixWindowGroupedSpinnerPreference.source<(int, int)>(
                  title: '当前分组选择器',
                  groups: groups(),
                  closeOnSelection: false,
                  onSelected: (value) {
                    calls.add(value);
                    setState(() => selected[value.$1] = value.$2);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('当前分组选择器'));
      await tester.pumpAndSettle();
      final popup = find.byType(MiuixListPopup<(int, int)>);
      expect(popup, findsOneWidget);
      expect(find.byType(MiuixDropdownImpl), findsNWidgets(8));
      expect(find.byType(MiuixHorizontalDivider), findsNWidgets(2));
      final popupViewport = tester.getRect(find.byType(MiuixListPopupColumn));
      expect(popupViewport.width * density, closeTo(525, .001));
      // First-eight layout children are row1, row2, divider, row3, row4,
      // divider, row5, and row6. Their native physical sum is 1009px.
      expect(popupViewport.height * density, closeTo(1009, .001));
      final sourceRows = find.byType(MiuixDropdownImpl);
      final rowRects = [
        for (var index = 0; index < 8; index++)
          tester.getRect(sourceRows.at(index)),
      ];
      const expectedRowHeights = [177, 156, 156, 156, 156, 156, 156, 177];
      for (var index = 0; index < rowRects.length; index++) {
        expect(
          rowRects[index].height * density,
          closeTo(expectedRowHeights[index], .001),
        );
      }
      expect(
        (rowRects[2].top - rowRects[1].bottom) * density,
        closeTo(26, .001),
      );
      expect(
        (rowRects[4].top - rowRects[3].bottom) * density,
        closeTo(26, .001),
      );
      final disabled = tester
          .widgetList<MiuixDropdownImpl>(find.byType(MiuixDropdownImpl))
          .where((row) => !row.enabled)
          .toList(growable: false);
      expect(disabled, hasLength(2));

      await tester.tap(find.text('C2'));
      await tester.pump();
      expect(calls, isEmpty);
      expect(popup, findsOneWidget);

      await tester.tap(find.text('A2'));
      await tester.pump();
      expect(calls, const [(0, 1)]);
      expect(popup, findsOneWidget);
      expect(
        tester.widget<MiuixListPopup<(int, int)>>(popup).sourceRows,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'current grouped spinner dialog uses source rows dividers and close button',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      final selected = <int>[0, 0, 0];
      final calls = <(int, int)>[];
      List<MiuixDropdownGroup<(int, int)>> groups() => [
        for (var group = 0; group < 3; group++)
          MiuixDropdownGroup(
            entries: [
              for (var index = 0; index < (group == 2 ? 4 : 2); index++)
                MiuixDropdownEntry(
                  value: (group, index),
                  label: '组$group-${index + 1}',
                  summary: '摘要$group-${index + 1}',
                  enabled: group != 2 || index.isEven,
                  selected: selected[group] == index,
                ),
            ],
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => MiuixTheme(
              child: Scaffold(
                body: MiuixWindowGroupedSpinnerPreference.source<(int, int)>(
                  title: '当前分组对话框',
                  groups: groups(),
                  dialogButtonString: '确定',
                  onSelected: (value) {
                    calls.add(value);
                    setState(() => selected[value.$1] = value.$2);
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('当前分组对话框'));
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
      final rows = find.byType(MiuixDropdownImpl);
      expect(rows, findsNWidgets(8));
      expect(
        tester
            .widgetList<MiuixDropdownImpl>(rows)
            .every((row) => row.dialogMode),
        isTrue,
      );
      expect(find.byType(MiuixHorizontalDivider), findsNWidgets(2));
      expect(find.widgetWithText(MiuixTextButton, '确定'), findsOneWidget);
      expect(tester.getRect(rows.first).left, tester.getRect(surface).left);
      expect(tester.getRect(rows.first).right, tester.getRect(surface).right);
      final rowRects = [
        for (var index = 0; index < 8; index++) tester.getRect(rows.at(index)),
      ];
      expect(
        rowRects.map((rect) => rect.height * density),
        everyElement(closeTo(156, .001)),
      );
      // Native current SpinnerSection: dialog group dividers occupy 26px,
      // each 28dp-padded row is 156px, and the close button is 131px after a
      // separately rounded 12dp (32px) gap.
      expect(
        (rowRects[2].top - rowRects[1].bottom) * density,
        closeTo(26, .001),
      );
      expect(
        (rowRects[4].top - rowRects[3].bottom) * density,
        closeTo(26, .001),
      );
      final button = find.widgetWithText(MiuixTextButton, '确定');
      final buttonRect = tester.getRect(button);
      expect(
        (buttonRect.top - rowRects.last.bottom) * density,
        closeTo(32, .001),
      );
      expect(buttonRect.height * density, closeTo(131, .001));

      await tester.tap(find.text('组1-2'));
      await tester.pump();
      expect(calls, const [(1, 1)]);
      expect(surface, findsOneWidget);
      await tester.tap(find.text('确定'));
      await tester.pumpAndSettle();
      expect(surface, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('overlay dropdown uses the same end-aligned adaptive placement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixScaffold(
          body: Column(
            children: [
              const SizedBox(height: 180),
              MiuixOverlayDropdownPreference<String>(
                title: 'Overlay display mode',
                value: 'Balanced',
                entries: const [
                  MiuixDropdownEntry(value: 'Balanced', label: 'Balanced'),
                  MiuixDropdownEntry(value: 'Compact', label: 'Compact'),
                  MiuixDropdownEntry(value: 'Expressive', label: 'Expressive'),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final preference = find.byType(MiuixOverlayDropdownPreference<String>);
    final anchorTarget = find.descendant(
      of: preference,
      matching: find.byType(CompositedTransformTarget),
    );
    final anchor = tester.getRect(anchorTarget);
    await tester.tap(find.text('Overlay display mode'));
    await tester.pumpAndSettle();

    final popup = tester.getRect(find.byType(MiuixListPopup<String>));
    // BasicComponent hold-down changes only MiuixIndication alpha; unlike a
    // SinkFeedback card it must retain the anchor's measured and painted size.
    expect(tester.getRect(anchorTarget).width, closeTo(anchor.width, .01));
    final sourceAnchorLeft = anchor.left.truncate();
    final sourceAnchorTop = anchor.top.truncate();
    final sourceAnchorWidth = anchor.width.round();
    final sourceAnchorHeight = anchor.height.round();
    expect(popup.top.round(), sourceAnchorTop + sourceAnchorHeight + 8);
    expect(popup.right.round(), sourceAnchorLeft + sourceAnchorWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grouped dropdown keeps independent checks while staying open', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MiuixWindowGroupedDropdownPreference<String>(
            title: 'Grouped menu',
            groups: const [
              MiuixDropdownGroup(
                entries: [
                  MiuixDropdownEntry(value: 'a1', label: 'A-1', selected: true),
                  MiuixDropdownEntry(value: 'a2', label: 'A-2'),
                ],
              ),
              MiuixDropdownGroup(
                entries: [
                  MiuixDropdownEntry(value: 'b1', label: 'B-1', selected: true),
                  MiuixDropdownEntry(value: 'b2', label: 'B-2', enabled: false),
                ],
              ),
            ],
            onSelected: selected.add,
          ),
        ),
      ),
    );

    // The current entries overload joins one active label from every group in
    // the preference end action before the arrow.
    expect(find.text('A-1\nB-1'), findsOneWidget);
    await tester.tap(find.text('Grouped menu'));
    await tester.pumpAndSettle();
    final popup = find.byType(MiuixListPopup<String>);
    expect(popup, findsOneWidget);
    expect(
      find.descendant(
        of: popup,
        matching: find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.text('A-2'));
    await tester.pump();
    expect(selected, ['a2']);
    expect(popup, findsOneWidget);
    expect(
      find.descendant(
        of: popup,
        matching: find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      ),
      findsNWidgets(2),
    );

    await tester.tap(find.text('B-2'));
    await tester.pump();
    expect(selected, ['a2']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog spinner commits its pending value only on confirm', (
    tester,
  ) async {
    var value = 'one';
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MiuixWindowSpinnerPreference<String>(
                title: 'Dialog spinner',
                value: value,
                entries: const [
                  MiuixDropdownEntry(value: 'one', label: '选项一'),
                  MiuixDropdownEntry(value: 'two', label: '选项二'),
                ],
                dialogConfirmLabel: '确定',
                onChanged: (next) => setState(() => value = next),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Dialog spinner'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('选项二'));
    await tester.pump();
    expect(value, 'one');

    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(value, 'two');
    expect(find.text('确定'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('open confirm spinner refreshes entries draft and owner', (
    tester,
  ) async {
    var entries = const <MiuixDropdownEntry<String>>[
      MiuixDropdownEntry(value: 'a', label: '确认旧选项 A'),
      MiuixDropdownEntry(value: 'b', label: '确认旧选项 B'),
    ];
    var confirmLabel = '旧确定';
    var selected = '';
    ValueChanged<String> handler = (value) => selected = 'old:$value';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Scaffold(
              body: MiuixWindowSpinnerPreference<String>(
                title: '动态确认选择器',
                value: 'b',
                entries: entries,
                dialogConfirmLabel: confirmLabel,
                onChanged: handler,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('动态确认选择器'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确认旧选项 A'));
    await tester.pump();
    final openingSurface = tester.element(
      find.byKey(const ValueKey('miuix-dialog-surface')),
    );

    updateHost(() {
      entries = const [
        MiuixDropdownEntry(value: 'a', label: '确认新选项 A'),
        MiuixDropdownEntry(value: 'c', label: '确认新选项 C'),
      ];
      confirmLabel = '新应用';
      handler = (value) => selected = 'new:$value';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('确认旧选项 A'), findsNothing);
    expect(find.text('确认新选项 A'), findsOneWidget);
    expect(find.text('确认新选项 C'), findsOneWidget);
    expect(find.text('新应用'), findsOneWidget);
    expect(
      tester.element(find.byKey(const ValueKey('miuix-dialog-surface'))),
      same(openingSurface),
      reason: 'content refresh must not replace or replay the dialog route',
    );

    // The valid unconfirmed draft A survives the option refresh.
    await tester.tap(find.text('新应用'));
    await tester.pumpAndSettle();
    expect(selected, 'new:a');
    expect(tester.takeException(), isNull);
  });

  testWidgets('confirm spinner replaces a removed draft with current value', (
    tester,
  ) async {
    var entries = const <MiuixDropdownEntry<String>>[
      MiuixDropdownEntry(value: 'a', label: '待删除草稿 A'),
      MiuixDropdownEntry(value: 'b', label: '受控值 B'),
    ];
    var selected = '';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Scaffold(
              body: MiuixWindowSpinnerPreference<String>(
                title: '草稿失效选择器',
                value: 'b',
                entries: entries,
                dialogConfirmLabel: '应用失效草稿',
                onChanged: (value) => selected = value,
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('草稿失效选择器'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('待删除草稿 A'));
    await tester.pump();

    updateHost(() {
      entries = const [
        MiuixDropdownEntry(value: 'b', label: '刷新受控值 B'),
        MiuixDropdownEntry(value: 'c', label: '刷新选项 C'),
      ];
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('待删除草稿 A'), findsNothing);

    await tester.tap(find.text('应用失效草稿'));
    await tester.pumpAndSettle();
    expect(selected, 'b');
    expect(tester.takeException(), isNull);
  });

  testWidgets('open source spinner dialog refreshes items and owner', (
    tester,
  ) async {
    var items = const <MiuixSpinnerEntry>[
      MiuixSpinnerEntry(title: '源旧选项一'),
      MiuixSpinnerEntry(title: '源旧选项二'),
    ];
    var buttonLabel = '旧关闭';
    var selected = '';
    ValueChanged<int> handler = (index) => selected = 'old:$index';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return MiuixTheme(
              child: Scaffold(
                body: MiuixWindowSpinnerPreference.source(
                  title: '动态源式选择器',
                  items: items,
                  selectedIndex: 0,
                  dialogButtonString: buttonLabel,
                  onSelectedIndexChange: handler,
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('动态源式选择器'));
    await tester.pumpAndSettle();
    updateHost(() {
      items = const [
        MiuixSpinnerEntry(title: '源新选项一'),
        MiuixSpinnerEntry(title: '源新选项二'),
      ];
      buttonLabel = '新关闭';
      handler = (index) => selected = 'new:$index';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('源旧选项二'), findsNothing);
    expect(find.text('源新选项二'), findsOneWidget);
    expect(find.text('新关闭'), findsOneWidget);

    await tester.tap(find.text('源新选项二'));
    await tester.pumpAndSettle();
    expect(selected, 'new:1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('open grouped confirm dialog refreshes groups and owner', (
    tester,
  ) async {
    var groups = const <MiuixDropdownGroup<String>>[
      MiuixDropdownGroup(
        entries: [
          MiuixDropdownEntry(value: 'a', label: '确认分组旧选项 A'),
          MiuixDropdownEntry(value: 'b', label: '确认分组旧选项 B'),
        ],
      ),
    ];
    var confirmLabel = '旧完成';
    var selected = '';
    ValueChanged<String> handler = (value) => selected = 'old:$value';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return Scaffold(
              body: MiuixGroupedDropdownPreference<String>(
                title: '动态分组确认框',
                groups: groups,
                dialogConfirmLabel: confirmLabel,
                closeOnSelection: false,
                onSelected: handler,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('动态分组确认框'));
    await tester.pumpAndSettle();
    updateHost(() {
      groups = const [
        MiuixDropdownGroup(
          entries: [
            MiuixDropdownEntry(value: 'b', label: '确认分组新选项 B'),
            MiuixDropdownEntry(value: 'c', label: '确认分组新选项 C'),
          ],
        ),
      ];
      confirmLabel = '新完成';
      handler = (value) => selected = 'new:$value';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('确认分组旧选项 A'), findsNothing);
    expect(find.text('确认分组新选项 C'), findsOneWidget);
    expect(find.text('新完成'), findsOneWidget);

    await tester.tap(find.text('确认分组新选项 C'));
    await tester.pump();
    expect(selected, 'new:c');
    expect(find.text('新完成'), findsOneWidget);
    await tester.tap(find.text('新完成'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown anchor survives expansion callback rebuilds', (
    tester,
  ) async {
    var expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: MiuixWindowDropdownPreference<String>(
                title: 'Rebuilding dropdown',
                summary: expanded ? 'Expanded' : 'Collapsed',
                value: 'one',
                entries: const [
                  MiuixDropdownEntry(value: 'one', label: 'First option'),
                  MiuixDropdownEntry(value: 'two', label: 'Second option'),
                ],
                onChanged: (_) {},
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Rebuilding dropdown'));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(find.text('Second option').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('default dropdown routes follow a scrolling HyperOS anchor', (
    tester,
  ) async {
    Future<void> verify(MiuixPopupPresentation presentation) async {
      final scroll = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              body: ListView(
                controller: scroll,
                children: [
                  const SizedBox(height: 180),
                  Center(
                    child: MiuixDropdownMenuButton<String>(
                      presentation: presentation,
                      entries: const [
                        MiuixDropdownEntry(value: 'one', label: '实时选项一'),
                        MiuixDropdownEntry(value: 'two', label: '实时选项二'),
                      ],
                      onSelected: (_) {},
                      child: Text('实时锚点-${presentation.name}'),
                    ),
                  ),
                  const SizedBox(height: 1000),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('实时锚点-${presentation.name}'));
      await tester.pumpAndSettle();
      final anchorBefore = tester.getCenter(
        find.text('实时锚点-${presentation.name}'),
      );
      final before = tester.getCenter(find.text('实时选项一'));
      final pixelsBefore = scroll.offset;
      scroll.jumpTo(pixelsBefore + 60);
      await tester.pump();
      await tester.pump();
      final anchorAfter = tester.getCenter(
        find.text('实时锚点-${presentation.name}'),
      );
      final after = tester.getCenter(find.text('实时选项一'));
      expect(scroll.offset, closeTo(pixelsBefore + 60, .01));
      expect(anchorAfter.dy, closeTo(anchorBefore.dy - 60, .01));
      expect(
        after.dy,
        closeTo(before.dy - 60, .01),
        reason: '${presentation.name} popup must follow its live anchor',
      );

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      scroll.dispose();
      expect(tester.takeException(), isNull);
    }

    await verify(MiuixPopupPresentation.overlay);
    await verify(MiuixPopupPresentation.window);
  });

  testWidgets('open dropdown refreshes rebuilt entries and callback owner', (
    tester,
  ) async {
    var entries = const <MiuixDropdownEntry<String>>[
      MiuixDropdownEntry(value: 'a', label: '旧选项 A'),
      MiuixDropdownEntry(value: 'b', label: '旧选项 B'),
    ];
    var selected = '';
    ValueChanged<String> handler = (value) => selected = 'old:$value';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Center(
                  child: MiuixDropdownMenuButton<String>(
                    presentation: MiuixPopupPresentation.overlay,
                    entries: entries,
                    onSelected: handler,
                    child: const Text('动态菜单锚点'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('动态菜单锚点'));
    await tester.pumpAndSettle();
    expect(find.text('旧选项 A'), findsOneWidget);

    updateHost(() {
      entries = const <MiuixDropdownEntry<String>>[
        MiuixDropdownEntry(value: 'b', label: '新选项 B'),
        MiuixDropdownEntry(value: 'c', label: '新选项 C'),
      ];
      handler = (value) => selected = 'new:$value';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('旧选项 A'), findsNothing);
    expect(find.text('新选项 B'), findsOneWidget);
    expect(find.text('新选项 C'), findsOneWidget);

    await tester.tap(find.text('新选项 C'));
    await tester.pumpAndSettle();
    expect(selected, 'new:c');
    expect(tester.takeException(), isNull);
  });

  testWidgets('open dropdown preference refreshes entries and callback owner', (
    tester,
  ) async {
    var entries = const <MiuixDropdownEntry<String>>[
      MiuixDropdownEntry(value: 'a', label: '偏好旧选项 A'),
      MiuixDropdownEntry(value: 'b', label: '偏好旧选项 B'),
    ];
    var selected = '';
    ValueChanged<String> handler = (value) => selected = 'old:$value';
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return MiuixDropdownPreference<String>(
                  title: '动态偏好菜单',
                  value: 'b',
                  entries: entries,
                  presentation: MiuixPopupPresentation.overlay,
                  onChanged: handler,
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('动态偏好菜单'));
    await tester.pumpAndSettle();
    expect(find.text('偏好旧选项 A'), findsOneWidget);

    updateHost(() {
      entries = const <MiuixDropdownEntry<String>>[
        MiuixDropdownEntry(value: 'b', label: '偏好新选项 B'),
        MiuixDropdownEntry(value: 'c', label: '偏好新选项 C'),
      ];
      handler = (value) => selected = 'new:$value';
    });
    await tester.pump();
    await tester.pump();
    expect(find.text('偏好旧选项 A'), findsNothing);
    // The selected value appears once in the preference trailing action and
    // once in the still-open popup.
    expect(find.text('偏好新选项 B'), findsNWidgets(2));
    expect(find.text('偏好新选项 C'), findsOneWidget);

    await tester.tap(find.text('偏好新选项 C'));
    await tester.pumpAndSettle();
    expect(selected, 'new:c');
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'open grouped dropdown preference refreshes groups and callback owner',
    (tester) async {
      var groups = const <MiuixDropdownGroup<String>>[
        MiuixDropdownGroup<String>(
          entries: [
            MiuixDropdownEntry(value: 'a', label: '分组旧选项 A'),
            MiuixDropdownEntry(value: 'b', label: '分组旧选项 B'),
          ],
        ),
      ];
      var selected = '';
      ValueChanged<String> handler = (value) => selected = 'old:$value';
      late StateSetter updateHost;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return MiuixGroupedDropdownPreference<String>(
                    title: '动态分组偏好菜单',
                    groups: groups,
                    presentation: MiuixPopupPresentation.overlay,
                    onSelected: handler,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('动态分组偏好菜单'));
      await tester.pumpAndSettle();
      expect(find.text('分组旧选项 A'), findsOneWidget);

      updateHost(() {
        groups = const <MiuixDropdownGroup<String>>[
          MiuixDropdownGroup<String>(
            entries: [
              MiuixDropdownEntry(value: 'b', label: '分组新选项 B'),
              MiuixDropdownEntry(value: 'c', label: '分组新选项 C'),
            ],
          ),
        ];
        handler = (value) => selected = 'new:$value';
      });
      await tester.pump();
      await tester.pump();
      expect(find.text('分组旧选项 A'), findsNothing);
      expect(find.text('分组新选项 B'), findsOneWidget);
      expect(find.text('分组新选项 C'), findsOneWidget);

      await tester.tap(find.text('分组新选项 C'));
      await tester.pumpAndSettle();
      expect(selected, 'new:c');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('window dropdown dismissal restores the trigger focus scope', (
    tester,
  ) async {
    final focus = FocusNode(debugLabel: 'dropdown-trigger-owner');
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Focus(
              focusNode: focus,
              autofocus: true,
              child: Center(
                child: MiuixDropdownMenuButton<String>(
                  presentation: MiuixPopupPresentation.window,
                  entries: const [
                    MiuixDropdownEntry(value: 'a', label: '焦点选项'),
                  ],
                  onSelected: (_) {},
                  child: const Text('焦点锚点'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(focus.hasFocus, isTrue);

    await tester.tap(find.text('焦点锚点'));
    await tester.pumpAndSettle();
    expect(find.text('焦点选项'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source dropdown and spinner rows keep exact outer geometry', (
    tester,
  ) async {
    const density = 3.0;
    tester.view.physicalSize = const Size(2400, 1800);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selectedIndex = -1;
    const firstKey = ValueKey('source-dropdown-first');
    const lastKey = ValueKey('source-dropdown-last');
    const spinnerKey = ValueKey('source-spinner-dialog');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: MiuixDropdownImpl(
                    key: firstKey,
                    text: '第一项',
                    optionSize: 2,
                    isSelected: true,
                    index: 0,
                    onSelectedIndexChange: (value) => selectedIndex = value,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: MiuixDropdownImpl(
                    key: lastKey,
                    text: '第二项',
                    optionSize: 2,
                    isSelected: false,
                    index: 1,
                    onSelectedIndexChange: (value) => selectedIndex = value,
                  ),
                ),
                MiuixSpinnerItemImpl(
                  key: spinnerKey,
                  entry: const MiuixSpinnerEntry(title: '对话框选项', summary: '摘要'),
                  entryCount: 1,
                  isSelected: true,
                  index: 0,
                  dialogMode: true,
                  onSelectedIndexChange: (value) => selectedIndex = value,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Compose publishes complete rows as integer-pixel placeables. At 3x,
    // ceil((20 + 54/2.625 + 12) * 3) = 158px for the edge dropdown rows.
    expect(tester.getSize(find.byKey(firstKey)).height, closeTo(158 / 3, .01));
    expect(tester.getSize(find.byKey(lastKey)).height, closeTo(158 / 3, .01));
    // The rich dialog row encloses 20.6 + 14.8 + 12 + 12dp to 179px.
    expect(
      tester.getSize(find.byKey(spinnerKey)).height,
      closeTo(179 / 3, .01),
    );
    expect(tester.getSize(find.byKey(spinnerKey)).width, 800);

    await tester.tap(find.text('第二项'));
    expect(selectedIndex, 1);
    await tester.tap(find.text('对话框选项'));
    expect(selectedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source long dropdown wraps into exact 420dpi viewport', (
    tester,
  ) async {
    const density = 2.625;
    const popupKey = ValueKey('source-long-dropdown-popup');
    const labels = [
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
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: UnconstrainedBox(
                child: MiuixListPopupColumn(
                  key: popupKey,
                  children: [
                    for (var index = 0; index < labels.length; index++)
                      MiuixDropdownImpl(
                        text: labels[index],
                        optionSize: labels.length,
                        isSelected: index == 0,
                        index: index,
                        onSelectedIndexChange: (_) {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final popupSize = tester.getSize(find.byKey(popupKey));
    expect(popupSize.width * density, closeTo(756, .01));
    expect(popupSize.height * density, closeTo(1137, .01));
    expect(
      tester.getSize(find.text(labels.first)).height * density,
      closeTo(49.875, .01),
    );
    expect(tester.getSize(find.text(labels[7])).height * density, 99);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list popup measures width from only its first eight rows', (
    tester,
  ) async {
    const popupKey = ValueKey('source-list-popup-column');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: UnconstrainedBox(
              child: MiuixListPopupColumn(
                key: popupKey,
                children: [
                  SizedBox(width: 40, height: 10),
                  SizedBox(width: 50, height: 10),
                  SizedBox(width: 60, height: 10),
                  SizedBox(width: 70, height: 10),
                  SizedBox(width: 80, height: 10),
                  SizedBox(width: 90, height: 10),
                  SizedBox(width: 100, height: 10),
                  SizedBox(width: 110, height: 10),
                  SizedBox(width: 600, height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Current ListPopupColumn gives both width and viewport height to only the
    // first eight children. The ninth 10dp row remains laid out and scrollable
    // inside the resulting 80dp viewport.
    expect(tester.getSize(find.byKey(popupKey)), const Size(200, 80));
    final scrollable = find.descendant(
      of: find.byKey(popupKey),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    expect(position.maxScrollExtent, 10);
    await tester.drag(scrollable, const Offset(0, -10));
    await tester.pumpAndSettle();
    expect(position.pixels, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlay long dropdown owns a physical touch drag above a scrollable page',
    (tester) async {
      final pageController = ScrollController();
      addTearDown(pageController.dispose);
      final items = List<String>.generate(25, (index) => '弹窗选项 $index');

      await tester.pumpWidget(
        MaterialApp(
          scrollBehavior: const MiuixScrollBehavior(showScrollbars: false),
          home: MiuixTheme(
            child: MiuixScaffold(
              body: ListView(
                controller: pageController,
                children: [
                  const SizedBox(height: 180),
                  MiuixOverlayDropdownPreference.source(
                    title: '长下拉菜单',
                    items: items,
                    selectedIndex: 0,
                    onSelectedIndexChange: (_) {},
                  ),
                  const SizedBox(height: 1600),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('长下拉菜单'));
      await tester.pumpAndSettle();

      final popup = find.byType(MiuixListPopupColumn);
      final popupScrollable = find.descendant(
        of: popup,
        matching: find.byType(Scrollable),
      );
      final popupPosition = tester
          .state<ScrollableState>(popupScrollable)
          .position;
      final popupRect = tester.getRect(popup);
      final pagePixelsBefore = pageController.position.pixels;

      // Use a raw touch sequence at the popup's painted screen coordinate.
      // Dragging the Scrollable finder directly can conceal a Stack hit-test
      // error because WidgetTester chooses that descendant as the target. The
      // device sends only coordinates, so this fixture follows the Android
      // path and simultaneously verifies that the full-screen barrier does not
      // forward the same vertical gesture to the underlying preference page.
      final dragStart = Offset(popupRect.center.dx, popupRect.bottom - 24);
      final gesture = await tester.startGesture(
        dragStart,
        kind: PointerDeviceKind.touch,
      );
      // The first MOVE crosses touch slop; the second one verifies that the
      // popup's accepted vertical gesture updates its independent position.
      await gesture.moveBy(const Offset(0, -40));
      await gesture.moveBy(const Offset(0, -140));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(popupPosition.maxScrollExtent, greaterThan(0));
      expect(popupPosition.pixels, greaterThan(0));
      expect(pageController.position.pixels, pagePixelsBefore);
      expect(find.byType(MiuixListPopupColumn), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('list popup layout and independent motion match source tokens', () {
    final motion = debugMiuixListPopupMotion();
    expect(motion.dampingRatio, .82);
    expect(motion.stiffness, 362.5);
    expect(motion.visibilityThreshold, .0001);
    expect(motion.fractionDuration, const Duration(milliseconds: 620));
    expect(motion.alphaEnterDuration, const Duration(milliseconds: 200));
    expect(motion.alphaExitDuration, const Duration(milliseconds: 150));
    expect(motion.dimEnterDuration, const Duration(milliseconds: 300));
    expect(motion.dimExitDuration, const Duration(milliseconds: 150));
    expect(motion.fractionAt200ms, closeTo(.973415, .00001));

    final below = resolveMiuixListPopupLayoutInfo(
      alignment: MiuixPopupAlignment.start,
      popupPositionProvider: MiuixListPopupDefaults.dropdownPositionProvider,
      parentBounds: const Rect.fromLTRB(100, 200, 150, 240),
      popupContentSize: const Size(200, 100),
      containerSize: const Size(400, 800),
      windowBounds: const Rect.fromLTRB(0, 0, 400, 800),
      textDirection: TextDirection.ltr,
    );
    expect(
      below.popupLayoutPosition,
      const MiuixPopupLayoutPosition(
        showBelow: true,
        showAbove: false,
        isRightAligned: false,
      ),
    );
    expect(below.localTransformOrigin, const MiuixTransformOrigin(0, 0));
    expect(
      below.effectiveTransformOrigin,
      const MiuixTransformOrigin(.25, .31),
    );

    final above = resolveMiuixListPopupLayoutInfo(
      alignment: MiuixPopupAlignment.start,
      popupPositionProvider: MiuixListPopupDefaults.dropdownPositionProvider,
      parentBounds: const Rect.fromLTRB(100, 700, 150, 740),
      popupContentSize: const Size(200, 100),
      containerSize: const Size(400, 800),
      windowBounds: const Rect.fromLTRB(0, 0, 400, 800),
      textDirection: TextDirection.ltr,
    );
    expect(
      above.popupLayoutPosition,
      const MiuixPopupLayoutPosition(
        showBelow: false,
        showAbove: true,
        isRightAligned: false,
      ),
    );
    expect(above.localTransformOrigin, const MiuixTransformOrigin(0, 1));
    expect(
      above.effectiveTransformOrigin,
      const MiuixTransformOrigin(.25, .865),
    );
  });

  testWidgets('source PopupLayout registers with host and owns Back', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);
    var label = '原版弹层内容';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return MiuixPopupLayout.source(
                  visible: visible,
                  child: Center(child: Text(label)),
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('原版弹层内容'), findsNothing);

    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('原版弹层内容'), findsOneWidget);

    // PopupLayout's dim layer consumes outside input but does not treat it as
    // an implicit dismissal request.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(visible.value, isTrue);
    expect(find.text('原版弹层内容'), findsOneWidget);

    label = '更新后的弹层内容';
    rebuild(() {});
    // One frame updates the registration and the following host frame swaps
    // the content, mirroring Compose's rememberUpdatedState hand-off.
    await tester.pumpAndSettle();
    expect(find.text('原版弹层内容'), findsNothing);
    expect(find.text('更新后的弹层内容'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(visible.value, isFalse);
    expect(find.text('更新后的弹层内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source DialogLayout keeps compact motion and exit callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final visible = ValueNotifier<bool>(false);
    final dimAlpha = ValueNotifier<double>(.25);
    addTearDown(visible.dispose);
    addTearDown(dimAlpha.dispose);
    var dismissFinished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixDialogLayout.source(
              visible: visible,
              enableAutoLargeScreen: false,
              dimAlpha: dimAlpha,
              onDismissFinished: () => dismissFinished++,
              child: const Center(child: Text('原版对话框宿主')),
            ),
          ),
        ),
      ),
    );

    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('原版对话框宿主'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('原版对话框宿主'),
        matching: find.byKey(const ValueKey('miuix-host-dialog-slide')),
      ),
      findsOneWidget,
    );

    // DialogLayout itself only hosts content; outside dismissal belongs to
    // DialogContentLayout, so the generic dim layer must consume this tap.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(visible.value, isTrue);

    dimAlpha.value = 2;
    await tester.pump();
    expect(tester.takeException(), isNull);

    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.text('原版对话框宿主'), findsNothing);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source PopupHost renders the current Scaffold state', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            // Upstream Scaffold accepts MiuixPopupHost() as a renderer slot.
            // It must reuse this Scaffold's state instead of nesting a scope.
            popupHost: const MiuixPopupHost(),
            body: MiuixPopupLayout.source(
              visible: visible,
              child: const Center(child: Text('当前脚手架弹层')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(MiuixPopupHost), findsOneWidget);
    expect(find.byType(MiuixPopupHostView), findsOneWidget);
    expect(find.text('当前脚手架弹层'), findsNothing);

    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('当前脚手架弹层'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(visible.value, isFalse);
    expect(find.text('当前脚手架弹层'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source popup z-order belongs to composition identity', (
    tester,
  ) async {
    final firstVisible = ValueNotifier<bool>(false);
    final secondVisible = ValueNotifier<bool>(false);
    addTearDown(firstVisible.dispose);
    addTearDown(secondVisible.dispose);
    var firstTaps = 0;
    var secondTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Stack(
              children: [
                MiuixPopupLayout.source(
                  visible: firstVisible,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => firstTaps++,
                    child: const SizedBox.expand(),
                  ),
                ),
                MiuixPopupLayout.source(
                  visible: secondVisible,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => secondTaps++,
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // The later-composed state owns the higher source z-index even though the
    // earlier-composed state is opened last.
    secondVisible.value = true;
    await tester.pumpAndSettle();
    firstVisible.value = true;
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    expect(firstTaps, 0);
    expect(secondTaps, 1);

    firstVisible.value = false;
    secondVisible.value = false;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('source dialog hides IME focus and disposes visible state', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    final focusNode = FocusNode();
    addTearDown(visible.dispose);
    addTearDown(focusNode.dispose);

    Widget fixture(bool includeDialog) {
      return MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: includeDialog
                ? MiuixDialogLayout.source(
                    visible: visible,
                    child: Center(
                      child: Material(
                        child: TextField(
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: '对话框输入框',
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }

    await tester.pumpWidget(fixture(true));
    visible.value = true;
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    visible.value = false;
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    await tester.pumpAndSettle();

    visible.value = true;
    await tester.pumpAndSettle();
    await tester.pumpWidget(fixture(false));
    await tester.pumpAndSettle();
    expect(visible.value, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source popup replaces changed visible-state identity safely', (
    tester,
  ) async {
    final firstVisible = ValueNotifier<bool>(true);
    final secondVisible = ValueNotifier<bool>(true);
    addTearDown(firstVisible.dispose);
    addTearDown(secondVisible.dispose);
    var currentVisible = firstVisible;
    var label = '第一状态';
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return MiuixPopupLayout.source(
                  visible: currentVisible,
                  child: Center(child: Text(label)),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('第一状态'), findsOneWidget);

    currentVisible = secondVisible;
    label = '第二状态';
    rebuild(() {});
    await tester.pumpAndSettle();

    expect(firstVisible.value, isFalse);
    expect(secondVisible.value, isTrue);
    expect(find.text('第一状态'), findsNothing);
    expect(find.text('第二状态'), findsOneWidget);
    expect(tester.takeException(), isNull);

    secondVisible.value = false;
    await tester.pumpAndSettle();
  });

  testWidgets('source popup runs four independent custom transitions', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);
    var contentProgress = -1.0;
    var dimProgress = -1.0;

    MiuixVisibilityTransition transition({
      required Duration duration,
      required ValueChanged<double> report,
      required String key,
    }) {
      return MiuixVisibilityTransition.custom(
        duration: duration,
        builder: (context, animation, child) {
          return AnimatedBuilder(
            key: ValueKey(key),
            animation: animation,
            child: child,
            builder: (context, child) {
              report(animation.value);
              return Opacity(
                opacity: animation.value.clamp(0.0, 1.0),
                child: child,
              );
            },
          );
        },
      );
    }

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixPopupLayout.source(
              visible: visible,
              enterTransition: transition(
                duration: const Duration(milliseconds: 1000),
                report: (value) => contentProgress = value,
                key: 'custom-content-enter',
              ),
              exitTransition: transition(
                duration: const Duration(milliseconds: 100),
                report: (value) => contentProgress = value,
                key: 'custom-content-exit',
              ),
              dimEnterTransition: transition(
                duration: const Duration(milliseconds: 2000),
                report: (value) => dimProgress = value,
                key: 'custom-dim-enter',
              ),
              dimExitTransition: transition(
                duration: const Duration(milliseconds: 300),
                report: (value) => dimProgress = value,
                key: 'custom-dim-exit',
              ),
              child: const Center(child: Text('自定义四路动画')),
            ),
          ),
        ),
      ),
    );

    visible.value = true;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(contentProgress, closeTo(.5, .02));
    expect(dimProgress, closeTo(.25, .02));
    expect(find.byKey(const ValueKey('custom-content-enter')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-dim-enter')), findsOneWidget);

    await tester.pumpAndSettle();
    visible.value = false;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(contentProgress, closeTo(0, .02));
    expect(dimProgress, closeTo(.5, .02));
    // The content transition is done, but source host ownership continues
    // until the independently longer dim exit also reaches its hidden state.
    expect(find.text('自定义四路动画'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-content-exit')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-dim-exit')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();
    expect(find.text('自定义四路动画'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('visibility transition composes fade scale and slide', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixPopupLayout.source(
              visible: visible,
              enableWindowDim: false,
              enterTransition: const MiuixVisibilityTransition(
                duration: Duration(milliseconds: 1000),
                hiddenOpacity: .2,
                hiddenScale: .5,
                hiddenOffset: Offset(1, 0),
                scaleAlignment: Alignment.topLeft,
              ),
              child: const Center(child: Text('组合动画')),
            ),
          ),
        ),
      ),
    );

    visible.value = true;
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final text = find.text('组合动画');
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: text, matching: find.byType(FadeTransition)).first,
    );
    final scale = tester.widget<ScaleTransition>(
      find.ancestor(of: text, matching: find.byType(ScaleTransition)).first,
    );
    final slide = tester.widget<SlideTransition>(
      find.ancestor(of: text, matching: find.byType(SlideTransition)).first,
    );
    expect(fade.opacity.value, closeTo(.6, .02));
    expect(scale.scale.value, closeTo(.75, .02));
    expect(scale.alignment, Alignment.topLeft);
    expect(slide.position.value.dx, closeTo(.5, .02));

    visible.value = false;
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog normalizes invalid dynamic panel geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixDialog(
              maxWidth: double.nan,
              cornerRadius: -10,
              content: Text('safe dialog geometry'),
            ),
          ),
        ),
      ),
    );

    final dialog = find.byType(MiuixDialog);
    final glass = tester.widget<MiuixGlass>(
      find.descendant(of: dialog, matching: find.byType(MiuixGlass)),
    );
    final constrained = tester
        .widgetList<ConstrainedBox>(
          find.descendant(of: dialog, matching: find.byType(ConstrainedBox)),
        )
        .singleWhere(
          (box) => box.constraints.maxWidth == MiuixDialogDefaults.maxWidth,
        );
    expect(
      glass.radius,
      MiuixTheme.of(tester.element(dialog)).hyperOs4.dialogCornerRadius,
    );
    expect(constrained.constraints.maxWidth, MiuixDialogDefaults.maxWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hosted transitions normalize invalid release endpoints', (
    tester,
  ) async {
    final visible = ValueNotifier<bool>(false);
    addTearDown(visible.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixPopupLayout.source(
              visible: visible,
              enableWindowDim: false,
              enterTransition: const MiuixVisibilityTransition(
                duration: Duration(milliseconds: -1),
                hiddenOpacity: double.nan,
                hiddenScale: double.infinity,
                hiddenOffset: Offset(double.nan, double.infinity),
              ),
              exitTransition: const MiuixVisibilityTransition.fade(
                duration: Duration(milliseconds: -1),
                hiddenOpacity: double.infinity,
              ),
              child: const Text('safe transition'),
            ),
          ),
        ),
      ),
    );

    visible.value = true;
    await tester.pumpAndSettle();
    expect(find.text('safe transition'), findsOneWidget);
    visible.value = false;
    await tester.pumpAndSettle();
    expect(find.text('safe transition'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('popup triggers and source rows tolerate empty dynamic input', (
    tester,
  ) async {
    var dropdownIndex = -1;
    var spinnerIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MiuixDropdownMenuButton<int>(
                entries: const <MiuixDropdownEntry<int>>[],
                onSelected: (_) {},
              ),
              MiuixIconDropdownMenu<int>(
                icon: const Icon(Icons.more_horiz),
                entries: const <MiuixDropdownEntry<int>>[],
                onSelected: (_) {},
              ),
              MiuixDropdownImpl(
                text: 'normalized dropdown row',
                optionSize: -4,
                isSelected: false,
                index: -2,
                onSelectedIndexChange: (value) => dropdownIndex = value,
              ),
              MiuixSpinnerItemImpl(
                entry: const MiuixSpinnerEntry(title: 'normalized spinner row'),
                entryCount: -3,
                isSelected: false,
                index: -1,
                onSelectedIndexChange: (value) => spinnerIndex = value,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('normalized dropdown row'));
    await tester.tap(find.text('normalized spinner row'));
    expect(dropdownIndex, 0);
    expect(spinnerIndex, 0);
    expect(tester.takeException(), isNull);
  });
}
