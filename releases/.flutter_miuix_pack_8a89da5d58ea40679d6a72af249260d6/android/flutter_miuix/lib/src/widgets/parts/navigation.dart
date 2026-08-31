part of '../miuix_widgets.dart';

/// Floating-action-button positions supported by [MiuixScaffold].
enum MiuixFabPosition { start, center, end, endOverlay }

/// Floating-toolbar positions supported by [MiuixScaffold].
enum MiuixToolbarPosition {
  topStart,
  centerStart,
  bottomStart,
  topEnd,
  centerEnd,
  bottomEnd,
  topCenter,
  bottomCenter,
}

// Dialog hosts use the source component's compact slide-up transition while
// anchored menus and ordinary popup content retain their scale transition.
enum _MiuixHostedPopupTransition { scale, fade, dialog, bottomSheet }

// MiuixPopupUtils allocates one process-local nextZIndex for dialog and popup
// states across every Scaffold. Source wrappers reserve from this sequence when
// their state identity is composed; direct route helpers reserve when opened.
var _miuixNextHostedPopupZIndex = 1;

// Compose measures every PopupPositionProvider against the complete Android
// window, even when PopupHost later clips the result inside a nested Scaffold.
// Keep the host origin in the same separately truncated physical-pixel space
// used by LayoutCoordinates.positionInWindow().
Offset? _miuixPopupHostOriginInWindow(BuildContext? hostContext) {
  final renderObject = hostContext?.findRenderObject();
  if (hostContext == null ||
      renderObject is! RenderBox ||
      !renderObject.hasSize) {
    return null;
  }
  final density = View.of(hostContext).devicePixelRatio;
  final position = renderObject.localToGlobal(Offset.zero);
  return Offset(
    (position.dx * density).truncate() / density,
    (position.dy * density).truncate() / density,
  );
}

class _MiuixHostedPopup<T> {
  _MiuixHostedPopup({
    required this.id,
    required this.zIndex,
    required this.child,
    required this.completer,
    this.link,
    this.anchorRect,
    this.popupAlignment = MiuixPopupAlignment.bottomStart,
    this.popupPositioning = MiuixPopupPositioning.dropdown,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = Offset.zero,
    this.unanchoredAlignment = Alignment.center,
    this.dimBackground = true,
    this.dimColor,
    this.dimAlpha,
    this.enterTransition,
    this.exitTransition,
    this.dimEnterTransition,
    this.dimExitTransition,
    this.transition = _MiuixHostedPopupTransition.scale,
    this.barrierDismissible = true,
    this.enableBackHandler = true,
    this.enableAutoLargeScreen = true,
    this.canDismiss,
    this.onDismissRequest,
    this.onDismissFinished,
  });

  final int id;
  final int zIndex;
  Widget child;
  final Completer<T?> completer;
  final LayerLink? link;
  final Rect? anchorRect;
  final MiuixPopupAlignment popupAlignment;
  final MiuixPopupPositioning popupPositioning;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final Alignment unanchoredAlignment;
  bool dimBackground;
  Color? dimColor;
  ValueListenable<double>? dimAlpha;
  MiuixVisibilityTransition? enterTransition;
  MiuixVisibilityTransition? exitTransition;
  MiuixVisibilityTransition? dimEnterTransition;
  MiuixVisibilityTransition? dimExitTransition;
  final _MiuixHostedPopupTransition transition;
  final bool barrierDismissible;
  bool enableBackHandler;
  bool enableAutoLargeScreen;
  final bool Function()? canDismiss;
  final VoidCallback? onDismissRequest;
  final VoidCallback? onDismissFinished;
  bool visible = true;
}

/// Controller for popups rendered inside one isolated [MiuixScaffold].
class MiuixPopupHostController extends ChangeNotifier {
  MiuixPopupHostController({this.parent});

  /// Parent host for nested-scaffold root rendering.
  final MiuixPopupHostController? parent;
  final GlobalKey _hostKey = GlobalKey();
  final List<_MiuixHostedPopup<dynamic>> _entries = [];
  LocalHistoryEntry? _backHistoryEntry;
  bool _removingBackHistoryProgrammatically = false;
  ModalRoute<dynamic>? _backGuardRoute;
  Future<bool> Function()? _backGuardCallback;
  bool _disposed = false;
  var _id = 0;

  /// Outermost popup host in the current scaffold chain.
  MiuixPopupHostController get root => parent?.root ?? this;

  List<_MiuixHostedPopup<dynamic>> get _currentEntries {
    final ordered = List<_MiuixHostedPopup<dynamic>>.of(_entries)
      ..sort((a, b) {
        final zOrder = a.zIndex.compareTo(b.zIndex);
        return zOrder != 0 ? zOrder : a.id.compareTo(b.id);
      });
    return List.unmodifiable(ordered);
  }

  // A popup that is reversing still owns the route's back gesture until its
  // exit animation has completed. Otherwise a quick second Back press can pop
  // the application page while the modal surface is visibly leaving.
  bool get _hasBackHandlingEntry =>
      _entries.any((entry) => entry.enableBackHandler);

  bool get _blocksRoutePop => _hasBackHandlingEntry;

  void _syncBackRegistration() {
    if (_hasBackHandlingEntry) {
      _ensureBackHistoryEntry();
      _ensureBackRouteGuard();
    } else {
      _clearBackRouteGuard();
      _clearBackHistoryEntry();
    }
  }

