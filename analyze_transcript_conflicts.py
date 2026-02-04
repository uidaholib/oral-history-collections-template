#!/usr/bin/env python3
"""
Analyze transcript_xml conflicts in lcoh.csv.

Identifies cases where the same transcript_xml file is referenced by multiple
objectids. This happens when interviews include multiple people (e.g., sisters
interviewed together).

Usage:
    python3 analyze_transcript_conflicts.py
"""

import csv
from pathlib import Path
from collections import defaultdict


def analyze_transcript_conflicts(csv_path):
    """
    Analyze which transcript_xml files map to multiple objectids.
    
    Args:
        csv_path: Path to lcoh.csv
    
    Returns:
        Dict mapping transcript_xml -> list of objectids
    """
    xml_to_objectids = defaultdict(list)
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        
        for row in reader:
            objectid = row.get('objectid', '').strip()
            transcript_xml = row.get('transcript_xml', '').strip()
            display_template = row.get('display_template', '').strip()
            
            # Only process rows that have transcript_xml and are transcripts
            if transcript_xml and objectid and display_template == 'transcript':
                xml_to_objectids[transcript_xml].append(objectid)
    
    return xml_to_objectids


def main():
    """Main execution."""
    # Set up paths
    script_dir = Path(__file__).parent
    csv_path = script_dir / "_data" / "lcoh.csv"
    
    if not csv_path.exists():
        print(f"Error: Could not find {csv_path}")
        return
    
    print(f"Analyzing transcript conflicts in {csv_path}...\n")
    print("="*80)
    
    xml_to_objectids = analyze_transcript_conflicts(csv_path)
    
    # Find conflicts (same XML maps to multiple objectids)
    conflicts = {xml: objectids for xml, objectids in xml_to_objectids.items() 
                 if len(objectids) > 1}
    
    # Find unique mappings
    unique = {xml: objectids for xml, objectids in xml_to_objectids.items() 
              if len(objectids) == 1}
    
    print(f"\nTOTAL TRANSCRIPT XML FILES: {len(xml_to_objectids)}")
    print(f"  Unique mappings (1 XML → 1 objectid): {len(unique)}")
    print(f"  Conflicts (1 XML → multiple objectids): {len(conflicts)}")
    
    if conflicts:
        print(f"\n{'='*80}")
        print(f"CONFLICTS FOUND: {len(conflicts)} transcript_xml files map to multiple objectids")
        print("="*80)
        print("\nThese interviews include multiple people and need resolution:\n")
        
        for xml, objectids in sorted(conflicts.items()):
            print(f"\n{xml} → {len(objectids)} objectids:")
            for objectid in sorted(objectids):
                print(f"    - {objectid}")
        
        print(f"\n{'='*80}")
        print("RECOMMENDATION:")
        print("="*80)
        print("""
Add a new column to lcoh.csv (e.g., 'transcript_objectid' or 'generate_transcript')
to explicitly control which objectid should generate the CSV from each XML file.

For shared interviews:
  - One person's objectid row should have the value set (to generate the CSV)
  - Other people's objectid rows should leave it empty (to skip CSV generation)
  
Example:
  objectid,transcript_xml,generate_transcript,...
  adair_ione_1,Adair1.xml,true,...           ← Generates adair_ione_1.csv
  cornelison_bernadine_1,Adair1.xml,,...     ← Skips generation, uses adair_ione_1.csv
        """)
        
        # Write detailed report to file
        report_path = script_dir / "transcript_conflict_report.txt"
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write("TRANSCRIPT CONFLICT ANALYSIS REPORT\n")
            f.write("="*80 + "\n\n")
            f.write(f"Total transcript XML files: {len(xml_to_objectids)}\n")
            f.write(f"Unique mappings: {len(unique)}\n")
            f.write(f"Conflicts: {len(conflicts)}\n\n")
            f.write("="*80 + "\n")
            f.write("CONFLICTS (Same XML → Multiple Objectids)\n")
            f.write("="*80 + "\n\n")
            
            for xml, objectids in sorted(conflicts.items()):
                f.write(f"{xml}\n")
                for objectid in sorted(objectids):
                    f.write(f"  → {objectid}\n")
                f.write("\n")
            
            f.write("="*80 + "\n")
            f.write("UNIQUE MAPPINGS (For reference)\n")
            f.write("="*80 + "\n\n")
            
            for xml, objectids in sorted(unique.items()):
                f.write(f"{xml} → {objectids[0]}\n")
        
        print(f"\nDetailed report written to: {report_path}")
    else:
        print("\n✓ No conflicts found! All transcript_xml files map to unique objectids.")


if __name__ == "__main__":
    main()
