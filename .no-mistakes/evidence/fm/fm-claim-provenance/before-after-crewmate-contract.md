# Before / after: what a crewmate actually receives

Both files below are real output of the real scripts, generated into a throwaway
FM_HOME. The "before" copy is the base commit a56a78a extracted with git archive;
the "after" copy is this branch (b3845ae).

## 1. Generated ship brief (bin/fm-brief.sh <id> rehoboam --mode no-mistakes)

BEFORE - the brief has no project-instructions section at all:
```
3:# Task
6:# Herdr lifecycle declaration - NOT ENABLED
11:# Setup
21:# Rules
47:# Firstmate instruction inbox
52:# Project memory
59:# Definition of done
```

AFTER - the brief now carries it, between the instruction inbox and project memory:
```
3:# Task
6:# Herdr lifecycle declaration - NOT ENABLED
11:# Setup
21:# Rules
47:# Firstmate instruction inbox
52:# Project instructions
57:# Project memory
64:# Definition of done
```

The section as the crewmate reads it:
```
# Project instructions
If the project carries its own `AGENTS.md` or `CLAUDE.md`, read it before you edit any file and follow it for this task, including any issue, branch, evidence, and review requirements it states.
Where it conflicts with the task instructions firstmate gave you, append `needs-decision: {the conflict}` and stop as rule 6 requires, rather than choosing between them yourself.
If firstmate named an issue for this task, make sure any pull request this task produces links that issue before you report that pull request done.
```

## 2. Promoted scout (bin/fm-promote.sh <id> --mode no-mistakes --yolo off)

This is the payload fm-send.sh delivers into the running crewmate window.

BEFORE - a scout promoted in place was never told to read the project's own instructions:
```
matches for "Project instructions": 0
```

AFTER:
```
# Project instructions
If the project carries its own `AGENTS.md` or `CLAUDE.md`, read it before you edit any file and follow it for this task, including any issue, branch, evidence, and review requirements it states.
Where it conflicts with the task instructions firstmate gave you, append `needs-decision: {the conflict}` and stop as rule 6 requires, rather than choosing between them yourself.
If firstmate named an issue for this task, make sure any pull request this task produces links that issue before you report that pull request done.
```

Byte-identical to the briefed worker's copy (single owner, bin/fm-dod-lib.sh):
```
$ cmp blk-brief.txt blk-promoted.txt && echo IDENTICAL
IDENTICAL
```

## 3. The `rule 6` the block points at is the real stop-and-wait rule in the same brief

```
6. If a decision belongs above the implementation worker (product choices, destructive actions, ask-user findings),
   append `needs-decision: {summary of options}` and stop. Firstmate will reply with the decision.
   A decision or blocker you opened stays open until a `resolved` line carrying its exact key lands; a later `done:` or `working:` line never closes it, even when the answer is what started that work.
   Firstmate's reply normally writes that closing line at answer time; when a blocker or wait clears WITHOUT a firstmate reply, append `resolved: {how it cleared}` yourself (same `[key=<slug>]` if you opened it with one) as you resume.
```

## 4. Rendered in every ship mode, and correctly absent from a scout brief

```
no-mistakes  -> 4 block line(s)
direct-PR    -> 4 block line(s)
local-only   -> 4 block line(s)
scout        -> 0 block line(s)  (a scout writes a report, it does not edit files)
```

## 5. Whole-brief diff, base vs branch

Path noise aside (the two homes differ), the ONLY change to the generated brief
is the new block. The crewmate status protocol is untouched, which is the
deliberate omission the intent calls out: crewmates were not given a matching
"state your basis" line.

```diff
--- /tmp/fm-evidence.i6Uep6/before-brief.md	2026-08-31 11:43:58
+++ /tmp/fm-evidence.i6Uep6/after-brief.md	2026-08-31 11:43:32
@@ -23,7 +23,7 @@
 2. Stay inside this worktree; modify nothing outside it.
 3. Use gh-axi for GitHub operations and chrome-devtools-axi for browser operations.
 4. Report status by appending one line:
    States: working, needs-decision, blocked, paused, done, failed.
    Each append wakes firstmate, so report sparingly: only phase changes a supervisor
    would act on (setup done, bug reproduced, fix implemented, validation passed) and the
@@ -45,15 +45,20 @@
    daemon error, append `blocked: {the daemon error}` and stop; only firstmate manages the daemon.
 
 # Firstmate instruction inbox
 The move IS the acknowledgement: without it firstmate rings again and eventually treats you as stuck. An empty or absent inbox needs no action.
 
+# Project instructions
+If the project carries its own `AGENTS.md` or `CLAUDE.md`, read it before you edit any file and follow it for this task, including any issue, branch, evidence, and review requirements it states.
+Where it conflicts with the task instructions firstmate gave you, append `needs-decision: {the conflict}` and stop as rule 6 requires, rather than choosing between them yourself.
+If firstmate named an issue for this task, make sure any pull request this task produces links that issue before you report that pull request done.
+
 # Project memory
 Record only project knowledge useful to almost every future session.
 For anything the codebase already shows, prefer a pointer to the authoritative file, command, or doc over copying the detail.
 Keep it proportionate: skip `AGENTS.md` edits for trivial tasks that produced no durable project knowledge.
 
 # Definition of done
```

## 6. Guard falsification - each new assertion was seen to go red

```
$ perl -0pi -e 's/^\$PROJECT_INSTRUCTIONS\n\n//m' bin/fm-brief.sh && bash tests/fm-brief.test.sh
not ok - ship brief must instruct the crewmate to read and follow the project's own instructions

$ perl -0pi -e 's/^  fm_project_instructions_block\n  echo\n//m' bin/fm-promote.sh && bash tests/fm-task-delivery.test.sh
not ok - no-mistakes: promoted worker was not told to read the project's own agent instructions

$ # promote renders its own divergent copy instead of the shared owner
not ok - no-mistakes: promotion and ordinary brief generation delivered different project instructions

$ # promote keeps the same first 3 lines but appends a 4th (the length-cap case the
$ # round-3 auto-fix closed by terminating the awk window on the blank line)
not ok - no-mistakes: promotion and ordinary brief generation delivered different project instructions
```

All four edits were reverted; `git status --porcelain` is empty.
