/// Provider-agnostic user identity. Concrete repositories map their SDK's user
/// (Supabase today, Firebase if ever swapped) onto this.
class AuthUser {
  const AuthUser({required this.id, required this.email, this.displayName});

  final String id;
  final String email;
  final String? displayName;

  String get initial {
    final String source =
        (displayName != null && displayName!.isNotEmpty) ? displayName! : email;
    return source.isEmpty ? '?' : source.substring(0, 1).toUpperCase();
  }
}
