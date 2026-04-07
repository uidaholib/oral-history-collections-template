#!/usr/bin/env python3
"""
Rename transcript and index CSV files to match objectid from lcoh.csv.

Matches files based on the transcript_xml field, which contains the original
XML filename (e.g., "Adair1.xml"). The script normalizes this to match the
current CSV filenames (e.g., "adair_1.csv") and renames them to match the
objectid (e.g., "adair_ione_1.csv").

Usage:
    python3 rename_transcripts_indexes.py          # Dry run (shows changes)
    python3 rename_transcripts_indexes.py --execute # Actually rename files
"""

import csv
import os
import re
import argparse
from pathlib import Path
from collections import defaultdict


def normalize_xml_filename(xml_filename):
    """
    Normalize XML filename to match the CSV filename pattern.

    Args:
        xml_filename: Original XML filename (e.g., "Adair1.xml")

    Returns:
        Normalized CSV filename (e.g., "adair_1.csv")
    """
    # Remove .xml extension
    base_name = xml_filename.replace('.xml', '')

    # Convert to lowercase
    base_name = base_name.lower()

    # Insert underscore before numbers if not already present
    base_name = re.sub(r'([a-z])(\d)', r'\1_\2', base_name)

    return f"{base_name}.csv"


def build_rename_mapping(csv_path):
    """
    Build a mapping from current filenames to desired filenames.

    Args:
        csv_path: Path to lcoh.csv

    Returns:
        Dict mapping current_filename -> new_filename (objectid)
    """
    rename_map = {}
    conflicts = defaultdict(list)

    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)

        for row in reader:
            objectid = row.get('objectid', '').strip()
            transcript_xml = row.get('transcript_xml', '').strip()

            # Skip rows without transcript_xml or objectid
            if not transcript_xml or not objectid:
                continue

            # Normalize the XML filename to match current CSV filenames
            current_filename = normalize_xml_filename(transcript_xml)
            new_filename = f"{objectid}.csv"

            # Check for conflicts (same current file maps to multiple objectids)
            if current_filename in rename_map:
                conflicts[current_filename].append(new_filename)
            else:
                rename_map[current_filename] = new_filename

    return rename_map, conflicts


def rename_files_in_directory(directory, rename_map, dry_run=True):
    """
    Rename files in a directory based on the rename mapping.

    Args:
        directory: Path to directory containing files to rename
        rename_map: Dict mapping current_filename -> new_filename
        dry_run: If True, only show what would be renamed

    Returns:
        Tuple of (renamed_count, skipped_count, error_count)
    """
    directory = Path(directory)
    renamed = 0
    skipped = 0
    errors = 0

    # Get all CSV files in directory
    csv_files = sorted(directory.glob("*.csv"))

    for csv_file in csv_files:
        current_name = csv_file.name

        # Check if this file should be renamed
        if current_name in rename_map:
            new_name = rename_map[current_name]
            new_path = directory / new_name

            # Check if target already exists
            if new_path.exists() and new_path != csv_file:
                print(f"  ✗ {current_name} -> {new_name} (target exists)")
                errors += 1
                continue

            # Check if already has correct name
            if current_name == new_name:
                print(f"  ✓ {current_name} (already correct)")
                skipped += 1
                continue

            # Perform rename (or show what would happen)
            if dry_run:
                print(f"  ✓ {current_name:40} -> {new_name}")
            else:
                try:
                    csv_file.rename(new_path)
                    print(f"  ✓ {current_name:40} -> {new_name}")
                    renamed += 1
                except Exception as e:
                    print(f"  ✗ {current_name} -> {new_name} (error: {e})")
                    errors += 1
                    continue

            if dry_run:
                renamed += 1
        else:
            # File not in rename map - keep original name
            print(f"  ⊘ {current_name} (no mapping found, keeping original)")
            skipped += 1

    return renamed, skipped, errors


def main():
    """Main execution."""
    parser = argparse.ArgumentParser(
        description='Rename transcript and index files to match objectids from lcoh.csv'
    )
    parser.add_argument(
        '--execute',
        action='store_true',
        help='Actually rename files (default is dry-run mode)'
    )
    args = parser.parse_args()

    # Set up paths
    script_dir = Path(__file__).parent
    csv_path = script_dir / "_data" / "lcoh.csv"
    transcripts_dir = script_dir / "_data" / "transcripts"
    indexes_dir = script_dir / "_data" / "indexes"

    # Check if CSV exists
    if not csv_path.exists():
        print(f"Error: Could not find {csv_path}")
        return

    # Build rename mapping
    print(f"Reading {csv_path}...")
    rename_map, conflicts = build_rename_mapping(csv_path)

    print(f"\nFound {len(rename_map)} files to potentially rename")

    # Report conflicts
    if conflicts:
        print(f"\n⚠ Warning: Found {len(conflicts)} conflicts:")
        for current, targets in conflicts.items():
            print(f"  {current} maps to multiple objectids: {', '.join(targets)}")
        print()

    # Determine mode
    if args.execute:
        print("\n=== EXECUTING RENAMES ===\n")
    else:
        print("\n=== DRY RUN (use --execute to actually rename files) ===\n")

    # Rename transcripts
    print(f"Processing transcripts in {transcripts_dir}...\n")
    trans_renamed, trans_skipped, trans_errors = rename_files_in_directory(
        transcripts_dir, rename_map, dry_run=not args.execute
    )

    print(f"\n{'='*70}")
    print(f"Transcripts: {trans_renamed} renamed, {trans_skipped} skipped, {trans_errors} errors")

    # Rename indexes
    print(f"\n{'='*70}")
    print(f"Processing indexes in {indexes_dir}...\n")
    index_renamed, index_skipped, index_errors = rename_files_in_directory(
        indexes_dir, rename_map, dry_run=not args.execute
    )

    print(f"\n{'='*70}")
    print(f"Indexes: {index_renamed} renamed, {index_skipped} skipped, {index_errors} errors")

    # Final summary
    print(f"\n{'='*70}")
    print("SUMMARY")
    print(f"{'='*70}")
    total_renamed = trans_renamed + index_renamed
    total_skipped = trans_skipped + index_skipped
    total_errors = trans_errors + index_errors

    print(f"Total files renamed: {total_renamed}")
    print(f"Total files skipped: {total_skipped}")
    print(f"Total errors: {total_errors}")

    if not args.execute:
        print(f"\n✓ This was a dry run. Use --execute to actually rename files.")


if __name__ == "__main__":
    main()
