# Compare Shopify Liquid and Liquify

From the repository root, with the Dart SDK and a running Docker daemon:

```sh
dart pub get
pkgs/liquify/tool/liquid_compat/compare.sh
```

The default run covers both `issue_42.json` and `rendering.json`. Together
they cover expressions, filters, tags, partials, whitespace, and error
handling. Pass one or more paths to compare specific files. Relative paths
are resolved from the directory in which you run the command.

The initial Docker build needs network access. It pins Shopify Liquid 5.14.0
to commit `15a2e32d186f713643fe86202da8da44a7bb058b`. Ruby renders in a
container without network access. Liquify uses the current checkout and
renders each fixture synchronously and asynchronously in separate templates.

The runner compares exact output, including whitespace, or checks whether
both engines reject the template for the same known reason. It prints the
Ruby, Dart sync, and Dart async results for each difference and exits with
status 1 if any fixture differs. Both engines use strict missing-partial
resolution. Ruby uses its default parser with strict filter checking.

## Add a fixture

Each fixture file is a JSON array. Each entry has a `label` and a template
`source`. The optional `data` object supplies template variables and the
optional `partials` object maps names to partial template strings.

```json
[
  {
    "label": "integer division",
    "source": "{{ total | divided_by: 7 }}",
    "data": { "total": 20 }
  }
]
```

The live comparison gets expected output directly from Ruby. The issue #42
fixtures also carry `expected` or `expected_contains` for the offline VM
regression test. Run it from `pkgs/liquify` with
`dart test -p vm test/issue_42_test.dart`.
