<!-- markdownlint-disable -->

# Hardening Report: hadolint--hadolint-action/v3.1.0

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `1`

Action **hadolint--hadolint-action/v3.1.0** was hardened automatically. 4 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### unpinned-uses (severity: high)

Multiple uses: references in .github/workflows/ci.yml are pinned to mutable tags or version strings rather than full 40-character SHA commit hashes. Affected references: actions/checkout@v3 (lines 17, 26, 44), actions/checkout@v2 (line 84), brpaz/structure-tests-action@v1.1.2 (line 30), cycjimmy/semantic-release-action@v3 (line 85). These can be silently updated by the upstream maintainer, enabling supply-chain attacks.

Locations:

- `.github/workflows/ci.yml:17`
- `.github/workflows/ci.yml:26`
- `.github/workflows/ci.yml:30`
- `.github/workflows/ci.yml:44`
- `.github/workflows/ci.yml:84`
- `.github/workflows/ci.yml:85`

### missing-permissions (severity: medium)

The workflow file .github/workflows/ci.yml has no top-level permissions: key and no job-level permissions: block on any of its jobs (lint, build-test, integration-tests, release). Without explicit permissions, the workflow inherits the default broad permissions, which may include write access to repository contents and other resources.

Locations:

- `.github/workflows/ci.yml:1`

### script-injection (severity: high)

Rule (a) violation: A ${{ }} expression is directly interpolated inside a run: shell command string. In the integration-tests job, the step 'Run integration test 6 - verify results output parameter' uses: run: echo "${{ steps.hadolint5.outputs.results }}". The steps.*.outputs.* context is workflow-controllable and is interpolated directly into the shell command before the shell processes it, enabling script injection.

Locations:

- `.github/workflows/ci.yml:82`

### github-env-injection (severity: high)

In hadolint.sh, the RESULTS variable (output from running hadolint on a user-controlled Dockerfile path passed via inputs.dockerfile) is written to $GITHUB_OUTPUT and $GITHUB_ENV without sanitization (no printf '%s' ... | tr -d '\n\r' step). The writes are: 'echo "${RESULTS}" >> $GITHUB_OUTPUT' and '{ echo "HADOLINT_RESULTS<<EOF"; echo "$RESULTS"; echo "EOF"; } >> $GITHUB_ENV'. Hadolint output can contain newlines derived from Dockerfile content, enabling newline injection into the special environment files.

Locations:

- `hadolint.sh:44`
- `hadolint.sh:48`

## Iteration Notes

### Iteration 1

**Fixes applied:** unpinned-uses, missing-permissions, script-injection, github-env-injection

**Notes:**

Fixed all four findings:
1. unpinned-uses: Pinned all action references in .github/workflows/ci.yml to full SHAs: actions/checkout@v3 → f43a0e5ff2bd294095638e18286ca9a3d1956744, actions/checkout@v2 → ee0669bd1cc54295c223e0bb666b733df41de1c5, brpaz/structure-tests-action@v1.1.2 → 814df1d626990796d73100ef248792a7d03260ea, cycjimmy/semantic-release-action@v3 → 8e58d20d0f6c8773181f43eb74d6a05e3099571d.
2. missing-permissions: Added top-level `permissions: {}` and job-level permissions blocks (contents: read for lint/build-test/integration-tests; contents/issues/pull-requests: write for release).
3. script-injection: Moved `${{ steps.hadolint5.outputs.results }}` from the run: shell string into an env: block as HADOLINT5_RESULTS, referenced as $HADOLINT5_RESULTS in the shell.
4. github-env-injection: In hadolint.sh, added `SAFE_RESULTS=$(printf '%s' "$RESULTS" | tr -d '\n\r')` to sanitize before writing to $GITHUB_OUTPUT and $GITHUB_ENV, preventing newline injection.

