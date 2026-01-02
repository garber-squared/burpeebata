#!/usr/bin/env node

const admin = require('firebase-admin');
const fs = require('fs');
const { parse } = require('csv-parse/sync');
const { v4: uuidv4 } = require('uuid');

// Initialize Firebase Admin SDK using Application Default Credentials
// This uses the Firebase CLI's authentication
try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    projectId: 'burpeebata',
  });
} catch (error) {
  console.error('Error initializing Firebase Admin SDK:', error);
  console.error('\nPlease ensure you are logged in with Firebase CLI:');
  console.error('  firebase login');
  process.exit(1);
}

const db = admin.firestore();
const auth = admin.auth();

// Map CSV burpee types to app enum
function mapBurpeeType(csvType) {
  if (csvType === 'Navy Seal') return 1; // BurpeeType.navySeal
  if (csvType === 'Six Count') return 0; // BurpeeType.militarySixCount
  return 0;
}

// Parse CSV timestamp to Date
function parseTimestamp(timestamp) {
  // Format: "10/27/2025 11:02:22" (MM/DD/YYYY HH:mm:ss)
  const [datePart, timePart] = timestamp.split(' ');
  const [month, day, year] = datePart.split('/');
  const [hours, minutes, seconds] = timePart.split(':');

  return new Date(
    parseInt(year),
    parseInt(month) - 1, // JS months are 0-indexed
    parseInt(day),
    parseInt(hours),
    parseInt(minutes),
    parseInt(seconds)
  );
}

// Convert CSV row to Workout object
function csvRowToWorkout(row) {
  const date = parseTimestamp(row.Timestamp);
  const totalWorkSeconds = parseInt(row.SetCount) * parseInt(row.SetDuration);
  const totalRestSeconds = (parseInt(row.SetCount) - 1) * parseInt(row.RestDuration);
  const elapsedSeconds = totalWorkSeconds + totalRestSeconds;

  return {
    id: uuidv4(),
    date: date.toISOString(),
    burpeeType: mapBurpeeType(row.BurpeeType),
    repsPerSet: parseInt(row.RepsPerSet),
    secondsPerSet: parseInt(row.SetDuration),
    numberOfSets: parseInt(row.SetCount),
    restBetweenSets: parseInt(row.RestDuration),
    completed: row.IsCompleted === 'TRUE',
    completedSets: parseInt(row.SetCount), // Assume all completed if IsCompleted is true
    isCompleted: row.IsCompleted === 'TRUE',
    isCompletedInTime: row.IsOnTime === 'TRUE',
    elapsedSeconds: elapsedSeconds,
  };
}

async function importWorkouts(userId, csvPath) {
  try {
    console.log(`User ID: ${userId}`);

    // Read and parse CSV
    console.log(`Reading CSV file: ${csvPath}...`);
    const csvContent = fs.readFileSync(csvPath, 'utf-8');
    const records = parse(csvContent, {
      columns: true,
      skip_empty_lines: true,
    });
    console.log(`Found ${records.length} workout records`);

    // Convert to workouts
    const workouts = records.map(csvRowToWorkout);

    // Import to Firestore
    console.log(`Importing workouts to Firestore...`);
    const batch = db.batch();
    let count = 0;

    for (const workout of workouts) {
      const docRef = db
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout.id);

      batch.set(docRef, workout);
      count++;

      // Firestore batch limit is 500 operations
      if (count % 500 === 0) {
        await batch.commit();
        console.log(`  Committed batch of ${count} workouts...`);
      }
    }

    // Commit remaining
    if (count % 500 !== 0) {
      await batch.commit();
    }

    console.log(`✅ Successfully imported ${workouts.length} workouts`);
    console.log(`📊 Summary:`);
    console.log(`   - User ID: ${userId}`);
    console.log(`   - Total workouts: ${workouts.length}`);
    console.log(`   - Completed: ${workouts.filter(w => w.completed).length}`);
    console.log(`   - Date range: ${workouts[0].date} to ${workouts[workouts.length - 1].date}`);

  } catch (error) {
    console.error('❌ Error importing workouts:', error);
    process.exit(1);
  }
}

// Run the import
const userId = process.argv[2];
const csvPath = process.argv[3] || './user_records_export.csv';

if (!userId) {
  console.error('Usage: node import_workouts.js <userId> [csvPath]');
  console.error('Example: node import_workouts.js 3zqmtJb9CiZxKD7wx8avCGSWHRw1 user_records_export.csv');
  process.exit(1);
}

importWorkouts(userId, csvPath)
  .then(() => process.exit(0))
  .catch(err => {
    console.error(err);
    process.exit(1);
  });
