#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))
BASE_KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v4.x/
KBUILD=4

cd "${TOP}"

. ../common.sh

pg=$(curl -s "${BASE_KERNEL_URL}")
kvers=$(echo "${pg}" \
	| grep -Po 'linux-\d+\.\d+\.tar\.gz' \
	| sed 's/linux-//g; s/.tar.gz//g' \
	| sort -u)

rm -rf build
mkdir -p build
cd build

pushd .
mkdir docker
cp ../Dockerfile docker
cp ../../kbuild.sh docker
docker build -t kbuild-${KBUILD} docker
popd

for kver in ${kvers}; do
	build_kver "${kver}"
done

cd ..
rm -rf build
