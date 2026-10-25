import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

Finder _item(int index) =>
    find.byKey(ValueKey('floating-navigation-item-$index'));
Finder get _lens =>
    find.byKey(const ValueKey('floating-navigation-selection-indicator'));

Future<void> _mount(WidgetTester tester, List<int> commits) async {
  var selected = 0;
  await tester.pumpWidget(
    MaterialApp(
      home: MiuixTheme(
        child: StatefulBuilder(
          builder: (context, setState) => Center(
            child: MiuixFloatingNavigationBar(
              selectedIndex: selected,
              onSelected: (index) {
                commits.add(index);
                setState(() => selected = index);
              },
              items: const [
                MiuixNavigationItem(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Home',
                ),
                MiuixNavigationItem(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profile',
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

void main() {
  testWidgets('pickup is continuous and subsequent reversals track directly', (
    tester,
  ) async {
    final commits = <int>[];
    await _mount(tester, commits);
    final initial = tester.getCenter(_lens);
    final drag = await tester.startGesture(tester.getCenter(_item(2)));
    await drag.moveBy(const Offset(-20, 0));
    await tester.pump();
    expect(tester.getCenter(_lens), initial);
    await tester.pump(const Duration(milliseconds: 32));
    expect(tester.getCenter(_lens).dx, greaterThan(initial.dx));
    await tester.pump(const Duration(milliseconds: 100));
    for (final index in [1, 2, 0, 1]) {
      await drag.moveTo(tester.getCenter(_item(index)));
      await tester.pump();
      expect(
        tester.getCenter(_lens).dx,
        closeTo(tester.getCenter(_item(index)).dx, .1),
      );
      final artwork = tester.widget<Icon>(
        find.descendant(of: _item(index), matching: find.byType(Icon)),
      );
      expect(artwork.icon, [Icons.home, Icons.person, Icons.settings][index]);
      expect(commits, isEmpty);
    }
    await drag.cancel();
    await tester.pumpAndSettle();
    expect((tester.getCenter(_lens) - initial).distance, lessThan(.1));
    expect(commits, isEmpty);
  });

  testWidgets('quick release near boundary commits the actual nearest slot', (
    tester,
  ) async {
    final commits = <int>[];
    await _mount(tester, commits);
    final origin = tester.getCenter(_item(0));
    final pitch = tester.getCenter(_item(1)).dx - origin.dx;
    final drag = await tester.startGesture(origin);
    for (var i = 1; i <= 5; i++) {
      await drag.moveTo(
        origin + Offset(pitch * .07 * i, 0),
        timeStamp: Duration(milliseconds: i * 8),
      );
      await tester.pump(const Duration(milliseconds: 8));
    }
    await drag.up(timeStamp: const Duration(milliseconds: 41));
    await tester.pumpAndSettle();
    expect(commits, isEmpty);
    expect(
      tester.getCenter(_lens).dx,
      closeTo(tester.getCenter(_item(0)).dx, .1),
    );
  });

  testWidgets(
    'icon change never paints both outlines and rapid taps settle once',
    (tester) async {
      final commits = <int>[];
      await _mount(tester, commits);
      await tester.tap(_item(1));
      await tester.pump();
      for (var frame = 0; frame < 9; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(
          find.descendant(of: _item(1), matching: find.byType(Icon)),
          findsOneWidget,
        );
      }
      await tester.tap(_item(2));
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(_item(0));
      await tester.pumpAndSettle();
      expect(commits, [1, 2, 0]);
      expect(
        tester.getCenter(_lens).dx,
        closeTo(tester.getCenter(_item(0)).dx, .1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
