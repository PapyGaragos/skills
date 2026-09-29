# Skills

Agent skills for goal-directed work. They frame a goal as an effort, meaning the state someone wants to be true rather than the work to get there. An effort gets written down as a file with its checks, and the work toward it gets a log that someone else can resume.

Scripts in those skills are bash and use only `awk`, `sed`, `grep` and `find`.

## The skills

Four building blocks each produce one part of an effort:

- **as-effort** turns a goal, task or ticket into an effort: a slug, a kind (`achieve`, `maintain` or `optimize`) and a one-line intent, `<Verb> <end state>, so that <purpose>.`
- **definition-of-done** lists the few properties that decide whether a goal is met, each with the conditions that mark it, without saying how to check them.
- **reliable-checks** describes the most trustworthy check for each condition (formal, execution, judge, intrinsic or human) and what a pass does and doesn't prove. It describes the check without writing or running it.
- **key-tasks** names the intermediate states that every workable approach has to reach, without choosing an approach.

Two skills use them:

- **to-effort-file** calls the four building blocks and writes the result to `<slug>-effort.md`. It links the file to the parent efforts it serves and lints the file with its own scripts.
- **one-thing** asks "what's the one thing I can do at this horizon that makes everything else easier or unnecessary?" and answers with a single effort.

One skill stands apart:

- **logbook** keeps a `<effort-name>.logbook` file recording the steps, surprises, questions and decisions of multi-step work, written through `scripts/logbook.sh`.

## How they call each other

Skills call each other by name through the Skill tool, so install a skill together with everything it calls, under the same names.

```
to-effort-file ──> as-effort
               ──> definition-of-done ──> as-effort
               ──> reliable-checks    ──> definition-of-done  (only when given a goal with no conditions)
               ──> key-tasks          ──> as-effort

one-thing      ──> as-effort

logbook        (calls nothing)
```

**Each building block also works on its own.** Ask for a definition of done, or how to check a property, and you get only that part.

## A workflow

1. **File the top-level goals.** Talk through the project's goals with the agent, then run `/to-effort-file` on each one and say it serves no other effort. It becomes a root effort.

2. **File narrower efforts under them.** Run `/to-effort-file` on a smaller goal, sized for a session or a commit. It looks for `*-effort.md` files under the working directory, picks the ones this effort serves, and lists them in `contributes-to:`. It marks the parents it guessed with `# guessed`, so check those. The file's Serves section says how to check that the new effort moves each parent.

3. **Work on the effort.** Point the agent at the file and ask for a log, for example `work on @<slug>-effort.md, keep a logbook`. The effort file says what done means and what limits to respect, and leaves the approach to the agent. The logbook records what the agent tried and why, and the Work section at the end of the effort file collects what the work produced. Several agents can write to the same logbook.

4. **Resume.** After a reset or a handoff, `pick up the work from <effort-name>.logbook`. The agent starts from `logbook.sh status`, which shows the work in progress, the open questions and blockers, and the steps not started yet.

`one-thing` could pick the effort for step 2: give it the existing effort files and a horizon, then file its answer with `/to-effort-file`. It hasn't been tested with the current versions of the effort skills, so treat that step as a suggestion for now.

## License

MIT, see [LICENSE](LICENSE).
