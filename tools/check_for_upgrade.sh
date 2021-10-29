# Migrate .zsh-update file to $ZSH_CACHE_DIR
if [[ -f ~/.zsh-update && ! -f "${ZSH_CACHE_DIR}/.zsh-update" ]]; then
  mv ~/.zsh-update "${ZSH_CACHE_DIR}/.zsh-update"
fi

# Get user's update preferences
#
# Supported update modes:
# - prompt (default): the user is asked before updating when it's time to update
# - auto: the update is performed automatically when it's time
# - reminder: a reminder is shown to the user when it's time to update
# - disabled: automatic update is turned off
zstyle -s ':omz:update' mode update_mode || update_mode=prompt

# Support old-style settings
[[ "$DISABLE_UPDATE_PROMPT" != true ]] || update_mode=auto
[[ "$DISABLE_AUTO_UPDATE" != true ]] || update_mode=disabled

# Cancel update if:
# - the automatic update is disabled.
# - the current user doesn't have write permissions nor owns the $ZSH directory.
# - git is unavailable on the system.
if [[ "$update_mode" = disabled ]] \
   || [[ ! -w "$ZSH" || ! -O "$ZSH" ]] \
   || ! command -v git &>/dev/null; then
  unset update_mode
  return
fi

function current_epoch() {
  zmodload zsh/datetime
  echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
}

function is_update_available() {
  local branch
  branch=${"$(git -C "$ZSH" config --local oh-my-zsh.branch)":-master}

  local remote remote_url remote_repo
  remote=${"$(git -C "$ZSH" config --local oh-my-zsh.remote)":-origin}
  remote_url=$(git -C "$ZSH" config remote.$remote.url)

  local repo
  case "$remote_url" in
  https://github.com/*) repo=${${remote_url#https://github.com/}%.git} ;;
  git@github.com:*) repo=${${remote_url#git@github.com:}%.git} ;;
  *)
    # If the remote is not using GitHub we can't check for updates
    # Let's assume there are updates
    return 0 ;;
  esac

  # If the remote repo is not the official one, let's assume there are updates available
  [[ "$repo" = ohmyzsh/ohmyzsh ]] || return 0
  local api_url="https://api.github.com/repos/${repo}/commits/${branch}"

  # Get local and remote HEADs and compare them. If we can't get either assume there are updates
  local local_head remote_head
  local_head=$(git -C "$ZSH" rev-parse $branch 2>/dev/null) || return 0

  remote_head=$(curl -fsSL -H 'Accept: application/vnd.github.v3.sha' $api_url 2>/dev/null) \
  || remote_head=$(wget -O- --header='Accept: application/vnd.github.v3.sha' $api_url 2>/dev/null) \
  || remote_head=$(HTTP_ACCEPT='Accept: application/vnd.github.v3.sha' fetch -o - $api_url 2>/dev/null) \
  || return 0

  # Compare local and remote HEADs
  [[ "$local_head" != "$remote_head" ]]
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

unset update_mode
unset -f current_epoch is_update_available update_last_updated_file update_ohmyzsh
