# agent-skills

Claude Code skills for building software with subagents. You make the product decisions; agents write the specs, plans and code, run the tests and do the reviews. The workflow is tuned for token cost: on the project it came from, a whole server plan went from 2.7–4.4M tokens to 1.3–1.9M with the same review findings.

## Contents
- The skills, in order
- What each one asks of you
- A typical session
- Files the workflow keeps
- Architecture
- Shared material
- Install
- Test profiles
- Rules of thumb that came from real failures
- Authoring notes

## The skills, in order

| # | Skill | When you use it | What you get |
|---|---|---|---|
| 0 | `/orchestrating-development` | At the start of every session and after a `/compact` | The controller loop: resume from the state files, pick the next plan, run stages 2–5 |
| 1 | `/writing-specs` | Once per new area of the product, before any plan touches it | An approved spec in which every feature is marked `[USER]`, `[PROPOSED]` or `[DEFAULT]` |
| 2 | `/planning-slices` | Once per roadmap slice (a "plan") | A committed light plan, 150–300 lines, quoting your decisions verbatim |
| 3 | `/implementing-plans` | Right after the plan is committed | Every task built and committed in two halves, full gate green |
| 4 | `/testing-changes` | Reference, used during stage 3 and before merges | The test cadence, how to wait on long runs, flaky-test triage, screenshot review |
| 5 | `/reviewing-plans` | Right after the build's gate is green | Review findings fixed, gate green again, open items logged |
| – | `/unslop` | Whenever prose is written for people | Specs, plans, docs and messages without AI writing patterns |
| – | `/applying-hexagonal-architecture` | Only in projects on the hexagonal layout | The layout, service-container rules and layer check the other skills apply there |

Then merge, update the state files, `/compact`, and start the next plan at stage 2.

```
/writing-specs          (once per new area)
      │
      ▼
┌─► /planning-slices ──► /implementing-plans ──► /reviewing-plans ──► merge + /compact ─┐
│                         (uses /testing-changes)                                       │
└─────────────────────────────────── next plan ───────────────────────────────────────┘
```

## What each one asks of you

- **`/writing-specs`.** You answer product questions in batches of up to 4. You then go through every agent-proposed feature and choose keep or cut. Last, you approve the written spec.
- **`/planning-slices`.** You answer up to about 8 questions per plan, mostly keep/cut on proposed features plus the gameplay choices the spec leaves open. Engineering questions are decided for you and logged.
- **`/implementing-plans`.** Nothing, unless an agent reports a concern that needs a product decision. For UI work, the controller checks the screenshots before they are committed.
- **`/testing-changes`.** Nothing. It is the agents' and the controller's reference.
- **`/reviewing-plans`.** Sometimes one question, when a finding turns out to be a product choice (for example "10% of max or of missing?").

When you are away, the controller decides with a recommended default, logs it in `docs/decisions.md` as its own ruling, and keeps going. You can overrule it later.

## A typical session

1. Run `/orchestrating-development`. The controller reads `.agent-work/STATE.md`, says where things stand, and starts the next plan.
2. Answer the plan's questions when they appear.
3. Wait. The controller replies with one short line per agent notification. A plan takes a few hours of wall clock: the build in two halves, then the review and fixes.
4. When a plan merges, the controller suggests `/compact`. Run it, because the controller's context is re-read on every notification.
5. Repeat.

## Files the workflow keeps

Committed in `docs/`, so every device and teammate has them:
- **`docs/terminology.md`:** every business and technical term in plain words. Agents add a term in the commit that introduces it.
- **`docs/decisions.md`:** every decision you made, verbatim and dated, plus the controller's rulings, marked as such.
- **`docs/roadmap.md`:** the plans in order, with status and what you can try when each lands.
- **`docs/specs/`, `docs/plans/`:** the specs and plans.

Local in `.agent-work/` (git-ignored), because they belong to one machine and one session: `STATE.md` (the resume point), `workflow-metrics.md`, the implementers' progress ledgers, question files, review packages and rulings, screenshots waiting for review, and logs.

`shared/scripts/init-project.sh` creates this layout in a new project. `shared/project-files.md` has the details: the layout, what to commit, and who maintains each file.

## Architecture

The workflow skills are architecture-neutral: specs, plans, builds and reviews follow whatever the project's AGENTS.md or CLAUDE.md and existing layout say.

For projects on the hexagonal (ports and adapters) layout (`main.go`, `cmd/`, `config/`, `container/`, `domain/`, `infrastructure/`, `port/{contract,dto,mock}`), there is a separate skill, `/applying-hexagonal-architecture`. It covers the folder roles, the lazy service container and its eight rules, the new-dependency checklist, and a sample `layers.rules` with `applying-hexagonal-architecture/scripts/check-layers.sh`, the import checker. When a project uses that layout, the workflow skills apply it:
- specs name the ports;
- plans list contracts by folder;
- implementers build `port/` → `domain/` → `infrastructure/` → `config/` → `container/` → `cmd/`;
- reviewers run `check-layers.sh` and check the container rules.

