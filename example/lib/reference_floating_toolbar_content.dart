part of 'main.dart';

/// Fade-only adapter for source `AnimatedVisibility` call sites.
///
/// Unlike settings rows and navigation bars, the FloatingToolbar and FPS
/// monitor explicitly replace default expand/shrink transforms with only
/// `fadeIn()` and `fadeOut()`. Their children therefore stay at final size
/// throughout both transitions and leave the tree only after exit reaches zero.
class _ReferenceFadeOnlyVisibility extends StatefulWidget {
  const _ReferenceFadeOnlyVisibility({
    required this.visible,
    required this.child,
    required this.opacityKey,
    required this.hiddenKey,
  });

  final bool visible;
  final Widget child;
  final Key opacityKey;
  final Key hiddenKey;

  @override
  State<_ReferenceFadeOnlyVisibility> createState() =>
      _ReferenceFadeOnlyVisibilityState();
}

class _ReferenceFadeOnlyVisibilityState
    extends State<_ReferenceFadeOnlyVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opacity;
  late bool _includeChild;
  int _transitionGeneration = 0;

  @override
  void initState() {
    super.initState();
    _includeChild = widget.visible;
    _opacity = AnimationController.unbounded(
      vsync: this,
      value: widget.visible ? 1 : 0,
    )..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant _ReferenceFadeOnlyVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible == widget.visible) return;
    if (widget.visible) {
      setState(() => _includeChild = true);
    }
    _springTo(widget.visible);
  }

  /// Retargets from the live value and velocity, matching Transition reversal.
  void _springTo(bool visible) {
    final generation = ++_transitionGeneration;
    final target = visible ? 1.0 : 0.0;
    _opacity
        .animateWith(
          SpringSimulation(
            debugReferenceVisibilitySpring(),
            _opacity.value,
            target,
            _opacity.velocity,
            tolerance: const Tolerance(distance: .01, velocity: .01),
          ),
        )
        .whenCompleteOrCancel(() {
          if (!mounted || generation != _transitionGeneration) return;
          _opacity.value = target;
          if (!widget.visible) {
            setState(() => _includeChild = false);
          }
        });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _opacity
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_includeChild) {
      return SizedBox.shrink(key: widget.hiddenKey);
    }
    final opacity = _opacity.value.clamp(0.0, 1.0);
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: ReferenceLayerOpacity(
          key: widget.opacityKey,
          opacity: opacity,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Source `AnimatedContent` adapter used only by the FloatingToolbar sample.
///
/// AppContent.kt changes between a padded Row and Column with Compose's
/// default AnimatedContent transition. Flutter's AnimatedSwitcher keeps the
/// largest outgoing/incoming size until disposal, which turns the toolbar into
/// a temporary square. This adapter instead measures both children and drives
/// the container along the source medium-low size spring.
class _ReferenceFloatingToolbarAnimatedContent extends StatefulWidget {
  const _ReferenceFloatingToolbarAnimatedContent({
    required this.horizontal,
    required this.actions,
  });

  final bool horizontal;
  final List<Widget> actions;

  @override
  State<_ReferenceFloatingToolbarAnimatedContent> createState() =>
      _ReferenceFloatingToolbarAnimatedContentState();
}

class _ReferenceFloatingToolbarAnimatedContentState
    extends State<_ReferenceFloatingToolbarAnimatedContent>
    with TickerProviderStateMixin {
  late final AnimationController _incoming;
  late final AnimationController _outgoing;
  late final AnimationController _size;
  Widget? _outgoingContent;
  int _transitionGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Default AnimatedContent delays its 220ms incoming tween by 90ms.
    _incoming = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 310),
      value: 1,
    );
    // The previous content fades independently over the first 90ms.
    _outgoing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      value: 1,
    );
    _size = AnimationController.unbounded(vsync: this, value: 1);
  }

  @override
  void didUpdateWidget(
    covariant _ReferenceFloatingToolbarAnimatedContent oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horizontal == widget.horizontal) return;

    final generation = ++_transitionGeneration;
    _outgoingContent = _arrange(
      horizontal: oldWidget.horizontal,
      actions: oldWidget.actions,
      key: ValueKey<bool>(oldWidget.horizontal),
    );
    _incoming.forward(from: 0);
    _outgoing.forward(from: 0);
    _size.value = 0;
    _size
        .animateWith(
          SpringSimulation(
            debugReferenceVisibilitySpring(),
            0,
            1,
            0,
            tolerance: const Tolerance(distance: .01, velocity: .01),
          ),
        )
        .whenCompleteOrCancel(() {
          if (!mounted || generation != _transitionGeneration) return;
          _size.value = 1;
          setState(() => _outgoingContent = null);
        });
  }

  @override
  void dispose() {
    _incoming.dispose();
    _outgoing.dispose();
    _size.dispose();
    super.dispose();
  }

  Widget _arrange({
    required bool horizontal,
    required List<Widget> actions,
    required Key key,
  }) {
    return Padding(
      key: key,
      padding: const EdgeInsets.all(8),
      child: horizontal
          ? Row(mainAxisSize: MainAxisSize.min, spacing: 8, children: actions)
          : Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: actions,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomingProgress = CurvedAnimation(
      parent: _incoming,
      // 90 / (90 + 220): the target is invisible during the source delay.
      curve: const Interval(90 / 310, 1, curve: Curves.linear),
    );
    final current = FadeTransition(
      key: const ValueKey('reference-toolbar-incoming-opacity'),
      opacity: incomingProgress,
      child: ScaleTransition(
        key: const ValueKey('reference-toolbar-incoming-scale'),
        scale: Tween<double>(begin: .92, end: 1).animate(incomingProgress),
        alignment: AlignmentDirectional.topStart.resolve(
          Directionality.of(context),
        ),
        child: _arrange(
          horizontal: widget.horizontal,
          actions: widget.actions,
          key: ValueKey<bool>(widget.horizontal),
        ),
      ),
    );
    final previous = _outgoingContent == null
        ? null
        : IgnorePointer(
            child: ExcludeSemantics(
              child: FadeTransition(
                key: const ValueKey('reference-toolbar-outgoing-opacity'),
                opacity: ReverseAnimation(_outgoing),
                child: _outgoingContent!,
              ),
            ),
          );

    // Incoming content is last, matching AnimatedContent's equal-z-order rule.
    return _ReferenceAnimatedContentSize(
      progress: _size,
      children: <Widget>[if (previous != null) previous, current],
    );
  }
}

