# Build Instructions for Burpata Android App

## Prerequisites

1. **Android Studio** (Latest version recommended)
   - Download from: https://developer.android.com/studio

2. **Android SDK**
   - Minimum SDK: API 24 (Android 7.0)
   - Target SDK: API 34 (Android 14)

3. **Java Development Kit (JDK)**
   - JDK 8 or higher (JDK 17 recommended)

## Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/clockworkpc/burpata.git
   cd burpata
   ```

2. **Open in Android Studio:**
   - Open Android Studio
   - Select "Open an Existing Project"
   - Navigate to the cloned repository folder
   - Android Studio will automatically sync Gradle dependencies

3. **Replace Audio Files:**
   - Navigate to `app/src/main/res/raw/`
   - Replace the placeholder audio files with actual audio:
     - `countdown.mp3` - Countdown beep sound
     - `whistle.mp3` - Sports whistle sound
     - `bell.mp3` - Boxing bell sound
   - See `AUDIO_README.md` for details

## Building the App

### Using Android Studio:

1. Click "Build" → "Make Project" or press `Ctrl+F9` (Windows/Linux) / `Cmd+F9` (Mac)
2. Wait for the build to complete
3. Fix any errors if they occur

### Using Command Line:

```bash
# On Linux/Mac
./gradlew build

# On Windows
gradlew.bat build
```

## Running the App

### On an Emulator:

1. In Android Studio, click "Tools" → "AVD Manager"
2. Create a new virtual device if needed (recommended: Pixel 5 with API 34)
3. Click the "Run" button or press `Shift+F10`
4. Select your emulator

### On a Physical Device:

1. Enable Developer Options on your Android device:
   - Go to Settings → About Phone
   - Tap "Build Number" 7 times
2. Enable USB Debugging:
   - Go to Settings → Developer Options
   - Enable "USB Debugging"
3. Connect your device via USB
4. Click the "Run" button in Android Studio
5. Select your device

## Project Structure

```
burpata/
├── app/
│   ├── src/
│   │   └── main/
│   │       ├── java/com/clockworkpc/burpata/
│   │       │   ├── MainActivity.kt          # Input screen
│   │       │   └── WorkoutActivity.kt       # Workout timer
│   │       ├── res/
│   │       │   ├── layout/
│   │       │   │   ├── activity_main.xml    # Main layout
│   │       │   │   └── activity_workout.xml # Workout layout
│   │       │   ├── values/
│   │       │   │   ├── strings.xml          # String resources
│   │       │   │   ├── colors.xml           # Color definitions
│   │       │   │   └── themes.xml           # App theme
│   │       │   └── raw/                     # Audio files
│   │       └── AndroidManifest.xml
│   └── build.gradle                         # App-level build config
├── build.gradle                             # Project-level build config
├── settings.gradle                          # Project settings
└── gradle.properties                        # Gradle properties
```

## Features

The app implements a Tabata timer with the following features:

- **Input Parameters:**
  - Number of reps per set
  - Number of seconds per set
  - Number of sets in the workout
  - Rest time between sets (in seconds)

- **Audio Cues:**
  - Countdown sound (3 seconds before each set)
  - Sports whistle at the start of each set
  - Boxing bell at the end of each set

- **Workout Flow:**
  1. 3-second countdown before first set
  2. Active workout set (visual and audio cues)
  3. Rest period after each set
  4. Repeat for all sets
  5. Completion dialog asking if workout was successful

## Troubleshooting

### Build Errors:

- **SDK not found:** Ensure Android SDK is installed via Android Studio
- **Gradle sync failed:** Click "File" → "Sync Project with Gradle Files"
- **Dependency issues:** Update dependencies in `build.gradle`

### Runtime Errors:

- **No audio playback:** Ensure audio files are properly placed in `raw` folder
- **App crashes on start:** Check Logcat for error messages
- **Screen turns off:** The app uses `WAKE_LOCK` permission to keep screen on

## Testing

The app can be tested by:
1. Entering workout parameters on the main screen
2. Starting a workout
3. Verifying countdown, active set, and rest phases
4. Checking audio playback at appropriate times
5. Completing the workout and responding to the success prompt

## Notes

- The app keeps the screen on during workouts
- Device orientation is locked to portrait mode
- Back button during workout shows a confirmation dialog
