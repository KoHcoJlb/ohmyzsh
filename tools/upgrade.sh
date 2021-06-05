#!/usr/bin/env zsh

if [ -z "$ZSH_VERSION" ]; then
  exec zsh "$0" "$@"
fi

cd "$ZSH"

# Use colors, but only if connected to a terminal
# and that terminal supports them.

local -a RAINBOW
local RED GREEN YELLOW BLUE BOLD DIM UNDER RESET

if [ -t 1 ]; then
  RAINBOW=(
    "$(printf '\033[38;5;196m')"
    "$(printf '\033[38;5;202m')"
    "$(printf '\033[38;5;226m')"
    "$(printf '\033[38;5;082m')"
    "$(printf '\033[38;5;021m')"
    "$(printf '\033[38;5;093m')"
    "$(printf '\033[38;5;163m')"
  )

  RED=$(printf '\033[31m')
  GREEN=$(printf '\033[32m')
  YELLOW=$(printf '\033[33m')
  BLUE=$(printf '\033[34m')
  BOLD=$(printf '\033[1m')
  DIM=$(printf '\033[2m')
  UNDER=$(printf '\033[4m')
  RESET=$(printf '\033[m')
fi

# Update upstream remote to ohmyzsh org
git remote -v | while read remote url extra; do
  case "$url" in
  https://github.com/robbyrussell/oh-my-zsh(|.git))
    git remote set-url "$remote" "https://github.com/ohmyzsh/ohmyzsh.git"
    break ;;
  git@github.com:robbyrussell/oh-my-zsh(|.git))
    git remote set-url "$remote" "git@github.com:ohmyzsh/ohmyzsh.git"
    break ;;
  esac
done

# Set git-config values known to fix git errors
# Line endings (#4069)
git config core.eol lf
git config core.autocrlf false
# zeroPaddedFilemode fsck errors (#4963)
git config fsck.zeroPaddedFilemode ignore
git config fetch.fsck.zeroPaddedFilemode ignore
git config receive.fsck.zeroPaddedFilemode ignore
# autostash on rebase (#7172)
resetAutoStash=$(git config --bool rebase.autoStash 2>/dev/null)
git config rebase.autoStash true

local ret=0

# Update Oh My Zsh
last_commit=$(git rev-parse HEAD)
if git pull --recurse-submodules --rebase --stat origin &> /dev/null; then
  # Check if it was really updated or not
  if [[ "$(git rev-parse HEAD)" != "$last_commit" ]]; then
    printf "${BLUE}${BOLD}Hooray! Oh My Zsh has been updated!"

    # Save the commit prior to updating
    git config oh-my-zsh.lastVersion "$last_commit"
  fi
else
  ret=$?
  printf "${RED}%s${RESET}\n" 'There was an error updating. Try again later?'
fi

# Exit with `1` if the update failed
exit $ret
