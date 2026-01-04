# Visit Migration Script

This script migrates existing Visit documents in Firestore to the new schema:

- **Removes** `added_at` field (redundant with `created_at`)
- **Adds** `visited_at` field using `created_at` value
- **Adds** `planned` field as `false`
- **Adds missing address fields**: Uses reverse geocoding to add `county`/`region` and `country` to addresses that are missing these fields

## Prerequisites

1. **Node.js** installed (v14 or higher)
2. **Firebase Admin SDK** service account key

## Getting the Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **Service Accounts**
4. Click **Generate New Private Key**
5. Save the JSON file securely (e.g., `firebase-admin-key.json`)
6. **DO NOT commit this file to version control**

## Installation

Install required dependencies:

```bash
npm install firebase-admin
```

## Usage

### Option 1: Using command line argument

```bash
node scripts/migrate_visits.js --key=path/to/firebase-admin-key.json
```

### Option 2: Using environment variable

```bash
export GOOGLE_APPLICATION_CREDENTIALS="path/to/firebase-admin-key.json"
node scripts/migrate_visits.js
```

### Dry Run (Preview Changes)

To preview what changes will be made without actually applying them:

```bash
node scripts/migrate_visits.js --key=path/to/firebase-admin-key.json --dry-run
```

### Custom Batch Size

By default, the script processes 500 documents at a time. To change this:

```bash
node scripts/migrate_visits.js --key=path/to/firebase-admin-key.json --batch-size=1000
```

## Security Considerations

⚠️ **IMPORTANT**: The Firebase Admin SDK bypasses Firestore security rules. This script has full read/write access to your Firestore database.

1. **Never commit** the service account key JSON file to version control
2. **Store the key securely** and limit access
3. **Use dry-run mode first** to preview changes
4. **Backup your database** before running the migration
5. **Run during low-traffic periods** if possible

## What the Script Does

1. Connects to Firestore using Admin SDK
2. Fetches all documents from the `visits` collection
3. For each document:
   - Removes `added_at` field if present
   - Adds `visited_at` field using `created_at` value (if missing)
   - Adds `planned` field as `false` (if missing)
   - **For addresses missing county/region or country**:
     - Uses reverse geocoding (Nominatim API) to look up address components
     - Uses coordinates from `gps_known` (preferred) or `gps_recorded`
     - Extracts county/region and country from geocoding response
     - Updates address fields with missing data
4. Processes documents in batches to avoid timeouts
5. Shows progress and statistics

**Note**: Reverse geocoding uses Nominatim API with rate limiting (1 request per second). This may significantly increase migration time if many addresses need to be geocoded. The script will show statistics on how many addresses were geocoded.

## Output

The script provides:
- Progress updates during migration
- Final statistics:
  - Total documents found
  - Documents processed
  - Documents updated
  - Documents skipped (already migrated)
  - Errors encountered
  - Addresses geocoded (county/region or country added)
  - Geocoding errors encountered

## Troubleshooting

### "Firebase Admin credentials not found"

Make sure you've provided credentials using either:
- `--key=path/to/key.json` argument, or
- `GOOGLE_APPLICATION_CREDENTIALS` environment variable

### "Permission denied"

Ensure the service account key has the necessary permissions:
- Cloud Datastore User (or Firestore User)
- Service Account Token Creator

### Network/Timeout Errors

- Reduce batch size: `--batch-size=100`
- Check your internet connection
- Verify Firebase project is accessible

### Geocoding Takes Too Long

The script uses Nominatim API with rate limiting (1 request per second). If you have many addresses to geocode:
- The migration will take longer (approximately 1 second per address that needs geocoding)
- This is expected behavior to respect Nominatim's usage policy
- Consider running during off-peak hours for large datasets
- The script will show progress and statistics on geocoding operations

## Rollback

If you need to rollback the migration, you would need to:
1. Restore from a database backup, or
2. Create a reverse migration script

**Always backup your database before running migrations.**

