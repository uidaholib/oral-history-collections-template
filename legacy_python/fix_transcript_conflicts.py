#!/usr/bin/env python3
"""
Fix transcript conflicts by changing display_template to 'record' for secondary people.

For interviews with multiple people, keeps the first alphabetically as 'transcript'
and changes others to 'record' so only one CSV is generated.

Usage:
    python3 fix_transcript_conflicts.py          # Dry run
    python3 fix_transcript_conflicts.py --execute # Apply changes
"""

import csv
import argparse
from pathlib import Path
from collections import defaultdict


def analyze_and_fix_conflicts(csv_path, execute=False):
    """
    Analyze conflicts and change display_template for secondary people.
    
    Args:
        csv_path: Path to lcoh.csv
        execute: If True, write changes back to CSV
    
    Returns:
        List of changes made
    """
    # Read all rows
    rows = []
    fieldnames = []
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        fieldnames = reader.fieldnames
        rows = list(reader)
    
    # Find transcript_xml conflicts
    xml_to_rows = defaultdict(list)
    
    for i, row in enumerate(rows):
        transcript_xml = row.get('transcript_xml', '').strip()
        display_template = row.get('display_template', '').strip()
        
        if transcript_xml and display_template == 'transcript':
            xml_to_rows[transcript_xml].append(i)
    
    # Identify conflicts and determine changes
    changes = []
    
    for xml, row_indices in xml_to_rows.items():
        if len(row_indices) > 1:
            # Get objectids for these rows
            objectids = [(rows[i]['objectid'], i) for i in row_indices]
            objectids.sort()  # Sort alphabetically
            
            # First alphabetically stays as 'transcript', others become 'record'
            primary_objectid, primary_idx = objectids[0]
            
            for objectid, idx in objectids[1:]:
                changes.append({
                    'xml': xml,
                    'objectid': objectid,
                    'row_index': idx,
                    'old_template': 'transcript',
                    'new_template': 'record',
                    'primary_objectid': primary_objectid
                })
                
                # Apply change to row data
                rows[idx]['display_template'] = 'record'
    
    # Write changes if execute is True
    if execute and changes:
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
    
    return changes, xml_to_rows


def main():
    """Main execution."""
    parser = argparse.ArgumentParser(
        description='Fix transcript conflicts by changing display_template for secondary people'
    )
    parser.add_argument(
        '--execute',
        action='store_true',
        help='Actually apply changes (default is dry-run mode)'
    )
    args = parser.parse_args()
    
    # Set up paths
    script_dir = Path(__file__).parent
    csv_path = script_dir / "_data" / "lcoh.csv"
    
    if not csv_path.exists():
        print(f"Error: Could not find {csv_path}")
        return
    
    print(f"Analyzing transcript conflicts in {csv_path}...\n")
    print("="*80)
    
    changes, xml_to_rows = analyze_and_fix_conflicts(csv_path, execute=args.execute)
    
    if not args.execute:
        print("\n=== DRY RUN (use --execute to apply changes) ===\n")
    else:
        print("\n=== APPLYING CHANGES ===\n")
    
    # Group changes by XML file
    by_xml = defaultdict(list)
    for change in changes:
        by_xml[change['xml']].append(change)
    
    print(f"FOUND {len(by_xml)} SHARED INTERVIEWS WITH CONFLICTS\n")
    
    for xml in sorted(by_xml.keys()):
        xml_changes = by_xml[xml]
        primary = xml_changes[0]['primary_objectid']
        
        print(f"\n{xml}")
        print(f"  ✓ PRIMARY (keeps transcript): {primary}")
        
        for change in xml_changes:
            print(f"  → SECONDARY (change to record): {change['objectid']}")
    
    print(f"\n{'='*80}")
    print(f"SUMMARY: {len(changes)} objectids will be changed from 'transcript' to 'record'")
    print("="*80)
    
    if args.execute and changes:
        print(f"\n✓ Changes applied to {csv_path}")
        
        # Write report
        report_path = script_dir / "transcript_fix_report.txt"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("TRANSCRIPT CONFLICT FIX REPORT\n")
            f.write("="*80 + "\n\n")
            f.write(f"Total shared interviews: {len(by_xml)}\n")
            f.write(f"Total objectids changed: {len(changes)}\n\n")
            f.write("="*80 + "\n")
            f.write("CHANGES APPLIED\n")
            f.write("="*80 + "\n\n")
            
            for xml in sorted(by_xml.keys()):
                xml_changes = by_xml[xml]
                primary = xml_changes[0]['primary_objectid']
                
                f.write(f"{xml}\n")
                f.write(f"  PRIMARY: {primary} (display_template=transcript)\n")
                for change in xml_changes:
                    f.write(f"  CHANGED: {change['objectid']} (display_template=record)\n")
                f.write("\n")
        
        print(f"✓ Report written to: {report_path}")
    elif not args.execute:
        print(f"\n→ Run with --execute to apply these changes")


if __name__ == "__main__":
    main()
