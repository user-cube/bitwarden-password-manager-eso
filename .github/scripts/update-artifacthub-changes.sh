#!/usr/bin/env bash
# Reads the latest entry from CHANGELOG.md and writes the
# artifacthub.io/changes annotation into Chart.yaml.
#
# Usage: update-artifacthub-changes.sh <chart-yaml-path> <changelog-path>

set -euo pipefail

CHART_YAML="${1:-charts/bitwarden-password-manager-eso/Chart.yaml}"
CHANGELOG="${2:-CHANGELOG.md}"

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

declare -a changes=()
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
      changes+=("  - kind: ${current_kind}"$'\n'"    description: \"${description}\"")
    fi
  fi
done < "$CHANGELOG"

if [[ ${#changes[@]} -eq 0 ]]; then
  echo "No changes detected, skipping artifacthub.io/changes update."
  exit 0
fi

changes_yaml=$(printf '%s\n' "${changes[@]}")

python3 - "$CHART_YAML" <<PYEOF
import sys
import re

chart_path = sys.argv[1]
changes_yaml = """$changes_yaml"""

with open(chart_path, 'r') as f:
    content = f.read()

new_annotation = '  artifacthub.io/changes: |\n'
for line in changes_yaml.splitlines():
    new_annotation += f'    {line}\n'

if re.search(r'^\s*artifacthub\.io/changes:', content, re.MULTILINE):
    content = re.sub(
        r'  artifacthub\.io/changes: \|.*?(?=\n  \S|\nappVersion|\nversion|\Z)',
        new_annotation.rstrip('\n'),
        content,
        flags=re.DOTALL
    )
elif re.search(r'^annotations:', content, re.MULTILINE):
    content = re.sub(
        r'^(annotations:)',
        r'\1\n' + new_annotation.rstrip('\n'),
        content,
        flags=re.MULTILINE
    )
else:
    content = content.rstrip('\n') + '\nannotations:\n' + new_annotation

with open(chart_path, 'w') as f:
    f.write(content)

print(f"Updated {chart_path} with artifacthub.io/changes annotation.")
PYEOF
