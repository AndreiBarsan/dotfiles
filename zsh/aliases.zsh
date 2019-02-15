alias reload!='. ~/.zshrc'

alias master='cd /Users/andrei/polybox/~Master'

# 1st semester MSc
# alias al='master && cd "AL-(Algorithms-Lab)"'
# alias asl='master && cd "ASL-(Advanced-Systems-Lab)"'
# alias dm='master && cd "DM-(Data-Mining)"'
# alias ir='master && cd "IR-(Information-Retrieval)"'
# alias ml='master && cd "ML-(Machine-Learning)"'
# alias pai='master && cd "PAI-(Probabilistic-AI)"'
# alias sdb='master && cd "SDB-(Scientific-Databases)"'

# 2nd semester MSc
# alias acd='master && cd ACD*'
# alias amr='master && cd AMR*'
# alias cil='master && cd CIL*'
# alias dal='master && cd DAL*'
# alias nlp='master && cd NLP*'
# alias sem='master && cd SEM*'

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
  # Temporarily disabled since the version on U of T's servers doesn't have
  # server support *grumble grumble*.
  # alias vim='vim --servername vim-server'
  alias open='xdg-open'
fi

# Traditional safety measure
alias mv='mv -i'
alias rm='rm -i'
alias cp='cp -i'
