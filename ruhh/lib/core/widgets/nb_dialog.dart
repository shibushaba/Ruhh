import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/nb_colors.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_glass.dart';

/// Closes the modal opened by [showNBFormDialog] / [showNBStatefulFormDialog].
/// Use the [BuildContext] from the dialog `actions` callback — not the page.
void popNBDialog(BuildContext dialogContext) {
  Navigator.of(dialogContext).pop();
}

class NBDialogAction {
  const NBDialogAction({
    required this.label,
    required this.onPressed,
    this.destructive = false,
    this.primary = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool destructive;
  final bool primary;
}

const _kDialogInset = EdgeInsets.symmetric(horizontal: 20, vertical: 40);
const _kDialogPadding = EdgeInsets.fromLTRB(20, 20, 20, 20);

class _NBDialogActionsBar extends StatelessWidget {
  const _NBDialogActionsBar({required this.actions});

  final List<NBDialogAction> actions;

  @override
  Widget build(BuildContext context) {
    final primary = actions.where((a) => a.primary).toList();
    final secondary = actions.where((a) => !a.primary).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < secondary.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          TextButton(
            onPressed: secondary[i].onPressed,
            child: Text(
              secondary[i].label,
              style: TextStyle(
                color: secondary[i].destructive
                    ? Colors.red.shade700
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final a in primary)
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 96),
                    child: NBButton(
                      label: a.label,
                      expand: false,
                      color: a.destructive ? Colors.red.shade700 : NBColors.budget,
                      onPressed: a.onPressed,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class NBFormDialogPanel extends StatelessWidget {
  const NBFormDialogPanel({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.scrollable = false,
  });

  final String title;
  final Widget content;
  final List<NBDialogAction> actions;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxDialogH = MediaQuery.sizeOf(context).height * 0.86;
    final maxScrollH = MediaQuery.sizeOf(context).height * 0.48;

    return Dialog(
      alignment: Alignment.center,
      backgroundColor: Colors.transparent,
      insetPadding: _kDialogInset,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxDialogH,
        ),
        child: NBGlassPanel(
          elevated: true,
          padding: _kDialogPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              if (scrollable)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxScrollH),
                  child: SingleChildScrollView(
                    child: content,
                  ),
                )
              else
                content,
              const SizedBox(height: 20),
              Divider(
                height: 1,
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 16),
              _NBDialogActionsBar(actions: actions),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form-style modal with labels above fields (vector panel, full width).
Future<void> showNBFormDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<NBDialogAction> Function(BuildContext dialogContext) actions,
  bool scrollable = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) => NBFormDialogPanel(
      title: title,
      content: content,
      actions: actions(dialogContext),
      scrollable: scrollable,
    ),
  );
}

/// Stateful form dialog — use for dropdowns, toggles, and segmented controls.
Future<void> showNBStatefulFormDialog({
  required BuildContext context,
  required String title,
  required Widget Function(BuildContext context, StateSetter setState) content,
  required List<NBDialogAction> Function(
    BuildContext context,
    StateSetter setState,
  ) actions,
  bool scrollable = false,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (statefulContext, setState) {
          return NBFormDialogPanel(
            title: title,
            scrollable: scrollable,
            content: content(statefulContext, setState),
            actions: actions(dialogContext, setState),
          );
        },
      );
    },
  );
}

/// Confirmation alert with the same shell as form dialogs.
Future<bool?> showNBConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'OK',
  String cancelLabel = 'Cancel',
  bool destructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      return NBFormDialogPanel(
        title: title,
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyLarge,
        ),
        actions: [
          NBDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          NBDialogAction(
            label: confirmLabel,
            primary: !destructive,
            destructive: destructive,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      );
    },
  );
}
