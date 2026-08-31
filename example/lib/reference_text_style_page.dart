part of 'main.dart';

/// Localized reconstruction of the current upstream `TextStylePage`.
///
/// The role names stay in English because they are public design-token names;
/// all descriptive user-facing copy and section labels are translated.
class _MiuixReferenceTextStylePage extends StatefulWidget {
  const _MiuixReferenceTextStylePage({
    required this.wide,
    required this.bottomContentInset,
    required this.showTopBar,
    required this.enableBlur,
  });

  final bool wide;
  final double bottomContentInset;
  final bool showTopBar;
  final bool enableBlur;

  @override
  State<_MiuixReferenceTextStylePage> createState() =>
      _MiuixReferenceTextStylePageState();
}

class _MiuixReferenceTextStylePageState
    extends State<_MiuixReferenceTextStylePage> {
  static const _chineseSample = '天地玄黄 宇宙洪荒';
  static const _englishSample = 'The Quick Brown Fox Jumps';
  static const _numberSample = r'0123456789 !@#$%&';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context).textTheme;
    final styles = <_ReferenceTextStyleEntry>[
      _ReferenceTextStyleEntry('title1', '32sp', theme.displayLarge!),
      _ReferenceTextStyleEntry('title2', '24sp', theme.displayMedium!),
      _ReferenceTextStyleEntry('title3', '20sp', theme.displaySmall!),
      _ReferenceTextStyleEntry('title4', '18sp', theme.headlineMedium!),
      _ReferenceTextStyleEntry('headline1', '17sp', theme.titleLarge!),
      _ReferenceTextStyleEntry('headline2', '16sp', theme.titleMedium!),
      _ReferenceTextStyleEntry('subtitle', '14sp / 粗体', theme.titleSmall!),
      _ReferenceTextStyleEntry('main', '17sp', theme.bodyLarge!),
      _ReferenceTextStyleEntry(
        'paragraph',
        '17sp / 行高 1.2em',
        theme.bodyLarge!.copyWith(height: 1.2),
      ),
      _ReferenceTextStyleEntry('body1', '16sp', theme.bodyMedium!),
      _ReferenceTextStyleEntry('body2', '14sp', theme.bodySmall!),
      _ReferenceTextStyleEntry('button', '17sp', theme.labelLarge!),
      _ReferenceTextStyleEntry('footnote1', '13sp', theme.labelMedium!),
      _ReferenceTextStyleEntry('footnote2', '11sp', theme.labelSmall!),
    ];
    final sections = <_ReferenceTextStyleSection>[
      _ReferenceTextStyleSection('标题样式', styles.sublist(0, 4)),
      _ReferenceTextStyleSection('大标题样式', styles.sublist(4, 6)),
      _ReferenceTextStyleSection('正文样式', styles.sublist(6, 12)),
      _ReferenceTextStyleSection('脚注样式', styles.sublist(12, 14)),
      _ReferenceTextStyleSection('全部样式概览', styles),
    ];

    return _ReferencePageScaffold(
      title: '文本样式',
      wide: widget.wide,
      showTopBar: widget.showTopBar,
      enableBlur: widget.enableBlur,
      bodyBuilder: (context, topContentInset) {
        return MiuixVerticalScrollBar(
          key: const ValueKey('reference-text-style-scrollbar'),
          controller: _scrollController,
          trackPadding: EdgeInsets.only(
            top: topContentInset,
            bottom: widget.bottomContentInset,
          ),
          child: ListView.builder(
            key: const PageStorageKey('miuix-reference-text-styles'),
            controller: _scrollController,
            padding: _referencePagePadding(
              context: context,
              bottomContentInset: widget.bottomContentInset,
              topContentInset: topContentInset,
            ),
            itemCount: sections.length,
            itemBuilder: (context, index) =>
                _ReferenceTextStyleSectionCard(section: sections[index]),
          ),
        );
      },
    );
  }
}

@immutable
class _ReferenceTextStyleEntry {
  const _ReferenceTextStyleEntry(this.name, this.description, this.style);

  final String name;
  final String description;
  final TextStyle style;
}

@immutable
class _ReferenceTextStyleSection {
  const _ReferenceTextStyleSection(this.title, this.entries);

