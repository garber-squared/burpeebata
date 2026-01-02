import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../lib/firebase_options.dart';
import '../lib/models/burpee_type.dart';

void main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart run scripts/import_workouts.dart <user_email> <csv_path>');
    print('Example: dart run scripts/import_workouts.dart alexandergarber@gmail.com user_records_export.csv');
    exit(1);
  }

  final userEmail = args[0];
  final csvPath = args[1];

  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('📧 User email: $userEmail');
  print('📄 CSV file: $csvPath');

  try {
    await importWorkouts(userEmail, csvPath);
    print('✅ Import completed successfully!');
    exit(0);
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print(stackTrace);
    exit(1);
  }
}

Future<void> importWorkouts(String userEmail, String csvPath) async {
  // For this script, we need the user ID
  // Since we can't query Firebase Auth users without admin SDK,
  // we'll need to pass the user ID directly
  print('\n⚠️  Note: Firebase Auth user lookup requires Admin SDK');
  print('Please provide the user ID for $userEmail');
  print('You can find it in Firebase Console > Authentication > Users');
  print('\nEnter user ID: ');
  final userId = stdin.readLineSync()?.trim();

  if (userId == null || userId.isEmpty) {
    throw Exception('User ID is required');
  }

  print('\n👤 Using user ID: $userId');

  // Read CSV file
  final csvFile = File(csvPath);
  if (!await csvFile.exists()) {
    throw Exception('CSV file not found: $csvPath');
  }

  final csvContent = await csvFile.readAsString();
  final rows = const CsvToListConverter(fieldDelimiter: ',', eol: '\n')
      .convert(csvContent);

  if (rows.isEmpty || rows.length < 2) {
    throw Exception('CSV file is empty or has no data rows');
  }

  // Parse header row
  final headers = rows[0].map((e) => e.toString()).toList();
  final dataRows = rows.sublist(1);

  print('📊 Found ${dataRows.length} workout records');

  // Convert rows to workout objects
  final workouts = <Map<String, dynamic>>[];
  for (final row in dataRows) {
    final workout = parseWorkoutRow(headers, row);
    if (workout != null) {
      workouts.add(workout);
    }
  }

  print('💾 Uploading ${workouts.length} workouts to Firestore...');

  // Upload to Firestore
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();
  int count = 0;

  for (final workout in workouts) {
    final docRef = firestore
        .collection('users')
        .doc(userId)
        .collection('workouts')
        .doc(workout['id'] as String);

    batch.set(docRef, workout);
    count++;

    // Firestore batch limit is 500 operations
    if (count % 500 == 0) {
      await batch.commit();
      print('  ✓ Committed batch: $count workouts');
    }
  }

  // Commit remaining
  if (count % 500 != 0) {
    await batch.commit();
  }

  print('\n✅ Successfully imported ${workouts.length} workouts!');
  print('📈 Summary:');
  final completed = workouts.where((w) => w['completed'] == true).length;
  print('   • Total: ${workouts.length}');
  print('   • Completed: $completed');
  print('   • Incomplete: ${workouts.length - completed}');
}

Map<String, dynamic>? parseWorkoutRow(List<String> headers, List row) {
  try {
    final data = <String, String>{};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      data[headers[i]] = row[i].toString();
    }

    // Parse timestamp: "10/27/2025 11:02:22" -> DateTime
    final timestampParts = data['Timestamp']!.split(' ');
    final dateParts = timestampParts[0].split('/');
    final timeParts = timestampParts[1].split(':');

    final date = DateTime(
      int.parse(dateParts[2]), // year
      int.parse(dateParts[0]), // month
      int.parse(dateParts[1]), // day
      int.parse(timeParts[0]), // hour
      int.parse(timeParts[1]), // minute
      int.parse(timeParts[2]), // second
    );

    // Map burpee type
    final burpeeType = data['BurpeeType'] == 'Navy Seal'
        ? BurpeeType.navySeal.index
        : BurpeeType.militarySixCount.index;

    // Calculate elapsed seconds
    final setCount = int.parse(data['SetCount']!);
    final setDuration = int.parse(data['SetDuration']!);
    final restDuration = int.parse(data['RestDuration']!);
    final elapsedSeconds =
        (setCount * setDuration) + ((setCount - 1) * restDuration);

    return {
      'id': const Uuid().v4(),
      'date': date.toIso8601String(),
      'burpeeType': burpeeType,
      'repsPerSet': int.parse(data['RepsPerSet']!),
      'secondsPerSet': setDuration,
      'numberOfSets': setCount,
      'restBetweenSets': restDuration,
      'completed': data['IsCompleted'] == 'TRUE',
      'completedSets': setCount, // Assuming all sets completed if marked complete
      'isCompleted': data['IsCompleted'] == 'TRUE',
      'isCompletedInTime': data['IsOnTime'] == 'TRUE',
      'elapsedSeconds': elapsedSeconds,
    };
  } catch (e) {
    print('Warning: Failed to parse row: $row - $e');
    return null;
  }
}
