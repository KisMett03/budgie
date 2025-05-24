# Budgie App - System Architecture

## Overview

Budgie is a Flutter-based personal finance management application built with clean architecture principles. The app supports both online and offline functionality with automatic data synchronization.

## Project Structure

```
lib/
├── core/                    # Core functionality and utilities
│   ├── constants/          # App constants and configuration
│   ├── errors/            # Error handling and custom exceptions
│   ├── network/           # Network connectivity services
│   ├── router/            # Navigation and routing logic
│   ├── services/          # Core business services
│   └── utils/             # Utility functions and helpers
├── data/                   # Data layer implementation
│   ├── datasources/       # Data source interfaces and implementations
│   ├── local/             # Local database and storage
│   ├── models/            # Data models and DTOs
│   └── repositories/      # Repository implementations
├── di/                     # Dependency injection setup
├── domain/                 # Domain layer (business logic)
│   ├── entities/          # Business entities
│   └── repositories/      # Repository interfaces
├── presentation/           # Presentation layer (UI)
│   ├── screens/           # App screens and pages
│   ├── utils/             # UI utilities and helpers
│   ├── viewmodels/        # State management (ViewModels)
│   └── widgets/           # Reusable UI components
└── main.dart              # App entry point
```

## Architecture Layers

### 1. Presentation Layer (`lib/presentation/`)

**Purpose**: Handles UI rendering and user interactions.

**Components**:
- **Screens**: Full-page UI components (HomeScreen, LoginScreen, etc.)
- **Widgets**: Reusable UI components (CustomButton, ExpenseCard, etc.)
- **ViewModels**: State management using Provider pattern
- **Utils**: UI-specific utilities (themes, constants, etc.)

**Key Features**:
- Responsive design with Material Design 3
- Smooth page transitions and animations
- State management with Provider
- Custom widgets for consistent UI

### 2. Domain Layer (`lib/domain/`)

**Purpose**: Contains business logic and entities, independent of external frameworks.

**Components**:
- **Entities**: Core business objects (User, Expense, Budget, Category)
- **Repositories**: Abstract interfaces for data access

**Key Features**:
- Framework-independent business logic
- Clean entity definitions
- Repository pattern for data abstraction

### 3. Data Layer (`lib/data/`)

**Purpose**: Handles data persistence and external API communication.

**Components**:
- **Datasources**: Local and remote data source implementations
- **Local**: SQLite database using Drift ORM
- **Models**: Data transfer objects and serialization
- **Repositories**: Concrete repository implementations

**Key Features**:
- Offline-first architecture with SQLite
- Firebase integration for cloud sync
- Automatic data synchronization
- Repository pattern implementation

### 4. Core Layer (`lib/core/`)

**Purpose**: Provides shared functionality across all layers.

**Components**:
- **Constants**: App-wide constants and configuration
- **Errors**: Custom exception classes and error handling
- **Network**: Connectivity monitoring and network utilities
- **Router**: Navigation system with smooth transitions
- **Services**: Core business services (sync, settings, notifications)
- **Utils**: Utility functions and helpers

## Key Features

### 1. Offline-First Architecture

- **Local Storage**: SQLite database with Drift ORM
- **Sync Service**: Automatic synchronization when online
- **Conflict Resolution**: Local changes take precedence
- **Queue System**: Pending operations stored locally

### 2. Smooth Navigation System

- **Custom Transitions**: Multiple transition types (slide, fade, scale, etc.)
- **Direction-Aware**: Smart transition direction based on navigation flow
- **Performance Optimized**: Smooth 60fps animations
- **Contextual**: Different transitions for different screen types

### 3. Settings Management

- **Offline Support**: Settings work without internet connection
- **Auto-Sync**: Automatic synchronization with Firebase
- **User Preferences**: Currency, theme, notifications, etc.
- **Default Values**: Sensible defaults for new users

### 4. Data Synchronization

- **Background Sync**: Automatic sync when connection restored
- **Periodic Sync**: Regular sync every 15 minutes
- **Manual Sync**: User-triggered synchronization
- **Error Handling**: Robust error handling and retry logic

## Services

### SyncService
- Manages data synchronization between local and remote storage
- Handles offline queue processing
- Provides conflict resolution strategies

### SettingsService
- Manages user preferences and app settings
- Supports offline functionality
- Automatic Firebase synchronization

### ConnectivityService
- Monitors network connectivity status
- Provides real-time connection updates
- Triggers sync operations when online

### NotificationService
- Handles push notifications
- Expense detection from notifications
- User permission management

## Database Schema

### Tables

1. **Users**: User information and settings
2. **Expenses**: Expense records with categories
3. **Budgets**: Monthly budget allocations
4. **SyncQueue**: Pending synchronization operations

### Migration Strategy
- Schema versioning with automatic migrations
- Backward compatibility support
- Data integrity preservation

## Navigation System

### Transition Types
- `smoothSlideRight/Left`: Horizontal sliding with fade
- `smoothFadeSlide`: Fade with subtle slide
- `smoothScale`: Scale animation for important screens
- `materialPageRoute`: Material Design standard transition
- `slideAndFadeVertical`: Modal-style bottom slide

### Navigation Helper
- Simplified navigation methods
- Context extensions for easy usage
- Type-safe route handling
- Consistent transition application

## Error Handling

### Custom Exceptions
- `NetworkError`: Network-related issues
- `AuthError`: Authentication problems
- `DataError`: Data access errors

### Error Recovery
- Graceful degradation for offline scenarios
- User-friendly error messages
- Automatic retry mechanisms
- Logging for debugging

## Performance Optimizations

### Database
- Indexed queries for fast data retrieval
- Batch operations for bulk updates
- Connection pooling and optimization

### UI
- Widget recycling in lists
- Image caching and optimization
- Lazy loading for large datasets
- Smooth animations with proper curves

### Memory Management
- Proper disposal of resources
- Stream subscription management
- Image memory optimization

## Security Considerations

### Data Protection
- Local database encryption (planned)
- Secure API communication with HTTPS
- User authentication with Firebase Auth
- Input validation and sanitization

### Privacy
- Minimal data collection
- User consent for notifications
- Local-first data storage
- Optional cloud synchronization

## Testing Strategy

### Unit Tests
- Business logic testing
- Repository pattern testing
- Service layer testing

### Integration Tests
- Database operations
- API communication
- Sync functionality

### Widget Tests
- UI component testing
- User interaction testing
- Navigation testing

## Deployment

### Build Configuration
- Environment-specific configurations
- Firebase project setup
- Platform-specific optimizations

### Release Process
- Automated testing pipeline
- Code quality checks
- Performance monitoring
- Crash reporting integration

## Future Enhancements

### Planned Features
- Data export/import functionality
- Advanced analytics and reporting
- Multi-currency support enhancement
- Collaborative budgeting
- Receipt scanning with OCR
- Investment tracking

### Technical Improvements
- Database encryption
- Advanced caching strategies
- Real-time collaboration
- Machine learning for expense categorization
- Advanced notification intelligence

## Contributing

### Code Style
- Follow Dart/Flutter conventions
- Use meaningful variable names
- Add comprehensive documentation
- Write unit tests for new features

### Architecture Guidelines
- Maintain clean architecture principles
- Keep layers separated and independent
- Use dependency injection consistently
- Follow SOLID principles

### Pull Request Process
1. Create feature branch from main
2. Implement changes with tests
3. Update documentation
4. Submit pull request with description
5. Code review and approval
6. Merge to main branch

## License

This project is licensed under the MIT License - see the LICENSE file for details. 