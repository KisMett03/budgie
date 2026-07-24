# Development

Install Flutter, then run:

```bash
flutter pub get
flutter analyze
flutter test
```

Format Dart files with:

```bash
dart format .
```

After changing Drift tables or migration-related code, regenerate the database companion and verify the generated diff:

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code
```