  // Overlay-hosted surfaces do not push a Navigator route. A PopScope alone
  // can veto the route pop, but Flutter then invokes every PopScope callback
  // registered on that route with didPop=false. An application-level handler
  // can therefore react as well (the reference example returned its pager to
  // Home while the dropdown was still open). LocalHistoryEntry is Flutter's
  // route-native mechanism for menus: Back removes this entry internally,
  // starts the popup dismissal, and never reaches unrelated page handlers.
  void _ensureBackHistoryEntry() {
    if (_backHistoryEntry != null || !_hasBackHandlingEntry) {
      return;
    }
    final hostContext = _hostKey.currentContext;
    final route = hostContext == null ? null : ModalRoute.of(hostContext);
    if (route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasBackHandlingEntry) {
          _ensureBackHistoryEntry();
        }
      });
      return;
    }

    late final LocalHistoryEntry entry;
    entry = LocalHistoryEntry(
      impliesAppBarDismissal: false,
      onRemove: () {
        if (identical(_backHistoryEntry, entry)) {
          _backHistoryEntry = null;
        }
        if (_removingBackHistoryProgrammatically) {
          return;
        }

        // The system removed the local entry, so this is a genuine Back
        // request. Dismiss only the top live popup. Reinstall a local entry
        // while its reverse animation is still mounted; a second fast Back
        // must remain consumed until physical removal finishes.
        _handleRoutePop();
        if (_hasBackHandlingEntry) {
          _ensureBackHistoryEntry();
        }
      },
    );
    _backHistoryEntry = entry;
    route.addLocalHistoryEntry(entry);
  }

  void _clearBackHistoryEntry() {
    final entry = _backHistoryEntry;
    _backHistoryEntry = null;
    if (entry == null) {
      return;
    }
    _removingBackHistoryProgrammatically = true;
    try {
      entry.remove();
    } finally {
      _removingBackHistoryProgrammatically = false;
    }
  }

  // Local history gives the hosted popup route ownership, while this scoped
  // callback consumes Navigator.maybePop before Flutter broadcasts a rejected
  // PopScope attempt to every listener on the route. That broadcast would make
  // an unrelated pager-level PopScope react to the same Back press. Flutter
  // currently has no PopScope priority API, so the scoped callback remains the
  // compatibility bridge for overlay-hosted surfaces.
  void _ensureBackRouteGuard() {
    if (_backGuardCallback != null || !_hasBackHandlingEntry) {
      return;
    }
    final hostContext = _hostKey.currentContext;
    final route = hostContext == null ? null : ModalRoute.of(hostContext);
    if (route == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_hasBackHandlingEntry) {
          _ensureBackRouteGuard();
        }
      });
      return;
    }

    Future<bool> callback() async {
      _handleRoutePop();
      return false;
    }

    _backGuardRoute = route;
    _backGuardCallback = callback;
    // ignore: deprecated_member_use
    route.addScopedWillPopCallback(callback);
  }

  void _clearBackRouteGuard() {
    final route = _backGuardRoute;
    final callback = _backGuardCallback;
    _backGuardRoute = null;
    _backGuardCallback = null;
    if (route == null || callback == null) {
      return;
    }
    // ignore: deprecated_member_use
    route.removeScopedWillPopCallback(callback);
  }

  /// Shows content in this scaffold's popup layer.
  Future<T?> show<T>({
    required Widget child,
    int? zIndex,
    LayerLink? link,
    Rect? anchorRect,
    MiuixPopupAlignment popupAlignment = MiuixPopupAlignment.bottomStart,
    MiuixPopupPositioning popupPositioning = MiuixPopupPositioning.dropdown,
    Alignment targetAnchor = Alignment.bottomLeft,
    Alignment followerAnchor = Alignment.topLeft,
    Offset offset = Offset.zero,
    Alignment unanchoredAlignment = Alignment.center,
    bool dimBackground = true,
    Color? dimColor,
    ValueListenable<double>? dimAlpha,
    MiuixVisibilityTransition? enterTransition,
    MiuixVisibilityTransition? exitTransition,
    MiuixVisibilityTransition? dimEnterTransition,
    MiuixVisibilityTransition? dimExitTransition,
    bool fadeTransition = false,
    bool dialogTransition = false,
    bool bottomSheetTransition = false,
    bool barrierDismissible = true,
    bool enableBackHandler = true,
    bool enableAutoLargeScreen = true,
    bool Function()? canDismiss,
    VoidCallback? onDismissRequest,
    VoidCallback? onDismissFinished,
  }) {
    // Anchor rectangles are measured in the application's global coordinate
    // space. A nested Scaffold's popup host starts at that Scaffold's own
    // origin, so feeding the global rectangle directly to its layout delegate
    // shifts the popup down and right by the nested host's screen offset. The
    // source PopupHost always resolves coordinates in its local layout space.
    // Convert here once, while both the trigger and host render boxes are
    // attached; root hosts naturally retain the same coordinates.
    final hostContext = _hostKey.currentContext;
    final sourceHostOrigin = _miuixPopupHostOriginInWindow(hostContext);
    final localAnchorRect = anchorRect != null && sourceHostOrigin != null
        ? anchorRect.shift(-sourceHostOrigin)
        : anchorRect;
    final completer = Completer<T?>();
    final entryId = ++_id;
    final entry = _MiuixHostedPopup<T>(
      id: entryId,
      zIndex: zIndex ?? _miuixNextHostedPopupZIndex++,
      child: child,
      completer: completer,
      link: link,
      anchorRect: localAnchorRect,
      popupAlignment: popupAlignment,
      popupPositioning: popupPositioning,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: offset,
      unanchoredAlignment: unanchoredAlignment,
      dimBackground: dimBackground,
      dimColor: dimColor,
      dimAlpha: dimAlpha,
      enterTransition: enterTransition,
      exitTransition: exitTransition,
      dimEnterTransition: dimEnterTransition,
      dimExitTransition: dimExitTransition,
      transition: bottomSheetTransition
          ? _MiuixHostedPopupTransition.bottomSheet
          : dialogTransition
          ? _MiuixHostedPopupTransition.dialog
          : fadeTransition
          ? _MiuixHostedPopupTransition.fade
          : _MiuixHostedPopupTransition.scale,
      barrierDismissible: barrierDismissible,
      enableBackHandler: enableBackHandler,
      enableAutoLargeScreen: enableAutoLargeScreen,
      canDismiss: canDismiss,
      onDismissRequest: onDismissRequest,
      onDismissFinished: onDismissFinished,
    );
    _entries.add(entry);
    _syncBackRegistration();
    notifyListeners();
    return completer.future;
  }

  void _refreshEntry(_MiuixHostedPopup<dynamic> entry) {
    if (_entries.contains(entry)) {
      _syncBackRegistration();
      notifyListeners();
    }
  }

  /// Begins the hide animation for the topmost popup.
  void dismissTop<T>([T? result]) {
    for (final entry in _entries.reversed) {
      if (entry.visible) {
        _dismiss(entry, result);
        return;
      }
    }
  }

  // Handles a platform Back request using the same live dismissibility rules
  // as the popup barrier. This path must invoke onDismissRequest before the
  // reverse animation so OverlayDialog and OverlayBottomSheet can release the
  // hold-down state at the same lifecycle point as the Compose PopupHost.
  bool _handleRoutePop() {
    for (final entry in _entries.reversed) {
      if (!entry.enableBackHandler) {
        continue;
      }
      // A reversing popup keeps ownership of Back until it is physically
      // removed. This prevents a rapid second press from dismissing the entry
      // immediately below it.
      if (!entry.visible) {
        return true;
      }
      if (entry.canDismiss?.call() == false) {
        return false;
      }
      entry.onDismissRequest?.call();
      _dismiss(entry);
      return true;
    }
    return false;
  }

  void _dismiss<T>(_MiuixHostedPopup<dynamic> entry, [T? result]) {
    if (_disposed || !entry.visible) {
      return;
    }
    entry.visible = false;
    if (!entry.completer.isCompleted) {
      entry.completer.complete(result);
    }
    notifyListeners();
  }

  void _remove(_MiuixHostedPopup<dynamic> entry) {
    if (!_disposed && _entries.remove(entry)) {
      entry.onDismissFinished?.call();
      _syncBackRegistration();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _clearBackRouteGuard();
    _clearBackHistoryEntry();
    for (final entry in _entries) {
      if (!entry.completer.isCompleted) {
        entry.completer.complete();
      }
    }
    _entries.clear();
    super.dispose();
  }
}

/// Inherited access point used by Overlay-prefixed components.
class MiuixPopupHostScope extends InheritedNotifier<MiuixPopupHostController> {
  /// Creates a popup-host scope.
  const MiuixPopupHostScope({
    super.key,
    required MiuixPopupHostController controller,
    required super.child,
  }) : super(notifier: controller);

  /// Returns the nearest controller without establishing a dependency.
  static MiuixPopupHostController? maybeOf(BuildContext context) {
    return context
        .getInheritedWidgetOfExactType<MiuixPopupHostScope>()
        ?.notifier;
  }
}

/// Visual popup layer driven by a [MiuixPopupHostController].
class MiuixPopupHostView extends StatefulWidget {
  /// Creates a popup layer.
  const MiuixPopupHostView({super.key, required this.controller});

  final MiuixPopupHostController controller;

  @override
  State<MiuixPopupHostView> createState() => _MiuixPopupHostViewState();
}

