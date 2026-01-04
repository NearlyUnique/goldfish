# Search Location Feature

## Overview

Add the ability to search for places by name/address in addition to the existing GPS-based location search. This allows users to record visits to places they visited in the past by searching for the location and setting a custom date/time.

As there are currently only test users a separate database update script will be run to migrate the firestore database.
The migration script will:
- Remove the `added_at` field (redundant with `created_at`)
- Add `visited_at` field using the `created_at` value for existing visits
- Add `planned` field as `false` for all existing visits

See `scripts/migrate_visits.js` for the migration script and instructions on how to run it.

## Current Behaviour

1. User presses FAB (Add place)
2. Add screen finds current GPS location
3. Displays current lat/long
4. Looks up nearby places of interest using Overpass API (within 20m radius)
5. User selects a place from suggestions
6. User saves by pressing Add button
7. Visit is saved with `createdAt`, `updatedAt` all set to current time

## New Behaviour Requirements

1. **Search by Name/Address**: Add a search button next to the existing place name text field
2. **Search Functionality**: When user enters a place name/address (e.g., "Bag of Nails, Glasgow") and clicks search:
   - Query Overpass API using the same criteria as location-based search but based on place name/address
   - Display results in the same format as location-based suggestions
   - as a temporary measure print out to the logs the current country and town/city, we may add this into the search later if it is useful
3. **Date/Time Selection**: When adding via search:
   - Allow user to set date and time to any point in time (past or future)
   - User may set as visit as "Planned" instead of setting a visited date, default is to have "planned" disabled
   - record `planned` as an explicit Boolean field
   - This enables recording historical and planned visits
4. **Full Address Usage**: Use the complete address returned by Overpass API when saving, including county/region and country when available
5. **New Model Field**: Add `visitedAt` attribute to Visit model to store when the visit actually occurred

## Implementation Plan

### Task 0: Database Migration Script
**Priority**: Critical
**Estimated Time**: 2-3 hours

**Description**: Create and run a migration script to update existing Firestore documents before deploying code changes.

**Files to Create**:
- `scripts/migrate_visits.js` - Node.js migration script using Firebase Admin SDK

**Migration Actions**:
1. Remove `added_at` field from all visit documents
2. Add `visited_at` field using `created_at` value for existing visits
3. Add `planned` field as `false` for all existing visits
4. **Add county/region and country to addresses**:
   - For visits with `place_address` but missing `county` or `country`:
     - Use reverse geocoding (Nominatim API) to look up address components
     - Use coordinates from `gps_known` (preferred) or `gps_recorded`
     - Extract county/region and country from geocoding response
     - Update address fields with missing data

**Security Setup**:
The migration script requires Firebase Admin SDK which bypasses Firestore security rules. To run the script:

1. **Get Firebase Admin Service Account Key**:
   - Go to Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save the JSON file securely (e.g., `firebase-admin-key.json`)
   - **DO NOT commit this file to version control** - add to `.gitignore`

2. **Set Environment Variable**:
   ```bash
   export GOOGLE_APPLICATION_CREDENTIALS="path/to/firebase-admin-key.json"
   ```
   Or pass directly to the script:
   ```bash
   node scripts/migrate_visits.js --key=path/to/firebase-admin-key.json
   ```

3. **Install Dependencies** (if not already installed):
   ```bash
   npm install firebase-admin
   ```

4. **Run Migration**:
   ```bash
   node scripts/migrate_visits.js
   ```

**Script Features**:
- Processes visits in batches to avoid timeout
- Shows progress and statistics
- Dry-run mode to preview changes without applying
- Error handling and logging
- Confirmation prompt before making changes
- **Reverse geocoding** using Nominatim API to fill missing county/region and country:
  - Uses `gps_known` coordinates (preferred) or `gps_recorded`
  - Rate limiting to respect Nominatim usage policy (1 request per second)
  - Extracts county/region and country from geocoding response
  - Only updates addresses that are missing these fields

**Deliverables**:
- Migration script: `scripts/migrate_visits.js`
- Documentation: `scripts/README_MIGRATION.md`
- Security setup instructions (in README)

**See `scripts/README_MIGRATION.md` for detailed instructions on:**
- Getting Firebase Admin service account key
- Running the migration script
- Security considerations
- Troubleshooting

---

### Task 1: Remove `addedAt` and Add `visitedAt` Field to Visit Model
**Priority**: Critical
**Estimated Time**: 30 minutes

**Description**: Remove the redundant `addedAt` field and add new `visitedAt` DateTime and `planned` bool fields to the Visit model.

**Files to Modify**:
- `lib/core/data/models/visit_model.dart`

