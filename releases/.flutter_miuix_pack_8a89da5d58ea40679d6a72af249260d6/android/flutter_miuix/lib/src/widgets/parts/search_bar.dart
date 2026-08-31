part of '../miuix_widgets.dart';

/// Source constants shared by [MiuixSearchBar] and [MiuixInputField].
///
/// These values are direct translations of `SearchBarDefaults` in MIUIX
/// 1.0.9. They remain public so migrated applications do not need to duplicate
/// source geometry in their own search-field slots.
abstract final class MiuixSearchBarDefaults {
  /// Horizontal and vertical margin inside the search-bar row.
  static const Size insideMargin = Size(12, 0);

  /// Minimum painted height of the input capsule.
  static const double inputFieldMinHeight = 45;

  /// Font size of the collapsed label.
  static const double inputFieldFontSize = 17;

  /// Directional padding before the default search vector.
  static const double leadingIconStartPadding = 16;

  /// Directional padding after the default search vector.
  static const double leadingIconEndPadding = 8;

  /// Directional padding before the default cleanup vector.
  static const double trailingIconStartPadding = 8;

  /// Directional padding after the default cleanup vector.
  static const double trailingIconEndPadding = 16;

  /// Intrinsic size declared by the source Search vector.
  static const double searchIconSize = 20;

  /// Intrinsic size declared by the source SearchCleanup vector.
  static const double cleanupIconSize = 18.199984;
}

/// Compose's default visibility spring used by SearchBar transitions.
@visibleForTesting
SpringDescription debugMiuixSearchVisibilitySpring() =>
    SpringDescription.withDampingRatio(mass: 1, stiffness: 400, ratio: 1);

/// Source `InputField` used inside a [MiuixSearchBar].
///
/// This is intentionally separate from [MiuixTextField]. Upstream MIUIX gives
/// the search input a capsule, search IME action, expansion/focus coupling,
/// cleanup affordance, and delayed collapse sequence that the ordinary text
/// field does not have.
class MiuixInputField extends StatefulWidget {
  /// Creates the controlled, source-shaped input field.
  const MiuixInputField({
    super.key,
    required this.query,
    required this.onQueryChange,
    required this.onSearch,
    required this.expanded,
    required this.onExpandedChange,
    this.label = '',
    this.enabled = true,
    this.textStyle,
    this.leadingIcon,
    this.trailingIcon,
    this.interactionSource,
    this.controller,
  });

  /// Creates a controller-backed compatibility form.
  ///
  /// The public source contract remains value based. This constructor only
  /// avoids selection loss for existing Flutter callers that already own a
  /// [TextEditingController].
  factory MiuixInputField.controller({
    Key? key,
    required TextEditingController controller,
    required bool expanded,
    required ValueChanged<bool> onExpandedChange,
    String label = '',
    bool enabled = true,
    TextStyle? textStyle,
    Widget? leadingIcon,
    Widget? trailingIcon,
    MiuixInteractionSource? interactionSource,
    ValueChanged<String>? onQueryChange,
    ValueChanged<String>? onSearch,
  }) {
    return MiuixInputField(
      key: key,
      query: controller.text,
      onQueryChange: onQueryChange ?? (_) {},
      onSearch: onSearch ?? (_) {},
      expanded: expanded,
      onExpandedChange: onExpandedChange,
      label: label,
      enabled: enabled,
      textStyle: textStyle,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      interactionSource: interactionSource,
      controller: controller,
    );
  }

  /// Current controlled query.
  final String query;

  /// Reports edits and source-driven cleanup.
  final ValueChanged<String> onQueryChange;

  /// Reports the Search IME action with the current query.
  final ValueChanged<String> onSearch;

  /// Whether the owning search bar is expanded.
  final bool expanded;

  /// Requests a new expansion state.
  final ValueChanged<bool> onExpandedChange;

  /// Label shown only while collapsed with an empty query.
  final String label;

