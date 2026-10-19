---
name: definition-of-done
description: Say what counts as done for a task, goal or effort. Gives the properties that decide success, each with the conditions that mark it reached or held, or the value to push and its direction, without saying how to check them. Use when the user asks what should count as done, what success looks like, what the acceptance or exit criteria are, how they would know a goal is met, or wants a definition of done, and whenever another skill needs the success conditions of a goal.
---

# Definition of done

A definition of done names the conditions that are true once a goal is met. It says what someone would find, not how they would look. These conditions are the end state, which people keep aiming at when the plan changes (ADP 6-0, 2026).

This skill decides what counts as done. It does not pick, write or run the checks that confirm it.

## Steps

1. **Name the properties that decide success.** Ask what would have to be true for the work to count, and keep only the properties where being wrong would matter. Keep two properties apart when one could fail without the other, or when one is a matter of fact and the other a matter of judgment. Keep to the finished state: states that only matter on the way there belong to the plan, not to the definition of done.

2. **State each property as an effort.** Load the as-effort skill with the Skill tool, leaving its arguments empty, and apply its steps yourself to each property, for its slug, kind and end state. A skill called with a request answers it and ends the run there. The effort's slug becomes the property's name, and its end state is what the conditions describe. The efforts stay out of the output: they shape the conditions, and the reader only needs the conditions. The kind sets their shape in step 3.

3. **Write the conditions in the shape of the kind.**

   | kind | the conditions |
   |---|---|
   | `achieve` | Done when: each condition that marks the state reached |
   | `maintain` | Held when: each condition that marks the state held |
   | `optimize` | Metric: what is measured and over what period, which way is better, and the ideal when there is one |

   Write each condition so that someone could find it true or false by looking: name what they would look at and what they would find. Words like *works*, *clean* or *fast* hide the condition instead of naming it. Leave out who or what does the looking, and how. When the input gives no threshold for a `Done when` or `Held when` condition, infer the likeliest one and mark it `(guessed)`. A metric has no target: no level marks an optimize property done, and a guessed one would mark it done at a point nobody chose. The period the value is counted over, such as the weeks around a change or each week from now on, is what keeps a low value low rather than low for a day. Its ideal, such as none or all, is where the direction ends, not a level to reach; give it only when the input implies one. When the input wants as little or as much as possible and names an ideal (*ideally no one has to...*), the property is that metric with that ideal, never a condition demanding the ideal. A level the value must stay within is a threshold, so write it as `Held when`. How many samples or runs a check takes belongs to the check, not here. When the property is a judgment of what is better or worth doing, such as taste, direction or priority, the condition is a decision: `Done when: <who> decides or approves <what>`.

## Output

Once the properties and their conditions are worked out, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| entries | a person wants the definition of done stated | `references/entries.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one | `references/carried.md` |

## When it doesn't fit

If the input names no outcome at all, so there is nothing whose success could be defined, say so in one line and stop.
