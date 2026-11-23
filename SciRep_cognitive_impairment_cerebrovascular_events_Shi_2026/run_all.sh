#!/usr/bin/env bash
# S4 (plan §5, §7, §8): every stage 4 posterior run, through run_model.sh. From the repo root, in the project environment:
#   ./SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/run_all.sh [--dry-run]
# pem_competing (14 runs), outcomes isch and any:
#   main (uniform person-years), early, late                      proportional group effect, beta_sd 1
#   main with --beta-sd 2                                          wide-prior sensitivity
#   main and early with --split                                    group effect free before and after year 4
#   main with --split --beta-sd 2                                  how much Normal(0, 1) shrinks the tail group effect
# exposure_age (15 runs), outcomes isch, any, death:
#   P1, P2, P3 at the age ceiling 90; P2 at the ceilings 80 and 100
# 29 runs, sequential (4 chains each in parallel), seconds each. A run whose diagnose file exists is skipped
# (SKIP_DONE=1), so the script resumes after an interruption; delete the diagnose file to force a rerun.
# Terminal: one line per run. Full output: $FITS_DIR/<article>/run_all.log. Diagnostics and estimates are collected
# afterwards by  Rscript <article>/R/03_postprocess.R
set -euo pipefail
art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
art_name="$(basename "$art_dir")"
: "${FITS_DIR:?FITS_DIR not set: run inside the project environment (direnv or nix-shell)}"
[ -d "$FITS_DIR" ] || { echo "Archive disk not mounted at $FITS_DIR" >&2; exit 1; }
dry=0
case "${1:-}" in --dry-run) dry=1 ;; "") ;; *) echo "usage: run_all.sh [--dry-run]" >&2; exit 1 ;; esac

runs=()
for o in isch any; do
  runs+=("pem_competing pem_${o}")
  runs+=("pem_competing pem_${o}_early")
  runs+=("pem_competing pem_${o}_late")
  runs+=("pem_competing pem_${o} --beta-sd 2")
  runs+=("pem_competing pem_${o} --split")
  runs+=("pem_competing pem_${o}_early --split")
  runs+=("pem_competing pem_${o} --split --beta-sd 2")
done
for o in isch any death; do
  for p in P1 P2 P3; do runs+=("exposure_age exposure_age_${o} --prior $p"); done
  for am in 80 100; do runs+=("exposure_age exposure_age_${o} --prior P2 --age-max $am"); done
done

echo "${#runs[@]} runs"
if [ "$dry" = 1 ]; then printf '%s\n' "${runs[@]}"; exit 0; fi

mkdir -p "$FITS_DIR/$art_name"
log="$FITS_DIR/$art_name/run_all.log"
echo "=== run_all $(date -Is)" >> "$log"
failed=0; i=0
for r in "${runs[@]}"; do
  i=$((i + 1))
  # shellcheck disable=SC2086   # the run string is split into arguments on purpose
  if SKIP_DONE=1 "$art_dir/run_model.sh" $r >> "$log" 2>&1; then
    printf '%2d/%d ok      %s\n' "$i" "${#runs[@]}" "$r"
  else
    printf '%2d/%d FAILED  %s   (see %s)\n' "$i" "${#runs[@]}" "$r" "$log"; failed=$((failed + 1))
  fi
done
echo "done: $((${#runs[@]} - failed)) of ${#runs[@]} runs completed; log $log"
[ "$failed" -eq 0 ]
