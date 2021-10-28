#!/bin/bash
check_only="${1}"
set -e
# set -x
#latest="$(wget https://github.com/adrienverge/openfortivpn/releases -qO - | grep muted | grep gz | head -n 1 | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
latest="$(wget https://github.com/adrienverge/openfortivpn/tags -qO - | grep muted | grep gz | head -n 1 | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
latest="${latest##*/}"
latest="${latest:0:-7}"

if [ -f vpn/clients/openfortivpn/openfortivpn ];then
	current_version="$(strings vpn/clients/openfortivpn/openfortivpn | grep -E 'openfortivpn .*[0-9]' | awk '{print $2}' )"
fi
if [ -n "$current_version" ] && [[ "$latest" =~ $current_version ]]; then
	echo "Already at the latest version: $current_version"
else
	if [ -n "${check_only}" ]; then
		echo "Needs upgrade"
	else
		echo "getting the latest version"
		DOCKER_BUILDKIT=1 docker build --force-rm --rm --pull -f vpn/openfortivpn_builder.Dockerfile --build-arg "OPENFORTIVPN_VERSION=${latest}" -t ofv_builder .
		docker create --name ofv_builder ofv_builder
		docker cp ofv_builder:/bin/openfortivpn vpn/clients/openfortivpn/
		docker rm ofv_builder 
		docker rmi ofv_builder
	fi
fi
