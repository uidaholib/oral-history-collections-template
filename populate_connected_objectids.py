#!/usr/bin/env python3
"""
Populate connected_objectid field for records with display_template='record'.

For shared interviews, links secondary people to the primary person's objectid.

Usage:
    python3 populate_connected_objectids.py          # Dry run
    python3 populate_connected_objectids.py --execute # Apply changes
"""

import csv
import argparse
from pathlib import Path
from collections import defaultdict


def populate_connected_objectids(csv_path, execute=False):
    """
    Populate connected_objectid for records with display_template='record'.
    
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
    
    # Build mapping: transcript_xml -> primary objectid (where display_template='transcript')
    xml_to_primary = {}
    
    for row in rows:
        transcript_xml = row.get('transcript_xml', '').strip()
        display_template = row.get('display_template', '').strip()
        objectid = row.get('objectid', '').strip()
        
        if transcript_xml and display_template == 'transcript':
            xml_to_primary[transcript_xml] = objectid
    
    # Find records that need connected_objectid populated
    changes = []
    
    for i, row in enumerate(rows):
        transcript_xml = row.get('transcript_xml', '').strip()
        display_template = row.get('display_template', '').strip()
        objectid = row.get('objectid', '').strip()
        current_connected = (row.get('connected_objectid') or '').strip()
        
        if transcript_xml and display_template == 'record':
            # Find the primary objectid for this XML
            primary_objectid = xml_to_primary.get(transcript_xml)
            
            if primary_objectid:
                # Set connected_objectid to the primary objectid
                rows[i]['connected_objectid'] = primary_objectid
                
                changes.append({
                    'objectid': objectid,
                    'transcript_xml': transcript_xml,
                    'primary_objectid': primary_objectid,
                    'was_empty': not current_connected,
                    'old_value': current_connected
                })
    
    # Write changes if execute is True
    if execute and changes:
        with open(csv_path, 'w', newline='', encoding='utf-8') as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(rows)
    
    return changes, xml_to_primary


def main():
    """Main execution."""
    parser = argparse.ArgumentParser(
        description='Populate connected_objectid for records with display_template=record'
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
    
    print(f"Analyzing connected_objectid population needs in {csv_path}...\n")
    print("="*80)
    
    changes, xml_to_primary = populate_connected_objectids(csv_path, execute=args.execute)
    
    if not args.execute:
        print("\n=== DRY RUN (use --execute to apply changes) ===\n")
    else:
        print("\n=== APPLYING CHANGES ===\n")
    
    if not changes:
        print("No changes needed - all records already have correct connected_objectid!")
        return
    
    # Group changes by XML file
    by_xml = defaultdict(list)
    for change in changes:
        by_xml[change['transcript_xml']].append(change)
    
    print(f"FOUND {len(changes)} RECORDS NEEDING connected_objectid\n")
    
    for xml in sorted(by_xml.keys()):
        xml_changes = by_xml[xml]
        primary = xml_changes[0]['primary_objectid']
        
        print(f"\n{xml}")
        print(f"  → Primary objectid: {primary}")
        
        for change in xml_changes:
            status = "NEW" if change['was_empty'] else "UPDATE"
            old_val = f" (was: {change['old_value']})" if not change['was_empty'] else ""
            print(f"    [{status}] {change['objectid']} → {primary}{old_val}")
    
    print(f"\n{'='*80}")
    print(f"SUMMARY: {len(changes)} records will have connected_objectid populated")
    print("="*80)
    
    if args.execute and changes:
        print(f"\n✓ Changes applied to {csv_path}")
        
        # Write report
        report_path = script_dir / "connected_objectid_report.txt"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("CONNECTED OBJECTID POPULATION REPORT\n")
            f.write("="*80 + "\n\n")
            f.write(f"Total records updated: {len(changes)}\n\n")
            f.write("="*80 + "\n")
            f.write("CHANGES APPLIED\n")
            f.write("="*80 + "\n\n")
            
            for xml in sorted(by_xml.keys()):
                xml_changes = by_xml[xml]
                primary = xml_changes[0]['primary_objectid']
                
                f.write(f"{xml}\n")
                f.write(f"  Primary: {primary}\n")
                for change in xml_changes:
                    f.write(f"  {change['objectid']} → connected_objectid={primary}\n")
                f.write("\n")
        
        print(f"✓ Report written to: {report_path}")
    elif not args.execute:
        print(f"\n→ Run with --execute to apply these changes")


if __name__ == "__main__":
    main()
