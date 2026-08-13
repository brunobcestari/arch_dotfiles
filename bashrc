#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '

if [ -f /etc/profile.d/custom_ps1.sh ]; then
   . /etc/profile.d/custom_ps1.sh
fi
export PATH=~/.npm-global/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"
#export DOCKER_HOST=unix:///run/user/1000/podman/podman.sock

search() {
  lynx "https://lite.duckduckgo.com/lite?q=$1"
}

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/bruno/.lmstudio/bin"
# End of LM Studio CLI section

