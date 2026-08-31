part of '../miuix_flutter_test.dart';

final class _TestNavKey implements MiuixNavKey {
  const _TestNavKey(this.name);

  final String name;

  @override
  bool operator ==(Object other) => other is _TestNavKey && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

class _NavCounterPage extends StatefulWidget {
  const _NavCounterPage({required this.label});

  final String label;

  @override
  State<_NavCounterPage> createState() => _NavCounterPageState();
}

class _NavCounterPageState extends State<_NavCounterPage> {
  var count = 0;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: widget.label == 'root' ? Colors.white : Colors.blue,
    child: Center(
      child: TextButton(
        onPressed: () => setState(() => count += 1),
        child: Text('${widget.label}:$count'),
      ),
    ),
  );
}

void _registerNavigationInputTests() {
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

  testWidgets(
    'selected-label navigation animates only source position and alpha',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      Text homeLabel() => tester.widget<Text>(find.text('Home'));
      Text settingsLabel() => tester.widget<Text>(find.text('Settings'));
      Opacity labelOpacity(String label) => tester.widget<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      );
      final navigationBar = find.byType(MiuixNavigationBar);
      double labelTop(String label) =>
          tester.getTopLeft(find.text(label)).dy -
          tester.getTopLeft(navigationBar).dy;

      // Source tint and weight change with selected state immediately; only the
      // selected-label offset and alpha use the 300ms FastOutSlowIn tween. The
      // paragraph follows the animated icon bottom instead of staying pinned
      // to the row bottom.
      expect(homeLabel().style?.fontWeight, FontWeight.w400);
      expect(settingsLabel().style?.fontWeight, FontWeight.w700);
      expect(labelOpacity('Home').opacity, 1);
      expect(labelOpacity('Settings').opacity, 0);
      expect(labelTop('Home'), closeTo(35, .001));
      expect(labelTop('Settings'), closeTo(46, .001));

      await tester.pump(const Duration(milliseconds: 150));
      final midpoint = Curves.fastOutSlowIn.transform(.5);
      expect(labelOpacity('Home').opacity, closeTo(1 - midpoint, .02));
      expect(labelOpacity('Settings').opacity, closeTo(midpoint, .02));
      expect(labelTop('Home'), closeTo(46 - 11 * (1 - midpoint), .02));
      expect(labelTop('Settings'), closeTo(46 - 11 * midpoint, .02));
      await tester.pump(const Duration(milliseconds: 150));
      expect(labelOpacity('Home').opacity, 0);
      expect(labelOpacity('Settings').opacity, 1);
      expect(labelTop('Home'), closeTo(46, .001));
      expect(labelTop('Settings'), closeTo(35, .001));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selected-label navigation restarts the full source tween when reversed',
    (tester) async {
      var selected = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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
              ),
            ),
          ),
        ),
      );

      Opacity labelOpacity(String label) => tester.widget<Opacity>(
        find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
      );

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final firstLeg = Curves.fastOutSlowIn.transform(1 / 3);
      expect(labelOpacity('Home').opacity, closeTo(1 - firstLeg, .02));
      expect(labelOpacity('Settings').opacity, closeTo(firstLeg, .02));

      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      final reverseMidpoint = Curves.fastOutSlowIn.transform(.5);
      final expectedHome = (1 - firstLeg) + firstLeg * reverseMidpoint;
      final expectedSettings = firstLeg * (1 - reverseMidpoint);

      // Compose's tween restarts its complete 300ms clock from the sampled
      // value whenever animateDpAsState receives another target. Flutter's
      // default AnimationController.animateTo duration is proportional to the
      // remaining distance, which would already finish this reversal at 150ms.
      expect(labelOpacity('Home').opacity, closeTo(expectedHome, .02));
      expect(labelOpacity('Settings').opacity, closeTo(expectedSettings, .02));
      expect(labelOpacity('Home').opacity, lessThan(.99));
      expect(labelOpacity('Settings').opacity, greaterThan(.01));

      await tester.pump(const Duration(milliseconds: 150));
      expect(labelOpacity('Home').opacity, 1);
      expect(labelOpacity('Settings').opacity, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('selected-label navigation snaps with reduced motion', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) => Scaffold(
                bottomNavigationBar: MiuixNavigationBar(
                  displayMode:
                      MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
                  selectedIndex: selected,
                  onDestinationSelected: (index) {
                    setState(() => selected = index);
                  },
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
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    Opacity labelOpacity(String label) => tester.widget<Opacity>(
      find.ancestor(of: find.text(label), matching: find.byType(Opacity)),
    );
    expect(labelOpacity('Home').opacity, 0);
    expect(labelOpacity('Settings').opacity, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation exposes all three source display modes', (
    tester,
  ) async {
    var mode = MiuixFloatingNavigationBarDisplayMode.iconAndText;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  displayMode: mode,
                  selectedIndex: 0,
                  onSelected: (_) {},
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
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsNWidgets(2));
    final iconAndTextTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.home_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    expect(iconAndTextTheme.data.size, 24);
    expect(
      tester.getSize(
        find
            .byKey(const ValueKey('floating-navigation-vertical-content'))
            .first,
      ),
      const Size(96, 43),
    );
    expect(
      tester
          .getSize(
            find
                .byKey(const ValueKey('floating-navigation-content-spacing'))
                .first,
          )
          .height,
      5,
    );
    final combinedIconRect = tester.getRect(find.byIcon(Icons.home_outlined));
    final combinedLabelRect = tester.getRect(find.text('Home').last);
    expect(
      combinedLabelRect.top,
      greaterThanOrEqualTo(combinedIconRect.bottom),
    );
    expect(combinedLabelRect.center.dx, closeTo(combinedIconRect.center.dx, 1));
    Size itemSize() => tester.getSize(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    Size indicatorSize() => tester.getSize(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    expect(itemSize(), const Size(104, 52));
    expect(indicatorSize(), const Size(100, 52));
    expect(
      find.descendant(
        of: find.byType(MiuixFloatingNavigationBar),
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );

    updateHost(() => mode = MiuixFloatingNavigationBarDisplayMode.textOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNWidgets(2));
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(itemSize(), const Size(104, 52));
    expect(indicatorSize(), const Size(100, 52));

    updateHost(() => mode = MiuixFloatingNavigationBarDisplayMode.iconOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(itemSize(), const Size(104, 52));
    expect(indicatorSize(), const Size(100, 52));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation bars honor the source item enabled switch', (
    tester,
  ) async {
    var selected = -1;
    const items = [
      MiuixNavigationItem(
        icon: Icon(Icons.block),
        label: 'Disabled',
        enabled: false,
      ),
      MiuixNavigationItem(icon: Icon(Icons.check), label: 'Enabled'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixNavigationBar(
              items: items,
              selectedIndex: 1,
              onDestinationSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Disabled'));
    await tester.pump();
    expect(selected, -1);
    await tester.tap(find.text('Enabled'));
    await tester.pump();
    expect(selected, 1);

    selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              items: items,
              selectedIndex: 1,
              displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
              onSelected: (index) => selected = index,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-0')));
    await tester.pump();
    expect(selected, -1);
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-1')));
    await tester.pump();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation bar uses near-full HyperOS 4 selection', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                MiuixNavigationItem(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets),
                  label: 'Components',
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune),
                  label: 'Settings',
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.image_outlined),
                  label: 'Color',
                ),
                MiuixNavigationItem(icon: Icon(Icons.sort), label: 'Dropdown'),
                MiuixNavigationItem(
                  icon: Icon(Icons.edit_outlined),
                  label: 'Icon',
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final semantic = MiuixSemanticColors.of(
      tester.element(find.byType(MiuixFloatingNavigationBar)),
    );
    final selectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.widgets),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    final unselectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.tune_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 24);
    final unselectedRect = tester.getRect(find.byIcon(Icons.tune_outlined));
    final selectedRect = tester.getRect(find.byIcon(Icons.widgets));
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    final surface = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('floating-navigation-glass')),
    );

    expect(selectedIconTheme.data.size, 24);
    expect(selectedIconTheme.data.color, semantic['onSurfaceContainer']);
    expect(
      unselectedIconTheme.data.color,
      semantic['onSurfaceContainer'].withValues(alpha: .4),
    );
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsOneWidget,
    );
    expect(surface.radius, 29);
    expect(surface.blur, 28);
    expect(surface.opacity, .52);
    expect(
      find.byKey(const ValueKey('floating-navigation-shadow')),
      findsOneWidget,
    );
    expect(MiuixFloatingNavigationBar.sourceShadowRadius, 10);
    expect(MiuixFloatingNavigationBar.sourceShadowOpacity, .2);
    expect(unselectedRect.left - selectedRect.right, closeTo(44, 1));
    // Five touching 68dp equal items and two 6dp capsule insets fit a 360dp
    // phone without allowing an English label to enlarge one destination.
    // The selected 64x52 material leaves only three dp above and below it,
    // while the semantic destination and 58dp glass surface remain separate.
    expect(surfaceRect.size, const Size(352, 58));
    final indicatorRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    final selectedContentRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-vertical-content')).first,
    );
    expect(indicatorRect.size, const Size(64, 52));
    expect(indicatorRect.width / indicatorRect.height, closeTo(64 / 52, .001));
    expect(indicatorRect.top - surfaceRect.top, closeTo(3, .001));
    expect(surfaceRect.bottom - indicatorRect.bottom, closeTo(3, .001));
    final indicatorBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byKey(
          const ValueKey('floating-navigation-selection-indicator'),
        ),
        matching: find.byType(DecoratedBox),
      ),
    );
    final indicatorShape =
        (indicatorBox.decoration as ShapeDecoration).shape
            as MiuixSquircleBorder;
    expect(indicatorShape.side, BorderSide.none);
    // A 3dp inset from a 29dp outer radius keeps both capsule ends concentric.
    expect(
      indicatorShape.borderRadius.resolve(TextDirection.ltr).topLeft.x,
      26,
    );
    expect(indicatorRect.center.dy, closeTo(surfaceRect.center.dy, .001));
    expect(selectedContentRect.height, 43);
    expect(
      selectedContentRect.center.dy,
      closeTo(indicatorRect.center.dy, .001),
    );
    expect(selectedContentRect.top, greaterThan(indicatorRect.top));
    expect(selectedContentRect.bottom, lessThan(indicatorRect.bottom));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation selection surface moves continuously', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: selected,
                  onSelected: (value) => updateHost(() => selected = value),
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
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
    await tester.pumpAndSettle();

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final startCenter = tester.getCenter(indicator);
    final indicatorRect = tester.getRect(indicator);
    final firstItemRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    expect(firstItemRect.size, const Size(88, 52));
    expect(indicatorRect.size, const Size(84, 52));
    expect(indicatorRect.width / indicatorRect.height, closeTo(84 / 52, .001));
    final destinationCenter = tester.getCenter(
      find.byKey(const ValueKey('floating-navigation-item-2')),
    );
    expect(startCenter.dx, lessThan(destinationCenter.dx));

    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final midpoint = tester.getCenter(indicator).dx;
    expect(midpoint, greaterThan(startCenter.dx));
    expect(midpoint, lessThan(destinationCenter.dx));
    await tester.pumpAndSettle();
    expect(tester.getCenter(indicator).dx, closeTo(destinationCenter.dx, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation drag shrinks and commits the selector', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: selected,
                  onSelected: (value) => updateHost(() => selected = value),
                  items: const <MiuixNavigationItem>[
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                    MiuixNavigationItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings),
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

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final firstItem = find.byKey(const ValueKey('floating-navigation-item-0'));
    final secondItem = find.byKey(const ValueKey('floating-navigation-item-1'));
    expect(tester.getSize(indicator), const Size(84, 52));

    final gesture = await tester.startGesture(tester.getCenter(firstItem));
    await gesture.moveBy(const Offset(88, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    // The direct-manipulation slider is inset another two dp on every edge.
    expect(tester.getSize(indicator), const Size(80, 48));
    expect(
      tester.getCenter(indicator).dx,
      closeTo(tester.getCenter(secondItem).dx, .01),
    );
    expect(
      selected,
      0,
      reason: 'dragging does not switch the page mid-gesture',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.getSize(indicator), const Size(84, 52));
    expect(
      tester.getCenter(indicator).dx,
      closeTo(tester.getCenter(secondItem).dx, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation survives items clearing during a drag', (
    tester,
  ) async {
    var items = const <MiuixNavigationItem>[
      MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
      MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: MiuixFloatingNavigationBar(
                  selectedIndex: 2,
                  onSelected: (_) {},
                  items: items,
                ),
              );
            },
          ),
        ),
      ),
    );

    final first = find.byKey(const ValueKey('floating-navigation-item-0'));
    final drag = await tester.startGesture(tester.getCenter(first));
    await drag.moveBy(const Offset(32, 0));
    await tester.pump();
    updateHost(() => items = const <MiuixNavigationItem>[]);
    await tester.pump();
    await drag.up();
    await tester.pump();
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsNothing,
    );

    updateHost(
      () => items = const <MiuixNavigationItem>[
        MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      ],
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation drag follows logical direction in RTL', (
    tester,
  ) async {
    var selected = 1;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Center(
                  child: MiuixFloatingNavigationBar(
                    selectedIndex: selected,
                    onSelected: (value) => updateHost(() => selected = value),
                    items: const <MiuixNavigationItem>[
                      MiuixNavigationItem(icon: Icon(Icons.home), label: '主页'),
                      MiuixNavigationItem(
                        icon: Icon(Icons.search),
                        label: '搜索',
                      ),
                      MiuixNavigationItem(
                        icon: Icon(Icons.settings),
                        label: '设置',
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    final secondItem = find.byKey(const ValueKey('floating-navigation-item-1'));
    final gesture = await tester.startGesture(tester.getCenter(secondItem));
    // Physical movement to the right selects the preceding logical RTL item.
    await gesture.moveBy(const Offset(88, 0));
    await tester.pump(const Duration(milliseconds: 140));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation near-full selector honors RTL and motion', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return Center(
                    child: MiuixFloatingNavigationBar(
                      selectedIndex: selected,
                      onSelected: (value) => updateHost(() => selected = value),
                      items: const <MiuixNavigationItem>[
                        MiuixNavigationItem(
                          icon: Icon(Icons.home),
                          label: '主页',
                        ),
                        MiuixNavigationItem(
                          icon: Icon(Icons.search),
                          label: '搜索',
                        ),
                        MiuixNavigationItem(
                          icon: Icon(Icons.settings),
                          label: '设置',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = find.byKey(
      const ValueKey('floating-navigation-selection-indicator'),
    );
    final dragSizeAnimation = tester.widget<TweenAnimationBuilder<double>>(
      find.byKey(const ValueKey('floating-navigation-drag-size-animation')),
    );
    expect(dragSizeAnimation.duration, Duration.zero);
    expect(
      tester.getCenter(indicator).dx,
      closeTo(
        tester
            .getCenter(find.byKey(const ValueKey('floating-navigation-item-0')))
            .dx,
        .001,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-2')));
    await tester.pump();
    expect(
      tester.getCenter(indicator).dx,
      closeTo(
        tester
            .getCenter(find.byKey(const ValueKey('floating-navigation-item-2')))
            .dx,
        .001,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation exposes independent geometry overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              itemWidth: 90,
              itemHeight: 50,
              selectionHeight: 38,
              selectionHorizontalInset: 7,
              items: const <MiuixNavigationItem>[
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

    final item = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    final indicator = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-selection-indicator')),
    );
    expect(item.size, const Size(90, 50));
    expect(indicator.size, const Size(76, 38));
    expect(indicator.center, item.center);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation badge bounds clamp top and logical end in RTL', (
    tester,
  ) async {
    Future<void> pumpBar(TextDirection direction) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Directionality(
              textDirection: direction,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  key: const ValueKey('bounded-regular-bar'),
                  width: 180,
                  height: 64,
                  child: MiuixNavigationBar(
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    showDivider: false,
                    defaultWindowInsetsPadding: false,
                    items: const [
                      MiuixNavigationItem(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                        badge: SizedBox(
                          key: ValueKey('bounded-regular-badge'),
                          width: 120,
                          height: 48,
                        ),
                      ),
                      MiuixNavigationItem(
                        icon: Icon(Icons.settings_outlined),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    await pumpBar(TextDirection.ltr);
    var host = tester.getRect(
      find.byKey(const ValueKey('bounded-regular-bar')),
    );
    var badge = tester.getRect(
      find.byKey(const ValueKey('bounded-regular-badge')),
    );
    expect(badge.top, closeTo(host.top, .001));
    expect(badge.right, closeTo(host.left + host.width / 2, .001));

    await pumpBar(TextDirection.rtl);
    host = tester.getRect(find.byKey(const ValueKey('bounded-regular-bar')));
    badge = tester.getRect(find.byKey(const ValueKey('bounded-regular-badge')));
    // The first logical destination occupies the physical right half in RTL;
    // its logical end is therefore the half-width boundary on the left.
    expect(badge.top, closeTo(host.top, .001));
    expect(badge.left, closeTo(host.left + host.width / 2, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation clamps an oversized source badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              defaultWindowInsetsPadding: false,
              items: const [
                MiuixNavigationItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                  badge: SizedBox(
                    key: ValueKey('bounded-floating-badge'),
                    width: 120,
                    height: 48,
                  ),
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final item = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-item-0')),
    );
    final badge = tester.getRect(
      find.byKey(const ValueKey('bounded-floating-badge')),
    );
    // Horizontal HyperOS content may keep a large badge slightly inside the
    // item, but it must never escape above or beyond the logical-end edge.
    expect(badge.top, greaterThanOrEqualTo(item.top));
    expect(badge.right, closeTo(item.right, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic and expandable rails clamp oversized source badges', (
    tester,
  ) async {
    Widget rail({MiuixNavigationRailState? state, required String badgeKey}) {
      return MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 400,
              child: MiuixNavigationRail.sourceItems(
                state: state,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                showDivider: false,
                defaultWindowInsetsPadding: false,
                items: [
                  MiuixNavigationItem(
                    icon: const Icon(Icons.home_outlined),
                    label: 'Home',
                    badge: SizedBox(
                      key: ValueKey(badgeKey),
                      width: 120,
                      height: 48,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(rail(badgeKey: 'bounded-classic-rail-badge'));
    await tester.pump();
    var item = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-item-0')),
    );
    var badge = tester.getRect(
      find.byKey(const ValueKey('bounded-classic-rail-badge')),
    );
    expect(badge.top, closeTo(item.top, .001));
    expect(badge.right, closeTo(item.right, .001));

    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);
    await tester.pumpWidget(
      rail(state: state, badgeKey: 'bounded-expandable-rail-badge'),
    );
    await tester.pump();
    item = tester.getRect(find.byKey(const ValueKey('navigation-rail-item-0')));
    badge = tester.getRect(
      find.byKey(const ValueKey('bounded-expandable-rail-badge')),
    );
    expect(badge.top, closeTo(item.top, .001));
    expect(badge.right, closeTo(item.right, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating navigation evenly divides Chinese and English destinations',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
                displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home),
                    label: '主页',
                    layoutLabel: 'Home',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings),
                    label: '设置',
                    layoutLabel: 'Settings',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.image),
                    label: '颜色',
                    layoutLabel: 'Color',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.sort),
                    label: '下拉菜单',
                    layoutLabel: 'Dropdown',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.edit),
                    label: '图标',
                    layoutLabel: 'Icon',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final homeLabel = tester.getRect(find.text('主页'));
      final homeLayoutLabel = tester.getRect(find.text('Home'));
      final settingsLabel = tester.getRect(find.text('设置'));
      final settingsLayoutLabel = tester.getRect(find.text('Settings'));
      final surface = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );

      expect(homeLayoutLabel.width, greaterThan(homeLabel.width));
      expect(settingsLayoutLabel.width, greaterThan(settingsLabel.width));
      expect(homeLabel.center.dx, closeTo(homeLayoutLabel.center.dx, .01));
      expect(
        settingsLabel.center.dx,
        closeTo(settingsLayoutLabel.center.dx, .01),
      );
      final itemRects = [
        for (var index = 0; index < 5; index++)
          tester.getRect(
            find.byKey(ValueKey('floating-navigation-item-$index')),
          ),
      ];
      final equalWidth = itemRects.first.width;
      expect(equalWidth, greaterThanOrEqualTo(68));
      expect(
        itemRects.map((rect) => rect.width),
        everyElement(closeTo(equalWidth, .001)),
      );
      expect(itemRects.map((rect) => rect.height).toSet(), {52.0});
      for (var index = 1; index < itemRects.length; index++) {
        expect(
          itemRects[index].left - itemRects[index - 1].right,
          closeTo(0, .001),
        );
      }
      expect(surface.width, closeTo(equalWidth * 5 + 12, .001));
      expect(surface.height, 58);

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
                displayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
                items: const [
                  MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                  MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Icons'),
                  MiuixNavigationItem(icon: Icon(Icons.image), label: 'Colors'),
                  MiuixNavigationItem(
                    icon: Icon(Icons.sort),
                    label: 'Dropdown',
                  ),
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
      final englishItemRects = [
        for (var index = 0; index < 5; index++)
          tester.getRect(
            find.byKey(ValueKey('floating-navigation-item-$index')),
          ),
      ];
      final englishEqualWidth = englishItemRects.first.width;
      expect(englishEqualWidth, greaterThanOrEqualTo(68));
      expect(
        englishItemRects.map((rect) => rect.width),
        everyElement(closeTo(englishEqualWidth, .001)),
      );
      expect(englishItemRects.map((rect) => rect.height).toSet(), {52.0});
      expect(
        tester.getRect(find.text('Dropdown').last).width,
        lessThanOrEqualTo(englishItemRects.first.width),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('floating navigation bar keeps scaffold body visible', (
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
            topBar: const MiuixTopAppBar(title: 'Settings'),
            body: const ColoredBox(
              key: ValueKey('floating-navigation-body'),
              color: Colors.white,
              child: Center(child: Text('Body remains visible')),
            ),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bodySize = tester.getSize(
      find.byKey(const ValueKey('floating-navigation-body')),
    );
    final barRect = tester.getRect(find.byType(MiuixFloatingNavigationBar));
    final iconRect = tester.getRect(find.byIcon(Icons.home));

    expect(find.text('Body remains visible'), findsOneWidget);
    final bodyRect = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-body')),
    );
    expect(bodySize.height, greaterThan(750));
    expect(bodyRect.bottom, 844);
    expect(barRect.height, 84);
    expect(barRect.bottom, 844);
    expect(bodyRect.bottom, greaterThan(barRect.top));
    expect(iconRect.center.dy, greaterThan(760));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation reserves the source upper shadow paint', (
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
            body: const ColoredBox(color: Colors.white),
            bottomBar: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final shadowAllowance = tester
        .widgetList<Padding>(
          find.descendant(
            of: find.byType(MiuixFloatingNavigationBar),
            matching: find.byType(Padding),
          ),
        )
        .where((padding) => padding.padding == const EdgeInsets.only(top: 10));

    // Floating bars are painted in the full-window overlay rather than the
    // clipping Scaffold slot. The transparent 10dp band gives the zero-offset
    // source halo room above the capsule without changing its keyed height.
    expect(scaffold.bottomNavigationBar, isNull);
    expect(shadowAllowance, hasLength(1));
    expect(
      tester.getSize(find.byKey(const ValueKey('floating-navigation-surface'))),
      const Size(220, 58),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation keeps the Android gesture-bar gap', (
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

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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

    final navigation = tester.getRect(find.byType(MiuixFloatingNavigationBar));
    final pill = tester.getRect(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    debugDefaultTargetPlatformOverride = null;
    expect(navigation.bottom, 600);
    expect(navigation.bottom - pill.bottom, 40);
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation animates caption above the gesture gap', (
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
            child: MiuixFloatingNavigationBar(
              selectedIndex: 0,
              onSelected: (_) {},
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

    double capsuleBottomGap() {
      final navigation = tester.getRect(
        find.byType(MiuixFloatingNavigationBar),
      );
      final capsule = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );
      return navigation.bottom - capsule.bottom;
    }

    expect(capsuleBottomGap(), 40);
    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(capsuleBottomGap(), closeTo(55, .001));
    await tester.pump(const Duration(milliseconds: 150));
    expect(capsuleBottomGap(), 70);
    MiuixWindowInsetsObserver.debugEvents = null;
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation caption inset snaps with reduced motion', (
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
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 24),
            viewPadding: EdgeInsets.only(bottom: 24),
            disableAnimations: true,
          ),
          child: MiuixTheme(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MiuixFloatingNavigationBar(
                selectedIndex: 0,
                onSelected: (_) {},
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
      ),
    );
    await tester.pump();

    double capsuleBottomGap() {
      final navigation = tester.getRect(
        find.byType(MiuixFloatingNavigationBar),
      );
      final capsule = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );
      return navigation.bottom - capsule.bottom;
    }

    expect(capsuleBottomGap(), 40);
    insets.add(
      const MiuixWindowInsets(navigationBarBottom: 24, captionBarBottom: 30),
    );
    await tester.pump();
    expect(capsuleBottomGap(), 70);
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find
                .descendant(
                  of: find.byKey(
                    const ValueKey(
                      'floating-navigation-caption-inset-animation',
                    ),
                  ),
                  matching: find.byType(TweenAnimationBuilder<double>),
                )
                .first,
          )
          .duration,
      Duration.zero,
    );
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid navigation tolerates asynchronous empty items', (
    tester,
  ) async {
    var items = const <MiuixNavigationItem>[
      MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
      MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
      MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Settings'),
    ];
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MiuixIosLiquidGlassNavigationBar(
                items: items,
                selectedIndex: 99,
                onDestinationSelected: (_) {},
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panel = find.byKey(const ValueKey('ios-liquid-panel'));
    final pointer = await tester.startGesture(tester.getCenter(panel));
    await tester.pump();
    updateHost(() => items = const <MiuixNavigationItem>[]);
    await tester.pump();
    expect(panel, findsNothing);
    await pointer.up();
    await tester.pump();

    updateHost(
      () => items = const <MiuixNavigationItem>[
        MiuixNavigationItem(icon: Icon(Icons.home), label: 'Only'),
      ],
    );
    await tester.pumpAndSettle();
    expect(panel, findsOneWidget);
    expect(find.byKey(const ValueKey('ios-liquid-tab-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-like navigation keeps liquid source metrics and taps', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            extendBody: true,
            body: const ColoredBox(color: Colors.white),
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    final indicator = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-indicator')),
    );
    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('ios-liquid-surface')),
    );
    expect(panel, const Rect.fromLTWH(24, 744, 342, 64));
    expect(indicator.left, closeTo(28, .01));
    expect(indicator.top, 748);
    expect(indicator.width, closeTo(66.8, .01));
    expect(indicator.height, 56);
    // Upstream draws a 40% surface-container tint into its refracting panel.
    // The global five-level setting modulates that authored opacity.
    expect(
      surface.color.a,
      closeTo(MiuixGlassIntensity.intense.resolveOpacity(.4), .001),
    );
    // Host text themes must not inject underline/overline decoration into the
    // duplicated normal and selector rows. Release screenshots previously
    // exposed those inherited baselines as bright double rules under labels.
    for (final label in tester.widgetList<Text>(find.text('Home'))) {
      expect(label.style?.decoration, TextDecoration.none);
      expect(label.style?.decorationColor, Colors.transparent);
    }
    expect(
      find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-panel-source-specular')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsNWidgets(2),
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsOneWidget,
    );
    // Selected color now belongs to the stationary destination row. The lens
    // no longer carries a second translated copy that can reveal two clipped
    // labels while travelling between adjacent destinations.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Color'), findsOneWidget);

    // A click shrinks the current selector on down but does not jump to the
    // touched destination before the gesture has actually been committed.
    final target = find.byKey(const ValueKey('ios-liquid-tab-2'));
    final tap = await tester.startGesture(tester.getCenter(target));
    // Start the spring clock first; the next frame then has a deterministic
    // nonzero elapsed duration instead of being AnimationController's epoch.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(selected, -1);
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28, .01),
    );
    await tap.up();
    await tester.pump();
    expect(selected, 2);
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28 + 2 * 66.8, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS-like navigation supports a centered split action group', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;
    var actionTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(),
          child: Scaffold(
            extendBody: true,
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.history), label: 'Recent'),
                MiuixNavigationItem(icon: Icon(Icons.folder), label: 'Browse'),
              ],
              trailingAction: MiuixIconButton(
                key: const ValueKey('split-search'),
                onPressed: () => actionTaps++,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-panel'))),
      const Rect.fromLTWH(77, 752, 168, 56),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-trailing-action'))),
      const Rect.fromLTWH(257, 752, 56, 56),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))),
      const Rect.fromLTWH(81, 756, 80, 48),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ios-liquid-trailing-action')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('split-search')));
    await tester.pumpAndSettle();
    expect(actionTaps, 1);
    expect(selected, -1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HyperOS liquid selector paints one travelling selection layer', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Set'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    expect(
      find.descendant(
        of: indicator,
        matching: find.byKey(
          const ValueKey('ios-liquid-indicator-single-fill'),
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-specular')),
      findsNothing,
    );
    // The upstream panel BloomStroke concentrates its secondary light along
    // the capsule's lower edge. HyperOS omits it so the bar cannot acquire a
    // bright horizontal seam over light content.
    expect(
      find.byKey(const ValueKey('ios-liquid-panel-source-specular')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-inner-depth')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    final singleFill = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
    );
    // Level five may clear the shared panel tint, but the selected destination
    // retains a stable light-mode contrast wash instead of fading to 2.2%.
    expect(singleFill.color.a, closeTo(.08, .001));

    final panelFilter = tester.widget(
      find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
    );
    void expectStableHyperOsGeometry() {
      final panelScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-panel-press-scale')),
      );
      final indicatorScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      final selectedItemScale = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-selected-item-scale-0')),
      );
      expect(panelScale.transform.storage[0], closeTo(1, 1e-9));
      expect(panelScale.transform.storage[5], closeTo(1, 1e-9));
      expect(indicatorScale.transform.storage[0], closeTo(1, 1e-9));
      expect(indicatorScale.transform.storage[5], closeTo(1, 1e-9));
      expect(selectedItemScale.transform.storage[0], closeTo(1, 1e-9));
      expect(selectedItemScale.transform.storage[5], closeTo(1, 1e-9));
      expect(
        tester
            .widget<ColoredBox>(
              find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
            )
            .color,
        singleFill.color,
      );
    }

    expectStableHyperOsGeometry();

    // Pressing and dragging contract the same travelling surface. They must
    // not insert a second edge light or inner-shadow ellipse at interaction
    // time, which was the hardware-only doubled selector appearance.
    final drag = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expectStableHyperOsGeometry();
    expect(
      identical(
        tester.widget(find.byKey(const ValueKey('ios-liquid-backdrop-filter'))),
        panelFilter,
      ),
      isTrue,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-specular')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-source-inner-depth')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsNothing,
    );
    await drag.moveBy(const Offset(72, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-single-fill')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    await drag.up();
    await tester.pumpAndSettle();
    expectStableHyperOsGeometry();
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid selector tracks drag directly and snaps once', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    // A tap retains a short settle spring and reaches the exact destination.
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
    const tabWidth = 66.8;
    await tester.pumpAndSettle();
    expect(
      tester.getRect(find.byKey(const ValueKey('ios-liquid-indicator'))).left,
      closeTo(28 + 2 * tabWidth, .01),
    );
    expect(selected, 2);

    // The HyperOS 4 travelling thumb contracts inside the resting tab-wide,
    // 56dp-high lens and retains only bounded velocity deformation.
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final panelShadow = find.byKey(const ValueKey('ios-liquid-panel-shadow'));
    final restingShadowRect = tester.getRect(panelShadow);
    final restingHighlight = tester
        .widgetList<MiuixHighlightOverlay>(
          find.descendant(
            of: indicator,
            matching: find.byType(MiuixHighlightOverlay),
          ),
        )
        .single;
    // Android used to keep a .35-alpha fallback outline at rest. Against the
    // outer capsule edge that rendered as a second concentric ellipse.
    expect(restingHighlight.highlight.alpha, closeTo(0, .001));
    final press = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    var shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    expect(shape.transform.storage[0], inExclusiveRange(.7, 1));
    expect(shape.transform.storage[5], inExclusiveRange(.7, 1));
    await tester.pump(const Duration(milliseconds: 100));
    // Only the glass surface expands. Its drop shadow remains at exactly the
    // resting panel footprint, matching the upstream modifier order.
    expect(tester.getRect(panelShadow), restingShadowRect);
    final panelGlassScale = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-panel-press-scale')),
    );
    expect(panelGlassScale.transform.storage[0], greaterThan(1));
    // Each selected item scales around its own center. Scaling the complete
    // row would shift edge items away from their stationary item underneath.
    final selectedItemScale = find.byKey(
      const ValueKey('ios-liquid-selected-item-scale-2'),
    );
    final selectedForegroundCenter = tester.getCenter(selectedItemScale);
    final stationaryItemCenter = tester.getCenter(
      find.byKey(const ValueKey('ios-liquid-tab-2')),
    );
    expect(selectedForegroundCenter.dx, closeTo(stationaryItemCenter.dx, .001));
    expect(selectedForegroundCenter.dy, closeTo(stationaryItemCenter.dy, .001));
    expect(
      tester.widget<Transform>(selectedItemScale).transform.storage[0],
      greaterThan(1),
    );
    // WidgetTester.getRect reports layout bounds and deliberately excludes a
    // RenderTransform's paint-only scale. Reconstruct the painted vertical
    // bounds from the actual matrix around the centered selection slot.
    shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    final indicatorSlot = tester.getRect(indicator);
    final paintedHeight = indicatorSlot.height * shape.transform.storage[5];
    final paintedTop = indicatorSlot.center.dy - paintedHeight / 2;
    final paintedBottom = indicatorSlot.center.dy + paintedHeight / 2;
    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    expect(paintedHeight, lessThan(56));
    expect(paintedTop, greaterThan(panel.top));
    expect(paintedBottom, lessThan(panel.bottom));
    await press.up();
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(tester.getCenter(indicator));
    final dragStartLeft = tester.getRect(indicator).left;
    await tester.pump();
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(16, 0));
    await tester.pump(const Duration(milliseconds: 16));
    // Pointer samples move the selector one-for-one instead of repeatedly
    // retargeting a lagging spring. Only release performs a spring snap.
    final panelTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
    );
    final panelOffset = panelTransform.transform.storage[12];
    expect(
      tester.getRect(indicator).left,
      closeTo(dragStartLeft + 40 + panelOffset, .01),
    );
    expect(panelTransform.transform.storage[12].abs(), inExclusiveRange(0, 4));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 3);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
          )
          .transform
          .storage[12],
      // The source panel spring uses a .5px visibility threshold; after the
      // rubber-band transfer that permits only a few thousandths of a dp.
      closeTo(0, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid release stays in the slot under the finger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 4,
              onDestinationSelected: (value) => selected = value,
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    const tabWidth = 66.8;
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final gesture = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    // End 20% inside the second slot, as the physical Xiaomi verification did.
    // Its nearest selector center is still index 1; release velocity must not
    // fling the committed destination one extra slot to index 0.
    await gesture.moveBy(const Offset(-3.2 * tabWidth, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(tester.getRect(indicator).left, closeTo(28 + tabWidth, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid position frames retain both filter subtrees', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.search), label: 'Search'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final panelLens = find.byKey(const ValueKey('ios-liquid-backdrop-filter'));
    final indicatorLens = find.byKey(
      const ValueKey('ios-liquid-indicator-lens-filter'),
    );
    final drag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('ios-liquid-indicator'))),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    final panelLensWidget = tester.widget(panelLens);
    final indicatorLensWidget = tester.widget(indicatorLens);

    await drag.moveBy(const Offset(28, 0));
    await tester.pump(const Duration(milliseconds: 16));
    expect(identical(tester.widget(panelLens), panelLensWidget), isTrue);
    expect(
      identical(tester.widget(indicatorLens), indicatorLensWidget),
      isTrue,
    );

    await drag.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Android high-DPR liquid lens stays bounded and releases', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: Scaffold(
            bottomNavigationBar: MiuixIosLiquidGlassNavigationBar.source(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              items: const [
                MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
                MiuixNavigationItem(icon: Icon(Icons.image), label: 'Color'),
                MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Text'),
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

    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    expect(tester.getSize(indicator), const Size(83.5, 56));
    final pointer = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    var shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    // The springs settle around a two-dp-per-edge inset. Both dimensions stay
    // below the resting tab-wide lens on a high-density Android host.
    expect(shape.transform.storage[0], inInclusiveRange(.88, .98));
    expect(shape.transform.storage[5], inInclusiveRange(.88, .98));

    await pointer.up();
    await tester.pumpAndSettle();
    shape = tester.widget<Transform>(
      find.byKey(const ValueKey('ios-liquid-indicator-shape')),
    );
    expect(shape.transform.storage[0], closeTo(1, .001));
    expect(shape.transform.storage[5], closeTo(1, .001));
    expect(tester.getSize(indicator), const Size(83.5, 56));
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('iOS liquid selector keeps RTL drag direction and fixed inset', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          // The source ignores iOS MediaQuery navigation padding here and
          // installs its own fixed 20dp optical bottom gap.
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 34)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              bottomNavigationBar: MiuixTheme(
                child: MiuixIosLiquidGlassNavigationBar.source(
                  selectedIndex: 1,
                  onDestinationSelected: (value) => selected = value,
                  items: const [
                    MiuixNavigationItem(icon: Icon(Icons.home), label: 'One'),
                    MiuixNavigationItem(icon: Icon(Icons.search), label: 'Two'),
                    MiuixNavigationItem(icon: Icon(Icons.edit), label: 'Three'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    expect(panel.bottom, 824);

    // In RTL a physical rightward drag moves from logical index one to zero.
    final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
    final gesture = await tester.startGesture(tester.getCenter(indicator));
    await tester.pump();
    // Cross touch slop first, then deliver an accepted drag segment; a single
    // synthetic jump can be consumed entirely by arena resolution.
    await gesture.moveBy(const Offset(24, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(96, 0));
    await tester.pump(const Duration(milliseconds: 40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 0);
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'iOS liquid selector reduced motion snaps but keeps direct drag',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = 0;
      var reduceMotion = false;
      late StateSetter updateHost;

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
                  child: Scaffold(
                    bottomNavigationBar:
                        MiuixIosLiquidGlassNavigationBar.source(
                          selectedIndex: selected,
                          onDestinationSelected: (value) => selected = value,
                          items: const [
                            MiuixNavigationItem(
                              icon: Icon(Icons.home),
                              label: 'Home',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.search),
                              label: 'Search',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.image),
                              label: 'Color',
                            ),
                            MiuixNavigationItem(
                              icon: Icon(Icons.edit),
                              label: 'Text',
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
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-2')));
      final indicator = find.byKey(const ValueKey('ios-liquid-indicator'));
      await tester.pumpAndSettle();
      expect(tester.getRect(indicator).left, closeTo(161.6, .01));

      updateHost(() => reduceMotion = true);
      await tester.pump();
      await tester.pump();
      expect(tester.getRect(indicator).left, closeTo(161.6, .01));
      var shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(1, 1e-9));
      expect(shape.transform.storage[5], closeTo(1, 1e-9));

      final drag = await tester.startGesture(tester.getCenter(indicator));
      await tester.pump();
      shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(52 / 56, 1e-9));
      expect(shape.transform.storage[5], closeTo(52 / 56, 1e-9));
      await drag.moveBy(const Offset(24, 0));
      await tester.pump();
      await drag.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(tester.getRect(indicator).left, greaterThan(210));

      await drag.up();
      await tester.pump();
      expect(selected, 3);
      expect(tester.getRect(indicator).left, closeTo(228.4, .01));
      shape = tester.widget<Transform>(
        find.byKey(const ValueKey('ios-liquid-indicator-shape')),
      );
      expect(shape.transform.storage[0], closeTo(1, 1e-9));
      expect(shape.transform.storage[5], closeTo(1, 1e-9));
      expect(
        tester
            .widget<Transform>(
              find.byKey(const ValueKey('ios-liquid-panel-rubber-band')),
            )
            .transform
            .storage[12],
        closeTo(0, 1e-9),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('intense glass top and bottom bars blur extended page content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            glassIntensity: MiuixGlassIntensity.intense,
          ),
          child: MiuixScaffold(
            topBar: const MiuixTopAppBar(
              title: 'Glass',
              glass: true,
              blurStyle: MiuixTopAppBarBlurStyle.gaussian,
            ),
            bottomBar: MiuixNavigationBar(
              glass: true,
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
            body: ListView(
              key: const ValueKey('glass-bars-body'),
              padding: EdgeInsets.zero,
              children: const [
                ColoredBox(color: Colors.red, child: SizedBox(height: 300)),
                ColoredBox(color: Colors.blue, child: SizedBox(height: 600)),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final topGlass = find.byKey(const ValueKey('top-app-bar-glass'));
    final bottomGlass = find.byKey(const ValueKey('navigation-bar-glass'));
    expect(scaffold.extendBodyBehindAppBar, isTrue);
    expect(scaffold.extendBody, isTrue);
    expect(
      find.descendant(of: topGlass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: bottomGlass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );

    // Level five scales the shared HyperOS 4 28dp/58% recipe. The resulting
    // tint stays visibly translucent rather than turning into a white slab.
    expect(tester.widget<MiuixGlass>(topGlass).blur, 28);
    expect(tester.widget<MiuixGlass>(topGlass).opacity, .58);
    expect(tester.widget<MiuixGlass>(topGlass).showSpecular, isFalse);
    expect(
      tester.widget<MiuixGlass>(topGlass).optics,
      same(MiuixGlassOptics.navigation),
    );
    expect(tester.widget<MiuixGlass>(bottomGlass).blur, 28);
    expect(tester.widget<MiuixGlass>(bottomGlass).opacity, .58);
    expect(
      tester.widget<MiuixGlass>(bottomGlass).optics,
      same(MiuixGlassOptics.navigation),
    );
    final topSurface = tester.widget<DecoratedBox>(
      find.descendant(of: topGlass, matching: find.byType(DecoratedBox)).first,
    );
    final bottomSurface = tester.widget<DecoratedBox>(
      find
          .descendant(of: bottomGlass, matching: find.byType(DecoratedBox))
          .first,
    );
    expect(
      (topSurface.decoration as ShapeDecoration).color!.a,
      closeTo(.0928, .001),
    );
    expect(
      (bottomSurface.decoration as ShapeDecoration).color!.a,
      closeTo(.0928, .001),
    );
    expect(
      find.byKey(const ValueKey('miuix-glass-specular-highlight')),
      findsOneWidget,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('glass-bars-body'))).top,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('top app bar defaults to persistent glass and shaped actions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(),
          child: const Scaffold(
            appBar: MiuixTopAppBar(
              title: 'Browse',
              large: false,
              actions: [Icon(Icons.more_vert)],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final bar = tester.widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar));
    expect(bar.blurStyle, MiuixTopAppBarBlurStyle.gaussian);
    expect(bar.actionStyle, MiuixTopAppBarActionStyle.glass);
    expect(find.byKey(const ValueKey('top-app-bar-glass')), findsOneWidget);
    final actionGroup = find.byKey(const ValueKey('top-app-bar-glass-actions'));
    expect(tester.getSize(actionGroup), const Size(48, 48));
    expect(
      find.descendant(of: actionGroup, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('source floating action button keeps MIUIX surface metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Center(
              child: MiuixFloatingActionButton.source(
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );

    final scheme = Theme.of(
      tester.element(find.byType(MiuixFloatingActionButton)),
    ).colorScheme;
    final shadowBox = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-floating-action-button-surface')),
    );
    final shadowDecoration = shadowBox.decoration as ShapeDecoration;
    final fillBox = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('miuix-floating-action-button-fill')),
    );
    final fillDecoration = fillBox.decoration as ShapeDecoration;
    final iconTheme = tester.widget<IconTheme>(
      find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(IconTheme),
      ),
    );

    expect(
      tester.getSize(find.byType(MiuixFloatingActionButton)),
      const Size(60, 60),
    );
    expect(MiuixFloatingActionButtonDefaults.minWidth, 60);
    expect(MiuixFloatingActionButtonDefaults.minHeight, 60);
    expect(MiuixFloatingActionButtonDefaults.shadowElevation, 4);
    expect(fillDecoration.color, scheme.primary);
    expect(fillDecoration.shape, isA<StadiumBorder>());
    expect((fillDecoration.shape as StadiumBorder).side, BorderSide.none);
    expect(shadowDecoration.color, Colors.transparent);
    expect(shadowDecoration.shape, fillDecoration.shape);
    expect(shadowDecoration.shadows, hasLength(1));
    final shadow = shadowDecoration.shadows!.single;
    expect(shadow.color.a, closeTo(.20, .001));
    expect(shadow.blurRadius, 8);
    expect(shadow.offset, const Offset(0, 2));
    expect(iconTheme.data.color, scheme.onSurface);
    expect(iconTheme.data.size, 24);

    // Surface.kt uses LocalIndication without adding sink motion.
    final pressable = tester.widget<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(MiuixPressable),
      ),
    );
    expect(pressable.feedbackType, MiuixPressFeedbackType.none);
    expect(pressable.showIndication, isTrue);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiuixFloatingActionButton)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final indication = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('miuix-press-indication')),
    );
    expect(indication.opacity.value, inExclusiveRange(0, .10));
    await tester.pumpAndSettle();
    expect(indication.opacity.value, closeTo(.10, .001));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating action button defaults to one shape-aligned HyperOS glass',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: Center(
                child: MiuixFloatingActionButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MiuixFloatingActionButton));
      final scheme = Theme.of(context).colorScheme;
      final tokens = MiuixTheme.of(context).hyperOs4;
      final glassFinder = find.descendant(
        of: find.byType(MiuixFloatingActionButton),
        matching: find.byType(MiuixGlass),
      );
      expect(glassFinder, findsOneWidget);
      final glass = tester.widget<MiuixGlass>(glassFinder);
      expect(glass.blur, tokens.floatingActionButtonBlur);
      expect(glass.opacity, tokens.floatingActionButtonTintOpacity);
      expect(glass.color, scheme.primary);
      expect(glass.shape, isA<StadiumBorder>());
      expect(glass.showSpecular, isTrue);
      expect(
        find.byKey(const ValueKey('miuix-floating-action-button-fill')),
        findsNothing,
      );

      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
          of: find.byType(MiuixFloatingActionButton),
          matching: find.byType(IconTheme),
        ),
      );
      expect(iconTheme.data.color, scheme.onPrimary);
      final shadow = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      expect((shadow.decoration as ShapeDecoration).shape, glass.shape);
      expect(tester.takeException(), isNull);
    },
  );

  test('floating action capsule follows the final shorter dimension', () {
    const capsule = MiuixCapsuleBorder();
    const square = Rect.fromLTWH(0, 0, 60, 60);
    const extended = Rect.fromLTWH(0, 0, 120, 80);
    final squarePath = capsule.getOuterPath(square);
    final extendedPath = capsule.getOuterPath(extended);
    final squareReference = const MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(30)),
    ).getOuterPath(square);
    final extendedReference = const MiuixSquircleBorder(
      borderRadius: BorderRadius.all(Radius.circular(40)),
    ).getOuterPath(extended);

    // Path objects do not define geometric equality. Sampling the complete
    // physical grid verifies that each capsule uses half of its own short edge.
    for (var y = 0.5; y < square.height; y += 1) {
      for (var x = 0.5; x < square.width; x += 1) {
        final point = Offset(x, y);
        expect(squarePath.contains(point), squareReference.contains(point));
      }
    }
    for (var y = 0.5; y < extended.height; y += 1) {
      for (var x = 0.5; x < extended.width; x += 1) {
        final point = Offset(x, y);
        expect(extendedPath.contains(point), extendedReference.contains(point));
      }
    }
  });

  testWidgets('floating action circle ignores the smooth-rounding switch', (
    tester,
  ) async {
    for (final enableSquircle in <bool>[true, false]) {
      final theme = MiuixThemeData.defaults().copyWith(
        enableSquircle: enableSquircle,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: theme,
            child: Center(
              child: MiuixFloatingActionButton.source(
                onPressed: () {},
                child: const SizedBox(width: 96, height: 64),
              ),
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      final shape = (decorated.decoration as ShapeDecoration).shape;
      // Upstream uses CircleShape directly; the global smooth-corner setting
      // must not silently replace it with MIUIX's G2 squircle capsule.
      expect(shape, isA<StadiumBorder>());
      expect(
        tester.getSize(find.byType(MiuixFloatingActionButton)),
        const Size(96, 64),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'floating action button preserves content and accepts negative shadow',
    (tester) async {
      const customShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: MiuixFloatingActionButton.source(
                onPressed: null,
                shape: customShape,
                containerColor: Colors.red,
                contentColor: Colors.cyan,
                // Surface.kt tests only `> 0f`. A negative Dp is therefore a
                // legal no-shadow request, not a constructor error.
                shadowElevation: -4,
                minWidth: 72,
                minHeight: 64,
                child: SizedBox(
                  key: ValueKey('source-fab-content'),
                  width: 96,
                  height: 44,
                ),
              ),
            ),
          ),
        ),
      );

      final decorated = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-fill')),
      );
      final decoration = decorated.decoration as ShapeDecoration;
      final shadowBox = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('miuix-floating-action-button-surface')),
      );
      final shadowDecoration = shadowBox.decoration as ShapeDecoration;
      final iconTheme = tester.widget<IconTheme>(
        find.descendant(
          of: find.byType(MiuixFloatingActionButton),
          matching: find.byType(IconTheme),
        ),
      );
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(MiuixFloatingActionButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      // Compose defaultMinSize supplies only minimum constraints, so content is
      // free to make the source surface wider than the default 60dp.
      expect(
        tester.getSize(find.byType(MiuixFloatingActionButton)),
        const Size(96, 64),
      );
      final surfaceRect = tester.getRect(
        find.byType(MiuixFloatingActionButton),
      );
      final contentRect = tester.getRect(
        find.byKey(const ValueKey('source-fab-content')),
      );
      // Source Box(contentAlignment = Center) centers the shorter content in
      // the independently supplied minimum height.
      expect(contentRect.center, surfaceRect.center);
      expect(contentRect.top - surfaceRect.top, 10);
      expect(decoration.color, Colors.red);
      expect(decoration.shape, customShape);
      expect(shadowDecoration.shadows, anyOf(isNull, isEmpty));
      expect(iconTheme.data.color, Colors.cyan);
      expect(semantics.properties.enabled, isFalse);
      expect(
        find.byKey(const ValueKey('miuix-press-indication')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('floating action button centers a small arbitrary child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: MiuixFloatingActionButton.source(
              onPressed: null,
              child: SizedBox(
                key: ValueKey('small-fab-content'),
                width: 20,
                height: 10,
              ),
            ),
          ),
        ),
      ),
    );

    final surfaceRect = tester.getRect(find.byType(MiuixFloatingActionButton));
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('small-fab-content')),
    );
    expect(surfaceRect.size, const Size.square(60));
    expect(contentRect.size, const Size(20, 10));
    expect(contentRect.center, surfaceRect.center);
    expect(contentRect.topLeft - surfaceRect.topLeft, const Offset(20, 25));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaffold places FAB with MIUIX spacing above bottom bar', (
    tester,
  ) async {
    const fabKey = ValueKey('fab');
    const bottomKey = ValueKey('bottom-bar');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: const SizedBox(key: bottomKey, height: 64),
            floatingActionButton: MiuixFloatingActionButton(
              key: fabKey,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final fabRect = tester.getRect(find.byKey(fabKey));
    final bottomRect = tester.getRect(find.byKey(bottomKey));

    expect(800 - fabRect.right, closeTo(12, 1));
    expect(bottomRect.top - fabRect.bottom, closeTo(12, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('glass bottom bar keeps FAB above its measured source height', (
    tester,
  ) async {
    const density = 2.625;
    const fabKey = ValueKey('glass-fab');
    const bottomKey = ValueKey('glass-bottom-bar');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: MiuixNavigationBar(
              key: bottomKey,
              glass: true,
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
            floatingActionButton: MiuixFloatingActionButton(
              key: fabKey,
              icon: const Icon(Icons.add),
              onPressed: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fabRect = tester.getRect(find.byKey(fabKey));
    final bottomRect = tester.getRect(find.byKey(bottomKey));
    final windowWidth = tester.view.physicalSize.width / density;

    // Scaffold.kt rounds 12dp to 32px before placing the 158px FAB. A glass
    // bar extends the body, so its complete measured height must also be
    // subtracted rather than letting the button paint behind the bar.
    expect(fabRect.width * density, closeTo(158, .01));
    expect(fabRect.height * density, closeTo(158, .01));
    expect((windowWidth - fabRect.right) * density, closeTo(32, .01));
    expect((bottomRect.top - fabRect.bottom) * density, closeTo(32, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaffold keeps snackbar above the measured floating button', (
    tester,
  ) async {
    const fabKey = ValueKey('snackbar-fab');
    const snackbarKey = ValueKey('snackbar-above-fab');
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: SizedBox.expand(),
            bottomBar: SizedBox(height: 64),
            floatingActionButton: SizedBox(key: fabKey, width: 60, height: 60),
            snackbarHost: SizedBox(key: snackbarKey, height: 40),
          ),
        ),
      ),
    );
    // Compose subcomposes both placeables in one pass. The Flutter adapter
    // reads their final transformed rectangles immediately after first layout.
    await tester.pump();
    await tester.pump();

    final fabRect = tester.getRect(find.byKey(fabKey));
    final snackbarRect = tester.getRect(find.byKey(snackbarKey));
    expect(snackbarRect.bottom, closeTo(fabRect.top, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar clears only a bottom-docked floating toolbar', (
    tester,
  ) async {
    const density = 2.625;
    const toolbarKey = ValueKey('snackbar-toolbar');
    const snackbarKey = ValueKey('snackbar-above-toolbar');
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Widget configuredScene(MiuixToolbarPosition position) {
      return MaterialApp(
        home: MiuixTheme(
          child: MiuixScaffold(
            body: const SizedBox.expand(),
            bottomBar: const SizedBox(height: 64),
            floatingToolbarPosition: position,
            floatingToolbar: const SizedBox(
              key: toolbarKey,
              width: 100,
              height: 140,
            ),
            snackbarHost: const SizedBox(key: snackbarKey, height: 40),
          ),
        ),
      );
    }

    await tester.pumpWidget(configuredScene(MiuixToolbarPosition.bottomCenter));
    await tester.pump();
    await tester.pump();

    var toolbarRect = tester.getRect(find.byKey(toolbarKey));
    var snackbarRect = tester.getRect(find.byKey(snackbarKey));
    // FloatingToolbarSpacing is independently rounded: 4dp at 2.625 density
    // is an 11px gap rather than a fractional 10.5px placement.
    expect((toolbarRect.top - snackbarRect.bottom) * density, closeTo(11, .01));

    await tester.pumpWidget(configuredScene(MiuixToolbarPosition.topCenter));
    await tester.pump();
    await tester.pump();
    toolbarRect = tester.getRect(find.byKey(toolbarKey));
    snackbarRect = tester.getRect(find.byKey(snackbarKey));
    final bottomBarRect = tester.getRect(find.byType(MiuixScaffold));
    expect(toolbarRect.bottom, lessThan(snackbarRect.top));
    // A top/center toolbar is not a bottom obstruction. The snackbar keeps
    // the ordinary 64dp bottom-bar anchor instead of jumping above it.
    expect(
      (bottomBarRect.bottom - snackbarRect.bottom) * density,
      closeTo(168, .01),
    );
    expect(tester.takeException(), isNull);
  });

  test('pull refresh defaults match the upstream public constants', () {
    // Compose Color.Gray is #888888, not Material Colors.grey (#9E9E9E).
    expect(MiuixPullToRefreshDefaults.color, const Color(0xFF888888));
    expect(MiuixPullToRefreshDefaults.circleSize, 20);
    expect(MiuixPullToRefreshDefaults.refreshTextStyle.fontSize, 14);
    expect(
      MiuixPullToRefreshDefaults.refreshTextStyle.fontWeight,
      FontWeight.bold,
    );
    expect(
      MiuixPullToRefreshDefaults.refreshTextStyle.color,
      const Color(0xFF888888),
    );
    expect(MiuixPullToRefreshDefaults.refreshTexts, hasLength(4));
  });

  testWidgets('pull refresh uses HyperOS tokens and source stays fixed', (
    tester,
  ) async {
    Widget fixture({required bool source}) => MaterialApp(
      home: MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            pullRefreshIndicatorSize: 28,
            pullRefreshSettleMotion: Duration(milliseconds: 10),
            pullRefreshCompleteMotion: Duration(milliseconds: 333),
            pullRefreshOrbitMotion: Duration(milliseconds: 777),
          ),
        ),
        child: Scaffold(
          body: source
              ? MiuixPullToRefresh.source(
                  isRefreshing: true,
                  onRefresh: () {},
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 800)],
                  ),
                )
              : MiuixPullToRefresh(
                  isRefreshing: true,
                  onRefresh: () {},
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [SizedBox(height: 800)],
                  ),
                ),
        ),
      ),
    );

    List<AnimationController> orbitControllers() => tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .map((builder) => builder.animation)
        .whereType<AnimationController>()
        .toList(growable: false);

    await tester.pumpWidget(fixture(source: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(28),
    );
    expect(
      orbitControllers().map((controller) => controller.duration),
      contains(const Duration(milliseconds: 777)),
    );

    await tester.pumpWidget(fixture(source: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(20),
    );
    expect(
      orbitControllers().map((controller) => controller.duration),
      contains(const Duration(milliseconds: 800)),
    );
  });

  testWidgets('pull refresh normalizes invalid theme geometry and motion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              pullRefreshIndicatorSize: double.nan,
              pullRefreshSettleMotion: Duration(microseconds: -1),
              pullRefreshCompleteMotion: Duration(microseconds: -1),
              pullRefreshOrbitMotion: Duration(microseconds: -1),
            ),
          ),
          child: Scaffold(
            body: MiuixPullToRefresh(
              isRefreshing: true,
              onRefresh: () {},
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const <Widget>[SizedBox(height: 800)],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      tester.getSize(
        find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
      ),
      const Size.square(MiuixPullToRefreshDefaults.circleSize),
    );
    final orbit = tester
        .widgetList<AnimatedBuilder>(
          find.ancestor(
            of: find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
            matching: find.byType(AnimatedBuilder),
          ),
        )
        .map((builder) => builder.animation)
        .whereType<AnimationController>()
        .first;
    expect(orbit.duration, Duration.zero);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'pull refresh exposes configurable trigger and full-range progress',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshState = MiuixPullToRefreshState();
      final listKey = GlobalKey();
      final progressValues = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Scaffold(
              body: MiuixPullToRefresh(
                state: refreshState,
                refreshThreshold: .5,
                onPullProgress: progressValues.add,
                onRefresh: () {},
                child: ListView(
                  key: listKey,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [SizedBox(height: 1000)],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(refreshState.refreshThreshold, .5);
      expect(refreshState.refreshThresholdOffset, closeTo(35, .01));
      expect(refreshState.triggerProgressOffset, closeTo(140, .01));
      expect(progressValues, [0]);

      final context = listKey.currentContext!;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 160,
        pixels: 0,
        viewportDimension: 840,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: -180,
        velocity: 0,
      ).dispatch(context);
      await tester.pump();
      await tester.pump();

      expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
      expect(refreshState.fullDragProgress, closeTo(progressValues.last, .001));
      expect(progressValues.last, greaterThan(.5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pull refresh accepts source-style sync callback and short text list',
    (tester) async {
      tester.view.physicalSize = const Size(390, 840);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final refreshState = MiuixPullToRefreshState();
      final listKey = GlobalKey();
      late StateSetter updateHost;
      var refreshing = false;
      var callbackCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Scaffold(
                  body: MiuixPullToRefresh(
                    state: refreshState,
                    isRefreshing: refreshing,
                    // PullToRefresh.kt accepts () -> Unit and reads missing
                    // labels with getOrElse, including a completely empty list.
                    refreshTexts: const [],
                    onRefresh: () {
                      callbackCount++;
                      setState(() => refreshing = true);
                    },
                    child: ListView(
                      key: listKey,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 1000)],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      final context = listKey.currentContext!;
      final metrics = FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 160,
        pixels: 0,
        viewportDimension: 840,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      );
      OverscrollNotification(
        metrics: metrics,
        context: context,
        overscroll: -90,
        velocity: 0,
      ).dispatch(context);
      ScrollEndNotification(
        metrics: metrics,
        context: context,
      ).dispatch(context);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      expect(callbackCount, 1);
      expect(refreshState.refreshState, MiuixRefreshState.refreshing);
      expect(tester.takeException(), isNull);

      updateHost(() => refreshing = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(refreshState.refreshState, MiuixRefreshState.idle);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pull refresh coalesces a hoisted start during release spring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final refreshState = MiuixPullToRefreshState();
    final listKey = GlobalKey();
    bool? isRefreshing;
    var callbackCount = 0;
    late StateSetter rebuildHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuildHost = setState;
              return Scaffold(
                body: MiuixPullToRefresh(
                  state: refreshState,
                  isRefreshing: isRefreshing,
                  onRefresh: () => callbackCount++,
                  child: ListView(
                    key: listKey,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const <Widget>[SizedBox(height: 1000)],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -220,
      velocity: 0,
    ).dispatch(context);
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);

    rebuildHost(() => isRefreshing = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    expect(callbackCount, 1);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh ignores null scroll deltas safely', (tester) async {
    final dispatchKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              onRefresh: () async {},
              child: Builder(
                key: dispatchKey,
                builder: (_) =>
                    const SizedBox(height: 80, child: Text('Dispatch target')),
              ),
            ),
          ),
        ),
      ),
    );

    final dispatchContext = dispatchKey.currentContext!;
    ScrollUpdateNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 120,
        pixels: 0,
        viewportDimension: 80,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: dispatchContext,
      dragDetails: DragUpdateDetails(
        globalPosition: Offset.zero,
        delta: const Offset(0, 12),
      ),
    ).dispatch(dispatchContext);
    await tester.pump();

    expect(find.text('Dispatch target'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh uses the source Android pointer slop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    final listKey = GlobalKey();

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              state: refreshState,
              onRefresh: () => refreshCompleter.future,
              child: ListView(
                key: listKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 1000)],
              ),
            ),
          ),
        ),
      ),
    );

    // Android Compose removes its native 8dp touch slop from the first event.
    // Flutter's larger 18dp fallback would produce the wrong drag geometry.
    final gesture = await tester.startGesture(const Offset(195, 300));
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    const normalized = (90 - 8) / 840;
    const expected =
        840 *
        (normalized -
            normalized * normalized +
            normalized * normalized * normalized / 3);
    expect(refreshState.dragOffset, closeTo(expected, .01));
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);

    // Subsequent events use the gesture's cumulative displacement and must
    // not be added again by the scroll-notification fallback.
    await gesture.moveBy(const Offset(0, 50));
    await tester.pump();
    const secondNormalized = (140 - 8) / 840;
    const secondExpected =
        840 *
        (secondNormalized -
            secondNormalized * secondNormalized +
            secondNormalized * secondNormalized * secondNormalized / 3);
    expect(refreshState.dragOffset, closeTo(secondExpected, .01));
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('miuix-pull-refresh-header')),
    );
    final listRect = tester.getRect(find.byKey(listKey));
    expect(listRect.top, closeTo(headerRect.bottom, .01));

    await gesture.up();
    await tester.pump();
    // Leave the asynchronous refresh callback pending only until teardown.
    refreshCompleter.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh follows the source threshold and five states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listKey = GlobalKey();
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    var callbackStarted = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixPullToRefresh(
              state: refreshState,
              refreshTexts: const ['下拉刷新', '松开刷新', '正在刷新…', '刷新成功'],
              onRefresh: () {
                callbackStarted = true;
                return refreshCompleter.future;
              },
              child: ListView(
                key: listKey,
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 1000)],
              ),
            ),
          ),
        ),
      ),
    );

    // The fixed visual offset stays 840 * 1/6 * 1/4 = 35dp. The current
    // configurable default triggers at 25% of the 280dp damped drag range.
    expect(refreshState.refreshThresholdOffset, closeTo(35, .01));
    expect(refreshState.triggerProgressOffset, closeTo(70, .01));
    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );

    // Twenty raw pixels are damped but remain just above half the threshold,
    // which is precisely where the source begins showing its first label.
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -20,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.pulling);
    expect(find.text('下拉刷新'), findsOneWidget);
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('miuix-pull-refresh-header')),
    );
    final listRect = tester.getRect(find.byKey(listKey));
    // The source header participates in Column measurement and pushes content;
    // it is not a floating spinner painted over the first list item.
    expect(listRect.top, closeTo(headerRect.bottom, .01));

    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -60,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
    expect(find.text('松开刷新'), findsOneWidget);

    // A substantial over-pull makes the release spring observable. During
    // that spring the source deliberately keeps the capsule/release phase.
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -180,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(
      refreshState.dragOffset,
      greaterThan(refreshState.refreshThresholdOffset * 3),
    );

    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(callbackStarted, isFalse);
    expect(refreshState.refreshState, MiuixRefreshState.thresholdReached);
    expect(find.text('松开刷新'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(callbackStarted, isTrue);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(find.text('正在刷新…'), findsOneWidget);

    refreshCompleter.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshState.refreshState, MiuixRefreshState.refreshComplete);
    expect(find.text('刷新成功'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 420));
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, closeTo(0, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh preserves direct drag but skips autonomous motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listKey = GlobalKey();
    final refreshState = MiuixPullToRefreshState();
    final refreshCompleter = Completer<void>();
    var reduceMotion = false;
    var callbackCount = 0;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Scaffold(
                  body: MiuixPullToRefresh(
                    state: refreshState,
                    refreshTexts: const [
                      'Pull',
                      'Release',
                      'Refreshing',
                      'Complete',
                    ],
                    onRefresh: () {
                      callbackCount++;
                      return refreshCompleter.future;
                    },
                    child: ListView(
                      key: listKey,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [SizedBox(height: 1000)],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    final context = listKey.currentContext!;
    final metrics = FixedScrollMetrics(
      minScrollExtent: 0,
      maxScrollExtent: 160,
      pixels: 0,
      viewportDimension: 840,
      axisDirection: AxisDirection.down,
      devicePixelRatio: 1,
    );
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: -220,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    final overPullOffset = refreshState.dragOffset;
    expect(
      overPullOffset,
      greaterThan(refreshState.refreshThresholdOffset * 3),
    );

    // First prove that an ordinary release really is inside the source spring.
    // Enabling the setting during that spring must finish the same coroutine,
    // not cancel its pending refresh callback or strand ThresholdReached.
    ScrollEndNotification(metrics: metrics, context: context).dispatch(context);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(callbackCount, 0);
    expect(refreshState.dragOffset, lessThan(overPullOffset));
    expect(
      refreshState.dragOffset,
      greaterThan(refreshState.refreshThresholdOffset),
    );

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(callbackCount, 1);
    expect(refreshState.refreshState, MiuixRefreshState.refreshing);
    expect(
      refreshState.dragOffset,
      closeTo(refreshState.refreshThresholdOffset, .01),
    );

    dynamic refreshPainter() => tester
        .widget<CustomPaint>(
          find.byKey(const ValueKey('miuix-pull-refresh-indicator')),
        )
        .painter;
    final frozenRotation = refreshPainter().rotation as double;
    await tester.pump(const Duration(seconds: 3));
    expect(refreshPainter().rotation, frozenRotation);

    // Completion remains visible for one frame, then both the collapse and
    // return spring resolve without animated intermediate geometry.
    refreshCompleter.complete();
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.refreshComplete);
    // The completion can arrive after this frame's build phase. The next frame
    // paints it, and the reduced-motion branch keeps it through that boundary.
    await tester.pump();
    expect(find.text('Complete'), findsOneWidget);
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, 0);

    // Reduced motion does not disable direct manipulation. A fresh subthreshold
    // pointer drag still tracks the finger, while its release snaps closed.
    final gesture = await tester.startGesture(const Offset(195, 300));
    await gesture.moveBy(const Offset(0, 30));
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.pulling);
    expect(refreshState.dragOffset, greaterThan(0));
    await gesture.up();
    await tester.pump();
    await tester.pump();
    expect(refreshState.refreshState, MiuixRefreshState.idle);
    expect(refreshState.dragOffset, 0);
    expect(callbackCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull refresh can unmount while refresh is pending', (
    tester,
  ) async {
    final refreshCompleter = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              height: 120,
              child: MiuixPullToRefresh(
                onRefresh: () => refreshCompleter.future,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 300, child: Text('Pending refresh')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 80));
    expect(refreshCompleter.isCompleted, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    refreshCompleter.complete();
    await tester.pump(const Duration(milliseconds: 420));

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'custom navigation rail, tabs, and dropdown preference stay safe',
    (tester) async {
      var selectedTab = -1;
      var selectedDropdown = 'one';
      var selectedRail = -1;

      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      MiuixTabBar(
                        tabs: const ['First', 'Second', 'Third'],
                        onTap: (index) => setState(() => selectedTab = index),
                      ),
                      SizedBox(
                        height: 180,
                        child: MiuixNavigationRail(
                          selectedIndex: 99,
                          extended: true,
                          onDestinationSelected: (index) =>
                              setState(() => selectedRail = index),
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
                      MiuixDropdownPreference<String>(
                        title: 'Choice',
                        value: selectedDropdown,
                        entries: const [
                          MiuixDropdownEntry(value: 'one', label: 'One'),
                          MiuixDropdownEntry(value: 'two', label: 'Two'),
                        ],
                        onChanged: (value) =>
                            setState(() => selectedDropdown = value),
                      ),
                      const MiuixFloatingActionButton(
                        icon: Icon(Icons.add),
                        onPressed: null,
                      ),
                      const MiuixAvatar(initials: 'MI'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Second'));
      await tester.pumpAndSettle();
      expect(selectedTab, 1);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(selectedRail, 0);

      await tester.tap(find.text('Choice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Two').last);
      await tester.pumpAndSettle();
      expect(selectedDropdown, 'two');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation rail defaults to local HyperOS glass', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: '主页',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.byType(MiuixNavigationRail);
    final glass = tester.widget<MiuixGlass>(
      find.byKey(const ValueKey('navigation-rail-glass')),
    );
    final selectedSurface = tester
        .widgetList<AnimatedContainer>(
          find.byKey(const ValueKey('navigation-rail-item-surface')),
        )
        .first;
    final selectedDecoration = selectedSurface.decoration! as ShapeDecoration;
    final selectedShape = selectedDecoration.shape as MiuixSquircleBorder;
    final scheme = Theme.of(tester.element(rail)).colorScheme;

    expect(tester.getSize(rail), const Size(104, 300));
    expect(
      tester.getRect(find.byKey(const ValueKey('navigation-rail-glass'))),
      const Rect.fromLTWH(12, 12, 80, 276),
    );
    expect(glass.blur, 24);
    expect(glass.opacity, .56);
    expect(glass.radius, 32);
    expect(glass.padding, EdgeInsets.zero);
    expect(find.byKey(const ValueKey('navigation-rail-divider')), findsNothing);
    expect(find.byIcon(Icons.home), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);
    expect(selectedDecoration.color, scheme.primary.withValues(alpha: .08));
    expect(selectedShape.borderRadius, BorderRadius.circular(22));
    expect(selectedSurface.constraints?.minHeight, 54);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail.sourceItems(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-rail-glass')), findsNothing);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      find.byKey(const ValueKey('navigation-rail-divider')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail selected wash preserves foreground contrast', (
    tester,
  ) async {
    double contrast(Color foreground, Color background) {
      final lighter = math.max(
        foreground.computeLuminance(),
        background.computeLuminance(),
      );
      final darker = math.min(
        foreground.computeLuminance(),
        background.computeLuminance(),
      );
      return (lighter + .05) / (darker + .05);
    }

    for (final brightness in Brightness.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(platformBrightness: brightness),
            child: MiuixTheme(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 220,
                  child: MiuixNavigationRail(
                    defaultWindowInsetsPadding: false,
                    selectedIndex: 0,
                    onDestinationSelected: (_) {},
                    items: const [
                      MiuixNavigationItem(
                        icon: Icon(Icons.home_outlined),
                        label: '主页',
                      ),
                      MiuixNavigationItem(
                        icon: Icon(Icons.settings_outlined),
                        label: '设置',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rail = find.byType(MiuixNavigationRail);
      final scheme = Theme.of(tester.element(rail)).colorScheme;
      final selectedSurface = tester
          .widgetList<AnimatedContainer>(
            find.byKey(const ValueKey('navigation-rail-item-surface')),
          )
          .first;
      final decoration = selectedSurface.decoration! as ShapeDecoration;
      final wash = decoration.color!;
      final paintedBackground = Color.alphaBlend(wash, scheme.surface);
      final label = tester.widget<Text>(find.text('主页'));
      expect(Theme.of(tester.element(find.text('主页'))).brightness, brightness);
      final expectedForeground = brightness == Brightness.dark
          ? scheme.onPrimaryContainer
          : scheme.primary;
      expect(label.style?.color, expectedForeground);
      expect(
        IconTheme.of(tester.element(find.byIcon(Icons.home_outlined))).color,
        expectedForeground,
      );
      expect(
        contrast(expectedForeground, paintedBackground),
        greaterThanOrEqualTo(3),
        reason: '$brightness selected rail content must remain distinguishable',
      );
    }
  });

  testWidgets('navigation rail snaps selection and expansion when reduced', (
    tester,
  ) async {
    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);
    MiuixNavigationRailState? activeState = state;
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 360,
                  child: MiuixNavigationRail(
                    state: activeState,
                    defaultWindowInsetsPadding: false,
                    selectedIndex: selected,
                    onDestinationSelected: (index) =>
                        setState(() => selected = index),
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
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 104);
    state.expand();
    await tester.pump();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 264);

    updateHost(() {
      activeState = null;
      selected = 1;
    });
    await tester.pump();
    final surfaces = tester.widgetList<AnimatedContainer>(
      find.byKey(const ValueKey('navigation-rail-item-surface')),
    );
    expect(surfaces, isNotEmpty);
    expect(
      surfaces.every((surface) => surface.duration == Duration.zero),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail uses MIUIX source item metrics', (tester) async {
    Future<void> pumpRail({required bool extended}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            child: Center(
              child: SizedBox(
                height: 180,
                child: MiuixNavigationRail.sourceItems(
                  selectedIndex: 0,
                  extended: extended,
                  onDestinationSelected: (_) {},
                  items: const [
                    MiuixNavigationItem(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    MiuixNavigationItem(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpRail(extended: true);

    final scheme = Theme.of(
      tester.element(find.byType(MiuixNavigationRail)),
    ).colorScheme;
    final semantic = MiuixSemanticColors.of(
      tester.element(find.byType(MiuixNavigationRail)),
    );
    final selectedContainer = tester
        .widgetList<AnimatedContainer>(
          find.ancestor(
            of: find.text('Home'),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .firstWhere((container) => container.decoration is BoxDecoration);
    final selectedDecoration = selectedContainer.decoration! as BoxDecoration;
    final selectedText = tester.widget<Text>(find.text('Home'));
    final selectedIconTheme = tester
        .widgetList<IconTheme>(
          find.ancestor(
            of: find.byIcon(Icons.home_outlined),
            matching: find.byType(IconTheme),
          ),
        )
        .firstWhere((theme) => theme.data.size == 28);

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 240.75);
    expect(selectedContainer.constraints?.minWidth, 216);
    expect(selectedContainer.constraints?.minHeight, 56);
    expect(
      selectedContainer.padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
    expect(selectedDecoration.color, scheme.surfaceContainerHigh);
    expect(selectedText.style?.fontSize, 16);
    expect(selectedText.style?.fontWeight, FontWeight.w500);
    expect(selectedText.style?.color, semantic['onSurfaceContainer']);
    expect(selectedIconTheme.data.size, 28);
    expect(selectedIconTheme.data.color, semantic['onSurfaceContainer']);

    await pumpRail(extended: false);

    final collapsedContainer = tester
        .widgetList<AnimatedContainer>(
          find.ancestor(
            of: find.text('Home'),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .firstWhere((container) => container.decoration is BoxDecoration);
    final collapsedDecoration = collapsedContainer.decoration! as BoxDecoration;
    final collapsedText = tester.widget<Text>(find.text('Home'));

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('navigation-rail-divider')))
          .width,
      .75,
    );
    expect(collapsedContainer.constraints?.minHeight, 0);
    expect(collapsedContainer.padding, EdgeInsets.zero);
    expect(collapsedDecoration.color, Colors.transparent);
    expect(collapsedText.style?.fontSize, 12);
    expect(collapsedText.style?.fontWeight, FontWeight.w700);
    expect(collapsedText.style?.color, semantic['onSurfaceContainer']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation rail exposes all four current source modes', (
    tester,
  ) async {
    var mode = MiuixNavigationRailDisplayMode.iconAndText;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: SizedBox(
                  height: 240,
                  child: MiuixNavigationRail(
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
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    updateHost(() => mode = MiuixNavigationRailDisplayMode.iconOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    updateHost(() => mode = MiuixNavigationRailDisplayMode.textOnly);
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsNothing);

    updateHost(
      () => mode = MiuixNavigationRailDisplayMode.iconWithSelectedLabel,
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source navigation rail exposes defaults and arbitrary items', (
    tester,
  ) async {
    var selected = 0;
    var mode = MiuixNavigationRailDisplayMode.iconOnly;
    late StateSetter updateHost;

    expect(MiuixNavigationRailDefaults.minWidth, 80);
    expect(MiuixNavigationRailDefaults.verticalPadding, 24);
    expect(MiuixNavigationRailDefaults.headerSpacing, 24);
    expect(MiuixNavigationRailDefaults.iconSize, 28);
    expect(MiuixNavigationRailDefaults.iconTextSpacing, 4);
    expect(MiuixNavigationRailDefaults.itemVerticalPadding, 12);
    expect(MiuixNavigationRailDefaults.labelFontSize, 12);
    expect(MiuixNavigationRailDefaults.textOnlyFontSize, 14);
    expect(MiuixNavigationRailDefaults.textOnlyVerticalPadding, 4);
    expect(MiuixNavigationRailDefaults.selectedPressedAlpha, .5);
    expect(MiuixNavigationRailDefaults.unselectedPressedAlpha, .6);
    expect(MiuixNavigationRailDefaults.unselectedAlpha, .4);
    final spring = debugMiuixNavigationRailSizeSpring();
    expect(spring.stiffness, 400);
    expect(spring.damping, closeTo(40, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: 260,
                  child: MiuixNavigationRail.source(
                    defaultWindowInsetsPadding: false,
                    mode: mode,
                    header: const SizedBox(
                      key: ValueKey('source-rail-header'),
                      width: 16,
                      height: 16,
                    ),
                    children: [
                      MiuixNavigationRailItem(
                        key: const ValueKey('source-rail-home'),
                        selected: selected == 0,
                        onClick: () => updateHost(() => selected = 0),
                        icon: const Icon(Icons.home_outlined),
                        label: '主页',
                        badge: const MiuixBadge.source(
                          key: ValueKey('source-rail-badge'),
                          content: Text('8'),
                        ),
                      ),
                      MiuixNavigationRailItem(
                        key: const ValueKey('source-rail-settings'),
                        selected: selected == 1,
                        onClick: () => updateHost(() => selected = 1),
                        icon: const Icon(Icons.settings_outlined),
                        label: '设置',
                      ),
                      const SizedBox(
                        key: ValueKey('source-rail-arbitrary-child'),
                        height: 3,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(find.byKey(const ValueKey('source-rail-header')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('source-rail-arbitrary-child')),
      findsOneWidget,
    );
    expect(find.text('主页'), findsNothing);
    expect(find.byKey(const ValueKey('source-rail-badge')), findsOneWidget);
    final iconOnlyHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;

    updateHost(
      () => mode = MiuixNavigationRailDisplayMode.iconWithSelectedLabel,
    );
    await tester.pump();
    await tester.pump();
    final springStartHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;
    await tester.pump(const Duration(milliseconds: 16));
    final springFrameHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;
    await tester.pumpAndSettle();
    final settledHeight = tester
        .getSize(find.byKey(const ValueKey('source-rail-home')))
        .height;

    expect(springStartHeight, closeTo(iconOnlyHeight, .01));
    expect(springFrameHeight, greaterThan(springStartHeight));
    expect(springFrameHeight, lessThan(settledHeight));
    expect(find.text('主页'), findsOneWidget);
    expect(find.text('设置'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('source-rail-settings')));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(find.text('主页'), findsNothing);
    expect(find.text('设置'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current classic rail uses medium tint and MIUIX indication', (
    tester,
  ) async {
    final enter = debugMiuixNavigationRailIndicationSpring(entering: true);
    final exit = debugMiuixNavigationRailIndicationSpring(entering: false);
    const enterFrequency = 2 * math.pi / .2;
    const exitFrequency = 2 * math.pi / .35;
    expect(enter.stiffness, closeTo(enterFrequency * enterFrequency, .001));
    expect(enter.damping, closeTo(2 * enterFrequency, .001));
    expect(exit.stiffness, closeTo(exitFrequency * exitFrequency, .001));
    expect(exit.damping, closeTo(2 * .95 * exitFrequency, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 260,
              child: MiuixNavigationRail.source(
                defaultWindowInsetsPadding: false,
                children: [
                  MiuixNavigationRailItem(
                    key: const ValueKey('classic-current-selected'),
                    selected: true,
                    onClick: () {},
                    icon: const Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  MiuixNavigationRailItem(
                    key: const ValueKey('classic-current-unselected'),
                    selected: false,
                    onClick: () {},
                    icon: const Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Current NavigationRail.kt does not dim or bold classic destinations;
    // both labels use the same medium onSurfaceContainer style.
    final home = tester.widget<Text>(find.text('Home'));
    final settings = tester.widget<Text>(find.text('Settings'));
    expect(home.style?.fontWeight, FontWeight.w500);
    expect(settings.style?.fontWeight, FontWeight.w500);
    expect(home.style?.color, settings.style?.color);
    expect(home.style?.color?.a, 1);

    final unselected = find.byKey(const ValueKey('classic-current-unselected'));
    final indications = find.byKey(
      const ValueKey('navigation-rail-source-indication'),
    );
    expect(indications, findsNWidgets(2));
    double indicationAlpha() => tester
        .widgetList<ColoredBox>(indications)
        .map((box) => box.color.a)
        .reduce(math.max);
    expect(indicationAlpha(), 0);
    final gesture = await tester.startGesture(tester.getCenter(unselected));
    // The first frame resolves the tap recognizer and starts the spring; the
    // next frame measures the source indication while that spring is moving.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(indicationAlpha(), greaterThan(0));
    expect(indicationAlpha(), lessThan(.1));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(.1, .001));
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(indicationAlpha(), greaterThan(0));
    expect(indicationAlpha(), lessThan(.1));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(0, .001));

    final quickGesture = await tester.startGesture(
      tester.getCenter(unselected),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    final quickReleaseAlpha = indicationAlpha();
    expect(quickReleaseAlpha, inExclusiveRange(0, .1));
    await quickGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    // MiuixIndication joins the positive press job before starting PressExit;
    // a short tap therefore still reaches toward the authored 10% overlay.
    expect(indicationAlpha(), greaterThan(quickReleaseAlpha));
    await tester.pumpAndSettle();
    expect(indicationAlpha(), closeTo(0, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('expandable navigation rail follows current stateful morph', (
    tester,
  ) async {
    final state = MiuixNavigationRailState();
    addTearDown(state.dispose);

    expect(MiuixNavigationRailDefaults.expandedWidth, 240);
    expect(MiuixNavigationRailDefaults.expandedLabelFontSize, 16);
    expect(MiuixNavigationRailDefaults.expandedItemHorizontalMargin, 12);
    expect(MiuixNavigationRailDefaults.expandedItemCornerRadius, 16);
    expect(MiuixNavigationRailDefaults.collapsedIndicatorVerticalPadding, 4);
    expect(
      MiuixNavigationRailDefaults.expandedItemContentHorizontalPadding,
      14,
    );
    expect(MiuixNavigationRailDefaults.expandedItemContentVerticalPadding, 14);
    expect(MiuixNavigationRailDefaults.expandedItemIconTextSpacing, 16);
    final expandSpring = debugMiuixNavigationRailExpandSpring();
    const expectedFrequency = 2 * math.pi / .35;
    expect(
      expandSpring.stiffness,
      closeTo(expectedFrequency * expectedFrequency, .001),
    );
    expect(expandSpring.damping, closeTo(2 * expectedFrequency, .001));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 560,
              child: MiuixNavigationRail.sourceItems(
                state: state,
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: '主页',
                    badge: MiuixBadge.source(
                      key: ValueKey('expandable-rail-badge'),
                      content: Text('8'),
                    ),
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings_outlined),
                    label: '设置',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(state.currentValue, MiuixNavigationRailValue.collapsed);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('navigation-rail-expandable-item-visual')),
      findsNWidgets(2),
    );
    final collapsedHome = tester.widget<Text>(find.text('主页'));
    expect(collapsedHome.style?.fontSize, 12);
    expect(collapsedHome.style?.fontWeight, FontWeight.w500);
    final collapsedIndicator = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-expandable-indicator')).first,
    );
    expect(collapsedIndicator.left, 12);
    expect(collapsedIndicator.width, 56);
    expect(collapsedIndicator.height, 36);
    final collapsedIcon = tester.getRect(find.byIcon(Icons.home_outlined));
    final collapsedBadge = tester.getRect(
      find.byKey(const ValueKey('expandable-rail-badge')),
    );
    // NavigationItemIcon retains the 28dp anchor and lets a content badge
    // overlap it by the source 12dp/14dp offsets. Wrapping the pair in the
    // icon's FittedBox would incorrectly shrink this 16dp badge.
    expect(collapsedIcon.size, const Size.square(28));
    // Flutter's Ahem test font makes one 11sp digit wider than Android Roboto;
    // it may exceed the 16dp minimum, but must remain below the 28dp icon slot.
    expect(collapsedBadge.width, greaterThanOrEqualTo(16));
    expect(collapsedBadge.width, lessThan(28));
    expect(collapsedBadge.height, 16);
    expect(collapsedBadge.left, closeTo(collapsedIcon.left + 16, .001));
    expect(collapsedBadge.top, closeTo(collapsedIcon.top - 2, .001));

    state.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final movingWidth = tester.getSize(find.byType(MiuixNavigationRail)).width;
    expect(movingWidth, greaterThan(80.75));
    expect(movingWidth, lessThan(240.75));
    await tester.pumpAndSettle();

    expect(state.currentValue, MiuixNavigationRailValue.expanded);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 240.75);
    final expandedHome = tester.widget<Text>(find.text('主页'));
    expect(expandedHome.style?.fontSize, 16);
    expect(expandedHome.style?.fontWeight, FontWeight.w500);
    final expandedIndicator = tester.getRect(
      find.byKey(const ValueKey('navigation-rail-expandable-indicator')).first,
    );
    expect(expandedIndicator.left, 12);
    expect(expandedIndicator.width, 216);
    expect(expandedIndicator.height, 56);
    final expandedIcon = tester.getRect(find.byIcon(Icons.home_outlined));
    final expandedBadge = tester.getRect(
      find.byKey(const ValueKey('expandable-rail-badge')),
    );
    expect(expandedIcon.size, const Size.square(28));
    expect(expandedBadge.width, greaterThanOrEqualTo(16));
    expect(expandedBadge.width, lessThan(28));
    expect(expandedBadge.height, 16);
    expect(expandedBadge.left, closeTo(expandedIcon.left + 16, .001));
    expect(expandedBadge.top, closeTo(expandedIcon.top - 2, .001));
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find
                        .byKey(
                          const ValueKey(
                            'navigation-rail-expandable-indicator',
                          ),
                        )
                        .first,
                  )
                  .decoration
              as ShapeDecoration)
          .shape,
      isA<MiuixSquircleBorder>(),
    );

    await tester.tap(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
    );
    await tester.pumpAndSettle();
    expect(state.currentValue, MiuixNavigationRailValue.collapsed);
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);

    state.expand();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 30));
    final widthBeforeReverse = tester
        .getSize(find.byType(MiuixNavigationRail))
        .width;
    state.collapse();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    // animateFloatAsState retargets with its current outward velocity, so a
    // rapid reversal continues outward briefly instead of forming a cusp.
    expect(
      tester.getSize(find.byType(MiuixNavigationRail)).width,
      greaterThan(widthBeforeReverse),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 80.75);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'navigation rail applies source header divider and start insets',
    (tester) async {
      tester.view.physicalSize = const Size(300, 400);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 20, left: 10);
      tester.view.viewPadding = const FakeViewPadding(top: 20, left: 10);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      Widget rail({
        bool showDivider = true,
        bool defaultWindowInsetsPadding = true,
      }) => MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 300,
              child: MiuixNavigationRail.sourceItems(
                color: Colors.red,
                showDivider: showDivider,
                defaultWindowInsetsPadding: defaultWindowInsetsPadding,
                header: const SizedBox(
                  key: ValueKey('rail-header'),
                  width: 20,
                  height: 20,
                ),
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(rail());
      await tester.pumpAndSettle();

      final railRect = tester.getRect(find.byType(MiuixNavigationRail));
      final columnRect = tester.getRect(
        find.byKey(const ValueKey('navigation-rail-column')),
      );
      final dividerRect = tester.getRect(
        find.byKey(const ValueKey('navigation-rail-divider')),
      );
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('rail-header')),
      );
      final surface = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(MiuixNavigationRail),
              matching: find.byType(ColoredBox),
            ),
          )
          .first;

      expect(railRect, const Rect.fromLTWH(0, 0, 90.75, 300));
      // Current NavigationRail applies status/navigation insets to the
      // scrollable column only. Its background and divider remain full height,
      // while the first header still starts after 20dp + 24dp content padding.
      expect(columnRect, const Rect.fromLTWH(10, 0, 80, 300));
      expect(dividerRect, const Rect.fromLTWH(90, 0, .75, 300));
      expect(headerRect, const Rect.fromLTWH(40, 44, 20, 20));
      expect(surface.color, Colors.red);

      await tester.pumpWidget(
        rail(showDivider: false, defaultWindowInsetsPadding: false),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(MiuixNavigationRail)),
        const Rect.fromLTWH(0, 0, 80, 300),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('navigation-rail-column'))),
        const Rect.fromLTWH(0, 0, 80, 300),
      );
      expect(tester.getRect(find.byKey(const ValueKey('rail-header'))).top, 24);
      expect(
        find.byKey(const ValueKey('navigation-rail-divider')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('navigation rail follows source pressed and disabled behavior', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 320,
              child: MiuixNavigationRail.sourceItems(
                defaultWindowInsetsPadding: false,
                selectedIndex: 0,
                onDestinationSelected: (index) => selected = index,
                items: const [
                  MiuixNavigationItem(
                    icon: Icon(Icons.home_outlined),
                    label: 'Home',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                  MiuixNavigationItem(
                    icon: Icon(Icons.person_outline),
                    label: 'Disabled',
                    enabled: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Color iconColor(int index) {
      final item = find.byKey(ValueKey('navigation-rail-item-$index'));
      return tester
          .widgetList<IconTheme>(
            find.descendant(of: item, matching: find.byType(IconTheme)),
          )
          .firstWhere((theme) => theme.data.size == 28)
          .data
          .color!;
    }

    expect(iconColor(0).a, 1);
    expect(iconColor(1).a, closeTo(.4, .001));
    expect(iconColor(2).a, closeTo(.4, .001));

    final selectedGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('navigation-rail-item-0'))),
    );
    await tester.pump();
    expect(iconColor(0).a, closeTo(.5, .001));
    await selectedGesture.up();
    await tester.pump();
    expect(iconColor(0).a, 1);
    expect(selected, 0);

    final unselectedGesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('navigation-rail-item-1'))),
    );
    await tester.pump();
    expect(iconColor(1).a, closeTo(.6, .001));
    await unselectedGesture.up();
    await tester.pump();
    expect(iconColor(1).a, closeTo(.4, .001));
    expect(selected, 1);

    selected = -1;
    await tester.tap(find.byKey(const ValueKey('navigation-rail-item-2')));
    await tester.pump();
    expect(selected, -1);
    expect(iconColor(2).a, closeTo(.4, .001));
    expect(tester.takeException(), isNull);
  });

  test('tab rows allocate widths with the MIUIX source formula', () {
    expect(
      debugMiuixTabWidth(
        tabCount: 3,
        minWidth: 76,
        maxWidth: 98,
        spacing: 9,
        availableWidth: 366,
      ),
      116,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 3,
        minWidth: 76,
        maxWidth: 98,
        spacing: 9,
        availableWidth: 300,
      ),
      94,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 6,
        minWidth: 62,
        maxWidth: 84,
        spacing: 5,
        availableWidth: 290,
      ),
      62,
    );
    expect(
      debugMiuixTabWidth(
        tabCount: 6,
        minWidth: 62,
        maxWidth: 84,
        spacing: 5,
        availableWidth: 520,
      ),
      82.5,
    );
  });

  testWidgets('tab row normalizes dynamic geometry before layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 320,
              child: MiuixTabBar.contour(
                tabs: <String>['One', 'Two'],
                minWidth: double.nan,
                maxWidth: -10,
                height: -4,
                cornerRadius: double.infinity,
                itemSpacing: double.nan,
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('miuix-hyperos4-tab-surface')))
          .height,
      MiuixTabRowDefaults.hyperOs4Padding * 2,
    );
    expect(
      indicator.borderRadius,
      BorderRadius.circular(MiuixTabRowDefaults.hyperOs4CornerRadius),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation remains a read-only controlled preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixFloatingNavigationBar(
            items: <MiuixNavigationItem>[
              MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
              MiuixNavigationItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedIndex: 0,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('floating-navigation-item-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab row defaults resolve the four source color channels', (
    tester,
  ) async {
    late MiuixTabRowColors colors;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Builder(
            builder: (context) {
              colors = MiuixTabRowDefaults.tabRowColors(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final context = tester.element(find.byType(SizedBox));
    final semantic = MiuixSemanticColors.of(context);
    expect(MiuixTabRowDefaults.height, 42);
    expect(MiuixTabRowDefaults.contourHeight, 45);
    expect(MiuixTabRowDefaults.cornerRadius, 12);
    expect(MiuixTabRowDefaults.contourCornerRadius, 8);
    expect(MiuixTabRowDefaults.minWidth, 76);
    expect(MiuixTabRowDefaults.contourMinWidth, 62);
    expect(MiuixTabRowDefaults.maxWidth, 98);
    expect(MiuixTabRowDefaults.contourMaxWidth, 84);
    expect(MiuixTabRowDefaults.itemSpacing, 9);
    expect(MiuixTabRowDefaults.contourItemSpacing, 5);
    expect(colors.backgroundColor, semantic['surface']);
    expect(colors.contentColor, semantic['onSurfaceVariantSummary']);
    expect(colors.selectedBackgroundColor, semantic['surfaceContainer']);
    expect(colors.selectedContentColor, semantic['onBackground']);

    const replacement = Color(0xff102030);
    final changed = colors.copyWith(contentColor: replacement);
    expect(changed.contentColor, replacement);
    expect(changed.backgroundColor, colors.backgroundColor);
    expect(changed.selectedBackgroundColor, colors.selectedBackgroundColor);
    expect(changed.selectedContentColor, colors.selectedContentColor);
    expect(changed, colors.copyWith(contentColor: replacement));
    expect(
      changed.hashCode,
      colors.copyWith(contentColor: replacement).hashCode,
    );
  });

  testWidgets('default tab row uses HyperOS glass metrics and reduced motion', (
    tester,
  ) async {
    var selected = 0;
    var reduceMotion = false;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(disableAnimations: reduceMotion),
                child: Center(
                  child: SizedBox(
                    width: 366,
                    child: MiuixTabRow(
                      tabs: const ['One', 'Two', 'Three'],
                      selectedTabIndex: selected,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(MiuixTabRowDefaults.hyperOs4Height, 44);
    expect(MiuixTabRowDefaults.hyperOs4CornerRadius, 19);
    expect(MiuixTabRowDefaults.hyperOs4Padding, 3);
    final row = find.byType(MiuixTabRow);
    final surface = tester.widget<MiuixSurface>(
      find.descendant(of: row, matching: find.byType(MiuixSurface)).first,
    );
    final first = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final second = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final positioned = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-tab-indicator')),
    );
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(of: row, matching: find.byType(MiuixPressable)),
    );

    // These are project-calibrated HyperOS values, not unpublished Xiaomi dp.
    expect(tester.getSize(row).height, 44);
    expect(first.height, 38);
    expect(first.width, 118);
    expect(second.left - first.right, 3);
    expect(surface.glass, isTrue);
    expect(surface.radius, 22);
    expect(surface.glassBlur, 18);
    expect(surface.glassOpacity, .60);
    expect(positioned.duration, const Duration(milliseconds: 380));
    expect(positioned.curve, Curves.easeOutCubic);
    expect(tester.widget<Text>(find.text('One')).style?.fontSize, 14);
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w600,
    );
    expect(pressables.every((pressable) => pressable.showIndication), isTrue);

    final start = tester.getTopLeft(indicator).dx;
    updateHost(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    final intermediate = tester.getTopLeft(indicator).dx;
    expect(intermediate, greaterThan(start));
    expect(intermediate, lessThan(second.left));
    await tester.pump(const Duration(milliseconds: 260));
    expect(tester.getTopLeft(indicator).dx, closeTo(second.left, .01));

    updateHost(() {
      reduceMotion = true;
      selected = 2;
    });
    await tester.pump();
    final third = tester.getRect(find.byKey(const ValueKey('miuix-tab-2')));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab row applies custom source geometry colors and interaction', (
    tester,
  ) async {
    const colors = MiuixTabRowColors(
      backgroundColor: Color(0xff112233),
      contentColor: Color(0xff445566),
      selectedBackgroundColor: Color(0xff778899),
      selectedContentColor: Color(0xffaabbcc),
    );
    final interactionSource = MiuixInteractionSource();
    addTearDown(interactionSource.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 210,
              child: MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                colors: colors,
                minWidth: 60,
                maxWidth: 70,
                height: 50,
                cornerRadius: 10,
                itemSpacing: 4,
                contentAlignment: Alignment.centerLeft,
                interactionSource: interactionSource,
                showIndication: true,
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byType(MiuixTabRow);
    final first = find.byKey(const ValueKey('miuix-tab-0'));
    final second = find.byKey(const ValueKey('miuix-tab-1'));
    final firstRect = tester.getRect(first);
    final secondRect = tester.getRect(second);
    final background = tester.widget<ColoredBox>(
      find.descendant(of: row, matching: find.byType(ColoredBox)).first,
    );
    final indicator = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    final firstText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(of: row, matching: find.byType(MiuixPressable)),
    );

    expect(tester.getSize(row), const Size(210, 50));
    expect(firstRect.width, closeTo(202 / 3, .01));
    expect(secondRect.left - firstRect.right, closeTo(4, .01));
    expect(
      tester.getTopLeft(find.text('One')).dx,
      closeTo(firstRect.left + 12, .01),
    );
    expect(background.color, colors.backgroundColor);
    expect(indicator.color, colors.selectedBackgroundColor);
    expect(indicator.borderRadius, BorderRadius.circular(10));
    expect(firstText.style?.color, colors.selectedContentColor);
    expect(secondText.style?.color, colors.contentColor);
    expect(
      pressables.every(
        (pressable) =>
            pressable.showIndication &&
            identical(pressable.interactionSource, interactionSource),
      ),
      isTrue,
    );

    final gesture = await tester.startGesture(tester.getCenter(first));
    await tester.pump();
    expect(interactionSource.pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(interactionSource.pressed, isFalse);
  });

  testWidgets('tab items expose selected source tab semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: MiuixTabRow.source(tabs: ['One', 'Two'], selectedTabIndex: 1),
        ),
      ),
    );

    final first = tester.getSemantics(
      find.byKey(const ValueKey('miuix-tab-semantic-0')),
    );
    final second = tester.getSemantics(
      find.byKey(const ValueKey('miuix-tab-semantic-1')),
    );
    expect(first.role, SemanticsRole.tab);
    expect(first.flagsCollection.isSelected, Tristate.isFalse);
    expect(first.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(first.rect.height, 48);
    expect(second.role, SemanticsRole.tab);
    expect(second.flagsCollection.isSelected, Tristate.isTrue);
    expect(second.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(second.rect.height, 48);
  });

  testWidgets('tab accepts taps in the source 48dp expansion band', (
    tester,
  ) async {
    var selected = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                selectedTabIndex: 0,
                onTabSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      ),
    );

    final second = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(second.height, 42);
    await tester.tapAt(Offset(second.center.dx, second.top - 2));
    await tester.pump();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab row fills wide source layouts', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(tabs: ['One', 'Two', 'Three']),
            ),
          ),
        ),
      ),
    );

    final first = find.byKey(const ValueKey('miuix-tab-0'));
    final second = find.byKey(const ValueKey('miuix-tab-1'));
    final firstRect = tester.getRect(first);
    final secondRect = tester.getRect(second);
    final firstText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );
    final selectedOutline =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-tab-outline-0')),
                )
                .decoration
            as ShapeDecoration;
    final unselectedOutline =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('miuix-tab-outline-1')),
                )
                .decoration
            as ShapeDecoration;
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixTabRow),
        matching: find.byType(MiuixPressable),
      ),
    );
    final semantic = MiuixSemanticColors.of(tester.element(first));

    expect(tester.getSize(find.byType(MiuixTabRow)).height, 42);
    expect(firstRect.width, 116);
    expect(secondRect.left - firstRect.right, 9);
    expect(firstText.style?.fontSize, 16);
    expect(firstText.style?.fontWeight, FontWeight.w700);
    expect(firstText.style?.color, semantic['onBackground']);
    expect(secondText.style?.fontWeight, FontWeight.w400);
    expect(secondText.style?.color, semantic['onSurfaceVariantSummary']);
    expect(indicatorSurface.enabled, isTrue);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(12));
    expect(
      (selectedOutline.shape as MiuixSquircleBorder).side,
      BorderSide.none,
    );
    expect(
      (unselectedOutline.shape as MiuixSquircleBorder).side,
      BorderSide(color: semantic['outline'], width: 1),
    );
    expect(
      pressables.every(
        (pressable) =>
            pressable.feedbackType == MiuixPressFeedbackType.none &&
            !pressable.showIndication,
      ),
      isTrue,
    );
  });

  testWidgets('tab row preserves the source empty-list surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Column(
            children: [
              SizedBox(width: 300, child: MiuixTabRow.source(tabs: [])),
              SizedBox(
                width: 300,
                child: MiuixTabRowWithContour.source(tabs: []),
              ),
            ],
          ),
        ),
      ),
    );

    // calculateTabWidth returns the variant's minimum width for an empty
    // source list. Both composables still build their fixed-height surface
    // and a zero-selection indicator; they do not collapse.
    expect(tester.getSize(find.byType(MiuixTabRow)), const Size(300, 42));
    expect(
      tester.getSize(find.byType(MiuixTabRowWithContour)),
      const Size(300, 45),
    );
    final indicators = find.byKey(
      const ValueKey('miuix-tab-indicator-surface'),
    );
    expect(indicators, findsNWidgets(2));
    expect(tester.getSize(indicators.at(0)).width, 76);
    expect(tester.getSize(indicators.at(1)).width, 62);
    expect(find.byKey(const ValueKey('miuix-tab-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab row snaps an initial nonzero source selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: MiuixTabRow.source(
                tabs: ['One', 'Two', 'Three'],
                selectedTabIndex: 2,
              ),
            ),
          ),
        ),
      ),
    );

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final third = tester.getRect(find.byKey(const ValueKey('miuix-tab-2')));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(
      tester.widget<Text>(find.text('Three')).style?.fontWeight,
      FontWeight.w700,
    );

    // Current TabRow derives its indicator offset directly. It must not reuse
    // the contour variant's remembered Animatable or delayed target handoff.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(third.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('source-controlled tab row waits for its selected index', (
    tester,
  ) async {
    var selected = 0;
    var callbackIndex = -1;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return MiuixTabRow.source(
                tabs: const ['One', 'Two', 'Three'],
                selectedTabIndex: selected,
                onTabSelected: (index) => callbackIndex = index,
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();
    expect(callbackIndex, 1);
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('Two')).style?.fontWeight,
      FontWeight.w400,
    );

    updateHost(() => selected = 1);
    await tester.pump();
    expect(
      tester.widget<Text>(find.text('One')).style?.fontWeight,
      FontWeight.w400,
    );
    expect(
      tester.widget<Text>(find.text('Two')).style?.fontWeight,
      FontWeight.w700,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordinary tab indicator follows selection without animation', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return MiuixTabRow.source(
                    tabs: const ['One', 'Two', 'Three'],
                    selectedTabIndex: selected,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final start = tester.getTopLeft(indicator).dx;
    final firstTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final secondTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(start, closeTo(firstTab.left, .01));

    updateHost(() => selected = 1);
    await tester.pump();
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contour tab indicator follows the source 200 ms linear motion', (
    tester,
  ) async {
    var selected = 0;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 366,
              child: StatefulBuilder(
                builder: (context, setState) {
                  updateHost = setState;
                  return MiuixTabRowWithContour.source(
                    tabs: const ['One', 'Two', 'Three'],
                    selectedTabIndex: selected,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final firstTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-0')));
    final secondTab = tester.getRect(find.byKey(const ValueKey('miuix-tab-1')));
    expect(tester.getTopLeft(indicator).dx, closeTo(firstTab.left, .01));

    updateHost(() => selected = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.getTopLeft(indicator).dx,
      closeTo((firstTab.left + secondTab.left) / 2, .01),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(indicator).dx, closeTo(secondTab.left, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contour tab row snaps its initial selection and scroll offset', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
                selectedTabIndex: 5,
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byType(MiuixTabRowWithContour);
    final indicator = find.byKey(const ValueKey('miuix-tab-indicator-surface'));
    final selected = find.byKey(const ValueKey('miuix-tab-5'));
    await tester.pump();

    // The first source LaunchedEffect uses scrollToItem and the contour
    // Animatable uses snapTo, so neither operation begins an entrance tween.
    expect(tester.getRect(indicator), tester.getRect(selected));
    expect(
      tester.getRect(selected).right,
      lessThanOrEqualTo(tester.getRect(row).right),
    );
    final scrollable = find.descendant(
      of: row,
      matching: find.byType(Scrollable),
    );
    expect(
      tester
          .state<ScrollableState>(scrollable)
          .position
          .isScrollingNotifier
          .value,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tab rows follow the source smooth-rounding theme switch', (
    tester,
  ) async {
    final theme = MiuixThemeData.defaults().copyWith(enableSquircle: false);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: theme,
          child: const Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: ['One', 'Two', 'Three'],
              ),
            ),
          ),
        ),
      ),
    );

    final outer = tester.widget<SizedBox>(
      find.byKey(const ValueKey('miuix-contour-tab-surface')),
    );
    final outerSurface = tester.widget<MiuixSquircleBackground>(
      find
          .descendant(
            of: find.byKey(const ValueKey('miuix-contour-tab-surface')),
            matching: find.byType(MiuixSquircleBackground),
          )
          .first,
    );
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );

    // LocalSmoothRounding=false makes both source shapes ordinary rounded
    // rectangles; the geometry and radii remain unchanged.
    expect(outer.height, 45);
    expect(outerSurface.enabled, isFalse);
    expect(outerSurface.borderRadius, BorderRadius.circular(13));
    expect(indicatorSurface.enabled, isFalse);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('contour tab row uses source metrics and centers selection', (
    tester,
  ) async {
    var selected = -1;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 300,
              child: MiuixTabRowWithContour.source(
                tabs: const ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
                onTap: (index) => selected = index,
              ),
            ),
          ),
        ),
      ),
    );

    final outer = tester.widget<SizedBox>(
      find.byKey(const ValueKey('miuix-contour-tab-surface')),
    );
    final outerSurface = tester.widget<MiuixSquircleBackground>(
      find
          .descendant(
            of: find.byKey(const ValueKey('miuix-contour-tab-surface')),
            matching: find.byType(MiuixSquircleBackground),
          )
          .first,
    );
    final selectedTabFinder = find.byKey(const ValueKey('miuix-tab-0'));
    final secondTabFinder = find.byKey(const ValueKey('miuix-tab-1'));
    final selectedText = tester.widget<Text>(find.text('One'));
    final secondText = tester.widget<Text>(find.text('Two'));
    final pressables = tester.widgetList<MiuixPressable>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(MiuixPressable),
      ),
    );
    final horizontalViewport = tester.widget<SingleChildScrollView>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(SingleChildScrollView),
      ),
    );
    final selectedRect = tester.getRect(selectedTabFinder);
    final secondRect = tester.getRect(secondTabFinder);
    final semantic = MiuixSemanticColors.of(tester.element(selectedTabFinder));
    final indicator = tester.widget<AnimatedPositionedDirectional>(
      find.byKey(const ValueKey('miuix-tab-indicator')),
    );
    final indicatorSurface = tester.widget<MiuixSquircleBackground>(
      find.byKey(const ValueKey('miuix-tab-indicator-surface')),
    );

    expect(tester.getSize(find.byType(MiuixTabRowWithContour)).height, 45);
    expect(outer.height, 45);
    expect(outerSurface.color, semantic['surface']);
    expect(outerSurface.enabled, isTrue);
    expect(outerSurface.borderRadius, BorderRadius.circular(13));
    expect(tester.getSize(selectedTabFinder).height, 35);
    expect(tester.getSize(selectedTabFinder).width, 62);
    // Compose LazyRow clips only scroll-axis paint. This prevents the sixth
    // sample label from escaping the right side while the independent target
    // proxy below still exposes the full 48dp vertical interaction band.
    expect(horizontalViewport.clipBehavior, Clip.hardEdge);
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('miuix-tab-semantic-0')))
          .rect
          .height,
      48,
    );
    expect(tester.getSize(secondTabFinder).height, 35);
    expect(tester.getSize(secondTabFinder).width, 62);
    expect(secondRect.left - selectedRect.right, closeTo(5, 1));
    expect(selectedText.style?.fontSize, 14);
    expect(selectedText.style?.fontWeight, FontWeight.w700);
    expect(selectedText.style?.color, semantic['onBackground']);
    expect(secondText.style?.fontWeight, FontWeight.w400);
    expect(secondText.style?.color, semantic['onSurfaceVariantSummary']);
    expect(indicator.duration, const Duration(milliseconds: 200));
    expect(indicator.curve, Curves.linear);
    expect(indicatorSurface.color, semantic['surfaceContainer']);
    expect(indicatorSurface.enabled, isTrue);
    expect(indicatorSurface.borderRadius, BorderRadius.circular(8));
    expect(
      pressables.every(
        (pressable) =>
            pressable.feedbackType == MiuixPressFeedbackType.none &&
            !pressable.showIndication,
      ),
      isTrue,
    );

    await tester.drag(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Four'));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(MiuixTabRowWithContour),
        matching: find.byType(Scrollable),
      ),
    );
    expect(selected, 3);
    expect(scrollable.position.pixels, closeTo(87, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom snackbar, chip, and pull refresh stay safe', (
    tester,
  ) async {
    var actionPressed = false;
    var chipDeleted = false;
    var refreshed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    MiuixTextButton(
                      label: 'Show snackbar',
                      onPressed: () {
                        MiuixSnackbar.show(
                          context,
                          'Saved',
                          action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () => actionPressed = true,
                          ),
                        );
                      },
                    ),
                    MiuixTextButton(
                      label: 'Show toast',
                      onPressed: () => MiuixToast.show(context, 'Toast text'),
                    ),
                    MiuixChip(
                      label: 'Tagged',
                      icon: const Icon(Icons.label_outline),
                      onDeleted: () => chipDeleted = true,
                    ),
                    SizedBox(
                      height: 120,
                      child: MiuixPullToRefresh(
                        onRefresh: () async => refreshed = true,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 300, child: Text('Refresh child')),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show snackbar'));
    // Snackbar.kt uses Compose's critically damped default spring rather than
    // a fixed 180ms tween. Settle that source motion before exercising action
    // hit testing so the control is at its final screen coordinate.
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(actionPressed, isTrue);

    await tester.tap(find.text('Show toast'));
    await tester.pump(const Duration(milliseconds: 240));
    expect(find.text('Toast text'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pump(const Duration(milliseconds: 120));
    expect(chipDeleted, isTrue);

    await tester.drag(find.byType(ListView), const Offset(0, 160));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 520));
    expect(refreshed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('custom text fields and segmented controls stay safe', (
    tester,
  ) async {
    final controller = TextEditingController();
    var changed = '';
    var submitted = '';
    var selected = <String>{'A'};

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    MiuixTextField(
                      controller: controller,
                      label: 'Name',
                      hint: 'Type name',
                      prefixIcon: const Icon(Icons.person_outline),
                      suffixIcon: const Icon(Icons.check),
                      onChanged: (value) => changed = value,
                      onSubmitted: (value) => submitted = value,
                    ),
                    const MiuixTextField(hint: 'Internal controller'),
                    MiuixSegmentedControl<String>(
                      values: const ['A', 'B', 'C'],
                      selected: selected,
                      labelBuilder: (value) => value,
                      onSelectionChanged: (value) =>
                          setState(() => selected = value),
                    ),
                    const MiuixSegmentedControl<String>(
                      values: [],
                      selected: {},
                      labelBuilder: _identityLabel,
                      onSelectionChanged: _ignoreStringSet,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, 'Miuix');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(changed, 'Miuix');
    expect(submitted, 'Miuix');
    expect(controller.text, 'Miuix');

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    expect(selected, containsAll(['A', 'B']));

    await tester.tap(find.text('A'));
    await tester.pumpAndSettle();
    expect(selected, isNot(contains('A')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized empty text field keeps source one-line height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 320,
              child: MiuixTextField(
                key: ValueKey('localized-source-field'),
                label: '文本框',
              ),
            ),
          ),
        ),
      ),
    );

    // TextFieldDefaults.InsideMargin contributes 16dp above and below. At the
    // test's 3x density, the source 17sp line box encloses 60 physical pixels;
    // together with the two 48px insets that is 156px.
    expect(
      tester
          .getSize(find.byKey(const ValueKey('localized-source-field')))
          .height,
      52,
    );
    final labelDefaults = tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text('文本框'),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
    // The rendered style carries the already-enclosed 60px line box back as a
    // ratio so Text and StrutStyle cannot independently round it a second time.
    expect(labelDefaults.style.height, closeTo(20 / 17, 1e-12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('preference trailing content contracts on narrow screens', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Center(
            child: SizedBox(
              width: 220,
              child: MiuixSettingsGroup(
                children: [
                  const MiuixPreference(
                    title: 'Display mode',
                    summary: 'A compact row with a long selected value.',
                    leading: Icon(Icons.tune),
                    trailing: Text('Very long selected preference value'),
                  ),
                  MiuixDropdownPreference<String>(
                    title: 'Dropdown',
                    value: 'expressive',
                    entries: const [
                      MiuixDropdownEntry(
                        value: 'expressive',
                        label: 'Expressive mode with long copy',
                      ),
                    ],
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Display mode'), findsOneWidget);
    expect(find.text('Dropdown'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar uses HyperOS 4 glass metrics and clears safely', (
    tester,
  ) async {
    final firstController = TextEditingController();
    final secondController = TextEditingController(text: 'swap');
    final changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixSearchBar(
              controller: firstController,
              hint: 'Search components',
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 48);
    final semanticTarget = find.byKey(
      const ValueKey('miuix-search-semantic-target'),
    );
    expect(tester.getSize(semanticTarget).height, 48);
    final semantics = tester.ensureSemantics();
    final semanticNode = tester.getSemantics(semanticTarget);
    // The HyperOS 4 capsule and accessibility target now share 48dp.
    expect(semanticNode.rect.height, 48);
    semantics.dispose();
    // InputField.kt applies size(44.dp) before 16dp/8dp padding. The padding
    // constrains the vector to 20dp; it must not enlarge the slot to 48dp.
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-leading-slot'))),
      const Size(44, 44),
    );
    final glass = tester.widget<MiuixGlass>(container);
    expect(glass.enabled, isTrue);
    expect(glass.blur, 18);
    expect(glass.opacity, .62);
    final clip = tester.widget<ClipPath>(
      find.descendant(of: container, matching: find.byType(ClipPath)).first,
    );
    final shape = (clip.clipper! as ShapeBorderClipper).shape;
    expect(shape, isA<MiuixSquircleBorder>());
    expect((shape as MiuixSquircleBorder).side, BorderSide.none);
    expect(
      tester
          .widget<EditableText>(
            find.byKey(const ValueKey('miuix-search-bar-input')),
          )
          .style
          .fontSize,
      17,
    );

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'miuix',
    );
    await tester.pump();
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-trailing-slot'))),
      const Size(44, 44),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-bar-clear'))),
      const Size(20, 20),
    );
    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-clear')));
    await tester.pump();

    expect(firstController.text, isEmpty);
    expect(changes, containsAll(['miuix', '']));

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(body: MiuixSearchBar(controller: secondController)),
        ),
      ),
    );
    await tester.pump();

    expect(secondController.text, 'swap');
    expect(tester.takeException(), isNull);
  });

  testWidgets('search collapse never clears a replacement controller', (
    tester,
  ) async {
    final firstController = TextEditingController(text: 'old query');
    final secondController = TextEditingController(text: 'new query');
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    var controller = firstController;
    var expanded = true;
    late StateSetter rebuildHost;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuildHost = setState;
                return MiuixSearchBar(
                  controller: controller,
                  expanded: expanded,
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    rebuildHost(() {
      controller = secondController;
      expanded = false;
    });
    await tester.pump();
    await tester.pump();

    expect(firstController.text, 'old query');
    expect(secondController.text, 'new query');
    expect(tester.takeException(), isNull);
  });

  testWidgets('search glass follows the smooth capsule switch', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    Future<void> pumpSearch({required bool enableSquircle}) {
      return tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              enableSquircle: enableSquircle,
            ),
            child: Scaffold(body: MiuixSearchBar(controller: controller)),
          ),
        ),
      );
    }

    ShapeBorder currentShape() {
      final surface = find.byKey(const ValueKey('miuix-search-bar-container'));
      final clip = tester.widget<ClipPath>(
        find.descendant(of: surface, matching: find.byType(ClipPath)).first,
      );
      return (clip.clipper! as ShapeBorderClipper).shape;
    }

    await pumpSearch(enableSquircle: true);
    expect(currentShape(), isA<MiuixSquircleBorder>());

    await pumpSearch(enableSquircle: false);
    expect(currentShape(), isA<RoundedRectangleBorder>());
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar expands source action and result slots', (
    tester,
  ) async {
    final controller = TextEditingController();
    var expanded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixSearchBar(
                controller: controller,
                expanded: expanded,
                onExpandedChanged: (value) {
                  setState(() => expanded = value);
                },
                outsideEndAction: GestureDetector(
                  key: const ValueKey('source-search-cancel'),
                  onTap: () => setState(() => expanded = false),
                  child: const Text('Cancel'),
                ),
                expandedContent: const Text(
                  'Suggestion',
                  key: ValueKey('source-search-result'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('source-search-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-result')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-input')));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(find.byKey(const ValueKey('source-search-cancel')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-result')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'query',
    );
    await tester.tap(find.byKey(const ValueKey('source-search-cancel')));
    await tester.pumpAndSettle();
    expect(expanded, isFalse);
    expect(controller.text, isEmpty);
    expect(find.byKey(const ValueKey('source-search-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-result')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar inserted already expanded requests input focus', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: MiuixSearchBar(
              controller: controller,
              expanded: true,
              onExpandedChanged: (_) {},
              outsideEndAction: const Text('取消'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final editable = tester.widget<EditableText>(
      find.byKey(const ValueKey('miuix-search-bar-input')),
    );
    expect(editable.focusNode.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar stays safe under very narrow constraints', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'narrow');
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              width: 44,
              child: MiuixSearchBar(controller: controller),
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('miuix-search-bar-container')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search bar accepts a bounded legacy app-bar height', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: SizedBox(
              height: 45,
              child: MiuixSearchBar(controller: controller),
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 45);
    final semantics = tester.ensureSemantics();
    expect(
      tester
          .getSemantics(
            find.byKey(const ValueKey('miuix-search-semantic-target')),
          )
          .rect
          .height,
      48,
    );
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('search input exposes HyperOS defaults and legacy metrics', (
    tester,
  ) async {
    var query = '';
    var expanded = false;
    var searched = '';
    final interaction = MiuixInteractionSource();
    addTearDown(interaction.dispose);

    expect(MiuixSearchBarDefaults.insideMargin, const Size(12, 0));
    expect(MiuixSearchBarDefaults.inputFieldMinHeight, 48);
    expect(MiuixSearchBarDefaults.legacyInputFieldMinHeight, 45);
    expect(MiuixSearchBarDefaults.inputFieldFontSize, 17);
    expect(MiuixSearchBarDefaults.leadingIconStartPadding, 16);
    expect(MiuixSearchBarDefaults.leadingIconEndPadding, 8);
    expect(MiuixSearchBarDefaults.trailingIconStartPadding, 8);
    expect(MiuixSearchBarDefaults.trailingIconEndPadding, 16);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixSearchBar.source(
                inputField: MiuixInputField(
                  query: query,
                  onQueryChange: (value) => setState(() => query = value),
                  onSearch: (value) => searched = value,
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  label: '搜索',
                  interactionSource: interaction,
                ),
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
                outsideEndAction: const Text(
                  '取消',
                  key: ValueKey('source-search-action'),
                ),
                content: const Text(
                  '建议',
                  key: ValueKey('source-search-content'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final container = find.byKey(const ValueKey('miuix-search-bar-container'));
    expect(tester.getSize(container).height, 48);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-action')), findsNothing);
    expect(find.byKey(const ValueKey('source-search-content')), findsNothing);
    expect(
      tester.getSize(find.byKey(const ValueKey('miuix-search-leading-slot'))),
      const Size(44, 20),
    );

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-container')));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    expect(interaction.focused, isTrue);
    expect(find.text('搜索'), findsNothing);
    expect(find.byKey(const ValueKey('source-search-action')), findsOneWidget);
    expect(find.byKey(const ValueKey('source-search-content')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('miuix-search-bar-input')),
      'miuix',
    );
    await tester.pumpAndSettle();
    expect(query, 'miuix');
    final trailing = tester.getSize(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
    );
    expect(trailing.width, closeTo(42.199984, .0001));
    expect(trailing.height, closeTo(18.199984, .0001));

    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(searched, 'miuix');

    await tester.tap(find.byKey(const ValueKey('miuix-search-bar-clear')));
    await tester.pumpAndSettle();
    expect(query, isEmpty);
    expect(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('source search collapse delays fade cleanup and focus release', (
    tester,
  ) async {
    var query = 'query';
    var expanded = true;

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixInputField(
                query: query,
                onQueryChange: (value) => setState(() => query = value),
                onSearch: (_) {},
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final editableFinder = find.byKey(const ValueKey('miuix-search-bar-input'));
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );

    expanded = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => MiuixInputField(
                query: query,
                onQueryChange: (value) => setState(() => query = value),
                onSearch: (_) {},
                expanded: expanded,
                onExpandedChange: (value) {
                  setState(() => expanded = value);
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 99));
    expect(query, 'query');
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(query, isEmpty);
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('search reduced motion snaps visibility and collapse cleanup', (
    tester,
  ) async {
    var query = 'query';
    var expanded = true;
    late StateSetter updateSearch;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
        home: MiuixTheme(
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateSearch = setState;
                return MiuixSearchBar.source(
                  inputField: MiuixInputField(
                    query: query,
                    onQueryChange: (value) => setState(() => query = value),
                    onSearch: (_) {},
                    expanded: expanded,
                    onExpandedChange: (value) {
                      setState(() => expanded = value);
                    },
                  ),
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  outsideEndAction: const Text(
                    '立即取消',
                    key: ValueKey('reduced-search-action'),
                  ),
                  content: const Text(
                    '立即结果',
                    key: ValueKey('reduced-search-content'),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final editableFinder = find.byKey(const ValueKey('miuix-search-bar-input'));
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      true,
    );
    expect(find.byKey(const ValueKey('reduced-search-action')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('reduced-search-content')),
      findsOneWidget,
    );

    updateSearch(() => expanded = false);
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(query, isEmpty);
    expect(
      tester.widget<EditableText>(editableFinder).focusNode.hasFocus,
      false,
    );
    expect(find.byKey(const ValueKey('reduced-search-action')), findsNothing);
    expect(find.byKey(const ValueKey('reduced-search-content')), findsNothing);
    expect(
      find.byKey(const ValueKey('miuix-search-trailing-slot')),
      findsNothing,
    );

    // Re-expansion after an interrupted collapse restores text opacity to its
    // visible endpoint instead of allowing the old fade to keep running.
    updateSearch(() {
      query = 'restored';
      expanded = true;
    });
    await tester.pump();
    await tester.pump();
    final fade = tester.widget<FadeTransition>(
      find
          .descendant(
            of: find.byType(MiuixInputField),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    expect(fade.opacity.value, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling reduced motion settles active search expansion', (
    tester,
  ) async {
    var expanded = false;
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
              child: Scaffold(
                body: MiuixSearchBar.source(
                  inputField: MiuixInputField(
                    query: '',
                    onQueryChange: (_) {},
                    onSearch: (_) {},
                    expanded: expanded,
                    onExpandedChange: (value) {
                      setState(() => expanded = value);
                    },
                  ),
                  expanded: expanded,
                  onExpandedChange: (value) {
                    setState(() => expanded = value);
                  },
                  outsideEndAction: const Text(
                    '动态取消',
                    key: ValueKey('moving-search-action'),
                  ),
                  content: const SizedBox(
                    key: ValueKey('moving-search-content'),
                    height: 120,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    updateHost(() => expanded = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    Align actionReveal() => tester
        .widgetList<Align>(
          find.ancestor(
            of: find.byKey(const ValueKey('moving-search-action')),
            matching: find.byType(Align),
          ),
        )
        .firstWhere((align) => align.widthFactor != null);
    Align contentReveal() => tester
        .widgetList<Align>(
          find.ancestor(
            of: find.byKey(const ValueKey('moving-search-content')),
            matching: find.byType(Align),
          ),
        )
        .firstWhere((align) => align.heightFactor != null);
    expect(actionReveal().widthFactor!, inExclusiveRange(0, 1));
    expect(contentReveal().heightFactor!, inExclusiveRange(0, 1));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(actionReveal().widthFactor, 1);
    expect(contentReveal().heightFactor, 1);
    expect(tester.takeException(), isNull);
  });
}
