#!/bin/sh

cd /root/wdir

make ARCH=i386 mrproper
make ARCH=i386 defconfig

cat .config \
	| grep -v CONFIG_EXPERIMENTAL \
	| grep -v CONFIG_HYPERVISOR_GUEST \
	| grep -v CONFIG_PARAVIRT \
	| grep -v CONFIG_PARAVIRT_GUEST \
	| grep -v CONFIG_LGUEST_GUEST \
	| grep -v CONFIG_VIRTIO \
	| grep -v CONFIG_VIRTIO_PCI \
	| grep -v CONFIG_VIRTIO_NET \
	| grep -v CONFIG_EXT2_FS \
	| grep -v CONFIG_MPENTIUM4 \
	| grep -v CONFIG_IDE_GENERIC \
	| grep -v CONFIG_BLK_DEV_PIIX \
	| grep -v CONFIG_HIGHMEM64G > .config.new

echo CONFIG_EXPERIMENTAL=y >>.config.new
echo CONFIG_HYPERVISOR_GUEST=y >>.config.new
echo CONFIG_PARAVIRT=y >>.config.new
echo CONFIG_PARAVIRT_GUEST=y >>.config.new
echo CONFIG_LGUEST_GUEST=y >>.config.new
echo CONFIG_VIRTIO=y >>.config.new
echo CONFIG_VIRTIO_PCI=y >>.config.new
echo CONFIG_VIRTIO_NET=y >>.config.new
echo CONFIG_EXT2_FS=y >>.config.new
echo CONFIG_MPENTIUM4=y >>.config.new
echo CONFIG_IDE_GENERIC=y >>.config.new
echo CONFIG_BLK_DEV_PIIX=y >>.config.new
echo CONFIG_HIGHMEM64G=y >> .config.new

mv .config.new .config

while :; do echo -e '\n'; done | make ARCH=i386 oldconfig

make ARCH=i386 bzImage -j$(cat /proc/cpuinfo | grep '^processor' | wc -l)
