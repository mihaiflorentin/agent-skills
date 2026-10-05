---
name: review-changes
description: Reviews the code of a finished batch once, with one reviewer over all parallel lanes' work, checking the seams between lanes first; writes a rulings file, dispatches 1-3 fixers split by area and re-reviews only Important findings or worse. Use when every lane of a batch is merged and the fast checks are green, or after review fixes land.
disable-model-invocation: true
---

# Review workflow

Copy this checklist and tick it off as you go:

```
Review progress:
- [ ] 1. Layer check run (if the project has one)
- [ ] 2. Review package written
- [ ] 3. One reviewer's findings received (cross-lane seams first)
- [ ] 4. rulings.md written; user asked about product choices
- [ ] 5. Fixers done, 1-3 split by area (owed tests written); targeted tests green; tester loop started
- [ ] 6. Re-review of Important+ fixes done
- [ ] 7. Open items logged; cost recorded
```

Contents: Steps · Done when

Review is the safety net for light plans, and the same flow serves bug-fix batches and follow-up sweeps. Measured over six plans, it found 1–5 real Important bugs per plan whatever the plan style was: lost updates, double payouts, resurrected entities, a reset that never finished, overlapping labels. So keep the review, and scope it tightly.

## Steps

1. **Layers.** If the project enforces layer rules, run its check (for the hexagonal layout: `~/.claude/skills/apply-hexagonal-architecture/scripts/check-layers.sh`, when the repo has `layers.rules`). A violation is an Important finding.
2. **Package.** Run `shared/scripts/review-package.sh <base-before-plan> HEAD .agent-work/reviews/<plan>`. That produces `code.diff` (no tests, no generated files), `tests.stat` and `commits.txt`. Exclude another plan's commits from the range.
3. **Review.** Start only when every lane of the batch is merged. Dispatch ONE `reviewer` over all the changes at once, not one per lane or per task. Its first focus is the cross-lane seams: parallel lanes cannot see each other, so wire and field names, shared stores, call chains and feature flags are where they disagree, and where a trial's Important findings were. Give it:
   - the plan (the authority);
   - the decisions section (binding decisions and cut features);
   - the package, and every lane ledger with its deviations, notes for the merge, owed work and owed-to-tester list.

   After the seams, focus it on what this plan risks: concurrency and lock order, double claims or payouts, binding decisions, cut features creeping in, breaks of the project's architecture rules (for the hexagonal layout: rules in adapters or controllers, container getters that read fields or return concrete types), owed race tests and the tests lanes skipped ("decide from the code: safe, or a real bug?"), new user-visible or cross-module names missing from `docs/terminology.md` (Minor), tests that pin a wrong command (check every new test against the server contract, because a wrong unit test can pin a wrong command), and unexplained failures the implementers reported. The reviewer returns at most 40–50 lines of text (reviewers often cannot write files), with findings by severity giving `file:line`, the scenario and the fix.
4. **Rule.** Write `.agent-work/reviews/<plan>/rulings.md`:
   - each finding with its location, marked FIX, KEEP (recorded deviation) or RECORD (follow-up);
   - your choice wherever the reviewer offered options;
   - any user question the review surfaced. Ask the user before dispatching, for example "10% of max or of missing?".
5. **Fix.** Split the FIX findings by where they were found: findings in the same files or subsystem go to the same fixer, so it loads that context once (10 issues in one place means one fixer). Use 1–3 **fresh** `implementer` agents (the fixers), each with its part of the rulings file and the agent-rules blocks: one commit per fix, a test per fix, targeted tests only. Each also writes the owed tests of its area that the lanes skipped or ran out of budget for. The slow gates belong to one tester (`/test-changes`), which loops with the fixers until green. The same flow applies to bug-fix batches and follow-up sweeps.
6. **Re-review only if the review found Important or worse.** Package just the fix commits and dispatch a scoped `reviewer` (about 50–130k tokens). For a fix of a few lines, read the diff yourself instead. If the findings were only Minor or Low and each fix has a test, skip the re-review.
7. **Close.** Fix any Low leftovers yourself if they're trivial (a stale comment, say). Log the rest as open items in `docs/decisions.md`, and record the loop's cost in `.agent-work/workflow-metrics.md`.

## Done when

The rulings are applied, the owed tests are written, the tester's full gate is green after the fixes, any Important finding has been re-checked, and the open items are logged. Only then does the work merge to the main branch and get pushed.
