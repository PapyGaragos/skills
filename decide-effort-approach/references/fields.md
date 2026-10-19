# Fields

Give only the fields the request names, in the format it names. The fields, under these names when the format has keys and the request names none:

- `outcome`: `chosen`, `kept`, `switched` or `needs a person`.
- `approaches`: the slugs chosen, kept or switched to; empty for `needs a person`.
- `from`: on a switch, the slugs switched away from.
- `why`: for `needs a person`, why, in a few words.
- `uncovered`: the criteria no chosen approach covers.
- `logbook`: the logbook's `path` and the `node` where the decision was worked out, the same one the `decided by:` note names.

An empty list stays an empty list. A structured format (YAML, JSON, CSV) comes bare, with no code fence, so it can be read as it is by a person or a script. Nothing goes before or after it.
