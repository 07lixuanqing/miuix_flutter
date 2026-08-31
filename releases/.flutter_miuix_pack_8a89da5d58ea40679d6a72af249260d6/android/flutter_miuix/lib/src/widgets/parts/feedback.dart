part of '../miuix_widgets.dart';

/// Segmented control for small option sets.
class MiuixSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const MiuixSegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onSelectionChanged,
  });

  /// Segment values.
  final List<T> values;

  /// Currently selected values.
  final Set<T> selected;

  /// Label builder.
  final String Function(T value) labelBuilder;

  /// Selection callback.
  final ValueChanged<Set<T>> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: .88),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .2),
          width: .5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < values.length; index++)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  end: index == values.length - 1 ? 0 : 3,
                ),
                child: _MiuixSegmentButton<T>(
                  label: labelBuilder(values[index]),
                  selected: selected.contains(values[index]),
                  onTap: () {
                    final next = Set<T>.of(selected);
                    if (!next.add(values[index])) {
                      next.remove(values[index]);
                    }
                    onSelectionChanged(next);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiuixSegmentButton<T> extends StatelessWidget {
  const _MiuixSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onSurface
        : scheme.onSecondaryContainer;
    return Semantics(
      button: true,
      selected: selected,
      child: MiuixPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        feedbackType: MiuixPressFeedbackType.none,
        showIndication: true,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          height: 36,
          constraints: const BoxConstraints(minWidth: 58, maxWidth: 112),
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            color: selected ? scheme.surface : Colors.transparent,
            border: Border.all(
              color: selected
                  ? scheme.outlineVariant.withValues(alpha: .22)
                  : Colors.transparent,
              width: .5,
            ),
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: foreground,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Arrangement direction used by [MiuixFloatingToolbar].
enum MiuixFloatingToolbarOrientation {
  /// Place actions from start to end.
  horizontal,

  /// Place actions from top to bottom.
  vertical,
}

/// Public source defaults for [MiuixFloatingToolbar].
abstract final class MiuixFloatingToolbarDefaults {
  /// Default continuous-corner radius.
  static const double cornerRadius = 50;

  /// Default logical outside padding.
  static const EdgeInsets outSidePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 8,
  );

  /// Resolves `FloatingToolbarDefaults.defaultColor()`.
  static Color defaultColor(BuildContext context) {
    return MiuixSemanticColors.of(context)['surfaceContainer'];
  }
}

/// Floating toolbar matching MIUIX surface and shadow defaults.
class MiuixFloatingToolbar extends StatelessWidget {
  /// Creates a floating toolbar.
  const MiuixFloatingToolbar({
    super.key,
    this.child,
    this.children = const <Widget>[],
    this.orientation = MiuixFloatingToolbarOrientation.horizontal,
    this.color,
    this.cornerRadius = MiuixFloatingToolbarDefaults.cornerRadius,
    this.outSidePadding = MiuixFloatingToolbarDefaults.outSidePadding,
    this.outsidePadding,
    this.contentPadding = EdgeInsets.zero,
    this.spacing = 0,
    this.shadowElevation = 4,
    this.showDivider = false,
    this.glass = false,
  }) : assert(cornerRadius >= 0),
       assert(spacing >= 0),
       assert(shadowElevation >= 0);

  /// Arbitrary source-style toolbar content.
  ///
  /// Upstream does not arrange actions itself; its sample supplies a Row or
  /// Column as this slot. [children] remains the Flutter convenience adapter.
  final Widget? child;

  /// Convenience actions arranged by [orientation].
  final List<Widget> children;

  /// Horizontal or vertical action arrangement.
  final MiuixFloatingToolbarOrientation orientation;

  /// Surface color, defaulting to MIUIX `surfaceContainer`.
  final Color? color;

  /// Surface corner radius; the source component defaults to 50dp.
  final double cornerRadius;

  /// Source-named padding outside the painted toolbar.
  final EdgeInsetsGeometry outSidePadding;

  /// Legacy spelling retained for source compatibility with earlier releases.
  ///
  /// When supplied this takes precedence over [outSidePadding].
  final EdgeInsetsGeometry? outsidePadding;

  /// Padding around the arranged action content.
  final EdgeInsetsGeometry contentPadding;

  /// Gap between adjacent actions.
  final double spacing;

  /// Source graphics-layer shadow elevation.
  final double shadowElevation;

  /// Whether to draw the source 0.75dp outline.
  final bool showDivider;

  /// Optional compatibility path for callers explicitly requesting glass.
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final arranged =
        child ??
        (orientation == MiuixFloatingToolbarOrientation.horizontal
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: _spacedChildren(Axis.horizontal),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: _spacedChildren(Axis.vertical),
              ));
    final content = Padding(padding: contentPadding, child: arranged);
    final resolvedOutsidePadding = _miuixRoundedInsets(
      context,
      outsidePadding ?? outSidePadding,
    );
    final resolvedDividerPadding = _miuixRoundedInsets(
      context,
      const EdgeInsets.all(.75),
    );
    final corners = BorderRadius.circular(cornerRadius);
    final ShapeBorder shape = MiuixTheme.of(context).enableSquircle
        ? MiuixSquircleBorder(borderRadius: corners)
        : RoundedRectangleBorder(borderRadius: corners);
    final background =
        color ?? MiuixFloatingToolbarDefaults.defaultColor(context);
    final pointerContent = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTap: () {},
      child: content,
    );

    Widget surface;
    if (glass) {
      surface = MiuixGlass(
        key: const ValueKey('floating-toolbar-glass'),
        blur: 25,
        opacity: .60,
        color: background,
        radius: cornerRadius,
        padding: EdgeInsets.zero,
        child: pointerContent,
      );
    } else {
      final fill = ColoredBox(
        key: const ValueKey('miuix-floating-toolbar-fill'),
        color: background,
        child: pointerContent,
      );
      surface = cornerRadius > 0
          ? ClipPath(
              clipper: ShapeBorderClipper(shape: shape),
              child: fill,
            )
          : fill;
    }

    // graphicsLayer is created only for positive source elevation. Reuse the
    // package's calibrated 4dp elevation projection instead of Material Card
    // defaults, which have a different ambient/spot shadow split.
    if (shadowElevation > 0) {
      surface = DecoratedBox(
        key: const ValueKey('miuix-floating-toolbar-shadow'),
        decoration: ShapeDecoration(
          color: Colors.transparent,
          shape: shape,
          shadows: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: .20),
              blurRadius: shadowElevation * 2,
              offset: Offset(0, shadowElevation / 2),
            ),
          ],
        ),
        child: surface,
      );
    }

    // Source divider order is background(dividerLine) -> padding(0.75dp) ->
    // graphicsLayer/clip -> toolbar background. It therefore adds measurable
    // size around the inner surface rather than painting an inset BoxBorder.
    if (showDivider) {
      surface = DecoratedBox(
        key: const ValueKey('miuix-floating-toolbar-divider'),
        decoration: ShapeDecoration(
          color: semantic['dividerLine'],
          shape: shape,
        ),
        child: Padding(padding: resolvedDividerPadding, child: surface),
      );
    }

    return Padding(
      padding: resolvedOutsidePadding,
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        child: surface,
      ),
    );
  }

  List<Widget> _spacedChildren(Axis axis) {
    return [
      for (var index = 0; index < children.length; index++) ...[
        if (index > 0)
          SizedBox(
            width: axis == Axis.horizontal ? spacing : 0,
            height: axis == Axis.vertical ? spacing : 0,
          ),
        children[index],
      ],
    ];
  }
}

