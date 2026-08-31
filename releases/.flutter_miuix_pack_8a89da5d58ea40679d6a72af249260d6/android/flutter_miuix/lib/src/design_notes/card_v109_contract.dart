// MIUIX v1.0.9 Card parity contract.
//
// Authoritative component source:
// - miuix-ui/.../basic/Card.kt
//
// Authoritative sample source:
// - example/shared/.../component/CardSection.kt
//
// This file is documentation only. Keeping the complete source obligation in
// one place prevents a visually plausible card from being mistaken for the
// original component when its colors, semantics, or desktop states differ.
//
// ---------------------------------------------------------------------------
// Public overloads
// ---------------------------------------------------------------------------
//
// Card.kt exposes a passive and an interactive overload.
//
// The passive overload accepts:
// - modifier;
// - cornerRadius, default 16dp;
// - insideMargin, default PaddingValues(0dp);
// - CardColors;
// - ColumnScope content.
//
// It does not install click, long-click, press feedback, or indication nodes.
//
// The interactive overload additionally accepts:
// - PressFeedbackType, default None;
// - showIndication, default false;
// - nullable onClick;
// - nullable onLongPress.
//
// The interactive overload always installs combinedClickable. A missing click
// callback is replaced with EmptyClickAction rather than removing click
// handling. The Flutter card therefore selects its interactive path whenever
// a callback, indication, or non-None feedback type is supplied.
//
// MiuixCard.source mirrors the interactive source parameter names:
// content, cornerRadius, insideMargin, colors, pressFeedbackType,
// showIndication, onClick, and onLongPress.
//
// Existing Flutter aliases remain compatibility extensions:
// - child is the Widget form of Compose content;
// - padding aliases insideMargin;
// - margin represents an outer Compose padding modifier;
// - color overrides only the background channel;
// - glass opts into the package's non-source blur extension.
//
// Supplying padding and insideMargin together is rejected so two padding
// layers cannot silently change the source geometry.
//
// ---------------------------------------------------------------------------
// Defaults and colors
// ---------------------------------------------------------------------------
//
// CardDefaults.CornerRadius is exactly 16dp.
//
// CardDefaults.InsideMargin is exactly zero on every edge.
//
// CardDefaults.defaultColors resolves:
// - color from surfaceContainer;
// - contentColor from onSurfaceContainer.
//
// The two optional overrides are independent.
//
// CardColors is an immutable two-channel value object. Flutter exposes the
// same channels as MiuixCardColors and provides value equality plus copyWith
// without changing either channel implicitly.
//
// BasicCard publishes contentColor through LocalContentColor. The Flutter
// surface must therefore inherit the resolved content color through both
// DefaultTextStyle and IconTheme, even when the background is overridden.
//
// Ordinary cards paint the resolved background at full opacity. They have no
// Material outline, elevation, tint layer, minimum size, or default padding.
//
// ---------------------------------------------------------------------------
// Layout and modifier order
// ---------------------------------------------------------------------------
//
// BasicCard creates a Box with propagateMinConstraints=true.
//
// Its modifier order is:
// 1. caller modifier;
// 2. semantics with mergeDescendants=false and isTraversalGroup=true;
// 3. clip to miuixShape(cornerRadius);
// 4. paint the CardColors background.
//
// The passive overload puts a padded Column directly inside that Box.
//
// The interactive overload first places pressable on the caller modifier.
// BasicCard then applies semantics, clip, and background. Inside the Box, the
// Column applies combinedClickable before insideMargin padding. Consequently:
// - outer caller margin is outside paint and hit testing;
// - the complete colored card is the interactive region;
// - insideMargin does not shrink the clickable bounds;
// - press motion transforms the already clipped card;
// - tilted corners must not be clipped again by an untransformed ancestor.
//
// The global MIUIX smooth-rounding setting decides whether miuixShape uses the
// continuous G2 outline or a conventional rounded rectangle. Both branches
// retain the requested 16dp radius.
//
// ---------------------------------------------------------------------------
// Interaction source and press feedback
// ---------------------------------------------------------------------------
//
// The interactive overload remembers one MutableInteractionSource.
//
// None creates no outer press-feedback indication.
//
// Sink creates SinkFeedback with:
// - sinkAmount 0.94;
// - spring damping ratio 0.8;
// - spring stiffness 600.
//
// Tilt creates TiltFeedback with:
// - tiltAmount 8 degrees;
// - spring damping ratio 0.6;
// - spring stiffness 400;
// - cameraDistance 12 * density;
// - a transform origin at the corner opposite the pointer quadrant.
//
// Card passes delay=null to its outer pressable modifier, so sink and tilt
// receive the press immediately rather than waiting the usual 150ms.
//
// The same interaction source is shared with combinedClickable whenever a
// motion feedback object exists. This keeps motion, release, cancellation,
// click, and long-click on one pointer lifecycle.
//
// A long press must keep tilt or sink held after the tap recognizer yields to
// the long-press recognizer. Motion returns to rest only on release or actual
// gesture cancellation.
//
// ---------------------------------------------------------------------------
// Indication, desktop hover, and keyboard focus
// ---------------------------------------------------------------------------
//
// showIndication=false passes null instead of LocalIndication.
//
// showIndication=true uses MiuixIndication with the theme onBackground color.
//
// Its four states add rather than replace alpha:
// - hover adds 0.06;
// - keyboard focus adds 0.08;
// - pointer press adds 0.10;
// - HoldDownInteraction adds 0.10.
//
// Every target change uses a 120ms linear animation.
//
// When the target becomes zero, MiuixIndication waits for any active positive
// transition to finish before animating back to zero. A new positive target
// cancels the pending resting transition.
//
// combinedClickable is keyboard focusable. Enter and Space activate the click
// action, including EmptyClickAction for an indication-only card. Hover and
// focus remain independent, so a focused pointer-hovered card resolves 0.14
// before press contributes another 0.10.
//
// ---------------------------------------------------------------------------
// Accessibility
// ---------------------------------------------------------------------------
//
// BasicCard is a traversal group and does not merge its passive descendants.
//
// The interactive branch receives click/long-click semantics from
// combinedClickable. A source interactive card with no owner click callback
// still exposes the empty click action because EmptyClickAction is installed.
//
// The component does not invent a Material card role, tooltip, label, or
// disabled state. Descriptions continue to come from its content.
//
// ---------------------------------------------------------------------------
// Localized CardSection fixture
// ---------------------------------------------------------------------------
//
// The original item order is retained:
// 1. SmallTitle("Card");
// 2. one full-width primaryVariant card;
// 3. one row containing equal Sink and Tilt cards.
//
// The full-width card uses:
// - 12dp horizontal outer padding;
// - 12dp bottom outer padding;
// - 16dp inside margin;
// - PressFeedbackType.None;
// - showIndication=true;
// - 19sp SemiBold title;
// - 17sp Normal supporting line.
//
// The two feedback cards use:
// - equal Row weights;
// - a 12dp horizontal gap;
// - 16dp inside margin;
// - 18sp Medium title;
// - paragraph-style two-line supporting text;
// - Sink with onClick on the left;
// - Tilt with onLongPress on the right.
//
// Only user-visible strings are translated:
// - Card -> 卡片;
// - ShowIndication: true -> 显示触摸指示：是;
// - PressFeedback Type: Sink -> 按压反馈 / 类型：下沉;
// - PressFeedback Type: Tilt -> 按压反馈 / 类型：倾斜.
//
// Translation must not reorder controls or change the source font sizes,
// weights, line count, spacing, padding, colors, callbacks, or feedback modes.
//
// ---------------------------------------------------------------------------
// Same-device physical evidence
// ---------------------------------------------------------------------------
//
// At 1080 x 2400 and 420dpi:
// - the primaryVariant surface is 194 physical pixels high;
// - its bottom margin rounds independently to 32 physical pixels;
// - each feedback surface is 246 physical pixels high;
// - both feedback columns have equal width;
// - the independently rounded middle gap is 32 physical pixels.
//
// Existing paired source and Flutter captures cover static, Sink-held, and all
// four Tilt pointer quadrants under artifacts/parity/audit_2026-07-24 and the
// consolidated source/Flutter audit under artifacts/parity/audit_2026-07-27.
//
// Regression tests additionally cover:
// - default and overridden color channels;
// - value equality and copyWith;
// - source-named parameters;
// - custom radius and inside margin forwarding;
// - EmptyClickAction selection;
// - exact Sink and Tilt spring constants;
// - press/release motion;
// - long-press retention;
// - indication-only behavior;
// - additive hover, focus, and press alpha;
// - Enter activation;
// - all six existing Card visual baselines.