**Changes Required**:
1. **Remove `addedAt` field** from Visit class (redundant with `createdAt`)
2. Add `visitedAt` field to Visit class (optional DateTime)
3. Add `planned` field to Visit class (required bool, default false)
4. **Update Address class** to include:
   - `county` field (optional String) - county/region/state
   - `country` field (optional String) - country name
   - Update `fromMap`, `toMap`, `copyWith`, equality, and hashCode
5. Update `fromFirestore` factory:
   - Remove `added_at` field reading
   - Read `visited_at` from Firestore:
     - Use `data.containsKey('visited_at')` to check if field exists
     - If field exists: read value (could be null for planned visits)
     - If field doesn't exist: set to null (old visit, will be treated as `createdAt` in business logic)
   - Read `planned` field (default to false if missing)
   - Update address parsing to include `county` and `country`
6. Update `fromMap` factory similarly
7. Update `toMap` method:
   - Remove `added_at` field
   - Include `visited_at` (always include, even if null for new visits)
   - Include `planned` field (always include)
   - Include `county` and `country` in address
8. Update `copyWith` method to remove `addedAt` and add `visitedAt` and `planned`
9. Update equality operator and hashCode to remove `addedAt` and add `visitedAt` and `planned`
10. Update `toFormattedString` to include county and country

**Considerations**:
- `visitedAt` should be optional (nullable) to maintain backward compatibility
- **Firestore distinguishes between missing fields and null values**:
  - Missing field: Old visit (created before this feature) - use `data.containsKey('visited_at')` to detect
  - Field exists with `null`: Planned visit (user marked as "Planned")
  - Field exists with value: Visit with specific date/time
- For existing visits without `visitedAt` field: treat as if `visitedAt == createdAt` (backward compatibility)
- When saving via GPS location (current flow): `visitedAt` should default to current time
- `planned` field is always required (default false) to distinguish planned visits
- When saving via search: `visitedAt` should be set to user-selected date/time, or `null` if marked as "Planned"
- In `fromFirestore` and `fromMap`: Use `data.containsKey('visited_at')` to check if field exists, then handle null vs missing appropriately
- **Address model changes**:
  - `county` field (optional) - stores county/region/state
  - `country` field (optional) - stores country name
  - These fields will be populated from Overpass API when available, or via reverse geocoding during migration

**Deliverables**:
- Updated Visit model with `visitedAt` and `planned` fields
- Removed `addedAt` field
- Firestore serialization/deserialization
- Updated unit tests

---

### Task 1b: Update Code Using `addedAt` Field
**Priority**: Critical
**Estimated Time**: 30 minutes

**Description**: Update all code that references `addedAt` to use `createdAt` instead.

**Files to Modify**:
- `lib/core/data/repositories/visit_repository.dart` - Change `orderBy('added_at')` to `orderBy('created_at')`
- `lib/features/visits/domain/view_models/record_visit_view_model.dart` - Remove `addedAt` from `_buildVisit`
- `lib/features/home/presentation/screens/home_screen.dart` - Change `visit.addedAt` to `visit.createdAt` (or `visit.visitedAt ?? visit.createdAt` for display)

**Changes Required**:
1. Update repository query ordering from `added_at` to `created_at`
2. Remove `addedAt` parameter from `_buildVisit` method
3. Update UI display to show `visitedAt ?? createdAt` (prefer visitedAt if available, fallback to createdAt)
4. Update all tests that reference `addedAt`

**Deliverables**:
- All `addedAt` references removed
- Code uses `createdAt` or `visitedAt` as appropriate
- Updated tests

---

### Task 2: Extend OverpassClient with Name/Address Search
**Priority**: High
**Estimated Time**: 1-2 hours

**Description**: Add a method to OverpassClient that searches for places by name/address instead of coordinates.

**Files to Modify**:
- `lib/core/api/overpass_client.dart`

**New Method**:
- `searchPlacesByName(String query)` - Search for places matching the query string

**Overpass Query Strategy**:
Overpass API supports searching by name using the `name` tag. The query should:
1. Search for nodes, ways, and relations with matching name
2. Filter by the same place tags (amenity, tourism, historic, leisure, shop, craft, office, public_transport)
3. Use case-insensitive regex matching for the name
4. Optionally search in `addr:city` and `addr:street` for address-based queries

**Example Overpass Query**:
```overpass
[out:json][timeout:25];
(
  node["name"~"Bag of Nails",i]["amenity"~"."];
  way["name"~"Bag of Nails",i]["amenity"~"."];
  relation["name"~"Bag of Nails",i]["amenity"~"."];
);
out center tags;
```

**Considerations**:
- Handle queries that include city names (e.g., "Bag of Nails, Glasgow")
  - Option 1: Parse query to extract city and add city filter
  - Option 2: Use broader search and filter results client-side
  - Option 3: Use Nominatim geocoding service first to get coordinates, then use existing `findNearbyPlaces`
