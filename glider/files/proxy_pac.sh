#!/bin/sh
# based on the work of https://github.com/avleen/bashttpd


if [ ! -f /tmp/proxy.pac ]; then
    WD="/conf/rules.d" 
    cat <<EOF > /tmp/proxy.pac
function FindProxyForURL(url, host) {
    var proxy_machine = "SOCKS5 ${PROXY_ENDPOINT}";
    
    var ips = [$(\grep -h -E '^(ip|domain)=' "${WD}"/* | sort -u | awk -F= '{s=(NR==1?s:s ", ")"\""$2"\""}END{print s}')];
    if(ips.indexOf(host) != -1) return proxy_machine;
    if ($(\grep -h -E '^domain=' "${WD}"/* | sort -u | awk -F= '{s=(NR==1?s:s " || ")"shExpMatch(host,\"*."$2"\")"}END{print s}')) return proxy_machine;
    if ($(\grep -h -E '^cidr=' "${WD}"/* | awk -F. '{print $1"."$2"."$3}' | sort -u  | awk -F= '{s=(NR==1?s:s " || ")"shExpMatch(host,\""$2".*\")"}END{print s}')) return proxy_machine;

    return "DIRECT";
}
EOF
fi

read -r REQUEST_METHOD REQUEST_URI REQUEST_HTTP_VERSION
REQUEST_HTTP_VERSION="$(echo "$REQUEST_HTTP_VERSION" | tr -d '\r')"
echo "$REQUEST_METHOD|$REQUEST_URI|$REQUEST_HTTP_VERSION" >&2
while read -r line; do
    line="$(echo "$line" | tr -d '\r')"
    echo "$line" >&2
    [ -z "$line" ] && break
done

DATE=$(date +"%a, %d %b %Y %H:%M:%S %Z")

send() { printf '%s\r\n' "$*"; }
send_dbg() { echo "> $*" >&2; printf '%s\r\n' "$*"; }

if [ "$REQUEST_METHOD" = "GET" ] && [ "$REQUEST_URI" = "/proxy.pac" ]; then
    send "${REQUEST_HTTP_VERSION} 200 OK"
    send "Date: $DATE"
    send "Expires: $DATE"
    send "Server: ash-mini-http/1.0"
    send "Content-Type: application/x-ns-proxy-autoconfig"
    send "Content-Length: $(stat -c'%s' /tmp/proxy.pac )"
    send
    cat /tmp/proxy.pac
else
    send "${REQUEST_HTTP_VERSION} 404 Not Found"
    send "Date: $DATE"
    send "Expires: $DATE"
    send "Server: ash-mini-http/1.0"
    send
fi
exit 0
