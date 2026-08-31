// MIUIX v1.0.9 TabRow parity contract.
//
// Authoritative component source:
// - miuix-ui/.../basic/TabRow.kt
//
// Authoritative sample source:
// - example/shared/.../component/TabRowSection.kt
//
// This documentation records the source obligation for both TabRow variants.
// It prevents a generic Material TabBar from being treated as equivalent only
// because it has text labels and a moving selection background.
//
// ---------------------------------------------------------------------------
// Public variants and state
// ---------------------------------------------------------------------------
//
// TabRow and TabRowWithContour receive:
// - a list of String labels;
// - selectedTabIndex;
// - onTabSelected;
// - colors;
// - minimum and maximum item width;
// - total height;
// - item corner radius;
// - item spacing;
// - content alignment;
// - nullable interaction source;
// - nullable indication.
//
// MiuixTabRow and MiuixTabRowWithContour expose those same controls. Their
// selectedTabIndex path is fully controlled: a tap reports intent but never
// moves the selected state until the owner publishes the new index.
//
// TabController and onTap remain compatibility extensions for existing Flutter
// call sites. They do not change the behavior of the source-controlled path.
//
// Compose Indication is an open drawing interface and cannot cross framework
// boundaries. showIndication=false represents the source default null value;
// true installs flutter_miuix's source-matched MIUIX indication layer.
//
// MiuixInteractionSource publishes pointer press state to external callers.
//
// ---------------------------------------------------------------------------
// Defaults and colors
// ---------------------------------------------------------------------------
//
// Ordinary defaults:
// - minimum width 76dp;
// - maximum width 98dp;
// - height 42dp;
// - corner radius 12dp;
// - spacing 9dp;
// - centered content.
//
// Contour defaults:
// - minimum width 62dp;
// - maximum width 84dp;
// - height 45dp;
// - item corner radius 8dp;
// - spacing 5dp;
// - outer content padding 5dp;
// - outer corner radius 13dp;
// - centered content.
//
// MiuixTabRowDefaults publishes the source's public variant dimensions and its
// tabRowColors factory. contourPadding remains a named constant so geometry
// tests can prove the source inset and derived outer radius independently.
//
// MiuixTabRowColors keeps four independent channels:
// - backgroundColor = surface;
// - contentColor = onSurfaceVariantSummary;
// - selectedBackgroundColor = surfaceContainer;
// - selectedContentColor = onBackground.
//
// Replacing one channel must not silently modify any other channel.
//
// ---------------------------------------------------------------------------
// Width allocation and density conversion
// ---------------------------------------------------------------------------
//
// For N tabs and spacing S:
// - totalSpacing = max(0, N - 1) * S;
// - ideal = (availableWidth - totalSpacing) / N.
//
// Empty lists return the variant minimum width and retain a fixed-height
// surface plus the remembered zero-offset indicator.
//
// When ideal is below minimum, the result is minimum and the row scrolls.
//
// When ideal is between minimum and maximum, the result is ideal.
//
// When ideal exceeds maximum:
// - use ideal if N maximum-width items plus spacing would leave unused width;
// - otherwise use maximum.
//
// This final branch intentionally lets short tab lists fill a wide surface.
//
// Compose converts each declared Dp measurement through roundToPx before
// placement. Flutter rounds spacing, widths, height, and contour padding into
// logical values at the active device pixel ratio. The contour outer radius is
// calculated from the declared item radius plus declared 5dp padding before
// painting; separately rounded layout padding must not be reused for it.
//
// ---------------------------------------------------------------------------
// Indicator and scrolling
// ---------------------------------------------------------------------------
//
// The indicator begins at offset zero even when initial selection is nonzero.
//
// Every selected-index change animates its logical offset to:
// selectedIndex * (tabWidth + itemSpacing).
//
// Duration is exactly 200ms and easing is Linear.
//
// The selected item is independently centered when possible. The requested
// center offset is clamped by the horizontal scroll extent at both ends.
//
// The rendered indicator subtracts the current scroll offset so it remains
// attached to the selected item while the user drags the row.
//
// Both the indicator and clickable items use the same active MIUIX shape:
// continuous G2 rounding when enabled, ordinary rounded rectangles otherwise.
//
// ---------------------------------------------------------------------------
// Items, text, and interaction
// ---------------------------------------------------------------------------
//
// Ordinary items fill the 42dp row and apply 12dp horizontal content padding.
// Their labels use body1 at 16sp.
//
// Contour items fill the 35dp inner row and apply no automatic horizontal
// padding. Their labels use body2 at 14sp.
//
// Selected labels are bold; unselected labels are normal weight.
//
// All labels are one line with ellipsis overflow.
//
// The caller contentAlignment applies inside every fixed-width item.
//
// Source items have no sink or tilt transform. An indication appears only
// when the caller supplies one.
//
// Each item exposes role Tab, selected state, and a tap action to Flutter's
// semantic tree. Flutter requires selected state on Tab roles, so publishing it
// is the faithful accessible equivalent of the visual source selection.
//
// ---------------------------------------------------------------------------
// Localized source sample
// ---------------------------------------------------------------------------
//
// The example retains the original sample structure:
// - SmallTitle for TabRow;
// - an ordinary three-item controlled row;
// - 12dp gap below it;
// - a full-width Card with 16dp inside margin;
// - a six-item contoured row linked to a horizontally swipeable pager;
// - 12dp gap before the page text.
//
// Only visible strings are localized:
// - Tab 1...6 -> 标签 1...6;
// - Content of Tab X -> 标签 X 的内容.
//
// Localization must not change item counts, ordering, state ownership,
// horizontal padding, vertical spacing, pager behavior, or typography.
