FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --no-check-gpg --arch=i386 --include=bc,make,gcc,libc6-dev,libssl-dev,flex,bison jessie jessie http://archive.debian.org/debian

FROM scratch

COPY --from=build /root/jessie /
COPY kbuild.sh /usr/local/bin/kbuild.sh
