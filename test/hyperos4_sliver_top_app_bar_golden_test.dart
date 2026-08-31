import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      for (final collapsed in <bool>[false, true]) {
        final mode = source ? 'source' : 'hyperos4';
        final state = collapsed ? 'collapsed' : 'expanded';
        testWidgets('sliver top bar $mode $state ${brightness.name}', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(const Size(520, 500));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _SliverTopBarFrame(
              brightness: brightness,
              source: source,
              collapsed: collapsed,
            ),
          );
          await tester.pumpAndSettle();

          await expectLater(
            find.byKey(const ValueKey('sliver-top-bar-golden')),
            matchesGoldenFile(
              'goldens/hyperos4_sliver_top_app_bar/'
              '${mode}_${state}_${brightness.name}.png',
            ),
          );
        });
      }
    }
  }
}

class _SliverTopBarFrame extends StatefulWidget {
  const _SliverTopBarFrame({
    required this.brightness,
    required this.source,
    required this.collapsed,
  });

  final Brightness brightness;
  final bool source;
  final bool collapsed;

  @override
  State<_SliverTopBarFrame> createState() => _SliverTopBarFrameState();
}

class _SliverTopBarFrameState extends State<_SliverTopBarFrame> {
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: widget.collapsed ? 80 : 0,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a77ff),
      brightness: widget.brightness,
    );
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    return RepaintBoundary(
      key: const ValueKey('sliver-top-bar-golden'),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: scheme,
          brightness: widget.brightness,
          fontFamily: 'Roboto',
        ),
        home: MiuixTheme(
          data: defaults.copyWith(
            textTheme: defaults.textTheme.apply(fontFamily: 'Roboto'),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const <Color>[
                        Color(0xff11182e),
                        Color(0xff302348),
                        Color(0xff12373f),
                      ]
                    : const <Color>[
                        Color(0xffd4e5ff),
                        Color(0xffffdae7),
                        Color(0xffcff3e8),
                      ],
              ),
            ),
            child: CustomScrollView(
              controller: _controller,
              slivers: <Widget>[
                widget.source
                    ? const MiuixSliverTopAppBar.source(
                        title: 'Library',
                        largeTitle: 'Components',
                      )
                    : const MiuixSliverTopAppBar(
                        title: 'Library',
                        largeTitle: 'Components',
                      ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  sliver: SliverList.builder(
                    itemCount: 8,
                    itemBuilder: (context, index) => _GoldenRow(
                      index: index,
                      color: index.isEven
                          ? const Color(0x807695ff)
                          : const Color(0x80ff789e),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldenRow extends StatelessWidget {
  const _GoldenRow({required this.index, required this.color});

  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 78,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .48),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Component ${index + 1}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      ],
    ),
  );
}
