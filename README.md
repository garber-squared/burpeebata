# Burpata - Tabata Timer for Android

A busy dad inspired Tabata timer specifically designed for burpee workouts and other high-intensity interval training.

## Features

- ⏱️ **Customizable Workout Parameters**
  - Set reps per set
  - Configure seconds per workout set
  - Define number of sets
  - Set rest time between sets

- 🔊 **Audio Cues**
  - Countdown beep (3 seconds before each set)
  - Sports whistle to start workout sets
  - Boxing bell to end workout sets

- 📱 **User Experience**
  - Clean, easy-to-read interface
  - Screen stays on during workout
  - Color-coded workout phases (countdown, active, rest)
  - Workout completion confirmation prompt

## Quick Start

1. Enter your workout parameters on the main screen
2. Tap "Start Workout" 
3. Follow the audio and visual cues
4. Complete your workout and confirm success

## Build & Installation

See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) for detailed setup and build instructions.

**Note:** Audio files need to be added to `app/src/main/res/raw/`. See [AUDIO_README.md](AUDIO_README.md) for details.

## Technology Stack

- **Language:** Kotlin
- **Minimum SDK:** API 24 (Android 7.0)
- **Target SDK:** API 34 (Android 14)
- **UI Framework:** Material Design Components
- **Build System:** Gradle

## Project Structure

```
app/src/main/
├── java/com/clockworkpc/burpata/
│   ├── MainActivity.kt       # Input configuration screen
│   └── WorkoutActivity.kt    # Timer and workout logic
├── res/
│   ├── layout/              # UI layouts
│   ├── values/              # Strings, colors, themes
│   └── raw/                 # Audio files (to be added)
└── AndroidManifest.xml
```

## License

This project is open source. Feel free to use and modify as needed.
