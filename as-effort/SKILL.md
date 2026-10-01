---
name: as-effort
description: Reframe an objective, goal, task or piece of work as an effort, meaning the wanted state behind it rather than the work to reach it. Gives the effort's slug, its kind (achieve, maintain or optimize) and its one-line intent, `<Verb> <end state>, so that <purpose>.` Use when the user asks to phrase, name or reframe something as an effort, wants the intent line or `contributes-to:` slug for some work, wants an effort's fields in a given format (YAML, CSV, a table), asks what a task or ticket is really for, or hands over a goal and wants the state it aims at.
---

# As effort

An effort is a state someone wants to be true. It names what should be true, never the work to get there, so its name survives a change of approach. A finished piece of work names an effort as the reason it was done. Its intent line gives an end state and a purpose, which people steer by once the plan stops fitting (ADP 6-0, 2026). When a plan broke, people given an intent chose as its author would only about half the time (Shattuck, 2000).

## What to produce

Three small things:

- **Slug.** The wanted state in kebab-case. It names the state, not the work.
- **Kind.** `achieve` is reached once, then done. `maintain` is reached if it isn't true yet, then held for as long as it matters. `optimize` is pushed as far as it will go.
- **Intent.** One sentence, `<Verb> <end state>, so that <purpose>.` Its parts are fields too: the verb, the state, and the purpose. The purpose field is the text after `so that`, without those two words.

When the request doesn't say otherwise, give one line as plain text, not in a code block:

```
[<kind>] <slug> : <Verb> <end state>, so that <purpose>.
```

When the request names fields or a format (YAML, CSV, prose, a table), give only those fields, in that format. "The one-liner" means the intent alone, and "a name" means the slug alone.

Stop there. Don't explain the choices. Add one line only for a guess that `(guessed)` doesn't already mark. Writing the full effort file, its checks, or finding its parent efforts is a separate job.

When the request goes on to other work, such as a commit or a plan, give the effort line first anyway. That work names the effort by its slug as its reason. For the rest of the conversation, call the effort by its slug. Put the kind before it when that reads as a sentence: "this commit helps achieve `<slug>`". Don't restate the intent unless asked.

## Steps

1. **Find the wanted state.** When the input names work, ask what is true once the work is done. Then test the result: if a change of approach would force a new name, it still names work. A vendor, tool or library in the state usually names the approach. If the user named a tool as the way to reach the state, leave it out without comment, since they may switch tools later. Keep it when being on that tool is the state they want. Name the state concretely enough that someone could tell whether it holds. Words like *reliable*, *good* or *clean* hide the state instead of naming it. If two people could disagree about whether the state holds, it isn't concrete yet, so name what they would look at.

2. **Pick the kind.** Ask what happens after the state is first reached. If the job is over, it is `achieve`. If the state decays unless someone keeps working on it, it is `maintain`, whether or not it holds today. A state that could break but stays put once reached is still `achieve`. If there is a value with no finish line, it is `optimize`. A threshold to stay within, such as under a limit or above a floor, is a finish line, so holding it is `maintain`.

3. **Write the intent with a verb from the kind's list.**

   | kind | verbs |
   |---|---|
   | `achieve` | Achieve, Establish, Reach, Have, Make |
   | `maintain` | Maintain, Keep, Preserve, Avoid, Prevent |
   | `optimize` | Maximize, Minimize, Increase, Reduce |

   The list is closed so the intent can't name work. Keep also fits a state that isn't true yet. Write, Build, Migrate and Implement are on no list. The verb comes from the kind's own row; if the verb that fits sits in another row, the kind is wrong. Make takes a thing and the state it ends in, never a thing alone. Have takes a thing that exists, never an event marked done.

4. **Write the purpose.** The `so that` says how this state serves something larger. It does not restate the larger thing. Then imagine the likeliest way to reach the state stops working. The purpose should help someone choose between two other ways. If it doesn't, it is too vague to steer by, so name the larger outcome that depends on the state. A purpose that only says the state is useful (restorable, responsive, trusted) restates it. If the input gives no purpose, infer the likeliest one and mark it `(guessed)` so the user can correct it. The mark goes right after the purpose, before the final period: `so that <purpose> (guessed).`

One input sometimes holds two independent wanted states. Give two efforts rather than joining them under one sentence. Reaching a state and then holding it is one `maintain` effort, not two.

## When it doesn't fit

Some input is not a wanted state and has none behind it. Say so in one line with the reason, and stop. A forced effort is worse than none, because work records will name it as their reason and it will claim a purpose nobody had.