/// Tooltip wrapper with Miuix naming.
class MiuixTooltip extends StatelessWidget {
  /// Creates a tooltip.
  const MiuixTooltip({super.key, required this.message, required this.child});

  /// Tooltip message.
  final String message;

  /// Anchor widget.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _MiuixTooltipAnchor(message: message, child: child);
  }
}

/// Tooltip box adapter matching MIUIX `TooltipBox`.
class MiuixTooltipBox extends MiuixTooltip {
  /// Creates a tooltip box.
  const MiuixTooltipBox({
    super.key,
    required super.message,
    required super.child,
  });
}

/// Rich tooltip surface for multiline or custom tooltip content.
class MiuixRichTooltip extends StatelessWidget {
  /// Creates a rich tooltip.
  const MiuixRichTooltip({
    super.key,
    required this.child,
    required this.content,
    this.message,
  });

  /// Anchor widget.
  final Widget child;

  /// Custom tooltip content shown by semantics-friendly fallback.
  final Widget content;

  /// Optional plain-text tooltip message.
  final String? message;

  @override
  Widget build(BuildContext context) {
    final tooltipMessage = message ?? 'More information';
    return _MiuixTooltipAnchor(
      message: tooltipMessage,
      content: content,
      child: Semantics(
        label: tooltipMessage,
        tooltip: tooltipMessage,
        child: child,
      ),
    );
  }
}

