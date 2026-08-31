---
name: project-management
description: >-
  Agent-only procedure for Firstmate project management.
  Use before adding, creating, removing, or initializing a project, before dispatching into or promoting a scout inside a project that carries its own agent instructions, and before landing an approved local-only merge for a task that carries a named issue.
  Cloning or registering a project is add intake and uses the same trigger.
  Owns project add, create, clone, remove, initialization, registry, delivery-mode, autonomy, outward-consent, and dispatch-time project-instruction decisions.
user-invocable: false
metadata:
  internal: true
---

# project-management

Use this procedure before adding, creating, removing, or initializing a project, before dispatching into or promoting a scout inside a project that carries its own agent instructions, and before landing an approved local-only merge for a task that carries a named issue.
Cloning or registering a project is add intake and uses the same trigger.
This skill is the single owner of Firstmate's project-management procedure.
It does not replace `secondmate-provisioning`, which owns project clones inside persistent secondmate homes.

## Preconditions and registry

Projects live flat under `projects/`, and `data/projects.md` is the private fleet registry.
Use the registry format and parser contract owned by the header of `bin/fm-project-mode.sh`.
Keep each registry description useful for identifying the project, but keep delivery posture, captain-private state, and detailed project knowledge in their existing designated homes.
Do not turn the registry into project documentation.

Before adding, cloning, creating, or registering any project in the main home, inspect the authoritative `data/secondmates.md` routing table and judge every existing natural-language `scope:` against the proposed project or domain.
Apply `AGENTS.md` section 7's authoritative secondmate routing rules; if an existing scope owns that domain, route the new-project operation or work there instead of creating or registering a duplicate main-home clone.
Absence from the main `data/projects.md` registry is never evidence that no second mate owns the domain.
If the owning second mate cannot accept the route, report that concrete blocker or obtain an explicit captain redirection rather than silently duplicating the project in the main home.

Resolve the project name, destination, delivery posture, and autonomy posture before changing local or remote state.
Keep a newly added clone and its registry entry consistent, and roll back only artifacts created by the incomplete operation when a later initialization step fails and that rollback is safe.
Do not overwrite or repurpose an existing path.

## Delivery posture

The registry records the project's standing posture, which is the captain's default for the work rather than any task's answer; `AGENTS.md` section 7 owns how each task's concrete mode and yolo are resolved at intake and passed explicitly to the brief, the spawn, and any promotion.
Choose that posture when adding or creating the project:

- `no-mistakes` runs the full validation pipeline before a PR.
- `direct-PR` pushes and opens a PR without the no-mistakes pipeline.
- `local-only` has no required remote or PR and lands only through the approved local fast-forward path.
- `no-mistakes-prod-only` is a conditional policy rather than one flat mode: genuinely internal-only tooling, automation, contributor or operator process, and release or submission work ships `direct-PR`, while product-facing, mixed, and uncertain work ships `no-mistakes`.

`no-mistakes-prod-only` is the default for a newly added or created remote-backed project when the captain specifies nothing, and a project with no remote defaults to `local-only`.
State that resolved default while confirming the source, local name, and posture instead of asking the captain to choose from scratch, and record a flat mode instead whenever they ask for one.
Existing registry entries keep the meaning they already have and are never migrated or reinterpreted, so a legacy entry with no bracket stays `no-mistakes`.
Registering a conditional policy is a one-time choice and never requires classifying any change; the per-task surface classification happens at each task's intake, and internal-only is never inferred from file location or project name.

The optional `+yolo` posture changes merge authority only and does not change the delivery mode.
Default it off for every project and every posture, and enable it only on the captain's explicit instruction.
`AGENTS.md` section 7 owns the merge-authority contract.

## Add or clone an existing project

Confirm the source URL, local project name, delivery posture, and autonomy posture, stating the resolved default for each rather than asking the captain to invent one.
Clone into `projects/<name>` and add the registry entry only after the destination is known to be unused.
A `no-mistakes` or `no-mistakes-prod-only` project must have an `origin` remote and must complete the initialization procedure below, because a conditional policy's product-facing work runs the pipeline while its internal-only work still takes the direct PR.
A `direct-PR` project needs an `origin` remote but skips no-mistakes initialization.
A `local-only` project may have no remote and skips no-mistakes initialization.

## Create a project

Creating a GitHub repository is outward-facing.
Before making that remote change, propose the repository name, owner or organization, visibility, and delivery posture, defaulting visibility to private and the posture to `no-mistakes-prod-only`, then obtain the captain's explicit consent for those exact values; a stated default never replaces that consent.
Use `gh-axi` for the approved GitHub operation and consult its current help rather than relying on remembered flags.
After remote creation succeeds, clone it locally, add the registry entry, and initialize it according to its delivery posture.

For a purely `local-only` project, create a local Git repository under its unused `projects/<name>` path, add the registry entry, and make no GitHub call.
The captain's request to create that local project authorizes this local initialization, but it does not authorize an unmentioned remote repository.

## Initialize

Run no-mistakes initialization only for `no-mistakes` and `no-mistakes-prod-only` projects:

```sh
cd projects/<name> && no-mistakes init && no-mistakes doctor
```

Initialization configures the local gate and does not vendor a no-mistakes skill into the project.
Do not create a commit merely because initialization ran.
If doctor reports an environment, authentication, or daemon problem, resolve that blocker before dispatching work and never restart the shared daemon from a project operation.

