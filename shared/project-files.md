# Project files

## Contents
- Layout
- What to commit, and what not to
- docs/terminology.md
- docs/decisions.md
- docs/roadmap.md
- .agent-work/ (local only)
- Setting up a new project

Every session, compacted or fresh, and every device starts from the same files. The rule for choosing where a file lives: **commit what another device or a teammate needs to continue the work. Keep local what belongs to one machine or one session.**

## Layout

```
AGENTS.md                         entry point for every agent: project map, rules, and a pointer to each file below
docs/
  terminology.md                  every business and technical term, in plain words      (commit)
  decisions.md                    the user's decisions, verbatim and dated               (commit)
  roadmap.md                      the plans in order, each with its status and spec      (commit)
  specs/YYYY-MM-DD-<area>.md      design specs                                           (commit)
  plans/YYYY-MM-DD-<slice>.md     implementation plans                                   (commit)
.agent-work/                      git-ignored scratch, one machine only                  (never commit)
  STATE.md                        resume point: running agents, the next step
  workflow-metrics.md             tokens, tool calls and hours per stage
  plans-run/<plan>/progress.md    the implementers' ledger and HAND-OFF section
  questions/<plan>.md             the question scout's output
  reviews/<plan>/                 review package (code.diff, tests.stat, commits.txt) and rulings.md
  shots/<plan>/{before,after}/    screenshots waiting for review
  logs/                           run-logged.sh output
```

If the project already keeps specs and plans somewhere else, use that location and write it into `AGENTS.md`. Don't move existing files just to match this layout.

## What to commit, and what not to

| Commit (in `docs/`) | Never commit (in `.agent-work/`) |
|---|---|
| Terminology, decisions, roadmap, specs, plans | `STATE.md`: running agent ids are meaningless on another machine |
| Changes to `AGENTS.md` that a new rule or file needs | Progress ledgers, review packages, rulings, question files |
| Approved screenshot baselines (as the project stores them) | Screenshots still waiting for review, logs, metrics |

- Commit docs in their own `docs:` commits with explicit paths, never mixed into a code commit (unless a code change renames a term; then the terminology line goes in that same commit).
- A rule that every agent must follow belongs in `AGENTS.md` (committed), not in `STATE.md`.
- When a plan merges, move whatever is still worth keeping out of `.agent-work/`: a decision goes to `docs/decisions.md`, a deferred feature goes to `docs/roadmap.md`, and a new term goes to `docs/terminology.md`.

## docs/terminology.md

This is the project's glossary: every business term (product or domain words, such as "invoice run" or "billing run") and every technical term a newcomer would trip over (a wire field, an internal component, a cadence name). It has two uses. Agents keep names consistent with it, and the controller uses it when it explains a question to the user in plain words.

Format: a short contents list, then two alphabetical tables.

```
## Business terms
| Term | Meaning in plain words | Where it lives |
|---|---|---|
| Billing run | The nightly job that charges every subscription due that day. | billing/, docs/specs/…-billing.md |

## Technical terms
| Term | Meaning in plain words | Where it lives |
|---|---|---|
| gate | The project's full check (`make check`); it must pass before a plan is done. | Makefile |
```

Who maintains it:
- **Spec writer:** adds every new term the spec introduces, before the user reads the spec.
- **Plan writer:** adds the terms the plan introduces (new components, wire fields, statuses).
- **Implementer:** adds a term in the same commit that introduces the name in code or UI, and updates its line when a rename lands.
- **Reviewer:** reports a new user-visible or cross-module name that is missing from the file, as a Minor finding.
- **Controller:** reads it before asking the user a question, and explains every term the question uses.

Keep each meaning to one line. One term has one name. When two words mean the same thing, pick one and list the other as "see X".

## docs/decisions.md

Every decision the user made, quoted verbatim and dated, in one section per plan or topic. Controller rulings made while the user was away sit beside them, marked `[controller]`, until the user confirms or overrules them. Plans quote this file, and reviewers check against the quotes. Never paraphrase an answer.

## docs/roadmap.md

The plans in build order, one line each: name, status (planned, in progress, done or deferred), spec, plan file, and what the user can try once it lands. Deferred and cut features are listed with the decision that deferred or cut them.

## .agent-work/ (local only)

- **`STATE.md`:** a RESUME block with what is done, which agents are running (id, worktree, what each ends with) and what comes next. Add an `UPDATE n` line after each plan boundary, merge or dispatch; never rewrite earlier lines. After a `/compact` or a new session, read it first and trust it, together with `git log`, over your own recollection.
- **`workflow-metrics.md`:** one row per plan stage (tokens, tool calls, hours, what the gate needed). These rows are the evidence for every workflow change.
- **`plans-run/<plan>/progress.md`:** the implementer's ledger, one line per task with its commits and deviations, plus a HAND-OFF section for the next implementer and the reviewer.
- **Compact at plan boundaries.** The controller's context is re-read on every agent notification. Suggest `/compact` once a plan merges and `STATE.md` is current.

## Setting up a new project

Run `shared/scripts/init-project.sh` from the project root. It creates the layout above and adds `.agent-work/` to `.gitignore`. It never overwrites a file that already exists. Then make sure `AGENTS.md` (or `CLAUDE.md`) points at `docs/terminology.md`, `docs/decisions.md` and `docs/roadmap.md`, and commit the result as `docs: agent workflow layout`.
