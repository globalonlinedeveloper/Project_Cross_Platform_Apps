import 'package:mason/mason.dart';

/// Prints the owner's manual, non-automatable checklist after a stamp.
void run(HookContext context) {
  final v = context.vars;
  final id = v['app_id'];
  context.logger
    ..info('')
    ..success('Stamped $id. Owner checklist (not automatable):')
    ..info('  1. Fill apps/$id/app.yaml store metadata + brand assets.')
    ..info('  2. Create the Cloudflare D1 + KV and set their ids in services/$id-api.')
    ..info('  3. Add DNS for ${v['api_domain']} and the web subdomain ${v['subdomain']}.')
    ..info('  4. Append $id to sites/_shared/_data/apps.json (SHOW-1) once shipped.')
    ..info('  5. cd apps/$id && flutter pub get && flutter analyze.');
}
