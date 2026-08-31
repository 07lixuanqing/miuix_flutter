part of 'main.dart';

/// Reconstructs `systemMd3Roles()` from Android's system color resources.
///
/// Android 12 and 12L do not expose the secure palette metadata used on newer
/// releases. The original MIUIX implementation reads five system tonal
/// families and maps their roles directly instead of regenerating a palette
/// from one accent. The native bridge returns those families; this function
/// performs the same HCT tone adjustments and role selection in Dart.
@visibleForTesting
ColorScheme? debugReferenceAndroidSystemScheme(
  Map<String, dynamic>? message, {
  required bool dark,
}) {
  final rawPalette = message?['systemPalette'];
  if (rawPalette is! Map) return null;
  final rawTones = rawPalette['tones'];
  if (rawTones is! List) return null;
  final tones = rawTones
      .whereType<num>()
      .map((value) => value.toInt())
      .toList();
  if (tones.isEmpty) return null;

  Map<int, Color>? readFamily(String name) {
    final rawColors = rawPalette[name];
    if (rawColors is! List || rawColors.length != tones.length) return null;
    final result = <int, Color>{};
    for (var index = 0; index < tones.length; index++) {
      final rawColor = rawColors[index];
      if (rawColor is! num) return null;
      result[tones[index]] = Color(rawColor.toInt());
    }
    return result;
  }

  final accent1 = readFamily('accent1');
  final accent2 = readFamily('accent2');
  final accent3 = readFamily('accent3');
  final neutral1 = readFamily('neutral1');
  final neutral2 = readFamily('neutral2');
  if (accent1 == null ||
      accent2 == null ||
      accent3 == null ||
      neutral1 == null ||
      neutral2 == null) {
    return null;
  }

  Color role(Map<int, Color> family, int tone) => family[tone]!;
  Color toneFrom(Color base, double tone) {
    final hct = monet.Hct.fromInt(base.toARGB32());
    return Color(monet.Hct.from(hct.hue, hct.chroma, tone).toInt());
  }

  Color a1(int tone) => role(accent1, tone);
  Color a2(int tone) => role(accent2, tone);
  Color a3(int tone) => role(accent3, tone);
  Color n1(int tone) => role(neutral1, tone);
  Color n2(int tone) => role(neutral2, tone);

  // DynamicColors.android.kt changes its neutral-resource mapping at API 34.
  final sdk = (message?['sdk'] as num?)?.toInt() ?? 31;
  final modern = sdk >= 34;
  late final Color primary;
  late final Color onPrimary;
  late final Color primaryFixed;
  late final Color onPrimaryFixed;
  late final Color primaryContainer;
  late final Color onPrimaryContainer;
  late final Color secondary;
  late final Color onSecondary;
  late final Color secondaryContainer;
  late final Color onSecondaryContainer;
  late final Color tertiaryContainer;
  late final Color onTertiaryContainer;
  late final Color background;
  late final Color onBackground;
  late final Color surfaceVariant;
  late final Color surfaceContainer;
  late final Color surfaceContainerHigh;
  late final Color surfaceContainerHighest;
  late final Color outline;
  late final Color outlineVariant;
  late final Color onSurfaceVariant;

  if (!dark) {
    primary = a1(600);
    onPrimary = a1(0);
    primaryFixed = a1(200);
    onPrimaryFixed = a1(0);
    primaryContainer = a1(100);
    onPrimaryContainer = a1(900);
    secondary = a2(600);
    onSecondary = a2(0);
    secondaryContainer = a2(100);
    onSecondaryContainer = a2(900);
    tertiaryContainer = a3(100);
    onTertiaryContainer = a3(900);
    if (modern) {
      background = toneFrom(n1(100), 98);
      onBackground = toneFrom(n1(100), 10);
      surfaceVariant = toneFrom(n2(200), 90);
      surfaceContainer = toneFrom(n1(100), 94);
      surfaceContainerHigh = toneFrom(n1(100), 92);
      surfaceContainerHighest = toneFrom(n1(100), 90);
      outline = toneFrom(n2(200), 50);
      outlineVariant = toneFrom(n2(200), 80);
      onSurfaceVariant = toneFrom(n2(200), 30);
    } else {
      final neutralVariantBase = n2(600);
      background = toneFrom(neutralVariantBase, 98);
      onBackground = n2(900);
      surfaceVariant = n2(100);
      surfaceContainer = toneFrom(neutralVariantBase, 94);
      surfaceContainerHigh = toneFrom(neutralVariantBase, 92);
      surfaceContainerHighest = n2(100);
      outline = n2(500);
      outlineVariant = n2(200);
      onSurfaceVariant = n2(700);
    }
  } else {
    primary = a1(200);
    onPrimary = a1(800);
    primaryFixed = a1(200);
    onPrimaryFixed = a1(800);
    primaryContainer = a1(700);
    onPrimaryContainer = a1(100);
    secondary = a2(200);
    onSecondary = a2(800);
    secondaryContainer = a2(700);
    onSecondaryContainer = a2(100);
    tertiaryContainer = a3(700);
    onTertiaryContainer = a3(100);
    if (modern) {
      background = toneFrom(n1(10), 6);
      onBackground = toneFrom(n1(10), 90);
      surfaceVariant = toneFrom(n2(700), 30);
      surfaceContainer = toneFrom(n1(10), 12);
      surfaceContainerHigh = toneFrom(n1(10), 17);
      surfaceContainerHighest = toneFrom(n1(10), 22);
      outline = toneFrom(n2(700), 60);
      outlineVariant = toneFrom(n2(700), 30);
      onSurfaceVariant = toneFrom(n2(700), 80);
    } else {
      final neutralVariantBase = n2(600);
      background = toneFrom(neutralVariantBase, 6);
      onBackground = n2(100);
      surfaceVariant = n2(700);
      surfaceContainer = toneFrom(neutralVariantBase, 12);
      surfaceContainerHigh = toneFrom(neutralVariantBase, 17);
      surfaceContainerHighest = toneFrom(neutralVariantBase, 22);
      outline = n2(400);
      outlineVariant = n2(700);
      onSurfaceVariant = n2(200);
    }
  }

  const lightError = Color(0xFFB3261E);
  final errorContainer = dark
      ? const Color(0xFF8C1D18)
      : const Color(0xFFF9DEDC);
  final onErrorContainer = dark
      ? const Color(0xFFF9DEDC)
      : const Color(0xFF410E0B);
  final brightness = dark ? Brightness.dark : Brightness.light;
  final generated = ColorScheme.fromSeed(
    seedColor: a1(500),
    brightness: brightness,
  );

  return generated.copyWith(
    primary: primary,
    onPrimary: onPrimary,
    primaryFixed: primaryFixed,
    onPrimaryFixed: onPrimaryFixed,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: lightError,
    onError: Colors.white,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
    surface: background,
    onSurface: onBackground,
    surfaceDim: background,
    surfaceBright: background,
    surfaceContainerLowest: background,
    surfaceContainerLow: surfaceContainer,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    outlineVariant: outlineVariant,
    surfaceTint: primary,
    // These deprecated Material aliases remain distinct inputs to the source
    // MIUIX Monet role mapping.
    // ignore: deprecated_member_use
    background: background,
    // ignore: deprecated_member_use
    onBackground: onBackground,
    // ignore: deprecated_member_use
    surfaceVariant: surfaceVariant,
  );
}
