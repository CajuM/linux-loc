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

	local kver_major=$(echo "${kver}" | grep -Po '^\d+')
	local kver_minor=$(echo "${kver}" | sed 's/^[0-9]*\.//g' | grep -Po '^\d+')
	local kver_patch=$(echo "${kver}" | sed 's/^[0-9]*\.[0-9]*\.//g;' | grep -Po '^\d+')

	if [[ ( ${kver_major} -eq 2 ) && ( ${kver_minor} -eq 4 ) ]]; then
		local root=/dev/hda
	fi

	if [[ ( ${kver_major} -eq 2 ) && ( ${kver_minor} -eq 6 ) ]]; then
		if [ ${kver_patch} -lt 27 ]; then
			local root=/dev/hda
		else
			local root=/dev/sda
		fi
	fi

	if [ ${kver_major} -gt 2 ]; then
		local root=/dev/sda
	fi

	echo "root=${root}"
}

function get_console {
	local kver=$1

	local kver_major=$(echo "${kver}" | grep -Po '^\d+')
	local kver_minor=$(echo "${kver}" | sed 's/^[0-9]*\.//g' | grep -Po '^\d+')

	if [[ ( ${kver_major} -eq 2 ) && ( ${kver_minor} -eq 4 ) ]]; then
		echo ""
	else
		echo "console=ttyS0"
	fi
}

function get_kver {
	basename "$1" | sed 's/^vmlinuz-//g'
}

function qemu_vm {
	local vmlinuz=$1
	local tx=$2
	local model=$3

	local kver=$(get_kver "${vmlinuz}")
	local root=$(get_root "${kver}")
	local console=$(get_console "${kver}")

	if [ "${tx}" == "tx" ]; then
		local macaddr="12:23:34:45:56:01"
	else
		local macaddr="12:23:34:45:56:02"
	fi

	if [ "${model}" == "virtio" ]; then
		local machine=q35
		local nic=virtio
	else
		local machine=pc
		local nic=virtio
	fi

	exec qemu-system-i386 \
                -display none \
                -name ${tx},debug-threads=on \
		-smp 2 \
                -m 8G \
                -M ${machine},accel=kvm \
                -cpu qemu32 \
                -drive file=tmp/rootfs-${tx}.img,format=raw \
                -kernel "${vmlinuz}" \
                -serial stdio \
                -append "init=/linux-perf-${tx} ${root} ${console}" \
                -net nic,model=${nic},macaddr=${macaddr} \
                -net tap,script=./ifup.sh,downscript=./ifdown.sh
}
