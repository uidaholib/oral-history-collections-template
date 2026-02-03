#!/usr/bin/env python3
"""
Convert XML interview files to CSV transcript format for OHD/CollectionBuilder.

Reads XML files from xml/ directory and converts transcript text to CSV format
matching the example.csv structure (speaker, words, tags, timestamp).

Output files are saved to _data/transcripts-from-xml/
"""

import xml.etree.ElementTree as ET
import csv
import os
import re
from pathlib import Path


def normalize_filename(filename):
    """
    Normalize filename to lowercase with underscores before numbers.

    Examples:
        Adair1 -> adair_1
        Anderson_Axel2 -> anderson_axel_2
        Clark_J -> clark_j

    Args:
        filename: Base filename without extension

    Returns:
        Normalized lowercase filename with underscores before numbers
    """
    # Convert to lowercase
    filename = filename.lower()

    # Insert underscore before numbers if not already present
    # Pattern: look for letter followed by number without underscore between
    filename = re.sub(r'([a-z])(\d)', r'\1_\2', filename)

    return filename


def parse_transcript_text(transcript_text):
    """
    Parse semi-structured transcript text into lines with speaker and words.

    The transcript text appears to be OCR'd and has patterns like:
    "IO:  Some text here. More text."
    "SS: Response text."

    Returns list of dicts with keys: speaker, words, tags, timestamp
    """
    if not transcript_text or transcript_text.strip() == "No transcript available.":
        return []

    lines = []
    current_speaker = ""

    # Split by line breaks and process
    raw_lines = transcript_text.split('\n')

    for line in raw_lines:
        line = line.strip()
        if not line:
            continue

        # Look for speaker pattern: "INITIALS:" or "NAME:" at start of line
        speaker_match = re.match(r'^([A-Z]{1,3}|[A-Z][a-z]+(?:\s+[A-Z][a-z]+)?):\s*(.*)$', line)

        if speaker_match:
            current_speaker = speaker_match.group(1)
            words = speaker_match.group(2).strip()
            if words:
                lines.append({
                    'speaker': current_speaker,
                    'words': words,
                    'tags': '',
                    'timestamp': ''
                })
        else:
            # Continuation of previous speaker's words
            if line:
                lines.append({
                    'speaker': current_speaker if current_speaker else '',
                    'words': line,
                    'tags': '',
                    'timestamp': ''
                })

    return lines


def convert_xml_to_transcript_csv(xml_file_path, output_dir):
    """
    Convert a single XML file to transcript CSV format.

    Args:
        xml_file_path: Path to the XML file
        output_dir: Directory to save the CSV file

    Returns:
        True if successful, False otherwise
    """
    try:
        # Parse XML
        tree = ET.parse(xml_file_path)
        root = tree.getroot()

        # Extract transcript text
        transcript_elem = root.find('.//transcript')
        if transcript_elem is None or not transcript_elem.text:
            print(f"⊘ {Path(xml_file_path).stem}: No transcript element found")
            return False

        transcript_text = transcript_elem.text.strip()

        if transcript_text == "No transcript available.":
            print(f"⊘ {Path(xml_file_path).stem}: No transcript available")
            return False

        # Parse transcript into structured lines
        lines = parse_transcript_text(transcript_text)

        if not lines:
            print(f"⊘ {Path(xml_file_path).stem}: Could not parse transcript text")
            return False

        # Create output filename (normalize to lowercase with underscores)
        base_name = Path(xml_file_path).stem
        normalized_name = normalize_filename(base_name)
        output_file = output_dir / f"{normalized_name}.csv"

        # Write CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['speaker', 'words', 'tags', 'timestamp']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(lines)

        print(f"✓ {normalized_name}.csv ({len(lines)} lines)")
        return True

    except Exception as e:
        print(f"✗ {Path(xml_file_path).stem}: Error - {str(e)}")
        return False


def main():
    """Main conversion process."""
    # Set up paths
    script_dir = Path(__file__).parent
    xml_dir = script_dir / "xml"
    output_dir = script_dir / "_data" / "transcripts-from-xml"

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get all XML files
    xml_files = sorted(xml_dir.glob("*.xml"))

    if not xml_files:
        print("No XML files found in xml/ directory")
        return

    print(f"Found {len(xml_files)} XML files to process\n")
    print("Converting transcripts to CSV...\n")

    # Convert each file
    success_count = 0
    skip_count = 0
    error_count = 0

    for xml_file in xml_files:
        result = convert_xml_to_transcript_csv(xml_file, output_dir)
        if result:
            success_count += 1
        elif result is False:
            skip_count += 1

    print(f"\n{'='*60}")
    print(f"Conversion complete!")
    print(f"  ✓ Successfully converted: {success_count}")
    print(f"  ⊘ Skipped (no transcript): {skip_count}")
    print(f"  ✗ Errors: {error_count}")
    print(f"\nOutput directory: {output_dir}")


if __name__ == "__main__":
    main()
