FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && apk upgrade --no-cache -l --prune -a --purge && \
  apk add --no-cache vpnc && \
  echo "alias ll='ls -al'" >> /etc/profile && \
  rm -f /var/cache/apk/*

COPY files clients/vpnc /

EXPOSE 2226

ENTRYPOINT ["/autostart.sh"]
