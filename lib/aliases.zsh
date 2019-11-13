alias cp="rsync -Phrvl"

function sudo-zsh() {
  sudo $@ ZDOTDIR=$HOME SUDO_ZSH=1 zsh
}

function git() {
  if [[ $1 == "fpull" ]]
  then
    /usr/bin/git fetch && /usr/bin/git reset --hard $(git rev-parse --abbrev-ref --symbolic-full-name @{u})
  else
    /usr/bin/git $@
  fi
}
