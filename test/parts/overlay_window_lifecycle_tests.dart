part of '../miuix_flutter_test.dart';

// 保留原测试注册顺序和公共夹具；按弹层职责拆分超长文件。
void _registerOverlayWindowLifecycleTests() {
  testWidgets('compact overlay dialog follows and cancels predictive Back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    var dismissRequested = 0;
    var dismissFinished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) => MiuixButton(
                label: '打开预测返回叠加对话框',
                onPressed: () => MiuixOverlayDialog.show<void>(
                  context: context,
                  title: '预测返回',
                  content: const SizedBox(height: 80),
                  onDismissRequest: () => dismissRequested++,
                  onDismissFinished: () => dismissFinished++,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开预测返回叠加对话框'));
    await tester.pumpAndSettle();
    final surfaceHeight = tester
        .getRect(find.byKey(const ValueKey('miuix-dialog-surface')))
        .height;

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 400.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [120.0, 400.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    await tester.pump();

    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-dialog-predictive-transform')),
    );
    expect(
      transform.transform.getTranslation().y,
      closeTo((surfaceHeight + 24 + 12) * .5, .01),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-dialog-predictive-dim')),
          )
          .opacity,
      closeTo(.5, .001),
    );

    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    final reset = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-dialog-predictive-transform')),
    );
    expect(reset.transform.getTranslation().y, closeTo(0, .001));
    expect(find.text('预测返回'), findsOneWidget);

    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 400.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [180.0, 400.0],
      'progress': 0.65,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('预测返回'), findsNothing);
    expect(dismissRequested, 1);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large window dialog scales and commits predictive Back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var dismissRequested = 0;
    var dismissFinished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => MiuixButton(
              label: '打开预测返回窗口对话框',
              onPressed: () => MiuixWindowDialog.show<void>(
                context: context,
                title: '大屏预测返回',
                content: const SizedBox(height: 80),
                onDismissRequest: () => dismissRequested++,
                onDismissFinished: () => dismissFinished++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开预测返回窗口对话框'));
    await tester.pumpAndSettle();

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [140.0, 300.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.byKey(const ValueKey('miuix-dialog-predictive-transform')),
    );
    expect(transform.transform.storage[0], closeTo(.9, .001));

    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.text('大屏预测返回'), findsNothing);
    expect(dismissRequested, 1);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet defaults and public surface overrides stay wired', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const background = Color(0xff204060);
    const handle = Color(0xff20a060);
    const outside = EdgeInsets.fromLTRB(16, 0, 24, 0);
    const inside = EdgeInsets.fromLTRB(11, 0, 13, 7);
    final behavior = MiuixBottomSheetController();
    addTearDown(behavior.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => MiuixButton(
              label: 'Custom sheet',
              onPressed: () => MiuixWindowBottomSheet.show<void>(
                context: context,
                controller: behavior,
                child: const SizedBox(height: 120),
                backgroundColor: background,
                enableWindowDim: false,
                cornerRadius: 17,
                sheetMaxWidth: 640,
                outsideMargin: outside,
                insideMargin: inside,
                defaultWindowInsetsPadding: false,
                dragHandleColor: handle,
                glass: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Custom sheet'));
    await tester.pumpAndSettle();

    expect(MiuixBottomSheetDefaults.cornerRadius, 28);
    expect(MiuixBottomSheetDefaults.maxWidth, 640);
    expect(MiuixBottomSheetDefaults.outsideMargin, EdgeInsets.zero);
    expect(
      MiuixBottomSheetDefaults.insideMargin,
      const EdgeInsets.symmetric(horizontal: 24),
    );
    final surfaceFinder = find.byKey(
      const ValueKey('miuix-bottom-sheet-surface'),
    );
    final surface = tester.widget<MiuixGlass>(surfaceFinder);
    expect(surface.enabled, isFalse);
    expect(surface.color, background);
    expect(
      surface.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(17)),
    );
    expect(surface.padding, inside);
    final rect = tester.getRect(surfaceFinder);
    expect(rect.left, 16);
    expect(rect.right, 366);

    final handleDecoration =
        tester
                .widget<AnimatedContainer>(
                  find.byKey(const ValueKey('miuix-bottom-sheet-drag-handle')),
                )
                .decoration
            as BoxDecoration;
    expect(handleDecoration.color, handle.withValues(alpha: .2));
    final dim = tester.widget<ColoredBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
            matching: find.byType(ColoredBox),
          )
          .first,
    );
    expect(dim.color, Colors.transparent);

    behavior.dismiss();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlay list popup follows cancels and commits predictive Back',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              body: MiuixOverlayDropdownMenu<String>(
                entries: [MiuixDropdownEntry(value: 'one', label: '叠加列表选项')],
                onSelected: _ignoreString,
                child: Text('打开叠加列表'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开叠加列表'));
      await tester.pumpAndSettle();

      expect(
        await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
          'touchOffset': [1.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
        isTrue,
      );
      await _sendMiuixPredictiveBack(
        tester,
        'updateBackGestureProgress',
        const {
          'touchOffset': [120.0, 300.0],
          'progress': 0.5,
          'swipeEdge': 0,
        },
      );
      await tester.pump();

      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('miuix-list-popup-content-transform')),
            )
            .transform
            .storage[0],
        closeTo(.575, .001),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('miuix-list-popup-content-opacity')),
            )
            .opacity,
        closeTo(.5, .001),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('miuix-list-popup-predictive-dim')),
            )
            .opacity,
        closeTo(.5, .001),
      );

      await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
      await tester.pump();
      await tester.pump(MiuixListPopupDefaults.fractionDuration);
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('miuix-list-popup-content-transform')),
            )
            .transform
            .storage[0],
        closeTo(1, .001),
      );
      expect(find.text('叠加列表选项'), findsOneWidget);

      expect(
        await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
          'touchOffset': [1.0, 300.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
        isTrue,
      );
      await _sendMiuixPredictiveBack(
        tester,
        'updateBackGestureProgress',
        const {
          'touchOffset': [180.0, 300.0],
          'progress': 0.7,
          'swipeEdge': 0,
        },
      );
      await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('叠加列表选项'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('window list popup follows and commits predictive Back', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixWindowDropdownMenu<String>(
            entries: [MiuixDropdownEntry(value: 'one', label: '窗口列表选项')],
            onSelected: _ignoreString,
            child: Text('打开窗口列表'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开窗口列表'));
    await tester.pumpAndSettle();

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [150.0, 300.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-list-popup-content-opacity')),
          )
          .opacity,
      closeTo(.6, .001),
    );

    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('窗口列表选项'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cascading popup freezes predictive Back depth per gesture', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: MiuixIconCascadingDropdownMenu<String>(
              icon: Icon(Icons.more_vert),
              presentation: MiuixPopupPresentation.overlay,
              groups: [
                MiuixDropdownGroup(
                  entries: [
                    MiuixDropdownEntry(
                      value: 'parent',
                      label: '一级菜单',
                      children: [
                        MiuixDropdownEntry(value: 'child', label: '二级菜单'),
                      ],
                    ),
                  ],
                ),
              ],
              onSelected: _ignoreString,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('一级菜单'));
    await tester.pumpAndSettle();
    expect(find.text('二级菜单'), findsOneWidget);

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [120.0, 300.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('miuix-cascading-primary-transform')),
          )
          .transform
          .storage[0],
      closeTo(.975, .001),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-list-popup-predictive-dim')),
          )
          .opacity,
      1,
    );

    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('miuix-cascading-primary-transform')),
          )
          .transform
          .storage[0],
      closeTo(.95, .001),
    );
    expect(find.text('二级菜单'), findsOneWidget);

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [180.0, 300.0],
      'progress': 0.65,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('二级菜单'), findsNothing);
    expect(find.text('一级菜单'), findsOneWidget);

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [180.0, 300.0],
      'progress': 0.65,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('一级菜单'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'window cascading popup consumes button Back one depth at a time',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: MiuixIconCascadingDropdownMenu<String>(
              icon: Icon(Icons.menu),
              presentation: MiuixPopupPresentation.window,
              groups: [
                MiuixDropdownGroup(
                  entries: [
                    MiuixDropdownEntry(
                      value: 'window-parent',
                      label: '窗口一级菜单',
                      children: [
                        MiuixDropdownEntry(
                          value: 'window-child',
                          label: '窗口二级菜单',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
              onSelected: _ignoreString,
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('窗口一级菜单'));
      await tester.pumpAndSettle();
      expect(find.text('窗口二级菜单'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('窗口二级菜单'), findsNothing);
      expect(find.text('窗口一级菜单'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('窗口一级菜单'), findsNothing);

      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('窗口一级菜单'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('窗口二级菜单'));
      await tester.pumpAndSettle();
      expect(find.text('窗口一级菜单'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('window dropdown applies its dismissal guard to button Back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixDropdownMenuButton<String>(
              entries: const [
                MiuixDropdownEntry(value: 'locked', label: 'Locked option'),
              ],
              onSelected: _ignoreString,
              canDismiss: () => false,
              child: const Text('Open locked popup'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open locked popup'));
    await tester.pumpAndSettle();
    expect(find.text('Locked option'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // Barrier taps and platform Back now share the same dismissal contract.
    expect(find.text('Locked option'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy cascading popup anchor survives parent rebuilds', (
    tester,
  ) async {
    late StateSetter rebuildHost;
    var selected = false;
    var rebuildCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Rebuild $rebuildCount'),
                    MiuixIconCascadingDropdownMenu<String>(
                      icon: const Icon(Icons.more_vert),
                      items: const [
                        MiuixCascadingMenuItem(
                          label: 'Legacy parent',
                          children: [
                            MiuixDropdownEntry(
                              value: 'child',
                              label: 'Legacy child',
                            ),
                          ],
                        ),
                      ],
                      onSelected: (_) => selected = true,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    expect(find.text('Legacy child'), findsOneWidget);

    rebuildHost(() => rebuildCount++);
    await tester.pump();
    await tester.tap(find.text('Legacy child'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(selected, isTrue);
    expect(find.text('Legacy child'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('legacy cascading popup rejects a replaced child value', (
    tester,
  ) async {
    late StateSetter rebuildHost;
    var items = const <MiuixCascadingMenuItem<String>>[
      MiuixCascadingMenuItem(
        label: 'Stale legacy parent',
        children: [
          MiuixDropdownEntry(value: 'old', label: 'Stale legacy child'),
        ],
      ),
    ];
    var selected = '';
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Center(
                child: MiuixIconCascadingDropdownMenu<String>(
                  icon: const Icon(Icons.more_horiz),
                  items: items,
                  onSelected: (value) => selected = value,
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    rebuildHost(() {
      items = const [
        MiuixCascadingMenuItem(
          label: 'Current legacy parent',
          children: [
            MiuixDropdownEntry(value: 'new', label: 'Current legacy child'),
          ],
        ),
      ];
    });
    await tester.pump();
    await tester.tap(find.text('Stale legacy child'));
    await tester.pumpAndSettle();

    expect(selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'overlay bottom sheet follows cancels and commits predictive Back',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var dismissRequested = 0;
      var dismissFinished = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              body: Builder(
                builder: (context) => MiuixButton(
                  label: '打开预测返回叠加底部弹层',
                  onPressed: () => MiuixOverlayBottomSheet.show<void>(
                    context: context,
                    title: '预测返回底部弹层',
                    child: const SizedBox(height: 220),
                    onDismissRequest: () => dismissRequested++,
                    onDismissFinished: () => dismissFinished++,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('打开预测返回叠加底部弹层'));
      await tester.pumpAndSettle();
      final surfaceHeight = tester
          .getRect(find.byKey(const ValueKey('miuix-bottom-sheet-surface')))
          .height;

      expect(
        await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
          'touchOffset': [1.0, 400.0],
          'progress': 0.0,
          'swipeEdge': 0,
        }),
        isTrue,
      );
      await _sendMiuixPredictiveBack(
        tester,
        'updateBackGestureProgress',
        const {
          'touchOffset': [120.0, 400.0],
          'progress': 0.5,
          'swipeEdge': 0,
        },
      );
      await tester.pump();
      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('miuix-bottom-sheet-predictive-transform')),
      );
      expect(
        transform.transform.getTranslation().y,
        closeTo(surfaceHeight * .5, .01),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
            )
            .opacity,
        closeTo(.5, .001),
      );

      await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(
        tester
            .widget<Transform>(
              find.byKey(
                const ValueKey('miuix-bottom-sheet-predictive-transform'),
              ),
            )
            .transform
            .getTranslation()
            .y,
        closeTo(0, .001),
      );
      expect(find.text('预测返回底部弹层'), findsOneWidget);

      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 400.0],
        'progress': 0.0,
        'swipeEdge': 0,
      });
      await _sendMiuixPredictiveBack(
        tester,
        'updateBackGestureProgress',
        const {
          'touchOffset': [180.0, 400.0],
          'progress': 0.65,
          'swipeEdge': 0,
        },
      );
      await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('预测返回底部弹层'), findsNothing);
      expect(dismissRequested, 1);
      expect(dismissFinished, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('window bottom sheet resists Back when dismissal is disabled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final behavior = MiuixBottomSheetController(allowDismiss: false);
    addTearDown(behavior.dispose);
    var dismissRequested = 0;
    var dismissFinished = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => MiuixButton(
              label: '打开禁止关闭的窗口底部弹层',
              onPressed: () => MiuixWindowBottomSheet.show<void>(
                context: context,
                controller: behavior,
                title: '禁止关闭',
                child: const SizedBox(height: 220),
                onDismissRequest: () => dismissRequested++,
                onDismissFinished: () => dismissFinished++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开禁止关闭的窗口底部弹层'));
    await tester.pumpAndSettle();
    final surfaceHeight = tester
        .getRect(find.byKey(const ValueKey('miuix-bottom-sheet-surface')))
        .height;

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 400.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [120.0, 400.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      closeTo(surfaceHeight * .05, .01),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
          )
          .opacity,
      1,
    );

    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.text('禁止关闭'), findsOneWidget);
    expect(dismissRequested, 0);
    expect(dismissFinished, 0);

    behavior.allowDismiss = true;
    await tester.pump();
    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 400.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [180.0, 400.0],
      'progress': 0.65,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('禁止关闭'), findsNothing);
    expect(dismissRequested, 1);
    expect(dismissFinished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('window bottom sheet visibility uses the source Folme channels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final behavior = MiuixBottomSheetController();
    addTearDown(behavior.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => MiuixButton(
              label: '打开弹簧窗口底部弹层',
              onPressed: () => MiuixWindowBottomSheet.show<void>(
                context: context,
                controller: behavior,
                title: '弹簧底部弹层',
                child: const SizedBox(height: 220),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开弹簧窗口底部弹层'));
    await tester.pump();
    final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
    final surfaceHeight = tester.getSize(surface).height;
    await tester.pump(const Duration(milliseconds: 100));
    final expectedEnter = _miuixBottomSheetSourceResponse(.1);
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      closeTo(surfaceHeight * (1 - expectedEnter), .01),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
          )
          .opacity,
      closeTo(expectedEnter, .001),
    );
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
        matching: find.byKey(
          const ValueKey('miuix-bottom-sheet-predictive-transform'),
        ),
      ),
      findsNothing,
    );

    await tester.pumpAndSettle();
    behavior.dismiss();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final expectedExitRemaining = 1 - _miuixBottomSheetSourceResponse(.1);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-bottom-sheet-predictive-dim')),
          )
          .opacity,
      closeTo(expectedExitRemaining, .001),
    );
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      closeTo(surfaceHeight * _miuixBottomSheetSourceResponse(.1), .01),
    );
    await tester.pumpAndSettle();
    expect(find.text('弹簧底部弹层'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overlay bottom sheet visibility uses the same Folme channels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) => MiuixButton(
                label: '打开弹簧叠加底部弹层',
                onPressed: () => MiuixOverlayBottomSheet.show<void>(
                  context: context,
                  title: '叠加弹簧底部弹层',
                  child: const SizedBox(height: 220),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开弹簧叠加底部弹层'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final expectedEnter = _miuixBottomSheetSourceResponse(.1);
    expect(
      tester
          .widget<SlideTransition>(
            find.byKey(const ValueKey('miuix-host-bottom-sheet-slide')),
          )
          .position
          .value
          .dy,
      closeTo(1 - expectedEnter, .001),
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-host-bottom-sheet-dim')),
          )
          .opacity,
      closeTo(expectedEnter, .001),
    );

    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('叠加弹簧底部弹层'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion settles hosted dialog and sheet transitions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: MiuixScaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => MiuixOverlayDialog.show<void>(
                      context: context,
                      title: '减少动画对话框',
                      content: const Text('对话框内容'),
                    ),
                    child: const Text('打开对话框'),
                  ),
                  TextButton(
                    onPressed: () => MiuixOverlayBottomSheet.show<void>(
                      context: context,
                      title: '减少动画底部弹层',
                      child: const SizedBox(height: 220),
                    ),
                    child: const Text('打开底部弹层'),
                  ),
                  TextButton(
                    onPressed: () => MiuixDialog.show<void>(
                      context: context,
                      title: '减少动画窗口对话框',
                      content: const Text('窗口对话框内容'),
                    ),
                    child: const Text('打开窗口对话框'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开对话框'));
    await tester.pump();
    final dialogSlide = tester.widget<SlideTransition>(
      find.byKey(const ValueKey('miuix-host-dialog-slide')),
    );
    expect(dialogSlide.position.value, Offset.zero);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump();
    expect(find.text('对话框内容'), findsNothing);

    await tester.tap(find.text('打开底部弹层'));
    await tester.pump();
    final sheetSlide = tester.widget<SlideTransition>(
      find.byKey(const ValueKey('miuix-host-bottom-sheet-slide')),
    );
    expect(sheetSlide.position.value, Offset.zero);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('miuix-host-bottom-sheet-dim')),
          )
          .opacity,
      1,
    );

    // Direct handle movement stays finger-tracked. A slow subthreshold release
    // then returns to rest immediately instead of starting the settle spring.
    final handle = find.byKey(
      const ValueKey('miuix-bottom-sheet-drag-handle-area'),
    );
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(
      const Offset(0, 40),
      timeStamp: const Duration(milliseconds: 300),
    );
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      greaterThan(0),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 600));
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      closeTo(0, .001),
    );

    // Predictive Back itself remains direct; cancelling it has no 150ms
    // autonomous return when reduced motion is enabled.
    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 400.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [120.0, 400.0],
      'progress': 0.5,
      'swipeEdge': 0,
    });
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      greaterThan(0),
    );
    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    await tester.pump();
    expect(
      tester
          .widget<Transform>(
            find.byKey(
              const ValueKey('miuix-bottom-sheet-predictive-transform'),
            ),
          )
          .transform
          .getTranslation()
          .y,
      closeTo(0, .001),
    );
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump();
    expect(find.text('减少动画底部弹层'), findsNothing);

    await tester.tap(find.text('打开窗口对话框'));
    await tester.pump();
    // The zero-duration route bypasses the compact viewport-height slide.
    expect(
      find.byKey(const ValueKey('miuix-window-dialog-slide')),
      findsNothing,
    );
    expect(find.text('窗口对话框内容'), findsOneWidget);
    Navigator.of(
      tester.element(find.text('窗口对话框内容')),
      rootNavigator: true,
    ).pop();
    await tester.pump();
    expect(find.text('窗口对话框内容'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling reduced motion settles an active hosted transition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var reduceMotion = false;
    late StateSetter updateHost;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: child!,
            ),
            home: MiuixTheme(
              child: MiuixScaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => MiuixOverlayDialog.show<void>(
                      context: context,
                      title: '切换减少动画',
                      content: const Text('运动中的弹层'),
                    ),
                    child: const Text('启动弹层'),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('启动弹层'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    Offset slideOffset() => tester
        .widget<SlideTransition>(
          find.byKey(const ValueKey('miuix-host-dialog-slide')),
        )
        .position
        .value;
    expect(slideOffset().dy, inExclusiveRange(0, 1));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(slideOffset(), Offset.zero);
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump();
    expect(find.text('运动中的弹层'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact dialog uses HyperOS glass bottom-panel geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => Scaffold(
              body: MiuixButton(
                label: 'Open',
                onPressed: () => MiuixDialog.show<void>(
                  context: context,
                  title: '标题',
                  summary: '摘要',
                  content: const SizedBox(height: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    // v1.0.9 aligns compact dialogs to the bottom, adds the 12dp outer margin
    // after the 24dp navigation inset, and uses a 32dp minimum corner.
    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-dialog-surface')),
    );
    expect(surface.left, 12);
    expect(surface.right, 378);
    expect(surface.bottom, 808);
    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('miuix-dialog-surface')),
    );
    expect(glass.enabled, isTrue);
    expect(glass.blur, 30);
    expect(glass.opacity, .68);
    expect(glass.optics, same(MiuixGlassOptics.transient));
    expect(glass.radius, 32);
    final summary = tester.widget<Text>(find.text('摘要'));
    expect(summary.style?.fontSize, 16);
    expect(
      summary.style?.color,
      const MiuixSemanticColors.light()['onSurfaceSecondary'],
    );
  });

  testWidgets('window dialog preserves the caller scoped text scaler', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.6)),
              child: Builder(
                builder: (scaledContext) => MiuixButton(
                  label: 'Open scaled dialog',
                  onPressed: () => MiuixDialog.show<void>(
                    context: scaledContext,
                    title: 'Scaled title',
                    content: const Text('Scaled content'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open scaled dialog'));
    await tester.pumpAndSettle();

    final dialogContext = tester.element(find.byType(MiuixDialog));
    expect(MediaQuery.textScalerOf(dialogContext).scale(10), 16);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom dialog, sheet, and popup surfaces route safely', (
    tester,
  ) async {
    var dropdownValue = '';
    var cascadingValue = '';
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixButton(
                      label: 'Dialog trigger',
                      onPressed: () {
                        MiuixDialog.show<void>(
                          context: context,
                          title: 'Dialog title',
                          content: const Text('Dialog body'),
                          actions: [
                            MiuixButton(
                              label: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    ),
                    MiuixButton(
                      label: 'Sheet trigger',
                      onPressed: () {
                        MiuixBottomSheet.show<void>(
                          context: context,
                          title: 'Sheet title',
                          startAction: const Icon(Icons.close),
                          endAction: const Icon(Icons.check),
                          child: const Text('Sheet body'),
                        );
                      },
                    ),
                    MiuixButton(
                      label: 'Loading trigger',
                      onPressed: () {
                        MiuixLoadingDialog.show<void>(
                          context: context,
                          message: 'Loading state',
                        );
                      },
                    ),
                    MiuixListPopup<String>(
                      entries: const [],
                      onSelected: (_) {},
                    ),
                    MiuixDropdownMenuButton<String>(
                      entries: const [
                        MiuixDropdownEntry(value: 'one', label: 'One'),
                      ],
                      onSelected: (value) => dropdownValue = value,
                      child: const Text('Dropdown trigger'),
                    ),
                    MiuixIconCascadingDropdownMenu<String>(
                      icon: const Icon(Icons.more_horiz),
                      items: const [
                        MiuixCascadingMenuItem<String>(
                          label: 'Parent',
                          children: [
                            MiuixDropdownEntry(value: 'child', label: 'Child'),
                          ],
                        ),
                      ],
                      onSelected: (value) => cascadingValue = value,
                    ),
                    const MiuixExpandableCard(
                      title: 'Expandable',
                      children: [Text('Expanded child')],
                    ),
                    const MiuixStepperRow(
                      index: 1,
                      title: 'Step title',
                      subtitle: 'Step subtitle',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Dialog title'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pump(const Duration(milliseconds: 320));

    await tester.tap(find.text('Sheet trigger'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(find.text('Sheet body'), findsOneWidget);
    expect(find.text('Sheet title'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    Navigator.of(tester.element(find.text('Sheet body'))).pop();
    await tester.pump(const Duration(milliseconds: 360));

    await tester.tap(find.text('Loading trigger'));
    await tester.pump(const Duration(milliseconds: 320));
    expect(find.text('Loading state'), findsOneWidget);
    Navigator.of(tester.element(find.text('Loading state'))).pop();
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('No actions'), findsOneWidget);

    await tester.tap(find.text('Dropdown trigger'));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    await tester.tap(find.text('One').last);
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    expect(dropdownValue, 'one');

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    await tester.tap(find.text('Child'));
    await tester.pump();
    await tester.pump(MiuixListPopupDefaults.fractionDuration);
    expect(cascadingValue, 'child');

    await tester.tap(find.text('Expandable'));
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('Expanded child'), findsOneWidget);
    expect(find.text('Step title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cascading submenu refreshes rebuilt entries by position', (
    tester,
  ) async {
    // Upstream keeps the authored entry/item coordinate while the popup is
    // visible. Recreating immutable models must refresh the detached secondary
    // plane without collapsing it or retaining the old parent object.
    var revision = 0;
    late StateSetter rebuild;
    final controller = MiuixCascadingPopupController();
    addTearDown(controller.dispose);

    List<MiuixDropdownGroup<String>> groups() => [
      MiuixDropdownGroup<String>(
        entries: [
          MiuixDropdownEntry<String>(
            value: 'parent',
            label: 'Parent $revision',
            summary: 'Summary $revision',
            children: [
              MiuixDropdownEntry<String>(
                value: 'child',
                label: 'Child $revision',
                selected: revision.isOdd,
              ),
            ],
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Align(
                  alignment: Alignment.topLeft,
                  child: MiuixGroupedCascadingListPopup<String>(
                    groups: groups(),
                    controller: controller,
                    onSelected: _ignoreString,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Parent 0'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Child 0'), findsOneWidget);

    rebuild(() => revision = 1);
    await tester.pump();
    await tester.pump();

    // Both planes now resolve position (0, 0) against the latest group tree.
    expect(find.text('Parent 0'), findsNothing);
    expect(find.text('Summary 0'), findsNothing);
    expect(find.text('Child 0'), findsNothing);
    expect(find.text('Parent 1'), findsNWidgets(2));
    expect(find.text('Summary 1'), findsNWidgets(2));
    expect(find.text('Child 1'), findsOneWidget);
    expect(controller.collapseSecondary(), isTrue);
  });

  testWidgets('cascading submenu safely clears a removed tracked position', (
    tester,
  ) async {
    // A consumer may replace its immutable group tree while depth one is open.
    // Removing the tracked parent must clear the detached overlay after the
    // current build, without notifying or removing OverlayEntry during build.
    var includeParent = true;
    late StateSetter rebuild;
    final controller = MiuixCascadingPopupController();
    addTearDown(controller.dispose);

    List<MiuixDropdownGroup<String>> groups() => [
      MiuixDropdownGroup<String>(
        entries: includeParent
            ? const [
                MiuixDropdownEntry<String>(
                  value: 'parent',
                  label: 'Removable parent',
                  children: [
                    MiuixDropdownEntry<String>(
                      value: 'child',
                      label: 'Removable child',
                    ),
                  ],
                ),
              ]
            : const [],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Align(
                  alignment: Alignment.topLeft,
                  child: MiuixGroupedCascadingListPopup<String>(
                    groups: groups(),
                    controller: controller,
                    onSelected: _ignoreString,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Removable parent'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Removable child'), findsOneWidget);

    rebuild(() => includeParent = false);
    await tester.pump();
    await tester.pump();

    expect(find.text('Removable parent'), findsNothing);
    expect(find.text('Removable child'), findsNothing);
    expect(controller.collapseSecondary(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cascading submenu reduced motion uses exact depth endpoints', (
    tester,
  ) async {
    var reduceMotion = false;
    late StateSetter updateHost;
    final controller = MiuixCascadingPopupController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: reduceMotion),
              child: MiuixTheme(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: MiuixGroupedCascadingListPopup<String>(
                    controller: controller,
                    groups: const [
                      MiuixDropdownGroup<String>(
                        entries: [
                          MiuixDropdownEntry<String>(
                            value: 'parent',
                            label: 'Reduced parent',
                            children: [
                              MiuixDropdownEntry<String>(
                                value: 'child',
                                label: 'Reduced child',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                    onSelected: _ignoreString,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Reduced parent'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('Reduced child'), findsOneWidget);
    final primaryFinder = find.byKey(
      const ValueKey('miuix-cascading-primary-transform'),
    );
    final movingScale = tester
        .widget<Transform>(primaryFinder)
        .transform
        .storage[0];
    expect(movingScale, inExclusiveRange(.95, 1));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    final settledScale = tester
        .widget<Transform>(primaryFinder)
        .transform
        .storage[0];
    expect(settledScale, closeTo(.95, 1e-9));
    expect(find.text('Reduced child'), findsOneWidget);

    expect(controller.collapseSecondary(), isTrue);
    await tester.pump();
    expect(find.text('Reduced child'), findsNothing);
    expect(controller.collapseSecondary(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('list popup uses MIUIX dropdown row metrics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixListPopup<String>(
              entries: const [
                MiuixDropdownEntry(
                  value: 'one',
                  label: 'First action',
                  icon: Icon(Icons.copy),
                ),
                MiuixDropdownEntry(
                  value: 'two',
                  label: 'Second action with long text',
                ),
              ],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    final firstMetrics = debugMiuixDropdownMetrics(
      isFirst: true,
      isLast: false,
    );
    final lastMetrics = debugMiuixDropdownMetrics(isFirst: false, isLast: true);
    final popupRect = tester.getRect(find.byType(MiuixListPopup<String>));
    final popupSurface = tester.widget<MiuixSurface>(
      find.descendant(
        of: find.byType(MiuixListPopup<String>),
        matching: find.byType(MiuixSurface),
      ),
    );
    final firstTextRect = tester.getRect(find.text('First action'));
    final secondTextRect = tester.getRect(
      find.text('Second action with long text'),
    );

    // DropdownImpl has no Material-style minimum row height; its measured
    // height comes only from body1 text and the source edge padding.
    expect(firstMetrics.minHeight, 0);
    expect(popupSurface.glass, isTrue);
    expect(popupSurface.glassOptics, same(MiuixGlassOptics.transient));
    expect(firstMetrics.minWidth, 200);
    expect(firstMetrics.topPadding, 20);
    expect(firstMetrics.bottomPadding, 12);
    expect(firstMetrics.iconMinSize, 26);
    expect(firstMetrics.iconEndPadding, 12);
    expect(firstMetrics.textFontSize, 16);
    expect(firstMetrics.textLineHeight, 54 / 2.625);
    expect(firstMetrics.summaryTitleLineHeight, 20.6);
    expect(firstMetrics.summaryLineHeight, 14.8);
    expect(lastMetrics.topPadding, 12);
    expect(lastMetrics.bottomPadding, 20);
    expect(popupRect.width, inInclusiveRange(200, 288));
    expect(
      firstTextRect.left - popupRect.left,
      closeTo(
        firstMetrics.horizontalPadding +
            firstMetrics.iconMinSize +
            firstMetrics.iconEndPadding,
        1,
      ),
    );
    expect(
      secondTextRect.left - popupRect.left,
      closeTo(firstMetrics.horizontalPadding, 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('four-row spinner popup keeps the source measured height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              // Keep this metric fixture independent from the intrinsic-width
              // branch, which is already covered by the preceding test.
              width: 288,
              child: MiuixListPopup<int>(
                entries: const [
                  MiuixDropdownEntry(
                    value: 0,
                    label: '选项一',
                    summary: '红色',
                    icon: SizedBox.square(dimension: 24),
                    selected: true,
                  ),
                  MiuixDropdownEntry(
                    value: 1,
                    label: '选项二',
                    summary: '绿色',
                    icon: SizedBox.square(dimension: 24),
                  ),
                  MiuixDropdownEntry(
                    value: 2,
                    label: '选项三',
                    summary: '蓝色',
                    icon: SizedBox.square(dimension: 24),
                  ),
                  MiuixDropdownEntry(
                    value: 3,
                    label: '选项四',
                    summary: '黄色',
                    icon: SizedBox.square(dimension: 24),
                  ),
                ],
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final popupRect = tester.getRect(find.byType(MiuixListPopup<int>));
    // 112dp edge padding plus four 54px-at-420dpi/14.8dp text stacks. At the
    // reference device's 2.625 density this becomes the measured 666px.
    expect(popupRect.height, closeTo(253.6, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('list popup families normalize invalid minimum widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            children: [
              Expanded(
                child: MiuixListPopup<int>(
                  entries: const [MiuixDropdownEntry(value: 1, label: '普通弹层')],
                  minWidth: double.nan,
                  onSelected: (_) {},
                ),
              ),
              Expanded(
                child: MiuixGroupedCascadingListPopup<int>(
                  groups: const [
                    MiuixDropdownGroup(
                      entries: [MiuixDropdownEntry(value: 1, label: '级联弹层')],
                    ),
                  ],
                  minWidth: double.infinity,
                  onSelected: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('普通弹层'), findsOneWidget);
    expect(find.text('级联弹层'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
