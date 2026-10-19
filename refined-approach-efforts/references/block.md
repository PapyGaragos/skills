# Block

The answer is this block alone, as plain text with no code fence around it (the fence below only marks the template):

```
children:
- <slug>: <written|reused> <path>, step <the step>
approach: <path>, decision <logbook path> <node>
logbook: <path>
edits:
- <path>[:<line>]: <the change>
<criterion>: complete
  - <child>: needed, <what would be missing without it>
  - <child>: helps, <which child already does it, or what it improves without being required>
<criterion>: open, missing <what stays false once every child serving it is reached>
  - <child>: needed, <what it moves that no other child does>
outside the definition of done:
  - <child>: <what it moves instead>
missing steps: <criterion>, ...: ground for propose-effort-approach on <approach-slug>
uncovered: <criterion>, ...: ground for propose-effort-approach on <effort-slug>
```

One `approach:` line per approach whose steps gained a reference. Each reason is one clause. A child appears under every criterion it serves, its verdict possibly differing. A child moving a criterion it does not name carries `(not named)` after its slug. With no step made an effort, write `children: none` and leave out `approach:`. Leave out `edits:`, `outside the definition of done:`, `missing steps:` and `uncovered:` when empty. No sentence before or after: another skill may read the block as it is.
