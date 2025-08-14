FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --arch=i386 --include=make,gcc,libc6-dev lenny lenny http://archive.debian.org/debian

FROM scratch

COPY --from=build /root/lenny /
COPY kbuild.sh /usr/local/bin/kbuild.sh
