---
name: definition-of-done
description: Say what counts as done for a task, goal or effort. Gives the few properties that decide success, each with the conditions that mark it reached, held, or good enough, without saying how to check them. Use when the user asks what should count as done, what success looks like, what the acceptance or exit criteria are, how they would know a goal is met, or wants a definition of done, and whenever another skill needs the success conditions of a goal.
---

# Definition of done

A definition of done names the conditions that are true once a goal is met. It says what someone would find, not how they would look. These conditions are the end state, which people keep aiming at when the plan changes (ADP 6-0, 2026).

This skill decides what counts as done. It does not pick, write or run the checks that confirm it.

## Steps

1. **Name the properties that decide success.** Ask what would have to be true for the work to count, and keep only the properties where being wrong would matter. Most goals have one to three. Keep two properties apart when one could fail without the other, or when one is a matter of fact and the other a matter of judgment. Keep to the finished state: states that only matter on the way there belong to the plan, not to the definition of done.

2. **State each property as an effort.** Call the Skill tool with "as-effort" and work out each property's default one-line form. The effort's slug becomes the property's name, and its end state is what the conditions describe. The effort lines stay out of the output, even though as-effort asks for them first. They shape the conditions, and the reader only needs the conditions. The kind sets their shape in step 3.

3. **Write the conditions in the shape of the kind.**

   | kind | the conditions |
   |---|---|
   | `achieve` | Done when: each condition that marks the state reached |
   | `maintain` | Held when: each condition that marks the state held |
   | `optimize` | Metric: what is measured, and the target |

   Write each condition so that someone could find it true or false by looking: name what they would look at and what they would find. Words like *works*, *clean* or *fast* hide the condition instead of naming it. Leave out who or what does the looking, and how. When the input gives no target for a metric or threshold for a condition, infer the likeliest one and mark it `(guessed)`. How many samples or runs a check takes belongs to the check, not here. When the property is a judgment of what is better or worth doing, such as taste, direction or priority, the condition is a decision: `Done when: <who> decides or approves <what>`.

## What to produce

One entry per property:

```
<property>  Done when: <condition>; <condition>.
<property>  Held when: <condition>; <condition>.
<property>  Metric: <what is measured>, target <target>.
```

Stop after the last entry, with no preamble or advice. Another skill may read the output as it is, so keep this shape even when talking to a person.

## When it doesn't fit

If the input names no outcome at all, so there is nothing whose success could be defined, say so in one line and stop.
