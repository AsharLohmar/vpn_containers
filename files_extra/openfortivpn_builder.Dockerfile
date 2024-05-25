FROM alpine:latest
#ARG OPENFORTIVPN_VERSION=v1.13.3
ARG OPENFORTIVPN_VERSION

RUN \
  apk upgrade --no-cache -l --prune -a --purge   && \
  apk add --no-cache autoconf automake build-base ca-certificates curl git openssl-dev ppp && \
  update-ca-certificates && \
  # build openfortivpn
  mkdir -p /usr/src/openfortivpn && \
  echo "curl -sL https://github.com/adrienverge/openfortivpn/archive/${OPENFORTIVPN_VERSION}.tar.gz" && \
  curl -sL https://github.com/adrienverge/openfortivpn/archive/${OPENFORTIVPN_VERSION}.tar.gz \
    | tar xz -C /usr/src/openfortivpn --strip-components=1 && \
  cd /usr/src/openfortivpn && \
  ./autogen.sh && \
  ./configure --prefix= && \
  make -j$(nproc) && \
  make install && cp /bin/openfortivpn / && echo "done"