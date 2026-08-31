import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps one public extension in the package theme at a deterministic size.
Future<void> pumpAdvancedExtension(
  WidgetTester tester,
  Widget child, {
  Size size = const Size(800, 800),
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

Object _advancedRowKey(int item) => item;

int _compareAdvancedRows(int first, int second) => first.compareTo(second);

Widget _advancedRowCell(BuildContext context, int item) => Text('Row $item');

Future<List<MiuixDroppedFile>> _emptyDroppedFiles() async =>
    const <MiuixDroppedFile>[];

void main() {
  testWidgets('process stepper hoists selection and expands current content', (
    tester,
  ) async {
    final controller = MiuixProcessStepperController();
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            processStateMotion: Duration(milliseconds: 888),
            inlineSurfaceCornerRadius: 26,
            inlineSurfaceBlur: 31,
            inlineSurfaceTintOpacity: .41,
          ),
        ),
        child: MiuixProcessStepper(
          controller: controller,
          showDefaultActions: false,
          steps: const <MiuixProcessStep>[
            MiuixProcessStep(title: 'Account', content: Text('Account body')),
            MiuixProcessStep(title: 'Profile', content: Text('Profile body')),
          ],
        ),
      ),
    );

    expect(find.text('Account body'), findsOneWidget);
    expect(find.text('Profile body'), findsNothing);
    expect(
      tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MiuixProcessStepper),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .every(
            (surface) => surface.duration == const Duration(milliseconds: 888),
          ),
      isTrue,
    );
    expect(
      tester.widget<AnimatedSize>(find.byType(AnimatedSize).first).duration,
      const Duration(milliseconds: 888),
    );
    final selectedSurface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<String>('miuix-process-step-0')),
    );
    expect(selectedSurface.radius, 26);
    expect(selectedSurface.glass, isTrue);
    expect(selectedSurface.glassBlur, 31);
    expect(selectedSurface.glassOpacity, .41);
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(controller.currentStep, 1);
    expect(find.text('Profile body'), findsOneWidget);
  });

  testWidgets('horizontal process stepper animates content and keeps actions', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            inlineSurfaceCornerRadius: 29,
            processStateMotion: Duration(milliseconds: 666),
          ),
        ),
        child: MiuixProcessStepper(
          orientation: MiuixProcessStepperOrientation.horizontal,
          onContinue: () {},
          steps: const <MiuixProcessStep>[
            MiuixProcessStep(title: 'Install', content: Text('Install body')),
            MiuixProcessStep(title: 'Finish', content: Text('Finish body')),
          ],
        ),
      ),
    );

    expect(find.text('Install body'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(
      tester
          .widget<MiuixSurface>(
            find.byKey(const ValueKey<String>('miuix-process-step-0')),
          )
          .radius,
      29,
    );
    expect(
      tester
          .widgetList<AnimatedSize>(find.byType(AnimatedSize))
          .every(
            (animation) =>
                animation.duration == const Duration(milliseconds: 666),
          ),
      isTrue,
    );
    expect(
      tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(MiuixProcessStepper),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .every(
            (animation) =>
                animation.duration == const Duration(milliseconds: 666),
          ),
      isTrue,
    );
  });

  testWidgets('process source retains former opaque 18dp step surfaces', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(inlineSurfaceCornerRadius: 32),
        ),
        child: const MiuixProcessStepper.source(
          showDefaultActions: false,
          steps: <MiuixProcessStep>[MiuixProcessStep(title: 'Source')],
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<String>('miuix-process-step-0')),
    );
    expect(surface.radius, MiuixProcessStepperDefaults.cornerRadius);
    expect(surface.glass, isFalse);
  });

  testWidgets('process stepper reduced motion builds exact content endpoint', (
    tester,
  ) async {
    final controller = MiuixProcessStepperController();
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MiuixProcessStepper(
          controller: controller,
          showDefaultActions: false,
          steps: const <MiuixProcessStep>[
            MiuixProcessStep(title: 'First', content: Text('First body')),
            MiuixProcessStep(title: 'Second', content: Text('Second body')),
          ],
        ),
      ),
    );

    expect(find.byType(AnimatedSize), findsNothing);
    final stateSurfaces = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixProcessStepper),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(stateSurfaces, isNotEmpty);
    expect(
      stateSurfaces.every((surface) => surface.duration == Duration.zero),
      isTrue,
    );

    controller.jumpTo(1);
    await tester.pump();
    expect(find.text('First body'), findsNothing);
    expect(find.text('Second body'), findsOneWidget);
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('process stepper clamps controlled and shrinking step indices', (
    tester,
  ) async {
    final controller = MiuixProcessStepperController(currentStep: 2);
    final published = <int>[];
    addTearDown(controller.dispose);
    var stepCount = 3;
    late StateSetter rebuildHost;
    await pumpAdvancedExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          const steps = <MiuixProcessStep>[
            MiuixProcessStep(title: 'First', content: Text('First content')),
            MiuixProcessStep(title: 'Second', content: Text('Second content')),
            MiuixProcessStep(title: 'Third', content: Text('Third content')),
          ];
          return MiuixProcessStepper(
            controller: controller,
            currentStep: stepCount == 3 ? 99 : null,
            onStepChanged: published.add,
            showDefaultActions: false,
            steps: steps.take(stepCount).toList(growable: false),
          );
        },
      ),
    );

    expect(find.text('Third content'), findsOneWidget);
    rebuildHost(() => stepCount = 1);
    await tester.pump();
    await tester.pump();

    expect(controller.currentStep, 0);
    expect(published, <int>[0]);
    expect(find.text('First content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('process stepper normalizes negative controller and scalar', (
    tester,
  ) async {
    final controller = MiuixProcessStepperController(currentStep: -7);
    addTearDown(controller.dispose);
    expect(controller.currentStep, 0);
    await pumpAdvancedExtension(
      tester,
      MiuixProcessStepper(
        controller: controller,
        currentStep: -9,
        showDefaultActions: false,
        steps: const <MiuixProcessStep>[
          MiuixProcessStep(title: 'First', content: Text('First body')),
          MiuixProcessStep(title: 'Second', content: Text('Second body')),
        ],
      ),
    );

    expect(find.text('First body'), findsOneWidget);
    expect(find.text('Second body'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('process stepper uses axis keys and ignores boundary movement', (
    tester,
  ) async {
    final controller = MiuixProcessStepperController(currentStep: 1);
    final published = <int>[];
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      MiuixProcessStepper(
        controller: controller,
        onStepChanged: published.add,
        showDefaultActions: false,
        steps: const <MiuixProcessStep>[
          MiuixProcessStep(title: 'First'),
          MiuixProcessStep(title: 'Last'),
        ],
      ),
    );

    final shortcuts = tester.widget<Shortcuts>(
      find
          .descendant(
            of: find.byType(MiuixProcessStepper),
            matching: find.byType(Shortcuts),
          )
          .first,
    );
    expect(
      shortcuts.shortcuts.keys,
      containsAll(<ShortcutActivator>[
        const SingleActivator(LogicalKeyboardKey.arrowUp),
        const SingleActivator(LogicalKeyboardKey.arrowDown),
      ]),
    );
    expect(
      shortcuts.shortcuts.keys,
      isNot(contains(const SingleActivator(LogicalKeyboardKey.arrowLeft))),
    );
    final focus = tester
        .widgetList<Focus>(
          find.descendant(
            of: find.byType(MiuixProcessStepper),
            matching: find.byType(Focus),
          ),
        )
        .firstWhere((candidate) => candidate.focusNode != null);
    focus.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    expect(controller.currentStep, 1);
    expect(published, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-selectable process stepper installs no key bindings', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      const MiuixProcessStepper(
        allowStepSelection: false,
        showDefaultActions: false,
        steps: <MiuixProcessStep>[
          MiuixProcessStep(title: 'Read only'),
          MiuixProcessStep(title: 'Still read only'),
        ],
      ),
    );

    final shortcuts = tester.widget<Shortcuts>(
      find.descendant(
        of: find.byType(MiuixProcessStepper),
        matching: find.byType(Shortcuts),
      ),
    );
    expect(shortcuts.shortcuts, isEmpty);
    final focus = tester.widget<Focus>(
      find
          .descendant(
            of: find.byType(MiuixProcessStepper),
            matching: find.byType(Focus),
          )
          .first,
    );
    expect(focus.canRequestFocus, isFalse);
  });

  testWidgets('data table sorts and publishes stable row selection', (
    tester,
  ) async {
    final controller = MiuixDataTableController();
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            cardCornerRadius: 28,
            contentSurfaceBlur: 33,
            contentSurfaceTintOpacity: .42,
            dataTableHeaderTintOpacity: .37,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: MiuixDataTable<int>(
            controller: controller,
            items: const <int>[3, 1, 2],
            rowKey: (item) => item,
            selectable: true,
            height: 320,
            columns: <MiuixDataColumn<int>>[
              MiuixDataColumn<int>(
                id: 'value',
                label: 'Value',
                comparator: (a, b) => a.compareTo(b),
                cellBuilder: (context, item) => Text('Row $item'),
              ),
            ],
          ),
        ),
      ),
    );

    final tableSurface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-data-table-surface')),
    );
    expect(tableSurface.radius, 28);
    expect(tableSurface.glass, isTrue);
    expect(tableSurface.glassBlur, 33);
    expect(tableSurface.glassOpacity, .42);
    final header = tester.widget<Container>(
      find.byKey(const ValueKey('miuix-data-table-header')),
    );
    expect((header.color?.a ?? 0), closeTo(.37, .01));

    await tester.tap(find.text('Value'));
    await tester.pumpAndSettle();
    expect(controller.sortColumnId, 'value');
    expect(find.text('Row 1'), findsOneWidget);
    await tester.tap(find.text('Row 1'));
    await tester.pump();
    expect(controller.selectedKeys, contains(1));
  });

  testWidgets('data table source keeps fixed opaque outer geometry', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(cardCornerRadius: 31),
        ),
        child: MiuixDataTable<int>.source(
          items: const <int>[1],
          rowKey: (item) => item,
          columns: <MiuixDataColumn<int>>[
            MiuixDataColumn<int>(
              id: 'value',
              label: 'Value',
              cellBuilder: (context, item) => Text('$item'),
            ),
          ],
        ),
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-data-table-surface')),
    );
    expect(surface.radius, MiuixDataTableDefaults.cornerRadius);
    expect(surface.glass, isFalse);
  });

  testWidgets('data table normalizes invalid public dimensions', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      const MiuixDataTable<int>(
        items: <int>[1],
        rowKey: _advancedRowKey,
        height: double.nan,
        minimumWidth: double.infinity,
        headerHeight: double.nan,
        rowHeight: double.infinity,
        cornerRadius: double.infinity,
        columns: <MiuixDataColumn<int>>[
          MiuixDataColumn<int>(
            id: 'value',
            label: 'Safe dimensions',
            width: double.nan,
            cellBuilder: _advancedRowCell,
          ),
        ],
      ),
    );

    final surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-data-table-surface')),
    );
    final header = tester.widget<Container>(
      find.byKey(const ValueKey('miuix-data-table-header')),
    );
    final row = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Row 1'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(surface.radius, MiuixThemeData.defaults().hyperOs4.cardCornerRadius);
    expect(header.constraints!.maxHeight, MiuixDataTableDefaults.headerHeight);
    expect(row.constraints!.maxHeight, MiuixDataTableDefaults.rowHeight);
    expect(tester.getSize(find.byType(MiuixDataTable<int>)).height, 420);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table owns header interaction without Material ancestor', (
    tester,
  ) async {
    final controller = MiuixDataTableController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          child: MiuixDataTable<int>(
            controller: controller,
            items: const <int>[2, 1],
            rowKey: _advancedRowKey,
            height: 180,
            columns: const <MiuixDataColumn<int>>[
              MiuixDataColumn<int>(
                id: 'value',
                label: 'Standalone value',
                comparator: _compareAdvancedRows,
                cellBuilder: _advancedRowCell,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Standalone value'));
    await tester.pump();
    expect(controller.sortColumnId, 'value');
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table keyboard focus follows row identity through sort', (
    tester,
  ) async {
    final controller = MiuixDataTableController();
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      MiuixDataTable<int>(
        controller: controller,
        items: const <int>[3, 1, 2],
        rowKey: (item) => item,
        selectable: true,
        height: 260,
        columns: <MiuixDataColumn<int>>[
          MiuixDataColumn<int>(
            id: 'value',
            label: 'Sortable identity',
            comparator: (a, b) => a.compareTo(b),
            cellBuilder: (context, item) => Text('Focus row $item'),
          ),
        ],
      ),
    );

    await tester.tap(find.text('Focus row 3'));
    await tester.pump();
    expect(controller.selectedKeys, contains(3));
    controller.setSelection(const <Object>[]);
    controller.sortBy('value');
    await tester.pump();
    Actions.invoke(
      tester.element(find.text('Focus row 3')),
      const ActivateIntent(),
    );
    await tester.pump();

    expect(controller.selectedKeys, contains(3));
    expect(controller.selectedKeys, isNot(contains(1)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table moves focus to a surviving row after shrink', (
    tester,
  ) async {
    final controller = MiuixDataTableController();
    addTearDown(controller.dispose);
    var items = <int>[0, 1, 2];
    late StateSetter rebuildHost;
    await pumpAdvancedExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixDataTable<int>(
            controller: controller,
            items: items,
            rowKey: (item) => item,
            selectable: true,
            height: 260,
            columns: <MiuixDataColumn<int>>[
              MiuixDataColumn<int>(
                id: 'value',
                label: 'Shrinkable rows',
                cellBuilder: (context, item) => Text('Shrink row $item'),
              ),
            ],
          );
        },
      ),
    );

    await tester.tap(find.text('Shrink row 2'));
    await tester.pump();
    controller.setSelection(const <Object>[]);
    rebuildHost(() => items = <int>[0]);
    await tester.pump();

    final rowContainer = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Shrink row 0'),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = rowContainer.decoration! as BoxDecoration;
    final colors = MiuixDataTableDefaults.colors(
      tester.element(find.byType(MiuixDataTable<int>)),
    );
    expect(decoration.color, colors.hoverSurface);
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-select table has no select-all and emits snapshots', (
    tester,
  ) async {
    final controller = MiuixDataTableController();
    final snapshots = <Set<Object>>[];
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      MiuixDataTable<int>(
        controller: controller,
        items: const <int>[1, 2],
        rowKey: (item) => item,
        selectable: true,
        multiSelect: false,
        height: 220,
        onSelectionChanged: snapshots.add,
        columns: <MiuixDataColumn<int>>[
          MiuixDataColumn<int>(
            id: 'value',
            label: 'Single selection',
            cellBuilder: (context, item) => Text('Single row $item'),
          ),
        ],
      ),
    );

    // Only row checkboxes exist; the aligned header lane is not actionable.
    expect(find.byType(MiuixCheckbox), findsNWidgets(2));
    await tester.tap(find.text('Single row 1'));
    await tester.pump();
    await tester.tap(find.text('Single row 2'));
    await tester.pump();

    expect(controller.selectedKeys, <Object>{2});
    expect(snapshots, hasLength(2));
    expect(snapshots.first, <Object>{1});
    expect(snapshots.last, <Object>{2});
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table zero scroll clock settles only when row exits view', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            collectionScrollMotion: Duration.zero,
          ),
        ),
        child: MiuixDataTable<int>(
          items: List<int>.generate(12, (index) => index),
          rowKey: (item) => item,
          height: 208,
          minimumWidth: 300,
          columns: <MiuixDataColumn<int>>[
            MiuixDataColumn<int>(
              id: 'value',
              label: 'Zero clock',
              width: 300,
              cellBuilder: (context, item) => Text('Zero row $item'),
            ),
          ],
        ),
      ),
      size: const Size(400, 500),
    );

    await tester.tap(find.text('Zero row 0'));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    final vertical = tester
        .stateList<ScrollableState>(
          find.descendant(
            of: find.byType(MiuixDataTable<int>),
            matching: find.byType(Scrollable),
          ),
        )
        .firstWhere(
          (state) => state.position.axisDirection == AxisDirection.down,
        );
    expect(vertical.position.pixels, 0);
    for (var index = 0; index < 5; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    expect(vertical.position.pixels, closeTo(208, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table removes inherited top inset and can fit short data', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      MediaQuery(
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(top: 96),
        ),
        child: MiuixDataTable<int>(
          items: const <int>[1, 2, 3],
          rowKey: (item) => item,
          selectable: true,
          height: 400,
          shrinkWrapRows: true,
          columns: <MiuixDataColumn<int>>[
            MiuixDataColumn<int>(
              id: 'value',
              label: 'Value',
              cellBuilder: (context, item) => Text('Row $item'),
            ),
          ],
        ),
      ),
      size: const Size(400, 800),
    );

    // 52dp header plus three 52dp rows and the 32dp horizontal-scrollbar lane;
    // the ambient 96dp safe inset must not be inserted again inside the table.
    expect(tester.getSize(find.byType(MiuixDataTable<int>)).height, 240);
    final verticalList = tester.widget<ListView>(find.byType(ListView));
    expect(verticalList.padding, EdgeInsets.zero);
    expect(verticalList.primary, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('data table reduced motion snaps row and keyboard scrolling', (
    tester,
  ) async {
    var reduceMotion = false;
    late StateSetter updateHost;
    await pumpAdvancedExtension(
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
                  collectionRowMotion: Duration(milliseconds: 888),
                  collectionScrollMotion: Duration(milliseconds: 777),
                ),
              ),
              child: MiuixDataTable<int>(
                items: List<int>.generate(15, (index) => index),
                rowKey: (item) => item,
                height: 208,
                minimumWidth: 300,
                columns: <MiuixDataColumn<int>>[
                  MiuixDataColumn<int>(
                    id: 'value',
                    label: 'Value',
                    width: 300,
                    cellBuilder: (context, item) => Text('Reduced row $item'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      size: const Size(400, 500),
    );

    final rowSurfaces = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixDataTable<int>),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(rowSurfaces, isNotEmpty);
    expect(rowSurfaces, isNotEmpty);
    expect(
      rowSurfaces.every(
        (surface) => surface.duration == const Duration(milliseconds: 888),
      ),
      isTrue,
    );

    await tester.tap(find.text('Reduced row 0'));
    for (var index = 0; index < 6; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    }
    final vertical = tester
        .stateList<ScrollableState>(
          find.descendant(
            of: find.byType(MiuixDataTable<int>),
            matching: find.byType(Scrollable),
          ),
        )
        .firstWhere(
          (state) => state.position.axisDirection == AxisDirection.down,
        );
    expect(vertical.position.pixels, lessThan(208));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(vertical.position.pixels, inExclusiveRange(0, 208));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    await tester.pump();
    expect(vertical.position.pixels, closeTo(208, .01));
    final reducedRows = tester.widgetList<AnimatedContainer>(
      find.descendant(
        of: find.byType(MiuixDataTable<int>),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(
      reducedRows.every((surface) => surface.duration == Duration.zero),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliver top bar receives a direct collapse fraction', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      CustomScrollView(
        slivers: <Widget>[
          const MiuixSliverTopAppBar(title: 'Library', glass: true),
          SliverList.builder(
            itemCount: 40,
            itemBuilder: (context, index) =>
                SizedBox(height: 60, child: Text('Item $index')),
          ),
        ],
      ),
    );

    expect(
      tester
          .widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar))
          .collapseFraction,
      0,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar))
          .collapseFraction,
      greaterThan(.9),
    );
  });

  testWidgets('sliver top bar tokenizes snap and honors reduced motion', (
    tester,
  ) async {
    final reduceMotion = ValueNotifier<bool>(false);
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
                  sliverAppBarSnapMotion: Duration(milliseconds: 777),
                ),
              ),
              child: const CustomScrollView(
                slivers: <Widget>[
                  MiuixSliverTopAppBar(
                    title: 'Snapping library',
                    floating: true,
                    snap: true,
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: 1200)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Duration snapDuration() => tester
        .widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
        .delegate
        .snapConfiguration!
        .duration;

    expect(snapDuration(), const Duration(milliseconds: 777));
    reduceMotion.value = true;
    await tester.pump();
    expect(snapDuration(), Duration.zero);
  });

  testWidgets('sliver top bar normalizes malformed Release geometry', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      const CustomScrollView(
        slivers: <Widget>[
          MiuixSliverTopAppBar(
            title: 'Safe sliver',
            snap: true,
            floating: false,
            expandedHeight: double.nan,
            collapsedHeight: -1,
            bottomContentHeight: double.infinity,
            bottomContentExpandedTopPadding: -20,
          ),
          SliverToBoxAdapter(child: SizedBox(height: 800)),
        ],
      ),
    );

    final delegate = tester
        .widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
        .delegate;
    expect(delegate.minExtent, MiuixSliverTopAppBarDefaults.collapsedHeight);
    expect(delegate.maxExtent, MiuixSliverTopAppBarDefaults.expandedHeight);
    expect(delegate.snapConfiguration, isNull);
    final bar = tester.widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar));
    expect(bar.bottomContentHeight, 0);
    expect(bar.bottomContentExpandedTopPadding, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sliver top bar separates HyperOS 4 and source geometry', (
    tester,
  ) async {
    Future<(double, double, MiuixTopAppBar)> pumpBar({
      required bool source,
      bool subtitle = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MiuixTheme(
            data: MiuixThemeData.defaults().copyWith(
              hyperOs4: const MiuixHyperOs4Tokens(
                sliverAppBarExpandedHeight: 132,
                sliverAppBarCollapsedHeight: 72,
                sliverAppBarExpandedSubtitleHeight: 148,
                sliverAppBarCollapsedSubtitleHeight: 76,
              ),
            ),
            child: CustomScrollView(
              slivers: <Widget>[
                source
                    ? MiuixSliverTopAppBar.source(
                        title: 'Source',
                        subtitle: subtitle ? 'Supporting' : null,
                      )
                    : MiuixSliverTopAppBar(
                        title: 'HyperOS 4',
                        subtitle: subtitle ? 'Supporting' : null,
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 900)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      final delegate = tester
          .widget<SliverPersistentHeader>(find.byType(SliverPersistentHeader))
          .delegate;
      return (
        delegate.minExtent,
        delegate.maxExtent,
        tester.widget<MiuixTopAppBar>(find.byType(MiuixTopAppBar)),
      );
    }

    final standard = await pumpBar(source: false);
    expect(standard.$1, 72);
    expect(standard.$2, 132);
    expect(standard.$3.expandedHeight, 132);
    expect(standard.$3.collapsedTitleAreaHeight, 72);

    final source = await pumpBar(source: true);
    expect(source.$1, MiuixSliverTopAppBarDefaults.legacyCollapsedHeight);
    expect(source.$2, MiuixSliverTopAppBarDefaults.legacyExpandedHeight);
    expect(source.$3.expandedHeight, 94);
    expect(source.$3.collapsedTitleAreaHeight, 56);

    final standardSubtitle = await pumpBar(source: false, subtitle: true);
    expect(standardSubtitle.$1, 76);
    expect(standardSubtitle.$2, 148);
    expect(standardSubtitle.$3.expandedHeight, 148);
    expect(standardSubtitle.$3.collapsedTitleAreaHeight, 76);

    final sourceSubtitle = await pumpBar(source: true, subtitle: true);
    expect(
      sourceSubtitle.$1,
      MiuixSliverTopAppBarDefaults.legacyCollapsedSubtitleHeight,
    );
    expect(
      sourceSubtitle.$2,
      MiuixSliverTopAppBarDefaults.legacyExpandedSubtitleHeight,
    );
  });

  testWidgets('sliver content starts below title then moves behind glass', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      CustomScrollView(
        controller: controller,
        slivers: <Widget>[
          const MiuixSliverTopAppBar(title: 'Library'),
          SliverList.builder(
            itemCount: 20,
            itemBuilder: (context, index) => SizedBox(
              key: ValueKey<String>('sliver-row-$index'),
              height: 60,
              child: Text('Row $index'),
            ),
          ),
        ],
      ),
    );

    Rect headerRect() => tester.getRect(
      find.byKey(const ValueKey('top-app-bar-progressive-glass')),
    );
    Rect firstRowRect() =>
        tester.getRect(find.byKey(const ValueKey<String>('sliver-row-0')));

    expect(firstRowRect().top, closeTo(headerRect().bottom, .001));
    controller.jumpTo(80);
    await tester.pump();
    expect(headerRect().height, MiuixSliverTopAppBarDefaults.collapsedHeight);
    expect(firstRowRect().top, lessThan(headerRect().bottom));
    expect(firstRowRect().bottom, greaterThan(headerRect().top));
  });

  testWidgets('command palette filters and returns typed command', (
    tester,
  ) async {
    MiuixCommand? invoked;
    final commands = <MiuixCommand>[
      MiuixCommand(id: 'open', title: 'Open file', onInvoke: () {}),
      MiuixCommand(id: 'theme', title: 'Change theme', onInvoke: () {}),
    ];
    await pumpAdvancedExtension(
      tester,
      MiuixTheme(
        data: MiuixThemeData.defaults().copyWith(
          hyperOs4: const MiuixHyperOs4Tokens(
            inlineSurfaceMotion: Duration(milliseconds: 777),
          ),
        ),
        child: MiuixCommandPalette(
          commands: commands,
          onInvoked: (command) => invoked = command,
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSize>(find.byType(AnimatedSize)).duration,
      const Duration(milliseconds: 777),
    );
    final commandsList = tester.widget<ListView>(find.byType(ListView));
    expect(commandsList.padding, EdgeInsets.zero);
    expect(commandsList.primary, isFalse);

    await tester.enterText(find.byType(EditableText), 'theme');
    await tester.pump();
    expect(find.text('Open file'), findsNothing);
    expect(find.text('Change theme'), findsOneWidget);
    await tester.tap(find.text('Change theme'));
    await tester.pump();
    expect(invoked?.id, 'theme');
  });

  testWidgets('command palette separates popup material and source host', (
    tester,
  ) async {
    const panelKey = ValueKey('miuix-command-palette-surface');
    Widget standard({bool glass = true}) => MiuixTheme(
      data: MiuixThemeData.defaults().copyWith(
        hyperOs4: const MiuixHyperOs4Tokens(
          popupBlur: 37,
          popupTintOpacity: .43,
          popupCornerRadius: 27,
        ),
      ),
      child: MiuixCommandPalette(
        autofocus: false,
        glass: glass,
        commands: <MiuixCommand>[
          MiuixCommand(id: 'open', title: 'Open file', onInvoke: () {}),
        ],
      ),
    );

    await pumpAdvancedExtension(tester, standard());
    var surface = tester.widget<MiuixSurface>(find.byKey(panelKey));
    expect(surface.glass, isTrue);
    expect(surface.glassBlur, 37);
    expect(surface.glassOpacity, .43);
    expect(surface.radius, 27);
    expect(surface.showGlassSpecular, isTrue);
    expect(find.byType(MiuixGlass), findsOneWidget);

    await pumpAdvancedExtension(tester, standard(glass: false));
    surface = tester.widget<MiuixSurface>(find.byKey(panelKey));
    expect(surface.glass, isFalse);
    expect(find.byType(MiuixGlass), findsNothing);

    await pumpAdvancedExtension(
      tester,
      MiuixCommandPalette.source(
        autofocus: false,
        commands: <MiuixCommand>[
          MiuixCommand(id: 'open', title: 'Open file', onInvoke: () {}),
        ],
      ),
    );
    expect(find.byKey(panelKey), findsNothing);
    expect(find.byType(MiuixGlass), findsNothing);
  });

  testWidgets('command palette dialogs keep exactly one material owner', (
    tester,
  ) async {
    final commands = <MiuixCommand>[
      MiuixCommand(id: 'open', title: 'Open file', onInvoke: () {}),
    ];
    await pumpAdvancedExtension(
      tester,
      Builder(
        builder: (context) => Column(
          children: <Widget>[
            TextButton(
              onPressed: () => MiuixCommandPalette.show(
                context: context,
                commands: commands,
              ),
              child: const Text('Open standard'),
            ),
            TextButton(
              onPressed: () => MiuixCommandPalette.showSource(
                context: context,
                commands: commands,
              ),
              child: const Text('Open source'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Open standard'));
    await tester.pumpAndSettle();
    var dialogGlass = tester.widget<MiuixGlass>(find.byType(MiuixGlass));
    expect(dialogGlass.enabled, isTrue);
    expect(dialogGlass.optics, same(MiuixGlassOptics.transient));
    expect(
      tester
          .widget<MiuixSurface>(
            find.byKey(const ValueKey('miuix-command-palette-surface')),
          )
          .glass,
      isFalse,
    );
    Navigator.of(tester.element(find.text('Open file'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open source'));
    await tester.pumpAndSettle();
    dialogGlass = tester.widget<MiuixGlass>(find.byType(MiuixGlass));
    expect(dialogGlass.enabled, isFalse);
    expect(
      find.byKey(const ValueKey('miuix-command-palette-surface')),
      findsNothing,
    );
  });

  testWidgets(
    'command palette invokes without popping its nested caller route',
    (tester) async {
      final nestedNavigator = GlobalKey<NavigatorState>();
      var invocations = 0;
      await tester.pumpWidget(
        MiuixTheme(
          child: MaterialApp(
            home: Navigator(
              key: nestedNavigator,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) =>
                    const Scaffold(body: Text('command root')),
              ),
            ),
          ),
        ),
      );
      nestedNavigator.currentState!.push<void>(
        MaterialPageRoute<void>(
          builder: (context) => Scaffold(
            body: Column(
              children: <Widget>[
                const Text('nested command page'),
                MiuixButton(
                  label: 'open nested commands',
                  onPressed: () => MiuixCommandPalette.show(
                    context: context,
                    commands: <MiuixCommand>[
                      MiuixCommand(
                        id: 'nested-run',
                        title: 'Run nested command',
                        onInvoke: () => invocations++,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open nested commands'));
      await tester.pumpAndSettle();
      // A second pointer activation before route removal must not issue a
      // second root pop that would consume the nested caller page.
      final commandRow = tester.widget<MiuixSurface>(
        find.byKey(const ValueKey<Object>(('miuix-command-row', 'nested-run'))),
      );
      commandRow.onTap!();
      commandRow.onTap!();
      await tester.pumpAndSettle();

      expect(invocations, 1);
      expect(find.byType(MiuixCommandPalette), findsNothing);
      expect(find.text('nested command page'), findsOneWidget);
      expect(nestedNavigator.currentState!.canPop(), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('command palette row motion retargets and reduces directly', (
    tester,
  ) async {
    final controller = MiuixCommandPaletteController();
    final reduceMotion = ValueNotifier<bool>(false);
    addTearDown(controller.dispose);
    addTearDown(reduceMotion.dispose);
    await pumpAdvancedExtension(
      tester,
      ValueListenableBuilder<bool>(
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
            child: MiuixCommandPalette(
              controller: controller,
              autofocus: false,
              commands: <MiuixCommand>[
                MiuixCommand(id: 'one', title: 'Command one', onInvoke: () {}),
                MiuixCommand(id: 'two', title: 'Command two', onInvoke: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    Finder secondMotion() => find.ancestor(
      of: find.text('Command two'),
      matching: find.byType(TweenAnimationBuilder<double>),
    );
    MiuixSurface secondSurface() => tester.widget<MiuixSurface>(
      find.byKey(const ValueKey<Object>(('miuix-command-row', 'two'))),
    );
    expect(
      tester.widget<TweenAnimationBuilder<double>>(secondMotion()).duration,
      const Duration(milliseconds: 777),
    );
    expect(secondSurface().radius, 23);
    expect(secondSurface().color, Colors.transparent);
    controller.highlight(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final intermediate = secondSurface().color!;
    expect(intermediate, isNot(Colors.transparent));

    // The logical highlight already changed; enabling reduced motion must
    // replace the in-flight sample with that exact endpoint in one rebuild.
    reduceMotion.value = true;
    await tester.pump();
    expect(
      tester.widget<TweenAnimationBuilder<double>>(secondMotion()).duration,
      Duration.zero,
    );
    expect(secondSurface().color, isNot(intermediate));
  });

  testWidgets('command palette reduced motion replaces panel height directly', (
    tester,
  ) async {
    final controller = MiuixCommandPaletteController();
    addTearDown(controller.dispose);
    await pumpAdvancedExtension(
      tester,
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MiuixCommandPalette(
          controller: controller,
          autofocus: false,
          commands: <MiuixCommand>[
            MiuixCommand(id: 'open', title: 'Open file', onInvoke: () {}),
            MiuixCommand(id: 'theme', title: 'Change theme', onInvoke: () {}),
          ],
        ),
      ),
    );

    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.getSize(find.byType(MiuixCommandPalette)).height, 218);
    controller.setQuery('theme');
    await tester.pump();
    expect(find.text('Open file'), findsNothing);
    expect(find.text('Change theme'), findsOneWidget);
    expect(tester.getSize(find.byType(MiuixCommandPalette)).height, 180);
    expect(find.byType(AnimatedSize), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('command palette normalizes dynamic and empty catalogues', (
    tester,
  ) async {
    final first = MiuixCommandPaletteController()..highlight(4);
    final second = MiuixCommandPaletteController()..highlight(3);
    var active = first;
    var commands = <MiuixCommand>[
      MiuixCommand(id: 'one', title: 'One', onInvoke: () {}),
    ];
    late StateSetter rebuild;
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await pumpAdvancedExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return MiuixCommandPalette(
            controller: active,
            autofocus: false,
            commands: commands,
          );
        },
      ),
    );

    expect(first.highlightedIndex, 0);
    // The replacement controller already points at a legal row in the new
    // catalogue, so normalization must preserve its visible coordinate.
    rebuild(() {
      active = second;
      commands = List<MiuixCommand>.generate(
        4,
        (index) => MiuixCommand(
          id: 'replacement-$index',
          title: 'Replacement $index',
          onInvoke: () {},
        ),
      );
    });
    await tester.pump();
    await tester.pump();

    expect(first.highlightedIndex, 0);
    expect(second.highlightedIndex, 3);
    rebuild(() => commands = const <MiuixCommand>[]);
    await tester.pump();
    await tester.pump();
    expect(second.highlightedIndex, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'command palette skips disabled rows and scrolls keyboard highlight',
    (tester) async {
      final controller = MiuixCommandPaletteController();
      final invoked = <String>[];
      addTearDown(controller.dispose);
      final commands = List<MiuixCommand>.generate(
        14,
        (index) => MiuixCommand(
          id: 'command-$index',
          title: 'Command $index',
          enabled: index != 0 && index != 12,
          onInvoke: () {},
        ),
      );
      await pumpAdvancedExtension(
        tester,
        MiuixCommandPalette(
          controller: controller,
          autofocus: true,
          maxHeight: 260,
          commands: commands,
          onInvoked: (command) => invoked.add(command.id),
        ),
      );
      await tester.pump();

      // Initial selection cannot remain on the disabled first result.
      expect(controller.highlightedIndex, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(controller.highlightedIndex, 13);
      expect(
        tester.widget<ListView>(find.byType(ListView)).controller!.offset,
        greaterThan(0),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(controller.highlightedIndex, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      expect(invoked, <String>['command-1', 'command-1']);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Command 1'));
      expect(invoked, <String>['command-1', 'command-1', 'command-1']);
      expect(tester.takeException(), isNull);
    },
  );

  test('command palette treats maxHeight as a cap for short lists', () {
    expect(MiuixCommandPaletteDefaults.panelHeight(commandCount: 2), 218);
    expect(
      MiuixCommandPaletteDefaults.panelHeight(commandCount: 100),
      MiuixCommandPaletteDefaults.maxHeight,
    );
    expect(
      MiuixCommandPaletteDefaults.panelHeight(commandCount: 0, maxHeight: 120),
      120,
    );
    expect(
      MiuixCommandPaletteDefaults.panelHeight(
        commandCount: 2,
        maxHeight: double.nan,
      ),
      218,
    );
    expect(
      MiuixCommandPaletteDefaults.panelHeight(
        commandCount: 100,
        maxHeight: double.infinity,
      ),
      MiuixCommandPaletteDefaults.maxHeight,
    );
  });

  testWidgets(
    'file drop picker shares validation and public controller state',
    (tester) async {
      final controller = MiuixFileDropController();
      List<MiuixRejectedFile>? rejected;
      await pumpAdvancedExtension(
        tester,
        Center(
          child: SizedBox(
            width: 520,
            child: MiuixFileDropZone(
              controller: controller,
              enableNativeDrop: false,
              acceptedExtensions: const <String>['txt'],
              maximumBytes: 10,
              onFilesRejected: (files) => rejected = files,
              onBrowseRequested: () async => <MiuixDroppedFile>[
                MiuixDroppedFile(
                  path: 'note.txt',
                  name: 'note.txt',
                  length: 4,
                  readBytes: () async => Uint8List.fromList(<int>[1, 2, 3, 4]),
                ),
                const MiuixDroppedFile(
                  path: 'image.png',
                  name: 'image.png',
                  length: 4,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('选择文件'));
      await tester.pumpAndSettle();
      expect(controller.files.single.name, 'note.txt');
      expect(rejected?.single.reason, MiuixFileRejectionReason.unsupportedType);
      expect(await controller.files.single.readAsBytes(), hasLength(4));
    },
  );

  testWidgets('file drop ignores a picker result from a replaced controller', (
    tester,
  ) async {
    final firstController = MiuixFileDropController();
    final secondController = MiuixFileDropController();
    final stale = Completer<List<MiuixDroppedFile>>();
    addTearDown(firstController.dispose);
    addTearDown(secondController.dispose);
    var currentController = firstController;
    Future<List<MiuixDroppedFile>> Function() picker = () => stale.future;
    late StateSetter rebuildHost;

    await pumpAdvancedExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return Center(
            child: SizedBox(
              width: 520,
              child: MiuixFileDropZone(
                controller: currentController,
                enableNativeDrop: false,
                onBrowseRequested: picker,
              ),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pump();
    rebuildHost(() {
      currentController = secondController;
      picker = () async => const <MiuixDroppedFile>[
        MiuixDroppedFile(path: 'fresh.txt', name: 'fresh.txt'),
      ];
    });
    await tester.pump();
    stale.complete(const <MiuixDroppedFile>[
      MiuixDroppedFile(path: 'stale.txt', name: 'stale.txt'),
    ]);
    await tester.pumpAndSettle();

    expect(firstController.files, isEmpty);
    expect(secondController.files, isEmpty);
    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();
    expect(secondController.files.single.name, 'fresh.txt');
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop invalidates a pending validation callback contract', (
    tester,
  ) async {
    final controller = MiuixFileDropController();
    final pending = Completer<List<MiuixDroppedFile>>();
    final accepted = <String>[];
    var useReplacement = false;
    late StateSetter rebuildHost;
    addTearDown(controller.dispose);

    await pumpAdvancedExtension(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuildHost = setState;
          return MiuixFileDropZone(
            controller: controller,
            enableNativeDrop: false,
            acceptedExtensions: useReplacement
                ? const <String>['png']
                : const <String>['txt'],
            onFilesAccepted: (files) => accepted.add(
              '${useReplacement ? 'new' : 'old'}:${files.single.name}',
            ),
            onBrowseRequested: () => pending.future,
          );
        },
      ),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pump();
    rebuildHost(() => useReplacement = true);
    await tester.pump();
    pending.complete(const <MiuixDroppedFile>[
      MiuixDroppedFile(path: 'stale.png', name: 'stale.png', length: 1),
    ]);
    await tester.pumpAndSettle();

    expect(controller.files, isEmpty);
    expect(accepted, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop disables stale native entry while picker is busy', (
    tester,
  ) async {
    final pending = Completer<List<MiuixDroppedFile>>();
    await pumpAdvancedExtension(
      tester,
      MiuixFileDropZone(onBrowseRequested: () => pending.future),
    );
    final initialTarget = tester.widget<DropTarget>(find.byType(DropTarget));
    expect(initialTarget.enable, isTrue);

    await tester.tap(find.text('选择文件'));
    await tester.pump();
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isFalse);

    initialTarget.onDragEntered!(
      DropEventDetails(
        localPosition: const Offset(40, 40),
        globalPosition: const Offset(40, 40),
      ),
    );
    await tester.pump();
    expect(
      tester
          .widget<MiuixSurface>(
            find.byKey(const ValueKey('miuix-file-drop-surface')),
          )
          .border
          ?.width,
      1,
    );

    pending.complete(const <MiuixDroppedFile>[]);
    await tester.pumpAndSettle();
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop reports picker errors and releases native input', (
    tester,
  ) async {
    MiuixFileDropOperation? operation;
    Object? reportedError;
    StackTrace? reportedStack;
    await pumpAdvancedExtension(
      tester,
      MiuixFileDropZone(
        onBrowseRequested: () => Future<List<MiuixDroppedFile>>.error(
          StateError('picker unavailable'),
          StackTrace.current,
        ),
        onError: (value, error, stackTrace) {
          operation = value;
          reportedError = error;
          reportedStack = stackTrace;
        },
      ),
    );

    await tester.tap(find.text('选择文件'));
    await tester.pumpAndSettle();

    expect(operation, MiuixFileDropOperation.browse);
    expect(reportedError, isA<StateError>());
    expect(reportedStack, isNotNull);
    expect(tester.widget<DropTarget>(find.byType(DropTarget)).enable, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop normalizes invalid limits and disabled affordance', (
    tester,
  ) async {
    await pumpAdvancedExtension(
      tester,
      const MiuixFileDropZone(
        enabled: false,
        enableNativeDrop: false,
        minimumHeight: double.nan,
        maximumFiles: 0,
        maximumBytes: -1,
        acceptedExtensions: <String>[''],
        onBrowseRequested: _emptyDroppedFiles,
      ),
    );

    final constrained = tester.widget<ConstrainedBox>(
      find.ancestor(
        of: find.byKey(const ValueKey('miuix-file-drop-surface')),
        matching: find.byType(ConstrainedBox),
      ),
    );
    expect(
      constrained.constraints.minHeight,
      MiuixFileDropZoneDefaults.minimumHeight,
    );
    final button = tester.widget<MiuixButton>(
      find.widgetWithText(MiuixButton, '选择文件'),
    );
    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop reduced motion snaps the drag-state surface', (
    tester,
  ) async {
    var reduceMotion = false;
    late StateSetter updateHost;
    await pumpAdvancedExtension(
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
                  inlineSurfaceBlur: 33,
                  inlineSurfaceTintOpacity: .44,
                  inlineSurfaceCornerRadius: 27,
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 520,
                  child: MiuixFileDropZone(glass: true),
                ),
              ),
            ),
          );
        },
      ),
    );

    Finder motionFinder(bool reduced) =>
        find.byKey(ValueKey<Object>(('miuix-file-drop-motion', reduced)));
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(motionFinder(false))
          .duration,
      const Duration(milliseconds: 777),
    );
    final dropSurface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-file-drop-surface')),
    );
    expect(dropSurface.radius, 27);
    expect(dropSurface.glass, isTrue);
    expect(dropSurface.glassBlur, 33);
    expect(dropSurface.glassOpacity, .44);
    expect(dropSurface.border?.width, 1);

    final dropTarget = tester.widget<DropTarget>(find.byType(DropTarget));
    dropTarget.onDragEntered!(
      DropEventDetails(
        localPosition: const Offset(40, 40),
        globalPosition: const Offset(40, 40),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final movingSurface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-file-drop-surface')),
    );
    expect(movingSurface.border!.width, inExclusiveRange(1, 2));

    updateHost(() => reduceMotion = true);
    await tester.pump();
    expect(
      tester.widget<TweenAnimationBuilder<double>>(motionFinder(true)).duration,
      Duration.zero,
    );
    expect(
      tester
          .widget<MiuixSurface>(
            find.byKey(const ValueKey('miuix-file-drop-surface')),
          )
          .border
          ?.width,
      2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('file drop separates HyperOS glass, solid, and source material', (
    tester,
  ) async {
    Widget zone(int presentation) => switch (presentation) {
      0 => const MiuixFileDropZone(enableNativeDrop: false),
      1 => const MiuixFileDropZone(
        enableNativeDrop: false,
        glass: false,
        cornerRadius: 29,
      ),
      _ => const MiuixFileDropZone.source(enableNativeDrop: false),
    };

    Future<void> pumpZone(int presentation) => pumpAdvancedExtension(
      tester,
      Center(child: SizedBox(width: 520, child: zone(presentation))),
    );

    await pumpZone(0);
    var surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-file-drop-surface')),
    );
    expect(surface.glass, isTrue);
    expect(surface.radius, 20);
    expect(surface.glassBlur, 20);
    expect(surface.glassOpacity, .62);
    expect(surface.border?.width, 1);

    await pumpZone(1);
    surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-file-drop-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.radius, 29);
    expect(surface.shape, isNull);
    expect(surface.border?.width, 1);

    await pumpZone(2);
    surface = tester.widget<MiuixSurface>(
      find.byKey(const ValueKey('miuix-file-drop-surface')),
    );
    expect(surface.glass, isFalse);
    expect(surface.radius, isNull);
    expect(surface.shape, isA<RoundedRectangleBorder>());
    expect(
      (surface.shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(22),
    );
    expect(surface.showGlassSpecular, isFalse);
  });
}
