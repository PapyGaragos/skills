# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

- `question`: the logbook `path`, the question's `node` and its `text`.
- `options`: a list, each item with its `slug`, `status` (as the effort's section now reads), `lead` (the lead line), `file` (the approach file's path) and `node` (its option's path).
- `uncovered`: the criteria no option on the question covers.
- `decision`: when a decider ran, its `outcome`, the `approaches` it names, the criteria it leaves `uncovered`, and the logbook `node` where it worked the decision out; empty otherwise.

An empty list stays an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it.
