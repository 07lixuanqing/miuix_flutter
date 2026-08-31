import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_miuix/flutter_miuix.dart';

void main() {
  test('basic icon aliases use generated current-source vectors', () {
    const basicIcons = <IconData>[
      MiuixBasicIconCatalog.arrowRight,
      MiuixBasicIconCatalog.arrowUpDown,
      MiuixBasicIconCatalog.check,
      MiuixBasicIconCatalog.close,
      MiuixBasicIconCatalog.search,
      MiuixBasicIconCatalog.sidebar,
    ];

    expect(basicIcons.map((icon) => icon.codePoint).toSet(), hasLength(6));
    expect(
      basicIcons.every(
        (icon) =>
            icon.fontFamily == 'MiuixIconsBasic' &&
            icon.fontPackage == 'flutter_miuix',
      ),
      true,
    );
    expect(MiuixIcons.basic.arrowRight, MiuixBasicIconCatalog.arrowRight);
    expect(MiuixIcons.basic.arrowUpDown, MiuixBasicIconCatalog.arrowUpDown);
    expect(MiuixIcons.basic.check, MiuixBasicIconCatalog.check);
    expect(MiuixIcons.basic.close, MiuixBasicIconCatalog.close);
    expect(MiuixIcons.basic.search, MiuixBasicIconCatalog.search);
    expect(MiuixIcons.basic.sidebar, MiuixBasicIconCatalog.sidebar);
  });

  test('common extended aliases use regular MIUIX font glyphs', () {
    final aliases = <String, IconData>{
      'Add': MiuixIcons.extended.add,
      'Delete': MiuixIcons.extended.delete,
      'Home': MiuixIcons.extended.home,
      'Info': MiuixIcons.extended.info,
      'Location': MiuixIcons.extended.location,
      'More': MiuixIcons.extended.more,
      'Phone': MiuixIcons.extended.phone,
      'Refresh': MiuixIcons.extended.refresh,
      'Settings': MiuixIcons.extended.settings,
      'Share': MiuixIcons.extended.share,
      'Theme': MiuixIcons.extended.theme,
      'Update': MiuixIcons.extended.update,
    };

    for (final entry in aliases.entries) {
      expect(entry.value, MiuixExtendedIconCatalog.find(entry.key)!.regular);
      expect(entry.value.fontFamily, 'MiuixIconsRegular');
    }
  });

  test('extended icon catalogue contains every source icon and weight', () {
    expect(MiuixExtendedIconCatalog.all, hasLength(156));
    expect(MiuixExtendedIconCatalog.all.first.name, 'Add');
    expect(MiuixExtendedIconCatalog.find('Home'), isNotNull);
    expect(MiuixExtendedIconCatalog.all.last.name, 'ZoomOut');

    for (final icon in MiuixExtendedIconCatalog.all) {
      final weights = <IconData>[
        icon.light,
        icon.normal,
        icon.regular,
        icon.medium,
        icon.demibold,
      ];
      expect(weights.map((item) => item.codePoint).toSet(), hasLength(1));
      expect(weights.map((item) => item.fontFamily).toSet(), <String>{
        'MiuixIconsLight',
        'MiuixIconsNormal',
        'MiuixIconsRegular',
        'MiuixIconsMedium',
        'MiuixIconsDemibold',
      });
      expect(
        weights.every((item) => item.fontPackage == 'flutter_miuix'),
        true,
      );
    }
  });

  test('semantic palettes preserve complete 0.9.3 source constants', () {
    const light = MiuixSemanticColors.light();
    const dark = MiuixSemanticColors.dark();

    expect(light.values, hasLength(53));
    expect(dark.values, hasLength(53));
    expect(light['primary'], const Color(0xFF3482FF));
    expect(light['windowDimming'], const Color(0x4D000000));
    expect(light['sliderKeyPointForeground'], const Color(0xFF6EB5FF));
    expect(dark['primaryVariant'], const Color(0xFF0073DD));
    expect(dark['windowDimming'], const Color(0x99000000));
    expect(dark['sliderBackground'], const Color(0x26FFFFFF));
    expect(
      () => light['misspelledRole'],
      throwsA(
        isA<ArgumentError>().having(
          (error) => error.invalidValue,
          'invalidValue',
          'misspelledRole',
        ),
      ),
    );
  });

  testWidgets('Miuix theme installs its semantic color extension', (
    tester,
  ) async {
    late MiuixSemanticColors colors;
    await tester.pumpWidget(
      MiuixTheme(
        data: MiuixThemeData.defaults(mode: MiuixColorMode.dark),
        child: Builder(
          builder: (context) {
            colors = MiuixSemanticColors.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(colors['primary'], const Color(0xFF277AF7));
    // Fixed modes install the exact MIUIX semantic table rather than a lossy
    // Material ColorScheme round trip.
    expect(colors['surfaceContainerHighest'], const Color(0xFF2D2D2D));
  });

  test('generated schemes follow the upstream Monet role mapping', () {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4));
    final colors = MiuixSemanticColors.fromScheme(scheme);

    // MonetMapping.kt intentionally maps MIUIX secondary controls to outline
    // roles rather than Material secondary accents.
    expect(colors['primaryVariant'], scheme.primaryFixed);
    expect(colors['onPrimaryVariant'], scheme.onPrimaryFixed);
    expect(colors['secondary'], scheme.outlineVariant);
    expect(colors['onSecondary'], scheme.outline);
    expect(colors['secondaryVariant'], scheme.surfaceContainerHigh);
    expect(colors['onSecondaryVariant'], scheme.onSurface);

    // Disabled roles are composited to opaque colors over the source surface.
    expect(
      colors['disabledPrimary'],
      Color.alphaBlend(
        scheme.primary.withValues(alpha: .38),
        scheme.surface,
      ).withValues(alpha: 1),
    );
  });
}
