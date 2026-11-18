#!/usr/bin/env bash
# Compile and sample one Stan model with CmdStan (plan §5). Run inside nix-shell, from the repo root:
#   ./SciRep_emotions_in_working_donkeys_Bukhari_2026/run_model.sh <model> [data.json] [options]
# <model>     stan/<model>.stan (sbr_nb2, sbr_poisson, et_mvn, et_normal, rmssd_lognormal_mvn, rmssd_gamma, delta_slopes)
# data.json   a file of data/derived/stan_data/ (path or basename). Default: the example replicate rho0_rep01 of the
#             model's outcome (delta_slopes: delta_sbr_rho0_rep01.json).
# options     --prior-only          prior predictive run (likelihood skipped)
#             --prior-scale X       every prior SD multiplied by X (sensitivities i: 2, i': 0.5)
#             --pooled              one sigma / alpha for the three conditions (sensitivity iv; MVN, et_normal, rmssd_gamma)
#             --chains N --warmup N --sampling N --adapt-delta D   (defaults 4, 1000, 1000; 0.95 for the condition models,
#                                   CmdStan's 0.8 for delta_slopes)
# The switches are written into a copy of the data file (keys prior_only, prior_scale, pooled set by R/01_prepare_data.R).
# Draws:    $FITS_DIR/<article>/<model>/<model>_<suffix>_<chain>.csv   (archive disk; never the project tree)
#           suffix = data name without its cond_<outcome>_ / delta_ prefix, then _prior, _psX, _pooled as applicable
# Also there: the data copy (data/<model>_<suffix>.json), <model>_<suffix>_diagnose.txt, and a line in runs.log.
# Seed: 20261025 + replicate index + 1000 × scenario index (rhom05 1, rho0 2, rhop05 3), so no two data files share a seed.
# SKIP_DONE=1 in the environment skips a run whose diagnose file already exists (run_all.sh resumes that way).
set -euo pipefail

usage() { sed -n '2,15p' "${BASH_SOURCE[0]}" >&2; exit 1; }
model="${1:-}"; [ -n "$model" ] || usage; shift

art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
art_name="$(basename "$art_dir")"
: "${CMDSTAN:?CMDSTAN not set: run inside nix-shell}"
: "${FITS_DIR:?FITS_DIR not set: run inside nix-shell}"
[ -d "$FITS_DIR" ] || { echo "Archive disk not mounted at $FITS_DIR" >&2; exit 1; }

data_arg=""; prior_only=0; prior_scale=1; pooled=0; chains=4; warmup=1000; sampling=1000; adapt_delta=""
while [ $# -gt 0 ]; do
  case "$1" in
    --prior-only)  prior_only=1 ;;
    --prior-scale) prior_scale="${2:?--prior-scale needs a value}"; shift ;;
    --pooled)      pooled=1 ;;
    --chains)      chains="${2:?}"; shift ;;
    --warmup)      warmup="${2:?}"; shift ;;
    --sampling)    sampling="${2:?}"; shift ;;
    --adapt-delta) adapt_delta="${2:?}"; shift ;;
    -*)            echo "unknown option: $1" >&2; usage ;;
    *)             [ -z "$data_arg" ] || { echo "only one data file" >&2; usage; }; data_arg="$1" ;;
  esac
  shift
done

stan_file="$art_dir/stan/$model.stan"
exe="$art_dir/stan/$model"
[ -f "$stan_file" ] || { echo "missing $stan_file" >&2; exit 1; }

stan_data="$art_dir/data/derived/stan_data"
if [ -z "$data_arg" ]; then
  case "$model" in
    sbr_*)   data_arg="cond_sbr_rho0_rep01.json" ;;
    et_*)    data_arg="cond_et_rho0_rep01.json" ;;
    rmssd_*) data_arg="cond_rmssd_rho0_rep01.json" ;;
    delta_*) data_arg="delta_sbr_rho0_rep01.json" ;;
    *)       echo "no default data file for $model" >&2; exit 1 ;;
  esac
