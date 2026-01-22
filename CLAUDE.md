# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BurpeeBata is a Flutter application - a tabata timer specifically designed for burpee workouts. It targets mobile platforms (Android/iOS) and web.

## Development Commands

All commands run through Docker Compose via Makefile:

```bash
# Start development environment (uses dev Firebase)
make up

# Start with production Firebase
FLUTTER_ENV=prod make up

# Build and start
make up-build

# Run tests
make test

# Run a single test file
docker compose exec flutter flutter test test/path/to/test_file.dart

# Generate mocks (for mockito)
make mocks

# Build production APK (uses production Firebase)
make apk

# Build development APK (uses dev Firebase)
make apk-dev

# Build production web app
make build-web

# Build development web app
make build-web-dev

# Install dependencies
make pub-get

# View logs
make logs

# Check Flutter environment
make doctor

# Run linting
docker compose exec flutter flutter analyze
```

## Code Architecture

### Directory Structure
- `lib/` - Main application code
  - `main.dart` - App entry point with dual Firebase config and Provider setup
  - `firebase_options.dart` - Development Firebase configuration
  - `firebase_options_prod.dart` - Production Firebase configuration
  - `theme/` - App theme and design system
  - `screens/` - UI screens
    - Authentication: LoginScreen, SignupScreen, AuthWrapper
    - Main: HomeScreen, TimerScreen, HistoryScreen, ProfileScreen
    - Workouts: SavedWorkoutsScreen, WorkoutBuilderScreen, PostWorkoutQuestionnaireScreen
  - `models/` - Data models
    - Workout data: Workout, WorkoutConfig, BurpeeType, WorkoutTemplate
    - User data: UserProfile (with optional fields)
  - `services/` - Business logic
    - Workout: TimerService, StorageService (local), WorkoutService (Firestore), AudioService
    - User: AuthService (Firebase Auth), UserService (Firestore)
  - `providers/` - State management (Provider pattern)
    - AuthProvider - Authentication state and user profile
- `test/` - Test files mirror lib structure
- `assets/audio/` - Audio files for workout cues
- `scripts/` - Utility scripts for data migration and imports

### Key Dependencies

**Authentication & Data:**
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication (email/password, anonymous)
- `cloud_firestore` - User profile and workout storage in cloud
- `provider` - State management for authentication

**Workout Features:**
- `shared_preferences` - Local storage for workout history (offline-first)
- `audioplayers` - Audio playback for timer cues
- `wakelock_plus` - Keep screen awake during workout
- `uuid` - Unique ID generation
- `share_plus` - Share workout results

**Development:**
- `mockito` + `build_runner` - Test mocking
- `flutter_lints` - Linting rules
- `fake_cloud_firestore` - Mock Firestore for testing
- `firebase_auth_mocks` - Mock Firebase Auth for testing
- `fake_async` - Async testing utilities

## Dual Firebase Environment

The app supports separate development and production Firebase projects:

**Configuration:** `lib/main.dart`
- Build flag `PRODUCTION` determines which Firebase project to use
- Development (default): Uses `firebase_options.dart` (burpeebata-dev)
- Production: Uses `firebase_options_prod.dart` (burpeebata) when `--dart-define=PRODUCTION=true`

**Usage:**
- Development builds: `make up`, `make apk-dev`, `make build-web-dev`
- Production builds: `make apk`, `make build-web`, or `FLUTTER_ENV=prod make up`

**Benefits:**
- Test features without affecting production data
- Separate analytics and error tracking
- Safe iteration during development

## Testing

Uses Flutter's test framework with mockito for mocking. Mocks are generated in `*.mocks.dart` files.

To regenerate mocks after adding new mock annotations:
```bash
make mocks
```

Test files are located in `test/` and mirror the structure of `lib/`.

## Authentication & User Profiles

BurpeeBata uses Firebase for authentication and user data storage.

### Authentication Methods
- **Email/Password** - Standard sign-up and login
- **Anonymous** - Guest access (perfect for app store reviewers)
- Users can convert anonymous accounts to permanent accounts

### User Profile (Optional)
All profile fields are optional:
- Name
- Age
- Sex (Male/Female, defaults to Male)
- Height (cm)
- Weight (kg)

### Firebase Setup
See `FIREBASE_SETUP.md` for complete configuration instructions.

### App Store Reviewer Access
See `APP_STORE_REVIEWER_ACCESS.md` for credentials and access instructions.

