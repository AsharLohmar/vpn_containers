#!/bin/bash
check_only="${1}"
set -e
cd "$(dirname "$0")"
latests_page="$(wget https://github.com/nadoo/glider/releases/latest -qO - | grep -E '.*href.*(linux|checksum|amd64)')"
if [ -f glider/files/glider ]; then
    current_version="$(glider/files/glider --help | grep usage | awk '{print $2}')"
fi

if [ -n "$current_version" ] && [[ "$latests_page" =~ "$current_version" ]]; then
    echo "Already at the latest version: $current_version"
else
    if [ -n "${check_only}" ]; then
        echo "Needs upgrade"
    else
        echo "getting the latest version"
        file_uri="$(grep amd64 <<<"$latests_page" | grep linux | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
        checksum_uri="$(grep checksum <<<"$latests_page" | sed 's/.*href=["'\'']\([^"'\'']\+\).*/\1/')"
        checksum="$(wget "https://github.com${checksum_uri}" -qO - | grep linux | grep amd64 | awk '{print $1}')  glider.tar.gz" # keep 2 spaces as per sha256sum specs
        wget "https://github.com${file_uri}" -qcN --show-progress -O glider.tar.gz
        if shasum --status -c <<<"$checksum" ; then
            echo "package check passed"
            tar -C glider/files/ -zxvf glider.tar.gz --wildcards '*glider' --transform='s/.*\///'
            tar -C vpn/files/ -zxvf glider.tar.gz --wildcards '*glider' --transform='s/.*\///'
        else
            echo "checksum mismatch, run again"
            rm glider.tar.gz
        fi
    fi
fi
