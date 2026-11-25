#!/usr/bin/env python3
"""Download a sampling frame from OpenAlex and draw the screening order for a systematic batch.

Implements protocol/selection.md v0.3 (track `systematic`): one journal, one calendar month,
`type:article`, and for multidisciplinary journals a set of OpenAlex subfields (field journals
are sampled whole: omit --subfields); the journal of each batch is drawn by
tools/journal_draw.py; the frame is saved and committed, then permuted
with a recorded seed. Alberto screens the order file by hand, in order, until the first
eligible paper (see the eligibility screen in selection.md).

Usage (inside nix-shell, from the repo root; no API key, no email is sent):

    python3 tools/sample_frame.py --batch B01 --field psychiatry \
        --from 2026-10-01 --to 2026-10-31 --subfields 2738 --seed 20261120

    python3 tools/sample_frame.py --batch B02 --field ethology \
        --from 2026-11-01 --to 2026-11-30 --subfields 1103 1105 2802 --seed 20261220

    python3 tools/sample_frame.py --batch B03 --field psychiatry --issn 1471-244X \
        --from 2026-12-01 --to 2026-12-31 --seed 20270125          # a field journal, no subfield filter

    python3 tools/sample_frame.py --batch B01 ... --draw-only    # redo the permutation from the saved frame

Writes, under registry/batches/ (created if missing):

    <batch>_frame.csv    one row per work, sorted by DOI: openalex_id, doi, publication_date,
                         title, topic, subfield, first_author, n_authors, is_retracted, abstract
    <batch>_frame.json   the query, retrieval time, count reported by OpenAlex, rows saved
    <batch>_order.csv    the permuted frame with rank, plus empty columns `eligible` and
                         `reason` to be filled by hand, in order, until the first `yes`

and prints the first ten of the order. It refuses to overwrite an existing frame unless
--force is given, because the committed frame is what makes the batch reproducible.

The frame is retrieved with cursor pagination (200 per page) and a generic User-Agent; the
request carries no identifying information.
"""
import argparse
import csv
import datetime as dt
import json
import random
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

API = "https://api.openalex.org/works"
UA = "articles-reviews-sampler/0.1"
FIELDS = ["id", "doi", "title", "publication_date", "type", "primary_topic", "authorships",
          "is_retracted", "abstract_inverted_index"]


def build_filter(issn, date_from, date_to, subfields):
    parts = [f"primary_location.source.issn:{issn}",
             f"from_publication_date:{date_from}",
             f"to_publication_date:{date_to}",
             "type:article"]
    if subfields:
        parts.append("primary_topic.subfield.id:" + "|".join(f"subfields/{s}" for s in subfields))
    return ",".join(parts)


def fetch_all(flt, pause=1.0):
    cursor, rows, reported = "*", [], None
    while cursor:
        q = urllib.parse.urlencode({"filter": flt, "per-page": 200, "cursor": cursor,
                                    "select": ",".join(FIELDS)})
        req = urllib.request.Request(f"{API}?{q}", headers={"User-Agent": UA, "Accept": "application/json"})
        with urllib.request.urlopen(req, timeout=60) as r:
            data = json.load(r)
        if reported is None:
            reported = data["meta"]["count"]
        rows.extend(data["results"])
        cursor = data["meta"].get("next_cursor")
        if cursor:
            time.sleep(pause)
    return rows, reported


def abstract_text(inv):
    if not inv:
        return ""
    pos = sorted((p, w) for w, ps in inv.items() for p in ps)
    return " ".join(w for _, w in pos)


def flatten(w):
    pt = w.get("primary_topic") or {}
    auth = w.get("authorships") or []
    first = next((a.get("author", {}).get("display_name", "") for a in auth
                  if a.get("author_position") == "first"), auth[0]["author"]["display_name"] if auth else "")
    return {
        "openalex_id": (w.get("id") or "").rsplit("/", 1)[-1],
        "doi": (w.get("doi") or "").replace("https://doi.org/", ""),
        "publication_date": w.get("publication_date") or "",
        "title": (w.get("title") or "").strip(),
        "topic": pt.get("display_name", ""),
        "subfield": (pt.get("subfield") or {}).get("display_name", ""),
        "first_author": first,
        "n_authors": len(auth),
        "is_retracted": w.get("is_retracted", ""),
        "abstract": abstract_text(w.get("abstract_inverted_index")),
    }


