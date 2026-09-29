#!/usr/bin/env bash
# Print the intent of each named effort and of its parents, read from the
# frontmatter of <slug>-effort.md files. Run it on an effort's parents to see
# the intents one and two levels up without copying them into the file.
# With --all, print every effort under the root instead, one line each.
#
# Usage: effort-intents.sh [--root DIR] SLUG...
#        effort-intents.sh [--root DIR] --all
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/effort-lib.sh"

usage() {
  echo "usage: effort-intents.sh [--root DIR] SLUG... | [--root DIR] --all" >&2
  exit 2
}

root=. all=0
while [[ ${1:-} == --* ]]; do
  case $1 in
    --root) [[ $# -ge 2 ]] || usage; root=$2; shift 2 ;;
    --all) all=1; shift ;;
    *) usage ;;
  esac
done
if (( all )); then [[ $# -eq 0 ]] || usage; else [[ $# -gt 0 ]] || usage; fi

index_efforts "$root"

show() {
  local slug=$1 depth=$2 indent=$3 file parent
  find_file "$slug"
  file=$found
  if [[ -z $file ]]; then
    echo "${indent}${slug}: (no ${slug}-effort.md under $root)"
    return
  fi
  echo "${indent}${slug}: $(intent_of "$file")"
  if (( depth > 0 )); then
    for parent in $(parents_of "$file"); do
      show "$parent" $((depth - 1)) "$indent  "
    done
  fi
}

# One line per file, sorted by slug. A duplicate slug gets a line per file.
if (( all )); then
  for slug in $(printf '%s\n' "${!effort_paths[@]}" | LC_ALL=C sort); do
    find_file "$slug"
    while IFS= read -r file; do
      echo "$slug [$(field_of "$file" kind)]: $(intent_of "$file")"
    done <<< "${effort_paths[$slug]%$'\n'}"
  done
  exit 0
fi

for slug in "$@"; do
  show "$slug" 1 ""
done
