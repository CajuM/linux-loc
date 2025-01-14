#!/bin/sh

TAP=$1

ip link set ${TAP} up
ip addr add 10.111.111.2/24 dev ${TAP}
