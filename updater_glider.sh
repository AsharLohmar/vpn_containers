#!/bin/bash
check_only="${1}"
set -e
. .settings

latest_available="$(wget https://github.com/nadoo/glider/releases/latest  -O -  2>&1 --max-redirect 0 | grep Location | awk '{print $2}' | awk -F'/v' '{print $2}')"

latest_used="$(docker run --rm -it --pull always --entrypoint /glider asharlohmar/glider-proxy:latest -help 2>/dev/null | tail -1 | awk '{print $2}' | tr -d ',')"
if [ "${latest_available}" = "${latest_used}x" ]; then
    echo "Already at the latest version: ${latest_used}"
else
	echo "Needs upgrade"
	echo "latest: ${latest_used}"
fi

latests_page="$(wget "$(wget https://github.com/nadoo/glider/releases/latest  -O -  2>&1 --max-redirect 0 | grep Location | awk '{print $2}' | sed 's/tag/expanded_assets/g')" -qO - | grep -E 'href.*(checksum|linux.*amd64\.tar)')"
file_uri="$(grep amd64 <<<"$latests_page" | grep linux | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
checksum_uri="$(grep checksum <<<"$latests_page" | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
echo "file: https://github.com${file_uri}"
echo "chks: $(wget "https://github.com${checksum_uri}" -qO - | grep -E 'linux.*amd64\.tar' | awk '{print $1}')"
