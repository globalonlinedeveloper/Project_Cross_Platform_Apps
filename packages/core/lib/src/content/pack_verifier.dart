/// The pinned Ed25519 public key (base64 of the raw 32-byte key) used to verify
/// every remote content pack's signature. SINGLE SOURCE OF TRUTH — the app-layer
/// [PackVerifier] impl reads it from here (ADR 007).
///
/// PLACEHOLDER until the owner generates the pack-signing keypair (OWNER_QUEUE
/// S-3): the private key goes to `.claude/` (never git), the public key is pinned
/// here. While this is empty a correct [PackVerifier] MUST reject remote packs
/// (only the trusted bundled base loads), so no unsigned CDN content is ever
/// accepted. Losing the private key = no pack can ever be updated again — back it
/// up with a restore drill before the first signed pack ships.
const String kContentPackPublicKeyBase64 = '';

/// Whether a real pack-signing key has been pinned yet. False until S-3 lands.
bool get isContentPackKeyConfigured => kContentPackPublicKeyBase64.isNotEmpty;

/// Seam for Ed25519 signature verification of a content pack manifest. The
/// concrete impl (e.g. `package:cryptography` or `package:ed25519_edwards`) is
/// injected from the app layer so `core` stays pure Dart (ADR 007).
abstract interface class PackVerifier {
  /// Whether [signature] is a valid Ed25519 signature over [message] for the
  /// pinned [kContentPackPublicKeyBase64]. MUST return false (never throw) when
  /// the key is unconfigured or the signature/inputs are malformed.
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
  });
}

/// A [PackVerifier] that rejects everything — the safe default before a real
/// Ed25519 impl + pinned key exist (OWNER_QUEUE S-3). With this verifier only a
/// trusted bundled base pack loads; every remote pack is refused.
class RejectingPackVerifier implements PackVerifier {
  const RejectingPackVerifier();

  @override
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
  }) async =>
      false;
}
