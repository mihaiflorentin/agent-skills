---
name: reviewing-plans
description: Reviews a finished plan once with a scoped diff package, writes a rulings file, dispatches a fresh fix agent and re-reviews only Important findings or worse. Use when a plan's build gate is green, or after review fixes land.
disable-model-invocation: true
---

# Review workflow

Copy this checklist and tick it off as you go:

```
Review progress:
- [ ] 1. Layer check run (if the project has one)
- [ ] 2. Review package written
- [ ] 3. Reviewer's findings received
- [ ] 4. rulings.md written; user asked about product choices
- [ ] 5. Fresh fix agent done; gate green
- [ ] 6. Re-review of Important+ fixes done
- [ ] 7. Open items logged; cost recorded
```

Contents: Steps · Done when

Review is the safety net for light plans. Measured over six plans, it found 1–5 real Important bugs per plan whatever the plan style was: lost updates, double payouts, resurrected entities, a reset that never finished, overlapping labels. So keep the review, and scope it tightly.

## Steps

1. **Layers.** If the project enforces layer rules, run its check (for the hexagonal layout: `~/.claude/skills/applying-hexagonal-architecture/scripts/check-layers.sh`, when the repo has `layers.rules`). A violation is an Important finding.
2. **Package.** Run `shared/scripts/review-package.sh <base-before-plan> HEAD .agent-work/reviews/<plan>`. That produces `code.diff` (no tests, no generated files), `tests.stat` and `commits.txt`. Exclude another plan's commits from the range.
3. **Review.** Dispatch one `reviewer` with:
   - the plan (the authority);
   - the decisions section (binding decisions and cut features);
   - the package and the progress file with its deviations and owed tests.

   Focus it on what this plan risks: concurrency and lock order, double claims or payouts, binding decisions, cut features creeping in, breaks of the project's architecture rules (for the hexagonal layout: rules in adapters or controllers, container getters that read fields or return concrete types), owed race tests ("decide from the code: safe, or a real bug?"), new player-visible or cross-module names missing from `docs/terminology.md` (Minor), and unexplained failures the implementer reported. The reviewer returns at most 40–50 lines of text (reviewers often cannot write files), with findings by severity giving `file:line`, the scenario and the fix.
4. **Rule.** Write `.agent-work/reviews/<plan>/rulings.md`:
   - each finding with its location, marked FIX, KEEP (recorded deviation) or RECORD (follow-up);
   - your choice wherever the reviewer offered options;
   - any user question the review surfaced. Ask the user before dispatching, for example "10% of max or of missing?".
5. **Fix.** Dispatch a **fresh** `implementer` with the rulings file and the agent-rules blocks: one commit per fix, a test per fix, then the full gate once.
6. **Re-review only if the review found Important or worse.** Package just the fix commits and dispatch a scoped `reviewer` (about 50–130k tokens). For a fix of a few lines, read the diff yourself instead. If the findings were only Minor or Low and each fix has a test, skip the re-review.
7. **Close.** Fix any Low leftovers yourself if they're trivial (a stale comment, say). Log the rest as open items in `docs/decisions.md`, and record the loop's cost in `.agent-work/workflow-metrics.md`.

## Done when

The rulings are applied, the full gate is green after the fixes, any Important finding has been re-checked, and the open items are logged.
