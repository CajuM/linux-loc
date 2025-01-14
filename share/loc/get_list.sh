#!/bin/sh

BASE_URL="https://cdn.kernel.org/pub/linux/kernel"

for dir in $(curl -s ${BASE_URL}/ | grep -Po 'href="v[^/]+/"' | grep -Po 'v\d+\.[x\d]+'); do
	for tb in $(curl -s ${BASE_URL}/${dir}/ | grep -Po 'linux-[\d.]+\.tar.gz'); do
		ver=$(echo "${tb}" | grep -Po '\d+(\.\d+)+')
		url=${BASE_URL}/${dir}/${tb}
		echo "${ver} ${url}"
	done
done
