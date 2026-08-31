// Navigation and top-app-bar source parity contract.
//
// Provenance
// ----------
// The authority for this contract is compose-miuix 0.9.3.
// The regular bar maps to basic/NavigationBar.kt.
// The floating bar maps to basic/NavigationBar.kt.
// The large title bar maps to basic/TopAppBar.kt.
// The compact title bar maps to SmallTopAppBar in that same source.
// Example option order maps to the source SettingsPage.kt.
// Example adaptive behavior maps to utils/PageUtils.kt.
// Names are localized only in the Flutter example UI.
// Public Dart identifiers remain English for package consumers.
// Values listed here are source measurements, not visual guesses.
// This file documents intentional choices made in the executable widgets.
// It also prevents later refactors from reintroducing Material defaults.
//
// Regular NavigationBar surface
// -----------------------------
// The regular navigation bar fills the available width.
// The destination row has an exact logical height of 64dp.
// Bottom system-window padding is outside that 64dp item row.
// Default background is the MIUIX surface semantic color.
// A divider is visible by default at the top edge.
// The divider is a line, not a drop shadow.
// The regular bar has no floating outer margin.
// The regular bar has no corner radius.
// The regular bar has no glass capsule.
// The regular bar has no selected pill.
// The regular bar has no selected icon background.
// The regular bar has no Material splash.
// Empty destination lists must remain safe.
// Out-of-range selected indices are clamped safely.
// Every destination receives equal horizontal width.
// The supported source range is two through five destinations.
// The API remains tolerant outside that range for defensive rendering.
// Semantics expose every destination as a selectable button.
// Semantics expose the source label even in icon-only mode.
// The selected semantics state follows the clamped destination index.
//
// Regular NavigationBar common item metrics
// -----------------------------------------
// Navigation icons are exactly 26dp square.
// Navigation labels are exactly 12sp.
// Selected label weight is bold.
// Unselected label weight is normal.
// The selected tint is onSurfaceContainer.
// Flutter maps onSurfaceContainer to ColorScheme.onSurface.
// The unselected resting alpha is 0.4.
// The selected pressed alpha is 0.5.
// The unselected pressed alpha is 0.6.
// Pressed tint replaces the resting tint immediately.
// Releasing restores the selection-derived tint.
// Cancelling a gesture also restores the resting tint.
// Icon and label colors always use the same resolved tint.
// A selectedIcon may replace the normal icon when supplied.
// A normal icon remains valid when selectedIcon is absent.
// Selection color moves over the same 300ms mode transition interval.
// Selection changes never animate a background because none exists.
// Destination taps report the source list index.
// Gesture hit testing covers the whole equal-width item.
// Labels use one line and ellipsize when width is constrained.
//
// IconAndText mode
// ----------------
// IconAndText is the first and default source display mode.
// Both icon and label remain present for every destination.
// The icon begins 8dp below the top of the 64dp item.
// The label ends 8dp above the bottom of the item.
// Remaining vertical space separates the icon and label.
// Selection changes tint and label weight only.
// No item changes its occupied width on selection.
// No item changes its occupied height on selection.
// This mode is localized as "图标和文字" in the example.
// The obsolete Dart name iconAndLabel must not return.
//
// IconOnly mode
// -------------
// IconOnly is the second source display mode.
// Every label is removed from the visual tree.
// Icons remain vertically centered in the 64dp item.
// Icon size remains 26dp rather than growing to fill the label space.
// Accessibility labels remain available through semantics.
// Selection remains visible through tint and optional selectedIcon.
// This mode is localized as "仅图标" in the example.
// IconOnly is not the floating navigation component.
// Choosing IconOnly must not change the bar surface shape.
// Choosing IconOnly must not change system inset handling.
//
// IconWithSelectedLabel mode
// -------------------------
// IconWithSelectedLabel is the third current source display mode.
// Icons remain visible for every destination.
// Only the selected destination reveals its label.
// The selected icon top position is 8dp.
// The unselected icon top position is 19dp.
// Nineteen is the centered offset for a 26dp icon in a 64dp item.
// Icon top position interpolates during selection changes.
// Label opacity interpolates during selection changes.
// The selection interpolation lasts 300ms.
// The label remains 8dp above the item bottom when visible.
// The selected label retains the 12sp bold source typography.
// Hidden labels retain semantics through their parent destination.
// This mode is localized as "仅选中项显示文字" in the example.
// The current source removed its historical text-only mode.
// Therefore the Flutter library does not invent a text-only enum value.
// A request for icon/text switching maps to these three source modes.
// Mode changes cross-fade over the source 300ms interval.
// Mode changes do not introduce scale, slide, or pill motion.
//
// FloatingNavigationBar identity
// ------------------------------
// FloatingNavigationBar is a separate component, not a display mode.
// It is always icon-only in the current source.
// It accepts the same navigation item model for shell reuse.
// Item semantics still expose labels.
// The selected destination may use selectedIcon.
// The source supports two through five items.
// Defensive rendering remains safe for an empty list.
// Out-of-range selection is clamped before rendering.
// Both onSelected and onDestinationSelected names are accepted.
// The latter aligns new code with the regular navigation callback.
// The former remains for compatibility with the previous Flutter API.
// At least one callback is required by constructor assertion.
//
// FloatingNavigationBar surface metrics
// -------------------------------------
// Minimum floating surface height is 52dp.
// The default corner radius is 50dp.
// That radius comes from FloatingToolbarDefaults.CornerRadius.
// The default surface color is surfaceContainer.
// The default internal horizontal padding is 12dp.
// The default spacing between destination items is 12dp.
// The default outside aligned-edge padding is 36dp.
// The floating bar has no divider by default.
// Enabling the divider uses a 0.75dp outline.
// Default shadow elevation is enabled at logical value 1dp.
// The source shadow blur radius is 10dp.
// The source shadow color is black at alpha 0.2.
// The source shadow has no decorative colored glow.
// The floating surface is not glass by default.
// The floating surface is not translucent by default.
// Blur may be supplied externally by the example's backdrop layer.
// The component itself must not force a glass implementation.
// The surface consumes taps so content below cannot receive them.
// The row sizes to its icon content rather than filling the screen.
// The host remains full width so alignment choices have meaning.
//
// FloatingNavigationBar item metrics
// ----------------------------------
// Floating destination icons are exactly 28dp square.
// Each icon has 10dp padding on all four sides.
// Each item therefore occupies 48dp before inter-item spacing.
// The containing surface supplies the remaining minimum-height centering.
// The selected tint is onSurfaceContainer.
// Flutter resolves that semantic role through ColorScheme.onSurface.
// The unselected resting alpha is 0.4.
// The selected pressed alpha is 0.5.
// The unselected pressed alpha is 0.6.
// The component has no visible text labels.
// The component has no selected pill.
// The component has no per-item background.
// The component has no Material ink splash.
// The entire 48dp item is the gesture target.
// Press cancellation restores the appropriate resting tint.
// Destination order matches the supplied list exactly.
//
// FloatingNavigationBar placement and insets
// ------------------------------------------
// The default horizontal placement is centered.
// Start placement aligns the surface to the leading edge.
// End placement aligns the surface to the trailing edge.
// Start placement applies 36dp only on the leading outside edge.
// End placement applies 36dp only on the trailing outside edge.
// Center placement applies no unnecessary horizontal outside padding.
// Directional alignment respects left-to-right and right-to-left text.
// iOS uses 36dp of bottom outside padding in the source.
// Other platforms use 36dp when navigation inset is zero.
// Other platforms use navigation inset plus 26dp when it is nonzero.
// Flutter MediaQuery bottom padding supplies the navigation inset.
// Disabling defaultWindowInsetsPadding removes this bottom padding.
// Caption-bar inset changes animate over 300ms in the source.
// Flutter rebuilds against MediaQuery inset changes from the host window.
// The floating bar may be passed directly to scaffold.bottomBar.
// The example replaces the regular bar rather than overlaying both bars.
//
// TopAppBar shared surface contract
// ---------------------------------
// Both title bar variants use surface as their default color.
// Neither variant draws a bottom border by default.
// Neither variant adds an unsolicited shadow.
// Compact title color defaults to onSurface.
// Large title color defaults to onSurface.
// Subtitle color defaults to onSurfaceVariant.
// The compact title size is 20sp.
// The compact title uses medium weight.
// The large title size is 32sp.
// The large title uses normal weight.
// Subtitle size is 14sp.
// Collapsed title-area height is exactly 52dp.
// Compact vertical center is exactly 50dp divided by two.
// Title horizontal padding defaults to 26dp.
// Navigation icon start padding defaults to 16dp.
// Action icon end padding defaults to 16dp.
// Maximum title width factor is 0.9.
// Titles use one line and ellipsize under constraints.
// The compact title remains centered when side slots permit.
// The compact title is clamped away from navigation and action slots.
// Navigation and action slots remain in the 52dp collapsed band.
// Action slots use stable hit-area allocation.
// System-window top padding is enabled by default.
// Wide adaptive bars may disable it when an outer scaffold owns padding.
// Custom background and semantic title colors are supported.
// Optional bottomContent is placed after the title area.
// bottomContentHeight reserves deterministic preferred size for Flutter.
//
// Large TopAppBar expanded layout
// -------------------------------
// The expanded large title begins after the 52dp collapsed band.
// A title-only expanded bar is approximately 94dp tall.
// The exact source height is derived from measured title content.
// Flutter exposes expandedHeight for exact custom text measurement cases.
// Large title bottom padding is exactly 4dp without a subtitle.
// Subtitle bottom padding is exactly 8dp when a subtitle is present.
// The large title uses the optional largeTitle string when supplied.
// It falls back to the compact title string otherwise.
// Subtitle appears below the large title while expanded.
// A subtitle also appears below the compact title when collapsed.
// The expanded title is left aligned at the 26dp title inset.
// The expanded title never receives a Material toolbar baseline offset.
// The large layout clips content while its height collapses.
// Leading and action icons stay visible during the entire transition.
// Preferred size follows the current normalized collapse fraction.
// Scaffold rebuilds when that preferred size changes.
// The body therefore follows the bar without leaving an expanded gap.
//
// Large TopAppBar collapse motion
// -------------------------------
// Collapse fraction zero means fully expanded.
// Collapse fraction one means fully collapsed.
// Vertical scroll notifications drive the fraction.
// Horizontal PageView notifications are ignored.
// The leading 42dp scroll range maps to the title collapse extent.
// Negative overscroll clamps the bar to fully expanded.
// Large title alpha follows one minus collapseFraction times three.
// Large title is fully hidden at one-third collapse.
// Compact title becomes visible at one-third collapse.
// This visibility threshold matches the source title transition.
// Navigation and action slots do not fade with the title.
// A scroll start cancels any in-progress settle animation.
// A scroll end below midpoint settles to expanded.
// A scroll end at or above midpoint settles to collapsed.
// The settle duration defaults to 300ms.
// The settle curve is critically damped and does not overshoot bounds.
// The source folme response is represented without introducing bounce.
// Callers may set collapseFraction directly for deterministic control.
// Callers may expand immediately after root-page navigation.
// The controller owns and cancels its settle timer on dispose.
// MiuixScaffold subscribes and unsubscribes controller listeners safely.
// MiuixScaffold forwards body ScrollNotifications without consuming them.
// Nested scrollables retain their own normal Flutter behavior.
//
// Compact-title spring parity
// ---------------------------
// The source mounts compact and expanded title nodes at the same time.
// Expanded state keeps the compact title at alpha zero.
// The compact node remains centered in the collapsed 52dp band.
// It does not participate in the large-title height measurement.
// The visibility trigger is collapsedFraction multiplied by three.
// Values below one keep the compact title target hidden.
// Values at or above one set the compact title target visible.
// Crossing the threshold starts an independent animation.
// Continued scroll does not scrub that independent animation.
// Showing uses folmeSpring damping one and response 0.3 seconds.
// Hiding uses folmeSpring damping one and response 0.15 seconds.
// Damping one is the critically damped no-overshoot case.
// Folme stiffness is the square of two pi divided by response.
// The corresponding step response starts with zero velocity.
// Its position is one minus one plus omega t times exp minus omega t.
// Flutter normalizes that response to its finite animation interval.
// Normalization preserves the source acceleration and exact final value.
// Compact title alpha is the spring position.
// Compact subtitle alpha shares the same spring position.
// Compact title translation starts at 20 physical pixels.
// Compact subtitle translation shares that physical-pixel offset.
// Translation approaches zero while the title becomes visible.
// Translation returns to 20 pixels while the title becomes hidden.
// Compose graphicsLayer translation is expressed in raw pixels.
// Flutter therefore divides 20 by the current device-pixel ratio.
// A 420dpi Android device travels about 7.62 logical pixels.
// A density-one Windows surface travels 20 logical pixels.
// Leading navigation content never uses the title opacity.
// Trailing action content never uses the title opacity.
// Their hit targets remain active throughout the transition.
// Their visual centers remain fixed throughout the transition.
// Large-title alpha remains driven directly by collapse fraction.
// Large-title alpha reaches zero at the same one-third threshold.
// The compact animation can therefore continue after large title removal.
// The source snap spec uses spring stiffness 2500.
// Its default damping is critical and does not overshoot.
// Angular frequency is the square root of stiffness.
// The equivalent response is two pi divided by square root 2500.
// The settle timer samples that response at Flutter frame cadence.
// Direct controller values remain clamped between zero and one.
// Zero-duration controllers still settle synchronously for deterministic tests.
// Widget tests sample intermediate show and hide opacity values.
// Android captures verify expanded and collapsed endpoint geometry.
//
// SmallTopAppBar contract
// ----------------------
// MiuixSmallTopAppBar is a named adapter for the compact source variant.
// It always reports the 52dp title-area preferred height.
// It uses the same title, subtitle, navigation, and action slots.
// It accepts the same color and padding overrides.
// It accepts the same optional bottom content slot.
// It does not expose or require a collapse controller.
// Wide example layouts choose this variant.
// Narrow example layouts choose the large variant.
// This matches the source AdaptiveTopAppBar helper.
//
// Localized example integration
// -----------------------------
// The five root page titles are translated to Simplified Chinese.
// Narrow pages display the translated title as a large title.
// Wide pages display the translated title in SmallTopAppBar.
// The settings page shows the package version as subtitle.
// Page selection expands the shared large-title controller.
// Body scrolling then collapses the title for the active page.
// Navigation mode options preserve source enum order.
// "图标和文字" maps to IconAndText.
// "仅图标" maps to IconOnly.
// "仅选中项显示文字" maps to IconWithSelectedLabel.
// The floating navigation switch is separate from display mode.
// Regular display-mode selection hides while floating mode is active.
// Floating position selection appears only while floating mode is active.
// "居中" maps to center placement.
// "靠左" maps to start placement.
// "靠右" maps to end placement.
// Switching regular and floating bars uses a 300ms cross-fade.
// Root destination changes retain the existing 300ms pager transition.
// The example defaults to the source IconAndText mode.
// The example defaults to the source non-floating configuration.
// The example defaults the navigation badge to hidden like AppState.kt.
//
// Regression requirements
// -----------------------
// Static analysis must pass for both the package and localized example.
// Package widget tests cover source dimensions and semantic colors.
// Package widget tests cover all three regular display modes.
// Package widget tests cover expanded, midpoint, and collapsed bar heights.
// Floating tests cover icon size, icon padding, spacing, and tint.
// Golden tests cover regular navigation in light and dark themes.
// Golden tests cover compact TopAppBar with both side slots.
// Golden tests cover the floating navigation surface independently.
// Example tests verify that settings mutate the real shell.
// Android release output must remain arm64-v8a only when requested.
// Android non-production signing must be disclosed when a debug key is used.
// Windows release output must include the runner and required runtime files.
// Component source remains split into bounded, reviewable part files.
// navigation.dart retains scaffold, rail, tabs, and navigation utilities.
// navigation_bars.dart owns regular and floating bottom navigation.
// top_app_bars.dart owns both title variants and collapse behavior.
// Future changes must compare against the source before changing constants.
// Future changes must not restore removed text-only documentation.
// Future changes must not reinterpret floating navigation as a display mode.
// Future changes must not add selected pills absent from the source.
// Future changes must keep the project comment-ratio check at fifty percent.
