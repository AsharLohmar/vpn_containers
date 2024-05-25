#!/bin/sh
# based on the work of https://github.com/avleen/bashttpd


if [ ! -f /tmp/proxy.pac ]; then
    WD="/conf/rules.d" 
    cat <<EOF > /tmp/proxy.pac
function isInCIDR(ip, cidr) {
	return ip.split('.').map(octet => ('00000000' + parseInt(octet).toString(2)).slice(-8)).join('')
	.startsWith(cidr.split('/')[0].split('.').map(octet => ('00000000' + parseInt(octet).toString(2)).slice(-8)).join('').slice(0, parseInt(cidr.split('/')[1], 10)));
}
function FindProxyForURL(url, host) {
	var proxy_machine = "SOCKS5 ${PROXY_ENDPOINT}";
	var i;
	var ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;

	var ips = [$(\grep -h -E '^\s*ip=' "${WD}"/* | sort -u | awk -F= '{s=(NR==1?s:s ", ")"\""$2"\""}END{print s}')];
	var domains = [$(\grep -h -E '^\s*domain=' "${WD}"/* | sort -u | awk -F= '{s=(NR==1?s:s ", ")"\""$2"\""}END{print s}')];
	var cidrs = [$(\grep -h -E '^\s*cidr=' "${WD}"/* | sort -u | awk -F= '{s=(NR==1?s:s ", ")"\""$2"\""}END{print s}')];

	if (ipv4Regex.test(host)) {
		if (ips.indexOf(host) !== -1)
			return proxy_machine;
		for (i = 0; i < cidrs.length; i++) {
			if (isInCIDR(host, cidrs[i])) {
				return proxy_machine;
			}
		}
	} else {
		if (domains.indexOf(host) !== -1)
			return proxy_machine;
		for (i = 0; i < domains.length; i++) {
			if (shExpMatch(host, "*." + domains[i])) {
				return proxy_machine;
			}
		}
	}
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