fi
data_file="$data_arg"; [ -f "$data_file" ] || data_file="$stan_data/$data_arg"
[ -f "$data_file" ] || { echo "missing data file $data_arg" >&2; exit 1; }
grep -q '"prior_only":' "$data_file" || { echo "$data_file has no prior_only key: re-run R/01_prepare_data.R" >&2; exit 1; }

base="$(basename "$data_file" .json)"
suffix="$(echo "$base" | sed -E 's/^cond_(sbr|et|rmssd)_//; s/^delta_//')"
[ "$prior_only" = 1 ] && suffix="${suffix}_prior"
[ "$prior_scale" = 1 ] || suffix="${suffix}_ps${prior_scale}"
[ "$pooled" = 1 ] && suffix="${suffix}_pooled"

rep="$(echo "$base" | sed -nE 's/.*_rep0*([0-9]+)$/\1/p')"
case "$base" in *rhom05*) sc=1 ;; *rho0_*) sc=2 ;; *rhop05*) sc=3 ;; *) sc=0 ;; esac
seed=$((20261025 + ${rep:-0} + 1000 * sc))
if [ -z "$adapt_delta" ]; then case "$model" in delta_*) adapt_delta=0.8 ;; *) adapt_delta=0.95 ;; esac; fi

out_dir="$FITS_DIR/$art_name/$model"
mkdir -p "$out_dir/data"
if [ "${SKIP_DONE:-0}" = 1 ] && [ -f "$out_dir/${model}_${suffix}_diagnose.txt" ]; then echo "== $model [$suffix] already done, skipped"; exit 0; fi
run_data="$out_dir/data/${model}_${suffix}.json"
sed -E "s/\"prior_only\":[0-9]+/\"prior_only\":$prior_only/; s/\"prior_scale\":[0-9.]+/\"prior_scale\":$prior_scale/; s/\"pooled\":[0-9]+/\"pooled\":$pooled/" \
  "$data_file" > "$run_data"

echo "== compiling $model"
# The nixpkgs CmdStan lives in the read-only store: make cannot refresh the dependency files (.d) of the prebuilt
# main.o and precompiled header and prints "Permission denied" for those two scans before using the prebuilt objects.
# Those lines are dropped here; any real compiler error still shows and fails the script (pipefail).
make -C "$CMDSTAN" "$exe" 2>&1 | grep -Ev -- '-M[M]? -E -MG -MP -MF|fatal error: opening dependency file|^compilation terminated\.$' \
  || { make_status=${PIPESTATUS[0]}; [ "$make_status" -eq 0 ] || exit "$make_status"; }   # grep's 1 (nothing left to print) is not an error

echo "== sampling $model on $base [$suffix]: $chains chains, warmup $warmup, sampling $sampling, adapt_delta $adapt_delta, seed $seed"
t0=$(date +%s)
for c in $(seq 1 "$chains"); do
  "$exe" sample num_warmup="$warmup" num_samples="$sampling" adapt delta="$adapt_delta" \
    data file="$run_data" \
    random seed="$seed" id="$c" \
    output file="$out_dir/${model}_${suffix}_${c}.csv" refresh=500 &
done
wait
elapsed=$(( $(date +%s) - t0 ))

echo "== diagnose"
"$CMDSTAN/bin/diagnose" "$out_dir"/${model}_${suffix}_[0-9]*.csv | tee "$out_dir/${model}_${suffix}_diagnose.txt"
printf '%s\t%s\t%s\t%s\tseed=%s\tprior_only=%s\tprior_scale=%s\tpooled=%s\tchains=%s\twarmup=%s\tsampling=%s\tadapt_delta=%s\telapsed_s=%s\n' \
  "$(date -Is)" "$model" "$suffix" "$base" "$seed" "$prior_only" "$prior_scale" "$pooled" "$chains" "$warmup" "$sampling" "$adapt_delta" "$elapsed" >> "$FITS_DIR/$art_name/runs.log"
echo "== done in ${elapsed}s: $out_dir/${model}_${suffix}_{1..$chains}.csv"
