#!/bin/bash

# Script to increment the build number in pubspec.yaml
# Version format: major.minor.patch+buildNumber

PUBSPEC_FILE="pubspec.yaml"

# Read current version
current_version=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')

# Extract version name and build number
version_name=$(echo "$current_version" | cut -d'+' -f1)
build_number=$(echo "$current_version" | cut -d'+' -f2)

# Increment build number
new_build_number=$((build_number + 1))
new_version="${version_name}+${new_build_number}"

# Update pubspec.yaml
sed -i "s/^version: .*/version: ${new_version}/" "$PUBSPEC_FILE"

echo "Version incremented: ${current_version} → ${new_version}"
