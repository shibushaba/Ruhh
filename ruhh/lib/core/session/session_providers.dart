import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:ruhh/core/data/isar_service.dart';
import 'package:ruhh/core/data/models/user_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ruhhSessionUsernameKey = 'ruhh_session_username';

final sessionUsernameProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(ruhhSessionUsernameKey);
});

final isarProvider = FutureProvider<Isar>((ref) => IsarService.open());

/// Resolves logged-in user from session prefs, with Isar fallbacks for overlay isolate.
Future<UserLocal?> resolveCurrentUser(Isar isar) async {
  final prefs = await SharedPreferences.getInstance();
  final username = prefs.getString(ruhhSessionUsernameKey);
  if (username != null && username.isNotEmpty) {
    final match =
        await isar.userLocals.filter().usernameEqualTo(username).findFirst();
    if (match != null) return match;
    // Session points at a missing user — do not fall back to another account.
    return null;
  }

  final all = await isar.userLocals.where().findAll();
  if (all.length == 1) return all.first;
  if (all.isEmpty) return null;

  all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return all.first;
}

final currentUserProvider = FutureProvider<UserLocal?>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  return resolveCurrentUser(isar);
});

final activeUserIdProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No logged-in user');
  return user.supabaseId ?? user.id.toString();
});
