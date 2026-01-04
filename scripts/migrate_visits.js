#!/usr/bin/env node

/**
 * Migration script for Visit documents in Firestore
 *
 * This script:
 * 1. Removes the `added_at` field (redundant with `created_at`)
 * 2. Adds `visited_at` field using `created_at` value for existing visits
 * 3. Adds `planned` field as `false` for all existing visits
 * 4. Adds missing `county`/`region` and `country` to addresses using reverse geocoding
 *
 * Usage:
 *   node scripts/migrate_visits.js [--key=path/to/service-account-key.json] [--apply] [--batch-size=500]
 *
 * Note: Reverse geocoding uses Nominatim API with rate limiting (1 request/second).
 *       This may significantly increase migration time for large datasets.
 *
 * Environment Variables:
 *   GOOGLE_APPLICATION_CREDENTIALS - Path to Firebase Admin service account key JSON file
 *
 * Security:
 *   This script uses Firebase Admin SDK which bypasses Firestore security rules.
 *   The service account key must be kept secure and never committed to version control.
 */

const admin = require('firebase-admin');
const readline = require('readline');
const https = require('https');
const { URL } = require('url');
const fs = require('fs');
const path = require('path');

// Parse command line arguments
const args = process.argv.slice(2);
const options = {
    key: null,
    dryRun: true,
    batchSize: 500,
};

args.forEach(arg => {
    if (arg.startsWith('--key=')) {
        options.key = arg.split('=')[1];
    } else if (arg === '--apply') {
        options.dryRun = false;
    } else if (arg.startsWith('--batch-size=')) {
        options.batchSize = parseInt(arg.split('=')[1], 10);
    }
});

// Initialize Firebase Admin SDK
let app;
try {
    if (options.key) {
        const keyPath = path.resolve(options.key);
        if (!fs.existsSync(keyPath)) {
            console.error(`Error: Service account key file not found: ${keyPath}`);
            process.exit(1);
        }
        const serviceAccount = require(keyPath);
        app = admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
        });
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
        app = admin.initializeApp({
            credential: admin.credential.applicationDefault(),
        });
    } else {
        console.error('Error: Firebase Admin credentials not found.');
        console.error('Please provide credentials using one of:');
        console.error('  1. --key=path/to/service-account-key.json');
        console.error('  2. GOOGLE_APPLICATION_CREDENTIALS environment variable');
        process.exit(1);
    }
} catch (error) {
    console.error('Error initializing Firebase Admin SDK:', error.message);
    if (error.message.includes('ENOENT')) {
        console.error('Service account key file not found or cannot be read.');
    } else if (error.message.includes('Unexpected token')) {
        console.error('Service account key file is not valid JSON.');
    }
    process.exit(1);
}

const db = admin.firestore();
const COLLECTION = 'visits';

// Test database connection
async function testConnection() {
    try {
        await db.collection(COLLECTION).limit(1).get();
    } catch (error) {
        console.error('Error connecting to Firestore:', error.message);
        if (error.code === 'permission-denied') {
            console.error('Service account does not have permission to read Firestore.');
        }
        process.exit(1);
    }
}

// Statistics
const stats = {
    total: 0,
    processed: 0,
    updated: 0,
    skipped: 0,
    errors: 0,
    geocoded: 0,
    geocodingErrors: 0,
};

// Rate limiting for Nominatim (1 request per second)
let lastGeocodeTime = 0;
const GEOCODE_DELAY_MS = 1000;

/**
 * Reverse geocode coordinates to get address components
 * Uses Nominatim API (OpenStreetMap's geocoding service)
 */
