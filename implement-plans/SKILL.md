---
name: implement-plans
description: Builds a committed plan with implementer subagents, by default as parallel lanes (one git worktree and branch per lane, a wave table, file ownership, a merge agent), or in two sequential halves when every task depends on the previous one. Use right after a plan is committed, or to resume a half-built plan.
disable-model-invocation: true
---

# Implement workflow

Copy this checklist and tick it off as you go:

```
Build progress (parallel lanes, the default):
- [ ] 1. Plan has a wave table, lanes and a file ownership table; mode chosen
- [ ] 2. Lane-rules file written in .agent-work/; one worktree and branch per lane
- [ ] 3. Wave 0 (seams and types) merged, if the plan has one
- [ ] 4. Each batch: lanes dispatched together; WAIT for every lane; reports read, metrics logged
- [ ] 5. Merge agent: all lanes merged once (--no-ff), notes applied, fast checks green, owed-to-tester list written
- [ ] 6. Art lanes: renders approved by the user before commit
- [ ] 7. Hand over to /review-changes (one review, 1-3 fixers, one tester); working branch only after green
```

Sequential fallback checklist:

```
Build progress (sequential halves):
- [ ] 1. First half dispatched (tasks 1-6)
- [ ] 2. First half's report read; metrics logged; concerns turned into instructions
- [ ] 3. Second half dispatched with the HAND-OFF section
- [ ] 4. UI only: baselines reviewed before commit
- [ ] 5. Every task committed; gate log ends in EXIT 0
```

Contents: Choose the mode · Parallel lanes · Sequential halves · Watch for

A subagent's context cannot be compacted, and every tool call re-reads all of it, so cost grows with the length of one agent's run. Lanes keep every agent short and run side by side. Measured on one 20-task plan: sequential halves cost 158–189k Sonnet tokens and 29–40 minutes per task; four parallel lanes cost about 98k tokens and 3.5 minutes per task, 20 tasks in about 70 minutes. Bug-fix batches of 3 lanes × 4 tasks took about 4–6 minutes per lane on Sonnet medium. Review, fix and test costs come on top (see `/review-changes` and `/test-changes`).

## Choose the mode

Use **parallel lanes** when the plan has a wave table and a file ownership table (`/plan-slices`). Use **sequential halves** only when the tasks all depend on each other, so no wave holds more than one task. If the plan has no wave table, send it back to `/plan-slices` first.

## Parallel lanes

