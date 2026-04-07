#!/usr/bin/env python3
"""
Analyze transcript file sizes for oral history collection.
Checks all items with display_template='transcript' and reports on character counts.
"""

import csv
import os
from pathlib import Path

def analyze_transcripts():
    """Analyze transcript files and generate report."""
    
    # Path configuration
    base_dir = Path(__file__).parent
    metadata_file = base_dir / '_data' / 'lcoh.csv'
    transcripts_dir = base_dir / '_data' / 'transcripts'
    report_file = base_dir / 'transcript_size_report.txt'
    
    # Storage for results
    transcript_items = []
    missing_files = []
    
    print("Reading lcoh.csv...")
    
    # Read metadata and find transcript items
    with open(metadata_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            if row.get('display_template', '').strip() == 'transcript':
                objectid = row.get('objectid', '').strip()
                title = row.get('title', '').strip()
                
                if objectid:
                    # Check for transcript file
                    transcript_file = transcripts_dir / f"{objectid}.csv"
                    
                    if transcript_file.exists():
                        # Count characters in file
                        with open(transcript_file, 'r', encoding='utf-8') as tf:
                            content = tf.read()
                            char_count = len(content)
                        
                        transcript_items.append({
                            'objectid': objectid,
                            'title': title,
                            'char_count': char_count,
                            'file_path': str(transcript_file)
                        })
                    else:
                        missing_files.append({
                            'objectid': objectid,
                            'title': title,
                            'expected_path': str(transcript_file)
                        })
    
    # Sort by character count
    transcript_items.sort(key=lambda x: x['char_count'])
    
    # Generate report
    print(f"\nGenerating report to {report_file}...")
    
    with open(report_file, 'w', encoding='utf-8') as f:
        f.write("=" * 80 + "\n")
        f.write("TRANSCRIPT FILE SIZE ANALYSIS REPORT\n")
        f.write("=" * 80 + "\n\n")
        
        # Summary statistics
        f.write("SUMMARY\n")
        f.write("-" * 80 + "\n")
        f.write(f"Total transcript items in lcoh.csv: {len(transcript_items) + len(missing_files)}\n")
        f.write(f"Transcript files found: {len(transcript_items)}\n")
        f.write(f"Transcript files missing: {len(missing_files)}\n")
        
        if transcript_items:
            total_chars = sum(item['char_count'] for item in transcript_items)
            avg_chars = total_chars / len(transcript_items)
            f.write(f"Average character count: {avg_chars:,.0f}\n")
            f.write(f"Total characters across all transcripts: {total_chars:,}\n")
        
        f.write("\n")
        
        # Missing files
        if missing_files:
            f.write("=" * 80 + "\n")
            f.write(f"MISSING TRANSCRIPT FILES ({len(missing_files)})\n")
            f.write("=" * 80 + "\n\n")
            
            for item in missing_files:
                f.write(f"ObjectID: {item['objectid']}\n")
                f.write(f"Title: {item['title']}\n")
                f.write(f"Expected path: {item['expected_path']}\n")
                f.write("-" * 80 + "\n")
        
        # Top 10 smallest transcripts
        if transcript_items:
            f.write("\n")
            f.write("=" * 80 + "\n")
            f.write("10 SMALLEST TRANSCRIPT FILES\n")
            f.write("=" * 80 + "\n\n")
            
            smallest_10 = transcript_items[:10]
            for i, item in enumerate(smallest_10, 1):
                f.write(f"{i}. ObjectID: {item['objectid']}\n")
                f.write(f"   Title: {item['title']}\n")
                f.write(f"   Character count: {item['char_count']:,}\n")
                f.write(f"   File: {item['file_path']}\n")
                f.write("-" * 80 + "\n")
        
        # Full listing (sorted by size)
        if transcript_items:
            f.write("\n")
            f.write("=" * 80 + "\n")
            f.write("COMPLETE LISTING (sorted by character count, ascending)\n")
            f.write("=" * 80 + "\n\n")
            
            for item in transcript_items:
                f.write(f"ObjectID: {item['objectid']:<30} ")
                f.write(f"Chars: {item['char_count']:>10,}  ")
                f.write(f"Title: {item['title']}\n")
    
    # Console output
    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE")
    print("=" * 80)
    print(f"Total transcript items: {len(transcript_items) + len(missing_files)}")
    print(f"Files found: {len(transcript_items)}")
    print(f"Files missing: {len(missing_files)}")
    
    if missing_files:
        print(f"\n⚠️  WARNING: {len(missing_files)} transcript files are missing!")
        print("See report for details.")
    
    if transcript_items:
        print(f"\nSmallest transcript: {transcript_items[0]['objectid']} ({transcript_items[0]['char_count']:,} chars)")
        print(f"Largest transcript: {transcript_items[-1]['objectid']} ({transcript_items[-1]['char_count']:,} chars)")
    
    print(f"\nFull report saved to: {report_file}")

if __name__ == "__main__":
    analyze_transcripts()
