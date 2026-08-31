part of '../miuix_widgets.dart';

/// Source dimensions used by [MiuixIconButton].
///
/// The values mirror `IconButtonDefaults` in MIUIX 1.0.9. The visible
/// placeable is 40dp by default; Android independently exposes a 48dp minimum
/// interactive target without increasing the measured layout size.
abstract final class MiuixIconButtonDefaults {
  /// Default minimum width of the visible placeable.
  static const double minWidth = 40;

  /// Default minimum height of the visible placeable.
  static const double minHeight = 40;

  /// Default continuous-corner radius.
  static const double cornerRadius = 40;

  /// Android's accessibility and pointer target around the visual placeable.
  static const double minimumInteractiveSize = 48;
}

/// Compact MIUIX icon action.
///
/// This is a direct Flutter counterpart of MIUIX `IconButton`. It deliberately
/// keeps the source's minimum-size rather than fixed-size contract, so larger
/// custom content can expand the button. The Android touch target is handled
/// by a render object and therefore does not alter toolbar measurement.
class MiuixIconButton extends StatefulWidget {
  /// Creates a source-compatible MIUIX icon button.
  ///
  /// [icon] is retained as the convenient API used by earlier releases of this
  /// package. [child] exposes the arbitrary content slot from the source API.
  /// Exactly one of them must be supplied.
  const MiuixIconButton({
    super.key,
    required this.onPressed,
    this.icon,
    this.child,
    this.enabled = true,
    this.holdDownState = false,
    this.backgroundColor,
    this.contentColor,
    this.cornerRadius = MiuixIconButtonDefaults.cornerRadius,
    this.minHeight = MiuixIconButtonDefaults.minHeight,
    this.minWidth = MiuixIconButtonDefaults.minWidth,
    this.tooltip,
    this.selected = false,
  }) : assert(
         (icon == null) != (child == null),
         'Provide exactly one of icon or child.',
       ),
       assert(cornerRadius >= 0),
       assert(minHeight >= 0),
       assert(minWidth >= 0);

  /// Convenience icon content.
  ///
  /// Use [child] instead when the source slot contains more than one widget.
  final Widget? icon;

  /// Arbitrary source-compatible content.
  final Widget? child;

  /// Callback invoked after a completed tap.
  ///
  /// A null callback disables the interaction for compatibility with ordinary
  /// Flutter controls. The source's explicit [enabled] switch is still applied
  /// independently when the callback is non-null.
  final VoidCallback? onPressed;

  /// Whether the clickable modifier is installed.
  ///
  /// MIUIX does not change the painted background or content tint when this is
  /// false; it only removes pointer, pressed-indication, and button semantics.
  final bool enabled;

  /// Keeps the MIUIX indication in its externally controlled held state.
  ///
  /// Popup anchors use this while their popup remains visible. Pointer press
  /// and hold-down each contribute 10% of `onBackground`, matching the source.
  final bool holdDownState;

  /// Optional button background.
  ///
  /// A null value corresponds to Compose `Color.Unspecified` and paints no
  /// visible fill. It remains unchanged when the button is disabled.
  final Color? backgroundColor;

  /// Optional inherited color for icon and text content.
  ///
  /// The original slot inherits `LocalContentColor`; Flutter callers may use
  /// this property to provide the equivalent local value. When omitted, the
  /// surrounding theme's surface foreground is used for legacy compatibility.
  final Color? contentColor;

  /// Radius passed to the MIUIX smooth-corner shape.
  final double cornerRadius;

  /// Minimum visible height before larger custom content is measured.
  final double minHeight;

  /// Minimum visible width before larger custom content is measured.
  final double minWidth;

  /// Optional package extension that shows a MIUIX tooltip.
  ///
  /// The source icon button has no tooltip parameter; its icon content owns
  /// the accessibility description. Reference-example usages therefore avoid
  /// this extension unless they are specifically demonstrating tooltips.
  final String? tooltip;

  /// Backward-compatible selected presentation.
  ///
  /// This is a Flutter package extension, not a source parameter. An explicit
  /// [backgroundColor] takes precedence over the selected container color.
  final bool selected;

  bool get _isInteractive => enabled && onPressed != null;

  @override
  State<MiuixIconButton> createState() => _MiuixIconButtonState();
}

class _MiuixIconButtonState extends State<MiuixIconButton> {
  bool _pointerPressed = false;

  void _setPointerPressed(bool value) {
    if (_pointerPressed == value || !mounted) {
      return;
    }
    setState(() => _pointerPressed = value);
  }

