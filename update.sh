#!/bin/bash
# shellcheck disable=SC2076

[ -f .settings ] && . .settings

while getopts ":f" option; do
   case $option in
      f)
          force="1"
          ;;
      *)
          ;;
   esac
done

set -e 
docker pull alpine:latest 
alpine_layer="$(docker inspect --format '{{join .RootFS.Layers ""}}' alpine:latest)"
echo

images="$(grep "glider-" Dockerfile  | awk '{print $NF}')"
#images="glider-openconnect "
to_build=""
if [ "${force}" = "1" ]; then
    echo "Building forced"
    to_build="${images}"
    checkup="$(./updater_glider.sh 1)"
    glider_url="$(grep 'file:' <<<"$checkup" | awk '{print $2}')"
    glider_sum="$(grep 'chks:' <<<"$checkup" | awk '{print $2}')"
else
    echo "GLIDER"
    checkup="$(./updater_glider.sh 1)"
    if [[ ! "${checkup}" =~ "Already" ]]; then
        current_version="$(grep 'latest:' <<<"$checkup" | awk '{print $2}')"
        for i in ${images}; do
            image_version="$(docker run --rm -it --name tmp  --entrypoint /glider asharlohmar/"${i}" --help | tr ',' ' ' | grep -E ' [0-9]+\.[0-9]+\.[0-9]+ ' | awk '{print $2}')"
            if [[ ! "$image_version" =~ "$current_version" ]] && [[ ! " ${to_build} " =~ " ${i} " ]]; then
                to_build="${to_build} ${i} "
            fi
        done
    else
        head -n 1 <<<"$checkup"
    fi
    glider_url="$(grep 'file:' <<<"$checkup" | awk '{print $2}')"
    glider_sum="$(grep 'chks:' <<<"$checkup" | awk '{print $2}')"

    echo

    echo "FORTIVPN"
    checkup="$(./updater_openfortivpn.sh 1)"
    if [[ ! "${checkup}" =~ "Already" ]]; then
        ./updater_openfortivpn.sh
        current_version="$(strings files_extra/openfortivpn | grep -E 'openfortivpn .*[0-9]' | awk '{print $2}' )"
        for i in ${images}; do 
            if [[ "${i}" =~  fortivpn ]]; then
                image_version="$(docker run --rm -it --name tmp  --entrypoint /openfortivpn asharlohmar/"${i}" --version)"
                if [[ ! "$image_version" =~ "$current_version" ]] && [[ ! " ${to_build} " =~ " ${i} " ]]; then
                    to_build="${to_build} ${i} "
                fi
            fi
        done
    else
        echo "${checkup[*]}"
    fi
    echo 

    echo "ALPINE"
    for i in ${images}; do
        name="asharlohmar/${i%}"
        if [ -z "$(docker images --format '{{.Repository}}' "${name}:latest")" ]; then
            docker pull "${name}:latest" || true
        fi
        
        if docker inspect --format '{{.RootFS.Layers}}' "${name}" | grep -q "${alpine_layer}"; then
            echo "${name} is at the latest alpine"
        else
            echo "${name} needs alpine update"
            [[ ! " ${to_build} " =~ " ${i} " ]]  && to_build="${to_build} ${i}"
        fi
    done
    echo
fi

echo "BUILDING: ${to_build}"
tag="$(date "+%Y%m%d")"
for i in ${to_build}; do
    name="asharlohmar/${i%}"
    docker build \
        --build-arg glider_url="${glider_url}" \
        --build-arg glider_sum="${glider_sum}" \
        --force-rm --rm --pull \
        -t "${name}:latest" -t "${name}:${tag}" \
        --target "${i}" .
done

[ -z "${to_build}" ] && echo "Nothing to build"

echo "Done"
