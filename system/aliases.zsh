# Despite the file extension, these aliases should be shell-agnostic

# grc overides for ls
#   Made possible through contributions from generous benefactors like
#   `brew install coreutils`
if $(gls &>/dev/null)
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
fi

alias gib='sudo apt-get install'

# Nosy neighbor! :)
alias ww='watch -n 0.5 w'

# For jumping around
alias phd="cd $HOME/drive/PhD"

# gcalcli (Google Calendar)
alias agenda='gcalcli agenda'
alias calw='gcalcli calw'
alias calm='gcalcli calm'

# [OSX] Force regular vim to be MacVim's vim
if [[ "$(uname -s)" == "Darwin" ]]; then
  # alias vim='DISPLAY=:0 reattach-to-user-namespace /Applications/MacVim.app/Contents/MacOS/Vim --servername vim-server'
  # alias mvim='DISPLAY=:0 reattach-to-user-namespace mvim --servername vim-server'
  # alias open='DISPLAY=:0 reattach-to-user-namespace open'
  # alias vim='DISPLAY=:0 vim --servername vim-server'
  # alias mvim='DISPLAY=:0 mvim --servername vim-server'
  alias open='DISPLAY=:0 open'
else
  # No more need for this in 2019
  # alias vim='vim --servername vim-server'
  alias open='xdg-open'
fi

# Traditional safety measure
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'

# Pretty Print Path
function ppp () {
  sed 's/:/\n/g' <<<$PATH
}

function shiet() {
  BODY=${1-nope}
  notify-send 'oh no' $BODY -i "$HOME/Pictures/ohno.png"
}

# [Linux] Ensure tmux always uses 256 colors
alias tmux='tmux -2'
