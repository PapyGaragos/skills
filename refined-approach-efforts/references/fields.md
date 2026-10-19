# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

- `children`: a list, each item with its `slug`, `how` (`written` or `reused`), `path` and `step`.
- `approaches`: a list of the approach files whose steps gained a reference, each with its `path` and the `decision` (logbook path and node).
- `logbook`: the logbook's path.
- `edits`: the proposed edits to files this run did not write, each with its `path`, `line` when there is one, and `change`.
- `criteria`: a list, each item with its `slug`, `verdict` (`complete` or `open`), `missing` when open (what stays false once every child serving it is reached), and `children`, each with its `slug`, `verdict` (`needed` or `helps`), `reason` in one clause and `named` (false when its Serves entries do not name this criterion).
- `outside`: the children moving no criterion, each with its `slug` and what it moves instead.
- `missing_steps`: the criteria a missing step leaves open, with the approach to propose on.
- `uncovered`: the criteria no chosen approach covers.

An empty list stays an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it.
