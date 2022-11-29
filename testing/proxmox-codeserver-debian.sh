#!/bin/bash

## starting ##
[[ -z "$(which curl)" ]] && apt install -y curl
source /dev/stdin <<< "$(curl -s https://raw.githubusercontent.com/ryda20/bashlog/master/log.sh)"

log "run as user: $(id)"
read -p "Install by install.sh script? [Y/n]" answer
answer="${answer:-y}"
if [[ "$answer" == "y" ]]; then
	log "installing with install.sh script"
	#https://github.com/coder/code-server/blob/main/install.sh
	curl -fsSL https://code-server.dev/install.sh | sh
else
	log "installing with deb file"
	# https://coder.com/docs/code-server/latest/install#debian-ubuntu
	VERSION=4.8.0
	curl -fOL https://github.com/coder/code-server/releases/download/v$VERSION/code-server_${VERSION}_amd64.deb
	dpkg -i code-server_${VERSION}_amd64.deb
fi

systemctl enable --now code-server@$USER
# Now visit http://127.0.0.1:8080. Your password is in ~/.config/code-server/config.yaml

log --title "Fira Font Fix" "fixing fira code font not working"
dir="/usr/lib/code-server"
[[ ! -d "$dir" ]] && log "not found code-server directory at $dir" && return
#
log "adding fira code font url to header of workbench.html file"
findstr="</head>"
replace="<style>@import url('https://fonts.googleapis.com/css2?family=Fira+Code\&display=swap');</style></head>"
find "$dir" -name workbench.html -exec sed -i "s%${findstr}%${replace}%g" {} \;
#
log "adding style-src to fonts.googleapis.com"
findstr1="style-src 'self' 'unsafe-inline'"
replace1="style-src 'self' 'unsafe-inline' fonts.googleapis.com"
findstr2="font-src 'self' blob:"
replace2="font-src 'self' blob: fonts.gstatic.com"
find "$dir" \
	# only do on *.js file, can add another file extension: .*\(js\|html\|css\|ts\)
	-regex ".*\.\(js\)" \
	# group 1: if exec 1 ok -> do exec 2, else, stop
	\( -exec grep -rl "${findstr1}" {} \; -a -exec sed -i -e "s/${findstr1}/${replace1}/g" {} \; \) \
	# group 2
	\(  -exec grep -rl "${findstr2}" {} \; -a -exec sed -i -e "s/${findstr2}/${replace2}/g" {} \; \)
# find $dir -regex ".*\.\(js\)" \( -exec grep -rl "${findstr1}" {} \; -a -exec sed -i -e "s/${findstr1}/${replace1}/g" {} \; \) \(  -exec grep -rl "${findstr2}" {} \; -a -exec sed -i -e "s/${findstr2}/${replace2}/g" {} \; \)
