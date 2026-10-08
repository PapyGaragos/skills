# Approach file

This writes an approach down as `<slug>-approach.md`, from the content SKILL.md produced. It changes none of that content.

## Before writing

1. **Look for the file.** When `<slug>-approach.md` already exists, show it to the caller and ask before replacing it. Write nothing, there or anywhere else, until they answer.

2. **Check for a decision.** An approach some effort has chosen is what work is being done against, so changing it silently would leave that work aiming at a way nobody decided on. Read the Approaches section of each effort in `contributes-to`. When any lists the approach as `[chosen]`, its steps, assumptions, covers and risks change only through a logbook decision that names the change. Adding an effort to `contributes-to`, with that effort's own Covers and Risks headings, changes nothing for the efforts already there and needs no decision. The caller supplies it, as a logbook path and node. Without one, write nothing and say which decision is missing.

3. **A new lead line is a new approach.** It gets a new slug and its own file. The old file stays, since efforts and logbooks may still point at it.

## Writing

Pipe the content into `scripts/write-approach-file.sh`, in this skill's folder. It writes in the working directory, or in the folder passed as its argument: the one the caller names, else the folder of the first effort's file.

```
scripts/write-approach-file.sh <<'EOF'
name: <slug>
effort: <one line per effort in contributes-to>
way: <the lead line>
step: <one line per Steps line, as it reads in the file, its indentation after "step: ">
assumption: <slug> : <what will or will not be true>. Breaks when: <signal>.
cover: <effort slug> <criterion name> : <how the way covers it>.
risk: <effort slug> <criterion name or limit slug> : <how the way risks it>.
EOF
```

One `cover:` line per criterion covered, at least one per effort, and one `risk:` line per criterion or limit risked; the ` : <how ...>.` explanation is optional on both. Leave out the `step:`, `assumption:` or `risk:` lines a section doesn't have. A nested step keeps its indentation:

```
step: 2. In any order:
step:    - <step>
```

It writes the file only when `scripts/check-approach-file.sh` passes on it. Otherwise it prints the problems, each with its line, and writes nothing: fix the input and run the same command again until it exits 0. Exit 3 means the file exists; rerun with `--replace` only once the caller has agreed, and the decision in step 2 is in hand when one is needed. `--root DIR` names the folder the effort files are found under, by default the git toplevel of the folder written to, else that folder.

## Reply

The file's path, then any warning the last run printed, as it printed it.