def write_csv(path, rows, fieldnames):
    with path.open("w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=fieldnames)
        wr.writeheader()
        wr.writerows(rows)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--batch", required=True, help="batch id, e.g. B01")
    ap.add_argument("--field", required=True, choices=["psychiatry", "ethology"])
    ap.add_argument("--issn", default="2045-2322", help="journal ISSN (default Scientific Reports)")
    ap.add_argument("--from", dest="date_from", required=True, help="YYYY-MM-DD, first day of the window")
    ap.add_argument("--to", dest="date_to", required=True, help="YYYY-MM-DD, last day of the window")
    ap.add_argument("--subfields", nargs="*", default=[],
                    help="OpenAlex subfield ids, e.g. 2738; omit for a field journal (selection v0.3)")
    ap.add_argument("--seed", type=int, required=True, help="batch date as YYYYMMDD")
    ap.add_argument("--out", default="registry/batches", type=Path)
    ap.add_argument("--draw-only", action="store_true", help="skip the download, permute the saved frame")
    ap.add_argument("--force", action="store_true", help="overwrite an existing frame")
    args = ap.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    frame_csv = args.out / f"{args.batch}_frame.csv"
    frame_json = args.out / f"{args.batch}_frame.json"
    order_csv = args.out / f"{args.batch}_order.csv"
    cols = ["openalex_id", "doi", "publication_date", "title", "topic", "subfield",
            "first_author", "n_authors", "is_retracted", "abstract"]

    if args.draw_only:
        if not frame_csv.exists():
            sys.exit(f"{frame_csv} not found; run without --draw-only first")
        with frame_csv.open(encoding="utf-8") as f:
            frame = list(csv.DictReader(f))
    else:
        if frame_csv.exists() and not args.force:
            sys.exit(f"{frame_csv} exists; use --draw-only to redraw or --force to download again")
        flt = build_filter(args.issn, args.date_from, args.date_to, args.subfields)
        works, reported = fetch_all(flt)
        frame = [flatten(w) for w in works]
        frame = [r for r in frame if r["doi"]]
        frame.sort(key=lambda r: r["doi"])
        write_csv(frame_csv, frame, cols)
        frame_json.write_text(json.dumps({
            "batch": args.batch, "track": "systematic", "field": args.field,
            "issn": args.issn, "from": args.date_from, "to": args.date_to,
            "subfields": args.subfields, "filter": flt, "api": API,
            "retrieved": dt.datetime.now().astimezone().isoformat(timespec="minutes"),
            "count_reported": reported, "rows_saved": len(frame),
            "rows_without_doi_dropped": len(works) - len(frame),
        }, indent=2) + "\n", encoding="utf-8")
        print(f"frame: {len(frame)} works saved to {frame_csv} (OpenAlex reported {reported})")

    if order_csv.exists() and not args.force:
        sys.exit(f"{order_csv} exists (it may hold screening decisions); use --force to overwrite")
    order = list(frame)
    random.Random(args.seed).shuffle(order)
    out_rows = [{"rank": i + 1, "eligible": "", "reason": "", **r} for i, r in enumerate(order)]
    write_csv(order_csv, out_rows, ["rank", "eligible", "reason"] + cols)
    print(f"order: seed {args.seed}, {len(order)} rows written to {order_csv}")
    print("screen in this order, title and abstract only, until the first eligible:")
    for r in out_rows[:10]:
        print(f"  {r['rank']:>3}  {r['doi']}  {r['publication_date']}  {r['title'][:90]}")


if __name__ == "__main__":
    main()