- Handle partial matches and fuzzy search
- Limit results to reasonable number (e.g., 50)
- Handle empty results gracefully
- Error handling for network issues and API errors

**Alternative Approach** (if Overpass name search is insufficient):
- Use Nominatim API for geocoding (converts name/address to coordinates)
- Then use existing `findNearbyPlaces` with those coordinates and a larger radius
- This approach leverages existing code but adds Nominatim dependency

**Deliverables**:
- New `searchPlacesByName` method in OverpassClient
- Query building for name-based search
- Error handling
- Unit tests with mocked HTTP client

---

### Task 3: Add Date/Time Picker to Record Visit Screen
**Priority**: High
**Estimated Time**: 1-2 hours

**Description**: Add date and time selection fields to the record visit screen. These should be visible and editable when using search functionality.

**Files to Modify**:
- `lib/features/visits/presentation/screens/record_visit_screen.dart`

**UI Changes**:
1. Add a new section for "Visit Date & Time" after the place name field
2. Include:
   - Date picker (shows date selector)
   - Time picker (shows time selector)
   - Checkbox or toggle for "Planned Visit" (sets `visitedAt` to null)
3. Default values:
   - When using GPS location: current date/time (read-only or hidden)
   - When using search: current date/time (editable)
4. Use Flutter's built-in date/time pickers:
   - `showDatePicker` for date selection
   - `showTimePicker` for time selection

**Considerations**:
- Date/time fields should only be visible/editable when using search mode
- Or: Always show but only editable in search mode
- Or: Show a toggle to enable "Set custom date/time"
- Default to current date/time for backward compatibility
- "Planned Visit" checkbox: When checked, `visitedAt` should be set to `null` (not omitted from Firestore)
- This allows distinguishing planned visits (null) from old visits (missing field)
- Allow future dates for planned visits

**Deliverables**:
- Date picker widget
- Time picker widget
- Integration with form validation
- UI/UX consistent with existing design

---

### Task 4: Add Search Button and Functionality to UI
**Priority**: High
**Estimated Time**: 1-2 hours

**Description**: Add a search button next to the place name text field and implement the search functionality.

**Files to Modify**:
- `lib/features/visits/presentation/screens/record_visit_screen.dart`
- `lib/features/visits/domain/view_models/record_visit_view_model.dart`

**UI Changes**:
1. Modify `_ManualEntrySection` to include:
   - Text field for place name (existing)
   - Search button (new) - icon button or text button next to the text field
2. When search button is clicked:
   - Validate that text field is not empty
   - Show loading indicator
   - Call ViewModel search method
   - Display results in the same `PlaceSuggestionsList` widget used for location-based suggestions

**ViewModel Changes**:
1. Add new state:
   - `bool _isSearching` - whether a search is in progress
   - `bool _isSearchMode` - whether user is in search mode vs location mode
2. Add new method:
   - `Future<void> searchPlacesByName(String query)` - searches for places by name
3. Modify existing methods:
   - Update `_fetchSuggestions` or create separate method for search results
   - Ensure search results populate the same `_suggestions` list
4. Add date/time state:
   - `DateTime? _visitedAt` - the selected visit date/time
   - `void updateVisitedAt(DateTime dateTime)` - update the visit date/time
5. Update `_buildVisit` to use `_visitedAt` instead of `now` for `visitedAt` field

**Considerations**:
- Search results should replace location-based suggestions when in search mode
- Clear location-based suggestions when search is performed
- Handle search errors (no results, network errors, etc.)
- Show appropriate loading states
- Allow user to clear search and return to location-based mode

**Deliverables**:
- Search button in UI
- Search functionality in ViewModel
- Integration with existing suggestions list
- Error handling and loading states

---

### Task 5: Update Visit Saving Logic
**Priority**: High
**Estimated Time**: 30 minutes

**Description**: Update the visit saving logic to use the `visitedAt` field and handle search-based visits differently from location-based visits.

**Files to Modify**:
- `lib/features/visits/domain/view_models/record_visit_view_model.dart`

**Changes Required**:
1. Update `_buildVisit` method:
   - For `visitedAt` field:
     - If `_visitedAt` is explicitly set (not null): use that value
     - If `_visitedAt` is null and user marked as "Planned": set to `null` (will be stored in Firestore)
     - If `_visitedAt` is null and not planned: default to `DateTime.now()` (GPS location mode)
   - Keep `createdAt`, `updatedAt` as current time (when record is added)
   - When search result is selected, ensure full address from Overpass is used
   - Update `_parseAddress` method to extract `addr:county`/`addr:state` and `addr:country` from Overpass tags when available
2. Update `canSave` getter if needed:
   - Ensure place name is required
   - Location may not be required when using search mode
