# Map View Feature - Phase 1 Implementation Plan

## Overview

Phase 1 implements the **current location** map view mode with a toggle between list and map views on the home screen. The map displays visited locations as markers, centered on the user's current location with a 1km radius default view.

## Requirements Summary

- **Mode**: Current location only (Phase 1)
- **Toggle**: Switch between list and map view above the visits list
- **Default View**: 1km radius centered on current location
- **Interactions**: Pinch to zoom, drag to pan (standard map gestures)
- **Markers**: Display visited locations that have GPS coordinates
- **Testing**: Comprehensive tests following existing patterns
- **Tile Caching**: Include if possible
- **OSM Attribution**: Follow OpenStreetMap licensing requirements

---

## Technical Decisions

### Map Package Selection

**Package**: `flutter_map` (v6.x)
- **Why**: Most popular and well-maintained OpenStreetMap package for Flutter
- **Features**:
  - Native OpenStreetMap tile support
  - Custom tile providers
  - Marker support
  - Gesture handling (zoom, pan)
  - Good performance
  - Active maintenance

**Alternative considered**: `google_maps_flutter` - Rejected because requirement specifies OpenStreetMap

**Dependencies to add**:
```yaml
dependencies:
  flutter_map: ^6.1.0
  latlong2: ^0.8.1  # Required by flutter_map for LatLng
```

### Tile Caching

**Package**: `flutter_map_cache` (optional, if available) or custom implementation
- **Why**: Reduces network usage and improves offline performance
- **Implementation**: Use `CachedNetworkTileProvider` wrapper if package available, otherwise implement basic caching using `flutter_cache_manager`

**Note**: If tile caching adds significant complexity, it can be deferred to a later phase.

### OSM Attribution

OpenStreetMap requires attribution. We'll add:
- Text attribution in bottom-right corner: "© OpenStreetMap contributors"
- Link to OSM copyright page (optional but recommended)
- Style: Small, unobtrusive text that doesn't interfere with map usage

---

## Architecture

### File Structure

```
lib/
  features/
    map/
      domain/
        models/
          map_marker.dart          # Marker data model
      presentation/
        widgets/
          map_view_widget.dart     # Main map widget
          visit_marker.dart        # Custom marker widget for visits
          osm_attribution.dart     # OSM attribution widget
        screens/
          map_view_screen.dart     # Full-screen map (future use)
      data/
        services/
          map_tile_cache_service.dart  # Tile caching service (if implemented)
test/
  features/
    map/
      presentation/
        widgets/
          map_view_widget_test.dart
          visit_marker_test.dart
      data/
        services/
          map_tile_cache_service_test.dart
  fakes/
    map_tile_cache_service_fake.dart  # If caching implemented
```

### State Management

- **HomeScreen**: Add state variable for view mode (list/map)
- **MapViewWidget**: Stateless widget that receives data as parameters
- **Location updates**: Use existing `LocationService` to get current location
- **Visit data**: Pass visits list from HomeScreen to MapViewWidget

### Data Flow

1. **HomeScreen** loads visits via `VisitRepository`
2. **HomeScreen** gets current location via `LocationService`
3. **HomeScreen** passes visits + current location to **MapViewWidget**
4. **MapViewWidget** displays map with markers
5. User toggles between list/map view

### Task completion

Once complete add a ✅ to the task heading

---

## Implementation Tasks

### Task 1: Add Dependencies ✅
**Priority**: Critical
**Estimated Time**: 15 minutes

**Actions**:
1. Add `flutter_map` and `latlong2` to `pubspec.yaml`
2. Run `flutter pub get`
3. If implementing tile caching, add `flutter_cache_manager` or `flutter_map_cache`

**Files to Modify**:
- `pubspec.yaml`

**Verification**:
- Dependencies resolve without conflicts
- No breaking changes to existing code

---

### Task 2: Create Map Marker Model ✅
**Priority**: High
**Estimated Time**: 30 minutes

**Description**: Create a model to represent map markers for visits.

**Requirements**:
- Represent a visit location on the map
- Include visit data (id, placeName, coordinates)
- Support both `gpsRecorded` and `gpsKnown` coordinates (prefer `gpsKnown`, fallback to `gpsRecorded`)

**Files to Create**:
- `lib/features/map/domain/models/map_marker.dart`

**Model Structure**:
```dart
class MapMarker {
  final String visitId;
  final String placeName;
  final GeoLatLong coordinates;
  final Visit visit; // Full visit data for info windows/details

  // Constructor, equality, toString
}
```

**Helper Method**:
- `List<MapMarker> fromVisits(List<Visit> visits)` - Convert visits to markers, filtering out visits without coordinates

