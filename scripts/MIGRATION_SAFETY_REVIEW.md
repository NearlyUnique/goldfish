# Migration Script Safety Review

## Review Date
Review conducted for migration script `migrate_visits.js` handling <50 visits for 2 test users.

## Safety Improvements Made

### 1. JSON Output of All Database Data
- **Added**: Script now outputs all documents as JSON to stdout in both dry-run and apply modes
- **Location**: Output appears before processing begins
- **Format**: Clean JSON with Firestore Timestamps converted to ISO strings and GeoPoints normalized
- **Purpose**: Enables auditing, debugging, and verification of data before/after migration

### 2. Document Validation
- **Added**: `validateDocument()` function that checks for required fields before processing
- **Validates**:
  - `user_id` is present
  - `place_name` is present
  - `created_at` is present
  - `updated_at` is present
  - GPS coordinates are valid (if present)
- **Behaviour**: Documents with validation errors are skipped and counted in error statistics

### 3. Database Connection Testing
- **Added**: `testConnection()` function that verifies Firestore access before migration starts
- **Checks**: Service account permissions and network connectivity
- **Failure**: Script exits early if connection fails, preventing partial migrations

### 4. Improved Error Handling
- **Enhanced**: Better error messages for credential issues
- **Added**: Validation of geocoding API responses
- **Added**: Coordinate range validation (-90 to 90 for lat, -180 to 180 for lon)
- **Improved**: Error statistics tracking (validation errors, geocoding errors)

### 5. Post-Migration Verification
- **Added**: Sample verification of updated documents after migration completes
- **Checks**: Verifies that `added_at` was removed and `visited_at`/`planned` were added
- **Sample Size**: Up to 5 documents (or all if fewer than 5 were updated)

### 6. Coordinate Handling
- **Added**: `getLongitude()` helper function that handles both `long` and `lng` field names
- **Purpose**: Firestore GeoPoint objects may use either naming convention

### 7. Better Initialization Error Handling
- **Enhanced**: More specific error messages for:
  - Missing service account key file
  - Invalid JSON in service account key
  - File system errors

## Failure Modes Addressed

### Network Failures
- **Geocoding API failures**: Caught and logged, script continues with other documents
- **Firestore connection failures**: Detected early via `testConnection()`, script exits before making changes
- **Firestore update failures**: Caught per-document, logged, counted in statistics

### Data Integrity Issues
- **Missing required fields**: Detected via validation, document skipped
- **Invalid coordinates**: Validated before geocoding, prevents API errors
- **Malformed documents**: Validation catches structural issues before processing

### Partial Migration Risks
- **Small dataset (<50 visits)**: Low risk of partial failures
- **Batch processing**: Processes in configurable batches (default 500, but with <50 visits, all processed together)
- **Error tracking**: All errors are logged and counted, allowing manual review

### Geocoding API Issues
- **Rate limiting**: Already implemented (1 request/second)
- **Invalid responses**: Now validated before processing
- **Timeout**: Already handled (10 second timeout)
- **Missing data**: Gracefully handled, script continues

## Remaining Considerations

### Low Risk (Given Small Dataset)

1. **No Backup Mechanism**
   - **Risk**: Low - only 2 users, <50 visits
   - **Mitigation**: JSON output provides audit trail
   - **Recommendation**: For production with more data, consider exporting before migration

2. **No Rollback Mechanism**
   - **Risk**: Low - migration is additive (adds fields, removes one redundant field)
   - **Mitigation**: Can manually restore `added_at` if needed (though it's redundant)
   - **Recommendation**: For production, consider transaction-based updates or backup/restore

3. **Geocoding Failures Don't Block Migration**
   - **Risk**: Low - address enhancement is optional
   - **Behaviour**: Documents are still migrated even if geocoding fails
   - **Acceptable**: Core migration (removing `added_at`, adding `visited_at`/`planned`) succeeds

### Medium Risk

1. **Service Account Permissions**
   - **Risk**: If service account lacks write permissions, updates will fail
   - **Mitigation**: `testConnection()` checks read permissions, but not write
   - **Recommendation**: Test with a single document first in dry-run mode

2. **Concurrent Modifications**
   - **Risk**: If app is running during migration, concurrent writes could conflict
   - **Mitigation**: Script processes documents sequentially
   - **Recommendation**: Run migration during low-usage period or with app paused

## Testing Recommendations

1. **Dry-Run First**: Always run without `--apply` first to review changes
2. **Review JSON Output**: Check the JSON output to verify data structure
3. **Test with One Document**: Consider testing with a single document first
4. **Verify Results**: Check the verification output after migration completes

## Usage Safety Checklist

- [ ] Run dry-run first: `node scripts/migrate_visits.js`
- [ ] Review JSON output to understand current data structure
- [ ] Verify service account has read/write permissions
- [ ] Ensure app is not actively writing to Firestore during migration
- [ ] Review statistics after dry-run
- [ ] Run with `--apply` only after confirming dry-run results
- [ ] Verify sample documents after migration completes

## Summary

The migration script is now safer with:
- ✅ JSON output for auditing
- ✅ Document validation before processing
- ✅ Connection testing before migration
- ✅ Better error handling and reporting
- ✅ Post-migration verification
- ✅ Improved coordinate handling

Given the small dataset (<50 visits, 2 users), the script is safe to run. The improvements provide better visibility, error handling, and verification capabilities.

