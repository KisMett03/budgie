# Budgie architecture

Budgie keeps its existing Flutter, Provider, GetIt, and Drift stack. The code is organized into presentation, domain, and data layers, with `lib/app` composing those layers at startup and routing.

```text
lib/
  app/                 Application composition, routing, bootstrap, lifecycle
  core/                Configuration and cross-cutting utilities
  domain/              Entities, repository contracts, and business rules
  data/                Drift database, platform services, API clients, repositories
  presentation/       Screens, widgets, view models, and presentation utilities
```

GetIt is the service-lifetime owner. Services use ordinary constructors and receive their dependencies from the service locator; screens should resolve shared services from GetIt rather than constructing them directly.

`AppRouter.generateRoute` is the single route registry. `BudgieApp` owns the root providers and Material configuration, while route-specific providers are attached by the route builder.

The domain layer is being kept pragmatic for now. Some existing orchestration services still depend on infrastructure types; future boundary cleanup should introduce ports and an application layer incrementally rather than changing the current framework choices.

Historical architecture proposals and examples remain available under `docs/archive/` when present. They are not descriptions of the running application.
