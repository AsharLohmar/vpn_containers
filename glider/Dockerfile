FROM alpine:latest
RUN \
  echo "hosts: files dns" > /etc/nsswitch.conf && apk upgrade --no-cache -l --prune -a --purge && \
  echo "alias ll='ls -al'" >> /etc/profile && \
  rm -f /var/cache/apk/*
  
COPY files/ /
EXPOSE 8443 8088

ENTRYPOINT ["/start.sh"]

