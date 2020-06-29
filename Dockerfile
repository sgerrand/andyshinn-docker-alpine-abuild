#Add qemu function for supporting multiarch
ARG IMAGEARCH
FROM alpine:3.12 as qemu
RUN apk add --no-cache curl
ARG QEMUVERSION=4.0.0
ARG QEMUARCH

SHELL ["/bin/ash", "-o", "pipefail", "-c"]

RUN curl -fsSL https://github.com/multiarch/qemu-user-static/releases/download/v${QEMUVERSION}/qemu-${QEMUARCH}-static.tar.gz | tar zxvf - -C /usr/bin
RUN chmod +x /usr/bin/qemu-*

FROM ${IMAGEARCH}alpine:3.11
ARG QEMUARCH
COPY --from=qemu /usr/bin/qemu-${QEMUARCH}-static /usr/bin/

RUN apk --no-cache add alpine-sdk coreutils cmake \
  && adduser -G abuild -g "Alpine Package Builder" -s /bin/ash -D builder \
  && echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
  && mkdir /packages \
  && chown builder:abuild /packages
COPY /abuilder /bin/
USER builder
ENTRYPOINT ["abuilder", "-r"]
WORKDIR /home/builder/package
ENV RSA_PRIVATE_KEY_NAME ssh.rsa
ENV PACKAGER_PRIVKEY /home/builder/${RSA_PRIVATE_KEY_NAME}
ENV REPODEST /packages
VOLUME ["/home/builder/package"]
