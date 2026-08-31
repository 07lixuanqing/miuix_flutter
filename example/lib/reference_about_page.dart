part of 'main.dart';

/// Localized reconstruction of the upstream example's dedicated About route.
///
/// The page deliberately remains outside the five-root-page pager. This
/// matches the source navigator: entering About covers the root shell, gives
/// the route its own compact top bar, and returns to the exact settings scroll
/// position when popped.
class _MiuixReferenceAboutPage extends StatefulWidget {
  const _MiuixReferenceAboutPage({
    this.showTopBar = true,
    this.enableBlur = false,
    this.enableScrollEndHaptic = true,
  });

  final bool showTopBar;
  final bool enableBlur;
  final bool enableScrollEndHaptic;

  @override
  State<_MiuixReferenceAboutPage> createState() =>
      _MiuixReferenceAboutPageState();
}

class _MiuixReferenceAboutPageState extends State<_MiuixReferenceAboutPage>
    with TickerProviderStateMixin {
  // On the 420 dpi reference phone the source spacer ends at y=1198 px.
  // The list starts at 200 px, so its exact logical height is 380 dp.
  static const double _logoSectionHeight = 380;
  // Kotlin divides the first item's scroll offset by that measured spacer
  // height. Using a longer independent range left 11.6% of the animated
  // background visible after the page had already reached its scroll limit.
  static const double _collapseDistance = _logoSectionHeight;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _identityGeometryKey = GlobalKey();
  final GlobalKey _iconGeometryKey = GlobalKey();
  final GlobalKey _nameGeometryKey = GlobalKey();
  final GlobalKey _versionGeometryKey = GlobalKey();
  late final _ReferenceEffectBackgroundController _backgroundMotion;
  ui.FragmentShader? _effectBackgroundShader;
  double _scrollProgress = 0;
  double _iconProgress = 0;
  double _nameProgress = 0;
  double _versionProgress = 0;
  double? _identityHeight;
  double? _logoAreaBottom;
  double? _iconBottom;
  double? _nameBottom;
  double? _versionBottom;
  bool _geometryCaptureScheduled = false;
  bool _isOs3Effect = true;
  bool _dynamicBackground = true;
  bool _fullScreenBackground = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _backgroundMotion = _ReferenceEffectBackgroundController(
      vsync: this,
      dynamic: _dynamicBackground,
      os3: _isOs3Effect,
    );
    unawaited(_loadEffectBackgroundShader());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: _dynamicBackground,
      os3: _isOs3Effect,
    );
  }

  Future<void> _loadEffectBackgroundShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'shaders/miuix_effect_background.frag',
    );
    if (!mounted) return;
    setState(() => _effectBackgroundShader = program.fragmentShader());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _backgroundMotion.dispose();
    _effectBackgroundShader?.dispose();
    super.dispose();
  }

  void _setDynamicBackground(bool value) {
    _dynamicBackground = value;
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: value,
      os3: _isOs3Effect,
    );
  }

  void _setEffectVariant(int index) {
    _isOs3Effect = index == 1;
    _backgroundMotion.configure(
      brightness: Theme.of(context).brightness,
      dynamic: _dynamicBackground,
      os3: _isOs3Effect,
    );
  }

  void _handleScroll() {
    _captureIdentityGeometry();
    final offset = _scrollController.offset;
    final collapseDistance =
        _identityHeight ?? _referenceRoundedDp(context, _collapseDistance);
    final scrollProgress = (offset / collapseDistance).clamp(0.0, 1.0);

    // AboutPage.kt records the first global bottom coordinate of every
    // identity element and derives three consecutive disappearance stages.
    // These stages are not fixed percentages of the full logo spacer.
    var versionProgress = 0.0;
    var nameProgress = 0.0;
    var iconProgress = 0.0;
    final logoBottom = _logoAreaBottom;
    final versionBottom = _versionBottom;
    final nameBottom = _nameBottom;
    final iconBottom = _iconBottom;
    if (logoBottom != null &&
        versionBottom != null &&
        nameBottom != null &&
        iconBottom != null) {
      final stage1 = math.max(1.0, logoBottom - versionBottom);
      final stage2 = math.max(1.0, versionBottom - nameBottom);
      final stage3 = math.max(1.0, nameBottom - iconBottom);
      final versionDelay = stage1 * .5;
      versionProgress =
          ((offset - versionDelay) / math.max(1.0, stage1 - versionDelay))
              .clamp(0.0, 1.0);
      nameProgress = ((offset - stage1) / stage2).clamp(0.0, 1.0);
      iconProgress = ((offset - stage1 - stage2) / stage3).clamp(0.0, 1.0);
    }

    final changed =
        (scrollProgress - _scrollProgress).abs() > .001 ||
        (versionProgress - _versionProgress).abs() > .001 ||
        (nameProgress - _nameProgress).abs() > .001 ||
        (iconProgress - _iconProgress).abs() > .001;
    if (changed && mounted) {
      setState(() {
        _scrollProgress = scrollProgress;
        _versionProgress = versionProgress;
        _nameProgress = nameProgress;
        _iconProgress = iconProgress;
      });
    }
  }

  /// Captures the same first-frame window coordinates used by Compose.
  ///
  /// The upstream `onGloballyPositioned` callbacks keep the first bottom
  /// position for the icon, project name and version. `logoAreaY` is then
  /// frozen on the first scroll observation. Capturing all four after Flutter
  /// layout gives the same stage lengths without hard-coding one phone's text
  /// metrics.
  void _captureIdentityGeometry() {
    if (_logoAreaBottom != null) {
      return;
    }
    RenderBox? boxFor(GlobalKey key) =>
        key.currentContext?.findRenderObject() as RenderBox?;
    final identity = boxFor(_identityGeometryKey);
    final icon = boxFor(_iconGeometryKey);
    final name = boxFor(_nameGeometryKey);
    final version = boxFor(_versionGeometryKey);
    if (identity == null ||
        icon == null ||
        name == null ||
        version == null ||
        !identity.hasSize ||
        !icon.hasSize ||
        !name.hasSize ||
        !version.hasSize) {
      _scheduleIdentityGeometryCapture();
      return;
    }
    double bottom(RenderBox box) =>
        box.localToGlobal(Offset(0, box.size.height)).dy;
    _identityHeight = identity.size.height;
    _logoAreaBottom = bottom(identity);
    _iconBottom = bottom(icon);
    _nameBottom = bottom(name);
    _versionBottom = bottom(version);
  }

  void _scheduleIdentityGeometryCapture() {
    if (_geometryCaptureScheduled) {
      return;
    }
    _geometryCaptureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _geometryCaptureScheduled = false;
      if (mounted) {
        _captureIdentityGeometry();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleIdentityGeometryCapture();
    final scheme = Theme.of(context).colorScheme;
    // Capture window insets above Scaffold. Its body rewrites MediaQuery
    // padding, while the source route uses the original window values.
    final windowPadding = MediaQuery.paddingOf(context);
    final topContentPadding =
        windowPadding.top + _referenceRoundedDp(context, 52);
    final bottomContentPadding =
        windowPadding.bottom + _referenceRoundedDp(context, 12);
    final sourceLogoSectionHeight = _referenceRoundedDp(
      context,
      _logoSectionHeight,
    );
    final sourceCardSpacing = _referenceRoundedDp(context, 12);
    final titleAlpha = ((_scrollProgress - .35) / .65).clamp(0.0, 1.0);
    final collapsed = _scrollProgress >= .999;
    return MiuixScaffold(
      backgroundColor: scheme.surface,
      // AboutPage.kt always owns its compact bar; the global visibility flag
      // only applies to AdaptiveTopAppBar routes such as Licenses.
      topBar: MiuixSmallTopAppBar(
        title: '关于',
        // AboutPage.kt activates BlurredBar only after the logo spacer has
        // fully collapsed. Applying the filter on the initial transparent bar
        // also erases the route body inside Flutter's transition saveLayer.
        glass: widget.enableBlur && collapsed,
        color: collapsed ? scheme.surface : Colors.transparent,
        titleColor: scheme.onSurface.withValues(alpha: titleAlpha),
        leading: MiuixIconButton(
          key: const ValueKey('about-back'),
          // BackNavigationIcon.kt tints the glyph explicitly; IconButton does
          // not provide a content color for its arbitrary source slot.
          icon: Icon(
            _miuixIcon('Back'),
            color: MiuixSemanticColors.of(context)['onBackground'],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 1 - _scrollProgress,
                child: AnimatedBuilder(
                  animation: _backgroundMotion,
                  builder: (context, child) => CustomPaint(
                    painter: _ReferenceEffectBackgroundPainter(
                      scheme: Theme.of(context).colorScheme,
                      elapsedSeconds: _backgroundMotion.elapsedSeconds,
                      colorStage: _backgroundMotion.stage,
                      shader: _effectBackgroundShader,
                      // AboutPage.kt defaults to a full-size background and
                      // exposes the original compact 78% variant in its sheet.
                      heightFraction: _fullScreenBackground ? 1 : .78,
                      os3: _isOs3Effect,
                    ),
                  ),
                ),
              ),
            ),
          ),
          MiuixVerticalScrollBar(
            key: const ValueKey('reference-about-scrollbar'),
            controller: _scrollController,
            trackPadding: EdgeInsets.only(
              top: topContentPadding,
              bottom: windowPadding.bottom,
            ),
            child: MiuixScrollEndHaptic(
              enabled: widget.enableScrollEndHaptic,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // AboutPage.kt places the cards in a Column using
                  // fillParentMaxHeight(). That second full-height list item is
                  // what makes the 380dp identity spacer collapsible even when
                  // the four preference rows would otherwise fit on screen.
                  final contentPageHeight = math
                      .max(0.0, constraints.maxHeight - topContentPadding)
                      .toDouble();
                  return ListView(
                    key: const PageStorageKey('miuix-reference-about'),
                    controller: _scrollController,
                    padding: EdgeInsets.only(top: topContentPadding),
                    children: [
                      Builder(
                        builder: (popupContext) => GestureDetector(
                          key: const ValueKey('about-identity'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _showBackgroundEffectSheet(popupContext),
                          child: SizedBox(
                            key: _identityGeometryKey,
                            height: sourceLogoSectionHeight,
                            child: _buildIdentity(context),
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: contentPageHeight,
                        ),
                        child: Column(
                          children: [
                            _buildLinksCard(context),
                            SizedBox(height: sourceCardSpacing),
                            _buildLicensesCard(context),
                            SizedBox(height: bottomContentPadding),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final semantic = MiuixSemanticColors.of(context);
    final sourceTopPadding = _referenceRoundedDp(context, 92);
    final sourceNameTopPadding = _referenceRoundedDp(context, 12);
    final sourceNameBottomPadding = _referenceRoundedDp(context, 5);
    return Padding(
      // Source layout adds 52dp after its top-aware 40dp content padding.
      // Because this list already starts below the 52dp bar, 92dp here puts
      // the 88dp logo at the same absolute 144dp top coordinate.
      padding: EdgeInsets.only(top: sourceTopPadding),
      child: Column(
        children: [
          Opacity(
            key: const ValueKey('about-icon-opacity'),
            opacity: 1 - _iconProgress,
            child: Transform.scale(
              scale: 1 - _iconProgress * .05,
              child: KeyedSubtree(
                key: _iconGeometryKey,
                child: const _ReferenceAppIcon(),
              ),
            ),
          ),
          SizedBox(height: sourceNameTopPadding),
          Opacity(
            key: const ValueKey('about-name-opacity'),
            opacity: 1 - _nameProgress,
            child: Transform.scale(
              scale: 1 - _nameProgress * .05,
              child: KeyedSubtree(
                key: _nameGeometryKey,
                child: MiuixForegroundBlurText(
                  text: 'Miuix for Compose',
                  width: 330,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                  ),
                  backdrop: MiuixBackdrop(
                    // AboutPage.kt uses textureBlur(blurRadius = 150f) for
                    // the project-name foreground mask. Keep this literal at
                    // the source value: the component performs the same
                    // radius-to-sigma conversion internally.
                    blur: 150,
                    noise: _referenceFloat32(.0045),
                    enabled: widget.enableBlur,
                    colors: MiuixBlurColors(
                      tint: Colors.transparent,
                      border: Colors.transparent,
                      opacity: 0,
                      blendColors: _logoBlend(
                        Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                  ),
                  fallbackGradient: _referenceLogoFallbackGradient(
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: sourceNameBottomPadding),
          Opacity(
            key: const ValueKey('about-version-opacity'),
            opacity: 1 - _versionProgress,
            child: Transform.scale(
              scale: 1 - _versionProgress * .05,
              child: KeyedSubtree(
                key: _versionGeometryKey,
                child: Text(
                  _referenceSourceVersionLabel,
                  style: TextStyle(
                    color: semantic['onSurfaceVariantSummary'],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackgroundEffectSheet(BuildContext popupContext) {
    MiuixOverlayBottomSheet.show<void>(
      context: popupContext,
      title: '背景效果',
      // The source About page explicitly requests a zero inside margin.
      insideMargin: EdgeInsets.zero,
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void update(VoidCallback change) {
            setState(change);
            setSheetState(() {});
          }

          return ListView(
            key: const ValueKey('about-background-controls'),
            shrinkWrap: true,
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(sheetContext).bottom,
            ),
            children: [
              MiuixOverlayDropdownPreference.source(
                title: '效果版本',
                items: const ['OS2', 'OS3'],
                selectedIndex: _isOs3Effect ? 1 : 0,
                onSelectedIndexChange: (index) =>
                    update(() => _setEffectVariant(index)),
              ),
              MiuixSwitchPreference.source(
                title: '动态背景',
                checked: _dynamicBackground,
                onCheckedChange: (value) =>
                    update(() => _setDynamicBackground(value)),
              ),
              MiuixSwitchPreference.source(
                title: '全屏背景',
                checked: _fullScreenBackground,
                onCheckedChange: (value) =>
                    update(() => _fullScreenBackground = value),
              ),
            ],
          );
        },
      ),
    );
  }

  MiuixBackdrop _aboutCardBackdrop(BuildContext context) {
    return MiuixBackdrop(
      blur: 60,
      noise: _referenceFloat32(.0045),
      enabled: widget.enableBlur,
      colors: MiuixBlurColors(
        tint: Colors.transparent,
        border: Colors.transparent,
        opacity: 0,
        blendColors: _referenceAboutBlendConfigs(context).first.entries,
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return _ReferenceAboutCard(
      key: const ValueKey('reference-about-links-card'),
      backdrop: _aboutCardBackdrop(context),
      children: [
        MiuixArrowPreference(
          title: '查看源代码',
          secondaryAction: Text(
            'GitHub',
            style: _referenceActionTextStyle(context),
          ),
          onTap: () =>
              _openReferenceUrl('https://github.com/compose-miuix-ui/miuix'),
        ),
        MiuixArrowPreference(
          title: '加入群组',
          secondaryAction: Text(
            'Telegram',
            style: _referenceActionTextStyle(context),
          ),
          onTap: () => _openReferenceUrl('https://t.me/YuKongA13579'),
        ),
      ],
    );
  }

  Widget _buildLicensesCard(BuildContext context) {
    return _ReferenceAboutCard(
      key: const ValueKey('reference-about-licenses-card'),
      backdrop: _aboutCardBackdrop(context),
      children: [
        MiuixArrowPreference(
          title: '许可证',
          secondaryAction: Text(
            'Apache-2.0',
            style: _referenceActionTextStyle(context),
          ),
          onTap: () => _openReferenceUrl(
            'https://www.apache.org/licenses/LICENSE-2.0.txt',
          ),
        ),
        MiuixArrowPreference(
          key: const ValueKey('third-party-licenses-link'),
          title: '第三方许可证',
          onTap: () => Navigator.of(context).push<void>(
            _ReferenceMaterialPageRoute<void>(
              context: context,
              builder: (_) => _MiuixReferenceLicensePage(
                showTopBar: widget.showTopBar,
                enableBlur: widget.enableBlur,
                enableScrollEndHaptic: widget.enableScrollEndHaptic,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Texture-blurred card shared by the two preference groups on the About route.
class _ReferenceAboutCard extends StatelessWidget {
  const _ReferenceAboutCard({
    super.key,
    required this.children,
    required this.backdrop,
  });

  final List<Widget> children;
  final MiuixBackdrop backdrop;

  @override
  Widget build(BuildContext context) {
    final sourceHorizontalMargin = _referenceRoundedDp(context, 12);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: sourceHorizontalMargin),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backdrop.enabled
              ? Colors.transparent
              : MiuixSemanticColors.of(context)['surfaceContainer'],
          borderRadius: BorderRadius.circular(16),
        ),
        child: MiuixLayerBackdrop(
          backdrop: backdrop,
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ),
    );
  }
}

/// Opens one of the same external destinations used by the source example.
///
/// Compose's `LocalUriHandler` does not add UI on failure, so the localized
/// port also avoids inventing a Toast when no external handler is available.
void _openReferenceUrl(String value) {
  unawaited(debugReferenceOpenExternalUrl(value));
}

/// Launches a source URL externally and exposes the boundary for regression.
@visibleForTesting
Future<bool> debugReferenceOpenExternalUrl(
  String value, {
  Future<bool> Function(Uri uri)? launcher,
}) async {
  try {
    final uri = Uri.parse(value);
    return await (launcher ?? _launchReferenceExternalUrl)(uri);
  } on Object {
    return false;
  }
}

Future<bool> _launchReferenceExternalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Upstream 88dp launcher-icon presentation using the unmodified source PNG.
class _ReferenceAppIcon extends StatelessWidget {
  const _ReferenceAppIcon();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SizedBox(
        width: 88,
        height: 88,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Image.asset(
            'assets/images/ic_launcher.png',
            width: 74,
            height: 74,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            excludeFromSemantics: true,
          ),
        ),
      ),
    );
  }
}
