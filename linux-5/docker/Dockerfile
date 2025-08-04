FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --no-check-gpg --arch=i386 --include=bc,make,gcc,libc6-dev,libssl-dev,flex,bison bullseye bullseye

FROM scratch

COPY --from=build /root/bullseye /
COPY kbuild-5.sh /usr/local/bin/kbuild-5.sh
