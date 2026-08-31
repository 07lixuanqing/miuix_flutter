import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpCollectionExtension(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(600, 800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MiuixTheme(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('chip variants toggle, announce, and delete independently', (
    tester,
  ) async {
    var selected = false;
    var deleted = false;
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: MiuixChip(
            label: 'Filter',
            variant: MiuixChipVariant.filter,
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
            onDeleted: () => deleted = true,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    expect(
      find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsNothing);

    await tester.tap(find.byIcon(Icons.close));
    expect(deleted, isTrue);
  });

  testWidgets('chip selection tint retargets continuously without entry fade', (
    tester,
  ) async {
    var selected = false;
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Center(
          child: MiuixChip(
            label: 'Filter',
            variant: MiuixChipVariant.filter,
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );

    final chipGlass = find.descendant(
      of: find.byType(MiuixChip),
      matching: find.byType(MiuixGlass),
    );
    final initial = tester.widget<MiuixGlass>(chipGlass).color;
    expect(initial, isNotNull);
    await tester.tap(find.text('Filter'));
    await tester.pump();
    expect(
      tester.widget<MiuixGlass>(chipGlass).color,
      initial,
      reason: 'the transition starts at the currently painted idle color',
    );
    await tester.pump(const Duration(milliseconds: 140));
    final midpoint = tester.widget<MiuixGlass>(chipGlass).color;
    expect(midpoint, isNot(initial));
    await tester.pumpAndSettle();
    final settled = tester.widget<MiuixGlass>(chipGlass).color;
    expect(settled, isNot(initial));
    expect(midpoint, isNot(settled));
  });

  testWidgets('tag input reduced motion snaps focus and rejection outline', (
    tester,
  ) async {
    final controller = MiuixTagInputController();
    final textController = TextEditingController();
    final focusNode = FocusNode();
    var reduceMotion = false;
    late StateSetter updateHost;
    addTearDown(controller.dispose);
    addTearDown(textController.dispose);
    addTearDown(focusNode.dispose);
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          updateHost = setState;
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: reduceMotion),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  inputStateMotion: Duration(milliseconds: 777),
                ),
              ),
              child: MiuixTagInput(
                controller: controller,
                textController: textController,
                focusNode: focusNode,
                maximumTagLength: 3,
              ),
            ),
          );
        },
      ),
    );

    final colorMotionFinder = find.descendant(
      of: find.byType(MiuixTagInput),
      matching: find.byType(TweenAnimationBuilder<Color?>),
    );
    final surfaceFinder = find.byKey(const ValueKey('miuix-tag-input-surface'));
    expect(colorMotionFinder, findsOneWidget);
    expect(surfaceFinder, findsOneWidget);
    expect(
      tester.widget<TweenAnimationBuilder<Color?>>(colorMotionFinder).duration,
      const Duration(milliseconds: 777),
    );
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(
      tester.widget<TweenAnimationBuilder<Color?>>(colorMotionFinder).duration,
      Duration.zero,
    );
    await tester.enterText(find.byType(TextField), 'long');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('标签过长'), findsOneWidget);
    final surface = tester.widget<MiuixSurface>(surfaceFinder);
    expect(surface.border?.width, 2);
    expect(surface.glass, isTrue);
    expect(controller.tags, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tag input uses editable geometry and content glass tokens', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            textFieldCornerRadius: 27,
            contentSurfaceBlur: 33,
            contentSurfaceTintOpacity: .41,
          ),
        ),
        child: const MiuixTagInput(initialTags: <String>['design']),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-tag-input-surface')),
    );
    expect(surface.radius, 27);
    expect(surface.glass, isTrue);
    expect(surface.glassBlur, 33);
    expect(surface.glassOpacity, .41);
    expect(find.byType(MiuixGlass), findsOneWidget);
  });

  testWidgets('tag input source keeps the opaque 18dp compatibility path', (
    tester,
  ) async {
    await pumpCollectionExtension(tester, const MiuixTagInput.source());

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-tag-input-surface')),
    );
    expect(surface.radius, 18);
    expect(surface.glass, isFalse);
    expect(find.byType(MiuixGlass), findsNothing);
  });

  testWidgets('tag input normalizes invalid limits and empty separators', (
    tester,
  ) async {
    final controller = MiuixTagInputController();
    final rejected = <String>[];
    addTearDown(controller.dispose);
    await pumpCollectionExtension(
      tester,
      MiuixTagInput(
        controller: controller,
        maximumTags: 0,
        maximumTagLength: 0,
        separators: const <String>['', ','],
        onRejected: rejected.add,
      ),
    );

    await tester.enterText(find.byType(TextField), 'AB');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.tags, isEmpty);
    expect(rejected, <String>['AB']);

    await tester.enterText(find.byType(TextField), 'A');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.tags, <String>['A']);

    await tester.enterText(find.byType(TextField), 'B,');
    await tester.pump();
    expect(controller.tags, <String>['A']);
    expect(rejected, <String>['AB', 'B']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tag input waits for IME composition before parsing separators', (
    tester,
  ) async {
    final controller = MiuixTagInputController();
    final textController = TextEditingController();
    addTearDown(controller.dispose);
    addTearDown(textController.dispose);
    await pumpCollectionExtension(
      tester,
      MiuixTagInput(controller: controller, textController: textController),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '候,选',
        selection: TextSelection.collapsed(offset: 3),
        composing: TextRange(start: 0, end: 3),
      ),
    );
    await tester.pump();
    expect(controller.tags, isEmpty);
    expect(textController.text, '候,选');

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '候,选',
        selection: TextSelection.collapsed(offset: 3),
      ),
    );
    await tester.pump();
    expect(controller.tags, <String>['候']);
    expect(textController.text, '选');
  });

  testWidgets('tag input keeps rejected pasted pieces editable', (
    tester,
  ) async {
    final controller = MiuixTagInputController();
    final textController = TextEditingController();
    final rejected = <String>[];
    addTearDown(controller.dispose);
    addTearDown(textController.dispose);
    await pumpCollectionExtension(
      tester,
      MiuixTagInput(
        controller: controller,
        textController: textController,
        separators: const <String>[','],
        validateTag: (tag) => tag != 'bad',
        onRejected: rejected.add,
      ),
    );

    await tester.enterText(find.byType(TextField), 'good,bad,tail');
    await tester.pump();
    expect(controller.tags, <String>['good']);
    expect(rejected, <String>['bad']);
    expect(textController.text, 'bad,tail');
    expect(textController.selection, const TextSelection.collapsed(offset: 8));
  });

  testWidgets('reorderable list reports adjusted order through drag handles', (
    tester,
  ) async {
    final items = <String>['A', 'B', 'C'];
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MiuixReorderableList<String>(
          items: items,
          itemKey: ValueKey<String>.new,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final item = items.removeAt(oldIndex);
              items.insert(newIndex, item);
            });
          },
          itemBuilder: (context, item, index) =>
              MiuixReorderableItem(index: index, child: Text(item)),
        ),
      ),
    );

    final reorderable = tester.widget<ReorderableListView>(
      find.byType(ReorderableListView),
    );
    expect(reorderable.padding, EdgeInsets.zero);
    expect(reorderable.primary, isFalse);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(MiuixDragHandle).first),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 140));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(items.first, isNot('A'));
  });

  testWidgets('reorder handles support keyboard movement by stable item key', (
    tester,
  ) async {
    final items = <String>['A', 'B', 'C'];
    final starts = <int>[];
    final ends = <int>[];
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) => MiuixReorderableList<String>(
          items: items,
          itemKey: ValueKey<String>.new,
          onReorderStart: starts.add,
          onReorderEnd: ends.add,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              final destination = newIndex > oldIndex ? newIndex - 1 : newIndex;
              final item = items.removeAt(oldIndex);
              items.insert(destination, item);
            });
          },
          itemBuilder: (context, item, index) =>
              MiuixReorderableItem(index: index, child: Text('Keyboard $item')),
        ),
      ),
    );

    await tester.tap(find.byType(MiuixDragHandle).at(1));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(items, <String>['A', 'C', 'B']);
    expect(starts, <int>[1]);
    expect(ends, <int>[2]);

    // The keyed handle keeps focus while its item moves, and cannot move past
    // the collection boundary.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(items, <String>['A', 'C', 'B']);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(items, <String>['A', 'B', 'C']);
    expect(starts, <int>[1, 2]);
    expect(ends, <int>[2, 1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reorder handle rejects invalid index and releases disabled focus',
    (tester) async {
      var enabled = true;
      var index = 0;
      var moves = 0;
      late StateSetter rebuildHost;
      await pumpCollectionExtension(
        tester,
        StatefulBuilder(
          builder: (context, setState) {
            rebuildHost = setState;
            return MiuixDragHandle(
              index: index,
              enabled: enabled,
              delayed: false,
              onMoveDown: () => moves++,
            );
          },
        ),
      );

      final handleFocus = find.descendant(
        of: find.byType(MiuixDragHandle),
        matching: find.byType(Focus),
      );
      expect(find.byType(ReorderableDragStartListener), findsOneWidget);
      var focus = tester.widget<Focus>(handleFocus);
      expect(focus.canRequestFocus, isTrue);
      await tester.tap(find.byType(MiuixDragHandle));
      await tester.pump();
      focus = tester.widget<Focus>(handleFocus);
      expect(focus.focusNode!.hasFocus, isTrue);

      // A valid standalone handle can focus, but disabling it must revoke that
      // focus and all keyboard movement immediately.
      rebuildHost(() => enabled = false);
      await tester.pump();
      focus = tester.widget<Focus>(handleFocus);
      expect(focus.canRequestFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(moves, 0);

      rebuildHost(() {
        enabled = true;
        index = -1;
      });
      await tester.pump();
      expect(find.byType(ReorderableDragStartListener), findsNothing);
      expect(tester.widget<Focus>(handleFocus).canRequestFocus, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reorder proxy settles lift and uses collection shape', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      MiuixReorderableList<String>(
        items: const <String>['A'],
        itemKey: ValueKey<String>.new,
        itemBuilder: (context, item, index) => Text(item),
        onReorder: (oldIndex, newIndex) {},
      ),
    );
    final decorator = tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .proxyDecorator!;
    final proxy = decorator(
      const SizedBox(width: 100, height: 52),
      0,
      const AlwaysStoppedAnimation<double>(.25),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                collectionRowCornerRadius: 23,
              ),
            ),
            child: proxy,
          ),
        ),
      ),
    );
    await tester.pump();

    final lift = tester.widget<Transform>(find.byType(Transform));
    expect(lift.transform.getMaxScaleOnAxis(), closeTo(1.015, 1e-9));
    final material = tester.widget<Material>(find.byType(Material));
    expect(material.elevation, MiuixReorderableListDefaults.proxyElevation);
    expect(material.borderRadius, BorderRadius.circular(23));
  });

  testWidgets('reorder source list keeps the former proxy shape', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      MiuixReorderableList<String>.source(
        items: const <String>['A'],
        itemKey: ValueKey<String>.new,
        itemBuilder: (context, item, index) => Text(item),
        onReorder: (oldIndex, newIndex) {},
      ),
    );
    final decorator = tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .proxyDecorator!;
    final proxy = decorator(
      const SizedBox(width: 100, height: 52),
      0,
      const AlwaysStoppedAnimation<double>(1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 27),
          ),
          child: proxy,
        ),
      ),
    );
    await tester.pump();

    final material = tester.widget<Material>(find.byType(Material));
    expect(
      material.borderRadius,
      BorderRadius.circular(MiuixReorderableListDefaults.proxyRadius),
    );
  });

  testWidgets('reorderable item shares collection geometry with its proxy', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 25),
        ),
        child: const MiuixReorderableItem(
          showHandle: false,
          child: Text('Theme row'),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-reorderable-item-surface')),
    );
    expect(surface.radius, 25);
  });

  testWidgets('reorderable source item keeps the former 18dp geometry', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 25),
        ),
        child: const MiuixReorderableItem.source(
          showHandle: false,
          child: Text('Source row'),
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-reorderable-item-surface')),
    );
    expect(surface.radius, MiuixReorderableListDefaults.proxyRadius);
  });

  testWidgets('tree rows separate collection tokens and source geometry', (
    tester,
  ) async {
    const nodes = <MiuixTreeNode<String>>[
      MiuixTreeNode<String>(value: 'root', label: 'Root'),
    ];
    await pumpCollectionExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 26),
        ),
        child: const MiuixTreeView<String>(nodes: nodes),
      ),
    );
    var surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<Object>(('miuix-tree-row', 'root'))),
    );
    expect(surface.radius, 26);

    await pumpCollectionExtension(
      tester,
      const MiuixTreeView<String>.source(nodes: nodes),
    );
    surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<Object>(('miuix-tree-row', 'root'))),
    );
    expect(surface.radius, MiuixTreeViewDefaults.cornerRadius);
  });

  testWidgets('tree normalizes invalid public row geometry', (tester) async {
    final controller = MiuixTreeController<String>(
      expanded: const <String>['root'],
    );
    addTearDown(controller.dispose);
    await pumpCollectionExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(collectionRowCornerRadius: 22),
        ),
        child: MiuixTreeView<String>(
          controller: controller,
          indentation: double.nan,
          rowCornerRadius: double.infinity,
          nodes: const <MiuixTreeNode<String>>[
            MiuixTreeNode<String>(
              value: 'root',
              label: 'Safe root',
              children: <MiuixTreeNode<String>>[
                MiuixTreeNode<String>(value: 'child', label: 'Safe child'),
              ],
            ),
          ],
        ),
      ),
    );

    final childSurface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<Object>(('miuix-tree-row', 'child'))),
    );
    final childPadding = tester.widget<Padding>(
      find
          .ancestor(of: find.text('Safe child'), matching: find.byType(Padding))
          .last,
    );
    expect(childSurface.radius, 22);
    expect(
      childPadding.padding,
      const EdgeInsetsDirectional.only(start: 24, top: 2, bottom: 2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree expands eager nodes and selects a child', (tester) async {
    final controller = MiuixTreeController<String>();
    await pumpCollectionExtension(
      tester,
      MiuixTreeView<String>(
        controller: controller,
        nodes: const <MiuixTreeNode<String>>[
          MiuixTreeNode<String>(
            value: 'root',
            label: 'Root',
            children: <MiuixTreeNode<String>>[
              MiuixTreeNode<String>(value: 'child', label: 'Child'),
            ],
          ),
        ],
      ),
    );

    expect(find.text('Child'), findsNothing);
    final forward = MiuixExtendedIconCatalog.find('ChevronForward')!.regular;
    await tester.tap(find.byIcon(forward));
    await tester.pumpAndSettle();
    expect(find.text('Child'), findsOneWidget);
    await tester.tap(find.text('Child'));
    await tester.pump();
    expect(controller.selected, 'child');
  });

  testWidgets('tree branch motion is continuous and reduced motion settles', (
    tester,
  ) async {
    final controller = MiuixTreeController<String>();
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(controller.dispose);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, reduced, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  treeExpansionMotion: Duration(milliseconds: 777),
                ),
              ),
              child: MiuixTreeView<String>(
                controller: controller,
                nodes: const <MiuixTreeNode<String>>[
                  MiuixTreeNode<String>(
                    value: 'root',
                    label: 'Animated root',
                    children: <MiuixTreeNode<String>>[
                      MiuixTreeNode<String>(
                        value: 'child',
                        label: 'Animated child',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Finder disclosure() => find
        .descendant(
          of: find.byType(MiuixTreeView<String>),
          matching: find.byType(MiuixIconButton),
        )
        .first;
    expect(find.text('Animated child'), findsNothing);
    await tester.tap(disclosure());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final transition = find.ancestor(
      of: find.text('Animated child'),
      matching: find.byType(SizeTransition),
    );
    expect(transition, findsOneWidget);
    expect(tester.getSize(transition).height, inExclusiveRange(0, 52));

    reduceMotion.value = true;
    await tester.pump();
    expect(tester.getSize(transition).height, 52);
    await tester.tap(disclosure());
    await tester.pump();
    expect(find.text('Animated child'), findsNothing);
  });

  testWidgets('tree selection uses collection tokens and reduced endpoint', (
    tester,
  ) async {
    final controller = MiuixTreeController<String>(expanded: const ['root']);
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(controller.dispose);
    addTearDown(reduceMotion.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, reduced, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: MiuixTheme(
              data: MiuixThemeData.defaults().copyWith(
                hyperOs4: const MiuixHyperOs4Tokens(
                  collectionRowMotion: Duration(milliseconds: 777),
                  collectionRowCornerRadius: 23,
                ),
              ),
              child: MiuixTreeView<String>(
                controller: controller,
                nodes: const <MiuixTreeNode<String>>[
                  MiuixTreeNode<String>(
                    value: 'root',
                    label: 'Token root',
                    children: <MiuixTreeNode<String>>[
                      MiuixTreeNode<String>(
                        value: 'child',
                        label: 'Token child',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Finder childRowAnimation() => find.ancestor(
      of: find.text('Token child'),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    MiuixSurface childSurface() => tester.widget<MiuixSurface>(
      find.ancestor(
        of: find.text('Token child'),
        matching: find.byType(MiuixSurface),
      ),
    );

    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(childRowAnimation())
          .duration,
      const Duration(milliseconds: 777),
    );
    expect(childSurface().radius, 23);
    expect(childSurface().color, Colors.transparent);

    await tester.tap(find.text('Token child'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = childSurface().color!;
    expect(intermediate, isNot(Colors.transparent));

    reduceMotion.value = true;
    await tester.pump();
    final reducedAnimation = tester.widget<TweenAnimationBuilder<double>>(
      childRowAnimation(),
    );
    expect(reducedAnimation.duration, Duration.zero);
    expect(childSurface().color, isNot(intermediate));
    expect(controller.selected, 'child');
  });

  testWidgets('nested tree does not inherit route safe-area padding', (
    tester,
  ) async {
    await pumpCollectionExtension(
      tester,
      const MediaQuery(
        data: MediaQueryData(padding: EdgeInsets.only(top: 80, bottom: 60)),
        child: MiuixTreeView<String>(
          nodes: <MiuixTreeNode<String>>[
            MiuixTreeNode<String>(value: 'root', label: 'Root'),
          ],
        ),
      ),
    );

    // One row is 48dp high with 2dp separation on both vertical edges.
    expect(tester.getSize(find.byType(MiuixTreeView<String>)).height, 52);
  });

  testWidgets('tree loads asynchronous children only on first expansion', (
    tester,
  ) async {
    var loads = 0;
    await pumpCollectionExtension(
      tester,
      MiuixTreeView<String>(
        nodes: <MiuixTreeNode<String>>[
          MiuixTreeNode<String>(
            value: 'lazy',
            label: 'Lazy',
            childrenLoader: () async {
              loads++;
              return const <MiuixTreeNode<String>>[
                MiuixTreeNode<String>(value: 'loaded', label: 'Loaded'),
              ];
            },
          ),
        ],
      ),
    );

    final forward = MiuixExtendedIconCatalog.find('ChevronForward')!.regular;
    await tester.tap(find.byIcon(forward));
    await tester.pumpAndSettle();
    expect(find.text('Loaded'), findsOneWidget);
    expect(loads, 1);
  });

  testWidgets('tree discards a late loader result from a replaced node', (
    tester,
  ) async {
    final first = Completer<List<MiuixTreeNode<String>>>();
    final second = Completer<List<MiuixTreeNode<String>>>();
    final controller = MiuixTreeController<String>();
    addTearDown(controller.dispose);
    var useSecond = false;
    late StateSetter rebuildHost;
    Future<List<MiuixTreeNode<String>>> firstLoader() => first.future;
    Future<List<MiuixTreeNode<String>>> secondLoader() => second.future;

    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixTreeView<String>(
            controller: controller,
            nodes: <MiuixTreeNode<String>>[
              MiuixTreeNode<String>(
                value: 'root',
                label: 'Replaceable root',
                childrenLoader: useSecond ? secondLoader : firstLoader,
              ),
            ],
          );
        },
      ),
    );

    final forward = MiuixExtendedIconCatalog.find('ChevronForward')!.regular;
    await tester.tap(find.byIcon(forward));
    await tester.pump();
    rebuildHost(() => useSecond = true);
    await tester.pump();

    first.complete(const <MiuixTreeNode<String>>[
      MiuixTreeNode<String>(value: 'stale', label: 'Stale child'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Stale child'), findsNothing);
    expect(controller.isExpanded('root'), isFalse);

    await tester.tap(find.byIcon(forward));
    await tester.pump();
    second.complete(const <MiuixTreeNode<String>>[
      MiuixTreeNode<String>(value: 'fresh', label: 'Fresh child'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Fresh child'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree replaces a completed loader cache with the new source', (
    tester,
  ) async {
    var useSecond = false;
    var firstLoads = 0;
    var secondLoads = 0;
    late StateSetter rebuildHost;
    Future<List<MiuixTreeNode<String>>> firstLoader() async {
      firstLoads++;
      return const <MiuixTreeNode<String>>[
        MiuixTreeNode<String>(value: 'old', label: 'Old cached child'),
      ];
    }

    Future<List<MiuixTreeNode<String>>> secondLoader() async {
      secondLoads++;
      return const <MiuixTreeNode<String>>[
        MiuixTreeNode<String>(value: 'new', label: 'New loaded child'),
      ];
    }

    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixTreeView<String>(
            nodes: <MiuixTreeNode<String>>[
              MiuixTreeNode<String>(
                value: 'root',
                label: 'Reloadable root',
                childrenLoader: useSecond ? secondLoader : firstLoader,
              ),
            ],
          );
        },
      ),
    );

    final disclosure = find.byType(MiuixIconButton);
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(find.text('Old cached child'), findsOneWidget);
    await tester.tap(disclosure.first);
    await tester.pumpAndSettle();

    rebuildHost(() => useSecond = true);
    await tester.pump();
    await tester.tap(disclosure);
    await tester.pumpAndSettle();
    expect(find.text('Old cached child'), findsNothing);
    expect(find.text('New loaded child'), findsOneWidget);
    expect(firstLoads, 1);
    expect(secondLoads, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree keyboard skips disabled rows and reports collapse', (
    tester,
  ) async {
    final controller = MiuixTreeController<String>(
      expanded: const <String>['branch'],
    );
    final expansions = <bool>[];
    addTearDown(controller.dispose);
    await pumpCollectionExtension(
      tester,
      MiuixTreeView<String>(
        controller: controller,
        onExpansionChanged: (value, expanded) => expansions.add(expanded),
        nodes: const <MiuixTreeNode<String>>[
          MiuixTreeNode<String>(
            value: 'disabled',
            label: 'Disabled row',
            enabled: false,
            children: <MiuixTreeNode<String>>[
              MiuixTreeNode<String>(value: 'hidden', label: 'Hidden child'),
            ],
          ),
          MiuixTreeNode<String>(
            value: 'branch',
            label: 'Enabled branch',
            children: <MiuixTreeNode<String>>[
              MiuixTreeNode<String>(value: 'child', label: 'Enabled child'),
            ],
          ),
          MiuixTreeNode<String>(value: 'last', label: 'Last enabled row'),
        ],
      ),
    );

    await tester.tap(find.text('Enabled branch'));
    await tester.pump();
    controller.selected = null;
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(controller.selected, 'branch');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(controller.isExpanded('branch'), isFalse);
    expect(expansions, <bool>[false]);

    final disabledDisclosure = find.descendant(
      of: find.byKey(const ValueKey<Object>(('miuix-tree-row', 'disabled'))),
      matching: find.byType(MiuixIconButton),
    );
    expect(
      tester.widget<MiuixIconButton>(disabledDisclosure).onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('combo box filters options and returns typed selection', (
    tester,
  ) async {
    final controller = MiuixSearchableSelectController<int>();
    await pumpCollectionExtension(
      tester,
      Center(
        child: SizedBox(
          width: 400,
          child: MiuixComboBox<int>(
            controller: controller,
            label: 'City',
            options: const <MiuixSearchableSelectOption<int>>[
              MiuixSearchableSelectOption<int>(value: 1, label: 'Beijing'),
              MiuixSearchableSelectOption<int>(value: 2, label: 'Shanghai'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    final optionsList = tester.widget<ListView>(find.byType(ListView));
    expect(optionsList.padding, EdgeInsets.zero);
    expect(optionsList.primary, isFalse);
    await tester.enterText(find.byType(MiuixTextField), 'Shang');
    await tester.pump();
    expect(find.text('Beijing'), findsNothing);
    await tester.tap(find.text('Shanghai'));
    await tester.pumpAndSettle();
    expect(controller.value, 2);
  });

  testWidgets(
    'combo box keyboard skips disabled rows and restores trigger focus',
    (tester) async {
      final controller = MiuixSearchableSelectController<String>();
      final triggerFocus = FocusNode(debugLabel: 'combo-trigger-owner');
      addTearDown(controller.dispose);
      addTearDown(triggerFocus.dispose);
      await pumpCollectionExtension(
        tester,
        Focus(
          focusNode: triggerFocus,
          autofocus: true,
          child: Center(
            child: SizedBox(
              width: 400,
              child: MiuixComboBox<String>(
                controller: controller,
                options: const <MiuixSearchableSelectOption<String>>[
                  MiuixSearchableSelectOption<String>(
                    value: 'disabled',
                    label: 'Disabled',
                    enabled: false,
                  ),
                  MiuixSearchableSelectOption<String>(
                    value: 'beta',
                    label: 'Beta',
                  ),
                  MiuixSearchableSelectOption<String>(
                    value: 'gamma',
                    label: 'Gamma',
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(triggerFocus.hasFocus, isTrue);
      await tester.tap(find.text('请选择'));
      await tester.pumpAndSettle();
      final searchField = tester.widget<EditableText>(
        find.byType(EditableText),
      );
      expect(searchField.focusNode.hasFocus, isTrue);

      // The first enabled row is highlighted when the dialog opens, so Enter
      // must never activate the disabled row that precedes it.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.value, 'beta');
      expect(triggerFocus.hasFocus, isTrue);

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(MiuixTextField), 'Gam');
      await tester.pumpAndSettle();
      expect(
        find.descendant(of: find.byType(ListView), matching: find.text('Beta')),
        findsNothing,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.value, 'gamma');
      expect(triggerFocus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('searchable multi-select normalizes an invalid maximum', (
    tester,
  ) async {
    final controller = MiuixSearchableSelectController<String>();
    addTearDown(controller.dispose);
    await pumpCollectionExtension(
      tester,
      Center(
        child: SizedBox(
          width: 400,
          child: MiuixSearchableSelect<String>(
            controller: controller,
            multiple: true,
            maximumSelection: 0,
            options: const <MiuixSearchableSelectOption<String>>[
              MiuixSearchableSelectOption<String>(value: 'a', label: 'A'),
              MiuixSearchableSelectOption<String>(value: 'b', label: 'B'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        MaterialLocalizations.of(
          tester.element(find.byType(MiuixDialog)),
        ).okButtonLabel,
      ),
    );
    await tester.pumpAndSettle();

    expect(controller.selected, <String>{'a'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('multi searchable select confirms several values', (
    tester,
  ) async {
    final controller = MiuixSearchableSelectController<String>();
    await pumpCollectionExtension(
      tester,
      Center(
        child: SizedBox(
          width: 400,
          child: MiuixSearchableSelect<String>(
            controller: controller,
            multiple: true,
            options: const <MiuixSearchableSelectOption<String>>[
              MiuixSearchableSelectOption<String>(value: 'a', label: 'A'),
              MiuixSearchableSelectOption<String>(value: 'b', label: 'B'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A'));
    await tester.tap(find.text('B'));
    await tester.tap(
      find.text(
        MaterialLocalizations.of(
          tester.element(find.byType(MiuixDialog)),
        ).okButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.selected, <String>{'a', 'b'});
  });

  testWidgets('searchable select discards a result after controller swap', (
    tester,
  ) async {
    final firstController = MiuixSearchableSelectController<String>();
    final secondController = MiuixSearchableSelectController<String>();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    var controller = firstController;
    late StateSetter rebuildHost;
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return Center(
            child: SizedBox(
              width: 400,
              child: MiuixSearchableSelect<String>(
                controller: controller,
                options: const <MiuixSearchableSelectOption<String>>[
                  MiuixSearchableSelectOption<String>(
                    value: 'one',
                    label: 'One',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    rebuildHost(() => controller = secondController);
    await tester.pump();
    await tester.tap(find.text('One'));
    await tester.pumpAndSettle();

    expect(firstController.selected, isEmpty);
    expect(secondController.selected, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searchable select reconciles live options and selection shape', (
    tester,
  ) async {
    final controller = MiuixSearchableSelectController<String>(
      selected: <String>['stale', 'b', 'c'],
    );
    final published = <Set<String>>[];
    late StateSetter rebuild;
    var multiple = true;
    int? maximum = 2;
    var options = const <MiuixSearchableSelectOption<String>>[
      MiuixSearchableSelectOption<String>(value: 'a', label: 'A'),
      MiuixSearchableSelectOption<String>(value: 'b', label: 'B'),
      MiuixSearchableSelectOption<String>(value: 'c', label: 'C'),
    ];
    addTearDown(controller.dispose);
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return SizedBox(
            width: 400,
            child: MiuixSearchableSelect<String>(
              controller: controller,
              options: options,
              multiple: multiple,
              maximumSelection: maximum,
              onChanged: published.add,
              glass: false,
            ),
          );
        },
      ),
    );

    expect(controller.selected, <String>{'b', 'c'});
    expect(published, isEmpty);
    rebuild(() {
      options = const <MiuixSearchableSelectOption<String>>[
        MiuixSearchableSelectOption<String>(value: 'a', label: 'A'),
        MiuixSearchableSelectOption<String>(value: 'c', label: 'C'),
      ];
    });
    await tester.pump();
    expect(controller.selected, <String>{'c'});
    expect(published, isEmpty);

    controller.setSelected(<String>['missing', 'a', 'c']);
    await tester.pump();
    expect(controller.selected, <String>{'a', 'c'});
    rebuild(() {
      multiple = false;
      maximum = null;
    });
    await tester.pump();
    expect(controller.selected, <String>{'a'});
    expect(find.text('A'), findsOneWidget);
    expect(find.text('C'), findsNothing);
    expect(published, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('searchable and combo fields separate glass and source styles', (
    tester,
  ) async {
    const options = <MiuixSearchableSelectOption<int>>[
      MiuixSearchableSelectOption<int>(value: 1, label: 'One'),
    ];
    Widget field(int presentation) => switch (presentation) {
      0 => const MiuixComboBox<int>(options: options),
      1 => const MiuixSearchableSelect<int>(
        options: options,
        glass: false,
        cornerRadius: 29,
      ),
      2 => const MiuixSearchableSelect<int>.source(options: options),
      _ => const MiuixComboBox<int>.source(options: options),
    };

    Future<void> pumpField(int presentation) => pumpCollectionExtension(
      tester,
      Center(
        child: SizedBox(
          width: 400,
          child: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                contentSurfaceBlur: 35,
                contentSurfaceTintOpacity: .42,
                textFieldCornerRadius: 27,
              ),
            ),
            child: field(presentation),
          ),
        ),
      ),
    );

    await pumpField(0);
    var trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-searchable-select-trigger')),
    );
    expect(trigger.glass, isTrue);
    expect(trigger.glassBlur, 35);
    expect(trigger.glassOpacity, .42);
    expect(trigger.radius, 27);

    await pumpField(1);
    trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-searchable-select-trigger')),
    );
    expect(trigger.glass, isFalse);
    expect(trigger.radius, 29);

    await pumpField(2);
    trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-searchable-select-trigger')),
    );
    expect(trigger.glass, isFalse);
    expect(trigger.radius, 18);
    expect(trigger.showGlassSpecular, isFalse);

    await pumpField(3);
    trigger = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-searchable-select-trigger')),
    );
    expect(trigger.glass, isFalse);
    expect(trigger.radius, 18);
  });

  testWidgets('searchable selection animates panel and row token endpoints', (
    tester,
  ) async {
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(reduceMotion.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(600, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        // Placing this policy above Navigator also lets an already-open route
        // observe a runtime accessibility change instead of only its trigger.
        builder: (context, child) => ValueListenableBuilder<bool>(
          valueListenable: reduceMotion,
          builder: (context, reduced, _) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
            child: child!,
          ),
        ),
        home: MiuixTheme(
          data: MiuixThemeData.defaults().copyWith(
            hyperOs4: const MiuixHyperOs4Tokens(
              selectionSurfaceMotion: Duration(milliseconds: 888),
              collectionRowMotion: Duration(milliseconds: 777),
              collectionRowCornerRadius: 23,
            ),
          ),
          child: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                child: MiuixSearchableSelect<String>(
                  multiple: true,
                  options: <MiuixSearchableSelectOption<String>>[
                    MiuixSearchableSelectOption<String>(
                      value: 'a',
                      label: 'Alpha',
                    ),
                    MiuixSearchableSelectOption<String>(
                      value: 'b',
                      label: 'Beta',
                    ),
                    MiuixSearchableSelectOption<String>(
                      value: 'c',
                      label: 'Gamma',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('请选择'));
    await tester.pumpAndSettle();
    final panelSize = find.byKey(
      const ValueKey('miuix-searchable-select-panel-size'),
    );
    expect(
      tester.widget<AnimatedSize>(panelSize).duration,
      const Duration(milliseconds: 888),
    );
    expect(tester.getSize(panelSize).height, 362);

    // Filtering one of three results shrinks toward 210dp over the dedicated
    // panel channel rather than jumping to its destination in one frame.
    await tester.enterText(find.byType(MiuixTextField), 'Alpha');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getSize(panelSize).height, inExclusiveRange(210, 362));
    await tester.pumpAndSettle();
    expect(tester.getSize(panelSize).height, 210);

    final optionLabel = find.descendant(
      of: find.byType(ListView),
      matching: find.text('Alpha'),
    );
    Finder rowMotion() => find.ancestor(
      of: optionLabel,
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    MiuixSurface rowSurface() => tester.widget<MiuixSurface>(
      find.ancestor(of: optionLabel, matching: find.byType(MiuixSurface)),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(rowMotion()).duration,
      const Duration(milliseconds: 777),
    );
    expect(rowSurface().radius, 23);
    final keyboardHighlight = rowSurface().color!;
    expect(keyboardHighlight, isNot(Colors.transparent));
    expect(keyboardHighlight.a, closeTo(.38, .001));
    await tester.tap(optionLabel);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = rowSurface().color!;
    expect(intermediate, isNot(keyboardHighlight));

    // Runtime reduced motion replaces both in-flight mechanisms and exposes
    // the already selected logical endpoint without another settling frame.
    reduceMotion.value = true;
    await tester.pump();
    expect(panelSize, findsNothing);
    expect(
      tester.widget<TweenAnimationBuilder<double>>(rowMotion()).duration,
      Duration.zero,
    );
    expect(rowSurface().color, isNot(intermediate));
  });

  test(
    'searchable select dialog height fits short lists and caps long ones',
    () {
      expect(
        MiuixSearchableSelectDefaults.dialogHeight(
          optionCount: 3,
          multiple: true,
        ),
        362,
      );
      expect(
        MiuixSearchableSelectDefaults.dialogHeight(
          optionCount: 50,
          multiple: false,
        ),
        MiuixSearchableSelectDefaults.maxDialogHeight,
      );
      expect(
        MiuixSearchableSelectDefaults.dialogHeight(
          optionCount: 0,
          multiple: false,
        ),
        MiuixSearchableSelectDefaults.minDialogHeight,
      );
    },
  );

  testWidgets('tag input commits separators and prevents duplicates', (
    tester,
  ) async {
    final controller = MiuixTagInputController();
    final rejected = <String>[];
    await pumpCollectionExtension(
      tester,
      Padding(
        padding: const EdgeInsets.all(20),
        child: MiuixTagInput(controller: controller, onRejected: rejected.add),
      ),
    );

    await tester.enterText(find.byType(TextField), 'one,two,');
    await tester.pump();
    expect(controller.tags, <String>['one', 'two']);

    await tester.enterText(find.byType(TextField), 'ONE');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(controller.tags, <String>['one', 'two']);
    expect(rejected, <String>['ONE']);
  });

  testWidgets('tag input hot-swaps all caller-owned state channels', (
    tester,
  ) async {
    final firstTags = MiuixTagInputController(tags: const <String>['first']);
    final secondTags = MiuixTagInputController(tags: const <String>['second']);
    final firstText = TextEditingController(text: 'old');
    final secondText = TextEditingController(text: 'new');
    final firstFocus = FocusNode();
    final secondFocus = FocusNode();
    addTearDown(() {
      firstTags.dispose();
      secondTags.dispose();
      firstText.dispose();
      secondText.dispose();
      firstFocus.dispose();
      secondFocus.dispose();
    });

    late StateSetter replace;
    var tags = firstTags;
    var text = firstText;
    var focus = firstFocus;
    await pumpCollectionExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          replace = setState;
          return MiuixTagInput(
            controller: tags,
            textController: text,
            focusNode: focus,
          );
        },
      ),
    );
    expect(find.text('first'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller,
      firstText,
    );

    replace(() {
      tags = secondTags;
      text = secondText;
      focus = secondFocus;
    });
    await tester.pump();
    expect(find.text('first'), findsNothing);
    expect(find.text('second'), findsOneWidget);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller, secondText);
    expect(field.focusNode, secondFocus);

    firstTags.add('detached');
    await tester.pump();
    expect(find.text('detached'), findsNothing);
  });
}
