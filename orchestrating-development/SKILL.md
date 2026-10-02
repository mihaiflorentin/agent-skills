---
name: orchestrating-development
description: Runs the controller loop that takes a software project through spec, plan, implementation, testing and review with subagents, resuming from the STATE.md, briefing.md and metrics files. Use at the start of a session, after a /compact, or when the user asks to continue the roadmap or pick the next plan.
disable-model-invocation: true
---

# Dev workflow (controller)

Copy this checklist into your notes and tick it off per plan:

```
Plan progress:
- [ ] 1. Read the controller files; resume from STATE.md and git log; test profile known
- [ ] 2. /planning-slices: questions asked, plan committed
- [ ] 3. /implementing-plans: both halves done, gate EXIT 0
- [ ] 4. /reviewing-plans: findings fixed, gate green again
- [ ] 5. Merge with the pre-merge gate
- [ ] 6. STATE.md, briefing.md, workflow-metrics.md updated; /compact suggested
```

Contents: The pipeline · Loop per plan · Standing rules · Paths · Scripts

You are the **controller**. Subagents write specs, plans and code, and run tests and reviews. Your job is the decisions, the dispatches and the files that survive compaction. Keep your own context small: every agent notification re-reads all of it.

## The pipeline

| Stage | Skill | Ends when |
|---|---|---|
| Design a new area | `/writing-specs` | the user approved the spec, with every feature marked as their decision or a proposal they kept |
| Plan one slice | `/planning-slices` | a committed light plan with binding user decisions quoted verbatim |
| Build it | `/implementing-plans` | every task committed and the full gate green |
| Gate and waits | `/testing-changes` | reference for cadence, background runs, flakes and screenshot baselines |
| Check it | `/reviewing-plans` | review findings fixed and the gate green again |

## Loop per plan

1. Read the controller files (`shared/controller-files.md`). Resume from `STATE.md` and `git log`. On a new project, time the full gate once and record the test profile, Fast or Slow, in `STATE.md` (`/testing-changes`). Every dispatch carries that profile's cadence.
2. Run `/planning-slices`, then `/implementing-plans`, then `/reviewing-plans`.
3. Merge at plan boundaries, running the full pre-merge gate. Regenerate generated files instead of hand-resolving their conflicts.
4. Update `STATE.md`, `briefing.md` and `workflow-metrics.md`. Suggest `/compact` to the user.
5. Pick the next plan. Ask the user whether reordering would let them test earlier: you can only run the game in tests, and the user is the first player.

## Standing rules

- **One plan builds at a time per checkout.** Never run a server plan and a UI plan together: load makes perf tests flake, and the reruns cost more than the parallelism saves.
- **Rulings, not stalls.** When the user is away, decide, log the ruling in `briefing.md` as the controller's, and continue. When the user is present, ask genuine product questions one at a time, each with a **Background** paragraph that explains every project term in plain words (what the feature is, what exists, what's missing and why), then 2–4 options that say what the player would see and what each costs, recommended first. Record the answer verbatim. Terse questions leave the user unable to decide.
- **Fresh agents for revisions.** Give a fix or a plan revision to a new agent along with a findings file. Resuming a long-running agent drags its whole context along.
- **Short replies to the user.** One short status line per notification. Batch updates.
- **Architecture.** Follow the project's own conventions. For a project on the hexagonal layout (`cmd/`, `config/`, `container/`, `domain/`, `infrastructure/`, `port/`), every stage also applies `/applying-hexagonal-architecture`.
- **Agent rules travel in the prompt.** Paste the blocks from `shared/agent-rules.md` into every dispatch.

## Paths

Paths such as `shared/agent-rules.md` and `shared/scripts/run-logged.sh` are relative to this skill's folder (Claude Code shows it as the skill's base directory; `shared` is a link to the repo's shared folder). Other skills of this set sit beside it, in `~/.claude/skills/<skill-name>/`. A subagent does not know these folders, so write the full path out whenever you put a script or file into a dispatch.

## Scripts

`shared/scripts/`:
- `run-logged.sh`: long runs, with an EXIT line and the failure lines.
- `failures.sh`: the failure lines of a log.
- `review-package.sh`: a scoped diff for reviewers.
- `shared/scripts/commit-only.sh`: commits only the named paths, safe while another agent commits.
- `contact-sheet.py`: tiles screenshots into one image for review.
- `stale-waits.sh`: finds stuck `tail -f` or sleep waits.
