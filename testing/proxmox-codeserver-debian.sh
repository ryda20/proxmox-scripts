#!/bin/bash

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

#https://github.com/coder/code-server/blob/main/install.sh
# curl -fsSL https://code-server.dev/install.sh | sh
# or
# https://coder.com/docs/code-server/latest/install#debian-ubuntu

VERSION=4.8.0

curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb
sudo dpkg -i code-server_${VERSION}_amd64.deb
sudo systemctl enable --now code-server@$USER
# Now visit http://127.0.0.1:8080. Your password is in ~/.config/code-server/config.yaml
