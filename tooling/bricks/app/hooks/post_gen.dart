import 'dart:convert';
import 'dart:io';

import 'package:mason/mason.dart';

/// After a stamp: (1) append the app to sites/_shared/_data/apps.json (SHOW-1,
/// automated), then (2) print the owner's manual, non-automatable checklist.
void run(HookContext context) {
  final v = context.vars;
  final id = (v['app_id'] ?? '').toString();
  final displayName = (v['display_name'] ?? id).toString();
  final subdomain = (v['subdomain'] ?? '').toString();
  final apiDomain = (v['api_domain'] ?? '').toString();
  final tagline = (v['description'] ?? '').toString();

  _appendToAppsJson(
    context,
    id: id,
    name: _shortName(displayName),
    tagline: tagline,
    url: subdomain.isEmpty ? '' : 'https://$subdomain',
    api: apiDomain.isEmpty ? '' : 'https://$apiDomain',
  );

  final apiHost = apiDomain.isEmpty ? 'api-$id.nikatru.com' : apiDomain;
  final webHost = subdomain.isEmpty ? '$id.nikatru.com' : subdomain;
  context.logger
    ..info('')
    ..success('Stamped $id (apps/$id + services/$id-api). Owner checklist:')
    ..info('  1. Fill apps/$id/app.yaml store metadata + brand assets.')
    ..info('  2. wrangler d1 create ${id}_db, then paste the id into '
        'services/$id-api/wrangler.jsonc (APP_DB.database_id).')
    ..info('  3. cd services/$id-api && npm install && npm run db:migrate.')
    ..info('  4. Add DNS for $apiHost and the web subdomain $webHost.')
    ..info('  5. cd apps/$id && flutter pub get && flutter analyze.');
}

/// "Lingo — Offline Phrasebook" -> "Lingo".
String _shortName(String displayName) {
  final dash = displayName.indexOf(RegExp(r'[—-]'));
  final base = dash > 0 ? displayName.substring(0, dash) : displayName;
  return base.trim();
}

/// SHOW-1: append `id` to the shared apps catalog if not already present.
/// Idempotent; leaves the file untouched when the slug already exists.
void _appendToAppsJson(
  HookContext context, {
  required String id,
  required String name,
  required String tagline,
  required String url,
  required String api,
}) {
  final file = File('sites/_shared/_data/apps.json');
  if (!file.existsSync()) {
    context.logger
        .warn('apps.json not found at ${file.path}; skipped SHOW-1 append.');
    return;
  }
  final decoded = jsonDecode(file.readAsStringSync());
  if (decoded is! List) {
    context.logger.warn('apps.json is not a JSON array; skipped.');
    return;
  }
  if (decoded.any((e) => e is Map && e['slug'] == id)) {
    context.logger.info('apps.json already lists "$id"; left unchanged.');
    return;
  }
  decoded.add(<String, dynamic>{
    'slug': id,
    'name': name,
    'tagline': tagline,
    'url': url,
    'api': api,
    'platforms': <String>['web'],
    'status': 'preview',
  });
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(decoded)}\n');
  context.logger.success('apps.json: added "$id" (SHOW-1).');
}
