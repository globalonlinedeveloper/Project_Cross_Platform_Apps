import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nikatru_core/nikatru_core.dart';
import 'package:test/test.dart';

/// A [PackVerifier] whose result is fixed — stands in for the app-layer Ed25519
/// impl so the loader's verify→hash→fallback logic is testable without a key.
class _FakeVerifier implements PackVerifier {
  const _FakeVerifier(this.result);
  final bool result;
  @override
  Future<bool> verify({
    required List<int> message,
    required List<int> signature,
  }) async =>
      result;
}

List<int> _b(String s) => utf8.encode(s);
String _sha(List<int> bytes) => sha256.convert(bytes).toString();

/// A well-formed pack source with a matching content hash. [tamperContent]
/// corrupts content.json AFTER the manifest hash is computed (hash mismatch);
/// omit [sig] to drop the signature entry.
InMemoryContentPackSource _pack({
  bool tamperContent = false,
  bool includeSig = true,
}) {
  final List<int> content = _b('{"en":{"hello":"Hi"},"fr":{"hello":"Salut"}}');
  final List<int> manifest = _b(jsonEncode(<String, Object?>{
    'pack_id': 'lingo',
    'version': '1.2.0',
    'content_hash': _sha(content),
    'locales': <String>['en', 'fr'],
    'generators': <String>['gemini-x'],
  }));
  return InMemoryContentPackSource(<String, List<int>>{
    'manifest.json': manifest,
    'content.json': tamperContent ? _b('{"en":{"hello":"HACKED"}}') : content,
    if (includeSig) 'manifest.sig': _b('signature-bytes'),
  });
}

/// A signed source whose manifest declares NO content_hash — used to prove the
/// remote path fails closed rather than accepting unverified content.
InMemoryContentPackSource _hashlessPack() {
  final List<int> content = _b('{"en":{"hello":"Hi"}}');
  final List<int> manifest = _b(jsonEncode(<String, Object?>{
    'pack_id': 'lingo',
    'version': '1.0.0', // no content_hash
  }));
  return InMemoryContentPackSource(<String, List<int>>{
    'manifest.json': manifest,
    'content.json': content,
    'manifest.sig': _b('signature-bytes'),
  });
}