3. Handle `gpsRecorded` field:
   - When using search: `gpsRecorded` should be null (user wasn't at location)
   - When using GPS location: `gpsRecorded` should be current location
4. Add state for "Planned Visit" flag:
   - `bool _isPlannedVisit` - whether user marked visit as planned
   - `void setPlannedVisit(bool isPlanned)` - update the planned flag

**Considerations**:
- `visitedAt` should default to current time if not set
- `gpsRecorded` should be null for search-based visits
- `gpsKnown` should always be populated from Overpass result (both modes)
- Full address from Overpass should always be used when available

**Deliverables**:
- Updated visit building logic
- Proper handling of `visitedAt` field
- Correct GPS field handling for search vs location modes

---

### Task 6: Update Validation and Error Handling
**Priority**: Medium
**Estimated Time**: 30 minutes

**Description**: Update form validation to handle both location-based and search-based visit creation.

**Files to Modify**:
- `lib/features/visits/presentation/screens/record_visit_screen.dart`
- `lib/features/visits/domain/view_models/record_visit_view_model.dart`

**Changes Required**:
1. Update `canSave` logic:
   - Location-based: requires place name AND current location
   - Search-based: requires place name AND selected suggestion (location not required)
2. Update error messages to be context-aware
3. Handle search-specific errors:
   - No results found
   - Network errors during search
   - Invalid search query

**Considerations**:
- Different validation rules for different modes
- Clear error messages for users
- Graceful degradation if search fails

**Deliverables**:
- Updated validation logic
- Context-aware error messages
- Error handling for search failures

---

## Technical Considerations

### Overpass API Name Search
- Overpass API supports regex matching on the `name` tag
- Can search across multiple tags (name, addr:city, addr:street)
- May need to handle city name parsing (e.g., "Bag of Nails, Glasgow")
- Consider using Nominatim for geocoding if Overpass name search is insufficient

### Backward Compatibility
- Existing visits without `visitedAt` field should still work
- **Firestore Field Distinction**:
  - Missing field (`!data.containsKey('visited_at')`): Old visit created before this feature
  - Field with `null` value: Planned visit (user marked as "Planned")
  - Field with value: Visit with specific date/time
- In business logic, treat missing field as if `visitedAt == createdAt` for display purposes
- Ensure Firestore queries don't break with new field
- When reading old visits: check `containsKey()` to distinguish missing vs null

### Data Migration
- Existing visits in Firestore won't have `visited_at` field (missing, not null)
- This is acceptable as the field is optional
- No migration script needed initially
- New visits will always include `visited_at` field (even if null for planned visits)

### UI/UX Considerations
- Search button should be clearly visible and accessible
- Date/time pickers should be intuitive
- Loading states should be clear
- Error messages should be helpful
- Consider adding a toggle between "Current Location" and "Search" modes

---

## Testing Requirements

### Unit Tests
1. Visit model with `visitedAt` field (serialization/deserialization):
   - Test missing field (old visit)
   - Test null field (planned visit)
   - Test value field (specific date/time)
   - Verify `containsKey()` usage in `fromFirestore` and `fromMap`
2. OverpassClient name search method
3. ViewModel search functionality
4. Visit building logic with `visitedAt`:
   - Test GPS location mode (defaults to now)
   - Test search mode with date/time
   - Test planned visit (null value)

### Integration Tests
1. Search flow end-to-end
2. Date/time selection and saving
3. Address extraction from search results

### Manual Testing
1. Search for various place names
2. Search with city names
3. Set custom date/time
4. Mark visit as "Planned" (verify `visited_at` is null in Firestore, not missing)
5. Verify saved visit has correct `visitedAt`
6. Verify address is correctly saved
7. Test error scenarios (no results, network errors)
8. Verify old visits (without field) still display correctly

---

## Dependencies

- No new external dependencies required (using existing Overpass API)
- If Nominatim is used, may need to add HTTP client for Nominatim API
- Flutter date/time pickers are built-in

---

## Future Enhancements

1. **Search History**: Remember recent searches
2. **Autocomplete**: Show suggestions as user types
3. **Fuzzy Matching**: Improve search results with fuzzy matching
4. **Search Filters**: Filter by place type, city, etc.
5. **Map Preview**: Show search results on a map
6. **Multiple Results Handling**: Better UI for handling many search results

---

## Summary

This feature adds the ability to search for places by name/address, enabling users to record historical visits with custom date/time. The implementation involves:

1. Adding `visitedAt` field to Visit model
2. Extending OverpassClient with name search
3. Adding date/time pickers to UI
4. Adding search button and functionality
5. Updating visit saving logic
6. Updating validation and error handling

The feature maintains backward compatibility and integrates seamlessly with the existing location-based visit recording flow.

