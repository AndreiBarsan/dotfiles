#!/usr/bin/env bash
# Script that gets run nightly after installed by crontab.

set -euo pipefail
IFS=$'\n\t'

#
# Ensure sensible environment vars are set, since cron doesn't load .zshrc / .bashrc (non-interactive shell).
# 
export USER=andreib
export PATH=$HOME/.local/bin:$HOME/.local/mini_tools:$PATH:/usr/games/

echo "Starting nightly cron: $(date)"

notify_error () {
  notify "Error running nightly cron job at $(date)." "Cron failed at $(date). Check log for details."
}
trap notify_error ERR

# Use rsync to back up my home directory to another drive.
backup_home || echo "Could not back up homedir!"

# Only try to rebuild work code on the work computer. ;)
# if hash rebuild_my_code >&2; then
  # echo "$(date)"
  # echo "Will rebuild your code..."
  # build=true
  # build_output="/tmp/build_log_$RANDOM.log"
  # (time rebuild_my_code no-2fa | tee $build_output) || echo "Could not rebuild code. Check log for details."
# else
build=false
echo "SKIPPING AV CODE REBUILD"
# fi

build_output=""
if hash refresh_my_code >&2; then
  date
  echo "Will refresh your code..."
  build_output="/tmp/refresh_log_$RANDOM.log"
  (time refresh_my_code no-2fa | tee $build_output) || echo "Could not rebuild code. Check log for details."
fi

#
# Report the status of the jobs.
#
echo "Nightly finished OK at $(date)."

body="More info in logs.<br/>"

if $build; then
  body="$body Built code OK!<br/>$(tail -n 20 <$build_output)"
else
  body="$body Code was not built.<br/>"
fi

body="$body<br/><hr/><blockquote>$(fortune)</blockquote>"

notify "Nightly cron job ran OK at $(date)." "$body"
