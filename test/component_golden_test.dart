import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

enum _GoldenState {
  light,
  dark,
  pressed,
  disabled,
  expanded,
  animationMidpoint,
}

const _components = <String>[
  'Scaffold',
  'Surface',
  'TopAppBar',
  'NavigationBar',
  'FloatingNavigationBar',
  'NavigationRail',
  'TabRow',
  'Card',
  'BasicComponent',
  'Button',
  'IconButton',
  'Text',
  'SmallTitle',
  'TextField',
  'Switch',
  'Checkbox',
  'RadioButton',
  'Slider',
  'NumberPicker',
  'ProgressIndicator',
  'Snackbar',
  'Tooltip',
  'Badge',
  'Icon',
  'FloatingActionButton',
  'FloatingToolbar',
  'Divider',
  'PullToRefresh',
  'SearchBar',
  'ColorPalette',
  'ColorPicker',
  'ArrowPreference',
  'SwitchPreference',
  'CheckboxPreference',
  'RadioButtonPreference',
  'SliderPreference',
  'RangeSliderPreference',
  'OverlayListPopup',
  'OverlayCascadingListPopup',
  'OverlayDropdownPreference',
  'OverlaySpinnerPreference',
  'OverlayDropdownMenu',
  'OverlayIconDropdownMenu',
  'OverlayIconCascadingDropdownMenu',
  'OverlayBottomSheet',
  'OverlayDialog',
  'WindowListPopup',
  'WindowCascadingListPopup',
  'WindowDropdownPreference',
  'WindowSpinnerPreference',
  'WindowDropdownMenu',
  'WindowIconDropdownMenu',
  'WindowIconCascadingDropdownMenu',
  'WindowBottomSheet',
  'WindowDialog',
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);
  setUp(() {
    debugPaintSizeEnabled = false;
    debugPaintBaselinesEnabled = false;
    debugPaintPointersEnabled = false;
    debugPaintLayerBordersEnabled = false;
  });

  for (final component in _components) {
    testWidgets('$component has six visual baselines', (tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 420));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final state in _GoldenState.values) {
        await tester.pumpWidget(
          _GoldenFrame(component: component, state: state),
        );
        await tester.pump();
        // Flush post-frame hosts (Snackbar/Tooltip/Popup) before choosing the
        // exact frame to capture.
        await tester.pump();
        if (state != _GoldenState.animationMidpoint) {
          await tester.pump(const Duration(milliseconds: 220));
        }

        TestGesture? press;
        if (state == _GoldenState.pressed ||
            state == _GoldenState.animationMidpoint) {
          final target = find.byKey(const ValueKey('golden-component-target'));
          press = await tester.startGesture(tester.getCenter(target));
          if (component == 'Slider') {
            // Source sliders begin their visual feedback only after draggable
            // crosses slop; a stationary pointer is deliberately a no-op.
            await press.moveBy(const Offset(24, 0));
          }
          if (component == 'FloatingNavigationBar' &&
              state == _GoldenState.animationMidpoint) {
            // The interaction midpoint captures the smaller direct-drag slider
            // halfway between two otherwise equal destinations.
            await press.moveBy(const Offset(44, 0));
          }
          if (state == _GoldenState.animationMidpoint &&
              component == 'PullToRefresh') {
            await press.moveBy(const Offset(0, 64));
          }
          await tester.pump();
          await tester.pump(
            state == _GoldenState.animationMidpoint
                ? const Duration(milliseconds: 90)
                : const Duration(milliseconds: 16),
          );
        } else if (state == _GoldenState.expanded) {
          final target = find.byKey(const ValueKey('golden-component-target'));
          if (component == 'Tooltip') {
            press = await tester.startGesture(tester.getCenter(target));
            await _pumpGoldenFrames(tester, const Duration(milliseconds: 600));
            await tester.pump();
            await _pumpGoldenFrames(tester, const Duration(milliseconds: 220));
          } else if (_routeExpansionComponents.contains(component)) {
            await tester.tap(target);
            await tester.pump();
            // DialogContentLayout uses a physical spring whose last few pixels
            // settle after the shorter popup transitions have completed.
            await _pumpGoldenFrames(
              tester,
              component.contains('Dialog')
                  ? const Duration(milliseconds: 600)
                  : component.contains('BottomSheet')
                  // BottomSheetContentLayout.kt drives both the panel and the
                  // dim layer with the source 0.9/0.38 Folme spring. Capture
                  // the stable expanded state instead of an arbitrary frame
                  // from the former 220ms approximation.
                  ? const Duration(milliseconds: 720)
                  // ListPopup.kt settles its 362.5/.82 fraction spring after
                  // the shorter 200ms alpha and 300ms dim clocks.
                  : const Duration(milliseconds: 650),
            );
            // A quick click lets the positive indication spring finish before
            // its release spring starts. List popups are already settled
            // above, so these final frames affect only the trigger indication.
            // Anchors held for an open route retain one 10% channel; current
            // MiuixIndication does not stack a stale pointer channel with it.
            //
            // BottomSheet uses the longer source physical spring. It has
            // already reached the stable expanded baseline above, so these
            // frames continue to affect only shorter trigger indications.
            if (!component.contains('BottomSheet')) {
              await _pumpGoldenFrames(tester, const Duration(milliseconds: 24));
            }
            if (component.contains('BottomSheet')) {
              expect(find.text('$component content'), findsOneWidget);
            } else if (component.contains('Dialog')) {
              expect(find.byType(MiuixDialog), findsOneWidget);
            } else if (component.contains('Cascading')) {
              expect(find.byType(MiuixCascadingMenu<String>), findsOneWidget);
            } else {
              expect(find.byType(MiuixListPopup<String>), findsOneWidget);
            }
          }
        }

        final image = await _captureFullSurface(tester);
        try {
          await expectLater(
            image,
            matchesGoldenFile('goldens/${_slug(component)}/${state.name}.png'),
          );
        } finally {
          image.dispose();
        }
        await press?.cancel();
        // Several documented components intentionally animate forever (for
        // example the indeterminate progress indicator). A bounded frame also
        // prevents a released press from opening a popup after its pressed
        // baseline has already been captured.
        await tester.pump(const Duration(milliseconds: 250));
      }
    });
  }

  test('golden manifest covers every documented component exactly once', () {
    expect(_components, hasLength(55));
    expect(_components.toSet(), hasLength(55));
    expect(_GoldenState.values, hasLength(6));
  });

  test('state drivers produce distinct frames where states are applicable', () {
    bool differs(String component, String first, String second) {
      final directory = 'test/goldens/${_slug(component)}';
      final firstBytes = File('$directory/$first.png').readAsBytesSync();
      final secondBytes = File('$directory/$second.png').readAsBytesSync();
      return !listEquals(firstBytes, secondBytes);
    }

    for (final component in const [
      'Button',
      'Surface',
      'SwitchPreference',
      'Slider',
      'OverlayDropdownMenu',
      'WindowDropdownMenu',
    ]) {
      expect(
        differs(component, 'light', 'pressed'),
        isTrue,
        reason: '$component must capture real pointer-down feedback.',
      );
      expect(
        differs(component, 'light', 'animationMidpoint'),
        isTrue,
        reason: '$component must capture a real animation midpoint.',
      );
    }

    // Card keeps the source's disabled sink/indication defaults, but the
    // HyperOS 4 glass default now contributes a local contact-light response.
    // Both held frames must therefore differ from the idle glass surface.
    expect(differs('Card', 'light', 'pressed'), isTrue);
    expect(differs('Card', 'light', 'animationMidpoint'), isTrue);

    for (final component in const [
      'Button',
      'Switch',
      'Checkbox',
      'RadioButton',
      'Slider',
      'NumberPicker',
      'SwitchPreference',
      'OverlayDropdownPreference',
      'WindowDropdownPreference',
    ]) {
      expect(
        differs(component, 'light', 'disabled'),
        isTrue,
        reason: '$component must capture its native disabled state.',
      );
    }

    for (final component in _routeExpansionComponents) {
      expect(
        differs(component, 'light', 'expanded'),
        isTrue,
        reason: '$component must capture its actual open popup route.',
      );
    }

    for (final component in const [
      'Snackbar',
      'ProgressIndicator',
      'PullToRefresh',
    ]) {
      expect(
        differs(component, 'light', 'animationMidpoint'),
        isTrue,
        reason: '$component must capture an in-flight animation frame.',
      );
    }
  });
}

