part of '../miuix_widgets.dart';

/// Compact status chip used by HyperOS-like lists and dashboards.
class MiuixChip extends StatelessWidget {
  /// Creates a chip.
  const MiuixChip({super.key, required this.label, this.icon, this.onDeleted});

  /// Chip label.
  final String label;

  /// Optional icon.
  final Widget? icon;

  /// Optional delete callback.
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: .88),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: .42),
          width: .5,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32, maxWidth: 220),
        child: Padding(
          padding: EdgeInsetsDirectional.only(
            start: icon == null ? 12 : 8,
            end: onDeleted == null ? 12 : 6,
            top: 6,
            bottom: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: scheme.onSecondaryContainer,
                    size: 18,
                  ),
                  child: icon!,
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 6),
                MiuixPressable(
                  onTap: onDeleted,
                  borderRadius: BorderRadius.circular(999),
                  feedbackType: MiuixPressFeedbackType.none,
                  showIndication: true,
                  child: SizedBox.square(
                    dimension: 20,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: scheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Avatar widget for MIUI account and contact screens.
class MiuixAvatar extends StatelessWidget {
  /// Creates an avatar.
  const MiuixAvatar({super.key, this.image, this.initials, this.size = 48});

  /// Optional image provider.
  final ImageProvider? image;

  /// Optional initials.
  final String? initials;

  /// Avatar diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: ClipOval(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: .14),
              width: .5,
            ),
          ),
          child: image == null
              ? Center(
                  child: initials == null
                      ? null
                      : Text(
                          initials!,
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: scheme.primary,
                                fontSize: size * .3,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                )
              : Image(image: image!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// Control center tile inspired by MIUI quick settings.
class MiuixControlCenterTile extends StatelessWidget {
  /// Creates a control center tile.
  const MiuixControlCenterTile({
    super.key,
    required this.icon,
    required this.label,
    this.value,
    this.onTap,
    this.enabled = true,
  });

  /// Tile icon.
  final Widget icon;

  /// Tile label.
  final String label;

  /// Optional value text.
  final String? value;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Whether the tile is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final activeColor = enabled ? scheme.primary : scheme.onSurfaceVariant;
    return MiuixSurface(
      onTap: enabled ? onTap : null,
      radius: 20,
      color: enabled
          ? scheme.surfaceContainerLow.withValues(alpha: .97)
          : scheme.surfaceContainerHigh.withValues(alpha: .8),
      border: BorderSide(
        color: enabled
            ? scheme.outlineVariant.withValues(alpha: .06)
            : scheme.outlineVariant.withValues(alpha: .12),
        width: .5,
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.md - 2,
        tokens.spacing.sm,
        tokens.spacing.md - 2,
        tokens.spacing.xs + 1,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: enabled
                    ? scheme.primary.withValues(alpha: .072)
                    : scheme.surfaceContainerHigh.withValues(alpha: .68),
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconTheme(
                data: IconThemeData(color: activeColor, size: 12),
                child: icon,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
                height: 1.0,
              ),
            ),
            if (value != null) ...[
              const SizedBox(height: 2),
              Text(
                value!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? scheme.onSurfaceVariant
                      : scheme.onSurfaceVariant.withValues(alpha: .72),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Control center tile with an embedded slider.
///
/// This covers common HyperOS controls such as brightness, volume, and media
/// intensity where the tile itself is both a status surface and a value editor.
class MiuixControlSliderTile extends StatelessWidget {
  /// Creates a control slider tile.
  const MiuixControlSliderTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
  });

  /// Tile icon.
  final Widget icon;

  /// Tile label.
  final String label;

  /// Current slider value.
  final double value;

  /// Change callback.
  final ValueChanged<double> onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = MiuixTheme.of(context);
    final range = _safeRange(min, max);
    final safeValue = _finiteOr(value, range.min).clamp(range.min, range.max);
    final denominator = range.max - range.min;
    final scheme = theme.colorScheme;
    final percent = denominator == 0
        ? 0
        : (((safeValue - range.min) / denominator) * 100).round();
    return MiuixSurface(
      radius: 18,
      color: Color.alphaBlend(
        scheme.primary.withValues(alpha: .045),
        scheme.surfaceContainerLow.withValues(alpha: .98),
      ),
      border: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: .045),
        width: .5,
      ),
      padding: EdgeInsets.fromLTRB(
        tokens.spacing.xs + 6,
        tokens.spacing.xs - 1,
        tokens.spacing.xs + 6,
        tokens.spacing.xs - 3,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: .06),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: IconTheme(
                    data: IconThemeData(size: 9.5, color: scheme.primary),
                    child: icon,
                  ),
                ),
                SizedBox(width: tokens.spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -.15,
                    ),
                  ),
                ),
                SizedBox(
                  width: 20,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$percent%',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 6.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 0),
            MiuixSlider(
              value: safeValue,
              min: range.min,
              max: range.max,
              height: 7.5,
              trackScale: .64,
              thumbScale: .7,
              onChanged: denominator == 0
                  ? null
                  : (next) {
                      final safeNext = _normalizeSliderCallbackValue(
                        next,
                        range,
                      );
                      if ((safeNext - safeValue).abs() > 0.0005) {
                        onChanged(safeNext);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

/// Account header surface for MIUI account and settings pages.
class MiuixAccountHeader extends StatelessWidget {
  /// Creates an account header.
  const MiuixAccountHeader({
    super.key,
    required this.name,
    this.subtitle,
    this.avatar,
    this.trailing,
    this.onTap,
  });

  /// Account display name.
  final String name;

  /// Optional account subtitle.
  final String? subtitle;

  /// Optional avatar.
  final Widget? avatar;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      onTap: onTap,
      child: Row(
        children: [
          avatar ?? const MiuixAvatar(initials: 'Mi', size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Device status card used by connected-device and ecosystem screens.
class MiuixDeviceCard extends StatelessWidget {
  /// Creates a device card.
  const MiuixDeviceCard({
    super.key,
    required this.name,
    required this.status,
    this.icon = const Icon(Icons.devices),
    this.battery,
    this.onTap,
  });

  /// Device name.
  final String name;

  /// Device status text.
  final String status;

  /// Device icon.
  final Widget icon;

  /// Optional battery percentage.
  final int? battery;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .07),
              borderRadius: BorderRadius.circular(11),
            ),
            child: IconTheme(
              data: IconThemeData(color: scheme.primary, size: 17),
              child: icon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          if (battery != null)
            Text(
              '$battery%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

/// Application row for package installers, app managers, and security tools.
class MiuixAppListTile extends StatelessWidget {
  /// Creates an app list tile.
  const MiuixAppListTile({
    super.key,
    required this.name,
    this.packageName,
    this.icon,
    this.trailing,
    this.onTap,
  });

  /// App display name.
  final String name;

  /// Optional package identifier.
  final String? packageName;

  /// Optional app icon.
  final Widget? icon;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: MiuixPreference(
        title: name,
        summary: packageName,
        leading: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: .07),
            borderRadius: BorderRadius.circular(9),
          ),
          child: IconTheme(
            data: IconThemeData(color: scheme.primary, size: 15),
            child: icon ?? const Icon(Icons.apps),
          ),
        ),
        trailing: trailing,
        onTap: null,
      ),
    );
  }
}

/// Notification-style card with app identity, title, body, and actions.
class MiuixNotificationCard extends StatelessWidget {
  /// Creates a notification card.
  const MiuixNotificationCard({
    super.key,
    required this.title,
    required this.body,
    this.appName,
    this.icon,
    this.actions = const [],
  });

  /// Notification title.
  final String title;

  /// Notification body.
  final String body;

  /// Optional app name.
  final String? appName;

  /// Optional app icon.
  final Widget? icon;

  /// Optional action buttons.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: IconTheme(
                  data: IconThemeData(color: scheme.primary, size: 15),
                  child: icon ?? const Icon(Icons.notifications),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  appName ?? title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.xs + 1),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          if (actions.isNotEmpty) ...[
            SizedBox(height: theme.spacing.sm + 1),
            Wrap(spacing: theme.spacing.sm, children: actions),
          ],
        ],
      ),
    );
  }
}

/// Permission prompt card for privacy and security workflows.
class MiuixPermissionCard extends StatelessWidget {
  /// Creates a permission card.
  const MiuixPermissionCard({
    super.key,
    required this.permission,
    required this.description,
    required this.onAllow,
    required this.onDeny,
    this.icon = const Icon(Icons.privacy_tip),
  });

  /// Permission name.
  final String permission;

  /// Explanation shown to the user.
  final String description;

  /// Allow callback.
  final VoidCallback onAllow;

  /// Deny callback.
  final VoidCallback onDeny;

  /// Prompt icon.
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.error.withValues(alpha: .07),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: IconTheme(
                  data: IconThemeData(color: scheme.error, size: 15),
                  child: icon,
                ),
              ),
              const SizedBox(width: 9),
              Text(
                permission,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: theme.spacing.xs + 1),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          SizedBox(height: theme.spacing.sm + 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              MiuixButton(label: 'Deny', filled: false, onPressed: onDeny),
              SizedBox(width: theme.spacing.sm),
              MiuixButton(label: 'Allow', filled: true, onPressed: onAllow),
            ],
          ),
        ],
      ),
    );
  }
}

