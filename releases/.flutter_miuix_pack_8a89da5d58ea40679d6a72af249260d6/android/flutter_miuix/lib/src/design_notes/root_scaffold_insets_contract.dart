// MIUIX v1.0.9 root Scaffold and navigation-inset contract.
//
// Purpose
// -------
// This note records the measurement behavior shared by the library and sample.
// It exists because Flutter Scaffold and Compose Scaffold use different models.
// The original sample always measures its page content at full window height.
// The bottom navigation is measured separately and painted over that content.
// A content-padding value tells scroll containers how far their final item moves.
// Therefore the page viewport itself is never shortened by a compact bottom bar.
// This distinction keeps scrollable content visible through transparent regions.
// It also avoids reserving the same navigation height in two different layers.
//
// Compact regular navigation
// --------------------------
// The regular navigation item row is 64dp high in the original component.
// A separate 0.75dp divider is measured immediately above that item row.
// The system-navigation inset is appended below the row on edge-to-edge hosts.
// Measured height is consequently 64.75dp plus the safe bottom inset.
// The root pager still extends to the physical bottom edge of the application.
// Each page uses the measured value as its final scroll-content bottom padding.
// A device without a bottom safe inset therefore reports exactly 64.75dp.
// An Android device with a 24dp navigation inset reports exactly 88.75dp.
// The navigation surface may be opaque without changing the measurement model.
// Enabling glass changes its paint and blur behavior, not its occupied height.
// Switching labels or icons also leaves the outer 64dp measurement unchanged.
//
// Hidden navigation
// -----------------
// Hiding compact navigation removes the component height from content padding.
// The platform safe bottom inset remains because page controls must stay usable.
// A test environment with a zero safe inset therefore receives zero padding.
// A gesture-navigation device continues to receive its reported bottom inset.
// The pager remains full height in both cases and no invisible bar is retained.
// Animated removal must not leave the old 64.75dp padding afterward.
// Animated insertion must update padding with the same state as the visible bar.
// Wide layouts follow the same hidden behavior because they have no bottom bar.
// Their navigation rail affects horizontal width rather than vertical padding.
//
// Standard floating navigation
// ----------------------------
// The standard floating bar uses a 56dp item extent in the Flutter component.
// Its pill is placed above a platform-specific lower gap from the source layout.
// Android without a reported inset uses a 36dp lower gap.
// Android with an inset uses 8dp plus twice the reported bottom inset.
// The doubled inset mirrors the original platform navigation-space expression.
// iOS uses an 8dp gap plus its reported bottom inset.
// Desktop platforms use a 36dp visual gap plus any reported safe inset.
// A zero-inset Android or Windows layout therefore reports 92dp total padding.
// A 24dp Android inset produces a 56dp plus 56dp, or 112dp, total padding.
// Only the pill participates in surface color, shadow, clipping, and glass blur.
// The rectangular region around it must reveal the already-laid-out page.
// Its rounded-corner shadow must be clipped to the same pill-shaped boundary.
// Equal-width destinations divide the pill's usable width, not the screen width.
// Localization may change glyph widths but cannot change destination allocation.
//
// iOS-like floating navigation
// ----------------------------
// The optional iOS-like extension uses a 64dp navigation panel.
// With no safe inset it keeps the same 36dp desktop-style lower breathing room.
// With a safe inset it uses an 8dp visual gap followed by that inset.
// A 24dp inset therefore produces a 96dp total content-padding measurement.
// The liquid-glass material belongs only to the panel and selected item layers.
// The surrounding rectangle stays fully transparent at every glass intensity.
// Changing the five-level blur setting cannot alter panel geometry or padding.
// The page remains interactive and visible outside the floating panel bounds.
//
// Top application bar interaction
// -------------------------------
// Root pages begin below the expanded title content on their initial scroll state.
// The top application bar itself is painted above the page viewport.
// Scrolling upward may move list content behind the top application bar layer.
// Opaque and glass top bars retain the same content-inset calculation.
// The Android status-bar inset is part of the top bar's safe layout region.
// Edge-to-edge drawing may extend its surface behind the status-bar icons.
// The first page item must never begin beneath the title before scrolling occurs.
// Bottom navigation changes must not reset or alter the current top scroll offset.
//
// Snackbar and transient content
// ------------------------------
// Snackbar placement uses the actually rendered bottom-navigation measurement.
// A snackbar cannot be obscured behind either regular or floating navigation.
// Hidden navigation allows the snackbar to descend to the remaining safe inset.
// Floating controls calculate their avoidance from the same active bar geometry.
// These overlays do not reserve an additional permanent strip in the root pager.
// Dialogs and sheets use their own window insets and do not reuse page padding.
//
// Adaptive layout
// ---------------
// Widths below 600dp always use the compact bottom-navigation arrangement.
// Widths from 600dp use split panes only below the source's 1.2 aspect threshold.
// Widths of at least 840dp use the split-pane navigation rail unconditionally.
// The wide pager fills all horizontal space remaining beside the rail.
// It does not receive a centered maximum-width wrapper or artificial side gutter.
// Wide pages retain only the platform safe bottom inset for their scroll content.
// Returning to compact mode restores the active bottom-bar measurement at once.
//
// Verification
// ------------
// Unit tests lock hidden, regular, floating, and iOS-like inset calculations.
// Widget tests assert that a 390 by 844 compact pager remains exactly 844 high.
// Widget tests assert a 64dp row plus 0.75dp divider without system insets.
// Widget tests compare list bottom padding with the rendered navigation height.
// Floating-navigation tests assert that the page extends behind the pill region.
// Glass tests verify that real page pixels remain visible through blurred panels.
// Snackbar tests verify that feedback is painted above the active navigation bar.
// Adaptive tests lock the 600dp ratio boundary and unconditional 840dp boundary.
// Any future navigation metric change must update source evidence and these tests.
// Static analysis and the package comment-ratio gate must remain clean afterward.