  @override
  void didUpdateWidget(covariant MiuixIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Compose removes the whole clickable modifier when disabled. Clear any
    // pointer state left by an in-flight gesture at the same transition.
    if (!widget._isInteractive && _pointerPressed) {
      _pointerPressed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final miuixTheme = MiuixTheme.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final effectiveMinWidth = _miuixRoundLogicalDimension(
      widget.minWidth,
      pixelRatio,
    );
    final effectiveMinHeight = _miuixRoundLogicalDimension(
      widget.minHeight,
      pixelRatio,
    );
    final borderRadius = BorderRadius.circular(widget.cornerRadius);
    final ShapeBorder shape = miuixTheme.enableSquircle
        ? MiuixSquircleBorder(borderRadius: borderRadius)
        : RoundedRectangleBorder(borderRadius: borderRadius);
    final background =
        widget.backgroundColor ??
        (widget.selected ? scheme.primaryContainer : Colors.transparent);
    final foreground = widget.contentColor ?? scheme.onSurface;
    final content = widget.child ?? widget.icon!;
    final targetGeometry = _MiuixIconButtonTargetOffset.maybeOf(context);
    final indicationAlpha = widget._isInteractive
        ? (_pointerPressed ? .10 : 0.0) + (widget.holdDownState ? .10 : 0.0)
        : 0.0;

    // Decoration and indication share the same smooth outline. Keeping the
    // constraints inside that clip reproduces defaultMinSize -> clip ->
    // background -> clickable from the upstream modifier chain.
    final visualSurface = DecoratedBox(
      key: const ValueKey('miuix-icon-button-surface'),
      decoration: ShapeDecoration(color: background, shape: shape),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: effectiveMinWidth,
                minHeight: effectiveMinHeight,
              ),
              // Width and height factors keep the Box equivalent shrink-wrap
              // behavior under a Row or Column's loose cross-axis constraint.
              child: Align(
                widthFactor: 1,
                heightFactor: 1,
                child: IconTheme(
                  data: IconThemeData(color: foreground),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(color: foreground),
                    child: content,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  key: const ValueKey('miuix-press-indication'),
                  opacity: indicationAlpha,
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.linear,
                  child: ColoredBox(
                    color: MiuixSemanticColors.of(context)['onBackground'],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget button = _MiuixIconButtonTouchTarget(
      enabled: widget._isInteractive,
      selected: widget.selected,
      semanticLabel: widget.tooltip,
      textDirection: Directionality.of(context),
      targetOffset: targetGeometry.offset,
      targetInsets: targetGeometry.insets,
      minimumSize: _miuixRoundLogicalDimension(
        MiuixIconButtonDefaults.minimumInteractiveSize,
        pixelRatio,
      ),
      onTap: widget.onPressed,
      onTapDown: () => _setPointerPressed(true),
      onTapUp: () => _setPointerPressed(false),
      onTapCancel: () => _setPointerPressed(false),
      child: visualSurface,
    );
    if (widget.tooltip != null) {
      button = MiuixTooltip(message: widget.tooltip!, child: button);
    }
    return button;
  }
}

/// Widget bridge for the non-layout-affecting Android interaction target.
///
/// A normal `SizedBox.square(48)` would move neighboring icons eight logical
/// pixels farther apart. Compose instead expands hit testing and semantics
/// around the 40dp placeable. This render object mirrors that distinction.
class _MiuixIconButtonTouchTarget extends SingleChildRenderObjectWidget {
  const _MiuixIconButtonTouchTarget({
    required this.enabled,
    required this.selected,
    required this.semanticLabel,
    required this.textDirection,
    required this.targetOffset,
    required this.targetInsets,
    required this.minimumSize,
    required this.onTap,
    required this.onTapDown,
    required this.onTapUp,
    required this.onTapCancel,
    required super.child,
  });

  final bool enabled;
  final bool selected;
  final String? semanticLabel;
  final TextDirection textDirection;
  final Offset targetOffset;
  final EdgeInsets targetInsets;
  final double minimumSize;
  final VoidCallback? onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapUp;
  final VoidCallback onTapCancel;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMiuixIconButtonTouchTarget(
      enabled: enabled,
      selected: selected,
      semanticLabel: semanticLabel,
      textDirection: textDirection,
      targetOffset: targetOffset,
      targetInsets: targetInsets,
      minimumSize: minimumSize,
      onTap: onTap,
      onTapDown: onTapDown,
      onTapUp: onTapUp,
      onTapCancel: onTapCancel,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMiuixIconButtonTouchTarget renderObject,
  ) {
    renderObject
      ..enabled = enabled
      ..selected = selected
      ..semanticLabel = semanticLabel
      ..textDirection = textDirection
      ..targetOffset = targetOffset
      ..targetInsets = targetInsets
      ..minimumSize = minimumSize
      ..onTap = onTap
      ..onTapDown = onTapDown
      ..onTapUp = onTapUp
      ..onTapCancel = onTapCancel;
  }
}

class _RenderMiuixIconButtonTouchTarget extends RenderProxyBox {
  _RenderMiuixIconButtonTouchTarget({
    required bool enabled,
    required bool selected,
    required String? semanticLabel,
    required TextDirection textDirection,
    required Offset targetOffset,
    required EdgeInsets targetInsets,
    required double minimumSize,
    required VoidCallback? onTap,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
  }) : _enabled = enabled,
       _selected = selected,
       _semanticLabel = semanticLabel,
       _textDirection = textDirection,
       _targetOffset = targetOffset,
       _targetInsets = targetInsets,
       _minimumSize = minimumSize,
       _onTap = onTap,
       _onTapDown = onTapDown,
       _onTapUp = onTapUp,
       _onTapCancel = onTapCancel {
    _tapRecognizer = TapGestureRecognizer(debugOwner: this);
    _syncRecognizer();
  }

  late final TapGestureRecognizer _tapRecognizer;
  bool _enabled;
  bool _selected;
  String? _semanticLabel;
  TextDirection _textDirection;
  Offset _targetOffset;
  EdgeInsets _targetInsets;
  double _minimumSize;
  VoidCallback? _onTap;
  VoidCallback _onTapDown;
  VoidCallback _onTapUp;
  VoidCallback _onTapCancel;

  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    _syncRecognizer();
    markNeedsSemanticsUpdate();
  }

  bool get selected => _selected;
  set selected(bool value) {
    if (_selected == value) return;
    _selected = value;
    markNeedsSemanticsUpdate();
  }

  String? get semanticLabel => _semanticLabel;
  set semanticLabel(String? value) {
    if (_semanticLabel == value) return;
    _semanticLabel = value;
    markNeedsSemanticsUpdate();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  Offset get targetOffset => _targetOffset;
  set targetOffset(Offset value) {
    if (_targetOffset == value) return;
    _targetOffset = value;
    markNeedsSemanticsUpdate();
  }

  EdgeInsets get targetInsets => _targetInsets;
  set targetInsets(EdgeInsets value) {
    if (_targetInsets == value) return;
    _targetInsets = value;
    markNeedsSemanticsUpdate();
  }

  double get minimumSize => _minimumSize;
  set minimumSize(double value) {
    if (_minimumSize == value) return;
    _minimumSize = value;
    markNeedsSemanticsUpdate();
  }

  VoidCallback? get onTap => _onTap;
  set onTap(VoidCallback? value) {
    if (_onTap == value) return;
    _onTap = value;
    _syncRecognizer();
    markNeedsSemanticsUpdate();
  }

  VoidCallback get onTapDown => _onTapDown;
  set onTapDown(VoidCallback value) {
    if (_onTapDown == value) return;
    _onTapDown = value;
    _syncRecognizer();
  }

  VoidCallback get onTapUp => _onTapUp;
  set onTapUp(VoidCallback value) {
    if (_onTapUp == value) return;
    _onTapUp = value;
    _syncRecognizer();
  }

  VoidCallback get onTapCancel => _onTapCancel;
  set onTapCancel(VoidCallback value) {
    if (_onTapCancel == value) return;
    _onTapCancel = value;
    _syncRecognizer();
  }

  Rect get _interactiveBounds {
    final targetWidth = math.max(size.width, minimumSize);
    final targetHeight = math.max(size.height, minimumSize);
    final expanded = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: targetWidth,
      height: targetHeight,
    ).shift(targetOffset);
    return Rect.fromLTRB(
      expanded.left + targetInsets.left,
      expanded.top + targetInsets.top,
      expanded.right - targetInsets.right,
      expanded.bottom - targetInsets.bottom,
    );
  }

  void _syncRecognizer() {
    _tapRecognizer
      ..onTap = enabled ? _onTap : null
      ..onTapDown = enabled ? (_) => _onTapDown() : null
      ..onTapUp = enabled ? (_) => _onTapUp() : null
      ..onTapCancel = enabled ? _onTapCancel : null;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!enabled || size.isEmpty || !_interactiveBounds.contains(position)) {
      return false;
    }
    // The render object owns the recognizer, so a pointer in the four-dp
    // expansion does not need to be artificially clamped into its child.
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is PointerDownEvent && enabled) {
      _tapRecognizer.addPointer(event);
    }
  }

  @override
  Rect get semanticBounds => _interactiveBounds;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config.isSemanticBoundary = true;
    if (!enabled) {
      // Upstream removes `Modifier.clickable` completely rather than exposing
      // a disabled button role. Child content semantics remain discoverable.
      return;
    }
    config
      ..isButton = true
      ..isEnabled = true
      ..isSelected = selected
      ..onTap = _onTap;
    if (_semanticLabel case final label? when label.isNotEmpty) {
      config
        ..label = label
        ..textDirection = textDirection;
    }
  }

  @override
  void dispose() {
    _tapRecognizer.dispose();
    super.dispose();
  }
}

/// Supplies a paint-independent interaction correction to top-bar buttons.
///
/// Compose rounds Android touch-bound coordinates toward the following
/// physical pixel at fractional densities. Flutter otherwise places the
/// semantic rectangle one pixel earlier on the vertical axis. The correction
/// is inherited so it never changes the button's visual layout or public API.
class _MiuixIconButtonTargetOffset extends InheritedWidget {
  const _MiuixIconButtonTargetOffset({
    required this.offset,
    this.insets = EdgeInsets.zero,
    required super.child,
  });

  final Offset offset;
  final EdgeInsets insets;

  static _MiuixIconButtonTargetOffset maybeOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<
              _MiuixIconButtonTargetOffset
            >() ??
        const _MiuixIconButtonTargetOffset(
          offset: Offset.zero,
          child: SizedBox.shrink(),
        );
  }

  @override
  bool updateShouldNotify(_MiuixIconButtonTargetOffset oldWidget) {
    return offset != oldWidget.offset || insets != oldWidget.insets;
  }
}
