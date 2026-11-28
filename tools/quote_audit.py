#!/usr/bin/env python3
"""Measure how much of a copyrighted article is reproduced verbatim in the committed files.

Usage (from the repo root; no network, standard library only):

    python3 tools/quote_audit.py <article_dir> [--n 7] [--limit 400] [--all]

Sources: every *.txt in <article_dir>/paper/ (the full text extracted with pdftotext, plus any
supplement text) — local files, never committed. Targets: the files of the article folder that git
tracks (notes/*.md, review.qmd, primer*.qmd, correspondence/*.md, data/raw/*.md), i.e. what the
public repository shows; --all adds untracked files too.

A run of N or more consecutive words (default 7; case-insensitive, punctuation ignored, numbers
kept) that also occurs in a source counts as verbatim. The script prints each run with file and
line, the verbatim word count per file, and the total; it exits 1 if the total exceeds --limit.
The default limit is 400 words, the STM Permission Guidelines' benchmark for a single text
extract from one journal article that publishers grant each other without a written request
(protocol/copyright.md); it is a working ceiling for a closed-access paper, not a legal threshold.
Runs made only of numbers and units (a transcribed table row) are listed separately and not counted.
"""
import argparse
import pathlib
import re
import subprocess
import sys

WORD = re.compile(r"[A-Za-z0-9][A-Za-z0-9'’\-\.]*")


def tokens(text):
    out = []
    for m in WORD.finditer(text):
        w = m.group(0).lower().strip(".'’-")
        if w:
            out.append((w, m.start()))
    return out


def shingles(words, n):
    return {tuple(words[i:i + n]) for i in range(len(words) - n + 1)}


def numeric_only(run_words):
    return all(re.fullmatch(r"[0-9\.\-]+|[a-z]{0,2}|[a-z]+\d+", w) for w in run_words)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("article")
    ap.add_argument("--n", type=int, default=7, help="minimum run length in words (default 7)")
    ap.add_argument("--limit", type=int, default=400, help="total verbatim words allowed (default 400)")
    ap.add_argument("--all", action="store_true", help="scan untracked files too")
    a = ap.parse_args()
    art = pathlib.Path(a.article)
    sources = sorted((art / "paper").glob("*.txt")) + sorted((art / "paper").glob("**/*.txt"))
    sources = sorted(set(sources))
    if not sources:
        sys.exit(f"no *.txt under {art / 'paper'}: extract the full text first (pdftotext -layout)")
    src_words = []
    for s in sources:
        src_words += [w for w, _ in tokens(s.read_text(errors="ignore"))]
    sh = shingles(src_words, a.n)

    if a.all:
        targets = [p for p in art.rglob("*") if p.suffix in (".md", ".qmd") and "paper" not in p.parts]
    else:
        out = subprocess.run(["git", "ls-files", str(art)], capture_output=True, text=True, check=True).stdout.split()
        targets = [pathlib.Path(p) for p in out if p.endswith((".md", ".qmd")) and "/paper/" not in p]
    total = 0
    print(f"sources: {', '.join(str(s) for s in sources)}  ({len(src_words)} words); min run {a.n} words\n")
    for t in sorted(targets):
        text = t.read_text(errors="ignore")
        toks = tokens(text)
        words = [w for w, _ in toks]
        hit = [False] * len(words)
        for i in range(len(words) - a.n + 1):
            if tuple(words[i:i + a.n]) in sh:
                for k in range(i, i + a.n):
                    hit[k] = True
        runs, i = [], 0
        while i < len(words):
            if hit[i]:
                j = i
                while j < len(words) and hit[j]:
                    j += 1
                runs.append((i, j))
                i = j
            else:
                i += 1
        file_total = 0
        lines = []
        for i, j in runs:
            run_words = words[i:j]
            line_no = text.count("\n", 0, toks[i][1]) + 1
            excerpt = " ".join(run_words)
            if numeric_only(run_words):
                lines.append(f"    (numbers) {t}:{line_no}: {excerpt[:90]}")
                continue
            file_total += j - i
            lines.append(f"    {j - i:4d}w  {t}:{line_no}: {excerpt[:110]}{'…' if len(excerpt) > 110 else ''}")
        if lines:
            print(f"{t}: {file_total} verbatim words in {sum(1 for l in lines if not l.strip().startswith('(numbers)'))} runs")
            print("\n".join(lines))
        total += file_total
    print(f"\nTOTAL verbatim words in committed files: {total}  (limit {a.limit})")
    sys.exit(1 if total > a.limit else 0)


if __name__ == "__main__":
    main()
