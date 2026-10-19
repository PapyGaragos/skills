# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

- `advanced`: the effort's slug; `via`: the descendant advanced, when there is one.
- `did`: what the run did, one line.
- `criteria`: a list for the effort the run worked on, each item with its `slug` and `state` (`met`, `unmet`, `unknown`, or a metric's value).
- `asks`: the questions the run stopped on or its next action depends on, each standing on its own; a guess nothing depended on stays out.
- `stopped`: why the run stopped.
- `logbook`: the logbook's `path` and the `node` of the run's goal.

An empty list stays an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it.