/// Update card for system updater and app updater surfaces.
class MiuixUpdateCard extends StatelessWidget {
  /// Creates an update card.
  const MiuixUpdateCard({
    super.key,
    required this.version,
    required this.summary,
    this.progress,
    this.onUpdate,
  });

  /// Version label.
  final String version;

  /// Update summary.
  final String summary;

  /// Optional download or install progress.
  final double? progress;

  /// Optional update callback.
  final VoidCallback? onUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return MiuixCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            version,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs + 1),
          Text(
            summary,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.2,
            ),
          ),
          if (progress != null) ...[
            SizedBox(height: theme.spacing.sm + 1),
            MiuixProgressIndicator(value: progress),
          ],
          if (onUpdate != null) ...[
            SizedBox(height: theme.spacing.sm + 1),
            MiuixButton(label: 'Update', filled: true, onPressed: onUpdate),
          ],
        ],
      ),
    );
  }
}

/// Inline alert banner for warnings, tips, and status messages.
class MiuixInlineAlert extends StatelessWidget {
  /// Creates an inline alert.
  const MiuixInlineAlert({
    super.key,
    required this.message,
    this.icon = const Icon(Icons.info),
    this.severity = MiuixAlertSeverity.info,
  });

  /// Alert message.
  final String message;

  /// Alert icon.
  final Widget icon;

