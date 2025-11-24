# Goldfish - Visit Tracking App

## Project Overview

A mobile app (Android 13 and above) designed to make it easy to record visits to pubs, bars, restaurants, and places of interest. Users can find places nearby they've visited before, attach photos and text notes, and view their visit history. The app prioritizes simplicity, ease of use, and efficient screen space utilization across all device sizes.

## Core Principles

- **Simplicity**: Clean, intuitive interface with minimal cognitive load
- **Screen Efficiency**: Maximize use of available screen space, responsive to all screen sizes
- **Offline-First**: Core functionality works without internet connection
- **Minimal Dependencies**: Prefer built-in Flutter/Dart capabilities, avoid external APIs where possible
- **Privacy-Focused**: User data stored securely, user controls data sharing
- **Undo Over Confirmation**: No "Are you sure?" dialogs. Actions execute immediately with undo capability. Use SnackBar with undo action for destructive operations. Only use confirmations for truly irreversible actions (e.g., data export that overwrites files)

## Technical Stack

- **Framework**: Flutter (Dart)
- **Platform**: Android 13+ (API level 33+)
- **State Management**: Built-in Flutter solutions (ValueNotifier, ChangeNotifier, or MVVM pattern)
- **Storage**: 
  - Local: SQLite (via `sqflite`) for offline-first data storage
  - Cloud: Firebase Firestore or similar cloud storage (minimal API usage)
- **Location**: `geolocator` package for location services
- **Images**: Local storage with cloud sync capability
- **Navigation**: `go_router` for declarative routing

## Data Model

### Visit
- **id**: Unique identifier (UUID)
- **placeName**: String (required)
- **placeAddress**: String (optional)
- **latitude**: double (required)
- **longitude**: double (required)
- **visitDate**: DateTime (required)
- **notes**: String (optional, multi-line text)
- **photos**: List<String> (paths/URLs to photo files)
- **tags**: List<String> (optional, for categorization)
- **rating**: int? (optional, 1-5 scale)
- **createdAt**: DateTime (auto-generated)
- **updatedAt**: DateTime (auto-generated)
- **synced**: bool (track cloud sync status)
- **deletedAt**: DateTime? (for soft delete, supports undo functionality)

### Place (Aggregated from Visits)
- Derived from visits, showing unique places with visit count
- Most recent visit date
- Total number of visits

## Feature Breakdown

### Feature 1: Record a New Visit
**Priority**: High  
**Description**: Allow users to quickly record a visit to a location.

**Requirements**:
- Quick access button (FAB or prominent button) to start recording
- Location capture:
  - Use current GPS location as default
  - Allow manual location selection on map
  - Display address from reverse geocoding
- Place name input (required field)
- Optional fields:
  - Notes (multi-line text input)
  - Rating (1-5 stars)
  - Tags (comma-separated or chip-based input)
- Photo attachment:
  - Camera capture
  - Gallery selection
  - Multiple photos per visit
  - Photo preview with delete option
- Save button stores visit locally
- Confirmation feedback after save
- Auto-sync to cloud in background (if available)

**UI Considerations**:
- Form should be scrollable
- Use bottom sheet or full-screen modal
- Minimize required fields for quick entry
- Large touch targets for mobile use

---

### Feature 2: View Visit History
**Priority**: High  
**Description**: Display a list of all recorded visits, sortable and filterable.

**Requirements**:
- List view of all visits:
  - Place name
  - Visit date (formatted: "2 days ago", "Jan 15, 2024")
  - First photo as thumbnail (if available)
  - Rating stars (if provided)
- Sorting options:
  - Most recent first (default)
  - Oldest first
  - By place name (alphabetical)
  - By rating (highest first)
- Filtering options:
  - By date range (calendar picker)
  - By tags
  - By rating
  - By place name (search)
- Pull-to-refresh for sync
- Infinite scroll or pagination for large lists
- Empty state when no visits exist

**UI Considerations**:
- Card-based layout for each visit
- Responsive grid/list toggle for different screen sizes
- Efficient use of screen space
- Fast scrolling performance

---

### Feature 3: View Visit Details
**Priority**: High  
**Description**: Show full details of a single visit with all associated data.

**Requirements**:
- Display all visit information:
  - Place name (large, prominent)
  - Address
  - Visit date and time
  - Notes (if provided)
  - Rating (if provided)
  - Tags (as chips)
  - All photos (gallery view with zoom)
