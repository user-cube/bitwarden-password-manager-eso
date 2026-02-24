#!/usr/bin/env bash
# Parses semantic-release notes (passed via stdin or $1) and writes
# the artifacthub.io/changes annotation into Chart.yaml.
#
# Usage: echo "$NOTES" | update-artifacthub-changes.sh <chart-yaml-path>

set -euo pipefail

CHART_YAML="${1:-charts/bitwarden-password-manager-eso/Chart.yaml}"
NOTES="${RELEASE_NOTES:-}"

declare -a changes=()

# Map conventional commit section headings to ArtifactHub change kinds
map_kind() {
  local section="$1"
  case "$section" in
    "Bug Fixes")      echo "fixed" ;;
    "Features")       echo "added" ;;
    "Performance"*)   echo "changed" ;;
    "Reverts")        echo "changed" ;;
    "Security"*)      echo "security" ;;
    "Deprecated"*)    echo "deprecated" ;;
    "Removed"*)       echo "removed" ;;
    *)                echo "changed" ;;
  esac
}

current_kind=""

while IFS= read -r line; do
  # Detect section headings like "### Bug Fixes" or "### Features"
  if [[ "$line" =~ ^###[[:space:]](.+)$ ]]; then
    current_kind=$(map_kind "${BASH_REMATCH[1]}")
    continue
  fi

  # Detect bullet entries like "* some description ([abc1234](...))"
  if [[ -n "$current_kind" && "$line" =~ ^\*[[:space:]](.+) ]]; then
    entry="${BASH_REMATCH[1]}"
    # Strip markdown links: keep only the description before " ([..."
    description=$(echo "$entry" | sed 's/ (\[.*//g' | sed 's/\*\*//g' | xargs)
    if [[ -n "$description" ]]; then
      changes+=("  - kind: ${current_kind}"$'\n'"    description: \"${description}\"")
    fi
  fi
done <<< "$NOTES"

if [[ ${#changes[@]} -eq 0 ]]; then
  echo "No changes detected, skipping artifacthub.io/changes update."
  exit 0
fi

# Build the annotation value
changes_yaml=$(printf '%s\n' "${changes[@]}")

# Use awk to replace or insert the annotation block in Chart.yaml
python3 - "$CHART_YAML" "$changes_yaml" <<'PYEOF'
import sys
import re

chart_path = sys.argv[1]
changes_yaml = sys.argv[2]

with open(chart_path, 'r') as f:
    content = f.read()

annotation_block = f'annotations:\n  artifacthub.io/changes: |\n'
for line in changes_yaml.splitlines():
    annotation_block += f'    {line}\n'

# If annotations section exists, replace the changes entry within it
if re.search(r'^annotations:', content, re.MULTILINE):
    # Replace existing artifacthub.io/changes value
    content = re.sub(
        r'  artifacthub\.io/changes: \|.*?(?=\n\S|\n  \S|\Z)',
        f'  artifacthub.io/changes: |\n' + '\n'.join(f'    {l}' for l in changes_yaml.splitlines()),
        content,
        flags=re.DOTALL
    )
else:
    # Append annotations section
    content = content.rstrip('\n') + '\n' + annotation_block

with open(chart_path, 'w') as f:
    f.write(content)

print(f"Updated {chart_path} with artifacthub.io/changes annotation.")
PYEOF