## Carry a project's own agent instructions into dispatch

A project's committed `AGENTS.md`, or the `CLAUDE.md` that points at it, is that project's own contract for work done in it, and it binds firstmate's dispatch as well as the worker's implementation.
Read it in the clone under `projects/<name>` before dispatching the task.
Reading it never authorizes changing it: `AGENTS.md` hard rule 1 still forbids firstmate writing a project's own instructions, and a crewmate updates them through the project's selected delivery path.

Separate what those instructions require of the work from what they require of the dispatcher.
Requirements on the work, such as a named exit criterion and its raw output, an evidence format, a test scope, or a review gate, are task-specific brief content.
The generated ship brief already tells the crewmate to read and follow the project's own instructions, so name in the brief only what changes this task's scope, acceptance criteria, or required evidence.

Requirements on the dispatcher must be satisfied before the worker receives its delivery contract, not left for the worker to discover.
That is the spawn for a freshly briefed ship task, and the promotion for a scout: `bin/fm-promote.sh` is where a scout's delivery mode is first resolved at all, and it takes no issue argument, so run this whole dispatcher step - read the project's instructions, reconcile the mode, search and reuse or create the issue - before running it.
The ship instructions carry no task slot to name the issue in, so steer it to the promoted worker with `bin/fm-send.sh`, which writes a durable record under the task's steering inbox rather than only printing into a pane; state the issue number explicitly in that message so the record itself identifies it.
That record is the promotion path's durable issue reference: it stays in the task's inbox until the worker acknowledges it, and the acknowledgement moves it into that inbox's `handled/` directory rather than deleting it. Leave it there until the task lands and any issue closure is done - it is the only place the number survives a session restart on this path.
Reconcile the resolved delivery mode against those requirements first, while nothing has been created yet.
That reconciliation is about this task, not the project in the abstract. It fires only where the project's instructions require this work to carry an issue and require that issue to be linked or closed through a pull request: `local-only` opens none, so change the mode or return that concrete decision, and do not create the issue first.
Both inputs are already in hand at that point, so creating an outward-facing issue for a task that will halt on its first read of the project's instructions spends a public artifact and a spawn for nothing.
Where the project mandates no issue for this work, or permits an issue to be closed without a pull request, `local-only` needs no reconciliation and stays available.
Searching, reusing, creating, assigning, and post-landing closing of a registered project's tracker issues under this procedure is the narrow authority `AGENTS.md` hard rule 1 names for it, and it needs no per-issue consent. It authorizes nothing else on that remote: no code, settings, releases, or any other mutation.
Where the project mandates an issue-first intake, search that project's open issues with `gh-axi` first and reuse a matching open issue rather than creating a second one for work already tracked.
Only when no open issue covers the scope, create it with `gh-axi` using the issue form that project names.
Either way, pass the issue number into the brief so the worker can claim it.
On `local-only` that issue has no pull request to close it, so firstmate owns closing it, and only after the guarded local merge has landed.
Reread the number from the exact durable source for this task's path - the task's brief on a spawned ship task, or the promotion steer record in the task's inbox or its `handled/` directory on a promoted one - then close it with `gh-axi`, naming the commit the fast-forward landed.
Where neither of those sources names an issue, close nothing: an issue you remember but cannot read back is not an identification, and closing the wrong number is worse than leaving one open. Report that instead.
Do not close it at `done: ready`, before the merge, or where the project forbids closing an issue without a pull request - that case is the mode conflict resolved above, before any issue exists.
That closure comes due long after dispatch, often in a later session, so an approved local-only landing for a task carrying a named issue is itself a trigger for this skill; `AGENTS.md` section 6 routes it there at the merge step.
Linking is not satisfiable before the spawn because no pull request exists yet, so the generated brief's project-instructions block owns that moment and names the lever for this task's delivery mode: a `Closes #N` reference carried in the `--intent` a no-mistakes worker gives the pipeline, and the body of the pull request a direct-PR worker opens itself.
`local-only` opens no pull request and so has no link to make; the block's halt there is the backstop for a PR-link requirement this reconciliation missed, and it fires only when an issue was actually named.
Where the project mandates scanning open pull requests for overlapping scope, run that scan and reconcile the overlap under `AGENTS.md` section 7's serialization rules before dispatching.

Never copy a project's rules into firstmate's own instructions, and never carry one project's workflow to another project.
If a project's instructions conflict with a current captain instruction or a firstmate safety boundary, the captain and the boundary win, and the conflict is reported rather than silently resolved.
A project's branch-naming convention is settled the same way and needs no dispatch-time reconciliation: the task branch is firstmate's own `fm/<task-id>`, which the brief's project-instructions block already exempts.

## Remove

Project removal is destructive.
First obtain the captain's explicit removal decision, then inspect the current digest and authoritative repositories for in-flight or queued work, registered secondmate clones, linked worktrees, dirty files, unpushed commits, and any other unlanded work.
If any dependency or unlanded work exists, stop and report it before changing anything.
Never issue a raw removal command from Firstmate.
Once that preflight confirms none of the above and the captain's approval is concrete, AGENTS.md hard rule 1's captain-approved project operation exception authorizes firstmate to remove the clone directly and update its registry entry to match.
When a clone has already been removed through an approved removal, or the registry is provably stale because no clone exists, remove its registry line so navigation matches reality.
