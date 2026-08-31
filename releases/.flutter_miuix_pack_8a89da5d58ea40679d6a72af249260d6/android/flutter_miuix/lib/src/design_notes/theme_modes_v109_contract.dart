// MIUIX v1.0.9 theme-mode reconstruction contract.
//
// Purpose
// -------
// This note records the observable source behavior used by the Flutter port.
// It prevents the example settings from drifting into a custom theme editor.
// It also explains which options belong to the public library theme object.
// Visible labels may be localized, but option identity and order stay intact.
//
// Color modes
// -----------
// The source exposes exactly six color modes.
// System is the first mode.
// Light is the second mode.
// Dark is the third mode.
// Monet System is the fourth mode.
// Monet Light is the fifth mode.
// Monet Dark is the sixth mode.
// System follows the host brightness.
// Light always resolves to a light scheme.
// Dark always resolves to a dark scheme.
// Monet System follows the host brightness.
// Monet Light always resolves to a light dynamic scheme.
// Monet Dark always resolves to a dark dynamic scheme.
// Fixed modes do not expose dynamic key-color controls in the example.
// Monet modes expose the key-color control immediately.
//
// Key colors
// ----------
// Default is the first key-color choice.
// Blue, green, purple, yellow, orange, pink, and teal follow Default.
// The translated labels do not change the source RGB values.
// Default represents the absence of an explicit user seed.
// A missing explicit seed uses Android's platform dynamic palette on Android.
// Other platforms use ThemeController's deterministic fallback purple.
// Selecting a concrete key color rebuilds all inherited MIUIX theme data.
// The color preview page reads the same effective seed as the components.
// Key-color selection survives changes between the three Monet modes.
// Fixed modes retain the selection without applying it to their fixed scheme.
//
// Palette styles
// --------------
// Palette controls appear only after a concrete Monet key color is selected.
// Tonal Spot is the first and default palette family.
// Neutral is the second palette family.
// Vibrant is the third palette family.
// Expressive is the fourth palette family.
// Rainbow is the fifth palette family.
// Fruit Salad is the sixth palette family.
// Monochrome is the seventh palette family.
// Fidelity is the eighth palette family.
// Content is the ninth palette family.
// Their order follows the source SettingsPage rather than alphabetical order.
// Every family maps to the corresponding Flutter dynamic-scheme variant.
// Changing family must change the generated scheme without changing its seed.
// Changing family must not alter the selected light or dark mode policy.
//
// Color specifications
// --------------------
// The source exposes Spec 2021 first and Spec 2025 second.
// Specification controls follow the same visibility rule as palette controls.
// The selected specification is retained in MiuixThemeData.
// copyWith preserves it unless a replacement is supplied.
// Theme interpolation chooses one specification at the midpoint.
// Monet generation uses the same 2021 and 2025 dynamic-color algorithms.
// Tonal Spot, Neutral, Vibrant, and Expressive retain a requested Spec 2025.
// Rainbow, Fruit Salad, Monochrome, Fidelity, and Content fall back to 2021.
// This support matrix is the one implemented by source ThemeController.kt.
// Every generated Material role is preserved before MIUIX semantic mapping.
// Tests lock representative 2021 and 2025 colors for the example's blue seed.
// The fallback does not affect the six mode choices or nine palette styles.
//
// Settings visibility
// -------------------
// Color Mode is always visible in the main source settings card.
// Key Color is hidden for System, Light, and Dark.
// Key Color is visible for all three Monet modes.
// Palette Style is hidden while Key Color is Default.
// Color Spec is hidden while Key Color is Default.
// Palette Style appears after a concrete Monet key is selected.
// Color Spec appears after a concrete Monet key is selected.
// Returning to a fixed mode hides all three conditional dynamic controls.
// Returning to Monet restores the retained selections.
// Conditional rows must not leave blank dividers or placeholder height.
// The source settings cards do not add automatic section headings.
// The source settings cards do not add automatic row dividers.
//
// Glass interaction
// -----------------
// Theme color selection and liquid-glass intensity are independent tokens.
// Changing a palette does not reset the five-level glass choice.
// Changing a glass level does not reset the key color or palette family.
// Disabling blur retains the chosen glass intensity for later restoration.
// Glass components tint from the currently resolved color scheme.
// Opaque components continue to use the same resolved semantic colors.
// Floating navigation paints only its pill-shaped glass surface.
// The rectangular area around that pill remains transparent.
// Page content remains laid out behind floating navigation through extendBody.
// Transparent regions never become a full-screen modal or opaque scaffold.
//
// Verification
// ------------
// Unit tests count all six public color-mode values.
// Unit tests count all nine public palette-style values.
// Unit tests count both public color-specification values.
// Widget tests verify conditional settings-row visibility.
// Widget tests verify forced brightness for Monet Light and Monet Dark.
// Widget tests verify a selected key color reaches inherited theme data.
// Widget tests verify palette changes alter the generated primary color.
// Golden tests cover floating navigation above real scrolling page content.
// Golden tests cover the iOS-like selected-item liquid-glass treatment.
// Static analysis must remain clean after any option is added or renamed.
// The package comment-ratio check includes this maintained design contract.
