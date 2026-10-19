# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

Placing one effort:

- `duplicate`: the node already carrying this state, with its `slug` and `places`; empty when none.
- `parents` and `children`: lists, each item with its `slug`, `how` (how reaching one state moves the other, in one clause) and `guessed` (true when neither the input nor the files name it).
- `edits`: a list, each item with its `path`, `line` when there is one, and `change`.

Auditing the graph:

- `duplicates`: a list, each item with its `kept` slug, its `others` and `merge_to_decide` (true when two members both have files).
- `edits`: as above.

An empty list stays an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it.
