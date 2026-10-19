---
name: as-effort
description: Reframe an objective, goal, task or piece of work as an effort, meaning the wanted state behind it rather than the work to reach it. Gives the effort's slug, its kind (achieve, maintain or optimize) and its one-line intent, `<Verb> <end state>, so that <purpose>.` Use when the user asks to phrase, name or reframe something as an effort, wants the intent line or `contributes-to:` slug for some work, wants an effort's fields in a given format (YAML, CSV, a table), asks what a task or ticket is really for, or hands over a goal and wants the state it aims at. Also writes the effort down as a file, `<slug>-effort.md`, with its end state, definition of done, what serves its parent efforts and its limits: use when the user asks for an effort file, wants to write down, file or record an effort, or turns a goal, task or ticket into an effort to track work against.
---

# As effort

An effort is a state someone wants to be true. It names what should be true, never the work to get there, so its name survives a change of approach. A finished piece of work names an effort as the reason it was done. Its intent line gives an end state and a purpose, which people steer by once the plan stops fitting (ADP 6-0, 2026). When a plan broke, people given an intent chose as its author would only about half the time (Shattuck, 2000).

## What to work out

Three small things:

- **Slug.** The wanted state in kebab-case. It names the state, not the work.
- **Kind.** `achieve` is reached once, then done. `maintain` is reached if it isn't true yet, then held for as long as it matters. `optimize` is pushed as far as it will go.
- **Intent.** One sentence, `<Verb> <end state>, so that <purpose>.` Its parts are fields too: the verb, the state, and the purpose. The purpose field is the text after `so that`, without those two words.

Work them out with the steps below, then decide what to give back (see Output).

## Steps

1. **Find the wanted state.** When the input names work, ask what is true once the work is done. Then test the result: if a change of approach would force a new name, it still names work. A vendor, tool or library in the state usually names the approach. If the user named a tool as the way to reach the state, leave it out without comment, since they may switch tools later. Keep it when being on that tool is the state they want. Name the state concretely enough that someone could tell whether it holds. Words like *reliable*, *good* or *clean* hide the state instead of naming it. If two people could disagree about whether the state holds, it isn't concrete yet, so name what they would look at.

2. **Pick the kind.** First ask whether success is a level or only a direction. When only a direction counts, lower or higher, and no level was stated or is plainly implied, it is `optimize`, even when the value must stay low or high over time: the period the value is counted over carries that. Wording like *as little as possible* or *ideally none* names a direction and its ideal, not a level. Never invent a level to make it fit another kind. When there is a level, ask what happens after the state is first reached. If the job is over, it is `achieve`. If the state decays unless someone keeps working on it, it is `maintain`, whether or not it holds today. A state that could break but stays put once reached is still `achieve`. A threshold to stay within, such as under a limit or above a floor, is a level, so holding it is `maintain`. A direction with a level it must never cross is `optimize`, with that level as a limit.

3. **Write the intent with a verb from the kind's list.**

   | kind | verbs |
   |---|---|
   | `achieve` | Achieve, Establish, Reach, Have, Make |
   | `maintain` | Maintain, Keep, Preserve, Avoid, Prevent |
   | `optimize` | Maximize, Minimize, Increase, Reduce |

   The list is closed so the intent can't name work. Keep also fits a state that isn't true yet. Write, Build, Migrate and Implement are on no list. The verb comes from the kind's own row; if the verb that fits sits in another row, the kind is wrong. Make takes a thing and the state it ends in, never a thing alone. Have takes a thing that exists, never an event marked done.

4. **Write the purpose.** The `so that` says how this state serves something larger. It does not restate the larger thing. Then imagine the likeliest way to reach the state stops working. The purpose should help someone choose between two other ways. If it doesn't, it is too vague to steer by, so name the larger outcome that depends on the state. A purpose that only says the state is useful (restorable, responsive, trusted) restates it. If the input gives no purpose, infer the likeliest one and mark it `(guessed)` so the user can correct it. The mark goes right after the purpose, before the final period: `so that <purpose> (guessed).`

One input sometimes holds two independent wanted states. Give two efforts rather than joining them under one sentence. Reaching a state and then holding it is one `maintain` effort, not two.

## Output

Once the effort is worked out, decide whether anything goes back and in what form. When another skill's steps called this one, the mode is `carried`, whatever the call asks for, since its wording is the caller's and the result is theirs to use. Otherwise match the request against each mode below, read the reference of the one it fits, and follow it. Pick by what the request is for, not by what is quickest to give. The shape of the reply is in the reference and nowhere else, so read it before writing any reply, even a short answer to a person.

| mode | when | reference |
|---|---|---|
| line | a person wants the effort stated, to read or to name other work by, such as a commit or a plan the request goes on to | `references/line.md` |
| fields | the request names fields or a format (YAML, JSON, CSV, prose, a table), or asks for "the one-liner" or "a name" | `references/fields.md` |
| effort file | the user wants the effort written down, filed or recorded, or to track work against it | `references/effort-file.md` |
| carried | another skill's steps called this one, for the effort or its file | `references/carried.md` |

Once the effort is named, work that follows names it by its slug as its reason. For the rest of the conversation, call the effort by its slug. Put the kind before it when that reads as a sentence: "this commit helps achieve `<slug>`". Don't restate the intent unless asked.

## When it doesn't fit

Some input is not a wanted state and has none behind it. Say so in one line with the reason, and stop. A forced effort is worse than none, because work records will name it as their reason and it will claim a purpose nobody had.
