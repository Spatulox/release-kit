#!/usr/bin/env bash
# Prints the CHANGELOG.md section matching a tag.
#
#   changelog.sh <tag> [CHANGELOG.md]
#
# Looks for a "## <tag>" heading (e.g. "## v1.2.0_beta", "## [v1.2.0_beta] - 2026-11-12"),
# then, failing that, "## v1.2.0" or "## 1.2.0". Exits with code 1 if nothing is found.
set -euo pipefail

tag="${1:?usage: changelog.sh <tag> [CHANGELOG.md]}"
file="${2:-CHANGELOG.md}"

[ -f "$file" ] || { echo "File not found: $file" >&2; exit 1; }

extract() {
  awk -v want="$1" '
    /^## / {
      if (found) exit
      key = $2
      gsub(/[][]/, "", key)
      if (key == want) { found = 1; next }
    }
    found {
      lines[++n] = $0
      if ($0 ~ /[^[:space:]]/) { if (!first) first = n; last = n }
    }
    END {
      for (i = first; first && i <= last; i++) print lines[i]
      exit !found
    }
  ' "$file"
}

version="${tag%%_*}"   # v1.2.0_beta -> v1.2.0
version="${version#v}" # v1.2.0      -> 1.2.0

for key in "$tag" "v$version" "$version"; do
  if extract "$key"; then
    exit 0
  fi
done

echo "No CHANGELOG entry for $tag" >&2
exit 1
