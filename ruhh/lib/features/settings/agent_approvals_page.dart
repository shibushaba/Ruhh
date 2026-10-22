import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ruhh/core/services/cloud_auth_client.dart';
import 'package:ruhh/core/services/ruhh_file_backup_service.dart';
import 'package:ruhh/core/services/supabase_service.dart';
import 'package:ruhh/core/theme/ruhh_tokens.dart';
import 'package:ruhh/core/widgets/nb_button.dart';
import 'package:ruhh/core/widgets/nb_card.dart';
import 'package:ruhh/core/widgets/nb_layout.dart';
import 'package:ruhh/core/widgets/nb_scaffold.dart';

/// User-only approval of agent proposals (edits/deletes requested via Telegram).
/// Uses the phone's own cloud session; the agent can never approve by itself.
class AgentApprovalsPage extends ConsumerStatefulWidget {
  const AgentApprovalsPage({super.key});

  @override
  ConsumerState<AgentApprovalsPage> createState() => _AgentApprovalsPageState();
}

class _AgentApprovalsPageState extends ConsumerState<AgentApprovalsPage> {
  Future<List<AgentProposal>>? _future;
  String? _userId;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = () async {
        final user = await currentUserLocal(ref);
        final id = user?.supabaseId;
        if (id == null || id.isEmpty) return const <AgentProposal>[];
        _userId = id;
        return SupabaseService.auth.listProposals(id);
      }();
    });
  }

  static String _message(ProposalDecisionResult r) => switch (r) {
    ProposalDecisionResult.executed => 'Approved. It applies on the next sync.',
    ProposalDecisionResult.rejected => 'Rejected. Nothing was changed.',
    ProposalDecisionResult.expired => 'This request expired. Nothing changed.',
    ProposalDecisionResult.alreadyDecided =>
      'This request was already handled.',
    ProposalDecisionResult.changed =>
      'This request changed after it was shown. Nothing changed.',
    ProposalDecisionResult.conflict =>
      'The item was edited since the request. Nothing changed.',
    ProposalDecisionResult.targetMissing => 'The item no longer exists.',
    ProposalDecisionResult.notFound => 'Request not found.',
    ProposalDecisionResult.sessionRequired =>
      'Sign out and sign in again with your PIN to approve requests.',
    ProposalDecisionResult.failed =>
      'Could not reach the cloud. Try again shortly.',
  };

  Future<void> _decide(AgentProposal p, bool approve) async {
    final uid = _userId;
    if (uid == null) return;
    if (approve) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Approve this change?'),
          content: Text(p.summary),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _busy.add(p.id));
    final r = await SupabaseService.auth.decideProposal(
      uid,
      p,
      approve: approve,
    );
    if (!mounted) return;
    _busy.remove(p.id);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(_message(r))));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ruhh;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: ruhhAppBar(context, title: 'Agent approvals'),
      body: NBPageBody(
        child: FutureBuilder<List<AgentProposal>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final e = snap.error;
              return Center(
                child: Text(
                  e is CloudSyncAuthException
                      ? e.message
                      : 'Could not load requests. Try again shortly.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            final items = snap.data ?? const <AgentProposal>[];
            if (items.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView(
                  children: const [
                    SizedBox(height: 48),
                    Center(child: Text('No pending requests.')),
                  ],
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: NBLayout.sectionGap),
                itemBuilder: (context, i) {
                  final p = items[i];
                  final busy = _busy.contains(p.id);
                  return NBCard(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          p.summary,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: t.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          describeTarget(p),
                          style: t.caption(Theme.of(context).textTheme),
                        ),
                        if (p.expiresAt != null)
                          Text(
                            'Expires ${DateFormat.Hm().format(p.expiresAt!.toLocal())}',
                            style: t.caption(Theme.of(context).textTheme),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NBButton(
                                label: 'Reject',
                                primary: false,
                                onPressed: busy
                                    ? null
                                    : () => _decide(p, false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NBButton(
                                label: 'Approve',
                                onPressed: busy ? null : () => _decide(p, true),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Human-readable description of what a proposal touches (pure, unit-tested).
String describeTarget(AgentProposal p) {
  final t = p.target;
  if (t == null) return 'The item no longer exists in the cloud backup.';
  if (t['kind'] == 'transaction') {
    final amount = t['amount'];
    final title = (t['title'] as String?)?.isNotEmpty == true
        ? t['title']
        : t['category'];
    final when = DateTime.tryParse(t['occurred_at'] as String? ?? '');
    final date = when == null
        ? ''
        : ' on ${DateFormat.yMMMd().format(when.toLocal())}';
    final sign = t['is_income'] == true ? '+' : '-';
    return 'Transaction: $title, $sign$amount$date';
  }
  if (t['kind'] == 'movie') return 'Movie: ${t['title']}';
  return p.action;
}
