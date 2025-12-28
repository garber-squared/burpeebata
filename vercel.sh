#!/bin/bash

# Environment-specific build script for Vercel deployments
# Uses VERCEL_ENV to determine which Firebase configuration to use:
# - production: Uses burpeebata (production Firebase)
# - preview/development: Uses burpeebata-dev (development Firebase)

echo "Building Flutter web app..."
echo "VERCEL_ENV: $VERCEL_ENV"

# Install and configure Flutter if not already done
if [ ! -d "flutter" ]; then
  echo "Installing Flutter..."
  git clone https://github.com/flutter/flutter.git -b stable
  flutter/bin/flutter --version
  flutter/bin/flutter config --enable-web
fi

# Build with appropriate Firebase configuration based on environment
if [ "$VERCEL_ENV" == "production" ]; then
  echo "Building for PRODUCTION environment (burpeebata Firebase)"
  flutter/bin/flutter build web --release --base-href / --dart-define=PRODUCTION=true
else
  echo "Building for PREVIEW/DEVELOPMENT environment (burpeebata-dev Firebase)"
  flutter/bin/flutter build web --release --base-href /
fi

echo "Build complete!"
