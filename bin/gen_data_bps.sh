#!/bin/sh

TOP=$(dirname $(dirname $(readlink -f $0)))
FILE_LIST=$(cat "${TOP}/share/loc/linux_tcp_file_list.txt")
LOG="${TOP}/out/data-linux-bps.tsv"
TMP=$(mktemp -d)

cd "${TMP}"
mkdir -p "${TOP}/out"

echo -e "linux\tbps" >"${LOG}"

for linux in $(ls "${TOP}/out/perf-"*.log | grep -Po 'perf-[\d\.]+.log' | sed 's/perf-//g; s/.log//g' | sort -V); do
	plogf="${TOP}/out/perf-${linux}.log"
	plog=$(cat "${plogf}" | grep -Po 'bps=\d+' | sed 's/bps=//g')
	sum=$(echo "${plog}" | awk 'BEGIN { sum = 0 } { sum += $1 } END { print sum }')
	mean=$((sum / $(wc -l --total=only "${plogf}")))

	echo -e "${linux}\t${mean}" >>"${LOG}"
done

cd
rm -rf "${TMP}"
