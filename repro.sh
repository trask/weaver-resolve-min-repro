#!/usr/bin/env bash
set -euo pipefail

out_dir="out"
cache_dir="${HOME}/.weaver/vdir_cache"

rm -rf "$out_dir"
mkdir -p "$out_dir"

echo "run 1"
rm -rf "$cache_dir"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output "$out_dir/out1.yaml" >/dev/null

echo "run 2"
rm -rf "$cache_dir"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output "$out_dir/out2.yaml" >/dev/null

echo "run 3"
rm -rf "$cache_dir"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output "$out_dir/out3.yaml" >/dev/null

echo
echo "DIFF out1 vs out2"
git diff --no-index -- "$out_dir/out1.yaml" "$out_dir/out2.yaml" || true

echo
echo "DIFF out2 vs out3"
git diff --no-index -- "$out_dir/out2.yaml" "$out_dir/out3.yaml" || true