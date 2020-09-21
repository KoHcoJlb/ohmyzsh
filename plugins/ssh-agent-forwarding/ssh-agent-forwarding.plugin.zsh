auth_sock_path=${ZSH_SSH_AGENT_SOCK:-$(cd;pwd)/.ssh/auth_sock}
mkdir -p $(dirname $auth_sock_path)

if [[ -n $SSH_AUTH_SOCK && $SSH_AUTH_SOCK != $auth_sock_path ]]
then
    ln -sf $SSH_AUTH_SOCK $auth_sock_path
fi

export SSH_AUTH_SOCK=$auth_sock_path
