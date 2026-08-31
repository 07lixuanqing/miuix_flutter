import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';
import 'package:miuix_flutter_example/main.dart';

/// Advances the source-style lazy list until a late section has been built.
///
/// `scrollUntilVisible` requires the target element to exist already. The
/// example deliberately uses `ListView.builder`, so sections after the large
/// dropdown, slider, and color-picker fixtures are absent from the element
/// tree until scrolling reaches their neighborhood.
Future<void> _scrollUntilBuilt(
  WidgetTester tester,
  Finder scrollable,
  Finder target, {
  double delta = 240,
  int maxAttempts = 400,
}) async {
  final position = tester.state<ScrollableState>(scrollable).position;
  for (
    var attempt = 0;
    attempt < maxAttempts && target.evaluate().isEmpty;
    attempt++
  ) {
    final next = math.min(position.pixels + delta, position.maxScrollExtent);
    position.jumpTo(next);
    // A single frame builds the next lazy section and refreshes the estimated
    // maximum extent before the following step.
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadReferenceFonts);

  test('Android build number stays monotonic for overwrite installs', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final versionMatch = RegExp(
      r'^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$',
      multiLine: true,
    ).firstMatch(pubspec);

    // Encode semantic versions as major*10000 + minor*100 + patch. This keeps
    // every normal version bump monotonic and prevents Android from rejecting
    // a freshly built APK as a downgrade of an older distributed test build.
    expect(versionMatch, isNotNull);
    final major = int.parse(versionMatch!.group(1)!);
    final minor = int.parse(versionMatch.group(2)!);
    final patch = int.parse(versionMatch.group(3)!);
    final buildNumber = int.parse(versionMatch.group(4)!);
    final minimumBuildNumber = major * 10000 + minor * 100 + patch;
    expect(buildNumber, greaterThanOrEqualTo(minimumBuildNumber));
    expect(buildNumber, greaterThan(10007));

    // The release builder must also repair Flutter's generated Gradle fallback.
    // A split arm64 build otherwise leaves its pre-offset base here, causing a
    // later direct Gradle build to be rejected as a 2000-point downgrade.
    final localProperties = File('android/local.properties').readAsStringSync();
    final localBuildNumber = int.parse(
      RegExp(
        r'^flutter\.versionCode=(\d+)\s*$',
        multiLine: true,
      ).firstMatch(localProperties)!.group(1)!,
    );
    expect(localBuildNumber, greaterThanOrEqualTo(buildNumber));

    // ABI split offsets differ, so pubspec monotonicity alone cannot guarantee
    // that arm64 replaces an x86_64 diagnostic build. The install path must
    // read the target package and raise its base beyond the live version code.
    final releaseBuilder = File(
      '../tool/build_android_arm64_release.ps1',
    ).readAsStringSync();
    expect(releaseBuilder, contains('shell dumpsys package \$packageName'));
    expect(releaseBuilder, contains('\$installedVersionCode + 1'));
  });

  test('FPS monitor matches the source rolling statistics and health ramp', () {
    final durations = <int>[...List<int>.filled(99, 10000), 100000];
    final stats = computeReferenceFpsStats(durations);

    // One 100ms frame is the slowest one percent of this 100-frame window.
    expect(stats.average, 91);
    expect(stats.lowOnePercent, 10);
    expect(referenceFpsHealthColor(0, 100), Colors.grey);
    expect(referenceFpsHealthColor(49, 100), const Color(0xFFFF5B29));
    expect(referenceFpsHealthColor(50, 100), const Color(0xFFFF5B29));
    expect(referenceFpsHealthColor(75, 100), const Color(0xFFFFB21D));
    expect(referenceFpsHealthColor(100, 100), const Color(0xFF36D167));
  });

  test('effect shader accepts both source background domains', () {
    final shader = File(
      'shaders/miuix_effect_background.frag',
    ).readAsStringSync();

    // ForegroundBlurDemo.kt resolves uBound to (0, 0, 1, 1), while AboutPage
    // retains the ordinary (0, 0.22, 1, 0.78) domain. A single hard-coded
    // transform can match only one of those two original call sites.
    expect(shader, contains('uniform vec4 u_bound;'));
    expect(shader, contains('vec2 uv = v_uv;'));
    expect(shader, contains('uv -= u_bound.xy;'));
    expect(shader, contains('uv /= u_bound.zw;'));
    expect(shader, isNot(contains('uv -= vec2(0.0, 0.22)')));
    expect(shader, isNot(contains('uv /= vec2(1.0, 0.78)')));
  });

  test('pull-to-refresh route forwards scroll-end haptic setting', () {
    final source = File(
      'lib/reference_home_feedback_sections.dart',
    ).readAsStringSync();

    // The original page reads LocalAppState instead of forcing haptics on.
    // Keep the Flutter route connected to the same app-level preference so
    // disabling the setting also disables the pull-to-refresh edge feedback.
    expect(source, contains('enableScrollEndHaptic: enableScrollEndHaptic'));
    expect(
      source,
      isNot(
        contains(
          'const _ReferencePullToRefreshPage(enableScrollEndHaptic: true)',
        ),
      ),
    );
  });

  test(
    'source external links forward the exact URI without invented UI',
    () async {
      Uri? received;
      final opened = await debugReferenceOpenExternalUrl(
        'https://github.com/compose-miuix-ui/miuix',
        launcher: (uri) async {
          received = uri;
          return true;
        },
      );
      expect(opened, isTrue);
      expect(received, Uri.parse('https://github.com/compose-miuix-ui/miuix'));

      // LocalUriHandler does not display a fallback notification. A missing
      // platform handler is therefore represented only by a false result.
      expect(
        await debugReferenceOpenExternalUrl(
          'https://github.com/compose-miuix-ui/miuix',
          launcher: (_) => throw StateError('no handler'),
        ),
        isFalse,
      );
      final shellSource = File('lib/main.dart').readAsStringSync();
      expect(
        shellSource,
        contains("'https://github.com/compose-miuix-ui/miuix'"),
      );
      expect(
        shellSource,
        isNot(contains("MiuixToast.show(context, 'GitHub')")),
      );
    },
  );

  testWidgets('example exposes the five localized original pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> expectSourceScrollBar({
      required String barKey,
      required Key listKey,
      bool expectThumb = true,
    }) async {
      final bar = find.byKey(ValueKey(barKey));
      final list = find.byKey(listKey);
      expect(bar, findsOneWidget);
      expect(list, findsOneWidget);
      final barWidget = tester.widget<MiuixVerticalScrollBar>(bar);
      final listWidget = tester.widget<ListView>(list);
      expect(barWidget.controller, isNotNull);
      expect(identical(barWidget.controller, listWidget.controller), isTrue);
      await tester.drag(list, const Offset(0, -80));
      await tester.pump();
      if (expectThumb) {
        expect(
          find.descendant(
            of: bar,
            matching: find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
          ),
          findsOneWidget,
        );
      }
    }

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    expect(
      tester
          .widgetList<ScrollConfiguration>(find.byType(ScrollConfiguration))
          .any(
            (configuration) =>
                configuration.behavior is MiuixScrollBehavior &&
                !(configuration.behavior as MiuixScrollBehavior).showScrollbars,
          ),
      isTrue,
    );
    expect(find.byType(GlowingOverscrollIndicator), findsNothing);
    expect(find.byType(StretchingOverscrollIndicator), findsNothing);

    // The original example has five persistent destinations. The Flutter
    // version keeps their order while translating the visible labels.
    for (final label in const ['主页', '图标', '颜色', '文本样式', '设置']) {
      expect(find.text(label), findsWidgets);
    }
    final navigation = tester.widget<MiuixIosLiquidGlassNavigationBar>(
      find.byType(MiuixIosLiquidGlassNavigationBar),
    );
    final homeIcon = navigation.items.first.icon as Icon;
    expect(homeIcon.icon, MiuixExtendedIconCatalog.find('Home')!.regular);
    final iconDestination = navigation.items[1].icon as Icon;
    expect(
      iconDestination.icon,
      MiuixExtendedIconCatalog.find('Create')!.regular,
    );
    final textStyleDestination = navigation.items[3].icon as Icon;
    expect(
      textStyleDestination.icon,
      MiuixExtendedIconCatalog.find('Edit')!.regular,
    );
    final searchSectionTitle = tester.widget<Text>(find.text('搜索栏'));
    expect(searchSectionTitle.style?.fontSize, 15);
    expect(searchSectionTitle.style?.fontWeight, FontWeight.w600);
    expect(searchSectionTitle.style?.color, const Color(0xCC000000));
    expect(find.text('文字样式'), findsNothing);
    expect(find.text('搜索栏'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);

    // Compose BasicComponent leaves action content styling to the caller. The
    // source sample supplies its 14sp, 40%-opacity action role explicitly, so
    // the translated sample must not inherit the much darker body text color.
    final tailAction = tester.widgetList<Text>(find.text('尾部一')).first;
    final actionContext = tester.element(find.text('尾部一').first);
    final semantic = MiuixSemanticColors.of(actionContext);
    expect(tailAction.style?.fontSize, 14);
    expect(tailAction.style?.color, semantic['onSurfaceVariantActions']);

    // The disabled leading action uses its own source semantic role instead
    // of applying a generic opacity to the enabled action color.
    final disabledLeading = tester.widgetList<Text>(find.text('开头')).last;
    expect(
      disabledLeading.style?.color,
      semantic['disabledOnSecondaryVariant'],
    );
    await expectSourceScrollBar(
      barKey: 'reference-home-scrollbar',
      listKey: const PageStorageKey('miuix-reference-home'),
    );

    // Navigation taps must move the pager and reveal the matching original
    // page rather than swapping in project-specific lab pages.
    await tester.tap(find.text('图标'));
    await tester.pumpAndSettle();
    expect(find.text('搜索图标'), findsOneWidget);
    await expectSourceScrollBar(
      barKey: 'reference-icon-scrollbar',
      listKey: const PageStorageKey('miuix-reference-icons'),
    );

    await tester.tap(find.text('颜色'));
    await tester.pumpAndSettle();
    expect(find.text('当前主题颜色'), findsOneWidget);
    expect(tester.widget<Text>(find.text('主色')).style?.fontSize, 17);
    final primaryBlock = tester.getRect(
      find.byKey(const ValueKey('color-role-primary')),
    );
    final onPrimaryBlock = tester.getRect(
      find.byKey(const ValueKey('color-role-onPrimary')),
    );
    final finalLeftBlock = tester.getRect(
      find.byKey(const ValueKey('color-role-sliderKeyPoint')),
    );
    final finalRightBlock = tester.getRect(
      find.byKey(const ValueKey('color-role-sliderKeyPointForeground')),
    );
    expect(onPrimaryBlock.width - primaryBlock.width, 16);
    expect(onPrimaryBlock.left - primaryBlock.right, 16);
    expect(finalRightBlock.width - finalLeftBlock.width, 16);
    expect(finalRightBlock.left - finalLeftBlock.right, 16);
    await expectSourceScrollBar(
      barKey: 'reference-color-scrollbar',
      listKey: const PageStorageKey('miuix-reference-colors'),
    );

    await tester.tap(find.text('文本样式'));
    await tester.pumpAndSettle();
    expect(find.text('标题样式'), findsOneWidget);
    expect(find.text('title1'), findsOneWidget);
    expect(find.text('32sp'), findsOneWidget);
    expect(find.text('天地玄黄 宇宙洪荒'), findsWidgets);
    expect(
      tester.widget<Text>(find.text('天地玄黄 宇宙洪荒').first).style?.fontSize,
      32,
    );
    await expectSourceScrollBar(
      barKey: 'reference-text-style-scrollbar',
      listKey: const PageStorageKey('miuix-reference-text-styles'),
    );

    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    expect(find.text('显示 FPS 监视器'), findsOneWidget);
    // Native TopAppBar keeps expanded and compact subtitle nodes mounted;
    // the inactive one is hidden by its graphics-layer alpha.
    expect(find.text('v1.0.9 (228)'), findsNWidgets(2));
    expect(
      MiuixTheme.of(tester.element(find.text('显示 FPS 监视器'))).enableGlass,
      isTrue,
    );
    await expectSourceScrollBar(
      barKey: 'reference-settings-scrollbar',
      listKey: const PageStorageKey('miuix-reference-settings'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text style page preserves current source natural line metrics', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('文本样式').first);
    await tester.pumpAndSettle();

    double physicalTop(String label) =>
        tester.getRect(find.text(label).first).top * density;
    final title1Top = physicalTop('title1');
    final title2Top = physicalTop('title2');
    final title3Top = physicalTop('title3');
    final title4Top = physicalTop('title4');
    final headline1Top = physicalTop('headline1');

    // These relative placeable origins come from the current native page at
    // 1080 x 2400 / 420 dpi. Relative values exclude Android's status inset
    // while locking natural CJK, Roboto, divider, and section spacing together.
    final physicalStrides = <double>[
      title2Top - title1Top,
      title3Top - title2Top,
      title4Top - title3Top,
      headline1Top - title4Top,
    ];
    final chineseHeights = <double>[
      for (var index = 0; index < 4; index++)
        tester.getRect(find.text('天地玄黄 宇宙洪荒').at(index)).height * density,
    ];
    final englishHeights = <double>[
      for (var index = 0; index < 4; index++)
        tester
                .getRect(find.text('The Quick Brown Fox Jumps').at(index))
                .height *
            density,
    ];
    final numberHeights = <double>[
      for (var index = 0; index < 4; index++)
        tester.getRect(find.text(r'0123456789 !@#$%&').at(index)).height *
            density,
    ];
    for (var index = 0; index < physicalStrides.length; index++) {
      expect(
        physicalStrides[index],
        closeTo(const [553, 372, 334, 425.125][index], .5),
      );
    }
    final sampleHeights = <List<double>>[
      chineseHeights,
      englishHeights,
      numberHeights,
    ];
    const nativeSampleHeights = <List<double>>[
      [121, 91, 75, 69],
      [198, 73, 62, 56],
      [99, 73, 62, 56],
    ];
    for (var script = 0; script < sampleHeights.length; script++) {
      for (var index = 0; index < sampleHeights[script].length; index++) {
        expect(
          sampleHeights[script][index],
          closeTo(nativeSampleHeights[script][index], 2),
        );
      }
    }

    final card = tester.getRect(
      find.byKey(const ValueKey('reference-text-style-标题样式-card')),
    );
    expect(card.width * density, closeTo(1016, 1e-6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown page matches alternating source list and refresh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: _localizedReferenceTestTheme(),
          child: debugReferenceDropdownPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('overlay-dropdown-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('window-dropdown-2')), findsOneWidget);
    final firstPreference = find.byKey(const ValueKey('overlay-dropdown-1'));
    final trailingAnchor = find.descendant(
      of: firstPreference,
      matching: find.byType(CompositedTransformTarget),
    );
    final anchorRect = tester.getRect(trailingAnchor);
    await tester.tap(firstPreference);
    await tester.pumpAndSettle();

    // OverlayDropdownPreference.kt hosts ListPopup from its endActions Row.
    // The popup therefore ends at the 10x16 arrow and begins eight dp below
    // that compact row. Four short labels clamp to the source 200dp minimum.
    final popup = find.byType(MiuixListPopupColumn);
    final popupRect = tester.getRect(popup);
    expect(popupRect.width, 200);
    // Compose encloses every row as an integer-pixel placeable. At this 1x
    // fixture density the two 52.57dp edge rows become 53px and the two
    // 44.57dp inner rows become 45px: 53 + 45 + 45 + 53 = 196px.
    expect(popupRect.height, 196);
    expect(popupRect.top, closeTo(anchorRect.bottom + 8, .51));
    // Compose truncates positionInWindow first, then adds the independently
    // measured integer width. Do not compare with Flutter's fractional far
    // edge because that rounds the two values in the opposite order.
    final density = tester.view.devicePixelRatio;
    final sourceAnchorRight =
        ((anchorRect.left * density).truncate() +
            (anchorRect.width * density).round()) /
        density;
    expect(popupRect.right, closeTo(sourceAnchorRight, .1));
    final popupSurface = tester.widget<MiuixSurface>(
      find.ancestor(of: popup, matching: find.byType(MiuixSurface)).first,
    );
    // The default application path follows the HyperOS 4 transient-surface
    // token. Exact Compose geometry remains covered by the explicit `.source`
    // component tests rather than by this default-app integration fixture.
    expect(popupSurface.radius, 20);
    expect(popupSurface.border, isNull);
    expect(
      popupSurface.color,
      Theme.of(tester.element(popup)).colorScheme.surfaceContainer,
    );
    final selectedOption = tester.widgetList<Text>(find.text('选项 1')).last;
    final semantic = MiuixSemanticColors.of(tester.element(popup));
    expect(selectedOption.style?.fontSize, 16);
    expect(selectedOption.style?.color, semantic['primary']);
    expect(
      find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('miuix-dropdown-check-empty')),
      findsNWidgets(3),
    );
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((box) => box.color == semantic['windowDimming']),
      isTrue,
    );
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/dropdown_popup.png'),
    );
    await tester.tap(find.text('选项 3').last);
    await tester.pumpAndSettle();
    expect(find.text('选项 3'), findsWidgets);

    await tester.drag(find.byType(ListView).last, const Offset(0, 180));
    // The original critical spring settles before the 200 ms refresh delay;
    // allow both phases instead of assuming the old fixed 180 ms transition.
    await tester.pumpAndSettle(const Duration(milliseconds: 50));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('window-dropdown-12')),
      320,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('overlay-dropdown-11')), findsOneWidget);
    expect(find.byKey(const ValueKey('window-dropdown-12')), findsOneWidget);
    await tester.drag(
      find.byKey(const PageStorageKey('miuix-reference-dropdown')),
      const Offset(0, 40),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reference-dropdown-scrollbar')),
        matching: find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('root tab click uses the HyperOS direct replacement clocks', () {
    expect(
      debugReferenceTabFadeOutDuration(),
      const Duration(milliseconds: 80),
    );
    expect(
      debugReferenceTabFadeInDuration(),
      const Duration(milliseconds: 180),
    );
    expect(debugReferenceTabFadeCurve(), Curves.easeOutCubic);
  });

  test('contoured tab pager uses Compose default spring constants', () {
    final spring = debugReferenceTabPagerSpring();
    expect(spring.mass, 1);
    expect(spring.stiffness, 1500);
    expect(spring.damping, closeTo(2 * math.sqrt(1500), .0001));
  });

  test('cascading depth uses the current Folme spring pairs', () {
    final expand = debugMiuixCascadingSpring(expanding: true);
    const expandFrequency = 2 * math.pi / .45;
    expect(expand.mass, 1);
    expect(expand.stiffness, closeTo(expandFrequency * expandFrequency, .0001));
    expect(expand.damping, closeTo(2 * .99 * expandFrequency, .0001));

    final collapse = debugMiuixCascadingSpring(expanding: false);
    const collapseFrequency = 2 * math.pi / .2;
    expect(collapse.mass, 1);
    expect(
      collapse.stiffness,
      closeTo(collapseFrequency * collapseFrequency, .0001),
    );
    expect(collapse.damping, closeTo(2 * .95 * collapseFrequency, .0001));
  });

  test('visibility transitions use Compose medium-low spring constants', () {
    final spring = debugReferenceVisibilitySpring();
    expect(spring.mass, 1);
    expect(spring.stiffness, 400);
    expect(spring.damping, closeTo(40, .0001));
  });

  test('adaptive split-pane thresholds match the original utility', () {
    expect(debugReferenceShouldShowSplitPane(const Size(599, 300)), isFalse);
    expect(debugReferenceShouldShowSplitPane(const Size(600, 720)), isFalse);
    expect(debugReferenceShouldShowSplitPane(const Size(600, 719)), isTrue);
    expect(debugReferenceShouldShowSplitPane(const Size(839, 1007)), isFalse);
    expect(debugReferenceShouldShowSplitPane(const Size(840, 1400)), isTrue);
  });

  test('root content inset follows each active bottom-bar measurement', () {
    double inset({
      required bool visible,
      required bool floating,
      bool iosLike = false,
      TargetPlatform platform = TargetPlatform.android,
      double systemBottom = 0,
      MiuixFloatingNavigationBarDisplayMode floatingDisplayMode =
          MiuixFloatingNavigationBarDisplayMode.iconOnly,
    }) => debugReferenceRootBottomContentInset(
      navigationVisible: visible,
      floating: floating,
      iosLike: iosLike,
      platform: platform,
      systemBottom: systemBottom,
      floatingDisplayMode: floatingDisplayMode,
    );

    expect(inset(visible: false, floating: false, systemBottom: 24), 24);
    expect(inset(visible: true, floating: false, systemBottom: 24), 88.75);
    expect(
      inset(visible: true, floating: false, platform: TargetPlatform.windows),
      64.75,
    );
    expect(inset(visible: true, floating: true), 88);
    expect(inset(visible: true, floating: true, systemBottom: 24), 102);
    expect(
      inset(
        visible: true,
        floating: true,
        systemBottom: 24,
        floatingDisplayMode: MiuixFloatingNavigationBarDisplayMode.iconAndText,
      ),
      102,
    );
    expect(
      inset(visible: true, floating: true, platform: TargetPlatform.windows),
      88,
    );
    expect(
      inset(visible: true, floating: true, iosLike: true, systemBottom: 24),
      88,
    );
  });

  test('Compose dimensions round independently at the Android density', () {
    expect(debugReferenceRoundedDp(12, 2.625) * 2.625, closeTo(32, 1e-9));
    expect(debugReferenceRoundedDp(6, 2.625) * 2.625, closeTo(16, 1e-9));
    expect(debugReferenceRoundedDp(94, 2.625) * 2.625, closeTo(247, 1e-9));
    expect(debugReferenceRoundedDp(12, 0), 12);
    expect(debugReferenceRoundedDp(12, double.nan), 12);
  });

  testWidgets('compact pager stays full-height behind the HyperOS liquid bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    final pagerRect = tester.getRect(find.byType(PageView));
    final navigationRect = tester.getRect(
      find.byType(MiuixIosLiquidGlassNavigationBar),
    );
    final homeList = tester.widget<ListView>(
      find.byKey(const PageStorageKey('miuix-reference-home')),
    );
    final listPadding = homeList.padding! as EdgeInsets;

    expect(pagerRect.bottom, 844);
    expect(navigationRect.height, 92);
    expect(navigationRect.bottom, 844);
    expect(listPadding.bottom, navigationRect.height);
  });

  test('Android system families map to the original MIUIX dynamic roles', () {
    const tones = <int>[
      0,
      10,
      50,
      100,
      200,
      300,
      400,
      500,
      600,
      700,
      800,
      900,
      1000,
    ];
    List<int> family(int red) => List<int>.generate(
      tones.length,
      (index) => 0xFF000000 | (red << 16) | (index << 8) | index,
    );
    final accent1 = family(0x31);
    final accent2 = family(0x52);
    final accent3 = family(0x73);
    final neutral1 = family(0x84);
    final neutral2 = family(0x95);
    final palette = <String, dynamic>{
      'tones': tones,
      'accent1': accent1,
      'accent2': accent2,
      'accent3': accent3,
      'neutral1': neutral1,
      'neutral2': neutral2,
    };
    final legacyMessage = <String, dynamic>{
      'sdk': 33,
      'systemPalette': palette,
    };
    final light = debugReferenceAndroidSystemScheme(
      legacyMessage,
      dark: false,
    )!;
    final dark = debugReferenceAndroidSystemScheme(legacyMessage, dark: true)!;

    expect(light.primary, Color(accent1[tones.indexOf(600)]));
    expect(light.primaryFixed, Color(accent1[tones.indexOf(200)]));
    expect(light.secondaryContainer, Color(accent2[tones.indexOf(100)]));
    expect(light.tertiaryContainer, Color(accent3[tones.indexOf(100)]));
    // ignore: deprecated_member_use
    expect(light.surfaceVariant, Color(neutral2[tones.indexOf(100)]));
    expect(light.outline, Color(neutral2[tones.indexOf(500)]));
    expect(dark.primary, Color(accent1[tones.indexOf(200)]));
    expect(dark.primaryContainer, Color(accent1[tones.indexOf(700)]));
    // ignore: deprecated_member_use
    expect(dark.surfaceVariant, Color(neutral2[tones.indexOf(700)]));
    expect(dark.outline, Color(neutral2[tones.indexOf(400)]));

    final modern = debugReferenceAndroidSystemScheme(<String, dynamic>{
      'sdk': 34,
      'systemPalette': palette,
    }, dark: false)!;
    expect(modern.primary, light.primary);
    expect(modern.surface, isNot(light.surface));
    expect(modern.outline, isNot(light.outline));
    expect(
      MiuixSemanticColors.fromScheme(light)['surfaceVariant'],
      // ignore: deprecated_member_use
      light.surfaceVariant,
    );
  });

  testWidgets('adaptive shell switches at the source split-pane boundary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    tester.view.physicalSize = const Size(600, 719);
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    expect(find.byType(MiuixNavigationRail), findsOneWidget);
    expect(find.byType(MiuixIosLiquidGlassNavigationBar), findsNothing);

    tester.view.physicalSize = const Size(600, 720);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(MiuixNavigationRail), findsNothing);
    expect(find.byType(MiuixIosLiquidGlassNavigationBar), findsOneWidget);

    tester.view.physicalSize = const Size(840, 1400);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(MiuixNavigationRail), findsOneWidget);
    expect(find.byType(MiuixIosLiquidGlassNavigationBar), findsNothing);

    // AppPager fills the entire remaining Row in the source; no centered
    // desktop max-width gutter is inserted beside the navigation rail.
    tester.view.physicalSize = const Size(1000, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    final railRect = tester.getRect(find.byType(MiuixNavigationRail));
    final pagerRect = tester.getRect(find.byType(PageView));
    expect(pagerRect.left, closeTo(railRect.right, .01));
    expect(pagerRect.right, closeTo(1000, .01));
  });

  testWidgets('wide HyperOS rail follows the 1200dp expansion breakpoint', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1199, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 104);
    expect(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
      findsOneWidget,
    );

    // shouldExpandNavigationRail() switches at width >= 1200dp. The existing
    // state drives the local glass width and item geometry continuously.
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 264);
    final railHomeLabel = find.descendant(
      of: find.byType(MiuixNavigationRail),
      matching: find.text('主页'),
    );
    expect(
      tester.widget<Text>(railHomeLabel).style?.fontSize,
      closeTo(16, .001),
    );

    // Manual toggle remains effective while the breakpoint itself is stable;
    // LaunchedEffect reruns only when the threshold result changes.
    await tester.tap(
      find.byKey(const ValueKey('navigation-rail-expand-toggle')),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 104);
    await tester.pump();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 104);

    tester.view.physicalSize = const Size(1199, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(MiuixNavigationRail)).width, 264);
    expect(tester.takeException(), isNull);
  });

  testWidgets('maximized wide shell caps the HyperOS content plane', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    expect(find.text('搜索'), findsOneWidget);

    // Preserve the live home route while crossing from the compact shell into
    // the centered, width-capped desktop plane. MediaQuery reports the whole
    // window after this transition, while the search belongs to the local pane.
    tester.view.physicalSize = const Size(1708, 1019);
    await tester.pump();
    await tester.pumpAndSettle();
    final railRect = tester.getRect(find.byType(MiuixNavigationRail));
    final planeRect = tester.getRect(
      find.byKey(const ValueKey('reference-wide-content-plane')),
    );
    expect(railRect.width, 264);
    expect(planeRect.width, 1200);
    expect(planeRect.left - railRect.right, closeTo(122, .01));
    expect(1708 - planeRect.right, closeTo(122, .01));
    expect(planeRect.height, 1019);
    final searchLabel = find.text('搜索');
    expect(
      searchLabel,
      findsOneWidget,
      reason: 'the capped pane must retain the search placeholder',
    );
    final searchLabelRect = tester.getRect(searchLabel);
    expect(searchLabelRect.left, greaterThanOrEqualTo(planeRect.left));
    expect(searchLabelRect.right, lessThanOrEqualTo(planeRect.right));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide routes animate only inside the clipped content pane', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1000, 800);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final rail = find.byType(MiuixNavigationRail);
    final originalRailRect = tester.getRect(rail);

    // PersistentNavigationRail is a sibling of NavDisplay in AppContent.kt.
    // Select Settings through that chrome before opening a pushed destination.
    await tester.tap(find.descendant(of: rail, matching: find.text('设置')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 300);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull, reason: 'first route midpoint');

    // Both transition layers belong to the nested pane Navigator. The ClipRect
    // starts exactly after the rail, so translated parallax cannot paint over
    // the persistent navigation chrome during the source's 500ms motion.
    final paneClip = find.byKey(const ValueKey('reference-wide-pane-clip'));
    final paneRect = tester.getRect(paneClip);
    expect(tester.getRect(rail), originalRailRect);
    expect(paneRect.left, closeTo(originalRailRect.right, .01));
    expect(paneRect.right, closeTo(1000, .01));
    expect(
      find.byKey(const ValueKey('reference-nav-transition-scene')),
      findsNWidgets(2),
    );
    final paneNavigator = find.descendant(
      of: paneClip,
      matching: find.byType(Navigator),
    );
    expect(paneNavigator, findsOneWidget);
    expect(
      Navigator.of(tester.element(find.byKey(const ValueKey('about-back')))),
      same(tester.state<NavigatorState>(paneNavigator)),
    );

    // A rail destination first pops to the main entry, then switches the
    // pager. This mirrors navigator.popUntil(Route.Main) in the source.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.descendant(of: rail, matching: find.text('主页')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('about-back')), findsNothing);
    expect(tester.getRect(rail), originalRailRect);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch expansion uses source fade and vertical spring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final visibility = find.byKey(
      const ValueKey('reference-switch-expanded-visibility'),
    );
    for (
      var attempt = 0;
      attempt < 8 && visibility.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(homeList, const Offset(0, -420));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(visibility, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(find.text('点击以展开一个开关')),
      alignment: .4,
      duration: Duration.zero,
    );
    await tester.tap(find.text('点击以展开一个开关'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final expandingAlign = tester
        .widgetList<Align>(
          find.descendant(of: visibility, matching: find.byType(Align)),
        )
        .firstWhere((align) => align.heightFactor != null);
    expect(expandingAlign.alignment, Alignment.bottomCenter);
    expect(expandingAlign.widthFactor, isNull);
    expect(expandingAlign.heightFactor, inExclusiveRange(0, 1));
    expect(
      find.descendant(
        of: visibility,
        matching: find.byType(ReferenceLayerOpacity),
      ),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(
      find.descendant(of: visibility, matching: find.text('否')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('progress indicators use source FlowRow space-evenly layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final flowRow = find.byKey(const ValueKey('reference-progress-flow-row'));
    for (
      var attempt = 0;
      attempt < 14 && flowRow.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(homeList, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(flowRow, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(flowRow),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pump();

    final rowRect = tester.getRect(flowRow);
    final viewportWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    // Compose fills the viewport first, then removes 12 dp on both sides.
    // Guard the outer extent as well as the child gaps: otherwise a
    // shrink-wrapped row can report zero gaps and still satisfy the formula.
    expect(rowRect.left, closeTo(12, .01));
    expect(rowRect.width, closeTo(viewportWidth - 24, .01));
    final circles = find.byKey(const ValueKey('miuix-circular-progress'));
    expect(circles, findsNWidgets(7));
    final circleRects = [
      for (var index = 0; index < 7; index++) tester.getRect(circles.at(index)),
    ];
    final orbitRect = tester.getRect(
      find.byKey(const ValueKey('miuix-infinite-progress')),
    );
    final expectedGap = (rowRect.width - 7 * 30 - 20) / 9;
    expect(circleRects.first.left, closeTo(rowRect.left + expectedGap, .01));
    for (var index = 1; index < circleRects.length; index++) {
      expect(
        circleRects[index].left - circleRects[index - 1].right,
        closeTo(expectedGap, .01),
      );
    }
    expect(orbitRect.left - circleRects.last.right, closeTo(expectedGap, .01));
    expect(rowRect.right - orbitRect.right, closeTo(expectedGap, .01));
    expect(orbitRect.center.dy, closeTo(circleRects.first.center.dy, .01));

    final section = find.byKey(const ValueKey('reference-progress-section'));
    // Only the two indefinitely changing pictures rebuild. Rebuilding the
    // entire section once per frame repeatedly invalidates the adjacent lazy
    // list's Android accessibility subtree and prevents a UI dump from ever
    // reaching idle, even though the fixed indicators did not change.
    final sectionColumn = tester.widget<Column>(section);
    expect(sectionColumn.children.whereType<AnimatedBuilder>(), isEmpty);
    for (final key in const [
      ValueKey('reference-animated-linear-semantics'),
      ValueKey('reference-animated-circular-semantics'),
    ]) {
      final semantics = tester.widget<Semantics>(find.byKey(key));
      expect(semantics.properties.role, SemanticsRole.progressBar);
      expect(semantics.properties.value, '0.5');
      expect(semantics.properties.minValue, '0');
      expect(semantics.properties.maxValue, '1');
      expect(semantics.child, isA<ExcludeSemantics>());
      final excluded = semantics.child! as ExcludeSemantics;
      expect(excluded.child, isA<AnimatedBuilder>());
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('linear progress preserves source 420dpi total inset rounding', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final progress = find.byKey(const ValueKey('miuix-linear-progress'));
    for (
      var attempt = 0;
      attempt < 18 && progress.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(homeList, const Offset(0, -700));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(progress, findsWidgets);
    await tester.scrollUntilVisible(
      progress.first,
      700,
      scrollable: homeScroll,
    );
    await Scrollable.ensureVisible(
      tester.element(progress.first),
      alignment: .25,
      duration: Duration.zero,
    );
    await tester.pump();

    expect(progress, findsNWidgets(7));
    for (var index = 0; index < 7; index++) {
      final physical = tester.getRect(progress.at(index));
      // Native v228 exposes every line at [39..1041], not the [40..1040]
      // produced by independently rounding the residual logical 3dp.
      expect(physical.left * density, closeTo(39, .01));
      expect(physical.right * density, closeTo(1041, .01));
      expect(physical.height * density, closeTo(16, .01));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field examples keep source Done and placeholder behavior', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final placeholder = find.byKey(
      const ValueKey('reference-text-field-placeholder'),
    );
    for (
      var attempt = 0;
      attempt < 18 && placeholder.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(homeList, const Offset(0, -500));
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(placeholder, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(placeholder),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pump();

    const keys = [
      ValueKey('reference-text-field-plain'),
      ValueKey('reference-text-field-titled'),
      ValueKey('reference-text-field-state'),
      ValueKey('reference-text-field-placeholder'),
    ];
    for (final key in keys) {
      final field = tester.widget<MiuixTextField>(find.byKey(key));
      expect(field.textInputAction, TextInputAction.done);
      expect(field.onSubmitted, isNotNull);
    }

    await tester.tap(placeholder);
    await tester.pump();
    final editor = find.descendant(
      of: placeholder,
      matching: find.byType(EditableText),
    );
    await tester.enterText(editor, '示例');
    // The adjacent indeterminate progress row keeps ticking; advance beyond
    // the finite TextField label spring without waiting for global quiescence.
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('占位标题与单行输入'), findsNothing);
    expect(tester.widget<EditableText>(editor).focusNode.hasFocus, isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<EditableText>(editor).focusNode.hasFocus, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text field examples preserve the source 420dpi row geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final plain = find.byKey(const ValueKey('reference-text-field-plain'));
    await tester.scrollUntilVisible(plain, 700, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(plain),
      alignment: .25,
      duration: Duration.zero,
    );
    await tester.pump();

    const keys = [
      ValueKey('reference-text-field-plain'),
      ValueKey('reference-text-field-titled'),
      ValueKey('reference-text-field-state'),
      ValueKey('reference-text-field-placeholder'),
    ];
    var rects = [for (final key in keys) tester.getRect(find.byKey(key))];
    final list = tester.widget<ListView>(homeList);
    const targetTop = 517 / density;
    list.controller!.jumpTo(
      list.controller!.offset + rects.first.top - targetTop,
    );
    await tester.pump();
    rects = [for (final key in keys) tester.getRect(find.byKey(key))];

    // TextFieldSection.kt applies 12dp horizontal list padding, 16dp field
    // content padding, and a separate 12dp bottom modifier to each field.
    // Compose independently rounds those values at 420dpi. The coordinates
    // below were captured from the native v1.0.9 UI tree on the same emulator.
    expect((rects.first.left * density).round(), 32);
    expect((rects.first.right * density).round(), 1048);
    expect(rects.map((rect) => (rect.top * density).round()).toList(), const [
      517,
      685,
      853,
      1021,
    ]);
    expect(rects.map((rect) => (rect.height * density).round()).toSet(), const {
      136,
    });

    await tester.tap(find.byKey(keys[1]));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      tester.getSize(find.byKey(keys[1])).height * density,
      closeTo(136, .01),
    );
    final titledEditor = find.descendant(
      of: find.byKey(keys[1]),
      matching: find.byType(EditableText),
    );
    await tester.enterText(titledEditor, '示例');
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('带标题'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('contoured tab pager follows the source spring motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final pagerHost = find.byKey(const ValueKey('reference-tab-content-pager'));
    // The source page is lazy; advance the ListView until the tab section is
    // materialized, then center the small pager without relying on an absent
    // finder during the first drag.
    for (
      var attempt = 0;
      attempt < 16 && pagerHost.evaluate().isEmpty;
      attempt++
    ) {
      await tester.drag(homeList, const Offset(0, -520));
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(pagerHost, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(pagerHost),
      alignment: .6,
      duration: Duration.zero,
    );
    await tester.pump();

    final contourTabs = find.descendant(
      of: find.byType(MiuixTabRowWithContour),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(contourTabs, const Offset(-220, 0));
    await tester.pump(const Duration(milliseconds: 250));
    final nestedPager = find.descendant(
      of: pagerHost,
      matching: find.byType(PageView),
    );
    final pageController = tester.widget<PageView>(nestedPager).controller!;
    expect(pageController.page, 0);

    expect(find.text('标签 6').hitTestable(), findsOneWidget);
    await tester.tap(find.text('标签 6'));
    // The first scheduled frame establishes the simulation epoch; the next
    // frames must show physical motion rather than a completed duration tween.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    expect(pageController.page, greaterThan(0));
    expect(pageController.page, lessThan(5));

    await tester.pump(const Duration(seconds: 1));
    expect(pageController.page, closeTo(5, .001));
    expect(find.text('标签 6 的内容'), findsOneWidget);

    // A real finger drag must immediately take ownership from the spring,
    // matching PagerState's MutatorMutex cancellation semantics.
    await tester.drag(contourTabs, const Offset(220, 0));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('标签 1').hitTestable(), findsWidgets);
    await tester.tap(find.text('标签 1').hitTestable().last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 48));
    expect(pageController.page, inExclusiveRange(0, 5));
    await tester.drag(nestedPager, const Offset(-120, 0));
    await tester.pump(const Duration(seconds: 1));
    expect(pageController.page, greaterThan(.5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal pager follows the original swipe navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(PageView), const Offset(-340, 0));
    await tester.pumpAndSettle();

    expect(find.text('搜索图标'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('root tab click never scrolls through intermediate pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    final rootPager = find.byType(PageView).first;
    final controller = tester.widget<PageView>(rootPager).controller!;
    final observedPages = <double>[];
    controller.addListener(() {
      final page = controller.page;
      if (page != null) observedPages.add(page);
    });

    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(controller.page, closeTo(0, .001));
    final fade = tester.widget<FadeTransition>(
      find.byKey(const ValueKey('reference-root-tab-fade')),
    );
    expect(fade.opacity.value, inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.pump();
    expect(controller.page, closeTo(4, .001));
    expect(observedPages.where((page) => page > .001 && page < 3.999), isEmpty);

    // A rapid reverse cancels the current fade and still replaces directly.
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-0')));
    await tester.pumpAndSettle();
    expect(controller.page, closeTo(0, .001));
    expect(
      tester
          .widget<FadeTransition>(
            find.byKey(const ValueKey('reference-root-tab-fade')),
          )
          .opacity
          .value,
      closeTo(1, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('system back returns the root pager to Home before exit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('颜色').last);
    await tester.pumpAndSettle();
    expect(find.text('当前主题颜色'), findsOneWidget);

    // MainScreenBackHandler consumes this event because the navigator is still
    // on its root route but the pager is not on page zero.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('搜索栏'), findsOneWidget);
    expect(find.text('当前主题颜色'), findsNothing);
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      closeTo(0, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown overlay consumes Back before its fixture route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: _localizedReferenceTestTheme(),
          child: debugReferenceDropdownPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overlay-dropdown-1')));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixListPopupColumn), findsOneWidget);

    // The first Back request must dismiss only the popup.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();

    expect(find.byType(MiuixListPopupColumn), findsNothing);
    expect(find.text('叠加下拉偏好 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Android insets keep initial content below glass then scroll it behind',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(const MiuixExampleApp());
      await tester.pumpAndSettle();

      // Current AppState enables blur by default. Keep the helper idempotent so
      // this measurement remains valid if a preceding interaction changed it.
      await _enableReferenceBlur(tester, returnToHome: true);

      final topGlass = find.byKey(const ValueKey('top-app-bar-glass')).first;
      final sectionTitle = find.text('搜索栏');
      final initialBar = tester.getRect(topGlass);
      final initialSection = tester.getRect(sectionTitle);
      expect(initialBar.top, 0);
      expect(initialBar.height, 118);
      expect(initialSection.top, greaterThanOrEqualTo(initialBar.bottom));

      final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
      await tester.drag(homeList, const Offset(0, -80));
      await tester.pump();

      // The leading spacer belongs to scroll content. Once it scrolls away, the
      // first section enters the glass region instead of pushing the title away.
      // TopAppBar.kt keeps its 52dp compact row plus the large-title 4dp bottom
      // padding, so the fully collapsed overlay is 24 + 56 = 80dp here.
      expect(tester.getRect(topGlass).height, 80);
      expect(tester.getRect(sectionTitle).top, lessThan(initialBar.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('compact page title visibly shrinks and grows with its list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    Iterable<Text> homeTitles() => tester
        .widgetList<Text>(find.text('主页'))
        .where(
          (text) => text.style?.fontSize == 32 || text.style?.fontSize == 20,
        );

    // A phone page begins with the leading 32sp title. The centered compact
    // copy exists for its fade animation but remains transparent at the top.
    expect(homeTitles().any((text) => text.style?.fontSize == 32), isTrue);
    final compactOpacity = find.byKey(
      const ValueKey('top-app-bar-compact-title-opacity'),
    );
    expect(tester.widget<Opacity>(compactOpacity.first).opacity, 0);

    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    await tester.drag(homeList, const Offset(0, -100));
    await tester.pumpAndSettle();

    // After the title column is consumed, only the 20sp centered title is
    // visible. Dragging back to the leading edge must restore the 32sp copy.
    expect(homeTitles().any((text) => text.style?.fontSize == 32), isFalse);
    expect(homeTitles().any((text) => text.style?.fontSize == 20), isTrue);
    expect(tester.widget<Opacity>(compactOpacity.first).opacity, 1);

    await tester.drag(homeList, const Offset(0, 160));
    await tester.pumpAndSettle();
    expect(homeTitles().any((text) => text.style?.fontSize == 32), isTrue);
    expect(tester.widget<Opacity>(compactOpacity.first).opacity, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'opaque top bar also overlays content after initial title padding',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(const MiuixExampleApp());
      await tester.pumpAndSettle();

      // This test intentionally covers the non-blurred branch even though the
      // current source starts with blur enabled.
      await _disableReferenceBlur(tester, returnToHome: true);

      final topSurface = find
          .byKey(const ValueKey('top-app-bar-surface'))
          .first;
      final sectionTitle = find.text('搜索栏');
      final initialBar = tester.getRect(topSurface);
      expect(initialBar.height, 118);
      expect(
        tester.getRect(sectionTitle).top,
        greaterThanOrEqualTo(initialBar.bottom),
      );
      expect(
        tester
            .widget<Scaffold>(find.byType(Scaffold).last)
            .extendBodyBehindAppBar,
        isTrue,
      );

      final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
      await tester.drag(homeList, const Offset(0, -80));
      await tester.pump();

      // The opaque fill hides the row visually, but the geometry must still
      // pass behind the collapsed title exactly as it does with glass enabled.
      expect(tester.getRect(topSurface).height, 80);
      expect(tester.getRect(sectionTitle).top, lessThan(initialBar.bottom));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('page content inset follows the live top bar measurement', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    final bar = tester.widget<MiuixTopAppBar>(
      find.byType(MiuixTopAppBar).first,
    );
    final behavior = bar.scrollBehavior!;
    final section = find.text('搜索栏');
    final initialSectionTop = tester.getTopLeft(section).dy;

    behavior.setCollapseFraction(.5);
    await tester.pump();
    // The default title-only bar moves from 94dp toward 56dp. At one half the
    // source Scaffold content inset and the first section both move up 19dp.
    expect(tester.getTopLeft(section).dy, closeTo(initialSectionTop - 19, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed top bar rounds its source rows independently at 420dpi', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    // This emulator exports a 63px Flutter status inset. Compose then measures
    // the 52dp compact row and 4dp trailing padding as separate IntSize values.
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    final behavior = MiuixTopAppBarScrollBehavior()..setCollapseFraction(1);
    addTearDown(behavior.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topCenter,
          child: MiuixTopAppBar(
            title: '主页',
            scrollBehavior: behavior,
            glass: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final surface = tester.getRect(
      find.byKey(const ValueKey('top-app-bar-surface')),
    );
    // Native source: 63px status inset + round(52dp)=137px compact row +
    // round(4dp)=11px bottom padding. Combining 56dp would produce only 147px
    // for the title area and finish one pixel too early.
    expect(surface.height * density, closeTo(211, .001));

    // Verify the PreferredSizeWidget through the real source-style Scaffold as
    // well. Flutter's Scaffold reads the nominal preferred size, but the bar's
    // independently measured content must retain the extra physical pixel.
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    await tester.drag(homeList, const Offset(0, -300));
    await tester.pump();
    final scaffoldSurface = tester.getRect(
      find.byKey(const ValueKey('top-app-bar-glass')).first,
    );
    expect(scaffoldSurface.height * density, closeTo(211, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('app publishes transparent Android system-bar styling', (
    tester,
  ) async {
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();

    final regions = tester.widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
      find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
    );
    final style = regions
        .map((region) => region.value)
        .firstWhere((value) => value.systemNavigationBarColor != null);
    expect(style.statusBarColor, Colors.transparent);
    expect(style.systemNavigationBarColor, Colors.transparent);
    expect(style.systemNavigationBarDividerColor, Colors.transparent);
    expect(style.statusBarIconBrightness, Brightness.dark);
    expect(style.systemNavigationBarIconBrightness, Brightness.dark);
    expect(style.systemStatusBarContrastEnforced, isFalse);
    expect(style.systemNavigationBarContrastEnforced, isFalse);
  });

  testWidgets('icon page matches source table and search takeover', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(
      1080 / sourceDensity,
      2400 / sourceDensity,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 60 / sourceDensity);
    tester.view.viewPadding = const FakeViewPadding(top: 60 / sourceDensity);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('图标').last);
    await tester.pumpAndSettle();

    bool semanticsTreeContains(String label) {
      final root = tester
          .binding
          .renderViews
          .first
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!;
      var found = false;
      void visit(SemanticsNode node) {
        if (node.label == label) {
          found = true;
        }
        node.visitChildren((child) {
          visit(child);
          return !found;
        });
      }

      visit(root);
      return found;
    }

    // Current IconPage.kt is an accordion. Its collapsed table keeps one
    // Regular glyph and an expand affordance; tapping a row reveals all five
    // source weights while every other row remains collapsed.
    for (final label in const ['名称', '点击比较字重']) {
      expect(find.text(label), findsOneWidget);
    }
    for (final label in const ['细体', '标准', '常规', '中等', '半粗']) {
      expect(find.text(label), findsNothing);
    }
    // Technical source identifiers remain Latin and therefore use the same
    // Roboto metrics as Compose instead of inheriting the CJK fallback.
    expect(
      DefaultTextStyle.of(tester.element(find.text('Add'))).style.fontFamily,
      'Roboto',
    );
    expect(tester.widget<Text>(find.text('Add')).style?.fontSize, 14);
    final firstRow = find.byKey(const ValueKey('icon-row-0'));
    expect(
      find.descendant(of: firstRow, matching: find.byType(Icon)),
      findsNWidgets(2),
    );
    await tester.tap(firstRow);
    await tester.pumpAndSettle();
    for (final label in const ['细体', '标准', '常规', '中等', '半粗']) {
      expect(find.text(label), findsOneWidget);
    }
    expect(
      find.descendant(of: firstRow, matching: find.byType(Icon)),
      findsNWidgets(7),
    );
    expect(
      tester
          .widget<ExcludeSemantics>(
            find.byKey(const ValueKey('icon-table-search-exclusion')),
          )
          .excluding,
      isFalse,
    );
    expect(semanticsTreeContains('名称\n点击比较字重'), isTrue);

    // Tapping the fake field replaces the page bar with the source search
    // pager. Choosing a result closes it and returns to the icon table.
    final fakeSearch = find.descendant(
      of: find.byKey(const ValueKey('icon-search-fake')),
      matching: find.byKey(const ValueKey('miuix-search-semantic-target')),
    );
    final fakeSearchTop = tester.getTopLeft(fakeSearch).dy;
    await tester.tap(find.byKey(const ValueKey('icon-search-fake')));
    await tester.pump();
    final openingSearch = find.descendant(
      of: find.byKey(const ValueKey('icon-search-pager')),
      matching: find.byKey(const ValueKey('miuix-search-semantic-target')),
    );
    expect(tester.getTopLeft(openingSearch).dy, closeTo(fakeSearchTop, .01));
    await tester.pump(const Duration(milliseconds: 150));
    final midwayTop = tester.getTopLeft(openingSearch).dy;
    expect(midwayTop, lessThan(fakeSearchTop));
    expect(midwayTop, greaterThan(60 / sourceDensity + 24));
    final midwaySurface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('icon-search-pager')),
    );
    expect(midwaySurface.color.a, inExclusiveRange(0, 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('icon-search-pager')), findsOneWidget);
    expect(find.byKey(const ValueKey('icon-search-cancel')), findsOneWidget);
    expect(
      tester
          .widget<ExcludeSemantics>(
            find.byKey(const ValueKey('icon-table-search-exclusion')),
          )
          .excluding,
      isTrue,
    );
    expect(
      tester
          .widget<IgnorePointer>(
            find.byKey(const ValueKey('icon-table-search-pointer-block')),
          )
          .ignoring,
      isTrue,
    );
    // The source popup semantics replace the table; hidden table rows cannot
    // remain reachable merely because Flutter keeps them mounted for state.
    expect(semanticsTreeContains('名称\n点击比较字重'), isFalse);
    final input = find.byKey(const ValueKey('miuix-search-bar-input'));
    await tester.enterText(input, 'Alarm');
    await tester.pumpAndSettle();
    // API 36 parity captures use the emulator's 2.625 density. Preserve the
    // native SearchPager final geometry while the visible labels stay Chinese:
    // field semantics [32,123][858,249], localized Cancel source slot
    // [901,123][1038,249]. The render capsule is the source's unchanged 45dp;
    // its merged Android editing semantics expands to the 48dp XML height.
    final pager = find.byKey(const ValueKey('icon-search-pager'));
    final searchTarget = find.descendant(
      of: pager,
      matching: find.byKey(const ValueKey('miuix-search-semantic-target')),
    );
    final cancel = find.byKey(const ValueKey('icon-search-cancel'));
    final searchRect = tester.getRect(searchTarget);
    final cancelRect = tester.getRect(cancel);
    expect(searchRect.left * sourceDensity, closeTo(32, 1));
    expect(searchRect.top * sourceDensity, closeTo(123, 1));
    expect(searchRect.right * sourceDensity, closeTo(858, 1));
    // HyperOS 4 keeps the field visually at 48dp. The explicit source
    // constructor retains the historical 45dp Compose sample geometry.
    expect(searchRect.height * sourceDensity, closeTo(48 * sourceDensity, 1));
    expect(cancelRect.left * sourceDensity, closeTo(901, 1));
    expect(cancelRect.right * sourceDensity, closeTo(1038, 1));
    expect(cancelRect.top - searchRect.top, closeTo(1.5, .01));
    expect(cancelRect.height, closeTo(45, .01));
    final cancelSemantics = tester.getSemantics(
      find.byKey(const ValueKey('icon-search-cancel-semantics')),
    );
    expect(cancelSemantics.label, '取消');
    final results = find.byKey(const ValueKey('icon-search-results'));
    final alarmResult = find.descendant(
      of: results,
      matching: find.text('Alarm'),
    );
    expect(alarmResult, findsOneWidget);
    await tester.tap(alarmResult);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('icon-search-pager')), findsNothing);
    expect(find.text('Alarm'), findsOneWidget);
    expect(semanticsTreeContains('名称\n点击比较字重'), isTrue);
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('directional icon glyphs preserve the upstream orientation', (
    tester,
  ) async {
    // Cover every direction-sensitive family rather than sampling only six
    // glyphs. This catches a missed SVG/Compose group transform immediately:
    // vertical arrows flip, horizontal arrows reverse, and circular actions
    // change winding when the font coordinate conversion is wrong.
    const names = [
      'Download',
      'UploadCloud',
      'ExpandLess',
      'ExpandMore',
      'Back',
      'Forward',
      'ChevronBackward',
      'ChevronForward',
      'Sort',
      'TopDownloads',
      'Undo',
      'Redo',
      'Refresh',
      'Update',
      'ZoomOut',
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          color: const Color(0xFFF7F7F7),
          child: Center(
            child: RepaintBoundary(
              key: const ValueKey('directional-icon-grid'),
              child: ColoredBox(
                color: const Color(0xFFF7F7F7),
                child: SizedBox(
                  width: 300,
                  height: 400,
                  child: Wrap(
                    children: [
                      for (final name in names)
                        SizedBox(
                          width: 100,
                          height: 80,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MiuixExtendedIconCatalog.find(name)!.regular,
                                size: 40,
                                color: Colors.black,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'NotoSansCJKsc',
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(const ValueKey('directional-icon-grid')),
      matchesGoldenFile('goldens/directional_icon_grid.png'),
    );
  });

  testWidgets('pull refresh threshold header matches the source geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final listKey = GlobalKey();
    final baseTheme = MiuixThemeData.defaults();
    final chineseTheme = baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(fontFamily: 'NotoSansCJKsc'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: chineseTheme,
          child: Material(
            color: const Color(0xFFF7F7F7),
            child: RepaintBoundary(
              key: const ValueKey('pull-refresh-threshold-preview'),
              child: ColoredBox(
                color: const Color(0xFFF7F7F7),
                child: MiuixPullToRefresh(
                  onRefresh: () async {},
                  refreshTexts: const ['下拉刷新', '松开刷新', '正在刷新…', '刷新成功'],
                  child: ListView(
                    key: listKey,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(12),
                    children: const [
                      MiuixCard(
                        child: MiuixBasicComponent(
                          title: '下拉菜单内容',
                          summary: '松开后添加六个项目',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final context = listKey.currentContext!;
    OverscrollNotification(
      metrics: FixedScrollMetrics(
        minScrollExtent: 0,
        maxScrollExtent: 100,
        pixels: 0,
        viewportDimension: 300,
        axisDirection: AxisDirection.down,
        devicePixelRatio: 1,
      ),
      context: context,
      overscroll: -40,
      velocity: 0,
    ).dispatch(context);
    await tester.pump();
    expect(find.text('松开刷新'), findsOneWidget);

    await expectLater(
      find.byKey(const ValueKey('pull-refresh-threshold-preview')),
      matchesGoldenFile('goldens/pull_refresh_threshold.png'),
    );
  });

  testWidgets('settings switches control the real five-page shell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    // These preferences are backed by the root state, so changing them must
    // immediately alter widgets outside the settings page itself.
    await _centerReferenceSetting(tester, '显示顶部栏');
    await tester.tap(find.text('显示顶部栏'));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixTopAppBar), findsNothing);

    await tester.tap(find.text('允许页面横向滑动'));
    await tester.pump();
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.physics, isA<NeverScrollableScrollPhysics>());

    await tester.tap(find.text('显示导航栏'));
    await tester.pumpAndSettle();
    expect(find.byType(MiuixNavigationBar), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top blur style setting switches the rendered source pipeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('top-app-bar-glass')), findsOneWidget);

    await _centerReferenceSetting(tester, '顶部栏模糊样式');
    await tester.tap(find.text('顶部栏模糊样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('渐进模糊').last);
    await tester.pumpAndSettle();

    final progressive = find.byKey(
      const ValueKey('top-app-bar-progressive-filter'),
    );
    expect(find.byKey(const ValueKey('top-app-bar-glass')), findsNothing);
    expect(progressive, findsOneWidget);
    expect(tester.widget<MiuixGlass>(progressive).blur, 18);
    expect(tester.widget<MiuixGlass>(progressive).opacity, .24);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('top-app-bar-progressive-opacity')),
          )
          .opacity,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FPS setting shows the full-screen draggable source monitor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('reference-fps-monitor')), findsNothing);

    // Upstream draws the monitor over the whole app immediately below the
    // status inset. It must not reserve height in the settings scroll content.
    await tester.tap(find.text('显示 FPS 监视器'));
    await tester.pump();
    for (var frame = 0; frame < 70; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final monitor = find.byKey(const ValueKey('reference-fps-monitor'));
    final rect = tester.getRect(monitor);
    expect(monitor, findsOneWidget);
    expect(find.byKey(const ValueKey('reference-fps-average')), findsOneWidget);
    expect(find.byKey(const ValueKey('reference-fps-low')), findsOneWidget);
    expect(rect.left, 0);
    expect(rect.right, 390);
    expect(rect.top, 0);
    expect(rect.bottom, 844);

    final pill = find.byKey(const ValueKey('reference-fps-pill'));
    final initialPill = tester.getRect(pill);
    final dynamic monitorState = tester.state(monitor);
    expect(initialPill.top, 0);
    expect(initialPill.center.dx, closeTo(195, .01));
    expect(monitorState.debugParentSize, const Size(390, 844));
    expect(monitorState.debugPillSize, initialPill.size);
    await tester.drag(pill, const Offset(1000, 1000));
    await tester.pump();
    final movedPill = tester.getRect(pill);
    expect(monitorState.debugOffset, isNot(Offset.zero));
    expect(movedPill.right, closeTo(390, .01));
    expect(movedPill.bottom, closeTo(844, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('color settings follow source Monet visibility and theme wiring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    // Source SettingsPage only exposes key color in Monet modes, and only
    // exposes palette/spec after a non-default key color is selected.
    await _centerReferenceSetting(tester, '颜色模式', scrollDelta: 360);
    final colorModePreference = tester
        .widget<MiuixOverlayDropdownPreference<int>>(
          find.widgetWithText(MiuixOverlayDropdownPreference<int>, '颜色模式'),
        );
    // SettingsPage.kt uses the index-based OverlayDropdownPreference for every
    // one of these rows. A generic/window preference changes both anchoring and
    // the popup host, so merely showing the same labels is not source parity.
    expect(colorModePreference.presentation, MiuixPopupPresentation.overlay);
    expect(find.text('关键色'), findsNothing);
    expect(find.text('调色板样式'), findsNothing);
    expect(find.text('色彩规范'), findsNothing);
    await tester.tap(find.text('颜色模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monet 浅色').last);
    await tester.pumpAndSettle();
    expect(find.text('关键色'), findsOneWidget);
    expect(find.text('调色板样式'), findsNothing);
    expect(find.text('色彩规范'), findsNothing);

    await tester.tap(find.text('关键色'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绿色').last);
    await tester.pumpAndSettle();
    expect(find.text('调色板样式'), findsOneWidget);
    expect(find.text('色彩规范'), findsOneWidget);
    var theme = MiuixTheme.of(tester.element(find.text('颜色模式')));
    expect(theme.mode, MiuixColorMode.monetLight);
    expect(theme.seedColor, const Color(0xFF36D167));
    expect(theme.paletteStyle, MiuixThemePaletteStyle.tonalSpot);
    expect(theme.schemeFor(Brightness.dark).brightness, Brightness.light);
    final tonalPrimary = theme.lightScheme.primary;

    await tester.tap(find.text('调色板样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('表现力').last);
    await tester.pumpAndSettle();
    theme = MiuixTheme.of(tester.element(find.text('颜色模式')));
    expect(theme.paletteStyle, MiuixThemePaletteStyle.expressive);
    expect(theme.lightScheme.primary, isNot(tonalPrimary));
    final expressive2021Primary = theme.lightScheme.primary;
    final expressive2021Surface = theme.lightScheme.surface;

    await tester.tap(find.text('色彩规范'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('规范 2025').last);
    await tester.pumpAndSettle();
    theme = MiuixTheme.of(tester.element(find.text('颜色模式')));
    expect(theme.colorSpec, MiuixThemeColorSpec.spec2025);
    expect(theme.lightScheme.primary, isNot(expressive2021Primary));
    expect(theme.lightScheme.surface, isNot(expressive2021Surface));
    expect(tester.takeException(), isNull);
  });

  testWidgets('default Monet key uses the loaded Android system palette', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const channel = MethodChannel('miuix_flutter/platform_dynamic_color');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => switch (call.method) {
        'getSystemPalette' => <String, dynamic>{
          'seed': 0xFF36D167,
          'style': 'EXPRESSIVE',
          'spec': 2025,
        },
        _ => null,
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '颜色模式', scrollDelta: 360);
    await tester.tap(find.text('颜色模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monet 浅色').last);
    await tester.pumpAndSettle();

    final theme = MiuixTheme.of(tester.element(find.text('颜色模式')));
    final expected = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetLight,
      seedColor: const Color(0xFF36D167),
      paletteStyle: MiuixThemePaletteStyle.expressive,
      colorSpec: MiuixThemeColorSpec.spec2025,
    );
    expect(theme.mode, MiuixColorMode.monetLight);
    expect(theme.lightScheme.primary, expected.lightScheme.primary);
    expect(theme.lightScheme.surface, expected.lightScheme.surface);
    expect(theme.darkScheme.primary, expected.darkScheme.primary);
    expect(find.text('关键色'), findsOneWidget);
    expect(find.text('默认'), findsWidgets);
  });

  testWidgets('floating navigation leaves the active page laid out', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();

    // The example now starts with its sole floating style. Disable it once to
    // establish the regular-bar layout baseline, then re-enable it below.
    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();
    final regularPageHeight = tester.getSize(find.byType(PageView)).height;

    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();

    final floatingPageHeight = tester.getSize(find.byType(PageView)).height;
    final floatingPageRect = tester.getRect(find.byType(PageView));
    final floatingBarRect = tester.getRect(
      find.byType(MiuixIosLiquidGlassNavigationBar),
    );
    expect(find.byType(MiuixIosLiquidGlassNavigationBar), findsOneWidget);
    expect(find.byType(MiuixFloatingNavigationBar), findsNothing);
    expect(
      find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
      findsOneWidget,
    );
    expect(find.byType(MiuixNavigationBar), findsNothing);
    expect(find.text('使用悬浮导航栏'), findsOneWidget);
    expect(floatingPageHeight, greaterThan(600));
    expect(floatingPageHeight, closeTo(regularPageHeight, .01));
    expect(floatingPageRect.bottom, 844);
    expect(floatingBarRect.bottom, 844);
    expect(floatingPageRect.bottom, greaterThan(floatingBarRect.top));
    final previousComparator = goldenFileComparator;
    // Capture the component under test instead of the whole scaffold. The
    // page geometry assertions above already protect content passthrough;
    // excluding the independent top glass bar also removes platform-specific
    // glyph raster noise from this bottom-navigation regression.
    goldenFileComparator = _TolerantReferenceGoldenComparator(
      Uri.parse('test/reference_structure_test.dart'),
      precisionTolerance: 0.006,
    );
    addTearDown(() => goldenFileComparator = previousComparator);
    await expectLater(
      find.byType(MiuixIosLiquidGlassNavigationBar),
      matchesGoldenFile('goldens/floating_navigation_shell.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating icon-only navigation uses equal raised metrics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = List<MiuixNavigationItem>.generate(
      5,
      (index) => MiuixNavigationItem(
        icon: const Icon(Icons.circle_outlined),
        label: '项目 $index',
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: MiuixThemeData.defaults(),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: MiuixFloatingNavigationBar(
                items: items,
                selectedIndex: 0,
                onSelected: (_) {},
                displayMode: MiuixFloatingNavigationBarDisplayMode.iconOnly,
                defaultWindowInsetsPadding: false,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final surfaceSize = tester.getSize(
      find.byKey(const ValueKey('floating-navigation-surface')),
    );
    // The HyperOS 4 phone shell uses the calibrated full-width 58dp capsule;
    // `.source` keeps the historical compact Compose row separately.
    expect(surfaceSize.width, closeTo(352, .01));
    expect(surfaceSize.height, closeTo(58, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating navigation keeps HyperOS 4 equal capsule geometry', (
    tester,
  ) async {
    const density = 2.625;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(bottom: 63);
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    const items = [
      MiuixNavigationItem(
        icon: Icon(Icons.home),
        label: '主页',
        layoutLabel: 'Home',
      ),
      MiuixNavigationItem(
        icon: Icon(Icons.edit),
        label: '图标',
        layoutLabel: 'Icon',
      ),
      MiuixNavigationItem(
        icon: Icon(Icons.image),
        label: '颜色',
        layoutLabel: 'Color',
      ),
      MiuixNavigationItem(
        icon: Icon(Icons.sort),
        label: '下拉菜单',
        layoutLabel: 'Dropdown',
      ),
      MiuixNavigationItem(
        icon: Icon(Icons.settings),
        label: '设置',
        layoutLabel: 'Settings',
      ),
    ];

    Future<void> checkMode(MiuixFloatingNavigationBarDisplayMode mode) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            fontFamily: 'Roboto',
            fontFamilyFallback: const ['NotoSansCJKsc'],
          ),
          home: MiuixTheme(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: MiuixFloatingNavigationBar(
                items: items,
                selectedIndex: 4,
                onSelected: (_) {},
                displayMode: mode,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final row = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-content-row')),
      );
      final surface = tester.getRect(
        find.byKey(const ValueKey('floating-navigation-surface')),
      );
      final itemRects = [
        for (var index = 0; index < items.length; index++)
          tester.getRect(
            find.byKey(ValueKey('floating-navigation-item-$index')),
          ),
      ];
      // HyperOS 4 keeps five equal 68dp destinations in one continuous row.
      // The six-dp capsule insets and all dimensions round independently at
      // the active density; changing label visibility must not resize it.
      expect(row.width * density, closeTo(892.5, .001));
      expect(surface.width * density, closeTo(924.5, .001));
      expect(surface.height * density, closeTo(152, .001));
      expect(row.height * density, closeTo(152, .001));
      expect(surface.bottom * density, closeTo(2295, .001));
      expect(
        itemRects.map((rect) => rect.width * density),
        everyElement(closeTo(itemRects.first.width * density, .001)),
      );
      expect(
        itemRects.map((rect) => rect.height * density),
        everyElement(closeTo(136.5, .001)),
      );
    }

    await checkMode(MiuixFloatingNavigationBarDisplayMode.iconAndText);
    await checkMode(MiuixFloatingNavigationBarDisplayMode.iconOnly);
    await checkMode(MiuixFloatingNavigationBarDisplayMode.textOnly);
    // Foundation verifies debug overrides before widget-test tearDown callbacks.
    // Restore this one explicitly after the final Android-only measurement;
    // the registered tearDown remains as the failure-path safety net.
    debugDefaultTargetPlatformOverride = null;
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation mode settings drive the rendered bars', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();

    // Regular navigation settings are conditional, so temporarily leave the
    // unified floating default before exercising both public mode controls.
    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();

    // Exercise the public settings controls rather than only constructing the
    // three bar widgets directly. This catches disconnected example wiring.
    await _centerReferenceSetting(tester, '导航栏模式');
    final navigationModePreference = tester
        .widget<MiuixOverlayDropdownPreference<int>>(
          find.widgetWithText(MiuixOverlayDropdownPreference<int>, '导航栏模式'),
        );
    expect(navigationModePreference.popupMinWidth, 238.5);
    // The component library now owns the density-sensitive Compose line-box
    // correction; translated example pages no longer carry private offsets.
    expect(navigationModePreference.popupAnchorOffset, Offset.zero);
    await tester.tap(find.text('导航栏模式'));
    await tester.pumpAndSettle();
    // Localization shortens the longest option, but the translated example
    // retains the source English popup's measured width.
    expect(
      tester.getSize(find.byType(MiuixListPopupColumn)).width,
      closeTo(238.5, .01),
    );
    await tester.tap(find.text('仅文字').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MiuixNavigationBar>(find.byType(MiuixNavigationBar))
          .displayMode,
      MiuixNavigationBarDisplayMode.textOnly,
    );

    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MiuixIosLiquidGlassNavigationBar>(
            find.byType(MiuixIosLiquidGlassNavigationBar),
          )
          .displayMode,
      MiuixFloatingNavigationBarDisplayMode.iconAndText,
    );
    await _centerReferenceSetting(tester, '悬浮导航栏显示模式');
    await tester.tap(find.text('悬浮导航栏显示模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('仅图标').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MiuixIosLiquidGlassNavigationBar>(
            find.byType(MiuixIosLiquidGlassNavigationBar),
          )
          .displayMode,
      MiuixFloatingNavigationBarDisplayMode.iconOnly,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('conditional settings rows use the source visibility animation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    expect(find.text('导航栏模式'), findsNothing);
    expect(find.text('悬浮导航栏样式'), findsNothing);
    expect(find.text('悬浮导航栏位置'), findsNothing);

    // Start from the regular state so the assertions below cover the same
    // immediate floating insertion and nested regular exit transition.
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    expect(find.text('导航栏模式'), findsOneWidget);

    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pump();
    expect(find.text('悬浮导航栏样式'), findsNothing);
    expect(find.text('悬浮导航栏位置'), findsNothing);
    expect(find.text('导航栏模式'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 150));
    final bottomTransition = find.byKey(
      const ValueKey('reference-bottom-navigation-transition'),
    );
    expect(find.byKey(const ValueKey('regular-navigation')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('ios-floating-navigation')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: bottomTransition,
        matching: find.byType(AnimatedSwitcher),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: bottomTransition,
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    final regularOpacity = tester.widget<ReferenceLayerOpacity>(
      find.byKey(const ValueKey('reference-navigation-regular-opacity')),
    );
    final regularSize = tester.widget<Align>(
      find.byKey(const ValueKey('reference-navigation-regular-size')),
    );
    expect(regularOpacity.opacity, inExclusiveRange(0.0, 1.0));
    expect(regularSize.heightFactor, inExclusiveRange(0.0, 1.0));
    expect(regularSize.alignment, Alignment.topCenter);
    await tester.pumpAndSettle();
    expect(find.text('导航栏模式'), findsNothing);
    expect(find.text('悬浮导航栏样式'), findsNothing);
    expect(find.text('悬浮导航栏位置'), findsNothing);
    expect(find.byKey(const ValueKey('regular-navigation')), findsNothing);
    expect(
      find.byKey(const ValueKey('ios-floating-navigation')),
      findsOneWidget,
    );

    // Disabling floating mode removes that direct `if` branch immediately;
    // only the ordinary bar receives the nested top-anchored enter spring.
    await _centerReferenceSetting(tester, '使用悬浮导航栏');
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pump();
    expect(find.byKey(const ValueKey('ios-floating-navigation')), findsNothing);
    expect(find.byKey(const ValueKey('regular-navigation')), findsOneWidget);
    expect(
      tester
          .widget<ReferenceLayerOpacity>(
            find.byKey(const ValueKey('reference-navigation-regular-opacity')),
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Align>(
            find.byKey(const ValueKey('reference-navigation-regular-size')),
          )
          .heightFactor,
      0,
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester
          .widget<ReferenceLayerOpacity>(
            find.byKey(const ValueKey('reference-navigation-regular-opacity')),
          )
          .opacity,
      inExclusiveRange(0.0, 1.0),
    );
    await tester.pumpAndSettle();

    // The outer layer independently applies the source bottom-anchored
    // fade/expand pair when the complete navigation area is shown or hidden.
    await _centerReferenceSetting(tester, '显示导航栏');
    await tester.tap(find.text('显示导航栏'));
    await tester.pump();
    expect(
      tester
          .widget<ReferenceLayerOpacity>(
            find.byKey(const ValueKey('reference-navigation-outer-opacity')),
          )
          .opacity,
      1,
    );
    await tester.pump(const Duration(milliseconds: 32));
    expect(
      tester
          .widget<ReferenceLayerOpacity>(
            find.byKey(const ValueKey('reference-navigation-outer-opacity')),
          )
          .opacity,
      inExclusiveRange(0.0, 1.0),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('navigation-hidden')), findsOneWidget);

    await tester.tap(find.text('显示导航栏'));
    await tester.pump();
    expect(
      tester
          .widget<ReferenceLayerOpacity>(
            find.byKey(const ValueKey('reference-navigation-outer-opacity')),
          )
          .opacity,
      0,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('regular-navigation')), findsOneWidget);
    expect(find.text('悬浮导航栏显示模式'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation transition settings drive the actual route scenes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 300);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    // Halfway through the source 500ms transition, the target travels in from
    // the right while the retained root scene moves left and receives dimming.
    final translatedScenes = tester.widgetList<FractionalTranslation>(
      find.byKey(const ValueKey('reference-nav-transition-scene')),
    );
    expect(translatedScenes.any((scene) => scene.translation.dx > 0), isTrue);
    expect(translatedScenes.any((scene) => scene.translation.dx < 0), isTrue);
    expect(
      find.byKey(const ValueKey('reference-nav-transition-corner-clip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('reference-nav-transition-dim')),
      findsOneWidget,
    );
    expect(
      tester
          .widgetList<AbsorbPointer>(
            find.byKey(const ValueKey('reference-nav-transition-input-block')),
          )
          .any((barrier) => barrier.absorbing),
      isFalse,
    );
    // About intentionally animates its texture forever. Finish the remaining
    // 250 ms route duration with a bounded pump instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 300));
    final aboutRoute = ModalRoute.of(
      tester.element(find.text('Miuix for Compose').first),
    )!;
    expect(aboutRoute.allowSnapshotting, isFalse);
    await tester.tap(find.byKey(const ValueKey('about-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // Programmatic pop uses one shared depth response for both pages. The top
    // scene moves toward the trailing edge while the retained Settings page
    // returns from its leading quarter-width parallax without a stationary
    // first frame or a late alpha jump.
    final returningScenes = tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('reference-nav-transition-scene')),
        )
        .map((scene) => scene.translation.dx);
    expect(returningScenes.any((value) => value > .01), isTrue);
    expect(returningScenes.any((value) => value < -.01), isTrue);
    final returningOpacities = tester
        .widgetList<Opacity>(
          find.byKey(
            const ValueKey('reference-nav-transition-covered-opacity'),
          ),
        )
        .map((opacity) => opacity.opacity);
    expect(returningOpacities.any((value) => value > .9 && value < 1), isTrue);

    // The dim is a fixed full-window sibling, not a child of either translated
    // route. This prevents a bright strip from appearing beside the returning
    // previous page while the quarter-width parallax is still non-zero.
    final returningDim = find.byKey(
      const ValueKey('reference-nav-transition-dim'),
    );
    expect(returningDim, findsOneWidget);
    expect(
      find.ancestor(
        of: returningDim,
        matching: find.byKey(const ValueKey('reference-nav-transition-scene')),
      ),
      findsNothing,
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Current AppState starts with visual effects enabled but input blocking
    // disabled. Invert all three through the actual rows to prove that the
    // controls drive route composition rather than a settings-only model.
    for (final label in const ['启用圆角裁剪', '启用背景变暗', '转场期间阻止输入']) {
      await _centerReferenceSetting(tester, label, scrollDelta: 220);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }
    await _centerReferenceSetting(tester, '关于', scrollDelta: 220);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(
      find.byKey(const ValueKey('reference-nav-transition-corner-clip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reference-nav-transition-dim')),
      findsNothing,
    );
    expect(
      tester
          .widgetList<AbsorbPointer>(
            find.byKey(const ValueKey('reference-nav-transition-input-block')),
          )
          .any((barrier) => barrier.absorbing),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('AOSP transition selection drives the classic activity scene', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    // This row used to update only the settings model. Select it through the
    // real overlay and prove that the following route uses the source's
    // separate 450ms CrossActivity programmatic branch.
    await _centerReferenceSetting(tester, '转场样式', scrollDelta: 260);
    await tester.tap(find.text('转场样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AOSP').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 260);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final aboutTitle = find.text('Miuix for Compose').first;
    final route = ModalRoute.of(tester.element(aboutTitle))!;
    expect(route.transitionDuration, const Duration(milliseconds: 450));
    expect(route.reverseTransitionDuration, const Duration(milliseconds: 450));
    expect(
      find.byKey(const ValueKey('reference-nav-transition-scene')),
      findsNothing,
    );

    // At 100ms the opening scene is partway through +96 -> 0 while the
    // retained scene is partway through 0 -> -96. Only the incoming scene
    // runs the independent 50ms-offset, 83ms alpha ramp.
    final translations = tester
        .widgetList<Transform>(
          find.byKey(const ValueKey('reference-aosp-transition-scene')),
        )
        .map((scene) => scene.transform.getTranslation().x)
        .toList();
    expect(translations.any((value) => value > 0 && value < 96), isTrue);
    expect(translations.any((value) => value < 0 && value > -96), isTrue);
    final opacities = tester
        .widgetList<Opacity>(
          find.byKey(const ValueKey('reference-aosp-transition-opacity')),
        )
        .map((opacity) => opacity.opacity)
        .toList();
    expect(opacities.any((value) => value > 0 && value < 1), isTrue);
    expect(opacities.any((value) => value == 1), isTrue);

    // Classic activity open/close never uses the predictive-back scrim or
    // scale. CrossActivity's All mode clips both moving layers and falls back
    // to the source's 32dp desktop radius when no Android radius is reported.
    expect(
      find.byKey(const ValueKey('reference-aosp-transition-dim')),
      findsNothing,
    );
    expect(
      tester
          .widgetList<Transform>(
            find.byKey(const ValueKey('reference-aosp-transition-scale')),
          )
          .every((transform) => transform.transform.storage[0] == 1),
      isTrue,
    );
    final clips = tester.widgetList<ClipPath>(
      find.byKey(const ValueKey('reference-aosp-transition-corner-clip')),
    );
    expect(clips, hasLength(2));
    for (final clip in clips) {
      final shape =
          (clip.clipper! as ShapeBorderClipper).shape as MiuixSquircleBorder;
      expect(shape.borderRadius, BorderRadius.circular(32));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('AOSP predictive back matches card geometry and settle channels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const platformChannel = MethodChannel('flutter_miuix/platform');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platformChannel,
      (call) async => call.method == 'screenCornerRadius' ? 24.0 : null,
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platformChannel,
        null,
      );
    });

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '转场样式', scrollDelta: 260);
    await tester.tap(find.text('转场样式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AOSP').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '启用滑动返回', scrollDelta: 220);
    await tester.tap(find.text('启用滑动返回'));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 220);
    await tester.tap(find.text('关于'));
    await tester.pump();
    // Give the 500ms route controller one scheduling frame on each side; the
    // animation itself remains a single source-duration transition.
    await tester.pump(const Duration(milliseconds: 520));
    await tester.pump();

    final route = ModalRoute.of(
      tester.element(find.text('Miuix for Compose').first),
    )!;
    expect(
      await _sendPredictiveBackMethod('startBackGesture', const {
        'touchOffset': [1.0, 360.0],
        'progress': 0.0,
        'swipeEdge': 0,
      }),
      isTrue,
    );
    // Flutter's event object omits Android's frame timestamp. The adapter
    // pairs each callback with the scheduler's monotonic system-frame time;
    // two 0.2 progress steps at 100ms intervals reproduce the source's exact
    // 2 progress-unit/s release sample.
    await tester.pump(const Duration(milliseconds: 100));
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [75.0, 430.0],
      'progress': 0.2,
      'swipeEdge': 0,
    });
    await tester.pump(const Duration(milliseconds: 100));
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [150.0, 500.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();

    // Both layers share the gesture-shaped 0.9..1 centered scale and the
    // damped touch-Y channel. The outgoing left-edge card hugs the physical
    // right edge while the revealed scene remains parked one 96dp drift back.
    final scaleTransforms = tester.widgetList<Transform>(
      find.byKey(const ValueKey('reference-aosp-transition-scale')),
    );
    final scales = scaleTransforms
        .map((transform) => transform.transform.storage[0])
        .toList();
    expect(scales, hasLength(2));
    expect(scales.every((value) => value > .9 && value < 1), isTrue);
    expect((scales.first - scales.last).abs(), lessThan(.0001));
    final sceneOffsets = tester
        .widgetList<Transform>(
          find.byKey(const ValueKey('reference-aosp-transition-scene')),
        )
        .map((scene) => scene.transform.getTranslation())
        .toList();
    expect(sceneOffsets.any((offset) => offset.x > 0), isTrue);
    expect(sceneOffsets.any((offset) => offset.x < 0), isTrue);
    expect(sceneOffsets.every((offset) => offset.y > 0), isTrue);

    final dim = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('reference-aosp-transition-dim')),
    );
    expect(dim.color.a, closeTo(.2, .001));
    final clips = tester.widgetList<ClipPath>(
      find.byKey(const ValueKey('reference-aosp-transition-corner-clip')),
    );
    expect(clips, hasLength(2));
    for (final clip in clips) {
      final shape =
          (clip.clipper! as ShapeBorderClipper).shape as MiuixSquircleBorder;
      expect(shape.borderRadius, BorderRadius.circular(24));
    }

    // Cancellation is the source's critically damped stiffness-1500 spring,
    // not Flutter's duration-scaled linear return. From 0.6 it is already past
    // 0.75 after 50ms and returns to the route rest state without popping.
    await _sendPredictiveBackMethod('cancelBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(route.animation!.value, greaterThan(.75));
    await tester.pump(const Duration(milliseconds: 400));
    expect(route.animation!.status, AnimationStatus.completed);
    expect(route.navigator!.userGestureInProgress, isFalse);

    // A committed gesture holds its exact release pose, then uses a fresh
    // fixed 450ms timeline. At 45ms the outgoing card's wall-clock alpha is
    // exactly halfway gone and the .2 light scrim has faded to .18.
    await _sendPredictiveBackMethod('startBackGesture', const {
      'touchOffset': [1.0, 360.0],
      'progress': 0.0,
      'swipeEdge': 0,
    });
    await tester.pump(const Duration(milliseconds: 100));
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [75.0, 430.0],
      'progress': 0.2,
      'swipeEdge': 0,
    });
    await tester.pump(const Duration(milliseconds: 100));
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [150.0, 500.0],
      'progress': 0.4,
      'swipeEdge': 0,
    });
    await tester.pump();
    await _sendPredictiveBackMethod('commitBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 45));
    final committedScales = tester
        .widgetList<Transform>(
          find.byKey(const ValueKey('reference-aosp-transition-scale')),
        )
        .map((transform) => transform.transform.storage[0])
        .toList();
    // Main scale 0.924487... multiplied by the source 0.989158... bounce
    // becomes 0.914464..., then the 390px width snap yields 357/390.
    expect(committedScales, hasLength(2));
    expect(committedScales, everyElement(closeTo(357 / 390, 1e-9)));
    final committedOpacities = tester
        .widgetList<Opacity>(
          find.byKey(const ValueKey('reference-aosp-transition-opacity')),
        )
        .map((opacity) => opacity.opacity)
        .toList();
    expect(committedOpacities.any((value) => (value - .5).abs() < .01), isTrue);
    final committedDim = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('reference-aosp-transition-dim')),
    );
    expect(committedDim.color.a, closeTo(.18, .002));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('Miuix for Compose'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('AOSP predictive back restores the source release-velocity bounce', () {
    // NavDisplay.kt uses only the last two timestamped progress events. A
    // change from .2 to .5 over 150ms is therefore exactly 2 progress units/s.
    expect(
      debugReferenceBackProgressVelocity(
        previousProgress: .2,
        currentProgress: .5,
        previousTime: const Duration(milliseconds: 100),
        currentTime: const Duration(milliseconds: 250),
      ),
      closeTo(2, 1e-12),
    );
    expect(
      debugReferenceBackProgressVelocity(
        previousProgress: .2,
        currentProgress: .5,
        previousTime: const Duration(milliseconds: 250),
        currentTime: const Duration(milliseconds: 250),
      ),
      0,
    );

    // At 45ms an edge release at 2 progress/s produces the source 40-unit
    // kick and a 1.084134% dip. Doubling the release speed doubles the kick,
    // while an almost stationary early commit uses the source 120-unit floor.
    expect(
      debugReferenceCrossActivityBounceScale(
        releaseVelocity: 2,
        elapsed: const Duration(milliseconds: 45),
        gestureProgress: .4,
        swipeEdge: SwipeEdge.left,
      ),
      closeTo(.9891586554642643, 1e-12),
    );
    expect(
      debugReferenceCrossActivityBounceScale(
        releaseVelocity: 4,
        elapsed: const Duration(milliseconds: 45),
        gestureProgress: .4,
        swipeEdge: SwipeEdge.left,
      ),
      closeTo(.9783173109285288, 1e-12),
    );
    expect(
      debugReferenceCrossActivityBounceScale(
        releaseVelocity: 0,
        elapsed: const Duration(milliseconds: 45),
        gestureProgress: .05,
        swipeEdge: SwipeEdge.left,
      ),
      closeTo(.9674759663927931, 1e-12),
    );
    expect(
      debugReferenceCrossActivityBounceScale(
        releaseVelocity: 2,
        elapsed: const Duration(milliseconds: 450),
        gestureProgress: .4,
        swipeEdge: SwipeEdge.left,
      ),
      1,
    );
  });

  testWidgets('right-edge predictive back mirrors the MIUIX pop transition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '启用滑动返回', scrollDelta: 220);
    await tester.tap(find.text('启用滑动返回'));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '返回动画跟随滑动边缘', scrollDelta: 220);
    await tester.tap(find.text('返回动画跟随滑动边缘'));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 220);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();

    expect(
      await _sendPredictiveBackMethod('startBackGesture', const {
        'touchOffset': [389.0, 400.0],
        'progress': 0.0,
        'swipeEdge': 1,
      }),
      isTrue,
    );
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [260.0, 400.0],
      'progress': 0.5,
      'swipeEdge': 1,
    });
    await tester.pump();

    final translations = tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('reference-nav-transition-scene')),
        )
        .map((scene) => scene.translation.dx)
        .toList();
    expect(translations.any((value) => (value + .5).abs() < 1e-9), isTrue);
    expect(translations.any((value) => (value - .125).abs() < 1e-9), isTrue);

    final clip = tester.widget<ClipPath>(
      find.byKey(const ValueKey('reference-nav-transition-corner-clip')),
    );
    final shape =
        (clip.clipper! as ShapeBorderClipper).shape as MiuixSquircleBorder;
    // Widget tests have no Android rounded-corner channel. The current source
    // returns 0 on non-Android targets; real devices supply their system radius.
    expect(shape.borderRadius.topRight.x, 0);
    expect(shape.borderRadius.bottomRight.x, 0);
    expect(shape.borderRadius.topLeft.x, 0);
    expect(
      tester
          .widgetList<AbsorbPointer>(
            find.byKey(const ValueKey('reference-nav-transition-input-block')),
          )
          .where((barrier) => barrier.absorbing),
      isEmpty,
    );

    await _sendPredictiveBackMethod('cancelBackGesture');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.text('Miuix for Compose'), findsWidgets);
    final aboutRoute = ModalRoute.of(
      tester.element(find.text('Miuix for Compose').first),
    )!;
    expect(aboutRoute.animation!.status, AnimationStatus.completed);
    expect(aboutRoute.navigator!.userGestureInProgress, isFalse);
    expect(aboutRoute.popGestureEnabled, isTrue);

    await _sendPredictiveBackMethod('startBackGesture', const {
      'touchOffset': [389.0, 400.0],
      'progress': 0.0,
      'swipeEdge': 1,
    });
    await _sendPredictiveBackMethod('updateBackGestureProgress', const {
      'touchOffset': [280.0, 400.0],
      'progress': 0.4,
      'swipeEdge': 1,
    });
    await tester.pump();
    await _sendPredictiveBackMethod('commitBackGesture');
    await tester.pump();
    final releaseTranslations = tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('reference-nav-transition-scene')),
        )
        .map((scene) => scene.translation.dx)
        .toList();
    expect(
      releaseTranslations.any((value) => (value + .4).abs() < 1e-9),
      isTrue,
      reason: 'commit must retain the exact predictive release pose',
    );
    expect(
      releaseTranslations.any((value) => (value - .15).abs() < 1e-9),
      isTrue,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final movingTranslations = tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('reference-nav-transition-scene')),
        )
        .map((scene) => scene.translation.dx)
        .toList();
    expect(movingTranslations.any((value) => value < -.4), isTrue);
    await tester.pump(const Duration(milliseconds: 550));
    expect(find.text('Miuix for Compose'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('liquid floating navigation follows HyperOS 4 geometry', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '玻璃模糊与透明度');
    await tester.tap(find.text('玻璃模糊与透明度'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 档 · 最强').last);
    await tester.pumpAndSettle();
    expect(
      MiuixTheme.of(tester.element(find.text('玻璃模糊与透明度'))).glassIntensity,
      MiuixGlassIntensity.intense,
    );
    final floatingGlass = find.byKey(
      const ValueKey('ios-liquid-backdrop-filter'),
    );
    expect(
      find.descendant(of: floatingGlass, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    // The liquid panel owns its dedicated 4dp blur, local lens, and gravity-
    // rotated BloomStroke instead of inheriting the generic navigation glass.
    expect(
      find.descendant(
        of: floatingGlass,
        matching: find.byType(MiuixHighlightOverlay),
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).first).extendBody,
      isTrue,
    );
    // The root scaffold extends behind navigation while the active page's own
    // scaffold extends behind its glass app bar, matching the source nesting.
    expect(
      tester
          .widget<Scaffold>(find.byType(Scaffold).last)
          .extendBodyBehindAppBar,
      isTrue,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('reference-settings-ui-card')),
        matching: find.text('悬浮导航栏样式'),
      ),
      findsNothing,
    );

    // The unified component keeps the 24/56/4 panel geometry while giving the
    // selected tint exactly one equal-width destination slot. The complete
    // panel owns the sole backdrop sample; the selected slot must not blur the
    // already blurred result a second time.
    expect(find.byType(MiuixIosLiquidGlassNavigationBar), findsOneWidget);
    expect(find.byType(MiuixFloatingNavigationBar), findsNothing);
    expect(find.text('悬浮导航栏位置'), findsNothing);
    final panel = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-panel')),
    );
    final indicator = tester.getRect(
      find.byKey(const ValueKey('ios-liquid-indicator')),
    );
    final surface = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('ios-liquid-surface')),
    );
    expect(panel.left, 24);
    expect(panel.right, 366);
    expect(panel.height, 56);
    expect(panel.bottom, 808);
    expect(indicator.height, 48);
    expect(indicator.top - panel.top, 4);
    expect(indicator.width, closeTo(66.8, .01));
    expect(
      surface.color.a,
      closeTo(MiuixGlassIntensity.intense.resolveOpacity(.4), .001),
    );
    expect(
      find.descendant(
        of: find.byType(MiuixIosLiquidGlassNavigationBar),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('ios-liquid-indicator-lens-filter')),
      findsNothing,
    );

    final previousComparator = goldenFileComparator;
    // Keep the golden scoped to the iOS glass component. The independent top
    // glass bar otherwise contributes platform-sensitive title glyph edges;
    // complete shell geometry, filter presence, and alpha are asserted above.
    goldenFileComparator = _TolerantReferenceGoldenComparator(
      Uri.parse('test/reference_structure_test.dart'),
      precisionTolerance: 0.006,
    );
    addTearDown(() => goldenFileComparator = previousComparator);
    await expectLater(
      find.byType(MiuixIosLiquidGlassNavigationBar),
      matchesGoldenFile('goldens/ios_floating_navigation_shell.png'),
    );
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('搜索图标'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings opens the localized About and licenses routes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 300);
    await tester.tap(find.text('关于'));
    // The source background is continuously animated. Advance the route by a
    // deterministic interval instead of waiting for an intentionally live
    // ticker to report that no frame is scheduled.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Finalize the completed route without advancing the continuously
    // animated texture clock used by the deterministic About golden.
    await tester.pump();
    // Raster decoding is real asynchronous work even under the fake widget
    // clock. Yield briefly so the already-mounted Image can populate Flutter's
    // cache, then paint the decoded frame. Waiting on precacheImage itself
    // would deadlock because its listener needs this following test pump.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    // The source About route uses a dedicated compact bar, large identity
    // header, two texture-blurred cards, and a generated-licenses route.
    final aboutTitle = find.byWidgetPredicate(
      (widget) =>
          widget is MiuixForegroundBlurText &&
          widget.text == 'Miuix for Compose',
    );
    expect(aboutTitle, findsOneWidget);
    expect(
      tester.widget<MiuixForegroundBlurText>(aboutTitle).backdrop.blur,
      150,
    );
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/ic_launcher.png'),
        tester.element(aboutTitle),
      );
    });
    await tester.pump();
    // Commit the decoded asset to the Image widget without waiting for the
    // intentionally perpetual effect-background ticker to settle.
    await tester.pump(const Duration(milliseconds: 16));
    expect(
      tester
          .getSize(
            find.descendant(
              of: aboutTitle,
              matching: find.byKey(
                const ValueKey('miuix-foreground-blur-mask'),
              ),
            ),
          )
          .width,
      lessThan(340),
    );
    expect(
      find.descendant(
        of: find.byKey(const PageStorageKey('miuix-reference-about')),
        matching: find.text('v1.0.9 (228)'),
      ),
      findsOneWidget,
    );
    expect(find.text('查看源代码'), findsOneWidget);
    expect(find.text('加入群组'), findsOneWidget);
    expect(find.text('许可证'), findsOneWidget);
    expect(find.text('第三方许可证'), findsOneWidget);
    // The source wraps the preference cards in fillParentMaxHeight(), leaving
    // exactly the 380dp logo spacer as scrollable collapse distance even when
    // all cards already fit in the visible viewport.
    final aboutList = tester.widget<ListView>(
      find.byKey(const PageStorageKey('miuix-reference-about')),
    );
    final aboutBar = find.byKey(const ValueKey('reference-about-scrollbar'));
    expect(aboutBar, findsOneWidget);
    expect(
      identical(
        tester.widget<MiuixVerticalScrollBar>(aboutBar).controller,
        aboutList.controller,
      ),
      isTrue,
    );
    expect(aboutList.controller!.position.maxScrollExtent, closeTo(380, .01));
    // Capture the initial resting state before exercising the scrollbar. The
    // source thumb is transient and is intentionally absent before scrolling.
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('goldens/about_page.png'),
    );
    final initialLinksTop = tester.getTopLeft(find.text('查看源代码')).dy;
    aboutList.controller!.jumpTo(
      aboutList.controller!.position.maxScrollExtent,
    );
    await tester.pump();
    expect(
      initialLinksTop - tester.getTopLeft(find.text('查看源代码')).dy,
      closeTo(380, .01),
    );
    expect(
      tester
          .widget<MiuixSmallTopAppBar>(find.byType(MiuixSmallTopAppBar))
          .titleColor!
          .a,
      1,
    );
    expect(
      find.descendant(
        of: aboutBar,
        matching: find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
      ),
      findsOneWidget,
    );
    aboutList.controller!.jumpTo(0);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('about-identity')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('背景效果'), findsOneWidget);
    expect(find.text('效果版本'), findsOneWidget);
    expect(find.text('OS3'), findsOneWidget);
    expect(find.text('动态背景'), findsOneWidget);
    expect(find.text('全屏背景'), findsOneWidget);
    expect(find.text('纹理设置'), findsNothing);
    expect(find.text('模糊半径'), findsNothing);
    expect(find.text('混合模式'), findsNothing);
    final backgroundSheet = tester.getRect(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    expect(backgroundSheet.top, greaterThan(56));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('about-background-controls')),
        matching: find.byType(MiuixSwitch),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('about-background-controls')),
        matching: find.byType(MiuixSlider),
      ),
      findsNothing,
    );
    await tester.tap(find.text('OS3'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.tap(find.text('OS2').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('OS2'), findsOneWidget);
    // Dismiss through the real dim layer above the content-sized source sheet.
    await tester.tapAt(const Offset(5, 30));
    await tester.pump();
    // BottomSheetContentLayout.kt uses the 0.9/0.38 Folme spring. Let the
    // source-equivalent 680ms route finish before interacting behind its dim.
    await tester.pump(const Duration(milliseconds: 720));

    await tester.tap(find.text('第三方许可证'));
    await tester.pumpAndSettle();
    // The source also loads its generated JSON asynchronously. Let that real
    // asset read finish before asking the test binding for the resulting row.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.text('第三方许可证'), findsWidgets);
    // LicensePage.kt reads the generated inventory without transforming or
    // re-sorting it; the AndroidX Activity row is therefore first.
    expect(find.text('Activity'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('androidx.activity:activity')),
        matching: find.text('1.13.0, Apache-2.0'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Apache-2.0'), findsWidgets);
    final licenseBar = find.byKey(
      const ValueKey('reference-license-scrollbar'),
    );
    final licenseListFinder = find.byKey(
      const PageStorageKey('miuix-reference-licenses'),
    );
    final licenseList = tester.widget<ListView>(licenseListFinder);
    expect(licenseBar, findsOneWidget);
    expect(
      identical(
        tester.widget<MiuixVerticalScrollBar>(licenseBar).controller,
        licenseList.controller,
      ),
      isTrue,
    );
    await tester.drag(licenseListFinder, const Offset(0, -80));
    await tester.pump();
    expect(
      find.descendant(
        of: licenseBar,
        matching: find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
      ),
      findsOneWidget,
    );
    // LicensePage.kt has no compact navigation-bar content inset. The last
    // record stops exactly one independent 12dp Spacer above the viewport;
    // adding MediaQuery.bottom or duplicating the spacer leaves a visibly
    // larger empty strip than the source.
    // A builder list refines its far-end estimate after materializing the last
    // records, so land on the recomputed maximum before measuring the spacer.
    for (var pass = 0; pass < 2; pass++) {
      licenseList.controller!.jumpTo(
        licenseList.controller!.position.maxScrollExtent,
      );
      await tester.pump();
    }
    expect(
      tester
          .getRect(find.byKey(const ValueKey('org.jspecify:jspecify')))
          .bottom,
      closeTo(tester.getRect(licenseListFinder).bottom - 12, .01),
    );

    // Reuse this already-loaded route for the same-device 420dpi geometry
    // contract. Keeping the assertions in this navigation test avoids a
    // second asynchronous asset route racing the Golden-heavy full suite.
    licenseList.controller!.jumpTo(0);
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await tester.pump();

    Finder cardFor(String uniqueId) => find.descendant(
      of: find.byKey(ValueKey(uniqueId)),
      matching: find.byType(MiuixSurface),
    );
    final first = tester.getRect(cardFor('androidx.activity:activity'));
    final second = tester.getRect(
      cardFor('androidx.activity:activity-compose'),
    );
    // The localized HyperOS 4 license list begins below its compact glass bar.
    // Row height and pitch remain source-compatible; only the page header
    // placement follows the current application baseline.
    expect(first.left * 2.625, closeTo(32, .001));
    expect(first.right * 2.625, closeTo(1048, .001));
    expect(first.top * 2.625, closeTo(300.75, .001));
    expect(first.height * 2.625, closeTo(179, .001));
    expect((second.top - first.top) * 2.625, closeTo(211, .001));
    final experimental = tester.getRect(
      find.byKey(const ValueKey('androidx.annotation:annotation-experimental')),
    );
    final annotation = tester.getRect(
      find.byKey(const ValueKey('androidx.annotation:annotation-jvm')),
    );
    expect(experimental.top, lessThan(annotation.top));

    await tester.tap(find.byKey(const ValueKey('licenses-back')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(aboutTitle, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('about-back')));
    await tester.pumpAndSettle();
    expect(find.text('关于'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about page preserves source physical geometry at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 300);
    await tester.tap(find.text('关于'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    final identity = tester.getRect(
      find.byKey(const ValueKey('about-identity')),
    );
    final linksCard = tester.getRect(
      find.byKey(const ValueKey('reference-about-links-card')),
    );
    final licensesCard = tester.getRect(
      find.byKey(const ValueKey('reference-about-licenses-card')),
    );

    // HyperOS 4 increases the two-row cards to a 120dp touch-friendly height;
    // the identity stage and independent 12dp inter-card gap remain fixed.
    expect(identity.top * sourceDensity, closeTo(200, .001));
    expect(identity.bottom * sourceDensity, closeTo(1198, .001));
    expect(linksCard.top * sourceDensity, closeTo(1198, .001));
    expect(linksCard.height * sourceDensity, closeTo(315, .001));
    expect(
      (licensesCard.top - linksCard.bottom) * sourceDensity,
      closeTo(32, .001),
    );
    expect(licensesCard.height * sourceDensity, closeTo(315, .001));

    // AboutPage.kt does not fade the three identity elements at arbitrary
    // fractions of the 380dp spacer. It records their initial window bottoms,
    // then constructs a delayed version stage followed by the name and icon.
    final versionOpacity = find.byKey(const ValueKey('about-version-opacity'));
    final nameOpacity = find.byKey(const ValueKey('about-name-opacity'));
    final iconOpacity = find.byKey(const ValueKey('about-icon-opacity'));
    final versionBottom = tester.getRect(versionOpacity).bottom;
    final nameBottom = tester.getRect(nameOpacity).bottom;
    final iconBottom = tester.getRect(iconOpacity).bottom;
    final stage1 = identity.bottom - versionBottom;
    final stage2 = versionBottom - nameBottom;
    final stage3 = nameBottom - iconBottom;
    final versionDelay = stage1 * .5;
    final aboutList = tester.widget<ListView>(
      find.byKey(const PageStorageKey('miuix-reference-about')),
    );

    // At 50dp the source has not reached the half-stage version delay.
    aboutList.controller!.jumpTo(50);
    await tester.pump();
    expect(tester.widget<Opacity>(versionOpacity).opacity, 1);
    expect(tester.widget<Opacity>(nameOpacity).opacity, 1);
    expect(tester.widget<Opacity>(iconOpacity).opacity, 1);

    // At 100dp only the version is part-way through its first stage.
    aboutList.controller!.jumpTo(100);
    await tester.pump();
    final expectedVersion =
        1 -
        ((100 - versionDelay) / math.max(1.0, stage1 - versionDelay)).clamp(
          0.0,
          1.0,
        );
    expect(
      tester.widget<Opacity>(versionOpacity).opacity,
      closeTo(expectedVersion, .001),
    );
    expect(tester.widget<Opacity>(nameOpacity).opacity, 1);
    expect(tester.widget<Opacity>(iconOpacity).opacity, 1);

    // Once stage one has ended, the name fades before the icon begins.
    final nameProbe = stage1 + stage2 * .5;
    aboutList.controller!.jumpTo(nameProbe);
    await tester.pump();
    expect(tester.widget<Opacity>(versionOpacity).opacity, 0);
    expect(tester.widget<Opacity>(nameOpacity).opacity, closeTo(.5, .001));
    expect(tester.widget<Opacity>(iconOpacity).opacity, 1);

    final iconProbe = stage1 + stage2 + stage3 * .5;
    aboutList.controller!.jumpTo(iconProbe);
    await tester.pump();
    expect(tester.widget<Opacity>(versionOpacity).opacity, 0);
    expect(tester.widget<Opacity>(nameOpacity).opacity, 0);
    expect(tester.widget<Opacity>(iconOpacity).opacity, closeTo(.5, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar visibility uses the source fade-only spring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '显示浮动工具栏');

    expect(
      find.byKey(const ValueKey('example-floating-toolbar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reference-toolbar-visibility-hidden')),
      findsOneWidget,
    );

    // Enter starts at alpha zero with the final toolbar size already measured.
    await tester.tap(find.text('显示浮动工具栏'));
    await tester.pump();
    final opacityFinder = find.byKey(
      const ValueKey('reference-toolbar-visibility-opacity'),
    );
    double opacity() =>
        tester.widget<ReferenceLayerOpacity>(opacityFinder).opacity;
    expect(opacity(), 0);
    final enterSize = tester.getSize(
      find.byKey(const ValueKey('example-floating-toolbar')),
    );
    await tester.pump(const Duration(milliseconds: 16));
    expect(opacity(), inExclusiveRange(0.0, 1.0));
    expect(
      tester.getSize(find.byKey(const ValueKey('example-floating-toolbar'))),
      enterSize,
    );
    await tester.pumpAndSettle();
    expect(opacity(), 1);

    // Exit retains the same measured child and can reverse without an alpha
    // jump because the new spring starts from the live value and velocity.
    await _centerReferenceSetting(tester, '显示浮动工具栏');
    await tester.tap(find.text('显示浮动工具栏'));
    await tester.pump();
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 32));
    final exitingOpacity = opacity();
    expect(exitingOpacity, inExclusiveRange(0.0, 1.0));
    expect(
      tester.getSize(find.byKey(const ValueKey('example-floating-toolbar'))),
      enterSize,
    );

    await tester.tap(find.text('显示浮动工具栏'));
    await tester.pump();
    expect(opacity(), closeTo(exitingOpacity, .0001));
    await tester.pumpAndSettle();
    expect(opacity(), 1);

    // A completed exit finally removes the toolbar subtree.
    await _centerReferenceSetting(tester, '显示浮动工具栏');
    await tester.tap(find.text('显示浮动工具栏'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('example-floating-toolbar')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reference-toolbar-visibility-hidden')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('FPS monitor visibility uses the source fade-only spring', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('reference-fps-monitor')), findsNothing);
    expect(
      find.byKey(const ValueKey('reference-fps-monitor-hidden')),
      findsOneWidget,
    );

    // AppContent.kt supplies only fadeIn/fadeOut here: the monitor adopts its
    // final dimensions before the first visible frame and never expands.
    await tester.tap(find.text('显示 FPS 监视器'));
    await tester.pump();
    final opacityFinder = find.byKey(
      const ValueKey('reference-fps-visibility-opacity'),
    );
    double opacity() =>
        tester.widget<ReferenceLayerOpacity>(opacityFinder).opacity;
    expect(opacity(), 0);
    final monitorFinder = find.byKey(const ValueKey('reference-fps-monitor'));
    final monitorSize = tester.getSize(monitorFinder);
    await tester.pump(const Duration(milliseconds: 16));
    expect(opacity(), inExclusiveRange(0.0, 1.0));
    expect(tester.getSize(monitorFinder), monitorSize);
    await tester.pump(const Duration(seconds: 1));
    expect(opacity(), 1);

    await tester.tap(find.text('显示 FPS 监视器'));
    await tester.pump();
    expect(opacity(), 1);
    await tester.pump(const Duration(milliseconds: 32));
    expect(opacity(), inExclusiveRange(0.0, 1.0));
    expect(tester.getSize(monitorFinder), monitorSize);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('reference-fps-monitor')), findsNothing);
    expect(
      find.byKey(const ValueKey('reference-fps-monitor-hidden')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('floating toolbar settings control its real shell layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    // The HyperOS 4 default uses the shared floating-toolbar glass recipe.
    // The explicit non-glass compatibility path remains covered in the
    // component library tests.
    await _centerReferenceSetting(tester, '显示浮动工具栏');
    await tester.tap(find.text('显示浮动工具栏'));
    await tester.pumpAndSettle();

    expect(find.text('浮动工具栏位置'), findsOneWidget);
    expect(find.text('浮动工具栏方向'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('floating-toolbar-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('miuix-floating-toolbar-fill')),
      findsNothing,
    );
    final verticalEdit = tester.getRect(
      find.byKey(const ValueKey('floating-toolbar-edit')),
    );
    final verticalDelete = tester.getRect(
      find.byKey(const ValueKey('floating-toolbar-delete')),
    );
    expect(find.bySemanticsLabel('编辑'), findsOneWidget);
    expect(find.bySemanticsLabel('删除'), findsOneWidget);
    expect(find.bySemanticsLabel('更多'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('编辑'));
    await tester.pump();
    expect(find.text('编辑'), findsNothing);
    expect(verticalEdit.center.dx, verticalDelete.center.dx);
    expect(verticalDelete.top - verticalEdit.bottom, 8);
    expect(verticalEdit.center.dx, lessThan(100));
    final previousComparator = goldenFileComparator;
    // BackdropFilter output can vary by a few edge pixels between otherwise
    // identical Skia frames. Keep this one glass golden strict to 0.3% while
    // the exact toolbar positions above continue to use numeric assertions.
    goldenFileComparator = _TolerantReferenceGoldenComparator(
      Uri.parse('test/reference_structure_test.dart'),
      precisionTolerance: 0.003,
    );
    addTearDown(() => goldenFileComparator = previousComparator);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/floating_toolbar_shell.png'),
    );

    await tester.tap(find.text('浮动工具栏方向'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('横向').last);
    await tester.pump();
    final verticalToolbarSize = tester.getSize(
      find.byKey(const ValueKey('example-floating-toolbar')),
    );

    // AnimatedContent fades the old Column over 90ms. The incoming Row stays
    // invisible for that same delay, then fades and scales over 220ms.
    await tester.pump(const Duration(milliseconds: 45));
    FadeTransition incomingOpacity() => tester.widget<FadeTransition>(
      find.byKey(const ValueKey('reference-toolbar-incoming-opacity')),
    );
    FadeTransition outgoingOpacity() => tester.widget<FadeTransition>(
      find.byKey(const ValueKey('reference-toolbar-outgoing-opacity')),
    );
    ScaleTransition incomingScale() => tester.widget<ScaleTransition>(
      find.byKey(const ValueKey('reference-toolbar-incoming-scale')),
    );
    expect(outgoingOpacity().opacity.value, closeTo(.5, .02));
    expect(incomingOpacity().opacity.value, 0);
    expect(incomingScale().scale.value, closeTo(.92, .001));

    await tester.pump(const Duration(milliseconds: 45));
    expect(outgoingOpacity().opacity.value, closeTo(0, .001));
    expect(incomingOpacity().opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 110));
    expect(incomingOpacity().opacity.value, closeTo(.5, .02));
    expect(incomingScale().scale.value, closeTo(.96, .002));
    final midpointToolbarSize = tester.getSize(
      find.byKey(const ValueKey('example-floating-toolbar')),
    );
    expect(midpointToolbarSize.width, greaterThan(verticalToolbarSize.width));
    expect(midpointToolbarSize.height, lessThan(verticalToolbarSize.height));

    await tester.pumpAndSettle();
    final horizontalEdit = tester.getRect(
      find.byKey(const ValueKey('floating-toolbar-edit')),
    );
    final horizontalDelete = tester.getRect(
      find.byKey(const ValueKey('floating-toolbar-delete')),
    );
    expect(horizontalEdit.center.dy, horizontalDelete.center.dy);
    expect(horizontalDelete.left - horizontalEdit.right, 8);
    final horizontalToolbarSize = tester.getSize(
      find.byKey(const ValueKey('example-floating-toolbar')),
    );
    expect(horizontalToolbarSize.width, greaterThan(midpointToolbarSize.width));
    expect(horizontalToolbarSize.height, lessThan(midpointToolbarSize.height));

    await tester.tap(find.text('显示浮动操作按钮'));
    await tester.pumpAndSettle();
    expect(find.text('浮动操作按钮位置'), findsOneWidget);
    final endFab = tester.getRect(
      find.byKey(const ValueKey('example-floating-action-button')),
    );
    expect(endFab.center.dx, greaterThan(320));
    final fabPositionRow = tester.getRect(find.text('浮动操作按钮位置'));
    await tester.tapAt(Offset(340, fabPositionRow.center.dy));
    await tester.pumpAndSettle();
    await tester.tap(find.text('居中').last);
    await tester.pumpAndSettle();
    final centerFab = tester.getRect(
      find.byKey(const ValueKey('example-floating-action-button')),
    );
    expect(centerFab.center.dx, closeTo(195, 1));
    await tester.tap(
      find.byKey(const ValueKey('example-floating-action-button')),
    );
    await tester.pump();
    expect(find.text('GitHub'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home search matches source expansion and four suggestions', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(
      1080 / sourceDensity,
      2400 / sourceDensity,
    );
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 60 / sourceDensity);
    tester.view.viewPadding = const FakeViewPadding(top: 60 / sourceDensity);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final search = find
        .byKey(const ValueKey('miuix-search-bar-input'))
        .hitTestable();
    expect(find.text('基础组件'), findsWidgets);
    expect(find.text('取消'), findsNothing);

    // MainPage.kt expands the search in place, hides every component section,
    // slides Cancel in from the end, and always renders four fixed suggestions.
    await tester.tap(search);
    await tester.pumpAndSettle();
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('基础组件'), findsNothing);
    for (var index = 0; index < 4; index++) {
      expect(find.text('建议 $index'), findsOneWidget);
    }
    final searchTarget = find
        .descendant(
          of: find.byKey(const ValueKey('home-reference-search')).hitTestable(),
          matching: find.byKey(const ValueKey('miuix-search-bar-container')),
        )
        .hitTestable();
    final searchRect = tester.getRect(searchTarget);
    final cancelRect = tester.getRect(
      find.byKey(const ValueKey('home-search-cancel-slot')),
    );
    expect(searchRect.left * sourceDensity, closeTo(32, 1));
    expect(searchRect.right * sourceDensity, closeTo(879, 1));
    expect(cancelRect.left * sourceDensity, closeTo(911, 1));
    expect(cancelRect.right * sourceDensity, closeTo(1049, 1));
    expect(
      tester.getRect(find.text('建议 0')).left * sourceDensity,
      closeTo(42, 1),
    );

    await tester.enterText(search, '任意文本');
    await tester.tap(find.text('建议 2'));
    await tester.pumpAndSettle();
    expect(find.text('取消'), findsNothing);
    expect(find.text('建议 2'), findsNothing);
    expect(find.text('基础组件'), findsWidgets);
    expect(tester.widget<EditableText>(search).controller.text, isEmpty);

    await tester.tap(search);
    await tester.pumpAndSettle();
    await tester.enterText(search, '将被清空');
    await tester.tap(find.byKey(const ValueKey('home-search-cancel')));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(search).controller.text, isEmpty);
    expect(find.text('取消'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('current Home exposes localized breadcrumb tooltip and badge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final position = tester.state<ScrollableState>(homeScrollable).position;

    Future<void> reveal(Finder target) async {
      for (
        var attempt = 0;
        attempt < 120 && target.evaluate().isEmpty;
        attempt++
      ) {
        final next = (position.pixels + 520).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        position.jumpTo(next);
        await tester.pump(const Duration(milliseconds: 24));
      }
      expect(target, findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(target),
        alignment: .45,
        duration: Duration.zero,
      );
      await tester.pump();
    }

    final breadcrumb = find.byKey(
      const ValueKey('reference-breadcrumb-standalone'),
    );
    await reveal(breadcrumb);
    final breadcrumbOffset = position.pixels;
    expect(find.text('面包屑导航栏'), findsOneWidget);
    expect(find.text('内部存储'), findsWidgets);
    expect(
      find.text(
        '完整路径：/storage/emulated/0/DataBackup/apps/'
        'com.tencent.mobileqq/user_0',
      ),
      findsOneWidget,
    );

    final tooltipCard = find.byKey(const ValueKey('reference-tooltip-card'));
    await reveal(tooltipCard);
    final tooltipOffset = position.pixels;
    expect(tooltipOffset, greaterThan(breadcrumbOffset));
    await tester.longPress(
      find.byKey(const ValueKey('reference-tooltip-rich-anchor')),
    );
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('丰富工具提示'), findsOneWidget);
    expect(find.text('知道了'), findsOneWidget);
    await tester.tap(find.text('知道了'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('丰富工具提示'), findsNothing);

    final badgeCard = find.byKey(const ValueKey('reference-badge-card'));
    await reveal(badgeCard);
    expect(position.pixels, greaterThan(tooltipOffset));
    expect(
      find.descendant(of: badgeCard, matching: find.byType(MiuixBadgedBox)),
      findsNWidgets(4),
    );
    for (final label in const ['8', '99+', '5']) {
      expect(
        find.descendant(of: badgeCard, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('badge section preserves source 420dpi anchor geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final badgeCard = find.byKey(const ValueKey('reference-badge-card'));
    await _scrollUntilBuilt(tester, homeScroll, badgeCard);
    expect(badgeCard, findsOneWidget);
    await tester.scrollUntilVisible(badgeCard, 800, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(badgeCard),
      alignment: .2,
      duration: Duration.zero,
    );
    await tester.pump();

    const anchorKeys = [
      ValueKey('reference-badge-dot-anchor'),
      ValueKey('reference-badge-eight-anchor'),
      ValueKey('reference-badge-long-anchor'),
      ValueKey('reference-badge-five-anchor'),
    ];
    final anchors = [
      for (final key in anchorKeys) tester.getRect(find.byKey(key)),
    ];
    // BadgeSection.kt gives the 1016px card a 12dp inner inset, then asks a
    // FlowRow to distribute four 28dp anchors with SpaceEvenly. Compose rounds
    // the inset, anchors, and cumulative free-space shares independently.
    expect(
      anchors.map((rect) => (rect.left * density).round()).toList(),
      const [195, 400, 606, 811],
    );
    expect(
      anchors.map((rect) => rect.width * density).toSet(),
      everyElement(closeTo(74, .01)),
    );
    expect(anchors.map((rect) => rect.top).toSet().length, 1);

    final card = tester.getRect(badgeCard);
    expect((card.left * density).round(), 32);
    expect((card.right * density).round(), 1048);
    final dot = tester.getRect(
      find.byKey(const ValueKey('reference-badge-dot-surface')),
    );
    final eight = tester.getRect(
      find.byKey(const ValueKey('reference-badge-eight-surface')),
    );
    final long = tester.getRect(
      find.byKey(const ValueKey('reference-badge-long-surface')),
    );
    // Compose rounds the 6dp dot to 16px, the 12dp/14dp content offsets to
    // 32px/37px, and the 16dp content badge to 42px at this density.
    expect(dot.width * density, closeTo(16, .01));
    expect(dot.height * density, closeTo(16, .01));
    expect(eight.width * density, greaterThanOrEqualTo(42));
    expect(eight.height * density, closeTo(42, .01));
    expect((eight.left - anchors[1].left) * density, closeTo(42, .01));
    expect((eight.top - anchors[1].top) * density, closeTo(-5, .01));
    expect(long.width, greaterThan(eight.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home top bar keeps one HyperOS overflow cascading menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final options = find.byKey(const ValueKey('home-top-options-menu'));
    final sort = find.byKey(const ValueKey('home-top-sort-menu'));
    final selectAll = find.byKey(const ValueKey('home-top-select-all-menu'));
    expect(options, findsOneWidget);
    expect(sort, findsNothing);
    expect(selectAll, findsNothing);

    await tester.longPress(options);
    await tester.pump(const Duration(milliseconds: 220));
    expect(find.text('选项'), findsOneWidget);
    await tester.tapAt(const Offset(20, 400));
    await tester.pump(const Duration(milliseconds: 160));

    await tester.tap(options);
    await tester.pumpAndSettle();
    final primary = find.byKey(const ValueKey('miuix-cascading-primary'));
    expect(primary, findsOneWidget);
    // The source English menu is [255,205][828,733] at 420dpi. Chinese labels
    // remain translated while the popup preserves that exact 573px width.
    expect(tester.getSize(primary).width, closeTo(573 / 2.625, .01));
    expect(find.text('按拍摄日期排序'), findsOneWidget);
    expect(find.text('查看模式'), findsOneWidget);
    expect(find.text('筛选'), findsOneWidget);
    final primaryRect = tester.getRect(primary);
    final submenuTrigger = find
        .ancestor(of: find.text('查看模式'), matching: find.byType(MiuixPressable))
        .first;
    final triggerRect = tester.getRect(submenuTrigger);
    final triggerLabelRect = tester.getRect(find.text('查看模式'));
    await tester.tap(find.text('查看模式'));
    await tester.pump();
    final morphClip = find.byKey(
      const ValueKey('miuix-cascading-secondary-clip'),
    );
    expect(morphClip, findsOneWidget);
    Rect clipBounds() {
      final widget = tester.widget<ClipPath>(morphClip);
      return widget.clipper!.getClip(tester.getSize(morphClip)).getBounds();
    }

    // The source expansion starts as the exact trigger-row rectangle, then a
    // 0.99-damped 0.45s Folme spring reveals the complete secondary panel.
    expect(clipBounds().height, closeTo(triggerRect.height, .01));
    expect(
      tester.getRect(find.text('查看模式').last).top,
      closeTo(triggerLabelRect.top, .01),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(clipBounds().height, greaterThan(triggerRect.height));
    expect(clipBounds().height, lessThan(tester.getSize(morphClip).height));
    final intermediateLabelTop = tester.getRect(find.text('查看模式').last).top;
    expect(intermediateLabelTop, greaterThan(triggerLabelRect.top));
    expect(intermediateLabelTop, lessThan(triggerLabelRect.top + 8));
    await tester.pumpAndSettle();
    // Current CascadingListPopupLayout retains the masked primary plane and
    // aligns the independent secondary plane to the frozen trigger row.
    expect(primary, findsOneWidget);
    final secondary = find.byKey(
      const ValueKey('miuix-cascading-secondary-查看模式'),
    );
    expect(secondary, findsOneWidget);
    final secondaryRect = tester.getRect(secondary);
    expect(secondaryRect.left, closeTo(primaryRect.left, .01));
    expect(secondaryRect.top, closeTo(triggerRect.top, .01));
    expect(secondaryRect.width, closeTo(primaryRect.width, .01));
    expect(clipBounds().height, closeTo(secondaryRect.height, .01));
    expect(
      tester.getRect(find.text('查看模式').last).top,
      closeTo(triggerLabelRect.top + 8, .01),
    );
    expect(find.text('按日期分组'), findsOneWidget);
    expect(find.text('紧凑'), findsOneWidget);

    // Back at depth two collapses only the submenu.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('按日期分组'), findsNothing);
    expect(find.text('查看模式'), findsOneWidget);
    await tester.tap(find.text('查看模式'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('紧凑'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('miuix-cascading-primary')), findsNothing);

    expect(tester.takeException(), isNull);
  });

  testWidgets('current Home opens nested navigation and load-more fixtures', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final homePosition = tester.state<ScrollableState>(homeScrollable).position;

    Future<void> revealHome(Finder target) async {
      for (
        var attempt = 0;
        attempt < 140 && target.evaluate().isEmpty;
        attempt++
      ) {
        homePosition.jumpTo(
          (homePosition.pixels + 520).clamp(
            homePosition.minScrollExtent,
            homePosition.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 24));
      }
      expect(target, findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(target),
        alignment: .5,
        duration: Duration.zero,
      );
      await tester.pump();
    }

    final nestedEntry = find.text('嵌套导航测试');
    await revealHome(nestedEntry);
    expect(find.text('过度滚动与加载更多测试'), findsOneWidget);
    await tester.tap(nestedEntry);
    await tester.pumpAndSettle();

    expect(find.text('嵌套导航'), findsNWidgets(2));
    final nestedHintCard = find.byKey(
      const ValueKey('nested-navigation-hint-card'),
    );
    expect(
      tester.getSize(nestedHintCard).height,
      // At the test's 1x density, BasicComponent resolves to 100px and keeps
      // the source-derived two-physical-pixel CJK compensation after it. The
      // Android 2.625x release check verifies the final 265px card.
      closeTo(99 + 2 / 2.625, .001),
    );
    expect(
      find.byKey(const ValueKey('nested-navigation-stack-card')),
      findsOneWidget,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('nested-navigation-stack-card')))
          .height,
      420,
    );
    expect(find.text('层级 1'), findsOneWidget);
    await tester.tap(find.text('推入内部层级'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('nested-navigation-display')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('nested-navigation-depth-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('nested-navigation-depth-2')),
      findsOneWidget,
    );
    final pushLower = tester.widget<Transform>(
      find.byKey(
        const ValueKey<(String, Object)>((
          'miuix-nav-entry-transform',
          'nested-navigation-entry-1',
        )),
      ),
    );
    final pushUpper = tester.widget<Transform>(
      find.byKey(
        const ValueKey<(String, Object)>((
          'miuix-nav-entry-transform',
          'nested-navigation-entry-2',
        )),
      ),
    );
    expect(pushLower.transform.getTranslation().x, lessThan(0));
    expect(pushUpper.transform.getTranslation().x, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.text('层级 1 / 2'), findsOneWidget);
    expect(find.text('弹出内部层级'), findsOneWidget);

    // One system Back press is consumed by the inner stack.
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const ValueKey('nested-navigation-display')),
      findsOneWidget,
    );
    final popUpper = tester.widget<Transform>(
      find.byKey(
        const ValueKey<(String, Object)>((
          'miuix-nav-entry-transform',
          'nested-navigation-entry-2',
        )),
      ),
    );
    expect(popUpper.transform.getTranslation().x, greaterThan(0));
    await tester.pumpAndSettle();
    expect(find.text('层级 1'), findsOneWidget);
    expect(find.text('嵌套导航'), findsNWidgets(2));

    await tester.tap(find.text('在上方推入外部页面'));
    await tester.pumpAndSettle();
    expect(find.text('导航测试 1'), findsNWidgets(2));
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('层级 1'), findsOneWidget);

    // At the inner root, Back falls through and closes the nested page.
    expect(await tester.binding.handlePopRoute(), isTrue);
    // Home's live blur demonstration intentionally animates forever once its
    // bottom chapters have been built, so settle the route by duration.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final loadMoreEntry = find.text('过度滚动与加载更多测试');
    await revealHome(loadMoreEntry);
    await tester.tap(loadMoreEntry);
    await tester.pumpAndSettle();

    expect(find.text('过度滚动与加载更多'), findsNWidgets(2));
    expect(find.text('项目：30 · 已加载页数：0'), findsOneWidget);
    final loadList = find.byKey(
      const PageStorageKey('miuix-reference-overscroll-load-more'),
    );
    final loadPosition = tester
        .state<ScrollableState>(
          find.descendant(of: loadList, matching: find.byType(Scrollable)),
        )
        .position;
    loadPosition.jumpTo(loadPosition.maxScrollExtent);
    await tester.pump();
    expect(find.text('正在加载更多…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    loadPosition.jumpTo(loadPosition.minScrollExtent);
    await tester.pump();
    expect(find.text('项目：50 · 已加载页数：1'), findsOneWidget);

    // Updating LazyListLayoutInfo invalidates Compose's snapshotFlow, so one
    // subsequent user drag must be sufficient to load the next page as well.
    // Place the viewport near the end without arming another session, then use
    // an actual pointer drag to reproduce the source's "fling again" step.
    loadPosition.jumpTo(loadPosition.maxScrollExtent - 400);
    await tester.pump();
    await tester.drag(loadList, const Offset(0, -500));
    await tester.pump();
    expect(find.text('正在加载更多…'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    loadPosition.jumpTo(loadPosition.minScrollExtent);
    await tester.pump();
    expect(find.text('项目：70 · 已加载页数：2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('项目：70 · 已加载页数：2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pull-to-refresh page keeps the current source controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '下拉刷新测试');

    expect(find.text('弹出菜单'), findsWidgets);
    expect(find.text('下拉进度：0%'), findsOneWidget);
    expect(find.text('刷新阈值：25%'), findsOneWidget);
    expect(find.text('叠加层下拉偏好 1'), findsOneWidget);
    expect(find.text('窗口下拉偏好 6'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pull-refresh-progress-card')));
    await tester.pumpAndSettle();
    expect(find.text('下拉刷新设置'), findsOneWidget);
    expect(find.text('刷新阈值'), findsOneWidget);
    expect(find.text('下拉拖动范围的 25% 即可刷新。'), findsOneWidget);

    final slider = tester.widget<MiuixSlider>(
      find.descendant(
        of: find.byKey(const ValueKey('pull-refresh-threshold-slider')),
        matching: find.byType(MiuixSlider),
      ),
    );
    expect(slider.divisions, 100);
    expect(slider.showKeyPoints, isTrue);
    expect(slider.keyPoints, const [0, .25, .5, .75, 1]);
    // Upstream renders a trailing value only when valueText is supplied.
    expect(find.text('0.25'), findsNothing);
    slider.onChanged!(.5);
    await tester.pump();
    expect(find.text('下拉拖动范围的 50% 即可刷新。'), findsOneWidget);

    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text('刷新阈值：50%'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('pull-refresh-toolbar-action')));
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 900));
    final list = tester.widget<ListView>(
      find.byKey(const ValueKey('pull-refresh-list')),
    );
    expect(
      (list.childrenDelegate as SliverChildBuilderDelegate).childCount,
      13,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('overscroll load-more keeps source 420dpi geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '过度滚动与加载更多测试');

    Rect physicalRect(Finder finder) {
      final rect = tester.getRect(finder);
      return Rect.fromLTRB(
        (rect.left * density).roundToDouble(),
        (rect.top * density).roundToDouble(),
        (rect.right * density).roundToDouble(),
        (rect.bottom * density).roundToDouble(),
      );
    }

    // OverscrollLoadMorePage.kt uses 12dp/8dp card margins, 16dp card
    // padding and Android line boxes measuring 43px at the source density.
    // The key is on MiuixCard's margin box; the painted source surface inside
    // it is x=32..1048 and y=363..640.
    expect(
      physicalRect(find.byKey(const ValueKey('overscroll-load-more-hint'))),
      const Rect.fromLTRB(0, 342, 1080, 660),
    );
    final status = physicalRect(
      find.byKey(const ValueKey('overscroll-load-more-status')),
    );
    // The translated sentence has a different intrinsic width, but its
    // baseline box keeps the source position and 43px line height.
    expect(status.left, 74);
    expect(status.top, 555);
    expect(status.bottom, 598);

    final first = physicalRect(
      find.byKey(const ValueKey('overscroll-load-more-item-1')),
    );
    final second = physicalRect(
      find.byKey(const ValueKey('overscroll-load-more-item-2')),
    );
    // The framework's fractional right edge rounds to 1049, while Android's
    // raster clip uses the preceding pixel boundary and paints through x=1048.
    expect(first, const Rect.fromLTRB(32, 660, 1049, 783));
    expect(second, const Rect.fromLTRB(32, 783, 1049, 906));

    expect(tester.takeException(), isNull);
  });

  testWidgets('overscroll load-more appends only once per fling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '过度滚动与加载更多测试');
    final list = find.byKey(
      const PageStorageKey('miuix-reference-overscroll-load-more'),
    );
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: list, matching: find.byType(Scrollable)),
        )
        .position;

    // Start close enough that one high-velocity gesture reaches the original
    // end and retains inertia after the first 20 rows are appended.
    position.jumpTo(position.maxScrollExtent - 180);
    await tester.pump();
    await tester.fling(list, const Offset(0, -1800), 5000);
    await tester.pump(const Duration(milliseconds: 2400));
    final builtList = tester.widget<ListView>(list);
    final delegate = builtList.childrenDelegate as SliverChildBuilderDelegate;
    // 50 rows plus the hint and conditional footer slots. The pre-fix state
    // reached 72 here because the same ballistic activity loaded twice.
    expect(delegate.childCount, 52);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spinner section keeps the current ten-row source structure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final card = find.byKey(const ValueKey('reference-spinner-card'));
    await _scrollUntilBuilt(tester, homeScroll, card);
    expect(card, findsOneWidget);

    const rowKeys = [
      ValueKey('reference-spinner-popup-overlay'),
      ValueKey('reference-spinner-popup-window'),
      ValueKey('reference-spinner-dialog-overlay'),
      ValueKey('reference-spinner-dialog-window'),
      ValueKey('reference-spinner-grouped-overlay'),
      ValueKey('reference-spinner-grouped-window'),
      ValueKey('reference-spinner-grouped-dialog-overlay'),
      ValueKey('reference-spinner-grouped-dialog-window'),
      ValueKey('reference-spinner-disabled-overlay'),
      ValueKey('reference-spinner-disabled-window'),
    ];
    final rowTops = [
      for (final key in rowKeys) tester.getTopLeft(find.byKey(key)).dy,
    ];
    expect(rowTops, orderedEquals(rowTops.toList()..sort()));
    expect(rowTops.toSet(), hasLength(10));

    expect(
      find.descendant(
        of: card,
        matching: find.byType(MiuixOverlaySpinnerPreference<int>),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byType(MiuixWindowSpinnerPreference<int>),
      ),
      findsNWidgets(3),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byType(MiuixOverlayGroupedSpinnerPreference<(int, int)>),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byType(MiuixWindowGroupedSpinnerPreference<(int, int)>),
      ),
      findsNWidgets(2),
    );

    final grouped = tester
        .widget<MiuixOverlayGroupedSpinnerPreference<(int, int)>>(
          find.byKey(const ValueKey('reference-spinner-grouped-overlay')),
        );
    expect(grouped.sourceMode, isTrue);
    expect(
      grouped.groups.map((group) => group.entries.length),
      orderedEquals(const [2, 2, 4]),
    );
    expect(
      grouped.groups
          .expand((group) => group.entries)
          .where((item) => item.selected),
      hasLength(3),
    );
    expect(
      grouped.groups.last.entries.map((item) => item.enabled),
      orderedEquals(const [true, false, true, false]),
    );
    expect(grouped.closeOnSelection, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('spinner section keeps current source row heights at 420dpi', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final card = find.byKey(const ValueKey('reference-spinner-card'));
    await _scrollUntilBuilt(tester, homeScroll, card);
    expect(card, findsOneWidget);

    const rowKeys = [
      ValueKey('reference-spinner-popup-overlay'),
      ValueKey('reference-spinner-popup-window'),
      ValueKey('reference-spinner-dialog-overlay'),
      ValueKey('reference-spinner-dialog-window'),
      ValueKey('reference-spinner-grouped-overlay'),
      ValueKey('reference-spinner-grouped-window'),
      ValueKey('reference-spinner-grouped-dialog-overlay'),
      ValueKey('reference-spinner-grouped-dialog-window'),
      ValueKey('reference-spinner-disabled-overlay'),
      ValueKey('reference-spinner-disabled-window'),
    ];
    final physicalHeights = [
      for (final key in rowKeys)
        (tester.getSize(find.byKey(key)).height * density).round(),
    ];
    // Current SpinnerSection.kt: four ordinary rows, four three-line grouped
    // value rows, then two disabled rows that retain their Collapsed summary.
    expect(
      physicalHeights,
      orderedEquals(const [179, 179, 179, 179, 213, 213, 213, 213, 179, 179]),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('spinner popup keeps source four-row Android geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-spinner-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    final trigger = find.text('选择器偏好（O）').first;
    await Scrollable.ensureVisible(
      tester.element(trigger),
      alignment: .5,
      duration: Duration.zero,
    );
    final preference = find.ancestor(
      of: trigger,
      matching: find.byType(MiuixOverlaySpinnerPreference<int>),
    );
    final trailingAnchor = find.descendant(
      of: preference,
      matching: find.byType(CompositedTransformTarget),
    );
    final anchorRect = tester.getRect(trailingAnchor);
    // At this Android-sized viewport the next continuously animated source
    // fixture can enter the tree after scrolling, so settling would wait
    // forever even though the spinner's own layout has completed.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(trigger);
    // The first frame mounts the popup and creates its 180ms controller; the
    // following frame advances that controller to its unscaled final geometry.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final popup = find.byType(MiuixListPopupColumn);
    expect(popup, findsOneWidget);
    final popupRect = tester.getRect(popup);
    // SpinnerSection.kt renders a 200dp list whose four source-measured rows
    // rasterize to 177 / 156 / 156 / 177 pixels at Android's 420dpi density.
    // This is the same 525 x 666 surface found in both native Overlay and
    // Window captures; importantly, it remains content-sized rather than
    // inheriting the full height of either popup host.
    expect((popupRect.width * density).round(), 525);
    expect((popupRect.height * density).round(), 666);
    // ListPopupLayout.kt truncates positionInWindow before adding the
    // separately measured integer end-action width. Android's Flutter surface
    // rasterizes this root overlay one physical pixel left of its framework
    // paint coordinate at 420dpi, so the overlay host carries one compensating
    // pixel: framework x=482..1007 becomes native raster x=481..1006.
    final sourceAnchorRight =
        (anchorRect.left * density).truncate() +
        (anchorRect.width * density).round();
    expect(popupRect.right * density, closeTo(sourceAnchorRight + 1, .001));
    expect(popupRect.right * density, closeTo(1007, .001));
    for (final label in const ['选项一', '选项二', '选项三', '选项四']) {
      expect(
        find.descendant(of: popup, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(
        of: popup,
        matching: find.byKey(const ValueKey('miuix-dropdown-check-selected')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('selection examples keep source state cycles and card metrics', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final searchSurface = find.byKey(
      const ValueKey('miuix-search-bar-container'),
    );
    final searchInput = find.byKey(const ValueKey('miuix-search-bar-input'));
    final searchLeadingSlot = find.byKey(
      const ValueKey('miuix-search-leading-slot'),
    );
    // InputField.kt measures a 44dp outer leading slot, then constrains the
    // search vector with 16dp start and 8dp end padding. At 420dpi that slot
    // rounds to 116 physical pixels and the editable text begins exactly
    // there, matching the native x=32 -> x=148 capture.
    expect((tester.getSize(searchLeadingSlot).width * density).round(), 116);
    expect(
      ((tester.getRect(searchInput).left - tester.getRect(searchSurface).left) *
              density)
          .round(),
      116,
    );
    final basicCard = find.byKey(
      const ValueKey('reference-basic-component-card'),
    );
    final basicRect = tester.getRect(basicCard);
    expect((basicRect.width * density).round(), 1016);
    // Two independently rounded 68dp rows are 179px each. The Card then adds
    // its separately rounded 12dp bottom margin, producing 358 + 32 = 390px.
    expect((basicRect.height * density).round(), 390);
    final checkboxCard = find.byKey(const ValueKey('reference-checkbox-card'));
    final checkboxRect = tester.getRect(checkboxCard);
    expect(checkboxRect.width * density, closeTo(1016, .01));
    // The widget box includes Section.kt's separately rounded 12dp bottom
    // modifier. Its rasterized 667px outer height minus that 32px margin leaves
    // the exact 635px painted card captured from both Android implementations.
    expect((checkboxRect.height * density).round(), 667);
    expect((checkboxRect.height * density).round() - 32, 635);

    MiuixCheckbox checkbox(String key) =>
        tester.widget<MiuixCheckbox>(find.byKey(ValueKey(key)));
    expect(checkbox('reference-checkbox-off').value, isFalse);
    expect(checkbox('reference-checkbox-on').value, isTrue);
    expect(checkbox('reference-checkbox-mixed').indeterminate, isTrue);

    await tester.tap(find.byKey(const ValueKey('reference-checkbox-off')));
    await tester.tap(find.byKey(const ValueKey('reference-checkbox-on')));
    await tester.pump(const Duration(milliseconds: 300));
    expect(checkbox('reference-checkbox-off').value, isTrue);
    expect(checkbox('reference-checkbox-on').value, isFalse);

    // CheckboxSection.kt starts at Indeterminate and cycles through On, Off,
    // then back to Indeterminate. A binary checkbox cycle would skip the third
    // state and silently diverge from the source example.
    final mixed = find.byKey(const ValueKey('reference-checkbox-mixed'));
    await tester.tap(mixed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(checkbox('reference-checkbox-mixed').value, isTrue);
    expect(checkbox('reference-checkbox-mixed').indeterminate, isFalse);
    await tester.tap(mixed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(checkbox('reference-checkbox-mixed').value, isFalse);
    expect(checkbox('reference-checkbox-mixed').indeterminate, isFalse);
    await tester.tap(mixed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(checkbox('reference-checkbox-mixed').value, isFalse);
    expect(checkbox('reference-checkbox-mixed').indeterminate, isTrue);

    final endPreference = find.byKey(
      const ValueKey('reference-checkbox-end-preference'),
    );
    final startPreference = find.byKey(
      const ValueKey('reference-checkbox-start-preference'),
    );
    final disabledPreference = find.byKey(
      const ValueKey('reference-checkbox-disabled-preference'),
    );
    final endCheckboxTarget = find.descendant(
      of: endPreference,
      matching: find.byKey(const ValueKey('miuix-checkbox-semantics')),
    );
    final startCheckboxTarget = find.descendant(
      of: startPreference,
      matching: find.byKey(const ValueKey('miuix-checkbox-semantics')),
    );
    final disabledCheckboxTarget = find.descendant(
      of: disabledPreference,
      matching: find.byKey(const ValueKey('miuix-checkbox-semantics')),
    );
    expect(
      ((tester.getRect(endCheckboxTarget).top -
                  tester.getRect(endPreference).top) *
              density)
          .round(),
      13,
    );
    expect(
      ((tester.getRect(startCheckboxTarget).top -
                  tester.getRect(startPreference).top) *
              density)
          .round(),
      26,
    );
    expect((tester.getRect(endCheckboxTarget).top * density).round(), 1907);
    expect((tester.getRect(startCheckboxTarget).top * density).round(), 2072);
    // The source preference still supplies its callback while enabled=false.
    // Compose therefore preserves the 48dp toggle target but suppresses taps.
    expect(
      ((tester.getRect(disabledCheckboxTarget).top -
                  tester.getRect(disabledPreference).top) *
              density)
          .round(),
      13,
    );
    expect(
      (tester.getRect(disabledCheckboxTarget).top * density).round(),
      2238,
    );
    expect(
      tester.getRect(disabledCheckboxTarget).height * density,
      closeTo(126, .001),
    );
    await tester.tap(endPreference);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.widget<MiuixCheckboxPreference>(endPreference).value, isTrue);
    expect(
      find.descendant(of: endPreference, matching: find.text('是')),
      findsOneWidget,
    );
    await tester.tap(startPreference);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<MiuixCheckboxPreference>(startPreference).value,
      isTrue,
    );
    expect(
      find.descendant(of: startPreference, matching: find.text('状态：是')),
      findsOneWidget,
    );
    await Scrollable.ensureVisible(
      tester.element(disabledPreference),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(disabledCheckboxTarget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      tester.widget<MiuixCheckboxPreference>(disabledPreference).value,
      isTrue,
    );

    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final firstRadioCard = find.byKey(const ValueKey('reference-radio-card-0'));
    await tester.scrollUntilVisible(
      firstRadioCard,
      420,
      scrollable: homeScroll,
    );
    for (var index = 0; index < 3; index++) {
      final card = find.byKey(ValueKey('reference-radio-card-$index'));
      final option = find.byKey(ValueKey('reference-radio-option-$index'));
      // Each source option is an independent 179px preference surface followed
      // by a separately rounded 12dp/32px Card margin: 211px per card.
      expect(tester.getSize(card).height * density, closeTo(211, .001));
      expect(tester.getSize(option).height * density, closeTo(179, .001));
    }
    final disabledRadioCard = find.byKey(
      const ValueKey('reference-radio-disabled-card'),
    );
    expect(
      tester.getSize(disabledRadioCard).height * density,
      closeTo(211, .001),
    );
    expect(
      find.descendant(of: disabledRadioCard, matching: find.text('此选项不可用')),
      findsOneWidget,
    );
    final optionB = find.byKey(const ValueKey('reference-radio-option-1'));
    final optionBRadioTarget = find.descendant(
      of: optionB,
      matching: find.byKey(const ValueKey('miuix-radio-semantics')),
    );
    expect(
      ((tester.getRect(optionBRadioTarget).top - tester.getRect(optionB).top) *
              density)
          .round(),
      26,
    );
    final disabledRadioPreference = find.byKey(
      const ValueKey('reference-radio-disabled-preference'),
    );
    final disabledRadioTarget = find.descendant(
      of: disabledRadioPreference,
      matching: find.byKey(const ValueKey('miuix-radio-semantics')),
    );
    expect(
      ((tester.getRect(disabledRadioTarget).top -
                  tester.getRect(disabledRadioPreference).top) *
              density)
          .round(),
      26,
    );
    expect(
      tester.getRect(disabledRadioTarget).height * density,
      closeTo(126, .001),
    );
    await Scrollable.ensureVisible(
      tester.element(optionB),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(optionB);
    await tester.pump(const Duration(milliseconds: 300));
    for (var index = 0; index < 3; index++) {
      final option = find.byKey(ValueKey('reference-radio-option-$index'));
      expect(
        tester.widget<MiuixRadioButtonPreference<bool>>(option).groupValue,
        index == 1,
      );
    }
    expect(
      find.descendant(of: optionB, matching: find.text('已选择：是')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('switch examples preserve source 420dpi target geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final switchCard = find.byKey(const ValueKey('reference-switch-card'));
    await tester.scrollUntilVisible(switchCard, 420, scrollable: homeScroll);

    Finder switchTarget(Finder owner) => find.descendant(
      of: owner,
      matching: find.byKey(const ValueKey('miuix-switch-semantics')),
    );
    for (final key in const [
      'reference-switch-off',
      'reference-switch-on',
      'reference-switch-disabled-off',
      'reference-switch-disabled-on',
    ]) {
      final control = find.byKey(ValueKey(key));
      final target = switchTarget(control);
      expect(tester.getSize(control).width * density, closeTo(129, .001));
      expect(tester.getSize(control).height * density, closeTo(74, .001));
      expect(tester.getRect(target).width * density, closeTo(129, .001));
      expect(tester.getRect(target).height * density, closeTo(126, .001));
    }

    final mainPreference = find.byKey(
      const ValueKey('reference-switch-main-preference'),
    );
    final disabledPreference = find.byKey(
      const ValueKey('reference-switch-disabled-preference'),
    );
    final mainTarget = switchTarget(mainPreference);
    final disabledTarget = switchTarget(disabledPreference);
    expect(
      ((tester.getRect(mainTarget).top - tester.getRect(mainPreference).top) *
              density)
          .round(),
      26,
    );
    expect(
      ((tester.getRect(disabledTarget).top -
                  tester.getRect(disabledPreference).top) *
              density)
          .round(),
      // The 28dp track makes the title-only SwitchPreference 60dp tall,
      // unlike the 58dp title-only checkbox/radio rows.
      16,
    );
    expect(tester.getRect(mainTarget).height * density, closeTo(126, .001));
    expect(tester.getRect(disabledTarget).height * density, closeTo(126, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('button rows preserve HyperOS 4 geometry and state', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-button-section'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(section),
      alignment: .5,
      duration: Duration.zero,
    );
    // The source page contains continuously animated examples farther down the
    // lazy list, so use a bounded frame advance instead of waiting for global
    // animation quiescence after the scroll position changes.
    await tester.pump(const Duration(milliseconds: 600));

    final buttonFinder = find.descendant(
      of: section,
      matching: find.byType(MiuixTextButton),
    );
    final buttons = tester
        .widgetList<MiuixTextButton>(buttonFinder)
        .toList(growable: false);
    expect(buttons, hasLength(4));
    final rects = List.generate(
      buttons.length,
      (index) => tester.getRect(buttonFinder.at(index)),
    );
    expect(buttons.map((button) => button.enabled), [
      isTrue,
      isTrue,
      isFalse,
      isFalse,
    ]);
    // ButtonSection.kt supplies a non-null callback to disabled TextButtons
    // and disables them only through the source `enabled` parameter.
    expect(buttons.every((button) => button.onPressed != null), isTrue);
    expect(buttons.map((button) => button.colors != null), [
      isFalse,
      isTrue,
      isFalse,
      isTrue,
    ]);

    // The Android reference resolves each 12dp edge independently: 32px
    // outside, 32px between equal 492px columns, and 32px between rows.
    // HyperOS 4 keeps the source column allocation while using the calibrated
    // 48dp action height for a 126px physical target at this density.
    for (final rect in rects) {
      expect(rect.width * density, closeTo(492, .01));
      expect(rect.height * density, closeTo(126, .01));
    }
    expect(rects.first.left * density, closeTo(32, .01));
    expect((rects[1].left - rects[0].right) * density, closeTo(32, .01));
    expect((rects[2].top - rects[0].bottom) * density, closeTo(32, .01));

    await tester.tap(find.widgetWithText(MiuixTextButton, '取消'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(MiuixTextButton, '点击：1'), findsOneWidget);
    expect(find.widgetWithText(MiuixTextButton, '提交'), findsOneWidget);
    await tester.tap(find.widgetWithText(MiuixTextButton, '提交'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.widgetWithText(MiuixTextButton, '点击：1'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom-sheet demos keep source chrome and control order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-bottom-sheet-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('叠加底部弹层')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('叠加底部弹层'));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
    expect(surface, findsOneWidget);
    expect(tester.widget<MiuixGlass>(surface).enabled, isTrue);
    expect(
      find.descendant(of: surface, matching: find.text('叠加底部弹层')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('overlay-sheet-close')), findsOneWidget);
    expect(find.byKey(const ValueKey('overlay-sheet-confirm')), findsOneWidget);
    expect(
      find.descendant(of: surface, matching: find.text('行为设置')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: surface, matching: find.byType(MiuixSlider)),
      findsNothing,
    );
    expect(
      find.descendant(of: surface, matching: find.byType(MiuixScrollEndHaptic)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: surface, matching: find.text('文本框')),
      findsOneWidget,
    );
    final localizedField = find.descendant(
      of: surface,
      matching: find.byType(MiuixTextField),
    );
    // The Chinese label must retain TextField.kt's 52dp one-line geometry;
    // otherwise the content-sized sheet grows beyond the original sample.
    expect(tester.getSize(localizedField).height, 52);
    final sheetCards = tester
        .widgetList<MiuixCard>(
          find.descendant(of: surface, matching: find.byType(MiuixCard)),
        )
        .toList(growable: false);
    expect(sheetCards, hasLength(2));
    expect(
      sheetCards.every(
        (card) =>
            card.color ==
            Theme.of(tester.element(surface)).colorScheme.secondaryContainer,
      ),
      isTrue,
    );
    final surfaceRect = tester.getRect(surface);
    final finalCardRect = tester.getRect(
      find.descendant(of: surface, matching: find.byType(MiuixCard)).last,
    );
    final navigationRect = tester.getRect(
      find.byType(MiuixIosLiquidGlassNavigationBar),
    );
    expect(surfaceRect.bottom, closeTo(844, .1));
    expect(surfaceRect.top, lessThan(navigationRect.top));
    // BottomSheetSection.kt applies 12dp below its final card before adding
    // the platform navigation inset. The test window has no platform inset.
    expect(surfaceRect.bottom - finalCardRect.bottom, closeTo(12, .1));
    await tester.tap(find.text('允许关闭'));
    await tester.pump();
    await tester.tapAt(const Offset(6, 6));
    await tester.pump(const Duration(milliseconds: 260));
    expect(surface, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overlay-sheet-close')));
    await tester.pumpAndSettle();
    expect(surface, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom sheet preserves the 420dpi source pixel geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-bottom-sheet-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('叠加底部弹层')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('叠加底部弹层'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-bottom-sheet-surface'));
    final cards = find.descendant(
      of: surface,
      matching: find.byType(MiuixCard),
    );
    final surfaceRect = tester.getRect(surface);
    final behaviorCardRect = tester.getRect(cards.first);
    final finalCardRect = tester.getRect(cards.last);

    // These are the physical boundaries captured from the Android 1.0.9
    // reference on the same 1080x2400, 420dpi emulator.
    expect(surfaceRect.top * density, closeTo(1121.5, .01));
    expect(surfaceRect.bottom * density, closeTo(2400, .01));
    expect(behaviorCardRect.top * density, closeTo(1437.75, .01));
    expect(behaviorCardRect.bottom * density, closeTo(1789.5, .01));
    expect(finalCardRect.top * density, closeTo(1989.5, .01));
    expect(finalCardRect.bottom * density, closeTo(2305, .01));
    expect(
      (surfaceRect.bottom - finalCardRect.bottom) * density,
      closeTo(95, .01),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('bottom-sheet state follows source ownership across reopen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '叠加底部弹层');

    List<bool> sheetSwitchValues() => tester
        .widgetList<MiuixSwitch>(
          find.descendant(
            of: find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
            matching: find.byType(MiuixSwitch),
          ),
        )
        .map((widget) => widget.value)
        .toList(growable: false);

    expect(sheetSwitchValues(), const [true, true, true]);
    await tester.tap(find.text('允许关闭'));
    await tester.tap(find.text('开关偏好'));
    await tester.pump();
    expect(sheetSwitchValues(), const [false, true, false]);
    await tester.tap(find.byKey(const ValueKey('overlay-sheet-close')));
    await tester.pumpAndSettle();

    // SuperBottomSheetDemo owns these two behavior flags outside the popup,
    // so reopening the same variant retains them. SwitchPref belongs to the
    // section and is shared by the Overlay and Window demos.
    await tester.tap(find.text('叠加底部弹层'));
    await tester.pumpAndSettle();
    expect(sheetSwitchValues(), const [false, true, false]);
    await tester.tap(find.byKey(const ValueKey('overlay-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('窗口底部弹层'));
    await tester.pumpAndSettle();
    expect(sheetSwitchValues(), const [true, true, false]);
    await tester.tap(find.text('启用嵌套滚动'));
    await tester.pump();
    expect(sheetSwitchValues(), const [true, false, false]);
    await tester.tap(find.byKey(const ValueKey('window-sheet-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('窗口底部弹层'));
    await tester.pumpAndSettle();
    expect(sheetSwitchValues(), const [true, false, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('about background sheet preserves the current source controls', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '关于', scrollDelta: 300);
    await tester.tap(find.text('关于'));
    // About intentionally keeps its effect background ticker alive. Advance
    // the route transition explicitly instead of waiting for global settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('about-identity')));
    await tester.pump();
    // Sample the stable source spring instead of its slight 400ms
    // overshoot, which places the whole sheet three physical pixels high.
    await tester.pump(const Duration(milliseconds: 720));

    final surface = tester.getRect(
      find.byKey(const ValueKey('miuix-bottom-sheet-surface')),
    );
    final switches = find.descendant(
      of: find.byKey(const ValueKey('about-background-controls')),
      matching: find.byType(MiuixSwitch),
    );
    final switchRects = List<Rect>.generate(
      2,
      (index) => tester.getRect(switches.at(index)),
    );

    // These are the current AboutPage.kt boundaries captured from the same
    // 1080x2400 / 420dpi Release runtime. Compose rounds the header, the
    // 56dp dropdown row, both translated switch rows, and the 24dp gesture
    // inset independently.
    expect(
      <int>[
        (surface.top * density).round(),
        (surface.bottom * density).round(),
        ...switchRects.expand(
          (rect) => <int>[
            (rect.left * density).round(),
            (rect.top * density).round(),
            (rect.right * density).round(),
            (rect.bottom * density).round(),
          ],
        ),
      ],
      const [1707, 2400, 909, 2063, 1038, 2137, 909, 2221, 1038, 2295],
    );
    expect(find.byType(MiuixSlider), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog section keeps all five localized source demos', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-dialog-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);

    // DialogSection.kt exposes these five rows in this exact order. The labels
    // are localized, while the O/W host distinction remains visible.
    final rows = tester
        .widgetList<MiuixArrowPreference>(
          find.descendant(
            of: section,
            matching: find.byType(MiuixArrowPreference),
          ),
        )
        .toList(growable: false);
    expect(rows, hasLength(5));
    expect(rows.map((row) => row.title).toList(), const [
      '对话框（O）',
      '对话框（W）',
      '宽对话框（O）',
      '宽对话框（W）',
      '居中对话框（O）',
    ]);
    await tester.tap(find.text('对话框（O）'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final actions = tester
        .widgetList<MiuixTextButton>(
          find.descendant(of: surface, matching: find.byType(MiuixTextButton)),
        )
        .toList(growable: false);
    expect(actions, hasLength(2));
    expect(actions.map((button) => button.label), const ['取消', '确认']);
    expect(actions.first.colors, isNull);
    expect(actions.last.colors, isNotNull);
    expect(tester.getRect(surface).bottom, lessThanOrEqualTo(844));
    expect(tester.takeException(), isNull);
  });

  testWidgets('current Home keeps all six localized dropdown source rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(homeScroll).position;
    final section = find.byKey(const ValueKey('reference-dropdown-card'));
    for (
      var attempt = 0;
      attempt < 40 && section.evaluate().isEmpty;
      attempt++
    ) {
      position.jumpTo(
        (position.pixels + 520).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 24));
    }
    expect(section, findsOneWidget);

    const rowKeys = [
      'reference-dropdown-overlay',
      'reference-dropdown-window',
      'reference-dropdown-grouped-overlay',
      'reference-dropdown-grouped-window',
      'reference-dropdown-disabled-overlay',
      'reference-dropdown-disabled-window',
    ];
    final rows = [for (final key in rowKeys) find.byKey(ValueKey<String>(key))];
    for (final row in rows) {
      expect(row, findsOneWidget);
    }
    final groupedOverlay = tester
        .widget<MiuixOverlayGroupedDropdownPreference<String>>(rows[2]);
    final groupedWindow = tester
        .widget<MiuixWindowGroupedDropdownPreference<String>>(rows[3]);
    for (final grouped in [groupedOverlay, groupedWindow]) {
      expect(grouped.sourceMode, isTrue);
      expect(grouped.closeOnSelection, isFalse);
      expect(
        grouped.groups.map((group) => group.entries.length),
        orderedEquals(const [2, 3, 4]),
      );
      expect(
        grouped.groups.last.entries.map((entry) => entry.enabled),
        orderedEquals(const [true, false, true, false]),
      );
    }
    expect(
      rows.map((row) => tester.getTopLeft(row).dy).toList(),
      orderedEquals(
        rows.map((row) => tester.getTopLeft(row).dy).toList()..sort(),
      ),
    );
    expect(find.text('下拉偏好（O）'), findsOneWidget);
    expect(find.text('下拉偏好（W）'), findsOneWidget);
    expect(find.text('分组下拉偏好（O）'), findsOneWidget);
    expect(find.text('分组下拉偏好（W）'), findsOneWidget);
    expect(find.text('禁用下拉偏好（O）'), findsOneWidget);
    expect(find.text('禁用下拉偏好（W）'), findsOneWidget);
    expect(find.text('选项 A-1\n选项 B-1\n选项 C-1'), findsNWidgets(2));

    await Scrollable.ensureVisible(
      tester.element(rows[0]),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('下拉偏好（O）'));
    await tester.pumpAndSettle();
    expect(find.text('已展开'), findsOneWidget);
    expect(find.byType(MiuixListPopupColumn), findsOneWidget);
    await tester.tap(find.text('选项三').last);
    await tester.pumpAndSettle();
    expect(find.text('已收起'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dropdown rows preserve current source 420dpi heights', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(homeScroll).position;
    final section = find.byKey(const ValueKey('reference-dropdown-card'));
    for (
      var attempt = 0;
      attempt < 40 && section.evaluate().isEmpty;
      attempt++
    ) {
      position.jumpTo(
        (position.pixels + 520).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 24));
    }
    expect(section, findsOneWidget);

    const keys = [
      'reference-dropdown-overlay',
      'reference-dropdown-window',
      'reference-dropdown-grouped-overlay',
      'reference-dropdown-grouped-window',
      'reference-dropdown-disabled-overlay',
      'reference-dropdown-disabled-window',
    ];
    final heights = [
      for (final key in keys)
        (tester.getRect(find.byKey(ValueKey<String>(key))).height * density)
            .round(),
    ];
    // BasicComponent produces 179px title+summary rows, the three-line selected
    // group values raise only their two rows to 213px, and disabled title-only
    // rows retain the source 147px placeable.
    expect(heights, const [179, 179, 213, 213, 147, 147]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grouped dropdown preserves current source 420dpi popup rhythm', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(homeScroll).position;
    final row = find.byKey(
      const ValueKey('reference-dropdown-grouped-overlay'),
    );
    for (var attempt = 0; attempt < 40 && row.evaluate().isEmpty; attempt++) {
      position.jumpTo(
        (position.pixels + 520).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 24));
    }
    expect(row, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(row),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('分组下拉偏好（O）'));
    await tester.pumpAndSettle();

    final popup = find.byType(MiuixListPopupColumn);
    final rows = find.byType(MiuixDropdownImpl);
    expect(popup, findsOneWidget);
    expect(rows, findsNWidgets(9));
    expect(
      find.descendant(of: popup, matching: find.byType(MiuixHorizontalDivider)),
      findsNWidgets(2),
    );
    expect(tester.getSize(popup).width * density, closeTo(525, .001));
    // First-eight layout children are A1, A2, divider, B1, B2, B3,
    // divider, and C1. Native current-source placement is therefore
    // 138 + 117 + 26 + 117 + 117 + 117 + 26 + 117 = 775px.
    expect(tester.getSize(popup).height * density, closeTo(775, .001));
    final rowRects = [
      for (var index = 0; index < 9; index++) tester.getRect(rows.at(index)),
    ];
    const expectedHeights = [138, 117, 117, 117, 117, 117, 117, 117, 138];
    for (var index = 0; index < rowRects.length; index++) {
      expect(
        rowRects[index].height * density,
        closeTo(expectedHeights[index], .001),
      );
    }
    expect((rowRects[2].top - rowRects[1].bottom) * density, closeTo(26, .001));
    expect((rowRects[5].top - rowRects[4].bottom) * density, closeTo(26, .001));
    expect(
      tester
          .widgetList<MiuixDropdownImpl>(rows)
          .where((entry) => !entry.enabled),
      hasLength(2),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long window dropdown uses the source first-eight viewport', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(homeScroll).position;
    final row = find.byKey(const ValueKey('reference-dropdown-window'));
    for (var attempt = 0; attempt < 40 && row.evaluate().isEmpty; attempt++) {
      position.jumpTo(
        (position.pixels + 520).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 24));
    }
    expect(row, findsOneWidget);
    await Scrollable.ensureVisible(
      tester.element(row),
      alignment: .35,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('下拉偏好（W）'));
    await tester.pumpAndSettle();

    final popup = find.byType(MiuixListPopupColumn);
    expect(popup, findsOneWidget);
    final popupRect = tester.getRect(popup);
    // Current Dropdown.kt caps the inner row at 216dp. Together with the
    // 20+20dp outer padding and 12+20dp check slot, the native popup is 288dp
    // (756px) wide. Its first four rows are one line and rows five through
    // eight are two lines, producing the exact 1137px first-eight viewport.
    expect(popupRect.width * density, closeTo(756, .01));
    expect(popupRect.height * density, closeTo(1137, .01));
    expect(popupRect.right * density, closeTo(1006, .01));
    final popupScroll = find.descendant(
      of: popup,
      matching: find.byType(Scrollable),
    );
    final popupPosition = tester.state<ScrollableState>(popupScroll).position;
    expect(popupPosition.maxScrollExtent, greaterThan(0));
    await tester.drag(popupScroll, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(popupPosition.pixels, greaterThan(0));
    final eighth = find.descendant(
      of: popup,
      matching: find.text('非常长非常长非常长非常长非常长非常长非常长选项八'),
    );
    expect(tester.getSize(eighth).height * density, closeTo(99, .01));
    final first = find.descendant(of: popup, matching: find.text('选项一'));
    // The Text glyph box is 49.875px; its Align sits in the native 54px
    // one-line placeable used by the row-height calculation above.
    expect(tester.getSize(first).height * density, closeTo(49.875, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('window dialog preserves the 420dpi source panel geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-dialog-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('对话框（W）').first),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('对话框（W）').first);
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final surfaceRect = tester.getRect(surface);

    // The localized summary deliberately retains the upstream two-line body
    // placeable. Losing that second line moves the compact panel down by 49px
    // even though its outer margins and navigation inset still look valid.
    expect(surfaceRect.left * density, closeTo(32, 2));
    expect(surfaceRect.right * density, closeTo(1048, 2));
    expect(surfaceRect.top * density, closeTo(1835, .01));
    expect(surfaceRect.bottom * density, closeTo(2305, 2));
    expect(find.text('窗口级对话框，无需 MiuixPopupHost\n即可显示。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('centered dialog forces the source large-screen presentation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 24, bottom: 24);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-dialog-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('居中对话框（O）')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('居中对话框（O）'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final surfaceRect = tester.getRect(surface);
    expect(
      find.byKey(const ValueKey('miuix-host-dialog-large-fade')),
      findsOne,
    );
    expect(find.byKey(const ValueKey('miuix-host-dialog-slide')), findsNothing);
    // The hosted OverlayDialog converts Flutter's unconsumed top padding to the
    // source host center correction, while retaining navigation + outer bottom.
    expect(surfaceRect.center.dy, closeTo(410, .01));
    expect(surfaceRect.width, lessThanOrEqualTo(MiuixDialogDefaults.maxWidth));
    expect(find.text('居中对话框'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide dialog uses the source portrait action stack', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-dialog-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('宽对话框（O）')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('宽对话框（O）'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final actions = tester
        .widgetList<MiuixTextButton>(
          find.descendant(of: surface, matching: find.byType(MiuixTextButton)),
        )
        .toList(growable: false);
    expect(actions.map((button) => button.label), const [
      '仅允许一次',
      '始终允许',
      '拒绝',
    ]);
    expect(actions.first.colors, isNotNull);
    expect(actions.skip(1).every((button) => button.colors == null), isTrue);
    expect(find.text('宽对话框'), findsOneWidget);
    expect(find.text('旋转为横屏查看效果。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide dialog recomposes into the source landscape two columns', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final section = find.byKey(const ValueKey('reference-dialog-card'));
    await tester.scrollUntilVisible(section, 420, scrollable: homeScroll);
    await Scrollable.ensureVisible(
      tester.element(find.text('宽对话框（O）')),
      alignment: .5,
      duration: Duration.zero,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('宽对话框（O）'));
    await tester.pumpAndSettle();

    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    expect(
      find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey('miuix-dialog-title-placeable')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: surface, matching: find.byType(MiuixVerticalDivider)),
      findsNothing,
    );

    // LocalWindowInfo invalidates the Compose call site while the dialog is
    // open. The Flutter builder adapter must likewise rebuild, not require a
    // dismiss-and-reopen cycle after rotation.
    // Stay below the sample shell's separate 600dp landscape split breakpoint
    // so this assertion isolates DialogSection's LocalWindowInfo recomposition.
    tester.view.physicalSize = const Size(590, 390);
    await tester.pumpAndSettle();
    final surfaceRect = tester.getRect(surface);
    expect(surfaceRect.width, closeTo(560, .01));
    expect(
      find.descendant(
        of: surface,
        matching: find.byKey(const ValueKey('miuix-dialog-title-placeable')),
      ),
      findsNothing,
    );
    expect(
      find.descendant(of: surface, matching: find.byType(MiuixVerticalDivider)),
      findsOneWidget,
    );
    expect(find.text('宽对话框'), findsOneWidget);
    expect(find.text('旋转为横屏查看效果。'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow action dialog uses source summary and compact panel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final action = find.text('音量');
    await tester.scrollUntilVisible(action, 360, scrollable: homeScroll);

    // Put the source slider on a non-integer percentage so the dialog must
    // prove Kotlin Float.toInt truncation instead of accidental rounding.
    final actionRow = find
        .ancestor(of: action, matching: find.byType(MiuixPreference))
        .first;
    final sliderFinder = find.descendant(
      of: actionRow,
      matching: find.byType(MiuixSlider),
    );
    tester.widget<MiuixSlider>(sliderFinder).onChanged?.call(.739);
    await tester.pump();
    // The state rebuild keeps the row at the viewport's top edge, which is
    // intentionally behind the collapsing app bar. Move it back into the
    // normal hit-test region before exercising the real tap path.
    await tester.drag(homeScroll, const Offset(0, 120));
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();

    final dialog = tester.widget<MiuixDialog>(find.byType(MiuixDialog));
    final surface = find.byKey(const ValueKey('miuix-dialog-surface'));
    final summary = tester.widget<Text>(find.text('输入 0-100'));
    final actions = tester
        .widgetList<MiuixButton>(
          find.descendant(of: surface, matching: find.byType(MiuixButton)),
        )
        .toList(growable: false);
    expect(dialog.summary, '输入 0-100');
    expect(summary.style?.fontSize, 16);
    expect(actions, hasLength(2));
    expect(actions.first.filled, isFalse);
    expect(actions.last.filled, isTrue);
    final input = tester.widget<MiuixTextField>(find.byType(MiuixTextField));
    final editable = find.descendant(
      of: surface,
      matching: find.byType(EditableText),
    );
    expect(input.singleLine, isTrue);
    expect(tester.widget<EditableText>(editable).controller.text, '73');

    // Source takes only the first three digits before parsing, so the leading
    // zero sequence below normalizes to 1 rather than 12.
    await tester.enterText(editable, '0012');
    await tester.pump();
    expect(tester.widget<EditableText>(editable).controller.text, '1');

    // Clearing and confirming preserves the current truncated slider value.
    // Reopening proves that the empty field was not reset to a hard-coded 50.
    await tester.enterText(editable, '');
    await tester.tap(find.text('确认'));
    await tester.pumpAndSettle();
    await tester.tap(action);
    await tester.pumpAndSettle();
    final reopenedEditable = find.descendant(
      of: find.byKey(const ValueKey('miuix-dialog-surface')),
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(reopenedEditable).controller.text, '73');
    expect(tester.getRect(surface).height, lessThan(300));
    expect(tester.getRect(surface).bottom, closeTo(832, .1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('arrow section uses the source SliderPreference geometry', (
    tester,
  ) async {
    const density = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = density;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final card = find.byKey(const ValueKey('reference-arrow-card'));
    await tester.scrollUntilVisible(card, 420, scrollable: homeScroll);
    await tester.pumpAndSettle();

    final arrows = find.descendant(
      of: card,
      matching: find.byType(MiuixArrowPreference),
    );
    final slider = find.descendant(
      of: card,
      matching: find.byType(MiuixSliderPreference),
    );
    expect(arrows, findsNWidgets(2));
    expect(slider, findsOneWidget);
    expect(find.text('音量'), findsOneWidget);
    expect(find.text('箭头 + 滑块 + 对话框'), findsNothing);

    // Native 420dpi XML: Arrow=147px, SliderPreference=231px, disabled
    // Arrow=147px. Their independently rounded sum is the 525px card body.
    final firstRect = tester.getRect(arrows.first);
    final sliderRect = tester.getRect(slider);
    final disabledRect = tester.getRect(arrows.last);
    expect(firstRect.height * density, closeTo(147, .01));
    expect(sliderRect.height * density, closeTo(231, .01));
    expect(disabledRect.height * density, closeTo(147, .01));
    expect(
      (firstRect.height + sliderRect.height + disabledRect.height) * density,
      closeTo(525, .01),
    );
    expect(firstRect.left * density, closeTo(32, .01));
    expect(firstRect.right * density, closeTo(1048, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('snackbar feedback stays above the rendered bottom navigation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final homePosition = tester.state<ScrollableState>(homeScrollable).position;
    final indefiniteButton = find.text('无限时');
    // The example mirrors the source's long single page, so materialize the
    // snackbar section through the same lazy vertical list used at runtime.
    for (
      var attempt = 0;
      attempt < 64 && indefiniteButton.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 520).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump();
    }
    expect(indefiniteButton, findsOneWidget);
    final snackbarCard = find.byKey(const ValueKey('reference-snackbar-card'));
    expect(snackbarCard, findsOneWidget);
    expect(
      find.descendant(of: snackbarCard, matching: find.byType(MiuixTextButton)),
      findsNWidgets(9),
    );
    expect(find.text('操作 + 关闭'), findsOneWidget);
    expect(
      find.descendant(of: snackbarCard, matching: find.byType(MiuixButton)),
      findsNothing,
    );
    await Scrollable.ensureVisible(
      tester.element(indefiniteButton),
      alignment: .58,
      duration: Duration.zero,
    );
    await tester.pump();
    await tester.tap(indefiniteButton);
    // The first frame inserts the entry; advance a second frame beyond the
    // source critically damped spring before checking its final placement.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final message = find.text('这条消息会保留到手动关闭。');
    expect(message, findsOneWidget);
    final messageRect = tester.getRect(message);
    final navigationRect = tester.getRect(
      find.byType(MiuixIosLiquidGlassNavigationBar),
    );
    expect(
      find.byKey(const ValueKey('miuix-scaffold-snackbar-layer')),
      findsOneWidget,
    );
    // The transient surface may overlap page content, but never the bottom
    // navigation or Android gesture region owned beneath that navigation.
    expect(messageRect.bottom, lessThanOrEqualTo(navigationRect.top));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'localized action-close snackbar keeps the source two-line height',
    (tester) async {
      const density = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = density;
      tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
      tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);

      await tester.pumpWidget(const MiuixExampleApp());
      await tester.pumpAndSettle();
      final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
      final homeScroll = find
          .descendant(of: homeList, matching: find.byType(Scrollable))
          .first;
      final actionClose = find.text('操作 + 关闭');
      await tester.scrollUntilVisible(actionClose, 520, scrollable: homeScroll);
      await Scrollable.ensureVisible(
        tester.element(actionClose),
        alignment: .52,
        duration: Duration.zero,
      );
      await tester.pump();
      await tester.tap(actionClose);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      const localizedMessage = '这条消息同时带有一个操作按钮和一个关闭按钮。';
      expect(find.text(localizedMessage), findsOneWidget);
      final surface = find.byKey(const ValueKey('miuix-snackbar-surface'));
      expect(surface, findsOneWidget);
      // Native v228 at 1080x2400 / 420dpi naturally wraps the English source
      // message into two body2 lines. Its surface is 150 physical pixels high;
      // the separate 8dp top outer padding makes the complete queue item 171px.
      // A shortened Chinese translation used to fit one line and collapse the
      // surface to 132px, changing both the stack and its exit animation.
      expect(tester.getSize(surface).height * density, closeTo(150, .01));
      expect(tester.getRect(surface).width * density, closeTo(1016, .01));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('slider section matches source marker and layout variants', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final sliderCard = find.byKey(const ValueKey('reference-slider-card'));
    await tester.scrollUntilVisible(sliderCard, 440, scrollable: homeScroll);

    expect(find.text('普通'), findsOneWidget);
    expect(find.text('30%'), findsOneWidget);
    expect(find.text('分段'), findsOneWidget);
    expect(find.text('100/200'), findsOneWidget);
    expect(find.text('带关键点的分段'), findsOneWidget);
    expect(find.text('5/8'), findsOneWidget);
    expect(find.text('自定义关键点'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('禁用'), findsWidgets);
    expect(find.text('70%'), findsOneWidget);
    final sliders = tester
        .widgetList<MiuixSlider>(
          find.descendant(of: sliderCard, matching: find.byType(MiuixSlider)),
        )
        .toList(growable: false);
    expect(
      find.descendant(
        of: sliderCard,
        matching: find.byType(MiuixSliderPreference),
      ),
      findsNWidgets(5),
    );
    expect(sliders, hasLength(5));
    expect(sliders[1].divisions, 200);
    expect(sliders[1].showKeyPoints, isFalse);
    expect(sliders[2].showKeyPoints, isTrue);
    expect(sliders[3].divisions, isNull);
    expect(sliders[3].keyPoints, const [0, 25, 50, 75, 100]);
    expect(sliders[4].enabled, isFalse);
    expect(sliders[4].onChanged, isNotNull);

    final rangeCard = find.byKey(const ValueKey('reference-range-slider-card'));
    await tester.scrollUntilVisible(rangeCard, 360, scrollable: homeScroll);
    final rangeSliders = tester
        .widgetList<MiuixRangeSlider>(
          find.descendant(
            of: rangeCard,
            matching: find.byType(MiuixRangeSlider),
          ),
        )
        .toList(growable: false);
    expect(
      find.descendant(
        of: rangeCard,
        matching: find.byType(MiuixRangeSliderPreference),
      ),
      findsNWidgets(4),
    );
    expect(rangeSliders, hasLength(4));
    expect(rangeSliders[1].showKeyPoints, isTrue);
    expect(rangeSliders[2].keyPoints, const [0, 20, 40, 60, 80, 100]);
    expect(rangeSliders[3].values, const RangeValues(.3, .7));
    expect(rangeSliders[3].enabled, isFalse);
    expect(rangeSliders[3].onChanged, isNotNull);

    final verticalCard = find.byKey(
      const ValueKey('reference-vertical-slider-card'),
    );
    await tester.scrollUntilVisible(verticalCard, 360, scrollable: homeScroll);
    final verticalSliders = tester
        .widgetList<MiuixVerticalSlider>(
          find.descendant(
            of: verticalCard,
            matching: find.byType(MiuixVerticalSlider),
          ),
        )
        .toList(growable: false);
    expect(verticalSliders, hasLength(5));
    expect(verticalSliders.every((slider) => slider.height == 160), isTrue);
    expect(verticalSliders[2].showKeyPoints, isTrue);
    expect(verticalSliders[3].keyPoints, const [0, 25, 50, 75, 100]);
    expect(verticalSliders[4].enabled, isFalse);
    expect(verticalSliders[4].onChanged, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('slider cards preserve source physical heights at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final sliderCard = find.byKey(const ValueKey('reference-slider-card'));
    final rangeCard = find.byKey(const ValueKey('reference-range-slider-card'));
    final verticalCard = find.byKey(
      const ValueKey('reference-vertical-slider-card'),
    );
    await tester.scrollUntilVisible(sliderCard, 520, scrollable: homeScroll);

    // The source preference rows are 189 physical pixels apart at 420 dpi.
    // Four zero-bottom-margin rows plus the final default-bottom-margin row
    // produce a 987px Slider surface; the corresponding four-row RangeSlider
    // surface is 798px. Each card widget additionally owns the independently
    // rounded 12dp (32px) bottom modifier outside that painted surface.
    expect(
      tester.getSize(sliderCard).height * sourceDensity,
      closeTo(1019, .001),
    );
    expect(
      tester.getSize(rangeCard).height * sourceDensity,
      closeTo(830, .001),
    );
    await tester.scrollUntilVisible(verticalCard, 520, scrollable: homeScroll);
    final verticalSlider = find
        .descendant(
          of: verticalCard,
          matching: find.byType(MiuixVerticalSlider),
        )
        .first;
    expect(
      tester.getSize(verticalSlider).width * sourceDensity,
      closeTo(66, .001),
    );
    expect(
      tester.getSize(verticalSlider).height * sourceDensity,
      closeTo(420, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color picker labels use the source RGBA number formatting', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final sectionTitle = find.text('颜色选择器（HSV）');
    await _scrollUntilBuilt(tester, homeScroll, sectionTitle);
    expect(sectionTitle, findsOneWidget);
    await tester.scrollUntilVisible(sectionTitle, 520, scrollable: homeScroll);

    // Kotlin prints the rounded Double rather than a fixed two-decimal field.
    // Consequently opaque alpha is `1.0`, while a two-place value is `0.45`.
    expect(find.text('RGBA：52，130，255，1.0'), findsNWidgets(5));
    final picker = find.byType(MiuixColorPicker).first;
    final hexField = find.byType(MiuixTextField).first;
    final hexWidget = tester.widget<MiuixTextField>(hexField);
    final hexPrefix = find.descendant(
      of: hexField,
      matching: find.text('HEX：#'),
    );
    final hexEditable = find.descendant(
      of: hexField,
      matching: find.byType(EditableText),
    );
    expect(hexWidget.label, isEmpty);
    expect(hexWidget.leadingIcon, isNotNull);
    expect(hexWidget.prefixIcon, isNull);
    expect(hexWidget.singleLine, isTrue);
    expect(
      tester.getRect(hexEditable).left,
      closeTo(tester.getRect(hexPrefix).right, .1),
    );
    final formatter = hexWidget.inputFormatters!.single;
    const oldHex = TextEditingValue(
      text: 'A1',
      selection: TextSelection.collapsed(offset: 2),
    );
    expect(
      formatter
          .formatEditUpdate(oldHex, const TextEditingValue(text: 'b2'))
          .text,
      'B2',
    );
    expect(
      formatter.formatEditUpdate(oldHex, const TextEditingValue(text: 'B2G')),
      oldHex,
    );
    expect(
      formatter.formatEditUpdate(
        oldHex,
        const TextEditingValue(text: '123456789'),
      ),
      oldHex,
    );
    tester
        .widget<MiuixColorPicker>(picker)
        .onChanged(const Color.fromARGB(115, 51, 129, 254));
    await tester.pump();
    expect(find.text('RGBA：51，129，254，0.45'), findsOneWidget);
    expect(find.text('RGBA：52，130，255，1.0'), findsNWidgets(4));
    expect(find.textContaining('1.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'contoured tab card preserves source physical height at 420 dpi',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MiuixExampleApp());
      await tester.pumpAndSettle();
      final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
      final homeScrollable = find.descendant(
        of: homeList,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final homePosition = tester
          .state<ScrollableState>(homeScrollable)
          .position;
      final contourCard = find.byKey(
        const ValueKey('reference-contour-tab-card'),
      );
      for (
        var attempt = 0;
        attempt < 48 && contourCard.evaluate().isEmpty;
        attempt++
      ) {
        homePosition.jumpTo(
          (homePosition.pixels + 620).clamp(
            homePosition.minScrollExtent,
            homePosition.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(contourCard, findsOneWidget);
      // 16 dp top/bottom padding, 45 dp contour row, a 12 dp gap, the natural
      // 17 sp source line box, and the 12 dp outer margin rasterize to
      // 84 + 118 + 32 + 52 + 32 px.
      expect(
        tester.getSize(contourCard).height * sourceDensity,
        closeTo(316, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'number picker card preserves source physical height at 420 dpi',
    (tester) async {
      const sourceDensity = 2.625;
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = sourceDensity;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MiuixExampleApp());
      await tester.pumpAndSettle();
      final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
      final homeScrollable = find.descendant(
        of: homeList,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Scrollable &&
              widget.axisDirection == AxisDirection.down,
        ),
      );
      final homePosition = tester
          .state<ScrollableState>(homeScrollable)
          .position;
      final numberCard = find.byKey(
        const ValueKey('reference-number-picker-card'),
      );
      for (
        var attempt = 0;
        attempt < 48 && numberCard.evaluate().isEmpty;
        attempt++
      ) {
        homePosition.jumpTo(
          (homePosition.pixels + 620).clamp(
            homePosition.minScrollExtent,
            homePosition.maxScrollExtent,
          ),
        );
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(numberCard, findsOneWidget);
      // The 225 dp wheel rounds to 591 px. Card padding adds 64 px and its
      // separate 12 dp bottom margin adds 32 px.
      expect(
        tester.getSize(numberCard).height * sourceDensity,
        closeTo(687, .001),
      );
      final wheels = find.descendant(
        of: numberCard,
        matching: find.byKey(const ValueKey('miuix-number-picker-wheel')),
      );
      final colon = find.byKey(const ValueKey('reference-number-picker-colon'));
      final colonText = find.descendant(of: colon, matching: find.text(':'));
      expect(wheels, findsNWidgets(2));
      expect(colon, findsOneWidget);
      expect(colonText, findsOneWidget);
      // Compose exposes the inner 952 physical pixels as 468 / 15 / 469 after
      // Android converts the three adjacent bounds outwards. Flutter retains
      // equal logical weights, so lock the density-ceiled text placeable that
      // makes those final integer bounds land on the same source edges.
      expect(
        tester.getSize(wheels.at(0)).width * sourceDensity,
        closeTo(468, .001),
      );
      expect(tester.getSize(colon).width * sourceDensity, closeTo(15, .001));
      expect(
        tester.getSize(wheels.at(1)).width * sourceDensity,
        closeTo(469, .001),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('feedback cards preserve source physical height at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final homePosition = tester.state<ScrollableState>(homeScrollable).position;
    final sinkCard = find.byKey(const ValueKey('reference-card-feedback-sink'));
    final tiltCard = find.byKey(const ValueKey('reference-card-feedback-tilt'));
    final indicationCard = find.byKey(
      const ValueKey('reference-card-indication'),
    );
    final holdDownCard = find.byKey(const ValueKey('reference-card-hold-down'));
    for (
      var attempt = 0;
      attempt < 96 && sinkCard.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 620).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(indicationCard, findsOneWidget);
    expect(sinkCard, findsOneWidget);
    expect(tiltCard, findsOneWidget);
    expect(holdDownCard, findsOneWidget);
    // Compose keeps the first blue surface at 194 physical pixels and then
    // applies the independent 12dp Modifier.padding below it. The Flutter
    // widget's complete layout footprint therefore measures 226px, while its
    // actual painted surface remains 194px.
    expect(
      tester.getSize(indicationCard).height * sourceDensity,
      closeTo(226, .001),
    );
    final indicationSurface = find.descendant(
      of: indicationCard,
      // HyperOS 4 cards use the static G2 surface instead of a rectangular
      // ColoredBox. Measuring that exact-shape surface excludes the caller's
      // independent 12dp outer margin.
      matching: find.byType(MiuixPressable),
    );
    expect(indicationSurface, findsOneWidget);
    expect(
      tester.getSize(indicationSurface).height * sourceDensity,
      closeTo(194, .001),
    );
    // The source card surface is 246 physical pixels: independently rounded
    // 42px top/bottom padding, a 55px 18sp title, and a 107px two-line
    // Paragraph block. Both weighted Row children must resolve to that same
    // height even though the localized glyph painter is slightly shorter.
    expect(tester.getSize(sinkCard).height * sourceDensity, closeTo(246, .001));
    expect(tester.getSize(tiltCard).height * sourceDensity, closeTo(246, .001));
    // Same-device UI bounds measure the original long-press surface at 192px.
    // The one-line Paragraph placeable is one physical pixel shorter than the
    // arithmetic em line height, unlike the two-line feedback paragraph.
    expect(
      tester.getSize(holdDownCard).height * sourceDensity,
      closeTo(192, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('long-press card holds feedback until dialog exit finishes', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    final holdDownCard = find.byKey(const ValueKey('reference-card-hold-down'));
    await _scrollUntilBuilt(tester, homeScrollable, holdDownCard);
    expect(holdDownCard, findsOneWidget);
    await Scrollable.ensureVisible(tester.element(holdDownCard), alignment: .5);
    await tester.pump();

    await tester.longPress(holdDownCard);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('长按操作'), findsOneWidget);
    expect(find.text('通过长按卡片触发。'), findsOneWidget);
    final cancelButton = find.byWidgetPredicate(
      (widget) => widget is MiuixTextButton && widget.label == '取消',
    );
    final confirmButton = find.byWidgetPredicate(
      (widget) => widget is MiuixTextButton && widget.label == '确认',
    );
    expect(cancelButton, findsOneWidget);
    expect(confirmButton, findsOneWidget);
    expect(
      tester.getSize(cancelButton).width * sourceDensity,
      closeTo(418, .001),
    );
    expect(
      tester.getSize(confirmButton).width * sourceDensity,
      closeTo(419, .001),
    );
    MiuixPressable cardPressable() => tester.widget<MiuixPressable>(
      find.descendant(of: holdDownCard, matching: find.byType(MiuixPressable)),
    );
    expect(cardPressable().holdDown, isTrue);

    final cancelLabel = find.descendant(
      of: find.byType(MiuixDialog),
      matching: find.text('取消'),
    );
    expect(cancelLabel, findsOneWidget);
    await tester.tap(cancelLabel);
    await tester.pump();
    // `onDismissFinished`, not the button callback, releases the card. This
    // prevents the source sink/indication from flashing off behind the dialog.
    expect(cardPressable().holdDown, isTrue);
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('长按操作'), findsNothing);
    expect(cardPressable().holdDown, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shape comparison preserves source physical height at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: _localizedReferenceTestTheme(),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                child: debugReferenceShapeComparisonSection(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final comparison = find.byKey(const ValueKey('shape-comparison-golden'));

    expect(comparison, findsOneWidget);
    // Preview 420 px + top padding 21 px + slider 74 px + bottom padding
    // 32 px. Every value is a separately rounded Compose placeable.
    expect(
      tester.getSize(comparison).height * sourceDensity,
      closeTo(547, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color cards preserve source physical heights at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final pickerCard = find.byKey(
      const ValueKey('reference-color-picker-okLch-card'),
    );
    final paletteCard = find.byKey(
      const ValueKey('reference-color-palette-card'),
    );
    final homePosition = tester.state<ScrollableState>(homeScroll).position;
    for (
      var attempt = 0;
      attempt < 96 && pickerCard.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 620).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(pickerCard, findsOneWidget);

    // Widget bounds include the separately measured 32px bottom modifier.
    // The source surfaces themselves are 704px and 909px respectively.
    expect(
      tester.getSize(pickerCard).height * sourceDensity,
      closeTo(736, .001),
    );
    for (
      var attempt = 0;
      attempt < 24 && paletteCard.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 620).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }
    expect(paletteCard, findsOneWidget);
    expect(
      tester.getSize(paletteCard).height * sourceDensity,
      closeTo(941, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('color page rows preserve source physical stride at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('颜色'));
    await tester.pumpAndSettle();

    final colorScrollBar = find.byKey(
      const ValueKey('reference-color-scrollbar'),
    );
    final colorList = find.byKey(
      const PageStorageKey('miuix-reference-colors'),
    );
    expect(colorScrollBar, findsOneWidget);
    final scrollBarWidget = tester.widget<MiuixVerticalScrollBar>(
      colorScrollBar,
    );
    final listWidget = tester.widget<ListView>(colorList);
    // ColorPage.kt contains exactly five keyed theme groups: current, light,
    // dynamic light, dark, and dynamic dark. Each ColorsPreview uses the same
    // ordered set of 52 MIUIX semantic roles.
    expect(listWidget.childrenDelegate.estimatedChildCount, 5);
    final visibleRoleBlocks = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith('color-role-');
    });
    expect(visibleRoleBlocks, findsNWidgets(52));
    // ColorPage.kt gives LazyColumn and VerticalScrollBar one remembered
    // adapter. The Flutter integration must likewise share one controller;
    // otherwise the thumb can paint but direct source-style dragging cannot
    // update the long token table.
    expect(scrollBarWidget.controller, isNotNull);
    expect(
      identical(scrollBarWidget.controller, listWidget.controller),
      isTrue,
    );

    final primary = tester.getRect(
      find.byKey(const ValueKey('color-role-primary')),
    );
    final primaryVariant = tester.getRect(
      find.byKey(const ValueKey('color-role-primaryVariant')),
    );
    final error = tester.getRect(
      find.byKey(const ValueKey('color-role-error')),
    );

    // Compose measures height(100.dp) and padding(bottom = 16.dp) as
    // independent placeables: 263 px + 42 px at the source density.
    expect(primary.height * sourceDensity, closeTo(263, .001));
    expect(
      (primaryVariant.top - primary.top) * sourceDensity,
      closeTo(305, .001),
    );
    expect((error.top - primary.top) * sourceDensity, closeTo(610, .001));
    // Localization must preserve the line count of each source English role.
    // These 25 labels wrap to two 17sp lines in the 420dpi Compose blocks;
    // shorter Chinese translations must not collapse them to one line.
    const sourceTwoLineRoles = [
      'disabledPrimaryButton',
      'disabledOnPrimaryButton',
      'disabledPrimarySlider',
      'onPrimaryContainer',
      'onSecondaryVariant',
      'disabledOnSecondary',
      'disabledSecondaryVariant',
      'disabledOnSecondaryVariant',
      'secondaryContainer',
      'onSecondaryContainer',
      'secondaryContainerVariant',
      'onSecondaryContainerVariant',
      'onTertiaryContainer',
      'tertiaryContainerVariant',
      'onBackgroundVariant',
      'onSurfaceSecondary',
      'onSurfaceVariantSummary',
      'onSurfaceVariantActions',
      'onSurfaceContainer',
      'onSurfaceContainerVariant',
      'surfaceContainerHigh',
      'onSurfaceContainerHigh',
      'surfaceContainerHighest',
      'onSurfaceContainerHighest',
      'sliderKeyPointForeground',
    ];
    for (final role in sourceTwoLineRoles) {
      final label = find.descendant(
        of: find.byKey(ValueKey('color-role-$role')),
        matching: find.byType(Text),
      );
      expect(label, findsOneWidget, reason: role);
      expect(
        tester.getSize(label).height * sourceDensity,
        closeTo(105, .001),
        reason: role,
      );
    }
    await tester.drag(colorList, const Offset(0, -180));
    await tester.pump();
    expect(
      find.descendant(
        of: colorScrollBar,
        matching: find.byKey(const ValueKey('miuix-scrollbar-drag-target')),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('settings cards preserve source physical gaps at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();

    final settingsList = find.byKey(
      const PageStorageKey('miuix-reference-settings'),
    );
    final scrollable = find
        .descendant(of: settingsList, matching: find.byType(Scrollable))
        .first;
    final position = tester.state<ScrollableState>(scrollable).position;
    final uiCard = find.byKey(const ValueKey('reference-settings-ui-card'));
    final transitionCard = find.byKey(
      const ValueKey('reference-settings-transition-card'),
    );
    for (
      var attempt = 0;
      attempt < 12 && transitionCard.evaluate().isEmpty;
      attempt++
    ) {
      position.jumpTo(
        (position.pixels + 260).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }

    expect(uiCard, findsOneWidget);
    expect(transitionCard, findsOneWidget);
    final uiBounds = tester.getRect(uiCard);
    final transitionBounds = tester.getRect(transitionCard);
    // The keyed card includes its 12dp bottom margin. The current translated
    // SmallTitle slot occupies 34 logical pixels at this test density; this is
    // a project fixture measurement rather than a claimed official constant.
    expect(
      tester.widget<MiuixCard>(uiCard).margin,
      const EdgeInsets.only(bottom: 32 / sourceDensity),
    );
    expect(
      (transitionBounds.top - uiBounds.bottom) * sourceDensity,
      closeTo(89.25, .001),
    );

    // Floating navigation now has one canonical style. Leaving the default
    // floating state reveals exactly one regular-navigation mode row; it must
    // not inject the former floating style and alignment rows.
    position.jumpTo(0);
    await tester.pump();
    await tester.tap(find.text('使用悬浮导航栏'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('reference-floating-navigation-style-row')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('reference-floating-navigation-position-row')),
      findsNothing,
    );
    final expandedUiBounds = tester.getRect(uiCard);
    expect(expandedUiBounds.height, closeTo(uiBounds.height + 56, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nested scaffold popup keeps source local pixel origin', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '多脚手架测试');

    final quadrants = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith(
            'multi-scaffold-quadrant-',
          ),
    );
    final dropdowns = find.byType(MiuixOverlayDropdownPreference<int>);
    expect(quadrants, findsNWidgets(4));
    expect(dropdowns, findsNWidgets(4));

    await tester.tap(dropdowns.first);
    await tester.pumpAndSettle();
    final popup = find.byType(MiuixListPopupColumn);
    expect(popup, findsOneWidget);
    final popupRect = tester.getRect(popup);
    // The original 420dpi capture is [0,511][525,904]. Widget tests omit the
    // 63px Android status-bar inset, making the source-local top exactly 448.
    // The nested host starts on a half physical pixel in Flutter, so the
    // delegate must cancel that paint phase instead of rasterizing at 449.
    expect(popupRect.left * sourceDensity, closeTo(0, .001));
    final triggerRect = tester.getRect(dropdowns.first);
    expect(popupRect.top, closeTo(triggerRect.bottom - 12, .1));
    expect(popupRect.width * sourceDensity, closeTo(525, .001));
    // Flutter retains the subpixel intrinsic height, while both Android
    // accessibility bounds and the raster surface resolve it to 393px.
    expect((popupRect.height * sourceDensity).round(), 393);

    await tester.tap(find.text('B'));
    await tester.pumpAndSettle();
    final values = tester
        .widgetList<MiuixOverlayDropdownPreference<int>>(dropdowns)
        .map((preference) => preference.value)
        .toList();
    expect(values, const [1, 0, 0, 0]);

    // PopupPositionProvider clamps against the complete window before the
    // right-hand nested PopupHost clips its surface. The original lower-right
    // capture therefore keeps the 525px surface at x=481..1006 instead of
    // re-clamping it to the local host and shifting its end to x=1065.
    await tester.tap(dropdowns.last);
    await tester.pumpAndSettle();
    final lowerRightPopupRect = tester.getRect(
      find.byType(MiuixListPopupColumn),
    );
    final lowerRightQuadrant = quadrants.at(3);
    final lowerRightClip = find.descendant(
      of: lowerRightQuadrant,
      matching: find.byKey(const ValueKey('miuix-popup-host-clip')),
    );
    expect(lowerRightClip, findsOneWidget);
    final lowerRightClipRect = tester.getRect(lowerRightClip);
    expect(lowerRightPopupRect.left * sourceDensity, closeTo(481, .001));
    expect(lowerRightPopupRect.right * sourceDensity, closeTo(1006, .001));
    expect(lowerRightPopupRect.width * sourceDensity, closeTo(525, .001));
    expect(lowerRightClipRect.left * sourceDensity, closeTo(540, .001));
    expect(lowerRightPopupRect.left < lowerRightClipRect.left, isTrue);
    expect(lowerRightPopupRect.right <= lowerRightClipRect.right, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localized preference rows keep HyperOS 4 line boxes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: 'Roboto',
          fontFamilyFallback: const ['NotoSansCJKsc'],
        ),
        home: MiuixTheme(
          child: Column(
            children: [
              MiuixRadioButtonPreference<int>(
                key: const ValueKey('localized-two-line-preference'),
                title: '选项 A',
                summary: '已选择：是',
                value: 0,
                groupValue: 0,
                onChanged: (_) {},
              ),
              MiuixRadioButtonPreference<int>(
                key: const ValueKey('localized-one-line-preference'),
                title: '禁用的单选按钮',
                value: 1,
                groupValue: 1,
                enabled: false,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    final twoLine = tester.getSize(
      find.byKey(const ValueKey('localized-two-line-preference')),
    );
    final oneLine = tester.getSize(
      find.byKey(const ValueKey('localized-one-line-preference')),
    );
    expect(twoLine.height * 2.625, closeTo(175.875, 1e-9));
    expect(oneLine.height * 2.625, closeTo(157.5, 1e-9));
    expect(tester.takeException(), isNull);
  });

  testWidgets('blur preview preserves source physical sizes at 420 dpi', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final homeScroll = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final preview = find.byKey(
      const ValueKey('reference-texture-blur-preview'),
    );
    final homePosition = tester.state<ScrollableState>(homeScroll).position;
    for (
      var attempt = 0;
      attempt < 120 && preview.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 620).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 30));
    }

    final blurOverlay = find.byKey(const ValueKey('texture-blur-overlay'));
    final progressivePreview = find.byKey(
      const ValueKey('reference-progressive-blur-preview'),
    );
    expect(preview, findsOneWidget);
    expect(blurOverlay, findsOneWidget);
    expect(progressivePreview, findsOneWidget);
    // Complete shader loading before this app is disposed; otherwise a later
    // test in the same process could inherit an asset request cancelled by the
    // test binding teardown instead of the compiled shared program.
    for (
      var attempt = 0;
      attempt < 100 &&
          find
              .byKey(const ValueKey('miuix-backdrop-highlight-runtime'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
      find.byKey(const ValueKey('miuix-backdrop-highlight-runtime')),
      findsOneWidget,
    );
    // BlurSection.kt measures the 280dp preview and its centered 140dp blur
    // overlay independently: 735 px and 368 px on the reference device.
    expect(tester.getSize(preview).height * sourceDensity, closeTo(735, .001));
    expect(
      tester.getSize(blurOverlay).height * sourceDensity,
      closeTo(368, .001),
    );
    expect(
      tester.getSize(progressivePreview).height * sourceDensity,
      closeTo(735, .001),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('blur section matches source previews controls and blend order', (
    tester,
  ) async {
    final tiltEvents = StreamController<MiuixDeviceTilt>.broadcast();
    MiuixDeviceTiltSensor.debugEvents = tiltEvents.stream;
    addTearDown(() async {
      MiuixDeviceTiltSensor.debugEvents = null;
      await tiltEvents.close();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    debugFreezeReferenceBlurBackground = true;
    addTearDown(() => debugFreezeReferenceBlurBackground = false);
    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    // The blur showcase must opt into the optional global effect now that the
    // executable matches the original sample's opaque initial state.
    await _enableReferenceBlur(tester, returnToHome: true);
    final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
    final rootPager = find.ancestor(
      of: homeList,
      matching: find.byType(PageView),
    );
    final rootPageController = tester.widget<PageView>(rootPager).controller!;
    expect(rootPageController.page, closeTo(0, .001));
    expect(MiuixTheme.of(tester.element(homeList)).enableGlass, isTrue);
    final texturePreview = find.byKey(
      const ValueKey('reference-texture-blur-preview'),
    );
    // Once the animated source preview enters the lazy list, use bounded pumps
    // instead of pumpAndSettle because its background intentionally repeats.
    // The source home page is intentionally long and every component section
    // is a separate lazy item. Advance its actual scroll position so an
    // overlaying floating bar cannot consume the synthetic drag in this test.
    final homeScrollable = find.descendant(
      of: homeList,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    expect(homeScrollable, findsOneWidget);
    final homePosition = tester.state<ScrollableState>(homeScrollable).position;
    for (
      var attempt = 0;
      attempt < 96 && texturePreview.evaluate().isEmpty;
      attempt++
    ) {
      homePosition.jumpTo(
        (homePosition.pixels + 620).clamp(
          homePosition.minScrollExtent,
          homePosition.maxScrollExtent,
        ),
      );
      await tester.pump(const Duration(milliseconds: 40));
    }

    expect(texturePreview, findsOneWidget);
    final foregroundPreview = find.byKey(
      const ValueKey('reference-foreground-blur-preview'),
    );
    final progressivePreview = find.byKey(
      const ValueKey('reference-progressive-blur-preview'),
    );
    expect(foregroundPreview, findsOneWidget);
    expect(progressivePreview, findsOneWidget);
    expect(tester.getSize(texturePreview).height, 280);
    expect(tester.getSize(foregroundPreview).height, 280);
    expect(tester.getSize(progressivePreview).height, 280);
    // BlurSection.kt applies one 12 dp horizontal inset to both preview cards.
    // The page must not add a second section-local inset around either demo.
    expect(tester.getSize(texturePreview).width, 366);
    expect(tester.getSize(foregroundPreview).width, 366);
    expect(tester.getSize(progressivePreview).width, 366);
    expect(tester.getTopLeft(texturePreview).dx, 12);
    expect(tester.getTopLeft(foregroundPreview).dx, 12);
    expect(tester.getTopLeft(progressivePreview).dx, 12);
    expect(find.text('纹理模糊 | 半径=100'), findsOneWidget);
    expect(find.text('彩色厚重 | 小容器'), findsOneWidget);
    expect(find.text('渐进模糊\n顶部 | 半径=20 | 无'), findsOneWidget);
    expect(find.byType(MiuixForegroundBlurText), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 32));
    expect(
      find.byKey(const ValueKey('miuix-foreground-blur-mask')),
      findsOneWidget,
    );
    // Skia uses the measured Logo Blend gradient for foreground glyphs; the
    // texture preview itself still exercises the library backdrop. Impeller
    // swaps the foreground path to its exact image-filter shader at runtime.
    expect(find.byType(MiuixBackdropEffectScope), findsOneWidget);
    tiltEvents.add(
      const MiuixDeviceTilt(pitch: .4, roll: -.2, gravityX: 0, gravityY: 0),
    );
    await tester.pump();
    final tiltedBackdrop = tester
        .widget<MiuixBackdropEffectScope>(find.byType(MiuixBackdropEffectScope))
        .backdrop;
    // The example consumes the live platform stream instead of merely
    // exposing an unused sensor API. Restore zero before raster comparison.
    expect(tiltedBackdrop.highlight?.position.dx, closeTo(.47, .000001));
    expect(tiltedBackdrop.highlight?.position.dy, closeTo(.44, .000001));
    tiltEvents.add(MiuixDeviceTilt.zero);
    await tester.pump();
    // Device builds use the exact variable-radius shader. The headless Skia
    // test backend cannot host ImageFilter.shader and therefore exercises the
    // documented three-level fallback instead.
    if (ImageFilter.isShaderFilterSupported) {
      for (
        var attempt = 0;
        attempt < 100 &&
            find
                .byKey(const ValueKey('miuix-progressive-runtime-filter'))
                .evaluate()
                .isEmpty;
        attempt++
      ) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(
        find.byKey(const ValueKey('miuix-progressive-runtime-filter')),
        findsOneWidget,
      );
    } else {
      expect(
        find.byKey(const ValueKey('miuix-progressive-blur-level-13')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('miuix-progressive-blur-level-40')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('miuix-progressive-blur-level-100')),
        findsOneWidget,
      );
    }
    expect(
      find.byKey(const ValueKey('miuix-progressive-post-effect-mask')),
      findsNothing,
    );
    expect(find.byType(Image), findsWidgets);
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/images/blur_test.png'),
        tester.element(homeList),
      );
    });
    await tester.pump();
    await Scrollable.ensureVisible(
      tester.element(texturePreview),
      alignment: .1,
      duration: Duration.zero,
    );
    // The source highlight is a runtime shader. Wait for its asynchronous
    // compilation so the golden never alternates with the temporary fallback.
    for (
      var attempt = 0;
      attempt < 100 &&
          find
              .byKey(const ValueKey('miuix-backdrop-highlight-runtime'))
              .evaluate()
              .isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(
      find.byKey(const ValueKey('miuix-backdrop-highlight-runtime')),
      findsOneWidget,
    );
    await expectLater(
      texturePreview,
      matchesGoldenFile('goldens/blur_texture_preview.png'),
    );

    final textureControls = find.byKey(
      const ValueKey('reference-texture-blur-controls'),
    );
    final foregroundControls = find.byKey(
      const ValueKey('reference-foreground-blur-controls'),
    );
    final progressiveControls = find.byKey(
      const ValueKey('reference-progressive-blur-controls'),
    );
    expect(
      tester.widget<MiuixCard>(textureControls).margin,
      const EdgeInsets.only(bottom: 12),
    );
    // All three current source demos give their single combined preview and
    // control card the same trailing 12dp list spacing.
    expect(
      tester.widget<MiuixCard>(foregroundControls).margin,
      const EdgeInsets.only(bottom: 12),
    );
    expect(
      tester.widget<MiuixCard>(progressiveControls).margin,
      const EdgeInsets.only(bottom: 12),
    );
    // Freeze the source's optional animated background before raster
    // comparison; the foreground mask itself remains a live backdrop filter.
    tester
        .widget<MiuixSwitch>(
          find
              .descendant(
                of: foregroundControls,
                matching: find.byType(MiuixSwitch),
              )
              .first,
        )
        .onChanged
        ?.call(false);
    await tester.pump(const Duration(milliseconds: 32));
    await Scrollable.ensureVisible(
      tester.element(foregroundPreview),
      alignment: .1,
      duration: Duration.zero,
    );
    await tester.pump(const Duration(milliseconds: 32));
    await expectLater(
      foregroundPreview,
      matchesGoldenFile('goldens/blur_foreground_preview.png'),
    );
    await Scrollable.ensureVisible(
      tester.element(progressivePreview),
      alignment: .1,
      duration: Duration.zero,
    );
    await tester.pump(const Duration(milliseconds: 32));
    await expectLater(
      progressivePreview,
      matchesGoldenFile('goldens/blur_progressive_preview.png'),
    );
    expect(
      find.descendant(of: textureControls, matching: find.byType(MiuixSlider)),
      findsNWidgets(5),
    );
    expect(
      find.descendant(
        of: foregroundControls,
        matching: find.byType(MiuixSlider),
      ),
      findsNWidgets(5),
    );
    expect(
      find.descendant(
        of: progressiveControls,
        matching: find.byType(MiuixSlider),
      ),
      findsNWidgets(5),
    );
    // BlurDefaults.NoiseCoefficient is declared as 0.0045f, but the source
    // multiplies that binary32 value by 10000 and truncates it before display.
    // Its visible result is consequently 0.0044 in both control cards.
    expect(find.text('0.0044'), findsNWidgets(2));
    expect(find.text('0.0045'), findsNothing);
    expect(find.text('0.0'), findsWidgets);
    expect(find.text('上一个'), findsNothing);
    expect(find.text('下一个'), findsNothing);

    Finder dropdownsInside(Finder controls) => find.descendant(
      of: controls,
      matching: find.byWidgetPredicate(
        (widget) => widget is MiuixDropdownPreference<int>,
      ),
    );

    final textureDropdowns = tester
        .widgetList<MiuixDropdownPreference<int>>(
          dropdownsInside(textureControls),
        )
        .toList();
    final foregroundDropdowns = tester
        .widgetList<MiuixDropdownPreference<int>>(
          dropdownsInside(foregroundControls),
        )
        .toList();
    final progressiveDropdowns = tester
        .widgetList<MiuixDropdownPreference<int>>(
          dropdownsInside(progressiveControls),
        )
        .toList();
    expect(textureDropdowns, hasLength(2));
    expect(foregroundDropdowns, hasLength(2));
    expect(progressiveDropdowns, hasLength(2));
    expect(textureDropdowns.map((item) => item.title), ['混合模式', '高光']);
    expect(foregroundDropdowns.map((item) => item.title), ['效果版本', '混合模式']);
    expect(progressiveDropdowns.map((item) => item.title), ['方向', '混合模式']);
    expect(foregroundDropdowns.first.value, 1);
    expect(progressiveDropdowns.first.value, 0);

    textureDropdowns.first.onChanged(6);
    await tester.pump();
    expect(find.text('纯色常规 | 小容器'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('miuix-blur-blend-layers')),
      ImageFilter.isShaderFilterSupported ? findsNothing : findsOneWidget,
    );

    textureDropdowns.last.onChanged(0);
    await tester.pump();
    final textureBackdrop = tester.widget<MiuixBackdropEffectScope>(
      find.descendant(
        of: texturePreview,
        matching: find.byType(MiuixBackdropEffectScope),
      ),
    );
    expect(textureBackdrop.backdrop.highlight, isNull);

    progressiveDropdowns.first.onChanged(3);
    await tester.pump();
    final progressiveBackdrop = tester.widget<MiuixProgressiveLayerBackdrop>(
      find.descendant(
        of: progressivePreview,
        matching: find.byType(MiuixProgressiveLayerBackdrop),
      ),
    );
    expect(progressiveBackdrop.gradient.angle, 180);
    expect(find.text('渐进模糊\n右侧 | 半径=20 | 无'), findsOneWidget);
    expect(rootPageController.page, closeTo(0, .001));
    expect(tester.takeException(), isNull);

    // Dispose the repeating preview ticker before the test binding checks for
    // pending animations. Advance once so the preview's double-tap recognizer
    // can also release its short gesture timer.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shape comparison renders the upstream G2 difference', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MiuixTheme(
          data: _localizedReferenceTestTheme(),
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SingleChildScrollView(
                child: debugReferenceShapeComparisonSection(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final preview = find.byKey(const ValueKey('shape-comparison-preview'));
    expect(preview, findsOneWidget);
    // LazyList builds children inside its cache extent before they enter the
    // viewport. Bring the preview on-screen so the repaint boundary is not
    // culled by the compositor when the golden image is captured.
    await Scrollable.ensureVisible(tester.element(preview), alignment: .5);
    await tester.pump();
    expect(tester.getSize(preview).height, 160);
    expect(tester.getSize(preview).width, 366);
    expect(tester.getTopLeft(preview).dx, 12);
    await expectLater(
      find.byKey(const ValueKey('shape-comparison-golden')),
      matchesGoldenFile('goldens/shape_comparison.png'),
    );
    final radiusSlider = tester.widget<MiuixSlider>(
      find.descendant(
        of: find.byKey(const ValueKey('shape-comparison-golden')),
        matching: find.byType(MiuixSlider),
      ),
    );
    radiusSlider.onChanged?.call(48.9);
    await tester.pump();
    expect(find.text('红色 = 差异，圆角 = 48dp'), findsOneWidget);
    expect(find.text('红色 = 差异，圆角 = 49dp'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Home opens the current navigation fixture pages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '导航测试');
    // The source large app bar mounts both its large and compact title nodes.
    expect(find.text('导航测试 1'), findsNWidgets(2));
    expect(find.byType(MiuixArrowPreference), findsNWidgets(10));
    expect(find.byType(MiuixBasicComponent), findsOneWidget);
    expect(find.text('连续层级'), findsOneWidget);
    expect(find.text('手势返回'), findsOneWidget);
    expect(find.text('布局测试'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('navigation-continuous-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('navigation-gesture-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('navigation-layout-card')),
      findsOneWidget,
    );
    // Current NavigateTestPage.kt no longer has the historical Window popup.
    expect(find.bySemanticsLabel('窗口 1'), findsNothing);
    expect(find.byType(MiuixListPopup<String>), findsNothing);
    await expectLater(
      find.byType(Scaffold).last,
      matchesGoldenFile('goldens/navigation_test_page.png'),
    );

    // One push advances N by one. Three synchronous pushes then advance the
    // displayed stack depth by three, matching the current source callback.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('navigation-push-one'))),
      alignment: .5,
    );
    tester
        .widget<MiuixArrowPreference>(
          find.byKey(const ValueKey('navigation-push-one')),
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('导航测试 2'), findsNWidgets(2));
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('navigation-push-three'))),
      alignment: .5,
    );
    tester
        .widget<MiuixArrowPreference>(
          find.byKey(const ValueKey('navigation-push-three')),
        )
        .onTap!();
    await tester.pumpAndSettle();
    expect(find.text('导航测试 5'), findsNWidgets(2));

    // Pop only consecutive navigation routes. This returns to the Home entry
    // without replacing it or clearing the root page state.
    await Scrollable.ensureVisible(
      tester.element(find.byKey(const ValueKey('navigation-pop-all'))),
      alignment: .5,
    );
    tester
        .widget<MiuixArrowPreference>(
          find.byKey(const ValueKey('navigation-pop-all')),
        )
        .onTap!();
    await tester.pump();
    await tester.pump();
    expect(
      find.text('导航测试 0'),
      findsNWidgets(2),
      reason: 'the outgoing source page recomputes its index after popUntil',
    );
    await tester.pump(const Duration(milliseconds: 250));
    final midPopTranslations = tester
        .widgetList<FractionalTranslation>(
          find.byKey(const ValueKey('reference-nav-transition-scene')),
        )
        .map((scene) => scene.translation.dx)
        .toList(growable: false);
    expect(
      midPopTranslations.any((value) => value.abs() > .01 && value.abs() < .99),
      isTrue,
      reason: 'the shared multi-pop must render a real intermediate frame',
    );
    await tester.pump(const Duration(milliseconds: 270));
    await tester.pump();
    expect(find.text('导航测试 5'), findsNothing);
    expect(tester.takeException(), isNull);

    // The Android parity captures use the source fixture's 1080 / 2.625 =
    // 411.43dp viewport. A 390dp test window makes each half only 195dp wide,
    // which is narrower than MIUIX DropdownImpl's intentional 200dp minimum.
    tester.view.physicalSize = const Size(412, 915);
    await tester.pump();
    await _openReferenceHomeFixture(tester, '多脚手架测试');
    expect(find.text('多脚手架测试'), findsNWidgets(2));
    expect(find.text('左上'), findsOneWidget);
    expect(find.text('右下'), findsOneWidget);
    await expectLater(
      find.byKey(const ValueKey('multi-scaffold-page')),
      matchesGoldenFile('goldens/multi_scaffold_page.png'),
    );

    // The source fixture deliberately nests four independent Scaffold popup
    // hosts. Opening the upper-left dropdown must keep both its dim layer and
    // its popup surface inside that quadrant instead of promoting them to the
    // route-level host shared by the other three quadrants.
    final upperLeft = find.byKey(const ValueKey('multi-scaffold-quadrant-0'));
    await tester.tap(
      find.descendant(of: upperLeft, matching: find.text('下拉菜单')),
    );
    await tester.pumpAndSettle();
    final localPopup = find.descendant(
      of: upperLeft,
      matching: find.byType(MiuixListPopupColumn),
    );
    expect(localPopup, findsOneWidget);
    expect(find.byType(MiuixListPopupColumn), findsOneWidget);
    final quadrantRect = tester.getRect(upperLeft);
    final popupRect = tester.getRect(localPopup);
    expect(
      popupRect.left >= quadrantRect.left &&
          popupRect.top >= quadrantRect.top &&
          popupRect.right <= quadrantRect.right &&
          popupRect.bottom <= quadrantRect.bottom,
      isTrue,
      reason: 'popup $popupRect must stay inside quadrant $quadrantRect',
    );
    await expectLater(
      find.byKey(const ValueKey('multi-scaffold-page')),
      matchesGoldenFile('goldens/multi_scaffold_popup.png'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('current navigation fixture keeps source 420dpi geometry', (
    tester,
  ) async {
    const sourceDensity = 2.625;
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = sourceDensity;
    tester.view.padding = const FakeViewPadding(top: 63, bottom: 63);
    tester.view.viewPadding = const FakeViewPadding(top: 63, bottom: 63);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await _openReferenceHomeFixture(tester, '导航测试');
    expect(find.byType(MiuixListPopup<String>), findsNothing);
    expect(
      find.byIcon(MiuixExtendedIconCatalog.find('Edit')!.regular),
      findsNothing,
    );

    // All three source cards apply their own independently rounded 12dp
    // horizontal modifier rather than shrinking the LazyColumn itself.
    for (final key in const [
      ValueKey('navigation-continuous-card'),
      ValueKey('navigation-gesture-card'),
      ValueKey('navigation-layout-card'),
    ]) {
      final card = tester.getRect(find.byKey(key));
      expect(card.left * sourceDensity, closeTo(32, .001));
      expect(card.right * sourceDensity, closeTo(1048, .001));
      expect(card.width * sourceDensity, closeTo(1016, .001));
    }

    // Same-emulator native UI-tree rows from current NavigateTestPage.kt.
    // These lock independent Compose rounding and the localized line wrapping,
    // not merely the aggregate card width.
    const sourceRowBounds = <(String, double, double)>[
      ('navigation-push-one', 395, 574),
      ('navigation-push-three', 574, 753),
      ('navigation-pop-all', 753, 932),
      ('navigation-layout-0', 1474, 1705),
      ('navigation-layout-1', 1705, 1927),
      ('navigation-layout-2', 1927, 2115),
      ('navigation-layout-3', 2115, 2398),
      ('navigation-layout-4', 2398, 2620),
      ('navigation-layout-5', 2620, 2851),
      ('navigation-layout-6', 2851, 3073),
    ];
    const hyperOs4HeaderShift = 14.25;
    for (final (key, sourceTop, sourceBottom) in sourceRowBounds) {
      final row = tester.getRect(find.byKey(ValueKey(key)));
      final sectionShift = key.startsWith('navigation-layout-')
          ? hyperOs4HeaderShift * 3
          : hyperOs4HeaderShift;
      expect(row.top * sourceDensity, closeTo(sourceTop + sectionShift, .001));
      expect(
        row.height * sourceDensity,
        closeTo(sourceBottom - sourceTop, .001),
      );
    }
    final gestureCard = tester.getRect(
      find.byKey(const ValueKey('navigation-gesture-card')),
    );
    expect(
      gestureCard.top * sourceDensity,
      closeTo(1049 + hyperOs4HeaderShift * 2, .001),
    );
    expect(gestureCard.height * sourceDensity, closeTo(308, .001));

    // The current fixture contains exactly three continuous-depth rows, one
    // BasicComponent gesture explanation, and seven layout pressure rows.
    expect(find.byType(MiuixArrowPreference), findsNWidgets(10));
    expect(find.byType(MiuixBasicComponent), findsOneWidget);
    for (var index = 0; index < 7; index++) {
      expect(find.byKey(ValueKey('navigation-layout-$index')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('navigation-layout-7')), findsNothing);

    final navigationList = find.byType(ListView).last;
    final scrollable = find.descendant(
      of: navigationList,
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);
    final position = tester.state<ScrollableState>(scrollable).position;
    // The first jump collapses the source bar and changes the live Scaffold
    // padding/max extent. Land on that recomputed endpoint before measuring
    // the final 12dp edge spacing.
    for (var pass = 0; pass < 2; pass++) {
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
    }
    final layoutCard = tester.getRect(
      find.byKey(const ValueKey('navigation-layout-card')),
    );
    // The edge-to-edge source leaves only its 12dp content spacing below the
    // final card: 2400px - round(12dp * 2.625) = 2368px.
    expect(layoutCard.bottom * sourceDensity, closeTo(2368, .001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('level-five glass visibly reveals the settings page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MiuixExampleApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('ios-liquid-tab-4')));
    await tester.pumpAndSettle();
    await _centerReferenceSetting(tester, '玻璃模糊与透明度');
    await tester.tap(find.text('玻璃模糊与透明度'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 档 · 最强').last);
    await tester.pumpAndSettle();
    // Keep actual rows behind both surfaces. Capturing the entire shell catches
    // the failure mode where filters exist in the widget tree but an opaque
    // tint or an unextended body makes them visually indistinguishable.
    await _centerReferenceSetting(tester, '悬浮导航栏显示模式');
    // The compact title crosses its one-third threshold independently of the
    // scroll settle and uses the source's 0.3s critically damped show spring.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('ios-liquid-backdrop-filter')),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
    final previousComparator = goldenFileComparator;
    // The live floating BackdropFilter and scroll thumb can differ by a few
    // antialiased edge pixels between otherwise identical Skia frames. Keep
    // the same strict 0.3% ceiling used by the floating-toolbar glass proof.
    goldenFileComparator = _TolerantReferenceGoldenComparator(
      Uri.parse('test/reference_structure_test.dart'),
      precisionTolerance: 0.003,
    );
    addTearDown(() => goldenFileComparator = previousComparator);
    await expectLater(
      find.byType(Scaffold).first,
      matchesGoldenFile('goldens/intense_glass_settings_shell.png'),
    );
    expect(tester.takeException(), isNull);
  });
}

/// Enables the current source blur setting through the localized UI.
///
/// AppState now defaults to enabled, so the helper first reads the live theme
/// and mutates the switch only when a test has explicitly turned it off.
Future<void> _enableReferenceBlur(
  WidgetTester tester, {
  bool returnToHome = false,
}) async {
  await tester.tap(find.text('设置').last);
  await tester.pumpAndSettle();
  final fps = find.text('显示 FPS 监视器');
  if (!MiuixTheme.of(tester.element(fps)).enableGlass) {
    await _centerReferenceSetting(tester, '启用模糊效果');
    await tester.tap(find.text('启用模糊效果'));
    await tester.pumpAndSettle();
  }
  if (returnToHome) {
    await tester.tap(find.text('主页').last);
    await tester.pumpAndSettle();
  }
}

/// Disables blur only for tests that intentionally exercise the opaque branch.
Future<void> _disableReferenceBlur(
  WidgetTester tester, {
  bool returnToHome = false,
}) async {
  await tester.tap(find.text('设置').last);
  await tester.pumpAndSettle();
  final fps = find.text('显示 FPS 监视器');
  if (MiuixTheme.of(tester.element(fps)).enableGlass) {
    await _centerReferenceSetting(tester, '启用模糊效果');
    await tester.tap(find.text('启用模糊效果'));
    await tester.pumpAndSettle();
  }
  if (returnToHome) {
    await tester.tap(find.text('主页').last);
    await tester.pumpAndSettle();
  }
}

/// Reveals and opens one current source fixture from Home's lazy Other group.
Future<void> _openReferenceHomeFixture(
  WidgetTester tester,
  String label,
) async {
  if (find
      .byKey(const PageStorageKey('miuix-reference-home'))
      .evaluate()
      .isEmpty) {
    await tester.tap(find.text('主页').last);
    await tester.pumpAndSettle();
  }
  final homeList = find.byKey(const PageStorageKey('miuix-reference-home'));
  final scrollable = find.descendant(
    of: homeList,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  final position = tester.state<ScrollableState>(scrollable).position;
  final target = find.text(label);
  for (var attempt = 0; attempt < 140 && target.evaluate().isEmpty; attempt++) {
    position.jumpTo(
      (position.pixels + 520).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    await tester.pump(const Duration(milliseconds: 24));
  }
  expect(target, findsOneWidget);
  await Scrollable.ensureVisible(
    tester.element(target),
    alignment: .5,
    duration: Duration.zero,
  );
  await tester.pump();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

/// Scrolls one settings row away from both the top bar and floating navigation.
Future<void> _centerReferenceSetting(
  WidgetTester tester,
  String label, {
  double scrollDelta = 250,
}) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    scrollDelta,
    scrollable: find.byType(Scrollable).last,
  );
  // The source Scaffold updates body PaddingValues from the measured top-bar
  // height. Let the collapse snap finish, then align twice: the first jump may
  // rebuild that live inset, while the second lands on the final source
  // geometry instead of preserving a position measured against the old inset.
  await tester.pumpAndSettle();
  for (var pass = 0; pass < 2; pass++) {
    await Scrollable.ensureVisible(
      tester.element(target),
      alignment: .45,
      duration: Duration.zero,
    );
    await tester.pump();
  }
}

/// Sends the same method calls Android uses for an API 34+ back gesture.
Future<Object?> _sendPredictiveBackMethod(
  String method, [
  Map<String, Object?>? arguments,
]) async {
  final codec = SystemChannels.backGesture.codec;
  final reply = await TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.backGesture.name,
        codec.encodeMethodCall(MethodCall(method, arguments)),
        null,
      );
  return reply == null ? null : codec.decodeEnvelope(reply);
}

/// Loads the same Chinese and MIUIX icon fonts used by the executable app.
///
/// Flutter widget tests otherwise substitute the square Ahem test font, which
/// can preserve geometry while hiding real clipping and baseline regressions.
/// Matches the executable's Roboto-first, localized-CJK typography chain.
MiuixThemeData _localizedReferenceTestTheme() {
  final base = MiuixThemeData.defaults();
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: const ['NotoSansCJKsc'],
    ),
  );
}

Future<void> _loadReferenceFonts() async {
  final current = Directory.current;
  final exampleRoot =
      File(
        '${current.path}/assets/fonts/NotoSansCJKsc-Regular.otf',
      ).existsSync()
      ? current
      : Directory('${current.path}/example');
  final packageRoot = exampleRoot.parent;

  Future<void> load(String family, File file) async {
    final bytes = await file.readAsBytes();
    await (FontLoader(
      family,
    )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
  }

  final chineseLoader = FontLoader('NotoSansCJKsc');
  for (final name in const [
    'NotoSansCJKsc-Regular.otf',
    'NotoSansCJKsc-Medium.otf',
    'NotoSansCJKsc-Bold.otf',
  ]) {
    final bytes = await File(
      '${exampleRoot.path}/assets/fonts/$name',
    ).readAsBytes();
    chineseLoader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await chineseLoader.load();
  // The localized floating navigation keeps the upstream English labels as
  // invisible intrinsic-width references. Android resolves those labels with
  // its platform Roboto family, while widget tests otherwise substitute Ahem
  // for an unregistered family and make the five-item pill overflow by 12dp.
  // Flutter ships the same Roboto faces in every SDK cache, so register them
  // here to keep test geometry representative of the executable application.
  var flutterCache = File(Platform.resolvedExecutable).parent;
  while (flutterCache.parent.path != flutterCache.path &&
      flutterCache.path.split(Platform.pathSeparator).last.toLowerCase() !=
          'cache') {
    flutterCache = flutterCache.parent;
  }
  final robotoLoader = FontLoader('Roboto');
  for (final name in const ['roboto-regular.ttf', 'roboto-bold.ttf']) {
    final bytes = await File(
      '${flutterCache.path}/artifacts/material_fonts/$name',
    ).readAsBytes();
    robotoLoader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await robotoLoader.load();
  await load(
    'packages/flutter_miuix/MiuixIconsBasic',
    File('${packageRoot.path}/assets/fonts/MiuixIcons-Basic.ttf'),
  );
  await load(
    'packages/flutter_miuix/MiuixIconsRegular',
    File('${packageRoot.path}/assets/fonts/MiuixIcons-Regular.ttf'),
  );
  await load(
    'MaterialIcons',
    File(
      '${exampleRoot.path}/build/unit_test_assets/fonts/'
      'MaterialIcons-Regular.otf',
    ),
  );
}

/// Allows only subpixel raster noise while preserving visual regression value.
class _TolerantReferenceGoldenComparator extends LocalFileComparator {
  _TolerantReferenceGoldenComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(precisionTolerance >= 0 && precisionTolerance <= 1),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
