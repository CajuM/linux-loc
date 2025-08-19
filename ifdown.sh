#!/bin/sh

TAP=$1

ip link set br-exp down || true
ip link del br-exp || true
