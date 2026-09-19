import 'package:flutter/material.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/ruhh_components.dart';
import 'package:ruhh/core/widgets/ruhh_emoji_catalog.dart';

/// Top quick picks + “more” sheet with searchable full emoji catalog.
class RuhhEmojiPicker extends StatelessWidget {
  const RuhhEmojiPicker({
    super.key,
    required this.selected,
    required this.onSelected,
    this.inCard = true,
    this.accent,
  });

  final String selected;
  final ValueChanged<String> onSelected;
  final bool inCard;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final ring = accent ?? t.accentMint;
    final quick = ruhhEmojiQuickPicks(selected: selected);

    Widget row = Row(
      children: [
        for (final emoji in quick) ...[
          _EmojiChip(
            emoji: emoji,
            selected: selected == emoji,
            accent: ring,
            onTap: () => onSelected(emoji),
          ),
          const SizedBox(width: 6),
        ],
        _MoreEmojiChip(
          onTap: () async {
            final picked = await showRuhhEmojiPickerSheet(
              context,
              selected: selected,
            );
            if (picked != null) onSelected(picked);
          },
        ),
      ],
    );

    row = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: row,
    );

    if (inCard) {
      return RuhhSoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: row,
      );
    }
    return row;
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({
    required this.emoji,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusChip),
            color: selected
                ? accent.withValues(alpha: 0.35)
                : t.surfaceSecondary.withValues(alpha: 0.5),
            border: Border.all(
              color: selected ? accent : t.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(emoji, style: const TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}

class _MoreEmojiChip extends StatelessWidget {
  const _MoreEmojiChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(t.radiusChip),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(t.radiusChip),
            border: Border.all(color: t.divider, width: 1.5),
          ),
          child: Icon(Icons.more_horiz, color: t.textSecondary),
        ),
      ),
    );
  }
}

Future<String?> showRuhhEmojiPickerSheet(
  BuildContext context, {
  String? selected,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _EmojiPickerSheet(initial: selected),
  );
}

class _EmojiPickerSheet extends StatefulWidget {
  const _EmojiPickerSheet({this.initial});

  final String? initial;

  @override
  State<_EmojiPickerSheet> createState() => _EmojiPickerSheetState();
}

class _EmojiPickerSheetState extends State<_EmojiPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return kRuhhEmojiCatalog;
    return kRuhhEmojiCatalog.where((e) => e.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    final maxH = MediaQuery.sizeOf(context).height * 0.75;
    final emojis = _filtered;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: RuhhSoftCard(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: t.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose emoji',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: InputDecoration(
                  hintText: 'Search…',
                  prefixIcon: const Icon(Icons.search, size: 22),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: emojis.length,
                  itemBuilder: (context, i) {
                    final emoji = emojis[i];
                    final on = widget.initial == emoji;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pop(context, emoji),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on
                                ? t.accentMintPastel
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: on
                                ? Border.all(color: t.accentMint, width: 2)
                                : null,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
