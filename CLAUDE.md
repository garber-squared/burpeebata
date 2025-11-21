# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

BurpeeBata is a Flutter application - a tabata timer specifically designed for burpee workouts. It targets mobile platforms (Android/iOS) and web.

## Development Commands

All commands run through Docker Compose via Makefile:

```bash
# Start development environment
make up

# Build and start
make up-build

# Run tests
make test

# Run a single test file
docker compose exec flutter flutter test test/path/to/test_file.dart

# Generate mocks (for mockito)
make mocks

# Build release APK
make apk

# View logs
make logs

# Check Flutter environment
make doctor
```

## Code Architecture

### Directory Structure
- `lib/` - Main application code
  - `main.dart` - App entry point, MaterialApp configuration with light/dark themes
  - `screens/` - UI screens (HomeScreen, TimerScreen, HistoryScreen)
  - `models/` - Data models (Workout, WorkoutConfig, BurpeeType)
  - `services/` - Business logic (TimerService, StorageService, AudioService)
- `test/` - Test files mirror lib structure
- `assets/audio/` - Audio files for workout cues

### Key Dependencies
- `shared_preferences` - Local storage for workout history
- `audioplayers` - Audio playback for timer cues
- `wakelock` - Keep screen awake during workout
- `mockito` + `build_runner` - Test mocking

## Testing

Uses Flutter's test framework with mockito for mocking. Mocks are generated in `*.mocks.dart` files.

To regenerate mocks after adding new mock annotations:
```bash
make mocks
```

## Linting

Uses `flutter_lints` package. Run analysis with:
```bash
docker compose exec flutter flutter analyze
```
