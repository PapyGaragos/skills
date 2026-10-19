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

1. **Take the conditions as given.** The input may be a definition of done, a single condition, or a property. Its conditions are what a pass must show, so keep their wording. When the input is a goal with no conditions yet, load the definition-of-done skill with the Skill tool first, leaving its arguments empty, and apply its steps yourself to the goal. A skill called with a request answers it and ends the run there.

2. **Take the highest rung that covers each property.** Go down from `formal` and stop at the first rung whose check covers the property itself, not a neighboring property that is easier to check. A check that could be written counts; mark it `(to write)`. Skip a rung when its check would cost more than being wrong about the property. When the best check covers only part of the property, keep it and name the part it leaves out.

3. **Describe the check in this setting.** If you are in a project, look at what already runs there (a test runner, a type checker, a CI job) and name it. Describe the check as it would look once it exists. Keep each condition and add what the check needs: for `Held when`, when it is checked; for a `Metric`, how the value is measured and its current value. When the current value isn't known from the context, write `unknown` rather than measuring it. Make whatever does the checking the subject of the sentence: a test, a script, an LLM, a named person. Never address the reader. A check done by hand then reads as what that person compares and what result passes, not as steps to follow. Leave out how to build or set it up. The reader decides that. Choose the check's own settings, such as how often it runs or how many runs it takes. They are the check's choice, not gaps in the input, so they carry no `(guessed)`.

4. **Ground the weak rungs.** When a property lands on `judge` or `intrinsic`, add one check from a higher rung that covers some of it, if one exists. In the paper's evidence, one external check was enough to turn repeated self-review from rephrasing into improvement.

Watch for two traps while choosing. They decide which check you pick, and they stay out of the output.

- Tests written after the work, by whoever did the work, tend to confirm what it does rather than what it should do. Specify tests from the goal, not from the finished work.
- A judge given a vague question scores its own taste. Break a `judge` check into a few yes/no questions that can be answered from the output.

## Output

Once each property has its check, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| entries | a person wants the checks stated | `references/entries.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one | `references/carried.md` |

## When it doesn't fit

If the input names no outcome at all, so there is nothing whose success could be checked, say so in one line and stop.
