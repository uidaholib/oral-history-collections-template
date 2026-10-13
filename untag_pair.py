#!/usr/bin/env python3
"""
Remove a tag and a term from transcript rows where BOTH appear together.

    python3 untag_pair.py canadian richmond            # preview only
    python3 untag_pair.py canadian richmond --apply    # make the changes

  - TAG is removed from the tags column, TERM from the terms column, but only on
    rows where the tags column has TAG and the terms column has TERM.
  - Only the last two columns (tags, terms) are edited. The dialogue and every
    other row stay byte-for-byte as they were, including quoting and line endings.
  - Matching is whole-entry and case-insensitive: "richmond" removes "richmond",
    not "richmond hotel". A leftover separator is cleaned up ("a;b" -> "a").
  - Default folder: _data/transcripts (run from the repo root), or pass --dir.
"""
import argparse
import pathlib
import sys


def split_records(text, newline):
    """Yield complete CSV records (a quoted field may span several lines)."""
    record = []
    for line in text.split(newline):
        record.append(line)
        if newline.join(record).count('"') % 2 == 0:
            yield newline.join(record)
            record = []
    if record:
        yield newline.join(record)


def drop(entries, target):
    kept = [e for e in entries if e.strip().lower() != target]
    return kept, len(kept) != len(entries)


def process(path, tag, term, apply):
    raw = path.read_bytes().decode('utf-8')
    newline = '\r\n' if '\r\n' in raw else '\n'
    changed = []
    out = []
    for i, record in enumerate(split_records(raw, newline)):
        parts = record.rsplit(',', 2)
        # Header, blank lines, or tags/terms that are quoted (unexpected): leave alone.
        if i == 0 or len(parts) != 3 or '"' in parts[1] or '"' in parts[2]:
            out.append(record)
            continue
        head, tags, terms = parts
        tag_list = tags.split(';') if tags else []
        term_list = terms.split(';') if terms else []
        if any(t.strip().lower() == tag for t in tag_list) and any(t.strip().lower() == term for t in term_list):
            tag_list, _ = drop(tag_list, tag)
            term_list, _ = drop(term_list, term)
            new = f"{head},{';'.join(tag_list)},{';'.join(term_list)}"
            changed.append((i + 1, tags, ';'.join(tag_list), terms, ';'.join(term_list)))
            out.append(new)
        else:
            out.append(record)
    if changed and apply:
        path.write_bytes(newline.join(out).encode('utf-8'))
    return changed


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('tag', help='entry to remove from the tags column, e.g. canadian')
    ap.add_argument('term', help='entry to remove from the terms column, e.g. richmond')
    ap.add_argument('--dir', default='_data/transcripts', help='folder of transcript CSVs')
    ap.add_argument('--apply', action='store_true', help='write the changes (default: preview only)')
    args = ap.parse_args()

    folder = pathlib.Path(args.dir)
    if not folder.is_dir():
        sys.exit(f'Folder not found: {folder}  (run from the repo root, or pass --dir)')

    tag, term = args.tag.strip().lower(), args.term.strip().lower()
    total = 0
    for path in sorted(folder.glob('*.csv')):
        for row, old_tags, new_tags, old_terms, new_terms in process(path, tag, term, args.apply):
            total += 1
            print(f'{path.name} record {row}:  tags {old_tags!r} -> {new_tags!r}   terms {old_terms!r} -> {new_terms!r}')

    verb = 'Changed' if args.apply else 'Would change'
    print(f'\n{verb} {total} row(s).' + ('' if args.apply or not total else '  Re-run with --apply to write.'))


if __name__ == '__main__':
    main()