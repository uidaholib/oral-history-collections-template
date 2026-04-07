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
from datetime import datetime


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


def build_objectid_mapping(csv_path):
    """
    Build a mapping from normalized XML filenames to objectids.
    
    Args:
        csv_path: Path to lcoh.csv
    
    Returns:
        Dict mapping normalized XML filename -> objectid
    """
    mapping = {}
    
    try:
        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            
            for row in reader:
                objectid = row.get('objectid', '').strip()
                transcript_xml = row.get('transcript_xml', '').strip()
                display_template = row.get('display_template', '').strip()
                
                # Skip rows without transcript_xml or objectid
                if not transcript_xml or not objectid:
                    continue
                
                # Only include rows with display_template='transcript'
                # This excludes secondary people in shared interviews
                if display_template != 'transcript':
                    continue
                
                # Normalize the XML filename to match current CSV filenames
                normalized = normalize_xml_filename(transcript_xml)
                mapping[normalized] = objectid
    
    except Exception as e:
        print(f"Warning: Could not load objectid mapping from {csv_path}: {e}")
    
    return mapping


def parse_transcript_text(transcript_text):
    """
    Parse semi-structured transcript text into lines with speaker and words.
    Accumulates continuation lines until empty line (paragraph break).

    The transcript text appears to be OCR'd and has patterns like:
    "SAM SCHRAGER: Some text here. More text."
    "LC: Response text."

    Returns list of dicts with keys: speaker, words, tags, timestamp
    """
    if not transcript_text or transcript_text.strip() == "No transcript available.":
        return []

    lines = []
    current_speaker = ""
    accumulated_words = []

    # Split by line breaks and process
    raw_lines = transcript_text.split('\n')

    for line in raw_lines:
        line = line.strip()
        
        # Empty line = paragraph break, output accumulated words
        if not line:
            if accumulated_words:
                lines.append({
                    'speaker': current_speaker,
                    'words': ' '.join(accumulated_words),
                    'tags': '',
                    'timestamp': ''
                })
                accumulated_words = []
            continue

        # Speaker pattern: Only match all-caps names (uppercase letters and spaces only)
        # This prevents sentence fragments like "And Isaac Stevens wrote:" from matching
        speaker_match = re.match(r'^([A-Z][A-Z\s]+?):\s*(.*)$', line)

        if speaker_match and len(speaker_match.group(1)) <= 50:
            # New speaker detected - output previous accumulated words first
            if accumulated_words:
                lines.append({
                    'speaker': current_speaker,
                    'words': ' '.join(accumulated_words),
                    'tags': '',
                    'timestamp': ''
                })
                accumulated_words = []
            
            current_speaker = speaker_match.group(1).strip()
            words = speaker_match.group(2).strip()
            if words:
                accumulated_words.append(words)
        else:
            # Continuation line - accumulate
            if line:
                accumulated_words.append(line)

    # Output final accumulated words
    if accumulated_words:
        lines.append({
            'speaker': current_speaker,
            'words': ' '.join(accumulated_words),
            'tags': '',
            'timestamp': ''
        })

    return lines


def convert_xml_to_transcript_csv(xml_file_path, output_dir, objectid_mapping=None):
    """
    Convert a single XML file to transcript CSV format.

    Args:
        xml_file_path: Path to the XML file
        output_dir: Directory to save the CSV file
        objectid_mapping: Dict mapping normalized XML filenames to objectids

    Returns:
        Tuple (status, used_objectid, output_filename)
        status: 'success', 'skip', or 'error'
        used_objectid: True if objectid was used, False if fallback name
        output_filename: Name of output CSV file
    """
    try:
        # Parse XML
        tree = ET.parse(xml_file_path)
        root = tree.getroot()

        # Extract transcript text
        transcript_elem = root.find('.//transcript')
        if transcript_elem is None or not transcript_elem.text:
            print(f"⊘ {Path(xml_file_path).stem}: No transcript element found")
            return ('skip', False, None)

        transcript_text = transcript_elem.text.strip()

        if transcript_text == "No transcript available.":
            print(f"⊘ {Path(xml_file_path).stem}: No transcript available")
            return ('skip', False, None)

        # Parse transcript into structured lines
        lines = parse_transcript_text(transcript_text)

        if not lines:
            print(f"⊘ {Path(xml_file_path).stem}: Could not parse transcript text")
            return ('skip', False, None)

        # Determine output filename
        base_name = Path(xml_file_path).stem
        normalized_name = normalize_filename(base_name)
        normalized_xml = normalize_xml_filename(f"{base_name}.xml")
        
        # Try to get objectid from mapping
        used_objectid = False
        if objectid_mapping and normalized_xml in objectid_mapping:
            output_filename = objectid_mapping[normalized_xml].replace('.csv', '')
            used_objectid = True
        else:
            output_filename = normalized_name
        
        output_file = output_dir / f"{output_filename}.csv"

        # Write CSV
        with open(output_file, 'w', newline='', encoding='utf-8') as csvfile:
            fieldnames = ['speaker', 'words', 'tags', 'timestamp']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(lines)

        print(f"✓ {output_filename}.csv ({len(lines)} lines)")
        return ('success', used_objectid, f"{output_filename}.csv")

    except Exception as e:
        print(f"✗ {Path(xml_file_path).stem}: Error - {str(e)}")
        return ('error', False, None)


