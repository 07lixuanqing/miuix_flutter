import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  testWidgets('default artwork and accessibility are preserved', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MiuixThemedIcon(
          Icons.close,
          size: 30,
          color: Colors.red,
          semanticLabel: 'Close panel',
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.close);
    expect(icon.size, 30);
    expect(icon.color, Colors.red);
    expect(icon.semanticLabel, 'Close panel');
  });
  testWidgets('resolver reaches library controls and captured popup routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(
            mode: MiuixColorMode.light,
            seedColor: Colors.blue,
          ),
          child: MiuixIconTheme(
            resolve: (_) => Icons.star_rounded,
            child: Builder(
              builder: (context) => TextButton(
                child: const Text('Open'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const Dialog(
                    child: MiuixThemedIcon(Icons.close, semanticLabel: 'Close'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.star_rounded);
  });
  testWidgets('artwork builder receives source metadata in captured dialogs', (
    tester,
  ) async {
    Icon? source;
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixIconTheme(
          resolve: (_) => Icons.star,
          builder: (context, icon) {
            source = icon;
            return Semantics(
              label: icon.semanticLabel,
              child: SizedBox.square(
                dimension: icon.size!,
                child: const ColoredBox(color: Colors.blue),
              ),
            );
          },
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const Dialog(
                  child: Center(
                    child: MiuixThemedIcon(
                      Icons.close,
                      size: 30,
                      color: Colors.red,
                      semanticLabel: 'Close artwork',
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ),
              ),
              child: const Text('Open artwork'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open artwork'));
    await tester.pumpAndSettle();
    expect(source!.icon, Icons.close);
    expect(source!.size, 30);
    expect(source!.color, Colors.red);
    expect(source!.textDirection, TextDirection.rtl);
    expect(find.bySemanticsLabel('Close artwork'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });
  testWidgets('null artwork keeps the glyph resolver fallback', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixIconTheme(
          resolve: (_) => Icons.star,
          builder: (_, _) => null,
          child: const MiuixThemedIcon(Icons.close, size: 24),
        ),
      ),
    );
    expect(tester.widget<Icon>(find.byType(Icon)).icon, Icons.star);
  });
}
