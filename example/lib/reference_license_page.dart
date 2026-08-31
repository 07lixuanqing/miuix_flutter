part of 'main.dart';

/// Localized counterpart of the source sample's generated license route.
class _MiuixReferenceLicensePage extends StatefulWidget {
  const _MiuixReferenceLicensePage({
    this.showTopBar = true,
    this.enableBlur = false,
    this.enableScrollEndHaptic = true,
  });

  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_MiuixReferenceLicensePage> createState() =>
      _MiuixReferenceLicensePageState();
}

class _MiuixReferenceLicensePageState
    extends State<_MiuixReferenceLicensePage> {
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;
  late final Future<List<_ReferenceLicenseRecord>> _licenses;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollBehavior = MiuixTopAppBarScrollBehavior();
    _scrollBehavior.addListener(_handleTopBarChanged);
    _licenses = _loadReferenceLicenses();
  }

  void _handleTopBarChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _scrollBehavior
      ..removeListener(_handleTopBarChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 960;
    final topContentInset = _referenceTopContentInset(
      context,
      showTopBar: widget.showTopBar,
      wide: wide,
      scrollBehavior: wide ? null : _scrollBehavior,
    );
    // pageContentPadding() adds navigationBars only on the source wide-screen
    // branch. Compact Android deliberately draws the long list edge-to-edge
    // and relies solely on the independent final 12dp Spacer.
    final bottomContentInset = wide
        ? MediaQuery.viewPaddingOf(context).bottom
        : 0.0;
    final trackPadding = EdgeInsets.fromLTRB(
      0,
      topContentInset,
      0,
      bottomContentInset,
    );
    return MiuixScaffold(
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: '第三方许可证',
              glass: widget.enableBlur,
              large: !wide,
              scrollBehavior: wide ? null : _scrollBehavior,
              defaultWindowInsetsPadding: !wide,
              leading: MiuixIconButton(
                key: const ValueKey('licenses-back'),
                icon: Icon(
                  _miuixIcon('Back'),
                  color: MiuixSemanticColors.of(context)['onBackground'],
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: MiuixVerticalScrollBar(
        key: const ValueKey('reference-license-scrollbar'),
        controller: _scrollController,
        trackPadding: trackPadding,
        child: FutureBuilder<List<_ReferenceLicenseRecord>>(
          future: _licenses,
          builder: (context, snapshot) {
            final licenses = snapshot.data;
            if (licenses == null) {
              // The Compose page intentionally leaves its list empty while the
              // generated JSON is loading. Matching that behavior avoids adding
              // a progress indicator that is absent from the source example.
              return const SizedBox.expand();
            }
            return MiuixScrollEndHaptic(
              enabled: widget.enableScrollEndHaptic,
              child: Builder(
                builder: (context) {
                  final cardSpacing = _composeRoundedDimension(context, 12);
                  final preferenceHeight = _composeRoundedDimension(
                    context,
                    68,
                  );
                  final platform = Theme.of(context).platform;
                  final androidContentOffset =
                      platform == TargetPlatform.android
                      ? -_onePhysicalPixel(context)
                      : 0.0;
                  final latinFamily = _referenceLatinFontFamily(platform);
                  final titleLatinStyle = TextStyle(
                    fontFamily: latinFamily,
                    // Measured across 8, 10, 16, and 26-character source rows.
                    letterSpacing: platform == TargetPlatform.android
                        ? -.095
                        : null,
                  );
                  final summaryLatinStyle = TextStyle(
                    fontFamily: latinFamily,
                    // Compose and SkParagraph resolve the same Android system
                    // sans face with a repeatable per-size advance difference.
                    // Compensating per glyph preserves the source widths across
                    // short and long generated library names without resizing.
                    letterSpacing: platform == TargetPlatform.android
                        ? -.13
                        : null,
                  );
                  return ListView.builder(
                    key: const PageStorageKey('miuix-reference-licenses'),
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      0,
                      topContentInset,
                      0,
                      bottomContentInset,
                    ),
                    itemCount: licenses.length + 1,
                    itemBuilder: (context, index) {
                      if (index == licenses.length) {
                        return SizedBox(height: cardSpacing);
                      }
                      final library = licenses[index];
                      return Padding(
                        key: ValueKey(library.uniqueId),
                        padding: EdgeInsets.fromLTRB(
                          cardSpacing,
                          cardSpacing,
                          cardSpacing,
                          0,
                        ),
                        child: MiuixSurface(
                          radius: 16,
                          padding: EdgeInsets.zero,
                          color: MiuixSemanticColors.of(
                            context,
                          )['surfaceContainer'],
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: preferenceHeight,
                            ),
                            child: Transform.translate(
                              offset: Offset(0, androidContentOffset),
                              child: MiuixArrowPreference(
                                title: library.name,
                                summary:
                                    '${library.version}, ${library.license}',
                                titleStyle: titleLatinStyle,
                                summaryStyle: summaryLatinStyle,
                                onTap: library.website == null
                                    ? null
                                    : () => _openReferenceUrl(library.website!),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Reproduces Compose's per-dimension `roundToPx` before Flutter lays out.
///
/// At the Android reference density 12dp is 31.5 physical pixels. Compose
/// rounds that padding to 32 before adding the 68dp preference height, while
/// Flutter otherwise rounds the combined 80dp item to 210px. Snapping the
/// independent dimension prevents a one-pixel cumulative drift per row.
double _composeRoundedDimension(BuildContext context, double logicalPixels) {
  return _referenceRoundedDp(context, logicalPixels);
}

/// Returns one logical unit at the current physical device resolution.
double _onePhysicalPixel(BuildContext context) {
  final ratio = MediaQuery.devicePixelRatioOf(context);
  return ratio.isFinite && ratio > 0 ? 1 / ratio : 0;
}

/// Returns the platform UI Latin face used by the original Compose target.
String _referenceLatinFontFamily(TargetPlatform platform) => switch (platform) {
  // Compose does not set a family here, so Android resolves its current
  // system sans face rather than Flutter's legacy named Roboto family.
  TargetPlatform.android => 'sans-serif',
  TargetPlatform.windows => 'Segoe UI',
  TargetPlatform.iOS || TargetPlatform.macOS => '.AppleSystemUIFont',
  TargetPlatform.linux => 'sans-serif',
  TargetPlatform.fuchsia => 'Roboto',
};

/// Minimal display model matching the fields read from aboutlibraries.json.
class _ReferenceLicenseRecord {
  const _ReferenceLicenseRecord({
    required this.uniqueId,
    required this.name,
    required this.version,
    required this.license,
    this.website,
  });

  final String uniqueId;
  final String name;
  final String version;
  final String license;
  final String? website;
}

/// Reads the same generated inventory and fields consumed by LicensePage.kt.
Future<List<_ReferenceLicenseRecord>> _loadReferenceLicenses() async {
  final source = await rootBundle.loadString('assets/data/aboutlibraries.json');
  final document = jsonDecode(source) as Map<String, dynamic>;
  final libraries = document['libraries'] as List<dynamic>? ?? const [];
  return libraries
      .map((entry) {
        final library = entry as Map<String, dynamic>;
        final licenses = library['licenses'] as List<dynamic>? ?? const [];
        return _ReferenceLicenseRecord(
          uniqueId: library['uniqueId'] as String,
          name: library['name'] as String,
          version: library['artifactVersion'] as String,
          license: licenses.isEmpty ? 'null' : licenses.first as String,
          website: library['website'] as String?,
        );
      })
      .toList(growable: false);
}
