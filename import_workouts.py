#!/usr/bin/env python3

import csv
import json
import sys
import requests
from datetime import datetime
from uuid import uuid4

def map_burpee_type(csv_type):
    """Map CSV burpee type to app enum index"""
    return 1 if csv_type == 'Navy Seal' else 0  # 0=militarySixCount, 1=navySeal

def parse_timestamp(timestamp_str):
    """Parse MM/DD/YYYY HH:MM:SS to ISO8601"""
    dt = datetime.strptime(timestamp_str, '%m/%d/%Y %H:%M:%S')
    return dt.isoformat() + 'Z'

def csv_row_to_workout(row):
    """Convert CSV row to Workout document"""
    set_count = int(row['SetCount'])
    set_duration = int(row['SetDuration'])
    rest_duration = int(row['RestDuration'])

    # Calculate elapsed seconds
    elapsed_seconds = (set_count * set_duration) + ((set_count - 1) * rest_duration)

    return {
        'id': str(uuid4()),
        'date': parse_timestamp(row['Timestamp']),
        'burpeeType': map_burpee_type(row['BurpeeType']),
        'repsPerSet': int(row['RepsPerSet']),
        'secondsPerSet': set_duration,
        'numberOfSets': set_count,
        'restBetweenSets': rest_duration,
        'completed': row['IsCompleted'] == 'TRUE',
        'completedSets': set_count,
        'isCompleted': row['IsCompleted'] == 'TRUE',
        'isCompletedInTime': row['IsOnTime'] == 'TRUE',
        'elapsedSeconds': elapsed_seconds,
    }

def import_workouts(user_id, csv_path, project_id='burpeebata'):
    """Import workouts from CSV to Firestore"""

    # Read CSV
    print(f'📄 Reading CSV: {csv_path}')
    workouts = []
    with open(csv_path, 'r') as f:
        reader = csv.DictReader(f)
        for row in reader:
            workout = csv_row_to_workout(row)
            workouts.append(workout)

    print(f'📊 Found {len(workouts)} workout records')
    print(f'👤 Target user ID: {user_id}')
    print(f'🔥 Target project: {project_id}')

    # Import using Firestore REST API
    base_url = f'https://firestore.googleapis.com/v1/projects/{project_id}/databases/(default)/documents'

    print('\n⚠️  To authenticate, you need to provide a Firebase ID token.')
    print('You can get this by:')
    print('1. Sign in to the app as alexandergarber@gmail.com')
    print('2. Get the ID token from Firebase Auth')
    print('\nOr run: gcloud auth print-identity-token')
    print('\nEnter ID token (or press Enter to skip and show cURL commands): ')

    id_token = input().strip()

    if not id_token:
        # Generate cURL commands instead
        print('\n📋 Copy and run these commands to import workouts:\n')
        for i, workout in enumerate(workouts, 1):
            doc_path = f'users/{user_id}/workouts/{workout["id"]}'
            url = f'{base_url}/{doc_path}'

            print(f'# Workout {i}/{len(workouts)}: {workout["date"]}')
            print(f'curl -X PATCH "{url}?updateMask=*" \\')
            print(f'  -H "Content-Type: application/json" \\')
            print(f'  -H "Authorization: Bearer YOUR_ID_TOKEN" \\')
            print(f'  -d \'{json.dumps({"fields": convert_to_firestore_fields(workout)})}\'')
            print()
        return

    # Import with ID token
    headers = {
        'Authorization': f'Bearer {id_token}',
        'Content-Type': 'application/json',
    }

    success_count = 0
    for i, workout in enumerate(workouts, 1):
        doc_path = f'users/{user_id}/workouts/{workout["id"]}'
        url = f'{base_url}/{doc_path}'

        # Convert to Firestore fields format
        data = {'fields': convert_to_firestore_fields(workout)}

        try:
            response = requests.patch(
                url,
                headers=headers,
                params={'updateMask': '*'},
                json=data
            )

            if response.status_code in [200, 201]:
                success_count += 1
                print(f'  ✓ [{i}/{len(workouts)}] Imported: {workout["date"]}')
            else:
                print(f'  ✗ [{i}/{len(workouts)}] Failed: {response.status_code} - {response.text}')
        except Exception as e:
            print(f'  ✗ [{i}/{len(workouts)}] Error: {e}')

    print(f'\n✅ Successfully imported {success_count}/{len(workouts)} workouts!')

def convert_to_firestore_fields(workout):
    """Convert workout dict to Firestore fields format"""
    fields = {}
    for key, value in workout.items():
        if isinstance(value, bool):
            fields[key] = {'booleanValue': value}
        elif isinstance(value, int):
            fields[key] = {'integerValue': str(value)}
        elif isinstance(value, str):
            fields[key] = {'stringValue': value}
    return fields

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print('Usage: python3 import_workouts.py <user_id> <csv_path>')
        print('Example: python3 import_workouts.py abc123xyz user_records_export.csv')
        sys.exit(1)

    user_id = sys.argv[1]
    csv_path = sys.argv[2]

    import_workouts(user_id, csv_path)
