# nikatru_lints

Shared analyzer settings + lint rules for every Nikatru package and app
(portfolio baseline; mirrors Subly's proven config).

## Usage

In the consumer's `pubspec.yaml` (workspace members resolve it locally):

```yaml
dev_dependencies:
  nikatru_lints: ^0.1.0
```

In the consumer's `analysis_options.yaml`:

```yaml
include: package:nikatru_lints/analysis_options.yaml
```

Baseline: `flutter_lints` 6 + `prefer_final_locals` + `avoid_print`,
`strict-casts` on, codegen files (`*.g.dart`, `*.freezed.dart`) excluded.
`prefer_const_constructors` stays off (Subly template decision — enable per
app with `dart fix --apply` if wanted).
