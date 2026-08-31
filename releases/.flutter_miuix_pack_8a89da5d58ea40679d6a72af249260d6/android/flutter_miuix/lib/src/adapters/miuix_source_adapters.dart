import 'package:flutter/material.dart';

import '../effects/miuix_effects.dart';
import '../widgets/miuix_widgets.dart';

/// Source-level adapters for public MIUIX functions that are not standalone
/// Flutter widgets in the main catalog.
///
/// MIUIX exposes several public helpers for Compose layout scopes, popup
/// internals, color conversion, and implementation details. Flutter does not
/// need identical low-level primitives, but keeping named adapters makes source
/// migration explicit and lets the parity scripts check those entry points.

/// Flutter-side color wrapper for MIUIX color helper entry points.
@immutable
class MiuixColor {
  /// Creates a color adapter.
  const MiuixColor(this.value);

  /// Wrapped Flutter color.
  final Color value;

  /// Creates a color from an ARGB integer.
  factory MiuixColor.fromARGB32(int value) {
    return MiuixColor(Color(value));
  }
}

/// Backdrop effect scope adapter.
class MiuixBackdropEffectScope extends MiuixLayerBackdrop {
  /// Creates a backdrop scope.
  const MiuixBackdropEffectScope({
    super.key,
    required super.child,
    super.backdrop,
    super.radius,
    super.padding,
  });
}

/// Drawing scope marker for MIUIX highlight helpers.
@immutable
class MiuixDrawScope {
  /// Creates a drawing scope marker.
  const MiuixDrawScope({this.size = Size.zero});

  /// Logical drawing size.
  final Size size;
}

/// Drawing transform marker for MIUIX highlight helpers.
@immutable
class MiuixDrawTransform {
  /// Creates a drawing transform marker.
  const MiuixDrawTransform({this.rotation = 0, this.scale = 1});

  /// Rotation in radians.
  final double rotation;

  /// Scale multiplier.
  final double scale;
}

/// Floating navigation item adapter.
class MiuixFloatingNavigationBarItem extends MiuixNavigationItem {
  /// Creates a floating navigation item.
  const MiuixFloatingNavigationBarItem({
    required super.icon,
    required super.label,
    super.selectedIcon,
    super.layoutLabel,
  });
}

/// Renders the popup and dialog states owned by the current [MiuixScaffold].
///
/// The unnamed no-child form matches upstream `MiuixPopupHost()`: it is a
/// visual host slot and does not create another popup state scope. Supplying
/// [child], or using [MiuixPopupHost.scope], retains the package's historical
/// standalone nested-scope adapter.
class MiuixPopupHost extends StatefulWidget {
  /// Creates the source host renderer.
  ///
  /// [child] is optional only for backward compatibility. New standalone
  /// scope call sites should use [MiuixPopupHost.scope] explicitly.
  const MiuixPopupHost({super.key, this.child});

  /// Creates an independently scoped host around [child].
  // The field remains nullable because the source constructor has no child.
  const MiuixPopupHost.scope({super.key, required Widget child})
    // ignore: prefer_initializing_formals
    : child = child;

  /// Compatibility subtree, or null for the source renderer.
  final Widget? child;

  @override
  State<MiuixPopupHost> createState() => _MiuixPopupHostState();
}

class _MiuixPopupHostState extends State<MiuixPopupHost> {
  MiuixPopupHostController? _controller;
  MiuixPopupHostController? _parent;

