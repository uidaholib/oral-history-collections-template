#!/usr/bin/env python3
"""
Convert XML interview index data to CSV format for OHD/CollectionBuilder.

Reads XML files from xml/ directory and converts <index><point> elements
to CSV format with columns: time, title, description.

Output files are saved to _data/indexes/
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


def seconds_to_timestamp(seconds):
    """
    Convert seconds to timestamp format [MM:SS] or [H:MM:SS].

    Args:
        seconds: Integer seconds

    Returns:
        Formatted timestamp string like [0:15], [2:30], or [1:15:30]
    """
    try:
        seconds = int(seconds)
    except (ValueError, TypeError):
        return "[0:00]"

    hours = seconds // 3600
    minutes = (seconds % 3600) // 60
    secs = seconds % 60

    if hours > 0:
        return f"[{hours}:{minutes:02d}:{secs:02d}]"
    else:
        return f"[{minutes}:{secs:02d}]"


def clean_text(text):
    """
    Clean multi-line text by removing extra whitespace and line breaks.

    Args:
        text: Raw text string

    Returns:
        Cleaned single-line text
    """
    if not text:
        return ""

    # Replace multiple whitespace with single space
    text = re.sub(r'\s+', ' ', text)
    # Strip leading/trailing whitespace
    text = text.strip()

    return text


def extract_index_from_xml(xml_file_path):
    """
    Extract index points from XML file.

    Args:
        xml_file_path: Path to the XML file

    Returns:
        List of dicts with keys: time, title, description
    """
    try:
        # Parse XML
        tree = ET.parse(xml_file_path)
        root = tree.getroot()

        # Find index element
        index_elem = root.find('.//index')
        if index_elem is None:
            return None

        # Extract all point elements
        points = index_elem.findall('point')
        if not points:
            return None

        index_data = []
        for point in points:
            time_elem = point.find('time')
            title_elem = point.find('title')
            synopsis_elem = point.find('synopsis')

            # Convert time to timestamp
            time_seconds = time_elem.text if time_elem is not None else "0"
            timestamp = seconds_to_timestamp(time_seconds)

            # Clean title and description
            title = clean_text(title_elem.text) if title_elem is not None else ""
            description = clean_text(synopsis_elem.text) if synopsis_elem is not None else ""

            index_data.append({
                'time': timestamp,
                'title': title,
                'description': description
            })

        return index_data if index_data else None

    except Exception as e:
        raise Exception(f"Error parsing XML: {str(e)}")


def convert_xml_to_index_csv(xml_file_path, output_dir):
    """
    Convert a single XML file's index to CSV format.

    Args:
        xml_file_path: Path to the XML file
        output_dir: Directory to save the CSV file

    Returns:
        True if successful, False if skipped (no index), raises Exception on error
    """
    try:
        # Extract index data
        index_data = extract_index_from_xml(xml_file_path)

        if index_data is None:
            print(f"⊘ {Path(xml_file_path).stem}: No index data found")
            return False

        # Create output filename (normalize to lowercase with underscores)
        base_name = Path(xml_file_path).stem
        normalized_name = normalize_filename(base_name)
        output_file = output_dir / f"{normalized_name}.csv"

        # Write CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['time', 'title', 'description']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(index_data)

        print(f"✓ {normalized_name}.csv ({len(index_data)} index points)")
        return True

    except Exception as e:
        print(f"✗ {Path(xml_file_path).stem}: Error - {str(e)}")
        return False


def main():
    """Main conversion process."""
    # Set up paths
    script_dir = Path(__file__).parent
    xml_dir = script_dir / "xml"
    output_dir = script_dir / "_data" / "indexes"

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Get all XML files
    xml_files = sorted(xml_dir.glob("*.xml"))

    if not xml_files:
        print("No XML files found in xml/ directory")
        return

    print(f"Found {len(xml_files)} XML files to process\n")
    print("Converting indexes to CSV...\n")

    # Convert each file
    success_count = 0
    skip_count = 0
    error_count = 0

    for xml_file in xml_files:
        result = convert_xml_to_index_csv(xml_file, output_dir)
        if result:
            success_count += 1
        else:
            skip_count += 1

    print(f"\n{'='*60}")
    print(f"Conversion complete!")
    print(f"  ✓ Successfully converted: {success_count}")
    print(f"  ⊘ Skipped (no index): {skip_count}")
    print(f"  ✗ Errors: {error_count}")
    print(f"\nOutput directory: {output_dir}")


if __name__ == "__main__":
    main()
