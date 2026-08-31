part of '../miuix_widgets.dart';

/// Immutable platform-back progress payload shared by navigation surfaces.
@immutable
class MiuixNavBackEvent {
  const MiuixNavBackEvent({
    required this.progress,
    required this.swipeEdge,
    required this.touchY,
    this.frameTimeMillis = 0,
  });

  /// Gesture completion in the source driver's finite `[0, .999]` interval.
  final double progress;

  /// Physical screen edge that originated the platform gesture.
  final MiuixNavSwipeEdge swipeEdge;

  /// Vertical pointer position in logical pixels.
  final double touchY;

  /// Monotonic frame timestamp used for release-velocity estimation.
  final int frameTimeMillis;

  @override
  bool operator ==(Object other) =>
      other is MiuixNavBackEvent &&
      other.progress == progress &&
      other.swipeEdge == swipeEdge &&
      other.touchY == touchY &&
      other.frameTimeMillis == frameTimeMillis;

  @override
  int get hashCode => Object.hash(progress, swipeEdge, touchY, frameTimeMillis);
}

typedef MiuixPredictiveBackAdmission = bool Function(MiuixNavBackEvent event);

/// Bridges Flutter's predictive/discrete Back dispatch into one owner stream.
///
/// The most recently mounted enabled MIUIX back owner wins. This mirrors the
/// source dispatcher precedence and prevents a covered navigation display from
/// progressing underneath an open dialog, bottom sheet, or popup.
class MiuixPredictiveBackHandler extends StatefulWidget {
  const MiuixPredictiveBackHandler({
    super.key,
    this.enabled = true,
    this.canStart,
    required this.onProgress,
    required this.onCommit,
    required this.onCancel,
    required this.child,
  });

  final bool enabled;
  final MiuixPredictiveBackAdmission? canStart;
  final ValueChanged<MiuixNavBackEvent> onProgress;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final Widget child;

  @override
  State<MiuixPredictiveBackHandler> createState() =>
      _MiuixPredictiveBackHandlerState();
}

/// Explicit composition marker for content hosted in a separate app window.
///
/// Compose Android forwards between two navigation-event dispatchers. Flutter
/// routes each FlutterView's Back messages through WidgetsBinding already, so
/// this bridge preserves [child] without installing a duplicate observer.
class MiuixWindowNavigationEventBridge extends StatelessWidget {
  const MiuixWindowNavigationEventBridge({
    super.key,
    this.child = const SizedBox.shrink(),
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Process-local ownership order for every MIUIX predictive-back observer.
///
/// Flutter intentionally permits multiple WidgetsBindingObservers to accept a
/// gesture. MIUIX requires one terminal owner, so every observer registers one
/// stable token and accepts only while that token is last in composition order.
typedef _MiuixPredictiveBackEligibility =
    bool Function(PredictiveBackEvent? event);

class _MiuixPredictiveBackOwnerRegistry extends ChangeNotifier {
  _MiuixPredictiveBackOwnerRegistry._();

  static final instance = _MiuixPredictiveBackOwnerRegistry._();

  final List<({Object owner, _MiuixPredictiveBackEligibility isEligible})>
  _owners = [];

  void register(Object owner, _MiuixPredictiveBackEligibility isEligible) {
    _owners.removeWhere((entry) => identical(entry.owner, owner));
    _owners.add((owner: owner, isEligible: isEligible));
    notifyListeners();
  }

  void unregister(Object owner) {
    final before = _owners.length;
    _owners.removeWhere((entry) => identical(entry.owner, owner));
    if (_owners.length != before) notifyListeners();
  }

  bool isTop(Object owner, [PredictiveBackEvent? event]) {
    for (final entry in _owners.reversed) {
      if (!entry.isEligible(event)) continue;
      return identical(entry.owner, owner);
    }
    return false;
  }
}

class _MiuixPredictiveBackHandlerState extends State<MiuixPredictiveBackHandler>
    with WidgetsBindingObserver {
  bool _ownsGesture = false;
  bool _ownerUpdateScheduled = false;

  _MiuixPredictiveBackOwnerRegistry get _registry =>
      _MiuixPredictiveBackOwnerRegistry.instance;

  @override
  void initState() {
    super.initState();
    _registry
      ..register(this, _isEligible)
      ..addListener(_handleOwnerOrderChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  void _handleOwnerOrderChanged() {
    if (!mounted || _ownerUpdateScheduled) return;
    _ownerUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ownerUpdateScheduled = false;
      if (mounted) setState(() {});
    });
  }

  MiuixNavBackEvent _event(PredictiveBackEvent event) {
    final rawProgress = event.progress;
    final progress = rawProgress.isFinite ? rawProgress.clamp(0.0, .999) : 0.0;
    final rawTouchY = event.touchOffset?.dy ?? 0;
    final touchY = rawTouchY.isFinite ? rawTouchY : 0.0;
    return MiuixNavBackEvent(
      progress: progress,
      swipeEdge: switch (event.swipeEdge) {
        SwipeEdge.left => MiuixNavSwipeEdge.left,
        SwipeEdge.right => MiuixNavSwipeEdge.right,
      },
      touchY: touchY,
      frameTimeMillis:
          SchedulerBinding.instance.currentSystemFrameTimeStamp.inMilliseconds,
    );
  }

  bool _isEligible(PredictiveBackEvent? backEvent) {
    if (!widget.enabled || !(ModalRoute.of(context)?.isCurrent ?? true)) {
      return false;
    }
    return backEvent == null ||
        (widget.canStart?.call(_event(backEvent)) ?? true);
  }

  bool get _canOwnBack => _registry.isTop(this);

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    if (backEvent.isButtonEvent || !_registry.isTop(this, backEvent)) {
      return false;
    }
    final event = _event(backEvent);
    _ownsGesture = true;
    widget.onProgress(event);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    if (_ownsGesture) widget.onProgress(_event(backEvent));
  }

  @override
  void handleCancelBackGesture() {
    if (!_ownsGesture) return;
    _ownsGesture = false;
    widget.onCancel();
  }

  @override
  void handleCommitBackGesture() {
    if (!_ownsGesture) return;
    _ownsGesture = false;
    widget.onCommit();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _registry
      ..removeListener(_handleOwnerOrderChanged)
      ..unregister(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ownsDiscreteBack = _canOwnBack;
    return PopScope<Object?>(
      canPop: !ownsDiscreteBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && ownsDiscreteBack) widget.onCommit();
      },
      child: widget.child,
    );
  }
}
