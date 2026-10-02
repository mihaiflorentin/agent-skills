#!/usr/bin/env bash
# Link every skill in this repo into ~/.claude/skills.
#   install.sh        ask before replacing a skill that already exists
#   install.sh -y     replace without asking
# A replaced folder or file is moved to ~/.claude/skills-backup/<name>-<timestamp>, never deleted (outside the skills folder, so Claude never loads the old copy).
# A link that already points at this repo is left as it is.
set -eu
repo=$(cd "$(dirname "$0")" && pwd)
dest=${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}
yes=0
case "${1:-}" in -y|--yes) yes=1 ;; "") ;; *) echo "usage: install.sh [-y]" >&2; exit 2 ;; esac
mkdir -p "$dest"
stamp=$(date +%Y%m%d-%H%M%S)
backup=${CLAUDE_SKILLS_BACKUP_DIR:-$dest-backup}

for dir in "$repo"/*/; do
  name=$(basename "$dir")
  [ -f "$dir/SKILL.md" ] || continue          # shared/ and other non-skill folders
  target="$dest/$name"
  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$dir")" ]; then
    echo "ok       $name (already linked)"
    continue
  fi
  if [ -e "$target" ] || [ -L "$target" ]; then
    if [ $yes -eq 0 ]; then
      if [ ! -t 0 ]; then echo "skip     $name (exists; no terminal to ask, rerun with -y)"; continue; fi
      read -r -p "replace  $name ($target exists)? [y/N] " answer
      case "$answer" in y|Y|yes) ;; *) echo "skip     $name"; continue ;; esac
    fi
    mkdir -p "$backup"
    mv "$target" "$backup/$name-$stamp"
    echo "backup   $name -> $backup/$name-$stamp"
  fi
  ln -s "${dir%/}" "$target"
  echo "linked   $name"
done
