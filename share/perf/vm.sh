#!/bin/sh

PWD=$(dirname $(readlink -f $0))
img=$1

qemu-system-x86_64 \
	-M pc,accel=kvm \
	-m 1G \
	-cpu pentium3 \
	-vga std \
	-hda "${img}" \
	-net nic,model=pcnet,macaddr=12:23:34:45:56:01 \
	-net tap,script="${PWD}/ifup.sh"
