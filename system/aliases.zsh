# Despite the extension, these aliases should be shell-agnostic

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
  alias vim='DISPLAY=:0 reattach-to-user-namespace /Applications/MacVim.app/Contents/MacOS/Vim --servername vim-server'
  alias mvim='DISPLAY=:0 reattach-to-user-namespace mvim --servername vim-server'
  alias open='DISPLAY=:0 reattach-to-user-namespace open'
else
  alias vim='vim --servername vim-server'
  alias open='xdg-open'
fi

# Traditional safety measure
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'

alias shiet='notify-send "SSSSSHHHIIIIIIIIIIIIIIIIIIIIEEEEEEEEEEEEEEEEEEEEEEEEETT" -i ~/Pictures/db.jpg'
