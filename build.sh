#!/bin/sh

TOP=$(readlink -f $(dirname $0))

cd "${TOP}"

mkdir -p out

for b in linux-* rootfs; do
	"${b}/build.sh"
done