  /// Whether the field accepts interaction.
  final bool enabled;

  /// Optional character-level style merged over MIUIX main text.
  final TextStyle? textStyle;

  /// Optional leading slot; no padding or tint is invented around it.
  final Widget? leadingIcon;

  /// Optional trailing slot; no padding or tint is invented around it.
  final Widget? trailingIcon;

  /// Optional hoisted press/focus interaction state.
  final MiuixInteractionSource? interactionSource;

  /// Optional controller-backed Flutter compatibility channel.
  final TextEditingController? controller;

  @override
  State<MiuixInputField> createState() => _MiuixInputFieldState();
}

class _MiuixInputFieldState extends State<MiuixInputField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _textAlpha;
  late MiuixInteractionSource _interactionSource;
  bool _ownsController = false;
  int _collapseGeneration = 0;

  String get _query => widget.controller?.text ?? widget.query;

  @override
  void initState() {
    super.initState();
    _attachController(widget.controller);
    _interactionSource =
        widget.interactionSource ?? MiuixInteractionSource();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
    _textAlpha = AnimationController.unbounded(vsync: this, value: 1);
    if (widget.expanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
    }
  }

  void _attachController(TextEditingController? external) {
    _ownsController = external == null;
    _controller = external ?? TextEditingController(text: widget.query);
    _controller.addListener(_handleControllerMutation);
  }

  void _detachController() {
    _controller.removeListener(_handleControllerMutation);
    if (_ownsController) {
      _controller.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant MiuixInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _detachController();
      _attachController(widget.controller);
    } else if (widget.controller == null &&
        widget.query != _controller.text) {
      _replaceControllerText(widget.query);
    }
    if (oldWidget.interactionSource != widget.interactionSource) {
      _interactionSource =
          widget.interactionSource ?? MiuixInteractionSource();
      _interactionSource.setFocused(_focusNode.hasFocus);
    }
    if (oldWidget.expanded != widget.expanded) {
      _collapseGeneration++;
      if (widget.expanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _requestFocus());
      } else {
        _runCollapseSequence(_collapseGeneration);
      }
    }
  }

  void _replaceControllerText(String value) {
    final selection = _controller.selection;
    _controller.value = _controller.value.copyWith(
      text: value,
      selection: TextSelection.collapsed(
        offset: math.min(value.length, math.max(0, selection.baseOffset)),
      ),
      composing: TextRange.empty,
    );
  }

  void _handleControllerMutation() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    _interactionSource.setFocused(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      widget.onExpandedChange(true);
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _requestFocus() {
    if (mounted && widget.expanded && widget.enabled) {
      _focusNode.requestFocus();
    }
  }

  Future<void> _runCollapseSequence(int generation) async {
    if (!_focusNode.hasFocus) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted || widget.expanded || generation != _collapseGeneration) {
      return;
    }
    if (_query.isNotEmpty) {
      final simulation = SpringSimulation(
        SpringDescription.withDampingRatio(
          mass: 1,
          stiffness: 1500,
          ratio: 1,
        ),
        _textAlpha.value,
        0,
        _textAlpha.velocity,
      );
      try {
        await _textAlpha.animateWith(simulation).orCancel;
      } on TickerCanceled {
        return;
      }
      if (!mounted || widget.expanded || generation != _collapseGeneration) {
        return;
      }
      _replaceControllerText('');
      widget.onQueryChange('');
      _textAlpha.value = 1;
    }
    _focusNode.unfocus();
  }

  void _handleChanged(String value) {
    widget.onQueryChange(value);
  }

  void _clear() {
    if (_query.isEmpty) {
      return;
    }
    _replaceControllerText('');
    widget.onQueryChange('');
  }

  @override
  void dispose() {
    _collapseGeneration++;
    _detachController();
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _textAlpha.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final materialTheme = Theme.of(context);
    final miuixTheme = MiuixTheme.of(context);
    final inheritedColor =
        _MiuixContentColor.maybeOf(context) ??
        DefaultTextStyle.of(context).style.color ??
        semantic['onSurface'];
    final baseStyle =
        materialTheme.textTheme.bodyLarge ??
        const TextStyle(fontSize: 17, fontWeight: FontWeight.w500);
    final inputStyle = baseStyle
        .copyWith(fontWeight: FontWeight.w500)
        .merge(widget.textStyle)
        .copyWith(color: inheritedColor);
    final labelStyle = const TextStyle(
      fontSize: MiuixSearchBarDefaults.inputFieldFontSize,
      fontWeight: FontWeight.w500,
    ).merge(widget.textStyle);
    final capsuleRadius = BorderRadius.circular(999);
    final ShapeBorder capsuleShape = miuixTheme.enableSquircle
        ? MiuixSquircleBorder(borderRadius: capsuleRadius)
        : RoundedRectangleBorder(borderRadius: capsuleRadius);
    final defaultLeading = Padding(
      key: const ValueKey('miuix-search-leading-slot'),
      padding: const EdgeInsetsDirectional.only(
        start: MiuixSearchBarDefaults.leadingIconStartPadding,
        end: MiuixSearchBarDefaults.leadingIconEndPadding,
      ),
      child: MiuixIcon(
        MiuixIcons.basic.search,
        size: MiuixSearchBarDefaults.searchIconSize,
        tint: semantic['onSurfaceContainerHigh'],
        contentDescription: 'Search',
      ),
    );
    final defaultTrailing = _MiuixSearchCleanupVisibility(
      visible: _query.isNotEmpty,
      child: Padding(
        key: const ValueKey('miuix-search-trailing-slot'),
        padding: const EdgeInsetsDirectional.only(
          start: MiuixSearchBarDefaults.trailingIconStartPadding,
          end: MiuixSearchBarDefaults.trailingIconEndPadding,
        ),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: MiuixPressable(
            onTap: _clear,
            borderRadius: capsuleRadius,
            feedbackType: MiuixPressFeedbackType.none,
            child: _MiuixSearchCleanupIcon(
              key: const ValueKey('miuix-search-bar-clear'),
              size: MiuixSearchBarDefaults.cleanupIconSize,
              color: semantic['onSurfaceContainerHighest'],
            ),
          ),
        ),
      ),
    );
    final labelText = _query.isNotEmpty || widget.expanded
        ? ''
        : widget.label;
    final field = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _requestFocus : null,
      child: DecoratedBox(
        key: const ValueKey('miuix-search-bar-container'),
        decoration: ShapeDecoration(
          color: semantic['surfaceContainerHigh'],
          shape: capsuleShape,
        ),
        child: Row(
          children: [
            widget.leadingIcon ?? defaultLeading,
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: MiuixSearchBarDefaults.inputFieldMinHeight,
                ),
                child: Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    if (labelText.isNotEmpty)
                      IgnorePointer(
                        child: Text(
                          labelText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: labelStyle.copyWith(
                            color: semantic['onSurfaceContainerHigh'],
                          ),
                        ),
                      ),
                    FadeTransition(
                      opacity: _textAlpha,
                      child: EditableText(
                        key: const ValueKey('miuix-search-bar-input'),
                        controller: _controller,
                        focusNode: _focusNode,
                        style: inputStyle,
                        cursorColor: semantic['primary'],
                        backgroundCursorColor: semantic['onSurface'],
                        maxLines: 1,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.search,
                        onChanged: _handleChanged,
                        onSubmitted: (_) => widget.onSearch(_query),
                        selectionColor: semantic['primary'].withValues(
                          alpha: .24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            widget.trailingIcon ?? defaultTrailing,
          ],
        ),
      ),
    );
    return Semantics(
      enabled: widget.enabled,
      textField: true,
      onTap: widget.enabled ? _requestFocus : null,
      child: IgnorePointer(
        ignoring: !widget.enabled,
        child: _MiuixSearchSemanticsTarget(
          key: const ValueKey('miuix-search-semantic-target'),
          child: field,
        ),
      ),
    );
  }
}

