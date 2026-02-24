#!/usr/bin/env bash
set -euo pipefail

CHART_FILE="${1:-}"
VERSION="${2:-}"

if [[ -z "$CHART_FILE" || -z "$VERSION" ]]; then
  echo "Usage: $0 <chart-file> <version>" >&2
  exit 1
fi

# Garante que existe um bloco `annotations:`
if ! grep -q '^annotations:' "$CHART_FILE"; then
  cat <<'EOF' >>"$CHART_FILE"

annotations:
EOF
fi

# Se já existir artifacthub.io/changes, substitui o bloco inteiro
if grep -q 'artifacthub.io/changes:' "$CHART_FILE"; then
  perl -0pi -e 's/artifacthub\.io\/changes: \|\n(?:[ \t].*\n)*/artifacthub.io\/changes: |\n    - kind: changed\n      description: Release '"$VERSION"'\n/' "$CHART_FILE"
else
  # Caso contrário, acrescenta categoria + changes no fim do ficheiro, dentro de annotations
  cat <<EOF >>"$CHART_FILE"
  artifacthub.io/category: security
  artifacthub.io/changes: |
    - kind: changed
      description: Release $VERSION
EOF
fi