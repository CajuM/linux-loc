FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --arch=i386 --include=make,gcc,libc6-dev sarge sarge http://archive.debian.org/debian

FROM scratch

COPY --from=build /root/sarge /
COPY kbuild-2.6.sh /usr/local/bin/kbuild-2.6.sh
