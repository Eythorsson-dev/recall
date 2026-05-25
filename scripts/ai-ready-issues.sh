#!/usr/bin/env bash
# Fetch AI-ready GitHub issues: open issues labeled "AI-Ready", not labeled
# "in-progress", with no unresolved blockers.
#
# A blocker is any line under the "## Blocked by" section of an issue body.
#   - "#NUMBER" entries are resolved when the referenced issue is closed.
#   - Free-text entries (e.g. "CloudKit milestone") are treated as unresolved
#     because their state can't be checked programmatically.
#
# Usage:
#   scripts/ai-ready-issues.sh           # tab-separated text: number, title, labels
#   scripts/ai-ready-issues.sh --json    # JSON array

set -euo pipefail

format=text
case "${1:-}" in
  --json) format=json ;;
  "")     ;;
  *)      echo "usage: $0 [--json]" >&2; exit 2 ;;
esac

for cmd in gh jq awk; do
  command -v "$cmd" >/dev/null || { echo "$cmd is required" >&2; exit 1; }
done

all_open=$(gh issue list --state open --limit 500 \
  --json number,title,url,labels,body)

open_numbers=$(jq -r '.[].number' <<< "$all_open" | sort -u)

# Only iterate over AI-Ready issues that aren't already in-progress.
# Blockers still resolve against ALL open issues.
candidates=$(jq -c '[
  .[]
  | select(any(.labels[]; .name == "AI-Ready"))
  | select(all(.labels[]; .name != "in-progress"))
]' <<< "$all_open")

ready=$(jq -c '.[]' <<< "$candidates" | while read -r issue; do
  body=$(jq -r '.body // ""' <<< "$issue")

  section=$(awk '
    /^##[[:space:]]+[Bb]locked by/ { inseg=1; next }
    /^##[[:space:]]/ && inseg     { exit }
    inseg
  ' <<< "$body")

  blocked=false
  while IFS= read -r line; do
    item=$(sed -E 's/^[[:space:]]*[-*][[:space:]]*//; s/[[:space:]]+$//' <<< "$line")
    [[ -z "$item" ]] && continue

    if [[ "$item" =~ ^#([0-9]+)$ ]]; then
      n="${BASH_REMATCH[1]}"
      if grep -qxF "$n" <<< "$open_numbers"; then
        blocked=true; break
      fi
    else
      blocked=true; break
    fi
  done <<< "$section"

  $blocked || echo "$issue"
done)

if [[ "$format" == json ]]; then
  jq -s '[.[] | {number, title, url, labels: [.labels[].name]}]' <<< "$ready"
else
  if [[ -z "$ready" ]]; then exit 0; fi
  jq -r '"#\(.number)\t\(.title)\t" + ([.labels[].name] | join(","))' <<< "$ready"
fi