/// Advances an interaction duration with device-like frames.
///
/// A single large test-clock jump reaches the correct route timestamp but
/// starves asynchronous indication continuations until the jump has ended.
/// Sixteen-millisecond slices preserve the same total route time while letting
/// MIUIX's positive-then-resting indication sequence run as it does on device.
Future<void> _pumpGoldenFrames(WidgetTester tester, Duration duration) async {
  const frame = Duration(milliseconds: 16);
  var elapsed = Duration.zero;
  while (elapsed + frame <= duration) {
    await tester.pump(frame);
    elapsed += frame;
  }
  final remainder = duration - elapsed;
  if (remainder > Duration.zero) {
    await tester.pump(remainder);
  }
}

Future<ui.Image> _captureFullSurface(WidgetTester tester) {
  final renderView = tester.binding.renderViews.first;
  final layer = renderView.debugLayer! as OffsetLayer;
  return layer.toImage(renderView.paintBounds);
}

Future<void> _loadGoldenFonts() async {
  final materialFonts = _findMaterialFontDirectory();

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final name in files) {
      final bytes = await File(
        '${materialFonts.path}${Platform.pathSeparator}$name',
      ).readAsBytes();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await load('Roboto', const [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
  ]);
  await load('MaterialIcons', const ['materialicons-regular.otf']);
  final basicBytes = await File(
    '${Directory.current.path}${Platform.pathSeparator}assets'
    '${Platform.pathSeparator}fonts${Platform.pathSeparator}'
    'MiuixIcons-Basic.ttf',
  ).readAsBytes();
  await (FontLoader(
    'packages/flutter_miuix/MiuixIconsBasic',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(basicBytes)))).load();
}

