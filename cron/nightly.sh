#!/usr/bin/env bash
# Script that gets run nightly after installed by crontab.

set -euo pipefail
IFS=$'\n\t'

export PATH=$HOME/.local/bin:$HOME/.local/mini_tools:$PATH

notify_error () {
  notify "Error running nightly cron job at $(date)." "Cron failed at $(date). Check log for details."
}
trap notify_error ERR

# Only try to rebuild work code on the work computer. ;)
if hash rebuild_my_code >&2; then
  echo "$(date)"
  echo "Will rebuild things."
  rebuild_my_code no-2fa

  echo "Finished at $(date)."
fi

notify "Nightly cron job ran OK at $(date)." "More info in logs."