class _MiuixTooltipAnchor extends StatefulWidget {
  const _MiuixTooltipAnchor({
    required this.message,
    required this.child,
    this.content,
  });

  final String message;
  final Widget child;
  final Widget? content;

  @override
  State<_MiuixTooltipAnchor> createState() => _MiuixTooltipAnchorState();
}

class _MiuixTooltipAnchorState extends State<_MiuixTooltipAnchor> {
  OverlayEntry? _entry;
  Timer? _hideTimer;
  bool _removingEntry = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    _removeEntry();
    super.dispose();
  }

  void _show() {
    if (!mounted) {
      return;
    }
    _hideTimer?.cancel();
    if (_entry != null || (widget.message.isEmpty && widget.content == null)) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final renderObject = context.findRenderObject();
    if (overlay == null ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return;
    }
    final box = renderObject;
    final topLeft = box.localToGlobal(Offset.zero);
    final target = topLeft & box.size;
    _entry = OverlayEntry(
      builder: (context) => _MiuixTooltipOverlay(
        message: widget.message,
        content: widget.content,
        target: target,
      ),
    );
    overlay.insert(_entry!);
    _hideTimer = Timer(const Duration(milliseconds: 1800), _removeEntry);
  }

  void _scheduleHide() {
    if (!mounted) {
      return;
    }
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 120), _removeEntry);
  }

  void _removeEntry() {
    if (_removingEntry) {
      return;
    }
    _removingEntry = true;
    _hideTimer?.cancel();
    if (_entry?.mounted == true) {
      _entry?.remove();
    }
    _entry = null;
    _removingEntry = false;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        onEnter: (_) => _show(),
        onExit: (_) => _scheduleHide(),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onLongPressStart: (_) => _show(),
          onLongPressEnd: (_) => _scheduleHide(),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MiuixTooltipOverlay extends StatelessWidget {
  const _MiuixTooltipOverlay({
    required this.message,
    required this.target,
    this.content,
  });

  final String message;
  final Rect target;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final screen = MediaQuery.sizeOf(context);
    final rich = content != null;
    final maxWidth = math.min(rich ? 320.0 : 280.0, screen.width - 24);
    final estimatedHeight = rich ? 112.0 : 44.0;
    final top = target.top > estimatedHeight + 12
        ? target.top - estimatedHeight - 8
        : target.bottom + 8;
    final left = (target.center.dx - maxWidth / 2)
        .clamp(12.0, math.max(12.0, screen.width - maxWidth - 12))
        .toDouble();
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontSize: 13,
      height: 1.28,
      fontWeight: FontWeight.w500,
    );
    return Positioned(
      left: left,
      top: top.clamp(12.0, screen.height - estimatedHeight - 12).toDouble(),
      width: maxWidth,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: rich ? scheme.surface : scheme.inverseSurface,
            borderRadius: BorderRadius.circular(rich ? 18 : 12),
            border: rich
                ? Border.all(
                    color: scheme.outlineVariant.withValues(alpha: .18),
                    width: .5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: rich ? .08 : .1),
                blurRadius: rich ? 18 : 10,
                offset: Offset(0, rich ? 8 : 0),
              ),
            ],
          ),
          child: Padding(
            padding: rich
                ? const EdgeInsets.all(15)
                : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: rich
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.isNotEmpty) ...[
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: scheme.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      DefaultTextStyle(
                        style: bodyStyle ?? const TextStyle(),
                        child: content!,
                      ),
                    ],
                  )
                : Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onInverseSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Rich tooltip box adapter matching MIUIX `RichTooltipBox`.
class MiuixRichTooltipBox extends MiuixRichTooltip {
  /// Creates a rich tooltip box.
  const MiuixRichTooltipBox({
    super.key,
    required super.child,
    required super.content,
    super.message,
  });
}

