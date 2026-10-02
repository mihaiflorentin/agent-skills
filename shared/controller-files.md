# Controller files

The controller keeps four files in `.agent-work/` at the project root, a scratch directory listed in `.gitignore` and never committed. They outlive compaction: after a `/compact` or a new session, read them first and trust them, together with `git log`, over your own recollection.

| File | What it holds | Written when |
|---|---|---|
| `STATE.md` | A RESUME block: the plans that are done, the agents that are running (id, worktree, what each ends with), and what comes next. | After every plan boundary, merge or dispatch. Add an `UPDATE n` line; never rewrite history. |
| `briefing.md` | Every user decision, verbatim and dated, one section per plan. Controller defaults and rulings sit beside them, marked as the controller's. | The moment the user answers. Quote the exact answer text. |
| `workflow-metrics.md` | One row per plan stage: tokens, tool calls, hours, tokens per task, and what the gate needed. | When each agent reports. These rows are the evidence for every workflow change. |
| `plans-run/<plan>/progress.md` | The implementer's ledger: one line per task with its commits and deviations, plus a HAND-OFF section. | Written by the implementer, read by the next implementer and the reviewer. |

Rules:

- **Verbatim decisions.** Briefings quote the user's answer, not a paraphrase. Plans copy the quote, and reviewers check against the quote.
- **Distinguish proposals from decisions.** A spec feature that the user never decided is a proposal, even when the spec states it confidently. The plan workflow surfaces proposals as keep/cut questions.
- **Compact at plan boundaries.** The controller's context is re-read on every agent notification. Suggest `/compact` to the user once a plan merges and `STATE.md` is current.
