# Offline Settings Implementation

This document describes the offline settings functionality that has been added to the Budgie app.

## Overview

The app now supports offline settings management, allowing users to:
- Access and modify settings even when offline
- Automatically sync settings with Firebase when connection is restored
- Store settings locally using SQLite database

## Key Features

### 1. Offline-First Architecture
- Settings are stored locally in SQLite database using Drift ORM
- Local storage is the primary source of truth
- Firebase serves as backup and sync mechanism

### 2. Automatic Synchronization
- Settings sync automatically when internet connection is restored
- Background sync ensures data consistency
- Conflict resolution prioritizes local changes

### 3. Seamless User Experience
- No difference in user experience between online/offline modes
- Settings changes are immediately reflected in the UI
- Graceful handling of network failures

## Implementation Details

### Database Schema
The `Users` table in the local SQLite database stores:
- `currency`: User's preferred currency (default: 'MYR')
- `theme`: App theme preference (default: 'dark')
- `allowNotification`: Notification permission setting (default: true)
- `autoBudget`: Auto budget feature setting (default: false)
- `improveAccuracy`: Accuracy improvement setting (default: false)
- `isSynced`: Sync status flag
- `lastModified`: Last modification timestamp

### Key Components

#### 1. SettingsService (`lib/core/services/settings_service.dart`)
- Manages settings state and persistence
- Handles offline/online mode switching
- Provides methods for updating individual settings

#### 2. LocalDataSource (`lib/data/datasources/local_data_source_impl.dart`)
- Implements local storage operations
- Manages sync queue for pending changes
- Provides CRUD operations for user settings

#### 3. SyncService (`lib/core/services/sync_service.dart`)
- Handles background synchronization
- Manages sync queue processing
- Resolves conflicts between local and remote data

### Usage Examples

#### Initialize Settings for User
```dart
final settingsService = SettingsService.instance;
await settingsService.initializeForUser(userId);
```

#### Update Settings Offline
```dart
// These work both online and offline
await settingsService.updateCurrency('USD');
await settingsService.updateTheme('light');
await settingsService.updateNotificationSetting(false);
```

#### Manual Sync
```dart
await settingsService.syncPendingChanges();
```

## Benefits

1. **Improved User Experience**: Users can modify settings regardless of connectivity
2. **Data Reliability**: Local storage ensures settings are never lost
3. **Performance**: Faster settings access from local database
4. **Offline Capability**: Full functionality without internet connection
5. **Automatic Recovery**: Seamless sync when connection is restored

## Migration

The implementation includes automatic database migration from schema version 1 to 2, adding the new settings columns to existing installations.

## Testing

The offline functionality can be tested by:
1. Disabling network connection
2. Modifying settings in the app
3. Verifying changes persist after app restart
4. Re-enabling network and confirming sync to Firebase

## Future Enhancements

- Conflict resolution strategies for simultaneous changes
- Settings backup/restore functionality
- Advanced sync scheduling options
- Settings export/import features 