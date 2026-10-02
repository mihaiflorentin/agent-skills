# Agent rules

Paste the relevant blocks into every subagent prompt, with every script path written out in full (a subagent does not know where the skills are installed). A subagent cannot see the controller's conversation, so these rules reach it only through the prompt. Keep the block wording stable across prompts: the same words recruit the same behaviour every run.

## Models

- Nothing below Sonnet 5.5. Use `implementer` (Sonnet medium) by default, including ordinary UI work. Use `implementer-high` only for genuinely hard UI/3D work or subtle concurrency. Use `reviewer` for reviews and `scout` for cheap lookups.
- Use Opus 5.5 only for graphical assets (3D, VFX, art), audio, and work a Sonnet attempt already failed.
- Never pass `model: "sonnet"`: that alias can resolve to an older model. Use the pinned agent types.

## Token and tool-call discipline (every agent)

Every tool call re-reads the agent's whole context, so the cost is about calls × context size.

- **Logs, not output.** Send test and build output to a file. Read only `grep -E 'FAIL|panic|DATA RACE|Error|×'` plus `tail -5`.
- **Slices, not files.** Locate code with LSP (definition, references, hover) first, then grep plus a line-range read. Never read a whole large file.
- **Batch.** Send independent reads and lookups as parallel calls in one message. Chain shell steps in one command.
- **Trust the edit.** Never re-read a file to check an edit you just made.
- **Test once.** Run a task's tests once its change is complete, then again only after a fix.
- **One edit.** Make one larger edit, or a section rewrite, instead of many small edits to the same file.

## Waiting on long runs

- Start long jobs (full gates, e2e, simulations) with `run_in_background` and wait for the completion notice. Otherwise make one blocking call with timeout 600000.
- Wrap the command in `shared/scripts/run-logged.sh` so the log ends in an `EXIT <code>` line.
- **Never** wait with `tail -f LOG | grep -m1 X`. tail exits only on its next write, so once the log stops growing the wait hangs forever. Never use sleep or `pgrep` loops either.

## Gate cadence

Paste the block for the project's profile (from `/testing-changes`, recorded in `STATE.md`).

**Fast profile** (full gate up to about 3 minutes):
- Write the failing test first and watch it fail, then make it pass.
- Run the full gate before every commit; commit only when it is green.
- UI tasks run the touched e2e specs, and the whole suite if it takes 5 minutes or less.

**Slow profile** (longer gates):
- **Per commit:** only targeted checks. That means the touched packages (plus importers of a changed shared type) with the race detector, vet, a format check and the type check.
- **The full gate** (`make check` or the project's equivalent) runs once, after the whole plan or plan half is built. Fix and rerun it until it passes.
- **Full e2e** runs only in the final gate of a UI plan. During the build, run only the e2e specs for the touched area.

**Both profiles:**
- **Flaky tests:** rerun a failure alone before you treat it as real. If it passes alone, fix the root cause (wait on state, not on ticks or wall clock) instead of retrying.

## Commits

- Use conventional style, one logical change per commit, with an explicit `git add <paths>`.
- **Every commit builds.** Chain the build (`go build ./...`, `tsc --noEmit`) before `git commit`.
- Never amend, never push, never use a bare `git stash`, and never commit controller scratch (`.agent-work/`).
- When another agent commits in the same checkout, write files only and let the controller commit with `git commit -m … -- <paths>`. See `scripts/commit-only.sh`.
- End messages with the project's attribution lines.

## Architecture

- Follow the project's own architecture rules (its AGENTS.md/CLAUDE.md, existing layout). Only if the project uses the hexagonal layout, paste the rules from the `applying-hexagonal-architecture` skill ("Rules agents follow").

## Scope

- Build only what the plan and the user's decisions name. If a gameplay or product question is genuinely open, take the option closest to the plan, log it as a deviation and continue.
- Subagents never dispatch subagents and never retry a refused permission.
- **Hand-off.** At about 500k tokens, or after 6 tasks, stop after a committed task. Write a HAND-OFF section in the progress file covering the seams, the gotchas and the work still owed. A fresh agent continues from there, because a subagent's context cannot be compacted.

## Return contract

Agents return at most 5–10 lines: one line per task or finding with its commit, the gate exit code, and concerns. The full report goes in a file. Every line an agent returns stays in the controller's context for the rest of the session.