  final String title;
  final List<_ReferenceTextStyleEntry> entries;
}

class _ReferenceTextStyleSectionCard extends StatelessWidget {
  const _ReferenceTextStyleSectionCard({required this.section});

  final _ReferenceTextStyleSection section;

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final textTheme = MiuixTheme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MiuixSmallTitle(
          section.title,
          insideMargin: _referencePageSmallTitlePadding,
        ),
        MiuixCard(
          key: ValueKey('reference-text-style-${section.title}-card'),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: semantic['surfaceContainer'],
          cornerRadius: 16,
          child: Column(
            children: [
              for (var index = 0; index < section.entries.length; index++) ...[
                _ReferenceTextStyleItem(
                  entry: section.entries[index],
                  labelStyle: textTheme.labelMedium!,
                  descriptionStyle: textTheme.labelSmall!,
                  foreground: semantic['onSurface'],
                  summaryForeground: semantic['onSurfaceVariantSummary'],
                ),
                if (index != section.entries.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2),
                    child: MiuixHorizontalDivider(),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReferenceTextStyleItem extends StatelessWidget {
  const _ReferenceTextStyleItem({
    required this.entry,
    required this.labelStyle,
    required this.descriptionStyle,
    required this.foreground,
    required this.summaryForeground,
  });

  final _ReferenceTextStyleEntry entry;
  final TextStyle labelStyle;
  final TextStyle descriptionStyle;
  final Color foreground;
  final Color summaryForeground;

  @override
  Widget build(BuildContext context) {
    // Every upstream role except Paragraph leaves lineHeight unspecified. The
    // package theme deliberately fixes ordinary component text to the measured
    // 1.16em line box, but this page demonstrates the raw typography tokens:
    // restore natural Roboto/CJK metrics here and retain Paragraph's authored
    // 1.2em override. `kTextHeightNone` is Flutter's explicit null-height
    // sentinel and therefore survives TextStyle.copyWith.
    final chineseSampleStyle = entry.name == 'paragraph'
        ? entry.style
        : entry.style.copyWith(height: ui.kTextHeightNone);
    // Compose and Flutter resolve the same Roboto face to slightly different
    // natural line boxes. These source-measured factors retain the native
    // 420dpi placeables while CJK keeps its naturally taller fallback metrics.
    final latinHeight = switch (entry.name) {
      'paragraph' => 1.2,
      'title1' || 'title3' || 'title4' => 1.18,
      _ => 1.16,
    };
    final latinSampleStyle = entry.style.copyWith(height: latinHeight);
    final physicalPixel = 1 / MediaQuery.devicePixelRatioOf(context);
    // Flutter and Compose round the three mixed-script line boxes at different
    // stages. Keep the authored 10dp top inset, then compensate only the final
    // bottom slack so every following divider and item starts on the native
    // physical row without moving any visible sample baseline.
    final bottomMetricCorrection = switch (entry.name) {
      'title1' || 'title2' => 3 * physicalPixel,
      'title3' => 4 * physicalPixel,
      'title4' => -2 * physicalPixel,
      'headline1' || 'main' => 4 * physicalPixel,
      'headline2' => 1 * physicalPixel,
      'subtitle' => -1 * physicalPixel,
      'paragraph' => -5 * physicalPixel,
      'body1' => 2 * physicalPixel,
      'button' => 3 * physicalPixel,
      _ => 0.0,
    };
    return Padding(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 10 - bottomMetricCorrection),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: labelStyle.copyWith(color: foreground),
                ),
              ),
              Text(
                entry.description,
                style: descriptionStyle.copyWith(color: summaryForeground),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _MiuixReferenceTextStylePageState._chineseSample,
            style: chineseSampleStyle.copyWith(color: foreground),
          ),
          const SizedBox(height: 2),
          Text(
            _MiuixReferenceTextStylePageState._englishSample,
            style: latinSampleStyle.copyWith(color: foreground),
          ),
          const SizedBox(height: 2),
          Text(
            _MiuixReferenceTextStylePageState._numberSample,
            style: latinSampleStyle.copyWith(color: summaryForeground),
          ),
        ],
      ),
    );
  }
}
