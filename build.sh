#!/bin/bash

[ -f .settings ] && . .settings

images=( asharlohmar/glider-proxy:glider/Dockerfile )
images+=( asharlohmar/glider-vpnc:vpn/vpnc.Dockerfile )
images+=( asharlohmar/glider-vpnc-ssh:vpn/vpnc_ssh.Dockerfile )
images+=( asharlohmar/glider-openfortivpn:vpn/openfortivpn.Dockerfile )
images+=( asharlohmar/glider-openvpn:vpn/openvpn.Dockerfile )

tag="$(date "+%Y%m%d")"

for i in "${images[@]}"; do
	name="${i%%:*}"
	dockerfile="${i##*:}"
	docker build --force-rm --rm --pull -f "${dockerfile}" -t "${name}:latest" -t "${name}:${tag}" "${dockerfile%/*}"
done
echo "done"