/// Default `fadeIn`/`fadeOut` visibility used by SearchCleanup.
///
/// Compose retains the child for the complete 150ms transition. Flutter's
/// implicit opacity widget does the same here and removes it only after exit.
class _MiuixSearchCleanupVisibility extends StatefulWidget {
  const _MiuixSearchCleanupVisibility({
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  State<_MiuixSearchCleanupVisibility> createState() =>
      _MiuixSearchCleanupVisibilityState();
}

class _MiuixSearchCleanupVisibilityState
    extends State<_MiuixSearchCleanupVisibility> {
  bool _mountedChild = false;

  @override
  void initState() {
    super.initState();
    _mountedChild = widget.visible;
  }

  @override
  void didUpdateWidget(covariant _MiuixSearchCleanupVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _mountedChild = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountedChild && !widget.visible) {
      return const SizedBox.shrink();
    }
    return AnimatedOpacity(
      opacity: widget.visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.linear,
      onEnd: () {
        if (mounted && !widget.visible) {
          setState(() => _mountedChild = false);
        }
      },
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: widget.child,
      ),
    );
  }
}

/// Retained-child visibility matching Compose expand/shrink transitions.
///
/// The outside action combines horizontal expansion with a slide from the
/// logical end and intentionally has no fade. Expanded results use the
/// ColumnScope default: vertical expansion plus opacity. Both source paths use
/// the medium-low critically damped spring and dispose content only after exit.
class _MiuixSearchVisibility extends StatefulWidget {
  const _MiuixSearchVisibility({
    required this.visible,
    required this.axis,
    required this.child,
    this.fade = false,
    this.slideFromEnd = false,
  });

