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

# Default way of installing (local user, recommended):
#   pip install --user powerline-status
if [[ $(uname -s) == 'Linux' ]]; then
  export TMUX_POWERLINE_CONF="$HOME/.local/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf"
elif [[ $(hostname) == 'andreib-C02Y71MJJGH6' ]]; then
  export TMUX_POWERLINE_CONF="/usr/local/lib/python3.7/site-packages/powerline/bindings/tmux/powerline.conf"
else
  export TMUX_POWERLINE_CONF="$HOME/.local/lib/python3.7/site-packages/powerline/bindings/tmux/powerline.conf"
fi
