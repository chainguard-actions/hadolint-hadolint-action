<!-- markdownlint-disable -->

# Hardening Report: hadolint--hadolint-action/v3.4.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `374911c4be584df24e6da57af2d990570ef0f859`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **hadolint--hadolint-action/v3.4.0** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

The Docker entrypoint script hadolint.sh runs workflow-controlled values through eval. Line 37 is `RESULTS=$(eval "$COMMAND $flags" -- **/"$filename")` and line 40 is `RESULTS=$(eval "$COMMAND" "$flags")`. $flags comes from the container args (${{ inputs.dockerfile }}), and $COMMAND includes HADOLINT_CONFIG (${{ inputs.config }}). eval parses these strings again, so shell metacharacters in either input (`;`, `$(...)`, backticks) run as commands. Instead of building a string for eval, build a bash array (e.g. cmd=(hadolint); [ -n "$HADOLINT_CONFIG" ] && cmd+=(-c "$HADOLINT_CONFIG"); "${cmd[@]}" "$@").

Locations:

- `hadolint.sh:37`
- `hadolint.sh:40`

### github-env-injection (severity: high)

hadolint.sh writes the multi-line $RESULTS value to $GITHUB_OUTPUT (`echo "results<<EOF"` ... `} >>"$GITHUB_OUTPUT"`) and to $GITHUB_ENV (`echo "HADOLINT_RESULTS<<EOF"` ... `} >>"$GITHUB_ENV"`) using the fixed heredoc delimiter 'EOF'. $RESULTS is hadolint output, which includes text an attacker controls (the linted Dockerfile's path and content, and rule names from inputs). If that output contains a line equal to 'EOF', the block ends early and every line after it becomes a new entry. In GITHUB_ENV that means arbitrary environment variables (e.g. LD_PRELOAD, BASH_ENV) for later steps. Use a delimiter generated at random on every run, e.g. EOF="EOF_$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')".

Locations:

- `hadolint.sh:54`
- `hadolint.sh:60`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection, github-env-injection

**Notes:**

hadolint.sh: removed eval. The command is now built as a bash array, with -c "$HADOLINT_CONFIG" added only when a config is set. In recursive mode the flags are kept as an array and the file is matched with the **/"$filename" globstar search, as before. In non-recursive mode each argument is split on whitespace and globbed with an unquoted expansion, matching what eval did for multiple or wildcard dockerfile values but without running any shell syntax in them. The only difference: quotes inside the dockerfile value are now treated as plain text. The action's 'results' output (GITHUB_OUTPUT) and the HADOLINT_RESULTS variable (GITHUB_ENV) are now written with a heredoc delimiter drawn from /dev/urandom on each run, and the multi-line value is left as is. action.yml docker args were not changed.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

hadolint.sh: the fixed 'EOF' heredoc delimiter used for the $GITHUB_OUTPUT and $GITHUB_ENV writes is replaced with a delimiter generated once per run with EOF="EOF_$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')". The multi-line content of RESULTS is kept as is. The hadolint debian base image includes od.