1. **Lane rules.** Copy `shared/lane-rules.md` to `.agent-work/plans-run/<plan>/lane-rules.md` and fill in the project's test commands, the ownership table location and the docs to read. Every dispatch prompt then stays a few lines: the lane name, its tasks, the plan path and the rules path.
2. **Worktrees.** For each lane, one worktree and one branch off the current base: `git worktree add -b <plan>/lane-x ../<plan>-lane-x`. Share installed dependencies instead of reinstalling (for example a symlink to `node_modules`). Lane agents never touch another lane's worktree.
3. **Wave 0.** If lanes share types, a tiny wave-0 task (seams and types only, no behaviour) builds first, is merged into the base, and the lane branches start from it.
4. **Dispatch each wave.** At most 4–5 `implementer` agents per wave, all dispatched in one message. A lane holds 3–5 tasks, grouped by area (the same files or subsystem), so the agent loads as little context as possible. The same flow applies to bug-fix batches and follow-up sweeps. A lane may edit only files it owns (the plan's ownership table). For a file it does not own it writes a line under "Notes for the merge" in its ledger and does not edit. Each prompt carries:
   - the lane name, worktree path, task numbers and plan path;
   - the lane-rules path and the binding decisions section;
   - `docs/terminology.md`, and for a hexagonal project the build order of `/apply-hexagonal-architecture`.
5. **Lane tests.** Lanes run only fast tests, each under a minute. Never the full gate, the browser or e2e suites, or a database suite: the tester runs those later. Whatever a lane skips for that reason goes in its ledger under "Owed to the tester". Every other test, and every task, the lane finishes itself.
6. **Ledger.** Each lane keeps `.agent-work/plans-run/<plan>/lane-x.md` with one line per task and commit, the sections "Notes for the merge" and "Owed to the tester", and a HAND-OFF section if its context gets long. A lane finishes every task it was given, with its tests; it never leaves a task or a test as owed work. If its context gets long, it hands off to a fresh agent, which finishes the rest of the lane.
7. **Merge agent.** Wait for EVERY lane of the batch to finish. Never merge or review a partial batch, and review as many tasks at once as possible. Then dispatch one `implementer` that merges every lane branch with `--no-ff`, applies each lane's "Notes for the merge" to the files it owns, resolves conflicts (regenerate generated files rather than hand-merging them), runs the fast checks and writes one combined owed-to-tester list. Later waves branch from the merged base. The merge goes to the integration branch only; the working branch waits for the tester's green gate.
8. **Art and asset lanes.** Visual art lanes (3D models, icons, portraits, VFX) run on Opus 5.5, in parallel with the code lanes. Audio and music generation runs on Sonnet 5.5 (`shared/agent-rules.md`, Models). Renders are not committed until the user has approved them at an art checkpoint (`/test-changes`, screenshot baselines). Report their tokens separately from the code lanes.
9. **Metrics.** Record each agent's tokens, tool calls and wall clock in `.agent-work/workflow-metrics.md`.
10. **Done when** every lane is merged, the fast checks are green on the merged base, and the combined owed-to-tester list exists. Then run `/review-changes`. The full gate belongs to the tester, not to this stage.

## Sequential halves

For plans whose tasks all depend on each other. One implementer builds a run of tasks, then hands off to a fresh one. One agent that carried 12 tasks reached about 950k tokens and took 5.5 h. Split into halves, the same size of plan costs 600k + 400k.

1. **Dispatch the first half** (Tasks 1–6, or about 500k tokens' worth). The prompt carries:
   - one line on where the plan fits;
   - the plan path and the decisions section with the binding decisions (and the cut features to leave out);
   - which AGENTS.md sections to read, and the project's architecture rules. For a hexagonal project (the `apply-hexagonal-architecture` skill), each task goes `port/` → `domain/` → `infrastructure/` → `config/` → `container/` → `cmd/`;
   - `docs/terminology.md`: use its names, and add a term in the same commit that introduces it in code or UI;
   - the progress file path, `.agent-work/plans-run/<plan>/progress.md`;
   - the blocks from `shared/agent-rules.md`: token and tool-call discipline, waiting, gate cadence for the project's test profile (Slow: targeted checks only, **no full gate in this half**; Fast: test first, full gate before every commit), commits (every commit builds), scope, hand-off and the return contract.
2. **Read the first half's report** (5–10 lines). Record its tokens and tool calls in `.agent-work/workflow-metrics.md`. Check its deviations against the decisions file. Turn any concern into an instruction for the second half.
3. **Dispatch the second half** to a fresh agent. Its prompt has the HAND-OFF section first, then the remaining tasks and the same blocks. Add:
   - any concern from step 2 as an explicit fix;
   - the full gate after the last task (see `/test-changes`), fixed and rerun until green;
   - stop and write a HAND-OFF section at about 500k tokens, before finishing.
4. **UI plans:** the final gate includes the full e2e suite. New or changed screenshot baselines stay uncommitted. Copies go to `.agent-work/shots/<plan>/{before,after}`, and the agent STOPS for the controller's image review (`/test-changes`).
5. **Done when** every task is committed, the progress file has one line per task, and the gate log ends in `EXIT 0`. Then run `/review-changes`.

## Watch for

- **Skipped tests.** Implementers sometimes skip tests near the end of a long run. A lane's work is not done until each task has its tests: send a lane back (or to a fresh agent with its HAND-OFF) when a task or test is missing. Pass every ledger's "Owed to the tester" list on to the reviewer and the tester.
- **Seam mismatches.** Parallel lanes cannot see each other. Wire and field names, shared stores, call chains and feature flags are where they disagree. The ownership table and wave 0 reduce this; the review's first focus catches the rest.
- **Ownership breaches.** A lane that edits a shared file it does not own causes merge conflicts and silent overwrites. The merge agent reports any it finds.
- **Broken commits.** A commit that doesn't build, or that truncates a function, slipped through twice at medium effort. The "chain the build before committing" rule prevents it.
- **Re-pinned budgets.** Statement or performance re-pins need a stated reason in the commit message, and only the owning lane makes them. Read them.
- **Waits.** Never use sleep, `tail -f` or `pgrep` loops to wait. One such wait hung for 5 hours.
- **Noise in your context.** Live diagnostics (gopls, tsserver) about files the agents are editing land in your context as errors. They are stale snapshots of half-edited files. Ignore them; worktrees reduce this.
