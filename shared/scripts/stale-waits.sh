#!/usr/bin/env bash
# List long-running wait processes that may be stuck (tail -f, sleep loops), with their age and the log they watch.
# A tail -f on a log whose last line is "EXIT n" is stuck by construction: kill it.
ps -eo pid,etimes,cmd --sort=-etimes | awk '$2>600 && /tail -f|sleep [0-9]|pgrep -f/ && !/awk/' | while read -r pid secs cmd; do
  log=$(sed -nE 's/.*tail -f( -n ?[0-9]+)? ([^ |]+).*/\2/p' <<<"$cmd")
  last=$([ -n "$log" ] && [ -f "$log" ] && tail -1 "$log")
  printf '%s\t%ss\t%s\t%s\n' "$pid" "$secs" "${last:-?}" "${cmd:0:120}"
done
