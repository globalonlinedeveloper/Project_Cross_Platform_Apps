import 'auth_models.dart';

/// The auth seam. Swapping identity providers = writing one more implementation
/// of this interface; nothing above the data layer changes.
abstract class AuthRepository {
  /// Synchronous snapshot (used by the router's redirect guard).
  AuthUser? get currentUser;

  /// Emits on sign-in / sign-out / token refresh.
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
  });

  /// OAuth (Apple/Google). Completes via redirect/deep link — the resulting
  /// session arrives on [authStateChanges].
  Future<void> signInWithApple();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  /// The bearer token attached to every API call (the Supabase JWT the Worker
  /// verifies). Null when signed out.
  Future<String?> currentAccessToken();
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => 'AuthFailure: $message';
}