**Deliverables**:
- MapMarker model class
- Helper methods for conversion
- Unit tests

---

### Task 3: Create OSM Attribution Widget
**Priority**: High
**Estimated Time**: 30 minutes

**Description**: Create a widget to display OpenStreetMap attribution as required by OSM licensing.

**Requirements**:
- Display "© OpenStreetMap contributors" text
- Position in bottom-right corner (or configurable)
- Small, unobtrusive styling
- Optional: Link to OSM copyright page
- Material 3 styling

**Files to Create**:
- `lib/features/map/presentation/widgets/osm_attribution.dart`

**Design**:
- Small text (bodySmall style)
- Semi-transparent background for readability
- Padding for touch target
- Positioned widget that overlays map

**Deliverables**:
- OSM attribution widget
- Widget tests

---

### Task 4: Create Visit Marker Widget
**Priority**: High
**Estimated Time**: 1 hour

**Description**: Create a custom marker widget to display visits on the map.

**Requirements**:
- Visual marker (pin/icon) for each visit
- Differentiate current location marker from visit markers
- Tap to show visit info (optional for Phase 1, can be basic)
- Material 3 styling

**Files to Create**:
- `lib/features/map/presentation/widgets/visit_marker.dart`

**Design**:
- Use Material Icons (e.g., `Icons.place` or `Icons.location_on`)
- Color from theme (primary color for visits)
- Current location marker: Different color (e.g., accent or blue)
- Size: Appropriate for map zoom levels

**Deliverables**:
- Visit marker widget
- Current location marker widget
- Widget tests

---

### Task 5: Create Map View Widget
**Priority**: Critical
**Estimated Time**: 2-3 hours

**Description**: Main map widget that displays OpenStreetMap with markers.

**Requirements**:
- Display OpenStreetMap tiles
- Center on current location with 1km radius (zoom level ~15)
- Display visit markers
- Display current location marker
- Support pinch-to-zoom and drag-to-pan
- Handle loading states
- Handle error states (no location, no permission)
- Material 3 styling

**Files to Create**:
- `lib/features/map/presentation/widgets/map_view_widget.dart`

**Implementation Details**:

1. **Tile Provider**:
   - Use OpenStreetMap tile server: `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
   - Respect OSM tile usage policy (User-Agent header)
   - If caching implemented, wrap with cache provider

2. **Initial View**:
   - Calculate zoom level for 1km radius: `zoomLevel = 15` (approximately 1km at equator)
   - Center on current location
   - If no current location, show error state

3. **Markers**:
   - Convert visits to MapMarkers
   - Filter visits without coordinates
   - Display markers using flutter_map's MarkerLayer

4. **States**:
   - Loading: Show CircularProgressIndicator
   - Error: Show error message with retry option
   - Success: Show map with markers

5. **User-Agent**:
   - Set User-Agent header for OSM tile requests
   - Format: "Goldfish/1.0.0 (contact: your-email@example.com)"

**Widget Signature**:
```dart
class MapViewWidget extends StatelessWidget {
  final GeoLatLong? currentLocation;
  final List<Visit> visits;
  final VoidCallback? onRetry;