Directory _findMaterialFontDirectory() {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'];
  final candidates = <Directory>[
    if (flutterRoot != null)
      Directory(
        '$flutterRoot${Platform.pathSeparator}bin${Platform.pathSeparator}'
        'cache${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
        'material_fonts',
      ),
  ];
  var cursor = File(Platform.resolvedExecutable).parent;
  for (var depth = 0; depth < 8; depth++) {
    candidates.addAll([
      Directory(
        '${cursor.path}${Platform.pathSeparator}artifacts'
        '${Platform.pathSeparator}material_fonts',
      ),
      Directory(
        '${cursor.path}${Platform.pathSeparator}cache'
        '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
        'material_fonts',
      ),
    ]);
    cursor = cursor.parent;
  }
  return candidates.firstWhere(
    (directory) => File(
      '${directory.path}${Platform.pathSeparator}roboto-regular.ttf',
    ).existsSync(),
    orElse: () => throw StateError(
      'Could not locate Flutter material fonts for golden tests.',
    ),
  );
}

const _routeExpansionComponents = <String>{
  'OverlayDropdownPreference',
  'OverlaySpinnerPreference',
  'OverlayDropdownMenu',
  'OverlayIconDropdownMenu',
  'OverlayIconCascadingDropdownMenu',
  'OverlayBottomSheet',
  'OverlayDialog',
  'WindowDropdownPreference',
  'WindowSpinnerPreference',
  'WindowDropdownMenu',
  'WindowIconDropdownMenu',
  'WindowIconCascadingDropdownMenu',
  'WindowBottomSheet',
  'WindowDialog',
};

String _slug(String value) {
  return value.replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (match) {
    return '${match.group(1)}_${match.group(2)}';
  }).toLowerCase();
}

class _GoldenFrame extends StatelessWidget {
  const _GoldenFrame({required this.component, required this.state});

  final String component;
  final _GoldenState state;

