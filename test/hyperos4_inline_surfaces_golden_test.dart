import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('inline surfaces $mode ${brightness.name} visual baseline', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(440, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _InlineSurfaceFrame(brightness: brightness, source: source),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await expectLater(
          find.byKey(const ValueKey('inline-surface-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_inline_surfaces/${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _InlineSurfaceFrame extends StatelessWidget {
  const _InlineSurfaceFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  Widget build(BuildContext context) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff4a77ff),
      brightness: brightness,
    );
    return MiuixTheme(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorScheme: scheme, brightness: brightness),
        home: RepaintBoundary(
          key: const ValueKey('inline-surface-golden'),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: dark
                    ? const <Color>[
                        Color(0xff12172b),
                        Color(0xff242047),
                        Color(0xff102d37),
                      ]
                    : const <Color>[
                        Color(0xffd9e7ff),
                        Color(0xffffdfe9),
                        Color(0xffd7f5ed),
                      ],
              ),
            ),
            child: Stack(
              children: <Widget>[
                const Positioned(
                  top: 36,
                  right: -24,
                  child: _BackdropOrb(color: Color(0x996f8cff), size: 180),
                ),
                const Positioned(
                  bottom: 72,
                  left: -32,
                  child: _BackdropOrb(color: Color(0x88ff789e), size: 160),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          source ? 'Source' : 'HyperOS 4',
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: <Widget>[
                            _chip('Photos', selected: true),
                            _chip('Documents'),
                            _chip('Recent'),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _card(),
                        const SizedBox(height: 14),
                        _alert(),
                        const SizedBox(height: 14),
                        _banner(),
                        const SizedBox(height: 14),
                        _expandable(),
                        const SizedBox(height: 14),
                        _emptyState(),
                      ],
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

  Widget _chip(String label, {bool selected = false}) => source
      ? MiuixChip.source(
          label: label,
          selected: selected,
          variant: MiuixChipVariant.filter,
          onSelected: (_) {},
        )
      : MiuixChip(
          label: label,
          selected: selected,
          variant: MiuixChipVariant.filter,
          onSelected: (_) {},
        );

  Widget _alert() => source
      ? const MiuixInlineAlert.source(
          title: 'Connected',
          message: 'Files synced.',
          severity: MiuixAlertSeverity.success,
        )
      : const MiuixInlineAlert(
          title: 'Connected',
          message: 'Files synced.',
          severity: MiuixAlertSeverity.success,
        );

  Widget _card() => source
      ? MiuixCard.source(
          insideMargin: const EdgeInsets.all(16),
          content: const Row(
            children: <Widget>[
              Icon(Icons.folder_rounded),
              SizedBox(width: 10),
              Expanded(child: Text('Files', overflow: TextOverflow.ellipsis)),
            ],
          ),
        )
      : const MiuixCard(
          insideMargin: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.folder_rounded),
              SizedBox(width: 10),
              Expanded(child: Text('Files', overflow: TextOverflow.ellipsis)),
            ],
          ),
        );

  Widget _banner() => source
      ? const MiuixBanner.source(
          title: 'New layout',
          message: 'Compact view.',
          leading: Icon(Icons.auto_awesome_rounded),
        )
      : const MiuixBanner(
          title: 'New layout',
          message: 'Compact view.',
          leading: Icon(Icons.auto_awesome_rounded),
        );

  Widget _expandable() => source
      ? const MiuixExpandableCard.source(
          title: 'Options',
          subtitle: 'Expanded',
          initiallyExpanded: true,
          children: <Widget>[Text('Sync controls.')],
        )
      : const MiuixExpandableCard(
          title: 'Options',
          subtitle: 'Expanded',
          initiallyExpanded: true,
          children: <Widget>[Text('Sync controls.')],
        );

  Widget _emptyState() => source
      ? const MiuixEmptyState.source(
          title: 'No downloads',
          message: 'Saved files appear here.',
        )
      : const MiuixEmptyState(
          title: 'No downloads',
          message: 'Saved files appear here.',
        );
}

class _BackdropOrb extends StatelessWidget {
  const _BackdropOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
