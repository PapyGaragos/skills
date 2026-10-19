# Brief

The brief is read by the proposer mid-task: two lines, all else in the logbook, as plain text with no code fence around it (the fence below only marks the template):

```
<outcome>[; uncovered: <criterion>, ...]
logbook: <path> <node>
```

The outcome is one of:

- `chosen: <slug>, ...`
- `kept: <slug>, ...`
- `switched: <old-slug>, ... to <new-slug>, ...`
- `needs a person: <why, in a few words>`

`; uncovered: <criterion>, ...` ends the first line when a criterion stays uncovered, a ground for propose-effort-approach. The second line names the subtree where the decision was worked out, the same one the `decided by:` note names. Nothing goes before or after the two lines, even when talking to a person: the reasons are in the logbook.
