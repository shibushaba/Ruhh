import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruhh/core/session/session_providers.dart';
import 'package:ruhh/features/v14/data/v14_isar_store.dart';
import 'package:ruhh/features/v14/data/v14_models.dart';
import 'package:ruhh/features/v14/data/v14_store.dart';

final v14StoreProvider = FutureProvider<V14Store>((ref) async {
  final isar = await ref.watch(isarProvider.future);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) {
    throw StateError('No user');
  }
  return IsarV14Store(isar, user.supabaseId ?? user.id.toString());
});

final v14ProfileProvider = FutureProvider<V14ProfileData>((ref) async {
  final store = await ref.watch(v14StoreProvider.future);
  return store.loadProfile();
});

/// In-memory try. Nothing is written. Cleared when the timer ends.
final tryPetProvider = StateProvider<String?>((ref) => null);
