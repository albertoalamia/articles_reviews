#!/usr/bin/env bash
# S7 (plan §5, §8): every stage 4 run, through run_model.sh. From the repo root, inside nix-shell:
#   ./SciRep_emotions_in_working_donkeys_Bukhari_2026/run_all.sh [--dry-run|--reruns-only]
# Per replicate (30: rhom05, rho0, rhop05 × rep01..rep10) the 22 runs are
#   planned:        sbr_nb2, et_mvn, rmssd_lognormal_mvn on cond_*; delta_slopes on delta_sbr_* and delta_et_*
#   (i), (i'):      the same five with --prior-scale 2 and --prior-scale 0.5
#   (ii), (ii'):    rmssd_gamma (2000 sampling iterations, S6), et_normal
#   (iii):          sbr_poisson
#   (iv):           --pooled for et_mvn, rmssd_lognormal_mvn, et_normal, rmssd_gamma
# 660 runs, about 270 MB per replicate on $FITS_DIR (6.9 GB and 63 min on 2026-11-18). Runs are sequential (4 chains
# each in parallel); a run whose diagnose file exists is skipped (SKIP_DONE=1), so the script resumes after an interruption.
# After the main list, the runs in `reruns` are sampled again with 2000 sampling iterations, overwriting the first pass:
# these are the runs that failed the §5 R-hat threshold at the default settings (first pass of 2026-11-18, three of 660,
# R-hat 1.012–1.013 on lp__ with ESS > 690 and no divergences). --reruns-only skips the main list.
# Terminal: one line per run. Full output: $FITS_DIR/<article>/run_all.log. Diagnostics are collected afterwards by
# Rscript <article>/R/03_postprocess.R --collect.
set -euo pipefail
art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
art_name="$(basename "$art_dir")"
: "${FITS_DIR:?FITS_DIR not set: run inside nix-shell}"
[ -d "$FITS_DIR" ] || { echo "Archive disk not mounted at $FITS_DIR" >&2; exit 1; }
dry=0; reruns_only=0
case "${1:-}" in --dry-run) dry=1 ;; --reruns-only) reruns_only=1 ;; "") ;; *) echo "usage: run_all.sh [--dry-run|--reruns-only]" >&2; exit 1 ;; esac

runs=()
for sc in rhom05 rho0 rhop05; do
  for k in 01 02 03 04 05 06 07 08 09 10; do
    r="${sc}_rep${k}"
    for m in sbr_nb2 et_mvn rmssd_lognormal_mvn; do
      d="cond_${m%%_*}_${r}.json"
      runs+=("$m $d" "$m $d --prior-scale 2" "$m $d --prior-scale 0.5")
    done
    for x in sbr et; do
      d="delta_${x}_${r}.json"
      runs+=("delta_slopes $d" "delta_slopes $d --prior-scale 2" "delta_slopes $d --prior-scale 0.5")
    done
    runs+=("sbr_poisson cond_sbr_${r}.json")
    runs+=("et_normal cond_et_${r}.json" "et_normal cond_et_${r}.json --pooled")
    runs+=("rmssd_gamma cond_rmssd_${r}.json --sampling 2000" "rmssd_gamma cond_rmssd_${r}.json --pooled --sampling 2000")
    runs+=("et_mvn cond_et_${r}.json --pooled" "rmssd_lognormal_mvn cond_rmssd_${r}.json --pooled")
  done
done
reruns=(
  "sbr_nb2 cond_sbr_rhom05_rep10.json --prior-scale 0.5 --sampling 2000"
  "sbr_nb2 cond_sbr_rhop05_rep05.json --prior-scale 0.5 --sampling 2000"
  "sbr_poisson cond_sbr_rhop05_rep01.json --sampling 2000"
)
n=${#runs[@]}
echo "== $n runs + ${#reruns[@]} reruns; free space on $FITS_DIR: $(df -h "$FITS_DIR" | awk 'NR == 2 {print $4}')"
if [ "$dry" = 1 ]; then printf '%s\n' "${runs[@]}"; printf 'rerun: %s\n' "${reruns[@]}"; exit 0; fi

log="$FITS_DIR/$art_name/run_all.log"
echo "== run_all start $(date -Is)" >> "$log"
t_all=$(date +%s)
do_run() {   # do_run <skip_done 0|1> <label> <spec...>
  local skip="$1" label="$2" t0; shift 2
  t0=$(date +%s)
  if SKIP_DONE="$skip" "$art_dir/run_model.sh" "$@" >> "$log" 2>&1; then
    verdict=$(tail -n 40 "$log" | grep -E "skipped|divergen|treedepth|E-BFMI|R-hat|effective sample size" | grep -Evc "No divergent|satisfactory" || true)
    [ "$verdict" = 0 ] && verdict="ok" || verdict="CHECK"
    printf '%9s  %-22s %-32s %-28s %4ss  %s\n' "$label" "$1" "$2" "${*:3}" "$(( $(date +%s) - t0 ))" "$verdict"
  else
    printf '%9s  %-22s %-32s %-28s FAILED (see %s)\n' "$label" "$1" "$2" "${*:3}" "$log"
    exit 1
  fi
}
if [ "$reruns_only" = 0 ]; then
  i=0
  for spec in "${runs[@]}"; do
    i=$((i + 1))
    # shellcheck disable=SC2086
    do_run 1 "$i/$n" $spec
  done
fi
for spec in "${reruns[@]}"; do
  # shellcheck disable=SC2086
  do_run 0 "rerun" $spec
done
echo "== run_all done in $(( ( $(date +%s) - t_all ) / 60 )) min; $(du -sh "$FITS_DIR/$art_name" | cut -f1) on $FITS_DIR/$art_name" | tee -a "$log"