  bool get _ownsScope => widget.child != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _synchronizeOwnedController();
  }

  @override
  void didUpdateWidget(covariant MiuixPopupHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.child == null) != (widget.child == null)) {
      _synchronizeOwnedController();
    }
  }

  void _synchronizeOwnedController() {
    if (!_ownsScope) {
      _controller?.dispose();
      _controller = null;
      _parent = null;
      return;
    }
    final parent = MiuixPopupHostScope.maybeOf(context);
    if (_controller == null || parent != _parent) {
      _controller?.dispose();
      _parent = parent;
      _controller = MiuixPopupHostController(parent: parent);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    if (child == null) {
      // Scaffold supplies the state scope outside its complete layout. The
      // source host only paints that controller's entries in the popup slot.
      final controller = MiuixPopupHostScope.maybeOf(context);
      return controller == null
          ? const SizedBox.shrink()
          : MiuixPopupHostView(controller: controller);
    }

    final controller = _controller!;
    return MiuixPopupHostScope(
      controller: controller,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: controller.parent == null
                ? MiuixPopupHostView(controller: controller)
                : ClipRect(
                    key: const ValueKey('miuix-popup-host-clip'),
                    child: MiuixPopupHostView(controller: controller),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Modifier adapter for source migration.
@immutable
class MiuixModifier {
  /// Creates a modifier adapter.
  const MiuixModifier([this.builder]);

  /// Optional widget transform.
  final Widget Function(Widget child)? builder;

  /// Applies the modifier to a child.
  Widget apply(Widget child) {
    return builder?.call(child) ?? child;
  }
}

/// Path adapter used by squircle and shape migration code.
@immutable
class MiuixPath {
  /// Creates a path adapter.
  const MiuixPath(this.path);

  /// Wrapped Flutter path.
  final Path path;
}

/// Overlay dropdown dialog adapter.
class MiuixOverlayDropdownDialog<T> extends MiuixOverlayListPopup<T> {
  /// Creates an overlay dropdown dialog.
  const MiuixOverlayDropdownDialog({
    super.key,
    required super.entries,
    required super.onSelected,
  });
}

/// Overlay dropdown popup adapter.
class MiuixOverlayDropdownPopup<T> extends MiuixOverlayListPopup<T> {
  /// Creates an overlay dropdown popup.
  const MiuixOverlayDropdownPopup({
    super.key,
    required super.entries,
    required super.onSelected,
  });
}

/// Window dropdown dialog adapter.
class MiuixWindowDropdownDialog<T> extends MiuixWindowListPopup<T> {
  /// Creates a window dropdown dialog.
  const MiuixWindowDropdownDialog({
    super.key,
    required super.entries,
    required super.onSelected,
  });
}

/// Window dropdown popup adapter.
class MiuixWindowDropdownPopup<T> extends MiuixWindowListPopup<T> {
  /// Creates a window dropdown popup.
  const MiuixWindowDropdownPopup({
    super.key,
    required super.entries,
    required super.onSelected,
  });
}

/// Radio button alias matching the MIUIX source name.
class MiuixRadioButton<T> extends MiuixRadio<T> {
  /// Creates a radio button.
  const MiuixRadioButton({
    super.key,
    required super.value,
    required super.groupValue,
    required super.onChanged,
    super.enabled,
    super.colors,
  });

  /// Creates the source `selected` plus direct `onClick` API.
  static MiuixRadioButton<bool> source({
    Key? key,
    required bool selected,
    required VoidCallback? onClick,
    bool enabled = true,
    MiuixRadioButtonColors? colors,
  }) {
    return MiuixRadioButton<bool>(
      key: key,
      value: true,
      groupValue: selected,
      enabled: enabled,
      colors: colors,
      onChanged: onClick == null ? null : (_) => onClick(),
    );
  }
}

/// Row scope marker for navigation item migration.
@immutable
class MiuixRowScope {
  /// Creates a row scope marker.
  const MiuixRowScope();
}

/// Runtime shader descriptor.
@immutable
class MiuixRuntimeShader {
  /// Creates a runtime shader descriptor.
  const MiuixRuntimeShader({required this.name, this.source});

  /// Shader name or asset key.
  final String name;

  /// Optional shader source.
  final String? source;
}

/// Tab row alias matching MIUIX source naming.
class MiuixTabRow extends MiuixTabBar {
  /// Creates a tab row.
  const MiuixTabRow({
    super.key,
    required super.tabs,
    super.controller,
    super.selectedTabIndex,
    super.onTabSelected,
    super.onTap,
    super.colors,
    super.minWidth,
    super.maxWidth,
    super.height,
    super.cornerRadius,
    super.itemSpacing,
    super.contentAlignment,
    super.interactionSource,
    super.showIndication,
  });
}

/// Contoured tab row alias.
class MiuixTabRowWithContour extends MiuixTabBar {
  /// Creates a contoured tab row.
  const MiuixTabRowWithContour({
    super.key,
    required super.tabs,
    super.controller,
    super.selectedTabIndex,
    super.onTabSelected,
    super.onTap,
    super.colors,
    super.minWidth,
    super.maxWidth,
    super.height,
    super.cornerRadius,
    super.itemSpacing,
    super.contentAlignment,
    super.interactionSource,
    super.showIndication,
  }) : super.contour();
}

/// Tooltip scope marker for source migration.
@immutable
class MiuixTooltipScope {
  /// Creates a tooltip scope marker.
  const MiuixTooltipScope();
}
