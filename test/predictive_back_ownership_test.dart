import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

Future<Object?> back(WidgetTester tester, String method, {int edge = 0}) async {
  Object? result;
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/backgesture',
    const StandardMethodCodec().encodeMethodCall(
      MethodCall(
        method,
        method == 'startBackGesture' || method == 'updateBackGestureProgress'
            ? {
                'touchOffset': [1.0, 250.0],
                'progress': method == 'startBackGesture' ? 0.0 : .6,
                'swipeEdge': edge,
              }
            : null,
      ),
    ),
    (data) => result = data == null
        ? null
        : const StandardMethodCodec().decodeEnvelope(data),
  );
  return result;
}

ThemeData get theme => ThemeData(
  platform: TargetPlatform.android,
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {TargetPlatform.android: MiuixNavigationPageTransitionsBuilder()},
  ),
);

void main() {
  for (final overlay in [
    'dialog',
    'material-dialog',
    'nested-dialog',
    'sheet',
    'overlay-sheet',
    'menu-window',
    'menu-overlay',
    'blocked-dialog',
  ]) {
    testWidgets('nested page gives Back exclusively to $overlay', (
      tester,
    ) async {
      final nested = GlobalKey<NavigatorState>();
      late BuildContext detailContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MiuixTheme(
            child: Theme(
              data: theme,
              child: Navigator(
                key: nested,
                onGenerateRoute: (_) => MiuixPageRoute<void>(
                  builder: (_) => const MiuixScaffold(body: Text('Inner root')),
                ),
              ),
            ),
          ),
        ),
      );
      final detail = MiuixPageRoute<void>(
        builder: (context) {
          detailContext = context;
          return MiuixScaffold(
            body: Column(
              children: [
                const Text('Retained editor'),
                MiuixIconCascadingDropdownMenu<String>(
                  icon: const Icon(Icons.more_vert),
                  presentation: overlay == 'menu-overlay'
                      ? MiuixPopupPresentation.overlay
                      : MiuixPopupPresentation.window,
                  groups: const [
                    MiuixDropdownGroup(
                      entries: [
                        MiuixDropdownEntry(value: 'a', label: 'Top modal'),
                      ],
                    ),
                  ],
                  onSelected: (_) {},
                ),
                Builder(
                  builder: (context) => TextButton(
                    onPressed: () {
                      unawaited(
                        MiuixOverlayBottomSheet.show<void>(
                          context: context,
                          child: const Text('Top modal'),
                        ),
                      );
                    },
                    child: const Text('Open overlay sheet'),
                  ),
                ),
              ],
            ),
          );
        },
      );
      unawaited(nested.currentState!.push(detail));
      await tester.pumpAndSettle();
      switch (overlay) {
        case 'material-dialog':
          unawaited(
            showDialog<void>(
              context: detailContext,
              builder: (_) => const AlertDialog(content: Text('Top modal')),
            ),
          );
        case 'sheet':
          unawaited(
            MiuixBottomSheet.show<void>(
              context: detailContext,
              child: const Text('Top modal'),
            ),
          );
        case 'overlay-sheet':
          await tester.tap(find.text('Open overlay sheet'));
        case 'menu-window':
        case 'menu-overlay':
          await tester.tap(find.byIcon(Icons.more_vert));
        default:
          if (overlay == 'nested-dialog') {
            unawaited(
              MiuixDialog.show<void>(
                context: detailContext,
                content: const Text('Lower modal'),
              ),
            );
            await tester.pumpAndSettle();
          }
          unawaited(
            MiuixDialog.showBuilder<void>(
              context: detailContext,
              barrierDismissible: overlay != 'blocked-dialog',
              dialogBuilder: (_) => PopScope(
                canPop: overlay != 'blocked-dialog',
                child: const MiuixDialog(content: Text('Top modal')),
              ),
            ),
          );
      }
      await tester.pumpAndSettle();
      expect(find.text('Top modal'), findsOneWidget);
      await back(tester, 'startBackGesture');
      await back(tester, 'updateBackGestureProgress');
      await tester.pump();
      expect(
        detail.animation!.value,
        1,
        reason: 'Covered page must not animate',
      );
      await back(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('Top modal'), findsOneWidget);
      await back(tester, 'startBackGesture');
      await back(tester, 'updateBackGestureProgress');
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(detail.isCurrent, isTrue);
      expect(nested.currentState!.canPop(), isTrue);
      if (overlay == 'blocked-dialog') {
        expect(find.text('Top modal'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Top modal'), findsOneWidget);
        return;
      }
      expect(find.text('Top modal'), findsNothing);
      if (overlay == 'nested-dialog') {
        expect(find.text('Lower modal'), findsOneWidget);
        await back(tester, 'startBackGesture');
        await back(tester, 'commitBackGesture');
        await tester.pumpAndSettle();
        expect(find.text('Lower modal'), findsNothing);
        expect(detail.isCurrent, isTrue);
      }
      await back(tester, 'startBackGesture');
      await back(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(nested.currentState!.canPop(), isFalse);
      expect(find.text('Inner root'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a later mounted hidden navigator cannot consume Back', (
    tester,
  ) async {
    final keys = [GlobalKey<NavigatorState>(), GlobalKey<NavigatorState>()];
    var selected = 0;
    late StateSetter select;
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: StatefulBuilder(
          builder: (context, setState) {
            select = setState;
            return IndexedStack(
              index: selected,
              children: [
                for (var i = 0; i < 2; i++)
                  TickerMode(
                    enabled: i == selected,
                    child: Navigator(
                      key: keys[i],
                      onGenerateRoute: (_) =>
                          MiuixPageRoute<void>(builder: (_) => Text('root $i')),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
    for (var i = 0; i < 2; i++) {
      select(() => selected = i);
      await tester.pumpAndSettle();
      unawaited(
        keys[i].currentState!.push(
          MiuixPageRoute<void>(builder: (_) => Text('detail $i')),
        ),
      );
      await tester.pumpAndSettle();
    }
    select(() => selected = 0);
    await tester.pumpAndSettle();
    await back(tester, 'startBackGesture');
    await back(tester, 'commitBackGesture');
    await tester.pumpAndSettle();
    expect(keys[0].currentState!.canPop(), isFalse);
    expect(keys[1].currentState!.canPop(), isTrue);
  });
}