async function reverseGeocode(lat, lon) {
    // Rate limiting: wait if needed
    const now = Date.now();
    const timeSinceLastRequest = now - lastGeocodeTime;
    if (timeSinceLastRequest < GEOCODE_DELAY_MS) {
        await new Promise(resolve => setTimeout(resolve, GEOCODE_DELAY_MS - timeSinceLastRequest));
    }
    lastGeocodeTime = Date.now();

    const url = new URL('https://nominatim.openstreetmap.org/reverse');
    url.searchParams.set('lat', lat.toString());
    url.searchParams.set('lon', lon.toString());
    url.searchParams.set('format', 'json');
    url.searchParams.set('addressdetails', '1');
    url.searchParams.set('zoom', '10'); // Get more detailed address

    return new Promise((resolve, reject) => {
        const request = https.get(url.toString(), {
            headers: {
                'User-Agent': 'Goldfish-Migration-Script/1.0', // Required by Nominatim
            },
        }, (response) => {
            let data = '';

            response.on('data', (chunk) => {
                data += chunk;
            });

            response.on('end', () => {
                if (response.statusCode !== 200) {
                    reject(new Error(`Nominatim API returned status ${response.statusCode}`));
                    return;
                }

                try {
                    const json = JSON.parse(data);
                    resolve(json);
                } catch (error) {
                    reject(new Error(`Failed to parse Nominatim response: ${error.message}`));
                }
            });
        });

        request.on('error', (error) => {
            reject(error);
        });

        request.setTimeout(10000, () => {
            request.destroy();
            reject(new Error('Nominatim API request timeout'));
        });
    });
}

/**
 * Extract latitude from GPS object
 */
function getLatitude(gps) {
    if (!gps || gps.lat === undefined) {
        return null;
    }
    return gps.lat;
}

/**
 * Extract longitude from GPS object
 */
function getLongitude(gps) {
    if (!gps || gps.long === undefined) {
        return null;
    }
    return gps.long;
}

/**
 * Extract county/region and country from Nominatim response
 */
function extractAddressComponents(geocodeResult) {
    const address = geocodeResult.address || {};
    const components = {
        county: null,
        country: null,
    };

    // Try various fields for county/region/state
    // Nominatim uses different field names depending on country
    components.county = address.county ||
        address.state_district ||
        address.region ||
        address.state ||
        null;

    // Country is usually in 'country' field
    components.country = address.country || null;

    return components;
}

/**
 * Convert Firestore Timestamp to ISO string for JSON output
 */
function convertTimestampForJson(value) {
    if (value && typeof value.toDate === 'function') {
        return value.toDate().toISOString();
    }
    if (value && value.seconds !== undefined) {
        return new Date(value.seconds * 1000).toISOString();
    }
    return value;
}

/**
 * Convert Firestore document to plain JSON object
 */
function docToJson(doc) {
    const data = doc.data();
    const json = {
        id: doc.id,
        ...data,
    };

    // Convert Timestamps to ISO strings
    const timestampFields = ['added_at', 'created_at', 'updated_at', 'visited_at'];
    timestampFields.forEach(field => {
        if (json[field]) {
            json[field] = convertTimestampForJson(json[field]);
        }
    });

    // Convert nested GeoPoint objects
    ['gps_recorded', 'gps_known'].forEach(field => {
        if (json[field] && json[field].lat !== undefined) {
            json[field] = {
                lat: json[field].lat,
                long: json[field].long,
            };
        }
    });

    return json;
}

/**
 * Validate document structure before migration
 */
function validateDocument(doc) {
    const data = doc.data();
    const errors = [];

    if (!data.user_id) {
        errors.push('Missing required field: user_id');
    }
    if (!data.place_name) {
        errors.push('Missing required field: place_name');
    }
    if (!data.created_at) {
        errors.push('Missing required field: created_at');
    }
    if (!data.updated_at) {
        errors.push('Missing required field: updated_at');
    }

    // Validate GPS coordinates if present
    if (data.gps_known) {
        const lat = getLatitude(data.gps_known);
        const lon = getLongitude(data.gps_known);
        if (lat === null || typeof lat !== 'number' || lon === null || typeof lon !== 'number') {
            errors.push('Invalid gps_known coordinates');
        }
    }
    if (data.gps_recorded) {
        const lat = getLatitude(data.gps_recorded);
        const lon = getLongitude(data.gps_recorded);
        if (lat === null || typeof lat !== 'number' || lon === null || typeof lon !== 'number') {
            errors.push('Invalid gps_recorded coordinates');
        }
    }

    return errors;
}

/**
 * Migrate a single visit document
 */
