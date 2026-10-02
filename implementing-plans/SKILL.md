---
name: implementing-plans
description: Builds a committed plan with implementer subagents in two halves of about 6 tasks each, with a HAND-OFF section in the progress file between them and one full gate at the end. Use right after a plan is committed, or to resume a half-built plan.
disable-model-invocation: true
---

# Implement workflow

Copy this checklist and tick it off as you go:

```
Build progress:
- [ ] 1. First half dispatched (tasks 1-6)
- [ ] 2. First half's report read; metrics logged; concerns turned into instructions
- [ ] 3. Second half dispatched with the HAND-OFF section
- [ ] 4. UI only: baselines reviewed before commit
- [ ] 5. Every task committed; gate log ends in EXIT 0
```

Contents: Steps · Watch for

One implementer builds a run of tasks, then hands off to a fresh one. A subagent's context cannot be compacted, and every tool call re-reads all of it. One agent that carried 12 tasks reached about 950k tokens and took 5.5 h. Split into halves, the same size of plan costs 600k + 400k.

## Steps

1. **Dispatch the first half** (Tasks 1–6, or about 500k tokens' worth). The prompt carries:
   - one line on where the plan fits;
   - the plan path and the decisions section with the binding decisions (and the cut features to leave out);
   - which AGENTS.md sections to read, and the project's architecture rules. For a hexagonal project (the `applying-hexagonal-architecture` skill), each task goes `port/` → `domain/` → `infrastructure/` → `config/` → `container/` → `cmd/`;
   - `docs/terminology.md`: use its names, and add a term in the same commit that introduces it in code or UI;
   - the progress file path, `.agent-work/plans-run/<plan>/progress.md`;
   - the blocks from `shared/agent-rules.md`: token and tool-call discipline, waiting, gate cadence for the project's test profile (Slow: targeted checks only, **no full gate in this half**; Fast: test first, full gate before every commit), commits (every commit builds), scope, hand-off and the return contract.
2. **Read the first half's report** (5–10 lines). Record its tokens and tool calls in `.agent-work/workflow-metrics.md`. Check its deviations against the decisions file. Turn any concern into an instruction for the second half.
3. **Dispatch the second half** to a fresh agent. Its prompt has the HAND-OFF section first, then the remaining tasks and the same blocks. Add:
   - any concern from step 2 as an explicit fix;
   - the full gate after the last task (see `/testing-changes`), fixed and rerun until green;
   - stop and write a HAND-OFF section at about 500k tokens, before finishing.
4. **UI plans:** the final gate includes the full e2e suite. New or changed screenshot baselines stay uncommitted. Copies go to `.agent-work/shots/<plan>/{before,after}`, and the agent STOPS for the controller's image review (`/testing-changes`).
5. **Done when** every task is committed, the progress file has one line per task, and the gate log ends in `EXIT 0`. Then run `/reviewing-plans`.

## Watch for

- **Skipped tests.** Implementers skip owed race tests under budget pressure. Pass the "owed" list to the reviewer, who decides from the code which ones hide real bugs.
- **Broken commits.** A commit that doesn't build, or that truncates a function, slipped through twice at medium effort. The "chain the build before committing" rule prevents it.
- **Re-pinned budgets.** Statement or performance re-pins need a stated reason in the commit message. Read them.
- **Noise in your context.** Live diagnostics (gopls, tsserver) about files the agents are editing land in your context as errors. They are stale snapshots of half-edited files. Ignore them, or run the plan in its own worktree.