/// Result returned when a hosted snackbar finishes.
enum MiuixSnackbarResult {
  /// The snackbar timed out, was swiped, or was explicitly dismissed.
  dismissed,

  /// The snackbar action was selected.
  actionPerformed,
}

/// Duration model matching MIUIX short, long, indefinite, and custom modes.
@immutable
class MiuixSnackbarDuration {
  const MiuixSnackbarDuration._(this.duration);

  /// A four-second snackbar.
  static const short = MiuixSnackbarDuration._(Duration(seconds: 4));

  /// A ten-second snackbar.
  static const long = MiuixSnackbarDuration._(Duration(seconds: 10));

  /// A snackbar that remains until user or application dismissal.
  static const indefinite = MiuixSnackbarDuration._(null);

  /// Creates a positive custom duration.
  factory MiuixSnackbarDuration.custom(Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(
        duration,
        'duration',
        'must be greater than zero',
      );
    }
    return MiuixSnackbarDuration._(duration);
  }

  /// Concrete timeout, or null for [indefinite].
  final Duration? duration;
}

/// Immutable content and behavior of one snackbar.
@immutable
class MiuixSnackbarVisuals {
  /// Creates snackbar visuals.
  const MiuixSnackbarVisuals({
    required this.message,
    this.actionLabel,
    this.withDismissAction = false,
    this.duration = MiuixSnackbarDuration.short,
  });

  /// Message shown by the snackbar.
  final String message;

  /// Optional action label.
  final String? actionLabel;

  /// Whether a trailing close control is shown.
  final bool withDismissAction;

  /// Visibility duration.
  final MiuixSnackbarDuration duration;
}

/// Public handle for a snackbar managed by [MiuixSnackbarHostState].
abstract interface class MiuixSnackbarData {
  /// Visual configuration for this entry.
  MiuixSnackbarVisuals get visuals;

  /// Dismisses this snackbar.
  Future<void> dismiss();

  /// Completes this snackbar with an action result.
  Future<void> performAction();
}

class _MiuixSnackbarEntry {
  _MiuixSnackbarEntry(this.id, this.data);

  final int id;
  final _MiuixSnackbarData data;
  bool visible = true;
}

class _MiuixSnackbarData implements MiuixSnackbarData {
  _MiuixSnackbarData({required this.visuals, required this.onFinish});

  @override
  final MiuixSnackbarVisuals visuals;
  final ValueChanged<MiuixSnackbarResult> onFinish;
  bool _finished = false;

  void _complete(MiuixSnackbarResult result) {
    if (_finished) {
      return;
    }
    _finished = true;
    onFinish(result);
  }

  @override
  Future<void> dismiss() async => _complete(MiuixSnackbarResult.dismissed);

  @override
  Future<void> performAction() async =>
      _complete(MiuixSnackbarResult.actionPerformed);
}

/// Observable snackbar queue rendered by [MiuixSnackbarHost].
class MiuixSnackbarHostState extends ChangeNotifier {
  final List<_MiuixSnackbarEntry> _entries = [];
  var _id = 0;

  List<_MiuixSnackbarEntry> get _currentEntries => List.unmodifiable(_entries);

  /// Shows a snackbar and completes after dismissal or action selection.
  Future<MiuixSnackbarResult> showSnackbar(
    String message, {
    String? actionLabel,
    bool withDismissAction = false,
    MiuixSnackbarDuration duration = MiuixSnackbarDuration.short,
  }) {
    final result = Completer<MiuixSnackbarResult>();
    late final _MiuixSnackbarEntry entry;
    final data = _MiuixSnackbarData(
      visuals: MiuixSnackbarVisuals(
        message: message,
        actionLabel: actionLabel,
        withDismissAction: withDismissAction,
        duration: duration,
      ),
      onFinish: (value) {
        if (!result.isCompleted) {
          result.complete(value);
        }
        if (entry.visible) {
          entry.visible = false;
          notifyListeners();
        }
      },
    );
    entry = _MiuixSnackbarEntry(++_id, data);
    _entries.insert(0, entry);
    notifyListeners();
    return result.future;
  }

