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
zstyle -s ':omz:update' mode update_mode || {
  update_mode=prompt

  # If the mode zstyle setting is not set, support old-style settings
  [[ "$DISABLE_UPDATE_PROMPT" != true ]] || update_mode=auto
  [[ "$DISABLE_AUTO_UPDATE" != true ]] || update_mode=disabled
}

# Cancel update if:
# - the automatic update is disabled.
# - the current user doesn't have write permissions nor owns the $ZSH directory.
# - is not run from a tty
# - git is unavailable on the system.
if [[ "$update_mode" = disabled ]] \
   || [[ ! -w "$ZSH" || ! -O "$ZSH" ]] \
   || [[ ! -t 1 ]] \
   || ! command git --version 2>&1 >/dev/null; then
  unset update_mode
  return
fi

function current_epoch() {
  zmodload zsh/datetime
  echo $(( EPOCHSECONDS / 60 / 60 / 24 ))
}

function is_update_available() {
  local branch
  branch=${"$(builtin cd -q "$ZSH"; git config --local oh-my-zsh.branch)":-master}

  local remote remote_url remote_repo
  remote=${"$(builtin cd -q "$ZSH"; git config --local oh-my-zsh.remote)":-origin}
  remote_url=$(builtin cd -q "$ZSH"; git config remote.$remote.url)

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

  # Get local HEAD. If this fails assume there are updates
  local local_head
  local_head=$(builtin cd -q "$ZSH"; git rev-parse $branch 2>/dev/null) || return 0

  # Get remote HEAD. If no suitable command is found assume there are updates
  # On any other error, skip the update (connection may be down)
  local remote_head
  remote_head=$(
    if (( ${+commands[curl]} )); then
      curl --connect-timeout 2 -fsSL -H 'Accept: application/vnd.github.v3.sha' $api_url 2>/dev/null
    elif (( ${+commands[wget]} )); then
      wget -T 2 -O- --header='Accept: application/vnd.github.v3.sha' $api_url 2>/dev/null
    elif (( ${+commands[fetch]} )); then
      HTTP_ACCEPT='Accept: application/vnd.github.v3.sha' fetch -T 2 -o - $api_url 2>/dev/null
    else
      exit 0
    fi
  ) || return 1

  # Compare local and remote HEADs (if they're equal there are no updates)
  [[ "$local_head" != "$remote_head" ]] || return 1

  # If local and remote HEADs don't match, check if there's a common ancestor
  # If the merge-base call fails, $remote_head might not be downloaded so assume there are updates
  local base
  base=$(builtin cd -q "$ZSH"; git merge-base $local_head $remote_head 2>/dev/null) || return 0

  # If the common ancestor ($base) is not $remote_head,
  # the local HEAD is older than the remote HEAD
  [[ $base != $remote_head ]]
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
