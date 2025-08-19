#!/bin/sh

set -ex

LINUX=$(readlink -f $1)
GOOD=$2
BAD=$3

TOP=$(dirname $(dirname $(readlink -f $0)))
BIN=/usr/local/bin

cd ${LINUX}

git bisect reset
git bisect start

git bisect bad $2
git bisect good $1

while :; do
	docker run -it --rm --privileged -v "${TOP}/bisect/build.sh:${BIN}/build.sh" -v "${LINUX}:/root/wdir" kbuild-3 ${BIN}/build.sh
	nix-shell ${TOP} --run "${TOP}/exp.sh ${LINUX}/arch/i386/boot/bzImage"
	cat "${TOP}/out/exp-bzImage-2.log"

	read line

	if [ "${line}" == "good" ]; then
		git bisect good
	else
		git bisect bad
	fi
done
