#!/bin/bash

USER_ID="$1"
CSV_FILE="$2"
PROJECT_ID="burpeebata"

if [ -z "$USER_ID" ] || [ -z "$CSV_FILE" ]; then
  echo "Usage: ./import_workouts.sh <user_id> <csv_file>"
  echo "Example: ./import_workouts.sh 3zqmtJb9CiZxKD7wx8avCGSWHRw1 user_records_export.csv"
  exit 1
fi

echo "🔥 Firebase Workout Import"
echo "User ID: $USER_ID"
echo "CSV File: $CSV_FILE"
echo "Project: $PROJECT_ID"
echo ""

# Get Firebase access token
echo "Getting access token..."
if command -v gcloud &> /dev/null; then
  ACCESS_TOKEN=$(gcloud auth print-access-token 2>/dev/null)
elif [ -f ~/.config/firebase/*.json ]; then
  echo "❌ Could not get access token. Please run: gcloud auth login"
  exit 1
else
  echo "❌ gcloud not found. Please install Google Cloud SDK"
  exit 1
fi

if [ -z "$ACCESS_TOKEN" ]; then
  echo "❌ Failed to get access token"
  exit 1
fi

echo "✓ Got access token"
echo ""

# Function to convert burpee type
map_burpee_type() {
  if [ "$1" == "Navy Seal" ]; then
    echo "1"
  else
    echo "0"
  fi
}

# Function to parse date (MM/DD/YYYY HH:MM:SS)
parse_date() {
  # Convert to ISO8601
  date -d "$1" -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || \
  date -j -f "%m/%d/%Y %H:%M:%S" "$1" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null
}

# Function to generate UUID
generate_uuid() {
  cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen
}

# Read CSV and import
count=0
success=0

tail -n +2 "$CSV_FILE" | while IFS=, read -r timestamp setCount setDuration repsPerSet restDuration countdownDuration burpeeType isCompleted isOnTime; do
  count=$((count + 1))

  # Generate workout ID
  workout_id=$(generate_uuid)

  # Parse values
  burpee_type_idx=$(map_burpee_type "$burpeeType")
  date_iso=$(parse_date "$timestamp")
  elapsed_seconds=$(( setCount * setDuration + (setCount - 1) * restDuration ))

  # Build Firestore document
  doc_data=$(cat <<EOF
{
  "fields": {
    "id": {"stringValue": "$workout_id"},
    "date": {"stringValue": "$date_iso"},
    "burpeeType": {"integerValue": "$burpee_type_idx"},
    "repsPerSet": {"integerValue": "$repsPerSet"},
    "secondsPerSet": {"integerValue": "$setDuration"},
    "numberOfSets": {"integerValue": "$setCount"},
    "restBetweenSets": {"integerValue": "$restDuration"},
    "completed": {"booleanValue": $([ "$isCompleted" == "TRUE" ] && echo "true" || echo "false")},
    "completedSets": {"integerValue": "$setCount"},
    "isCompleted": {"booleanValue": $([ "$isCompleted" == "TRUE" ] && echo "true" || echo "false")},
    "isCompletedInTime": {"booleanValue": $([ "$isOnTime" == "TRUE" ] && echo "true" || echo "false")},
    "elapsedSeconds": {"integerValue": "$elapsed_seconds"}
  }
}
EOF
)

  # Upload to Firestore
  url="https://firestore.googleapis.com/v1/projects/$PROJECT_ID/databases/(default)/documents/users/$USER_ID/workouts?documentId=$workout_id"

  response=$(curl -s -w "\n%{http_code}" -X POST "$url" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$doc_data")

  http_code=$(echo "$response" | tail -n1)

  if [ "$http_code" == "200" ] || [ "$http_code" == "201" ]; then
    echo "✓ [$count] Imported: $timestamp"
    success=$((success + 1))
  else
    echo "✗ [$count] Failed: $timestamp (HTTP $http_code)"
  fi
done

echo ""
echo "✅ Import complete!"
echo "   Imported: $success workouts"
