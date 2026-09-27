- **as-effort**: Restates a goal or task as the end state it aims for, with a slug, a kind (achieve, maintain or optimize) and a one-line intent, so the work is judged by the state it reaches and not by the steps taken.
- **how-to-check**: Breaks a goal into the properties that decide success and picks a concrete check for each one (a test, an LLM review, a human decision...), so you know what "done" means before starting the work.
- **to-effort-file**: Writes an effort to <slug>-effort.md with its end state, its checks and its links to parent efforts, so there is one file to track the work in.
- **one-thing**: Answers "what should I do next?" with a single effort at a chosen horizon (now, this week, this milestone), so you stop weighing options and start on one.
- **logbook**: Records what was done, what came up and what was decided and why during multi-step work, so someone else can pick it up later and check past choices against the context they were made in.

Intended usage :
1. discuss your project's end goals with an agent, then record them each in a file with /to-effort-file
2. /one-thing -> /to-effort-file loop until you have a session-scoped or commit-scoped effort to work on. Make sure /one-thing is provided with all existing `*-effort.md` files
3. `work on @you-effort-file. keep a logbook` (or equivalent prompt) multi-agent collaboration on the same logbook is possible
4. `pickup the work from xxx.logbook` if the session was interrupted or reset
