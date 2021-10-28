FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && \
  apk -U upgrade && \
  apk add --no-cache ca-certificates openssl && \
  apk add --no-cache vpnc openssh-client && \
  update-ca-certificates && \
  echo "alias ll='ls -al'" >> /etc/profile && \
  rm -f /var/cache/apk/*

COPY files clients/vpnc /

EXPOSE 2226

ENTRYPOINT ["/autostart.sh"]
