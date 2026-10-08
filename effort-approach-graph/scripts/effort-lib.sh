# Shared helpers for the effort scripts: read <slug>-effort.md and
# <slug>-approach.md files and find them by slug. Sourced, not run.
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

# The parents in the contributes-to map as "<line> <slug> [<approach>...]":
# each key, then the parent's approaches its list names (none for []),
# without a "# guessed" comment.
parents_of() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^contributes-to:/ { f = 1; next }
    f && /^[ ]+[^ :]+:/ {
      s = $0; sub(/^[ ]+/, "", s); sub(/:.*$/, "", s)
      a = $0; sub(/^[^:]*:/, "", a); sub(/#.*$/, "", a); gsub(/[][,]/, " ", a); gsub(/[ ]+/, " ", a); sub(/[ ]+$/, "", a)
      print NR, s a; next
    }
    f { f = 0 }' "$1"
}

# The lines of one section shaped "- [<tag>] <slug> : <text>", as
# "<line>\t<tag>\t<slug>\t<text>", without a trailing "# guessed": as-effort
# lines in Limits, where the tag is a kind. Nested lines and lines of another
# shape are skipped.
section_efforts() {
  awk -v want="$2" '
    /^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == want); next }
    in_s && /^- \[[a-z]+\] [a-z0-9]+(-[a-z0-9]+)* : / {
      l = $0; sub(/ # guessed[ ]*$/, "", l)
      kind = l; sub(/^- \[/, "", kind); sub(/\].*/, "", kind)
      slug = l; sub(/^- \[[a-z]+\] /, "", slug); sub(/ : .*/, "", slug)
      intent = l; sub(/^[^:]* : /, "", intent)
      print NR "\t" kind "\t" slug "\t" intent
    }' "$1"
}

# The approaches of a file's Approaches section as "<line> <status> <slug>",
# in the file's order, dropped ones included. A line is
# "- [<status>] <approach-slug> (logbook: <path>)"; lines of another shape
# are skipped.
approaches_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Approaches"); next }
    in_s && /^- \[[a-z]+\] [a-z0-9]+(-[a-z0-9]+)*( |$)/ {
      st = $0; sub(/^- \[/, "", st); sub(/\].*/, "", st)
      a = $0; sub(/^- \[[a-z]+\] /, "", a); sub(/ .*/, "", a)
      print NR, st, a
    }' "$1"
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

# The criteria a file's Definition of done names, in the file's order: the slug
# that opens each "- <slug>  Done when|Held when|Metric:" entry.
criteria_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Definition of done"); next }
    in_s && /^- [a-z0-9]+(-[a-z0-9]+)*[ \t]+(Done when|Held when|Metric):/ { l = $0; sub(/^- /, "", l); sub(/[ \t].*/, "", l); print l }' "$1"
}

# The Serves entries of a file as "<line>\t<parent>\t<criterion>", one per
# entry under a "### <parent>" heading. The criterion is the slug the entry
# opens with, as in criteria_of, and is empty when it opens with none.
serves_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Serves"); p = ""; next }
    in_s && /^### / { p = $0; sub(/^### +/, "", p); sub(/[ \t]+$/, "", p); next }
    in_s && p != "" && /^- / {
      c = ""
      if ($0 ~ /^- [a-z0-9]+(-[a-z0-9]+)*[ \t]+(Done when|Held when|Metric):/) { c = $0; sub(/^- /, "", c); sub(/[ \t].*/, "", c) }
      print NR "\t" p "\t" c
    }' "$1"
}

# Every <slug>-approach.md under a root, keyed by slug, as index_efforts does.
declare -A approach_paths=()
index_approaches() {
  local path slug
  approach_paths=()
  while IFS= read -r path; do
    slug=${path##*/}
    slug=${slug%-approach.md}
    approach_paths[$slug]+=$path$'\n'
  done < <(find "$1" -name '*-approach.md' -not -path '*/.git/*' 2>/dev/null | LC_ALL=C sort)
}

# The efforts an approach file's contributes-to list names, as
# "<line> <effort>".
reaches_of() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
    $0 == "---" { exit }
    /^contributes-to:/ { f = 1; next }
    f && /^[ ]+-[ ]+[^ ]/ { e = $0; sub(/^[ ]+-[ ]+/, "", e); sub(/[ ]+$/, "", e); print NR, e; next }
    f && /^[^ ]/ { f = 0 }' "$1"
}

# An approach file's lead line: the first line after the frontmatter that is
# neither blank nor a heading, before any section.
lead_of() {
  awk 'NR == 1 && $0 == "---" { fm = 1; next }
    fm && $0 == "---" { fm = 0; next }
    fm { next }
    /^## / { exit }
    NF && !/^#/ { print; exit }' "$1"
}

# The criterion names an approach file lists under "### <effort>" in its
# Covers section, in the file's order.
covers_of() {
  awk -v want="$2" '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Covers"); h = ""; next }
    in_s && /^### / { h = $0; sub(/^### +/, "", h); sub(/[ \t]+$/, "", h); next }
    in_s && h == want && /^- [a-z0-9]+(-[a-z0-9]+)*([ \t]|$)/ { l = $0; sub(/^- /, "", l); sub(/[ \t].*/, "", l); print l }' "$1"
}

# The steps of an approach file that end with "(<effort-slug>, ...)", as
# "<line> <effort>", one line per effort.
step_efforts_of() {
  awk '/^## / { s = $0; sub(/^## +/, "", s); sub(/[ \t]+$/, "", s); in_s = (s == "Steps"); next }
    in_s && /^[ ]*([0-9]+\.|-)[ ]+.*[^ ][ ]+\([a-z0-9]+(-[a-z0-9]+)*(, [a-z0-9]+(-[a-z0-9]+)*)*\)[ ]*$/ {
      e = $0; sub(/[ ]*\)[ ]*$/, "", e); sub(/.*\(/, "", e); n = split(e, es, /, /)
      for (i = 1; i <= n; i++) print NR, es[i]
    }' "$1"
}