/// Two-child layout that interpolates measured old/new sizes.
///
/// The render object listens directly to the spring so the parent toolbar is
/// remeasured without rebuilding the icon subtrees on every simulation frame.
class _ReferenceAnimatedContentSize extends MultiChildRenderObjectWidget {
  const _ReferenceAnimatedContentSize({
    required this.progress,
    required super.children,
  });

  final Animation<double> progress;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderReferenceAnimatedContentSize(progress);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderReferenceAnimatedContentSize renderObject,
  ) {
    renderObject.progress = progress;
  }
}

class _ReferenceAnimatedContentParentData
    extends ContainerBoxParentData<RenderBox> {}

class _RenderReferenceAnimatedContentSize extends RenderBox
    with
        ContainerRenderObjectMixin<
          RenderBox,
          _ReferenceAnimatedContentParentData
        >,
        RenderBoxContainerDefaultsMixin<
          RenderBox,
          _ReferenceAnimatedContentParentData
        > {
  _RenderReferenceAnimatedContentSize(Animation<double> progress)
    : _progress = progress;

  Animation<double> _progress;

  set progress(Animation<double> value) {
    if (identical(value, _progress)) return;
    if (attached) _progress.removeListener(markNeedsLayout);
    _progress = value;
    if (attached) _progress.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ReferenceAnimatedContentParentData) {
      child.parentData = _ReferenceAnimatedContentParentData();
    }
  }

  @override
  void performLayout() {
    final loose = constraints.loosen();
    final oldChild = childCount > 1 ? firstChild : null;
    final newChild = lastChild;
    oldChild?.layout(loose, parentUsesSize: true);
    newChild?.layout(loose, parentUsesSize: true);

    final oldSize = oldChild?.size ?? newChild?.size ?? Size.zero;
    final newSize = newChild?.size ?? oldSize;
    final progress = _progress.value.clamp(0.0, 1.0);
    size = constraints.constrain(Size.lerp(oldSize, newSize, progress)!);

    RenderBox? child = firstChild;
    while (child != null) {
      final parentData =
          child.parentData! as _ReferenceAnimatedContentParentData;
      parentData.offset = Offset.zero;
      child = parentData.nextSibling;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;
    context.pushClipRect(
      needsCompositing,
      offset,
      // PaintingContext applies [offset] to the local clip rect. Supplying an
      // already translated rectangle shifts it twice and hides all actions
      // when BackdropFilter gives this render object a nonzero layer origin.
      Offset.zero & size,
      (context, offset) => defaultPaint(context, offset),
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (!(Offset.zero & size).contains(position)) return false;
    return defaultHitTestChildren(result, position: position);
  }
}
