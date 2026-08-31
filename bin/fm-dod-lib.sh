#!/usr/bin/env bash
# Single owner of the contract blocks a ship task carries: the mode-specific
# "Definition of done" and the project-instructions block.
# Sourced by bin/fm-brief.sh, which renders them into a generated ship brief, and by
# bin/fm-promote.sh, which renders them into the ship instructions a promoted scout
# receives. Both paths must hand the worker the same contract: a promoted
# no-mistakes worker that never received the ask-user escalation rule, the
# `--yes` ban, or the project's own agent instructions is the exact delivery hole
# this single owner exists to close.
# fm_dod_block <no-mistakes|direct-PR|local-only> <task-id> prints the block on
# stdout with no trailing blank line. The caller validates the mode; an unknown
# mode is refused rather than silently rendered as the pipeline contract.
# The block opens with the fixed machine-readable "Delivery contract: mode=<mode>"
# line that bin/fm-spawn.sh checks a ship brief against.
# Every heredoc here stays outside a command substitution: `VAR=$(cat <<EOF ...)`
# breaks parsing of the whole file on Bash 3.2 (tests/fm-brief.test.sh).

# fm_project_instructions_block <no-mistakes|direct-PR|local-only> <task-id>
# prints the block on stdout with no trailing blank line, and refuses an unknown
# mode rather than rendering a contract for one. A project's own committed
# AGENTS.md or CLAUDE.md binds the work done in it, so every worker that edits
# files - freshly briefed or promoted in place - must be told to read it and to
# stop on a conflict rather than choose silently. What binds is what that file
# requires of the work; a repository whose own instructions define a supervising
# agent's role, authority, or style is addressing a different reader, and a
# worker that adopted those would stall or misreport instead of implementing.
# Issue creation and reuse are dispatcher-owned in the project-management skill,
# so the block names them as firstmate's rather than leaving a project's
# issue-first mandate readable by the worker as licence to open a second one.
# The one carve-out is the branch NAME: `fm/<id>` is firstmate's own mechanical
# identity, created by the brief's Setup step and assumed by
# bin/fm-merge-local.sh and bin/fm-review-diff.sh, so a
# project's branch-naming convention cannot be allowed to stall every such task on
# needs-decision or rename the branch out from under those consumers.
# The block also owns the one moment an issue can be linked: firstmate creates or
# reuses the issue before the spawn, and only the worker is present once a pull
# request exists. That moment differs per mode, so the instruction names the exact
# lever for each: the `--intent` the pipeline derives its PR body from, whose one
# construction rule lives in the no-mistakes Definition of done below and is
# pointed at rather than restated here so the two cannot drift apart, repaired
# only at the CI-ready return point once the pipeline has stopped rewriting that
# body; the PR the direct-PR worker opens itself; and no PR at all on local-only,
# where a named issue's PR-link requirement is unmeetable and is routed back as a
# needs-decision rather than deferred to a pull request that never comes. With no
# issue named, local-only has nothing to link and raises nothing.
# Every escalation here names the action rather than a rule number: the block is
# appended under bin/fm-promote.sh's own numbered ship-instructions list, where a
# bare "rule 6" would resolve against the wrong list.
fm_project_instructions_block() {  # <mode> <task-id>
  local mode=$1 id=$2
  case "$mode" in
    no-mistakes|direct-PR|local-only) ;;
    *)
      echo "error: fm_project_instructions_block: unknown delivery mode '$mode'" >&2
      return 1 ;;
  esac
  cat <<EOF
# Project instructions
If the project carries its own \`AGENTS.md\` or \`CLAUDE.md\`, read it before you edit any file.
Follow what it requires of the work: the branch, evidence, test, review, and commit requirements it states for a change landing in that repository. Those bind this task.
Some of what it states is addressed to a different agent than you: a repository's own role definition, supervisor or delegation authority, conversational style, and the lifecycle steps its dispatcher owns. Those do not bind your implementation. You are the implementation worker for this task under firstmate's instructions - do not adopt another role from that file and do not delegate this task onward.
Issue creation, reuse, assignment, and this task's delivery mode are firstmate's and were decided before you were given this task. Use only an issue firstmate named to you; never open, reuse, or reassign one yourself, and close one only through the mode-specific pull request reference named below. If the project requires an issue for work like this and firstmate named none, that is a needs-decision stop, not permission to open one.
Where a work-binding requirement conflicts with the task instructions firstmate gave you, or where you cannot tell which of the two kinds a requirement is, append \`needs-decision: {the requirement, the file it came from, and the conflict}\` to the status file, stop, and wait for firstmate's answer, rather than choosing between them yourself.
Your branch name \`fm/$id\` is the single exception: it is firstmate's own mechanical identity, owned by these task instructions, and a project's branch-naming convention does not override it. Keep \`fm/$id\`, and do not report that naming difference as a conflict. Every other project-instruction conflict, including any other branch requirement, still stops.
EOF
  case "$mode" in
    direct-PR)
      cat <<'EOF'
If firstmate named issue #N for this task, put an explicit same-repository reference to it (`Closes #N`) in the body of the pull request you open with `gh-axi`, and confirm the body carries it before you append `done: PR {url}`.
EOF
      ;;
    local-only)
      cat <<'EOF'
