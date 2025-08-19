function build_kver {
	kver=$1

        tbal="linux-${kver}.tar.gz"
        while ! wget "${BASE_KERNEL_URL}${tbal}"; do rm -f "${tbal}"; done

        tar xvf "${tbal}"
        ldir=$(ls | grep '^linux' | grep -v "${tbal}")

        pushd .
        cd "${ldir}"
        cat $(cat ../../../linux_tcp_file_list.txt) | wc -l >"../../../out/loc-${kver}.txt"
        popd

        rm -rf "${ldir}"

        docker run -it --rm -v "${PWD}:/root/wdir" kbuild-${KBUILD} /usr/local/bin/kbuild.sh
        mv bzImage "../../out/vmlinuz-${kver}"
        mv src "../../out/src-${kver}"

        rm "${tbal}"
}

function get_root {
	local kver=$1

	local major=$(echo "${kver}" | cut -f1 -d.)
	local minor=$(echo "${kver}" | cut -f2 -d.)
	local patch=$(echo "${kver}" | cut -f3 -d.)

	local root="/dev/sda"

	if [[ ( ${major} == 2 ) && ( ${minor} == 6 ) && ( ${patch} -lt 27 ) ]]; then
		local root="/dev/hda"
	fi

	echo ${root}
}

function get_kver {
	basename $(echo "$1") | sed 's/vmlinuz-//g'
}

function qemu_vm {
	local vmlinuz=$1
	local tx=$2

	local kver=$(get_kver "${vmlinuz}")
	local root=$(get_root "${kver}")

	if [ "${tx}" == "tx" ]; then
		local macaddr="12:23:34:45:56:01"
		local dpdk=/tmp/dpdk1
	else
		local macaddr="12:23:34:45:56:02"
		local dpdk=/tmp/dpdk2
	fi

	exec qemu-system-i386 \
                -name ${tx},debug-threads=on \
		-display none \
                -m 6G \
		-smp 3 \
                -M pc,accel=kvm \
                -cpu qemu32 \
		-object memory-backend-file,id=mem,size=6144M,mem-path=/dev/hugepages,share=on \
		-mem-prealloc \
		-numa node,memdev=mem \
                -drive file=tmp/rootfs-${tx}.img,format=raw \
                -kernel "${vmlinuz}" \
                -serial stdio \
                -append "init=/linux-perf-${tx} root=${root} console=ttyS0" \
		-chardev socket,id=char1,server=off,path=${dpdk} \
		-netdev vhost-user,id=hostnet1,chardev=char1,vhostforce=on \
		-device virtio-net-pci,netdev=hostnet1,id=net1,mac=${macaddr},csum=on,guest_csum=on,disable-modern=on,mrg_rxbuf=off,gso=off,guest_tso4=off
}
