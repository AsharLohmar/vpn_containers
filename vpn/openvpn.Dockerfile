FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && apk upgrade --no-cache -l --prune -a --purge && \
  apk add --no-cache ca-certificates openssl openvpn openresolv bash && \
  wget "https://raw.githubusercontent.com/ProtonVPN/scripts/master/update-resolv-conf.sh" -O "/etc/openvpn/update-resolv-conf" && \
  chmod a+x /etc/openvpn/update-resolv-conf && \
  mkdir /dev/net && mknod /dev/net/tun c 10 200 && \
  update-ca-certificates && \
  echo "alias ll='ls -al'" >> /etc/profile && \
  rm -f /var/cache/apk/*

COPY files clients/openvpn /

EXPOSE 2226

ENTRYPOINT ["/autostart.sh"]