This task ships local-only: it opens no pull request, so there is no pull request body for you to add an issue reference to.
If firstmate named no issue for this task, there is nothing to link and nothing to raise here, whatever the project says about linking pull requests to issues.
If firstmate named issue #N and the project's own instructions require that issue to be closed or linked by a pull request, that requirement cannot be met under this delivery mode. Do not assume a later pull request will carry it: append `needs-decision: {the project requires a PR link for issue #N, mode is local-only}` to the status file, stop, and wait for firstmate's answer, so firstmate can change the mode or the plan.
EOF
      ;;
    no-mistakes)
      cat <<'EOF'
If firstmate named an issue for this task, the pipeline's pull request must link it, and the pipeline derives that pull request body from your `--intent`. The Definition of done's `--intent` rule below is authoritative for what goes in that field, and it names a firstmate-named issue reference as task-specific content to carry there; do not construct `--intent` by some other rule here.
Do not touch that pull request body while the run is active - the pipeline rewrites it. Wait until /no-mistakes reports CI green (the CI-ready return point below): only then read the body with `gh-axi` and, if the reference is missing, add it with `gh-axi`, immediately before you append your final `done:` line. That one edit changes no code and is made after the pipeline has stopped writing the pull request.
EOF
      ;;
  esac
}

fm_dod_block() {  # <mode> <task-id>
  local mode=$1 id=$2
  case "$mode" in
    direct-PR)
      cat <<EOF
# Definition of done
Delivery contract: mode=direct-PR
This task ships **direct-PR**: you raise the PR yourself, without the no-mistakes pipeline.
The task is complete only when committed on your branch.
When it is implemented and committed, push your branch and open a PR with \`gh-axi\`, then append \`done: PR {url}\` to the status file and stop.
Do NOT run /no-mistakes. The configured merge authority decides whether to merge the PR; firstmate relays the outcome.
EOF
      ;;
    local-only)
      cat <<EOF
# Definition of done
Delivery contract: mode=local-only
This task ships **local-only**: no remote, no PR, no pipeline.
The task is complete only when committed on your branch \`fm/$id\`. Do NOT push, do NOT open a PR, do NOT merge.
Keep your branch a clean fast-forward onto the current default branch - if \`main\` has advanced, rebase onto it so the eventual merge stays a fast-forward.
When it is implemented and committed, append \`done: ready in branch fm/$id\` to the status file and stop.
The configured merge authority approves the ready branch, then firstmate merges it into local \`main\` through the guarded fast-forward path.
EOF
      ;;
    no-mistakes)
      cat <<EOF
# Definition of done
Delivery contract: mode=no-mistakes
The task is complete only when committed on your branch.
When you believe it is complete, append \`done: {summary}\` to the status file and stop.
Firstmate will then instruct you to run /no-mistakes to validate and ship a PR.

You drive no-mistakes by responding to its gates, not by implementing fixes.
Follow the guidance no-mistakes itself provides for the mechanics: it loads when you invoke /no-mistakes, and \`no-mistakes axi run --help\` plus the \`help\` lines in each \`axi\` response are authoritative and version-matched to the installed binary.
When starting no-mistakes, make \`--intent\` preserve all relevant content from this brief's \`# Task\` section plus every later accepted Firstmate requirement, clarification, constraint, exclusion, and supersession, carrying only each requirement's current accepted form; retain direct requirements instead of substituting a diff summary, and exclude generic operational, status, delivery, and other scaffold boilerplate unless it is task-specific.
A same-repository issue reference firstmate named for this task (\`Closes #N\`) is task-specific accepted content, not scaffold boilerplate: carry it in \`--intent\` so the pull request the pipeline generates links that issue.
Do not hand-edit, commit, or fix findings yourself while a run is active - the pipeline applies every fix.

Two firstmate-specific rules layer on top of that guidance:
- ask-user findings are never yours to answer: escalate to firstmate (rule 6) and stop.
  Firstmate applies \`ask-user-authority\` and obtains any required captain decision.
  When the decision comes back, feed it to the gate with \`no-mistakes axi respond\` and let the pipeline apply it - do not route the question to "the user" or implement the fix yourself.
- NEVER pass \`--yes\` (or \`-y\`) to \`no-mistakes axi run\` or \`no-mistakes axi respond\`. It is banned fleet-wide.
  It auto-resolves every gate including ask-user findings with no escalation, and answering your own ask-user finding is a hard rule violation.

After /no-mistakes reports CI green (the CI-ready return point - do not wait for it to keep monitoring in the background until merge), append \`done: PR {url} checks green\` and stop. You are finished.
EOF
      ;;
    *)
      echo "error: fm_dod_block: unknown delivery mode '$mode'" >&2
      return 1 ;;
  esac
}
