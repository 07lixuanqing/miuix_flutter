part of '../miuix_widgets.dart';

/// Builds a custom dropdown trigger from the menu lifecycle.
///
/// [onPressed] is null while the trigger is disabled. [expanded] stays true
/// until the popup's exit transition finishes, which lets source IconButtons
/// retain their hold-down indication for the complete popup lifecycle.
typedef MiuixDropdownTriggerBuilder =
    Widget Function(
      BuildContext context,
      VoidCallback? onPressed,
      bool expanded,
    );

/// Dropdown menu built from Miuix entries.
class MiuixDropdownMenuButton<T> extends StatefulWidget {
  /// Creates a dropdown menu button.
  const MiuixDropdownMenuButton({
    super.key,
    required this.entries,
    required this.onSelected,
    this.child,
    this.triggerBuilder,
    this.presentation = MiuixPopupPresentation.window,
    this.alignment = MiuixPopupAlignment.bottomEnd,
    this.positioning = MiuixPopupPositioning.dropdown,
    this.renderInRootScaffold = true,
    this.enabled = true,
    this.onExpandedChange,
    this.popupAnchorInsets = EdgeInsets.zero,
    this.popupAnchorOffset = Offset.zero,
  }) : assert(
         (child == null) != (triggerBuilder == null),
         'Provide exactly one of child or triggerBuilder.',
       );

  /// Menu entries.
  final List<MiuixDropdownEntry<T>> entries;

  /// Selection callback.
  final ValueChanged<T> onSelected;

  /// Legacy button child wrapped in the package's general pressable.
  final Widget? child;

  /// Optional source-aware trigger builder.
  ///
  /// Use this for MIUIX IconButton popup anchors. The returned widget owns its
  /// own press indication and semantics while this menu still owns expansion.
  final MiuixDropdownTriggerBuilder? triggerBuilder;

  /// Popup route family used by this trigger.
  final MiuixPopupPresentation presentation;

  /// Anchor alignment of the popup.
  final MiuixPopupAlignment alignment;

  /// Position-provider family matching MIUIX Dropdown or ContextMenu.
  final MiuixPopupPositioning positioning;

  /// Whether Overlay routes use the outermost scaffold.
  final bool renderInRootScaffold;

  /// Whether the trigger can open the menu.
  final bool enabled;

  /// Called when popup expansion starts or finishes.
  final ValueChanged<bool>? onExpandedChange;

  /// Insets removed from the trigger bounds when positioning the popup.
  ///
  /// This lets a source-compatible 48dp touch target retain a smaller 40dp
  /// visual popup anchor. The default keeps the full trigger bounds.
  final EdgeInsets popupAnchorInsets;

  /// Translation applied after resolving the visual trigger rectangle.
  ///
  /// Fractional-density source fixtures use this to preserve Compose's
  /// physical-pixel rounding without changing the trigger's layout or target.
  final Offset popupAnchorOffset;

  @override
  State<MiuixDropdownMenuButton<T>> createState() =>
      _MiuixDropdownMenuButtonState<T>();
}

class _MiuixDropdownMenuButtonState<T>
    extends State<MiuixDropdownMenuButton<T>> {
  final LayerLink _link = LayerLink();
  final GlobalKey _anchorKey = GlobalKey();
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    Future<void> openMenu() async {
      if (!widget.enabled || widget.entries.isEmpty || _expanded) {
        return;
      }
      setState(() => _expanded = true);
      widget.onExpandedChange?.call(true);
      try {
        final anchorContext = _anchorKey.currentContext;
        final triggerRect = anchorContext == null
            ? null
            : _miuixGlobalRect(anchorContext);
        final anchorRect = triggerRect == null
            ? null
            : Rect.fromLTRB(
                triggerRect.left + widget.popupAnchorInsets.left,
                triggerRect.top + widget.popupAnchorInsets.top,
                triggerRect.right - widget.popupAnchorInsets.right,
                triggerRect.bottom - widget.popupAnchorInsets.bottom,
              );
        await _showMiuixDropdownMenu<T>(
          context: context,
          entries: widget.entries,
          onSelected: widget.onSelected,
          presentation: widget.presentation,
          link: _link,
          anchorRect: anchorRect,
          alignment: widget.alignment,
          positioning: widget.positioning,
          renderInRootScaffold: widget.renderInRootScaffold,
          popupAnchorOffset: widget.popupAnchorOffset,
        );
      } finally {
        if (mounted) {
          setState(() => _expanded = false);
          widget.onExpandedChange?.call(false);
        }
      }
    }

    final canOpen = widget.enabled && widget.entries.isNotEmpty;
    final triggerBuilder = widget.triggerBuilder;
    final trigger = triggerBuilder != null
        ? triggerBuilder(
            context,
            canOpen ? () => unawaited(openMenu()) : null,
            _expanded,
          )
        : MiuixPressable(
            onTap: canOpen ? () => unawaited(openMenu()) : null,
            feedbackType: MiuixPressFeedbackType.none,
            showIndication: canOpen,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: widget.enabled ? 1 : .38,
              child: widget.child!,
            ),
          );
    return CompositedTransformTarget(
      link: _link,
      child: SizedBox(key: _anchorKey, child: trigger),
    );
  }
}

