#!/usr/bin/env python3
"""Resolve the point counts of uncertain blobs in two digitised scatter plots that share one axis.

Context: tools/digitise_scatter.py counts overlapping points from their transparency. That
count is unreliable where the opaque fitted line crosses the blob (flag on_line). When the paper
gives two figures with a common variable (here ΔRMSSD on the y axis of Figures 3 and 4) and
reports the means of the plotted values (Table 2), the uncertain blobs can be resolved by
exhaustive search under three constraints:

  1. the multiset of shared-axis values is identical in the two figures (same donkeys);
  2. each figure has exactly n points per series;
  3. the sum of the values equals n × reported mean. Exact for an integer-valued variable
     whose mean is reported to 2 dp (ΔSBR: the sum is pinned to one integer); for variables
     that were rounded for plotting (ΔRMSSD to 1 ms, ΔET to 0.1 °C) only within
     n × half a plotting step, because the reported mean was computed on unrounded values.

Admissible configurations of an uncertain blob: multisets over the grid nodes its visible
extent covers (each node at least once, since the outline shows it), with sizes from
max(#nodes, k−2) to k+2 around the digitiser's count k. Certain blobs are taken as digitised.
Small fragments (area < 0.5 of a disc, points partly hidden under a point of the other
colour) may move by one grid step on the shared axis.

Usage:
  python3 tools/resolve_stacks.py --fig-a fig3_points_digitised.csv --xa dSBR --xa-step 1 \
      --fig-b fig4_points_digitised.csv --xb dET --xb-step 0.1 --shared dRMSSD --shared-step 1 \
      --table2 data/raw/table2_changes.csv --n 34 \
      --out-a fig3_points_resolved.csv --out-b fig4_points_resolved.csv --report resolve_report.json
Outcome: if exactly one configuration satisfies all constraints, the resolved CSVs are written
(uncertain blobs replaced by the solved points, column `resolved_by = constraints`); otherwise
the alternatives are listed and nothing is written (exit code 2).
"""
import argparse
import csv
import itertools
import json
import sys
from collections import Counter


def rnd(v, step):
    return round(round(v / step) * step, 6)


def load(path, xcol, xstep, shared, sstep):
    rows = list(csv.DictReader(open(path)))
    for r in rows:
        r["_x"] = rnd(float(r[xcol]), xstep)
        r["_y"] = rnd(float(r[shared]), sstep)
        r["_k"] = int(r["n_in_blob"])
        r["_area"] = float(r["blob_area"])
        r["_on_line"] = r.get("on_line", "False") == "True"
    return rows


def grid_between(lo, hi, step, slack=0.4):
    """Grid values v with lo - slack*step <= v <= hi + slack*step."""
    out, v = [], rnd(round((lo - slack * step) / step) * step, step)
    while v <= hi + slack * step + 1e-9:
        if v >= lo - slack * step - 1e-9:
            out.append(rnd(v, step))
        v = rnd(v + step, step)
    return out