  final bool visible;
  final Axis axis;
  final Widget child;
  final bool fade;
  final bool slideFromEnd;

  @override
  State<_MiuixSearchVisibility> createState() =>
      _MiuixSearchVisibilityState();
}

class _MiuixSearchVisibilityState extends State<_MiuixSearchVisibility>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  bool _retainChild = false;

  @override
  void initState() {
    super.initState();
    _retainChild = widget.visible;
    _progress = AnimationController.unbounded(
      vsync: this,
      value: widget.visible ? 1 : 0,
    )..addListener(_rebuild);
  }

  @override
  void didUpdateWidget(covariant _MiuixSearchVisibility oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _animateTo(widget.visible ? 1 : 0);
    }
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _animateTo(double target) async {
    if (target == 1 && !_retainChild) {
      setState(() => _retainChild = true);
    }
    try {
      await _progress
          .animateWith(
            SpringSimulation(
              debugMiuixSearchVisibilitySpring(),
              _progress.value,
              target,
              _progress.velocity,
            ),
          )
          .orCancel;
    } on TickerCanceled {
      return;
    }
    if (mounted && target == 0 && !widget.visible) {
      setState(() => _retainChild = false);
    }
  }

  @override
  void dispose() {
    _progress
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_retainChild) {
      return const SizedBox.shrink();
    }
    final progress = _progress.value.clamp(0.0, 1.0);
    Widget child = widget.child;
    if (widget.fade) {
      child = Opacity(opacity: progress, child: child);
    }
    if (widget.slideFromEnd) {
      child = FractionalTranslation(
        translation: Offset(
          Directionality.of(context) == TextDirection.ltr
              ? 1 - progress
              : progress - 1,
          0,
        ),
        child: child,
      );
    }
    return ClipRect(
      child: Align(
        alignment: widget.axis == Axis.horizontal
            ? AlignmentDirectional.centerEnd
            : Alignment.bottomCenter,
        widthFactor: widget.axis == Axis.horizontal ? progress : null,
        heightFactor: widget.axis == Axis.vertical ? progress : null,
        child: child,
      ),
    );
  }
}
