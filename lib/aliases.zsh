alias cp="rsync -Phhrvl"

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

function docker-compose() {
  if [[ $1 == "ubd" ]]
  then
    /usr/bin/docker-compose up --build -d
  elif [[ $1 == "ltf" ]]
  then
    /usr/bin/docker-compose logs --tail 100 -f
  else
    /usr/bin/docker-compose $@
  fi
}
