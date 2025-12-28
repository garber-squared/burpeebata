# Deployment Guide

This document describes how to deploy the BurpeeBata app to various platforms.

## Web Deployment (Vercel)

The production web app is deployed to Vercel at https://burpeebata.com

### Prerequisites
- Access to Vercel project: https://vercel.com/garbersquareds-projects/burpeebata
- Production Firebase project (`burpeebata`) configured
- Development Firebase project (`burpeebata-dev`) configured

### Firebase Configuration

The app uses two Firebase projects:
- **Development**: `burpeebata-dev` (lib/firebase_options.dart)
- **Production**: `burpeebata` (lib/firebase_options_prod.dart)

The environment is determined at build time via the `PRODUCTION` dart-define flag:

```dart
// lib/main.dart
const isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
final firebaseOptions = isProduction
    ? prod.DefaultFirebaseOptions.currentPlatform
    : dev.DefaultFirebaseOptions.currentPlatform;
```

### Automatic Deployment

Vercel automatically deploys when changes are pushed to the repository:

#### Production Deployments (master branch)
1. Push to `master` branch triggers production deployment
2. Vercel sets `VERCEL_ENV=production`
3. `vercel.sh` script builds with `--dart-define=PRODUCTION=true`
4. App connects to `burpeebata` (production Firebase)
5. Deployed to https://burpeebata.com

#### Preview Deployments (feature branches)
1. Push to any feature branch triggers preview deployment
2. Vercel sets `VERCEL_ENV=preview`
3. `vercel.sh` script builds WITHOUT production flag
4. App connects to `burpeebata-dev` (development Firebase)
5. Deployed to `*.vercel.app` preview URL

### Build Process

The build process is controlled by `vercel.sh`:

```bash
# Production build (VERCEL_ENV=production)
flutter build web --release --base-href / --dart-define=PRODUCTION=true

# Preview/Development build (VERCEL_ENV=preview or development)
flutter build web --release --base-href /
```

### Manual Deployment

To manually deploy from local machine:

```bash
# Build for production
flutter build web --release --dart-define=PRODUCTION=true

# Deploy using Vercel CLI
vercel --prod
```

### Verifying Deployment

After deployment, verify the correct Firebase project is in use:

1. Open browser console on https://burpeebata.com
2. Sign in and complete a workout
3. Check Firebase Console for `burpeebata` project (NOT `burpeebata-dev`)
4. Verify workout appears in production Firestore

For preview deployments:
1. Open the `*.vercel.app` preview URL
2. Verify it connects to `burpeebata-dev` project

### Environment Separation

| Environment | Firebase Project | VERCEL_ENV | Build Flag | URL |
|------------|-----------------|------------|------------|-----|
| Local Development | `burpeebata-dev` | N/A | (none) | localhost:* |
| Vercel Preview | `burpeebata-dev` | `preview` | (none) | *.vercel.app |
| Vercel Production | `burpeebata` | `production` | `--dart-define=PRODUCTION=true` | burpeebata.com |

### Vercel Configuration Files

- **vercel.json**: Main Vercel configuration
  - `buildCommand`: Points to `vercel.sh`
  - `outputDirectory`: `build/web`
  - Rewrites for SPA routing

- **vercel.sh**: Build script with environment detection
  - Checks `VERCEL_ENV` variable
  - Installs Flutter if needed
  - Builds with appropriate Firebase config

## Mobile Deployment

### Android (Google Play Store)

Build release APK:

```bash
# Using Docker (recommended)
make apk

# Or directly with Flutter
flutter build apk --release
```

The APK will be in `build/app/outputs/flutter-apk/app-release.apk`

**Note**: Android mobile builds use the **development** Firebase project (`burpeebata-dev`) by default. To use production Firebase for mobile:

```bash
flutter build apk --release --dart-define=PRODUCTION=true
```

### iOS (App Store)

iOS builds are not yet configured. To add iOS support:

1. Configure iOS app in production Firebase project (`burpeebata`)
2. Update `lib/firebase_options_prod.dart` with iOS configuration
3. Build with: `flutter build ios --release --dart-define=PRODUCTION=true`

## Troubleshooting

### Production app connecting to dev database

**Symptom**: Users on burpeebata.com see data in `burpeebata-dev` Firebase project

**Solution**:
1. Check that `vercel.sh` has correct VERCEL_ENV logic
2. Verify `vercel.json` uses `sh vercel.sh` as buildCommand
3. Check Vercel build logs to confirm VERCEL_ENV=production
4. Ensure production build includes `--dart-define=PRODUCTION=true`

### Preview deployments connecting to production database

**Symptom**: Feature branch previews connect to `burpeebata` instead of `burpeebata-dev`

**Solution**:
1. Verify `vercel.sh` only sets PRODUCTION flag when `VERCEL_ENV=production`
2. Check preview build logs to confirm correct environment detection

### Build fails on Vercel

**Common causes**:
- Flutter version mismatch
- Missing dependencies
- Firebase configuration errors
- Script permissions (ensure vercel.sh is executable)

**Solution**:
1. Check Vercel build logs
2. Test the build script locally:
   ```bash
   VERCEL_ENV=production sh vercel.sh
   VERCEL_ENV=preview sh vercel.sh
   ```

### Local build works but Vercel fails

**Solution**: Test the exact Vercel build command locally:
```bash
# Production
flutter build web --release --base-href / --dart-define=PRODUCTION=true

# Preview
flutter build web --release --base-href /
```

## Security Notes

- Never commit Firebase API keys or sensitive credentials to environment variables
- Firebase API keys in `firebase_options*.dart` are safe to commit (they're public client keys)
- Use Firestore Security Rules to protect user data
- See `FIRESTORE_SECURITY_RULES.md` for security configuration
- The `VERCEL_ENV` variable is automatically provided by Vercel (no manual configuration needed)

## References

- [Vercel Environment-Specific Build Commands](https://vercel.com/kb/guide/per-environment-and-per-branch-build-commands)
- [Vercel Environments Documentation](https://vercel.com/docs/deployments/environments)
- [Vercel System Environment Variables](https://vercel.com/docs/projects/environment-variables/system-environment-variables)
