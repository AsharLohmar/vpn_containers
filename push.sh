#!/bin/bash

[ -f .settings ] && . .settings

docker images -a | grep "asharlohmar/glider-proxy" | awk '{print $1":"$2}' | sort -u | \grep -E "$(date "+%Y%m%d")|latest" | sort -t: -k 1 -r | xargs -n 1 docker push
docker images -a | grep "asharlohmar" | grep -v 'glider-proxy' | awk '{print $1":"$2}' | sort -u | \grep -E "$(date "+%Y%m%d")|latest" | sort -t: -k 1 -r | xargs -n 1 docker push
