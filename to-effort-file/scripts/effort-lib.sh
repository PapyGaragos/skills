# Shared helpers for the effort scripts: read the frontmatter of
# <slug>-effort.md files and find those files by slug. Sourced, not run.
# shellcheck shell=bash

frontmatter() {
  awk 'NR == 1 && $0 == "---" { f = 1; next } f && $0 == "---" { exit } f' "$1"
}

# A one-line field such as name or kind, trimmed.
field_of() {
  frontmatter "$1" | awk -v key="$2" '
    index($0, key ":") == 1 { sub(/^[^:]*:[ ]*/, ""); sub(/[ ]+$/, ""); print; exit }'
}

# The intent field, either inline or as a folded/literal block (>-, |).
intent_of() {
  frontmatter "$1" | awk '
    !block && /^intent:/ {
      sub(/^intent:[ ]*/, "")
      if ($0 ~ /^[>|]/) { block = 1; next }
      print; done = 1; exit
    }
    block && /^[ ]+/ { sub(/^[ ]+/, ""); text = text (text == "" ? "" : " ") $0; next }
    block { exit }
    END { if (!done && text != "") print text }'
}

# The contributes-to list, without trailing "# guessed" comments.
parents_of() {
  frontmatter "$1" | awk '
    /^contributes-to:/ { f = 1; next }
    f && /^[ ]+- / { sub(/^[ ]+- /, ""); sub(/[ ]*#.*$/, ""); print; next }
    f { exit }'
}

# Every <slug>-effort.md under a root, keyed by slug. A slug can be carried by
# several files, so each value holds all their paths, one per line.
declare -A effort_paths=() effort_warned=()
index_efforts() {
  local path slug
  effort_paths=()
  while IFS= read -r path; do
    slug=${path##*/}
    slug=${slug%-effort.md}
    effort_paths[$slug]+=$path$'\n'
  done < <(find "$1" -name '*-effort.md' -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
}

# Set `found` to the first file carrying the slug, or to nothing. When several
# files carry it, warn once on stderr and name them all, since only the first
# is read.
find_file() {
  local paths=${effort_paths[$1]:-}
  # shellcheck disable=SC2034  # read by the caller
  found=${paths%%$'\n'*}
  if [[ $paths == *$'\n'*$'\n'* && -z ${effort_warned[$1]:-} ]]; then
    effort_warned[$1]=1
    echo "warning: slug $1 is carried by several files: $(echo "${paths%$'\n'}" | paste -sd ' ')" >&2
  fi
}
