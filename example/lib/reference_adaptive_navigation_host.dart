part of 'main.dart';

/// Hosts the source's `NavDisplay` inside only the wide-screen content pane.
///
/// The original `AppContent.kt` places `PersistentNavigationRail` beside a
/// weighted, clipped box. The route stack lives in that box, so About,
/// licenses, and navigation demos never cover the rail and all transition
/// distances are measured against the pane rather than the complete window.
class _ReferenceWidePaneNavigator extends StatefulWidget {
  const _ReferenceWidePaneNavigator({
    required this.navigatorKey,
    required this.home,
  });

  /// Lets a rail destination pop the pane back to its main route first.
  final GlobalKey<NavigatorState> navigatorKey;

  /// Current Home scene, rebuilt whenever settings or the pager state change.
  final Widget home;

  @override
  State<_ReferenceWidePaneNavigator> createState() =>
      _ReferenceWidePaneNavigatorState();
}

/// Retains the pane route stack while forwarding live Home configuration.
class _ReferenceWidePaneNavigatorState
    extends State<_ReferenceWidePaneNavigator> {
  /// A route builder runs only when its route is created. Keeping Home behind
  /// a notifier prevents that first closure from freezing later app settings.
  late final ValueNotifier<Widget> _home = ValueNotifier(widget.home);

  @override
  void didUpdateWidget(_ReferenceWidePaneNavigator oldWidget) {
    super.didUpdateWidget(oldWidget);
    _home.value = widget.home;
  }

  @override
  void dispose() {
    _home.dispose();
    super.dispose();
  }

  /// Creates the stack's permanent main entry without an initial transition.
  Route<void> _buildMainRoute(RouteSettings settings) => PageRouteBuilder<void>(
    settings: settings,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    pageBuilder: (context, animation, secondaryAnimation) =>
        ValueListenableBuilder<Widget>(
          valueListenable: _home,
          builder: (context, home, child) => home,
        ),
  );

  @override
  Widget build(BuildContext context) {
    // NavigatorPopHandler gives the nested stack first refusal on system Back.
    // When only Main remains, the event reaches MainScreenBackHandler instead.
    return NavigatorPopHandler<void>(
      onPopWithResult: (result) {
        widget.navigatorKey.currentState?.maybePop();
      },
      child: ClipRect(
        key: const ValueKey('reference-wide-pane-clip'),
        child: Navigator(
          key: widget.navigatorKey,
          restorationScopeId: 'reference-wide-pane',
          onGenerateRoute: _buildMainRoute,
        ),
      ),
    );
  }
}

/// Keeps the source FPS monitor above both application chrome and route layers.
///
/// `AppContent.kt` composes this `AnimatedVisibility` after `NavDisplay`, not
/// inside Route.Main. A pushed page must therefore leave the monitor visible.
class _ReferenceFpsOverlay extends StatelessWidget {
  const _ReferenceFpsOverlay({required this.visible});

  /// Whether the global diagnostic layer participates in the overlay.
  final bool visible;

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Padding(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: _ReferenceFadeOnlyVisibility(
        visible: visible,
        opacityKey: const ValueKey('reference-fps-visibility-opacity'),
        hiddenKey: const ValueKey('reference-fps-monitor-hidden'),
        child: const _ReferenceFpsMonitor(
          key: ValueKey('reference-fps-monitor'),
        ),
      ),
    ),
  );
}
