import 'package:flutter/material.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final brightness in Brightness.values) {
    for (final source in <bool>[false, true]) {
      final mode = source ? 'source' : 'hyperos4';
      testWidgets('collection groups $mode ${brightness.name}', (tester) async {
        await tester.binding.setSurfaceSize(const Size(560, 700));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _CollectionGroupFrame(brightness: brightness, source: source),
        );
        await tester.pumpAndSettle();

        await expectLater(
          find.byKey(const ValueKey('collection-groups-golden')),
          matchesGoldenFile(
            'goldens/hyperos4_collection_groups/'
            '${mode}_${brightness.name}.png',
          ),
        );
      });
    }
  }
}

class _CollectionGroupFrame extends StatefulWidget {
  const _CollectionGroupFrame({required this.brightness, required this.source});

  final Brightness brightness;
  final bool source;

  @override
  State<_CollectionGroupFrame> createState() => _CollectionGroupFrameState();
}

class _CollectionGroupFrameState extends State<_CollectionGroupFrame> {
  late final MiuixTreeController<String> _treeController =
      MiuixTreeController<String>(
        expanded: const <String>['root'],
        selected: 'child',
      );

  @override
  void dispose() {
    _treeController.dispose();
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
      key: const ValueKey('collection-groups-golden'),
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
            child: Stack(
              children: <Widget>[
                const Positioned(
                  right: -38,
                  top: 94,
                  child: _CollectionOrb(size: 220, color: Color(0x887695ff)),
                ),
                const Positioned(
                  left: -46,
                  bottom: 64,
                  child: _CollectionOrb(size: 190, color: Color(0x88ff789e)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        widget.source
                            ? 'Source collections'
                            : 'HyperOS 4 lists',
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontSize: 27,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      _listSection(),
                      const SizedBox(height: 18),
                      _tree(),
                      const SizedBox(height: 18),
                      _reorderableItem(0, 'First destination'),
                      const SizedBox(height: 8),
                      _reorderableItem(1, 'Second destination'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _listSection() {
    const children = <Widget>[
      MiuixPreference(title: 'Cloud backup', summary: 'Every night'),
      MiuixPreference(title: 'Device sync', summary: 'Wi-Fi only'),
    ];
    const sourceChildren = <Widget>[
      MiuixPreference.source(title: 'Cloud backup', summary: 'Every night'),
      MiuixPreference.source(title: 'Device sync', summary: 'Wi-Fi only'),
    ];
    return widget.source
        ? const MiuixListSection.source(
            title: 'Synchronization',
            footer: 'Settings apply to this account.',
            children: sourceChildren,
          )
        : const MiuixListSection(
            title: 'Synchronization',
            footer: 'Settings apply to this account.',
            children: children,
          );
  }

  Widget _tree() {
    const nodes = <MiuixTreeNode<String>>[
      MiuixTreeNode<String>(
        value: 'root',
        label: 'Documents',
        children: <MiuixTreeNode<String>>[
          MiuixTreeNode<String>(value: 'child', label: 'Projects'),
        ],
      ),
    ];
    return widget.source
        ? MiuixTreeView<String>.source(
            controller: _treeController,
            nodes: nodes,
          )
        : MiuixTreeView<String>(controller: _treeController, nodes: nodes);
  }

  Widget _reorderableItem(int index, String label) => widget.source
      ? MiuixReorderableItem.source(index: index, child: Text(label))
      : MiuixReorderableItem(index: index, child: Text(label));
}

class _CollectionOrb extends StatelessWidget {
  const _CollectionOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
