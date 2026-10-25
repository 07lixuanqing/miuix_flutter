# Text field autofill

`MiuixTextField` and `MiuixTextField.source` accept the optional `autofillHints` parameter and forward it to the underlying `EditableText`. The default is null, preserving existing behavior and layout.

Group related credentials in Flutter's `AutofillGroup`. Use `AutofillHints.username` or `email` for the account field, `password` for sign-in, and `newPassword` for registration or a replacement password. Password masking is controlled separately by `obscureText`.

The application owns the credential lifecycle: call `TextInput.finishAutofillContext(shouldSave: true)` only after authentication succeeds. Configure cancellation when abandoning a form. A hint does not store credentials itself or guarantee that a device's password manager displays a save prompt.

`test/input_autofill_test.dart` covers both constructors and password masking. This addition does not change the component's visual geometry.
