#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))

cd "${TOP}"

mkdir -p tmp

cp out/rootfs.img tmp/rootfs-tx.img
cp out/rootfs.img tmp/rootfs-rx.img

. ./common.sh

vmlinuz_list=$@
if [ -z "${vmlinuz_list}" ]; then
	vmlinuz_list=out/vmlinuz-*
fi

for vmlinuz in ${vmlinuz_list}; do
	kver=$(get_kver "${vmlinuz}")

	loop=1
	while [ ${loop} -eq 1 ]; do
		qemu_vm "${vmlinuz}" rx > "out/exp-${kver}-2.log" &
		rx_pid=$!
		sleep 2
		./qemu_affinity.py -k 3,4,5 -- ${rx_pid}

		qemu_vm "${vmlinuz}" tx > "out/exp-${kver}-1.log" &
		tx_pid=$!
		sleep 2
		./qemu_affinity.py -k 6,7,8 -- ${tx_pid}

		last3=0
		last2=0
		last1=0
		while :; do
			len=$(grep '^pps=' "out/exp-${kver}-2.log" | wc -l)
			if [[ ( ${len} == ${last3} ) && ( ${len} != 0 ) ]]; then
				break
			fi

			if [ ${len} -ge 40 ]; then
				loop=0
				break
			fi

			last3=${last2}
			last2=${last1}
			last1=${len}

			sleep 1s
		done

		kill ${tx_pid}
		kill ${rx_pid}

		wait ${tx_pid}
		wait ${rx_pid}
	done
done

rm -rf tmp
