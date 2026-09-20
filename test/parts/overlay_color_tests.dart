part of '../miuix_flutter_test.dart';

void _ignoreString(String _) {}

void _ignoreDropdownIndex(int _) {}

Future<Object?> _sendMiuixPredictiveBack(
  WidgetTester tester,
  String method, [
  Map<String, Object?>? arguments,
]) async {
  final message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  Object? response;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    message,
    (data) {
      response = data == null
          ? null
          : const StandardMethodCodec().decodeEnvelope(data);
    },
  );
  return response;
}

double _miuixBottomSheetSourceResponse(double seconds) {
  const dampingRatio = .9;
  const responseSeconds = .38;
  const naturalFrequency = 2 * math.pi / responseSeconds;
  final dampedFactor = math.sqrt(1 - dampingRatio * dampingRatio);
  final dampedFrequency = naturalFrequency * dampedFactor;
  final envelope = math.exp(-dampingRatio * naturalFrequency * seconds);
  return 1 -
      envelope *
          (math.cos(dampedFrequency * seconds) +
              dampingRatio /
                  dampedFactor *
                  math.sin(dampedFrequency * seconds));
}

void _registerOverlayColorTests() {
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

  testWidgets('rich tooltip renders custom content in its overlay', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixRichTooltipBox(
                message: 'Rich title',
                content: Text('Rich detail content'),
                child: Text('Rich target'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Rich detail content'), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Rich target')),
    );
    await tester.pump(const Duration(milliseconds: 650));

    expect(find.text('Rich title'), findsOneWidget);
    expect(find.text('Rich detail content'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Rich detail content'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Rich detail content'), findsNothing);
  });

  testWidgets('scroll behavior suppresses Flutter default overscroll effects', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ScrollConfiguration(
            behavior: const MiuixScrollBehavior(),
            child: Scaffold(
              body: SizedBox(
                height: 80,
                child: ListView(
                  children: const [
                    SizedBox(height: 240, child: Text('Scrollable content')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 80));
    await tester.pump(const Duration(milliseconds: 120));

    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('MIUIX spring physics uses the source cubic damping curve', () {
    const physics = MiuixSpringScrollPhysics();
    expect(physics.frictionFactor(0), 1);
    expect(physics.frictionFactor(.5), .25);
    expect(physics.frictionFactor(1), 0);

    var pixels = 0.0;
    for (var index = 0; index < 1000; index++) {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: pixels,
        viewportDimension: 1000,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      pixels += physics.applyPhysicsToUserOffset(metrics, -1);
    }
    // x - x² + x³/3 reaches exactly one third of the viewport at x=1.
    expect(-pixels, closeTo(1000 / 3, 2));
  });

  test('MIUIX spring physics uses the source window range and inverse', () {
    const physics = MiuixSpringScrollPhysics(windowSize: Size(500, 1000));
    for (final touch in <double>[1, 50, 250, 500, 1000]) {
      final damped = physics.dampingDistance(touch, 1000);
      expect(physics.touchDistance(damped, 1000), closeTo(touch, .0001));
    }

    var pixels = 0.0;
    for (var index = 0; index < 1000; index++) {
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 1000,
        pixels: pixels,
        viewportDimension: 100,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      pixels += physics.applyPhysicsToUserOffset(metrics, -1);
    }
    // A popup still damps against the 1000px window, not its 100px viewport.
    expect(-pixels, closeTo(1000 / 3, 2));
  });

  test('MIUIX spring simulation copies the source Euler frame step', () {
    const physics = MiuixSpringScrollPhysics();
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: -100,
      viewportDimension: 500,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    final simulation = physics.createBallisticSimulation(metrics, 0)!;
    const dt = .016;
    const omega = 2 * math.pi / .4;
    const expectedVelocity = omega * omega * 100 * dt;
    const expectedPosition = -100 + expectedVelocity * dt;
    expect(simulation.dx(dt), closeTo(expectedVelocity, 1e-9));
    expect(simulation.x(dt), closeTo(expectedPosition, 1e-9));
    expect(simulation.isDone(dt), isFalse);
  });

  testWidgets('overscroll behavior uses window range and honors its toggle', (
    tester,
  ) async {
    late ScrollPhysics enabled;
    late ScrollPhysics disabled;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            enabled = const MiuixScrollBehavior().getScrollPhysics(context);
            disabled = const MiuixScrollBehavior(
              showOverscrollIndicator: false,
            ).getScrollPhysics(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(enabled, isA<MiuixSpringScrollPhysics>());
    expect(
      (enabled as MiuixSpringScrollPhysics).windowSize,
      tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    expect(disabled, isA<ClampingScrollPhysics>());
  });

  test('overscroll factory preserves singleton value semantics and state', () {
    const first = MiuixOverscrollFactory();
    const second = MiuixOverscrollFactory();
    // Non-const calls prove the Kotlin singleton's strict identity semantics.
    // ignore: prefer_const_constructors
    final runtimeFirst = MiuixOverscrollFactory();
    // ignore: prefer_const_constructors
    final runtimeSecond = MiuixOverscrollFactory();
    final state = MiuixOverScrollState();
    addTearDown(state.dispose);
    expect(first, second);
    expect(runtimeFirst == runtimeSecond, isFalse);
    expect(first.hashCode, 1);
    final effect = first.createOverscrollEffect(
      state: state,
      child: const Text('Effect child'),
    );
    expect(effect.state, same(state));
    expect(effect.child, isA<Text>());
  });

  testWidgets('overscroll effect reports the source one-pixel active state', (
    tester,
  ) async {
    final state = MiuixOverScrollState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixOverscrollEffect(
          state: state,
          showScrollbars: false,
          child: SizedBox(
            height: 80,
            child: ListView(
              children: const [
                SizedBox(height: 240, child: Text('Scrollable content')),
              ],
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    expect(state.isOverScrollActive, isTrue);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(state.isOverScrollActive, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker uses the source flat stack and reports selection', (
    tester,
  ) async {
    var value = 5;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) => MiuixNumberPicker(
                value: value,
                min: 0,
                max: 10,
                onChanged: (next) => setState(() => value = next),
              ),
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    expect(find.byType(ListWheelScrollView), findsNothing);
    expect(
      find.descendant(of: wheel, matching: find.byType(Stack)),
      findsOneWidget,
    );
    expect(tester.getSize(wheel).height, 225);
    final selectedText = tester.widget<Text>(find.text('5'));
    final semantic = MiuixSemanticColors.of(tester.element(wheel));
    expect(semantic['onSurface'], const Color(0xFF000000));
    expect(selectedText.style?.fontSize, 32);
    expect(selectedText.style?.fontWeight, FontWeight.w600);
    expect(selectedText.style?.color, semantic['onSurface']);

    // One row from center: normalized distance is 1 / (2 + 0.5). The source
    // formula produces 48% opacity and 92% scale, without wheel magnification.
    final adjacentVisual = debugMiuixNumberPickerItemVisual(
      distanceFromCenter: 1,
      visibleItemCount: 5,
      selectedColor: semantic['onSurface'],
      unselectedColor: semantic['onSurfaceSecondary'],
    );
    expect(adjacentVisual.opacity, closeTo(.48, .0001));
    expect(adjacentVisual.scale, closeTo(.92, .0001));
    expect(
      adjacentVisual.color,
      Color.lerp(semantic['onSurface'], semantic['onSurfaceSecondary'], .4),
    );

    await tester.drag(wheel, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(value, 6);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker renders a huge sparse domain in constant space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixNumberPicker(
              value: 999999999,
              min: -1000000000,
              max: 1000000000,
              step: 3,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    // The requested value is between two legal entries and resolves to the
    // nearer lower entry. Only the visible preparation rows are constructed;
    // the two-billion-wide domain is never materialized as a list.
    expect(find.text('999999999'), findsNothing);
    expect(find.text('999999998'), findsOneWidget);
    expect(
      tester.getSemantics(wheel).label,
      '999999998, -1000000000 - 1000000000',
    );
    expect(
      find.descendant(of: wheel, matching: find.byType(Text)).evaluate().length,
      lessThanOrEqualTo(9),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'number picker reduced motion commits without autonomous settle',
    (tester) async {
      var value = 5;
      var changes = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MiuixTheme(
              child: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => MiuixNumberPicker(
                    value: value,
                    min: 0,
                    max: 10,
                    onChanged: (next) => setState(() {
                      value = next;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
      await tester.timedDrag(
        wheel,
        const Offset(0, -52),
        const Duration(seconds: 2),
      );
      // One bounded frame is sufficient: reduced motion skips both the
      // exponential decay and the critically damped row-centering spring.
      await tester.pump();
      expect(value, 6);
      expect(changes, 1);
      expect(tester.getSemantics(wheel).label, '6, 0 - 10');
      await tester.pump(const Duration(seconds: 1));
      expect(changes, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('number picker settles a running fling when motion is reduced', (
    tester,
  ) async {
    var value = 5;
    var changes = 0;
    final reduceMotion = ValueNotifier(false);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: Center(
                child: StatefulBuilder(
                  builder: (context, setState) => MiuixNumberPicker(
                    value: value,
                    min: 0,
                    max: 10,
                    onChanged: (next) => setState(() {
                      value = next;
                      changes++;
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    await tester.fling(wheel, const Offset(0, -80), 1000);
    await tester.pump(const Duration(milliseconds: 16));
    expect(changes, 0);

    reduceMotion.value = true;
    await tester.pump();
    await tester.pump();
    expect(value, greaterThan(5));
    expect(changes, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(changes, 1);
    expect(tester.takeException(), isNull);
  });

  test('number picker uses Kotlin tie rounding in both directions', () {
    expect(debugMiuixNumberPickerRoundToInt(.49), 0);
    expect(debugMiuixNumberPickerRoundToInt(.5), 1);
    expect(debugMiuixNumberPickerRoundToInt(1.5), 2);
    expect(debugMiuixNumberPickerRoundToInt(-.49), 0);
    expect(debugMiuixNumberPickerRoundToInt(-.5), 0);
    expect(debugMiuixNumberPickerRoundToInt(-1.5), -1);
  });

  testWidgets('number picker colors defaults and source adapter are exact', (
    tester,
  ) async {
    const custom = MiuixNumberPickerColors(
      selectedTextColor: Color(0xFF000001),
      unselectedTextColor: Color(0xFF000002),
      disabledSelectedTextColor: Color(0xFF000003),
      disabledUnselectedTextColor: Color(0xFF000004),
    );
    late MiuixNumberPickerColors defaults;
    late MiuixNumberPickerColors overridden;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              defaults = MiuixNumberPickerDefaults.colors(context);
              overridden = MiuixNumberPickerDefaults.colors(
                context,
                selectedTextColor: custom.selectedTextColor,
                unselectedTextColor: custom.unselectedTextColor,
                disabledSelectedTextColor: custom.disabledSelectedTextColor,
                disabledUnselectedTextColor: custom.disabledUnselectedTextColor,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(MiuixNumberPickerDefaults.itemHeight, 45);
    expect(defaults.selectedTextColor, const Color(0xFF000000));
    expect(defaults.unselectedTextColor, const Color(0xCC000000));
    expect(defaults.disabledSelectedTextColor, const Color(0xFFFCFCFC));
    expect(defaults.disabledUnselectedTextColor, const Color(0xFFFCFCFC));
    expect(overridden, custom);
    expect(custom.copyWith(), custom);
    expect(custom.selected(true), custom.selectedTextColor);
    expect(custom.selected(false), custom.disabledSelectedTextColor);
    expect(custom.unselected(true), custom.unselectedTextColor);
    expect(custom.unselected(false), custom.disabledUnselectedTextColor);

    final source = MiuixNumberPicker.source(
      value: 7,
      onValueChange: (_) {},
      range: (first: 3, last: 9),
      visibleItemCount: 7,
      wrapAround: true,
      colors: custom,
    );
    expect(source.value, 7);
    expect(source.min, 3);
    expect(source.max, 9);
    expect(source.visibleItemCount, 7);
    expect(source.wrapAround, isTrue);
    expect(source.colors, custom);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker forwards colors and source slot paint order', (
    tester,
  ) async {
    const custom = MiuixNumberPickerColors(
      selectedTextColor: Color(0xFF102030),
      unselectedTextColor: Color(0xFF203040),
      disabledSelectedTextColor: Color(0xFF304050),
      disabledUnselectedTextColor: Color(0xFF405060),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Row(
            children: [
              Expanded(
                child: MiuixNumberPicker(
                  value: 2,
                  min: 0,
                  max: 5,
                  colors: custom,
                  label: (value) => 'E$value',
                  textStyle: const TextStyle(fontFamily: 'sans-serif'),
                  onChanged: (_) {},
                ),
              ),
              Expanded(
                child: MiuixNumberPicker(
                  value: 2,
                  min: 0,
                  max: 5,
                  enabled: false,
                  colors: custom,
                  label: (value) => 'D$value',
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.widget<Text>(find.text('E2')).style?.color,
      const Color(0xFF102030),
    );
    expect(
      tester.widget<Text>(find.text('E5')).style?.color,
      const Color(0xFF203040),
    );
    expect(
      tester.widget<Text>(find.text('D2')).style?.color,
      const Color(0xFF304050),
    );
    expect(
      tester.widget<Text>(find.text('D5')).style?.color,
      const Color(0xFF405060),
    );
    // A caller style with no size stays unspecified; NumberPicker.kt only
    // fills a missing SemiBold weight instead of replacing the whole style.
    expect(tester.widget<Text>(find.text('E2')).style?.fontSize, isNull);
    expect(
      tester.widget<Text>(find.text('E2')).style?.fontWeight,
      FontWeight.w600,
    );

    final enabledWheel = find
        .byKey(const ValueKey('miuix-number-picker-wheel'))
        .first;
    final opacityKeys = tester
        .widgetList<Opacity>(
          find.descendant(of: enabledWheel, matching: find.byType(Opacity)),
        )
        .map((opacity) => opacity.key)
        .whereType<ValueKey<String>>()
        .map((key) => key.value)
        .toList();
    expect(opacityKeys, const [
      'miuix-number-picker-item-0',
      'miuix-number-picker-item-1',
      'miuix-number-picker-item-2',
      'miuix-number-picker-item-3',
      'miuix-number-picker-item-4',
      'miuix-number-picker-item-5',
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('number picker supports disabled and wrap-around states', (
    tester,
  ) async {
    var value = 2;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixNumberPicker(
              value: value,
              min: 0,
              max: 2,
              enabled: false,
              wrapAround: true,
              visibleItemCount: 4,
              label: (item) => 'v$item',
              onChanged: (next) => value = next,
            ),
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    expect(tester.getSize(wheel).height, 225);
    expect(find.text('v2'), findsWidgets);

    await tester.drag(wheel, const Offset(0, -52));
    await tester.pumpAndSettle();

    expect(value, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'wrap-around number picker centers its controlled initial value',
    (tester) async {
      var hour = 16;
      var minute = 30;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  Expanded(
                    child: MiuixNumberPicker(
                      value: hour,
                      min: 0,
                      max: 23,
                      wrapAround: true,
                      onChanged: (next) => setState(() => hour = next),
                    ),
                  ),
                  Expanded(
                    child: MiuixNumberPicker(
                      value: minute,
                      min: 0,
                      max: 59,
                      wrapAround: true,
                      onChanged: (next) => setState(() => minute = next),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A looping wheel must not let its synthetic scroll origin replace the
      // externally controlled value during the first Android/layout frame.
      expect(hour, 16);
      expect(minute, 30);
      final wheels = find.byKey(const ValueKey('miuix-number-picker-wheel'));
      expect(wheels, findsNWidgets(2));
      expect(tester.getSemantics(wheels.at(0)).label, '16, 0 - 23');
      expect(tester.getSemantics(wheels.at(0)).value, isEmpty);
      expect(tester.getSemantics(wheels.at(1)).label, '30, 0 - 59');
      expect(tester.getSemantics(wheels.at(1)).value, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('number picker semantics use the displayed source label', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixNumberPicker(
            value: 2,
            min: 0,
            max: 6,
            label: (value) => 'v$value',
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final wheel = find.byKey(const ValueKey('miuix-number-picker-wheel'));
    final semantics = tester.getSemantics(wheel);
    expect(semantics.label, 'v2, 0 - 6');
    expect(semantics.value, isEmpty);
  });

  testWidgets('snackbar host manages stacked lifecycle and action results', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            snackbarHost: MiuixSnackbarHost(state: state),
          ),
        ),
      ),
    );

    final oldest = state.showSnackbar(
      'Oldest message',
      duration: MiuixSnackbarDuration.indefinite,
    );
    final newest = state.showSnackbar(
      'Newest message',
      actionLabel: 'Undo',
      withDismissAction: true,
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Oldest message'), findsOneWidget);
    expect(find.text('Newest message'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(await newest, MiuixSnackbarResult.actionPerformed);

    final oldestData = await state.oldestSnackbarData();
    await oldestData!.dismiss();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(await oldest, MiuixSnackbarResult.dismissed);
    expect(find.text('Oldest message'), findsNothing);
    expect(find.text('Newest message'), findsNothing);
    expect(tester.takeException(), isNull);
    state.dispose();
  });

  testWidgets('snackbar reduced motion snaps entry and exit to endpoints', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    final reduceMotion = ValueNotifier(false);
    addTearDown(state.dispose);
    addTearDown(reduceMotion.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: ValueListenableBuilder<bool>(
            valueListenable: reduceMotion,
            builder: (context, disabled, _) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disabled),
              child: Center(
                child: SizedBox(
                  width: 400,
                  height: 200,
                  child: MiuixSnackbarHost(
                    state: state,
                    contentBuilder: (context, data) => SizedBox(
                      key: const ValueKey('reduced-motion-snackbar'),
                      height: 48,
                      child: Text(data.visuals.message),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final result = state.showSnackbar(
      'Reduced motion',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final content = find.byKey(const ValueKey('reduced-motion-snackbar'));
    Align entryAlign() => tester
        .widgetList<Align>(
          find.ancestor(of: content, matching: find.byType(Align)),
        )
        .singleWhere((align) => align.heightFactor != null);
    expect(entryAlign().heightFactor, inExclusiveRange(0, 1));

    // Turning the platform setting on during the spring must expose the fully
    // entered terminal frame immediately instead of replaying from the current
    // sampled value.
    reduceMotion.value = true;
    await tester.pump();
    expect(entryAlign().heightFactor, 1);

    await (await state.newestSnackbarData())!.dismiss();
    expect(await result, MiuixSnackbarResult.dismissed);
    await tester.pump();
    await tester.pump();
    expect(content, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar reduced motion preserves direct drag then snaps', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: MiuixSnackbarHost(state: state),
              ),
            ),
          ),
        ),
      ),
    );
    final result = state.showSnackbar(
      'Direct drag',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump();
    final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));
    final initialLeft = tester.getTopLeft(surface).dx;
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, closeTo(initialLeft + 100, .001));

    // Hold long enough that release velocity cannot cross the velocity anchor.
    await tester.pump(const Duration(seconds: 2));
    await gesture.up();
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, closeTo(initialLeft, .001));
    expect(find.text('Direct drag'), findsOneWidget);

    await (await state.newestSnackbarData())!.dismiss();
    await tester.pump();
    await tester.pump();
    expect(await result, MiuixSnackbarResult.dismissed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root snackbar overlay honors reduced motion endpoints', (
    tester,
  ) async {
    late BuildContext overlayContext;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: Builder(
              builder: (context) {
                overlayContext = context;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    final controller = MiuixSnackbar.show(
      overlayContext,
      'Reduced overlay',
      duration: MiuixSnackbarDuration.indefinite,
      withDismissAction: true,
    );
    await tester.pump();
    await tester.pump();
    final message = find.text('Reduced overlay');
    final opacity = tester.widget<Opacity>(
      find.ancestor(of: message, matching: find.byType(Opacity)).first,
    );
    final translation = tester.widget<FractionalTranslation>(
      find
          .ancestor(of: message, matching: find.byType(FractionalTranslation))
          .first,
    );
    expect(opacity.opacity, 1);
    expect(translation.translation, Offset.zero);

    await tester.tap(
      find.byKey(const ValueKey('miuix-snackbar-dismiss-action')),
    );
    await tester.pump();
    await tester.pump();
    await controller.closed;
    expect(message, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar paints newest above an older shrinking entry', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 240,
              height: 220,
              child: MiuixSnackbarHost(
                state: state,
                contentBuilder: (context, data) => Listener(
                  key: ValueKey('paint-${data.visuals.message}'),
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(width: 200, height: 80),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final oldest = state.showSnackbar(
      'oldest',
      duration: MiuixSnackbarDuration.indefinite,
    );
    state.showSnackbar('newest', duration: MiuixSnackbarDuration.indefinite);
    await tester.pumpAndSettle();

    // The source gives the newest list entry the greatest zIndex. Dismissing
    // an older entry is the frame where this matters: that entry fades and
    // shrinks from the top with clip=false, so its full child temporarily
    // overlaps the newer surface below it.
    await (await state.oldestSnackbarData())!.dismiss();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final oldFinder = find.byKey(const ValueKey('paint-oldest'));
    final newFinder = find.byKey(const ValueKey('paint-newest'));
    expect(oldFinder, findsOneWidget);
    expect(newFinder, findsOneWidget);
    final oldRect = tester.getRect(oldFinder);
    final newRect = tester.getRect(newFinder);
    final overlap = oldRect.intersect(newRect);
    expect(overlap.width, greaterThan(0));
    expect(overlap.height, greaterThan(0));

    // RenderFlex hit-tests in reverse paint order. At a shared point only the
    // newest Listener may win, proving the older unclipped child is behind it
    // just like the explicit Compose zIndex ordering.
    final hit = tester.hitTestOnBinding(overlap.center);
    final newestRender = tester.renderObject(newFinder);
    final oldestRender = tester.renderObject(oldFinder);
    expect(hit.path.any((entry) => entry.target == newestRender), isTrue);
    expect(hit.path.any((entry) => entry.target == oldestRender), isFalse);

    await tester.pumpAndSettle();
    expect(await oldest, MiuixSnackbarResult.dismissed);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar timer uses Android recommended accessibility timeout', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const channel = MethodChannel('flutter_miuix/accessibility');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 80;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            snackbarHost: MiuixSnackbarHost(state: state),
          ),
        ),
      ),
    );
    final result = state.showSnackbar(
      'Accessible timeout',
      actionLabel: 'Undo',
    );
    await tester.pump();
    // The second frame lets the native recommendation future complete and
    // starts its replacement timer, matching SnackbarHost's LaunchedEffect.
    await tester.pump();

    expect(calls, hasLength(1));
    expect(calls.single.method, 'recommendedTimeoutMillis');
    expect(calls.single.arguments, <String, Object>{
      'originalTimeoutMillis': 4000,
      'hasAction': true,
    });
    await tester.pump(const Duration(milliseconds: 79));
    expect(find.text('Accessible timeout'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 2));
    expect(await result, MiuixSnackbarResult.dismissed);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Accessible timeout'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar defaults to HyperOS glass geometry and styling', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 200,
                child: MiuixSnackbarHost(state: state),
              ),
            ),
          ),
        ),
      ),
    );

    state.showSnackbar(
      'Source message',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pumpAndSettle();

    final surfaceFinder = find.byKey(const ValueKey('miuix-snackbar-surface'));
    final surfaceRect = tester.getRect(surfaceFinder);
    // Snackbar.kt: 12dp outer horizontal padding leaves 376dp of a 400dp host.
    // The current source Row has a 48dp minimum after its 12dp content inset.
    expect(surfaceRect.width, 376);
    expect(surfaceRect.height, 48);

    final surface = tester.widget<DecoratedBox>(surfaceFinder);
    final decoration = surface.decoration as ShapeDecoration;
    final context = tester.element(surfaceFinder);
    final semantic = MiuixSemanticColors.of(context);
    final background = tester.widget<MiuixGlass>(
      find.descendant(of: surfaceFinder, matching: find.byType(MiuixGlass)),
    );
    expect(background.color, semantic['onSecondaryVariant']);
    expect(background.blur, 24);
    expect(background.opacity, .72);
    expect(background.optics, same(MiuixGlassOptics.transient));
    // Snackbar.kt applies dropShadow to RoundedCornerShape before the nested
    // squircleBackground paints the actual fill.
    expect(decoration.shape, isA<RoundedRectangleBorder>());
    final shape = decoration.shape as RoundedRectangleBorder;
    expect(shape.borderRadius, BorderRadius.circular(24));
    final shadows = decoration.shadows!;
    expect(shadows, hasLength(1));
    expect(shadows.single.blurRadius, 10);
    expect(shadows.single.spreadRadius, 0);
    expect(shadows.single.offset, Offset.zero);
    expect(shadows.single.color, Colors.black.withValues(alpha: .1));

    await (await state.newestSnackbarData())!.dismiss();
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Source message',
      actionLabel: '撤销',
      withDismissAction: true,
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pumpAndSettle();
    // The current source action pill has a 26dp minimum and zero vertical
    // action inset. The snackbar's 12dp vertical inset makes the row 50dp.
    expect(tester.getRect(surfaceFinder).height, 50);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-snackbar-action')))
          .height,
      26,
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-snackbar-dismiss-action')),
      ),
      const Size.square(20),
    );

    // The current host enables two-way anchored swipe dismissal by default.
    await tester.drag(surfaceFinder, const Offset(360, 0));
    await tester.pumpAndSettle();
    expect(find.text('Source message'), findsNothing);
  });

  test('snackbar value models retain source data-class equality', () {
    const colors = MiuixSnackbarColors(
      containerColor: Color(0xFF102030),
      contentColor: Color(0xFF405060),
      actionContentColor: Color(0xFF708090),
      dismissActionContentColor: Color(0xFFA0B0C0),
      actionContainerColor: Color(0xFFD0E0F0),
    );
    expect(
      MiuixSnackbarDuration.custom(const Duration(milliseconds: 1250)),
      MiuixSnackbarDuration.custom(const Duration(milliseconds: 1250)),
    );
    expect(
      const MiuixSnackbarVisuals(
        message: 'Saved',
        actionLabel: 'Undo',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.long,
      ),
      const MiuixSnackbarVisuals(
        message: 'Saved',
        actionLabel: 'Undo',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.long,
      ),
    );
    expect(
      colors,
      const MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF405060),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      ),
    );
    expect(
      colors.copyWith(contentColor: const Color(0xFF112233)),
      const MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF112233),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      ),
    );
    expect(
      () => MiuixSnackbarDuration.custom(Duration.zero),
      throwsArgumentError,
    );
  });

  testWidgets(
    'snackbar anchored swipe uses both source directions and opt-out',
    (tester) async {
      final state = MiuixSnackbarHostState();
      final swipeEnabled = ValueNotifier(true);
      addTearDown(state.dispose);
      addTearDown(swipeEnabled.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                height: 240,
                child: ValueListenableBuilder<bool>(
                  valueListenable: swipeEnabled,
                  builder: (context, enabled, _) => MiuixSnackbarHost(
                    state: state,
                    canSwipeToDismiss: enabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final first = state.showSnackbar(
        'Anchored swipe',
        duration: MiuixSnackbarDuration.indefinite,
      );
      await tester.pumpAndSettle();
      final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));

      // A slow drag below half the 400dp entry width settles back to zero.
      await tester.timedDrag(
        surface,
        const Offset(150, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(find.text('Anchored swipe'), findsOneWidget);

      // Crossing the source 50-percent anchor dismisses toward either side.
      await tester.timedDrag(
        surface,
        const Offset(-240, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(await first, MiuixSnackbarResult.dismissed);
      expect(find.text('Anchored swipe'), findsNothing);

      swipeEnabled.value = false;
      await tester.pump();
      final second = state.showSnackbar(
        'Swipe disabled',
        duration: MiuixSnackbarDuration.indefinite,
      );
      await tester.pumpAndSettle();
      await tester.drag(surface, const Offset(360, 0));
      await tester.pumpAndSettle();
      expect(find.text('Swipe disabled'), findsOneWidget);
      await (await state.newestSnackbarData())!.dismiss();
      await tester.pumpAndSettle();
      expect(await second, MiuixSnackbarResult.dismissed);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('snackbar horizontal drag owns the gesture above a pager', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    final pager = PageController();
    var selectedPage = 0;
    addTearDown(state.dispose);
    addTearDown(pager.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 400,
              height: 260,
              child: MiuixSnackbarHost(
                state: state,
                child: PageView(
                  controller: pager,
                  onPageChanged: (value) => selectedPage = value,
                  children: const [
                    ColoredBox(color: Colors.white, child: Text('Page zero')),
                    ColoredBox(color: Colors.blue, child: Text('Page one')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final result = state.showSnackbar(
      'Pager-safe swipe',
      duration: MiuixSnackbarDuration.indefinite,
    );
    MiuixSnackbarResult? completion;
    unawaited(result.then((value) => completion = value));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));

    // The 240dp drag crosses the snackbar's 50% anchor and would also be
    // enough to select Page one if the ancestor PageView won the gesture.
    final initialLeft = tester.getTopLeft(surface).dx;
    final gesture = await tester.startGesture(tester.getCenter(surface));
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tester.getTopLeft(surface).dx, lessThan(initialLeft - 50));
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectedPage, 0);
    expect(pager.page, 0);
    expect(find.text('Pager-safe swipe'), findsNothing);
    expect(completion, MiuixSnackbarResult.dismissed);
    expect(find.text('Page zero'), findsOneWidget);
    expect(find.text('Page one'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'snackbar source widget exposes colors radius and inside margin',
    (tester) async {
      final state = MiuixSnackbarHostState();
      addTearDown(state.dispose);
      state.showSnackbar(
        'Source contract',
        actionLabel: '执行',
        withDismissAction: true,
        duration: MiuixSnackbarDuration.indefinite,
      );
      final data = await state.newestSnackbarData();
      const colors = MiuixSnackbarColors(
        containerColor: Color(0xFF102030),
        contentColor: Color(0xFF405060),
        actionContentColor: Color(0xFF708090),
        dismissActionContentColor: Color(0xFFA0B0C0),
        actionContainerColor: Color(0xFFD0E0F0),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                width: 400,
                child: MiuixSnackbar(
                  data: data!,
                  cornerRadius: 20,
                  colors: colors,
                  insideMargin: const EdgeInsets.fromLTRB(20, 10, 24, 12),
                  glass: false,
                ),
              ),
            ),
          ),
        ),
      );

      final surfaceFinder = find.byKey(
        const ValueKey('miuix-snackbar-surface'),
      );
      final surface = tester.widget<DecoratedBox>(surfaceFinder);
      final decoration = surface.decoration as ShapeDecoration;
      final defaults = MiuixSnackbarDefaults.snackbarColors(
        tester.element(surfaceFinder),
        containerColor: const Color(0xFF010203),
      );
      expect(defaults.containerColor, const Color(0xFF010203));
      expect(
        defaults.contentColor,
        MiuixSemanticColors.of(
          tester.element(surfaceFinder),
        )['secondaryVariant'],
      );
      expect(
        defaults.actionContentColor,
        MiuixSemanticColors.of(tester.element(surfaceFinder))['onPrimary'],
      );
      expect(
        defaults.dismissActionContentColor,
        MiuixSemanticColors.of(
          tester.element(surfaceFinder),
        )['onSurfaceContainerVariant'],
      );
      expect(
        defaults.actionContainerColor,
        MiuixSemanticColors.of(tester.element(surfaceFinder))['primary'],
      );
      final background = tester.widget<MiuixSquircleBackground>(
        find.descendant(
          of: surfaceFinder,
          matching: find.byType(MiuixSquircleBackground),
        ),
      );
      expect(background.color, colors.containerColor);
      expect(
        (decoration.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(20),
      );
      expect(
        tester.widget<Text>(find.text('Source contract')).style?.color,
        colors.contentColor,
      );
      expect(
        tester.widget<Text>(find.text('执行')).style?.color,
        colors.actionContentColor,
      );
      expect(tester.getSize(surfaceFinder).height, 48);
      final dismissFinder = find.byKey(
        const ValueKey('miuix-snackbar-dismiss-action'),
      );
      final dismissSemantics = tester.getSemantics(dismissFinder);
      expect(
        dismissSemantics,
        matchesSemantics(
          label: 'Dismiss',
          isImage: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      // Modifier.size(20.dp).clickable() retains a 20dp glyph but Android's
      // Compose touch-bounds expansion publishes a separate 48dp target.
      expect(dismissSemantics.rect.size, const Size.square(48));
      expect(
        tester.getSize(find.byIcon(MiuixIcons.basic.close)),
        const Size.square(20),
      );
    },
  );

  testWidgets('empty snackbar action label does not create an action button', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    state.showSnackbar(
      'Empty action',
      actionLabel: '',
      duration: MiuixSnackbarDuration.indefinite,
    );
    final data = await state.newestSnackbarData();

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: SizedBox(width: 400, child: MiuixSnackbar(data: data!)),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('miuix-snackbar-action')), findsNothing);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-snackbar-surface')))
          .height,
      48,
    );
  });

  testWidgets('extended scaffold keeps snackbar above animated bottom bar', (
    tester,
  ) async {
    final state = MiuixSnackbarHostState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            snackbarHost: MiuixSnackbarHost(
              state: state,
              contentBuilder: (context, data) => SizedBox(
                key: const ValueKey('measured-snackbar-surface'),
                height: 48,
                child: Text(data.visuals.message),
              ),
            ),
            bottomBar: const AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: SizedBox(
                key: ValueKey('measured-bottom-navigation'),
                height: 96,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Navigation-safe feedback',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final snackbar = tester.getRect(
      find.byKey(const ValueKey('measured-snackbar-surface')),
    );
    final bottomBar = tester.getRect(
      find.byKey(const ValueKey('measured-bottom-navigation')),
    );
    expect(
      find.byKey(const ValueKey('miuix-scaffold-snackbar-layer')),
      findsOneWidget,
    );
    // The host adds its own 12dp visual gap. The essential contract is that
    // even the complete custom surface ends before navigation begins.
    expect(snackbar.bottom, lessThan(bottomBar.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar stays above the floating tab and gesture region', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    final state = MiuixSnackbarHostState();
    var selectedDestination = -1;
    addTearDown(state.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            snackbarHost: MiuixSnackbarHost(
              state: state,
              contentBuilder: (context, data) => SizedBox(
                key: const ValueKey('floating-safe-snackbar'),
                height: 48,
                child: Text(data.visuals.message),
              ),
            ),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (index) => selectedDestination = index,
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
    await tester.pumpAndSettle();
    state.showSnackbar(
      'Floating-safe feedback',
      duration: MiuixSnackbarDuration.indefinite,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 240));

    final snackbar = tester.getRect(
      find.byKey(const ValueKey('floating-safe-snackbar')),
    );
    final pill = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    expect(
      find.byKey(const ValueKey('miuix-scaffold-snackbar-layer')),
      findsOneWidget,
    );
    debugDefaultTargetPlatformOverride = null;
    expect(snackbar.bottom, lessThan(pill.top));
    // The elevated host occupies only the message region. Its transparent
    // surroundings must never become a full-screen pointer barrier.
    await tester.tap(find.byIcon(Icons.settings));
    expect(selectedDestination, 1);
    expect(tester.takeException(), isNull);
  });

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
