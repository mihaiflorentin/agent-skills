# Lane rules (template)

Copy this file to `.agent-work/plans-run/<plan>/lane-rules.md`, fill in the bracketed parts once per plan, and point every lane's dispatch prompt at it. The prompt then needs only the lane name, its worktree, its task numbers and the plan path. A lane agent cannot see the controller's conversation, so everything it needs is here or in the files named here.

Contents: Read first · Ownership · Tests · Token discipline · Commits · Ledger · Hand-off · Return contract

## Read first

Your lane holds 3–5 tasks of one area (the same files or subsystem), so load only that area's context.

Read only these, in this order, and only the parts that matter to your tasks:
1. The plan: your tasks, the decisions section (binding), the wave table, the file ownership table.
2. [the project's AGENTS.md or CLAUDE.md sections for the areas you touch]
3. `docs/terminology.md`: use its names.
4. [the architecture rules, if the project has them]
5. [the seam files wave 0 created]

## Ownership

- Work only in your own worktree and on your own branch.
- Edit only the files your lane owns, as the plan's file ownership table says. Shared files (size budgets, docs, shared contracts and wire types, generated goldens, statement and performance pins, i18n and name tables, feature flags) each have one owner lane.
- For a shared file you do not own, do not edit it. Write what the owner or the merge agent must change, with file, name and exact value, under "Notes for the merge" in your ledger.
- If your task cannot be done without breaking this rule, stop that task, record it in the ledger and go on to the next.

## Tests

- Run only fast tests, each under a minute: the touched packages or specs, plus the type and format checks.
- Never run the full gate, the browser or e2e suites, the database or multi-replica suites, or simulations. Record each test you skipped for that reason under "Owed to the tester".
- Write the test with the change. A test pins the server contract, so check it against the code or the spec it exercises: a wrong test can pin a wrong command.
- Run each task's tests once the change is complete, then again only after a fix.

## Token discipline

Every tool call re-reads your whole context, so cost is calls times context size.
- Send test and build output to a file; read only the failure lines and the last 5 lines.
- Locate code with symbol lookup and grep plus a line-range read. Never read a large file whole.
- Batch independent reads in one message. Chain shell steps in one command.
- Never re-read a file to check an edit you just made.
- Never wait with `sleep`, `tail -f` or `pgrep` loops. Run long commands in the background and wait for the notice, or make one blocking call.
- Finish every task of your lane, each with its tests. Never leave a task or a test as owed work. If your context gets long, hand off (below) and a fresh agent finishes the lane.

## Commits

- Conventional style, one logical change per commit, explicit `git add <paths>`.
- Every commit builds: chain the build or type check before `git commit`.
- Never amend, never push, never use a bare `git stash`, never commit `.agent-work/`.
- End messages with the project's attribution lines, if it has them.
- A new business or technical term goes into `docs/terminology.md` in the commit that introduces it, unless that file is owned by another lane (then use a note for the merge).

## Ledger

Keep `.agent-work/plans-run/<plan>/lane-<x>.md`, one line per task with its commit hash, then:
- **Deviations:** anything you did differently from the plan, and why.
- **Notes for the merge:** edits owed to files you do not own, or steps the merge agent must do (regenerate a golden, bump a size budget).
- **Owed to the tester:** tests and checks you did not run because of the under-a-minute rule.

## Hand-off

When your context gets long (around 450k tokens), stop after a committed task and write a HAND-OFF section in your ledger: the seams, the gotchas and the tasks still to do. A fresh agent continues from it and finishes the lane.

## Return contract

Return at most 5–10 lines: one line per task with its commit, the ledger path, and any concern. The full report is the ledger. Every line you return stays in the controller's context for the rest of the session.

## Never trigger a permission prompt

Nobody may be awake to answer it, and a waiting agent blocks its lane for hours.
- Use absolute paths and `git -C`, `go -C`, `npm --prefix`, `make -C` instead of `cd <dir> && …` compounds.
- Write commit messages to a file and commit with `-F <file>`; avoid multi-line `-m`.
- Create files with the editor tools, not shell heredocs.
- Stay inside your worktree and the scratch folder; never write to `.git/`, `.claude/` or home dotfiles.
- A refused or blocked command is logged and skipped, never retried or waited on.
