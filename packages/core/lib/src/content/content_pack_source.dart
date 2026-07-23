/// Byte source for a content pack's entries (ADR 007). Concrete impls live in
/// the app layer — a bundled-assets source (`rootBundle`) and a remote source
/// (dio → `packs.nikatru.com` / R2) — so `core` stays pure Dart.
abstract interface class ContentPackSource {
  /// The raw bytes of a named pack [entry] (e.g. `manifest.json`,
  /// `manifest.sig`, `content.json`, `assets/hero.png`), or null when absent.
  Future<List<int>?> read(String entry);
}

/// An in-memory [ContentPackSource] backed by a map of `entry -> bytes`. For
/// tests and simple fixtures.
class InMemoryContentPackSource implements ContentPackSource {
  const InMemoryContentPackSource(this._entries);

  final Map<String, List<int>> _entries;

  @override
  Future<List<int>?> read(String entry) async => _entries[entry];
}
