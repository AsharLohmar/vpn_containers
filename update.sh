#!/bin/bash
# shellcheck disable=SC2076

[ -f .settings ] && . .settings

set -e 
docker pull alpine:latest 
alpine_layer="$(docker inspect --format '{{join .RootFS.Layers ""}}' alpine:latest)"
echo

declare -a to_build
echo "GLIDER"
checkup="$(./glider_updater.sh 1)"
if [[ "${checkup}" =~ "Needs upgrade" ]]; then
	./glider_updater.sh
	to_build=( "${images[@]}" )
else
	echo "${checkup[*]}"
fi
echo

echo "FORTIVPN"
checkup="$(./openfortivpn_updater.sh 1)"
if [[ "${checkup}" =~ "Needs upgrade" ]]; then
	./openfortivpn_updater.sh
	i="asharlohmar/glider-openfortivpn:vpn/openfortivpn.Dockerfile"	
	[[ ! " ${to_build[*]} " =~ " ${i} " ]]  && to_build+=( "${i}" )
else
	echo "${checkup[*]}"
fi
echo

images=( asharlohmar/glider-proxy:glider/Dockerfile )
images+=( asharlohmar/glider-vpnc:vpn/vpnc.Dockerfile )
images+=( asharlohmar/glider-vpnc-ssh:vpn/vpnc_ssh.Dockerfile )
images+=( asharlohmar/glider-openfortivpn:vpn/openfortivpn.Dockerfile )
images+=( asharlohmar/glider-openvpn:vpn/openvpn.Dockerfile )
for i in "${images[@]}"; do
	name="${i%%:*}"
	if [ -z "$(docker images --format '{{.Repository}}' "${name}:latest")" ]; then
		docker pull "${name}:latest"
	fi
	
	if docker inspect --format '{{.RootFS.Layers}}' "${name}" | grep -q "${alpine_layer}"; then
		echo "${name} is at the latest alpine"
	else
		echo "${name} needs alpine update"
		[[ ! " ${to_build[*]} " =~ " ${i} " ]]  && to_build+=( "${i}" )
	fi
done
echo

tag="$(date "+%Y%m%d")"
for i in "${to_build[@]}"; do
	name="${i%%:*}"
	dockerfile="${i##*:}"
	docker build --force-rm --rm --pull -f "${dockerfile}" -t "${name}:latest" -t "${name}:${tag}" "${dockerfile%/*}"
done

echo "done"
