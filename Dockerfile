FROM cirrusci/flutter:stable

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Create non-root user
RUN groupadd -r flutter && useradd -r -g flutter -m -d /home/flutter flutter

# Set up Flutter SDK permissions - make writable by any user for development
RUN chmod -R 777 /sdks/flutter

# Create app directory and set ownership
RUN mkdir -p /app && chown -R flutter:flutter /app

# Switch to non-root user
USER flutter

WORKDIR /app

# Accept Android licenses
RUN yes | flutter doctor --android-licenses || true

# Pre-cache Flutter dependencies
RUN flutter precache

ENTRYPOINT ["flutter"]
