#=~=~=~=~=~=~=~=~= .bash_profile =~=~=~=~=~=~=~=~=~

main() {
  dev-env
  git-alias
  maven-alias
  misc
  terminal-tweaks
  user-vars
}

#=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~

dev-env() {
  # Source .bash_secrets when exists
  if [ -f ~/.bash_secrets ]
  then
    . ~/.bash_secrets
  fi

  # Set-Up SSH Agent
  eval $(ssh-agent) > /dev/null

  # Temp Dir
  export TMP="/tmp"
  export TMPDIR="$TMP"
}

git-alias() {
  git config --global alias.alias '! git config --get-regexp ^alias\.'
  git config --global alias.all 'commit -am'
  git config --global alias.br 'branch'
  git config --global alias.co 'checkout'
  git config --global alias.default '!git symbolic-ref refs/remotes/origin/HEAD --short | cut -d"/" -f2'
  git config --global alias.home '!git checkout $(git default) && git pull'
  git config --global alias.nah '!git reset --hard && git clean -df'
  git config --global alias.po 'push origin'
  git config --global alias.shove 'push --force'
  git config --global alias.st 'status'
  git config --global alias.trim '!git home && git branch -d $(git branch | grep -v $(git default))'
  git config --global alias.unstage 'reset HEAD --'
  git config --global alias.update '!git pull --rebase origin $(git default)'
}

maven-alias() {
  alias api-dev='mvn spring-boot:run -Dspring.profiles.active=dev'
  alias mci='mvn clean install'
  alias mcp='mvn clean package'
}

misc() {
  alias du-decrypt="dtk2 -e $DU_ENCRYPTION_KEY decrypt"
  alias du-encrypt='dtk2 -e $DU_ENCRYPTION_KEY encrypt'
  alias cd..='cd ..'
  alias e='emacs -nw'
  alias github='ssh-add ~/.ssh/github'
  alias bye-felicia='shutdown now'
  alias open='xdg-open'
  alias please='sudo'
  alias rot13="tr 'A-Za-z' 'N-ZA-Mn-za-m'"
  alias socks='ssh-add ~/.ssh/id_rsa_vetsgov; ssh socks -D 2001 -N &'
  alias start='ssh-add ~/.ssh/id_rsa'
}

terminal-tweaks() {
  if [ "$(uname)" == "Linux" ]; then
    export PS1='\[\e]0;${debian_chroot:+($debian_chroot)}\w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\][\w]\[\033[01;32m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
  else
    export PS1='\[\033[01;32m\]\u \[\033[00m\]\[\e]0;${debian_chroot:+($debian_chroot)}\w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;34m\][\w]\[\033[00m\]\n\$ '
  fi
}

user-vars() {
  export EDITOR='emacs -nw'
}

#=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~=~

main
