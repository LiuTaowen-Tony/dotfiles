#!/bin/bash

export PATH="$HOME/bin:$PATH"
current_shell=$(ps -p $$ -ocomm=)


if [ $current_shell = "bash" ] ; then
   
# BASH SPECIFIC

PS1='$(if [ $? -ne 0 ]; then echo -e ${RED}; else echo -e ${GREEN}; fi)→ ${BLUE}\W ${RESET} $(git branch &>/dev/null | grep "^\*" | sed "s/^\* //")'

elif [ $current_shell = "-zsh" ] ; then
   
# ZSH SPECIFIC

setopt CORRECT
setopt CORRECT_ALL
setopt NO_CASE_GLOB

HISTFILE="${HOME}/.zsh_history"
HISTSIZE=2000
SAVEHIST=5000
# share history across multiple zsh sessions
setopt SHARE_HISTORY
# append to history
setopt APPEND_HISTORY
# expire duplicates first
setopt HIST_EXPIRE_DUPS_FIRST
# do not store duplications
setopt HIST_IGNORE_DUPS
#ignore duplicates when searching
setopt HIST_FIND_NO_DUPS
# removes blank lines from history
setopt HIST_REDUCE_BLANKS
autoload -Uz compinit && compinit 

PROMPT='%(?..%F{red}?%? )%B%F{lime}%1~ %f'

fi

if [ $(uname) = "Darwin" ] ; then
  export CLICOLOR=1
  export LSCOLORS=ExGxBxDxCxEgEdxbxgxcxd
fi

ncolors=$(tput colors)
if [ -n "$ncolors" ] && [ $ncolors -ge 8 ]; then
alias grep='grep --color=auto'
alias diff='diff --color=auto'
alias ip='ip -color=auto'
alias git='git -c color.ui=auto'
alias json='jq .'
alias ls='ls --color=auto'
alias dir='dir --color=auto'
fi


source ${HOME}/.aliases

CHECK_OUTPUT="$HOME/.check_update_output.txt"
[ -e $CHECK_OUTPUT ] || touch $CHECK_OUTPUT
cat $CHECK_OUTPUT
cat /dev/null > $CHECK_OUTPUT

check_update "$HOME/bin" --bg "$CHECK_OUTPUT"
check_update "$HOME/dotfiles" --bg "$CHECK_OUTPUT"
background "sync_dotfiles d" /dev/null
