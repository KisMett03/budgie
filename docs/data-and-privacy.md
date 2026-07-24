# Data and privacy

Expense, budget, goal, profile, and cached exchange-rate data is stored locally in the Drift database on the device.

When enabled, notification-derived expense text and selected financial context may be sent to the Budgie FastAPI backend for structured extraction or analysis. The app also uses Firebase initialization and background services for platform integration; review the active service configuration before adding new remote data flows.

Do not log notification bodies, merchant names, amounts, user identifiers, or complete API request payloads. Debug logging should identify an endpoint or operation without exposing financial content.

The backend URL can be overridden at build time with `BUDGIE_API_BASE_URL`. Keep production credentials and platform configuration outside source control.
