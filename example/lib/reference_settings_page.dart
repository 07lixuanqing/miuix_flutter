part of 'main.dart';

/// Chinese reconstruction of the current source settings page.
class _MiuixReferenceSettingsPage extends StatelessWidget {
  const _MiuixReferenceSettingsPage({
    required this.wide,
    required this.bottomContentInset,
    required this.colorMode,
    required this.onColorModeChanged,
    required this.settings,
    required this.onSettingsChanged,
    required this.showTopBar,
    required this.enableBlur,
  });

  final bool wide;
  final double bottomContentInset;
  final MiuixColorMode colorMode;
  final ValueChanged<MiuixColorMode> onColorModeChanged;
  final _MiuixExampleSettings settings;
  final ValueChanged<_MiuixExampleSettings> onSettingsChanged;
  final bool showTopBar;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    return _ReferencePageScaffold(
      title: '设置',
      subtitle: _referenceSourceVersionLabel,
      wide: wide,
      showTopBar: showTopBar,
      enableBlur: enableBlur,
      bodyBuilder: (context, topContentInset) {
        final sourcePageMargin = _referenceRoundedDp(context, 12);
        final contentPadding = _referencePagePadding(
          context: context,
          bottomContentInset: bottomContentInset,
          // SettingsPage.kt wraps its first card in Modifier.padding(12.dp).
          // Compose rounds that modifier before adding Scaffold padding.
          topContentInset: topContentInset + sourcePageMargin,
        );
        return _ReferenceSettingsScrollBody(
          padding: contentPadding,
          children: [
            _ReferenceSettingsUiCard(
              wide: wide,
              colorMode: colorMode,
              onColorModeChanged: onColorModeChanged,
              settings: settings,
              onSettingsChanged: onSettingsChanged,
            ),
            const MiuixSmallTitle(
              '导航',
              insideMargin: _referencePageSmallTitlePadding,
            ),
            _buildTransitionCard(context),
            const MiuixSmallTitle(
              '其他',
              insideMargin: _referencePageSmallTitlePadding,
            ),
            _buildAboutCard(context),
            // SettingsPage.kt ends its source hierarchy with this 12dp spacer.
            // User-requested controls follow it, so they cannot shift any
            // source row or remove the source's final breathing room.
            SizedBox(height: sourcePageMargin),
            const MiuixSmallTitle(
              '扩展功能',
              insideMargin: _referencePageSmallTitlePadding,
            ),
            _buildExtensionCard(),
            SizedBox(height: sourcePageMargin),
          ],
        );
      },
    );
  }

  /// Hosts user-requested additions after the complete current hierarchy.
  ///
  /// Five-level glass strength and the extra floating display modes are not
  /// rows in current SettingsPage.kt, so they remain in a clearly separated
  /// final card and cannot change any source row's position or visibility.
  Widget _buildExtensionCard() {
    return MiuixCard(
      key: const ValueKey('reference-settings-extension-card'),
      child: Column(
        children: [
          if (!wide &&
              settings.showNavigation &&
              settings.useFloatingNavigationBar)
            MiuixDropdownPreference<String>(
              key: const ValueKey('reference-floating-navigation-mode-row'),
              title: '悬浮导航栏显示模式',
              value: settings.floatingNavigationBarMode,
              entries: _referenceFloatingNavigationModeEntries,
              onChanged: (value) => onSettingsChanged(
                settings.copyWith(floatingNavigationBarMode: value),
              ),
            ),
          if (settings.enableBlur)
            MiuixDropdownPreference<MiuixGlassIntensity>(
              title: '玻璃模糊与透明度',
              value: settings.glassIntensity,
              entries: _referenceGlassIntensityEntries,
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(glassIntensity: value)),
            ),
          if (settings.enableSwipeBack)
            MiuixSwitchPreference(
              title: '返回动画跟随滑动边缘',
              summary: '返回方向跟随手势开始的一侧',
              value: settings.popDirectionFollowsSwipeEdge,
              onChanged: (value) => onSettingsChanged(
                settings.copyWith(popDirectionFollowsSwipeEdge: value),
              ),
            ),
        ],
      ),
    );
  }

  /// Current navigation transition controls in exact source order.
  Widget _buildTransitionCard(BuildContext context) {
    return MiuixCard(
      key: const ValueKey('reference-settings-transition-card'),
      margin: EdgeInsets.only(bottom: _referenceRoundedDp(context, 12)),
      child: Column(
        children: [
          _referenceSettingsDropdown<String>(
            title: '转场样式',
            value: settings.navigationTransitionStyle,
            entries: _referenceNavigationTransitionEntries,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(navigationTransitionStyle: value),
            ),
          ),
          MiuixSwitchPreference(
            title: '启用圆角裁剪',
            summary: '转场期间使用圆角裁剪顶部场景',
            value: settings.enableCornerClip,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enableCornerClip: value)),
          ),
          MiuixSwitchPreference(
            title: '启用背景变暗',
            summary: '转场期间使后方场景变暗',
            value: settings.enableDim,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enableDim: value)),
          ),
          MiuixSwitchPreference(
            title: '转场期间阻止输入',
            summary: '阻止非目标场景接收触摸输入',
            value: settings.blockInputDuringTransition,
            onChanged: (value) => onSettingsChanged(
              settings.copyWith(blockInputDuringTransition: value),
            ),
          ),
          MiuixSwitchPreference(
            title: '启用滑动返回',
            summary: '滑动已推入的页面进行返回，方向跟随布局',
            value: settings.enableSwipeBack,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(enableSwipeBack: value)),
          ),
        ],
      ),
    );
  }

  /// Source About route card.
  Widget _buildAboutCard(BuildContext context) {
    return MiuixCard(
      key: const ValueKey('reference-settings-about-card'),
      child: MiuixArrowPreference(
        title: '关于',
        summary: '关于此示例应用',
        onTap: () => Navigator.of(context).push<void>(
          _ReferenceMaterialPageRoute<void>(
            context: context,
            builder: (_) => _MiuixReferenceAboutPage(
              showTopBar: settings.showTopBar,
              enableBlur: settings.enableBlur,
              enableScrollEndHaptic: settings.enableScrollEndHaptic,
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns the remembered list state shared by SettingsPage and its scrollbar.
///
/// Keeping this helper stateful lets the public settings reconstruction remain
/// a value-style widget while matching Compose's `rememberLazyListState()`.
class _ReferenceSettingsScrollBody extends StatefulWidget {
  const _ReferenceSettingsScrollBody({
    required this.padding,
    required this.children,
  });

  final EdgeInsets padding;
  final List<Widget> children;

  @override
  State<_ReferenceSettingsScrollBody> createState() =>
      _ReferenceSettingsScrollBodyState();
}

class _ReferenceSettingsScrollBodyState
    extends State<_ReferenceSettingsScrollBody> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MiuixVerticalScrollBar(
      key: const ValueKey('reference-settings-scrollbar'),
      controller: _scrollController,
      trackPadding: widget.padding,
      child: ListView(
        key: const PageStorageKey('miuix-reference-settings'),
        controller: _scrollController,
        padding: widget.padding,
        children: widget.children,
      ),
    );
  }
}
