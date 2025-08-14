#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))
BASE_KERNEL_URL=https://cdn.kernel.org/pub/linux/kernel/v2.6/
KBUILD=2.6.24

cd "${TOP}"

. ../common.sh

pg=$(curl -s "${BASE_KERNEL_URL}")
kvers=$(echo "${pg}" \
	| grep -Po 'linux-\d+\.\d+\.\d+\.tar\.gz' \
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
	kver_minor=$(echo "${kver}" | sed 's/^[0-9]\.[0-9]\.//g')
	if [ ${kver_minor} -lt 25 ]; then
		continue
	fi

	if [ ${kver_minor} -gt 31 ]; then
		continue
	fi

	build_kver "${kver}"
done

cd ..
rm -rf build