- Map view showing visit location
- Edit visit capability
- Delete visit capability (immediate with undo via SnackBar)
- Share visit (export as text/image)

**UI Considerations**:
- Scrollable detail view
- Photo gallery with swipe navigation
- Map takes reasonable portion of screen
- Edit/delete actions in app bar or bottom sheet

---

### Feature 4: Find Nearby Places
**Priority**: High  
**Description**: Show places the user has visited that are near their current location.

**Requirements**:
- Request location permissions
- Get current location
- Calculate distances to all visited places
- Display nearby places sorted by distance:
  - Place name
  - Distance (e.g., "0.5 km away")
  - Number of visits
  - Last visit date
  - Thumbnail photo
- Distance threshold filter (e.g., within 1km, 5km, 10km, 25km)
- Map view option showing:
  - Current location marker
  - Nearby visited places as markers
  - Tap marker to see place details
- Refresh location button
- Navigate to place (open in maps app)

**UI Considerations**:
- Distance prominently displayed
- Map view should be toggleable
- List and map views both available
- Clear indication of current location accuracy

---

### Feature 5: Places List (Unique Locations)
**Priority**: Medium  
**Description**: View all unique places visited, aggregated by location.

**Requirements**:
- List of unique places (deduplicated by location)
- For each place:
  - Place name
  - Address
  - Total visit count
  - Most recent visit date
  - Average rating (if ratings provided)
  - Thumbnail from most recent visit
- Sort by:
  - Most visited
  - Most recent visit
  - Alphabetical
  - Average rating
- Filter by tags
- Search by place name
- Tap to see all visits to that place

**UI Considerations**:
- Group visits by place
- Show visit frequency prominently
- Efficient list rendering

---

### Feature 6: Map View of All Visits
**Priority**: Medium  
**Description**: Visualize all visits on an interactive map.

**Requirements**:
- Display all visit locations as markers on map
- Cluster markers when zoomed out
- Different marker styles for:
  - Single visit locations
  - Multiple visit locations (show count)
- Tap marker to see place name and visit count
- Tap marker detail to navigate to visit details
- Map controls:
  - Zoom to show all visits
  - Filter by date range
  - Filter by tags
- Current location indicator (optional)

**UI Considerations**:
- Full-screen map option
- Overlay controls that don't obstruct map
- Smooth map interactions
- Efficient marker rendering

---

### Feature 7: Statistics and Insights
**Priority**: Low  
**Description**: Provide summary statistics about visits.

**Requirements**:
- Total number of visits
- Total number of unique places
- Most visited place
- Visit frequency over time (simple chart)
- Average visits per month/week
- Total distance traveled (sum of distances between visits)
- Most common tags
- Rating distribution (if ratings used)

**UI Considerations**:
- Card-based layout for each statistic
- Simple, readable charts
- Scrollable view for all stats

---

### Feature 8: Search Functionality
**Priority**: Medium  
**Description**: Global search across all visits and places.

**Requirements**:
- Search bar in app bar or dedicated search screen
- Search by:
  - Place name
  - Address
  - Notes content
  - Tags
- Real-time search results as user types
- Highlight matching text in results
- Navigate to visit/place from results

**UI Considerations**:
- Prominent search entry point
- Fast search performance
- Clear result highlighting

---

### Feature 9: Photo Management
**Priority**: Medium  
**Description**: Manage photos attached to visits.

**Requirements**:
- View all photos in gallery
- Delete photos from visits (immediate with undo via SnackBar)
- Add photos to existing visits
- Photo compression for storage efficiency
- Thumbnail generation for performance
- Full-screen photo viewer with zoom
- Share individual photos

**UI Considerations**:
- Grid layout for photo gallery
- Fast thumbnail loading
- Smooth zoom/pan interactions

---

### Feature 10: Data Export/Import
**Priority**: Low  
**Description**: Allow users to backup and restore their data.

**Requirements**:
- Export all data to JSON file
- Export photos as zip file
- Import data from JSON
- Share export file
- Cloud backup/restore (if cloud storage used)

**UI Considerations**:
- Clear export/import buttons in settings
- Progress indicator for large exports
- Import executes immediately (with undo option if overwriting existing data)
- Only show confirmation if import would overwrite existing data and user hasn't explicitly chosen to replace

---

### Feature 11: Settings
**Priority**: Low  
**Description**: App configuration and preferences.

