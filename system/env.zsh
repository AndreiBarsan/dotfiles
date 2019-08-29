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
#   pip3 install --user powerline-status
export TMUX_POWERLINE_CONF="$HOME/.local/lib/python3.6/site-packages/powerline/bindings/tmux/powerline.conf"


