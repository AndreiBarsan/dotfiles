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
# 
# If available, start tmux, attaching to any running session.
# Tries to use tmuxinator wrapper, if available.
if [[ $(uname -s) == 'Linux' ]]; then
  # TODO(andrei): For maximum cross-platformness, PLEASE just install poweline
  # locally in '~/bin'.
  export TMUX_POWERLINE_CONF=~"/.local/lib/python2.7/site-packages/powerline/bindings/tmux/powerline.conf"
else
  export TMUX_POWERLINE_CONF="/Users/andrei/.local/lib/python3.6/site-packages/powerline/bindings/tmux/powerline.conf"
fi

# [ETH] CUDA 8.0 support on Ubuntu 16
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-8.0/lib64"
export PATH="$PATH:/usr/local/cuda-8.0/bin"