**Requirements**:
- Location permission status and request
- Storage usage information
- Cloud sync status and manual sync trigger
- Default distance threshold for nearby places
- Theme preferences (light/dark/system)
- Data export/import
- About/help information
- Clear all data option (immediate with undo via SnackBar, undo available for limited time window)

**UI Considerations**:
- Standard settings list layout
- Clear section grouping
- Toggle switches for boolean preferences

---

### Feature 12: Cloud Sync
**Priority**: Medium  
**Description**: Synchronize data across devices via cloud storage.

**Requirements**:
- Background sync when internet available
- Manual sync trigger
- Conflict resolution (last write wins or user choice)
- Sync status indicator
- Sync only on WiFi option
- Handle offline changes gracefully

**UI Considerations**:
- Subtle sync status indicator
- Sync progress for manual sync
- Error messages for sync failures

## UI/UX Guidelines

### Layout Principles
- **Responsive Design**: Use `LayoutBuilder` and `MediaQuery` for all screen sizes
- **No Assumptions**: Support phones, tablets, foldables, all orientations
- **Screen Efficiency**: Minimize whitespace, maximize content area
- **Touch Targets**: Minimum 48x48 logical pixels for interactive elements
- **Navigation**: Bottom navigation bar or drawer for main sections

### Visual Design
- **Material Design 3**: Follow Material 3 design system
- **Color Scheme**: Use `ColorScheme.fromSeed()` for consistent theming
- **Typography**: Clear hierarchy, readable font sizes
- **Dark Mode**: Full support for light and dark themes
- **Icons**: Use Material icons, add custom icons only when necessary

### Performance
- **Lazy Loading**: Use `ListView.builder` for long lists
- **Image Optimization**: Compress and cache images
- **Database Queries**: Efficient queries with proper indexing
- **Background Processing**: Use isolates for heavy computations

### Undo Pattern
- **Immediate Actions**: All user actions execute immediately without confirmation dialogs
- **Undo via SnackBar**: Use Material `SnackBar` with action button for undo
  - Display for 4-5 seconds (standard SnackBar duration)
  - Undo action restores previous state
  - SnackBar dismisses automatically or when undo is tapped
- **Undo Implementation**:
  - Keep deleted items in memory/cache for undo window
  - Use soft delete pattern: mark as deleted, actually remove after undo window expires
  - For edits: store previous state, restore on undo
- **Undo Scope**:
  - Delete visit: Undo restores visit and all associated data
  - Delete photo: Undo restores photo to visit
  - Edit visit: Undo reverts to previous values
  - Clear all data: Undo restores all data (keep backup for undo window)
- **Exceptions**: Only use confirmation dialogs for:
  - Actions that affect external systems (exporting files that might overwrite)
  - Actions that cannot be undone (e.g., permanently deleting cloud backups)
  - First-time destructive actions (e.g., first time clearing all data, with option to "Don't ask again")

## Implementation Phases

### Phase 1: Core Functionality
1. Data model and local database setup
2. Record a new visit (Feature 1)
3. View visit history (Feature 2)
4. View visit details (Feature 3)

### Phase 2: Location Features
5. Find nearby places (Feature 4)
6. Map view of all visits (Feature 6)

### Phase 3: Enhanced Features
7. Places list (Feature 5)
8. Search functionality (Feature 8)
9. Photo management (Feature 9)

### Phase 4: Polish and Extras
10. Statistics and insights (Feature 7)
11. Settings (Feature 11)
12. Cloud sync (Feature 12)
13. Data export/import (Feature 10)

## Technical Considerations

### Permissions
- Location (foreground and background)
- Camera
- Storage/Photos
- Internet (for cloud sync)

### Error Handling
- Network errors (graceful degradation)
- Location unavailable
- Storage full
- Permission denied

### Testing
- Unit tests for data models and business logic
- Widget tests for UI components
- Integration tests for critical user flows

## Notes for LLM Implementation

When implementing features:
1. Extract one feature at a time from this document
2. Follow Flutter best practices from `.cursor/rules/flutter.mdc`
3. Implement responsive layouts that work on all screen sizes
4. Use local storage first, cloud sync as enhancement
5. Prioritize user experience and simplicity
6. Test on different screen sizes and orientations
7. Handle edge cases (no location, no photos, offline mode)
8. Provide clear feedback for user actions
9. Use Material 3 components and theming
10. Follow the established data model structure
11. **CRITICAL**: Implement undo for all destructive actions using SnackBar pattern - NO confirmation dialogs
12. Actions should feel instant and reversible - use soft deletes and state restoration for undo