/// Overlay-named dropdown menu adapter.
class MiuixOverlayDropdownMenu<T> extends MiuixDropdownMenuButton<T> {
  /// Creates an overlay dropdown menu.
  const MiuixOverlayDropdownMenu({
    super.key,
    required super.entries,
    required super.onSelected,
    required super.child,
    super.enabled,
    super.onExpandedChange,
    super.renderInRootScaffold,
    super.alignment,
    super.positioning,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-named dropdown menu adapter.
class MiuixWindowDropdownMenu<T> extends MiuixDropdownMenuButton<T> {
  /// Creates a window dropdown menu.
  const MiuixWindowDropdownMenu({
    super.key,
    required super.entries,
    required super.onSelected,
    required super.child,
    super.enabled,
    super.onExpandedChange,
    super.alignment,
    super.positioning,
  }) : super(presentation: MiuixPopupPresentation.window);
}

/// Icon-triggered dropdown menu.
class MiuixIconDropdownMenu<T> extends StatelessWidget {
  /// Creates an icon dropdown menu.
  const MiuixIconDropdownMenu({
    super.key,
    required this.icon,
    required this.entries,
    required this.onSelected,
    this.tooltip,
    this.presentation = MiuixPopupPresentation.window,
    this.enabled = true,
    this.onExpandedChange,
    this.renderInRootScaffold = true,
    this.alignment = MiuixPopupAlignment.bottomEnd,
    this.positioning = MiuixPopupPositioning.dropdown,
  });

  /// Trigger icon.
  final Widget icon;

  /// Optional trigger tooltip.
  final String? tooltip;

  /// Menu entries.
  final List<MiuixDropdownEntry<T>> entries;

  /// Selection callback.
  final ValueChanged<T> onSelected;

  /// Popup route family used by this trigger.
  final MiuixPopupPresentation presentation;

  /// Whether the icon trigger can open the menu.
  final bool enabled;

  /// Called when popup expansion starts or finishes.
  final ValueChanged<bool>? onExpandedChange;

  /// Whether Overlay presentation uses the outermost Scaffold host.
  final bool renderInRootScaffold;

  /// Anchor alignment of the popup.
  final MiuixPopupAlignment alignment;

  /// Position-provider family used for the anchored popup.
  final MiuixPopupPositioning positioning;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MiuixDropdownMenuButton<T>(
      entries: entries,
      onSelected: onSelected,
      presentation: presentation,
      enabled: enabled,
      onExpandedChange: onExpandedChange,
      renderInRootScaffold: renderInRootScaffold,
      alignment: alignment,
      positioning: positioning,
      child: MiuixTooltip(
        message: tooltip ?? '',
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing.sm),
            child: IconTheme.merge(
              data: IconThemeData(color: scheme.onSecondaryContainer),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Overlay-named icon dropdown menu.
class MiuixOverlayIconDropdownMenu<T> extends MiuixIconDropdownMenu<T> {
  /// Creates an overlay icon dropdown menu.
  const MiuixOverlayIconDropdownMenu({
    super.key,
    required super.icon,
    required super.entries,
    required super.onSelected,
    super.tooltip,
    super.enabled,
    super.onExpandedChange,
    super.renderInRootScaffold,
  }) : super(presentation: MiuixPopupPresentation.overlay);
}

/// Window-named icon dropdown menu.
class MiuixWindowIconDropdownMenu<T> extends MiuixIconDropdownMenu<T> {
  /// Creates a window icon dropdown menu.
  const MiuixWindowIconDropdownMenu({
    super.key,
    required super.icon,
    required super.entries,
    required super.onSelected,
    super.tooltip,
    super.enabled,
    super.onExpandedChange,
  }) : super(presentation: MiuixPopupPresentation.window);
}
