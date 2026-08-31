part of '../miuix_widgets.dart';

class _MiuixPopupLayoutDelegate extends SingleChildLayoutDelegate {
  const _MiuixPopupLayoutDelegate({
    required this.anchorRect,
    required this.alignment,
    required this.positioning,
    required this.textDirection,
    required this.safePadding,
    required this.devicePixelRatio,
    this.placementBounds,
    this.onLayoutPositionChanged,
  });

  final Rect anchorRect;
  final MiuixPopupAlignment alignment;
  final MiuixPopupPositioning positioning;
  final TextDirection textDirection;
  final EdgeInsets safePadding;
  final double devicePixelRatio;
  final ValueChanged<MiuixPopupLayoutPosition>? onLayoutPositionChanged;
  // Optional safe-window rectangle expressed in the popup host's local space.
  // Root window routes can derive it from their own size; nested Scaffold
  // hosts need the translated global bounds supplied by MiuixPopupHostView.
  final Rect? placementBounds;

  double get _verticalMargin =>
      positioning == MiuixPopupPositioning.dropdown ? 8 : 0;

  double get _horizontalMargin =>
      positioning == MiuixPopupPositioning.contextMenu ? 20 : 0;

  /// Converts Flutter logical geometry to the integer pixels used by the
  /// source PopupPositionProvider before doing its midpoint arithmetic.
  int _physicalPixels(double logicalPixels) =>
      (logicalPixels * devicePixelRatio).round();

  /// Returns the logical coordinate Flutter needs for final placement.
  ///
  /// Keeping this conversion at the boundary means every intermediate sum or
  /// division still follows Kotlin's integer behavior. It also prevents the
  /// overlay and separate-window paths from applying density rounding twice.
  /// The returned double remains suitable for subpixel Flutter composition.
  double _logicalPixels(int physicalPixels) =>
      physicalPixels / devicePixelRatio;

  bool get _alignEnd {
    final requestedEnd = switch (alignment) {
      MiuixPopupAlignment.end ||
      MiuixPopupAlignment.topEnd ||
      MiuixPopupAlignment.bottomEnd => true,
      _ => false,
    };
    return textDirection == TextDirection.rtl ? !requestedEnd : requestedEnd;
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final placementHeight =
        placementBounds?.height ?? constraints.maxHeight - safePadding.vertical;
    final availableHeight = math.max(
      0.0,
      placementHeight - _verticalMargin * 2,
    );
    return BoxConstraints(maxHeight: availableHeight);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final bounds =
        placementBounds ??
        Rect.fromLTRB(
          safePadding.left,
          safePadding.top,
          size.width - safePadding.right,
          size.height - safePadding.bottom,
        );
    final safeLeft = bounds.left;
    final windowTop = bounds.top;
    final safeRight = bounds.right;
    final windowBottom = bounds.bottom;
    final safeTop = windowTop + _verticalMargin;
    final safeBottom = windowBottom - _verticalMargin;

    // Dropdowns retain Flutter's exact composited horizontal edge. Context
    // menus reproduce Compose's IntOffset math because their 20dp margin can
    // land on a half physical pixel at Android's fractional densities.
    final horizontalMarginPixels = _physicalPixels(_horizontalMargin);
    final requestedX = positioning == MiuixPopupPositioning.contextMenu
        ? _logicalPixels(
            _alignEnd
                ? _physicalPixels(anchorRect.right) -
                      _physicalPixels(childSize.width) -
                      horizontalMarginPixels
                : _physicalPixels(anchorRect.left) + horizontalMarginPixels,
          )
        : _alignEnd
        ? anchorRect.right - childSize.width
        : anchorRect.left;
    final maxX = math.max(
      safeLeft,
      positioning == MiuixPopupPositioning.contextMenu
          ? _logicalPixels(
              _physicalPixels(safeRight) -
                  _physicalPixels(childSize.width) -
                  horizontalMarginPixels,
            )
          : safeRight - childSize.width,
    );
    final x = requestedX.clamp(safeLeft, maxX).toDouble();

    final marginPixels = _physicalPixels(_verticalMargin);
    final anchorTopPixels = _physicalPixels(anchorRect.top);
    final anchorHeightPixels = _physicalPixels(anchorRect.height);
    final childHeightPixels = _physicalPixels(childSize.height);
    final below = _logicalPixels(
      _physicalPixels(anchorRect.bottom) + marginPixels,
    );
    final above = _logicalPixels(
      anchorTopPixels - childHeightPixels - marginPixels,
    );
    // Kotlin Int division truncates each half independently. Reproducing that
    // order avoids a one-physical-pixel drift for odd anchor/popup extents.
    final centered = _logicalPixels(
      anchorTopPixels + anchorHeightPixels ~/ 2 - childHeightPixels ~/ 2,
    );
    final availableBelow = windowBottom - anchorRect.bottom;
    final availableAbove = anchorRect.top - windowTop;
    final requestedY = positioning == MiuixPopupPositioning.contextMenu
        ? switch (alignment) {
            MiuixPopupAlignment.bottomStart || MiuixPopupAlignment.bottomEnd =>
              _logicalPixels(_physicalPixels(anchorRect.bottom)),
            MiuixPopupAlignment.topStart || MiuixPopupAlignment.topEnd =>
              _logicalPixels(anchorTopPixels - childHeightPixels),
            _ =>
              availableBelow > childSize.height
                  ? below
                  : availableAbove > childSize.height
                  ? above
                  : centered,
          }
        : availableBelow > childSize.height
        ? below
        : availableAbove > childSize.height
        ? above
        : centered;
    final maxY = math.max(safeTop, safeBottom - childSize.height);
    final y = requestedY.clamp(safeTop, maxY).toDouble();
    final popupCenterY = y + childSize.height / 2;
    final anchorCenterY = anchorRect.top + anchorRect.height / 2;
    final distanceLeft = (x - anchorRect.left).abs();
    final distanceRight = (x + childSize.width - anchorRect.right).abs();
    final resolvedPosition = MiuixPopupLayoutPosition(
      showBelow: popupCenterY > anchorCenterY,
      showAbove: popupCenterY < anchorCenterY,
      isRightAligned: distanceRight < distanceLeft,
    );
    if (onLayoutPositionChanged != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        onLayoutPositionChanged?.call(resolvedPosition);
      });
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(covariant _MiuixPopupLayoutDelegate oldDelegate) {
    return anchorRect != oldDelegate.anchorRect ||
        alignment != oldDelegate.alignment ||
        positioning != oldDelegate.positioning ||
        textDirection != oldDelegate.textDirection ||
        safePadding != oldDelegate.safePadding ||
        placementBounds != oldDelegate.placementBounds ||
        onLayoutPositionChanged != oldDelegate.onLayoutPositionChanged ||
        devicePixelRatio != oldDelegate.devicePixelRatio;
  }
}

