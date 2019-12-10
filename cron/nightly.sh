#!/usr/bin/env bash
# Script that gets run nightly after installed by crontab.

set -euo pipefail
IFS=$'\n\t'

#
# Ensure sensible environment vars are set, since cron doesn't load .zshrc / .bashrc (non-interactive shell).
# 
export USER=andreib
export PATH=$HOME/.local/bin:$HOME/.local/mini_tools:$PATH

echo "Starting nightly cron: $(date)"

notify_error () {
  notify "Error running nightly cron job at $(date)." "Cron failed at $(date). Check log for details."
}
trap notify_error ERR

# Use rsync to back up my home directory to another drive.
backup_home || echo "Could not back up homedir!"

# Only try to rebuild work code on the work computer. ;)
if hash rebuild_my_code >&2; then
  echo "$(date)"
  echo "Will rebuild your code..."
  build=true
  build_output="/tmp/av_build_log_$RANDOM.log"
  (time rebuild_my_code no-2fa | tee $build_output) || echo "Could not rebuild code. Check log for details."
else
  build=false
  echo "SKIPPING CODE REBUILD"
fi

#
# Report the status of the jobs.
#
echo "Nightly finished OK at $(date)."

if $build; then
  body="More info in logs. Built code OK!<br/>$(cat $build_output | tail -n 20)"
else
  body="More info in logs. Code was not built."
fi

notify "Nightly cron job ran OK at $(date)." "$body"
