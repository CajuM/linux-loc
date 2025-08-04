#!/bin/sh

set -ex

TOP=$(dirname $(readlink -f $0))

cd "${TOP}"

mkdir -p tmp

cp out/rootfs.img tmp/rootfs-tx.img
cp out/rootfs.img tmp/rootfs-rx.img

. ./common.sh

vmlinuz_list=$1
if [ -z "${vmlinuz_list}" ]; then
	vmlinuz_list=out/vmlinuz-*
fi

for vmlinuz in ${vmlinuz_list}; do
	kver=$(get_kver "${vmlinuz}")

	qemu_vm out/vmlinuz-6.16 rx virtio > "out/exp-tx-${kver}-2.log" &
	rx_pid=$!
	sleep 2
	./qemu_affinity.py -k 1 -- ${rx_pid}

	qemu_vm "${vmlinuz}" tx pc > "out/exp-tx-${kver}-1.log" &
	tx_pid=$!
	sleep 2
	./qemu_affinity.py -k 2 -- ${tx_pid}

	sleep 30

	kill ${tx_pid}
	kill ${rx_pid}

	wait ${tx_pid}
	wait ${rx_pid}

	qemu_vm "${vmlinuz}" rx pc > "out/exp-rx-${kver}-2.log" &
	rx_pid=$!
	sleep 2
	./qemu_affinity.py -k 1 -- ${rx_pid}

	qemu_vm out/vmlinuz-6.16 tx virtio > "out/exp-rx-${kver}-1.log" &
	tx_pid=$!
	sleep 2
	./qemu_affinity.py -k 2 -- ${tx_pid}

	sleep 30

	kill ${tx_pid}
	kill ${rx_pid}

	wait ${tx_pid}
	wait ${rx_pid}
done

rm -rf tmp
