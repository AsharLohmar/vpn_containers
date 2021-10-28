FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && apk upgrade --no-cache -l --prune -a --purge && \
  apk add --no-cache ca-certificates openssl ppp && \
  echo "ifconfig&&sleep 1&&ifconfig" >> /etc/ppp/ip-up && \
  echo '[ "$(netstat -nr | grep -cE "192.168.0.0.+ppp0")" == "1" ] &&  route del -net 192.168.0.0 netmask "$(netstat -nr | grep -E "192.168.0.0.+ppp0" | awk "{print $3}")" ' >> /etc/ppp/ip-up && \
  update-ca-certificates && \
  echo "alias ll='ls -al'" >> /etc/profile && \
  rm -f /var/cache/apk/*

COPY files clients/openfortivpn /

EXPOSE 2226

ENTRYPOINT ["/autostart.sh"]
