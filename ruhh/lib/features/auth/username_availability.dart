/// Result of a live username availability check (local + Supabase).
enum UsernameAvailability {
  tooShort,
  checking,
  available,
  taken,
  offlineAvailable,
  checkFailed,
}
