#!/bin/sh

set -ex

cd /root/linux-perf

make

install -m0777 linux-perf-tx ../wdir/linux-perf-tx
install -m0777 linux-perf-rx ../wdir/linux-perf-rx