async function migrateVisit(doc) {
    const data = doc.data();
    const updates = {};
    let needsUpdate = false;

    // Validate document structure
    const validationErrors = validateDocument(doc);
    if (validationErrors.length > 0) {
        console.warn(`  Warning: Document ${doc.id} has validation errors:`, validationErrors);
        stats.errors++;
        return false;
    }

    // Check if document has added_at field (needs removal)
    if ('added_at' in data) {
        updates['added_at'] = admin.firestore.FieldValue.delete();
        needsUpdate = true;
    }

    // Check if document is missing visited_at field
    if (!('visited_at' in data)) {
        // Use created_at value for visited_at
        if (data.created_at) {
            updates['visited_at'] = data.created_at;
            needsUpdate = true;
        } else {
            console.warn(`  Warning: Document ${doc.id} has no created_at field`);
            stats.errors++;
            return false;
        }
    }

    // Check if document is missing planned field
    if (!('planned' in data)) {
        updates['planned'] = false;
        needsUpdate = true;
    }

    // Check if address needs county/region or country
    if (data.place_address && typeof data.place_address === 'object') {
        const address = data.place_address;
        const addressUpdates = {};
        let addressNeedsUpdate = false;

        // Check if county/region is missing
        if (!address.county && !address.region) {
            // Try to get coordinates for reverse geocoding
            let lat = null;
            let lon = null;

            // Prefer gps_known over gps_recorded
            if (data.gps_known) {
                lat = getLatitude(data.gps_known);
                lon = getLongitude(data.gps_known);
            } else if (data.gps_recorded) {
                lat = getLatitude(data.gps_recorded);
                lon = getLongitude(data.gps_recorded);
            }

            if (lat !== null && lon !== null) {
                // Validate coordinates are reasonable
                if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                    console.warn(`  Warning: Invalid coordinates for document ${doc.id}: lat=${lat}, lon=${lon}`);
                } else {
                    try {
                        const geocodeResult = await reverseGeocode(lat, lon);
                        if (!geocodeResult || typeof geocodeResult !== 'object') {
                            throw new Error('Invalid geocoding response format');
                        }
                        const components = extractAddressComponents(geocodeResult);

                        if (components.county && !address.county && !address.region) {
                            addressUpdates['county'] = components.county;
                            addressNeedsUpdate = true;
                        }

                        if (components.country && !address.country) {
                            addressUpdates['country'] = components.country;
                            addressNeedsUpdate = true;
                        }

                        if (addressNeedsUpdate) {
                            stats.geocoded++;
                        }
                    } catch (error) {
                        console.warn(`  Warning: Failed to geocode document ${doc.id}: ${error.message}`);
                        stats.geocodingErrors++;
                    }
                }
            }
        } else if (!address.country) {
            // County exists but country is missing
            let lat = null;
            let lon = null;

            if (data.gps_known) {
                lat = getLatitude(data.gps_known);
                lon = getLongitude(data.gps_known);
            } else if (data.gps_recorded) {
                lat = getLatitude(data.gps_recorded);
                lon = getLongitude(data.gps_recorded);
            }

            if (lat !== null && lon !== null) {
                // Validate coordinates are reasonable
                if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                    console.warn(`  Warning: Invalid coordinates for document ${doc.id}: lat=${lat}, lon=${lon}`);
                } else {
                    try {
                        const geocodeResult = await reverseGeocode(lat, lon);
                        if (!geocodeResult || typeof geocodeResult !== 'object') {
                            throw new Error('Invalid geocoding response format');
                        }
                        const components = extractAddressComponents(geocodeResult);

                        if (components.country) {
                            addressUpdates['country'] = components.country;
                            addressNeedsUpdate = true;
                            stats.geocoded++;
                        }
                    } catch (error) {
                        console.warn(`  Warning: Failed to geocode document ${doc.id}: ${error.message}`);
                        stats.geocodingErrors++;
                    }
                }
            }
        }

        if (addressNeedsUpdate) {
            // Merge address updates with existing address
            updates['place_address'] = {
                ...address,
                ...addressUpdates,
            };
            needsUpdate = true;
        }
    }

    if (needsUpdate) {
        try {
            if (!options.dryRun) {
                await doc.ref.update(updates);
            }
            stats.updated++;
            return true;
        } catch (error) {
            console.error(`  Error updating document ${doc.id}:`, error.message);
            stats.errors++;
        }
    } else {
        stats.skipped++;
    }
    return false;
}

