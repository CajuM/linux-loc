FROM debian AS build

RUN \
	apt-get update && \
	apt-get install -y debootstrap && \
	cd /root && \
	debootstrap --arch=i386 --include=make,gcc,libc6-dev etch etch http://archive.debian.org/debian

FROM scratch

COPY --from=build /root/etch /
COPY build-app.sh /usr/local/bin/build-app.sh
COPY linux-perf /root/linux-perf
