import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDyMJag5k07ZTPQLCJZxchrqDZzt4xjEiA',
        appId: '1:726464864566:web:3f67cb2b748b5317931397',
        messagingSenderId: '726464864566',
        projectId: 'burpeebata',
        authDomain: 'burpeebata.firebaseapp.com',
        storageBucket: 'burpeebata.firebasestorage.app',
        measurementId: 'G-88KPSLSJP2',
      ),
    );
  });

  test('Find user with email alexandergarber@gmail.com', () async {
    final firestore = FirebaseFirestore.instance;

    print('\n========================================');
    print('Searching for user with email: alexandergarber@gmail.com');
    print('Database: burpeebata (production)');
    print('========================================\n');

    try {
      // Query the users collection for the email
      final querySnapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: 'alexandergarber@gmail.com')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('❌ No user found with that exact email.\n');

        // Also check if there's a user document by trying common patterns
        print('Attempting to search all users...');
        final allUsers = await firestore.collection('users').get();
        print('Total users in database: ${allUsers.docs.length}\n');

        var foundSimilar = false;
        for (var doc in allUsers.docs) {
          final data = doc.data();
          final email = data['email']?.toString().toLowerCase() ?? '';
          if (email.contains('alexander') || email.contains('garber')) {
            foundSimilar = true;
            print('Found similar user:');
            print('  Document ID: ${doc.id}');
            print('  Email: ${data['email']}');
            print('  Data: $data');

            // Check for workouts subcollection
            final workouts = await doc.reference.collection('workouts').get();
            print('  Workouts: ${workouts.docs.length} workout(s)\n');
          }
        }

        if (!foundSimilar) {
          print('No similar users found.');
        }
      } else {
        print('✅ Found ${querySnapshot.docs.length} user(s):\n');

        for (var doc in querySnapshot.docs) {
          print('Document ID: ${doc.id}');
          print('Data:');
          final data = doc.data();
          data.forEach((key, value) {
            print('  $key: $value');
          });

          // Check for workouts subcollection
          final workouts = await doc.reference.collection('workouts').get();
          print('  workouts: ${workouts.docs.length} workout(s)');

          if (workouts.docs.isNotEmpty) {
            print('\n  Recent workouts:');
            for (var workout in workouts.docs.take(3)) {
              final workoutData = workout.data();
              print('    - ${workout.id}: ${workoutData['date']?.toString() ?? 'no date'} '
                    '(${workoutData['burpeeType'] ?? 'unknown type'})');
            }
          }
          print('');
        }
      }
    } catch (e) {
      print('❌ Error querying database: $e');
      print('Stack trace: ${StackTrace.current}');
    }

    print('========================================\n');
  });
}
