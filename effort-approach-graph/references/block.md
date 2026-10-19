# Block

The answer is the block for the task alone, as plain text with no code fence around it (the fences below only mark the templates), no sentence before or after it, and every line in its template's shape. Write `none` as the whole value of an empty field, as in `edits: none`. End each guessed parent or child with ` # guessed`, as an effort file marks a guessed parent.

Placing one effort:

```
duplicate: <slug>, at <its places>
parents:
- <slug>: <how reaching this state moves the parent's, in one clause>
children:
- <slug>: <how reaching the child's state moves this one, in one clause>
edits:
- <path>[:<line>]: <the change>
```

Auditing the graph:

```
duplicates:
- <kept slug>: <the other slugs>
edits:
- <path>[:<line>]: <the change>
```