  // Constructor, build method
}
```

**Deliverables**:
- Map view widget
- Error handling
- Loading states
- Widget tests

---

### Task 6: Integrate Map View into Home Screen
**Priority**: Critical
**Estimated Time**: 1-2 hours

**Description**: Add toggle between list and map view in HomeScreen.

**Requirements**:
- Toggle button/switch above the visits list
- Switch between ListView and MapViewWidget
- Preserve visits data when toggling
- Handle location permission requests
- Show appropriate states (loading, error, empty)

**Files to Modify**:
- `lib/features/home/presentation/screens/home_screen.dart`

**UI Changes**:

1. **Add View Mode State**:
   ```dart
   enum ViewMode { list, map }
   ViewMode _viewMode = ViewMode.list;
   GeoLatLong? _currentLocation;
   bool _isLoadingLocation = false;
   ```

2. **Add Toggle UI**:
   - SegmentedButton or Switch in AppBar or above body
   - Icons: `Icons.list` and `Icons.map`
   - Label: "List" / "Map"

3. **Location Handling**:
   - When switching to map view, request location if not available
   - Use existing `LocationService` (inject via constructor or create instance)
   - Handle permission denied states
   - Show error if location unavailable

4. **Body Logic**:
   ```dart
   Widget _buildBody() {
     if (_viewMode == ViewMode.map) {
       return MapViewWidget(
         currentLocation: _currentLocation,
         visits: _visits,
         onRetry: _loadLocation,
       );
     }
     // Existing list view code
   }
   ```

**Considerations**:
- Location permission should be requested only when user switches to map view (not on app start)
- If permission denied, show error message with option to open settings
- If location unavailable, allow user to still view map (centered on first visit or default location)

**Deliverables**:
- Updated HomeScreen with toggle
- Location handling
- State management
- Widget tests

---

### Task 7: Handle Location Permissions and Errors
**Priority**: High
**Estimated Time**: 1 hour

**Description**: Properly handle location permissions and error states in map view.

**Requirements**:
- Request location permission when switching to map view
- Handle permission denied gracefully
- Show error messages with actionable options
- Allow map to display even without current location (center on visits or default)

**Implementation**:
- Use existing `LocationService` methods
- Check `isPermissionDeniedForever()` to show "Open Settings" option
- If no current location but visits exist, center map on first visit or center of all visits
- If no location and no visits, show empty state with message

**Error States**:
1. **Permission Denied**: "Location permission required. Tap to enable in settings."
2. **Location Services Disabled**: "Please enable location services in device settings."
3. **Location Unavailable**: "Unable to get current location. Showing visited places."
4. **No Visits**: "No visits to display on map."

**Deliverables**:
- Error handling in MapViewWidget
- Error handling in HomeScreen
- User-friendly error messages
- Tests for error states

---

### Task 8: Implement Tile Caching (Optional)
**Priority**: Medium
**Estimated Time**: 2-3 hours

**Description**: Cache map tiles to reduce network usage and improve offline performance.

**Requirements**:
- Cache tiles locally
- Respect cache size limits
- Clear cache on app uninstall (automatic with app data)
- Handle cache errors gracefully

**Implementation Options**:

**Option A**: Use `flutter_cache_manager` (simpler)
- Wrap tile provider with cached network image provider
- Set cache size limit (e.g., 100MB)
- Cache duration: 30 days (OSM tiles don't change frequently)

**Option B**: Use `flutter_map_cache` package (if available and maintained)
- Dedicated package for flutter_map caching
- May have better integration

**Option C**: Custom implementation
- Use `path_provider` for cache directory
- Implement basic LRU cache
- More control but more code

**Recommendation**: Start with Option A (`flutter_cache_manager`) as it's well-maintained and simple.

**Files to Create**:
- `lib/features/map/data/services/map_tile_cache_service.dart` (if custom)
- Or use `flutter_cache_manager` directly in MapViewWidget

**Deliverables**:
- Tile caching implementation
- Cache management
- Tests (if custom service)

**Note**: This can be deferred to Phase 2 if time-constrained.

---

### Task 9: Testing
**Priority**: Critical
**Estimated Time**: 3-4 hours

**Description**: Write comprehensive tests for all map-related components.

**Test Coverage**:

1. **MapMarker Model** (`test/features/map/domain/models/map_marker_test.dart`):
   - Conversion from visits
   - Filtering visits without coordinates
   - Preferring `gpsKnown` over `gpsRecorded`
   - Equality and toString

2. **OSM Attribution Widget** (`test/features/map/presentation/widgets/osm_attribution_test.dart`):
   - Renders attribution text
   - Positioned correctly
   - Styling matches theme

3. **Visit Marker Widget** (`test/features/map/presentation/widgets/visit_marker_test.dart`):
   - Renders marker icon
   - Applies correct styling
   - Differentiates visit vs current location markers

4. **Map View Widget** (`test/features/map/presentation/widgets/map_view_widget_test.dart`):
   - Displays map with markers
   - Handles null current location
   - Handles empty visits list
   - Shows loading state
   - Shows error state
   - Calls onRetry callback

5. **HomeScreen Integration** (`test/features/home/presentation/screens/home_screen_test.dart`):
   - Toggle switches between list and map
   - Requests location when switching to map
   - Handles location permission denied
   - Passes visits to map view
   - Preserves visits when toggling

**Testing Patterns**:
- Use function-field fakes for `LocationService` (existing `FakeLocationService`)
- Use `FakeVisitRepository` for visit data
- Mock `flutter_map` components if needed (may require widget test setup)
- Test error states and edge cases

**Mocking Strategy**:
- `LocationService`: Use existing `FakeLocationService`
- `VisitRepository`: Use existing `FakeVisitRepository`
- `flutter_map`: May need to mock or use integration tests (flutter_map may not work well in widget tests)

**Note**: `flutter_map` widget tests may be challenging. Consider:
- Testing the widget structure and data flow
- Using golden tests for visual verification
- Integration tests for full map functionality

**Deliverables**:
- Unit tests for models
- Widget tests for UI components
- Integration tests for map functionality (if needed)
- Test coverage > 80%

---

### Task 10: Permissions and Configuration
**Priority**: High
**Estimated Time**: 30 minutes

**Description**: Ensure location permissions are properly configured for Android and iOS.

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Already configured (app uses `geolocator` which requires permissions)
- Verify: `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are present

