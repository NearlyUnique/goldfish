# RecordVisitScreen Dependency Creation Issue - Explanation

## Issue Summary

The code review identified that `RecordVisitScreen` had a tight coupling issue where it was creating dependencies directly within the screen widget, violating the Dependency Inversion Principle and making the code harder to test and maintain.

## Original Problem (As Identified in Review)

The review document mentioned that `RecordVisitScreen` had a `_createViewModel()` method that directly instantiated dependencies:

```dart
RecordVisitViewModel _createViewModel() {
  final locationService = GeolocatorLocationService();  // Direct instantiation
  final httpClient = HttpPackageClient();
  final overpassClient = OverpassClient(httpClient: httpClient);
  final visitRepository = VisitRepository(
    firestore: FirebaseFirestore.instance,  // Direct coupling
  );
  // ...
}
```

## Why This Was a Problem

1. **Tight Coupling**: The screen was directly coupled to concrete implementations (`GeolocatorLocationService`, `HttpPackageClient`, `FirebaseFirestore.instance`), making it impossible to swap implementations or use test doubles.

2. **Violation of Dependency Inversion Principle**: High-level modules (the screen) were depending on low-level modules (concrete implementations) instead of abstractions.

3. **Poor Testability**: The screen couldn't be tested with fake dependencies because it created them internally.

4. **Mixed Responsibilities**: The screen was responsible for both UI rendering AND dependency creation, violating the Single Responsibility Principle.

5. **Fragility**: If any dependency constructor changed, the screen code would break. Changes to dependency creation logic would require modifying the screen.

## Current State (After Fix)

The issue has been resolved. The current implementation:

1. **Constructor Injection**: `RecordVisitScreen` now receives the `RecordVisitViewModel` via constructor injection:
   ```dart
   class RecordVisitScreen extends StatefulWidget {
     const RecordVisitScreen({super.key, required this.viewModel});
     final RecordVisitViewModel viewModel;
     // ...
   }
   ```

2. **Dependency Creation in AppRouter**: The `RecordVisitViewModel` is created in `AppRouter` (which receives dependencies from `main.dart`):
   ```dart
   builder: (context, state) {
     final viewModel = createRecordVisitViewModel(
       locationService: _locationService,
       overpassClient: _overpassClient,
       visitRepository: _visitRepository,
       authNotifier: _authNotifier,
     );
     return RecordVisitScreen(viewModel: viewModel);
   }
   ```

3. **Factory Function**: A factory function `createRecordVisitViewModel` centralises the creation logic, making it reusable and testable.

## Benefits of the Current Approach

1. **Loose Coupling**: The screen depends only on the `RecordVisitViewModel` abstraction, not concrete implementations.

2. **Testability**: The screen can be tested by injecting a fake `RecordVisitViewModel`.

3. **Single Responsibility**: The screen only handles UI concerns; dependency creation is handled elsewhere.

4. **Maintainability**: Changes to dependency creation don't affect the screen code.

5. **Flexibility**: Different implementations can be injected for different environments (production, testing, etc.).

## Remaining Improvement (Completed)

To further improve the architecture, a factory function was created to centralise `RecordVisitViewModel` creation:

- **File**: `lib/features/visits/domain/view_models/record_visit_view_model_factory.dart`
- **Purpose**: Provides a single point for creating `RecordVisitViewModel` instances
- **Benefits**:
  - Makes dependency creation explicit and reusable
  - Easier to test and maintain
  - Follows the factory pattern for dependency creation

## Conclusion

The `RecordVisitScreen` dependency creation issue has been resolved. The screen now follows best practices:
- Dependencies are injected via constructor
- Dependency creation happens in appropriate layers (AppRouter/main.dart)
- Factory function centralises creation logic
- Code is testable, maintainable, and follows SOLID principles

