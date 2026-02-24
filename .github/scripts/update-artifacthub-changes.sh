#!/usr/bin/env bash
# Reads the latest entry from CHANGELOG.md and writes the
# artifacthub.io/changes annotation into Chart.yaml.
#
# Usage: update-artifacthub-changes.sh <chart-yaml-path> <changelog-path>

set -euo pipefail

CHART_YAML="${1:-charts/bitwarden-password-manager-eso/Chart.yaml}"
CHANGELOG="${2:-CHANGELOG.md}"
CHANGES_FILE="$(mktemp)"

map_kind() {
  case "$1" in
    "Bug Fixes")    echo "fixed" ;;
    "Features")     echo "added" ;;
    "Performance"*) echo "changed" ;;
    "Reverts")      echo "changed" ;;
    "Security"*)    echo "security" ;;
    "Deprecated"*)  echo "deprecated" ;;
    "Removed"*)     echo "removed" ;;
    *)              echo "changed" ;;
  esac
}

current_kind=""
in_first_entry=0

while IFS= read -r line; do
  # Start capturing at the first version heading
  if [[ "$line" =~ ^##[[:space:]] && $in_first_entry -eq 0 ]]; then
    in_first_entry=1
    continue
  fi

  # Stop at the second version heading
  if [[ "$line" =~ ^##[[:space:]] && $in_first_entry -eq 1 ]]; then
    break
  fi

  # Detect subsection like "### Bug Fixes"
  if [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
    current_kind=$(map_kind "${BASH_REMATCH[1]}")
    continue
  fi

  # Detect bullet entries
  if [[ -n "$current_kind" && "$line" =~ ^\*[[:space:]](.+) ]]; then
    entry="${BASH_REMATCH[1]}"
    # Strip markdown links: "description ([abc](url))" -> "description"
    description=$(echo "$entry" | sed 's/ (\[.*//g' | sed 's/\*\*//g' | xargs)
    if [[ -n "$description" ]]; then
      printf '%s\t%s\n' "$current_kind" "$description" >> "$CHANGES_FILE"
    fi
  fi
done < "$CHANGELOG"

if [[ ! -s "$CHANGES_FILE" ]]; then
  echo "No changes detected, skipping artifacthub.io/changes update."
  rm -f "$CHANGES_FILE"
  exit 0
fi

python3 /dev/stdin "$CHART_YAML" "$CHANGES_FILE" << 'PYEOF'
import sys

chart_path = sys.argv[1]
changes_file = sys.argv[2]

# Build the annotation lines
lines = []
with open(changes_file) as f:
    for row in f:
        row = row.rstrip('\n')
        if '\t' not in row:
            continue
        kind, description = row.split('\t', 1)
        lines.append(f'    - kind: {kind}')
        lines.append(f'      description: "{description}"')

if not lines:
    print("No changes to write.")
    sys.exit(0)

new_block = '  artifacthub.io/changes: |\n' + '\n'.join(lines) + '\n'

with open(chart_path, 'r') as f:
    content = f.read()

import re

if re.search(r'^\s*artifacthub\.io/changes:', content, re.MULTILINE):
    # Replace existing annotation value
    content = re.sub(
        r'  artifacthub\.io/changes: \|.*?(?=\n  \S|\nappVersion:|\nversion:|\Z)',
        new_block.rstrip('\n'),
        content,
        flags=re.DOTALL
    )
elif re.search(r'^annotations:', content, re.MULTILINE):
    # Add under existing annotations block
    content = re.sub(
        r'^(annotations:\n)',
        r'\1' + new_block,
        content,
        flags=re.MULTILINE
    )
else:
    # Append new annotations section
    content = content.rstrip('\n') + '\nannotations:\n' + new_block

with open(chart_path, 'w') as f:
    f.write(content)

print(f"Updated {chart_path} with artifacthub.io/changes annotation.")
PYEOF

rm -f "$CHANGES_FILE"
