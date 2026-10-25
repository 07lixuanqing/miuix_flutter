# Application icon artwork

`MiuixIconTheme(resolve: ..., child: ...)` optionally maps semantic `IconData`
to app artwork. Font icons rendered by MIUIX controls use `MiuixThemedIcon`.
The default resolver is identity, preserving MIUIX glyphs and existing API.
Scopes are inherited themes, so captured popup/dialog routes retain the artwork.
Applications can also use `MiuixThemedIcon` for their own controls. Size, tint,
semantics, direction, variable font properties and text scaling are preserved.
This hook affects font icons, not third-party logos, user media, system-owned
notification controls, or custom-painted control geometry (checkbox strokes etc.).