  /// Returns the newest visible snackbar.
  Future<MiuixSnackbarData?> newestSnackbarData() async {
    for (final entry in _entries) {
      if (entry.visible) {
        return entry.data;
      }
    }
    return null;
  }

  /// Returns the oldest visible snackbar.
  Future<MiuixSnackbarData?> oldestSnackbarData() async {
    for (final entry in _entries.reversed) {
      if (entry.visible) {
        return entry.data;
      }
    }
    return null;
  }

  void _remove(_MiuixSnackbarEntry entry) {
    if (_entries.remove(entry)) {
      notifyListeners();
    }
  }

  /// Compatibility helper for callers that still prefer the root overlay API.
  MiuixSnackbarController show(BuildContext context, String message) {
    return MiuixSnackbar.show(context, message);
  }

  @override
  void dispose() {
    for (final entry in List<_MiuixSnackbarEntry>.of(_entries)) {
      entry.data._complete(MiuixSnackbarResult.dismissed);
    }
    _entries.clear();
    super.dispose();
  }
}

/// Renders and animates every snackbar in a [MiuixSnackbarHostState] queue.
class MiuixSnackbarHost extends StatefulWidget {
  /// Creates a snackbar host.
  const MiuixSnackbarHost({
    super.key,
    this.state,
    this.child,
    this.canSwipeToDismiss = false,
    this.contentBuilder,
  });

  /// Queue rendered by this host. Null preserves the former child-only adapter.
  final MiuixSnackbarHostState? state;

  /// Optional content placed behind the snackbar stack.
  final Widget? child;

  /// Whether a fast horizontal swipe dismisses an entry.
  ///
  /// The source MIUIX Snackbar consumes taps but has no swipe-to-dismiss
  /// gesture, so this compatibility extension is disabled by default.
  final bool canSwipeToDismiss;

  /// Optional custom snackbar renderer.
  final Widget Function(BuildContext context, MiuixSnackbarData data)?
  contentBuilder;

  @override
  State<MiuixSnackbarHost> createState() => _MiuixSnackbarHostWidgetState();
}

class _MiuixSnackbarHostWidgetState extends State<MiuixSnackbarHost> {
  @override
  void initState() {
    super.initState();
    widget.state?.addListener(_changed);
  }

