part of '../miuix_flutter_test.dart';

// 按职责拆分原导航注册，测试名称、顺序与共享私有夹具保持不变。
void _registerNavigationStackTests() {
  test('navigation back stack is directly mutable and observable', () {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [_TestNavKey('root')]);
    var notifications = 0;
    stack.addListener(() => notifications += 1);

    stack.add(const _TestNavKey('details'));
    expect(stack.map((key) => key.name), ['root', 'details']);
    expect(notifications, 1);

    stack.replaceRange(1, 2, const [
      _TestNavKey('library'),
      _TestNavKey('reader'),
    ]);
    expect(stack.map((key) => key.name), ['root', 'library', 'reader']);
    expect(notifications, 2);

    stack.length = 2;
    expect(stack.map((key) => key.name), ['root', 'library']);
    expect(notifications, 3);
    expect(() => stack.length = 3, throwsUnsupportedError);
  });

  test(
    'navigation controller preserves root across destructive operations',
    () {
      final stack = miuixNavBackStackOf<_TestNavKey>(const [
        _TestNavKey('root'),
      ]);
      final controller = MiuixNavController<_TestNavKey>(stack);

      expect(controller.pop(), isFalse);
      controller.push(const _TestNavKey('library'));
      controller.push(const _TestNavKey('reader'));
      controller.replace(const _TestNavKey('reader-settings'));
      controller.popUntil((key) => key.name == 'library');
      expect(stack.map((key) => key.name), ['root', 'library']);
      expect(controller.pop(), isTrue);
      expect(stack.single.name, 'root');
      controller.popUntil((key) => false);
      expect(stack.single.name, 'root');

      final empty = MiuixNavBackStack<_TestNavKey>();
      MiuixNavController<_TestNavKey>(empty).replace(const _TestNavKey('root'));
      expect(empty.single.name, 'root');
    },
  );

  test('navigation back stack round-trips application-owned route data', () {
    final original = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('reader'),
    ]);
    final encoded = original.toRestorableData((key) => {'name': key.name});
    final restored = MiuixNavBackStack<_TestNavKey>.fromRestorableData(
      encoded,
      (value) =>
          _TestNavKey((value! as Map<Object?, Object?>)['name']! as String),
    );

    expect(restored, orderedEquals(original));
    expect(() => encoded.add('mutate'), throwsUnsupportedError);
  });

  test('navigation display effects keep exact continuous-depth boundaries', () {
    const leading = MiuixNavDisplayEffects(
      blockInputDuringTransition: true,
      backdropColor: Colors.red,
    );
    expect(leading.shouldClipCornersAt(-1), isFalse);
    expect(leading.shouldClipCornersAt(-.5), isTrue);
    expect(leading.shouldClipCornersAt(0), isFalse);
    expect(leading.shouldClipCornersAt(double.nan), isFalse);
    expect(leading.shouldBlockInputAt(-.5), isTrue);
    expect(leading.shouldBlockInputAt(1), isFalse);

    final all = leading.copyWith(
      cornerClipMode: MiuixNavCornerClipMode.all,
      clearBackdropColor: true,
    );
    expect(all.shouldClipCornersAt(-.5), isTrue);
    expect(all.shouldClipCornersAt(.5), isTrue);
    expect(all.shouldClipCornersAt(0), isFalse);
    expect(all.backdropColor, isNull);
    expect(all, equals(all.copyWith()));
    expect(MiuixNavDisplayEffects.none.shouldClipCornersAt(-.5), isFalse);
  });

  test('navigation motion validates springs and exposes source defaults', () {
    const defaults = MiuixNavMotion.defaults;
    final commit = defaults.commit as MiuixNavSpringSettleSpec;
    final programmatic = defaults.programmatic as MiuixNavTweenSettleSpec;
    expect(commit.dampingRatio, 1);
    expect(commit.stiffness, 146);
    expect(commit.clampOvershoot, isTrue);
    expect(programmatic.duration, const Duration(milliseconds: 500));
    expect(
      () => MiuixNavSpringSettleSpec(dampingRatio: .8),
      throwsArgumentError,
    );
    expect(
      MiuixNavSpringSettleSpec(
        dampingRatio: .8,
        clampOvershoot: false,
      ).toSpringDescription().stiffness,
      146,
    );
    expect(
      () => MiuixNavSpringSettleSpec(stiffness: double.infinity),
      throwsArgumentError,
    );
  });

  test('navigation route consumes its programmatic motion recipe', () {
    const curve = Curves.easeIn;
    const motion = MiuixNavMotion(
      programmatic: MiuixNavTweenSettleSpec(
        duration: Duration(milliseconds: 320),
        curve: curve,
      ),
    );
    final route = MiuixPageRoute<void>(
      builder: (_) => const SizedBox(),
      navMotion: motion,
    );
    const transitionBuilder = MiuixNavigationPageTransitionsBuilder(
      navMotion: motion,
    );
    expect(route.transitionDuration, const Duration(milliseconds: 320));
    expect(
      transitionBuilder.transitionDuration,
      const Duration(milliseconds: 320),
    );
    expect(
      MiuixNavigationTransitionMotion.programmaticCurve(route.navMotion),
      same(curve),
    );
  });

  testWidgets(
    'nav display keeps live entry state and one continuous layered driver',
    (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stack = miuixNavBackStackOf<_TestNavKey>(const [
        _TestNavKey('root'),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixNavDisplay<_TestNavKey>(
            backStack: stack,
            effects: const MiuixNavDisplayEffects(
              cornerClipRadius: 32,
              backdropColor: Colors.black,
            ),
            entries: (entries) {
              entries.entry<_TestNavKey>(
                contentKey: (key) => key.name,
                builder: (_, key) => _NavCounterPage(label: key.name),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('root:0'));
      await tester.pump();
      expect(find.text('root:1'), findsOneWidget);

      stack.add(const _TestNavKey('details'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('details:0'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('miuix-nav-display-scrim')),
        findsOneWidget,
      );
      final detailsTransform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey<Object>('details')),
          matching: find.byType(Transform),
        ),
      );
      final detailsX = detailsTransform.transform.getTranslation().x;
      expect(detailsX, inExclusiveRange(0, 400));

      await tester.pumpAndSettle();
      expect(find.text('root:1'), findsOneWidget);
      expect(find.text('details:0'), findsOneWidget);

      stack.add(const _TestNavKey('reader'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pumpAndSettle();
      expect(find.text('reader:0'), findsOneWidget);
      expect(find.text('root:1'), findsNothing);
      expect(
        find.text('root:1', skipOffstage: false),
        findsOneWidget,
        reason: 'depth-culled destinations must retain their Flutter State',
      );

      stack.removeLast();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('reader:0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('reader:0'), findsNothing);
      expect(find.text('details:0'), findsOneWidget);

      stack.removeLast();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('details:0'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('details:0'), findsNothing);
      expect(find.text('root:1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('nav display does not rebuild page bodies on transition ticks', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [_TestNavKey('root')]);
    final builds = <String, int>{};

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              contentKey: (key) => key.name,
              builder: (_, key) {
                builds.update(
                  key.name,
                  (value) => value + 1,
                  ifAbsent: () => 1,
                );
                return Center(child: Text(key.name));
              },
            );
          },
        ),
      ),
    );
    expect(builds, {'root': 1});

    stack.add(const _TestNavKey('details'));
    await tester.pump();
    expect(builds, {'root': 1, 'details': 1});
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pump(const Duration(milliseconds: 80));
    expect(builds, {'root': 1, 'details': 1});
    await tester.pumpAndSettle();

    stack.removeLast();
    await tester.pump();
    final returnBuilds = Map<String, int>.of(builds);
    final detailsTransform = find.byKey(
      const ValueKey<(String, Object)>((
        'miuix-nav-entry-transform',
        'details',
      )),
    );
    final before = tester
        .widget<Transform>(detailsTransform)
        .transform
        .getTranslation()
        .x;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 80));
    final after = tester
        .widget<Transform>(detailsTransform)
        .transform
        .getTranslation()
        .x;
    expect(after, greaterThan(before));
    expect(builds, returnBuilds);
    await tester.pumpAndSettle();
    expect(builds, returnBuilds);
  });

  testWidgets('nav display gesture grabs a running transition without a jump', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [_TestNavKey('root')]);
    final transition = MiuixNavTransition(
      dismissDirection: MiuixNavSwipeDirection.leftToRight,
      transform: MiuixNavTransitions.miuixDefault.transform,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          transition: transition,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              contentKey: (key) => key.name,
              builder: (_, key) => Center(child: Text(key.name)),
            );
          },
        ),
      ),
    );
    stack.add(const _TestNavKey('details'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    final finder = find.byKey(
      const ValueKey<(String, Object)>((
        'miuix-nav-entry-transform',
        'details',
      )),
    );
    final before = tester
        .widget<Transform>(finder)
        .transform
        .getTranslation()
        .x;

    final gesture = await tester.startGesture(const Offset(20, 300));
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    final after = tester.widget<Transform>(finder).transform.getTranslation().x;
    expect(after, greaterThanOrEqualTo(before));
    expect(after - before, lessThan(80));

    await gesture.moveBy(const Offset(-200, 0));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(stack.length, 2);
    expect(find.text('details'), findsOneWidget);
  });

  testWidgets('nav display classifies replacement and rejects duplicate keys', (
    tester,
  ) async {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('one'),
    ]);
    final changes = <Type>[];
    final transition = MiuixNavTransition(
      transform: (scope) {
        changes.add(scope.change.runtimeType);
        return MiuixNavEntryTransform.identity;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          transition: transition,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              contentKey: (key) => key.name,
              builder: (_, key) => Text(key.name),
            );
          },
        ),
      ),
    );
    stack[1] = const _TestNavKey('two');
    await tester.pump();
    expect(changes, contains(MiuixNavReplace));
    expect(find.text('two'), findsOneWidget);
    expect(find.text('one'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              contentKey: (_) => 'duplicate',
              builder: (_, key) => Text(key.name),
            );
          },
        ),
      ),
    );
    expect(tester.takeException(), isArgumentError);
  });

  testWidgets('nav display classifies batched mutations and external reorder', (
    tester,
  ) async {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [_TestNavKey('root')]);
    final changes = <Type>[];
    final transition = MiuixNavTransition(
      transform: (scope) {
        changes.add(scope.change.runtimeType);
        return MiuixNavEntryTransform.identity;
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          transition: transition,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              contentKey: (key) => key.name,
              builder: (_, key) => Center(child: Text(key.name)),
            );
          },
        ),
      ),
    );

    changes.clear();
    stack.addAll(const [_TestNavKey('one'), _TestNavKey('two')]);
    await tester.pump();
    expect(changes, contains(MiuixNavMultiPush));
    await tester.pumpAndSettle();

    changes.clear();
    stack.removeRange(1, 3);
    await tester.pump();
    expect(changes, contains(MiuixNavMultiPop));
    await tester.pumpAndSettle();

    stack.addAll(const [_TestNavKey('one'), _TestNavKey('two')]);
    await tester.pumpAndSettle();
    changes.clear();
    stack.replaceRange(0, 3, const [
      _TestNavKey('two'),
      _TestNavKey('root'),
      _TestNavKey('one'),
    ]);
    await tester.pump();
    expect(changes, contains(MiuixNavReplaceAll));
    expect(find.text('one'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav display refreshes a same-key registration in place', (
    tester,
  ) async {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [_TestNavKey('root')]);
    var revision = 'old';

    Widget buildDisplay() => MaterialApp(
      home: MiuixNavDisplay<_TestNavKey>(
        backStack: stack,
        entries: (entries) {
          entries.entry<_TestNavKey>(
            contentKey: (key) => key.name,
            builder: (_, key) => Text('${key.name}:$revision'),
          );
        },
      ),
    );

    await tester.pumpWidget(buildDisplay());
    expect(find.text('root:old'), findsOneWidget);
    revision = 'new';
    await tester.pumpWidget(buildDisplay());
    expect(find.text('root:new'), findsOneWidget);
    expect(find.byKey(const ValueKey<Object>('root')), findsNWidgets(2));
  });

  test('directional nav transition dispatches and merges source contracts', () {
    MiuixNavTransition branch(
      double x, {
      MiuixNavSwipeDirection dismiss = MiuixNavSwipeDirection.none,
      MiuixNavMotion motion = MiuixNavMotion.defaults,
      double opaqueDepth = 1,
    }) => MiuixNavTransition(
      transform: (_) => MiuixNavEntryTransform(translation: Offset(x, 0)),
      dismissDirection: dismiss,
      motion: motion,
      opaqueDepth: opaqueDepth,
      scrim: (_) => x / 10,
    );

    const popMotion = MiuixNavMotion(
      programmatic: MiuixNavTweenSettleSpec(
        duration: Duration(milliseconds: 320),
        curve: Curves.linear,
      ),
    );
    final transition = miuixNavDirectionalTransition(
      push: branch(1),
      pop: branch(2, motion: popMotion, opaqueDepth: 2),
      predictivePop: branch(
        3,
        dismiss: MiuixNavSwipeDirection.rightToLeft,
        opaqueDepth: 3,
      ),
    );
    MiuixNavTransitionScope scope({
      required MiuixNavChange change,
      MiuixNavGesture? gesture,
    }) => MiuixNavTransitionScope(
      relativeDepth: 0,
      role: MiuixNavRole.top,
      change: change,
      gesture: gesture,
      settle: null,
      layoutSize: const Size(400, 600),
      textDirection: TextDirection.ltr,
      devicePixelRatio: 1,
    );

    expect(
      transition.transform(scope(change: const MiuixNavPush())).translation.dx,
      1,
    );
    expect(
      transition.transform(scope(change: const MiuixNavPop())).translation.dx,
      2,
    );
    expect(
      transition
          .transform(
            scope(
              change: const MiuixNavPop(),
              gesture: const MiuixNavGesture(
                progress: .2,
                swipeEdge: MiuixNavSwipeEdge.left,
                touchY: 100,
                initialTouchY: 100,
              ),
            ),
          )
          .translation
          .dx,
      3,
    );
    expect(transition.opaqueDepth, 3);
    expect(transition.dismissDirection, MiuixNavSwipeDirection.rightToLeft);
    expect(
      (transition.motion.programmatic as MiuixNavTweenSettleSpec).duration,
      const Duration(milliseconds: 320),
    );
  });

  testWidgets('nav display swipe cancels then commits with source thresholds', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('details'),
    ]);
    final swipeTransition = MiuixNavTransition(
      dismissDirection: MiuixNavSwipeDirection.leftToRight,
      transform: (scope) => MiuixNavEntryTransform(
        translation: Offset(
          (-scope.relativeDepth).clamp(0.0, 1.0) * scope.layoutSize.width,
          0,
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          transition: swipeTransition,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              builder: (_, key) => ColoredBox(
                color: key.name == 'root' ? Colors.white : Colors.blue,
                child: Center(child: Text(key.name)),
              ),
            );
          },
        ),
      ),
    );

    await tester.dragFrom(const Offset(20, 300), const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(stack.length, 2);
    expect(find.text('details'), findsOneWidget);

    await tester.dragFrom(const Offset(20, 300), const Offset(260, 0));
    await tester.pumpAndSettle();
    expect(stack.length, 1);
    expect(find.text('details'), findsNothing);
    expect(find.text('root'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav display honors every physical swipe dismissal direction', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const cases = <(MiuixNavSwipeDirection, Offset)>[
      (MiuixNavSwipeDirection.rightToLeft, Offset(-260, 0)),
      (MiuixNavSwipeDirection.topToBottom, Offset(0, 360)),
      (MiuixNavSwipeDirection.bottomToTop, Offset(0, -360)),
    ];

    for (final (direction, delta) in cases) {
      final stack = miuixNavBackStackOf<_TestNavKey>(const [
        _TestNavKey('root'),
        _TestNavKey('details'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixNavDisplay<_TestNavKey>(
            backStack: stack,
            transition: MiuixNavTransition(
              dismissDirection: direction,
              transform: (_) => MiuixNavEntryTransform.identity,
            ),
            entries: (entries) {
              entries.entry<_TestNavKey>(
                builder: (_, key) => Center(child: Text(key.name)),
              );
            },
          ),
        ),
      );
      await tester.dragFrom(const Offset(200, 300), delta);
      await tester.pumpAndSettle();
      expect(stack.length, 1, reason: '$direction must commit physically');
      expect(find.text('root'), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav display follows and cancels Android predictive back', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('details'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              builder: (_, key) => ColoredBox(
                color: key.name == 'root' ? Colors.white : Colors.blue,
                child: Center(child: Text(key.name)),
              ),
            );
          },
        ),
      ),
    );
    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 300.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [160.0, 320.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();
    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<Object>(_TestNavKey('details'))),
        matching: find.byType(Transform),
      ),
    );
    expect(transform.transform.getTranslation().x, closeTo(160, 1));
    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    await tester.pumpAndSettle();
    expect(stack.length, 2);
    expect(find.text('details'), findsOneWidget);

    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 300.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [120.0, 300.0],
      'progress': 0.3,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final firstCommitFrame = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<Object>(_TestNavKey('details'))),
        matching: find.byType(Transform),
      ),
    );
    expect(
      firstCommitFrame.transform.getTranslation().x,
      greaterThan(120),
      reason: 'predictive commit must not wait for an extra post-frame settle',
    );
    await tester.pumpAndSettle();
    expect(stack.length, 1);
    expect(find.text('details'), findsNothing);
    expect(find.text('root'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nav display gives an interactive child first swipe ownership', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('details'),
    ]);
    var childUpdates = 0;
    final swipeTransition = MiuixNavTransition(
      dismissDirection: MiuixNavSwipeDirection.leftToRight,
      transform: (_) => MiuixNavEntryTransform.identity,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          transition: swipeTransition,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              builder: (_, key) => GestureDetector(
                key: ValueKey('nav-child-horizontal-control-${key.name}'),
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (_) => childUpdates += 1,
                child: Center(child: Text(key.name)),
              ),
            );
          },
        ),
      ),
    );
    await tester.drag(
      find.byKey(const ValueKey('nav-child-horizontal-control-details')),
      const Offset(280, 0),
    );
    await tester.pumpAndSettle();
    expect(childUpdates, greaterThan(0));
    expect(stack.length, 2);
    expect(find.text('details'), findsOneWidget);
  });

  testWidgets('nav display keeps modal boundary ownership through pop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('modal'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          entries: (entries) {
            entries.entry<_TestNavKey>(
              transition: MiuixNavTransitions.modal,
              builder: (_, key) => ColoredBox(
                color: key.name == 'root' ? Colors.white : Colors.blue,
                child: Center(child: Text(key.name)),
              ),
            );
          },
        ),
      ),
    );
    stack.removeLast();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    final rootTransform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<Object>(_TestNavKey('root'))),
        matching: find.byType(Transform),
      ),
    );
    final modalTransform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<Object>(_TestNavKey('modal'))),
        matching: find.byType(Transform),
      ),
    );
    final rootTranslation = rootTransform.transform.getTranslation();
    expect(rootTranslation.x, 0);
    expect(rootTranslation.y, 0);
    expect(
      modalTransform.transform.getTranslation().y,
      inExclusiveRange(0, 600),
    );
    await tester.pumpAndSettle();
    expect(find.text('modal'), findsNothing);
  });

  testWidgets(
    'nav display settles stack changes immediately with reduced motion',
    (tester) async {
      final stack = miuixNavBackStackOf<_TestNavKey>(const [
        _TestNavKey('root'),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: MiuixNavDisplay<_TestNavKey>(
              backStack: stack,
              entries: (entries) {
                entries.entry<_TestNavKey>(
                  builder: (_, key) => Center(child: Text(key.name)),
                );
              },
            ),
          ),
        ),
      );
      stack.add(const _TestNavKey('details'));
      await tester.pump();
      await tester.pump();
      expect(find.text('details'), findsOneWidget);
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(const ValueKey<Object>(_TestNavKey('details'))),
          matching: find.byType(Transform),
        ),
      );
      final translation = transform.transform.getTranslation();
      expect(translation.x, 0);
      expect(translation.y, 0);
      stack.removeLast();
      await tester.pump();
      await tester.pump();
      expect(find.text('details'), findsNothing);
      expect(find.text('root'), findsOneWidget);
    },
  );

  testWidgets('nav display contains non-finite custom visual values', (
    tester,
  ) async {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('details'),
    ]);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixNavDisplay<_TestNavKey>(
          backStack: stack,
          effects: const MiuixNavDisplayEffects(
            cornerClipRadius: double.infinity,
            dimAmount: double.nan,
          ),
          transition: MiuixNavTransition(
            opaqueDepth: double.nan,
            scrim: (_) => double.infinity,
            transform: (_) => const MiuixNavEntryTransform(
              translation: Offset(double.nan, double.infinity),
              scaleX: double.nan,
              scaleY: -1,
              opacity: double.nan,
            ),
          ),
          entries: (entries) {
            entries.entry<_TestNavKey>(
              builder: (_, key) => Center(child: Text(key.name)),
            );
          },
        ),
      ),
    );

    final transform = tester.widget<Transform>(
      find.descendant(
        of: find.byKey(const ValueKey<Object>(_TestNavKey('details'))),
        matching: find.byType(Transform),
      ),
    );
    final translation = transform.transform.getTranslation();
    expect(translation.x, 0);
    expect(translation.y, 0);
    expect(find.byKey(const ValueKey('miuix-nav-display-scrim')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test(
    'nav system corner radius reads the Android plugin and sanitizes it',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      const channel = MethodChannel('flutter_miuix/platform');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'screenCornerRadius');
            return 28.0;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      expect(await loadMiuixNavSystemCornerRadius(), 28);
    },
  );

  testWidgets('public predictive back handler emits one finite event stream', (
    tester,
  ) async {
    final events = <MiuixNavBackEvent>[];
    var commits = 0;
    var cancels = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixPredictiveBackHandler(
          onProgress: events.add,
          onCommit: () => commits += 1,
          onCancel: () => cancels += 1,
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(
      await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
        'touchOffset': [1.0, 120.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [400.0, 140.0],
      'progress': 1.0,
      'swipeEdge': 1,
    });
    await tester.pump();
    expect(events, hasLength(2));
    expect(events.first.progress, 0);
    expect(events.first.swipeEdge, MiuixNavSwipeEdge.left);
    expect(events.last.progress, .999);
    expect(events.last.swipeEdge, MiuixNavSwipeEdge.right);
    expect(events.last.touchY, 140);
    expect(events.last.frameTimeMillis, greaterThanOrEqualTo(0));

    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    expect(cancels, 1);
    expect(commits, 0);

    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 120.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    expect(commits, 1);
    expect(cancels, 1);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    expect(commits, 2, reason: 'button Back is the discrete commit path');
  });

  testWidgets('only the top MIUIX back owner receives a platform gesture', (
    tester,
  ) async {
    final outerEvents = <MiuixNavBackEvent>[];
    final innerEvents = <MiuixNavBackEvent>[];
    var showInner = true;

    Widget buildTree() => MaterialApp(
      home: MiuixPredictiveBackHandler(
        onProgress: outerEvents.add,
        onCommit: () {},
        onCancel: () {},
        child: showInner
            ? MiuixPredictiveBackHandler(
                onProgress: innerEvents.add,
                onCommit: () {},
                onCancel: () {},
                child: const SizedBox.expand(),
              )
            : const SizedBox.expand(),
      ),
    );

    await tester.pumpWidget(buildTree());
    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(innerEvents, hasLength(1));
    expect(outerEvents, isEmpty);
    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');

    showInner = false;
    await tester.pumpWidget(buildTree());
    await tester.pump();
    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    expect(outerEvents, hasLength(1));
    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    expect(tester.takeException(), isNull);
  });

  testWidgets('covered nav display yields Back to the highest eligible owner', (
    tester,
  ) async {
    final stack = miuixNavBackStackOf<_TestNavKey>(const [
      _TestNavKey('root'),
      _TestNavKey('details'),
    ]);
    var overlayEnabled = true;
    var overlayCommits = 0;

    Widget buildTree() => MaterialApp(
      home: Stack(
        children: [
          MiuixNavDisplay<_TestNavKey>(
            backStack: stack,
            entries: (entries) {
              entries.entry<_TestNavKey>(
                builder: (_, key) => Center(child: Text(key.name)),
              );
            },
          ),
          MiuixPredictiveBackHandler(
            enabled: overlayEnabled,
            onProgress: (_) {},
            onCommit: () => overlayCommits += 1,
            onCancel: () {},
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );

    await tester.pumpWidget(buildTree());
    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    expect(overlayCommits, 1);
    expect(
      stack,
      hasLength(2),
      reason: 'the covered display must not also pop',
    );

    overlayEnabled = false;
    await tester.pumpWidget(buildTree());
    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 100.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(overlayCommits, 1);
    expect(
      stack,
      hasLength(1),
      reason: 'an ineligible owner must not block nav',
    );
    expect(tester.takeException(), isNull);
  });

  test('navigation reverse motion restarts the spring from elapsed time', () {
    const rawValue = .968;
    final resolved = MiuixNavigationTransitionMotion.resolveValue(
      value: rawValue,
      status: AnimationStatus.reverse,
    );
    final outgoingDistance = 1 - resolved;
    final expected = MiuixNavigationTransitionMotion.curve.transform(
      1 - rawValue,
    );

    expect(outgoingDistance, closeTo(expected, 1e-12));
    expect(outgoingDistance, greaterThan(.01));
    expect(
      MiuixNavigationTransitionMotion.resolveValue(
        value: 1,
        status: AnimationStatus.reverse,
      ),
      1,
    );
    expect(
      MiuixNavigationTransitionMotion.resolveValue(
        value: 0,
        status: AnimationStatus.reverse,
      ),
      0,
    );
  });

  testWidgets('public navigation route moves on the first return frame', (
    tester,
  ) async {
    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          // Pin the builder platform: desktop test hosts otherwise select the
          // Windows fallback even though this fixture registers Android only.
          platform: TargetPlatform.android,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: MiuixNavigationPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (context) {
            homeContext = context;
            return const SizedBox.expand(child: Text('Level 1'));
          },
        ),
      ),
    );

    final route = MiuixPageRoute<void>(
      builder: (_) => const SizedBox.expand(child: Text('Level 2')),
    );
    expect(route.transitionDuration, const Duration(milliseconds: 500));
    // NavDisplay keeps live entry layers. A route snapshot can freeze blur,
    // shader, and ticker-backed content during pop even if its outer transform
    // moves, so the public MIUIX route disables Flutter snapshotting by default.
    expect(route.allowSnapshotting, isFalse);
    unawaited(Navigator.of(homeContext).push<void>(route));
    await tester.pumpAndSettle();
    expect(find.text('Level 2'), findsOneWidget);

    Navigator.of(tester.element(find.text('Level 2'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final translations = tester
        .widgetList<FractionalTranslation>(find.byType(FractionalTranslation))
        .map((widget) => widget.translation.dx);
    expect(
      translations.any((value) => value > .01),
      isTrue,
      reason: 'the outgoing route must not dwell at its settled pose',
    );
    // Both the retained alpha and fixed scrim recover on that same first
    // moving frame. This rejects the previous frozen-page/late-jump sequence.
    final returningOpacities = tester
        .widgetList<Opacity>(
          find.byKey(const ValueKey('miuix-navigation-covered-opacity')),
        )
        .map((opacity) => opacity.opacity);
    expect(returningOpacities.any((value) => value > .9 && value < 1), isTrue);
    // Flutter offstages the covered route at rest. Once pop exposes it, the
    // dim must be present as a sibling rather than inside its translated page.
    final dim = find.byKey(const ValueKey('miuix-navigation-transition-dim'));
    expect(dim, findsOneWidget);
    final returningDim = tester.widget<ColoredBox>(dim);
    expect(returningDim.color.a, inExclusiveRange(0, .5));
    expect(
      find.ancestor(
        of: dim,
        matching: find.byKey(
          const ValueKey('miuix-navigation-transition-scene'),
        ),
      ),
      findsNothing,
    );
    await tester.pumpAndSettle();
    expect(find.text('Level 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public navigation route keeps predictive progress continuous', (
    tester,
  ) async {
    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          platform: TargetPlatform.android,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: MiuixNavigationPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (context) {
            homeContext = context;
            return const SizedBox.expand(child: Text('Predictive root'));
          },
        ),
      ),
    );
    unawaited(
      Navigator.of(homeContext).push<void>(
        MiuixPageRoute<void>(
          builder: (_) =>
              const SizedBox.expand(child: Text('Predictive details')),
        ),
      ),
    );
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
      'touchOffset': [160.0, 300.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();
    List<double> translations() => tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('miuix-navigation-transition-scene')),
        )
        .map((scene) => scene.translation.dx)
        .toList();
    final dragged = translations();
    expect(dragged.any((value) => (value - .4).abs() < 1e-9), isTrue);
    expect(dragged.any((value) => (value + .15).abs() < 1e-9), isTrue);

    await _sendMiuixPredictiveBack(tester, 'cancelBackGesture');
    await tester.pump();
    final canceledAtRelease = translations();
    expect(canceledAtRelease.any((value) => (value - .4).abs() < 1e-9), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Predictive details'), findsOneWidget);

    await _sendMiuixPredictiveBack(tester, 'startBackGesture', const {
      'touchOffset': [1.0, 300.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await _sendMiuixPredictiveBack(tester, 'updateBackGestureProgress', const {
      'touchOffset': [160.0, 300.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();
    await _sendMiuixPredictiveBack(tester, 'commitBackGesture');
    await tester.pump();
    final released = translations();
    expect(released.any((value) => (value - .4).abs() < 1e-9), isTrue);
    expect(released.any((value) => (value + .15).abs() < 1e-9), isTrue);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(translations().any((value) => value > .4), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('Predictive details'), findsNothing);
    expect(find.text('Predictive root'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('public navigation transition mirrors its motion in RTL', (
    tester,
  ) async {
    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        theme: ThemeData(
          // Keep the direction assertion on the same MIUIX builder regardless
          // of the workstation platform executing the widget test.
          platform: TargetPlatform.android,
          pageTransitionsTheme: const PageTransitionsTheme(
            builders: <TargetPlatform, PageTransitionsBuilder>{
              TargetPlatform.android: MiuixNavigationPageTransitionsBuilder(),
            },
          ),
        ),
        home: Builder(
          builder: (context) {
            homeContext = context;
            return const SizedBox.expand(child: Text('RTL level 1'));
          },
        ),
      ),
    );

    unawaited(
      Navigator.of(homeContext).push<void>(
        MiuixPageRoute<void>(
          builder: (_) => const SizedBox.expand(child: Text('RTL level 2')),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final translations = tester
        .widgetList<FractionalTranslation>(find.byType(FractionalTranslation))
        .map((widget) => widget.translation.dx);
    expect(
      translations.any((value) => value < -.01),
      isTrue,
      reason: 'logical-end entry must mirror to the left in RTL',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('large top bar animates compact title like source threshold', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topCenter,
            child: MiuixTopAppBar(
              title: 'Animated title',
              large: true,
              scrollBehavior: behavior,
            ),
          ),
        ),
      ),
    );

    Opacity compactOpacity() => tester.widget<Opacity>(
      find.byKey(const ValueKey('top-app-bar-compact-title-opacity')),
    );

    // TopAppBar.kt keeps the compact title transparent before its
    // `collapsedFraction * 3 >= 1` threshold.
    expect(compactOpacity().opacity, 0);
    behavior.setCollapseFraction(.34);
    await tester.pump();
    expect(compactOpacity().opacity, 0);

    // The source's 0.3s critically damped show spring must expose a genuine
    // transition instead of switching the title on in a single frame.
    await tester.pump(const Duration(milliseconds: 75));
    expect(compactOpacity().opacity, greaterThan(0));
    expect(compactOpacity().opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 225));
    expect(compactOpacity().opacity, 1);

    // Dropping below the threshold uses the source's faster 0.15s response.
    behavior.setCollapseFraction(.2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(compactOpacity().opacity, greaterThan(0));
    expect(compactOpacity().opacity, lessThan(1));
    await tester.pump(const Duration(milliseconds: 110));
    expect(compactOpacity().opacity, 0);
  });

  testWidgets('top bar skips compact-title and settle motion when reduced', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    const barKey = ValueKey('reduced-motion-top-bar');
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: MiuixTopAppBar(
              key: barKey,
              title: 'Reduced title',
              large: true,
              scrollBehavior: behavior,
            ),
          ),
        ),
      ),
    );

    behavior.setCollapseFraction(.34);
    await tester.pump();
    final compactOpacity = tester.widget<Opacity>(
      find.byKey(const ValueKey('top-app-bar-compact-title-opacity')),
    );
    expect(compactOpacity.opacity, 1);

    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 0,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    behavior.setCollapseFraction(.6);
    behavior.handleNotification(
      ScrollEndNotification(
        metrics: metrics,
        context: tester.element(find.byKey(barKey)),
      ),
    );
    expect(behavior.collapseFraction, 1);
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('top bar snap uses the source frame-clock spring', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 0,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox(key: ValueKey('top-bar-motion-host'))),
    );
    final context = tester.element(
      find.byKey(const ValueKey('top-bar-motion-host')),
    );

    behavior.setCollapseFraction(.6);
    behavior.handleNotification(
      ScrollEndNotification(metrics: metrics, context: context),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // A critically damped stiffness-2500 spring has omega=50. At 50ms its
    // normalized response is 1 - (1 + 2.5)e^-2.5 = .7127, placing a .6 start
    // near .885 on the way to the collapsed endpoint.
    expect(behavior.collapseFraction, closeTo(.885, .025));
    await tester.pumpAndSettle();
    expect(behavior.collapseFraction, 1);
  });

  testWidgets('new top bar input cancels an in-flight source spring', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 0,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox(key: ValueKey('top-bar-motion-host'))),
    );
    final context = tester.element(
      find.byKey(const ValueKey('top-bar-motion-host')),
    );

    behavior.setCollapseFraction(.6);
    behavior.handleNotification(
      ScrollEndNotification(metrics: metrics, context: context),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    behavior.handleNotification(
      ScrollStartNotification(metrics: metrics, context: context),
    );
    final interrupted = behavior.collapseFraction;
    await tester.pump(const Duration(milliseconds: 500));

    expect(interrupted, greaterThan(.6));
    expect(behavior.collapseFraction, interrupted);
  });

  testWidgets('top bar release velocity continues through Android decay', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: 0,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox(key: ValueKey('top-bar-motion-host'))),
    );
    final context = tester.element(
      find.byKey(const ValueKey('top-bar-motion-host')),
    );

    behavior.setCollapseFraction(.6);
    behavior.handleNotification(
      ScrollEndNotification(
        metrics: metrics,
        context: context,
        dragDetails: DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(0, 800)),
          primaryVelocity: 800,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 32));

    // Positive vertical release velocity expands the negative height offset.
    // The previous fixed tween ignored this channel and always collapsed from
    // a .6 fraction solely because it was beyond the halfway threshold.
    expect(behavior.collapseFraction, lessThan(.6));
    await tester.pumpAndSettle();
    expect(behavior.collapseFraction, 0);
  });

  testWidgets('large top bar scroll extent follows its title column', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero);
    addTearDown(behavior.dispose);

    FixedScrollMetrics metrics(double pixels) => FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      pixels: pixels,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixTopAppBar(title: 'Title', scrollBehavior: behavior),
        ),
      ),
    );
    // 94 - 52 - 4 = 38dp is the measured 32sp title column represented by
    // the source's nested-scroll heightOffsetLimit.
    behavior.syncMetrics(metrics(19));
    expect(behavior.collapseFraction, closeTo(.5, .001));

    behavior.expand();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixTopAppBar(
            title: 'Title',
            subtitle: 'Summary',
            scrollBehavior: behavior,
          ),
        ),
      ),
    );
    // Adding the 14sp supporting line changes that column extent to 54dp.
    behavior.syncMetrics(metrics(27));
    expect(behavior.collapseFraction, closeTo(.5, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('underfilled pages keep the large title expanded', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero);
    addTearDown(behavior.dispose);
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 0,
      pixels: 0,
      viewportDimension: 800,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    await tester.pumpWidget(
      const MaterialApp(home: SizedBox(key: ValueKey('short-page-host'))),
    );
    final context = tester.element(
      find.byKey(const ValueKey('short-page-host')),
    );

    behavior.setCollapseFraction(.75);
    behavior.syncMetrics(metrics);
    expect(behavior.collapseFraction, 0);
    expect(behavior.contentOffset, 0);

    behavior.handleNotification(
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: 80,
        dragDetails: DragUpdateDetails(
          globalPosition: Offset.zero,
          delta: const Offset(0, -80),
        ),
      ),
    );
    expect(behavior.collapseFraction, 0);
    expect(behavior.contentOffset, 0);
  });

  testWidgets('small top bar pins and restores a shared scroll behavior', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior();
    addTearDown(behavior.dispose);
    behavior.setCollapseFraction(.5);

    Widget compact() => MaterialApp(
      home: MiuixTheme(
        child: Align(
          alignment: Alignment.topCenter,
          child: MiuixSmallTopAppBar(
            title: 'Shared title',
            scrollBehavior: behavior,
          ),
        ),
      ),
    );
    Widget large() => MaterialApp(
      home: MiuixTheme(
        child: Align(
          alignment: Alignment.topCenter,
          child: MiuixTopAppBar(
            title: 'Shared title',
            scrollBehavior: behavior,
          ),
        ),
      ),
    );

    await tester.pumpWidget(compact());
    await tester.pump();
    // SmallTopAppBar pins only the height channel. The previous content offset
    // survives so a later large bar can recover the right title state.
    expect(behavior.collapseFraction, 0);
    expect(behavior.contentOffset, closeTo(-19, .001));

    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 500,
      pixels: 120,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    // Programmatic/PageStorage metrics bypass pointer notifications, but the
    // compact bar must remain pinned on that path too.
    behavior.syncMetrics(metrics);
    expect(behavior.collapseFraction, 0);
    expect(behavior.contentOffset, -120);

    await tester.pumpWidget(large());
    // TopAppBar.kt uses any negative compact-mode content offset to restore
    // the complete collapsed endpoint before measuring the large title.
    expect(behavior.collapseFraction, 1);
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('top-app-bar-compact-title-opacity')),
          )
          .opacity,
      1,
    );

    await tester.pumpWidget(compact());
    await tester.pump();
    final leadingMetrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 500,
      pixels: 0,
      viewportDimension: 600,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    behavior.handleNotification(
      ScrollUpdateNotification(
        metrics: leadingMetrics,
        context: tester.element(find.byType(MiuixSmallTopAppBar)),
        scrollDelta: -120,
      ),
    );
    expect(behavior.contentOffset, 0);
    await tester.pumpWidget(large());
    expect(behavior.collapseFraction, 0);
    await tester.pump(const Duration(milliseconds: 150));
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('top-app-bar-compact-title-opacity')),
          )
          .opacity,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  test('navigation and top app bar defaults expose current source metrics', () {
    expect(MiuixNavigationBarDefaults.itemHeight, 64);
    expect(MiuixNavigationBarDefaults.iconSize, 26);
    expect(MiuixNavigationBarDefaults.labelFontSize, 12);
    expect(MiuixNavigationBarDefaults.iconTopPadding, 8);
    expect(MiuixNavigationBarDefaults.bottomPadding, 8);
    expect(MiuixNavigationBarDefaults.selectedPressedAlpha, .5);
    expect(MiuixNavigationBarDefaults.unselectedPressedAlpha, .6);
    expect(MiuixNavigationBarDefaults.unselectedAlpha, .4);

    expect(MiuixFloatingNavigationBarDefaults.horizontalOutsidePadding, 36);
    expect(MiuixFloatingNavigationBarDefaults.shadowElevation, 1);
    expect(MiuixFloatingNavigationBarDefaults.horizontalPadding, 12);
    expect(MiuixFloatingNavigationBarDefaults.itemSpacing, 12);
    expect(MiuixFloatingNavigationBarDefaults.iconSize, 28);
    expect(MiuixFloatingNavigationBarDefaults.iconPadding, 10);
    expect(MiuixFloatingNavigationBarDefaults.selectedPressedAlpha, .5);
    expect(MiuixFloatingNavigationBarDefaults.unselectedPressedAlpha, .6);
    expect(MiuixFloatingNavigationBarDefaults.unselectedAlpha, .4);

    expect(MiuixTopAppBarDefaults.titlePadding, 26);
    expect(MiuixTopAppBarDefaults.navigationIconPadding, 16);
    expect(MiuixTopAppBarDefaults.actionIconPadding, 16);
    expect(MiuixTopAppBarDefaults.collapsedHeight, 52);
    expect(MiuixTopAppBarDefaults.smallTopAppBarCenterHeight, 50);
    expect(MiuixTopAppBarDefaults.largeTitleBottomPadding, 4);
    expect(MiuixTopAppBarDefaults.subtitleBottomPadding, 8);
  });

  test(
    'hoisted top app bar state synchronizes both scroll behavior directions',
    () {
      final state = MiuixTopAppBarState(
        initialHeightOffsetLimit: -100,
        initialHeightOffset: -50,
        initialContentOffset: -25,
      );
      final behavior = MiuixTopAppBarScrollBehavior(state: state);
      addTearDown(behavior.dispose);
      addTearDown(state.dispose);

      expect(state.collapsedFraction, .5);
      expect(state.overlappedFraction, .25);
      expect(behavior.collapseFraction, .5);
      expect(behavior.contentOffset, -25);

      behavior.setCollapseFraction(.25);
      expect(state.heightOffsetLimit, -100);
      expect(state.heightOffset, -25);
      expect(state.collapsedFraction, .25);

      state.heightOffset = -80;
      state.contentOffset = -140;
      expect(behavior.collapseFraction, .8);
      expect(behavior.contentOffset, -140);

      state.heightOffset = -200;
      expect(state.heightOffset, -100);
      expect(behavior.collapseFraction, 1);
    },
  );

  testWidgets(
    'large top bar consumes upward drag before its list like source',
    (tester) async {
      final behavior = MiuixTopAppBarScrollBehavior(
        snapDuration: Duration.zero,
      );
      final controller = ScrollController();
      addTearDown(behavior.dispose);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: MiuixScaffold(
              topBar: MiuixTopAppBar(
                title: 'Nested title',
                // A tall fixture leaves enough pre-scroll range to inspect a
                // stable intermediate frame independent of test touch slop.
                expandedHeight: 200,
                scrollBehavior: behavior,
              ),
              body: ListView(
                controller: controller,
                children: const [SizedBox(height: 1600)],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();

      // The complete effective scroll belongs to the 144dp title column. Keep
      // the assertion independent of Flutter test touch-slop accounting: the
      // important source invariant is that the title moved while the list and
      // progressive content-offset channel did not.
      expect(behavior.collapseFraction, greaterThan(0));
      expect(behavior.collapseFraction, lessThan(1));
      expect(behavior.contentOffset, closeTo(0, .01));
      expect(controller.offset, closeTo(0, .01));

      await gesture.moveBy(const Offset(0, -160));
      await tester.pump();

      // The source returns the complete available delta whenever heightOffset
      // changed. A single update crossing the collapse limit is therefore
      // consumed in full rather than forwarding its arithmetic remainder.
      expect(behavior.collapseFraction, 1);
      expect(controller.offset, closeTo(0, .01));
      expect(behavior.contentOffset, closeTo(0, .01));

      // Only the next update, which starts with the title already collapsed,
      // reaches the list and the independent content-offset channel.
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump();
      expect(controller.offset, greaterThan(0));
      expect(behavior.contentOffset, closeTo(-controller.offset, .01));
      await gesture.up();
      await tester.pump();
      expect(behavior.contentOffset, closeTo(-controller.offset, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large top bar expands only after downward list reaches top', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero)
      ..setCollapseFraction(1);
    final controller = ScrollController(initialScrollOffset: 100);
    addTearDown(behavior.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            topBar: MiuixTopAppBar(
              title: 'Nested title',
              scrollBehavior: behavior,
            ),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1600)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    behavior.setCollapseFraction(1);
    await tester.pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(ListView)),
    );
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(controller.offset, greaterThan(0));
    expect(behavior.collapseFraction, 1);

    await gesture.moveBy(const Offset(0, 100));
    await tester.pump();
    expect(controller.offset, closeTo(0, .01));
    expect(behavior.collapseFraction, lessThan(1));
    expect(behavior.collapseFraction, greaterThan(0));
    await gesture.up();
    await tester.pump();
    expect(behavior.contentOffset, closeTo(0, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaffold restores a collapsed top bar from saved metrics', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero);
    final controller = ScrollController(initialScrollOffset: 120);
    addTearDown(behavior.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            topBar: MiuixTopAppBar(
              title: 'Restored title',
              large: true,
              scrollBehavior: behavior,
            ),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1600)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(controller.offset, 120);
    expect(behavior.collapseFraction, 1);
  });

  testWidgets('programmatic list jumps synchronize restored top bar state', (
    tester,
  ) async {
    final behavior = MiuixTopAppBarScrollBehavior(snapDuration: Duration.zero);
    final controller = ScrollController();
    addTearDown(behavior.dispose);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            topBar: MiuixTopAppBar(
              title: 'Programmatic title',
              scrollBehavior: behavior,
            ),
            body: ListView(
              controller: controller,
              children: const [SizedBox(height: 1600)],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    controller.jumpTo(120);
    await tester.pump();

    // Non-pointer relocation has no delta that can be returned through
    // correctBy. Keep the package restoration contract deterministic by
    // deriving both channels from the absolute ScrollPosition.
    expect(controller.offset, 120);
    expect(behavior.collapseFraction, 1);
    expect(behavior.contentOffset, -120);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PageStorage restoration reattaches the collapsed top bar', (
    tester,
  ) async {
    final bucket = PageStorageBucket();
    final firstBehavior = MiuixTopAppBarScrollBehavior(
      snapDuration: Duration.zero,
    );
    final restoredBehavior = MiuixTopAppBarScrollBehavior(
      snapDuration: Duration.zero,
    );
    addTearDown(firstBehavior.dispose);
    addTearDown(restoredBehavior.dispose);

    Widget page(MiuixTopAppBarScrollBehavior behavior) => MaterialApp(
      home: PageStorage(
        bucket: bucket,
        child: MiuixTheme(
          child: MiuixScaffold(
            topBar: MiuixTopAppBar(
              title: 'Stored title',
              large: true,
              scrollBehavior: behavior,
            ),
            body: ListView(
              key: const PageStorageKey('stored-list'),
              children: const [SizedBox(height: 1600)],
            ),
          ),
        ),
      ),
    );

    await tester.pumpWidget(page(firstBehavior));
    // A source pre-scroll update that changes heightOffset is consumed in
    // full. The first gesture collapses the bar; a subsequent gesture starts
    // with the bar collapsed and therefore creates the restorable list offset.
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(firstBehavior.collapseFraction, 1);
    await tester.drag(find.byType(ListView), const Offset(0, -180));
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      MaterialApp(
        home: PageStorage(bucket: bucket, child: const SizedBox()),
      ),
    );
    await tester.pumpWidget(page(restoredBehavior));
    await tester.pump();
    await tester.pump();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.pixels, greaterThan(42));
    expect(restoredBehavior.collapseFraction, 1);
  });

  testWidgets(
    'navigation bar uses HyperOS 4 glass defaults and label metrics',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              bottomNavigationBar: MiuixNavigationBar(
                selectedIndex: 0,
                onDestinationSelected: (_) {},
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

      final scheme = Theme.of(tester.element(find.text('Home'))).colorScheme;
      final selectedLabel = tester.widget<Text>(find.text('Home'));
      final unselectedLabel = tester.widget<Text>(find.text('Settings'));

      expect(selectedLabel.style?.fontSize, 12);
      expect(selectedLabel.style?.fontWeight, FontWeight.w700);
      expect(selectedLabel.style?.color, scheme.onSurface);
      expect(unselectedLabel.style?.fontSize, 12);
      expect(unselectedLabel.style?.fontWeight, FontWeight.w400);
      expect(
        unselectedLabel.style?.color,
        scheme.onSurface.withValues(alpha: .4),
      );
      final navigationBar = find.byType(MiuixNavigationBar);
      expect(tester.getSize(navigationBar).height, 64);
      // Source IconAndText places the 12sp paragraph directly after its 8dp
      // inset and 26dp icon. Flutter adds 1dp for the tighter translated CJK
      // line box, keeping the painted baseline aligned with Compose.
      expect(
        tester.getTopLeft(find.text('Home')).dy -
            tester.getTopLeft(navigationBar).dy,
        closeTo(35, .001),
      );
      final divider = find.byKey(const ValueKey('navigation-bar-divider'));
      expect(divider, findsNothing);
      expect(
        find.descendant(
          of: navigationBar,
          matching: find.byKey(const ValueKey('navigation-bar-glass')),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected bottom tabs keep one fill without an outer outline', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return MiuixTheme(
              child: Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  selectedIndex: selected,
                  selectedIndicatorColor: Colors.blue,
                  onDestinationSelected: (index) {
                    updateHost(() => selected = index);
                  },
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    BoxDecoration indicatorDecoration() =>
        tester
                .widget<Container>(
                  find.byKey(
                    const ValueKey('navigation-bar-selection-indicator'),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(indicatorDecoration().border, isNull);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(
      find.byKey(const ValueKey('navigation-bar-selection-indicator')),
      findsOneWidget,
    );
    expect(indicatorDecoration().border, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('regular navigation keeps the source fixed iOS bottom inset', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
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

    // NavigationBar.kt uses a fixed 20dp iOS spacer. SafeArea would copy the
    // device's 34dp inset and make the complete bar 14dp too tall.
    expect(
      tester.getSize(find.byKey(const ValueKey('navigation-bar-bottom-inset'))),
      const Size(390, 20),
    );
    expect(tester.getSize(find.byType(MiuixNavigationBar)).height, 84);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('regular navigation separates and animates caption inset', (
    tester,
  ) async {
    final insets = StreamController<MiuixWindowInsets>.broadcast(sync: true);
    MiuixWindowInsetsObserver.debugEvents = insets.stream;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(bottom: 24);
    addTearDown(() async {
      MiuixWindowInsetsObserver.debugEvents = null;
      debugDefaultTargetPlatformOverride = null;
      await insets.close();
    });
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
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
    await tester.pump();

    double insetHeight() => tester
        .getSize(find.byKey(const ValueKey('navigation-bar-bottom-inset')))
        .height;
    expect(insetHeight(), 24);

    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
    );
    await tester.pump();
    expect(insetHeight(), 24);
    await tester.pump(const Duration(milliseconds: 150));
    expect(insetHeight(), closeTo(39, .001));
    await tester.pump(const Duration(milliseconds: 150));
    expect(insetHeight(), 54);

    // A disappearing desktop/freeform caption bar follows the same full 300ms
    // linear tween instead of snapping the navigation row down immediately.
    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 0),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(insetHeight(), closeTo(39, .001));
    await tester.pump(const Duration(milliseconds: 150));
    expect(insetHeight(), 24);
    MiuixWindowInsetsObserver.debugEvents = null;
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'regular navigation settles a running caption inset when reduced',
    (tester) async {
      final insets = StreamController<MiuixWindowInsets>.broadcast(sync: true);
      MiuixWindowInsetsObserver.debugEvents = insets.stream;
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(bottom: 24);
      var reduceMotion = false;
      late StateSetter updateHost;
      addTearDown(() async {
        MiuixWindowInsetsObserver.debugEvents = null;
        debugDefaultTargetPlatformOverride = null;
        await insets.close();
      });
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

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
                    alignment: Alignment.bottomCenter,
                    child: MiuixNavigationBar(
                      selectedIndex: 0,
                      onDestinationSelected: (_) {},
                      items: const [
                        MiuixNavigationItem(
                          icon: Icon(Icons.home),
                          label: 'Home',
                        ),
                        MiuixNavigationItem(
                          icon: Icon(Icons.settings),
                          label: 'Settings',
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
      await tester.pump();

      double insetHeight() => tester
          .getSize(find.byKey(const ValueKey('navigation-bar-bottom-inset')))
          .height;
      insets.add(
        const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(insetHeight(), closeTo(39, .001));

      // Switching the inherited preference during the live tween must publish
      // the native endpoint immediately instead of retaining the halfway frame.
      updateHost(() => reduceMotion = true);
      await tester.pump();
      expect(insetHeight(), 54);
      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.descendant(
                of: find.byKey(
                  const ValueKey('navigation-bar-caption-inset-animation'),
                ),
                matching: find.byType(TweenAnimationBuilder<double>),
              ),
            )
            .duration,
        Duration.zero,
      );
      debugDefaultTargetPlatformOverride = null;
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation bar exposes all four source display modes', (
    tester,
  ) async {
    var mode = MiuixNavigationBarDisplayMode.iconOnly;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode: mode,
                  selectedIndex: 0,
                  onDestinationSelected: (_) {},
                  items: const [
                    MiuixNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      label: 'Home',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings_outlined),
                      label: 'Settings',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(MiuixNavigationBar),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );
    updateHost(() => mode = MiuixNavigationBarDisplayMode.textOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    updateHost(() => mode = MiuixNavigationBarDisplayMode.iconAndText);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    updateHost(
      () => mode = MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
    );
    await tester.pumpAndSettle();
    final selectedOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Home'), matching: find.byType(Opacity)),
    );
    final unselectedOpacity = tester.widget<Opacity>(
      find.ancestor(of: find.text('Settings'), matching: find.byType(Opacity)),
    );
    expect(selectedOpacity.opacity, 1);
    expect(unselectedOpacity.opacity, 0);
    expect(tester.takeException(), isNull);
  });
}
