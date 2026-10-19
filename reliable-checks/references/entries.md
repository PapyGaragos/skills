# Entries

One entry per property, its check in the shape of its conditions, as plain text with no code fence around it (the fence below only marks the template):

```
<property>  [<form>] Done when: <condition>; <condition>. <what a pass proves, one clause>
<property>  [<form>] Held when: <condition>; <condition>, checked <when>. <what a pass proves, one clause>
<property>  [<form>] Metric: <what is measured, and how>, now <current value>, <lower|higher> is better[, ideal <ideal>]. <what a pass proves, one clause>
            ground with: [<form>] <check, in the same shape>
```

The label names the form the check takes, in a few plain words a reader gets at a glance, such as `[proof]`, `[test]`, `[CI check]`, `[script]`, `[LLM review]`, `[self-review]` or `[human decision]`. The rung picked the check, and it stays out of the output.

A check that doesn't exist yet carries `(to write)` right after its label: `[<form>] (to write) Done when: ...`.

Say what a pass proves, not why the rung was picked. That is where a check that misses part of its property shows. The `ground with` line appears only under `judge` and `intrinsic`. A `human` entry reads `Done when: <who> decides or approves <what>`. When an automated proxy exists, add it on a `proxy:` line.

Stop after the last entry, with no preamble, advice paragraphs, fallback plans or advice on which check to start with. Don't write the check, run it, or explain the hierarchy. Another skill may read the output as it is, so keep this shape even when talking to a person.
