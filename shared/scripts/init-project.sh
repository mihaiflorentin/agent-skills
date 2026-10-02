#!/usr/bin/env bash
# Create the agent workflow layout in the current project (see shared/project-files.md).
#   init-project.sh            run from the project root
# Never overwrites an existing file. Safe to rerun: it only adds what is missing.
set -eu
root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not inside a git repository" >&2; exit 2; }
cd "$root"

made() { echo "created  $1"; }
mkdir -p docs/specs docs/plans .agent-work/plans-run .agent-work/questions .agent-work/reviews .agent-work/shots .agent-work/logs

new_file() { # path, content
  if [ -e "$1" ]; then echo "kept     $1"; else printf '%s\n' "$2" > "$1"; made "$1"; fi
}

new_file docs/terminology.md '# Terminology

Every business and technical term of this project, in plain words. One term, one name, one line.

## Contents
- Business terms
- Technical terms

## Business terms
| Term | Meaning in plain words | Where it lives |
|---|---|---|

## Technical terms
| Term | Meaning in plain words | Where it lives |
|---|---|---|'

new_file docs/decisions.md '# Decisions

The user'"'"'s decisions, quoted verbatim and dated, one section per plan or topic.
Controller rulings made while the user was away are marked [controller] until the user confirms or overrules them.'

new_file docs/roadmap.md '# Roadmap

| # | Plan | Status | Spec | Plan file | What you can try when it lands |
|---|---|---|---|---|---|'

new_file .agent-work/STATE.md '# State

RESUME: nothing running yet. Next: pick the first plan from docs/roadmap.md.'

new_file .agent-work/workflow-metrics.md '| Plan | Stage | Agent | Tokens | Tool calls | Hours | Notes |
|---|---|---|---|---|---|---|'

touch docs/specs/.keep docs/plans/.keep

if [ -f .gitignore ] && grep -qxF '.agent-work/' .gitignore; then
  echo "kept     .gitignore (.agent-work/ already ignored)"
else
  printf '\n# agent workflow scratch (local only)\n.agent-work/\n' >> .gitignore
  echo "updated  .gitignore"
fi

guide=AGENTS.md; [ -f AGENTS.md ] || { [ -f CLAUDE.md ] && guide=CLAUDE.md; }
if [ -f "$guide" ] && grep -q 'docs/terminology.md' "$guide"; then
  echo "kept     $guide (already points at docs/)"
else
  printf '\n## Project memory\n\n- `docs/terminology.md`: every business and technical term in plain words. Add a term in the commit that introduces it.\n- `docs/decisions.md`: the user'"'"'s decisions, verbatim. Plans quote it.\n- `docs/roadmap.md`: the plans in order, with their status.\n- `docs/specs/`, `docs/plans/`: specs and plans.\n- `.agent-work/`: local scratch (state, ledgers, reviews, logs). Never commit it.\n' >> "$guide"
  echo "updated  $guide"
fi
echo "next: review the changes, then commit docs/, .gitignore and $guide"