void main() {
  group('ContentPackManifest JSON', () {
    test('parses and round-trips', () {
      const ContentPackManifest m = ContentPackManifest(
        packId: 'lingo',
        version: '1.2.0',
        contentHash: 'abc',
        assets: <ContentAsset>[ContentAsset(path: 'a.png', sha256: 'deadbeef')],
        generators: <String>['gemini-x'],
        locales: <String>['en'],
      );
      final ContentPackManifest back = ContentPackManifest.fromJson(m.toJson());
      expect(back.packId, 'lingo');
      expect(back.version, '1.2.0');
      expect(back.contentHash, 'abc');
      expect(back.assets.single.path, 'a.png');
      expect(back.generators, <String>['gemini-x']);
      expect(back.locales, <String>['en']);
    });

    test('missing pack_id or version throws FormatException', () {
      expect(
          () => ContentPackManifest.fromJson(
              <String, Object?>{'version': '1.0.0'}),
          throwsFormatException);
      expect(
          () => ContentPackManifest.fromJson(<String, Object?>{'pack_id': 'x'}),
          throwsFormatException);
    });
  });

  group('ContentPackLoader.loadFrom (single source)', () {
    test('trusted bundled pack loads without a signature (hash enforced)',
        () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r =
          await loader.loadFrom(_pack(), requireSignature: false);
      expect(r.isOk, isTrue);
      final ContentPack p =
          r.fold((ContentPack p) => p, (_) => ContentPack.empty);
      expect(p.manifest.packId, 'lingo');
      expect(p.text('hello', locale: 'fr'), 'Salut');
      expect(p.text('hello'), 'Hi'); // default en
      expect(p.text('missing'), 'missing'); // key fallback
    });

    test('content hash mismatch is rejected', () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r = await loader
          .loadFrom(_pack(tamperContent: true), requireSignature: false);
      expect(r.isOk, isFalse);
    });

    test('remote pack with no content_hash is rejected (fail-closed)',
        () async {
      // A validly-signed but hash-less manifest must NOT leave content.json
      // unverified on the untrusted remote path (ADR 007: sig AND hash).
      const ContentPackLoader loader =
          ContentPackLoader(verifier: _FakeVerifier(true));
      final Result<ContentPack> r =
          await loader.loadFrom(_hashlessPack(), requireSignature: true);
      expect(r.isOk, isFalse);
    });

    test('trusted bundled pack may omit the content hash', () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r =
          await loader.loadFrom(_hashlessPack(), requireSignature: false);
      expect(r.isOk, isTrue);
    });

    test('remote pack requires a signature — missing sig rejected', () async {
      const ContentPackLoader loader =
          ContentPackLoader(verifier: _FakeVerifier(true));
      final Result<ContentPack> r = await loader
          .loadFrom(_pack(includeSig: false), requireSignature: true);
      expect(r.isOk, isFalse);
    });

    test('remote pack with an invalid signature is rejected', () async {
      const ContentPackLoader loader =
          ContentPackLoader(verifier: _FakeVerifier(false));
      final Result<ContentPack> r =
          await loader.loadFrom(_pack(), requireSignature: true);
      expect(r.isOk, isFalse);
    });

    test('remote pack with a valid signature + matching hash loads', () async {
      const ContentPackLoader loader =
          ContentPackLoader(verifier: _FakeVerifier(true));
      final Result<ContentPack> r =
          await loader.loadFrom(_pack(), requireSignature: true);
      expect(r.isOk, isTrue);
    });

    test('missing manifest is rejected', () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r = await loader.loadFrom(
          const InMemoryContentPackSource(<String, List<int>>{}),
          requireSignature: false);
      expect(r.isOk, isFalse);
    });

    test('malformed manifest JSON is rejected (not a crash)', () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r = await loader.loadFrom(
        const InMemoryContentPackSource(<String, List<int>>{
          'manifest.json': <int>[123, 34, 111]
        }),
        requireSignature: false,
      );
      expect(r.isOk, isFalse);
    });
  });

  group('ContentPackLoader.load (two-tier policy)', () {
    test('returns the verified remote pack when valid', () async {
      const ContentPackLoader loader =
          ContentPackLoader(verifier: _FakeVerifier(true));
      final Result<ContentPack> r =
          await loader.load(remote: _pack(), bundled: _pack());
      expect(r.isOk, isTrue);
    });

    test('falls back to the bundled base when the remote fails verification',
        () async {
      // Default RejectingPackVerifier => the remote signature never validates,
      // so the trusted bundled base must load instead.
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r =
          await loader.load(remote: _pack(), bundled: _pack());
      expect(r.isOk, isTrue);
      final ContentPack p =
          r.fold((ContentPack p) => p, (_) => ContentPack.empty);
      expect(p.manifest.packId, 'lingo');
    });

    test('errs when neither a valid remote nor a bundled pack is available',
        () async {
      const ContentPackLoader loader = ContentPackLoader();
      final Result<ContentPack> r = await loader.load(remote: _pack());
      expect(r.isOk, isFalse); // remote rejected, no bundled base
    });
  });

  group('pinned key + rejecting verifier', () {
    test('key is unconfigured until S-3 lands', () {
      expect(isContentPackKeyConfigured, isFalse);
      expect(kContentPackPublicKeyBase64, isEmpty);
    });

    test('RejectingPackVerifier refuses everything', () async {
      const PackVerifier v = RejectingPackVerifier();
      expect(await v.verify(message: <int>[1], signature: <int>[2]), isFalse);
    });
  });
}