  /// Alert severity.
  final MiuixAlertSeverity severity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (severity) {
      MiuixAlertSeverity.info => scheme.primary.withValues(alpha: .08),
      MiuixAlertSeverity.warning => Colors.amber.shade100,
      MiuixAlertSeverity.error => scheme.error.withValues(alpha: .10),
      MiuixAlertSeverity.success => Colors.green.shade100,
    };
    return MiuixSurface(
      color: color,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: BorderSide(
        color: switch (severity) {
          MiuixAlertSeverity.info => scheme.primary.withValues(alpha: .14),
          MiuixAlertSeverity.warning => Colors.amber.shade300.withValues(
            alpha: .28,
          ),
          MiuixAlertSeverity.error => scheme.error.withValues(alpha: .18),
          MiuixAlertSeverity.success => Colors.green.shade300.withValues(
            alpha: .24,
          ),
        },
        width: .5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTheme(
            data: IconThemeData(
              color: switch (severity) {
                MiuixAlertSeverity.info => scheme.primary,
                MiuixAlertSeverity.warning => Colors.amber.shade800,
                MiuixAlertSeverity.error => scheme.error,
                MiuixAlertSeverity.success => Colors.green.shade700,
              },
              size: 18,
            ),
            child: icon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
                fontSize: 13,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alert severity values.
enum MiuixAlertSeverity {
  /// Informational state.
  info,

  /// Warning state.
  warning,

  /// Error state.
  error,

  /// Success state.
  success,
}

/// Promotional or instructional banner.
class MiuixBanner extends StatelessWidget {
  /// Creates a banner.
  const MiuixBanner({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });

  /// Banner title.
  final String title;

  /// Banner message.
  final String message;

  /// Optional action.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    return MiuixSurface(
      color: Theme.of(context).colorScheme.surface,
      radius: 20,
      border: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: .18),
        width: .5,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: theme.spacing.xs + 2),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          if (action != null) ...[
            SizedBox(height: theme.spacing.sm + 2),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Empty state component for lists and dashboards.
class MiuixEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const MiuixEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = const Icon(Icons.inbox, size: 56),
    this.action,
  });

  /// Empty state title.
  final String title;

  /// Optional message.
  final String? message;

  /// Empty state icon.
  final Widget icon;

  /// Optional action.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = MiuixTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTheme(
              data: IconThemeData(
                color: scheme.onSurfaceVariant.withValues(alpha: .92),
                size: 52,
              ),
              child: icon,
            ),
            SizedBox(height: theme.spacing.sm + 2),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (message != null) ...[
              SizedBox(height: theme.spacing.xs + 2),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
            if (action != null) ...[
              SizedBox(height: theme.spacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Expandable card for dense settings or information sections.
class MiuixExpandableCard extends StatefulWidget {
  /// Creates an expandable card.
  const MiuixExpandableCard({
    super.key,
    required this.title,
    required this.children,
    this.leading,
    this.initiallyExpanded = false,
  });

  /// Card title.
  final String title;

  /// Optional leading widget.
  final Widget? leading;

  /// Child widgets shown when expanded.
  final List<Widget> children;

  /// Whether the card starts expanded.
  final bool initiallyExpanded;

  @override
  State<MiuixExpandableCard> createState() => _MiuixExpandableCardState();
}

class _MiuixExpandableCardState extends State<MiuixExpandableCard> {
  late bool _expanded;

  bool get _hasChildren => widget.children.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded && _hasChildren;
  }

  @override
  void didUpdateWidget(covariant MiuixExpandableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_hasChildren) {
      _expanded = false;
    } else if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MiuixSurface(
      padding: EdgeInsets.zero,
      color: scheme.surface,
      border: BorderSide(
        color: scheme.outlineVariant.withValues(alpha: .18),
        width: .5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiuixPressable(
            onTap: _hasChildren
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(16),
            feedbackType: MiuixPressFeedbackType.none,
            showIndication: _hasChildren,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    IconTheme(
                      data: IconThemeData(color: scheme.onSurface, size: 18),
                      child: widget.leading!,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_hasChildren)
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: scheme.onSurfaceVariant,
                      size: 18,
                    ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: widget.children,
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// Page indicator for carousels and onboarding flows.
class MiuixPageIndicator extends StatelessWidget {
  /// Creates a page indicator.
  const MiuixPageIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  /// Number of pages.
  final int count;

  /// Active page index.
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final safeCount = count < 0 ? 0 : count;
    final safeIndex = safeCount == 0 ? -1 : index.clamp(0, safeCount - 1);
    if (safeCount == 0) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < safeCount; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: i == safeIndex ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: i == safeIndex
                  ? scheme.primary.withValues(alpha: .92)
                  : scheme.outlineVariant.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
      ],
    );
  }
}

/// Stepper row for setup flows and update/install progress.
class MiuixStepperRow extends StatelessWidget {
  /// Creates a stepper row.
  const MiuixStepperRow({
    super.key,
    required this.index,
    required this.title,
    this.subtitle,
    this.completed = false,
  });

  /// Step index.
  final int index;

  /// Step title.
  final String title;

  /// Optional subtitle.
  final String? subtitle;

  /// Whether the step is complete.
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: completed ? scheme.primary : scheme.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: completed
                      ? Icon(Icons.check, color: scheme.onPrimary, size: 18)
                      : Text(
                          '$index',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.onSecondaryContainer),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog helper.
class MiuixLoadingDialog {
  /// Shows an indeterminate loading dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    String message = 'Loading...',
  }) {
    return MiuixDialog.show<T>(
      context: context,
      title: message,
      content: const Center(child: MiuixInfiniteProgressIndicator()),
      barrierDismissible: false,
    );
  }
}

/// Toast and snackbar helper.
class MiuixToast {
  /// Shows a snackbar-like toast.
  static void show(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    MiuixSnackbar.show(context, message);
  }
}
