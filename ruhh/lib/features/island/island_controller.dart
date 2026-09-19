import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruhh/core/session/session_providers.dart';

class IslandState {
  const IslandState({
    required this.owned,
    required this.spent,
    required this.name,
  });

  final List<String> owned;
  final int spent;
  final String name;

  IslandState copyWith({List<String>? owned, int? spent, String? name}) =>
      IslandState(
        owned: owned ?? this.owned,
        spent: spent ?? this.spent,
        name: name ?? this.name,
      );
}

class IslandNotifier extends StateNotifier<IslandState> {
  IslandNotifier(this._userKey) : super(const IslandState(owned: [], spent: 0, name: 'My island')) {
    _load();
  }

  final String _userKey;

  String get _ownedKey => 'island_owned_$_userKey';
  String get _spentKey => 'island_spent_$_userKey';
  String get _nameKey => 'island_name_$_userKey';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = IslandState(
      owned: p.getStringList(_ownedKey) ?? [],
      spent: p.getInt(_spentKey) ?? 0,
      name: p.getString(_nameKey) ?? 'My island',
    );
  }

  Future<void> setName(String name) async {
    state = state.copyWith(name: name);
    await (await SharedPreferences.getInstance()).setString(_nameKey, name);
  }

  Future<bool> buy(String pieceId, int price, int balance) async {
    if (state.owned.contains(pieceId) || balance < price) return false;
    final owned = [...state.owned, pieceId];
    final spent = state.spent + price;
    state = state.copyWith(owned: owned, spent: spent);
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_ownedKey, owned);
    await p.setInt(_spentKey, spent);
    return true;
  }

  int balance(int earned) => (earned - state.spent).clamp(0, 1 << 30);
}

final islandProvider =
    StateNotifierProvider<IslandNotifier, IslandState>((ref) {
  final id = ref.watch(activeUserIdProvider).valueOrNull ?? 'guest';
  return IslandNotifier(id);
});
