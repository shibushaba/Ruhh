import 'package:isar/isar.dart';

part 'user_local.g.dart';

@collection
class UserLocal {
  Id id = Isar.autoIncrement;

  @Index(unique: true, caseSensitive: false)
  late String username;

  late String pinHash;
  late String pinSalt;

  String? supabaseId;

  late DateTime createdAt;

  /// Tracker onboarding completed for this account.
  bool onboardingComplete = false;

  /// Optional budget module enabled for this account.
  bool budgetEnabled = false;
}
