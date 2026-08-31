// iOS-like liquid navigation source-parity contract.
//
// Authority
// ---------
// The visual authority is compose-miuix example version 0.9.3.
// The exact source file is component/liquid/LiquidGlassNavigationBar.kt.
// AppContent.kt selects this surface when floatingNavigationBarStyle is one.
// SettingsPage.kt labels that option iOS-like.
// AppState.kt stores the option independently from floating alignment.
// The implementation is example-originated rather than a Material pattern.
// The Flutter public widget preserves that source identity.
// The widget is not a display mode of the regular NavigationBar.
// The widget is not a color variant of FloatingNavigationBar.
// The widget is a third navigation surface with its own metrics.
// Visible labels may be localized by an application.
// Public Dart identifiers remain English.
// Source measurements remain logical pixels on every Flutter platform.
// No measurement in this contract comes from visual guessing.
// Every number below maps to a constant or expression in the Kotlin source.
// The contract is intentionally more precise than a screenshot comparison.
// It exists to stop future refactors from collapsing distinct source styles.
// It also explains why the widget belongs in its own Dart source file.
//
// Public API
// ----------
// MiuixIosLiquidGlassNavigationBar is a StatefulWidget.
// The items argument is required.
// The selectedIndex argument is required.
// The onDestinationSelected callback is required.
// The supported item count is two through five.
// The constructor asserts that supported source range.
// Each item reuses the MiuixNavigationItem data contract.
// Each item supplies a visible label.
// Each item supplies an icon.
// A selected icon may replace the ordinary icon in the indicator layer.
// The owning pager remains the source of truth for selectedIndex.
// Internal visual position may temporarily be fractional during motion.
// showBlur permits applications to disable the liquid backdrop effect.
// Theme enableGlass remains the global blur gate.
// Both gates must be true before BackdropFilter is created.
// defaultWindowInsetsPadding controls bottom system inset behavior.
// Disabling it removes only the outside bottom padding.
// Disabling it does not change the 64dp panel.
// The widget does not own route navigation.
// The callback lets the application animate its pager.
// The widget does not translate destination labels.
// The widget exposes stable semantics for assistive technology.
// Stable ValueKeys exist only to support exact regression checks.
// The keys do not affect production layout.
// The API does not expose Material NavigationBar properties.
// The API does not expose regular floating-bar alignment.
// The iOS-like style always uses the source full-width panel.
//
// Outer placement
// ---------------
// The outer widget fills the horizontal space offered by its bottom-bar host.
// It applies 24dp at the physical left edge.
// It applies 24dp at the physical right edge.
// The source uses start and end values of 24dp.
// Equal values make the geometry direction-independent.
// The panel width is therefore host width minus 48dp.
// A 390dp host produces a 342dp panel.
// The panel is horizontally centered by those equal insets.
// There is no start, center, or end alignment option for this style.
// FloatingNavigationBar alignment applies only to the default style.
// The settings page hides alignment while iOS-like is selected.
// The widget occupies only panel height plus bottom padding.
// It must never expand to the whole Scaffold height.
// It must never reserve an opaque rectangle behind the capsule.
// The application Scaffold uses extendBody for floating styles.
// Body painting therefore continues behind all non-panel space.
// Transparent outside space must reveal page content.
// Transparent outside space must not reveal a replacement surface color.
// The panel's bottom edge is separated from the window edge.
// On a platform with no navigation inset that separation is 36dp.
// With a non-zero navigation inset it is 8dp plus the inset.
// The source has a special iOS value of 20dp.
// Flutter has no reliable generic runtime iOS-layout signal in this widget.
// The cross-platform mapping uses the source non-iOS inset expression.
// Android gesture navigation therefore remains safe.
// Windows with no inset receives the exact 36dp fallback.
// A 390 by 844 no-inset test places panel bottom at 808dp.
// Its transparent host continues to the screen bottom at 844dp.
// Caption-bar height does not alter the panel height.
// System padding stays outside the glass layer.
// Shadows may paint outside panel bounds but do not change layout bounds.
//
// Panel geometry
// --------------
// The outer panel height is exactly 64dp.
// The outer panel shape is a circle-derived pill.
// Its effective radius is 32dp.
// The panel contains 4dp of padding on all four sides.
// The usable tab strip height is therefore 56dp.
// The usable tab strip width is panel width minus 8dp.
// Five items in a 342dp panel receive 66.8dp each.
// Every item receives exactly equal width.
// Labels do not change destination width.
// Badges do not change destination width.
// Selected state does not change destination width.
// Press state does not change the Row's measured width.
// Drag state does not change the Row's measured width.
// The panel uses a Stack so indicator and base content share geometry.
// The base content begins at x equals 4dp.
// The indicator begins at x equals 4dp plus visual index times tab width.
// The indicator top is exactly 4dp.
// The indicator height is exactly 56dp.
// The indicator width is exactly one tab width.
// The indicator radius is 28dp.
// The indicator clips all selected-content overflow.
// The panel clips all blur and content to its 32dp radius.
// The drop shadow is painted outside the clipping layer.
// The panel remains one continuous hit-test region.
// Tab hit regions divide the 56dp content width evenly.
// The remaining 4dp vertical edges belong to the panel gesture region.
// The panel never falls back to Material NavigationBar height.
// The panel never uses the 52dp default floating-bar minimum.
// The panel never uses regular navigation's 64dp icon-and-label row.
// Similar heights do not make those components interchangeable.
// Layout tests assert panel left, right, height, and bottom.
// Layout tests assert indicator height, top inset, and computed width.
//
// Tab content
// -----------
// Every tab is a vertically centered Column.
// The icon has an exact 22dp square box.
// The source icon size is 22dp.
// IconTheme carries both source size and active color.
// The icon-to-label gap is exactly 1dp.
// The label font size is exactly 11sp.
// The label font weight is normal.
// The label uses one line.
// The label truncates with an ellipsis when necessary.
// The label uses a compact line height to retain source centering.
// Base tab content uses onSurface color.
// Selected overlay content uses primary color.
// The selected overlay may use selectedIcon when supplied.
// The base row uses the ordinary icon for every destination.
// The overlay row paints all destinations offscreen.
// Only one overlay-tab slice is revealed by the indicator clip.
// Translating that overlay row keeps selected glyphs pixel-aligned.
// The overlay translation equals negative visual index times tab width.
// The indicator translation equals positive visual index times tab width.
// Those transformations cancel for the revealed destination.
// Fractional drag values reveal a continuous transition between destinations.
// No text is reconstructed during a drag.
// No icon is swapped at a fractional boundary.
// Badges supplied inside an icon remain part of both paint layers.
// The overlay content ignores pointers.
// The base content owns pointer and semantic behavior.
// Overlay content must not create duplicate selectable semantics.
// Tab content never shows a Material splash.
// Tab content never shows a Material hover fill.
// Press feedback belongs to the liquid indicator scale.
// Item order exactly follows the supplied list.
// The localized example order remains Home, Icons, Colors, Text, Settings.
//
// Surface and glass
// -----------------
// The non-blurred panel uses surfaceContainer at full opacity.
// The blurred panel uses surfaceContainer at 40 percent opacity.
// The source samples content behind the panel.
// Flutter performs that sampling with BackdropFilter.
// The blur sigma is 4 on both axes.
// The filter is clipped to the 32dp panel pill.
// A white 12 percent outline approximates the source specular highlight.
// The outline is painted above the blurred surface.
// The outline ignores pointers.
// The source shadow radius is 10dp.
// The source shadow color is black.
// The source shadow alpha is 20 percent.
// The Flutter BoxShadow uses the same blur radius and alpha.
// Shadow elevation is not represented by a Material elevation widget.
// Avoiding Material elevation prevents tint overlays.
// In light glass mode the resting indicator adds 10 percent black.
// In dark glass mode the resting indicator adds 10 percent white.
// In non-glass mode the indicator uses primary at 15 percent.
// Selected icon and label remain primary in every mode.
// The source adds refraction and chromatic aberration when shaders exist.
// Flutter BackdropFilter cannot reproduce arbitrary lens refraction alone.
// The API isolates this limitation inside the glass surface.
// Geometry and interaction remain exact when refraction is unavailable.
// A later runtime shader may replace only the effect layer.
// Such a shader must not change panel dimensions.
// Such a shader must not change hit testing.
// Such a shader must not change semantics.
// Such a shader must respect showBlur and enableGlass.
// High-contrast themes may still derive colors from ColorScheme.
// Surface opacity must not become an opaque reserved bottom strip.
// The Scaffold body remains visible behind the panel and its outside space.
//
// Selection animation
// -------------------
// The visual selection coordinate is a double.
// Whole numbers identify settled destinations.
// Fractional values identify drag or spring positions.
// The owning selectedIndex is clamped before initialization.
// An unbounded AnimationController stores the coordinate.
// Manual clamping keeps the coordinate inside destination bounds.
// Programmatic selection uses a spring simulation.
// The source spring stiffness is 300.
// The Flutter spring stiffness is also 300.
// The source spring is critically damped.
// Flutter damping is computed as two times square root of stiffness.
// Spring mass is one.
// The animation stops before a new target starts.
// A selectedIndex update animates only when the delta is meaningful.
// The epsilon threshold is .001 destinations.
// Rebuilding with the same selectedIndex does not restart motion.
// Tapping a destination starts visual motion immediately.
// The callback then lets the owning pager follow.
// Parent rebuilds do not snap the ongoing indicator.
// Drag start stops an active spring.
// Drag update divides physical delta by tab width.
// Drag update therefore has one destination per tab-width movement.
// Drag update clamps at the first and last destinations.
// Drag end rounds to the closest destination.
// Drag end converts pixel velocity into destinations per second.
// That velocity seeds the settling spring.
// The callback fires only if the target differs from selectedIndex.
// The indicator scale grows from 56dp to the source 78dp press scale.
// The scale animation lasts 140 milliseconds.
// The scale release uses an ease-out curve.
// Scaling does not alter the indicator's layout allocation.
// Scaling does not alter tab widths.
// Scaling is clipped by the panel boundary where appropriate.
// Destination changes must never use a hard linear jump.
//
// Gesture behavior
// ----------------
// Every base tab has an opaque hit-test region.
// A tap selects that tab.
// Pressing the current tab activates indicator scale feedback.
// Releasing a tap removes scale feedback.
// Cancelling a tap removes scale feedback.
// The panel also recognizes horizontal drag gestures.
// The panel consumes drag movement across item boundaries.
// Drag cancellation clears press feedback.
// Horizontal dragging does not resize the panel.
// Horizontal dragging does not scroll the page behind the panel.
// Tap and drag recognizers participate in Flutter's gesture arena.
// A simple tap remains owned by the destination child.
// A directional drag becomes owned by the panel recognizer.
// The indicator itself ignores pointers.
// That rule prevents the selected layer from blocking base tabs.
// Outside transparent padding has no panel tap behavior.
// Page content behind outside padding remains visually available.
// Bottom safe padding is not a destination hit region.
// Repeated taps on the selected item do not duplicate callbacks.
// A drag settling on the selected item does not duplicate callbacks.
// A callback may animate a PageView.
// The PageView onPageChanged result may update selectedIndex later.
// The spring tolerates that asynchronous parent update.
// A callback may synchronously rebuild the entire application shell.
// AnimationController remains owned by the persistent keyed state.
// AnimatedSwitcher keys distinguish default and iOS-like surfaces.
// Changing styles disposes the old animation controller safely.
// No timer survives widget disposal.
// No future calls setState after disposal.
//
// Semantics and accessibility
// ---------------------------
// Each interactive tab exposes a semantic button.
// Each interactive tab exposes its localized label.
// The current destination exposes selected equals true.
// Other destinations expose selected equals false.
// The selected semantic index follows the clamped parent index.
// The visual fractional position does not create fractional semantics.
// The hidden overlay row does not own taps.
// The hidden overlay row must not become a second navigation group.
// Decorative selected content must not be announced twice.
// Icons are decorative because the adjacent label names the destination.
// Truncated visible labels retain their full semantic label.
// Keyboard activation may target the semantic button.
// Screen readers encounter items in source list order.
// RTL layout retains list order through Flutter Row behavior.
// Equal physical outer insets remain correct in RTL.
// Indicator positioning currently follows the visual Row coordinate.
// Any future explicit RTL transform must move both paint layers together.
// Pointer scale feedback must not reduce semantic bounds.
// Blur availability must not alter semantic output.
// Theme brightness must not alter semantic output.
// Safe-area size must not alter semantic output.
// The test keys are not used as semantic labels.
// The panel itself is not announced as an extra button.
// Destination buttons remain reachable when content extends behind the bar.
// The transparent host is not announced.
// App localization owns pronunciation-friendly destination strings.
// Public library code never hardcodes example Chinese labels.
// The example translates visible labels while retaining original order.
//
// Example settings integration
// ----------------------------
// showNavigation remains the outer visibility switch.
// useFloatingNavigationBar chooses floating rather than regular navigation.
// floatingNavigationBarStyle chooses default or iOS-like floating style.
// The default stored style is default.
// The localized options appear as 默认 and iOS 风格.
// Style selection is visible only while floating navigation is enabled.
// Alignment selection is visible only for the default floating style.
// Selecting iOS-like retains the stored default alignment value.
// Returning to default restores that stored alignment.
// Badge visibility is shared by all navigation styles.
// Root selectedIndex is shared by all navigation styles.
// The iOS-like style calls the same page-selection method.
// The root PageView remains the destination content owner.
// The root Scaffold enables extendBody for both floating styles.
// The root settings page can scroll behind either floating surface.
// The root body keeps additional bottom content padding.
// That padding prevents the final preference from becoming unreachable.
// The padding does not paint an opaque navigation rectangle.
// AnimatedSwitcher transitions between navigation surfaces.
// Each surface has a distinct ValueKey.
// iOS-like position remains centered and full-width within 24dp margins.
// The style does not consume floatingNavigationBarAlignment.
// The style respects the global enableBlur setting.
// Disabling blur keeps the exact same panel geometry.
// Disabling blur uses source non-glass indicator colors.
// Wide layouts continue using NavigationRail instead.
// The iOS-like option is hidden on wide layouts.
// The regular navigation display-mode selector remains independent.
// Changing regular display mode does not affect this surface.
// All settings labels are translated without changing control order.
//
// Regression evidence
// -------------------
// Widget tests use a 390 by 844 logical-pixel viewport.
// Device pixel ratio is one for direct dp-to-pixel assertions.
// The test enters Settings through the fifth root destination.
// The test enables floating navigation.
// The test changes style through the real dropdown preference.
// The test verifies the iOS-like widget exists exactly once.
// The test verifies default FloatingNavigationBar is absent.
// The test verifies alignment control is hidden.
// The test verifies panel left equals 24.
// The test verifies panel right equals 366.
// The test verifies panel width equals 342 by implication.
// The test verifies panel height equals 64.
// The test verifies panel bottom equals 808.
// The test verifies bottom transparent space equals 36.
// The test verifies indicator top inset equals 4.
// The test verifies indicator height equals 56.
// The test verifies indicator width equals 66.8 for five items.
// The test taps a destination through its stable tab key.
// The test waits for both spring and pager animation to settle.
// The test verifies the Icons page becomes active.
// A golden captures the complete root shell with this style.
// The golden includes content painted behind the bottom-bar host.
// The golden includes translated labels.
// The golden includes the selected indicator.
// The golden includes glass surface and shadow.
// Golden updates require visual inspection before acceptance.
// A passing narrow test cannot prove wide NavigationRail behavior.
// A passing golden cannot replace the explicit geometry assertions.
// Explicit geometry cannot replace the interaction assertion.
// Interaction cannot replace semantic review.
// Full package analysis must remain clean.
// Root and example test suites must both remain green.
// Android and Windows release builds remain final integration gates.
// Comment-ratio verification includes this executable contract.
// The overall original-example parity goal remains broader than this widget.
