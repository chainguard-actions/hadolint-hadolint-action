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

# Build the command as an array instead of using eval on user-controlled input
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
  # Unquoted expansion word-splits (and globs) like upstream's eval did,
  # but never evaluates the content as shell code.
  # shellcheck disable=SC2206
  flags=(${*:1:$#-1})

  RESULTS=$("${CMD[@]}" "${flags[@]}" -- **/"$filename")
else
  # shellcheck disable=SC2206
  flags=($*)
  RESULTS=$("${CMD[@]}" "${flags[@]}")
fi
FAILED=$?

if [ -n "$HADOLINT_OUTPUT" ]; then
  if [ -f "$HADOLINT_OUTPUT" ]; then
    HADOLINT_OUTPUT="$TMP_FOLDER/$HADOLINT_OUTPUT"
  fi
  echo "$RESULTS" >"$HADOLINT_OUTPUT"
fi

RESULTS="${RESULTS//$'\\n'/''}"

EOF_DELIM="EOF_$(od -An -N16 -tx1 /dev/urandom | tr -d ' \n')"

{
  echo "results<<$EOF_DELIM"
  echo "$RESULTS"
  echo "$EOF_DELIM"
} >>"$GITHUB_OUTPUT"

{
  echo "HADOLINT_RESULTS<<$EOF_DELIM"
  echo "$RESULTS"
  echo "$EOF_DELIM"
} >>"$GITHUB_ENV"

[ -z "$HADOLINT_OUTPUT" ] || echo "Hadolint output saved to: $HADOLINT_OUTPUT"

exit $FAILED
