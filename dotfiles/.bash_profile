
#
# Source .bash_secrets when exists
#
if [ -f ~/.bash_secrets ]
then
  . ~/.bash_secrets
fi

#
# Set-Up SSH Agent
#
eval $(ssh-agent) > /dev/null

#
# Temp Dir
#
export TMP="/tmp"
export TMPDIR="$TMP"

#
# Terminal Tweaks
#
if [ "$(uname)" == "Linux" ]; then
  export PS1='\[\e]0;${debian_chroot:+($debian_chroot)}\w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\][\w]\[\033[01;32m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
else
  export PS1='\[\033[01;32m\]\u \[\033[00m\]\[\e]0;${debian_chroot:+($debian_chroot)}\w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\][\w]\[\033[00m\]\n\$ '
fi

#
# User Vars
#
export EDITOR='emacs -nw'
export LIGHTHOUSE_TOKEN=$MTOKEN
export NEXUS_USERNAME='jhulbert-va'
export VA_GITHUB_USER='jhulbert-va'

#
# Aliases
#

# mvn stuff
alias api-dev='mvn spring-boot:run -Dspring.profiles.active=dev'
alias mci='mvn clean install'
alias mcp='mvn clean package'

# git stuff
alias git-master='pull-default'
git config --global alias.alias '! git config --get-regexp ^alias\.'
git config --global alias.all 'commit -am'
git config --global alias.br 'branch'
git config --global alias.co 'checkout'
git config --global alias.nah '!git reset --hard && git clean -df'
git config --global alias.po 'push origin'
git config --global alias.shove 'push --force'
git config --global alias.st status
git config --global alias.unstage 'reset HEAD --'
git config --global alias.update 'pull --rebase origin master'

# misc
alias du-decrypt='docker run --rm -v $(pwd):/du vasdvp/deployer-toolkit:latest decrypt --encryption-passphrase $DU_ENCRYPTION_KEY'
alias du-encrypt='docker run --rm -v $(pwd):/du vasdvp/deployer-toolkit:latest encrypt --encryption-passphrase $DU_ENCRYPTION_KEY'
alias e='emacs -nw'
alias github='ssh-add ~/.ssh/github'
alias gnight='sudo shutdown now'
alias open='xdg-open'
alias please='sudo'
alias socks='ssh-add ~/.ssh/id_rsa_vetsgov; ssh socks -D 2001 -N &'
alias start='ssh-add ~/.ssh/id_rsa'
