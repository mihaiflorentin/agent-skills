---
name: orchestrate-development
description: Runs the controller loop that takes a software project through spec, plan, implementation, testing and review with subagents, resuming from the STATE.md, docs/decisions.md and metrics files. Use at the start of a session, after a /compact, or when the user asks to continue the roadmap or pick the next plan.
disable-model-invocation: true
---

# Dev workflow (controller)

Copy this checklist into your notes and tick it off per plan:

```
Plan progress:
- [ ] 1. Read the project files; resume from STATE.md and git log; test profile known; layout set up
- [ ] 2. /plan-slices: questions asked, plan committed
- [ ] 3. /implement-plans: EVERY lane of the batch finished, then one merge (or both halves done); quota % asked at build start and after the build
- [ ] 4. /review-changes: one review over all changes, 1-3 fixers; /test-changes: one tester, gate green; quota % asked
- [ ] 5. Only now merge to the working branch with the pre-merge gate, and push
- [ ] 6. docs/ (decisions, roadmap, terminology) committed; STATE.md and metrics updated; /compact suggested
```

Contents: The pipeline · Loop per plan · Measure · Standing rules · Paths · Scripts

You are the **controller**. Subagents write specs, plans and code, and run tests and reviews. Your job is the decisions, the dispatches and the files that survive compaction. Keep your own context small: every agent notification re-reads all of it.

## The pipeline

| Stage | Skill | Ends when |
|---|---|---|
| Design a new area | `/write-specs` | the user approved the spec, with every feature marked as their decision or a proposal they kept |
| Plan one slice | `/plan-slices` | a committed light plan with binding user decisions quoted verbatim |
| Build it | `/implement-plans` | every lane of the batch finished and merged once (parallel lanes, the default) or every task committed (sequential halves), fast checks green |
| Check it | `/review-changes` | one reviewer over all changes, 1–3 fixers split by area, rulings applied |
| Gate and waits | `/test-changes` | one tester ran the slow gates and looped with the fixers until green; also the reference for cadence, background runs, flakes and screenshot baselines |

## Loop per plan

1. Read the project files (`shared/project-files.md`). Resume from `.agent-work/STATE.md` and `git log`. On a new project, run `shared/scripts/init-project.sh` first (the committed `docs/` layout plus the git-ignored `.agent-work/`), then time the full gate once and record the test profile, Fast or Slow, in `.agent-work/STATE.md` (`/test-changes`). Every dispatch carries that profile's cadence.
2. **Plan** (`/plan-slices`): a scout lists the open questions, you ask the user and record the answers verbatim, then a light plan with a wave table, lanes and a file ownership table. Risky plans get one design review first.
3. **Build** (`/implement-plans`), the whole workflow in order:
   1. **Lanes.** A few Sonnet 5.5 agents (medium effort by default, high only for really difficult work; Opus 5.5 only for visual art), at most 4–5 at a time, each in its own worktree and branch. A lane holds 3–5 tasks grouped by area (the same files or subsystem), so it loads as little context as possible, and edits only the files it owns.
   2. **Fast tests only in a lane:** targeted unit tests, type, vet and format checks, each under about a minute. Never the full gate, e2e or database suites; the lane lists them as owed to the tester.
   3. **Wait for every lane.** Never merge or review a partial batch.
   4. **One merge** of all the lanes into one integration branch, by one merge agent: notes for the merge applied, generated files regenerated, fast checks green, one combined owed-to-tester list.
   5. **One review** (`/review-changes`) of all the changes at once, cross-lane seams first.
   6. **1–3 fixers**, split by where the findings are: findings in the same files or subsystem go to the same fixer, so it loads that context once. Each fix comes with its test. Important findings get a scoped re-review.
   7. **One tester** (`/test-changes`) runs the full gate and the e2e suite. Real failures go back to the fixer of that area; repeat until green.
   8. **Only then**, when the cycle is finished and the new code is safe to merge, merge the integration branch into the working branch (the branch the project is developed on, which may not be `main`) with the pre-merge gate, and push.
4. Nothing reaches the working branch lane by lane. A single urgent user-reported bug may go alone, but still gets the review. Bug-fix batches and follow-up sweeps use this same workflow. Regenerate generated files instead of hand-resolving their conflicts.
5. Update and commit `docs/decisions.md`, `docs/roadmap.md` and `docs/terminology.md`, then update `.agent-work/STATE.md` and `.agent-work/workflow-metrics.md`. Suggest `/compact` to the user.
6. Pick the next plan. Ask the user whether reordering would let them test earlier: you can only run the product in tests, and the user is the first person to try it.

## Measure

Record tokens, tool calls and wall clock for every agent in `.agent-work/workflow-metrics.md`, art lanes separately. Ask the user for the weekly quota percentage used at the start of the build, after the build, and when the gate is green, and record each answer. The difference per stage is the real cost.

## Standing rules

- **One plan builds at a time per checkout.** Never run a server plan and a UI plan together. Lanes of one plan are the exception: they run in their own worktrees, and run only fast tests (under a minute each), so load stays low. Run at most 4–5 lanes at a time. The slow gates run once, in the tester.
- **Wait for every lane before the merge and the review.** Never merge or review a partial batch: one merge of all the lanes, then one reviewer over all the changes, so the fixers can be split by area.
- **Rulings, not stalls.** When the user is away, decide, log the ruling in `docs/decisions.md` as the controller's, and continue. When the user is present, read `docs/terminology.md` first, then ask genuine product questions one at a time, each with a **Background** paragraph that explains every project term in plain words (what the feature is, what exists, what's missing and why), then 2–4 options that say what the user would see and what each costs, recommended first. Record the answer verbatim. Terse questions leave the user unable to decide.
- **Fresh agents for revisions.** Give a fix or a plan revision to a new agent along with a findings file. Resuming a long-running agent drags its whole context along.
- **Short replies to the user.** One short status line per notification. Batch updates.
- **Architecture.** Follow the project's own conventions. For a project on the hexagonal layout (`cmd/`, `config/`, `container/`, `domain/`, `infrastructure/`, `port/`), every stage also applies `/apply-hexagonal-architecture`.
- **Watchdog for unattended runs.** A stuck agent sends no notification. While agents run unattended, keep one background timer running (`sleep 2700` with run_in_background); when it fires, check each running agent's log or worktree for progress, then start the next timer. An agent with no file or log change for over 45 minutes is probably waiting on a prompt: report it, and restart its lane if needed.
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
