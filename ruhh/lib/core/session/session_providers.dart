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

final currentUserProvider = FutureProvider<UserLocal?>((ref) async {
  final username = await ref.watch(sessionUsernameProvider.future);
  if (username == null) return null;
  final isar = await ref.watch(isarProvider.future);
  return isar.userLocals.filter().usernameEqualTo(username).findFirst();
});

final activeUserIdProvider = FutureProvider<String>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) throw StateError('No logged-in user');
  return user.supabaseId ?? user.id.toString();
});
