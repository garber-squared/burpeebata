import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  // Initialize Firebase with production settings
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

  final firestore = FirebaseFirestore.instance;

  print('Searching for user with email: alexandergarber@gmail.com');
  print('Database: burpeebata (production)');
  print('---');

  try {
    // Query the users collection for the email
    final querySnapshot = await firestore
        .collection('users')
        .where('email', isEqualTo: 'alexandergarber@gmail.com')
        .get();

    if (querySnapshot.docs.isEmpty) {
      print('No user found with that email.');

      // Also check if there's a user document by trying common patterns
      print('\nAttempting to search all users...');
      final allUsers = await firestore.collection('users').get();
      print('Total users in database: ${allUsers.docs.length}');

      for (var doc in allUsers.docs) {
        final data = doc.data();
        if (data['email']?.toString().toLowerCase().contains('alexander') ?? false) {
          print('\nFound similar user:');
          print('Document ID: ${doc.id}');
          print('Data: $data');
        }
      }
    } else {
      print('Found ${querySnapshot.docs.length} user(s):');

      for (var doc in querySnapshot.docs) {
        print('\nDocument ID: ${doc.id}');
        print('Data:');
        final data = doc.data();
        data.forEach((key, value) {
          print('  $key: $value');
        });

        // Check for workouts subcollection
        final workouts = await doc.reference.collection('workouts').get();
        print('  workouts: ${workouts.docs.length} workout(s)');
      }
    }
  } catch (e) {
    print('Error querying database: $e');
  }
}