**iOS** (`ios/Runner/Info.plist`):
- Already configured (app uses `geolocator`)
- Verify: `NSLocationWhenInUseUsageDescription` is present
- Update description if needed: "Goldfish needs your location to show visited places on the map."

**Firestore Indexes**:
- **No new indexes required** for Phase 1
- Map view uses the same `getUserVisits()` query as list view
- All filtering/processing happens in-memory

**Deliverables**:
- Verified permission configurations
- Updated permission descriptions if needed
- Documentation of any changes

---

## Implementation Order

1. **Task 1**: Add Dependencies
2. **Task 2**: Create Map Marker Model
3. **Task 3**: Create OSM Attribution Widget
4. **Task 4**: Create Visit Marker Widget
5. **Task 5**: Create Map View Widget
6. **Task 6**: Integrate Map View into Home Screen
7. **Task 7**: Handle Location Permissions and Errors
8. **Task 10**: Permissions and Configuration
9. **Task 9**: Testing
10. **Task 8**: Tile Caching (optional, can be deferred)

---

## Edge Cases and Considerations

### No Current Location
- **Scenario**: User denies location permission or location unavailable
- **Solution**: Center map on first visit, or center of all visits, or default location (e.g., London)

### No Visits with Coordinates
- **Scenario**: User has visits but none have GPS coordinates
- **Solution**: Show map centered on current location (if available) or default location, with message "No visits with locations to display"

### Empty Visits List
- **Scenario**: User has no visits
- **Solution**: Show map centered on current location with empty state message

### Location Permission Denied Forever
- **Scenario**: User denied permission and selected "Don't ask again"
- **Solution**: Show error message with button to open app settings

### Network Issues
- **Scenario**: No internet connection for loading map tiles
- **Solution**: Show cached tiles if available, otherwise show error message

### Performance
- **Scenario**: User has many visits (100+)
- **Solution**:
  - Markers are lightweight, should handle 100+ without issues
  - Consider clustering in future phases if needed
  - Test with large datasets

---

## OSM Licensing and Attribution

### Requirements
OpenStreetMap data is licensed under ODbL (Open Database License). We must:

1. **Attribution**: Display "© OpenStreetMap contributors" on the map
2. **User-Agent**: Include proper User-Agent header in tile requests
3. **Tile Usage Policy**: Respect OSM tile usage policy (reasonable usage, not excessive)

### Implementation
- Attribution widget (Task 3) displays required text
- User-Agent header set in tile provider (Task 5)
- No excessive tile requests (flutter_map handles this automatically)

### Links
- OSM Copyright: https://www.openstreetmap.org/copyright
- Tile Usage Policy: https://operations.osmfoundation.org/policies/tiles/

---

## Future Phases (Out of Scope for Phase 1)

- **Phase 2**: Search for location mode
- **Phase 3**: View visit from list mode
- **Phase 4**: Marker clustering for many visits
- **Phase 5**: Visit details on marker tap
- **Phase 6**: Custom map styles
- **Phase 7**: Offline map support

---

## Success Criteria

Phase 1 is complete when:

1. ✅ User can toggle between list and map view
2. ✅ Map displays OpenStreetMap tiles
3. ✅ Map centers on current location with 1km radius
4. ✅ Visited locations with GPS coordinates are displayed as markers
5. ✅ Map supports pinch-to-zoom and drag-to-pan
6. ✅ Location permissions are handled gracefully
7. ✅ Error states are displayed appropriately
8. ✅ OSM attribution is displayed
9. ✅ All tests pass with >80% coverage
10. ✅ Code follows existing patterns and style guide

---

## Estimated Total Time

- **Core Implementation**: 8-10 hours
- **Testing**: 3-4 hours
- **Tile Caching (optional)**: 2-3 hours
- **Total**: 11-14 hours (13-17 hours with tile caching)

---

## Notes

- This plan focuses on Phase 1 only (current location mode)
- Future phases will add search and visit selection modes
- Tile caching can be deferred if time-constrained
- Testing `flutter_map` in widget tests may require special setup or integration tests
- Consider user feedback before implementing Phase 2 features

### Follow phases

1. This phase
2. search for a location
3. from a visit in the list

As per the rest of this app everything must have tests. Test setup must be as a simple as possible. Mocks follow the current pattern. If any Fire Store indexes or permission changes are required, an explanation should be included.
