#!/bin/bash

set -ex

cd /root

tar xvzf wdir/linux*.tar.gz

cd linux*

while :; do echo -e '\n'; done | make ARCH=i386 config
grep -v PCNET32 .config >.config.new
echo CONFIG_PCNET32=y >>.config.new
echo CONFIG_EXT2_FS=y >>.config.new
mv .config.new .config
while :; do echo -e '\n'; done | make ARCH=i386 config

make ARCH=i386 bzImage -j$(cat /proc/cpuinfo | grep '^processor' | wc -l)

install -m0666 arch/i386/boot/bzImage ../wdir/bzImage
