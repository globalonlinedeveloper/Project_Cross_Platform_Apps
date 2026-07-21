import 'package:mason/mason.dart';

/// Validates the app.yaml-derived vars before stamping.
void run(HookContext context) {
  final vars = context.vars;
  final appId = (vars['app_id'] ?? '').toString();
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(appId)) {
    context.logger.err('app_id must be snake_case lowercase starting with a letter: got "$appId"');
    throw Exception('invalid app_id');
  }
  final seed = (vars['seed_hex'] ?? '').toString();
  if (!RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(seed)) {
    context.logger.err('seed_hex must be 6 hex digits (RRGGBB): got "$seed"');
    throw Exception('invalid seed_hex');
  }
  context.logger.info('Stamping ${vars['display_name']} ($appId)…');
}