def main():
    """Main conversion process."""
    # Set up paths
    script_dir = Path(__file__).parent
    xml_dir = script_dir / "xml"
    output_dir = script_dir / "_data" / "transcripts"
    lcoh_csv = script_dir / "_data" / "lcoh.csv"

    # Create output directory if it doesn't exist
    output_dir.mkdir(parents=True, exist_ok=True)

    # Load objectid mapping
    print("Loading objectid mapping from lcoh.csv...")
    objectid_mapping = build_objectid_mapping(lcoh_csv)
    print(f"Loaded {len(objectid_mapping)} objectid mappings\n")

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
    objectid_used_count = 0
    fallback_used_count = 0
    
    successful_conversions = []
    fallback_files = []

    for xml_file in xml_files:
        status, used_objectid, output_filename = convert_xml_to_transcript_csv(
            xml_file, output_dir, objectid_mapping
        )
        
        if status == 'success':
            success_count += 1
            if used_objectid:
                objectid_used_count += 1
                successful_conversions.append(output_filename)
            else:
                fallback_used_count += 1
                fallback_files.append((xml_file.name, output_filename))
        elif status == 'skip':
            skip_count += 1
        else:
            error_count += 1

    # Print summary
    print(f"\n{'='*60}")
    print(f"Conversion complete!")
    print(f"  ✓ Successfully converted: {success_count}")
    print(f"    - With objectid names: {objectid_used_count}")
    print(f"    - With fallback names: {fallback_used_count}")
    print(f"  ⊘ Skipped (no transcript): {skip_count}")
    print(f"  ✗ Errors: {error_count}")
    print(f"\nOutput directory: {output_dir}")

    # Generate report file
    timestamp = datetime.now().strftime('%Y%m%d')
    report_path = script_dir / f"transcript_conversion_report_{timestamp}.txt"
    
    with open(report_path, 'w', encoding='utf-8') as report:
        report.write(f"Transcript Conversion Report - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        report.write(f"{'='*60}\n\n")
        
        report.write(f"Total XML files processed: {len(xml_files)}\n\n")
        
        report.write(f"SUMMARY:\n")
        report.write(f"  ✓ Successfully converted: {success_count}\n")
        report.write(f"    - With objectid names: {objectid_used_count}\n")
        report.write(f"    - With fallback names: {fallback_used_count}\n")
        report.write(f"  ⊘ Skipped (no transcript): {skip_count}\n")
        report.write(f"  ✗ Errors: {error_count}\n\n")
        
        if fallback_files:
            report.write(f"⚠ Warning: {len(fallback_files)} files used fallback names (no objectid mapping found):\n")
            for xml_name, csv_name in sorted(fallback_files):
                report.write(f"  {xml_name} -> {csv_name}\n")
            report.write(f"\n")
        
        report.write(f"\n{'='*60}\n")
        report.write(f"OUTPUT DIRECTORY: {output_dir}\n")
        report.write(f"\nConversion complete. {success_count} transcript CSVs generated.\n")
    
    print(f"\nReport saved to: {report_path}")


if __name__ == "__main__":
    main()
