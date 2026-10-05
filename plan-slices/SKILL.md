---
name: plan-slices
description: Turns one roadmap slice into a light implementation plan (no code): question scout, user decisions quoted verbatim, contracts and tests per task, a wave table with lanes and a file ownership table for parallel builds, and a design review for risky plans. Use when the next roadmap item needs a plan, or a plan must be split or revised.
disable-model-invocation: true
---

# Plan workflow

Copy this checklist and tick it off as you go:

```
Plan progress:
- [ ] 1. Question scout file written
- [ ] 2. User answered; answers in docs/decisions.md verbatim
- [ ] 3. Light plan written, with wave table, lanes and file ownership table
- [ ] 4. Plan defaults checked against the user's decisions
- [ ] 5. Design review (risky plans and server lanes touching multi-writer state)
- [ ] 6. Revision by a fresh agent (if reviewed)
- [ ] 7. Plan committed; cost logged (light about 100k–250k, big about 250k–500k)
```

Contents: Steps · Done when

A plan should cost a small fraction of what its build costs. Typical sizes, counting every planning agent (scout, writer, design review, revision). They are reference points, not limits: a plan may come in under or over them.
- **Light plan: about 100k–250k tokens.** Scout around 40k, writer around 120k, revision around 60k; most light plans need no design review.
- **Big plan: about 250k–500k tokens.** For risky plans (concurrency, money, multi-user writes, protocols): scout around 60k, writer around 200k, design review around 120k, revision around 100k.

The light plan fixes the scope, the user's decisions, the contracts between components and the tests each task needs. The implementer designs everything else.

What keeps a plan near those sizes:
- Mention the expected size in each planning agent's prompt, so it scopes its reading to match.
- Ask the questions before the plan is written, so no answer forces a rewrite.
- One revision is usually enough. A plan that needs a second one, or grows far past these sizes, may be two slices: consider splitting it.
- Log every planning agent's tokens in `.agent-work/workflow-metrics.md`, to compare against these sizes.

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
   - Ask only the questions that change user-visible behaviour. Decide engineering questions yourself.
   - Ask in the format `/orchestrate-development` sets out: one decision at a time, a Background paragraph that explains every project term in plain words, and options that say what the user would see and what each costs.
   - Before you recommend keeping a proposed feature, check with one grep that the data or server support it needs exists. A scout once marked features "keep" that had no backend at all.
   - Record every answer verbatim in `docs/decisions.md`, along with your defaults.
   - When an answer is a sentence, a refusal or "I don't know what this means", read it literally. Rephrase the question in user terms, or drop the feature.
3. **Light plan.** Dispatch an `implementer` (medium). Give it the questions file, the decisions section, and the model plan to copy (the last good light plan). Required sections:
   - Scope and deferrals (including what was cut).
   - User decisions, quoted verbatim.
   - Contracts per task, named in the project's own layering: the new interfaces, data types, packages or modules, adapters, wiring, routes or commands and config. For a hexagonal project, list them by folder as the `apply-hexagonal-architecture` skill describes. Also units and lock order, new tables, events and jobs, wire and read changes, statement or performance budgets for new units.
   - Tasks: as many as the feature needs (there is no cap on the count), each naming its required tests, including multi-replica races for anything several actors write.
   - **Wave table:** the tasks grouped into waves. Tasks in one wave are independent of each other. When lanes share types, wave 0 is a tiny "seams and types only" task that defines them.
   - **Lanes:** the tasks cut into lanes of 3–5 tasks each (one implementer's share; the plan has as many lanes as the feature needs), grouped by area (the same files or subsystem) so each agent loads little context. Write each lane as its own section, so every implementer is handed its own plan: its tasks, contracts, files and tests, readable without the other lanes. A big feature simply has more lanes or more waves; run 4–5 lanes at a time. A plan whose tasks all depend on each other has one task per wave; `/implement-plans` then builds it in sequential halves.
   - **File ownership table:** one owner lane for every shared file or resource: size budgets, docs, shared contracts and wire types, generated goldens, statement and performance pins, i18n and name tables, feature flags. Non-owners write "Notes for the merge" in their ledger instead of editing. A shared file with no owner is a plan defect.
   - Gates.
   - Hand-off notes.
   - New terms: the plan writer adds each new name (component, status, wire field, user-visible word) to `docs/terminology.md`.
   - Decisions to confirm, each with a default.

   No code, no SQL; as long as the feature needs. If the `unslop` skill is installed, the plan writer passes its draft through it once before finishing (one load, not one per section); say so in the writer's prompt, so the skill loads in its context and not yours. The plan writer reads seams through LSP, grep and `go doc`, never whole files. If another agent is committing in the same checkout, it writes the file without committing, and you commit it with `shared/scripts/commit-only.sh`.
4. **Check against the decisions.** Read the plan's "decisions to confirm". Reject any default that contradicts a binding user decision. One plan once changed "opens automatically" into "a user opens it".
5. **Design review**, for risky plans: concurrency, money or rewards, concurrent multi-user writes, protocols. Server lanes that touch multi-writer state always get one before the build: on a trial it found 4 serious bugs before any code existed. Dispatch one `reviewer`. It returns at most 40 lines covering findings by severity (with plan line, problem and fix) and a verdict on each decision. Skip this for plans where each user's data is private.
6. **Revise.** Write the rulings file: the findings plus your decisions. Hand it to a **fresh** `implementer`, which folds each fix into the contract or task it belongs to.
7. **Commit** the plan to `docs/plans/YYYY-MM-DD-<slice>.md` with its terminology lines and the `docs/decisions.md` section, mark it "in progress" in `docs/roadmap.md`, and log its cost in `.agent-work/workflow-metrics.md`.

## Done when

The plan is committed, every user decision is quoted in it verbatim, no cut feature appears in it, every multi-writer contract has a named test, and every shared file has one owner lane.
