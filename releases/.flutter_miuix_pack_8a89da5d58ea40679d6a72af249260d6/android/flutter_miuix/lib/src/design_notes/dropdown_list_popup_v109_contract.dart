// MIUIX v1.0.9 Dropdown and ListPopup parity contract.
//
// Authoritative source:
// - miuix-ui/.../basic/Dropdown.kt
// - miuix-ui/.../basic/ListPopup.kt
//
// Authoritative localized example:
// - example/shared/.../DropdownPage.kt
// - example/shared/.../component/DropdownSection.kt
// - example/shared/.../component/SpinnerSection.kt
//
// ---------------------------------------------------------------------------
// DropdownImpl
// ---------------------------------------------------------------------------
//
// DropdownImpl is one option row, not a menu-trigger convenience widget.
// Its source inputs are text, optionSize, isSelected, index, colors, and the
// selected-index callback. MiuixDropdownImpl preserves that same contract.
//
// Every row has 20dp horizontal padding. The first row has 20dp at its outer
// top edge, the last row has 20dp at its outer bottom edge, and all inner
// edges have 12dp. Text is body1: 16sp, medium, one line, ellipsized, with a
// maximum 200dp leading-content width.
//
// A 12dp gap and a 20dp check slot are always measured. The slot becomes
// transparent for ordinary rows instead of disappearing. Selected and
// ordinary options therefore keep identical intrinsic widths.
//
// DropdownArrowEndAction is exactly 10 by 16dp and uses the supplied action
// color. It is not replaced by a Material popup arrow or platform chevron.
//
// ---------------------------------------------------------------------------
// SpinnerItemImpl
// ---------------------------------------------------------------------------
//
// SpinnerEntry independently permits an icon, title, and summary. Anchored
// spinner rows use 20dp horizontal padding, an icon minimum of 26dp followed
// by 12dp, a 216dp maximum leading area, then the common 12dp/check-20dp tail.
//
// Anchored rows use the same 20dp outer and 12dp inner vertical rhythm as
// DropdownImpl. Dialog rows use 12dp on every vertical edge, 28dp horizontal
// padding, minimum width 200dp, minimum height 56dp, and fill available width.
//
// Anchored and dialog presentations have distinct semantic color defaults.
// In particular, dialog selected content, summary, surface, and check use the
// tertiary-container roles from the source rather than primary colors.
//
// ---------------------------------------------------------------------------
// ListPopupColumn measurement
// ---------------------------------------------------------------------------
//
// Only the first eight rows participate in intrinsic width. Their widest
// result is clamped to 200..288dp. A ninth or later wider row must be laid out
// at that already chosen width and must not widen the popup.
//
// Only the first eight rows participate in minimum intrinsic height, while
// every row participates in maximum height and actual vertical layout.
// Vertical overflow is scrollable with clamping physics.
//
// ---------------------------------------------------------------------------
// Placement and transform origins
// ---------------------------------------------------------------------------
//
// PopupPositionProvider receives anchor bounds, inset window bounds, layout
// direction, measured popup size, resolved margins, and alignment. Dropdown
// margins are 8dp vertically. Context-menu margins are 20dp horizontally.
//
// Adaptive vertical placement tries below first, then above. If neither side
// fits it centers on the anchor before clamping to the safe window. Start/end
// is direction aware.
//
// ListPopupLayoutInfo stores safe window bounds, provider margins, the
// window-relative effective origin, the popup-local origin, and actual
// placement. Placement is inferred from popup and anchor centers after the
// provider finishes, not from the requested alignment.
//
// The local x origin is zero for left alignment and one for right alignment.
// Its y origin is zero below, one above, and one half for a middle placement.
//
// ---------------------------------------------------------------------------
// ListPopupContent motion and reveal
// ---------------------------------------------------------------------------
//
// Fraction and reset use spring damping ratio 0.82, stiffness 362.5, and
// visibility threshold 0.0001. Flutter samples the physical spring through a
// 620ms window, which is the first whole-millisecond window satisfying the
// source distance and velocity thresholds.
//
// Popup scale is 0.15 + 0.85 * fraction. It must never be substituted with a
// conventional 0.92 or 0.94 Material menu scale.
//
// Alpha has independent linear clocks: 200ms enter and 150ms exit. The dim
// layer has independent SinOut clocks: 300ms enter and 150ms exit. Neither
// channel is derived from the spring fraction.
//
// The 16dp reveal is paint-only, matching drawWithContent. A popup below the
// anchor reveals downward from its top edge; a popup above reveals upward from
// its bottom edge; a middle popup reveals symmetrically from its center.
// Paint-only reveal must not clip pointer or semantic hit testing.
//
// Overlay and root-window presentations consume the same layout and motion
// implementation. Their only difference is ownership by a Scaffold popup host
// versus the root Navigator route.
//
// ---------------------------------------------------------------------------
// Regression evidence
// ---------------------------------------------------------------------------
//
// Source-level tests must cover row callbacks, selected-check reservation,
// dialog spinner geometry, the first-eight width rule, exact motion tokens,
// below/above/middle layout origins, route lifecycle, outside dismissal, Back,
// and anchor rebuilds. Expanded screenshot baselines are captured only after
// the complete 620ms spring has settled.
//
// ---------------------------------------------------------------------------
// Public API correspondence
// ---------------------------------------------------------------------------
//
// DropdownColors maps to MiuixDropdownColors.
// DropdownDefaults maps to MiuixDropdownDefaults.
// DropdownArrowEndAction maps to MiuixDropdownArrowEndAction.
// DropdownImpl maps to MiuixDropdownImpl.
// SpinnerColors maps to MiuixSpinnerColors.
// SpinnerDefaults maps to MiuixSpinnerDefaults.
// SpinnerEntry maps to MiuixSpinnerEntry.
// SpinnerItemImpl maps to MiuixSpinnerItemImpl.
// PopupLayoutPosition maps to MiuixPopupLayoutPosition.
// TransformOrigin maps to MiuixTransformOrigin.
// PopupPositionProvider maps to MiuixPopupPositionProvider.
// ListPopupDefaults maps to MiuixListPopupDefaults.
// ListPopupLayoutInfo maps to MiuixListPopupLayoutInfo.
// ListPopupColumn maps to MiuixListPopupColumn.
// ListPopupContent maps to MiuixListPopupContent.
//
// The Flutter names use a Miuix prefix to avoid collisions with Material and
// dart:ui types. Prefixing is the only intentional API naming difference.
// Values, defaults, callback timing, and geometry remain source-derived.
//
// ---------------------------------------------------------------------------
// Known incorrect substitutions
// ---------------------------------------------------------------------------
//
// A Material DropdownButton is not an acceptable DropdownImpl substitute.
// It combines trigger and route ownership that are separate in the source.
// It also imposes Material row height, padding, and menu motion.
//
// A plain Column is not an acceptable ListPopupColumn substitute.
// A plain Column lets the ninth row participate in intrinsic measurement.
// It also has no source maximum-width clamp or vertical scroll ownership.
//
// IntrinsicWidth around every child is not equivalent to the source.
// It measures all children and therefore breaks the first-eight rule.
//
// AnimatedScale with a 0.92 start is not equivalent to ListPopupContent.
// AnimatedScale with a 0.94 start is not equivalent either.
// Both hide the source's much more visible 0.15 opening state.
//
// FadeTransition driven by the spring controller is not source-correct.
// The source alpha reaches one at 200ms while the spring keeps settling.
//
// A linearly dimmed barrier is not source-correct.
// The source barrier uses an independent 300ms SinOut entrance.
//
// ClipRRect around the interactive subtree is not source-correct.
// Compose clips only drawWithContent, leaving pointer input uncut.
//
// Predicting above or below from alignment alone is not source-correct.
// Safe-window constraints can move a requested popup to another side.
//
// Centering a popup whenever below does not fit is not source-correct.
// The provider must try the complete above space before middle placement.
//
// Applying dropdown margins to the safe window twice is not source-correct.
// Margins participate in requested placement and the final clamp exactly once.
//
// Calculating end alignment without TextDirection is not source-correct.
// RTL swaps the physical edge while preserving the logical API value.
//
// Removing the unselected check widget is not source-correct.
// It makes selection change the popup width and shifts every text label.
//
// Using the same spinner colors in popup and dialog modes is not correct.
// Dialog selection belongs to the tertiary-container semantic family.
//
// ---------------------------------------------------------------------------
// Runtime verification notes
// ---------------------------------------------------------------------------
//
// Android verification uses the source 420dpi reference density.
// Popup coordinates are compared in physical pixels after system insets.
// The status bar is excluded from safe bounds once and only once.
// The navigation bar or gesture inset is excluded once and only once.
// Caption-bar insets are additionally relevant to desktop window hosts.
//
// Opening below is verified with an anchor near the top of the viewport.
// Opening above is verified with an anchor near the bottom of the viewport.
// Middle placement is verified with content taller than either free side.
// Start and end alignment are verified in both LTR and RTL directions.
// A ninth oversized row verifies that width remains at the first-eight result.
// A ninth ordinary row verifies that it remains reachable through scrolling.
//
// Entrance screenshots are not taken before the host has mounted its child.
// Settled screenshots wait for the complete physical spring window.
// Exit tests wait until the hosted entry is physically removed.
// Android Back must dismiss only the top popup before changing app pages.
// An outside tap must follow the same reverse lifecycle as Back.
// Trigger held state ends only after the popup's exit lifecycle completes.
//
// Debug builds are checked for RenderFlex overflow and hit-test warnings.
// Android logs are checked for Flutter framework exceptions.
// The accessibility tree is checked for compact, tappable option bounds.
// Selection callbacks are checked independently from route dismissal.
// A controlled parent rebuild must not detach or move the popup anchor.
//
// Golden updates are accepted only when the new frame is fully settled.
// A partially pressed trigger is not a stable expanded-state baseline.
// Overlay and window goldens must agree on popup geometry and row rhythm.
// Differences in route ownership must not create differences in appearance.
