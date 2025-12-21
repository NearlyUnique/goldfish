# Snag List - Feature Requests & Bug Fixes

## Feature Requests

### Map & Visualisation
1. **Show place names on map**: Display place names directly on the map markers
2. **Use custom icons on map**: Allow custom icons to be displayed on map markers instead of default pins
3. **Enlarge text on map**: Increase text size for better readability on map view
4. **Move OSM attribution to right**: Reposition OpenStreetMap attribution to the right side of the map
5. **View place from list on map**: Add ability to navigate to and highlight a place on the map from the list view

### Place Management
1. **Add place from map view**: Allow creating new places directly from the map, with search functionality on map
2. **Edit place details**: Enable editing of place information, including date and time
3. **Set custom icon for place**: Allow users to assign custom icons to places
4. **Add text notes to places**: Support adding free-form text notes to places
5. **Add photos to places**: Enable attaching photos to places
6. **Give rating to places**: Add rating system for places (e.g., 1-5 stars)
7. **Tag places**: Implement tagging system for places; location type (e.g., restaurant, bar) should be an automatic tag
8. **Link events to places**: Associate events (cinema, gig, theatre, exhibition) that happened at a location with the place
9. **Attach payment or screenshot**: Provide way to attach or link payment receipts or screenshots to places

### List & Display
1. **Expand place list to show all attributes**: Display all place attributes in the list view
2. **Show more detail on list**: Include additional information in list view (street, city, visit count)
3. **Swipe to soft delete**: Implement swipe gesture to soft delete places from list

### Search & Filter
1. **Search by name, city, tag**: Implement search functionality across place names, cities, and tags
2. **Filter for "noise" in places**: Add filter option to identify and filter out noisy/duplicate places

### Trips
1. **Put places into a Trip**: Group places into trips for better organisation
2. **Collapse trips**: Add collapse/expand functionality for trip sections in the list

### Configuration & Data
1. **Make place types a config list**: Convert place types to a configurable list rather than hardcoded
2. **Use geohash for geoqueries**: Implement geohash-based geoqueries for better performance (see: https://firebase.google.com/docs/firestore/solutions/geoqueries)
3. **Include nearby hand-created places when adding**: When adding a new place, show nearby manually created places

### Map View Enhancements
1. **Add new item list as map view, zoom to 20m**: When adding new items, show map view with zoom level set to 20 metres

## Bug Fixes

_No bug fixes identified in current list. All items appear to be feature requests or UI improvements._

---

## Notes for Triage
- **Prioritisation**: Consider user impact, development effort, and dependencies between features
- **Grouping**: Related features can be implemented together (e.g., map enhancements, place management features)
- **Dependencies**: Some features may depend on others (e.g., tagging system needed before tag-based search)
- **Technical notes**: Geohash implementation requires Firestore geoquery setup