  @override
  Widget build(BuildContext context) {
    final dark = state == _GoldenState.dark;
    final defaults = MiuixThemeData.defaults(
      mode: dark ? MiuixColorMode.dark : MiuixColorMode.light,
    );
    final theme = defaults.copyWith(
      textTheme: defaults.textTheme.apply(fontFamily: 'Roboto'),
    );
    return Center(
      child: RepaintBoundary(
        key: const ValueKey('golden-boundary'),
        child: SizedBox(
          width: 440,
          height: 380,
          child: MaterialApp(
            key: ValueKey('golden-app-${state.name}'),
            debugShowCheckedModeBanner: false,
            home: MiuixTheme(
              data: theme,
              child: Material(
                type: MaterialType.transparency,
                child: MiuixPopupHost.scope(
                  child: Builder(
                    builder: (context) {
                      final scheme = Theme.of(context).colorScheme;
                      return ColoredBox(
                        color: scheme.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: KeyedSubtree(
                              key: const ValueKey('golden-component-target'),
                              child: _GoldenComponent(
                                key: ValueKey('component-${state.name}'),
                                name: component,
                                state: state,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldenComponent extends StatefulWidget {
  const _GoldenComponent({super.key, required this.name, required this.state});

  final String name;
  final _GoldenState state;

  @override
  State<_GoldenComponent> createState() => _GoldenComponentState();
}

class _GoldenComponentState extends State<_GoldenComponent> {
  bool toggle = true;
  double value = .58;
  RangeValues range = const RangeValues(.24, .76);
  int number = 5;
  String choice = 'one';
  Color color = const Color(0xFF3482FF);
  late final TextEditingController textController;

  bool get disabled => widget.state == _GoldenState.disabled;
  bool get expanded => widget.state == _GoldenState.expanded;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController(text: 'MIUIX');
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  List<MiuixDropdownEntry<String>> get entries => const [
    MiuixDropdownEntry(
      value: 'one',
      label: 'First option',
      icon: Icon(Icons.star),
    ),
    MiuixDropdownEntry(value: 'two', label: 'Second option'),
  ];

  List<MiuixCascadingMenuItem<String>> get cascading => const [
    MiuixCascadingMenuItem(
      label: 'Display',
      icon: Icon(Icons.display_settings),
      children: [
        MiuixDropdownEntry(value: 'light', label: 'Light'),
        MiuixDropdownEntry(value: 'dark', label: 'Dark'),
      ],
    ),
  ];

  VoidCallback? get action => disabled ? null : () {};

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    return switch (widget.name) {
      'Scaffold' => SizedBox(
        width: 360,
        height: 300,
        child: MiuixScaffold(
          topBar: const MiuixTopAppBar(title: 'MIUIX'),
          bottomBar: MiuixNavigationBar(
            items: const [
              MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
              MiuixNavigationItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (_) {},
          ),
          floatingActionButton: MiuixFloatingActionButton(
            icon: const Icon(Icons.add),
            onPressed: action,
          ),
          body: const Center(child: Text('Content')),
        ),
      ),
      'Surface' => MiuixSurface(onTap: action, child: const Text('Surface')),
      'TopAppBar' => const SizedBox(
        width: 360,
        child: MiuixTopAppBar(
          title: 'Settings',
          leading: Icon(Icons.arrow_back),
          actions: [Icon(Icons.more_horiz)],
        ),
      ),
      'NavigationBar' => SizedBox(
        width: 360,
        child: MiuixNavigationBar(
          items: const [
            MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
            MiuixNavigationItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
      ),
      'FloatingNavigationBar' => SizedBox(
        width: 360,
        child: MiuixFloatingNavigationBar(
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
          selectedIndex: expanded ? 1 : 0,
          onDestinationSelected: (_) {},
        ),
      ),
      'NavigationRail' => SizedBox(
        height: 220,
        child: MiuixNavigationRail(
          items: const [
            MiuixNavigationItem(icon: Icon(Icons.home), label: 'Home'),
            MiuixNavigationItem(icon: Icon(Icons.settings), label: 'Settings'),
          ],
          selectedIndex: 0,
          extended: expanded,
          onDestinationSelected: (_) {},
        ),
      ),
      'TabRow' => const MiuixTabRowWithContour(tabs: ['One', 'Two', 'Three']),
      'Card' => MiuixCard(
        onTap: action,
        child: const Padding(padding: EdgeInsets.all(20), child: Text('Card')),
      ),
      'BasicComponent' => MiuixBasicComponent(
        title: 'Wi-Fi',
        summary: 'Connected',
        enabled: !disabled,
        trailing: const Icon(Icons.chevron_right),
      ),
      'Button' => MiuixButton(
        label: 'Continue',
        icon: const Icon(Icons.arrow_forward),
        onPressed: action,
      ),
      'IconButton' => IconTheme(
        // The controller-backed upstream MiuixTheme publishes onBackground as
        // LocalContentColor. IconButton itself must only inherit that local.
        data: IconThemeData(color: semantic['onBackground']),
        child: MiuixIconButton(
          icon: const Icon(Icons.favorite),
          selected: expanded,
          onPressed: action,
        ),
      ),
      'Text' => const MiuixText(
        'MIUIX typography',
        style: TextStyle(fontSize: 24),
      ),
      'SmallTitle' => const MiuixSmallTitle('Small title'),
      'TextField' => IgnorePointer(
        ignoring: disabled,
        child: Opacity(
          opacity: disabled ? .38 : 1,
          child: MiuixTextField(controller: textController, label: 'Account'),
        ),
      ),
      'Switch' => MiuixSwitch(
        value: toggle,
        enabled: !disabled,
        onChanged: disabled ? (_) {} : (next) => setState(() => toggle = next),
      ),
      'Checkbox' => MiuixCheckbox(
        value: toggle,
        enabled: !disabled,
        onChanged: disabled
            ? null
            : (next) => setState(() => toggle = next ?? false),
      ),
      'RadioButton' => MiuixRadioButton<int>(
        value: 1,
        groupValue: toggle ? 1 : 0,
        enabled: !disabled,
        onChanged: disabled ? null : (_) => setState(() => toggle = !toggle),
      ),
      'Slider' => SizedBox(
        width: 320,
        child: MiuixSlider(
          value: value,
          enabled: !disabled,
          onChanged: disabled ? (_) {} : (next) => setState(() => value = next),
        ),
      ),
      'NumberPicker' => MiuixNumberPicker(
        value: number,
        min: 0,
        max: 10,
        enabled: !disabled,
        wrapAround: expanded,
        onChanged: (next) => setState(() => number = next),
      ),
      'ProgressIndicator' => SizedBox(
        width: 300,
        child: MiuixProgressIndicator(
          value: expanded || widget.state == _GoldenState.animationMidpoint
              ? null
              : .64,
        ),
      ),
      'Snackbar' => _GoldenSnackbar(disabled: disabled, expanded: expanded),
      'Tooltip' => MiuixTooltip(
        message: 'Helpful tooltip',
        child: MiuixButton(label: 'Hover or hold', onPressed: action),
      ),
      'Badge' => const MiuixBadgedBox(
        badge: MiuixBadge(label: '8', child: SizedBox.shrink()),
        child: Icon(Icons.notifications, size: 32),
      ),
      'Icon' => const MiuixIcon(Icons.palette, size: 36),
      'FloatingActionButton' => MiuixFloatingActionButton(
        icon: const Icon(Icons.add),
        label: expanded ? 'Create' : null,
        onPressed: action,
      ),
      'FloatingToolbar' => IconTheme(
        // FloatingToolbar.kt deliberately does not provide a content local.
        // Reproduce the controller-backed MiuixTheme's onBackground local at
        // the fixture boundary instead of making IconButton invent one.
        data: IconThemeData(color: semantic['onBackground']),
        child: MiuixFloatingToolbar(
          children: [
            MiuixIconButton(icon: const Icon(Icons.copy), onPressed: action),
            MiuixIconButton(icon: const Icon(Icons.share), onPressed: action),
          ],
        ),
      ),
      'Divider' => const SizedBox(width: 320, child: MiuixDivider()),
      'PullToRefresh' => SizedBox(
        width: 340,
        height: 260,
        child: MiuixPullToRefresh(
          onRefresh: () async {},
          child: ListView(
            children: const [
              SizedBox(
                height: 80,
                child: Center(child: Text('Pull to refresh')),
              ),
            ],
          ),
        ),
      ),
      'SearchBar' => SizedBox(
        width: 340,
        child: IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? .38 : 1,
            child: MiuixSearchBar(controller: textController),
          ),
        ),
      ),
      'ColorPalette' => SizedBox(
        width: 340,
        child: MiuixColorPalette.hsv(
          color: color,
          onColorChanged: disabled
              ? (_) {}
              : (next) => setState(() => color = next),
        ),
      ),
      'ColorPicker' => SizedBox(
        width: 340,
        child: MiuixColorPicker(
          color: color,
          colorSpace: expanded ? MiuixColorSpace.okLch : MiuixColorSpace.hsv,
          onChanged: disabled ? (_) {} : (next) => setState(() => color = next),
        ),
      ),
      'ArrowPreference' => MiuixArrowPreference(
        title: 'About phone',
        summary: 'MIUIX device',
        enabled: !disabled,
        onTap: action,
      ),
      'SwitchPreference' => MiuixSwitchPreference(
        title: 'Bluetooth',
        value: toggle,
        enabled: !disabled,
        onChanged: disabled ? (_) {} : (next) => setState(() => toggle = next),
      ),
      'CheckboxPreference' => MiuixCheckboxPreference(
        title: 'Sync automatically',
        value: toggle,
        enabled: !disabled,
        onChanged: disabled ? (_) {} : (next) => setState(() => toggle = next),
      ),
      'RadioButtonPreference' => MiuixRadioButtonPreference<String>(
        title: 'Balanced',
        value: 'one',
        groupValue: choice,
        enabled: !disabled,
        onChanged: disabled
            ? (_) {}
            : (next) => setState(() => choice = next ?? choice),
      ),
      'SliderPreference' => SizedBox(
        width: 360,
        child: MiuixSliderPreference(
          title: 'Volume',
          value: value,
          enabled: !disabled,
          onChanged: disabled ? (_) {} : (next) => setState(() => value = next),
        ),
      ),
      'RangeSliderPreference' => SizedBox(
        width: 360,
        child: MiuixRangeSliderPreference(
          title: 'Range',
          values: range,
          enabled: !disabled,
          onChanged: disabled ? (_) {} : (next) => setState(() => range = next),
        ),
      ),
      'OverlayListPopup' => MiuixOverlayListPopup<String>(
        entries: entries,
        onSelected: (_) {},
      ),
      'OverlayCascadingListPopup' => MiuixOverlayCascadingListPopup<String>(
        items: cascading,
        onSelected: (_) {},
      ),
      'OverlayDropdownPreference' => MiuixOverlayDropdownPreference<String>(
        title: 'Overlay dropdown',
        value: choice,
        entries: entries,
        enabled: !disabled,
        onChanged: (_) {},
      ),
      'OverlaySpinnerPreference' => MiuixOverlaySpinnerPreference<String>(
        title: 'Overlay spinner',
        value: choice,
        entries: entries,
        enabled: !disabled,
        onChanged: (_) {},
      ),
      'OverlayDropdownMenu' => MiuixOverlayDropdownMenu<String>(
        entries: entries,
        enabled: !disabled,
        onSelected: (_) {},
        child: const Text('Overlay menu'),
      ),
      'OverlayIconDropdownMenu' => MiuixOverlayIconDropdownMenu<String>(
        icon: const Icon(Icons.more_horiz),
        entries: entries,
        enabled: !disabled,
        onSelected: (_) {},
      ),
      'OverlayIconCascadingDropdownMenu' =>
        MiuixOverlayIconCascadingDropdownMenu<String>(
          icon: const Icon(Icons.more_vert),
          items: cascading,
          enabled: !disabled,
          onSelected: (_) {},
        ),
      'OverlayBottomSheet' =>
        expanded
            ? Builder(
                builder: (context) => MiuixButton(
                  label: 'Open overlay sheet',
                  onPressed: () {
                    MiuixOverlayBottomSheet.show<void>(
                      context: context,
                      child: const Text('OverlayBottomSheet content'),
                    );
                  },
                ),
              )
            : const _GoldenSheet(label: 'Overlay bottom sheet'),
      'OverlayDialog' =>
        expanded
            ? Builder(
                builder: (context) => MiuixButton(
                  label: 'Open overlay dialog',
                  onPressed: () {
                    MiuixOverlayDialog.show<void>(
                      context: context,
                      title: 'Overlay dialog',
                      content: const Text('OverlayDialog content'),
                    );
                  },
                ),
              )
            : const MiuixDialog(
                title: 'Overlay dialog',
                content: Text('Dialog content'),
              ),
      'WindowListPopup' => MiuixWindowListPopup<String>(
        entries: entries,
        onSelected: (_) {},
      ),
      'WindowCascadingListPopup' => MiuixWindowCascadingListPopup<String>(
        items: cascading,
        onSelected: (_) {},
      ),
      'WindowDropdownPreference' => MiuixWindowDropdownPreference<String>(
        title: 'Window dropdown',
        value: choice,
        entries: entries,
        enabled: !disabled,
        onChanged: (_) {},
      ),
      'WindowSpinnerPreference' => MiuixWindowSpinnerPreference<String>(
        title: 'Window spinner',
        value: choice,
        entries: entries,
        enabled: !disabled,
        onChanged: (_) {},
      ),
      'WindowDropdownMenu' => MiuixWindowDropdownMenu<String>(
        entries: entries,
        enabled: !disabled,
        onSelected: (_) {},
        child: const Text('Window menu'),
      ),
      'WindowIconDropdownMenu' => MiuixWindowIconDropdownMenu<String>(
        icon: const Icon(Icons.more_horiz),
        entries: entries,
        enabled: !disabled,
        onSelected: (_) {},
      ),
      'WindowIconCascadingDropdownMenu' =>
        MiuixWindowIconCascadingDropdownMenu<String>(
          icon: const Icon(Icons.more_vert),
          items: cascading,
          enabled: !disabled,
          onSelected: (_) {},
        ),
      'WindowBottomSheet' =>
        expanded
            ? Builder(
                builder: (context) => MiuixButton(
                  label: 'Open window sheet',
                  onPressed: () {
                    MiuixWindowBottomSheet.show<void>(
                      context: context,
                      child: const Text('WindowBottomSheet content'),
                    );
                  },
                ),
              )
            : const _GoldenSheet(label: 'Window bottom sheet'),
      'WindowDialog' =>
        expanded
            ? Builder(
                builder: (context) => MiuixButton(
                  label: 'Open window dialog',
                  onPressed: () {
                    MiuixWindowDialog.show<void>(
                      context: context,
                      title: 'Window dialog',
                      content: const Text('WindowDialog content'),
                    );
                  },
                ),
              )
            : const MiuixDialog(
                title: 'Window dialog',
                content: Text('Dialog content'),
              ),
      _ => Text(widget.name),
    };
  }
}

class _GoldenSheet extends StatelessWidget {
  const _GoldenSheet({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: MiuixSurface(
        radius: 28,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _GoldenSnackbar extends StatefulWidget {
  const _GoldenSnackbar({required this.disabled, required this.expanded});

  final bool disabled;
  final bool expanded;

  @override
  State<_GoldenSnackbar> createState() => _GoldenSnackbarState();
}

class _GoldenSnackbarState extends State<_GoldenSnackbar> {
  late final MiuixSnackbarHostState state;

  @override
  void initState() {
    super.initState();
    state = MiuixSnackbarHostState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      state.showSnackbar(
        widget.disabled ? 'Disabled state' : 'Settings saved',
        actionLabel: widget.expanded ? 'Undo' : null,
        withDismissAction: widget.expanded,
        duration: MiuixSnackbarDuration.indefinite,
      );
    });
  }

  @override
  void dispose() {
    state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 380,
      height: 120,
      child: MiuixSnackbarHost(state: state),
    );
  }
}