**Quick Access for Reviewers:**
- Tap "Continue as Guest" on login screen (no credentials needed)
- OR use demo account: `reviewer@burpeebata.com` / `Reviewer2025!`

## Workout Storage Architecture

The app uses an **offline-first** architecture with dual storage:

### Storage Services

**1. StorageService** (`lib/services/storage_service.dart`)
- Local storage using SharedPreferences
- Primary source of truth for data safety
- Works offline
- **Keys:**
  - `'workouts'` - JSON-encoded list of completed/partial workouts
  - `'workout_templates'` - JSON-encoded list of saved templates

**2. WorkoutService** (`lib/services/workout_service.dart`)
- Cloud storage using Firestore
- Syncs data across devices for authenticated users
- Subcollection structure: `users/{userId}/workouts/{workoutId}`
- User isolation enforced by security rules
- **Methods:**
  - `saveWorkout()` - Save/update workout
  - `getWorkouts()` - Retrieve all workouts (sorted newest first)
  - `workoutsStream()` - Real-time updates
  - `deleteWorkout()` - Delete specific workout
  - `clearAllWorkouts()` - Delete all workouts
  - `getWorkoutsInRange()` - Query by date range
  - `getRecentWorkouts()` - Get N most recent

### Workout Data Flow

**Workout Execution:** `lib/screens/timer_screen.dart`
1. User starts workout with `WorkoutConfig`
2. `TimerService` manages countdown and state
3. Completion triggers save via `_saveWorkout()`:
   - Normal completion → `completed: true`
   - Early end → `completed: false` with partial sets
   - Back navigation → Shows dialog, saves on confirm
4. **Dual save:**
   - Saves to SharedPreferences first (ensures data never lost)
   - Syncs to Firestore for authenticated non-anonymous users
   - Graceful error handling - logs errors but doesn't fail

**Workout Display:** `lib/screens/history_screen.dart`
- **Authenticated non-anonymous users:** Loads from Firestore with local fallback
- **Anonymous/guest users:** Uses local storage only
- Delete operations sync to both local and Firestore
- Shows: date, time, burpee type, sets, reps, completion status
- Actions: Share (via `share_plus`), Delete (with confirmation)

**Workout Model:** `lib/models/workout.dart`
```dart
class Workout {
  final String id;              // UUID v4
  final DateTime date;
  final BurpeeType burpeeType;  // militarySixCount or navySeal
  final int repsPerSet;
  final int secondsPerSet;
  final int numberOfSets;
  final int restBetweenSets;
  final bool completed;         // true if all sets finished
  final int completedSets;      // actual sets completed
  final bool isCompleted;
  final bool isCompletedInTime;
  final int elapsedSeconds;

  // Calculated properties
  int get totalReps => repsPerSet * completedSets;
  String get shareText => // Formatted for sharing
}
```

### Firestore Data Structure

```
Firestore
└── users/{userId}
    ├── (user profile fields)
    └── workouts (subcollection)
        └── {workoutId}
            ├── id
            ├── date
            ├── burpeeType
            ├── repsPerSet
            ├── secondsPerSet
            ├── numberOfSets
            ├── restBetweenSets
            ├── completed
            ├── completedSets
            ├── isCompleted
            ├── isCompletedInTime
            └── elapsedSeconds
```

### Firestore Security Rules

File: `firestore.rules`

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /workouts/{workoutId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

Deploy rules: `firebase deploy --only firestore:rules`

### Data Migration

**Import Scripts:** Import workouts from CSV to Firestore
- `import_workouts.sh` - Bash implementation (requires gcloud)
- `import_workouts.py` - Python implementation
- `import_workouts.js` - Node.js implementation

**Usage:**
```bash
./import_workouts.sh <user_id> <csv_file>
```

## Audio System

**AudioService** (`lib/services/audio_service.dart`)
- Manages workout audio cues using `audioplayers` package
- Audio files located in `assets/audio/`
- Cues include: countdown beeps, whistles, boxing bell, ping

## Linting

Uses `flutter_lints` package. Run analysis with:
```bash
docker compose exec flutter flutter analyze
```

## Additional Documentation

- `FIREBASE_SETUP.md` - Complete Firebase configuration guide
- `APP_STORE_REVIEWER_ACCESS.md` - Credentials and access for app store reviewers
- `FIRESTORE_SECURITY_RULES.md` - Detailed security rules documentation
- `IMPLEMENTATION_SUMMARY.md` - Workout cloud storage implementation details
- `DEPLOYMENT.md` - Deployment instructions and procedures
