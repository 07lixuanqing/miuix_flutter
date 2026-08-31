part of 'main.dart';

/// Chinese version of the original color-token comparison page.
class _MiuixReferenceColorPage extends StatefulWidget {
  const _MiuixReferenceColorPage({
    required this.wide,
    required this.bottomContentInset,
    required this.platformDynamicLight,
    required this.platformDynamicDark,
    required this.showTopBar,
    required this.enableBlur,
  });

  final bool wide;
  final double bottomContentInset;
  final ColorScheme? platformDynamicLight;
  final ColorScheme? platformDynamicDark;
  final bool showTopBar;
  final bool enableBlur;

  @override
  State<_MiuixReferenceColorPage> createState() =>
      _MiuixReferenceColorPageState();
}

class _MiuixReferenceColorPageState extends State<_MiuixReferenceColorPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Source platformDynamicColors reads Android Monet roles directly and
    // falls back to the library's standard system Monet palette elsewhere.
    // Never synthesize a dynamic page by blending unrelated colors.
    final fallbackDynamicTheme = MiuixThemeData.defaults(
      mode: MiuixColorMode.monetSystem,
      seedColor: const Color(0xFF6750A4),
    );
    final dynamicLight =
        widget.platformDynamicLight ?? fallbackDynamicTheme.lightScheme;
    final dynamicDark =
        widget.platformDynamicDark ?? fallbackDynamicTheme.darkScheme;
    final groups = <({String title, MiuixSemanticColors colors})>[
      (title: '当前主题颜色', colors: MiuixSemanticColors.of(context)),
      (title: '浅色主题颜色', colors: const MiuixSemanticColors.light()),
      (title: '动态浅色颜色', colors: MiuixSemanticColors.fromScheme(dynamicLight)),
      (title: '深色主题颜色', colors: const MiuixSemanticColors.dark()),
      (title: '动态深色颜色', colors: MiuixSemanticColors.fromScheme(dynamicDark)),
    ];

    return _ReferencePageScaffold(
      title: '颜色',
      wide: widget.wide,
      showTopBar: widget.showTopBar,
      enableBlur: widget.enableBlur,
      bodyBuilder: (context, topContentInset) {
        return MiuixVerticalScrollBar(
          key: const ValueKey('reference-color-scrollbar'),
          controller: _scrollController,
          trackPadding: EdgeInsets.only(
            top: topContentInset,
            bottom: widget.bottomContentInset,
          ),
          child: ListView.builder(
            key: const PageStorageKey('miuix-reference-colors'),
            controller: _scrollController,
            padding: _referencePagePadding(
              context: context,
              bottomContentInset: widget.bottomContentInset,
              topContentInset: topContentInset,
            ),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MiuixSmallTitle(
                    group.title,
                    insideMargin: _referencePageSmallTitlePadding,
                  ),
                  MiuixCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    color: group.colors['surfaceContainer'],
                    child: _MiuixColorSchemePreview(colors: group.colors),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _MiuixColorSchemePreview extends StatelessWidget {
  const _MiuixColorSchemePreview({required this.colors});

  final MiuixSemanticColors colors;

  static const _roles = <String>[
    'primary',
    'onPrimary',
    'primaryVariant',
    'onPrimaryVariant',
    'error',
    'onError',
    'errorContainer',
    'onErrorContainer',
    'disabledPrimary',
    'disabledOnPrimary',
    'disabledPrimaryButton',
    'disabledOnPrimaryButton',
    'disabledPrimarySlider',
    'primaryContainer',
    'onPrimaryContainer',
    'secondary',
    'onSecondary',
    'secondaryVariant',
    'onSecondaryVariant',
    'disabledSecondary',
    'disabledOnSecondary',
    'disabledSecondaryVariant',
    'disabledOnSecondaryVariant',
    'secondaryContainer',
    'onSecondaryContainer',
    'secondaryContainerVariant',
    'onSecondaryContainerVariant',
    'tertiaryContainer',
    'onTertiaryContainer',
    'tertiaryContainerVariant',
    'background',
    'onBackground',
    'onBackgroundVariant',
    'surface',
    'onSurface',
    'surfaceVariant',
    'onSurfaceSecondary',
    'onSurfaceVariantSummary',
    'onSurfaceVariantActions',
    'disabledOnSurface',
    'surfaceContainer',
    'onSurfaceContainer',
    'onSurfaceContainerVariant',
    'surfaceContainerHigh',
    'onSurfaceContainerHigh',
    'surfaceContainerHighest',
    'onSurfaceContainerHighest',
    'outline',
    'dividerLine',
    'windowDimming',
    'sliderKeyPoint',
    'sliderKeyPointForeground',
  ];

  static const _localizedNames = <String, String>{
    'primary': '主色',
    'onPrimary': '主色上的内容',
    'primaryVariant': '主色变体',
    'onPrimaryVariant': '主色变体上的内容',
    'error': '错误色',
    'onError': '错误色上的内容',
    'errorContainer': '错误容器',
    'onErrorContainer': '错误容器上的内容',
    'disabledPrimary': '禁用主色',
    'disabledOnPrimary': '禁用主色上的内容',
    'disabledPrimaryButton': '禁用主色\n按钮',
    'disabledOnPrimaryButton': '禁用按钮上的\n内容',
    'disabledPrimarySlider': '滑块禁用\n主色',
    'primaryContainer': '主色容器',
    'onPrimaryContainer': '主色容器上的\n内容',
    'secondary': '次要色',
    'onSecondary': '次要色上的内容',
    'secondaryVariant': '次要色变体',
    'onSecondaryVariant': '次要色变体上的\n内容',
    'disabledSecondary': '禁用次要色',
    'disabledOnSecondary': '禁用次要色上的\n内容',
    'disabledSecondaryVariant': '禁用次要色\n变体',
    'disabledOnSecondaryVariant': '禁用次要变体\n上的内容',
    'secondaryContainer': '次要色\n容器',
    'onSecondaryContainer': '次要色容器上的\n内容',
    'secondaryContainerVariant': '次要色容器\n变体',
    'onSecondaryContainerVariant': '次要容器变体\n上的内容',
    'tertiaryContainer': '第三色容器',
    'onTertiaryContainer': '第三色容器上的\n内容',
    'tertiaryContainerVariant': '第三色容器\n变体',
    'background': '背景',
    'onBackground': '背景上的内容',
    'onBackgroundVariant': '背景上的内容\n变体',
    'surface': '表面',
    'onSurface': '表面上的内容',
    'surfaceVariant': '表面变体',
    'onSurfaceSecondary': '表面上的\n次要内容',
    'onSurfaceVariantSummary': '表面变体\n摘要内容',
    'onSurfaceVariantActions': '表面变体\n操作内容',
    'disabledOnSurface': '表面上的禁用内容',
    'surfaceContainer': '表面容器',
    'onSurfaceContainer': '表面容器上的\n内容',
    'onSurfaceContainerVariant': '表面容器内容\n变体',
    'surfaceContainerHigh': '高层表面\n容器',
    'onSurfaceContainerHigh': '高层表面容器\n上的内容',
    'surfaceContainerHighest': '最高层表面\n容器',
    'onSurfaceContainerHighest': '最高层表面容器\n上的内容',
    'outline': '轮廓线',
    'dividerLine': '分隔线',
    'windowDimming': '窗口遮罩',
    'sliderKeyPoint': '滑块关键点',
    'sliderKeyPointForeground': '滑块关键点\n前景',
  };

  @override
  Widget build(BuildContext context) {
    // In ColorsPreview.kt, `height(100.dp)` and the following 16 dp padding
    // are separate modifiers. Compose therefore rounds both measurements
    // independently. Keeping a literal 100 logical pixels lets Flutter
    // alternate 262/263 physical-pixel rows at 420 dpi and accumulates a
    // visible upward drift down the long color table.
    final sourceBlockHeight = _referenceRoundedDp(context, 100);
    final blocks = <({String role, Color color, Color foreground})>[];
    for (final role in _roles) {
      final color = colors[role];
      final counterpart = role.startsWith('on')
          ? '${role[2].toLowerCase()}${role.substring(3)}'
          : 'on${role[0].toUpperCase()}${role.substring(1)}';
      final paired = colors.values[counterpart];
      blocks.add((
        role: role,
        color: color,
        foreground:
            paired ??
            (color.computeLuminance() > .5 ? Colors.black : Colors.white),
      ));
    }

    Widget buildBlock(({String role, Color color, Color foreground}) entry) {
      // ColorBlock passes an explicit RoundedCornerShape(12.dp) to Surface.
      // It does not use the optional global G2/MIUIX shape.
      return Container(
        key: ValueKey('color-role-${entry.role}'),
        height: sourceBlockHeight,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: entry.color,
          border: Border.all(color: entry.foreground, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          _localizedNames[entry.role] ?? entry.role,
          textAlign: TextAlign.center,
          // ColorsPreview.kt uses the ordinary MIUIX Text role, whose default
          // is Main at 17sp rather than Body2 at 14sp.
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: entry.foreground,
            fontSize: 17,
          ),
        ),
      );
    }

    // Compose applies weight before the first child's 16dp end padding. The
    // two outer slots are equal, but the first visible swatch is therefore
    // 16dp narrower than the second. A final odd swatch receives the only
    // Expanded slot and fills the complete row.
    return Column(
      children: [
        for (var index = 0; index < blocks.length; index += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index + 1 < blocks.length ? 16 : 0,
                    ),
                    child: buildBlock(blocks[index]),
                  ),
                ),
                if (index + 1 < blocks.length)
                  Expanded(child: buildBlock(blocks[index + 1])),
              ],
            ),
          ),
      ],
    );
  }
}