class _MiuixPopupHostViewState extends State<MiuixPopupHostView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant MiuixPopupHostView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final textStyle =
        (Theme.of(context).textTheme.bodyLarge ?? const TextStyle(fontSize: 17))
            .copyWith(color: semantic['onSurface']);
    return SizedBox.expand(
      key: widget.controller._hostKey,
      child: PopScope<Object?>(
        // Overlay-prefixed components live inside the page instead of on a
        // Navigator route. Registering their host with PopScope is therefore
        // required to stop Android Back from closing the Activity behind them.
        canPop: !widget.controller._blocksRoutePop,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) widget.controller._handleRoutePop();
        },
        child: DefaultTextStyle(
          // The host is intentionally a sibling painted above Scaffold. Restore
          // the MIUIX main text style here because Scaffold's Material defaults
          // no longer sit above popup children in the element tree.
          style: textStyle,
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final entry in widget.controller._currentEntries)
                _MiuixHostedPopupView(
                  key: ValueKey(entry.id),
                  entry: entry,
                  controller: widget.controller,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiuixHostedPopupView extends StatefulWidget {
  const _MiuixHostedPopupView({
    super.key,
    required this.entry,
    required this.controller,
  });

  final _MiuixHostedPopup<dynamic> entry;
  final MiuixPopupHostController controller;

  @override
  State<_MiuixHostedPopupView> createState() => _MiuixHostedPopupViewState();
}

class _MiuixHostedPopupViewState extends State<_MiuixHostedPopupView>
    with TickerProviderStateMixin {
  late final AnimationController _contentAnimation;
  late final AnimationController _dimAnimation;
  MiuixPopupLayoutPosition? _popupLayoutPosition;

  Duration get _contentEnterDuration =>
      widget.entry.enterTransition?.duration ??
      switch (widget.entry.transition) {
        _MiuixHostedPopupTransition.dialog => _miuixDialogEnterDuration,
        _MiuixHostedPopupTransition.scale =>
          MiuixListPopupDefaults.fractionDuration,
        _MiuixHostedPopupTransition.fade => const Duration(milliseconds: 200),
        _MiuixHostedPopupTransition.bottomSheet => const Duration(
          milliseconds: 180,
        ),
      };

  Duration get _contentExitDuration =>
      widget.entry.exitTransition?.duration ??
      switch (widget.entry.transition) {
        _MiuixHostedPopupTransition.dialog => const Duration(milliseconds: 200),
        _MiuixHostedPopupTransition.scale =>
          MiuixListPopupDefaults.fractionDuration,
        _MiuixHostedPopupTransition.fade ||
        _MiuixHostedPopupTransition.bottomSheet => const Duration(
          milliseconds: 150,
        ),
      };

  Duration get _dimEnterDuration =>
      widget.entry.dimEnterTransition?.duration ??
      switch (widget.entry.transition) {
        _MiuixHostedPopupTransition.dialog ||
        _MiuixHostedPopupTransition.fade => const Duration(milliseconds: 300),
        _MiuixHostedPopupTransition.scale =>
          MiuixListPopupDefaults.fractionDuration,
        _MiuixHostedPopupTransition.bottomSheet => const Duration(
          milliseconds: 180,
        ),
      };

  Duration get _dimExitDuration =>
      widget.entry.dimExitTransition?.duration ??
      switch (widget.entry.transition) {
        _MiuixHostedPopupTransition.dialog => const Duration(milliseconds: 250),
        _MiuixHostedPopupTransition.scale =>
          MiuixListPopupDefaults.fractionDuration,
        _MiuixHostedPopupTransition.fade ||
        _MiuixHostedPopupTransition.bottomSheet => const Duration(
          milliseconds: 150,
        ),
      };

  @override
  void initState() {
    super.initState();
    _contentAnimation = AnimationController(
      vsync: this,
      duration: _contentEnterDuration,
      reverseDuration: _contentExitDuration,
    )..forward();
    _dimAnimation = AnimationController(
      vsync: this,
      duration: _dimEnterDuration,
      reverseDuration: _dimExitDuration,
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _MiuixHostedPopupView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _contentAnimation
      ..duration = _contentEnterDuration
      ..reverseDuration = _contentExitDuration;
    _dimAnimation
      ..duration = _dimEnterDuration
      ..reverseDuration = _dimExitDuration;
    if (!widget.entry.visible &&
        (_contentAnimation.status != AnimationStatus.reverse ||
            _dimAnimation.status != AnimationStatus.reverse)) {
      _hide();
    }
  }

  Future<void> _hide() async {
    try {
      await Future.wait([_contentAnimation.reverse(), _dimAnimation.reverse()]);
    } on TickerCanceled {
      return;
    }
    widget.controller._remove(widget.entry);
  }

  void _requestDismiss() {
    if (!widget.entry.barrierDismissible ||
        widget.entry.canDismiss?.call() == false) {
      return;
    }
    widget.entry.onDismissRequest?.call();
    widget.controller._dismiss(widget.entry);
  }

  @override
  void dispose() {
    _contentAnimation.dispose();
    _dimAnimation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _popupLayoutPosition ??= _miuixPredictedPopupLayoutPosition(
      widget.entry.popupAlignment,
      Directionality.of(context),
    );
    final defaultCurve = CurvedAnimation(
      parent: _contentAnimation,
      curve: Curves.easeOutCubic,
    );
    final size = MediaQuery.sizeOf(context);
    final largeDialog =
        widget.entry.enableAutoLargeScreen &&
        size.width >= 840 &&
        size.height >= 480;
    final dialogCurve = CurvedAnimation(
      parent: _contentAnimation,
      curve: _MiuixDialogSpringCurve(
        dampingRatio: largeDialog ? .9 : .88,
        stiffness: largeDialog ? 438.6 : 450,
      ),
      reverseCurve: const _MiuixAccelerateCurve(),
    );
    final dimCurve =
        widget.entry.transition == _MiuixHostedPopupTransition.dialog
        ? CurvedAnimation(
            parent: _dimAnimation,
            curve: const _MiuixDialogDimEnterCurve(),
            reverseCurve: const _MiuixDialogDimExitCurve(),
          )
        : CurvedAnimation(parent: _dimAnimation, curve: Curves.easeOutCubic);
    final defaultPopup = switch (widget.entry.transition) {
      _MiuixHostedPopupTransition.dialog when !largeDialog => SlideTransition(
        key: const ValueKey('miuix-host-dialog-slide'),
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(dialogCurve),
        child: widget.entry.child,
      ),
      _MiuixHostedPopupTransition.dialog => FadeTransition(
        key: const ValueKey('miuix-host-dialog-large-fade'),
        opacity: dialogCurve,
        child: ScaleTransition(
          scale: Tween<double>(begin: .8, end: 1).animate(dialogCurve),
          child: widget.entry.child,
        ),
      ),
      _MiuixHostedPopupTransition.bottomSheet => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(defaultCurve),
        child: widget.entry.child,
      ),
      _MiuixHostedPopupTransition.scale => _MiuixAnimatedListPopupSurface(
        animation: _contentAnimation,
        position: _popupLayoutPosition!,
        child: widget.entry.child,
      ),
      _MiuixHostedPopupTransition.fade => FadeTransition(
        opacity: _contentAnimation,
        child: widget.entry.child,
      ),
    };
    final contentTransition =
        _contentAnimation.status == AnimationStatus.reverse
        ? widget.entry.exitTransition
        : widget.entry.enterTransition;
    final popup =
        contentTransition?._build(
          context,
          _contentAnimation,
          widget.entry.child,
        ) ??
        defaultPopup;
    final dimGesture = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _requestDismiss,
      child: widget.entry.dimBackground
          ? ColoredBox(
              color:
                  widget.entry.dimColor ?? Colors.black.withValues(alpha: .16),
            )
          : const SizedBox.expand(),
    );
    final selectedDimTransition =
        _dimAnimation.status == AnimationStatus.reverse
        ? widget.entry.dimExitTransition
        : widget.entry.dimEnterTransition;
    Widget dimSurface;
    if (!widget.entry.dimBackground) {
      dimSurface = dimGesture;
    } else if (selectedDimTransition != null) {
      dimSurface = selectedDimTransition._build(
        context,
        _dimAnimation,
        dimGesture,
      );
    } else {
      dimSurface = switch (widget.entry.transition) {
        _MiuixHostedPopupTransition.scale => AnimatedBuilder(
          animation: _dimAnimation,
          builder: (context, child) {
            final progress = _miuixListPopupProgress(_dimAnimation);
            return Opacity(opacity: progress.dim.clamp(0.0, 1.0), child: child);
          },
          child: dimGesture,
        ),
        _MiuixHostedPopupTransition.fade => AnimatedBuilder(
          animation: _dimAnimation,
          builder: (context, child) {
            final reversing = _dimAnimation.status == AnimationStatus.reverse;
            final dimProgress = reversing
                ? 1 -
                      const _MiuixSinOutCurve().transform(
                        1 - _dimAnimation.value,
                      )
                : const _MiuixSinOutCurve().transform(_dimAnimation.value);
            return Opacity(opacity: dimProgress.clamp(0.0, 1.0), child: child);
          },
          child: dimGesture,
        ),
        _MiuixHostedPopupTransition.dialog ||
        _MiuixHostedPopupTransition.bottomSheet => FadeTransition(
          opacity: dimCurve,
          child: dimGesture,
        ),
      };
    }
    if (widget.entry.dimAlpha case final dimAlpha?) {
      dimSurface = AnimatedBuilder(
        animation: dimAlpha,
        builder: (context, child) =>
            Opacity(opacity: dimAlpha.value.clamp(0.0, 1.0), child: child),
        child: dimSurface,
      );
    }
    final density = View.of(context).devicePixelRatio;
    final windowSize = View.of(context).physicalSize / density;
    final windowPadding = MediaQuery.paddingOf(context);
    final sourceHostOrigin =
        _miuixPopupHostOriginInWindow(
          widget.controller._hostKey.currentContext,
        ) ??
        Offset.zero;
    // Bounds remain expressed in this host's local coordinates, but their
    // edges are the real safe Android window. A right-hand nested host thus
    // receives a negative local left edge; the popup may align left of that
    // host and is then clipped by PopupHost exactly like the Compose fixture.
    final sourceWindowBounds = Rect.fromLTRB(
      windowPadding.left - sourceHostOrigin.dx,
      windowPadding.top - sourceHostOrigin.dy,
      windowSize.width - windowPadding.right - sourceHostOrigin.dx,
      windowSize.height - windowPadding.bottom - sourceHostOrigin.dy,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        dimSurface,
        if (widget.entry.anchorRect case final anchorRect?)
          CustomSingleChildLayout(
            delegate: _MiuixPopupLayoutDelegate(
              anchorRect: anchorRect,
              alignment: widget.entry.popupAlignment,
              positioning: widget.entry.popupPositioning,
              textDirection: Directionality.of(context),
              safePadding: windowPadding,
              placementBounds: sourceWindowBounds,
              devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
              onLayoutPositionChanged: (position) {
                if (position != _popupLayoutPosition && mounted) {
                  setState(() => _popupLayoutPosition = position);
                }
              },
            ),
            child: popup,
          )
        else if (widget.entry.link case final link?)
          _MiuixAdaptivePopupFollower(
            link: link,
            targetAnchor: widget.entry.targetAnchor,
            followerAnchor: widget.entry.followerAnchor,
            offset: widget.entry.offset,
            child: popup,
          )
        else
          Align(alignment: widget.entry.unanchoredAlignment, child: popup),
      ],
    );
  }
}

