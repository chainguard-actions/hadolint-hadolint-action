#!/bin/bash
# The problem-matcher definition must be present in the repository
# checkout (outside the Docker container running hadolint). We copy
# problem-matcher.json to the home folder.

PROBLEM_MATCHER_FILE="/problem-matcher.json"
if [ -f "$PROBLEM_MATCHER_FILE" ]; then
  cp "$PROBLEM_MATCHER_FILE" "$HOME/"
fi
# After the run has finished we remove the problem-matcher.json from
# the repository so we don't leave the checkout dirty. We also remove
# the matcher so it won't take effect in later steps.
# shellcheck disable=SC2317
cleanup() {
  echo "::remove-matcher owner=brpaz/hadolint-action::"
}
trap cleanup EXIT

echo "::add-matcher::$HOME/problem-matcher.json"

COMMAND=(hadolint)
if [ -n "$HADOLINT_CONFIG" ]; then
  COMMAND+=(-c "$HADOLINT_CONFIG")
fi

if [ -z "$HADOLINT_TRUSTED_REGISTRIES" ]; then
  unset HADOLINT_TRUSTED_REGISTRIES
fi

if [ "$HADOLINT_RECURSIVE" = "true" ]; then
  shopt -s globstar

  filename="${!#}"
  flags=("${@:1:$#-1}")

  RESULTS=$("${COMMAND[@]}" "${flags[@]}" -- **/"$filename")
else
  # Word-split and glob each argument (as the former eval did) without
  # evaluating any shell syntax contained in the values.
  flags=()
  for arg in "$@"; do
    # shellcheck disable=SC2206
    flags+=($arg)
  done
  RESULTS=$("${COMMAND[@]}" "${flags[@]}")
fi
FAILED=$?

if [ -n "$HADOLINT_OUTPUT" ]; then
  if [ -f "$HADOLINT_OUTPUT" ]; then
    HADOLINT_OUTPUT="$TMP_FOLDER/$HADOLINT_OUTPUT"
  fi
  echo "$RESULTS" >"$HADOLINT_OUTPUT"
fi

RESULTS="${RESULTS//$'\\n'/''}"

EOF="EOF_$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"

{
  echo "results<<$EOF"
  echo "$RESULTS"
  echo "$EOF"
} >>"$GITHUB_OUTPUT"

{
  echo "HADOLINT_RESULTS<<$EOF"
  echo "$RESULTS"
  echo "$EOF"
} >>"$GITHUB_ENV"

[ -z "$HADOLINT_OUTPUT" ] || echo "Hadolint output saved to: $HADOLINT_OUTPUT"

exit $FAILED
