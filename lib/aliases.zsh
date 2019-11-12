alias cp="rsync -Phrvl"

function sudo-zsh() {
  sudo $@ ZDOTDIR=$HOME SUDO_ZSH=1 zsh
}