/// Keeps an Overlay-hosted popup inside the same safe placement rules as the
/// original MIUIX `DropdownPositionProvider` while retaining a live LayerLink.
class _MiuixAdaptivePopupFollower extends StatefulWidget {
  const _MiuixAdaptivePopupFollower({
    required this.link,
    required this.targetAnchor,
    required this.followerAnchor,
    required this.offset,
    required this.child,
  });

  final LayerLink link;
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Offset offset;
  final Widget child;

  @override
  State<_MiuixAdaptivePopupFollower> createState() =>
      _MiuixAdaptivePopupFollowerState();
}

class _MiuixAdaptivePopupFollowerState
    extends State<_MiuixAdaptivePopupFollower> {
  final GlobalKey _popupKey = GlobalKey();
  Offset _correction = Offset.zero;
  bool _measurementScheduled = false;

  bool get _prefersBelow => widget.targetAnchor.y > widget.followerAnchor.y;

  bool get _prefersAbove => widget.targetAnchor.y < widget.followerAnchor.y;

  @override
  void didUpdateWidget(covariant _MiuixAdaptivePopupFollower oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link != widget.link ||
        oldWidget.targetAnchor != widget.targetAnchor ||
        oldWidget.followerAnchor != widget.followerAnchor ||
        oldWidget.offset != widget.offset) {
      _correction = Offset.zero;
    }
  }

  void _scheduleMeasurement() {
    if (_measurementScheduled) return;
    _measurementScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measurementScheduled = false;
      if (mounted) _updateCorrection();
    });
  }

  // Placement deliberately mirrors `ListPopupDefaults.dropdownPositionProvider`:
  // 1. Read the popup's painted global rectangle after its first layout.
  // 2. Remove the previous correction to recover the linked base position.
  // 3. Treat system padding as the original provider's safe window bounds.
  // 4. Reserve eight logical pixels only for the final surface margin.
  // 5. Prefer the full popup below the anchor when it fits there.
  // 6. Otherwise prefer the full popup above the anchor when it fits there.
  // 7. If neither side fits, center it vertically on the anchor.
  // 8. Clamp that result between the top and bottom safe margins.
  // 9. Clamp horizontally without changing end/start alignment semantics.
  // 10. Apply the correction as a paint transform so the LayerLink remains live.
  // The correction is recomputed when text wrapping or menu state changes size.
  // Measuring the untransformed layout size avoids feedback from scale animation.
  // Subtracting the prior correction prevents cumulative drift across frames.
  // Strict `>` fit comparisons match the Compose implementation at boundaries.
  // Disabled rows remain part of popup size because MIUIX keeps them visible.
  // MediaQuery padding represents status, navigation, and display-cutout insets.
  // The root popup host may rebuild while open; the stable link preserves origin.
  // A sub-pixel tolerance prevents redundant frames from rounding differences.
  // All callers therefore share one placement rule on Android, Windows, and web.
  void _updateCorrection() {
    final box = _popupKey.currentContext?.findRenderObject();
    final leaderSize = widget.link.leaderSize;
    if (box is! RenderBox || !box.attached || leaderSize == null) return;

    final media = MediaQuery.of(context);
    final paintedTopLeft = box.localToGlobal(Offset.zero);
    final baseTopLeft = paintedTopLeft - _correction;
    final popupSize = box.size;
    final safeLeft = media.padding.left;
    final windowTop = media.padding.top;
    final safeRight = media.size.width - media.padding.right;
    final windowBottom = media.size.height - media.padding.bottom;
    final safeTop = windowTop + 8;
    final safeBottom = windowBottom - 8;

    final desiredX = baseTopLeft.dx
        .clamp(safeLeft, math.max(safeLeft, safeRight - popupSize.width))
        .toDouble();
    var desiredY = baseTopLeft.dy;
    if (_prefersBelow) {
      final anchorBottom = baseTopLeft.dy - widget.offset.dy;
      final anchorTop = anchorBottom - leaderSize.height;
      final availableBelow = windowBottom - anchorBottom;
      final availableAbove = anchorTop - windowTop;
      desiredY = availableBelow > popupSize.height
          ? anchorBottom + 8
          : availableAbove > popupSize.height
          ? anchorTop - popupSize.height - 8
          : anchorTop + leaderSize.height / 2 - popupSize.height / 2;
    } else if (_prefersAbove) {
      final anchorTop = baseTopLeft.dy + popupSize.height - widget.offset.dy;
      desiredY = anchorTop - popupSize.height - 8;
    }
    desiredY = desiredY
        .clamp(safeTop, math.max(safeTop, safeBottom - popupSize.height))
        .toDouble();
    final next = Offset(desiredX - baseTopLeft.dx, desiredY - baseTopLeft.dy);
    if ((next - _correction).distance > .1 && mounted) {
      setState(() => _correction = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasurement();
    return CompositedTransformFollower(
      link: widget.link,
      showWhenUnlinked: false,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      child: Transform.translate(
        offset: _correction,
        child: UnconstrainedBox(
          alignment: widget.followerAnchor,
          child: SizedBox(key: _popupKey, child: widget.child),
        ),
      ),
    );
  }
}

/// Application scaffold with isolated popup state and MIUIX floating slots.
class MiuixScaffold extends StatefulWidget {
  /// Creates a scaffold.
  const MiuixScaffold({
    super.key,
    required this.body,
    this.topBar,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonPosition = MiuixFabPosition.end,
    this.floatingToolbar,
    this.floatingToolbarPosition = MiuixToolbarPosition.bottomCenter,
    this.snackbarHost,
    this.popupHost,
    this.drawer,
    this.backgroundColor,
    this.extendBody = false,
  });

  /// Main page body.
  final Widget body;

  /// Optional app bar.
  final PreferredSizeWidget? topBar;

  /// Optional bottom bar.
  final Widget? bottomBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Placement of [floatingActionButton].
  final MiuixFabPosition floatingActionButtonPosition;

  /// Optional floating toolbar.
  final Widget? floatingToolbar;

  /// Placement of [floatingToolbar].
  final MiuixToolbarPosition floatingToolbarPosition;

  /// Optional snackbar host rendered above other body content.
  final Widget? snackbarHost;

  /// Optional popup layer override. The default renders this scaffold's host.
  final Widget? popupHost;

  /// Optional drawer.
  final Widget? drawer;

  /// Optional background color.
  final Color? backgroundColor;

  /// Whether body painting continues behind a non-rectangular bottom bar.
  final bool extendBody;

  @override
  State<MiuixScaffold> createState() => _MiuixScaffoldState();
}

class _MiuixScaffoldState extends State<MiuixScaffold> {
  static const double _floatingSpacing = 12;
  final GlobalKey _bottomBarSizeKey = GlobalKey();
  MiuixPopupHostController? _popupController;
  MiuixPopupHostController? _parentController;
  MiuixTopAppBarScrollBehavior? _topBarScrollBehavior;
  double _bottomBarHeight = 0;
  bool _bottomBarMeasureScheduled = false;

  @override
  void initState() {
    super.initState();
    _attachTopBarScrollBehavior();
  }

  @override
  void didUpdateWidget(covariant MiuixScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bottomBar == null) {
      _bottomBarHeight = 0;
    }
    final nextBehavior = _behaviorOf(widget.topBar);
    if (!identical(nextBehavior, _topBarScrollBehavior)) {
      _topBarScrollBehavior?.removeListener(_handleTopBarChanged);
      _topBarScrollBehavior = nextBehavior;
      _topBarScrollBehavior?.addListener(_handleTopBarChanged);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parent = MiuixPopupHostScope.maybeOf(context);
    if (_popupController == null || parent != _parentController) {
      _popupController?.dispose();
      _parentController = parent;
      _popupController = MiuixPopupHostController(parent: parent);
    }
  }

  @override
  void dispose() {
    _topBarScrollBehavior?.removeListener(_handleTopBarChanged);
    _popupController?.dispose();
    super.dispose();
  }

  MiuixTopAppBarScrollBehavior? _behaviorOf(PreferredSizeWidget? topBar) {
    return topBar is MiuixTopAppBar ? topBar.scrollBehavior : null;
  }

  void _attachTopBarScrollBehavior() {
    _topBarScrollBehavior = _behaviorOf(widget.topBar);
    _topBarScrollBehavior?.addListener(_handleTopBarChanged);
  }

  void _handleTopBarChanged() {
    if (mounted) {
      // Scaffold reads preferredSize only while it builds. Rebuilding here lets
      // the body follow the collapsing MIUIX top bar without leaving a gap.
      setState(() {});
    }
  }

  bool _handleBodyScroll(ScrollNotification notification) {
    _topBarScrollBehavior?.handleNotification(notification);
    return false;
  }

  bool _handleBottomBarSizeChanged(SizeChangedLayoutNotification notification) {
    // SizeChangedLayoutNotifier may emit more than once while AnimatedSwitcher
    // transitions between regular and floating bars. Coalescing measurements
    // keeps those animation frames from scheduling redundant scaffold rebuilds.
    _scheduleBottomBarMeasurement();
    return false;
  }

  void _scheduleBottomBarMeasurement() {
    if (_bottomBarMeasureScheduled) {
      return;
    }
    _bottomBarMeasureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bottomBarMeasureScheduled = false;
      if (!mounted) {
        return;
      }
      final renderObject = _bottomBarSizeKey.currentContext?.findRenderObject();
      final nextHeight = renderObject is RenderBox && renderObject.hasSize
          ? renderObject.size.height
          : 0.0;
      if ((nextHeight - _bottomBarHeight).abs() > .5) {
        setState(() => _bottomBarHeight = nextHeight);
      }
    });
  }

  AlignmentDirectional _toolbarAlignment(MiuixToolbarPosition position) {
    return switch (position) {
      MiuixToolbarPosition.topStart => AlignmentDirectional.topStart,
      MiuixToolbarPosition.centerStart => AlignmentDirectional.centerStart,
      MiuixToolbarPosition.bottomStart => AlignmentDirectional.bottomStart,
      MiuixToolbarPosition.topEnd => AlignmentDirectional.topEnd,
      MiuixToolbarPosition.centerEnd => AlignmentDirectional.centerEnd,
      MiuixToolbarPosition.bottomEnd => AlignmentDirectional.bottomEnd,
      MiuixToolbarPosition.topCenter => AlignmentDirectional.topCenter,
      MiuixToolbarPosition.bottomCenter => AlignmentDirectional.bottomCenter,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final controller = _popupController!;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Compose rounds FabSpacing as an independent Dp placement value. At
    // 420dpi, 12dp is 32 physical pixels rather than Flutter's fractional
    // 31.5px, which otherwise moves an end-aligned FAB one pixel inward.
    final sourceFloatingSpacing = _miuixRoundLogicalDimension(
      _floatingSpacing,
      pixelRatio,
    );
    final bottomBarUsesGlass = switch (widget.bottomBar) {
      final MiuixNavigationBar bottomBar => bottomBar.glass,
      final MiuixFloatingNavigationBar bottomBar => bottomBar.glass,
      final MiuixIosLiquidGlassNavigationBar bottomBar => bottomBar.showBlur,
      _ => false,
    };
    final effectiveExtendBody =
        widget.extendBody ||
        bottomBarUsesGlass ||
        widget.floatingActionButtonPosition == MiuixFabPosition.endOverlay;
    // A normal Flutter Scaffold shortens its body above bottomNavigationBar,
    // so only the source spacing is needed there. An extended body keeps the
    // complete window height and must explicitly subtract the measured bar,
    // exactly like Scaffold.kt's bottomBarPlaceable.height branch.
    final floatingBottom =
        widget.bottomBar == null ||
            widget.floatingActionButtonPosition == MiuixFabPosition.endOverlay
        ? sourceFloatingSpacing + bottomInset
        : effectiveExtendBody
        ? sourceFloatingSpacing + _bottomBarHeight
        : sourceFloatingSpacing;
    if (widget.bottomBar != null) {
      // SizeChangedLayoutNotifier reports later changes but not every initial
      // layout, so schedule one explicit first-frame measurement as well.
      _scheduleBottomBarMeasurement();
    }
    final content = Stack(
      children: [
        Positioned.fill(
          child: _MiuixTopBarScrollConnector(
            behavior: _topBarScrollBehavior,
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleBodyScroll,
              child: widget.body,
            ),
          ),
        ),
        if (widget.floatingActionButton != null &&
            widget.floatingActionButtonPosition != MiuixFabPosition.center)
          PositionedDirectional(
            start: switch (widget.floatingActionButtonPosition) {
              MiuixFabPosition.start => sourceFloatingSpacing,
              MiuixFabPosition.center => null,
              MiuixFabPosition.end || MiuixFabPosition.endOverlay => null,
            },
            end: switch (widget.floatingActionButtonPosition) {
              MiuixFabPosition.start || MiuixFabPosition.center => null,
              MiuixFabPosition.end ||
              MiuixFabPosition.endOverlay => sourceFloatingSpacing,
            },
            bottom: floatingBottom,
            child: widget.floatingActionButton!,
          ),
        if (widget.floatingActionButton != null &&
            widget.floatingActionButtonPosition == MiuixFabPosition.center)
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: floatingBottom,
            child: Align(child: widget.floatingActionButton!),
          ),
        if (widget.floatingToolbar != null)
          Positioned.fill(
            child: Transform.translate(
              // The original Scaffold lifts the aligned toolbar by 4dp;
              // outside edge spacing belongs to FloatingToolbar itself.
              offset: const Offset(0, -4),
              child: Align(
                alignment: _toolbarAlignment(widget.floatingToolbarPosition),
                child: widget.floatingToolbar,
              ),
            ),
          ),
      ],
    );
    final scaffold = Scaffold(
      // A BackdropFilter needs the body to be painted in the same region. The
      // glass flags therefore opt into extension automatically for direct
      // bar children; wrapped bars can still request extendBody explicitly.
      extendBody: effectiveExtendBody,
      // Compose MIUIX always places page content at y=0 and reports the
      // current top-bar height as content padding.  The first list item is
      // therefore below the title initially, but can scroll through the
      // app-bar layer after that padding is consumed.  This geometry is not
      // conditional on glass: an opaque bar simply hides the passing item,
      // while a glass bar reveals it through the backdrop filter.
      extendBodyBehindAppBar: widget.topBar != null,
      appBar: widget.topBar,
      body: content,
      bottomNavigationBar: widget.bottomBar == null
          ? null
          : SizeChangedLayoutNotifier(
              child: SizedBox(key: _bottomBarSizeKey, child: widget.bottomBar),
            ),
      drawer: widget.drawer,
      backgroundColor: widget.backgroundColor ?? scheme.surface,
    );
    // Flutter paints Scaffold.bottomNavigationBar after its body.  Keeping the
    // snackbar host inside `content` therefore allowed an opaque or glass tab
    // bar to cover the lower edge of a transient message even when its geometry
    // had been lifted correctly.  Compose measures the snackbar against the
    // bottom bar, then gives it an independent placement layer.  This outer
    // stack reproduces that contract: the host is offset by the complete bar
    // height and is also painted after the bar.
    final snackbarBottom = widget.bottomBar == null
        ? bottomInset
        : _bottomBarHeight > .5
        ? _bottomBarHeight
        // The first frame precedes SizeChangedLayoutNotifier's callback.
        // A conservative regular-bar estimate prevents a snackbar queued
        // during startup from flashing behind Android's gesture region.
        : bottomInset + 64;
    return MiuixPopupHostScope(
      controller: controller,
      child: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: _handleBottomBarSizeChanged,
        child: Stack(
          children: [
            Positioned.fill(child: scaffold),
            if (widget.snackbarHost != null)
              PositionedDirectional(
                key: const ValueKey('miuix-scaffold-snackbar-layer'),
                start: 0,
                end: 0,
                bottom: snackbarBottom,
                child: widget.snackbarHost!,
              ),
            // Compose's popup layer belongs to the complete scaffold, not to
            // its content slot.  Painting this host last lets modal sheets and
            // dialogs cover the app navigation bar while still drawing behind
            // Android's transparent gesture area, matching the source sample.
            Positioned.fill(
              child: controller.parent == null
                  ? widget.popupHost ??
                        MiuixPopupHostView(controller: controller)
                  : ClipRect(
                      key: const ValueKey('miuix-popup-host-clip'),
                      child:
                          widget.popupHost ??
                          MiuixPopupHostView(controller: controller),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Connects a scaffold bar to the authoritative descendant ScrollPosition.
///
/// ScrollNotification covers gestures but may miss a PageStorage restoration
/// performed while elements are attaching. Reading the position after layout
/// handles that path and keeps later programmatic jumps synchronized as well.
class _MiuixTopBarScrollConnector extends StatefulWidget {
  const _MiuixTopBarScrollConnector({
    required this.behavior,
    required this.child,
  });

  final MiuixTopAppBarScrollBehavior? behavior;
  final Widget child;

  @override
  State<_MiuixTopBarScrollConnector> createState() =>
      _MiuixTopBarScrollConnectorState();
}

class _MiuixTopBarScrollConnectorState
    extends State<_MiuixTopBarScrollConnector> {
  ScrollPosition? _position;
  bool _attachmentScheduled = false;

  @override
  void didUpdateWidget(covariant _MiuixTopBarScrollConnector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.behavior, widget.behavior)) {
      _detach();
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    _position?.removeListener(_syncPosition);
    _position = null;
  }

  void _scheduleAttachment() {
    if (_attachmentScheduled || widget.behavior == null) return;
    _attachmentScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachmentScheduled = false;
      if (!mounted) return;
      final nextPosition = _findVerticalPosition();
      if (!identical(nextPosition, _position)) {
        _detach();
        _position = nextPosition;
        _position?.addListener(_syncPosition);
      }
      _syncPosition();
    });
  }

  ScrollPosition? _findVerticalPosition() {
    ScrollPosition? result;
    void visit(Element element) {
      if (result != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        final scrollable = element.state as ScrollableState;
        if (axisDirectionToAxis(scrollable.axisDirection) == Axis.vertical) {
          result = scrollable.position;
          return;
        }
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    return result;
  }

  void _syncPosition() {
    final position = _position;
    if (position != null && position.hasPixels) {
      widget.behavior?.syncMetrics(position);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleAttachment();
    return widget.child;
  }
}

/// Immutable colors used by source-compatible MIUIX tab rows.
@immutable
class MiuixTabRowColors {
  /// Creates an explicit tab-row color set.
  const MiuixTabRowColors({
    required this.backgroundColor,
    required this.contentColor,
    required this.selectedBackgroundColor,
    required this.selectedContentColor,
  });

  /// Background behind every tab and the moving indicator.
  final Color backgroundColor;

  /// Foreground used by unselected labels.
  final Color contentColor;

  /// Fill of the selected-tab indicator.
  final Color selectedBackgroundColor;

  /// Foreground used by the selected label.
  final Color selectedContentColor;

  /// Resolves the foreground for one tab.
  Color contentColorFor(bool selected) {
    return selected ? selectedContentColor : contentColor;
  }

  /// Returns a copy with independently replaced channels.
  MiuixTabRowColors copyWith({
    Color? backgroundColor,
    Color? contentColor,
    Color? selectedBackgroundColor,
    Color? selectedContentColor,
  }) {
    return MiuixTabRowColors(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      contentColor: contentColor ?? this.contentColor,
      selectedBackgroundColor:
          selectedBackgroundColor ?? this.selectedBackgroundColor,
      selectedContentColor: selectedContentColor ?? this.selectedContentColor,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MiuixTabRowColors &&
            other.backgroundColor == backgroundColor &&
            other.contentColor == contentColor &&
            other.selectedBackgroundColor == selectedBackgroundColor &&
            other.selectedContentColor == selectedContentColor;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    contentColor,
    selectedBackgroundColor,
    selectedContentColor,
  );
}

/// Dimensions and theme-resolved colors from MIUIX `TabRowDefaults`.
abstract final class MiuixTabRowDefaults {
  /// Ordinary row height.
  static const double height = 42;

  /// Contoured row height.
  static const double contourHeight = 45;

  /// Ordinary tab corner radius.
  static const double cornerRadius = 12;

  /// Contoured tab corner radius.
  static const double contourCornerRadius = 8;

  /// Ordinary minimum tab width.
  static const double minWidth = 76;

  /// Contoured minimum tab width.
  static const double contourMinWidth = 62;

  /// Ordinary maximum tab width.
  static const double maxWidth = 98;

  /// Contoured maximum tab width.
  static const double contourMaxWidth = 84;

  /// Ordinary gap between tabs.
  static const double itemSpacing = 9;

  /// Contoured gap between tabs.
  static const double contourItemSpacing = 5;

  /// Insets between the contour surface and its tab items.
  static const double contourPadding = 5;

  /// Resolves the four source color roles with independent overrides.
  static MiuixTabRowColors tabRowColors(
    BuildContext context, {
    Color? backgroundColor,
    Color? contentColor,
    Color? selectedBackgroundColor,
    Color? selectedContentColor,
  }) {
    final semantic = MiuixSemanticColors.of(context);
    return MiuixTabRowColors(
      backgroundColor: backgroundColor ?? semantic['surface'],
      contentColor: contentColor ?? semantic['onSurfaceVariantSummary'],
      selectedBackgroundColor:
          selectedBackgroundColor ?? semantic['surfaceContainer'],
      selectedContentColor: selectedContentColor ?? semantic['onBackground'],
    );
  }
}

/// Tab bar wrapper for text tabs.
class MiuixTabBar extends StatefulWidget {
  /// Creates a tab bar.
  const MiuixTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.selectedTabIndex,
    this.onTabSelected,
    this.onTap,
    this.colors,
    this.minWidth = MiuixTabRowDefaults.minWidth,
    this.maxWidth = MiuixTabRowDefaults.maxWidth,
    this.height = MiuixTabRowDefaults.height,
    this.cornerRadius = MiuixTabRowDefaults.cornerRadius,
    this.itemSpacing = MiuixTabRowDefaults.itemSpacing,
    this.contentAlignment = Alignment.center,
    this.interactionSource,
    this.showIndication = false,
  }) : assert(minWidth >= 0),
       assert(maxWidth >= minWidth),
       assert(height >= 0),
       assert(cornerRadius >= 0),
       assert(itemSpacing >= 0),
       withContour = false;

  const MiuixTabBar.contour({
    super.key,
    required this.tabs,
    this.controller,
    this.selectedTabIndex,
    this.onTabSelected,
    this.onTap,
    this.colors,
    this.minWidth = MiuixTabRowDefaults.contourMinWidth,
    this.maxWidth = MiuixTabRowDefaults.contourMaxWidth,
    this.height = MiuixTabRowDefaults.contourHeight,
    this.cornerRadius = MiuixTabRowDefaults.contourCornerRadius,
    this.itemSpacing = MiuixTabRowDefaults.contourItemSpacing,
    this.contentAlignment = Alignment.center,
    this.interactionSource,
    this.showIndication = false,
  }) : assert(minWidth >= 0),
       assert(maxWidth >= minWidth),
       assert(height >= MiuixTabRowDefaults.contourPadding * 2),
       assert(cornerRadius >= 0),
       assert(itemSpacing >= 0),
       withContour = true;

  /// Tab labels.
  final List<String> tabs;

  /// Optional tab controller.
  ///
  /// This is the Flutter compatibility path. Source-style call sites should
  /// prefer [selectedTabIndex] and [onTabSelected].
  final TabController? controller;

  /// Source-controlled selected tab index.
  ///
  /// When supplied, tapping a tab never mutates selection locally. The owner
  /// must publish the next index, matching MIUIX `TabRow`.
  final int? selectedTabIndex;

  /// Source selection callback.
  final ValueChanged<int>? onTabSelected;

  /// Backward-compatible tap callback.
  final ValueChanged<int>? onTap;

  /// Explicit source color contract, or theme defaults when omitted.
  final MiuixTabRowColors? colors;

  /// Minimum width allocated to one tab.
  final double minWidth;

  /// Maximum width allocated to one tab while the row needs scrolling.
  final double maxWidth;

  /// Complete row height.
  final double height;

  /// Continuous corner radius of each tab and its indicator.
  final double cornerRadius;

  /// Horizontal gap between adjacent tabs.
  final double itemSpacing;

  /// Alignment of each label inside its tab.
  final AlignmentGeometry contentAlignment;

  /// Optional observer shared by the source tab items.
  final MiuixInteractionSource? interactionSource;

  /// Whether to paint the optional MIUIX indication layer while interacting.
  ///
  /// The source accepts a nullable Compose `Indication`; `false` represents
  /// its default `null`, while `true` selects this library's exact MIUIX
  /// indication implementation.
  final bool showIndication;

  /// Whether this tab row should use MIUIX TabRowWithContour metrics.
  final bool withContour;

  @override
  State<MiuixTabBar> createState() => _MiuixTabBarState();
}

class _MiuixTabBarState extends State<MiuixTabBar> {
  TabController? _controller;
  final ScrollController _scrollController = ScrollController();
  int _localIndex = 0;
  double? _lastScrollTarget;
  bool _initialIndicatorTargetApplied = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant MiuixTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncController();
    }
    final controller = _controller;
    if (controller != null && controller.index >= widget.tabs.length) {
      _localIndex = widget.tabs.isEmpty ? 0 : widget.tabs.length - 1;
    }
    if (_localIndex >= widget.tabs.length) {
      _localIndex = widget.tabs.isEmpty ? 0 : widget.tabs.length - 1;
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChange);
    _scrollController.dispose();
    super.dispose();
  }

  void _syncController() {
    final next = widget.controller ?? DefaultTabController.maybeOf(context);
    if (identical(next, _controller)) {
      return;
    }
    _controller?.removeListener(_handleControllerChange);
    _controller = next;
    _controller?.addListener(_handleControllerChange);
    final tabsLength = widget.tabs.length;
    if (tabsLength <= 0) {
      _localIndex = 0;
      return;
    }
    final controllerIndex = _controller?.index ?? _localIndex;
    _localIndex = controllerIndex.clamp(0, tabsLength - 1);
  }

  void _handleControllerChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _select(int index) {
    // The original component is fully controlled: a click reports intent and
    // the indicator moves only after selectedTabIndex changes.
    if (widget.selectedTabIndex != null) {
      widget.onTabSelected?.call(index);
      widget.onTap?.call(index);
      return;
    }
    setState(() => _localIndex = index);
    final controller = _controller;
    if (controller != null && index >= 0 && index < controller.length) {
      controller.animateTo(index);
    }
    widget.onTabSelected?.call(index);
    widget.onTap?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final selected = widget.tabs.isEmpty
        ? 0
        : widget.selectedTabIndex != null
        ? widget.selectedTabIndex!.clamp(0, widget.tabs.length - 1)
        : controller == null
        ? _localIndex.clamp(0, widget.tabs.length - 1)
        : controller.index.clamp(0, widget.tabs.length - 1);
    // Animatable in TabRow.kt is remembered with an initial value of zero.
    // Its first LaunchedEffect then animates to selectedTabIndex, even when a
    // controlled row is initially created with a later item selected. An
    // AnimatedPositioned normally paints its first target immediately, so
    // retain zero for exactly the first frame and publish the real target in
    // the following frame. Later selection changes continue to retarget the
    // same 200 ms linear animation without an extra delay.
    final indicatorIndex = _initialIndicatorTargetApplied ? selected : 0;
    if (!_initialIndicatorTargetApplied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _initialIndicatorTargetApplied) {
          return;
        }
        setState(() => _initialIndicatorTargetApplied = true);
      });
    }
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    // Compose measures every Dp layout value through roundToPx before placing
    // the tab row. Keeping raw fractional physical pixels makes the 45 dp
    // contour row 118.125 px at 420 dpi and pushes its enclosing sample card
    // one pixel away from the source.
    final spacing = _miuixRoundLogicalDimension(widget.itemSpacing, pixelRatio);
    final minWidth = _miuixRoundLogicalDimension(widget.minWidth, pixelRatio);
    final maxWidth = _miuixRoundLogicalDimension(widget.maxWidth, pixelRatio);
    final outerHeight = _miuixRoundLogicalDimension(widget.height, pixelRatio);
    final contourPadding = widget.withContour
        ? _miuixRoundLogicalDimension(
            MiuixTabRowDefaults.contourPadding,
            pixelRatio,
          )
        : 0.0;
    final radius = widget.cornerRadius;
    final colors = widget.colors ?? MiuixTabRowDefaults.tabRowColors(context);
    final useSmoothRounding = MiuixTheme.of(context).enableSquircle;
    // TabRow.kt creates one `miuixShape(cornerRadius)` and reuses it for the
    // moving indicator and every clickable tab. This is not equivalent to a
    // circular BoxDecoration: smooth rounding extends each corner farther
    // along the straight edge, which is visible on the shallow 35/42 dp rows.
    final BorderRadius tabBorderRadius = BorderRadius.circular(radius);
    final ShapeBorder tabShape = useSmoothRounding
        ? MiuixSquircleBorder(borderRadius: tabBorderRadius)
        : RoundedRectangleBorder(borderRadius: tabBorderRadius);
    // The contour source adds the declared 5 dp to the declared 8 dp radius
    // before density conversion. `contourPadding` above is the separately
    // rounded layout inset, so adding it here would incorrectly produce
    // 12.952 dp rather than the source's exact 13 dp at Android 420 dpi.
    final BorderRadius contourBorderRadius = BorderRadius.circular(
      radius + MiuixTabRowDefaults.contourPadding,
    );
    final ShapeBorder contourShape = useSmoothRounding
        ? MiuixSquircleBorder(borderRadius: contourBorderRadius)
        : RoundedRectangleBorder(borderRadius: contourBorderRadius);
    return LayoutBuilder(
      builder: (context, constraints) {
        final outerWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final availableWidth = math.max(0.0, outerWidth - contourPadding * 2);
        final tabWidth = debugMiuixTabWidth(
          tabCount: widget.tabs.length,
          minWidth: minWidth,
          maxWidth: maxWidth,
          spacing: spacing,
          availableWidth: availableWidth,
        );
        final contentWidth =
            tabWidth * widget.tabs.length +
            spacing * math.max(0, widget.tabs.length - 1);
        _centerSelectedTab(
          selected: selected,
          tabWidth: tabWidth,
          spacing: spacing,
          viewportWidth: availableWidth,
          contentWidth: contentWidth,
        );
        final row = SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            width: math.max(availableWidth, contentWidth),
            height: outerHeight - contourPadding * 2,
            child: Stack(
              children: [
                AnimatedPositionedDirectional(
                  key: const ValueKey('miuix-tab-indicator'),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.linear,
                  start: indicatorIndex * (tabWidth + spacing),
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: DecoratedBox(
                    key: const ValueKey('miuix-tab-indicator-surface'),
                    decoration: ShapeDecoration(
                      color: colors.selectedBackgroundColor,
                      shape: tabShape,
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (
                      var index = 0;
                      index < widget.tabs.length;
                      index++
                    ) ...[
                      if (index > 0) SizedBox(width: spacing),
                      _MiuixTabButton(
                        key: ValueKey('miuix-tab-$index'),
                        label: widget.tabs[index],
                        selected: index == selected,
                        withContour: widget.withContour,
                        width: tabWidth,
                        height: outerHeight - contourPadding * 2,
                        cornerRadius: radius,
                        contentAlignment: widget.contentAlignment,
                        foreground: colors.contentColorFor(index == selected),
                        interactionSource: widget.interactionSource,
                        showIndication: widget.showIndication,
                        onTap: () => _select(index),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
        if (!widget.withContour) {
          return ColoredBox(
            color: colors.backgroundColor,
            child: SizedBox(height: outerHeight, child: row),
          );
        }
        // Compose applies clip(outerShape), paints the surface background, and
        // only then inserts the 5 dp content padding. ShapeDecoration supplies
        // the same ShapeBorder path to Container's anti-aliased clip.
        return Container(
          key: const ValueKey('miuix-contour-tab-surface'),
          height: outerHeight,
          padding: EdgeInsets.all(contourPadding),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: colors.backgroundColor,
            shape: contourShape,
          ),
          child: row,
        );
      },
    );
  }

  void _centerSelectedTab({
    required int selected,
    required double tabWidth,
    required double spacing,
    required double viewportWidth,
    required double contentWidth,
  }) {
    final maxOffset = math.max(0.0, contentWidth - viewportWidth);
    final target =
        (selected * (tabWidth + spacing) - (viewportWidth - tabWidth) / 2)
            .clamp(0.0, maxOffset);
    if (_lastScrollTarget != null &&
        (_lastScrollTarget! - target).abs() < .01) {
      return;
    }
    _lastScrollTarget = target;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 200),
        curve: Curves.linear,
      );
    });
  }
}

class _MiuixTabButton extends StatelessWidget {
  const _MiuixTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.withContour,
    required this.width,
    required this.height,
    required this.cornerRadius,
    required this.contentAlignment,
    required this.foreground,
    required this.interactionSource,
    required this.showIndication,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool withContour;
  final double width;
  final double height;
  final double cornerRadius;
  final AlignmentGeometry contentAlignment;
  final Color foreground;
  final MiuixInteractionSource? interactionSource;
  final bool showIndication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      role: SemanticsRole.tab,
      selected: selected,
      child: SizedBox(
        width: width,
        height: height,
        child: MiuixPressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(cornerRadius),
          feedbackType: MiuixPressFeedbackType.none,
          interactionSource: interactionSource,
          showIndication: showIndication,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: withContour ? 0 : 12),
            child: Align(
              alignment: contentAlignment,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: foreground,
                  fontSize: withContour ? 14 : 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Applies the source width allocation used by both MIUIX tab rows.
@visibleForTesting
double debugMiuixTabWidth({
  required int tabCount,
  required double minWidth,
  required double maxWidth,
  required double spacing,
  required double availableWidth,
}) {
  if (tabCount <= 0) {
    return minWidth;
  }
  final totalSpacing = math.max(0, tabCount - 1) * spacing;
  final contentWidth = availableWidth - totalSpacing;
  if (contentWidth <= 0) {
    return minWidth;
  }
  final idealWidth = contentWidth / tabCount;
  if (idealWidth < minWidth) {
    return minWidth;
  }
  if (idealWidth > maxWidth) {
    final totalMaxWidth = maxWidth * tabCount + totalSpacing;
    return totalMaxWidth < availableWidth ? idealWidth : maxWidth;
  }
  return idealWidth;
}
