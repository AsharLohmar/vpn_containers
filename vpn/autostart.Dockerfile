FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && \
  apk -U upgrade && \
  apk add --no-cache ca-certificates openssl && \
  update-ca-certificates && \
  echo "alias ll='ls -al'" >> /etc/profile

COPY autostart.sh /

COPY /autostart.d/* /autostart.d/
ONBUILD COPY /autostart.d/* /autostart.d/

ENTRYPOINT ["/autostart.sh"]
