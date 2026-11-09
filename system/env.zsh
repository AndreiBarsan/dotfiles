# Sets up various environment variables

if [[ $(uname -s) == 'Linux' ]]; then
  export EDITOR='vim'
elif [[ $(uname -s) == 'Darwin' ]]; then
  # export EDITOR='reattach-to-user-namespace /Applications/MacVim.app/Contents/MacOS/Vim'
  # vim should already be aliased to the right thing...
  export EDITOR='vim'
else
  export EDITOR='vim'
fi

# 2024-08-25 macOS
export PATH="$HOME/Library/Python/3.12/bin/powerline:$PATH"

# Linux: single managed install via pipx — run `script/install-powerline.sh` (idempotent).
#   Manual: python3 -m pip install --user pipx && pipx install powerline-status
#   then `pipx inject powerline-status <plugin>` for extras.
# macOS: still using the legacy `pip install --user powerline-status` layout.
if [[ $(uname -s) == 'Linux' ]]; then
  # (N) glob qualifier: unmatched globs expand to nothing instead of erroring.
  # Canonical pipx venv first; legacy pip --user layouts kept as fallback for old machines.
  _powerline_conf=(
    "$HOME"/.local/share/pipx/venvs/powerline-status/lib/python*/site-packages/powerline/bindings/tmux/powerline.conf(N)
    "$HOME"/.local/lib/python*/site-packages/powerline/bindings/tmux/powerline.conf(N)
  )
  if (( ${#_powerline_conf} > 0 )); then
    export TMUX_POWERLINE_CONF="${_powerline_conf[1]}"
  else
    print -u2 "env.zsh: WARNING: no powerline conf found; run script/install-powerline.sh"
  fi
  unset _powerline_conf
  
elif [[ $(hostname) == 'andreib-C02Y71MJJGH6' ]]; then
  export TMUX_POWERLINE_CONF="/usr/local/lib/python3.7/site-packages/powerline/bindings/tmux/powerline.conf"
else
  #export TMUX_POWERLINE_CONF="$HOME/.local/lib/python3.10/site-packages/powerline/bindings/tmux/powerline.conf"
  export TMUX_POWERLINE_CONF="$HOME/Library/Python/3.12/lib/python/site-packages/powerline/bindings/tmux/powerline.conf"
fi
