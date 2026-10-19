---
name: as-approach
description: Formalize a given way to reach one or more efforts as an approach, giving its slug, its lead line (the way itself), its steps, what it assumes, which of each effort's criteria it covers and which criteria or limits it risks, and write it as `<slug>-approach.md` when a file is wanted. Use when a given approach needs to be formalized properly or written as a file - the user or another skill hands over a way and asks to phrase, name, write down or file it - when someone wants an approach's slug or steps, or asks what a proposed way assumes, covers or risks.
---

# As approach

An approach is one way to reach one or more efforts, named by how it gets there. It has no kind and no purpose: it serves its efforts' intents. This skill formalizes the way it is given and never changes it: adding actions to make the way cover more is proposing another way, which is propose-effort-approach's job. It need not reach a whole effort: it covers some of its criteria, and a criterion it leaves out is a gap of the effort, for another approach or a child effort, not a defect of the way.

Reasons, feasibility, cost and status stay out of it, since they go stale or belong to one effort's decision. They live in the effort files and the caller's logbook, which also takes what was read, tried or found while working the way out.

## What to work out

The approach's slug, the efforts it serves (`contributes-to`), its lead line, and its steps, assumptions, covers and risks, the last two per effort. Covers always has an entry per effort; the other parts may be empty. Work them out with the steps below, then decide what to give back (see Output).

## Steps

1. **Read the efforts.** `contributes-to` lists every effort the way serves, named or not. Look for each effort's file before anything else, by running `find . -name '*-effort.md'` from the project's root: a named effort usually has one, and only a search that came back empty means it has none. Check each effort file it finds: a way reaching another effort's criteria serves it too, and what it risks there counts against it. From that file, or the conversation when there is none, take the end state, the Criteria entry names and the Limits slugs. Covers and risks name only those names and slugs.

   An effort is framed when it has an as-effort line (`[<kind>] <slug> : <Verb> <end state>, so that <purpose>.`), its limits if any, and criteria named by slug. When no file exists and the effort is not framed, load the as-effort skill with the Skill tool, leaving its arguments empty, and apply its steps yourself to the effort. When it has no named criteria, apply as-effort that way and then definition-of-done the same way before writing any cover or risk, and never skip them or guess the criteria yourself. A skill called with a request answers it and ends the run there. Covers and risks name a criterion by its slug, and without those names they turn into prose nobody can check. Write no effort file.

2. **Check the way reaches something.** Take the way exactly as it was given, before writing anything, and name the criteria of each effort it works toward. When it works toward none of an effort's criteria, say so and stop for that effort: it is not an approach of that effort, or not an approach at all. Read the request as the way it states, not as a purpose it might have served: a way that needs new actions to reach a criterion is another way, for whoever gave it to propose.

3. **Write the lead line.** One sentence, starting with an action verb, going from where things start to what the way reaches. None of the verbs that name states: Achieve, Establish, Reach, Have, Make, Maintain, Keep, Preserve, Avoid, Prevent, Maximize, Minimize, Increase, Reduce. No reason: leave out `because`, `so that`, `since` and `in order to`. The slug is the way in kebab-case, unique among approach and effort slugs. Check the line:
   - **A way, not a state.** If the way changed, the slug would change. A line that would survive names an effort.
   - **More than a rewording** of the end state, and more than one step someone could tick off.
   - **Within the limits.** A way that may break a limit risks it; one sure to break it is no approach.

4. **Write the steps.** Actions at the level of the way, not a work plan, each one part of the given way or plainly implied by it; never one added so that the way covers a criterion. A numbered list runs in sequence, a bullet list in any order, and nesting groups them. Write no `(<effort-slug>, ...)` after a step: refined-approach-efforts adds it when it files child efforts covering that step. Leave the steps out when the lead line says them all.

5. **Ground the rest in the project.** The assumptions, covers and risks below rest on what the project shows about where the way would run: its files and records, and the checks and measuring tools it has. A risk those facts rule out is no risk; an assumption they bear on stays, for the decider to check against them.

6. **Write the assumptions.** What the way takes for granted, each with its own slug, as what will or will not be true, so someone could find it false by looking. *Should*, *may*, *might*, *could* and *probably* hide whether it holds. Add ` Breaks when: <signal>.` when a signal would show it failing early. Keep only those whose failure would change the choice, including one a competing approach relies on too: the decider sorts out what separates them. Never restate a criterion or a limit. Three tests tell an assumption from a criterion:
   - **Origin.** The effort's owner required the criterion of every way. The way's author took the assumption for granted.
   - **Failure.** An assumption can turn out false, which reopens the choice. A criterion can only be unmet.
   - **Consequence.** What the way may cost goes in risks. What it needs to be true goes in assumptions.

7. **Write the covers.** Under `### <effort-slug>`, one per effort in `contributes-to`, list the Criteria entries the way is meant to meet, one per line: `- <criterion name>`, optionally followed by ` : <how the way covers it>.` Leave out a criterion the way does not work toward: it stays for another approach or a child effort, and a decider combines approaches by what each covers, so a padded list hides that gap. Do not stretch a criterion to fit the way.

8. **Write the risks.** Under `### <effort-slug>`, per effort, list the covered criteria it may still leave unmet and the limits it may break, even when every assumption holds, one per line: `- <criterion name or limit slug>`, optionally followed by ` : <how the way risks it>.` What fails only when an assumption fails is not risked. A covered criterion not risked is claimed met, so leave none out to flatter the way.

## Example

The effort `meeting-date-agreed` has the criteria `date-accepted-by-all` and `date-fixed-before-deadline`, and the limit `members-free-to-decline`. The same way also serves `members-attend`, a criterion of `group-keeps-meeting`:

```
---
name: poll-on-three-dates
contributes-to:
  - meeting-date-agreed
  - group-keeps-meeting
---

Poll every member on three proposed dates and fix the one all can attend.

## Steps

1. Propose three dates to every member.
2. In any order:
   - Collect answers for three days.
   - Hold a room for each date.
3. Fix the date all can attend and announce it.

## Assumptions

- every-member-answers : Every member will answer within three days. Breaks when: fewer than half have answered after two days.
- one-date-suits-all : One of the three dates will suit everyone.

## Covers

### meeting-date-agreed

- date-accepted-by-all
- date-fixed-before-deadline

### group-keeps-meeting

- members-attend : Only a date all can attend is fixed.
```

It risks nothing: a late answer could miss the deadline, but only if `every-member-answers` fails. The competing `organizer-fixes-then-hears-objections` presses members to accept a date, so it lists `members-free-to-decline` under `### meeting-date-agreed`.

## Output

Once the approach is worked out, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| approach | a person wants the approach formalized or stated, with no file asked for | `references/approach.md` |
| file | the user asks for a file, or to write the approach down, file or record it | `references/approach-file.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, a table) | `references/fields.md` |
| carried | another skill's steps called this one, for the approach or its file, or brought you to `approach-file.md` | `references/carried.md` |

## When it doesn't fit

Input naming a state is an effort or a criterion, not an approach, and a way sure to break a limit is no approach. Say which in one line and stop.
