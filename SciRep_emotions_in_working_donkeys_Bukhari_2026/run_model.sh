#!/usr/bin/env bash
# Compile and sample one Stan model with CmdStan. Run from inside nix-shell, from the repo root:
#   ./SciRep_emotions_in_working_donkeys_Bukhari_2026/run_model.sh <model>            e.g. ./SciRep_.../run_model.sh nb_crossover
# Draws go to $FITS_DIR/SciRep_emotions_in_working_donkeys_Bukhari_2026/<model>_<chain>.csv  (archive disk, never the project tree).
set -euo pipefail

model="${1:?usage: run_model.sh <model-name-without-.stan>}"
art_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
art_name="$(basename "$art_dir")"
: "${CMDSTAN:?CMDSTAN not set: run inside nix-shell}"
: "${FITS_DIR:?FITS_DIR not set: run inside nix-shell}"

out_dir="$FITS_DIR/$art_name"
[ -d "$FITS_DIR" ] || { echo "Archive disk not mounted at $FITS_DIR" >&2; exit 1; }
mkdir -p "$out_dir"

stan_file="$art_dir/stan/$model.stan"
data_file="$art_dir/data/derived/${model}_data.json"
exe="$art_dir/stan/$model"
[ -f "$stan_file" ] || { echo "missing $stan_file" >&2; exit 1; }
[ -f "$data_file" ] || { echo "missing $data_file" >&2; exit 1; }

chains="${CHAINS:-4}"; warmup="${WARMUP:-1000}"; sampling="${SAMPLING:-1000}"; seed="${SEED:-20261025}"

echo "== compiling $model"
make -C "$CMDSTAN" "$exe"

echo "== sampling $chains chains -> $out_dir"
for c in $(seq 1 "$chains"); do
  "$exe" sample num_warmup="$warmup" num_samples="$sampling" \
    data file="$data_file" \
    random seed="$seed" id="$c" \
    output file="$out_dir/${model}_${c}.csv" refresh=500 &
done
wait

echo "== diagnose"
"$CMDSTAN/bin/diagnose" "$out_dir"/${model}_*.csv | tee "$art_dir/output/tables/${model}_diagnose.txt"
