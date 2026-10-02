---
name: planning-slices
description: Turns one roadmap slice into a light implementation plan (150-300 lines, no code): question scout, user decisions quoted verbatim, contracts and tests per task, and a design review only for risky plans. Use when the next roadmap item needs a plan, or a plan must be split or revised.
disable-model-invocation: true
---

# Plan workflow

Copy this checklist and tick it off as you go:

```
Plan progress:
- [ ] 1. Question scout file written
- [ ] 2. User answered; answers in docs/decisions.md verbatim
- [ ] 3. Light plan written
- [ ] 4. Plan defaults checked against the user's decisions
- [ ] 5. Design review (risky plans only)
- [ ] 6. Revision by a fresh agent (if reviewed)
- [ ] 7. Plan committed; cost logged
```

Contents: Steps · Done when

A plan should cost a small fraction of what its build costs. Measured on this workflow: light plans cost 150–320k tokens, while one detailed plan cost 3M because its questions were asked after it was written. The **light plan** fixes the scope, the user's decisions, the contracts between components and the tests each task needs. The implementer designs everything else.

## Steps

1. **Question scout.** Dispatch a `scout` with:
   - the roadmap row and its hand-offs;
   - only the spec sections that row cites, read through grep and line ranges;
   - the decisions file, so it does not re-ask decided questions.

   It writes `.agent-work/questions/<plan>.md`, which holds:
   - a scope of at most 8 lines;
   - **agent-proposed features**: anything not tagged `[USER]` and not in the decisions file, one plain line each, at most 12;
   - up to 6–8 genuine product questions, each with options, a recommendation and the spec location;
   - the defaults it adopts;
   - for a big slice, a split recommendation.

   It returns only the path and the counts.
2. **Ask.**
   - Put proposed features to the user as multi-select "keep which?" questions, up to 4 options each.
   - Ask only the questions that change player-visible behaviour. Decide engineering questions yourself.
   - Ask in the format `/orchestrating-development` sets out: one decision at a time, a Background paragraph that explains every project term in plain words, and options that say what the player would see and what each costs.
   - Before you recommend keeping a proposed feature, check with one grep that the data or server support it needs exists. A scout once marked features "keep" that had no backend at all.
   - Record every answer verbatim in `docs/decisions.md`, along with your defaults.
   - When an answer is a sentence, a refusal or "I don't know what this means", read it literally. Rephrase the question in player terms, or drop the feature.
3. **Light plan.** Dispatch an `implementer` (medium). Give it the questions file, the decisions section, and the model plan to copy (the last good light plan). Required sections:
   - Scope and deferrals (including what was cut).
   - User decisions, quoted verbatim.
   - Contracts per task, named in the project's own layering: the new interfaces, data types, packages or modules, adapters, wiring, routes or commands and config. For a hexagonal project, list them by folder as the `applying-hexagonal-architecture` skill describes. Also units and lock order, new tables, events and jobs, wire and read changes, statement or performance budgets for new units.
   - Tasks: 8–12, each naming its required tests, including multi-replica races for anything several actors write.
   - Gates.
   - Hand-off notes.
   - New terms: the plan writer adds each new name (component, status, wire field, player-visible word) to `docs/terminology.md`.
   - Decisions to confirm, each with a default.

   No code, no SQL, 150–300 lines. If the `unslop` skill is installed, the plan writer passes its draft through it once before finishing (one load, not one per section); say so in the writer's prompt, so the skill loads in its context and not yours. The plan writer reads seams through LSP, grep and `go doc`, never whole files. If another agent is committing in the same checkout, it writes the file without committing, and you commit it with `shared/scripts/commit-only.sh`.
4. **Check against the decisions.** Read the plan's "decisions to confirm". Reject any default that contradicts a binding user decision. One plan once changed "opens automatically" into "a player opens it".
5. **Design review**, only for risky plans: concurrency, money or loot, many-player writes, protocols. Dispatch one `reviewer`. It returns at most 40 lines covering findings by severity (with plan line, problem and fix) and a verdict on each decision. Skip this for plans where each player's data is private.
6. **Revise.** Write the rulings file: the findings plus your decisions. Hand it to a **fresh** `implementer`, which folds each fix into the contract or task it belongs to.
7. **Commit** the plan to `docs/plans/YYYY-MM-DD-<slice>.md` with its terminology lines and the `docs/decisions.md` section, mark it "in progress" in `docs/roadmap.md`, and log its cost in `.agent-work/workflow-metrics.md`.

## Done when

The plan is committed, every user decision is quoted in it verbatim, no cut feature appears in it, and every multi-writer contract has a named test.