/**
 * Process visits in batches
 */
async function migrateVisits() {
    console.log('Starting migration...');
    console.log(`Mode: ${options.dryRun ? 'DRY RUN (no changes will be made)' : 'LIVE (changes will be applied)'}`);
    console.log(`Batch size: ${options.batchSize}`);
    console.log('');

    try {
        // Get all visits
        const snapshot = await db.collection(COLLECTION).get();
        stats.total = snapshot.size;

        console.log(`Found ${stats.total} visit documents`);
        console.log('');

        if (stats.total === 0) {
            console.log('No documents to migrate.');
            return;
        }

        // Output all documents as JSON to stdout
        console.log('=== DATABASE DOCUMENTS (JSON) ===');
        const allDocuments = [];
        snapshot.docs.forEach(doc => {
            const jsonDoc = docToJson(doc);
            allDocuments.push(jsonDoc);
        });
        console.log(JSON.stringify(allDocuments, null, 2));
        console.log('=== END DATABASE DOCUMENTS ===');
        console.log('');

        // Process in batches
        const batches = [];
        let currentBatch = [];
        let batchCount = 0;

        for (const doc of snapshot.docs) {
            currentBatch.push(doc);

            if (currentBatch.length >= options.batchSize) {
                batches.push([...currentBatch]);
                currentBatch = [];
            }
        }

        // Add remaining documents
        if (currentBatch.length > 0) {
            batches.push(currentBatch);
        }

        console.log(`Processing ${batches.length} batch(es)...`);
        console.log('');

        // Process each batch
        for (let i = 0; i < batches.length; i++) {
            const batch = batches[i];
            console.log(`Processing batch ${i + 1}/${batches.length} (${batch.length} documents)...`);

            for (const doc of batch) {
                await migrateVisit(doc);
                stats.processed++;
            }

            // Show progress
            const progress = ((stats.processed / stats.total) * 100).toFixed(1);
            console.log(`  Progress: ${stats.processed}/${stats.total} (${progress}%)`);
        }

        console.log('');
        console.log('Migration completed!');
        console.log('Statistics:');
        console.log(`  Total documents: ${stats.total}`);
        console.log(`  Processed: ${stats.processed}`);
        console.log(`  Updated: ${stats.updated}`);
        console.log(`  Skipped (already migrated): ${stats.skipped}`);
        console.log(`  Errors: ${stats.errors}`);
        console.log(`  Addresses geocoded: ${stats.geocoded}`);
        console.log(`  Geocoding errors: ${stats.geocodingErrors}`);

        if (options.dryRun) {
            console.log('');
            console.log('This was a DRY RUN. No changes were made.');
            console.log('Run with --apply to apply changes.');
        } else if (stats.updated > 0) {
            console.log('');
            console.log('Verifying updates...');
            // Re-fetch a sample of updated documents to verify
            const verifyCount = Math.min(5, stats.updated);
            const verifySnapshot = await db.collection(COLLECTION)
                .limit(verifyCount)
                .get();
            let verified = 0;
            verifySnapshot.docs.forEach(doc => {
                const data = doc.data();
                if (!('added_at' in data) && 'visited_at' in data && 'planned' in data) {
                    verified++;
                }
            });
            console.log(`  Verified ${verified}/${verifyCount} sample documents`);
        }

    } catch (error) {
        console.error('Migration failed:', error);
        console.error('Stack trace:', error.stack);
        process.exit(1);
    }
}

// Confirm before running (for --apply)
async function confirm() {
    if (options.dryRun) {
        return true;
    }

    const rl = readline.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    return new Promise((resolve) => {
        rl.question('This will modify Firestore documents. Continue? (yes/no): ', (answer) => {
            rl.close();
            resolve(answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y');
        });
    });
}

// Main execution
(async () => {
    // Test connection before proceeding
    await testConnection();

    const confirmed = await confirm();
    if (!confirmed) {
        console.log('Migration cancelled.');
        process.exit(0);
    }

    await migrateVisits();
    process.exit(0);
})();