  @override
  void didUpdateWidget(covariant MiuixSnackbarHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state?.removeListener(_changed);
      widget.state?.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.state?.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (state == null) {
      return widget.child ?? const SizedBox.shrink();
    }
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (widget.child != null) Positioned.fill(child: widget.child!),
        Padding(
          padding: _miuixRoundedInsets(
            context,
            const EdgeInsets.only(bottom: 12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            verticalDirection: VerticalDirection.up,
            children: [
              for (final entry in state._currentEntries)
                _MiuixHostedSnackbarEntry(
                  key: ValueKey(entry.id),
                  entry: entry,
                  state: state,
                  canSwipeToDismiss: widget.canSwipeToDismiss,
                  contentBuilder: widget.contentBuilder,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiuixHostedSnackbarEntry extends StatefulWidget {
  const _MiuixHostedSnackbarEntry({
    super.key,
    required this.entry,
    required this.state,
    required this.canSwipeToDismiss,
    this.contentBuilder,
  });

  final _MiuixSnackbarEntry entry;
  final MiuixSnackbarHostState state;
  final bool canSwipeToDismiss;
  final Widget Function(BuildContext context, MiuixSnackbarData data)?
  contentBuilder;

  @override
  State<_MiuixHostedSnackbarEntry> createState() =>
      _MiuixHostedSnackbarEntryState();
}

class _MiuixHostedSnackbarEntryState extends State<_MiuixHostedSnackbarEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  var _hiding = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _controller.animateWith(_miuixSnackbarSpring(0, 1));
    unawaited(_startTimer());
  }

  @override
  void didUpdateWidget(covariant _MiuixHostedSnackbarEntry oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.entry.visible && oldWidget.entry.visible) {
      _hide();
    } else if (!widget.entry.visible &&
        _controller.status != AnimationStatus.reverse) {
      _hide();
    }
  }

  Future<void> _startTimer() async {
    final duration = widget.entry.data.visuals.duration.duration;
    if (duration == null) {
      return;
    }
    // Snackbar.kt asks Android's AccessibilityManager to account for text,
    // icons, controls, and the user's preferred interaction timeout before it
    // begins delay(). The package bridge performs the same native calculation.
    final recommended = await MiuixAccessibility.recommendedSnackbarTimeout(
      duration,
      hasAction: widget.entry.data.visuals.actionLabel != null,
    );
    if (!mounted || _hiding || !widget.entry.visible) {
      return;
    }
    _timer = Timer(recommended, widget.entry.data.dismiss);
  }

  Future<void> _hide() async {
    if (_hiding) {
      return;
    }
    _hiding = true;
    _timer?.cancel();
    if (!mounted) {
      return;
    }
    try {
      await _controller.animateWith(
        _miuixSnackbarSpring(_controller.value.clamp(0.0, 1.0), 0),
      );
    } on TickerCanceled {
      return;
    }
    widget.state._remove(widget.entry);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.entry.data;
    final content =
        widget.contentBuilder?.call(context, data) ??
        _MiuixHostedSnackbarSurface(data: data);
    return AnimatedBuilder(
      animation: _controller,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onHorizontalDragEnd: widget.canSwipeToDismiss
            ? (details) {
                if ((details.primaryVelocity?.abs() ?? 0) > 300) {
                  data.dismiss();
                }
              }
            : null,
        child: content,
      ),
      builder: (context, child) {
        final progress = _controller.value.clamp(0.0, 1.0);
        final transitioned = Opacity(
          opacity: progress,
          child: FractionalTranslation(
            translation: Offset(0, 1 - progress),
            child: child,
          ),
        );
        // AnimatedVisibility reserves the complete item height while entering.
        // Only the source exit transition adds shrinkVertically, anchored to
        // the bottom edge and clipped while the item collapses.
        if (!_hiding) {
          return transitioned;
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.bottomCenter,
            heightFactor: progress,
            child: transitioned,
          ),
        );
      },
    );
  }
}

/// Compose's default spring uses unit mass, stiffness 400, and critical
/// damping. Snackbar.kt uses that default for slide, fade, and exit shrink.
SpringSimulation _miuixSnackbarSpring(double from, double to) {
  return SpringSimulation(
    const SpringDescription(mass: 1, stiffness: 400, damping: 40),
    from,
    to,
    0,
    tolerance: const Tolerance(distance: .001, velocity: .01),
  );
}

class _MiuixHostedSnackbarSurface extends StatelessWidget {
  const _MiuixHostedSnackbarSurface({required this.data});

  final MiuixSnackbarData data;

  @override
  Widget build(BuildContext context) {
    return _MiuixSnackbarSurface(
      visuals: data.visuals,
      onAction: data.performAction,
      onDismiss: data.dismiss,
    );
  }
}

/// Exact default Snackbar surface shared by the hosted and overlay APIs.
class _MiuixSnackbarSurface extends StatelessWidget {
  const _MiuixSnackbarSurface({
    required this.visuals,
    this.onAction,
    this.onDismiss,
  });

  final MiuixSnackbarVisuals visuals;
  final FutureOr<void> Function()? onAction;
  final FutureOr<void> Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    final semantic = MiuixSemanticColors.of(context);
    final theme = MiuixTheme.of(context);
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final radius = BorderRadius.circular(12);
    final ShapeBorder shape = theme.enableSquircle
        ? MiuixSquircleBorder(borderRadius: radius)
        : RoundedRectangleBorder(borderRadius: radius);
    final surface = DecoratedBox(
      key: const ValueKey('miuix-snackbar-surface'),
      decoration: ShapeDecoration(
        color: semantic['surfaceContainerHighest'],
        shape: shape,
        shadows: [
          BoxShadow(
            color: semantic['dividerLine'],
            blurRadius: 1,
            spreadRadius: .6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: _miuixRoundLogicalDimension(44, pixelRatio),
          ),
          child: Padding(
            padding: _miuixRoundedInsets(
              context,
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    visuals.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: semantic['onSurfaceContainer'],
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (visuals.actionLabel case final label?)
                  _MiuixSnackbarAction(
                    label: label,
                    color: semantic['onSurfaceContainerHighest'],
                    onTap: onAction,
                  ),
                if (visuals.withDismissAction)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8),
                    child: Semantics(
                      button: true,
                      label: '关闭',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        excludeFromSemantics: true,
                        onTap: () => onDismiss?.call(),
                        child: ClipOval(
                          child: _MiuixSearchCleanupIcon(
                            key: const ValueKey(
                              'miuix-snackbar-dismiss-action',
                            ),
                            size: 24,
                            color: semantic['onSurfaceContainerHighest'],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Padding(
      // Snackbar.kt applies this modifier outside the shadowed Surface. In a
      // stacked host the two 4dp edges also create the exact 8dp item pitch.
      padding: _miuixRoundedInsets(
        context,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Semantics(
        liveRegion: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: () {},
          child: surface,
        ),
      ),
    );
  }
}

class _MiuixSnackbarAction extends StatelessWidget {
  const _MiuixSnackbarAction({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final FutureOr<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return Semantics(
      button: true,
      child: MiuixPressable(
        onTap: onTap == null ? null : () => onTap?.call(),
        borderRadius: BorderRadius.circular(16),
        feedbackType: MiuixPressFeedbackType.none,
        showIndication: onTap != null,
        child: ConstrainedBox(
          key: const ValueKey('miuix-snackbar-action'),
          constraints: BoxConstraints(
            minWidth: _miuixRoundLogicalDimension(58, pixelRatio),
            minHeight: _miuixRoundLogicalDimension(40, pixelRatio),
          ),
          child: Padding(
            padding: _miuixRoundedInsets(
              context,
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Snackbar helper with Miuix naming.
class MiuixSnackbar {
  /// Shows a snackbar.
  static MiuixSnackbarController show(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    final controller = MiuixSnackbarController._();
    if (!context.mounted || overlay == null) {
      controller._complete();
      return controller;
    }
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _MiuixSnackbarOverlay(
        message: message,
        actionLabel: action?.label,
        onAction: action?.onPressed,
        onDismissed: () {
          controller._dismiss = null;
          if (entry.mounted) {
            entry.remove();
          }
          controller._complete();
        },
      ),
    );
    controller._dismiss = () {
      if (controller._closed.isCompleted) {
        return;
      }
      if (entry.mounted) {
        entry.remove();
      }
      controller._complete();
    };
    if (context.mounted) {
      overlay.insert(entry);
    } else {
      controller._complete();
    }
    return controller;
  }
}

/// Controller returned when showing a Miuix snackbar.
class MiuixSnackbarController {
  MiuixSnackbarController._();

  final Completer<void> _closed = Completer<void>();
  VoidCallback? _dismiss;

  /// Completes when the snackbar is dismissed.
  Future<void> get closed => _closed.future;

  /// Dismisses the snackbar if it is still visible.
  void close() {
    final dismiss = _dismiss;
    _dismiss = null;
    dismiss?.call();
    _complete();
  }

  void _complete() {
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }
}

class _MiuixSnackbarOverlay extends StatefulWidget {
  const _MiuixSnackbarOverlay({
    required this.message,
    required this.onDismissed,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  @override
  State<_MiuixSnackbarOverlay> createState() => _MiuixSnackbarOverlayState();
}

class _MiuixSnackbarOverlayState extends State<_MiuixSnackbarOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this);
    _controller.animateWith(_miuixSnackbarSpring(0, 1));
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (_dismissed || !mounted) {
      return;
    }
    _dismissed = true;
    _timer?.cancel();
    try {
      await _controller.animateWith(
        _miuixSnackbarSpring(_controller.value.clamp(0.0, 1.0), 0),
      );
    } on TickerCanceled {
      return;
    }
    if (mounted) {
      widget.onDismissed();
    }
  }

  void _performAction() {
    if (_dismissed) {
      return;
    }
    widget.onAction?.call();
    _dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom + 12;
    return Positioned(
      left: 0,
      right: 0,
      bottom: bottom,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _controller.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: progress,
            child: FractionalTranslation(
              translation: Offset(0, 1 - progress),
              child: child,
            ),
          );
        },
        child: _MiuixSnackbarSurface(
          visuals: MiuixSnackbarVisuals(
            message: widget.message,
            actionLabel: widget.actionLabel,
          ),
          onAction: widget.actionLabel == null ? null : _performAction,
        ),
      ),
    );
  }
}
