part of '../miuix_flutter_test.dart';

// 保留原测试注册顺序和公共夹具；按弹层职责拆分超长文件。
void _registerOverlayHostSheetTests() {
  testWidgets('scaffold owns an isolated popup host with hide lifecycle', (
    tester,
  ) async {
    MiuixPopupHostController? controller;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) {
                controller = MiuixPopupHostScope.maybeOf(context);
                return const Text('Scaffold content');
              },
            ),
          ),
        ),
      ),
    );

    expect(controller, isNotNull);
    var dismissFinished = false;
    final closed = controller!.show<void>(
      child: const MiuixSurface(child: Text('Hosted popup')),
      onDismissFinished: () => dismissFinished = true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Hosted popup'), findsOneWidget);
    final popupContext = tester.element(find.text('Hosted popup'));
    expect(DefaultTextStyle.of(popupContext).style.fontSize, 17);
    expect(
      DefaultTextStyle.of(popupContext).style.color,
      MiuixSemanticColors.of(popupContext)['onSurface'],
    );

    controller!.dismissTop();
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    await closed;

    expect(find.text('Hosted popup'), findsNothing);
    expect(dismissFinished, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android Back dismisses an overlay before its application page', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => MiuixTheme(
                  child: MiuixScaffold(
                    body: Builder(
                      builder: (context) => TextButton(
                        onPressed: () => MiuixOverlayDialog.show<void>(
                          context: context,
                          title: 'Back-owned overlay',
                          content: const Text('Overlay content'),
                        ),
                        child: const Text('Show overlay'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            child: const Text('Open application page'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open application page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show overlay'));
    await tester.pumpAndSettle();
    expect(find.text('Back-owned overlay'), findsOneWidget);

    await tester.binding.handlePopRoute();
    // A second platform request can be queued before the reverse animation
    // receives its first frame. It must remain owned by the hosted entry and
    // must not escape to the application route behind that entry.
    await tester.binding.handlePopRoute();
    await tester.pump();
    // The source dialog owns a 260ms decelerating exit; wait past that point
    // before asserting that the hosted entry has been physically removed.
    await tester.pump(const Duration(milliseconds: 280));

    expect(find.text('Back-owned overlay'), findsNothing);
    expect(find.text('Show overlay'), findsOneWidget);
    expect(find.text('Open application page'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay Back does not trigger an ancestor pager PopScope', (
    tester,
  ) async {
    final selectedPage = ValueNotifier<int>(1);
    addTearDown(selectedPage.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<int>(
          valueListenable: selectedPage,
          builder: (context, page, child) {
            return PopScope<void>(
              canPop: page == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop && page != 0) {
                  selectedPage.value = 0;
                }
              },
              child: MiuixTheme(
                child: MiuixScaffold(
                  body: Column(
                    children: [
                      Text('Page $page'),
                      MiuixOverlayDropdownPreference<int>(
                        title: 'Overlay choice',
                        value: 1,
                        entries: const [
                          MiuixDropdownEntry(value: 1, label: 'One'),
                          MiuixDropdownEntry(value: 2, label: 'Two'),
                        ],
                        onChanged: (_) {},
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Overlay choice'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Two'), findsOneWidget);

    await tester.binding.handlePopRoute();
    expect(selectedPage.value, 1);
    // The popup remains the route-local Back owner while its source reset
    // spring is mounted, so a queued second request cannot reach the
    // pager-level PopScope either.
    await tester.binding.handlePopRoute();
    expect(selectedPage.value, 1);
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);

    expect(find.text('Two'), findsNothing);
    expect(find.text('Page 1'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Page 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay and window dropdowns use distinct anchored routes', (
    tester,
  ) async {
    var overlayValue = '';
    var windowValue = '';
    final overlayExpansion = <bool>[];
    final windowExpansion = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(80),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MiuixOverlayDropdownMenu<String>(
                      entries: const [
                        MiuixDropdownEntry(
                          value: 'overlay',
                          label: 'Overlay option',
                        ),
                      ],
                      onSelected: (value) => overlayValue = value,
                      onExpandedChange: overlayExpansion.add,
                      child: const Text('Overlay anchor'),
                    ),
                    const SizedBox(height: 80),
                    MiuixWindowDropdownMenu<String>(
                      entries: const [
                        MiuixDropdownEntry(
                          value: 'window',
                          label: 'Window option',
                        ),
                      ],
                      onSelected: (value) => windowValue = value,
                      onExpandedChange: windowExpansion.add,
                      child: const Text('Window anchor'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final baselineBarriers = find.byType(ModalBarrier).evaluate().length;
    final overlayAnchor = tester.getRect(find.text('Overlay anchor'));
    await tester.tap(find.text('Overlay anchor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(MiuixListPopup<String>), findsOneWidget);
    expect(find.byType(ModalBarrier).evaluate().length, baselineBarriers);
    final overlayPopup = tester.getRect(find.byType(MiuixListPopup<String>));
    expect(overlayPopup.top, closeTo(overlayAnchor.bottom, 18));
    await tester.tap(find.text('Overlay option'));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    expect(overlayValue, 'overlay');
    expect(overlayExpansion, [true, false]);

    final windowAnchor = tester.getRect(find.text('Window anchor'));
    await tester.tap(find.text('Window anchor'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(
      find.byType(ModalBarrier).evaluate().length,
      greaterThan(baselineBarriers),
    );
    final windowPopup = tester.getRect(find.byType(MiuixListPopup<String>));
    expect(windowPopup.top, closeTo(windowAnchor.bottom, 18));
    await tester.tap(find.text('Window option'));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    expect(windowValue, 'window');
    expect(windowExpansion, [true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown preference stays held while its popup is expanded', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixOverlayDropdownPreference<String>(
              key: ValueKey('held-dropdown-preference'),
              title: 'Held dropdown',
              value: 'one',
              entries: [
                MiuixDropdownEntry(value: 'one', label: 'One'),
                MiuixDropdownEntry(value: 'two', label: 'Two'),
              ],
              onChanged: _ignoreString,
            ),
          ),
        ),
      ),
    );

    Finder anchorPressable() => find.descendant(
      of: find.byKey(const ValueKey('held-dropdown-preference')),
      matching: find.byType(MiuixPressable),
    );

    expect(tester.widget<MiuixPressable>(anchorPressable()).holdDown, isFalse);
    await tester.tap(find.text('Held dropdown'));
    await tester.pump();
    expect(tester.widget<MiuixPressable>(anchorPressable()).holdDown, isTrue);

    await tester.pump(MiuixListPopupDefaults.alphaEnterDuration);
    await tester.tap(find.text('Two'));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    expect(tester.widget<MiuixPressable>(anchorPressable()).holdDown, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled composite preferences and menus stay inactive', (
    tester,
  ) async {
    var switchChanges = 0;
    var dropdownChanges = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Column(
              children: [
                MiuixSwitchPreference(
                  title: 'Disabled switch preference',
                  value: true,
                  enabled: false,
                  onChanged: (_) => switchChanges++,
                ),
                MiuixOverlayDropdownPreference<String>(
                  key: const ValueKey('disabled-dropdown-preference'),
                  title: 'Disabled dropdown preference',
                  value: 'one',
                  enabled: false,
                  entries: const [
                    MiuixDropdownEntry(value: 'one', label: 'One'),
                  ],
                  onChanged: (_) => dropdownChanges++,
                ),
                MiuixOverlayDropdownMenu<String>(
                  enabled: false,
                  entries: const [
                    MiuixDropdownEntry(value: 'one', label: 'Menu one'),
                  ],
                  onSelected: (_) => dropdownChanges++,
                  child: const Text('Disabled dropdown menu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final disabledDropdown = find.byKey(
      const ValueKey('disabled-dropdown-preference'),
    );
    expect(
      find.descendant(of: disabledDropdown, matching: find.text('One')),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: disabledDropdown,
              matching: find.byType(CustomPaint),
            ),
          )
          .any((paint) => paint.size == const Size(10, 16)),
      isTrue,
    );
    await tester.tap(find.text('Disabled switch preference'));
    await tester.tap(find.text('Disabled dropdown preference'));
    await tester.tap(find.text('Disabled dropdown menu'));
    await tester.pump(const Duration(milliseconds: 220));

    expect(switchChanges, 0);
    expect(dropdownChanges, 0);
    expect(find.byType(MiuixListPopup<String>), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('window dialog and bottom sheet report completed lifecycles', (
    tester,
  ) async {
    var dialogRequested = 0;
    var dialogFinished = 0;
    var sheetRequested = 0;
    var sheetFinished = 0;
    late BuildContext routeContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              routeContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    final dialog = MiuixWindowDialog.show<void>(
      context: routeContext,
      title: 'Window dialog lifecycle',
      content: const Text('Dialog content'),
      onDismissRequest: () {
        expect(dialogFinished, 0);
        dialogRequested++;
      },
      onDismissFinished: () => dialogFinished++,
    );
    await tester.pumpAndSettle();
    Navigator.of(routeContext, rootNavigator: true).pop();
    await tester.pump();
    expect(dialogRequested, 1);
    await tester.pump(const Duration(milliseconds: 280));
    await dialog;

    expect(dialogRequested, 1);
    expect(dialogFinished, 1);

    final sheet = MiuixWindowBottomSheet.show<void>(
      context: routeContext,
      child: const Text('Window sheet lifecycle'),
      onDismissRequest: () {
        expect(sheetFinished, 0);
        sheetRequested++;
      },
      onDismissFinished: () => sheetFinished++,
    );
    await tester.pumpAndSettle();
    Navigator.of(routeContext, rootNavigator: true).pop();
    await tester.pump();
    expect(sheetRequested, 1);
    await tester.pump(const Duration(milliseconds: 220));
    // 关闭结果已经返回，但源弹层的680ms退出动画尚未完成。
    // 完成回调必须等待真实路由退出，而不是仅等待 popped Future。
    expect(sheetFinished, 0);
    await tester.pumpAndSettle();
    await sheet;

    expect(sheetRequested, 1);
    expect(sheetFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('window dialog forwards the current source layout parameters', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    late BuildContext routeContext;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              routeContext = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );

    const background = Color(0xff234567);
    const titleColor = Color(0xffabcdef);
    const summaryColor = Color(0xfffedcba);
    final closed = MiuixWindowDialog.show<void>(
      context: routeContext,
      summary: '只有摘要',
      content: const SizedBox(width: 280, height: 40),
      titleColor: titleColor,
      summaryColor: summaryColor,
      backgroundColor: background,
      enableWindowDim: false,
      outsideMargin: const EdgeInsets.fromLTRB(30, 0, 40, 20),
      insideMargin: const EdgeInsets.all(10),
      defaultWindowInsetsPadding: false,
      maxWidth: 300,
      largeScreen: true,
      cornerRadius: 18,
    );
    await tester.pumpAndSettle();

    final dialog = tester.widget<MiuixDialog>(find.byType(MiuixDialog));
    expect(dialog.title, isNull);
    expect(dialog.summary, '只有摘要');
    expect(dialog.titleColor, titleColor);
    expect(dialog.summaryColor, summaryColor);
    expect(dialog.backgroundColor, background);
    expect(dialog.outsideMargin, const EdgeInsets.fromLTRB(30, 0, 40, 20));
    expect(dialog.insideMargin, const EdgeInsets.all(10));
    expect(dialog.defaultWindowInsetsPadding, isFalse);
    expect(dialog.maxWidth, 300);
    expect(dialog.largeScreen, isTrue);
    expect(dialog.cornerRadius, 18);
    expect(
      find.byKey(const ValueKey('miuix-dialog-title-placeable')),
      findsNothing,
    );
    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final glass = tester.widget<MiuixGlass>(surface);
    expect(glass.color, background);
    expect(glass.enabled, isTrue);
    expect(glass.radius, 18);
    expect(tester.getSize(surface).width, 300);

    Navigator.of(routeContext, rootNavigator: true).pop();
    await tester.pumpAndSettle();
    await closed;
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay dialog can force compact mode on a large window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MiuixOverlayDialog.show<void>(
                  context: context,
                  title: '强制紧凑',
                  content: const Text('紧凑内容'),
                  largeScreen: false,
                ),
                child: const Text('显示对话框'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('显示对话框'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('miuix-host-dialog-slide')), findsOne);
    expect(
      find.byKey(const ValueKey('miuix-host-dialog-large-fade')),
      findsNothing,
    );
    expect(
      tester.widget<MiuixDialog>(find.byType(MiuixDialog)).largeScreen,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  test('OKHSV, OKLab, and OKLCH conversions round-trip sRGB colors', () {
    const samples = [
      Color(0xFF3482FF),
      Color(0xFFE53935),
      Color(0xFF43A047),
      Color(0xB3522D80),
    ];

    void expectNear(Color actual, Color expected, {int tolerance = 3}) {
      int channel(int argb, int shift) => (argb >> shift) & 0xff;
      final actualArgb = actual.toARGB32();
      final expectedArgb = expected.toARGB32();
      for (final shift in const [24, 16, 8, 0]) {
        expect(
          (channel(actualArgb, shift) - channel(expectedArgb, shift)).abs(),
          lessThanOrEqualTo(tolerance),
        );
      }
    }

    for (final sample in samples) {
      expectNear(MiuixOkHsv.fromColor(sample).toColor(), sample);
      expectNear(MiuixOkLab.fromColor(sample).toColor(), sample);
      expectNear(MiuixOkLch.fromColor(sample).toColor(), sample);
    }
  });

  testWidgets('perceptual color pickers render real channel controls', (
    tester,
  ) async {
    final changes = <Color>[];
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SingleChildScrollView(
            child: Column(
              children: [
                MiuixOkHsvColorPicker(
                  color: Colors.blue,
                  onChanged: changes.add,
                  showPreview: false,
                ),
                MiuixOkLabColorPicker(
                  color: Colors.green,
                  onChanged: changes.add,
                ),
                MiuixOkLchColorPicker(
                  color: Colors.red,
                  onChanged: changes.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .widget<MiuixOkHsvColorPicker>(find.byType(MiuixOkHsvColorPicker))
          .colorSpace,
      MiuixColorSpace.okHsv,
    );
    expect(
      tester
          .widget<MiuixOkLabColorPicker>(find.byType(MiuixOkLabColorPicker))
          .colorSpace,
      MiuixColorSpace.okLab,
    );
    expect(
      tester
          .widget<MiuixOkLchColorPicker>(find.byType(MiuixOkLchColorPicker))
          .colorSpace,
      MiuixColorSpace.okLch,
    );

    final okHsvFirst = find.descendant(
      of: find.byType(MiuixOkHsvColorPicker),
      matching: find.byKey(const ValueKey('miuix-color-picker-hue-slider')),
    );
    await tester.drag(okHsvFirst, const Offset(40, 0));
    await tester.pump();

    expect(changes, isNotEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheets keep content height and stay bottom aligned', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: MiuixButton(
                label: 'Open compact sheet',
                onPressed: () {
                  unawaited(
                    MiuixBottomSheet.show<void>(
                      context: context,
                      child: const SizedBox(
                        height: 96,
                        child: Center(child: Text('Compact sheet content')),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open compact sheet'));
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    expect(surface.height, lessThan(180));
    expect(surface.bottom, closeTo(800, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet content stays above the gesture indicator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MiuixButton(
            label: 'Open safe sheet',
            onPressed: () => MiuixBottomSheet.show<void>(
              context: context,
              child: const SizedBox(
                key: ValueKey('safe-sheet-content'),
                height: 96,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open safe sheet'));
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    final content = tester.getRect(
      find.byKey(const ValueKey('safe-sheet-content')),
    );
    expect(surface.bottom, closeTo(800, .1));
    expect(content.bottom, closeTo(776, .1));
    expect(surface.bottom - content.bottom, closeTo(24, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet does not double count navigation under the IME', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding();
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MiuixButton(
            label: 'Open IME sheet',
            onPressed: () => MiuixBottomSheet.show<void>(
              context: context,
              child: const SizedBox(
                key: ValueKey('ime-sheet-content'),
                height: 96,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open IME sheet'));
    await tester.pumpAndSettle();

    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    final content = tester.getRect(
      find.byKey(const ValueKey('ime-sheet-content')),
    );
    expect(surface.bottom, closeTo(480, .1));
    expect(content.bottom, closeTo(surface.bottom, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay sheet covers app navigation and the gesture region', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    var selectedIndex = 0;
    var requestLegacyOpaque = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) => Center(
                child: MiuixButton(
                  label: 'Open overlay sheet',
                  onPressed: () {
                    unawaited(
                      MiuixOverlayBottomSheet.show<void>(
                        context: context,
                        glass: requestLegacyOpaque ? false : null,
                        child: const SizedBox(height: 520),
                      ),
                    );
                  },
                ),
              ),
            ),
            bottomBar: MiuixNavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => selectedIndex = index,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open overlay sheet'));
    await tester.pumpAndSettle();

    final surfaceFinder = find.byKey(
      const ValueKey('miuix-bottom-sheet-surface'),
    );
    final surface = tester.getRect(surfaceFinder);
    final navigation = tester.getRect(find.byType(MiuixNavigationBar));
    // HyperOS 4 defaults to local sampled glass; an explicit false retains the
    // old opaque surface without changing the surrounding transparent host.
    expect(tester.widget<MiuixGlass>(surfaceFinder).enabled, isTrue);
    expect(
      tester.widget<MiuixGlass>(surfaceFinder).optics,
      same(MiuixGlassOptics.transient),
    );
    expect(surface.bottom, closeTo(800, .1));
    expect(surface.top, lessThan(navigation.top));
    await tester.tapAt(Offset(navigation.right - 90, navigation.center.dy));
    await tester.pump();
    expect(selectedIndex, 0);
    expect(find.byKey(const ValueKey('miuix-bottom-sheet-surface')), findsOne);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();
    requestLegacyOpaque = true;
    await tester.tap(find.text('Open overlay sheet'));
    await tester.pumpAndSettle();
    expect(tester.widget<MiuixGlass>(surfaceFinder).enabled, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom-sheet behavior updates while the route is visible', (
    tester,
  ) async {
    final behavior = MiuixBottomSheetController();
    addTearDown(behavior.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: MiuixButton(
                label: 'Open behavior sheet',
                onPressed: () {
                  unawaited(
                    MiuixBottomSheet.show<void>(
                      context: context,
                      controller: behavior,
                      child: const SizedBox(
                        height: 120,
                        child: Center(child: Text('Behavior sheet body')),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open behavior sheet'));
    await tester.pumpAndSettle();
    behavior.allowDismiss = false;
    await tester.pump();
    await tester.tapAt(const Offset(8, 8));
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('Behavior sheet body'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 260));
    expect(find.text('Behavior sheet body'), findsOneWidget);

    behavior.dismiss();
    await tester.pumpAndSettle();
    expect(find.text('Behavior sheet body'), findsNothing);

    behavior.allowDismiss = true;
    await tester.tap(find.text('Open behavior sheet'));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
    final handle = find.byKey(
      const ValueKey('miuix-bottom-sheet-drag-handle-area'),
    );
    behavior.enableNestedScroll = false;
    await tester.pump();
    await tester.drag(surface, const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(surface, findsOneWidget);
    // BottomSheetContentLayout always lets the dedicated handle drag the
    // sheet. enableNestedScroll controls only the child-scroll bridge.
    await tester.drag(handle, const Offset(0, 220));
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'bottom-sheet handle preserves source damping and press geometry',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final behavior = MiuixBottomSheetController(
        allowDismiss: false,
        enableNestedScroll: false,
      );
      addTearDown(behavior.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MiuixBottomSheet.show<void>(
                  context: context,
                  controller: behavior,
                  child: const SizedBox(height: 260),
                ),
                child: const Text('Open damping sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open damping sheet'));
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
      final handleArea = find.byKey(
        const ValueKey('miuix-bottom-sheet-drag-handle-area'),
      );
      final handle = find.byKey(
        const ValueKey('miuix-bottom-sheet-drag-handle'),
      );
      final restingTop = tester.getTopLeft(surface).dy;
      expect(tester.getSize(handle), const Size(45, 4));

      final upward = await tester.startGesture(tester.getCenter(handleArea));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getSize(handle), const Size(55, 4));
      final pressed = tester.widget<AnimatedContainer>(handle);
      expect(pressed.transform!.getMaxScaleOnAxis(), closeTo(1.15, .001));
      // The first movement wins the vertical gesture arena. Measuring from the
      // resulting pose makes the second movement an exact source delta.
      await upward.moveBy(
        const Offset(0, -30),
        timeStamp: const Duration(milliseconds: 100),
      );
      await tester.pump();
      final acceptedTop = tester.getTopLeft(surface).dy;
      expect(acceptedTop, closeTo(restingTop - 2.2, .01));
      await upward.moveBy(
        const Offset(0, -100),
        timeStamp: const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(tester.getTopLeft(surface).dy, closeTo(acceptedTop - 10, .01));
      expect(
        find.byKey(const ValueKey('miuix-bottom-sheet-overscroll-background')),
        findsOneWidget,
      );
      await upward.up(timeStamp: const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(surface).dy, closeTo(restingTop, .01));

      final downward = await tester.startGesture(tester.getCenter(handleArea));
      await downward.moveBy(
        const Offset(0, 30),
        timeStamp: const Duration(milliseconds: 400),
      );
      await tester.pump();
      final downwardAcceptedTop = tester.getTopLeft(surface).dy;
      expect(downwardAcceptedTop, closeTo(restingTop + 2.2, .01));
      await downward.moveBy(
        const Offset(0, 100),
        timeStamp: const Duration(milliseconds: 500),
      );
      await tester.pump();
      expect(
        tester.getTopLeft(surface).dy,
        closeTo(downwardAcceptedTop + 10, .01),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
            )
            .opacity,
        closeTo(1, .001),
      );
      await downward.up(timeStamp: const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(surface, findsOneWidget);
      expect(tester.getTopLeft(surface).dy, closeTo(restingTop, .01));
      expect(tester.getSize(handle), const Size(45, 4));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'bottom-sheet drag settles with source thresholds and lifecycle',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var dismissRequested = 0;
      var dismissFinished = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => MiuixBottomSheet.show<void>(
                  context: context,
                  child: const SizedBox(height: 420),
                  onDismissRequest: () => dismissRequested++,
                  onDismissFinished: () => dismissFinished++,
                ),
                child: const Text('Open threshold sheet'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open threshold sheet'));
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
      final handle = find.byKey(
        const ValueKey('miuix-bottom-sheet-drag-handle-area'),
      );

      GestureDetector handleGesture() => tester.widget<GestureDetector>(
        find.descendant(of: handle, matching: find.byType(GestureDetector)),
      );

      // Invoke the handle's public gesture callbacks with exact source values.
      // Pointer wiring and one-tenth damping are covered by the preceding test;
      // this isolates the velocity branch from Flutter's estimator smoothing.
      final cancelGesture = handleGesture();
      cancelGesture.onVerticalDragStart!(DragStartDetails());
      cancelGesture.onVerticalDragUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 200),
          primaryDelta: 200,
        ),
      );
      cancelGesture.onVerticalDragEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(0, -900)),
          primaryVelocity: -900,
        ),
      );
      await tester.pumpAndSettle();
      expect(surface, findsOneWidget);
      expect(dismissRequested, 0);
      expect(dismissFinished, 0);

      // A downward release above 800dp/s dismisses even when the travelled
      // distance remains below the independent 150dp distance threshold.
      final fastGesture = handleGesture();
      fastGesture.onVerticalDragStart!(DragStartDetails());
      fastGesture.onVerticalDragUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 40),
          primaryDelta: 40,
        ),
      );
      fastGesture.onVerticalDragEnd!(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(0, 900)),
          primaryVelocity: 900,
        ),
      );
      expect(dismissRequested, 0);
      expect(dismissFinished, 0);
      await tester.pump(const Duration(milliseconds: 10));
      expect(dismissRequested, 0);
      expect(dismissFinished, 0);
      await tester.pump(const Duration(milliseconds: 240));
      expect(dismissRequested, 1);
      expect(dismissFinished, 1);
      expect(surface, findsNothing);

      await tester.tap(find.text('Open threshold sheet'));
      await tester.pumpAndSettle();
      expect(surface, findsOneWidget);

      // A slow drag beyond 150dp starts the .85/.4 dismissal spring. Callbacks
      // remain pending until the sheet has physically crossed its own height.
      final dismissGesture = handleGesture();
      dismissGesture.onVerticalDragStart!(DragStartDetails());
      dismissGesture.onVerticalDragUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, 220),
          primaryDelta: 220,
        ),
      );
      dismissGesture.onVerticalDragEnd!(DragEndDetails(primaryVelocity: 0));
      expect(dismissRequested, 1);
      expect(dismissFinished, 1);
      await tester.pump(const Duration(milliseconds: 10));
      expect(dismissRequested, 1);
      expect(dismissFinished, 1);
      await tester.pump(const Duration(milliseconds: 240));
      expect(dismissRequested, 2);
      expect(dismissFinished, 2);
      expect(surface, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('bottom-sheet nested scroll consumes only source edge motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final behavior = MiuixBottomSheetController();
    final scrollController = ScrollController();
    addTearDown(behavior.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => MiuixBottomSheet.show<void>(
                context: context,
                controller: behavior,
                child: SizedBox(
                  height: 300,
                  child: ListView.builder(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    itemExtent: 48,
                    itemCount: 20,
                    itemBuilder: (_, index) => Text('Nested item $index'),
                  ),
                ),
              ),
              child: const Text('Open nested sheet'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open nested sheet'));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
    final list = find.byType(ListView);
    final restingTop = tester.getTopLeft(surface).dy;

    final nested = await tester.startGesture(tester.getCenter(list));
    await nested.moveBy(
      const Offset(0, 30),
      timeStamp: const Duration(milliseconds: 100),
    );
    await tester.pump();
    final acceptedTop = tester.getTopLeft(surface).dy;
    expect(acceptedTop, closeTo(restingTop + 22, .01));
    await nested.moveBy(
      const Offset(0, 100),
      timeStamp: const Duration(milliseconds: 500),
    );
    await tester.pump();
    final displacedTop = tester.getTopLeft(surface).dy;
    expect(displacedTop, closeTo(acceptedTop + 100, .01));
    expect(scrollController.offset, closeTo(0, .01));

    // Reversing direction restores the sheet before the list consumes pixels.
    await nested.moveBy(
      const Offset(0, -60),
      timeStamp: const Duration(milliseconds: 1000),
    );
    await tester.pump();
    expect(tester.getTopLeft(surface).dy, closeTo(displacedTop - 60, .01));
    expect(scrollController.offset, closeTo(0, .01));
    await nested.up(timeStamp: const Duration(milliseconds: 2000));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(surface).dy, closeTo(restingTop, .01));

    behavior.enableNestedScroll = false;
    await tester.pump();
    await tester.timedDrag(
      list,
      const Offset(0, 220),
      const Duration(seconds: 2),
    );
    await tester.pumpAndSettle();
    expect(surface, findsOneWidget);
    expect(tester.getTopLeft(surface).dy, closeTo(restingTop, .01));

    behavior.enableNestedScroll = true;
    await tester.pump();
    await tester.timedDrag(
      list,
      const Offset(0, 220),
      const Duration(seconds: 2),
    );
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
