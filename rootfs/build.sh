#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))

cd "${TOP}"

docker build -t build-app docker

rm -rf build
mkdir -p build
cd build

docker run -it --rm -v "${PWD}:/root/wdir" build-app /usr/local/bin/build-app.sh

dd if=/dev/zero of=rootfs.img bs=1M count=200
mkfs.ext2 -I 128 rootfs.img
mkdir mnt
mount rootfs.img mnt
cp linux-perf-* mnt/
mkdir mnt/dev
mknod mnt/dev/console c 4 64
mkdir mnt/proc
mkdir mnt/sys
umount mnt
mv rootfs.img ../../out/

cd ..
rm -rf build
