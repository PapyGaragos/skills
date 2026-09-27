---
name: how-to-check
description: Infer the best way to verify a task, goal or effort, without building or running the check. Splits the goal into the properties that decide success, sharpens each one by stating it as an effort, and gives each a rung of the verification hierarchy (formal, execution, judge, intrinsic, or human) and the concrete check at that rung. Use when the user asks how to verify, test, check or validate some work, how they would know it is done or that it worked, what should count as done, or what a good check for a goal would be, and whenever another skill asks for a verification method.
---

# How to check

A check is only as good as the signal behind it. The verification hierarchy (Chen, Wang and Qu, 2026) ranks signals by how far they can be trusted. The signals that can be trusted most cover the fewest tasks, so the useful question for a given goal is how high its check can go.

This skill picks the check. It does not write or run it.

## The rungs, most trusted first

| rung | what belongs here | how it fails |
|---|---|---|
| `formal` | proof checkers, type systems, model checkers, schemas enforced by a tool | never accepts a false pass, but covers only what can be stated formally |
| `execution` | tests, compilers, linters, benchmarks, running the thing and comparing with a known answer, a mechanical lookup against a source | passing can hide wrong behavior the checks don't exercise; a fixed benchmark gets gamed over time |
| `judge` | an LLM or reward model scoring the output, a rubric scored by an LLM | only as good as the judge, has its biases (length, position, its own style), and gets optimized against |
| `intrinsic` | self-review, confidence, self-consistency across attempts | cheapest and least trustworthy, because the checker shares the blind spots of whoever did the work |

Above them sits `human`: a person decides. It is the only option when the property is itself a judgment of what is better or worth doing, such as taste, direction or priority.

## Steps

1. **Name the properties that decide success.** Ask what would have to be true for the work to count, and keep only the properties where being wrong would matter. Most goals have one to three. A goal with a checkable part and an uncheckable part gets two properties, never one averaged answer.

2. **State each property as an effort.** Call the Skill tool with "as-effort" and work out each property's default one-line form. The effort's slug becomes the property's name, and its end state is what the check must show. The effort lines stay out of the output, even though as-effort asks for them first. They shape the checks, and the reader only needs the checks. The kind sets the shape of the check in step 4.

3. **Take the highest rung that covers each property.** Go down from `formal` and stop at the first rung whose check covers the property itself, not a neighboring property that is easier to check. A check that could be written counts; mark it `(to write)`. Skip a rung when its check would cost more than being wrong about the property. When the best check covers only part of the property, keep it and name the part it leaves out.

4. **Describe the check in this setting.** If you are in a project, look at what already runs there (a test runner, a type checker, a CI job) and name it. Describe the check as it would look once it exists, in the shape its property's kind calls for:

   | kind | the check |
   |---|---|
   | `achieve` | Done when: each condition that marks the state reached |
   | `maintain` | Held when: each condition that marks the state held, and when it is checked |
   | `optimize` | Metric: what is measured and how, the current value, and the target |

   The conditions, or the target, are what counts as a pass. When the current value of a metric isn't known from the context, write `unknown` rather than measuring it. Make whatever does the checking the subject of the sentence: a test, a script, an LLM, a named person. Never address the reader. A check done by hand then reads as what that person compares and what result passes, not as steps to follow. Leave out how to build or set it up. The reader decides that.

5. **Ground the weak rungs.** When a property lands on `judge` or `intrinsic`, add one check from a higher rung that covers some of it, if one exists. In the paper's evidence, one external check was enough to turn repeated self-review from rephrasing into improvement.

Watch for two traps while choosing. They decide which check you pick, and they stay out of the output.

- Tests written after the work, by whoever did the work, tend to confirm what it does rather than what it should do. Specify tests from the goal, not from the finished work.
- A judge given a vague question scores its own taste. Break a `judge` check into a few yes/no questions that can be answered from the output.

## What to produce

One entry per property, its check in the shape of its kind:

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
