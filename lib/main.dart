import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/auth_wrapper.dart';
import 'theme/app_theme.dart';
import 'firebase_options.dart' as dev;
import 'firebase_options_prod.dart' as prod;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Use production Firebase for production builds, dev Firebase otherwise
  const isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
  final firebaseOptions = isProduction
      ? prod.DefaultFirebaseOptions.currentPlatform
      : dev.DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const BurpeeBataApp());
}

class BurpeeBataApp extends StatelessWidget {
  const BurpeeBataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
      title: 'BurpeeBata',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      home: const AuthWrapper(),
      ),
    );
  }
}
