part of 'main.dart';

typedef _ReferencePageBodyBuilder =
    Widget Function(BuildContext context, double topContentInset);

/// Converts one independently measured Compose dimension to logical pixels.
///
/// Android Compose resolves every `Dp` measurement to an integer number of
/// physical pixels before parent layouts add adjacent measurements. Flutter
/// normally keeps the logical values fractional until rasterization, so adding
/// 94dp and 12dp first can land one pixel above the source at a 2.625 density.
@visibleForTesting
double debugReferenceRoundedDp(double logicalPixels, double devicePixelRatio) {
  if (!devicePixelRatio.isFinite || devicePixelRatio <= 0) {
    return logicalPixels;
  }
  return (logicalPixels * devicePixelRatio).roundToDouble() / devicePixelRatio;
}

/// Applies the source's per-modifier `roundToPx` rule at the current density.
double _referenceRoundedDp(BuildContext context, double logicalPixels) =>
    debugReferenceRoundedDp(
      logicalPixels,
      MediaQuery.devicePixelRatioOf(context),
    );

/// Calculates the source Scaffold padding consumed by a page scrollable.
double _referenceTopContentInset(
  BuildContext context, {
  required bool showTopBar,
  required bool wide,
  bool hasSubtitle = false,
  double bottomContentHeight = 0,
  double bottomContentExpandedTopPadding = 0,
  MiuixTopAppBarScrollBehavior? scrollBehavior,
  double? systemTopInsetOverride,
}) {
  if (!showTopBar) return 0;
  // TopAppBar.kt always applies `systemBars.only(Top)`. Its
  // `defaultWindowInsetsPadding` switch affects only horizontal display-cutout
  // and navigation-bar insets, so adaptive compact bars retain the Android
  // status-bar inset on wide and landscape layouts too.
  final systemTopInset =
      systemTopInsetOverride ?? MediaQuery.viewPaddingOf(context).top;
  final expandedTitleHeight =
      _referenceRoundedDp(context, 94) +
      (hasSubtitle ? _referenceRoundedDp(context, 20) : 0.0);
  final collapsedTitleHeight = hasSubtitle
      ? _referenceRoundedDp(context, MiuixTopAppBar.collapsedSubtitleHeight)
      : _referenceRoundedDp(context, MiuixTopAppBar.collapsedHeight) +
            _referenceRoundedDp(
              context,
              MiuixTopAppBar.largeTitleBottomPadding,
            );
  final collapseFraction = wide
      ? 1.0
      : (scrollBehavior?.collapseFraction ?? 0.0);
  final titleHeight = wide
      ? hasSubtitle
            ? collapsedTitleHeight
            : _referenceRoundedDp(context, MiuixTopAppBar.collapsedHeight)
      : expandedTitleHeight +
            (collapsedTitleHeight - expandedTitleHeight) * collapseFraction;
  final dynamicBottomTopPadding =
      bottomContentExpandedTopPadding * (wide ? 0 : 1 - collapseFraction);
  // TopAppBar and its optional bottom slot are separate Compose measurables.
  // Round them independently before the Scaffold supplies the accumulated
  // content inset, exactly as the source layout's integer pixel constraints do.
  return systemTopInset +
      titleHeight +
      _referenceRoundedDp(context, dynamicBottomTopPadding) +
      _referenceRoundedDp(context, bottomContentHeight);
}

/// Rebuilds source content padding from the live TopAppBar measurement.
///
/// Compose Scaffold updates its remembered PaddingValues during every measure.
/// Flutter body widgets otherwise retain the expanded inset while the app bar
/// collapses, so source-style pages wrap their scrollable with this adapter.
class _ReferenceTopContentInsetBuilder extends StatelessWidget {
  const _ReferenceTopContentInsetBuilder({
    required this.showTopBar,
    required this.wide,
    required this.builder,
    this.hasSubtitle = false,
    this.bottomContentHeight = 0,
    this.bottomContentExpandedTopPadding = 0,
    this.scrollBehavior,
    this.systemTopInsetOverride,
  });

  final bool showTopBar;
  final bool wide;
  final bool hasSubtitle;
  final double bottomContentHeight;
  final double bottomContentExpandedTopPadding;
  final MiuixTopAppBarScrollBehavior? scrollBehavior;
  final double? systemTopInsetOverride;
  final Widget Function(BuildContext context, double topContentInset) builder;

