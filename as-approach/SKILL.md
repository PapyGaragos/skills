---
name: as-approach
description: Formalize a given way to reach one or more efforts as an approach, giving its slug, its lead line (the way itself), its steps, what it assumes, which of each effort's criteria it covers and which criteria or limits it risks, and write it as `<slug>-approach.md` when a file is wanted. Use when a given approach needs to be formalized properly or written as a file - the user or another skill hands over a way and asks to phrase, name, write down or file it - when someone wants an approach's slug or steps, or asks what a proposed way assumes, covers or risks.
---

# As approach

An approach is one way to reach one or more efforts, named by how it gets there. It has no kind and no purpose: it serves its efforts' intents. This skill formalizes the way it is given and never changes it: adding actions to make the way cover more is proposing another way, which is propose-effort-approach's job. It need not reach a whole effort: it covers some of its criteria, and a criterion it leaves out is a gap of the effort, for another approach or a child effort, not a defect of the way.

Reasons, feasibility, cost and status stay out of it, since they go stale or belong to one effort's decision. They live in the effort files and the caller's logbook, which also takes what was read, tried or found while working the way out.

## What to produce

The approach in its file's layout, as in the example, shown to the caller: frontmatter with `name` and `contributes-to`, the lead line, then `## Steps`, `## Assumptions`, `## Covers` and `## Risks` (a `### <effort-slug>` heading per effort). Covers is always there; leave out any other empty section. When a file is wanted, read `references/approach-file.md` and follow it.

## Steps

1. **Read the efforts.** `contributes-to` lists every effort the way serves. Look for each effort's file before anything else, by running `find . -name '*-effort.md'` from the project's root: a named effort usually has one, and only a search that came back empty means it has none. From that file, or the conversation when there is none, take the end state, the Definition of done entry names and the Limits slugs. Covers and risks name only those names and slugs.

   An effort is framed when it has an as-effort line (`[<kind>] <slug> : <Verb> <end state>, so that <purpose>.`), its limits if any, and criteria named by slug. When no file exists and the effort is not framed, call the Skill tool with "as-effort". When it has no named criteria, call it with "as-effort" and then with "definition-of-done" before writing any cover or risk, and never skip them or guess the criteria yourself: covers and risks name a criterion by its slug, and without those names they turn into prose nobody can check. Write no effort file.

2. **Check the way reaches something.** Take the way exactly as it was given, before writing anything, and name the criteria of each effort it works toward. When it works toward none of an effort's criteria, say so and stop for that effort: it is not an approach of that effort, or not an approach at all. Read the request as the way it states, not as a purpose it might have served: a way that needs new actions to reach a criterion is another way, for whoever gave it to propose.

3. **Write the lead line.** One sentence, starting with an action verb, going from where things start to what the way reaches. None of the verbs that name states: Achieve, Establish, Reach, Have, Make, Maintain, Keep, Preserve, Avoid, Prevent, Maximize, Minimize, Increase, Reduce. No reason: leave out `because`, `so that`, `since` and `in order to`. The slug is the way in kebab-case, unique among approach and effort slugs. Check the line:
   - **A way, not a state.** If the way changed, the slug would change. A line that would survive names an effort.
   - **More than a rewording** of the end state, and more than one step someone could tick off.
   - **Within the limits.** A way that may break a limit risks it; one sure to break it is no approach.

4. **Write the steps.** Actions at the level of the way, not a work plan, each one part of the given way or plainly implied by it; never one added so that the way covers a criterion. A numbered list runs in sequence, a bullet list in any order, and nesting groups them. Write no `(<effort-slug>, ...)` after a step: refined-approach-efforts adds it when it files child efforts covering that step. Leave the steps out when the lead line says them all.

5. **Write the assumptions.** What the way takes for granted, each with its own slug, as what will or will not be true, so someone could find it false by looking. *Should*, *may*, *might*, *could* and *probably* hide whether it holds. Add ` Breaks when: <signal>.` when a signal would show it failing early. Keep only those whose failure would change the choice, including one a competing approach relies on too: the decider sorts out what separates them. Never restate a criterion or a limit. Three tests tell an assumption from a criterion:
   - **Origin.** The effort's owner required the criterion of every way. The way's author took the assumption for granted.
   - **Failure.** An assumption can turn out false, which reopens the choice. A criterion can only be unmet.
   - **Consequence.** What the way may cost goes in risks. What it needs to be true goes in assumptions.

6. **Write the covers.** Under `### <effort-slug>`, one per effort in `contributes-to`, list the Definition of done entries the way is meant to meet, one per line: `- <criterion name>`, optionally followed by ` : <how the way covers it>.` Leave out a criterion the way does not work toward: it stays for another approach or a child effort, and a decider combines approaches by what each covers, so a padded list hides that gap. Do not stretch a criterion to fit the way.

7. **Write the risks.** Under `### <effort-slug>`, per effort, list the covered criteria it may still leave unmet and the limits it may break, even when every assumption holds, one per line: `- <criterion name or limit slug>`, optionally followed by ` : <how the way risks it>.` What fails only when an assumption fails is not risked. A covered criterion not risked is claimed met, so leave none out to flatter the way.

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

## When it doesn't fit

Input naming a state is an effort or a criterion, not an approach, and a way sure to break a limit is no approach. Say which in one line and stop.
