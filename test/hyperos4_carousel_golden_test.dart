import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('carousel $mode ${brightness.name} visual baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(440, 280));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _CarouselFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('carousel-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_carousel/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _CarouselFrame extends StatelessWidget {
  const _CarouselFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a77ff),
      brightness: brightness,
    );
    final pages = <Widget>[
      _CarouselCard(color: scheme.primaryContainer, label: 'Files'),
      _CarouselCard(color: scheme.secondaryContainer, label: 'Photos'),
      _CarouselCard(color: scheme.tertiaryContainer, label: 'Recent'),
    ];
    final carousel = source
        ? MiuixCarousel.source(
            height: 180,
            viewportFraction: .86,
            children: pages,
          )
        : MiuixCarousel(height: 180, viewportFraction: .86, children: pages);
    return MiuixTheme(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, brightness: brightness),
        home: RepaintBoundary(
          key: const ValueKey('carousel-golden'),
          child: ColoredBox(
            color: scheme.surface,
            child: Center(child: carousel),
          ),
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(
        child: Text(label, style: Theme.of(context).textTheme.headlineSmall),
      ),
    ),
  );
}
