<!-- markdownlint-disable -->

# Hardening Report: hadolint--hadolint-action/v3.3.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **hadolint--hadolint-action/v3.3.0** was hardened automatically. 3 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple `uses:` references in .github/workflows/ci.yml are pinned to mutable tags or version strings rather than immutable 40-character commit SHAs. This exposes the workflow to supply-chain attacks if any of these upstream actions are compromised or their tags are moved. Failing references: `actions/checkout@v5` (multiple steps), `reviewdog/action-shellcheck@v1.31.0`, `brpaz/structure-tests-action@v1.1.2`, `cycjimmy/semantic-release-action@v5`.

Locations:

- `.github/workflows/ci.yml:22`
- `.github/workflows/ci.yml:31`
- `.github/workflows/ci.yml:34`
- `.github/workflows/ci.yml:41`
- `.github/workflows/ci.yml:47`
- `.github/workflows/ci.yml:52`
- `.github/workflows/ci.yml:88`
- `.github/workflows/ci.yml:91`

### suspicious-run-content (severity: high)

Sub-check `eval-dynamic`: `hadolint.sh` uses `eval` with dynamically constructed content derived from `$flags` (which is set from `$*` — the Docker container arguments, populated from `inputs.dockerfile` and other user-controlled action inputs). Specifically: `RESULTS=$(eval "$COMMAND $flags" -- **/"$filename")` and `RESULTS=$(eval "$COMMAND" "$flags")`. An attacker-controlled `inputs.dockerfile` value containing shell metacharacters could cause arbitrary command execution via the `eval` call.

Locations:

- `hadolint.sh:33`
- `hadolint.sh:35`

### script-injection (severity: high)

Sub-rule (b) violation: In `.github/workflows/ci.yml`, the top-level `env:` block sets `TEST_IMAGE_NAME: hadolint-action:${{github.sha}}`, binding a workflow-context expression to an env var. The `run: docker build -t $TEST_IMAGE_NAME .` step then expands `$TEST_IMAGE_NAME` unquoted in the shell command. An unquoted shell variable expansion allows the shell to parse metacharacters out of the value. The variable should be double-quoted: `docker build -t "$TEST_IMAGE_NAME" .`

Locations:

- `.github/workflows/ci.yml:44`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, script-injection, suspicious-run-content

**Notes:**

1. Pinned all action references in .github/workflows/ci.yml to full 40-char SHAs: actions/checkout@v5→fbc6f39, reviewdog/action-shellcheck@v1.31.0→1bb9751, brpaz/structure-tests-action@v1.1.2→814df1d, cycjimmy/semantic-release-action@v5→ba33062. 2. Fixed unquoted $TEST_IMAGE_NAME in docker build command (added double quotes). 3. Rewrote hadolint.sh to eliminate eval with user-controlled input: replaced string-based command construction with bash arrays (CMD array for hadolint+config, flags array for positional args in recursive mode), invoking them safely with "${CMD[@]}" and "${flags[@]}" instead of eval.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In hadolint.sh, added a sanitization step before writing $RESULTS to $GITHUB_OUTPUT and $GITHUB_ENV. The fix introduces `SAFE_RESULTS="$(printf '%s' "$RESULTS" | tr -d '\n\r')"` after the existing string substitution, and replaces `echo "$RESULTS"` with `echo "$SAFE_RESULTS"` in both heredoc blocks. This prevents a crafted Dockerfile from producing linting output containing newlines that could inject arbitrary key=value pairs into $GITHUB_ENV or $GITHUB_OUTPUT.

