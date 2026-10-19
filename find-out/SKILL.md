---
name: find-out
description: Find out what the work depends on by climbing sources cheapest first, from what was already said and recorded up to the project, trying it and outside sources, and stopping at the first source that can settle the question. Tells apart what is (how things are or behave) from what is wanted (a goal, a threshold, a priority, a guess to confirm), which only stated intent or a person can settle. Returns the answer with its source, or the question to put to a person or a more capable model when nothing cheaper settles it. Use when a question comes up mid-task that the next step depends on, when an assumption, a requirement or something marked as guessed needs confirming, when deciding whether to ask the user or look it up, when investigating before acting, when the user asks to find out whether, why or how something is, and whenever another skill needs an answer gathered or a question escalated.
---

# Find out

Every source of an answer has a cost, and the costly ones, a person above all, are the only ones some questions need. So climb from the cheapest source and stop at the first one that can settle the question. Going higher is escalation.

What a source can settle depends on the kind of question:

- **What is.** How the project, the code, the data or the world are, or how something behaves.
- **What is wanted.** A goal, a threshold, a priority, a trade-off, or a guess someone made about any of them. Only someone who wants it can say, so only their stated intent or the person settles it. What exists shows what someone built, never what they meant.

## The rungs, cheapest first

| rung | what belongs here | settles | how it fails |
|---|---|---|---|
| `told` | the request and the conversation so far | what is wanted, when its owner said it; what is, when they stated it | a passing remark taken as a decision |
| `records` | logs of the work, notes, issue and review threads, commit messages | what was found, tried or decided before | old by now; records a decision, not the current state |
| `stated intent` | goal and requirement files, specs, tickets, decision records, a README's goals | what is wanted, what was decided | silent on the question, marked as a guess, or drifted from what is wanted now |
| `project` | code, data, configuration, version history | what is | shows what was built, never what was meant |
| `trying` | running it, a test, a throwaway prototype | how it behaves | covers only the cases tried |
| `outside` | documentation, the web | how the world works | outdated, or about another version or setting |
| `stronger model` | a more capable model, given the question and what was found | hard questions of what is, judgment calls | shares the blind spots of models, and cannot say what anyone wants |
| `person` | whoever owns the intent behind the question | anything, what is wanted above all | slow, costly, possibly unavailable |

## Steps

1. **Sharpen the question.** Say what answer would let the work go on: a fact, a value, a choice between named options. Give it its kind. A question holding both kinds is two questions, since each climbs on its own.

2. **Climb.** Go up from `told`, naming each rung as it exists here: which log, which spec, which file, which command. Skip a rung that cannot settle the question's kind, but read it on the way when it is cheap, since a lead there tells you where to look higher up. Stop at the first rung that settles the question. Climb no further than the question is worth: when being wrong would cost less than the next rung, keep the best answer so far as unconfirmed. When the work keeps a log, log what each rung gave, dead ends included, so nobody climbs the same rungs again.

3. **Try only what can be undone.** A try that writes outside a scratch area, sends anything, spends money or could break a limit of the work is not a try. Put it to a person as a question.

4. **Stop below `stronger model` and `person`.** Starting another model or interrupting a person is the caller's call, so reaching either rung ends the climb: write the question so it stands on its own, with the options when there are any, and with what the lower rungs gave.

Watch for three traps while climbing. They decide which answer you keep, and they stay out of the output.

- **Your own knowledge is not a rung.** It says nothing about this project or what anyone wants. On how the world works it is a lead, confirmed on a cheap rung when being wrong would matter.
- **Intent read from what exists.** "The code does this, so this is wanted" answers a question of what is wanted from the `project` rung, which cannot settle it. It is how guesses get confirmed without anyone confirming them.
- **A guess is not stated intent.** A statement marked guessed, assumed, to be decided or similar is a lead, whatever file it sits in.

## Output

Once the climb ends, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| entries | a person wants the answers, or the questions to ask, stated | `references/entries.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one | `references/carried.md` |

Whatever the mode, each question takes one verdict: `answered`, `unconfirmed` (the best answer so far, not settled), or `ask` (the question for a person or a stronger model, with what the lower rungs found). Only the split from step 1 makes two of one question.

## When it doesn't fit

When the input holds no question, nothing the work depends on and nothing to find out, say so in one line and stop.