  @override
  Widget build(BuildContext context) {
    Widget buildContent(BuildContext context) => builder(
      context,
      _referenceTopContentInset(
        context,
        showTopBar: showTopBar,
        wide: wide,
        hasSubtitle: hasSubtitle,
        bottomContentHeight: bottomContentHeight,
        bottomContentExpandedTopPadding: bottomContentExpandedTopPadding,
        scrollBehavior: scrollBehavior,
        systemTopInsetOverride: systemTopInsetOverride,
      ),
    );

    final behavior = scrollBehavior;
    if (behavior == null) return buildContent(context);
    return AnimatedBuilder(
      animation: behavior,
      builder: (context, _) => buildContent(context),
    );
  }
}

/// Per-page scaffold matching the source sample's nested page architecture.
///
/// The compact root owns navigation and floating controls. Each pager child
/// owns its own top bar, scroll behavior, popup host, and collapse state.
class _ReferencePageScaffold extends StatefulWidget {
  const _ReferencePageScaffold({
    required this.title,
    required this.wide,
    required this.showTopBar,
    required this.enableBlur,
    required this.bodyBuilder,
    this.subtitle,
    this.bottomContent,
    this.bottomContentHeight = 0,
    this.bottomContentExpandedTopPadding = 0,
    this.leading,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final bool wide;
  final bool showTopBar;
  final bool enableBlur;
  final _ReferencePageBodyBuilder bodyBuilder;
  final Widget? bottomContent;
  final double bottomContentHeight;
  final double bottomContentExpandedTopPadding;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  State<_ReferencePageScaffold> createState() => _ReferencePageScaffoldState();
}

class _ReferencePageScaffoldState extends State<_ReferencePageScaffold> {
  late final MiuixTopAppBarScrollBehavior _scrollBehavior;

  @override
  void initState() {
    super.initState();
    _scrollBehavior = MiuixTopAppBarScrollBehavior();
  }

  @override
  void dispose() {
    _scrollBehavior.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Root pages read the live blur-style selection from the same inherited
    // AppState-equivalent object that drives navigation transitions. This is
    // important because every page owns a separate Scaffold and top bar in the
    // upstream architecture; changing the setting must rebuild all five real
    // bars instead of swapping a preview inside Settings. Isolated page tests
    // intentionally omit that root scope, so `maybeOf` supplies the persistent
    // Gaussian fallback without forcing fixture routes to construct the full
    // navigation shell merely to render their local content.
    final appSettings = _ReferenceTransitionScope.maybeOf(context);
    return MiuixScaffold(
      topBar: widget.showTopBar
          ? MiuixTopAppBar(
              title: widget.title,
              subtitle: widget.subtitle,
              // Compact phone pages keep the source large-title hierarchy:
              // the 32sp leading title collapses into the centered 20sp title
              // only after the connected list moves upward. Wide layouts use
              // the compact bar because their persistent rail already owns the
              // primary hierarchy and no vertical collapse behavior is wired.
              large: !widget.wide,
              glass: widget.enableBlur,
              blurStyle: appSettings?.blurStyle == 'progressive'
                  ? MiuixTopAppBarBlurStyle.progressive
                  : MiuixTopAppBarBlurStyle.gaussian,
              scrollBehavior: widget.wide ? null : _scrollBehavior,
              defaultWindowInsetsPadding: !widget.wide,
              leading: widget.leading,
              actions: widget.actions,
              bottomContent: widget.bottomContent,
              bottomContentHeight: widget.bottomContentHeight,
              bottomContentExpandedTopPadding:
                  widget.bottomContentExpandedTopPadding,
            )
          : null,
      body: _ReferenceTopContentInsetBuilder(
        showTopBar: widget.showTopBar,
        wide: widget.wide,
        hasSubtitle: widget.subtitle?.isNotEmpty == true,
        bottomContentHeight: widget.bottomContentHeight,
        bottomContentExpandedTopPadding: widget.bottomContentExpandedTopPadding,
        scrollBehavior: widget.wide ? null : _scrollBehavior,
        // Flutter Scaffold removes the top MediaQuery padding from its body.
        // Capture the window value in the parent context before entering it.
        systemTopInsetOverride: MediaQuery.viewPaddingOf(context).top,
        builder: widget.bodyBuilder,
      ),
    );
  }
}