def blob_configs(points, k, sstep, xstep, frag=False, single_on_line=False):
    """All admissible multisets of (x, y) for one blob. points: the digitised points of the blob."""
    p0 = points[0]
    xs = grid_between(float(p0["centre_xmin"]), float(p0["centre_xmax"]), xstep) or sorted({p["_x"] for p in points})
    ys_ext = grid_between(float(p0["centre_ymin"]), float(p0["centre_ymax"]), sstep) or sorted({p["_y"] for p in points})
    if frag:                                   # fragment: single point, y may be off by one step
        y = points[0]["_y"]; x = points[0]["_x"]
        return [((x, rnd(y + d, sstep)),) for d in (0, sstep, -sstep)]
    if single_on_line:                         # a single disc on the opaque line: one point or two coincident
        x, y = points[0]["_x"], points[0]["_y"]
        return [((x, y),), ((x, y), (x, y))]
    nodes_y = ys_ext
    nodes = [(x, y) for x in xs for y in nodes_y]
    # outline: the lowest and highest levels of the extent are occupied, and no level is farther
    # than one step from an occupied one (discs of adjacent levels overlap; a two-level gap would
    # split the blob)
    out = set()
    lo, hi = nodes_y[0], nodes_y[-1]
    min_size = max(1, (len(nodes_y) + 1) // 2)
    for size in range(max(min_size, k - 2), k + 3):
        for combo in itertools.combinations_with_replacement(nodes, size):
            ys = sorted({y for _, y in combo})
            if ys[0] != lo or ys[-1] != hi:
                continue
            if any(b - a > sstep * 1.05 + 1e-9 for a, b in zip(ys, ys[1:])) and \
               any(b - a > 2 * sstep + 1e-9 for a, b in zip(ys, ys[1:])):
                continue
            out.add(tuple(sorted(combo)))
    return sorted(out)


def series_configs(rows, single_area, sstep, xstep):
    """Return (fixed points, [list of alternative tuples per uncertain blob], blob ids)."""
    by_blob = {}
    for r in rows:
        by_blob.setdefault(r["blob_id"], []).append(r)
    fixed, uncertain, ids = [], [], []
    for bid, pts in by_blob.items():
        frag = pts[0]["_area"] < 0.5 * single_area
        if frag:
            uncertain.append(blob_configs(pts, 1, sstep, xstep, frag=True)); ids.append(bid)
        elif pts[0]["_on_line"] and (len(pts) > 1 or pts[0]["_area"] > 1.25 * single_area):
            uncertain.append(blob_configs(pts, pts[0]["_k"], sstep, xstep)); ids.append(bid)
        elif pts[0]["_on_line"]:
            uncertain.append(blob_configs(pts, 1, sstep, xstep, single_on_line=True)); ids.append(bid)
        else:
            fixed += [(p["_x"], p["_y"]) for p in pts]
    return fixed, uncertain, ids


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--fig-a", required=True); ap.add_argument("--xa", required=True); ap.add_argument("--xa-step", type=float, required=True)
    ap.add_argument("--fig-b", required=True); ap.add_argument("--xb", required=True); ap.add_argument("--xb-step", type=float, required=True)
    ap.add_argument("--shared", required=True); ap.add_argument("--shared-step", type=float, required=True)
    ap.add_argument("--table2", required=True, help="CSV with outcome,treatment,delta_mean (reported means of the plotted values)")
    ap.add_argument("--outcome-a", default=None, help="outcome name of x in fig A in the table2 file (default: xa without leading d)")
    ap.add_argument("--outcome-b", default=None); ap.add_argument("--outcome-shared", default=None)
    ap.add_argument("--exact", nargs="*", default=[], help="outcomes whose sum is exact (integer data, no plotting rounding), e.g. SBR")
    ap.add_argument("--n", type=int, required=True)
    ap.add_argument("--out-a", required=True); ap.add_argument("--out-b", required=True); ap.add_argument("--report", required=True)
    args = ap.parse_args()
    oa = args.outcome_a or args.xa.lstrip("d"); ob = args.outcome_b or args.xb.lstrip("d"); os_ = args.outcome_shared or args.shared.lstrip("d")

    A = load(args.fig_a, args.xa, args.xa_step, args.shared, args.shared_step)
    B = load(args.fig_b, args.xb, args.xb_step, args.shared, args.shared_step)
    t2 = {(r["outcome"], r["treatment"]): r for r in csv.DictReader(open(args.table2))}
    n = args.n
    report, resolved_a, resolved_b = {}, [], []
    ok_all = True
    for s in sorted({r["series"] for r in A}):
        a = [r for r in A if r["series"] == s]; b = [r for r in B if r["series"] == s]
        single_a = sorted(r["_area"] for r in a)[len(a) // 2]; single_b = sorted(r["_area"] for r in b)[len(b) // 2]
        fa, ua, ida = series_configs(a, single_a, args.shared_step, args.xa_step)
        fb, ub, idb = series_configs(b, single_b, args.shared_step, args.xb_step)

        def target(outc, step, exact):
            m = float(t2[(outc, s)]["delta_mean"]); dec = len(t2[(outc, s)]["delta_mean"].split(".")[1]) if "." in t2[(outc, s)]["delta_mean"] else 0
            tol_mean = n * 0.5 * 10 ** (-dec)                      # rounding of the reported mean
            tol_plot = 0 if exact else n * 0.5 * step             # rounding of the plotted values
            return n * m, tol_mean + tol_plot
        tA, tolA = target(oa, args.xa_step, oa in args.exact)
        tB, tolB = target(ob, args.xb_step, ob in args.exact)
        tS, tolS = target(os_, args.shared_step, os_ in args.exact)

        sols = []
        n_tried = 0
        for ca in itertools.product(*ua) if ua else [()]:
            pa = fa + [p for c in ca for p in c]
            if len(pa) != n: continue
            sx = sum(x for x, _ in pa); sy = sum(y for _, y in pa)
            if abs(sx - tA) > tolA + 1e-9 or abs(sy - tS) > tolS + 1e-9: continue
            ma = Counter(y for _, y in pa)
            for cb in itertools.product(*ub) if ub else [()]:
                n_tried += 1
                pb = fb + [p for c in cb for p in c]
                if len(pb) != n: continue
                if Counter(y for _, y in pb) != ma: continue
                sxb = sum(x for x, _ in pb)
                if abs(sxb - tB) > tolB + 1e-9: continue
                sols.append((ca, cb, sx, sy, sxb))
        report[s] = dict(uncertain_blobs_a=ida, uncertain_blobs_b=idb,
                         n_alternatives_a=[len(u) for u in ua], n_alternatives_b=[len(u) for u in ub],
                         targets=dict(a=[tA, tolA], b=[tB, tolB], shared=[tS, tolS]),
                         n_solutions=len(sols),
                         solutions=[dict(a={i: list(c) for i, c in zip(ida, ca)}, b={i: list(c) for i, c in zip(idb, cb)},
                                         sum_xa=sx, sum_shared=sy, sum_xb=round(sxb, 3)) for ca, cb, sx, sy, sxb in sols[:20]])
        print(f"== {s}: uncertain blobs A {ida} ({[len(u) for u in ua]} alternatives), B {idb} ({[len(u) for u in ub]}); "
              f"{len(sols)} solution(s)")
        resolved_how = "constraints"
        if len(sols) > 1:
            # Tie-break by the image: prefer the solution whose points lie closest to the
            # digitiser's own placement (sum over points of the distance to the nearest
            # digitised point of the same blob, in grid steps). Kept only if the best is unique.
            def img_dist(conf, ids, rows, xstep):
                d = 0.0
                for bid, c in zip(ids, conf):
                    pts = [(r["_x"] / xstep, r["_y"] / args.shared_step) for r in rows if r["blob_id"] == bid]
                    for (x, y) in c:
                        d += min(abs(x / xstep - px) + abs(y / args.shared_step - py) for px, py in pts)
                return d
            scored = sorted((img_dist(ca, ida, a, args.xa_step) + img_dist(cb, idb, b, args.xb_step), j)
                            for j, (ca, cb, *_rest) in enumerate(sols))
            print(f"   {len(sols)} solutions satisfy the constraints; image distances: {[round(d, 2) for d, _ in scored]}")
            if scored[0][0] < scored[1][0] - 1e-9:
                sols = [sols[scored[0][1]]]
                resolved_how = "constraints+image"
        report[s]["resolved_by"] = resolved_how if len(sols) == 1 else None
        if len(sols) != 1:
            ok_all = False
            for ca, cb, sx, sy, sxb in sols[:10]:
                print("   A:", {i: list(c) for i, c in zip(ida, ca)}, " B:", {i: list(c) for i, c in zip(idb, cb)})
            continue
        ca, cb, sx, sy, sxb = sols[0]
        print(f"   A: {dict(zip(ida, [list(c) for c in ca]))}\n   B: {dict(zip(idb, [list(c) for c in cb]))}\n"
              f"   sums: {args.xa} {sx} (target {tA}), {args.shared} {sy} (target {tS} ± {tolS}), {args.xb} {round(sxb, 2)} (target {tB} ± {tolB})")

        def emit(rows, ids, conf, xcol, xstep):
            out = []
            for r in rows:
                if r["blob_id"] in ids: continue
                o = {k: v for k, v in r.items() if not k.startswith("_")}
                o[xcol] = r["_x"]; o[args.shared] = r["_y"]; o["resolved_by"] = "digitiser"
                out.append(o)
            for bid, c in zip(ids, conf):
                tmpl = next(r for r in rows if r["blob_id"] == bid)
                for (x, y) in c:
                    o = {k: v for k, v in tmpl.items() if not k.startswith("_")}
                    o[xcol] = x; o[args.shared] = y; o["n_in_blob"] = len(c); o["split"] = len(c) > 1
                    o["resolved_by"] = resolved_how; out.append(o)
            return out
        resolved_a += emit(a, ida, ca, args.xa, args.xa_step)
        resolved_b += emit(b, idb, cb, args.xb, args.xb_step)

    json.dump(report, open(args.report, "w"), indent=1)
    if not ok_all:
        print("no unique solution for at least one series; nothing written (see report)")
        sys.exit(2)
    for path, rows, xcol in ((args.out_a, resolved_a, args.xa), (args.out_b, resolved_b, args.xb)):
        cols = [c for c in rows[0].keys()]
        with open(path, "w", newline="") as fh:
            w = csv.DictWriter(fh, fieldnames=cols); w.writeheader()
            for r in sorted(rows, key=lambda r: (r["series"], float(r[xcol]), float(r[args.shared]))):
                w.writerow(r)
    print(f"written {args.out_a}, {args.out_b}, {args.report}")


if __name__ == "__main__":
    main()
