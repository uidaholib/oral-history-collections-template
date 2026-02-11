#!/usr/bin/env python3
"""
Updates the transcriptionist field in lcoh.csv based on transcript source.

- Items with display_template "transcript" whose objectid matches a file in 
  transcripts-from-transcriptwork-repo get "Transcription created by Premiere"
- Other items with display_template "transcript" get "Legacy transcription"
"""

import csv
import os
from pathlib import Path

# Paths
BASE_DIR = Path(__file__).parent
LCOH_CSV = BASE_DIR / "_data" / "lcoh.csv"
PREMIERE_DIR = BASE_DIR / "_data" / "transcripts-from-transcriptwork-repo"

def get_premiere_objectids():
    """Get set of objectids from transcripts-from-transcriptwork-repo directory."""
    premiere_ids = set()
    if PREMIERE_DIR.exists():
        for filename in os.listdir(PREMIERE_DIR):
            if filename.endswith('.csv'):
                # Strip .csv extension to get objectid
                objectid = filename[:-4]
                premiere_ids.add(objectid)
    return premiere_ids

def update_transcriptionist():
    """Update transcriptionist field in lcoh.csv."""
    premiere_ids = get_premiere_objectids()
    print(f"Found {len(premiere_ids)} transcripts in transcripts-from-transcriptwork-repo")
    
    # Read the CSV
    rows = []
    fieldnames = None
    with open(LCOH_CSV, 'r', newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    # Track changes
    premiere_count = 0
    legacy_count = 0
    
    # Update rows
    for row in rows:
        if row.get('display_template') == 'transcript':
            objectid = row.get('objectid', '')
            if objectid in premiere_ids:
                row['transcriptionist'] = 'Transcription created by Premiere'
                premiere_count += 1
            else:
                row['transcriptionist'] = 'Legacy transcription'
                legacy_count += 1
    
    # Write back
    with open(LCOH_CSV, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"Updated {premiere_count} transcripts to 'Transcription created by Premiere'")
    print(f"Updated {legacy_count} transcripts to 'Legacy transcription'")
    print(f"Total transcript items updated: {premiere_count + legacy_count}")

if __name__ == "__main__":
    update_transcriptionist()