Future<T?> _showMiuixWindowPopupSurface<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 320,
  LayerLink? link,
  Rect? anchorRect,
  MiuixPopupAlignment alignment = MiuixPopupAlignment.bottomStart,
  MiuixPopupPositioning positioning = MiuixPopupPositioning.dropdown,
  bool enableWindowDim = true,
  VoidCallback? onDismissRequest,
  VoidCallback? onDismissFinished,
}) {
  if (!context.mounted) {
    return Future<T?>.value();
  }
  final routeTheme = Theme.of(context);
  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  final overlayRenderObject = navigator?.overlay?.context.findRenderObject();
  final localAnchorRect =
      anchorRect != null &&
          overlayRenderObject is RenderBox &&
          overlayRenderObject.attached
      ? Rect.fromPoints(
          overlayRenderObject.globalToLocal(anchorRect.topLeft),
          overlayRenderObject.globalToLocal(anchorRect.bottomRight),
        )
      : anchorRect;
  var dismissRequested = false;
  void requestDismiss() {
    if (!dismissRequested) {
      dismissRequested = true;
      onDismissRequest?.call();
    }
  }

  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    // ListPopup owns the independently timed 300/150ms dim layer. Leaving the
    // route barrier transparent prevents Flutter's route-wide fade from
    // stretching that layer across the 620ms fraction spring.
    barrierColor: Colors.transparent,
    transitionDuration: MiuixListPopupDefaults.fractionDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      final constrained = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      );
      var layoutPosition = _miuixPredictedPopupLayoutPosition(
        alignment,
        Directionality.of(context),
      );
      return StatefulBuilder(
        builder: (context, setRouteState) {
          final animatedSurface = _MiuixAnimatedListPopupSurface(
            animation: animation,
            position: layoutPosition,
            child: constrained,
          );
          final popup = localAnchorRect != null
              ? CustomSingleChildLayout(
                  delegate: _MiuixPopupLayoutDelegate(
                    anchorRect: localAnchorRect,
                    alignment: alignment,
                    positioning: positioning,
                    textDirection: Directionality.of(context),
                    safePadding: MediaQuery.paddingOf(context),
                    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
                    onLayoutPositionChanged: (position) {
                      if (position != layoutPosition) {
                        setRouteState(() => layoutPosition = position);
                      }
                    },
                  ),
                  child: animatedSurface,
                )
              : link == null
              ? Center(child: animatedSurface)
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CompositedTransformFollower(
                      link: link,
                      showWhenUnlinked: false,
                      targetAnchor: _miuixPopupAnchors(
                        context,
                        alignment,
                      ).target,
                      followerAnchor: _miuixPopupAnchors(
                        context,
                        alignment,
                      ).follower,
                      child: UnconstrainedBox(
                        alignment: _miuixPopupAnchors(
                          context,
                          alignment,
                        ).follower,
                        child: animatedSurface,
                      ),
                    ),
                  ],
                );
          return PopScope<Object?>(
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) {
                requestDismiss();
              }
            },
            child: Theme(
              data: routeTheme,
              child: Material(
                type: MaterialType.transparency,
                child: AnimatedBuilder(
                  animation: animation,
                  child: popup,
                  builder: (context, popup) {
                    final progress = _miuixListPopupProgress(animation);
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            requestDismiss();
                            Navigator.of(context, rootNavigator: true).pop();
                          },
                          child: enableWindowDim
                              ? Opacity(
                                  opacity: progress.dim.clamp(0.0, 1.0),
                                  child: ColoredBox(
                                    color: MiuixSemanticColors.of(
                                      context,
                                    )['windowDimming'],
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                        popup!,
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) => child,
  ).whenComplete(() {
    requestDismiss();
    onDismissFinished?.call();
  });
}

Future<T?> _showMiuixOverlayPopupSurface<T>({
  required BuildContext context,
  required Widget child,
  double maxWidth = 320,
  LayerLink? link,
  Rect? anchorRect,
  MiuixPopupAlignment alignment = MiuixPopupAlignment.bottomStart,
  MiuixPopupPositioning positioning = MiuixPopupPositioning.dropdown,
  bool enableWindowDim = true,
  bool renderInRootScaffold = true,
  VoidCallback? onDismissRequest,
  VoidCallback? onDismissFinished,
}) {
  final nearest = MiuixPopupHostScope.maybeOf(context);
  if (nearest == null) {
    throw FlutterError(
      'Overlay popup components require a MiuixScaffold or MiuixPopupHost.',
    );
  }
  final anchors = _miuixPopupAnchors(context, alignment);
  final controller = renderInRootScaffold ? nearest.root : nearest;
  return controller.show<T>(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
    link: link,
    anchorRect: anchorRect,
    popupAlignment: alignment,
    popupPositioning: positioning,
    targetAnchor: anchors.target,
    followerAnchor: anchors.follower,
    offset: _miuixPopupOffset(alignment),
    dimBackground: enableWindowDim,
    dimColor: MiuixSemanticColors.of(context)['windowDimming'],
    onDismissRequest: onDismissRequest,
    onDismissFinished: onDismissFinished,
  );
}

Future<void> _showMiuixDropdownMenu<T>({
  required BuildContext context,
  required List<MiuixDropdownEntry<T>> entries,
  List<MiuixDropdownGroup<T>> groups = const [],
  required ValueChanged<T> onSelected,
  Widget Function(ValueChanged<T> onSelected)? popupBuilder,
  required MiuixPopupPresentation presentation,
  LayerLink? link,
  Rect? anchorRect,
  MiuixPopupAlignment alignment = MiuixPopupAlignment.bottomStart,
  MiuixPopupPositioning positioning = MiuixPopupPositioning.dropdown,
  bool renderInRootScaffold = true,
  bool closeOnSelection = true,
  double popupMinWidth = 200,
  Offset popupAnchorOffset = Offset.zero,
}) {
  if (entries.isEmpty && groups.every((group) => group.entries.isEmpty)) {
    return Future<void>.value();
  }
  final navigator = Navigator.maybeOf(context, rootNavigator: true);
  final host = MiuixPopupHostScope.maybeOf(context);
  void select(T value) {
    if (closeOnSelection) {
      if (presentation == MiuixPopupPresentation.overlay) {
        (renderInRootScaffold ? host?.root : host)?.dismissTop();
      } else {
        if (navigator?.mounted == true && navigator!.canPop()) {
          navigator.pop();
        }
      }
    }
    onSelected(value);
  }

  final popup =
      popupBuilder?.call(select) ??
      MiuixListPopup<T>(
        entries: entries,
        groups: groups,
        minWidth: popupMinWidth,
        onSelected: select,
      );
  final adjustedAnchorRect = anchorRect?.shift(popupAnchorOffset);
  return presentation == MiuixPopupPresentation.overlay
      ? _showMiuixOverlayPopupSurface<void>(
          context: context,
          child: popup,
          link: link,
          anchorRect: adjustedAnchorRect,
          alignment: alignment,
          positioning: positioning,
          renderInRootScaffold: renderInRootScaffold,
        )
      : _showMiuixWindowPopupSurface<void>(
          context: context,
          child: popup,
          link: link,
          anchorRect: adjustedAnchorRect,
          alignment: alignment,
          positioning: positioning,
        );
}
