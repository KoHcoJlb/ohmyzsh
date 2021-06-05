# Migrate .zsh-update file to $ZSH_CACHE_DIR
if [[ -f ~/.zsh-update && ! -f "${ZSH_CACHE_DIR}/.zsh-update" ]]; then
  mv ~/.zsh-update "${ZSH_CACHE_DIR}/.zsh-update"
fi

# Cancel update if:
# - the automatic update is disabled.
# - the current user doesn't have write permissions nor owns the $ZSH directory.
# - git is unavailable on the system.
if [[ "$DISABLE_AUTO_UPDATE" = true ]] \
   || [[ ! -w "$ZSH" || ! -O "$ZSH" ]] \
   || ! command -v git &>/dev/null; then
  return
fi


function current_epoch() {
  zmodload zsh/datetime
  echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
}

function update_last_updated_file() {
  echo "LAST_EPOCH=$(current_epoch)" >! "${ZSH_CACHE_DIR}/.zsh-update"
}

function update_ohmyzsh() {
  if ZSH="$ZSH" zsh -f "$ZSH/tools/upgrade.sh" --interactive; then
    update_last_updated_file
  fi
}

update_ohmyzsh
