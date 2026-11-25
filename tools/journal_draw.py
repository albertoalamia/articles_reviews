#!/usr/bin/env python3
"""Draw the journal of the next systematic batch of a field (protocol/selection.md v0.3).

The journals of the field in protocol/journals.csv that have not yet been used in the current
cycle are sorted by ISSN-L and one is drawn with `random.Random(seed).choice`; the seed is the
date of the draw as YYYYMMDD, the same seed then given to sample_frame.py. The journals already
used are read from registry/batches.csv (batches of the field, in file order): a cycle ends
when every journal of the current list has been used, and the next batch starts a new one.

    python3 tools/journal_draw.py --field ethology --seed 20261220

No network access. Prints the journals still to be used in the cycle, the one drawn, and the
arguments for sample_frame.py. It writes nothing: the batch row in registry/batches.csv is
what records the draw.
"""
import argparse
import csv
import random
from pathlib import Path


def remaining(journals, used):
    """Journals of the list not yet used in the current cycle, given the ISSNs used so far in order."""
    listed = {r["issn_l"] for r in journals}
    seen = set()
    for issn in used:
        if issn in listed:
            seen.add(issn)
        if seen == listed:
            seen = set()
    return sorted((r for r in journals if r["issn_l"] not in seen), key=lambda r: r["issn_l"])


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--field", required=True, choices=["psychiatry", "ethology"])
    ap.add_argument("--seed", type=int, required=True, help="date of the draw as YYYYMMDD")
    ap.add_argument("--journals", default="protocol/journals.csv", type=Path)
    ap.add_argument("--batches", default="registry/batches.csv", type=Path)
    args = ap.parse_args()

    with args.journals.open(encoding="utf-8") as f:
        journals = [r for r in csv.DictReader(f) if r["field"] == args.field]
    with args.batches.open(encoding="utf-8") as f:
        used = [r["issn"] for r in csv.DictReader(f) if r["track"] == "systematic" and r["field"] == args.field]
    rem = remaining(journals, used)
    pick = random.Random(args.seed).choice(rem)
    print(f"{args.field}: {len(used)} batch(es) so far, {len(rem)} of {len(journals)} journals left in the cycle")
    for r in rem:
        print(f"  {r['issn_l']}  {r['journal']}  [{r['type']}]")
    sub = f" --subfields {pick['subfield_filter']}" if pick["subfield_filter"] else ""
    print(f"drawn with seed {args.seed}: {pick['journal']} ({pick['issn_l']})")
    print(f"  python3 tools/sample_frame.py --batch B0x --field {args.field} --issn {pick['issn_l']}"
          f" --from YYYY-MM-01 --to YYYY-MM-DD{sub} --seed {args.seed}")


if __name__ == "__main__":
    main()
