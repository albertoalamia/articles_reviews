#!/usr/bin/env python3
"""Digitise a scatter plot raster: recover the data coordinates of every coloured point.

Written for ggplot2-style figures (white panel, grey major gridlines at the labelled ticks,
one colour per series, optional fitted lines in the same colours). Runs in the nix shell
(Pillow, NumPy, SciPy).

    python3 tools/digitise_scatter.py IMAGE \
        --x-ticks 0,10,20,30 --y-ticks 0,20,40,60 \
        --series positive=#00BFC4 negative=#F8766D \
        --xname dSBR --yname dRMSSD \
        --out points.csv --overlay overlay.png

Method
  1. Calibration: columns/rows dominated by light-grey pixels are gridlines. The N strongest
     (N = number of ticks given) are matched in order to the tick values and a straight line
     value = a + b * pixel is fitted; spacing regularity and residuals are reported.
  2. Series masks: pixels within --tol (Euclidean RGB) of each series colour.
  3. Lines vs points: a binary opening with a disc of radius --open removes strokes thinner
     than ~2*open px (fitted lines) and keeps the point discs.
  4. Components: connected blobs; the single-point area is the median of blobs within
     0.6–1.4 x the overall median; a blob is split into round(area / single_area) points by
     k-means on its pixel coordinates (so touching/overlapping points are counted).
  5. Blobs whose centroid falls outside the panel (gridline extent + one tick spacing) are
     dropped (legend keys, labels).
  The point count of a blob comes from its transparency: ggplot points are drawn with alpha,
     so overlapping discs are darker, and the summed layer depth divided by a single disc's
     gives the number of discs. This is reliable for blobs the opaque fitted line does not
     cross; blobs it crosses are flagged on_line and should be resolved with
     tools/resolve_stacks.py (other figure's multiset + reported sums).
  Output: CSV with series, pixel and data coordinates, blob id, blob area, blob_layers,
     n_in_blob, split, grid_placed, on_line;
  overlay PNG with detected centres and calibration lines for visual checking; a summary on
  stdout. Nothing here is edited by hand: re-running reproduces the CSV bit for bit.
"""
import argparse
import json
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage
from scipy.cluster.vq import kmeans2


def parse_hex(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=float)


def gridlines(grey_mask, axis, n_expected, frac=0.3):
    """Positions of the n_expected strongest grey-dominated columns (axis=0) or rows (axis=1)."""
    v = grey_mask.sum(axis=0 if axis == 0 else 1).astype(float)
    thr = frac * v.max()
    idx = np.where(v > thr)[0]
    groups = []
    for i in idx:
        if groups and i - groups[-1][-1] <= 2:
            groups[-1].append(i)
        else:
            groups.append([i])
    cands = [(float(np.average(g, weights=v[g])), float(v[g].sum()), len(g)) for g in groups]
    cands.sort(key=lambda c: -c[1])
    best = sorted(cands[:n_expected], key=lambda c: c[0])
    return best, cands


def calibrate(positions, ticks):
    px = np.array([p[0] for p in positions])
    val = np.array(ticks, dtype=float)
    if len(px) != len(val):
        sys.exit(f"found {len(px)} gridlines for {len(val)} ticks")
    b, a = np.polyfit(px, val, 1)
    resid = val - (a + b * px)
    spacing = np.diff(px)
    return dict(a=a, b=b, px=px.tolist(), ticks=val.tolist(),
                max_abs_resid=float(np.abs(resid).max()),
                spacing_px=spacing.tolist(),
                spacing_cv=float(spacing.std() / spacing.mean()))


def disc(r):
    y, x = np.ogrid[-r:r + 1, -r:r + 1]
    return (x * x + y * y) <= r * r


