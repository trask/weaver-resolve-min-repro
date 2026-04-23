# Weaver update-markdown Minimal Repro

Reproduces **`weaver registry update-markdown` nondeterminism** on Weaver
`0.23.0` (latest at the time of writing).

Identical inputs + a fresh `$HOME/.weaver/vdir_cache` before every run still
produce different output across runs.

## Background

The original incarnation of this repo targeted `weaver registry resolve
--lineage` nondeterminism on Weaver `0.22.1`. That narrower case no longer
reproduces on `0.23.0`:

- `--lineage` is documented as "not yet implemented" on `0.23.0`.
- `weaver registry resolve --include-unreferenced --format yaml` now produces
  byte-identical output across repeated fresh-cache runs in this repo.

However, `weaver registry update-markdown` still produces nondeterministic
output on the same input set, so this repro has been **rewritten to target
`update-markdown`**.

## Observed failure modes

On Weaver `0.23.0`, across 5 fresh-cache runs of `./repro.sh`, two
independent nondeterminism modes are observed. Both can occur in the same
run set:

1. **Shared-attribute links flip between runs.** The link for
   `gen_ai.operation.name` alternates between
   `/docs/attributes/attributes/gen-ai.md`,
   `/docs/attributes/attributes/event.md`, and
   `/docs/attributes/attributes/attributes.md`. Same flipping is observed
   for `error.type` (`error.md` vs `event.md` vs `attributes.md`) and
   `server.port` / `server.address` (`server.md` vs `event.md` vs
   `attributes.md`).

2. **Local enum member appears and disappears.** Inherited copies of
   `gen_ai.operation.name` sometimes include the local `invoke_workflow`
   enum member defined in `model/gen-ai-spans.yaml` and sometimes omit it:

   ```diff
   + | `invoke_workflow` | Invoke GenAI workflow | ![Development]... |
   ```

## Files

Local registry under `model/` (minimized to the smallest set that still
reproduces both modes):

- `gen-ai-registry.yaml`
- `gen-ai-spans.yaml`
- `gen-ai-events.yaml`
- `manifest.yaml` (pins upstream dependency to
  `https://github.com/open-telemetry/semantic-conventions.git@v1.40.0[model]`)

Snippet source:

- `docs/repro.md` — a minimal Markdown file with two `<!-- semconv ... -->`
  markers (one span, one event).

## Requirements

- Weaver `0.23.0`
- Git Bash (or any POSIX shell)
- `git` installed (for `git diff --no-index`)

## Repro

```bash
./repro.sh
```

The script:

1. Clears `$HOME/.weaver/vdir_cache` before every run.
2. Resets `docs/repro.md` to a fixed marker-only source on each run.
3. Invokes `weaver registry update-markdown -r ./model` with pinned remote
   templates (no retry loop — weaver is expected to succeed every time).
4. Copies the rendered `docs/repro.md` to `out_um/run$i.md`.
5. Diffs `out_um/run1.md` against every later run.

Exit code is non-zero whenever any two runs differ.

## Expected

All five runs should produce byte-identical `docs/repro.md` output.

## Actual on Weaver 0.23.0

At least one pair of runs differs in attribute link targets and/or in the
presence of the `invoke_workflow` enum member.

## Notes

- This is separate from the `weaver registry resolve` fresh-cache
  nondeterminism observed on `0.22.1`. That case no longer reproduces on
  `0.23.0`.
- The `clear-weaver-vdir-cache` step is not the workaround: these failures
  occur even with an empty cache.
- A separate stale-cache failure mode (links being rewritten to
  `/docs/attributes/attributes/event.md` permanently because of a poisoned
  global cache shared across repos) also exists but is orthogonal to this
  repro.
