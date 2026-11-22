#!/usr/bin/env bash
# Compile and sample one Stan model with CmdStan (plan §5). Run inside nix-shell, from the repo root:
#   ./SciRep_cognitive_impairment_cerebrovascular_events_Shi_2026/run_model.sh <model> [data.json] [options]
# <model>     stan/<model>.stan: pem_competing (E1), exposure_age (E2, E3)
# data.json   a file of data/derived/stan_data/ (path or basename, .json optional). Defaults: pem_isch.json, exposure_age_isch.json.
#             pem_competing:  pem_{isch,any}[_early|_late].json      exposure_age:  exposure_age_{isch,any,death}.json
# options     --prior-only          prior predictive run (likelihood skipped)
#             --beta-sd X           pem_competing: prior SD of the group effects (default 1; 2 = the wide-prior sensitivity)
#             --split               pem_competing: group effect free before and after year 4 (plan §7, S2)
#             --prior P1|P2|P3      exposure_age: prior on the age effect (default P2; plan §5)
#             --age-max 80|90|100   exposure_age: ceiling of the age distribution, A6 (default 90)
#             --chains N --warmup N --sampling N --adapt-delta D   (defaults 4, 1000, 1000, 0.95)
# The switches are written into a copy of the data file (keys prior_only, beta_sd, split, prior, age_max, set by R/01_prepare_data.R).
# Draws:    $FITS_DIR/<article>/<model>/<model>_<suffix>_<chain>.csv   (archive disk; never the project tree)
#           suffix = data name without its pem_ / exposure_age_ prefix, then _split, _bsdX (pem_competing), _P1|_P2|_P3 always and
#           _amaxNN if not 90 (exposure_age), _prior last. Examples: isch, any_early, isch_split, isch_bsd2, isch_P2, death_P2_amax80, isch_P3_prior
# Also there: the data copy (data/<model>_<suffix>.json), <model>_<suffix>_diagnose.txt, and a line in runs.log.
# Seed: 20261121 + 10000 x model (1 pem_competing, 2 exposure_age) + 1000 x outcome (1 isch, 2 any, 3 death)
#       + 100 x data variant (pem: 0 uniform, 1 early, 2 late; exposure: 0, 1, 2 for the ceiling 90, 80, 100)
#       + 10 x structure (pem: split; exposure: prior 1-3) + (2 if beta_sd is not 1) + (1 if prior only): no two runs share a seed.
# SKIP_DONE=1 in the environment skips a run whose diagnose file already exists (run_all.sh resumes that way).
set -euo pipefail

usage() { sed -n '2,20p' "${BASH_SOURCE[0]}" >&2; exit 1; }
model="${1:-}"; [ -n "$model" ] || usage; shift

art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
art_name="$(basename "$art_dir")"
: "${CMDSTAN:?CMDSTAN not set: run inside nix-shell}"
: "${FITS_DIR:?FITS_DIR not set: run inside nix-shell}"
[ -d "$FITS_DIR" ] || { echo "Archive disk not mounted at $FITS_DIR" >&2; exit 1; }

data_arg=""; prior_only=0; beta_sd=""; split=""; prior=""; age_max=""; chains=4; warmup=1000; sampling=1000; adapt_delta=0.95
while [ $# -gt 0 ]; do
  case "$1" in
    --prior-only)  prior_only=1 ;;
    --beta-sd)     beta_sd="${2:?--beta-sd needs a value}"; shift ;;
    --split)       split=1 ;;
    --prior)       prior="${2:?--prior needs P1, P2 or P3}"; shift ;;
    --age-max)     age_max="${2:?--age-max needs 80, 90 or 100}"; shift ;;
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

# options belong to one model each; defaults
case "$model" in
  pem_competing)
    [ -z "$prior$age_max" ] || { echo "--prior and --age-max are options of exposure_age" >&2; exit 1; }
    beta_sd="${beta_sd:-1}"; split="${split:-0}"; prefix="pem_"; default_data="pem_isch.json"; model_ix=1
    [[ "$beta_sd" =~ ^[0-9]+(\.[0-9]+)?$ ]] || { echo "--beta-sd: not a number: $beta_sd" >&2; exit 1; } ;;
  exposure_age)
    [ -z "$beta_sd$split" ] || { echo "--beta-sd and --split are options of pem_competing" >&2; exit 1; }
    prior="${prior:-P2}"; prior="${prior#P}"; age_max="${age_max:-90}"; prefix="exposure_age_"; default_data="exposure_age_isch.json"; model_ix=2
    case "$prior" in 1|2|3) ;; *) echo "--prior must be P1, P2 or P3" >&2; exit 1 ;; esac
    case "$age_max" in 80|90|100) ;; *) echo "--age-max must be 80, 90 or 100" >&2; exit 1 ;; esac ;;
  *) echo "no settings for model $model (pem_competing, exposure_age)" >&2; exit 1 ;;
esac

stan_data="$art_dir/data/derived/stan_data"
data_arg="${data_arg:-$default_data}"
data_file="$data_arg"
[ -f "$data_file" ] || data_file="$stan_data/$data_arg"
[ -f "$data_file" ] || data_file="$stan_data/$data_arg.json"
[ -f "$data_file" ] || { echo "missing data file $data_arg" >&2; exit 1; }
base="$(basename "$data_file" .json)"
case "$base" in "$prefix"*) ;; *) echo "$base is not a data file of $model (expected ${prefix}*.json)" >&2; exit 1 ;; esac

