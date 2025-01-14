#!/bin/sh

TOP=$(dirname $(dirname $(readlink -f $0)))
FILE_LIST=$(cat "${TOP}/share/loc/linux_tcp_file_list.txt")
LOG="${TOP}/out/data-linux-loc.tsv"
TMP=$(mktemp -d)

cd "${TMP}"
mkdir -p "${TOP}/out"

echo -e "linux\tloc" >"${LOG}"

kernel_list=$("${TOP}/share/loc/get_list.sh" | grep -v '/kernel/v3.0/' | sort -u)
for linux in $(ls "${TOP}/out/perf-"*.log | grep -Po 'perf-[\d\.]+.log' | sed 's/perf-//g; s/.log//g' | sort -V); do
	kver_pat=$(echo "${linux} " | sed 's/\./\\./g')
	line=$(echo "${kernel_list}" | grep "${kver_pat}")

	url=$(echo "${line}" | awk '{print $2}')

	while ! wget "${url}"; do rm *.tar.gz; done
	tar xf *.tar.gz
	rm *.tar.gz

	pushd "${TMP}" &>/dev/null
	cd *
	loc=$(wc -l ${FILE_LIST} --total=only 2>/dev/null)
	popd &>/dev/null

	rm -rf linux linux-* *.tar.gz

	echo -e "${linux}\t${loc}" >>"${LOG}"
done

cd
rm -rf "${TMP}"
