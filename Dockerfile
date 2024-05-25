FROM alpine:latest as base
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf                  && \
  apk upgrade --no-cache -l --prune -a --purge                  && \
  apk add --no-cache ca-certificates openssl libssl3            && \
  update-ca-certificates                                        && \
  echo "alias ll='ls -al --color'" >> /etc/profile              && \
  echo "export PS1='\[\033]0;[vpn:\h] \w\007\]\h: \w \\\$ '" >> /etc/profile              && \
  rm -f /var/cache/apk/*
  
FROM base as base_glider
ARG glider_url
ARG glider_sum
RUN \
	wget -O /tmp/glider.tar.gz "${glider_url}" && \
	sha256sum  -s -c <(echo "${glider_sum}  /tmp/glider.tar.gz") && \
	tar -C /	 --strip-components 1 -zxvpf /tmp/glider.tar.gz "$(tar -tzf /tmp/glider.tar.gz | grep -E '/glider$')" && \
	rm /tmp/glider.tar.gz

FROM base_glider as autostart_glider
COPY files_base /
EXPOSE 2226
ENTRYPOINT ["/autostart.sh"]

FROM base_glider as glider-proxy
COPY files_proxy /
EXPOSE 8443 8088
ENTRYPOINT ["/start.sh"]

FROM autostart_glider as glider-vpnc
RUN \
  apk add --no-cache vpnc
COPY files_extra/autostart_vpnc /autostart.d/02-vpn

FROM glider-vpnc as glider-vpnc-ssh
RUN \
  apk add --no-cache openssh-client

FROM glider-vpnc-ssh as glider-vpnc-ssh-openconnect
RUN \
  apk add --no-cache openconnect


FROM autostart_glider as glider-openvpn
RUN \
  apk add --no-cache openvpn openresolv bash && \
  wget "https://raw.githubusercontent.com/ProtonVPN/scripts/master/update-resolv-conf.sh" -O "/etc/openvpn/update-resolv-conf" && \
  chmod a+x /etc/openvpn/update-resolv-conf && \
  mkdir /dev/net && mknod /dev/net/tun c 10 200
  
COPY files_extra/autostart_openvpn /autostart.d/02-vpn


FROM autostart_glider as glider-openfortivpn
RUN \
  apk add --no-cache ppp && \
  echo "ifconfig&&sleep 1&&ifconfig" >> /etc/ppp/ip-up && \
  echo '[ "$(netstat -nr | grep -cE "192.168.0.0.+ppp0")" == "1" ] &&  route del -net 192.168.0.0 netmask "$(netstat -nr | grep -E "192.168.0.0.+ppp0" | awk "{print $3}")" ' >> /etc/ppp/ip-up && \
  if ! grep -q ipcp-accept-remote /etc/ppp/options; then echo ipcp-accept-remote >> /etc/ppp/options; fi && \
  mkdir -p /run/ppp/lock
  

COPY files_extra/autostart_openfortivpn /autostart.d/02-vpn
COPY files_extra/openfortivpn /

FROM autostart_glider as glider-openconnect
RUN \
  apk add --no-cache openconnect

COPY files_extra/autostart_openconnect /autostart.d/02-vpn  
