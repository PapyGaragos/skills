# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

- `slug` and `contributes_to` (the list of effort slugs).
- `lead`: the lead line.
- `steps`: the list of steps; a nested group is an item with its `text` and its own `steps`, and `ordered` (true for a numbered list).
- `assumptions`: a list, each item with its `slug`, `holds` (what will or will not be true) and `breaks_when` when there is one.
- `covers` and `risks`: per effort slug, a list, each item with its `name` (criterion name, or limit slug for a risk) and `how` when there is one.

An empty part is an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. The reply starts with its first key or bracket and ends with its last value: no line before it, not even one saying what follows, and no remark on what the approach covers after it.
