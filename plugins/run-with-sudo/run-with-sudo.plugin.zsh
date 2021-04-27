#!/bin/zsh

pacman() {
    sudo pacman $@
}

systemctl() {
    sudo systemctl $@
}

journalctl() {
    sudo journalctl $@
}
