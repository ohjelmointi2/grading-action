#!/usr/bin/env bash

set -uo pipefail

test_suite="${1:-.grading/config.json}"
CONFIG_FILE="${GITHUB_WORKSPACE:-$PWD}/$test_suite"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: grading configuration not found in file $CONFIG_FILE"
    exit 1
fi

total_score=0
max_score=0

report="## Grading

| Test | Result | Points |
|------|--------|--------|
"

failures="## Failures

"

has_failures=false

mkdir -p .grading-logs

while IFS= read -r test; do
    name=$(jq -r '.name' <<< "$test")
    run=$(jq -r '.run' <<< "$test")
    points=$(jq -r '.points' <<< "$test")
    timeout=$(jq -r '.timeout // 10' <<< "$test")

    max_score=$((max_score + points))

    safe_name=$(echo "$name" | tr ' /' '__')
    log_file=".grading-logs/${safe_name}.log"

    echo "Running: $name"

    if timeout --verbose $timeout bash -c "$run" \
        >"$log_file" \
        2>&1; then

        total_score=$((total_score + points))
        report+="| ${name} | ✅ Pass | ${points}/${points} |
"

        echo "PASS: $name (+$points)"
    else
        has_failures=true

        report+="| ${name} | ❌ Fail | 0/${points} |
"

        echo "FAIL: $name (+0)"
        echo "$(cat ${log_file})"

        failures+="### ${name}
"


        if [[ -s "$log_file" ]]; then
            failures+="
\`\`\`text
$run

$(cat "$log_file")
\`\`\`

"
        fi

        if [[ ! -s "$log_file" ]]; then
            failures+="No output captured.

"
        fi
    fi
    echo

done < <(jq -c '.tests[]' "$CONFIG_FILE")

report+="
**🏅 Total points: ${total_score}/${max_score}**

"

if [[ "$has_failures" == true ]]; then
    report+="${failures}"
fi

echo "========================="
echo "🏅 Total points: ${total_score}/${max_score}"
echo "========================="

if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
    echo "$report" >> "$GITHUB_STEP_SUMMARY"
fi

{
    echo "TOTAL_SCORE=$total_score"
    echo "MAX_SCORE=$max_score"
} >> "$GITHUB_ENV" 2>/dev/null || true

{
    result="success"
    if [[ "$has_failures" == true ]]; then
        result="failure"
    fi
    echo "status_state=$result"
    echo "status_description=Score: ${total_score}/${max_score}"
} >> "${GITHUB_OUTPUT:-/dev/null}"

if [[ "$has_failures" == true ]]; then
    exit 1
fi
