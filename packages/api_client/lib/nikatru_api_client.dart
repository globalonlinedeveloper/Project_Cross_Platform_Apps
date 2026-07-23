/// Generic, auth-agnostic HTTP client for NIKATRU app backends (Cloudflare
/// Workers). Inject a base URL and a token provider; no auth SDK, no app-config
/// coupling, and — by design — no app domain models. Per-app domain clients
/// build on top of [RestClient].
library;

export 'src/rest_client.dart';
