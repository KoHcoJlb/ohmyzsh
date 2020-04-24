#!/usr/bin/env zsh

zmodload zsh/datetime

# Cancel upgrade if the current user doesn't have write permissions for the
# oh-my-zsh directory.
[[ -w "$ZSH" ]] || return 0

# Cancel upgrade if git is unavailable on the system
whence git >/dev/null || return 0

if mkdir "$ZSH/log/update.lock" 2>/dev/null; then
  env ZSH=$ZSH zsh $ZSH/tools/upgrade.sh

  rmdir $ZSH/log/update.lock
fi
