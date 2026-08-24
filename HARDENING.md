<!-- markdownlint-disable -->

# Hardening Report: hadolint--hadolint-action/v3.5.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **hadolint--hadolint-action/v3.5.0** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

All `uses:` references in .github/workflows/ci.yml use mutable tag/version strings instead of pinned 40-character SHA commit hashes, making the workflow vulnerable to supply-chain attacks if any referenced action is compromised or its tag is moved. Failing references: `actions/checkout@v5` (×4 occurrences), `reviewdog/action-shellcheck@v1.31.0`, `brpaz/structure-tests-action@v1.1.2`, `cycjimmy/semantic-release-action@v5`.

Locations:

- `.github/workflows/ci.yml:22`
- `.github/workflows/ci.yml:30`
- `.github/workflows/ci.yml:32`
- `.github/workflows/ci.yml:42`
- `.github/workflows/ci.yml:46`
- `.github/workflows/ci.yml:58`
- `.github/workflows/ci.yml:103`
- `.github/workflows/ci.yml:105`

### github-env-injection (severity: high)

In hadolint.sh (the Docker action entrypoint), the variable $RESULTS — which contains output from running hadolint against user-controlled Dockerfiles and is derived from `eval "$COMMAND $flags"` where $flags comes from action inputs — is written to both $GITHUB_OUTPUT (line ~49) and $GITHUB_ENV (line ~55) using heredoc syntax without any sanitization step (`printf '%s' ... | tr -d '\n\r'`). If hadolint output contains newlines that include the heredoc delimiter `EOF`, this can allow injection of arbitrary key=value pairs into the GitHub environment, potentially overwriting environment variables used by subsequent steps.

Locations:

- `hadolint.sh:49`
- `hadolint.sh:55`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, github-env-injection

**Notes:**

Fixed all 8 unpinned action references in .github/workflows/ci.yml by pinning to full commit SHAs: actions/checkout@v5 (×4) → fbc6f3992d24b796d5a048ff273f7fcc4a7b6c09, reviewdog/action-shellcheck@v1.31.0 → 1bb9751763fdfbee4b5043772c37374f103bff9e, brpaz/structure-tests-action@v1.1.2 → 814df1d626990796d73100ef248792a7d03260ea, cycjimmy/semantic-release-action@v5 → ba330626c4750c19d8299de843f05c7aa5574f62. Fixed github-env-injection in hadolint.sh by sanitizing the RESULTS variable with `printf '%s' "$RESULTS" | tr -d '\n\r'` before writing to $GITHUB_OUTPUT and $GITHUB_ENV, preventing heredoc delimiter injection attacks.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

Fixed the unquoted shell variable expansion in `.github/workflows/ci.yml` line 50. Changed `docker build -t $TEST_IMAGE_NAME .` to `docker build -t "$TEST_IMAGE_NAME" .` to properly quote the variable that is derived from `github.sha` via the top-level `env:` block.

