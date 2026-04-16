# Weaver Resolve Minimal Repro

This repository isolates a Weaver 0.22.1 nondeterminism bug in `weaver registry resolve --lineage`.

## Symptom

Repeated fresh-cache resolves with identical inputs produce different YAML output.

The concrete symptom is that inherited copies of the local `gen_ai.operation.name`
attribute sometimes include the local `invoke_workflow` enum member and sometimes do not.

## Files

This repro intentionally contains only these local semconv files:

- `gen-ai-registry.yaml`
- `gen-ai-spans.yaml`
- `mcp-common.yaml`
- `mcp-registry.yaml`
- `manifest.yaml`

The upstream dependency is pinned in `manifest.yaml` to:

```yaml
https://github.com/open-telemetry/semantic-conventions.git@v1.40.0[model]
```

## Requirements

- Weaver `0.22.1`
- Git Bash or another shell that can run `rm -rf`
- Git installed for `git diff --no-index`

## Repro

Run:

```bash
./repro.sh
```

Or run the commands manually:

```bash
rm -rf out
mkdir -p out
rm -rf "$HOME/.weaver/vdir_cache"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output out/out1.yaml
rm -rf "$HOME/.weaver/vdir_cache"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output out/out2.yaml
rm -rf "$HOME/.weaver/vdir_cache"
weaver registry resolve -r . --skip-policies --format yaml --lineage --output out/out3.yaml
git diff --no-index -- out/out1.yaml out/out2.yaml
git diff --no-index -- out/out2.yaml out/out3.yaml
```

## Expected

All three resolved outputs are identical.

## Actual

The outputs differ even though:

- the registry inputs are identical
- the upstream dependency is pinned
- the global Weaver cache is deleted before each run

Representative diff:

```diff
@@ -63,10 +63,6 @@ groups:
          value: execute_tool
          brief: Execute a tool
          stability: development
-      - id: invoke_workflow
-        value: invoke_workflow
-        brief: Invoke GenAI workflow
-        stability: development
      brief: The name of the operation being performed.
```

## Notes

- This repro targets the fresh-cache resolve instability only.
- It is separate from the stale global cache issue that can poison `update-markdown`
  link targets in larger downstream repos.