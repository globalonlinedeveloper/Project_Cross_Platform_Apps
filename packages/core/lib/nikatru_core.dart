/// Core domain layer for NIKATRU apps: data models, Result/Failure and content
/// packs. Pure Dart — safe to depend on from any app or package.
library;

export 'src/content_pack.dart';
export 'src/result.dart';
export 'src/config/app_config.dart';
export 'src/config/config_loader.dart';
export 'src/config/default_configs.dart';
export 'src/models/app_notification.dart';
export 'src/models/budget_info.dart';
export 'src/models/entitlement.dart';
export 'src/models/payment_record.dart';
export 'src/models/subscription.dart';
export 'src/storage/key_value_store.dart';
export 'src/storage/secure_store.dart';
