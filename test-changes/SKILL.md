---
name: test-changes
description: Sets the test cadence for agent-built work: targeted checks per commit, one full gate per plan, background runs with run-logged.sh, flaky-test triage and screenshot-baseline review. Use when choosing what to run, waiting on a long test run, handling a flaky failure, or reviewing new e2e baselines.
disable-model-invocation: true
---

# Test workflow

Contents: Pick a profile · Cadence: Fast profile · Cadence: Slow profile · The tester (parallel lanes) · Long runs · Flaky tests · Screenshot baselines

The **gate** is the project's full check (for example `make check`, or `npm test && npm run lint`). The **pre-merge gate** adds whatever runs before a merge (image builds, container checks). How often to run them depends on how long they take, so pick a profile first.

## Pick a profile

Time the project's full gate once, from a warm cache, and record the profile in `.agent-work/STATE.md`. Re-time it when the suite grows a lot.

| Profile | Use when | Why |
|---|---|---|
| **Fast** | The full gate takes up to about 3 minutes, and the e2e suite (if any) up to about 5 | Running everything is cheap, so run it often. A break shows up in the task that caused it, and nobody has to bisect it later. |
| **Slow** | The full gate takes longer, or needs shared infrastructure (databases, browsers, simulations) | Every run costs agent turns spent waiting, plus reruns of flaky load-sensitive tests. Run the full gate once per plan, and rely on targeted checks and the review in between. |

A project can mix them per suite. For example, fast unit tests and a slow browser suite: use Fast for the unit gate and Slow for the e2e suite.

## Cadence: Fast profile

This is the recommended practice for most projects.

| When | Run |
|---|---|
| Each task | Test first. Write the failing test, watch it fail for the expected reason, write the code, and watch it pass. |
| Before each commit | The full gate, run as one blocking call. A commit goes in only when the gate is green. |
| UI task | The e2e specs of the touched area. The whole e2e suite too, if it fits the 5-minute budget. |
| End of plan | The full gate plus the full e2e suite once more, on the final commit. |
| After review fixes | The full gate after each fix. |
| Before a merge | The pre-merge gate. |

## Cadence: Slow profile

This is token-optimised for long gates, as used on one project, where `make check` plus e2e took 1–2 hours. Running the gate once per plan instead of once per task saved most of the waiting and the reruns, and caught no fewer bugs.

| When | Run |
|---|---|
| Each commit | The touched packages with the race detector, plus vet, format and type checks. Add the importers of any changed shared type or SQL. |
| UI task | The e2e specs of the touched area only. |
| End of plan (or end of its last half) | The full gate, fixed and rerun until it passes. For UI plans, the full e2e suite as well. |
| After review fixes | The full gate once. |
| Before a merge | The pre-merge gate (gate plus image or container checks). Regenerate generated files rather than hand-resolving their conflicts. |

## The tester (parallel lanes)

When a plan was built as parallel lanes, lanes run only fast tests (under a minute each), so the slow gates move to one place: ONE tester agent, after the merge, the one review and the fixers.
- It reads the combined owed-to-tester list and runs the full gate and the full browser suite (the Slow profile's end-of-plan run), in the background with `run-logged.sh`.
- Specs that advance shared clocks or other global state run last, or on a fresh server.
- On a failure it reruns that test alone before treating it as real. Under heavy parallel load, load-sensitive tests flake; a pass alone is a flake, to be fixed at the root.
- A real failure goes back to the fixer that owns that area (`/review-changes`) with the log path. The tester and the fixers loop until green. Only then does the work merge to the working branch and get pushed. Nothing reaches it lane by lane.

## Long runs

These apply in both profiles whenever a run takes more than about 2 minutes.


- Start them with `shared/scripts/run-logged.sh LOG -- <cmd>` under `run_in_background`, and wait for the notice. The log ends in `EXIT n`, and the script prints only the failure lines. Otherwise, make one blocking call with timeout 600000.
- Never wait with `tail -f | grep`, sleep or `pgrep` loops. A `tail -f` hung for 56 minutes after its run had finished, and another such wait hung for 5 hours. If something seems stuck, run `shared/scripts/stale-waits.sh`.
- A duplicate waiter on a run that is still going is harmless. Report it rather than killing it, and kill a process only when it is stuck (its log already ends in `EXIT n`) or orphaned.
- A stray `&` inside a foreground command leaves an orphaned run with no completion notice. Kill it and restart it properly.
- On a 16-thread machine, heavy integration suites flake under `-j16`. If the gate fails only on load-sensitive tests, rerun with `-j4` before investigating.

## Flaky tests

1. Rerun the failing test alone, a few times (`-count=5`, or vitest three times).
2. If it passes alone, it is a flake. Fix the root cause:
   - wait on state, not on ticks or wall-clock budgets;
   - guard shared test hooks with a mutex;
   - put perf assertions behind an env flag such as `PERF=1`.
3. Each merge exposed one more flake. A dedicated "fix every known flake" task paid for itself at once.

## Screenshot baselines

1. The implementer regenerates baselines without committing them (Playwright: `--update-snapshots=changed`, or `=all` when a change falls under the tolerance). Copies go to `.agent-work/shots/<plan>/{before,after}`, and the implementer STOPS.
2. Build one contact sheet per review: `shared/scripts/contact-sheet.py sheet.png --cols 2 before1 after1 …`. Read the sheet, not each image.
3. Check for overlapping or garbled text, cropping, missing objects and broken colours. A visual defect becomes a review finding, and its fix regenerates the baselines for another look.
4. Commit the baselines yourself after the images pass.
