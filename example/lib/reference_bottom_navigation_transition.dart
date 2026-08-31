part of 'main.dart';

/// Reproduces the two nested `AnimatedVisibility` layers in AppContent.kt.
///
/// The outer layer fades and changes height whenever navigation is globally
/// shown or hidden. Inside it, only the ordinary bar owns another fade/height
/// transition. Enabling floating mode inserts the floating bar immediately
/// while the ordinary bar exits beneath it; disabling floating mode removes
/// the floating bar immediately while the ordinary bar grows from its top.
class _ReferenceBottomNavigationTransition extends StatelessWidget {
  const _ReferenceBottomNavigationTransition({
    required this.visible,
    required this.useFloating,
    required this.regularBar,
    required this.floatingBar,
  });

  final bool visible;
  final bool useFloating;
  final Widget regularBar;
  final Widget floatingBar;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: const ValueKey('reference-bottom-navigation-transition'),
      child: _ReferenceAnimatedVisibility(
        visible: visible,
        verticalOnly: true,
        opacityKey: const ValueKey('reference-navigation-outer-opacity'),
        alignKey: const ValueKey('reference-navigation-outer-size'),
        hiddenKey: const ValueKey('navigation-hidden'),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            _ReferenceAnimatedVisibility(
              visible: !useFloating,
              verticalOnly: true,
              // The nested Kotlin call explicitly expands from and shrinks
              // toward Alignment.Top rather than the default bottom edge.
              verticalAlignment: Alignment.topCenter,
              opacityKey: const ValueKey(
                'reference-navigation-regular-opacity',
              ),
              alignKey: const ValueKey('reference-navigation-regular-size'),
              child: regularBar,
            ),
            if (useFloating) floatingBar,
          ],
        ),
      ),
    );
  }
}

/// Keeps the sizeable bottom-bar construction out of the root build method.
extension _ReferenceBottomNavigationBuilder on _MiuixExampleAppState {
  Widget _buildReferenceBottomNavigation() {
    final floatingBar = MiuixIosLiquidGlassNavigationBar(
      key: const ValueKey('ios-floating-navigation'),
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectPage,
      items: _navigationItems,
      showBlur: _settings.enableBlur,
      // A detached action is visually compatible with two or three wide
      // destinations. Five destinations need the complete phone width; adding
      // another circle would force every selected lens back toward a square.
      trailingAction: _navigationItems.length <= 3
          ? MiuixIconButton(
              key: const ValueKey('floating-navigation-search-action'),
              tooltip: '搜索',
              onPressed: () => _selectPage(0),
              icon: Icon(_miuixIcon('Search'), semanticLabel: '搜索'),
              minWidth: 48,
              minHeight: 48,
              cornerRadius: 24,
            )
          : null,
      displayMode: switch (_settings.floatingNavigationBarMode) {
        'iconAndText' => MiuixFloatingNavigationBarDisplayMode.iconAndText,
        'textOnly' => MiuixFloatingNavigationBarDisplayMode.textOnly,
        _ => MiuixFloatingNavigationBarDisplayMode.iconOnly,
      },
    );
    final regularBar = MiuixNavigationBar(
      key: const ValueKey('regular-navigation'),
      selectedIndex: _selectedIndex,
      onDestinationSelected: _selectPage,
      items: _navigationItems,
      glass: _settings.enableBlur,
      displayMode: switch (_settings.navigationMode) {
        'iconOnly' => MiuixNavigationBarDisplayMode.iconOnly,
        'textOnly' => MiuixNavigationBarDisplayMode.textOnly,
        'iconWithSelectedLabel' =>
          MiuixNavigationBarDisplayMode.iconWithSelectedLabel,
        _ => MiuixNavigationBarDisplayMode.iconAndText,
      },
    );
    return _ReferenceBottomNavigationTransition(
      visible: _settings.showNavigation,
      useFloating: _settings.useFloatingNavigationBar,
      regularBar: regularBar,
      floatingBar: floatingBar,
    );
  }
}