# every switch the model reads must be a key of the data file (R/01_prepare_data.R writes them)
if [ "$model" = pem_competing ]; then keys="prior_only beta_sd split"; else keys="prior_only prior age_max"; fi
for k in $keys; do
  grep -q "\"$k\":" "$data_file" || { echo "$data_file has no $k key: re-run R/01_prepare_data.R" >&2; exit 1; }
done

suffix="${base#"$prefix"}"
case "$suffix" in isch*) outcome_ix=1 ;; any*) outcome_ix=2 ;; death*) outcome_ix=3 ;; *) echo "unknown outcome in $base" >&2; exit 1 ;; esac
if [ "$model" = pem_competing ]; then
  case "$suffix" in *_early) variant_ix=1 ;; *_late) variant_ix=2 ;; *) variant_ix=0 ;; esac
  [ "$split" = 1 ] && suffix="${suffix}_split"
  [ "$beta_sd" = 1 ] || suffix="${suffix}_bsd${beta_sd}"
  struct_ix="$split"; extra=0; [ "$beta_sd" = 1 ] || extra=2
else
  case "$age_max" in 90) variant_ix=0 ;; 80) variant_ix=1 ;; 100) variant_ix=2 ;; esac
  suffix="${suffix}_P${prior}"
  [ "$age_max" = 90 ] || suffix="${suffix}_amax${age_max}"
  struct_ix="$prior"; extra=0
fi
[ "$prior_only" = 1 ] && suffix="${suffix}_prior"
seed=$((20261121 + 10000 * model_ix + 1000 * outcome_ix + 100 * variant_ix + 10 * struct_ix + extra + prior_only))

out_dir="$FITS_DIR/$art_name/$model"
mkdir -p "$out_dir/data"
if [ "${SKIP_DONE:-0}" = 1 ] && [ -f "$out_dir/${model}_${suffix}_diagnose.txt" ]; then echo "== $model [$suffix] already done, skipped"; exit 0; fi
run_data="$out_dir/data/${model}_${suffix}.json"
if [ "$model" = pem_competing ]; then
  sed -E "s/\"prior_only\":[0-9]+/\"prior_only\":$prior_only/; s/\"beta_sd\":[0-9.]+/\"beta_sd\":$beta_sd/; s/\"split\":[0-9]+/\"split\":$split/" \
    "$data_file" > "$run_data"
  settings="prior_only=$prior_only beta_sd=$beta_sd split=$split"
else
  sed -E "s/\"prior_only\":[0-9]+/\"prior_only\":$prior_only/; s/\"prior\":[0-9]+/\"prior\":$prior/; s/\"age_max\":[0-9]+/\"age_max\":$age_max/" \
    "$data_file" > "$run_data"
  settings="prior_only=$prior_only prior=P$prior age_max=$age_max"
fi

echo "== compiling $model"
# The nixpkgs CmdStan lives in the read-only store: make cannot refresh the dependency files (.d) of the prebuilt
# main.o and precompiled header and prints "Permission denied" for those two scans before using the prebuilt objects.
# Those lines are dropped here; any real compiler error still shows and fails the script (pipefail).
make -C "$CMDSTAN" "$exe" 2>&1 | grep -Ev -- '-M[M]? -E -MG -MP -MF|fatal error: opening dependency file|^compilation terminated\.$' \
  || { make_status=${PIPESTATUS[0]}; [ "$make_status" -eq 0 ] || exit "$make_status"; }   # grep's 1 (nothing left to print) is not an error

echo "== sampling $model on $base [$suffix]: $settings; $chains chains, warmup $warmup, sampling $sampling, adapt_delta $adapt_delta, seed $seed"
t0=$(date +%s)
for c in $(seq 1 "$chains"); do
  "$exe" sample num_warmup="$warmup" num_samples="$sampling" adapt delta="$adapt_delta" \
    data file="$run_data" \
    random seed="$seed" id="$c" \
    output file="$out_dir/${model}_${suffix}_${c}.csv" refresh=500 > "$out_dir/${model}_${suffix}_${c}.log" 2>&1 &
done
wait
elapsed=$(( $(date +%s) - t0 ))
for c in $(seq 1 "$chains"); do
  [ -s "$out_dir/${model}_${suffix}_${c}.csv" ] || { echo "chain $c wrote no draws: see $out_dir/${model}_${suffix}_${c}.log" >&2; exit 1; }
done

echo "== diagnose"
"$CMDSTAN/bin/diagnose" "$out_dir"/${model}_${suffix}_[0-9]*.csv | tee "$out_dir/${model}_${suffix}_diagnose.txt"
printf '%s\t%s\t%s\t%s\tseed=%s\t%s\tchains=%s\twarmup=%s\tsampling=%s\tadapt_delta=%s\telapsed_s=%s\n' \
  "$(date -Is)" "$model" "$suffix" "$base" "$seed" "${settings// /$'\t'}" "$chains" "$warmup" "$sampling" "$adapt_delta" "$elapsed" >> "$FITS_DIR/$art_name/runs.log"
echo "== done in ${elapsed}s: $out_dir/${model}_${suffix}_{1..$chains}.csv"
