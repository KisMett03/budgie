# Database

Budgie uses Drift with SQLite. The schema is defined in `lib/data/local/database/app_database.dart` and the generated companion code is `app_database.g.dart`.

Current tables:

- `Expenses`
- `Budgets`
- `ExchangeRates`
- `FinancialGoals`
- `GoalHistory`
- `UserProfiles`
- `AnalysisResults`

The database schema version is currently 18. Migration code is handwritten in `AppDatabase.migration`; migration behavior should be preserved during structural refactors and covered by in-memory database tests before changing SQL.

Regenerate Drift code with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated Drift code is committed so source checkouts can build without requiring a code-generation step during every development run. CI should regenerate it and fail if the generated diff is not clean.
