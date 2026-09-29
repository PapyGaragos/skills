---
name: reliable-checks
description: Describe the most reliable check that could confirm a property, a condition or a definition of done, without building, running or prescribing it. Places each check on the verification hierarchy (formal, execution, judge, intrinsic, or human), takes the most trusted one that covers the property, and says what a pass proves and what it leaves out. Use when the user asks how to verify, test, check or validate some work, how far a check can be trusted, or what would catch a failure, and whenever another skill asks for a verification method.
---

# Reliable checks

A check is only as good as the signal behind it. The verification hierarchy (Chen, Wang and Qu, 2026) ranks signals by how far they can be trusted. The signals that can be trusted most cover the fewest tasks, so the useful question for a given property is how high its check can go.

This skill describes the check. It does not decide what counts as done, and it does not write or run the check.

## The rungs, most trusted first

| rung | what belongs here | how it fails |
|---|---|---|
| `formal` | proof checkers, type systems, model checkers, schemas enforced by a tool | never accepts a false pass, but covers only what can be stated formally |
| `execution` | tests, compilers, linters, benchmarks, running the thing and comparing with a known answer, a mechanical lookup against a source | passing can hide wrong behavior the checks don't exercise; a fixed benchmark gets gamed over time |
| `judge` | an LLM or reward model scoring the output, a rubric scored by an LLM | only as good as the judge, has its biases (length, position, its own style), and gets optimized against |
| `intrinsic` | self-review, confidence, self-consistency across attempts | cheapest and least trustworthy, because the checker shares the blind spots of whoever did the work |

Above them sits `human`: a person decides. It is the only option when the property is itself a judgment of what is better or worth doing, such as taste, direction or priority.

## Steps

1. **Take the conditions as given.** The input may be a definition of done, a single condition, or a property. Its conditions are what a pass must show, so keep their wording. When the input is a goal with no conditions yet, call the Skill tool with "definition-of-done" on it first.

2. **Take the highest rung that covers each property.** Go down from `formal` and stop at the first rung whose check covers the property itself, not a neighboring property that is easier to check. A check that could be written counts; mark it `(to write)`. Skip a rung when its check would cost more than being wrong about the property. When the best check covers only part of the property, keep it and name the part it leaves out.

3. **Describe the check in this setting.** If you are in a project, look at what already runs there (a test runner, a type checker, a CI job) and name it. Describe the check as it would look once it exists. Keep each condition and add what the check needs: for `Held when`, when it is checked; for a `Metric`, how the value is measured and its current value. When the current value isn't known from the context, write `unknown` rather than measuring it. Make whatever does the checking the subject of the sentence: a test, a script, an LLM, a named person. Never address the reader. A check done by hand then reads as what that person compares and what result passes, not as steps to follow. Leave out how to build or set it up. The reader decides that. Choose the check's own settings, such as how often it runs or how many runs it takes. They are the check's choice, not gaps in the input, so they carry no `(guessed)`.

4. **Ground the weak rungs.** When a property lands on `judge` or `intrinsic`, add one check from a higher rung that covers some of it, if one exists. In the paper's evidence, one external check was enough to turn repeated self-review from rephrasing into improvement.

Watch for two traps while choosing. They decide which check you pick, and they stay out of the output.

- Tests written after the work, by whoever did the work, tend to confirm what it does rather than what it should do. Specify tests from the goal, not from the finished work.
- A judge given a vague question scores its own taste. Break a `judge` check into a few yes/no questions that can be answered from the output.

## What to produce

One entry per property, its check in the shape of its conditions, as plain text, not in a code block:

```
<property>  [<form>] Done when: <condition>; <condition>. <what a pass proves, one clause>
<property>  [<form>] Held when: <condition>; <condition>, checked <when>. <what a pass proves, one clause>
<property>  [<form>] Metric: <what is measured, and how>, now <current value>, target <target>. <what a pass proves, one clause>
            ground with: [<form>] <check, in the same shape>
```

The label names the form the check takes, in a few plain words a reader gets at a glance, such as `[proof]`, `[test]`, `[CI check]`, `[script]`, `[LLM review]`, `[self-review]` or `[human decision]`. The rung picked the check, and it stays out of the output.

A check that doesn't exist yet carries `(to write)` right after its label: `[<form>] (to write) Done when: ...`.

Say what a pass proves, not why the rung was picked. That is where a check that misses part of its property shows. The `ground with` line appears only under `judge` and `intrinsic`. A `human` entry reads `Done when: <who> decides or approves <what>`. When an automated proxy exists, add it on a `proxy:` line.

Stop after the last entry, with no preamble, advice paragraphs, fallback plans or advice on which check to start with. Don't write the check, run it, or explain the hierarchy. Another skill may read the output as it is, so keep this shape even when talking to a person.

## When it doesn't fit

If the input names no outcome at all, so there is nothing whose success could be checked, say so in one line and stop.
