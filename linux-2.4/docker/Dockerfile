FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --arch=i386 --include=make,gcc,libc6-dev woody woody http://archive.debian.org/debian

FROM scratch

COPY --from=build /root/woody /
COPY kbuild-2.4.sh /usr/local/bin/kbuild-2.4.sh
