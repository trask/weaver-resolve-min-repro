#!/usr/bin/env bash
set -euo pipefail

# Reproduces `weaver registry update-markdown` nondeterminism on identical
# inputs with a freshly cleared global vdir cache before every run.
#
# Observed on Weaver 0.23.0 (Windows / Git Bash). Two independent failure
# modes both trigger in the same run set:
#
# 1. Shared-attribute link targets flip between runs. Example: the link for
#    `gen_ai.operation.name` alternates between
#        /docs/attributes/attributes/gen-ai.md
#    and
#        /docs/attributes/attributes/event.md
#    (and /attributes.md). Same flipping is observed for `error.type`,
#    `server.port` and `server.address`.
#
# 2. The local `invoke_workflow` enum member on inherited copies of
#    `gen_ai.operation.name` appears on some runs and is missing on others,
#    even though inputs do not change.
#
# Inputs are pinned: local registry under ./model, upstream
# semantic-conventions dependency pinned to v1.40.0 in manifest.yaml,
# templates pinned to v1.40.0 via --templates. The global vdir cache
# ($HOME/.weaver/vdir_cache) is cleared before each run so stale cache
# state is not a factor.

out_dir="out_um"
cache_dir="${HOME}/.weaver/vdir_cache"
templates='https://github.com/open-telemetry/semantic-conventions.git@v1.40.0[templates]'

rm -rf "$out_dir"
mkdir -p "$out_dir"

runs=5
for i in $(seq 1 "$runs"); do
  echo "run $i"
  rm -rf "$cache_dir"

  # Re-seed docs/repro.md so each run starts from the same marker-only source.
  cat > docs/repro.md <<'EOF'
# Repro

## Span

<!-- semconv span.gen_ai.inference.client -->
<!-- endsemconv -->

## Event

<!-- semconv event.gen_ai.client.inference.operation.details -->
<!-- endsemconv -->
EOF

  weaver registry update-markdown \
    -r ./model \
    --templates "$templates" \
    --target markdown \
    --param registry_base_url=/docs/attributes/ \
    docs \
    >/dev/null 2>&1

  cp docs/repro.md "$out_dir/run$i.md"
done

echo
fail=0
for i in $(seq 2 "$runs"); do
  echo "=== run1 vs run$i ==="
  if ! diff -q "$out_dir/run1.md" "$out_dir/run$i.md" >/dev/null; then
    fail=1
    git --no-pager diff --no-index -- "$out_dir/run1.md" "$out_dir/run$i.md" || true
  else
    echo "identical"
  fi
  echo
done

if [ "$fail" = "1" ]; then
  echo "REPRO HIT: update-markdown output is not deterministic across runs."
  exit 1
fi

echo "All runs identical. Bug does not reproduce in this environment."