def place_on_grid(i, lab, layers, counted, r_disc, calx, caly, xgrid, ygrid, k_start, layer_scale):
    """Greedy placement of discs on data-grid nodes to reproduce a blob's layer map.

    Returns ([(y_px, x_px), ...], k). Nodes may repeat (coincident points). Discs are added while
    each one removes at least 35 % of a single disc's layer mass from the residual, up to
    k_start + 1; then every disc is tried on every node once more (refinement).
    """
    yy, xx = np.where(lab == i)
    pad = int(r_disc) + 2
    y0, y1 = yy.min() - pad, yy.max() + pad + 1
    x0, x1 = xx.min() - pad, xx.max() + pad + 1
    obs = layers[y0:y1, x0:x1].copy()
    w = counted[y0:y1, x0:x1].astype(float)            # 1 where the pixel is informative
    obs[(lab[y0:y1, x0:x1] != i)] = 0.0
    w[(lab[y0:y1, x0:x1] != i) & (lab[y0:y1, x0:x1] != 0)] = 0.0   # other blobs: ignore
    gy, gx = np.mgrid[y0:y1, x0:x1]
    # candidate nodes: data-grid points whose pixel position lies within the window
    def to_px_x(v): return (v - calx["a"]) / calx["b"]
    def to_px_y(v): return (v - caly["a"]) / caly["b"]
    def to_val_x(p): return calx["a"] + calx["b"] * p
    def to_val_y(p): return caly["a"] + caly["b"] * p
    vx = np.arange(np.floor(min(to_val_x(x0), to_val_x(x1)) / xgrid) * xgrid,
                   np.ceil(max(to_val_x(x0), to_val_x(x1)) / xgrid) * xgrid + xgrid / 2, xgrid)
    vy = np.arange(np.floor(min(to_val_y(y0), to_val_y(y1)) / ygrid) * ygrid,
                   np.ceil(max(to_val_y(y0), to_val_y(y1)) / ygrid) * ygrid + ygrid / 2, ygrid)
    nodes = [(to_px_y(b), to_px_x(a)) for a in vx for b in vy
             if y0 + r_disc / 2 <= to_px_y(b) <= y1 - r_disc / 2 and x0 + r_disc / 2 <= to_px_x(a) <= x1 - r_disc / 2]
    if not nodes:
        cy, cx = ndimage.center_of_mass(lab == i)
        return [(cy, cx)], 1
    discs = [(((gy - ny) ** 2 + (gx - nx) ** 2) <= r_disc ** 2).astype(float) for (ny, nx) in nodes]
    mass = np.pi * r_disc ** 2 * layer_scale
    model = np.zeros_like(obs)
    placed = []
    def score(m): return float((w * np.abs(obs - m)).sum())
    cur = score(model)
    # The layer mass fixes the number of discs (k_start); the fit decides where they go. One more
    # disc is added only if it still removes at least 35 % of a disc's mass from the residual.
    # Pixels under the opaque fitted line carry no information (weight 0), so discs that fall
    # entirely under it are positioned by the outline alone.
    for step in range(k_start + 1):
        best = min(range(len(nodes)), key=lambda j: score(model + discs[j]))
        new = score(model + discs[best])
        if step >= k_start and cur - new < 0.35 * mass:
            break
        model = model + discs[best]; placed.append(best); cur = new
    # refinement: move each disc to the best node given the others
    for _ in range(2):
        for p in range(len(placed)):
            base = model - discs[placed[p]]
            best = min(range(len(nodes)), key=lambda j: score(base + discs[j]))
            model = base + discs[best]; placed[p] = best
        cur = score(model)
    return [nodes[j] for j in placed], len(placed)


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("image")
    ap.add_argument("--x-ticks", required=True, help="comma-separated tick values of the vertical gridlines, left to right")
    ap.add_argument("--y-ticks", required=True, help="comma-separated tick values of the horizontal gridlines, bottom to top")
    ap.add_argument("--series", nargs="+", required=True, metavar="NAME=#RRGGBB")
    ap.add_argument("--xname", default="x")
    ap.add_argument("--yname", default="y")
    ap.add_argument("--tol", type=float, default=70, help="RGB distance tolerance for series colours (default 70)")
    ap.add_argument("--open", type=int, default=3, help="radius of the opening disc in px (default 3)")
    ap.add_argument("--min-area", type=int, default=20, help="drop blobs smaller than this after opening")
    ap.add_argument("--xgrid", type=float, default=None,
                    help="data grid step on x (e.g. 1 for integer counts, 0.1 for °C). With --ygrid, overlapping "
                         "points are placed on grid nodes by matching the transparency layer map")
    ap.add_argument("--ygrid", type=float, default=None, help="data grid step on y")
    ap.add_argument("--band-extra", type=float, default=0.0,
                    help="extra half-width (px) of the band around the fitted line that is ignored in the layer count")
    ap.add_argument("--xpad", type=float, default=1.0,
                    help="panel margin beyond the outer vertical gridlines, in tick spacings (default 1.0); "
                         "lower it when the legend sits close to the panel")
    ap.add_argument("--ypad", type=float, default=1.0, help="same for the horizontal gridlines")
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--out", required=True)
    ap.add_argument("--overlay")
    args = ap.parse_args()

    im = Image.open(args.image).convert("RGB")
    arr = np.asarray(im).astype(float)
    H, W, _ = arr.shape
    sat = arr.max(2) - arr.min(2)
    lum = arr.max(2)

    # 1. calibration from gridlines
    grey = (sat < 12) & (lum < 245) & (lum > 180)
    xt = [float(t) for t in args.x_ticks.split(",")]
    yt = [float(t) for t in args.y_ticks.split(",")]
    vx, vx_all = gridlines(grey, 0, len(xt))
    hy, hy_all = gridlines(grey, 1, len(yt))
    calx = calibrate(vx, xt)
    caly = calibrate(hy, yt[::-1])          # rows increase downwards: top gridline = largest tick
    if calx["spacing_cv"] > 0.03 or caly["spacing_cv"] > 0.03:
        print("WARNING: gridline spacing irregular; check the overlay", file=sys.stderr)
    xs_px = np.array(calx["px"]); ys_px = np.array(caly["px"])
    pad_x = args.xpad * np.diff(xs_px).mean(); pad_y = args.ypad * np.diff(ys_px).mean()
    panel = (xs_px.min() - pad_x, xs_px.max() + pad_x, ys_px.min() - pad_y, ys_px.max() + pad_y)

    # 2–5. points per series
    rng = np.random.default_rng(args.seed)
    rows, summary = [], {}
    for spec in args.series:
        name, hexcol = spec.split("=")
        target = parse_hex(hexcol)
        dist = np.sqrt(((arr - target) ** 2).sum(2))
        mask = dist < args.tol
        opened = ndimage.binary_opening(mask, structure=disc(args.open))
        lab, n = ndimage.label(opened)
        if n == 0:
            print(f"{name}: no blobs", file=sys.stderr); continue
        areas = ndimage.sum(opened, lab, index=np.arange(1, n + 1))
        cents = ndimage.center_of_mass(opened, lab, index=np.arange(1, n + 1))
        keep = [(i, a, c) for i, (a, c) in enumerate(zip(areas, cents), start=1)
                if a >= args.min_area and panel[0] <= c[1] <= panel[1] and panel[2] <= c[0] <= panel[3]]
        if not keep:
            print(f"{name}: no blobs inside the panel", file=sys.stderr); continue
        a_all = np.array([k[1] for k in keep])
        med = np.median(a_all)
        single = np.median(a_all[(a_all > 0.6 * med) & (a_all < 1.4 * med)])
        r_disc = np.sqrt(single / np.pi)

        # Layer depth from transparency. ggplot points are drawn with alpha < 1 on white, so a
        # pixel under n overlapping discs has colour 255 - (1 - (1-alpha)^n) * (255 - c) in each
        # channel. depth d = (255 - p) / (255 - c) on the channel with the largest contrast gives
        # n = log(1 - d) / log(1 - alpha). alpha is the modal depth over single-disc interiors.
        ch = int(np.argmax(255 - target))
        depth = np.clip((255 - arr[..., ch]) / (255 - target[ch]), 0, 0.999)
        interior = ndimage.binary_erosion(opened, structure=disc(3))
        singles = [i for i, a, c in keep if 0.8 * single < a < 1.25 * single]
        d_single = np.concatenate([depth[(lab == i) & interior] for i in singles]) if singles else depth[interior]
        alpha = float(np.median(d_single))
        layers = np.where(opened, np.log(1 - depth) / np.log(1 - alpha), 0.0)
        layers = np.minimum(layers, 4.0)

        # The fitted line of the same colour is opaque and crosses some discs; its pixels would
        # count as several layers. Fit the visible line (mask minus the dilated discs, inside the
        # panel) and ignore a band around it when summing layers, scaling the rest up to the
        # blob area.
        thin = mask & ~ndimage.binary_dilation(opened, structure=disc(2))
        gy_all, gx_all = np.mgrid[0:H, 0:W]
        inpanel = (gx_all >= panel[0]) & (gx_all <= panel[1]) & (gy_all >= panel[2]) & (gy_all <= panel[3])
        ly, lx = np.where(thin & inpanel)
        line_band = np.zeros_like(opened)
        line_fit = None
        if len(lx) > 200 and np.ptp(lx) > 50:
            m_, q_ = np.polyfit(lx, ly, 1)
            resid = ly - (m_ * lx + q_)
            half_w = float(np.percentile(np.abs(resid), 90)) + 1.5 + args.band_extra
            line_band = np.abs(gy_all - (m_ * gx_all + q_)) <= half_w
            line_fit = dict(slope_px=float(m_), intercept_px=float(q_), half_width_px=half_w, n_pixels=int(len(lx)))
        counted = opened & ~line_band
        eff_part = ndimage.sum(layers * counted, lab, index=np.arange(1, n + 1))
        n_part = ndimage.sum(counted, lab, index=np.arange(1, n + 1))
        eff = np.where(n_part > 0, eff_part / np.maximum(n_part, 1) * areas, eff_part)   # scale to the whole blob
        eff_single = np.median([eff[i - 1] for i in singles]) if singles else np.median(eff)

        on_line_ids = set(np.unique(lab[line_band & opened]).tolist()) - {0}
        slices = ndimage.find_objects(lab)
        n_points, n_split = 0, 0
        for i, a, c in keep:
            k_layers = max(1, int(round(eff[i - 1] / eff_single)))
            k_area = k_layers
            yy, xx = np.where(lab == i)
            if k_area == 1 and a < 1.25 * single:
                pts, k, placed = [c], 1, False
            elif args.xgrid and args.ygrid:
                # Place discs on the data grid so that the rendered layer map matches the observed
                # one (greedy, then one refinement pass). Handles stacks one grid step apart and
                # two discs on the same node.
                pts, k = place_on_grid(i, lab, layers, counted, r_disc, calx, caly, args.xgrid, args.ygrid,
                                       k_layers, eff_single / single)
                placed = True
                if k > 1:
                    n_split += 1
            else:
                # Heavily overlapping discs (points one grid step apart) have much less area than
                # k separate discs, so the area ratio under-counts them. Choose k by rendering k
                # discs at the k-means centres and comparing with the blob (Jaccard index); take
                # the smallest k whose fit is within 0.02 of the best.
                coords = np.column_stack([yy, xx]).astype(float)
                y0, x0 = yy.min() - 2, xx.min() - 2
                sub = np.zeros((yy.max() - y0 + 3, xx.max() - x0 + 3), bool)
                sub[yy - y0, xx - x0] = True
                gy, gx = np.mgrid[0:sub.shape[0], 0:sub.shape[1]]
                fits = {}
                for kk in range(max(1, k_area - 1), k_area + 2):
                    best = None
                    for rep in range(3):
                        cent, _ = kmeans2(coords, kk, minit="++", seed=int(rng.integers(1 << 30)))
                        model = np.zeros_like(sub)
                        for (cy, cx) in cent:
                            model |= ((gy - (cy - y0)) ** 2 + (gx - (cx - x0)) ** 2) <= r_disc ** 2
                        iou = (model & sub).sum() / (model | sub).sum()
                        if best is None or iou > best[0]:
                            best = (iou, cent)
                    fits[kk] = best
                # the transparency count decides k; the shape fit only breaks a near-tie (±1)
                top = max(f[0] for f in fits.values())
                k = k_layers if fits[k_layers][0] >= top - 0.03 else max(fits, key=lambda kk: fits[kk][0])
                pts = [tuple(p) for p in fits[k][1]]
                placed = False
                if k > 1:
                    n_split += 1
            sl = slices[i - 1]
            bx = sorted([calx["a"] + calx["b"] * (sl[1].start + r_disc), calx["a"] + calx["b"] * (sl[1].stop - 1 - r_disc)])
            by = sorted([caly["a"] + caly["b"] * (sl[0].start + r_disc), caly["a"] + caly["b"] * (sl[0].stop - 1 - r_disc)])
            for (py, px) in pts:
                rows.append(dict(series=name, x_px=round(px, 2), y_px=round(py, 2),
                                 centre_xmin=round(bx[0], 3), centre_xmax=round(bx[1], 3),
                                 centre_ymin=round(by[0], 3), centre_ymax=round(by[1], 3),
                                 **{args.xname: round(calx["a"] + calx["b"] * px, 4),
                                    args.yname: round(caly["a"] + caly["b"] * py, 4)},
                                 blob_id=int(i), blob_area=int(a), blob_layers=round(float(eff[i - 1] / eff_single), 2),
                                 n_in_blob=k, split=k > 1, grid_placed=placed,
                                 on_line=i in on_line_ids))
                n_points += 1
        summary[name] = dict(blobs=len(keep), points=n_points, blobs_split=n_split,
                             alpha_estimate=round(alpha, 3), fitted_line=line_fit,
                             single_point_area_px=float(single),
                             blob_area_min=int(a_all.min()), blob_area_max=int(a_all.max()))

    # write CSV
    import csv
    cols = ["series", "x_px", "y_px", args.xname, args.yname, "blob_id", "blob_area", "blob_layers",
            "n_in_blob", "split", "grid_placed", "on_line",
            "centre_xmin", "centre_xmax", "centre_ymin", "centre_ymax"]
    with open(args.out, "w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=cols)
        w.writeheader()
        for r in sorted(rows, key=lambda r: (r["series"], r[args.xname], r[args.yname])):
            w.writerow(r)

    # overlay
    if args.overlay:
        ov = im.copy()
        d = ImageDraw.Draw(ov)
        for x in xs_px:
            d.line([(x, 0), (x, H)], fill=(255, 0, 255), width=1)
        for y in ys_px:
            d.line([(0, y), (W, y)], fill=(255, 0, 255), width=1)
        d.rectangle([panel[0], panel[2], panel[1], panel[3]], outline=(0, 160, 0), width=1)
        for r in rows:
            x, y = r["x_px"], r["y_px"]
            col = (0, 0, 0) if not r["split"] else (255, 0, 0)
            d.line([(x - 6, y), (x + 6, y)], fill=col, width=1)
            d.line([(x, y - 6), (x, y + 6)], fill=col, width=1)
            d.ellipse([x - 9, y - 9, x + 9, y + 9], outline=col, width=1)
        ov.save(args.overlay)

    report = dict(image=args.image, size=[W, H],
                  calibration=dict(x=calx, y=caly, panel_px=[round(p, 1) for p in panel],
                                   px_per_unit_x=1 / calx["b"], px_per_unit_y=1 / caly["b"]),
                  series=summary, tol=args.tol, open_radius=args.open, seed=args.seed,
                  xpad=args.xpad, ypad=args.ypad,
                  gridline_candidates=dict(vertical=len(vx_all), horizontal=len(hy_all)))
    print(json.dumps(report, indent=1))


if __name__ == "__main__":
    main()
