#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))
BASE_KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v5.x/
KBUILD=5

cd "${TOP}"

. ../common.sh

docker build -t kbuild-${KBUILd} docker

kvers=$(curl -s "${BASE_KERNEL_URL}" \
	| grep -Po 'linux-[\d\.]+\.tar\.gz' \
	| sed 's/linux-//g; s/.tar.gz//g' \
	| grep -P '^\d+\.\d++$' \
	| sort -u)

rm -rf build
mkdir -p build
cd build

for kver in ${kvers}; do
	build_kver "${kver}"
done

cd ..
rm -rf build
