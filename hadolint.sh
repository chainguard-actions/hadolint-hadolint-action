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

# Build the base command as an array to avoid eval with user-controlled input
CMD=(hadolint)

if [ -n "$HADOLINT_CONFIG" ]; then
  CMD+=(-c "$HADOLINT_CONFIG")
fi

if [ -z "$HADOLINT_TRUSTED_REGISTRIES" ]; then
  unset HADOLINT_TRUSTED_REGISTRIES
fi

if [ "$HADOLINT_RECURSIVE" = "true" ]; then
  shopt -s globstar

  filename="${!#}"
  # Collect all flags (positional args except the last one) into an array
  flags=()
  for ((i = 1; i < $#; i++)); do
    flags+=("${!i}")
  done

  # shellcheck disable=SC2206
  RESULTS=$("${CMD[@]}" "${flags[@]}" -- **/"$filename")
else
  RESULTS=$("${CMD[@]}" "$@")
fi
FAILED=$?

if [ -n "$HADOLINT_OUTPUT" ]; then
  if [ -f "$HADOLINT_OUTPUT" ]; then
    HADOLINT_OUTPUT="$TMP_FOLDER/$HADOLINT_OUTPUT"
  fi
  echo "$RESULTS" >"$HADOLINT_OUTPUT"
fi

RESULTS="${RESULTS//$'\\n'/''}"

SAFE_RESULTS="$(printf '%s' "$RESULTS" | tr -d '\n\r')"

{
  echo "results<<EOF"
  echo "$SAFE_RESULTS"
  echo "EOF"
} >>"$GITHUB_OUTPUT"

{
  echo "HADOLINT_RESULTS<<EOF"
  echo "$SAFE_RESULTS"
  echo "EOF"
} >>"$GITHUB_ENV"

[ -z "$HADOLINT_OUTPUT" ] || echo "Hadolint output saved to: $HADOLINT_OUTPUT"

exit $FAILED
