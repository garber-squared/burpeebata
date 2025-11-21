FROM ghcr.io/cirruslabs/flutter:3.29.3

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install required Android SDK components
RUN yes | sdkmanager "build-tools;30.0.3" "platforms;android-31"

# Create non-root user with UID/GID 1000 to match host user (if not exists)
RUN groupadd -g 1000 flutter 2>/dev/null || true && \
    useradd -u 1000 -g 1000 -m -d /home/flutter flutter 2>/dev/null || true

# Set up Flutter SDK permissions - make writable by any user for development
RUN chmod -R 777 /sdks/flutter

# Create app directory and set ownership
RUN mkdir -p /app && chown -R 1000:1000 /app

# Switch to non-root user
USER 1000

WORKDIR /app

# Configure git safe directory for Flutter SDK
RUN git config --global --add safe.directory /sdks/flutter

# Accept Android licenses
RUN yes | flutter doctor --android-licenses || true

# Pre-cache Flutter dependencies
RUN flutter precache

ENTRYPOINT ["flutter"]
