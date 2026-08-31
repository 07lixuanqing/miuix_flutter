// MIUIX 1.0.9 Button parity contract.
//
// Purpose
//
// This note records the durable behavior defined by Button.kt.
// It covers both Button and the TextButton convenience overload.
// The rules distinguish upstream behavior from Flutter compatibility APIs.
// Each rule affects public API, painting, measurement, input, or semantics.
//
// Source Button API
//
// The source callback is named onClick.
// The source callback is non-null even when enabled is false.
// Flutter retains nullable onPressed for ecosystem compatibility.
// A null Flutter callback is treated as unavailable interaction.
// The source enabled parameter defaults to true.
// enabled controls click installation and both disabled color fields.
// The source cornerRadius parameter defaults to 16dp.
// The source minWidth parameter defaults to 58dp.
// The source minHeight parameter defaults to 40dp.
// The source colors parameter carries four independent colors.
// The source insideMargin parameter defaults to 16dp horizontal padding.
// The same insideMargin defaults to 13dp vertical padding.
// The source accepts a caller-owned MutableInteractionSource.
// The source accepts a nullable Indication.
// The source ends with an arbitrary RowScope content slot.
// Arbitrary content is not restricted to text or icons.
//
// Flutter compatibility surface
//
// label is a convenience retained from earlier flutter_miuix releases.
// child represents the source-equivalent arbitrary content slot.
// Exactly one of label or child must be supplied.
// icon is available only beside the label convenience.
// Arbitrary child content owns its own internal arrangement.
// filled selects the upstream primary color factory.
// expand remains a Flutter-only full-width adapter.
// expand wraps the component instead of changing its source measurement.
// showIndication false represents a null upstream Indication.
// Explicit colors take precedence over the filled shortcut.
//
// Source TextButton API
//
// TextButton accepts text rather than arbitrary content.
// TextButton maps TextButtonColors into ordinary ButtonColors.
// TextButton then delegates all layout and interaction to Button.
// TextButton uses the MIUIX button text style.
// Its default container is secondaryVariant.
// Its default text color is onSecondaryVariant.
// Its primary factory uses primary and onPrimary.
// The Flutter icon parameter is a compatibility extension.
// The original v1.0.9 example uses no TextButton icon.
//
// Color model
//
// ButtonColors contains enabled container color.
// ButtonColors contains disabled container color.
// ButtonColors contains enabled local content color.
// ButtonColors contains disabled local content color.
// TextButtonColors names the content pair as text colors.
// Ordinary enabled color is secondaryVariant.
// Ordinary disabled color is disabledSecondaryVariant.
// Ordinary enabled content is onSecondaryVariant.
// Ordinary disabled content is disabledOnSecondaryVariant.
// Primary enabled color is primary.
// Primary disabled color is disabledPrimaryButton.
// Primary enabled content is onPrimary.
// Primary disabled content is disabledOnPrimaryButton.
// Disabled colors are explicit tokens rather than opacity multipliers.
// Caller colors are never silently blended with Material defaults.
//
// Enabled-state behavior
//
// Source Surface receives the enabled flag.
// Enabled Surface installs click semantics and pointer handling.
// Disabled Surface does not invoke onClick.
// Disabled Surface paints disabledColor.
// Disabled Surface publishes disabledContentColor locally.
// The content tree remains mounted when disabled.
// The content layout remains unchanged when disabled.
// The smooth shape remains unchanged when disabled.
// The minimum dimensions remain unchanged when disabled.
// Disabled state does not add an opacity wrapper.
// Flutter combines enabled with non-null onPressed.
// Either false condition disables activation.
// Disabled state also suppresses pressed indication.
//
// Shape contract
//
// Button calls miuixShape with cornerRadius.
// The default continuous-corner radius is 16dp.
// The global smooth-rounding preference selects G2 or ordinary rounding.
// Background and pressed indication share the same shape.
// The shape clips the entire content and container paint.
// A custom radius affects both enabled and disabled states.
// A zero radius is valid and creates a rectangular surface.
// Negative radii are invalid.
// Button does not add a border.
// Button does not add elevation.
// Button does not add a Material stadium shape.
//
// Modifier and layout order
//
// The caller modifier is applied to Surface.
// Surface owns clickable behavior and visual clipping.
// The inner Row receives defaultMinSize.
// Padding is appended after defaultMinSize.
// The final complete Row therefore includes insideMargin.
// Row uses horizontal Arrangement.Center.
// Row uses vertical Alignment.CenterVertically.
// The content slot is invoked inside that centered Row.
// Reversing padding and minimum size changes small-button geometry.
// Moving padding outside Surface changes indication clipping.
// Moving defaultMinSize outside Surface changes semantic bounds.
// Flutter preserves the same containment order.
//
// Minimum-size behavior
//
// Fifty-eight dp is a minimum rather than a fixed width.
// Forty dp is a minimum rather than a fixed height.
// Larger arbitrary content expands the surface.
// Wider localized labels expand unless a parent supplies a tight width.
// A grid may supply equal tight widths to sibling buttons.
// A tight parent may be narrower than the natural label.
// Label convenience uses one-line ellipsis in that compatibility case.
// Independent minWidth and minHeight values are supported.
// Zero minima are valid.
// Negative minima are rejected by the Flutter constructor.
// The caller's inside padding still contributes when minima are zero.
//
// Padding and physical pixels
//
// Compose rounds each PaddingValues edge independently.
// At 420dpi, 13dp becomes 34 physical pixels.
// Both vertical edges therefore contribute 68 physical pixels.
// The captured 17sp button text placeable contributes 52 physical pixels.
// A default example button consequently measures 120 physical pixels high.
// Combining logical dimensions before rounding can incorrectly produce 121px.
// Flutter resolves directional padding before rounding each edge.
// Custom asymmetric padding retains four independent rounding operations.
// Layout density changes do not alter source logical defaults.
//
// Label compatibility content
//
// The convenience label uses the MIUIX button text size of 17sp.
// It uses regular font weight.
// It uses zero extra letter spacing.
// The label receives the resolved enabled or disabled content color.
// Its text placeable is rounded upward to enclose fractional font bounds.
// Optional compatibility icon uses a 16dp icon theme.
// Six dp separates that icon from the label.
// Those icon rules are Flutter compatibility behavior.
// Arbitrary child content receives no invented icon size or gap.
//
// Arbitrary child inheritance
//
// Source Surface publishes LocalContentColor.
// Flutter publishes the equivalent DefaultTextStyle color.
// Flutter publishes the equivalent IconTheme color.
// A child Text with an explicit color still overrides inheritance.
// A child Icon with an explicit color still overrides inheritance.
// The child may contain multiple widgets.
// The child may be taller than the default minimum.
// The child may be wider than the default minimum.
// The child is not replaced when enabled state changes.
// The child is centered as one Row content group.
//
// Indication behavior
//
// Source Button defaults to LocalIndication.current.
// The MIUIX theme supplies its ordinary pressed overlay.
// A null indication disables overlay painting.
// Button does not use sink scaling by default.
// Button does not use tilt feedback by default.
// Button does not use Material splash geometry.
// The indication is clipped to the same continuous-corner shape.
// Disabled Button never enters the indicated state.
// Flutter showIndication controls the equivalent installation.
// Existing example buttons retain indication by default.
//
// Semantics and activation
//
// The source modifier assigns Role.Button.
// Flutter publishes the button semantics flag.
// Flutter publishes the effective enabled state.
// Pointer taps invoke the latest non-null callback.
// A disabled tap has no callback effect.
// Arbitrary child semantics remain available inside the button.
// The visual surface and semantic button share the same measured bounds.
// No extra Material minimum touch target is inserted by Button.kt.
// Parent layout therefore continues to own row spacing.
//
// Original example contract
//
// ButtonSection uses four TextButton instances.
// Two enabled buttons occupy the first equal-width row.
// Two disabled buttons occupy the second equal-width row.
// The ordinary column uses the secondaryVariant factory.
// The primary column uses textButtonColorsPrimary.
// Twelve dp separates the two columns.
// Twelve dp separates the two rows.
// Twelve dp follows the complete section.
// At 420dpi each outside and inter-item gap resolves to 32px.
// Each equal button column resolves to 492px.
// Each button height resolves to 120px.
// Clicking the enabled buttons changes only their localized label.
// Disabled buttons retain their source disabled color pairs.
//
// Regression obligations
//
// Default tonal and primary colors require separate assertions.
// Disabled container and content colors require separate assertions.
// Smooth and conventional shape modes require separate assertions.
// Arbitrary content must remain mounted and color-inherited.
// Custom corner radius must reach both paint and indication shape.
// Custom min dimensions must remain floors.
// Larger child content must not be clipped to default maxima.
// Custom insideMargin must affect complete measured size.
// showIndication false must leave click behavior available when enabled.
// enabled false must suppress both click and indication.
// Existing label goldens must remain unchanged.
// The localized example must retain its captured 420dpi geometry.