Other projects never load it.

## Shared material

- **`shared/agent-rules.md`:** the rule blocks the controller pastes into every subagent prompt. It covers which model to use, token and tool-call discipline, waiting on long runs, test cadence, commits, scope, hand-off and the short return format. Edit this file to change how every agent behaves.
- **`shared/scripts/`:**

| Script | Does |
|---|---|
| `run-logged.sh LOG -- cmd` | Runs a long command into a log that ends with `EXIT n`, then prints only the failure lines. Use it with background runs. |
| `failures.sh LOG` | Prints the exit line and the failure lines of any log. |
| `review-package.sh BASE [HEAD] [DIR]` | Writes `code.diff` (no tests or generated files), `tests.stat` and `commits.txt` for a reviewer. |
| `commit-only.sh MSG PATH…` | Commits exactly those paths, safe while another agent is committing in the same checkout. |
| `contact-sheet.py OUT IMG…` | Tiles screenshots into one image for visual review (needs Pillow). |
| `stale-waits.sh` | Lists `tail -f` or sleep waits older than 10 minutes, with the last line of the log each one watches. |

## Install

```bash
./install.sh       # links every skill into ~/.claude/skills, asking before it replaces one that exists
./install.sh -y    # replaces without asking
```

A replaced skill is moved to `~/.claude/skills-backup/<name>-<timestamp>`, never deleted, and outside the skills folder so Claude never loads the old copy. A link that already points at this repo is left alone, so the script is safe to rerun after adding a skill.

The skills are user-invoked (`disable-model-invocation: true`), so they cost no context until you type one. They point at `shared/` by absolute path: keep this folder where it is, or update those paths if you move it.

Assumed agent types in `~/.claude/agents`:
- `scout`: cheap lookups.
- `implementer`: Sonnet 5.5 medium, the default.
- `implementer-high`: Sonnet 5.5 high, for hard UI work or concurrency.
- `reviewer`: read-only.
- `engineer` and `architect`: Opus, for escalation.

Nothing runs below Sonnet 5.5. Opus is for graphical assets, audio, and work a Sonnet attempt already failed.

## Test profiles

`/testing-changes` has two cadences. Time the full gate once per project and record the profile in `.agent-work/STATE.md`:
- **Fast** (gate up to about 3 minutes, e2e up to about 5): test first, full gate before every commit. This is the usual recommended practice.
- **Slow** (longer gates, shared databases or browsers): targeted checks per commit, one full gate per plan. This is the token-optimised cadence built on a game project, where a full gate plus e2e took 1–2 hours.

## Rules of thumb that came from real failures

| Rule | The failure behind it |
|---|---|
| Ask questions before writing a plan. | Answers that arrived after the plan was written forced two full rewrites, about 3M tokens. |
| Tag spec features by provenance. | Daily quests reached a plan that the user had never discussed. |
| Hand off at about 500k tokens or 6 tasks. | One agent carrying 12 tasks grew to 950k tokens and 5.5 h. |
| Never wait with `tail -f \| grep`. | A wait hung for 56 minutes after its test run had finished. |
| Never run a server plan and a UI plan at the same time. | The machine load made perf tests flake, and the reruns cost more than the parallelism saved. |
| Check the plan's open decisions against the user's answers. | A plan turned "opens automatically" into "a player opens it". |
| Make every commit build. | Two commits at medium effort didn't build, or cut a function short. |
| Keep the review, scoped. | It found 1–5 real Important bugs per plan whatever the plan style was. |

## Authoring notes

These skills follow Anthropic's skill-authoring best practices (platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices):
- Every description is in the third person and says what the skill does and when to use it. Claude picks a skill from its name and description alone; the body loads only after it is chosen.
- Each SKILL.md stays far under 500 lines. Shared detail (`shared/agent-rules.md`, `shared/project-files.md`) is linked directly from SKILL.md, one level deep.
- Each workflow opens with a copyable progress checklist and a contents line. Any file over 100 lines starts with a contents list, because Claude sometimes previews a file with a partial read (`head -100`).
- References to other skills are steps inside a stage, never standing rules. Each names the context it loads in (usually a subagent's) and what happens when that skill isn't installed. A skill's body loads only when a step uses it, so a reference costs nothing until then. Each reference also says to load the skill once per context: after the first load its rules are already in context and can be applied without loading it again.
- No path on the author's machine. Inside a skill, paths are relative to the skill's folder; each skill that uses `shared/` has a `shared` link to it, and other skills are found in `~/.claude/skills/<name>/`. The controller writes full paths into subagent prompts.
- Scripts are run, not read. Each one documents its usage in its header.
- Names use the recommended gerund form (`writing-specs`, `planning-slices` …).
