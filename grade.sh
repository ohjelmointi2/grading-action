#!/usr/bin/env bash

set -uo pipefail

CONFIG_FILE="${GITHUB_WORKSPACE}/.grading/config.json"

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

    max_score=$((max_score + points))

    safe_name=$(echo "$name" | tr ' /' '__')
    log_file=".grading-logs/${safe_name}.log"

    echo "Running: $name"

    if bash -c "$run" \
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
$(cat "$log_file")
\`\`\`

"
        fi

        if [[ ! -s "$log_file" ]]; then
            failures+="No output captured.

"
        fi
    fi

done < <(jq -c '.tests[]' "$CONFIG_FILE")

report+="
**🏅 Total points: ${total_score}/${max_score}**

"

if [[ "$has_failures" == true ]]; then
    report+="${failures}"
fi

echo
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

if [[ "$has_failures" == true ]]; then
    exit 1
fi